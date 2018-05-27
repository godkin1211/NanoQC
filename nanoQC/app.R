library(shiny)
library(shinyFiles)



ui <- fluidPage(
   
   titlePanel(title=div(img(src="logo.png"), "Microanaly Nanopore Sequencing Data QC Tool")),
   #titlePanel("Test"),
    
   # Sidebar
   sidebarLayout(
      sidebarPanel(
          tags$head(tags$style(type="text/css", "
             #loadmessage {
                               position: fixed;
                               top: 0px;
                               left: 0px;
                               width: 100%;
                               padding: 5px 0px 5px 0px;
                               text-align: center;
                               font-weight: bold;
                               font-size: 100%;
                               color: #000000;
                               background-color: #CCFF66;
                               z-index: 105;
                               }
                               ")),
         shinyFilesButton('fastqFile', 
                          label = 'Select', 
                          title = 'Please select a Fastq file', 
                          multiple = FALSE),
         verbatimTextOutput("filename"),
         
         tags$hr(),
         
         checkboxInput(inputId = "doTrimming", label = "Does reads need trimming?", value = TRUE),
         
         numericInput(inputId = "minLen", 
                      label = "Filter on a minimum read length",
                      value = 500),
         
         sliderInput(inputId = "minQual",
                     label = "Filter on a minimum average read quality score",
                     min = 5,
                     max = 20,
                     value = 10,
                     step = 1),
         
         sliderInput(inputId = "threadN",
                     label = "How many threads do you want use?",
                     min = 1,
                     max = 28,
                     value = 1,
                     step = 1),
         
         actionButton("goButton", "Start"),
         conditionalPanel(condition="$('html').hasClass('shiny-busy')",
                          tags$div("Processing, please wait a minute...",id="loadmessage"))
      ),
      
      # Main
      mainPanel(
          fluidRow(
              htmlOutput("finalReport")
          )
      )
   )
)

# Define server logic required to draw a histogram
server <- function(input, output) {
    home = c(home='~')
    fqpath <- NULL
    # Choose file
    shinyFileChoose(input, 'fastqFile', 
                    roots = home, 
                    filetypes = c('fq', 'fastq'))
    
    fqfileImport <- reactive({ 
        fqfileinfo <- parseFilePaths(home, input$fastqFile) 
        fqpath <<- file.path(as.character(fqfileinfo$datapath))
        if (length(fqpath) == 0) {
            return(NULL)
        }
        return(fqpath)
    })
    
    
    output$filename <- renderPrint({
        fqfilename <- fqfileImport()
        if (!is.null(fqfilename)) {
            fqfilename
        } else {
            cat("No file selected.")
        }
    })
    
    runPipeline <- eventReactive(input$goButton, {
        Sys.sleep(2)
        system("echo **************************")
        system("echo * Start NanoQC procedure *")
        system("echo **************************")
        doTrim <- input$doTrimming
        minLen <- input$minLen
        minQual <- input$minQual
        threadN <- input$threadN
        if (doTrim) {
            system("echo '*) Performing adapter trimming.........'")
            porechop_cmd <- paste("porechop -i", fqpath, "-o trimmed.fastq -t", threadN, "--discard_middle", sep = " ")
            system(porechop_cmd)
            system("echo '*) Performing quality trimming.........'")
            nanofilt_cmd <- paste("NanoFilt -q", minQual, "-l", minLen, "--logfile nanofilt.log < trimmed.fastq > cleaned.fastq" , sep = " ")
            system(nanofilt_cmd)
        }
        system("echo '*) Generating statistics summary..........'")
        input4NanoPlot <- ifelse(doTrim, "cleaned.fastq", fqpath)
        nanoplot_cmd <- paste("NanoPlot -t", threadN, "--fastq", input4NanoPlot, "--plots hex dot", sep = " ")
        system(nanoplot_cmd)
        system("cp *.html *.log *.png *.txt www/")
        if (file.exists("NanoPlot-report.html")) return(TRUE)
    })
    
    output$finalReport <- renderUI({
        finished <- runPipeline()
        if (finished) {
            system("rm -rf *.png *.log *.txt *.html")
            report <- tags$iframe(src="NanoPlot-report.html", height=840, width=1178)
        }
        print(report)
        report
    })
}

# Run the application 
shinyApp(ui = ui, server = server)


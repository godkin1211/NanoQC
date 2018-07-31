library(shiny)
library(shinyFiles)
library(shinycssloaders)
library(magrittr)

######################################################################################################################
# Check requirements installed
checkToolExist <- function(toolname) {
    commands <- paste("command -v", toolname, sep = " ")
    suppressWarnings(res <- system(commands, ignore.stdout = TRUE, ignore.stderr = TRUE))
    if (res != 0) stop(paste(toolname, "is required in this app, please check if you have already installed it correctly.", sep = " "))
}

baseCallTool <- "read_fast5_basecaller.py"
checkToolExist(baseCallTool)

adapterTrimTool <- "porechop"
checkToolExist(adapterTrimTool)

qualityTrimTool <- "NanoFilt"
checkToolExist(qualityTrimTool)

qcPlotTool <- "NanoPlot"
checkToolExist(qcPlotTool)

######################################################################################################################
# Generate randomized string
genRandomChar <- function(x=10) {
	chars <- c(LETTERS, letters, 0:9, '-', '#', '@', '&', '_', '%')
    idx <- sample(1:x, 1)
    randCharSet <- sapply(1:x, function(i) paste(sample(chars, 7, replace = TRUE), collapse=""))
	randCharSet[idx]
}
######################################################################################################################

# UI
ui <- fluidPage(
   
   titlePanel(title=div(img(src="logo.png"), "Microanaly Nanopore Sequencing Data QC Tool")),
    
   # Sidebar
   sidebarLayout(
      sidebarPanel(
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
         
         actionButton("goButton", "Start")
      ),
      
      # Main
      mainPanel(
          fluidRow(
              withSpinner(htmlOutput("finalReport"), type = 7)
          )
      )
   )
)

# Define server logic required to draw a histogram
server <- function(input, output) {
    home = c(home='~')
    fqpath <- NULL
	randDir <- genRandomChar()
    projDir <- file.path(getwd(), 'www', randDir)
    # Choose file
    shinyFileChoose(input, 'fastqFile', 
                    roots = home, 
                    filetypes = c('fq', 'fastq'))
    
    fqfileImport <- reactive({ 
        fqfileinfo <- parseFilePaths(home, input$fastqFile) 
        fqpath <- file.path(as.character(fqfileinfo$datapath))
        if (length(fqpath) == 0 | is.null(fqpath)) {
            return(NULL)
        }
        return(fqpath)
    })
    e
    
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
		fqpath <- fqfileImport()
        doTrim <- input$doTrimming
        minLen <- input$minLen
        minQual <- input$minQual
        threadN <- input$threadN
        if (doTrim) {
            system("echo '*) Performing adapter-trimming with porechop.........'")
            porechop_cmd <- paste("porechop -i", fqpath, "-o trimmed.fastq -t", threadN, "--discard_middle", sep = " ")
            system(porechop_cmd)
            system("echo '*) Performing quality-trimming with NanoFilt.........'")
            nanofilt_cmd <- paste("NanoFilt -q", minQual, "-l", minLen, "--logfile nanofilt.log < trimmed.fastq > cleaned.fastq" , sep = " ")
            system(nanofilt_cmd)
        }
        system("echo '*) Generating statistics summary..........'")
        input4NanoPlot <- ifelse(doTrim, "cleaned.fastq", fqpath)
        nanoplot_cmd <- paste("NanoPlot -t", threadN, "--fastq", input4NanoPlot, "--plots hex dot", sep = " ")
        system(nanoplot_cmd)
		system(paste("mkdir -p www/", randDir, sep = "/"))
        system(paste("mv *.html *.log *.png *.txt *.fastq", paste0("www/", randDir),sep = " "))
        if (file.exists(paste("www", randDir,"NanoPlot-report.html", sep = "/"))) return(TRUE)
    })
    
    output$finalReport <- renderUI({
        finished <- runPipeline()
        if (finished) {
            report <- tags$iframe(src=paste0(randDir,"/NanoPlot-report.html"), height=840, width=1178)
        }
        print(report)
        report
    })
    
}

# Run the application 
shinyApp(ui = ui, server = server)

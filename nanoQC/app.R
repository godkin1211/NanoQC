library(shiny)
library(shinyFiles)

# Define UI for application that draws a histogram
ui <- fluidPage(
   
   # Application title
   titlePanel(title=div(img(src="logo.png"), "Microanaly Nanopore Sequencing Data QC Tool")),
   
   # Sidebar with a slider input for number of bins 
   sidebarLayout(
      sidebarPanel(
         shinyFilesButton('fastqFile', 
                          label = 'Select', 
                          title = 'Please select a Fastq file', 
                          multiple = FALSE),
         
         tags$hr(),
         
         checkboxInput("trimming", "Does reads need trimming?", TRUE),
         
         sliderInput("minQual",
                     "Allow bases with minimum quality",
                     min = 5,
                     max = 20,
                     value = 10,
                     step = 1)
      ),
      
      # Show a plot of the generated distribution
      mainPanel(
          tags$h4('Wellcome to Microanaly\'s NanoQC Tool'),
          verbatimTextOutput("filename"),
          verbatimTextOutput("testoutput")
      )
   )
)

# Define server logic required to draw a histogram
server <- function(input, output) {
    home = c(home='~')
    shinyFileChoose(input, 'fastqFile', 
                    roots = home, 
                    filetypes = c('fastq', 'fq'))
    fqfileImport <- reactive({ 
        fqfileinfo <- parseFilePaths(home, input$fastqFile) 
        fqpath <- file.path(as.character(fqfileinfo$datapath))
        if (length(fqpath) == 0) {
            return(NULL)
        }
        return(fqpath)
    })
    
    output$filename <- renderPrint({
        fqfileImport()
    })

    output$testoutput <- renderPrint({
        fq <- fqfileImport()
        if (!is.null(fq)) {
            cat("\n")
        } else {
            cat("Hello world\n")
        }
    })
}

# Run the application 
shinyApp(ui = ui, server = server)


library(shiny)

ui <- fluidPage(
    
    titlePanel("My Great File Selector"),
    
    fluidRow(
        sidebarPanel(
            uiOutput("select.folder"),
            uiOutput('select.file')
        )
    )
)


server <- function(input, output) {
    
    root <- '~'
    
    output$select.folder <-
        renderUI(expr = selectInput(inputId = 'folder.name',
                                    label = 'Folder Name',
                                    choices = list.dirs(path = root,
                                                        full.names = FALSE,
                                                        recursive = FALSE)))
    
    output$select.file <-
        renderUI(expr = selectInput(inputId = 'file.name',
                                    label = 'File Name',
                                    choices = list.files(path = file.path(root,
                                                                          input$folder.name))))
    
}

shinyApp(ui = ui, server = server)

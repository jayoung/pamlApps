library(colourpicker)
library(shiny)
library(shinythemes)
library(markdown) ## without loading the markdown library I was getting a mysterious error when deploying the app to https://jyoungfhcrc.shinyapps.io/pamlApps/ although the app did work within my own Rstudio session. I found the error message in the Logs file via my shiny dashboard.
library(rmarkdown)

source("parseAndPlotPAML_functions.R")

options(shiny.sanitize.errors = FALSE) # so that users on shinyio web version see the 'real' error messages

ui <- fluidPage(
    
    ## some styling stuff
    theme=shinytheme("cerulean"),
    tags$head(
        ## control style of error messages from validation functions
        tags$style(HTML(".shiny-output-error-validation { 
                            color:red; font-size:150% ;   
                            text-align: center;
                            border: 2px solid powderblue;
                            margin: auto;
                        }")),
    ),
    
    ## stuff that's displayed:
    titlePanel("Janet's apps to parse and plot PAML output"),
 
    navbarPage(
        title="Analysis type:",
        
        ### sitewise PAML
        tabPanel(
            "Sites",
            sidebarLayout(
                ##### sitewise PAML control boxes
                sidebarPanel(
                    fluidRow(
                        column(5,h4("Upload rst file:")),
                        column(7,checkboxInput(inputId="sites_useACE2", 
                                               label=h6("or, use ACE2 example file"), 
                                               value=FALSE))),
                    fileInput(inputId="sites_rstFile",label=NULL),
                    hr(),
                    
                    ## options related to downloading the output
                    h4("Generate output files"),
                    downloadButton(outputId="sites_downloadTable", 
                                   label="Save BEB table"),
                    fluidRow(
                        column(5,downloadButton(outputId="sites_downloadPlot", 
                                                label="Save plot")),
                        # this style tag bottom aligns the download button:
                        tags$style(type='text/css', 
                                   "#sites_downloadPlot { width:100%; margin-top: 25px;}"),
                        
                        column(3,numericInput(
                            inputId="sites_plotWidth", 
                            label="width", 
                            value=11)),
                        column(3,numericInput(
                            inputId="sites_plotHeight", 
                            label="height", 
                            value=5))),
                    
                    hr(),
                    
                    ## options related to plot aesthetics
                    h4("Plot options"),
                    textInput(inputId="sites_plotTitle",
                              label="Plot title",
                              value="Site PAML results"),
                    
                    ## which plot type?
                    radioButtons(inputId="sites_plotType", label="Plot type",
                                 choices=list("dN/dS estimates"="omegas",
                                              "BEB probabilities"="probs")),
                    
                    ## options relating to coloring sites with high dN/dS
                    tags$b("Color sites with high probability of positive selection?"),
                    fluidRow(
                        column(4,checkboxInput(inputId="sites_colHigh", 
                                               label="Add color?", 
                                               value=TRUE)),
                        column(4,numericInput(inputId="sites_colHighThreshold", 
                                              label="Probability threshold", 
                                              value=0.9)),
                        column(4,colourInput(inputId="sites_highBEBcolor", 
                                             label=p("Choose color"), 
                                             value="red",
                                             showColour="background",
                                             returnName=TRUE, 
                                             closeOnClick=TRUE))
                    ),
                    
                    ## options relating to adding a threshold line to the probs plot
                    # xx I could perhaps only make these options appear if we select the probs plot - they're not relevant to sites plot
                    conditionalPanel(
                        condition = "input.sites_plotType == 'probs'",
                        tags$b("Add threshold line to probability plot?"),
                        fluidRow(
                            column(4,checkboxInput(inputId="sites_addThresholdLine", 
                                                   label="Add line?", 
                                                   value=TRUE)),
                            column(4,numericInput(inputId="sites_thresholdValue", 
                                                  label="Probability threshold", 
                                                  value=0.9)),
                            column(4,colourInput(inputId="sites_BEBthresholdLineColor", 
                                                 label="Choose color", 
                                                 value="blue",
                                                 showColour="background",
                                                 returnName=TRUE, 
                                                 closeOnClick=TRUE)) ) ),
                    
                ),
                ##### sitewise PAML results
                mainPanel(               
                    plotOutput("sites_plot",height="300px"),
                    includeMarkdown("sites_infoText_for_shiny.md")
                )
            ),
            ## footer
            hr(),
            tags$footer(
                # tags$footer(
                "The code behind this app is available here: ",
                tags$a(
                    "https://github.com/jayoung/pamlApps",
                    href = "https://github.com/jayoung/pamlApps"
                ),
                style = "position: absolute; width: 100%; color: black; text-align: center;"
            )
        ),
        ### branch PAML
        tabPanel(
            "Branches",
            sidebarLayout(
                ### branch PAML controls
                sidebarPanel(
                    fluidRow(
                        column(5,h4("Upload mlc file:")),
                        column(7,checkboxInput(inputId="branches_useACE2", 
                                               label=h6("or, use ACE2 example file"), 
                                               value=FALSE))),
                    fileInput(inputId="branches_mlcFile",label=NULL),
                    hr(),
                    
                    ## options related to downloading the output
                    h4("Generate output files"),
                    fluidRow(
                        column(5,downloadButton(outputId="branches_down", 
                                                label="Save BEB plot")),
                        # this style tag bottom aligns the download button:
                        tags$style(type='text/css', 
                                   "#branches_down { width:100%; margin-top: 25px;}"),
                        column(3,numericInput(inputId="branches_plotWidth", 
                                              label="width", value=11)),
                        column(3,numericInput(inputId="branches_plotHeight", 
                                              label="height", value=7))),
                    hr(),
                    
                    ## options related to plot aesthetics
                    h4("Plot options"),
                    textInput(inputId="branches_plotTitle",
                              label="Plot title",
                              value="Branch PAML results"),
                    tags$b("Font sizes"),
                    fluidRow(
                        column(4,numericInput(inputId="branches_taxLabelSize", 
                                              label="Taxon labels", 
                                              value=0.75)),
                        column(4,numericInput(inputId="branches_branchLabelSize", 
                                              label="Branch labels", 
                                              value=0.5))),
                    
                    ## options relating to coloring branches with high dN/dS
                    tags$b("Color branch labels with high dN/dS?"),
                    fluidRow(
                        column(4,checkboxInput(inputId="branches_colHigh", 
                                               label="Add color?", 
                                               value=TRUE)),
                        column(4,numericInput(inputId="branches_colHighThreshold", 
                                              label="dN/dS threshold", 
                                              value=1)),
                        column(4,numericInput(inputId="branches_colHighThreshold_NdN", 
                                              label="N*dN threshold", 
                                              value=1)),
                        column(4,colourInput(inputId="branches_highOmegaColor", 
                                             label="Choose color", 
                                             value="red",
                                             showColour="background",
                                             returnName=TRUE, 
                                             closeOnClick=TRUE)) )
                ),
                ### branch PAML outputs
                mainPanel(               
                    plotOutput("branches_plot",height="600px"),
                    includeMarkdown("branches_infoText_for_shiny.md")
                )
            ),
            ## footer
            hr(),
            tags$footer(
                # tags$footer(
                "The code behind this app is available here: ",
                tags$a(
                    "https://github.com/jayoung/pamlApps",
                    href = "https://github.com/jayoung/pamlApps"
                ),
                style = "position: absolute; width: 100%; color: black; text-align: center;"
            )
        )
    )
)

server <- function(input, output) {
    
    ###### sitewise PAML server functions
    ## get name of rst file
    rstFilename <- reactive({
        if (input$sites_useACE2) {
            return("data/paml_version_4.10.6/example_ACE2/M8_initOmega0.4_codonModel2/rst")
        } else { return(input$sites_rstFile[1,"datapath"]) }
    })
    
    ### read in the file
    rstParsed <- reactive({
        validate(
            need((!is.null(input$sites_rstFile[1,"datapath"]) | input$sites_useACE2), 
                 "Can't show results until you've selected an rst file") ,
            need(!(!is.null(input$sites_rstFile[1,"datapath"]) & input$sites_useACE2), 
                 "You've uploaded an rst file AND selected that you want to use the ACE2 example file - can't do both")
        )
        parseRSTfile(rstFilename())
    })
    
    ### make the plot - should update when a new file is uploaded.
    # I use a separate function to render it, so I can use it within the app AND when saving a pdf file
    myOmegaPlot <- function(){
        parsedRst <- rstParsed()
        par(oma=c(1,0,0,0))
        plotOmegas(parsedRst, 
                   title=input$sites_plotTitle, 
                   highlightHighBEB=input$sites_colHigh, 
                   highBEBthreshold=input$sites_colHighThreshold, 
                   highBEBcolor=input$sites_highBEBcolor)
    }
    myProbPlot <- function(){
        parsedRst <- rstParsed()
        par(oma=c(1,0,0,0))
        plotProbs(parsedRst, barCol="grey",
                  title=input$sites_plotTitle, 
                  addThresholdLine=input$sites_addThresholdLine, 
                  threshold=input$sites_thresholdValue, 
                  thresholdLineColor=input$sites_BEBthresholdLineColor,
                  highlightHighBEB=input$sites_colHigh, 
                  highBEBthreshold=input$sites_colHighThreshold, 
                  highBEBcolor=input$sites_highBEBcolor)
    }
    output$sites_plot <- renderPlot({ 
        if(input$sites_plotType == "omegas") { return( myOmegaPlot() ) }
        if(input$sites_plotType == "probs") { return( myProbPlot() ) }
    })  
    
    ### save the image as a pdf file
    output$sites_downloadPlot <- downloadHandler(
        filename= function() { 
            if(input$sites_plotType == "omegas") { return("dNdS_plot.pdf") }
            if(input$sites_plotType == "probs") { return("BEBprobability_plot.pdf") }
        }, ## default output file name, but user gets to change it
        content=function(file) {
            pdf(file, width=input$sites_plotWidth, height=input$sites_plotHeight) 
            if(input$sites_plotType == "omegas") { myOmegaPlot() }
            if(input$sites_plotType == "probs") { myProbPlot() }
            dev.off()  
        } 
    )
    
    ### save the image as a pdf file
    output$sites_downloadTable <- downloadHandler(
        filename= function() { "BEBtable.csv" }, ## default output file name, but user gets to change it
        content=function(file) {
            parsedRst <- rstParsed()
            write.csv(parsedRst, file=file, row.names=FALSE, quote=FALSE)  
        } 
    )
    
    ######## branch PAML server functions
    
    ## get name of mlc file
    mlcFilename <- reactive({
        if (input$branches_useACE2) {
            return("data/paml_version_4.10.6/example_ACE2/BRANCHpaml_initOmega0.4_codonModel2/mlc")
        } else { return(input$branches_mlcFile[1,"datapath"]) }
    })
    
    ### read in the file
    mlcParsed <- reactive({
        validate(
            need((!is.null(input$branches_mlcFile[1,"datapath"]) | input$branches_useACE2), 
                 "Can't show results until you've selected an mlc file")
        )
        parseMLCbranches(mlcFilename())
    })
    
    ### make the plot - should update when a new file is uploaded.
    # I use a separate function to render it, so I can use it within the app AND when saving a pdf file
    myTreePlot <- function(){
        parsedMLC <- mlcParsed()
        plotTree(phymlTree=parsedMLC[["tree"]], 
                 mlcTable=parsedMLC[["table"]], 
                 labelType="omega_NS",
                 myTitle=input$branches_plotTitle, 
                 colorHighOmega=input$branches_colHigh, 
                 colorHighOmegaThreshold=input$branches_colHighThreshold, 
                 colorHighOmegaThresholdNxN=input$branches_colHighThreshold_NdN,
                 branchLabelFontSize=input$branches_branchLabelSize, 
                 taxonLabelFontSize=input$branches_taxLabelSize,
                 highOmegaColor=input$branches_highOmegaColor)
    }
    output$branches_plot <- renderPlot({ 
        myTreePlot() 
    })  
    
    ### save the image as a pdf file
    output$branches_down <- downloadHandler(
        filename=function() { "branchPAMLresults.pdf" }, ## default output file name, but user gets to change it
        # downloadHandler uses a function called 'content' that actually does the work
        content=function(file) {
            pdf(file, width=input$branches_plotWidth, height=input$branches_plotHeight) 
            myTreePlot() 
            dev.off()  
        } 
    )
}

# Run the application within Rstudio
shinyApp(ui=ui, server=server)

# Run in a browser window instead (opens in Chrome - looks a bit nicer to me).  Unclear if it will still deploy OK.
#runGadget(ui, server, viewer=browserViewer(browser=getOption("browser")))

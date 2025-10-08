library(shiny)
library(DRpipe)
library(shinydashboard)
library(DT)
library(plotly)
library(tidyverse)
library(yaml)
library(shinyjs)

# UI Definition
ui <- dashboardPage(
  dashboardHeader(title = "Drug Repurposing Pipeline"),
  
  dashboardSidebar(
    sidebarMenu(id = "sidebar",
      menuItem("Home", tabName = "home", icon = icon("home")),
      menuItem("1. Upload Data", tabName = "upload", icon = icon("upload")),
      menuItem("2. Configure", tabName = "config", icon = icon("cog")),
      menuItem("3. Run Analysis", tabName = "analysis", icon = icon("play")),
      menuItem("4. Results", tabName = "results", icon = icon("table")),
      menuItem("Help", tabName = "help", icon = icon("question-circle"))
    )
  ),
  
  dashboardBody(
    useShinyjs(),
    
    tabItems(
      # Home Tab
      tabItem(tabName = "home",
        fluidRow(
          box(
            title = "Welcome to Drug Repurposing Pipeline",
            width = 12,
            status = "primary",
            solidHeader = TRUE,
            h3("About This Application"),
            p("This application identifies existing drugs that could be repurposed for new therapeutic applications."),
            
            h4("Workflow:"),
            tags$ol(
              tags$li("Upload your disease gene expression signature"),
              tags$li("Configure analysis parameters (including sweep mode options)"),
              tags$li("Run the analysis"),
              tags$li("View and download results")
            ),
            
            hr(),
            actionButton("startBtn", "Start Analysis →", 
                        class = "btn-success btn-lg", 
                        icon = icon("play-circle"))
          )
        )
      ),
      
      # Upload Data Tab
      tabItem(tabName = "upload",
        fluidRow(
          box(
            title = "Step 1: Upload Disease Expression Data",
            width = 12,
            status = "primary",
            solidHeader = TRUE
          )
        ),
        
        fluidRow(
          box(
            title = "Upload Data",
            width = 6,
            status = "info",
            solidHeader = TRUE,
            fileInput("diseaseFile", "Choose CSV File",
                     accept = c("text/csv", ".csv")),
            hr(),
            h4("Or Load Example Data:"),
            actionButton("loadFibroid", "Load Fibroid Example", 
                        class = "btn-info", icon = icon("download")),
            actionButton("loadEndothelial", "Load Endothelial Example", 
                        class = "btn-info", icon = icon("download"))
          ),
          
          box(
            title = "Data Requirements",
            width = 6,
            status = "warning",
            solidHeader = TRUE,
            h4("Required Columns:"),
            tags$ul(
              tags$li("Gene identifier (e.g., SYMBOL, ENSEMBL)"),
              tags$li("Log2 fold-change values")
            ),
            h4("Optional:"),
            tags$ul(
              tags$li("P-values or adjusted p-values")
            )
          )
        ),
        
        fluidRow(
          box(
            title = "Data Preview",
            width = 12,
            status = "success",
            solidHeader = TRUE,
            DTOutput("dataPreview"),
            br(),
            actionButton("confirmDataBtn", "Confirm & Continue →", 
                        class = "btn-primary btn-lg")
          )
        )
      ),
      
      # Configuration Tab
      tabItem(tabName = "config",
        fluidRow(
          box(
            title = "Step 2: Configure Analysis Parameters",
            width = 12,
            status = "primary",
            solidHeader = TRUE
          )
        ),
        
        fluidRow(
          box(
            title = "Basic Settings",
            width = 6,
            status = "info",
            solidHeader = TRUE,
            selectInput("geneKey", "Gene Column:", choices = NULL),
            textInput("logfcPrefix", "Log2FC Column Prefix:", value = "log2FC"),
            numericInput("logfcCutoff", "Log2FC Cutoff:", value = 1.0, min = 0, step = 0.1),
            selectInput("pvalKey", "P-value Column (optional):", choices = c("None" = "")),
            numericInput("pvalCutoff", "P-value Cutoff:", value = 0.05, min = 0, max = 1, step = 0.01),
            numericInput("qThresh", "Q-value Threshold:", value = 0.05, min = 0, max = 1, step = 0.01),
            checkboxInput("reversalOnly", "Reversal Only", value = TRUE)
          ),
          
          box(
            title = "Analysis Mode",
            width = 6,
            status = "warning",
            solidHeader = TRUE,
            selectInput("analysisMode", "Mode:", 
                       choices = c("Single Cutoff" = "single", "Sweep Mode" = "sweep"),
                       selected = "single"),
            
            conditionalPanel(
              condition = "input.analysisMode == 'sweep'",
              h4("Sweep Mode Settings"),
              checkboxInput("sweepAutoGrid", "Auto-generate threshold grid", value = TRUE),
              numericInput("sweepStep", "Step size:", value = 0.1, min = 0.05, step = 0.05),
              numericInput("sweepMinFrac", "Min fraction of genes:", value = 0.20, min = 0.05, max = 1, step = 0.05),
              numericInput("sweepMinGenes", "Min number of genes:", value = 200, min = 50, step = 50),
              checkboxInput("sweepStopOnSmall", "Stop if signature too small", value = FALSE),
              selectInput("combineLogFC", "Combine log2FC columns:", 
                         choices = c("Average" = "average", "Median" = "median", "First" = "first"),
                         selected = "average"),
              selectInput("robustRule", "Robust drug rule:", 
                         choices = c("All cutoffs" = "all", "K of N cutoffs" = "k_of_n"),
                         selected = "all"),
              conditionalPanel(
                condition = "input.robustRule == 'k_of_n'",
                numericInput("robustK", "Minimum cutoffs (k):", value = 2, min = 1, step = 1)
              ),
              selectInput("aggregate", "Score aggregation:", 
                         choices = c("Mean" = "mean", "Median" = "median"),
                         selected = "mean")
            ),
            
            numericInput("seed", "Random Seed:", value = 123, min = 1, step = 1)
          )
        ),
        
        fluidRow(
          box(
            title = "Configuration Summary",
            width = 12,
            status = "success",
            solidHeader = TRUE,
            verbatimTextOutput("configSummary"),
            br(),
            actionButton("proceedBtn", "Proceed to Analysis →", 
                        class = "btn-success btn-lg")
          )
        )
      ),
      
      # Analysis Tab
      tabItem(tabName = "analysis",
        fluidRow(
          box(
            title = "Step 3: Run Analysis",
            width = 12,
            status = "primary",
            solidHeader = TRUE,
            actionButton("runBtn", "Run Analysis", 
                        class = "btn-success btn-lg", 
                        icon = icon("play-circle")),
            hr(),
            h4("Progress:"),
            verbatimTextOutput("analysisLog")
          )
        )
      ),
      
      # Results Tab
      tabItem(tabName = "results",
        fluidRow(
          box(
            title = "Step 4: Analysis Results",
            width = 12,
            status = "primary",
            solidHeader = TRUE
          )
        ),
        
        fluidRow(
          valueBoxOutput("totalHitsBox"),
          valueBoxOutput("topDrugBox"),
          valueBoxOutput("medianQBox")
        ),
        
        fluidRow(
          box(
            title = "Significant Drug Hits",
            width = 12,
            status = "success",
            solidHeader = TRUE,
            downloadButton("downloadResults", "Download Results CSV"),
            hr(),
            DTOutput("resultsTable")
          )
        ),
        
        fluidRow(
          box(
            title = "Top Drugs Visualization",
            width = 12,
            status = "info",
            solidHeader = TRUE,
            sliderInput("topN", "Number of drugs:", min = 5, max = 30, value = 15),
            plotlyOutput("topDrugsPlot", height = "500px")
          )
        )
      ),
      
      # Help Tab
      tabItem(tabName = "help",
        fluidRow(
          box(
            title = "User Guide",
            width = 12,
            status = "info",
            solidHeader = TRUE,
            
            h3("Quick Start"),
            tags$ol(
              tags$li("Upload your disease gene expression CSV file"),
              tags$li("Configure parameters (or use defaults)"),
              tags$li("Choose Single or Sweep mode"),
              tags$li("Run analysis and view results")
            ),
            
            hr(),
            
            h3("Sweep Mode"),
            p("Sweep mode tests multiple log2FC thresholds to identify robust drug candidates."),
            h4("Key Parameters:"),
            tags$ul(
              tags$li(strong("Auto-grid:"), " Automatically generate threshold grid from data"),
              tags$li(strong("Step size:"), " Spacing between thresholds (e.g., 0.1 = 0.5, 0.6, 0.7...)"),
              tags$li(strong("Min fraction:"), " Minimum % of genes required at each threshold"),
              tags$li(strong("Min genes:"), " Minimum absolute number of genes required"),
              tags$li(strong("Robust rule:"), " How to determine robust drugs across thresholds"),
              tags$li(strong("Aggregation:"), " How to combine scores across thresholds")
            )
          )
        )
      )
    )
  )
)

# Server Definition
server <- function(input, output, session) {
  # Reactive values
  values <- reactiveValues(
    data = NULL,
    results = NULL,
    drugs_valid = NULL,
    analysisLog = ""
  )
  
  # Navigation buttons
  observeEvent(input$startBtn, {
    updateTabItems(session, "sidebar", "upload")
  })
  
  observeEvent(input$confirmDataBtn, {
    req(values$data)
    updateTabItems(session, "sidebar", "config")
  })
  
  observeEvent(input$proceedBtn, {
    updateTabItems(session, "sidebar", "analysis")
  })
  
  # Load example data
  observeEvent(input$loadFibroid, {
    tryCatch({
      path <- "../scripts/data/CoreFibroidSignature_All_Datasets.csv"
      if (file.exists(path)) {
        values$data <- read.csv(path, stringsAsFactors = FALSE, check.names = FALSE)
        updateSelectInput(session, "geneKey", choices = names(values$data), selected = "SYMBOL")
        updateSelectInput(session, "pvalKey", choices = c("None" = "", names(values$data)))
        showNotification("Fibroid data loaded!", type = "message")
      }
    }, error = function(e) {
      showNotification(paste("Error:", e$message), type = "error")
    })
  })
  
  observeEvent(input$loadEndothelial, {
    tryCatch({
      path <- "../scripts/data/Endothelia_DEG.csv"
      if (file.exists(path)) {
        values$data <- read.csv(path, stringsAsFactors = FALSE, check.names = FALSE)
        updateSelectInput(session, "geneKey", choices = names(values$data), selected = "SYMBOL")
        updateSelectInput(session, "pvalKey", choices = c("None" = "", names(values$data)))
        showNotification("Endothelial data loaded!", type = "message")
      }
    }, error = function(e) {
      showNotification(paste("Error:", e$message), type = "error")
    })
  })
  
  # File upload
  observeEvent(input$diseaseFile, {
    req(input$diseaseFile)
    tryCatch({
      values$data <- read.csv(input$diseaseFile$datapath, stringsAsFactors = FALSE, check.names = FALSE)
      updateSelectInput(session, "geneKey", choices = names(values$data))
      updateSelectInput(session, "pvalKey", choices = c("None" = "", names(values$data)))
      showNotification("Data uploaded!", type = "message")
    }, error = function(e) {
      showNotification(paste("Error:", e$message), type = "error")
    })
  })
  
  # Data preview
  output$dataPreview <- renderDT({
    req(values$data)
    datatable(head(values$data, 100), options = list(scrollX = TRUE, pageLength = 10))
  })
  
  # Configuration summary
  output$configSummary <- renderPrint({
    req(values$data)
    cat("Configuration:\n")
    cat("  Gene Column:", input$geneKey, "\n")
    cat("  Log2FC Prefix:", input$logfcPrefix, "\n")
    cat("  Log2FC Cutoff:", input$logfcCutoff, "\n")
    cat("  Mode:", input$analysisMode, "\n")
    if (input$analysisMode == "sweep") {
      cat("\nSweep Settings:\n")
      cat("  Auto-grid:", input$sweepAutoGrid, "\n")
      cat("  Step size:", input$sweepStep, "\n")
      cat("  Min fraction:", input$sweepMinFrac, "\n")
      cat("  Min genes:", input$sweepMinGenes, "\n")
      cat("  Robust rule:", input$robustRule, "\n")
      if (input$robustRule == "k_of_n") {
        cat("  Robust k:", input$robustK, "\n")
      }
      cat("  Aggregation:", input$aggregate, "\n")
    }
  })
  
  # Run analysis
  observeEvent(input$runBtn, {
    req(values$data)
    
    values$analysisLog <- ""
    
    temp_file <- tempfile(fileext = ".csv")
    write.csv(values$data, temp_file, row.names = FALSE)
    
    withProgress(message = 'Running analysis...', value = 0, {
      tryCatch({
        values$analysisLog <- paste0(values$analysisLog, "Initializing...\n")
        incProgress(0.1)
        
        # Prepare parameters
        pval_key_val <- if(input$pvalKey == "") NULL else input$pvalKey
        robust_k_val <- if(input$robustRule == "k_of_n") input$robustK else NULL
        
        drp <- DRP$new(
          signatures_rdata = "../scripts/data/cmap_signatures.RData",
          disease_path = temp_file,
          cmap_meta_path = "../scripts/data/cmap_drug_experiments_new.csv",
          cmap_valid_path = "../scripts/data/cmap_valid_instances.csv",
          out_dir = tempdir(),
          gene_key = input$geneKey,
          logfc_cols_pref = input$logfcPrefix,
          logfc_cutoff = input$logfcCutoff,
          pval_key = pval_key_val,
          pval_cutoff = input$pvalCutoff,
          q_thresh = input$qThresh,
          reversal_only = input$reversalOnly,
          seed = input$seed,
          mode = input$analysisMode,
          sweep_auto_grid = input$sweepAutoGrid,
          sweep_step = input$sweepStep,
          sweep_min_frac = input$sweepMinFrac,
          sweep_min_genes = input$sweepMinGenes,
          sweep_stop_on_small = input$sweepStopOnSmall,
          combine_log2fc = input$combineLogFC,
          robust_rule = input$robustRule,
          robust_k = robust_k_val,
          aggregate = input$aggregate,
          verbose = TRUE
        )
        
        values$analysisLog <- paste0(values$analysisLog, "Loading CMap...\n")
        incProgress(0.2)
        drp$load_cmap()
        
        values$analysisLog <- paste0(values$analysisLog, "Loading disease signature...\n")
        incProgress(0.1)
        drp$load_disease()
        
        values$analysisLog <- paste0(values$analysisLog, "Cleaning signature...\n")
        incProgress(0.1)
        drp$clean_signature()
        
        values$analysisLog <- paste0(values$analysisLog, "Computing scores...\n")
        incProgress(0.3)
        if (drp$mode == "single") {
          drp$run_single()
        } else {
          drp$run_sweep()
        }
        
        values$analysisLog <- paste0(values$analysisLog, "Annotating results...\n")
        incProgress(0.2)
        drp$annotate_and_filter()
        
        values$results <- drp$drugs
        values$drugs_valid <- drp$drugs_valid
        
        values$analysisLog <- paste0(values$analysisLog, "\nComplete! Found ", 
                                     nrow(drp$drugs_valid), " significant hits.\n")
        
        showNotification("Analysis complete!", type = "message")
        updateTabItems(session, "sidebar", "results")
        
      }, error = function(e) {
        values$analysisLog <- paste0(values$analysisLog, "\nERROR: ", e$message, "\n")
        showNotification(paste("Error:", e$message), type = "error")
      })
    })
    
    unlink(temp_file)
  })
  
  # Analysis log
  output$analysisLog <- renderPrint({
    cat(values$analysisLog)
  })
  
  # Value boxes
  output$totalHitsBox <- renderValueBox({
    hits <- if (!is.null(values$drugs_valid)) nrow(values$drugs_valid) else 0
    valueBox(hits, "Significant Hits", icon = icon("pills"), 
            color = if(hits > 0) "green" else "red")
  })
  
  output$topDrugBox <- renderValueBox({
    top <- if (!is.null(values$drugs_valid) && nrow(values$drugs_valid) > 0) {
      values$drugs_valid$name[1]
    } else "None"
    valueBox(top, "Top Drug", icon = icon("star"), color = "blue")
  })
  
  output$medianQBox <- renderValueBox({
    med_q <- if (!is.null(values$drugs_valid) && nrow(values$drugs_valid) > 0) {
      round(median(values$drugs_valid$q, na.rm = TRUE), 4)
    } else "N/A"
    valueBox(med_q, "Median Q-value", icon = icon("chart-line"), color = "purple")
  })
  
  # Results table
  output$resultsTable <- renderDT({
    req(values$drugs_valid)
    datatable(values$drugs_valid, options = list(scrollX = TRUE, pageLength = 25), filter = 'top')
  })
  
  # Top drugs plot
  output$topDrugsPlot <- renderPlotly({
    req(values$drugs_valid)
    n <- min(input$topN, nrow(values$drugs_valid))
    top <- head(values$drugs_valid, n)
    
    plot_ly(data = top, y = ~reorder(name, cmap_score), x = ~cmap_score,
            type = "bar", orientation = "h",
            marker = list(color = ~cmap_score, colorscale = "RdBu")) %>%
      layout(title = paste("Top", n, "Drugs"), xaxis = list(title = "CMap Score"),
             yaxis = list(title = ""), margin = list(l = 150))
  })
  
  # Download handler
  output$downloadResults <- downloadHandler(
    filename = function() {
      paste("drug_results_", Sys.Date(), ".csv", sep = "")
    },
    content = function(file) {
      req(values$drugs_valid)
      write.csv(values$drugs_valid, file, row.names = FALSE)
    }
  )
}

# Run app
shinyApp(ui = ui, server = server)

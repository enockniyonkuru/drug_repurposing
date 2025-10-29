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
      menuItem("1. Choose Analysis Type", tabName = "choose_type", icon = icon("route")),
      menuItem("2. Upload Data", tabName = "upload", icon = icon("upload")),
      menuItem("3. Configure", tabName = "config", icon = icon("cog")),
      menuItem("4. Run Analysis", tabName = "analysis", icon = icon("play")),
      menuItem("5. Results", tabName = "results", icon = icon("table")),
      menuItem("6. Visualizations", tabName = "plots", icon = icon("chart-bar")),
      menuItem("7. Sweep Results", tabName = "sweep_results", icon = icon("layer-group")),
      menuItem("Help", tabName = "help", icon = icon("question-circle"))
    )
  ),
  
  dashboardBody(
    useShinyjs(),
    tags$head(
      tags$style(HTML("
        .analysis-type-card {
          border: 2px solid #ddd;
          border-radius: 10px;
          padding: 30px;
          margin: 20px 0;
          cursor: pointer;
          transition: all 0.3s;
          background-color: #fff;
        }
        .analysis-type-card:hover {
          border-color: #3c8dbc;
          box-shadow: 0 4px 8px rgba(0,0,0,0.1);
          transform: translateY(-2px);
        }
        .analysis-type-card.selected {
          border-color: #00a65a;
          background-color: #e8f5e9;
          box-shadow: 0 4px 12px rgba(0,166,90,0.2);
        }
        .profile-card {
          border: 1px solid #ddd;
          border-radius: 5px;
          padding: 15px;
          margin: 10px 0;
          background-color: #f9f9f9;
          cursor: pointer;
          transition: all 0.2s;
        }
        .profile-card:hover {
          background-color: #e3f2fd;
          border-color: #2196F3;
        }
        .profile-card.selected {
          background-color: #c8e6c9;
          border-color: #4CAF50;
          border-width: 2px;
        }
      "))
    ),
    
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
              tags$li(strong("Choose Analysis Type:"), " Select Single or Comparative analysis"),
              tags$li(strong("Upload Data:"), " Upload your disease gene expression signature"),
              tags$li(strong("Configure:"), " Select profile(s) and customize parameters (including sweep mode)"),
              tags$li(strong("Run Analysis:"), " Execute the pipeline"),
              tags$li(strong("View Results:"), " Explore drug candidates and visualizations"),
              tags$li(strong("Sweep Results:"), " View sweep mode specific results and plots (if applicable)")
            ),
            
            h4("Analysis Types:"),
            tags$ul(
              tags$li(strong("Single Analysis:"), " Run with one configuration to identify drug candidates"),
              tags$li(strong("Comparative Analysis:"), " Compare multiple configurations to find robust candidates")
            ),
            
            hr(),
            actionButton("startBtn", "Start Analysis →", 
                        class = "btn-success btn-lg", 
                        icon = icon("play-circle"))
          )
        )
      ),
      
      # Choose Analysis Type Tab
      tabItem(tabName = "choose_type",
        fluidRow(
          box(
            title = "Step 1: Choose Your Analysis Type",
            width = 12,
            status = "primary",
            solidHeader = TRUE,
            h4("Select the type of analysis you want to perform:")
          )
        ),
        
        fluidRow(
          column(6,
            div(id = "singleAnalysisCard", class = "analysis-type-card",
              onclick = "Shiny.setInputValue('analysisTypeClick', 'single', {priority: 'event'});",
              div(style = "text-align: center;",
                icon("flask", class = "fa-4x", style = "color: #3c8dbc;"),
                h3("Single Analysis"),
                p(style = "font-size: 16px; margin-top: 15px;",
                  "Run analysis with ONE configuration profile."
                ),
                tags$ul(style = "text-align: left; margin-top: 20px;",
                  tags$li("Choose or create one analysis profile"),
                  tags$li("Full sweep mode customization available"),
                  tags$li("Faster execution time"),
                  tags$li("Ideal for initial exploration")
                )
              )
            )
          ),
          
          column(6,
            div(id = "comparativeAnalysisCard", class = "analysis-type-card",
              onclick = "Shiny.setInputValue('analysisTypeClick', 'comparative', {priority: 'event'});",
              div(style = "text-align: center;",
                icon("balance-scale", class = "fa-4x", style = "color: #00a65a;"),
                h3("Comparative Analysis"),
                p(style = "font-size: 16px; margin-top: 15px;",
                  "Compare results across MULTIPLE configuration profiles."
                ),
                tags$ul(style = "text-align: left; margin-top: 20px;",
                  tags$li("Select multiple analysis profiles"),
                  tags$li("Compare results side-by-side"),
                  tags$li("Identify robust drug candidates"),
                  tags$li("More comprehensive analysis")
                )
              )
            )
          )
        ),
        
        fluidRow(
          box(
            title = "Selected Analysis Type",
            width = 12,
            status = "info",
            solidHeader = TRUE,
            uiOutput("selectedAnalysisType"),
            br(),
            actionButton("confirmAnalysisType", "Confirm & Continue →", 
                        class = "btn-primary btn-lg")
          )
        )
      ),
      
      # Upload Data Tab
      tabItem(tabName = "upload",
        fluidRow(
          box(
            title = "Step 2: Upload Disease Expression Data",
            width = 12,
            status = "primary",
            solidHeader = TRUE,
            uiOutput("analysisTypeReminder")
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
      
      # Configuration Tab (keeping existing configuration UI)
      tabItem(tabName = "config",
        fluidRow(
          box(
            title = "Step 3: Configure Analysis Parameters",
            width = 12,
            status = "primary",
            solidHeader = TRUE,
            uiOutput("configInstructions")
          )
        ),
        
        uiOutput("configurationUI"),
        
        fluidRow(
          box(
            title = "Configuration Summary",
            width = 12,
            status = "success",
            solidHeader = TRUE,
            uiOutput("configSummary"),
            br(),
            actionButton("proceedBtn", "Proceed to Analysis →", 
                        class = "btn-success btn-lg")
          )
        )
      ),
      
      # Analysis Tab (keeping existing)
      tabItem(tabName = "analysis",
        fluidRow(
          box(
            title = "Step 4: Run Analysis",
            width = 12,
            status = "primary",
            solidHeader = TRUE,
            uiOutput("analysisHeader"),
            hr(),
            actionButton("runBtn", "Run Analysis", 
                        class = "btn-success btn-lg", 
                        icon = icon("play-circle")),
            hr(),
            h4("Progress:"),
            verbatimTextOutput("analysisLog")
          )
        )
      ),
      
      # Results Tab (keeping existing)
      tabItem(tabName = "results",
        fluidRow(
          box(
            title = "Step 5: Analysis Results",
            width = 12,
            status = "primary",
            solidHeader = TRUE,
            uiOutput("resultsHeader")
          )
        ),
        
        uiOutput("resultsUI")
      ),
      
      # Visualizations Tab (keeping existing)
      tabItem(tabName = "plots",
        fluidRow(
          box(
            title = "Step 6: Visualizations",
            width = 12,
            status = "primary",
            solidHeader = TRUE,
            uiOutput("plotsHeader")
          )
        ),
        
        uiOutput("plotsUI")
      ),
      
      # NEW: Sweep Results Tab
      tabItem(tabName = "sweep_results",
        fluidRow(
          box(
            title = "Step 7: Sweep Mode Results",
            width = 12,
            status = "primary",
            solidHeader = TRUE,
            uiOutput("sweepResultsHeader")
          )
        ),
        
        uiOutput("sweepResultsUI")
      ),
      
      # Help Tab (keeping existing)
      tabItem(tabName = "help",
        fluidRow(
          box(
            title = "User Guide",
            width = 12,
            status = "info",
            solidHeader = TRUE,
            
            h3("Quick Start"),
            tags$ol(
              tags$li("Choose analysis type (Single or Comparative)"),
              tags$li("Upload your disease gene expression CSV file"),
              tags$li("Configure parameters (or use defaults)"),
              tags$li("Run analysis and view results"),
              tags$li("If using sweep mode, check the Sweep Results tab for detailed visualizations")
            ),
            
            hr(),
            
            h3("Sweep Mode"),
            p("Sweep mode tests multiple log2FC thresholds to identify robust drug candidates."),
            h4("Key Parameters:"),
            tags$ul(
              tags$li(strong("Auto-grid:"), " Automatically generate threshold grid from data"),
              tags$li(strong("Step size:"), " Spacing between thresholds (e.g., 0.1)"),
              tags$li(strong("Min fraction:"), " Minimum % of genes required at each threshold"),
              tags$li(strong("Min genes:"), " Minimum absolute number of genes required"),
              tags$li(strong("Robust rule:"), " How to determine robust drugs across thresholds"),
              tags$li(strong("Aggregation:"), " How to combine scores across thresholds")
            ),
            
            hr(),
            
            h3("Sweep Results Tab"),
            p("When running in sweep mode, the Sweep Results tab provides:"),
            tags$ul(
              tags$li("Robust hits table - drugs that passed the robust filtering criteria"),
              tags$li("Cutoff summary - performance metrics for each threshold tested"),
              tags$li("Sweep-specific visualizations - plots showing results across thresholds"),
              tags$li("Generated plot images from the analysis")
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
    analysis_type = NULL,
    data = NULL,
    selected_profiles = list(),
    results = NULL,
    drugs_valid = NULL,
    analysisLog = "",
    config_profiles = list(),
    comparison_results = list(),
    drug_signatures = list(
      "OG - CMAP" = "../scripts/data/cmap_signatures.RData",
      "Filtered CMAP" = "../scripts/data/drug_rep_cmap_ranks_shared_genes_drugs.RData",
      "Filtered TAHOE" = "../scripts/data/drug_rep_tahoe_ranks_shared_genes_drugs.RData"
    ),
    selected_drug_signature = "../scripts/data/cmap_signatures.RData",
    # NEW: Sweep mode specific results
    drp_object = NULL,
    is_sweep_mode = FALSE,
    sweep_robust_hits = NULL,
    sweep_cutoff_summary = NULL,
    sweep_img_dir = NULL
  )
  
  # Load configuration profiles on startup
  observe({
    tryCatch({
      config_path <- "../scripts/config.yml"
      if (file.exists(config_path)) {
        config_data <- yaml::read_yaml(config_path)
        profile_names <- setdiff(names(config_data), c("execution", "default"))
        if (length(profile_names) > 0) {
          values$config_profiles <- config_data[profile_names]
        }
      }
    }, error = function(e) {
      showNotification(paste("Warning: Could not load config.yml:", e$message), type = "warning")
    })
  })
  
  # Observer for drug signature selection (single analysis)
  observeEvent(input$drugSignatureChoice, {
    req(input$drugSignatureChoice)
    signature_map <- list(
      og_cmap = "../scripts/data/cmap_signatures.RData",
      filtered_cmap = "../scripts/data/drug_rep_cmap_ranks_shared_genes_drugs.RData",
      filtered_tahoe = "../scripts/data/drug_rep_tahoe_ranks_shared_genes_drugs.RData"
    )
    values$selected_drug_signature <- signature_map[[input$drugSignatureChoice]]
  })
  
  # Observer for drug signature selection (comparative analysis)
  observeEvent(input$compDrugSignatureChoice, {
    req(input$compDrugSignatureChoice)
    signature_map <- list(
      og_cmap = "../scripts/data/cmap_signatures.RData",
      filtered_cmap = "../scripts/data/drug_rep_cmap_ranks_shared_genes_drugs.RData",
      filtered_tahoe = "../scripts/data/drug_rep_tahoe_ranks_shared_genes_drugs.RData"
    )
    values$selected_drug_signature <- signature_map[[input$compDrugSignatureChoice]]
  })
  
  # Navigation buttons
  observeEvent(input$startBtn, {
    updateTabItems(session, "sidebar", "choose_type")
  })
  
  observeEvent(input$confirmDataBtn, {
    req(values$data)
    updateTabItems(session, "sidebar", "config")
  })
  
  observeEvent(input$proceedBtn, {
    updateTabItems(session, "sidebar", "analysis")
  })
  
  # Handle analysis type selection
  observeEvent(input$analysisTypeClick, {
    values$analysis_type <- input$analysisTypeClick
    
    if (input$analysisTypeClick == "single") {
      runjs("$('#singleAnalysisCard').addClass('selected'); $('#comparativeAnalysisCard').removeClass('selected');")
    } else {
      runjs("$('#comparativeAnalysisCard').addClass('selected'); $('#singleAnalysisCard').removeClass('selected');")
    }
  })
  
  # Render selected analysis type
  output$selectedAnalysisType <- renderUI({
    if (is.null(values$analysis_type)) {
      return(p(style = "color: #999; font-style: italic;", 
              icon("info-circle"), " Please select an analysis type above"))
    }
    
    type_text <- if (values$analysis_type == "single") {
      "Single Analysis - Run with one configuration profile"
    } else {
      "Comparative Analysis - Compare multiple configuration profiles"
    }
    
    tags$div(
      style = "background-color: #d4edda; padding: 15px; border-radius: 5px; border-left: 4px solid #28a745;",
      h4(icon("check-circle", style = "color: #28a745;"), " Selected:"),
      p(style = "font-size: 18px; margin: 10px 0;", strong(type_text))
    )
  })
  
  # Confirm analysis type
  observeEvent(input$confirmAnalysisType, {
    req(values$analysis_type)
    updateTabItems(session, "sidebar", "upload")
    showNotification(paste("Analysis type set to:", 
                          ifelse(values$analysis_type == "single", "Single Analysis", "Comparative Analysis")), 
                    type = "message")
  })
  
  # Analysis type reminder
  output$analysisTypeReminder <- renderUI({
    if (is.null(values$analysis_type)) {
      return(tags$div(
        style = "background-color: #fff3cd; padding: 15px; border-radius: 5px;",
        p(icon("exclamation-triangle"), strong(" Please select an analysis type first in Step 1"))
      ))
    }
    
    type_text <- ifelse(values$analysis_type == "single", "Single Analysis", "Comparative Analysis")
    tags$div(
      style = "background-color: #d1ecf1; padding: 10px; border-radius: 5px;",
      p(icon("info-circle"), strong(" Analysis Type: "), type_text)
    )
  })
  
  # Load example data
  observeEvent(input$loadFibroid, {
    tryCatch({
      path <- "../scripts/data/CoreFibroidSignature_All_Datasets.csv"
      if (file.exists(path)) {
        values$data <- read.csv(path, stringsAsFactors = FALSE, check.names = FALSE)
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
  
  # Configuration instructions
  output$configInstructions <- renderUI({
    if (is.null(values$analysis_type)) {
      return(p("Please complete Step 1 first."))
    }
    
    if (values$analysis_type == "single") {
      p(icon("flask"), strong(" Single Analysis Mode - "), "Select ONE profile or create custom settings")
    } else {
      p(icon("balance-scale"), strong(" Comparative Analysis Mode - "), "Select MULTIPLE profiles to compare")
    }
  })
  
  # Dynamic configuration UI (keeping existing implementation)
  output$configurationUI <- renderUI({
    req(values$analysis_type)
    
    if (values$analysis_type == "single") {
      # Single analysis configuration
      fluidRow(
        box(
          title = "Select or Create Profile",
          width = 12,
          status = "warning",
          solidHeader = TRUE,
          
          # Existing profiles selection
          conditionalPanel(
            condition = "output.hasExistingProfiles",
            h4("Select Existing Profile"),
            selectInput("selectedExistingProfile", 
                       "Choose a profile:",
                       choices = c("Create Custom..." = "custom", 
                                 if(length(values$config_profiles) > 0) {
                                   setNames(names(values$config_profiles), names(values$config_profiles))
                                 }),
                       selected = "custom"),
            hr()
          ),
          
          # Custom profile creation (shown when "Create Custom..." is selected)
          conditionalPanel(
            condition = "input.selectedExistingProfile == 'custom' || !output.hasExistingProfiles",
            h4("Create Custom Profile"),
            textInput("customProfileName", "Profile Name:", value = "my_custom_profile"),
          
          h4("Drug Signature Selection"),
          selectInput("drugSignatureChoice", "Choose Drug Signature:",
                     choices = c("OG - CMAP" = "og_cmap",
                               "Filtered CMAP" = "filtered_cmap", 
                               "Filtered TAHOE" = "filtered_tahoe"),
                     selected = "og_cmap"),
          p(style = "color: #666; font-size: 12px;",
            "• OG - CMAP: Original CMAP signatures",
            br(),
            "• Filtered CMAP: CMAP signatures with shared genes/drugs",
            br(),
            "• Filtered TAHOE: TAHOE signatures with shared genes/drugs"),
          hr(),
          
          h4("Disease Signature Configuration"),
          selectInput("customGeneKey", "Gene Column:", 
                     choices = if(!is.null(values$data)) names(values$data) else c("SYMBOL"),
                     selected = "SYMBOL"),
          
          textInput("customLogFCPrefix", "Log2FC Column Prefix:", value = "log2FC"),
          numericInput("customLogFCCutoff", "Log2FC Cutoff:", value = 1.0, min = 0, step = 0.1),
          
          selectInput("customPvalKey", "P-value Column (optional):", 
                     choices = c("None" = "", if(!is.null(values$data)) names(values$data)),
                     selected = ""),
          
          numericInput("customPvalCutoff", "P-value Cutoff:", value = 0.05, min = 0, max = 1, step = 0.01),
          numericInput("customQThresh", "Q-value Threshold:", value = 0.05, min = 0, max = 1, step = 0.01),
          checkboxInput("customReversalOnly", "Reversal Only", value = TRUE),
          
          selectInput("customMode", "Analysis Mode:", 
                     choices = c("Single Cutoff" = "single", "Sweep Mode" = "sweep"),
                     selected = "single"),
          
          # Sweep mode parameters (conditional)
          conditionalPanel(
            condition = "input.customMode == 'sweep'",
            h4("Sweep Mode Settings"),
            checkboxInput("customSweepAutoGrid", "Auto-generate threshold grid", value = TRUE),
            numericInput("customSweepStep", "Step size:", value = 0.1, min = 0.05, step = 0.05),
            numericInput("customSweepMinFrac", "Min fraction of genes:", value = 0.20, min = 0.05, max = 1, step = 0.05),
            numericInput("customSweepMinGenes", "Min number of genes:", value = 200, min = 50, step = 50),
            checkboxInput("customSweepStopOnSmall", "Stop if signature too small", value = FALSE),
            selectInput("customCombineLogFC", "Combine log2FC columns:", 
                       choices = c("Average" = "average", "Median" = "median", "First" = "first"),
                       selected = "average"),
            selectInput("customRobustRule", "Robust drug rule:", 
                       choices = c("All cutoffs" = "all", "K of N cutoffs" = "k_of_n"),
                       selected = "all"),
            conditionalPanel(
              condition = "input.customRobustRule == 'k_of_n'",
              numericInput("customRobustK", "Minimum cutoffs (k):", value = 2, min = 1, step = 1)
            ),
            selectInput("customAggregate", "Score aggregation:", 
                       choices = c("Mean" = "mean", "Median" = "median"),
                       selected = "mean")
          ),
          
          numericInput("customSeed", "Random Seed:", value = 123, min = 1, step = 1)
          )
        )
      )
    } else {
      # Comparative analysis configuration (keeping existing)
      fluidRow(
        box(
          title = "Select Profiles to Compare",
          width = 12,
          status = "warning",
          solidHeader = TRUE,
          p("Select at least 2 profiles. You can also create custom profiles with sweep parameters."),
          
          checkboxGroupInput("selectedProfiles", 
                            "Select profiles (minimum 2):",
                            choices = if(length(values$config_profiles) > 0) {
                              setNames(names(values$config_profiles), names(values$config_profiles))
                            } else {
                              c()
                            },
                            selected = NULL),
          
          hr(),
          h4("Or Create Custom Profile for Comparison"),
          
          textInput("compCustomProfileName", "Profile Name:", 
                   value = paste0("custom_", as.integer(Sys.time()))),
          
          h4("Drug Signature Selection"),
          selectInput("compDrugSignatureChoice", "Choose Drug Signature:",
                     choices = c("OG - CMAP" = "og_cmap",
                               "Filtered CMAP" = "filtered_cmap", 
                               "Filtered TAHOE" = "filtered_tahoe"),
                     selected = "og_cmap"),
          p(style = "color: #666; font-size: 12px;",
            "• OG - CMAP: Original CMAP signatures",
            br(),
            "• Filtered CMAP: CMAP signatures with shared genes/drugs",
            br(),
            "• Filtered TAHOE: TAHOE signatures with shared genes/drugs"),
          hr(),
          
          h4("Disease Signature Configuration"),
          selectInput("compCustomGeneKey", "Gene Column:",
                     choices = if(!is.null(values$data)) names(values$data) else c("SYMBOL"),
                     selected = "SYMBOL"),
          
          textInput("compCustomLogFCPrefix", "Log2FC Column Prefix:", value = "log2FC"),
          numericInput("compCustomLogFCCutoff", "Log2FC Cutoff:", value = 1.0, min = 0, step = 0.1),
          
          selectInput("compCustomPvalKey", "P-value Column (optional):", 
                     choices = c("None" = "", if(!is.null(values$data)) names(values$data)),
                     selected = ""),
          
          numericInput("compCustomPvalCutoff", "P-value Cutoff:", value = 0.05, min = 0, max = 1, step = 0.01),
          numericInput("compCustomQThresh", "Q-value Threshold:", value = 0.05, min = 0, max = 1, step = 0.01),
          checkboxInput("compCustomReversalOnly", "Reversal Only", value = TRUE),
          
          selectInput("compCustomMode", "Analysis Mode:", 
                     choices = c("Single Cutoff" = "single", "Sweep Mode" = "sweep"),
                     selected = "single"),
          
          # Sweep mode parameters for comparative
          conditionalPanel(
            condition = "input.compCustomMode == 'sweep'",
            h4("Sweep Mode Settings"),
            checkboxInput("compCustomSweepAutoGrid", "Auto-generate threshold grid", value = TRUE),
            numericInput("compCustomSweepStep", "Step size:", value = 0.1, min = 0.05, step = 0.05),
            numericInput("compCustomSweepMinFrac", "Min fraction of genes:", value = 0.20, min = 0.05, max = 1, step = 0.05),
            numericInput("compCustomSweepMinGenes", "Min number of genes:", value = 200, min = 50, step = 50),
            checkboxInput("compCustomSweepStopOnSmall", "Stop if signature too small", value = FALSE),
            selectInput("compCustomCombineLogFC", "Combine log2FC columns:", 
                       choices = c("Average" = "average", "Median" = "median", "First" = "first"),
                       selected = "average"),
            selectInput("compCustomRobustRule", "Robust drug rule:", 
                       choices = c("All cutoffs" = "all", "K of N cutoffs" = "k_of_n"),
                       selected = "all"),
            conditionalPanel(
              condition = "input.compCustomRobustRule == 'k_of_n'",
              numericInput("compCustomRobustK", "Minimum cutoffs (k):", value = 2, min = 1, step = 1)
            ),
            selectInput("compCustomAggregate", "Score aggregation:", 
                       choices = c("Mean" = "mean", "Median" = "median"),
                       selected = "mean")
          ),
          
          numericInput("compCustomSeed", "Random Seed:", value = 123, min = 1, step = 1),
          
          actionButton("saveCompar

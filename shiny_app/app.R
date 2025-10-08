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
              tags$li(strong("View Results:"), " Explore drug candidates and visualizations")
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
      
      # Configuration Tab
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
      
      # Analysis Tab
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
      
      # Results Tab
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
      
      # Visualizations Tab
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
              tags$li("Choose analysis type (Single or Comparative)"),
              tags$li("Upload your disease gene expression CSV file"),
              tags$li("Configure parameters (or use defaults)"),
              tags$li("Run analysis and view results")
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
    comparison_results = list()
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
  
  # Dynamic configuration UI
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
      # Comparative analysis configuration
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
          
          actionButton("saveComparativeProfile", "Add Profile to Comparison", 
                      class = "btn-success", icon = icon("plus"))
        )
      )
    }
  })
  
  # Save comparative custom profile
  observeEvent(input$saveComparativeProfile, {
    req(input$compCustomProfileName)
    
    # Build sweep parameters if in sweep mode
    sweep_params <- if (input$compCustomMode == "sweep") {
      list(
        sweep_auto_grid = input$compCustomSweepAutoGrid,
        sweep_step = input$compCustomSweepStep,
        sweep_min_frac = input$compCustomSweepMinFrac,
        sweep_min_genes = input$compCustomSweepMinGenes,
        sweep_stop_on_small = input$compCustomSweepStopOnSmall,
        combine_log2fc = input$compCustomCombineLogFC,
        robust_rule = input$compCustomRobustRule,
        robust_k = if(input$compCustomRobustRule == "k_of_n") input$compCustomRobustK else NULL,
        aggregate = input$compCustomAggregate
      )
    } else {
      list()
    }
    
    custom_profile <- list(
      params = c(
        list(
          gene_key = input$compCustomGeneKey,
          logfc_cols_pref = input$compCustomLogFCPrefix,
          logfc_cutoff = input$compCustomLogFCCutoff,
          pval_key = if(input$compCustomPvalKey == "") NULL else input$compCustomPvalKey,
          pval_cutoff = input$compCustomPvalCutoff,
          q_thresh = input$compCustomQThresh,
          reversal_only = input$compCustomReversalOnly,
          mode = input$compCustomMode,
          seed = input$compCustomSeed
        ),
        sweep_params
      )
    )
    
    profile_name <- input$compCustomProfileName
    values$config_profiles[[profile_name]] <- custom_profile
    
    current_selected <- if(!is.null(input$selectedProfiles)) input$selectedProfiles else c()
    updateCheckboxGroupInput(session, "selectedProfiles",
                             choices = setNames(names(values$config_profiles), names(values$config_profiles)),
                             selected = c(current_selected, profile_name))
    
    showNotification(paste("Profile '", profile_name, "' added!"), type = "message")
  })
  
  # Check if existing profiles are available
  output$hasExistingProfiles <- reactive({
    length(values$config_profiles) > 0
  })
  outputOptions(output, "hasExistingProfiles", suspendWhenHidden = FALSE)
  
  # Update selected profiles for comparative
  observe({
    if (!is.null(values$analysis_type) && values$analysis_type == "comparative") {
      if (!is.null(input$selectedProfiles)) {
        values$selected_profiles <- as.list(input$selectedProfiles)
      }
    }
  })
  
  # Handle existing profile selection for single analysis
  observe({
    if (!is.null(values$analysis_type) && values$analysis_type == "single") {
      if (!is.null(input$selectedExistingProfile) && input$selectedExistingProfile != "custom") {
        # Load the selected profile's parameters
        profile <- values$config_profiles[[input$selectedExistingProfile]]
        
        if (!is.null(profile) && !is.null(values$data)) {
          # Update UI inputs with profile values
          updateSelectInput(session, "customGeneKey", 
                           selected = profile$params$gene_key %||% "SYMBOL")
          updateTextInput(session, "customLogFCPrefix", 
                         value = profile$params$logfc_cols_pref %||% "log2FC")
          updateNumericInput(session, "customLogFCCutoff", 
                            value = profile$params$logfc_cutoff %||% 1.0)
          updateNumericInput(session, "customQThresh", 
                            value = profile$params$q_thresh %||% 0.05)
          updateCheckboxInput(session, "customReversalOnly", 
                             value = isTRUE(profile$params$reversal_only %||% TRUE))
          updateSelectInput(session, "customMode", 
                           selected = profile$params$mode %||% "single")
          updateNumericInput(session, "customSeed", 
                            value = profile$params$seed %||% 123)
          
          # Update sweep parameters if they exist
          if (!is.null(profile$params$sweep_auto_grid)) {
            updateCheckboxInput(session, "customSweepAutoGrid", 
                               value = profile$params$sweep_auto_grid)
          }
          if (!is.null(profile$params$sweep_step)) {
            updateNumericInput(session, "customSweepStep", 
                              value = profile$params$sweep_step)
          }
          if (!is.null(profile$params$sweep_min_frac)) {
            updateNumericInput(session, "customSweepMinFrac", 
                              value = profile$params$sweep_min_frac)
          }
          if (!is.null(profile$params$sweep_min_genes)) {
            updateNumericInput(session, "customSweepMinGenes", 
                              value = profile$params$sweep_min_genes)
          }
          if (!is.null(profile$params$robust_rule)) {
            updateSelectInput(session, "customRobustRule", 
                             selected = profile$params$robust_rule)
          }
          if (!is.null(profile$params$aggregate)) {
            updateSelectInput(session, "customAggregate", 
                             selected = profile$params$aggregate)
          }
        }
      }
    }
  })
  
  # Configuration summary
  output$configSummary <- renderPrint({
    if (values$analysis_type == "single") {
      cat("Single Analysis Configuration:\n")
      cat("  Gene Column:", input$customGeneKey, "\n")
      cat("  Log2FC Cutoff:", input$customLogFCCutoff, "\n")
      cat("  Mode:", input$customMode, "\n")
      if (input$customMode == "sweep") {
        cat("\nSweep Settings:\n")
        cat("  Auto-grid:", input$customSweepAutoGrid, "\n")
        cat("  Step size:", input$customSweepStep, "\n")
        cat("  Robust rule:", input$customRobustRule, "\n")
      }
    } else {
      cat("Comparative Analysis Configuration:\n")
      cat("  Profiles selected:", length(values$selected_profiles), "\n")
      if (length(values$selected_profiles) > 0) {
        cat("  Profiles:", paste(unlist(values$selected_profiles), collapse = ", "), "\n")
      }
    }
  })
  
  # Analysis header
  output$analysisHeader <- renderUI({
    if (values$analysis_type == "single") {
      p(icon("flask"), strong(" Single Analysis"))
    } else {
      p(icon("balance-scale"), strong(" Comparative Analysis - "), 
        length(values$selected_profiles), " profiles")
    }
  })
  
  # Run analysis
  observeEvent(input$runBtn, {
    req(values$data)
    
    if (values$analysis_type == "single") {
      run_single_analysis()
    } else {
      run_comparative_analysis()
    }
  })
  
  # Single analysis function
  run_single_analysis <- function() {
    values$analysisLog <- ""
    temp_file <- tempfile(fileext = ".csv")
    write.csv(values$data, temp_file, row.names = FALSE)
    
    withProgress(message = 'Running analysis...', value = 0, {
      tryCatch({
        values$analysisLog <- paste0(values$analysisLog, "Initializing...\n")
        incProgress(0.1)
        
        # Build sweep parameters if in sweep mode
        sweep_params <- if (input$customMode == "sweep") {
          list(
            sweep_auto_grid = input$customSweepAutoGrid,
            sweep_step = input$customSweepStep,
            sweep_min_frac = input$customSweepMinFrac,
            sweep_min_genes = input$customSweepMinGenes,
            sweep_stop_on_small = input$customSweepStopOnSmall,
            combine_log2fc = input$customCombineLogFC,
            robust_rule = input$customRobustRule,
            robust_k = if(input$customRobustRule == "k_of_n") input$customRobustK else NULL,
            aggregate = input$customAggregate
          )
        } else {
          list()
        }
        
        pval_key_val <- if(input$customPvalKey == "") NULL else input$customPvalKey
        
        drp_args <- c(
          list(
            signatures_rdata = "../scripts/data/cmap_signatures.RData",
            disease_path = temp_file,
            cmap_meta_path = "../scripts/data/cmap_drug_experiments_new.csv",
            cmap_valid_path = "../scripts/data/cmap_valid_instances.csv",
            out_dir = tempdir(),
            gene_key = input$customGeneKey,
            logfc_cols_pref = input$customLogFCPrefix,
            logfc_cutoff = input$customLogFCCutoff,
            pval_key = pval_key_val,
            pval_cutoff = input$customPvalCutoff,
            q_thresh = input$customQThresh,
            reversal_only = input$customReversalOnly,
            seed = input$customSeed,
            mode = input$customMode,
            verbose = TRUE
          ),
          sweep_params
        )
        
        drp <- do.call(DRP$new, drp_args)
        
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
  }
  
  # Comparative analysis function
  run_comparative_analysis <- function() {
    values$comparison_results <- list()
    values$analysisLog <- "=== Comparative Analysis ===\n"
    
    profiles <- unlist(values$selected_profiles)
    
    if (length(profiles) < 2) {
      showNotification("Please select at least 2 profiles", type = "warning")
      return()
    }
    
    withProgress(message = 'Running comparative analysis...', value = 0, {
      for (i in seq_along(profiles)) {
        profile_name <- profiles[i]
        
        tryCatch({
          incProgress(1/length(profiles), detail = paste("Running", profile_name))
          values$analysisLog <- paste0(values$analysisLog, 
                                       "[", i, "/", length(profiles), "] ", profile_name, "\n")
          
          profile_config <- values$config_profiles[[profile_name]]
          
          temp_file <- tempfile(fileext = ".csv")
          write.csv(values$data, temp_file, row.names = FALSE)
          
          pval_key_val <- profile_config$params$pval_key
          if (!is.null(pval_key_val) && pval_key_val == "") pval_key_val <- NULL
          
          # Build DRP arguments including sweep parameters if present
          drp_args <- list(
            signatures_rdata = "../scripts/data/cmap_signatures.RData",
            disease_path = temp_file,
            cmap_meta_path = "../scripts/data/cmap_drug_experiments_new.csv",
            cmap_valid_path = "../scripts/data/cmap_valid_instances.csv",
            out_dir = tempdir(),
            gene_key = profile_config$params$gene_key %||% "SYMBOL",
            logfc_cols_pref = profile_config$params$logfc_cols_pref %||% "log2FC",
            logfc_cutoff = profile_config$params$logfc_cutoff %||% 1,
            pval_key = pval_key_val,
            pval_cutoff = profile_config$params$pval_cutoff %||% 0.05,
            q_thresh = profile_config$params$q_thresh %||% 0.05,
            reversal_only = isTRUE(profile_config$params$reversal_only %||% TRUE),
            seed = profile_config$params$seed %||% 123,
            verbose = FALSE,
            mode = profile_config$params$mode %||% "single"
          )
          
          # Add sweep parameters if they exist
          if (!is.null(profile_config$params$sweep_auto_grid)) {
            drp_args$sweep_auto_grid <- profile_config$params$sweep_auto_grid
          }
          if (!is.null(profile_config$params$sweep_step)) {
            drp_args$sweep_step <- profile_config$params$sweep_step
          }
          if (!is.null(profile_config$params$sweep_min_frac)) {
            drp_args$sweep_min_frac <- profile_config$params$sweep_min_frac
          }
          if (!is.null(profile_config$params$sweep_min_genes)) {
            drp_args$sweep_min_genes <- profile_config$params$sweep_min_genes
          }
          if (!is.null(profile_config$params$sweep_stop_on_small)) {
            drp_args$sweep_stop_on_small <- profile_config$params$sweep_stop_on_small
          }
          if (!is.null(profile_config$params$combine_log2fc)) {
            drp_args$combine_log2fc <- profile_config$params$combine_log2fc
          }
          if (!is.null(profile_config$params$robust_rule)) {
            drp_args$robust_rule <- profile_config$params$robust_rule
          }
          if (!is.null(profile_config$params$robust_k)) {
            drp_args$robust_k <- profile_config$params$robust_k
          }
          if (!is.null(profile_config$params$aggregate)) {
            drp_args$aggregate <- profile_config$params$aggregate
          }
          
          drp <- do.call(DRP$new, drp_args)
          
          drp$load_cmap()$load_disease()$clean_signature()
          
          if (drp$mode == "single") {
            drp$run_single()
          } else {
            drp$run_sweep()
          }
          
          drp$annotate_and_filter()
          
          if (!is.null(drp$drugs_valid) && nrow(drp$drugs_valid) > 0) {
            drp$drugs_valid$profile <- profile_name
            values$comparison_results[[profile_name]] <- drp$drugs_valid
            values$analysisLog <- paste0(values$analysisLog, "  → ", nrow(drp$drugs_valid), " hits\n")
          } else {
            values$analysisLog <- paste0(values$analysisLog, "  → No hits\n")
          }
          
          unlink(temp_file)
          
        }, error = function(e) {
          values$analysisLog <- paste0(values$analysisLog, "  → Error: ", e$message, "\n")
        })
      }
    })
    
    values$analysisLog <- paste0(values$analysisLog, "\n=== Complete ===\n")
    showNotification("Comparative analysis complete!", type = "message")
    updateTabItems(session, "sidebar", "results")
  }
  
  # Analysis log
  output$analysisLog <- renderPrint({
    cat(values$analysisLog)
  })
  
  # Results header
  output$resultsHeader <- renderUI({
    if (values$analysis_type == "single") {
      p(icon("flask"), strong(" Single Analysis Results"))
    } else {
      p(icon("balance-scale"), strong(" Comparative Analysis Results"))
    }
  })
  
  # Dynamic results UI
  output$resultsUI <- renderUI({
    if (values$analysis_type == "single") {
      fluidRow(
        valueBoxOutput("totalHitsBox"),
        valueBoxOutput("topDrugBox"),
        valueBoxOutput("medianQBox"),
        
        box(
          title = "Significant Drug Hits",
          width = 12,
          status = "success",
          solidHeader = TRUE,
          downloadButton("downloadResults", "Download Results CSV"),
          hr(),
          DTOutput("resultsTable")
        )
      )
    } else {
      fluidRow(
        box(
          title = "Comparison Summary",
          width = 12,
          status = "info",
          solidHeader = TRUE,
          DTOutput("comparisonSummary")
        ),
        
        box(
          title = "Combined Results",
          width = 12,
          status = "success",
          solidHeader = TRUE,
          downloadButton("downloadComparison", "Download Combined Results"),
          hr(),
          DTOutput("comparisonResults")
        )
      )
    }
  })
  
  # Plots header
  output$plotsHeader <- renderUI({
    if (values$analysis_type == "single") {
      p(icon("chart-bar"), strong(" Single Analysis Visualizations"))
    } else {
      p(icon("chart-bar"), strong(" Comparative Analysis Visualizations"))
    }
  })
  
  # Dynamic plots UI
  output$plotsUI <- renderUI({
    if (values$analysis_type == "single") {
      fluidRow(
        box(
          title = "Top Drugs by CMap Score",
          width = 12,
          status = "primary",
          solidHeader = TRUE,
          sliderInput("topN", "Number of drugs:", min = 5, max = 30, value = 15),
          plotlyOutput("topDrugsPlot", height = "500px")
        ),
        
        box(
          title = "Score Distribution",
          width = 6,
          status = "info",
          solidHeader = TRUE,
          plotlyOutput("scoreDist", height = "400px")
        ),
        
        box(
          title = "Volcano Plot",
          width = 6,
          status = "info",
          solidHeader = TRUE,
          plotlyOutput("volcanoPlot", height = "400px")
        )
      )
    } else {
      fluidRow(
        box(
          title = "Profile Overlap",
          width = 6,
          status = "success",
          solidHeader = TRUE,
          plotlyOutput("comparisonOverlap", height = "500px")
        ),
        box(
          title = "Score Distribution by Profile",
          width = 6,
          status = "success",
          solidHeader = TRUE,
          plotlyOutput("comparisonScoreDist", height = "500px")
        )
      )
    }
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
  
  # Comparison summary
  output$comparisonSummary <- renderDT({
    req(values$comparison_results)
    
    if (length(values$comparison_results) == 0) return(NULL)
    
    summary_df <- do.call(rbind, lapply(names(values$comparison_results), function(profile) {
      hits <- values$comparison_results[[profile]]
      data.frame(
        Profile = profile,
        Total_Hits = nrow(hits),
        Mean_Score = round(mean(hits$cmap_score, na.rm = TRUE), 4),
        Top_Drug = if(nrow(hits) > 0) hits$name[1] else "None",
        stringsAsFactors = FALSE
      )
    }))
    
    datatable(summary_df, options = list(pageLength = 10))
  })
  
  # Combined comparison results
  output$comparisonResults <- renderDT({
    req(values$comparison_results)
    
    if (length(values$comparison_results) == 0) return(NULL)
    
    combined <- do.call(rbind, values$comparison_results)
    datatable(combined, options = list(scrollX = TRUE, pageLength = 25), filter = 'top')
  })
  
  # Comparison overlap
  output$comparisonOverlap <- renderPlotly({
    req(values$comparison_results)
    
    if (length(values$comparison_results) < 2) return(NULL)
    
    profiles <- names(values$comparison_results)
    overlap_matrix <- matrix(0, nrow = length(profiles), ncol = length(profiles),
                            dimnames = list(profiles, profiles))
    
    for (i in seq_along(profiles)) {
      for (j in seq_along(profiles)) {
        drugs_i <- values$comparison_results[[profiles[i]]]$name
        drugs_j <- values$comparison_results[[profiles[j]]]$name
        overlap_matrix[i, j] <- length(intersect(drugs_i, drugs_j))
      }
    }
    
    plot_ly(z = overlap_matrix, x = profiles, y = profiles, 
            type = "heatmap", colorscale = "Blues") %>%
      layout(title = "Drug Overlap Between Profiles")
  })
  
  # Comparison score distribution
  output$comparisonScoreDist <- renderPlotly({
    req(values$comparison_results)
    
    if (length(values$comparison_results) == 0) return(NULL)
    
    combined <- do.call(rbind, values$comparison_results)
    
    plot_ly(data = combined, x = ~profile, y = ~cmap_score, 
            type = "box", color = ~profile) %>%
      layout(title = "Score Distribution by Profile", showlegend = FALSE)
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
  
  # Score distribution
  output$scoreDist <- renderPlotly({
    req(values$results)
    
    plot_ly(data = values$results, x = ~cmap_score, type = "histogram", nbinsx = 50) %>%
      layout(title = "CMap Score Distribution", xaxis = list(title = "CMap Score"))
  })
  
  # Volcano plot
  output$volcanoPlot <- renderPlotly({
    req(values$results)
    
    plot_ly(data = values$results, x = ~cmap_score, y = ~-log10(q),
            type = "scatter", mode = "markers",
            marker = list(color = ~cmap_score, colorscale = "RdBu")) %>%
      layout(title = "Volcano Plot", xaxis = list(title = "CMap Score"),
             yaxis = list(title = "-log10(Q-value)"))
  })
  
  # Download handlers
  output$downloadResults <- downloadHandler(
    filename = function() {
      paste("drug_results_", Sys.Date(), ".csv", sep = "")
    },
    content = function(file) {
      req(values$drugs_valid)
      write.csv(values$drugs_valid, file, row.names = FALSE)
    }
  )
  
  output$downloadComparison <- downloadHandler(
    filename = function() {
      paste("comparison_results_", Sys.Date(), ".csv", sep = "")
    },
    content = function(file) {
      req(values$comparison_results)
      combined <- do.call(rbind, values$comparison_results)
      write.csv(combined, file, row.names = FALSE)
    }
  )
}

# Run app
shinyApp(ui = ui, server = server)

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
    sidebarMenu(
      menuItem("Home", tabName = "home", icon = icon("home")),
      menuItem("1. Choose Analysis Type", tabName = "choose_type", icon = icon("route")),
      menuItem("2. Upload Data", tabName = "upload", icon = icon("upload")),
      menuItem("3. Configure", tabName = "config", icon = icon("cog")),
      menuItem("4. Run Analysis", tabName = "analysis", icon = icon("play")),
      menuItem("5. Results", tabName = "results", icon = icon("table")),
      menuItem("6. Visualizations", tabName = "plots", icon = icon("chart-bar")),
      menuItem("7. Sweep Analysis", tabName = "sweep", icon = icon("sliders-h")),
      menuItem("Help", tabName = "help", icon = icon("question-circle"))
    )
  ),
  
  dashboardBody(
    useShinyjs(),
    tags$head(
      tags$style(HTML("
        .box-header { font-weight: bold; }
        .info-box { margin-bottom: 15px; }
        .progress-text { font-size: 14px; margin-top: 10px; }
        .progress-step { 
          padding: 10px; 
          margin: 5px 0; 
          border-left: 4px solid #3c8dbc;
          background-color: #f4f4f4;
        }
        .progress-step.completed { 
          border-left-color: #00a65a;
          background-color: #e8f5e9;
        }
        .progress-step.active { 
          border-left-color: #f39c12;
          background-color: #fff3cd;
        }
        .progress-step.error { 
          border-left-color: #dd4b39;
          background-color: #f8d7da;
        }
        .step-title { font-weight: bold; margin-bottom: 5px; }
        .step-detail { font-size: 12px; color: #666; }
        .comparison-card {
          border: 1px solid #ddd;
          border-radius: 5px;
          padding: 15px;
          margin: 10px 0;
          background-color: #f9f9f9;
        }
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
            p("This Shiny application provides an interactive interface for the DRpipe drug repurposing analysis pipeline."),
            p("The pipeline identifies existing drugs that could be repurposed for new therapeutic applications by analyzing their ability to reverse disease-associated gene expression patterns using the Connectivity Map (CMap) database."),
            
            h4("Workflow:"),
            tags$div(style = "background-color: #e7f3ff; padding: 15px; border-radius: 5px; margin-bottom: 20px;",
              tags$ol(
                tags$li(tags$strong("Choose Analysis Type:"), " Select between Single Analysis or Comparative Analysis"),
                tags$li(tags$strong("Upload Data:"), " Upload your disease gene expression signature"),
                tags$li(tags$strong("Configure:"), " Select profile(s) and customize parameters"),
                tags$li(tags$strong("Run Analysis:"), " Execute the pipeline with real-time progress tracking"),
                tags$li(tags$strong("View Results:"), " Explore drug candidates and visualizations")
              )
            ),
            
            h4("Analysis Types:"),
            tags$div(style = "background-color: #f8f9fa; padding: 15px; border-radius: 5px; margin-bottom: 20px;",
              tags$ul(
                tags$li(tags$strong("Single Analysis:"), " Run analysis with one configuration profile to identify drug candidates"),
                tags$li(tags$strong("Comparative Analysis:"), " Compare results across multiple profiles to find robust drug candidates that appear consistently")
              )
            ),
            
            hr(),
            actionButton("startWorkflow", "Start Workflow →", 
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
            h4("Select the type of analysis you want to perform:"),
            br()
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
                  "Run analysis with ONE configuration profile to identify drug candidates for your disease signature."
                ),
                tags$ul(style = "text-align: left; margin-top: 20px;",
                  tags$li("Choose or create one analysis profile"),
                  tags$li("Get results for a specific parameter set"),
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
                  "Compare results across MULTIPLE configuration profiles to identify robust drug candidates."
                ),
                tags$ul(style = "text-align: left; margin-top: 20px;",
                  tags$li("Select multiple analysis profiles"),
                  tags$li("Compare results side-by-side"),
                  tags$li("Identify drugs that appear consistently"),
                  tags$li("More comprehensive and robust")
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
                        class = "btn-primary btn-lg",
                        icon = icon("check"))
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
                     multiple = FALSE,
                     accept = c("text/csv",
                              "text/comma-separated-values,text/plain",
                              ".csv")),
            helpText("Upload a CSV file containing gene expression data with gene identifiers and log2 fold-change values."),
            hr(),
            h4("Or Load Example Data:"),
            actionButton("loadExample", "Load Fibroid Example", 
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
              tags$li(strong("Gene identifier column:"), " e.g., SYMBOL, ENSEMBL, ENTREZ"),
              tags$li(strong("Log2 fold-change column(s):"), " e.g., log2FC, log2FC_1, log2FC_2")
            ),
            h4("Optional Columns:"),
            tags$ul(
              tags$li(strong("P-value column:"), " e.g., p_val_adj, FDR, pvalue")
            ),
            h4("Example Format:"),
            tags$pre(
              "SYMBOL,log2FC_1,log2FC_2,p_val_adj\n",
              "TP53,2.5,2.3,0.001\n",
              "BRCA1,-1.8,-2.1,0.005\n",
              "MYC,3.2,3.0,0.0001"
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
            actionButton("confirmData", "Confirm Data & Continue →", 
                        class = "btn-primary btn-lg",
                        icon = icon("check"))
          )
        )
      ),
      
      # Configuration Tab
      tabItem(tabName = "config",
        fluidRow(
          box(
            title = "Step 3: Configure Analysis",
            width = 12,
            status = "primary",
            solidHeader = TRUE,
            uiOutput("configInstructions")
          )
        ),
        
        # Dynamic UI based on analysis type
        uiOutput("configurationUI"),
        
        fluidRow(
          box(
            title = "Ready to Run",
            width = 12,
            status = "success",
            solidHeader = TRUE,
            uiOutput("configSummaryPreview"),
            br(),
            actionButton("proceedToAnalysis", "Proceed to Analysis →", 
                        class = "btn-success btn-lg",
                        icon = icon("play"))
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
            uiOutput("analysisHeader")
          )
        ),
        
        fluidRow(
          box(
            title = "Configuration Summary",
            width = 12,
            status = "info",
            solidHeader = TRUE,
            collapsible = TRUE,
            uiOutput("configSummary")
          )
        ),
        
        fluidRow(
          box(
            title = "Execute Analysis",
            width = 12,
            status = "success",
            solidHeader = TRUE,
            actionButton("runAnalysis", "Run Analysis", 
                        class = "btn-success btn-lg", 
                        icon = icon("play-circle")),
            hr(),
            h4("Analysis Progress:"),
            uiOutput("progressSteps"),
            hr(),
            h4("Detailed Log:"),
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
        
        # Dynamic results based on analysis type
        uiOutput("resultsUI")
      ),
      
      # Visualization Tab
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
        
        # Dynamic plots based on analysis type
        uiOutput("plotsUI")
      ),
      
      # Sweep Analysis Tab
      tabItem(tabName = "sweep",
        fluidRow(
          box(
            title = "Sweep Mode Analysis Visualization",
            width = 12,
            status = "primary",
            solidHeader = TRUE,
            p(icon("sliders-h"), strong(" Sweep Mode Results")),
            p("This tab displays visualizations specific to sweep mode analysis, which tests multiple log2FC thresholds to identify robust drug candidates.")
          )
        ),
        
        fluidRow(
          box(
            title = "About Sweep Mode",
            width = 12,
            status = "info",
            solidHeader = TRUE,
            collapsible = TRUE,
            collapsed = TRUE,
            h4("What is Sweep Mode?"),
            p("Sweep mode runs the drug repurposing analysis across multiple log2FC cutoff thresholds (e.g., 0, 0.5, 1.0, 1.5, 2.0, etc.) to identify drugs that consistently reverse the disease signature regardless of the specific threshold chosen."),
            h4("Why Use Sweep Mode?"),
            tags$ul(
              tags$li("Identifies robust drug candidates that appear across multiple thresholds"),
              tags$li("Reduces sensitivity to arbitrary cutoff selection"),
              tags$li("Provides confidence scores based on threshold support"),
              tags$li("Helps validate findings from single-threshold analyses")
            ),
            h4("Key Metrics:"),
            tags$ul(
              tags$li(strong("Threshold Support:"), " Number of different thresholds where a drug appears as significant"),
              tags$li(strong("Aggregated Score:"), " Combined CMap score across thresholds"),
              tags$li(strong("Min Q-value:"), " Best (lowest) q-value across all thresholds")
            )
          )
        ),
        
        conditionalPanel(
          condition = "output.hasSweepResults",
          fluidRow(
            valueBoxOutput("sweepTotalDrugsBox"),
            valueBoxOutput("sweepTopDrugBox"),
            valueBoxOutput("sweepThresholdsBox")
          ),
          
          fluidRow(
            box(
              title = "Threshold Support Distribution",
              width = 6,
              status = "success",
              solidHeader = TRUE,
              plotlyOutput("sweepSupportDist", height = "400px")
            ),
            box(
              title = "Score vs Support",
              width = 6,
              status = "success",
              solidHeader = TRUE,
              plotlyOutput("sweepScoreVsSupport", height = "400px")
            )
          ),
          
          fluidRow(
            box(
              title = "Cutoff Performance",
              width = 12,
              status = "warning",
              solidHeader = TRUE,
              plotlyOutput("sweepCutoffPerformance", height = "400px")
            )
          ),
          
          fluidRow(
            box(
              title = "Top Robust Drug Candidates",
              width = 12,
              status = "primary",
              solidHeader = TRUE,
              sliderInput("sweepTopN", "Number of top drugs to display:", 
                         min = 5, max = 30, value = 15, step = 5),
              plotlyOutput("sweepTopDrugs", height = "500px")
            )
          ),
          
          fluidRow(
            box(
              title = "Sweep Results Table",
              width = 12,
              status = "info",
              solidHeader = TRUE,
              downloadButton("downloadSweepResults", "Download Sweep Results"),
              hr(),
              DTOutput("sweepResultsTable")
            )
          )
        ),
        
        conditionalPanel(
          condition = "!output.hasSweepResults",
          fluidRow(
            box(
              title = "No Sweep Results Available",
              width = 12,
              status = "warning",
              solidHeader = TRUE,
              p(icon("info-circle"), " Sweep mode results will appear here after running an analysis with mode='sweep'."),
              p("To use sweep mode:"),
              tags$ol(
                tags$li("Go to Step 3: Configure"),
                tags$li("Create a custom profile or select an existing sweep profile"),
                tags$li("Set 'Analysis Mode' to 'Sweep Mode'"),
                tags$li("Run the analysis")
              )
            )
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
            
            h3("Getting Started"),
            p("Follow the numbered workflow in the sidebar:"),
            
            h4("1. Choose Analysis Type"),
            tags$ul(
              tags$li(strong("Single Analysis:"), " For testing one specific configuration"),
              tags$li(strong("Comparative Analysis:"), " For comparing multiple configurations to find robust candidates")
            ),
            
            h4("2. Upload Data"),
            p("Upload your disease gene expression CSV file or load an example dataset."),
            
            h4("3. Configure"),
            tags$ul(
              tags$li(strong("Single Analysis:"), " Select ONE profile or create custom settings"),
              tags$li(strong("Comparative Analysis:"), " Select MULTIPLE profiles to compare")
            ),
            
            h4("4. Run Analysis"),
            p("Review the configuration summary and run the analysis. Monitor real-time progress."),
            
            h4("5. Results"),
            tags$ul(
              tags$li(strong("Single Analysis:"), " View drug hits table and download results"),
              tags$li(strong("Comparative Analysis:"), " Compare results across profiles, view overlap, and identify robust candidates")
            ),
            
            h4("6. Visualizations"),
            p("Explore interactive plots and charts of your results."),
            
            hr(),
            
            h3("Parameter Guide"),
            
            h4("Log FC Cutoff"),
            p("Absolute log2 fold-change threshold for filtering genes:"),
            tags$ul(
              tags$li("0.5 = Lenient (more genes)"),
              tags$li("1.0 = Standard (recommended)"),
              tags$li("1.5 = Strict (fewer genes)")
            ),
            
            h4("Q-value Threshold"),
            p("False Discovery Rate (FDR) threshold for determining significant drug hits. Typical value: 0.05 (5% FDR)"),
            
            h4("Reversal Only"),
            p("When enabled, only drugs that reverse the disease signature (negative connectivity) are kept. Recommended for drug repurposing."),
            
            hr(),
            
            h3("Troubleshooting"),
            
            h4("Common Issues:"),
            tags$ul(
              tags$li(strong("'Gene column not found':"), " Verify the gene_key parameter matches your CSV column name"),
              tags$li(strong("'No genes matched':"), " Check that your gene identifiers are in the correct format"),
              tags$li(strong("'No significant hits':"), " Try adjusting the log FC cutoff or q-value threshold")
            )
          )
        )
      )
    )
  )
)

# Server Definition
server <- function(input, output, session) {
  # Reactive values to store data and results
  values <- reactiveValues(
    analysis_type = NULL,
    data = NULL,
    selected_profiles = list(),
    results = NULL,
    drugs_valid = NULL,
    analysisLog = "",
    drp_object = NULL,
    config_profiles = list(),
    progress_steps = list(),
    comparison_results = list(),
    comparison_log = "",
    custom_config = list()
  )
  
  # Start workflow button
  observeEvent(input$startWorkflow, {
    updateTabItems(session, "sidebar", "choose_type")
  })
  
  # Load configuration profiles on startup
  observe({
    tryCatch({
      config_path <- "../scripts/config.yml"
      if (file.exists(config_path)) {
        config_data <- yaml::read_yaml(config_path)
        
        # Extract profile names (exclude 'execution' and 'default')
        profile_names <- setdiff(names(config_data), c("execution", "default"))
        
        if (length(profile_names) > 0) {
          values$config_profiles <- config_data[profile_names]
        }
      }
    }, error = function(e) {
      showNotification(paste("Warning: Could not load config.yml:", e$message), type = "warning")
    })
  })
  
  # Handle analysis type selection
  observeEvent(input$analysisTypeClick, {
    values$analysis_type <- input$analysisTypeClick
    
    # Update card styling
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
        style = "background-color: #fff3cd; padding: 15px; border-radius: 5px; border-left: 4px solid #ffc107;",
        p(icon("exclamation-triangle"), strong(" Please select an analysis type first in Step 1"))
      ))
    }
    
    type_text <- ifelse(values$analysis_type == "single", "Single Analysis", "Comparative Analysis")
    tags$div(
      style = "background-color: #d1ecf1; padding: 10px; border-radius: 5px; border-left: 4px solid #17a2b8;",
      p(icon("info-circle"), strong(" Analysis Type: "), type_text)
    )
  })
  
  # Load example data - Fibroid
  observeEvent(input$loadExample, {
    tryCatch({
      example_path <- "../scripts/data/CoreFibroidSignature_All_Datasets.csv"
      if (file.exists(example_path)) {
        values$data <- read.csv(example_path, stringsAsFactors = FALSE, check.names = FALSE)
        showNotification("Fibroid example data loaded successfully!", type = "message")
      } else {
        showNotification("Example file not found. Please check data directory.", type = "error")
      }
    }, error = function(e) {
      showNotification(paste("Error loading example:", e$message), type = "error")
    })
  })
  
  # Load example data - Endothelial
  observeEvent(input$loadEndothelial, {
    tryCatch({
      example_path <- "../scripts/data/Endothelia_DEG.csv"
      if (file.exists(example_path)) {
        values$data <- read.csv(example_path, stringsAsFactors = FALSE, check.names = FALSE)
        showNotification("Endothelial example data loaded successfully!", type = "message")
      } else {
        showNotification("Example file not found. Please check data directory.", type = "error")
      }
    }, error = function(e) {
      showNotification(paste("Error loading example:", e$message), type = "error")
    })
  })
  
  # Data Preview from file upload
  observeEvent(input$diseaseFile, {
    req(input$diseaseFile)
    tryCatch({
      values$data <- read.csv(input$diseaseFile$datapath, 
                             stringsAsFactors = FALSE, 
                             check.names = FALSE)
      showNotification("Data uploaded successfully!", type = "message")
    }, error = function(e) {
      showNotification(paste("Error reading file:", e$message), type = "error")
    })
  })
  
  # Render data preview
  output$dataPreview <- renderDT({
    req(values$data)
    datatable(head(values$data, 100),
              options = list(scrollX = TRUE, pageLength = 10),
              caption = paste("Showing first 100 rows of", nrow(values$data), "total rows"))
  })
  
  # Confirm data button
  observeEvent(input$confirmData, {
    req(values$data)
    updateTabItems(session, "sidebar", "config")
    showNotification("Data confirmed. Proceed to configuration.", type = "message")
  })
  
  # Configuration instructions
  output$configInstructions <- renderUI({
    if (is.null(values$analysis_type)) {
      return(p("Please complete Step 1 first."))
    }
    
    if (values$analysis_type == "single") {
      tagList(
        p(icon("flask"), strong(" Single Analysis Mode")),
        p("Select ONE configuration profile or create custom settings.")
      )
    } else {
      tagList(
        p(icon("balance-scale"), strong(" Comparative Analysis Mode")),
        p("Select MULTIPLE configuration profiles to compare. You can also create new profiles.")
      )
    }
  })
  
  # Dynamic configuration UI
  output$configurationUI <- renderUI({
    req(values$analysis_type)
    
    if (values$analysis_type == "single") {
      # Single analysis: show profile selector (single selection)
      fluidRow(
        box(
          title = "Select Configuration Profile",
          width = 12,
          status = "warning",
          solidHeader = TRUE,
          p("Choose one profile:"),
          uiOutput("singleProfileSelector")
        )
      )
    } else {
      # Comparative analysis: show profile selector (multiple selection)
      fluidRow(
        box(
          title = "Select Profiles to Compare",
          width = 12,
          status = "warning",
          solidHeader = TRUE,
          p("Select at least 2 profiles to compare:"),
          uiOutput("multipleProfileSelector")
        )
      )
    }
  })
  
  # Single profile selector
  output$singleProfileSelector <- renderUI({
    profile_names <- names(values$config_profiles)
    
    # Create profile cards
    profile_cards <- if (length(profile_names) > 0) {
      lapply(profile_names, function(pname) {
        profile <- values$config_profiles[[pname]]
        
        div(
          class = "profile-card",
          id = paste0("profile_", pname),
          onclick = sprintf("Shiny.setInputValue('singleProfileClick', '%s', {priority: 'event'});", pname),
          h4(pname),
          tags$ul(
            tags$li("Log2FC Cutoff: ", profile$params$logfc_cutoff %||% "1.0"),
            tags$li("Q-value Threshold: ", profile$params$q_thresh %||% "0.05"),
            tags$li("Mode: ", profile$params$mode %||% "single")
          )
        )
      })
    } else {
      list()
    }
    
    tagList(
      if (length(profile_cards) > 0) {
        tagList(
          h4("Existing Profiles:"),
          do.call(tagList, profile_cards),
          hr()
        )
      },
      
      # Custom profile option
      div(
        class = "profile-card",
        id = "profile_custom",
        onclick = "Shiny.setInputValue('singleProfileClick', 'custom', {priority: 'event'});",
        h4(icon("plus-circle"), " Create Custom Profile"),
        p("Configure your own analysis parameters")
      ),
      
      hr(),
      p(strong("Selected: "), textOutput("selectedSingleProfile", inline = TRUE)),
      
      # Show custom configuration inputs when custom is selected
      conditionalPanel(
        condition = "input.singleProfileClick == 'custom'",
        tags$div(
          style = "background-color: #f8f9fa; padding: 15px; border-radius: 5px; margin-top: 15px;",
          h4("Custom Profile Configuration"),
          
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
          
          numericInput("customSeed", "Random Seed:", value = 123, min = 1, step = 1),
          
          actionButton("saveCustomProfile", "Save Custom Profile", 
                      class = "btn-success", icon = icon("save"))
        )
      )
    )
  })
  
  # Multiple profile selector
  output$multipleProfileSelector <- renderUI({
    profile_names <- names(values$config_profiles)
    
    tagList(
      if (length(profile_names) > 0) {
        tagList(
          h4("Existing Profiles:"),
          checkboxGroupInput("selectedProfiles", 
                            "Select profiles (minimum 2):",
                            choices = setNames(profile_names, profile_names),
                            selected = NULL),
          hr()
        )
      } else {
        p("No existing profiles found. Create custom profiles below.")
      },
      
      # Add custom profile button
      actionButton("addComparativeProfile", "Add Custom Profile", 
                  class = "btn-primary", icon = icon("plus-circle")),
      
      # Show custom profile form when button is clicked
      conditionalPanel(
        condition = "input.addComparativeProfile > 0",
        tags$div(
          style = "background-color: #f8f9fa; padding: 15px; border-radius: 5px; margin-top: 15px;",
          h4("Create Custom Profile for Comparison"),
          
          textInput("compCustomProfileName", "Profile Name:", 
                   value = paste0("custom_profile_", as.integer(Sys.time()))),
          
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
          
          numericInput("compCustomSeed", "Random Seed:", value = 123, min = 1, step = 1),
          
          actionButton("saveComparativeProfile", "Save & Add to Comparison", 
                      class = "btn-success", icon = icon("save"))
        )
      ),
      
      hr(),
      p(strong("Selected Profiles: "), textOutput("selectedMultipleProfiles", inline = TRUE))
    )
  })
  
  # Handle single profile selection
  observeEvent(input$singleProfileClick, {
    values$selected_profiles <- list(input$singleProfileClick)
    
    # Update card styling
    profile_names <- names(values$config_profiles)
    for (pname in profile_names) {
      if (pname == input$singleProfileClick) {
        runjs(sprintf("$('#profile_%s').addClass('selected');", pname))
      } else {
        runjs(sprintf("$('#profile_%s').removeClass('selected');", pname))
      }
    }
  })
  
  # Save custom profile
  observeEvent(input$saveCustomProfile, {
    req(input$customProfileName)
    
    # Create custom profile configuration
    custom_profile <- list(
      params = list(
        gene_key = input$customGeneKey,
        logfc_cols_pref = input$customLogFCPrefix,
        logfc_cutoff = input$customLogFCCutoff,
        pval_key = if(input$customPvalKey == "") NULL else input$customPvalKey,
        pval_cutoff = input$customPvalCutoff,
        q_thresh = input$customQThresh,
        reversal_only = input$customReversalOnly,
        mode = input$customMode,
        seed = input$customSeed
      )
    )
    
    # Store in config_profiles
    profile_name <- input$customProfileName
    values$config_profiles[[profile_name]] <- custom_profile
    
    # Auto-select the custom profile
    values$selected_profiles <- list(profile_name)
    
    showNotification(paste("Custom profile '", profile_name, "' created successfully!"), 
                    type = "message")
    
    # Update card styling
    runjs(sprintf("$('#profile_custom').removeClass('selected'); $('#profile_%s').addClass('selected');", profile_name))
  })
  
  # Display selected single profile
  output$selectedSingleProfile <- renderText({
    if (length(values$selected_profiles) == 0) {
      "None"
    } else {
      values$selected_profiles[[1]]
    }
  })
  
  # Save comparative custom profile
  observeEvent(input$saveComparativeProfile, {
    req(input$compCustomProfileName)
    
    # Create custom profile configuration
    custom_profile <- list(
      params = list(
        gene_key = input$compCustomGeneKey,
        logfc_cols_pref = input$compCustomLogFCPrefix,
        logfc_cutoff = input$compCustomLogFCCutoff,
        pval_key = if(input$compCustomPvalKey == "") NULL else input$compCustomPvalKey,
        pval_cutoff = input$compCustomPvalCutoff,
        q_thresh = input$compCustomQThresh,
        reversal_only = input$compCustomReversalOnly,
        mode = input$compCustomMode,
        seed = input$compCustomSeed
      )
    )
    
    # Store in config_profiles
    profile_name <- input$compCustomProfileName
    values$config_profiles[[profile_name]] <- custom_profile
    
    # Add to selected profiles
    current_selected <- if(!is.null(input$selectedProfiles)) input$selectedProfiles else c()
    updateCheckboxGroupInput(session, "selectedProfiles",
                             choices = setNames(names(values$config_profiles), names(values$config_profiles)),
                             selected = c(current_selected, profile_name))
    
    showNotification(paste("Custom profile '", profile_name, "' created and added to comparison!"), 
                    type = "message")
  })
  
  # Display selected multiple profiles
  output$selectedMultipleProfiles <- renderText({
    if (length(values$selected_profiles) == 0) {
      "None"
    } else {
      paste(unlist(values$selected_profiles), collapse = ", ")
    }
  })
  
  # Update selected profiles for comparative analysis
  observe({
    if (!is.null(values$analysis_type) && values$analysis_type == "comparative") {
      if (!is.null(input$selectedProfiles)) {
        values$selected_profiles <- as.list(input$selectedProfiles)
      }
    }
  })
  
  # Configuration summary preview
  output$configSummaryPreview <- renderUI({
    if (length(values$selected_profiles) == 0) {
      return(p(style = "color: #999; font-style: italic;", 
              "Please select profile(s) above"))
    }
    
    if (values$analysis_type == "single") {
      profile_name <- values$selected_profiles[[1]]
      profile <- values$config_profiles[[profile_name]]
      
      tagList(
        h4(icon("check-circle", style = "color: #28a745;"), " Configuration Ready"),
        tags$div(
          style = "background-color: #f8f9fa; padding: 15px; border-radius: 5px;",
          p(strong("Profile: "), profile_name),
          p(strong("Log2FC Cutoff: "), profile$params$logfc_cutoff %||% "1.0"),
          p(strong("Q-value Threshold: "), profile$params$q_thresh %||% "0.05"),
          p(strong("Mode: "), profile$params$mode %||% "single")
        )
      )
    } else {
      tagList(
        h4(icon("check-circle", style = "color: #28a745;"), " Profiles Selected for Comparison"),
        tags$div(
          style = "background-color: #f8f9fa; padding: 15px; border-radius: 5px;",
          p(strong("Number of profiles: "), length(values$selected_profiles)),
          p(strong("Profiles: "), paste(unlist(values$selected_profiles), collapse = ", "))
        )
      )
    }
  })
  
  # Proceed to analysis
  observeEvent(input$proceedToAnalysis, {
    if (length(values$selected_profiles) == 0) {
      showNotification("Please select at least one profile", type = "warning")
      return()
    }
    
    if (values$analysis_type == "comparative" && length(values$selected_profiles) < 2) {
      showNotification("Please select at least 2 profiles for comparative analysis", type = "warning")
      return()
    }
    
    updateTabItems(session, "sidebar", "analysis")
    showNotification("Configuration confirmed. Ready to run analysis.", type = "message")
  })
  
  # Analysis header
  output$analysisHeader <- renderUI({
    if (is.null(values$analysis_type)) {
      return(p("Please complete previous steps first."))
    }
    
    if (values$analysis_type == "single") {
      p(icon("flask"), strong(" Single Analysis - "), 
        "Running with profile: ", values$selected_profiles[[1]])
    } else {
      p(icon("balance-scale"), strong(" Comparative Analysis - "), 
        "Comparing ", length(values$selected_profiles), " profiles")
    }
  })
  
  # Configuration summary for analysis page
  output$configSummary <- renderUI({
    if (is.null(values$data)) {
      return(p("No data loaded"))
    }
    
    if (length(values$selected_profiles) == 0) {
      return(p("No profiles selected"))
    }
    
    # Show summary based on analysis type
    if (values$analysis_type == "single") {
      profile_name <- values$selected_profiles[[1]]
      profile <- values$config_profiles[[profile_name]]
      
      tagList(
        tags$div(
          style = "background-color: #f0f8ff; padding: 15px; border-radius: 5px; margin-bottom: 10px;",
          h4(icon("database"), " Data Information"),
          p(strong("Total genes: "), nrow(values$data)),
          p(strong("Columns: "), paste(names(values$data), collapse = ", "))
        ),
        tags$div(
          style = "background-color: #fff8e1; padding: 15px; border-radius: 5px;",
          h4(icon("cog"), " Profile: ", profile_name),
          p(strong("Log2FC Cutoff: "), profile$params$logfc_cutoff %||% "1.0"),
          p(strong("Q-value Threshold: "), profile$params$q_thresh %||% "0.05"),
          p(strong("Gene Column: "), profile$params$gene_key %||% "SYMBOL"),
          p(strong("Mode: "), profile$params$mode %||% "single")
        )
      )
    } else {
      tagList(
        tags$div(
          style = "background-color: #f0f8ff; padding: 15px; border-radius: 5px; margin-bottom: 10px;",
          h4(icon("database"), " Data Information"),
          p(strong("Total genes: "), nrow(values$data))
        ),
        tags$div(
          style = "background-color: #fff8e1; padding: 15px; border-radius: 5px;",
          h4(icon("balance-scale"), " Comparative Analysis"),
          p(strong("Profiles to compare: "), paste(unlist(values$selected_profiles), collapse = ", ")),
          p(strong("Number of profiles: "), length(values$selected_profiles))
        )
      )
    }
  })
  
  # Helper function to update progress steps
  updateProgressStep <- function(step_id, status = "active", detail = NULL) {
    if (is.null(values$progress_steps[[step_id]])) {
      values$progress_steps[[step_id]] <- list(status = status, detail = detail)
    } else {
      values$progress_steps[[step_id]]$status <- status
      if (!is.null(detail)) {
        values$progress_steps[[step_id]]$detail <- detail
      }
    }
  }
  
  # Run Analysis (handles both single and comparative)
  observeEvent(input$runAnalysis, {
    req(values$data)
    req(values$selected_profiles)
    
    if (values$analysis_type == "single") {
      # Run single analysis
      run_single_analysis()
    } else {
      # Run comparative analysis
      run_comparative_analysis()
    }
  })
  
  # Single analysis function
  run_single_analysis <- function() {
    # Clear previous results
    values$results <- NULL
    values$drugs_valid <- NULL
    values$analysisLog <- ""
    values$progress_steps <- list()
    
    # Initialize progress steps
    steps <- c("init", "load_cmap", "load_disease", "clean_signature", 
               "compute_scores", "annotate", "complete")
    for (step in steps) {
      values$progress_steps[[step]] <- list(status = "pending", detail = NULL)
    }
    
    profile_name <- values$selected_profiles[[1]]
    profile <- values$config_profiles[[profile_name]]
    
    # Create temporary file for disease data
    temp_disease_file <- tempfile(fileext = ".csv")
    write.csv(values$data, temp_disease_file, row.names = FALSE)
    
    # Prepare paths
    signatures_path <- "../scripts/data/cmap_signatures.RData"
    cmap_meta_path <- "../scripts/data/cmap_drug_experiments_new.csv"
    cmap_valid_path <- "../scripts/data/cmap_valid_instances.csv"
    
    # Check if required files exist
    if (!file.exists(signatures_path)) {
      showNotification("Error: cmap_signatures.RData not found in scripts/data/", type = "error")
      values$analysisLog <- paste0(values$analysisLog, 
                                   "\nError: cmap_signatures.RData not found.")
      updateProgressStep("init", "error", "Missing required files")
      return()
    }
    
    withProgress(message = 'Running analysis...', value = 0, {
      tryCatch({
        # Prepare pval_key
        pval_key_value <- profile$params$pval_key
        if (!is.null(pval_key_value) && pval_key_value == "") {
          pval_key_value <- NULL
        }
        
        # Step 1: Initialize DRP object
        updateProgressStep("init", "active", "Initializing pipeline...")
        incProgress(0.1, detail = "Initializing pipeline...")
        values$analysisLog <- paste0(values$analysisLog, "[1/7] Initializing DRP object...\n")
        values$analysisLog <- paste0(values$analysisLog, "Profile: ", profile_name, "\n")
        
        drp <- DRP$new(
          signatures_rdata = signatures_path,
          disease_path = temp_disease_file,
          cmap_meta_path = cmap_meta_path,
          cmap_valid_path = cmap_valid_path,
          out_dir = tempdir(),
          gene_key = profile$params$gene_key %||% "SYMBOL",
          logfc_cols_pref = profile$params$logfc_cols_pref %||% "log2FC",
          logfc_cutoff = profile$params$logfc_cutoff %||% 1,
          pval_key = pval_key_value,
          pval_cutoff = profile$params$pval_cutoff %||% 0.05,
          q_thresh = profile$params$q_thresh %||% 0.05,
          reversal_only = isTRUE(profile$params$reversal_only %||% TRUE),
          seed = profile$params$seed %||% 123,
          verbose = TRUE,
          mode = profile$params$mode %||% "single"
        )
        
        values$drp_object <- drp
        updateProgressStep("init", "completed", "Pipeline initialized successfully")
        
        # Step 2: Load CMap signatures
        updateProgressStep("load_cmap", "active", "Loading CMap database...")
        incProgress(0.15, detail = "Loading CMap signatures...")
        values$analysisLog <- paste0(values$analysisLog, "[2/7] Loading CMap signatures (1,309 drug profiles)...\n")
        drp$load_cmap()
        updateProgressStep("load_cmap", "completed", "Loaded 1,309 drug profiles")
        
        # Step 3: Load disease data
        updateProgressStep("load_disease", "active", "Loading disease signature...")
        incProgress(0.1, detail = "Loading disease signature...")
        values$analysisLog <- paste0(values$analysisLog, "[3/7] Loading disease signature...\n")
        drp$load_disease()
        n_genes_raw <- nrow(drp$dz_signature_raw)
        updateProgressStep("load_disease", "completed", paste("Loaded", n_genes_raw, "genes"))
        values$analysisLog <- paste0(values$analysisLog, "    → ", n_genes_raw, " genes loaded\n")
        
        # Step 4: Clean signature
        updateProgressStep("clean_signature", "active", "Filtering and cleaning signature...")
        incProgress(0.1, detail = "Cleaning signature...")
        values$analysisLog <- paste0(values$analysisLog, "[4/7] Cleaning and filtering signature...\n")
        drp$clean_signature()
        n_up <- length(drp$dz_genes_up)
        n_down <- length(drp$dz_genes_down)
        updateProgressStep("clean_signature", "completed", 
                          paste("Filtered to", n_up, "up-regulated and", n_down, "down-regulated genes"))
        values$analysisLog <- paste0(values$analysisLog, "    → Up-regulated genes: ", n_up, "\n")
        values$analysisLog <- paste0(values$analysisLog, "    → Down-regulated genes: ", n_down, "\n")
        
        # Step 5: Run scoring
        updateProgressStep("compute_scores", "active", "Computing connectivity scores...")
        incProgress(0.35, detail = "Computing connectivity scores...")
        values$analysisLog <- paste0(values$analysisLog, "[5/7] Computing connectivity scores...\n")
        
        if (drp$mode == "single") {
          drp$run_single()
        } else {
          drp$run_sweep()
        }
        
        n_drugs_scored <- nrow(drp$drugs)
        updateProgressStep("compute_scores", "completed", 
                          paste("Scored", n_drugs_scored, "drug profiles"))
        values$analysisLog <- paste0(values$analysisLog, "    → ", n_drugs_scored, " drugs scored\n")
        
        # Step 6: Annotate and filter
        updateProgressStep("annotate", "active", "Annotating with drug metadata...")
        incProgress(0.15, detail = "Annotating results...")
        values$analysisLog <- paste0(values$analysisLog, "[6/7] Annotating with drug metadata...\n")
        drp$annotate_and_filter()
        
        # Store results
        values$results <- drp$drugs
        values$drugs_valid <- drp$drugs_valid
        
        n_hits <- nrow(drp$drugs_valid)
        updateProgressStep("annotate", "completed", 
                          paste("Found", n_hits, "significant hits"))
        values$analysisLog <- paste0(values$analysisLog, "    → Significant hits: ", n_hits, "\n")
        
        # Step 7: Complete
        updateProgressStep("complete", "completed", "Analysis complete!")
        incProgress(0.05, detail = "Finalizing results...")
        values$analysisLog <- paste0(values$analysisLog, "\n[7/7] Analysis complete!\n")
        
        if (n_hits > 0) {
          top_drug <- drp$drugs_valid$name[1]
          top_score <- round(drp$drugs_valid$cmap_score[1], 4)
          values$analysisLog <- paste0(values$analysisLog, "\nTop drug candidate: ", top_drug, 
                                       " (score: ", top_score, ")\n")
        }
        
        showNotification("Analysis completed successfully!", type = "message", duration = 5)
        
      }, error = function(e) {
        error_step <- names(values$progress_steps)[sapply(values$progress_steps, function(x) x$status == "active")]
        if (length(error_step) > 0) {
          updateProgressStep(error_step[1], "error", paste("Error:", e$message))
        }
        values$analysisLog <- paste0(values$analysisLog, 
                                     "\n\n=== ERROR ===\n", e$message, "\n")
        showNotification(paste("Analysis failed:", e$message), type = "error", duration = 10)
      })
    })
    
    # Clean up temp file
    unlink(temp_disease_file)
  }
  
  # Comparative analysis function
  run_comparative_analysis <- function() {
    # Clear previous comparison results
    values$comparison_results <- list()
    values$comparison_log <- ""
    values$progress_steps <- list()
    
    profiles <- unlist(values$selected_profiles)
    values$comparison_log <- paste0("=== Comparative Analysis Started ===\n")
    values$comparison_log <- paste0(values$comparison_log, "Comparing ", length(profiles), " profiles: ", 
                                   paste(profiles, collapse = ", "), "\n\n")
    
    # Prepare paths
    signatures_path <- "../scripts/data/cmap_signatures.RData"
    cmap_meta_path <- "../scripts/data/cmap_drug_experiments_new.csv"
    cmap_valid_path <- "../scripts/data/cmap_valid_instances.csv"
    
    withProgress(message = 'Running comparative analysis...', value = 0, {
      for (i in seq_along(profiles)) {
        profile_name <- profiles[i]
        
        tryCatch({
          incProgress(1/length(profiles), detail = paste("Running", profile_name))
          values$comparison_log <- paste0(values$comparison_log, 
                                         "[", i, "/", length(profiles), "] Running profile: ", 
                                         profile_name, "\n")
          
          # Get profile configuration
          profile_config <- values$config_profiles[[profile_name]]
          
          # Create temporary file for disease data
          temp_disease_file <- tempfile(fileext = ".csv")
          write.csv(values$data, temp_disease_file, row.names = FALSE)
          
          # Prepare pval_key
          pval_key_value <- profile_config$params$pval_key
          if (!is.null(pval_key_value) && pval_key_value == "") {
            pval_key_value <- NULL
          }
          
          # Run analysis with this profile
          drp <- DRP$new(
            signatures_rdata = signatures_path,
            disease_path = temp_disease_file,
            cmap_meta_path = cmap_meta_path,
            cmap_valid_path = cmap_valid_path,
            out_dir = tempdir(),
            gene_key = profile_config$params$gene_key %||% "SYMBOL",
            logfc_cols_pref = profile_config$params$logfc_cols_pref %||% "log2FC",
            logfc_cutoff = profile_config$params$logfc_cutoff %||% 1,
            pval_key = pval_key_value,
            pval_cutoff = profile_config$params$pval_cutoff %||% 0.05,
            q_thresh = profile_config$params$q_thresh %||% 0.05,
            reversal_only = isTRUE(profile_config$params$reversal_only %||% TRUE),
            seed = profile_config$params$seed %||% 123,
            verbose = FALSE,
            mode = profile_config$params$mode %||% "single"
          )
          
          drp$load_cmap()$load_disease()$clean_signature()
          
          if (drp$mode == "single") {
            drp$run_single()
          } else {
            drp$run_sweep()
          }
          
          drp$annotate_and_filter()
          
          # Store results
          if (!is.null(drp$drugs_valid) && nrow(drp$drugs_valid) > 0) {
            drp$drugs_valid$profile <- profile_name
            values$comparison_results[[profile_name]] <- drp$drugs_valid
            
            values$comparison_log <- paste0(values$comparison_log, 
                                           "  → Found ", nrow(drp$drugs_valid), " hits\n")
          } else {
            values$comparison_log <- paste0(values$comparison_log, 
                                           "  → No significant hits found\n")
          }
          
          unlink(temp_disease_file)
          
        }, error = function(e) {
          values$comparison_log <- paste0(values$comparison_log, 
                                         "  → Error: ", e$message, "\n")
        })
      }
    })
    
    values$comparison_log <- paste0(values$comparison_log, "\n=== Comparison Complete ===\n")
    
    if (length(values$comparison_results) > 0) {
      showNotification("Comparative analysis completed!", type = "message")
      
      # Set progress as complete
      updateProgressStep("complete", "completed", 
                        paste("Compared", length(values$comparison_results), "profiles successfully"))
    } else {
      showNotification("No results found across profiles", type = "warning")
    }
  }
  
  # Render progress steps
  output$progressSteps <- renderUI({
    if (length(values$progress_steps) == 0) {
      return(p("Click 'Run Analysis' to start..."))
    }
    
    if (values$analysis_type == "comparative") {
      # Show comparison progress
      return(tagList(
        p(strong("Comparative Analysis Progress:")),
        verbatimTextOutput("comparisonLog")
      ))
    }
    
    # Single analysis progress
    step_names <- c(
      init = "1. Initialize Pipeline",
      load_cmap = "2. Load CMap Database",
      load_disease = "3. Load Disease Signature",
      clean_signature = "4. Filter & Clean Genes",
      compute_scores = "5. Compute Connectivity Scores",
      annotate = "6. Annotate & Filter Results",
      complete = "7. Complete"
    )
    
    step_icons <- c(
      pending = "circle-o",
      active = "spinner fa-spin",
      completed = "check-circle",
      error = "times-circle"
    )
    
    step_divs <- lapply(names(step_names), function(step_id) {
      step <- values$progress_steps[[step_id]]
      if (is.null(step)) {
        step <- list(status = "pending", detail = NULL)
      }
      
      class_name <- paste0("progress-step ", step$status)
      icon_name <- step_icons[[step$status]]
      
      detail_text <- if (!is.null(step$detail)) {
        tags$div(class = "step-detail", step$detail)
      } else {
        NULL
      }
      
      tags$div(
        class = class_name,
        tags$div(
          class = "step-title",
          icon(icon_name),
          " ",
          step_names[[step_id]]
        ),
        detail_text
      )
    })
    
    do.call(tagList, step_divs)
  })
  
  # Analysis Log Output
  output$analysisLog <- renderPrint({
    cat(values$analysisLog)
  })
  
  # Comparison log output
  output$comparisonLog <- renderPrint({
    cat(values$comparison_log)
  })
  
  # Results header
  output$resultsHeader <- renderUI({
    if (is.null(values$analysis_type)) {
      return(p("Please complete the analysis first."))
    }
    
    if (values$analysis_type == "single") {
      p(icon("flask"), strong(" Single Analysis Results"))
    } else {
      p(icon("balance-scale"), strong(" Comparative Analysis Results"))
    }
  })
  
  # Dynamic results UI
  output$resultsUI <- renderUI({
    if (values$analysis_type == "single") {
      # Single analysis results
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
          downloadButton("downloadRData", "Download RData"),
          hr(),
          DTOutput("resultsTable")
        )
      )
    } else {
      # Comparative analysis results
      fluidRow(
        box(
          title = "Comparison Summary",
          width = 12,
          status = "info",
          solidHeader = TRUE,
          DTOutput("comparisonSummary")
        ),
        
        box(
          title = "Profile Overlap Visualization",
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
        ),
        
        box(
          title = "Combined Results",
          width = 12,
          status = "warning",
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
    if (is.null(values$analysis_type)) {
      return(p("Please complete the analysis first."))
    }
    
    if (values$analysis_type == "single") {
      p(icon("chart-bar"), strong(" Visualizations - Single Analysis"))
    } else {
      p(icon("chart-bar"), strong(" Visualizations - Comparative Analysis"))
    }
  })
  
  # Dynamic plots UI
  output$plotsUI <- renderUI({
    if (values$analysis_type == "single") {
      # Single analysis plots
      fluidRow(
        box(
          title = "Drug Score Distribution",
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
        ),
        
        box(
          title = "Top Drugs by CMap Score",
          width = 12,
          status = "primary",
          solidHeader = TRUE,
          sliderInput("topN", "Number of top drugs to display:", 
                     min = 5, max = 50, value = 20, step = 5),
          plotlyOutput("topDrugsPlot", height = "500px")
        ),
        
        box(
          title = "Q-value Distribution",
          width = 6,
          status = "warning",
          solidHeader = TRUE,
          plotlyOutput("qvalueDist", height = "400px")
        ),
        box(
          title = "Score vs Significance",
          width = 6,
          status = "warning",
          solidHeader = TRUE,
          plotlyOutput("scoreVsQ", height = "400px")
        )
      )
    } else {
      # Comparative analysis plots (already shown in results)
      fluidRow(
        box(
          title = "Comparative Visualizations",
          width = 12,
          status = "info",
          solidHeader = TRUE,
          p("Comparative visualizations are available in the Results tab.")
        )
      )
    }
  })
  
  # Value Boxes (for single analysis)
  output$totalHitsBox <- renderValueBox({
    hits <- if (!is.null(values$drugs_valid)) nrow(values$drugs_valid) else 0
    valueBox(
      hits, "Significant Hits", 
      icon = icon("pills"),
      color = if(hits > 0) "green" else "red"
    )
  })
  
  output$topDrugBox <- renderValueBox({
    top_drug <- if (!is.null(values$drugs_valid) && nrow(values$drugs_valid) > 0) {
      values$drugs_valid$name[1]
    } else {
      "None"
    }
    valueBox(
      top_drug, "Top Drug Candidate",
      icon = icon("star"),
      color = "blue"
    )
  })
  
  output$medianQBox <- renderValueBox({
    median_q <- if (!is.null(values$drugs_valid) && nrow(values$drugs_valid) > 0) {
      round(median(values$drugs_valid$q, na.rm = TRUE), 4)
    } else {
      "N/A"
    }
    valueBox(
      median_q, "Median Q-value",
      icon = icon("chart-line"),
      color = "purple"
    )
  })
  
  # Results Table (single analysis)
  output$resultsTable <- renderDT({
    req(values$drugs_valid)
    datatable(values$drugs_valid,
              options = list(scrollX = TRUE, pageLength = 25),
              filter = 'top',
              caption = "Significant drug hits (sorted by CMap score)")
  })
  
  # Comparison summary table
  output$comparisonSummary <- renderDT({
    req(values$comparison_results)
    
    if (length(values$comparison_results) == 0) {
      return(NULL)
    }
    
    summary_df <- do.call(rbind, lapply(names(values$comparison_results), function(profile) {
      hits <- values$comparison_results[[profile]]
      data.frame(
        Profile = profile,
        Total_Hits = nrow(hits),
        Mean_CMap_Score = round(mean(hits$cmap_score, na.rm = TRUE), 4),
        Median_Q_Value = format(median(hits$q, na.rm = TRUE), scientific = TRUE),
        Top_Drug = if(nrow(hits) > 0) hits$name[1] else "None",
        stringsAsFactors = FALSE
      )
    }))
    
    datatable(summary_df, options = list(pageLength = 10))
  })
  
  # Combined comparison results
  output$comparisonResults <- renderDT({
    req(values$comparison_results)
    
    if (length(values$comparison_results) == 0) {
      return(NULL)
    }
    
    combined <- do.call(rbind, values$comparison_results)
    datatable(combined, 
              options = list(scrollX = TRUE, pageLength = 25),
              filter = 'top')
  })
  
  # Comparison overlap visualization
  output$comparisonOverlap <- renderPlotly({
    req(values$comparison_results)
    
    if (length(values$comparison_results) < 2) {
      return(NULL)
    }
    
    # Create overlap matrix
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
      layout(title = "Drug Overlap Between Profiles",
             xaxis = list(title = ""),
             yaxis = list(title = ""))
  })
  
  # Comparison score distribution
  output$comparisonScoreDist <- renderPlotly({
    req(values$comparison_results)
    
    if (length(values$comparison_results) == 0) {
      return(NULL)
    }
    
    combined <- do.call(rbind, values$comparison_results)
    
    plot_ly(data = combined, x = ~profile, y = ~cmap_score, 
            type = "box", color = ~profile) %>%
      layout(title = "CMap Score Distribution by Profile",
             xaxis = list(title = "Profile"),
             yaxis = list(title = "CMap Score"),
             showlegend = FALSE)
  })
  
  # Download handlers
  output$downloadResults <- downloadHandler(
    filename = function() {
      paste("drug_repurposing_results_", Sys.Date(), ".csv", sep = "")
    },
    content = function(file) {
      req(values$drugs_valid)
      write.csv(values$drugs_valid, file, row.names = FALSE)
    }
  )
  
  output$downloadRData <- downloadHandler(
    filename = function() {
      paste("drug_repurposing_results_", Sys.Date(), ".RData", sep = "")
    },
    content = function(file) {
      req(values$results)
      results <- list(
        drugs = values$results,
        drugs_valid = values$drugs_valid,
        signature = if(!is.null(values$drp_object)) values$drp_object$dz_signature else NULL
      )
      save(results, file = file)
    }
  )
  
  output$downloadComparison <- downloadHandler(
    filename = function() {
      paste("profile_comparison_", Sys.Date(), ".csv", sep = "")
    },
    content = function(file) {
      req(values$comparison_results)
      combined <- do.call(rbind, values$comparison_results)
      write.csv(combined, file, row.names = FALSE)
    }
  )
  
  # Visualizations (single analysis)
  output$volcanoPlot <- renderPlotly({
    req(values$results)
    
    plot_ly(data = values$results,
            x = ~cmap_score,
            y = ~-log10(q),
            type = "scatter",
            mode = "markers",
            text = ~paste("Drug:", exp_id, "<br>Score:", round(cmap_score, 3), 
                         "<br>Q-value:", format(q, scientific = TRUE)),
            hoverinfo = "text",
            marker = list(
              size = 6,
              color = ~cmap_score,
              colorscale = "RdBu",
              showscale = TRUE,
              colorbar = list(title = "CMap Score")
            )) %>%
      layout(title = "Volcano Plot: Drug Score vs Significance",
             xaxis = list(title = "CMap Score (negative = reversal)"),
             yaxis = list(title = "-log10(Q-value)"),
             hovermode = "closest")
  })
  
  output$scoreDist <- renderPlotly({
    req(values$results)
    
    plot_ly(data = values$results,
            x = ~cmap_score,
            type = "histogram",
            nbinsx = 50,
            marker = list(color = "steelblue")) %>%
      layout(title = "Distribution of CMap Scores",
             xaxis = list(title = "CMap Score"),
             yaxis = list(title = "Count"))
  })
  
  output$topDrugsPlot <- renderPlotly({
    req(values$drugs_valid)
    
    n <- min(input$topN, nrow(values$drugs_valid))
    top_drugs <- head(values$drugs_valid, n)
    
    plot_ly(data = top_drugs,
            y = ~reorder(name, cmap_score),
            x = ~cmap_score,
            type = "bar",
            orientation = "h",
            marker = list(color = ~cmap_score,
                         colorscale = "RdBu",
                         showscale = TRUE),
            text = ~paste("Q-value:", format(q, scientific = TRUE)),
            hoverinfo = "text") %>%
      layout(title = paste("Top", n, "Drugs by CMap Score"),
             xaxis = list(title = "CMap Score"),
             yaxis = list(title = ""),
             margin = list(l = 150))
  })
  
  output$qvalueDist <- renderPlotly({
    req(values$drugs_valid)
    
    plot_ly(data = values$drugs_valid,
            x = ~q,
            type = "histogram",
            nbinsx = 30,
            marker = list(color = "coral")) %>%
      layout(title = "Distribution of Q-values",
             xaxis = list(title = "Q-value", type = "log"),
             yaxis = list(title = "Count"))
  })
  
  output$scoreVsQ <- renderPlotly({
    req(values$drugs_valid)
    
    plot_ly(data = values$drugs_valid,
            x = ~cmap_score,
            y = ~q,
            type = "scatter",
            mode = "markers",
            text = ~name,
            hoverinfo = "text",
            marker = list(size = 8, color = "darkgreen")) %>%
      layout(title = "CMap Score vs Q-value",
             xaxis = list(title = "CMap Score"),
             yaxis = list(title = "Q-value", type = "log"))
  })
}

# Run the application
shinyApp(ui = ui, server = server)

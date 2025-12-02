#!/usr/bin/env Rscript
#' Drug Repurposing Pipeline Shiny Application
#'
#' Interactive web interface for running drug repurposing analysis.
#' Provides UI for data upload, parameter configuration, pipeline execution,
#' results visualization, and comparison across multiple analyses.
#'

library(shiny)
library(DRpipe)
library(shinydashboard)
library(fresh)
library(shinyWidgets)
library(shinycssloaders)
library(DT)
library(plotly)
library(tidyverse)
library(yaml)
library(shinyjs)

# Create modern "Scientific SaaS" theme
my_theme <- fresh::create_theme(
  fresh::adminlte_color(
    light_blue = "#093052",  # Deeper Ocean Blue (Header)
    aqua = "#3282B8",        # Accents
    green = "#00BFA5",       # Teal (Success/Action buttons)
    red = "#E05D5D"
  ),
  fresh::adminlte_sidebar(
    width = "280px",
    dark_bg = "#1B262C",     # Dark Slate Sidebar
    dark_hover_bg = "#093052",
    dark_color = "#BBE1FA"
  ),
  fresh::adminlte_global(
    content_bg = "#F4F6F9"   # Soft Gray Background
  )
)

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
      menuItem("Upload Results", tabName = "upload_results", icon = icon("file-upload")),
      menuItem("Help", tabName = "help", icon = icon("question-circle"))
    )
  ),
  
  dashboardBody(
    useShinyjs(),
    fresh::use_theme(my_theme),
    tags$head(
      tags$style(HTML("
        /* Import Inter Font */
        @import url('https://fonts.googleapis.com/css2?family=Inter:wght@300;400;600&display=swap');

        body, h1, h2, h3, h4, h5, h6 { font-family: 'Inter', sans-serif !important; }

        /* Modernize Boxes/Cards */
        .box {
          border-top: 0px solid transparent !important;
          border-radius: 12px !important;
          box-shadow: 0 4px 20px rgba(0,0,0,0.05) !important;
          border: 1px solid #E1E5EB;
        }

        /* Modernize Buttons */
        .btn {
          border-radius: 6px !important;
          font-weight: 600;
          text-transform: uppercase;
          letter-spacing: 0.5px;
          box-shadow: 0 2px 5px rgba(0,0,0,0.1);
          border: none;
          color: #ffffff !important;
        }
        .btn:hover, .btn:active, .btn:focus {
          color: #ffffff !important;
        }
        .btn-success { background-color: #00BFA5 !important; } /* Teal Action Button */
        .btn-success:hover, .btn-success:active, .btn-success:focus {
          color: #ffffff !important;
          background-color: #00a896 !important;
        }
        .btn-primary {
          color: #ffffff !important;
        }
        .btn-primary:hover, .btn-primary:active, .btn-primary:focus {
          color: #ffffff !important;
        }
        .btn-info {
          color: #ffffff !important;
        }
        .btn-info:hover, .btn-info:active, .btn-info:focus {
          color: #ffffff !important;
        }
        .btn-lg {
          color: #ffffff !important;
        }
        
        /* File Input Styling */
        .form-group.shiny-input-container {
          margin-bottom: 20px;
        }
        .form-group label {
          color: #0F4C75;
          font-weight: 600;
          margin-bottom: 8px;
          display: block;
        }
        input[type='file'] {
          border: 2px dashed #3282B8 !important;
          border-radius: 8px !important;
          padding: 15px !important;
          background-color: #f8f9fa !important;
          cursor: pointer;
          transition: all 0.3s ease;
          width: 100%;
        }
        input[type='file']:hover {
          border-color: #0F4C75 !important;
          background-color: #e9ecef !important;
        }
        /* Style the Browse button */
        input[type='file']::file-selector-button {
          background-color: #87CEEB !important;
          color: #ffffff !important;
          border: none !important;
          padding: 10px 20px !important;
          border-radius: 5px !important;
          cursor: pointer !important;
          font-weight: 700 !important;
          margin-right: 10px !important;
          transition: all 0.3s ease !important;
          box-shadow: 0 2px 4px rgba(0,0,0,0.2) !important;
        }
        input[type='file']::-webkit-file-upload-button {
          background-color: #87CEEB !important;
          color: #ffffff !important;
          border: none !important;
          padding: 10px 20px !important;
          border-radius: 5px !important;
          cursor: pointer !important;
          font-weight: 700 !important;
          margin-right: 10px !important;
          transition: all 0.3s ease !important;
          box-shadow: 0 2px 4px rgba(0,0,0,0.2) !important;
        }
        input[type='file']::-ms-browse {
          background-color: #87CEEB !important;
          color: #ffffff !important;
          border: none !important;
          padding: 10px 20px !important;
          border-radius: 5px !important;
          cursor: pointer !important;
          font-weight: 700 !important;
          margin-right: 10px !important;
        }
        input[type='file']::file-selector-button:hover,
        input[type='file']::-webkit-file-upload-button:hover,
        input[type='file']::-ms-browse:hover {
          background-color: #5BA5D1 !important;
          color: #ffffff !important;
        }
        .progress-bar {
          background-color: #00BFA5 !important;
        }
        
        /* Hero Section for Home Tab */
        .home-hero {
          background: linear-gradient(135deg, #faf8ff 0%, #f5f2ff 50%, #f8f6ff 100%);
          background-image: 
            radial-gradient(rgba(65,105,225,0.16) 2px, transparent 2px),
            linear-gradient(135deg, #faf8ff 0%, #f5f2ff 50%, #f8f6ff 100%);
          background-size: 20px 20px, 100%;
          background-position: 0 0, 0 0;
          padding: 60px 40px;
          border-radius: 12px;
          text-align: center;
          margin-bottom: 30px;
          border: 1px solid #c0d8e8;
        }
        
        /* Keep existing analysis-type-card and other styles */
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
        
        .home-header {
          background: linear-gradient(135deg, #0F4C75 0%, #09344A 100%);
          color: white;
          padding: 40px 20px;
          border-radius: 12px;
          margin-bottom: 30px;
          box-shadow: 0 4px 6px rgba(0,0,0,0.1);
        }
        .home-title {
          font-size: 36px;
          font-weight: bold;
          margin: 0 0 10px 0;
          display: inline-block;
          background: #093052; /* Deepened header color */
          color: #ffffff;
          padding: 10px 18px;
          border-radius: 12px;
          box-shadow: 0 2px 8px rgba(9,48,82,0.25);
        }
        .home-subtitle {
          font-size: 18px;
          opacity: 0.95;
          margin: 0;
        }
        .feature-card {
          border: none;
          border-radius: 12px;
          padding: 25px;
          margin-bottom: 20px;
          background: linear-gradient(to bottom right, #f8f9fa, #e9ecef);
          border-left: 4px solid #0F4C75;
          transition: all 0.3s ease;
          box-shadow: 0 2px 4px rgba(0,0,0,0.05);
        }
        .feature-card:hover {
          box-shadow: 0 4px 12px rgba(0,0,0,0.1);
          transform: translateY(-2px);
        }
        .feature-card h4 {
          color: #0F4C75;
          margin-top: 0;
          font-weight: bold;
        }
        .feature-icon {
          font-size: 24px;
          color: #0F4C75;
          margin-right: 10px;
        }
        .section-title {
          color: #0F4C75;
          border-bottom: 2px solid #3282B8;
          padding-bottom: 10px;
          margin-top: 30px;
          margin-bottom: 20px;
          font-weight: bold;
          font-size: 20px;
        }
        .workflow-step {
          display: flex;
          align-items: flex-start;
          margin: 15px 0;
        }
        .workflow-number {
          background-color: #0F4C75;
          color: white;
          width: 35px;
          height: 35px;
          border-radius: 50%;
          display: flex;
          align-items: center;
          justify-content: center;
          font-weight: bold;
          margin-right: 15px;
          flex-shrink: 0;
        }
        .workflow-content {
          flex: 1;
        }
        .github-link {
          display: inline-block;
          padding: 10px 20px;
          background-color: #333;
          color: white;
          border-radius: 5px;
          text-decoration: none;
          margin-top: 10px;
          transition: background-color 0.3s;
        }
        .github-link:hover {
          background-color: #555;
          text-decoration: none;
          color: white;
        }
        .start-buttons {
          display: flex;
          gap: 15px;
          margin-top: 20px;
          flex-wrap: wrap;
        }
      "))
    ),
    
    tabItems(
      # Home Tab
      tabItem(tabName = "home",
        # Header
        fluidRow(
          column(12,
            div(class = "home-hero",
              div(class = "home-title", "🔬 Drug Repurposing Pipeline"),
              div(class = "home-subtitle", "Identify existing drugs for new therapeutic applications")
            )
          )
        ),
        
        # About Section
        fluidRow(
          column(12,
            box(
              title = "About This Application",
              width = 12,
              status = "primary",
              solidHeader = TRUE,
              collapsible = TRUE,
              collapsed = FALSE,
              p("The Drug Repurposing Pipeline is a comprehensive analysis tool that identifies existing FDA-approved and other known drugs that could be repurposed for new therapeutic applications. By analyzing disease gene expression signatures and comparing them against drug-induced transcriptional profiles, this application helps researchers discover potential new uses for existing medications."),
              p("This approach can significantly accelerate drug discovery and reduce development costs by leveraging extensive existing safety data and known pharmacological properties of established drugs."),
              p(
                strong("Learn more about the project on GitHub: "),
                a(href = "https://github.com/enockniyonkuru/drug_repurposing", 
                  target = "_blank",
                  class = "github-link",
                  icon("github"), " View Repository")
              )
            )
          )
        ),
        
        # Workflow Section
        fluidRow(
          column(12,
            div(class = "section-title", "📋 How It Works")
          )
        ),
        
        fluidRow(
          column(6,
            div(class = "feature-card",
              h4(icon("exchange-alt", class = "feature-icon"), "Your Own Analysis"),
              div(class = "workflow-step",
                div(class = "workflow-number", "1"),
                div(class = "workflow-content",
                  strong("Choose Analysis Type:"), br(),
                  "Single analysis with one profile or comparative analysis across multiple profiles."
                )
              ),
              div(class = "workflow-step",
                div(class = "workflow-number", "2"),
                div(class = "workflow-content",
                  strong("Upload Your Data:"), br(),
                  "Provide your disease gene expression signature (gene symbols and log2 fold-change values)."
                )
              ),
              div(class = "workflow-step",
                div(class = "workflow-number", "3"),
                div(class = "workflow-content",
                  strong("Configure Parameters:"), br(),
                  "Select analysis profiles (CMAP/TAHOE) and customize settings."
                )
              ),
              div(class = "workflow-step",
                div(class = "workflow-number", "4"),
                div(class = "workflow-content",
                  strong("Run Analysis:"), br(),
                  "Execute the pipeline (7-30 minutes depending on configuration)."
                )
              ),
              div(class = "workflow-step",
                div(class = "workflow-number", "5"),
                div(class = "workflow-content",
                  strong("View Results:"), br(),
                  "Explore drug candidates, rankings, and interactive visualizations."
                )
              )
            )
          ),
          
          column(6,
            div(class = "feature-card",
              h4(icon("file-import", class = "feature-icon"), "Pre-computed Results"),
              p("Already have results from running the pipeline? You can upload your pre-computed results files here to visualize and interact with the data without re-running the analysis."),
              p("This option is useful if you:"),
              tags$ul(
                tags$li("Ran the analysis via command-line terminal"),
                tags$li("Have existing results from previous analyses"),
                tags$li("Want to visualize results without keeping a browser window open"),
                tags$li("Need to upload and share results for collaborative analysis")
              ),
              p(style = "margin-top: 20px; padding: 10px; background-color: #e3f2fd; border-radius: 5px;",
                strong("Note:"), " You can access the upload results feature anytime through the 'Upload Results' menu item in the sidebar."
              )
            )
          )
        ),
        
        # Quick Start Section
        fluidRow(
          column(12,
            div(class = "section-title", "🚀 Quick Start")
          )
        ),
        
        fluidRow(
          column(12,
            box(
              title = "Ready to get started?",
              width = 12,
              status = "success",
              solidHeader = TRUE,
              p("Choose how you'd like to proceed:"),
              div(class = "start-buttons",
                actionButton("startBtn", "Start New Analysis →", 
                            class = "btn-success btn-lg", 
                            icon = icon("play-circle")),
                actionButton("uploadResultsBtn", "Upload Results →", 
                            class = "btn-info btn-lg", 
                            icon = icon("file-upload"))
              )
            )
          )
        )
      ),
      
      # Choose Analysis Type Tab
      tabItem(tabName = "choose_type",
        fluidRow(
          box(
            title = "Step 1: Choose Your Path",
            width = 12,
            status = "primary",
            solidHeader = TRUE,
            h4("Select how you'd like to proceed:")
          )
        ),
        
        fluidRow(
          column(4,
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
          
          column(4,
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
          ),
          
          column(4,
            div(id = "uploadResultsCard", class = "analysis-type-card",
              onclick = "Shiny.setInputValue('analysisTypeClick', 'upload', {priority: 'event'});",
              div(style = "text-align: center;",
                icon("file-upload", class = "fa-4x", style = "color: #dd4b39;"),
                h3("Upload Results"),
                p(style = "font-size: 16px; margin-top: 15px;",
                  "Load pre-computed results for visualization."
                ),
                tags$ul(style = "text-align: left; margin-top: 20px;",
                  tags$li("Upload your pre-computed results"),
                  tags$li("Visualize and interact with data"),
                  tags$li("No need to re-run analysis"),
                  tags$li("Quick access to saved findings")
                )
              )
            )
          )
        ),
        
        fluidRow(
          box(
            title = "Selected Option",
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
            shinycssloaders::withSpinner(
              DTOutput("dataPreview"),
              type = 4,
              color = "#0F4C75"
            ),
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
            # Warning/Info box about runtime
            box(
              title = "Important: Runtime Information",
              width = 12,
              status = "warning",
              solidHeader = TRUE,
              collapsible = TRUE,
              collapsed = FALSE,
              h4("Expected Analysis Duration:"),
              tags$ul(
                tags$li(strong("CMAP Analysis: "), "8-15 minutes per profile"),
                tags$li(strong("TAHOE Analysis: "), "30-50 minutes per profile")
              ),
              h4("Important Requirements:"),
              tags$ul(
                tags$li(strong("Keep your browser open"), " - The analysis runs in your current session and will stop if you close the browser or leave the page"),
                tags$li(strong("Do not refresh the page"), " - You will lose progress if you refresh"),
                tags$li(strong("Stable internet connection"), " - Required for the entire duration of analysis")
              ),
              h4("Alternative Option:"),
              p("If you prefer not to keep the browser open, you can run the analysis from the command line terminal and then upload the results here using the 'Upload Results' tab to visualize and interact with them."),
              style = "background-color: #fff3cd; border-left: 5px solid #ff9800;"
            ),
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
      
      # Upload Pre-computed Results Tab
      tabItem(tabName = "upload_results",
        fluidRow(
          box(
            title = "Upload Pre-computed Results",
            width = 12,
            status = "primary",
            solidHeader = TRUE,
            p("If you have already run the pipeline from the terminal, you can upload the generated results CSV file here to visualize and interact with the data without re-running the analysis."),
            hr(),
            h4("How to generate results file:"),
            tags$ol(
              tags$li("Run the pipeline from terminal: ", tags$code("Rscript scripts/runall.R")),
              tags$li("Look in ", tags$code("scripts/results/[analysis_folder]/"), " for files named ", tags$code("*_hits_logFC_*.csv")),
              tags$li("Upload that CSV file below")
            )
          )
        ),
        
        fluidRow(
          box(
            title = "Upload Results CSV",
            width = 6,
            status = "info",
            solidHeader = TRUE,
            fileInput("uploadResultsFile", "Choose CSV File",
                     accept = c("text/csv", ".csv")),
            hr(),
            actionButton("loadResultsBtn", "Load Results", 
                        class = "btn-primary", icon = icon("upload"))
          ),
          
          box(
            title = "File Information",
            width = 6,
            status = "success",
            solidHeader = TRUE,
            h4("Expected CSV columns:"),
            tags$ul(
              tags$li("exp_id - Experiment ID"),
              tags$li("name - Drug name"),
              tags$li("cmap_score - CMap reversal score"),
              tags$li("q - Q-value (significance)"),
              tags$li("cell_line - Cell line used"),
              tags$li("concentration - Drug concentration"),
              tags$li("array_platform - Platform used")
            ),
            h4("Result statistics:"),
            textOutput("uploadedResultsStats")
          )
        ),
        
        fluidRow(
          box(
            title = "Preview",
            width = 12,
            status = "success",
            solidHeader = TRUE,
            shinycssloaders::withSpinner(
              DTOutput("uploadedResultsTable"),
              type = 4,
              color = "#0F4C75"
            ),
            br(),
            downloadButton("downloadUploadedResults", "Download Results"),
            style = "display: none;",
            id = "uploadedResultsPanel"
          )
        ),
        
        fluidRow(
          box(
            title = "Visualizations",
            width = 12,
            status = "info",
            solidHeader = TRUE,
            tabsetPanel(
              tabPanel(
                "Score Distribution",
                br(),
                shinycssloaders::withSpinner(
                  plotly::plotlyOutput("uploadedScorePlot", height = "500px"),
                  type = 4,
                  color = "#0F4C75"
                )
              ),
              tabPanel(
                "Top Drugs",
                br(),
                shinycssloaders::withSpinner(
                  plotly::plotlyOutput("uploadedTopDrugsPlot", height = "500px"),
                  type = 4,
                  color = "#0F4C75"
                )
              ),
              tabPanel(
                "Drug Details",
                br(),
                shinycssloaders::withSpinner(
                  DTOutput("uploadedDrugDetailsTable"),
                  type = 4,
                  color = "#0F4C75"
                )
              )
            ),
            style = "display: none;",
            id = "uploadedVisualizationsPanel"
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
    comparison_results = list(),
    drug_signatures = list(
      "CMAP" = "../scripts/data/drug_signatures/cmap_signatures.RData",
      "TAHOE" = "../scripts/data/drug_signatures/tahoe_signatures.RData"
    ),
    selected_drug_signature = "../scripts/data/drug_signatures/cmap_signatures.RData",
    # Sweep mode specific results
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
      cmap = "../scripts/data/drug_signatures/cmap_signatures.RData",
      tahoe = "../scripts/data/drug_signatures/tahoe_signatures.RData"
    )
    values$selected_drug_signature <- signature_map[[input$drugSignatureChoice]]
  })
  
  # Observer for drug signature selection (comparative analysis)
  observeEvent(input$compDrugSignatureChoice, {
    req(input$compDrugSignatureChoice)
    signature_map <- list(
      cmap = "../scripts/data/drug_signatures/cmap_signatures.RData",
      tahoe = "../scripts/data/drug_signatures/tahoe_signatures.RData"
    )
    values$selected_drug_signature <- signature_map[[input$compDrugSignatureChoice]]
  })
  
  # Navigation buttons
  observeEvent(input$startBtn, {
    updateTabItems(session, "sidebar", "choose_type")
  })
  
  observeEvent(input$uploadResultsBtn, {
    updateTabItems(session, "sidebar", "upload_results")
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
      runjs("$('#singleAnalysisCard').addClass('selected'); $('#comparativeAnalysisCard').removeClass('selected'); $('#uploadResultsCard').removeClass('selected');")
    } else if (input$analysisTypeClick == "comparative") {
      runjs("$('#comparativeAnalysisCard').addClass('selected'); $('#singleAnalysisCard').removeClass('selected'); $('#uploadResultsCard').removeClass('selected');")
    } else if (input$analysisTypeClick == "upload") {
      runjs("$('#uploadResultsCard').addClass('selected'); $('#singleAnalysisCard').removeClass('selected'); $('#comparativeAnalysisCard').removeClass('selected');")
    }
  })
  
  # Render selected analysis type
  output$selectedAnalysisType <- renderUI({
    if (is.null(values$analysis_type)) {
      return(p(style = "color: #999; font-style: italic;", 
              icon("info-circle"), " Please select an option above"))
    }
    
    type_text <- if (values$analysis_type == "single") {
      "Single Analysis - Run with one configuration profile"
    } else if (values$analysis_type == "comparative") {
      "Comparative Analysis - Compare multiple configuration profiles"
    } else if (values$analysis_type == "upload") {
      "Upload Results - Visualize pre-computed results"
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
    
    if (values$analysis_type == "upload") {
      # Directly go to upload results tab
      updateTabItems(session, "sidebar", "upload_results")
      showNotification("Proceeding to upload results...", type = "message")
    } else {
      # Go to data upload for analysis
      updateTabItems(session, "sidebar", "upload")
      showNotification(paste("Analysis type set to:", 
                            ifelse(values$analysis_type == "single", "Single Analysis", "Comparative Analysis")), 
                      type = "message")
    }
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
      path <- "../scripts/data/disease_signatures/CoreFibroidSignature_All_Datasets.csv"
      if (file.exists(path)) {
        values$data <- read.csv(path, stringsAsFactors = FALSE, check.names = FALSE)
        showNotification("Fibroid data loaded!", type = "message")
      } else {
        showNotification(paste("File not found:", path), type = "error")
      }
    }, error = function(e) {
      showNotification(paste("Error:", e$message), type = "error")
    })
  })
  
  observeEvent(input$loadEndothelial, {
    tryCatch({
      path <- "../scripts/data/disease_signatures/Endothelia_DEG.csv"
      if (file.exists(path)) {
        values$data <- read.csv(path, stringsAsFactors = FALSE, check.names = FALSE)
        showNotification("Endothelial data loaded!", type = "message")
      } else {
        showNotification(paste("File not found:", path), type = "error")
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
          
          h4("Drug Signature Selection"),
          selectInput("drugSignatureChoice", "Choose Drug Signature:",
                     choices = c("CMAP" = "cmap",
                               "TAHOE" = "tahoe"),
                     selected = "cmap"),
          p(style = "color: #666; font-size: 12px;",
            "• CMAP: CMap L1000 signatures database",
            br(),
            "• TAHOE: TAHOE drug signatures database"),
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
          shinyWidgets::materialSwitch("customReversalOnly", "Reversal Only", value = TRUE, status = "success"),
          
          selectInput("customMode", "Analysis Mode:", 
                     choices = c("Single Cutoff" = "single", "Sweep Mode" = "sweep"),
                     selected = "single"),
          
          # Sweep mode parameters (conditional)
          conditionalPanel(
            condition = "input.customMode == 'sweep'",
            h4("Sweep Mode Settings"),
            shinyWidgets::materialSwitch("customSweepAutoGrid", "Auto-generate threshold grid", value = TRUE, status = "success"),
            numericInput("customSweepStep", "Step size:", value = 0.1, min = 0.05, step = 0.05),
            numericInput("customSweepMinFrac", "Min fraction of genes:", value = 0.20, min = 0.05, max = 1, step = 0.05),
            numericInput("customSweepMinGenes", "Min number of genes:", value = 200, min = 50, step = 50),
            shinyWidgets::materialSwitch("customSweepStopOnSmall", "Stop if signature too small", value = FALSE, status = "success"),
            shinyWidgets::pickerInput("customCombineLogFC", "Combine log2FC columns:", 
                       choices = c("Average" = "average", "Median" = "median", "First" = "first"),
                       selected = "average"),
            shinyWidgets::pickerInput("customRobustRule", "Robust drug rule:", 
                       choices = c("All cutoffs" = "all", "K of N cutoffs" = "k_of_n"),
                       selected = "all"),
            conditionalPanel(
              condition = "input.customRobustRule == 'k_of_n'",
              numericInput("customRobustK", "Minimum cutoffs (k):", value = 2, min = 1, step = 1)
            ),
            shinyWidgets::pickerInput("customAggregate", "Score aggregation:", 
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
          
          h4("Drug Signature Selection"),
          selectInput("compDrugSignatureChoice", "Choose Drug Signature:",
                     choices = c("CMAP" = "cmap",
                               "TAHOE" = "tahoe"),
                     selected = "cmap"),
          p(style = "color: #666; font-size: 12px;",
            "• CMAP: CMap L1000 signatures database",
            br(),
            "• TAHOE: TAHOE drug signatures database"),
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
          shinyWidgets::materialSwitch("compCustomReversalOnly", "Reversal Only", value = TRUE, status = "success"),
          
          selectInput("compCustomMode", "Analysis Mode:", 
                     choices = c("Single Cutoff" = "single", "Sweep Mode" = "sweep"),
                     selected = "single"),
          
          # Sweep mode parameters for comparative
          conditionalPanel(
            condition = "input.compCustomMode == 'sweep'",
            h4("Sweep Mode Settings"),
            shinyWidgets::materialSwitch("compCustomSweepAutoGrid", "Auto-generate threshold grid", value = TRUE, status = "success"),
            numericInput("compCustomSweepStep", "Step size:", value = 0.1, min = 0.05, step = 0.05),
            numericInput("compCustomSweepMinFrac", "Min fraction of genes:", value = 0.20, min = 0.05, max = 1, step = 0.05),
            numericInput("compCustomSweepMinGenes", "Min number of genes:", value = 200, min = 50, step = 50),
            shinyWidgets::materialSwitch("compCustomSweepStopOnSmall", "Stop if signature too small", value = FALSE, status = "success"),
            shinyWidgets::pickerInput("compCustomCombineLogFC", "Combine log2FC columns:", 
                       choices = c("Average" = "average", "Median" = "median", "First" = "first"),
                       selected = "average"),
            shinyWidgets::pickerInput("compCustomRobustRule", "Robust drug rule:", 
                       choices = c("All cutoffs" = "all", "K of N cutoffs" = "k_of_n"),
                       selected = "all"),
            conditionalPanel(
              condition = "input.compCustomRobustRule == 'k_of_n'",
              numericInput("compCustomRobustK", "Minimum cutoffs (k):", value = 2, min = 1, step = 1)
            ),
            shinyWidgets::pickerInput("compCustomAggregate", "Score aggregation:", 
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
        # Store the profile name for later use in run_single_analysis
        values$selected_profile_name <- input$selectedExistingProfile
        
        if (!is.null(profile) && !is.null(values$data)) {
          # IMPORTANT: Load the drug signature path from the profile
          # Adjust path to be relative to shiny_app directory
          if (!is.null(profile$paths$signatures)) {
            sig_path <- profile$paths$signatures
            # If path doesn't start with "/" or "../", prepend "../scripts/"
            if (!grepl("^/|^\\.\\./", sig_path)) {
              sig_path <- file.path("../scripts", sig_path)
            }
            values$selected_drug_signature <- sig_path
          }
          
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
    if (is.null(values$analysis_type)) {
      cat("Please select an analysis type first.\n")
      return()
    }
    
    if (values$analysis_type == "single") {
      cat("Single Analysis Configuration:\n")
      if (!is.null(input$customGeneKey)) {
        cat("  Gene Column:", input$customGeneKey, "\n")
      }
      if (!is.null(input$customLogFCCutoff)) {
        cat("  Log2FC Cutoff:", input$customLogFCCutoff, "\n")
      }
      if (!is.null(input$customMode)) {
        cat("  Mode:", input$customMode, "\n")
        if (input$customMode == "sweep") {
          cat("\nSweep Settings:\n")
          if (!is.null(input$customSweepAutoGrid)) {
            cat("  Auto-grid:", input$customSweepAutoGrid, "\n")
          }
          if (!is.null(input$customSweepStep)) {
            cat("  Step size:", input$customSweepStep, "\n")
          }
          if (!is.null(input$customRobustRule)) {
            cat("  Robust rule:", input$customRobustRule, "\n")
          }
        }
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
    if (is.null(values$analysis_type)) {
      return(p("Please select an analysis type first."))
    }
    
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
        
        # Check if using a profile from config
        profile_selected <- !is.null(values$selected_profile_name) && values$selected_profile_name != ""
        
        if (profile_selected) {
          # Use paths from the profile config
          profile_config <- values$config_profiles[[values$selected_profile_name]]
          
          # Get paths from profile, prepending "../scripts/" if relative paths
          selected_meta <- if (!is.null(profile_config$paths$drug_meta)) {
            meta_path <- profile_config$paths$drug_meta
            if (!grepl("^/|^\\.\\./", meta_path)) {
              file.path("../scripts", meta_path)
            } else {
              meta_path
            }
          } else {
            "../scripts/data/drug_signatures/cmap_drug_experiments_new.csv"
          }
          
          # IMPORTANT: If drug_valid is NULL in config, pass NULL to DRP
          # Otherwise, use the specified path
          selected_valid <- if (!is.null(profile_config$paths$drug_valid)) {
            if (is.na(profile_config$paths$drug_valid) || profile_config$paths$drug_valid == "") {
              NULL
            } else {
              valid_path <- profile_config$paths$drug_valid
              if (!grepl("^/|^\\.\\./", valid_path)) {
                file.path("../scripts", valid_path)
              } else {
                valid_path
              }
            }
          } else {
            NULL
          }
        } else {
          # Fall back to signature-based mapping only if NOT using a profile
          drug_meta_mapping <- list(
            "../scripts/data/drug_signatures/cmap_signatures.RData" = "../scripts/data/drug_signatures/cmap_drug_experiments_new.csv",
            "../scripts/data/drug_signatures/tahoe_signatures.RData" = "../scripts/data/drug_signatures/tahoe_drug_experiments_new.csv",
            "../scripts/data/drug_rep_cmap_ranks_shared_genes_drugs.RData" = "../scripts/data/drug_signatures/cmap_drug_experiments_new.csv",
            "../scripts/data/drug_rep_tahoe_ranks_shared_genes_drugs.RData" = "../scripts/data/drug_signatures/tahoe_drug_experiments_new.csv"
          )
          selected_meta <- drug_meta_mapping[[values$selected_drug_signature]] %||% "../scripts/data/drug_signatures/cmap_drug_experiments_new.csv"
          selected_valid <- NULL
        }
        
          drp_args <- c(
          list(
            signatures_rdata = values$selected_drug_signature,
            disease_path = temp_file,
            drug_meta_path = selected_meta,
            drug_valid_path = selected_valid,
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
          # Single mode needs explicit annotation
          values$analysisLog <- paste0(values$analysisLog, "Annotating results...\n")
          incProgress(0.2)
          drp$annotate_and_filter()
        } else {
          # Sweep mode handles annotation internally during parallel processing
          drp$run_sweep()
          incProgress(0.2)
        }
        
        # Store the DRP object to access sweep results
        # Expose a couple of backward-compatible fields expected by the Shiny UI
        # The DRP class uses `dz_signature` and `cmap_signatures`; some UI
        # code expects `disease_sig` and `cmap_sig`. Add aliases here so the
        # heatmap preparation code can find them.
        if (!is.null(drp)) {
          if (is.null(drp$disease_sig)) {
            if (!is.null(drp$dz_signature)) {
              drp$disease_sig <- drp$dz_signature
            } else if (!is.null(drp$dz_signature_list) && length(drp$dz_signature_list) > 0) {
              # use the first available cleaned signature as a fallback
              first_sig <- drp$dz_signature_list[[1]]
              if (!is.null(first_sig$signature)) drp$disease_sig <- first_sig$signature
            }
          }
          if (is.null(drp$cmap_sig) && !is.null(drp$cmap_signatures)) {
            drp$cmap_sig <- drp$cmap_signatures
          }
        }
        values$drp_object <- drp
        values$is_sweep_mode <- (drp$mode == "sweep")
        
        # For sweep mode, capture sweep-specific results
        if (values$is_sweep_mode) {
          values$sweep_robust_hits <- drp$robust_hits
          values$sweep_cutoff_summary <- drp$cutoff_summary
          values$sweep_img_dir <- file.path(drp$out_dir, "img")
          
          # Use robust_hits as drugs_valid for compatibility
          # IMPORTANT: Include exp_id for heatmap generation
          if (!is.null(drp$robust_hits) && nrow(drp$robust_hits) > 0) {
            values$drugs_valid <- data.frame(
              exp_id = if ("exp_id" %in% names(drp$robust_hits)) drp$robust_hits$exp_id else NA,
              name = drp$robust_hits$name,
              cmap_score = drp$robust_hits$aggregated_score,
              q = drp$robust_hits$min_q,
              n_support = drp$robust_hits$n_support,
              stringsAsFactors = FALSE
            )
            # Sort by absolute cmap_score (strength) in descending order
            values$drugs_valid <- values$drugs_valid[order(abs(values$drugs_valid$cmap_score), decreasing = TRUE), ]
            values$results <- values$drugs_valid
          } else {
            values$drugs_valid <- data.frame()
            values$results <- data.frame()
          }
        } else {
          # Single mode: use drugs_valid as normal
          values$results <- drp$drugs
          values$drugs_valid <- drp$drugs_valid
          # Sort by absolute cmap_score (strength) in descending order
          if (!is.null(values$drugs_valid) && nrow(values$drugs_valid) > 0) {
            values$drugs_valid <- values$drugs_valid[order(abs(values$drugs_valid$cmap_score), decreasing = TRUE), ]
          }
          # IMPORTANT: For single mode, add exp_id to drugs_valid from the full drugs table
          if (!is.null(values$drugs_valid) && nrow(values$drugs_valid) > 0 && 
              !"exp_id" %in% names(values$drugs_valid) && 
              !is.null(drp$drugs) && "exp_id" %in% names(drp$drugs)) {
            values$drugs_valid <- merge(values$drugs_valid, 
                                       drp$drugs[, c("name", "exp_id")], 
                                       by = "name", 
                                       all.x = TRUE,
                                       sort = FALSE)
            # Re-sort after merge
            values$drugs_valid <- values$drugs_valid[order(abs(values$drugs_valid$cmap_score), decreasing = TRUE), ]
          }
        }
        
        hit_count <- if (!is.null(values$drugs_valid)) nrow(values$drugs_valid) else 0
        values$analysisLog <- paste0(values$analysisLog, "\nComplete! Found ", 
                                     hit_count, " significant hits.\n")
        
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
          
          # IMPORTANT: Use the drug signature from the profile, not the global selection
          profile_drug_signature <- if (!is.null(profile_config$paths$signatures)) {
            sig_path <- profile_config$paths$signatures
            # If path doesn't start with "/" or "../", prepend "../scripts/"
            if (!grepl("^/|^\\.\\./", sig_path)) {
              sig_path <- file.path("../scripts", sig_path)
            }
            sig_path
          } else {
            values$selected_drug_signature
          }
          
          # Build DRP arguments including sweep parameters if present
          # Use metadata paths from profile
          profile_meta_path <- if (!is.null(profile_config$paths$drug_meta)) {
            meta_path <- profile_config$paths$drug_meta
            if (!grepl("^/|^\\.\\./", meta_path)) {
              file.path("../scripts", meta_path)
            } else {
              meta_path
            }
          } else {
            "../scripts/data/drug_signatures/cmap_drug_experiments_new.csv"
          }
          
          # IMPORTANT: Respect drug_valid setting from profile
          # If drug_valid is NULL or empty string in config, pass NULL to DRP
          profile_valid_path <- if (!is.null(profile_config$paths$drug_valid)) {
            if (is.na(profile_config$paths$drug_valid) || profile_config$paths$drug_valid == "") {
              NULL
            } else {
              valid_path <- profile_config$paths$drug_valid
              if (!grepl("^/|^\\.\\./", valid_path)) {
                file.path("../scripts", valid_path)
              } else {
                valid_path
              }
            }
          } else {
            NULL
          }
          
          drp_args <- list(
            signatures_rdata = profile_drug_signature,
            disease_path = temp_file,
            drug_meta_path = profile_meta_path,
            drug_valid_path = profile_valid_path,
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
          
          # Add sweep parameters ONLY if mode is "sweep"
          if (drp_args$mode == "sweep") {
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
          }
          
          drp <- do.call(DRP$new, drp_args)
          
          drp$load_cmap()$load_disease()$clean_signature()
          
          if (drp$mode == "single") {
            drp$run_single()
            # Single mode needs explicit annotation
            drp$annotate_and_filter()
          } else {
            # Sweep mode handles annotation internally
            drp$run_sweep()
          }
          
          if (!is.null(drp$drugs_valid) && nrow(drp$drugs_valid) > 0) {
            drp$drugs_valid$profile <- profile_name
            # Sort by absolute cmap_score (strength) in descending order
            drp$drugs_valid <- drp$drugs_valid[order(abs(drp$drugs_valid$cmap_score), decreasing = TRUE), ]
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
        
        fluidRow(
          box(
            title = "Significant Drug Hits",
            width = 12,
            status = "success",
            solidHeader = TRUE,
            downloadButton("downloadResults", "Download Results CSV"),
            hr(),
            shinycssloaders::withSpinner(
              DTOutput("resultsTable"),
              type = 4,
              color = "#0F4C75"
            )
          )
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
      # Check if sweep mode to show additional sweep-specific visualizations
      if (values$is_sweep_mode && !is.null(values$sweep_robust_hits)) {
        fluidRow(
          box(
            title = "Top Drugs by CMap Score",
            width = 12,
            status = "primary",
            solidHeader = TRUE,
            sliderInput("topN", "Number of drugs:", min = 5, max = 30, value = 15),
            shinycssloaders::withSpinner(
              plotlyOutput("topDrugsPlot", height = "500px"),
              type = 4,
              color = "#0F4C75"
            )
          ),
          
          box(
            title = "Score Distribution",
            width = 6,
            status = "info",
            solidHeader = TRUE,
            shinycssloaders::withSpinner(
              plotlyOutput("scoreDist", height = "400px"),
              type = 4,
              color = "#0F4C75"
            )
          ),
          
          box(
            title = "Sweep Mode: Cutoff Performance",
            width = 6,
            status = "warning",
            solidHeader = TRUE,
            p("Interactive visualization of threshold performance"),
            shinycssloaders::withSpinner(
              plotlyOutput("sweepCutoffPlot", height = "400px"),
              type = 4,
              color = "#0F4C75"
            )
          ),
          
          box(
            title = "Sweep Mode: Threshold Summary Table",
            width = 12,
            status = "info",
            solidHeader = TRUE,
            p("Detailed performance metrics for each log2FC threshold tested"),
            shinycssloaders::withSpinner(
              DTOutput("sweepCutoffTable"),
              type = 4,
              color = "#0F4C75"
            )
          )
        )
      } else {
        # Standard single mode plots
        fluidRow(
          box(
            title = "Top Drugs by CMap Score",
            width = 12,
            status = "primary",
            solidHeader = TRUE,
            sliderInput("topN", "Number of drugs:", min = 5, max = 30, value = 15),
            shinycssloaders::withSpinner(
              plotlyOutput("topDrugsPlot", height = "500px"),
              type = 4,
              color = "#0F4C75"
            )
          ),
          
          box(
            title = "Disease-Drug Reversal Heatmap",
            width = 12,
            status = "primary",
            solidHeader = TRUE,
            p("Heatmap showing how disease signature aligns or reverses with top drug signatures"),
            sliderInput("heatmapTopN", "Number of top drugs to display:", min = 5, max = 20, value = 10),
            shinycssloaders::withSpinner(
              plotlyOutput("reversalHeatmap", height = "600px"),
              type = 4,
              color = "#0F4C75"
            )
          ),
          
          box(
            title = "Score Distribution",
            width = 6,
            status = "info",
            solidHeader = TRUE,
            shinycssloaders::withSpinner(
              plotlyOutput("scoreDist", height = "400px"),
              type = 4,
              color = "#0F4C75"
            )
          ),
          
          box(
            title = "Volcano Plot",
            width = 6,
            status = "info",
            solidHeader = TRUE,
            shinycssloaders::withSpinner(
              plotlyOutput("volcanoPlot", height = "400px"),
              type = 4,
              color = "#0F4C75"
            )
          )
        )
      }
    } else {
      fluidRow(
        box(
          title = "Profile Overlap (At Least 2)",
          width = 12,
          status = "success",
          solidHeader = TRUE,
          p("Drugs appearing in at least 2 profiles"),
          plotOutput("comparisonOverlapAtLeast2", height = "500px")
        ),
        
        box(
          title = "Profile Overlap Heatmap",
          width = 12,
          status = "success",
          solidHeader = TRUE,
          p("Shows the number of shared drugs between each pair of profiles"),
          shinycssloaders::withSpinner(
            plotlyOutput("comparisonOverlapHeatmap", height = "500px"),
            type = 4,
            color = "#0F4C75"
          )
        ),
        
        box(
          title = "Profile UpSet Plot",
          width = 6,
          status = "success",
          solidHeader = TRUE,
          p("Intersection of drugs across profiles"),
          plotOutput("comparisonUpset", height = "500px")
        ),
        
        box(
          title = "Score Distribution by Profile",
          width = 6,
          status = "success",
          solidHeader = TRUE,
          shinycssloaders::withSpinner(
            plotlyOutput("comparisonScoreDist", height = "500px"),
            type = 4,
            color = "#0F4C75"
          )
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
  
  # Comparison overlap heatmap (improved with better color intensity)
  output$comparisonOverlapHeatmap <- renderPlotly({
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
    
    # Use a custom color scale with better intensity gradation (avoiding pure white)
    plot_ly(z = overlap_matrix, x = profiles, y = profiles, 
            type = "heatmap", 
            colorscale = list(
              c(0, "rgb(230,245,255)"),
              c(0.2, "rgb(180,215,245)"),
              c(0.4, "rgb(130,185,235)"),
              c(0.6, "rgb(80,155,225)"),
              c(0.8, "rgb(40,115,185)"),
              c(1, "rgb(10,75,145)")
            ),
            text = overlap_matrix,
            hovertemplate = "Profile 1: %{y}<br>Profile 2: %{x}<br>Shared Drugs: %{z}<extra></extra>") %>%
      layout(title = "Drug Overlap Between Profiles",
             xaxis = list(title = ""),
             yaxis = list(title = ""))
  })
  
  # Profile overlap (at least 2) - using DRpipe's pl_overlap function
  output$comparisonOverlapAtLeast2 <- renderPlot({
    req(values$comparison_results)
    
    if (length(values$comparison_results) < 2) return(NULL)
    
    tryCatch({
      # Combine all results
      combined <- do.call(rbind, lapply(names(values$comparison_results), function(profile) {
        df <- values$comparison_results[[profile]]
        df$subset_comparison_id <- profile
        df
      }))
      
      # Use DRpipe's prepare_overlap function
      mat <- DRpipe::prepare_overlap(combined, at_least2 = TRUE)
      
      if (nrow(mat) == 0) {
        plot(1, 1, type = "n", axes = FALSE, xlab = "", ylab = "")
        text(1, 1, "No drugs appear in at least 2 profiles", cex = 1.2)
        return()
      }
      
      # Create heatmap using pheatmap
      pheatmap::pheatmap(t(mat[, 2:ncol(mat)]),
                        color = colorRampPalette(c("grey95", "orange", "red3"))(100),
                        border_color = "grey60",
                        angle_col = 90,
                        fontsize_row = 12,
                        fontsize_col = 10,
                        cluster_rows = FALSE,
                        cluster_cols = TRUE,
                        legend = TRUE,
                        main = "Drugs in At Least 2 Profiles")
    }, error = function(e) {
      plot(1, 1, type = "n", axes = FALSE, xlab = "", ylab = "")
      text(1, 1, paste("Error:", e$message), cex = 1)
    })
  })
  
  # Profile UpSet plot - using DRpipe's pl_upset function
  output$comparisonUpset <- renderPlot({
    req(values$comparison_results)
    
    if (length(values$comparison_results) < 2) return(NULL)
    
    tryCatch({
      # Combine all results
      combined <- do.call(rbind, lapply(names(values$comparison_results), function(profile) {
        df <- values$comparison_results[[profile]]
        df$subset_comparison_id <- profile
        df
      }))
      
      # Use DRpipe's prepare_upset_drug function
      drugs_list <- DRpipe::prepare_upset_drug(combined)
      
      if (length(drugs_list) == 0) {
        plot(1, 1, type = "n", axes = FALSE, xlab = "", ylab = "")
        text(1, 1, "No data available for UpSet plot", cex = 1.2)
        return()
      }
      
      # Create UpSet plot
      upset_plot <- UpSetR::upset(
        UpSetR::fromList(drugs_list),
        nsets = length(drugs_list),
        order.by = "freq",
        main.bar.color = "steelblue",
        sets.bar.color = "darkgreen",
        text.scale = c(1.3, 1.3, 1, 1, 1.5, 1.2)
      )
      
      print(upset_plot)
      grid::grid.text("Drug Intersection Across Profiles", 
                     x = 0.65, y = 0.95, 
                     gp = grid::gpar(fontsize = 14, fontface = "bold"))
    }, error = function(e) {
      plot(1, 1, type = "n", axes = FALSE, xlab = "", ylab = "")
      text(1, 1, paste("Error:", e$message), cex = 1)
    })
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
  
  # Disease-Drug Reversal Heatmap
  output$reversalHeatmap <- renderPlotly({
    req(values$drugs_valid, values$drp_object)
    
    tryCatch({
      # Check if we have the necessary data
      if (is.null(values$drp_object$disease_sig) || is.null(values$drp_object$cmap_sig)) {
        return(plotly_empty() %>% 
                layout(title = "Disease or drug signatures not available"))
      }
      
      # Get top N drugs based on slider
      n <- min(input$heatmapTopN, nrow(values$drugs_valid))
      top_drugs <- head(values$drugs_valid, n)
      
      # Check if exp_id column exists, if not try to get it from the full drugs table
      if (!"exp_id" %in% names(top_drugs)) {
        # Try to get exp_id from the full drugs table in drp_object
        if (!is.null(values$drp_object$drugs) && "exp_id" %in% names(values$drp_object$drugs)) {
          # Match by drug name to get exp_id
          top_drugs <- merge(top_drugs, 
                            values$drp_object$drugs[, c("name", "exp_id")], 
                            by = "name", 
                            all.x = TRUE)
        } else {
          return(plotly_empty() %>% 
                  layout(title = "Experiment IDs not available for heatmap generation"))
        }
      }
      
      # Remove any rows with missing exp_id
      top_drugs <- top_drugs[!is.na(top_drugs$exp_id), ]
      
      if (nrow(top_drugs) == 0) {
        return(plotly_empty() %>% 
                layout(title = "No valid experiment IDs found for selected drugs"))
      }
      
      # Convert exp_id to numeric to ensure proper indexing
      top_drugs$exp_id <- as.numeric(top_drugs$exp_id)
      
      # Create a subset with exp_id for prepare_heatmap
      top_drugs_subset <- data.frame(
        exp_id = top_drugs$exp_id,
        name = top_drugs$name,
        cmap_score = top_drugs$cmap_score,
        stringsAsFactors = FALSE
      )
      
      # Use DRpipe's prepare_heatmap function
      heatmap_data <- DRpipe::prepare_heatmap(
        top_drugs_subset,
        dz_sig = values$drp_object$disease_sig,
        cmap_sig = values$drp_object$cmap_sig
      )
      
      if (is.null(heatmap_data) || nrow(heatmap_data) == 0) {
        return(plotly_empty() %>% 
                layout(title = "No heatmap data available - prepare_heatmap returned empty"))
      }
      
      # Remove GeneID column for plotting
      heatmap_matrix <- as.matrix(heatmap_data[, -1])
      
      # Create interactive heatmap with plotly
      plot_ly(
        z = t(heatmap_matrix),
        x = 1:nrow(heatmap_matrix),
        y = colnames(heatmap_matrix),
        type = "heatmap",
        colorscale = list(
          c(0, "blue"),
          c(0.5, "white"),
          c(1, "red")
        ),
        hovertemplate = "Gene Rank: %{x}<br>%{y}<br>Rank Value: %{z:.0f}<extra></extra>"
      ) %>%
        layout(
          title = "Disease-Drug Reversal Heatmap",
          xaxis = list(title = "Gene Rank (ordered by disease signature)"),
          yaxis = list(title = ""),
          margin = list(l = 150)
        )
      
    }, error = function(e) {
      return(plotly_empty() %>% 
              layout(title = paste("Error generating heatmap:", e$message)))
    })
  })
  
  # Sweep mode specific outputs
  output$sweepCutoffTable <- renderDT({
    req(values$sweep_cutoff_summary)
    datatable(values$sweep_cutoff_summary, 
             options = list(scrollX = TRUE, pageLength = 10),
             caption = "Performance metrics for each log2FC threshold tested")
  })
  
  # Interactive sweep cutoff performance plot
  output$sweepCutoffPlot <- renderPlotly({
    req(values$sweep_cutoff_summary)
    
    # Create subplot with two y-axes
    fig <- plot_ly(data = values$sweep_cutoff_summary)
    
    # Add trace for number of hits
    fig <- fig %>% add_trace(
      x = ~cutoff,
      y = ~n_hits,
      name = "Number of Hits",
      type = "scatter",
      mode = "lines+markers",
      line = list(color = "steelblue", width = 3),
      marker = list(size = 10, color = "steelblue"),
      hovertemplate = paste(
        "<b>Cutoff:</b> %{x}<br>",
        "<b>Hits:</b> %{y}<br>",
        "<extra></extra>"
      )
    )
    
    # Add trace for median q-value on secondary y-axis
    fig <- fig %>% add_trace(
      x = ~cutoff,
      y = ~median_q,
      name = "Median Q-value",
      type = "scatter",
      mode = "lines+markers",
      yaxis = "y2",
      line = list(color = "darkred", width = 3, dash = "dash"),
      marker = list(size = 10, color = "darkred"),
      hovertemplate = paste(
        "<b>Cutoff:</b> %{x}<br>",
        "<b>Median Q:</b> %{y:.4f}<br>",
        "<extra></extra>"
      )
    )
    
    # Add horizontal line for q-value threshold
    fig <- fig %>% add_trace(
      x = values$sweep_cutoff_summary$cutoff,
      y = rep(0.05, nrow(values$sweep_cutoff_summary)),
      name = "Q-value Threshold (0.05)",
      type = "scatter",
      mode = "lines",
      yaxis = "y2",
      line = list(color = "gray", width = 2, dash = "dot"),
      hoverinfo = "skip",
      showlegend = TRUE
    )
    
    # Layout with dual y-axes
    fig <- fig %>% layout(
      title = "Sweep Mode: Threshold Performance",
      xaxis = list(
        title = "Log2FC Cutoff Threshold",
        gridcolor = "lightgray"
      ),
      yaxis = list(
        title = "Number of Hits",
        titlefont = list(color = "steelblue"),
        tickfont = list(color = "steelblue"),
        gridcolor = "lightgray"
      ),
      yaxis2 = list(
        title = "Median Q-value",
        titlefont = list(color = "darkred"),
        tickfont = list(color = "darkred"),
        overlaying = "y",
        side = "right",
        gridcolor = "transparent"
      ),
      hovermode = "x unified",
      legend = list(
        x = 0.02,
        y = 0.98,
        bgcolor = "rgba(255,255,255,0.8)",
        bordercolor = "gray",
        borderwidth = 1
      ),
      plot_bgcolor = "white",
      paper_bgcolor = "white"
    )
    
    fig
  })
  
  # ========== UPLOAD RESULTS FUNCTIONALITY ==========
  
  # Observer for loading uploaded results file
  observeEvent(input$loadResultsBtn, {
    req(input$uploadResultsFile)
    
    tryCatch({
      # Read the CSV file
      uploaded_data <- read.csv(input$uploadResultsFile$datapath, stringsAsFactors = FALSE, check.names = FALSE)
      
      # Validate required columns
      required_cols <- c("exp_id", "name", "cmap_score", "q")
      missing_cols <- setdiff(required_cols, names(uploaded_data))
      
      if (length(missing_cols) > 0) {
        showNotification(
          paste("Missing required columns:", paste(missing_cols, collapse = ", ")),
          type = "error"
        )
        return(NULL)
      }
      
      # Store the uploaded results
      values$uploaded_results <- uploaded_data
      
      # Display statistics
      n_drugs <- nrow(uploaded_data)
      avg_score <- mean(uploaded_data$cmap_score, na.rm = TRUE)
      median_q <- median(uploaded_data$q, na.rm = TRUE)
      
      output$uploadedResultsStats <- renderText({
        paste0(
          "Total drugs: ", n_drugs, "\n",
          "Avg score: ", round(avg_score, 4), "\n",
          "Median Q-value: ", format(median_q, scientific = TRUE)
        )
      })
      
      # Show results tables and visualizations
      shinyjs::show("uploadedResultsPanel")
      shinyjs::show("uploadedVisualizationsPanel")
      
      showNotification(paste0("Loaded ", n_drugs, " drug results!"), type = "message")
      
    }, error = function(e) {
      showNotification(paste("Error loading file:", e$message), type = "error")
    })
  })
  
  # Render uploaded results table
  output$uploadedResultsTable <- DT::renderDT({
    req(values$uploaded_results)
    
    df <- values$uploaded_results %>%
      select(name, cmap_score, q, cell_line, concentration, array_platform) %>%
      arrange(cmap_score) %>%
      head(50)
    
    DT::datatable(
      df,
      options = list(
        pageLength = 10,
        scrollX = TRUE,
        dom = 'lfrtip'
      ),
      rownames = FALSE
    )
  })
  
  # Render score distribution plot
  output$uploadedScorePlot <- plotly::renderPlotly({
    req(values$uploaded_results)
    
    df <- values$uploaded_results
    
    fig <- plotly::plot_ly(
      x = df$cmap_score,
      type = "histogram",
      nbinsx = 30,
      marker = list(color = "steelblue"),
      name = "Score Distribution"
    ) %>%
      plotly::layout(
        title = "Distribution of CMap Scores",
        xaxis = list(title = "CMap Score"),
        yaxis = list(title = "Frequency"),
        plot_bgcolor = "white",
        paper_bgcolor = "white"
      )
    
    fig
  })
  
  # Render top drugs plot
  output$uploadedTopDrugsPlot <- plotly::renderPlotly({
    req(values$uploaded_results)
    
    df <- values$uploaded_results %>%
      arrange(cmap_score) %>%
      head(15)
    
    fig <- plotly::plot_ly(
      y = reorder(df$name, df$cmap_score),
      x = df$cmap_score,
      type = "bar",
      orientation = "h",
      marker = list(
        color = df$cmap_score,
        colorscale = "RdBu",
        showscale = TRUE,
        colorbar = list(title = "CMap Score")
      ),
      hovertemplate = "%{y}: %{x:.4f}<extra></extra>"
    ) %>%
      plotly::layout(
        title = "Top 15 Drug Candidates by CMap Score",
        xaxis = list(title = "CMap Score"),
        yaxis = list(title = "Drug Name"),
        plot_bgcolor = "white",
        paper_bgcolor = "white",
        height = 500,
        margin = list(l = 200)
      )
    
    fig
  })
  
  # Render drug details table
  output$uploadedDrugDetailsTable <- DT::renderDT({
    req(values$uploaded_results)
    
    df <- values$uploaded_results %>%
      arrange(cmap_score) %>%
      select(name, cmap_score, q, cell_line, concentration, duration, vehicle, DrugBank.ID) %>%
      head(100)
    
    DT::datatable(
      df,
      options = list(
        pageLength = 10,
        scrollX = TRUE,
        dom = 'lfrtip',
        columnDefs = list(
          list(targets = c(1, 2), render = JS("function(data, type, row) {return type === 'display' ? parseFloat(data).toFixed(6) : data;}"))
        )
      ),
      rownames = FALSE
    )
  })
  
  # Download uploaded results
  output$downloadUploadedResults <- downloadHandler(
    filename = function() {
      paste0("uploaded_results_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".csv")
    },
    content = function(file) {
      req(values$uploaded_results)
      write.csv(values$uploaded_results, file, row.names = FALSE)
    }
  )
}

# Run app
shinyApp(ui = ui, server = server)

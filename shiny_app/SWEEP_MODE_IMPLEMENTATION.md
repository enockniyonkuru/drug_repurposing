# Sweep Mode Visualization Implementation Guide

## Problem Summary

When running the Shiny app in sweep mode, the analysis completes successfully in the terminal (showing 42 robust hits), but the app displays "zero hits" because:

1. **Sweep mode stores results differently**: Results are in `drp$robust_hits` and `drp$cutoff_summary`, not in `drp$drugs_valid`
2. **Plots are generated in temp directories**: Images are created in `/private/var/folders/.../img` but not accessible to the app
3. **No dedicated sweep visualization tab**: The app doesn't have a way to display sweep-specific results

## Solution Overview

The solution involves:

1. **Capture the DRP object**: Store the entire DRP R6 object after analysis to access sweep-specific fields
2. **Check for sweep mode results**: Look for `robust_hits` and `cutoff_summary` in addition to `drugs_valid`
3. **Add a Sweep Results tab**: Create a dedicated tab to display sweep mode outputs
4. **Display generated plots**: Show the plots that were created during sweep analysis

## Key Changes Needed

### 1. Update `run_single_analysis()` function

```r
run_single_analysis <- function() {
  # ... existing code ...
  
  # IMPORTANT: Store the DRP object to access sweep results
  values$drp_object <- drp
  values$is_sweep_mode <- (drp$mode == "sweep")
  
  # For sweep mode, capture sweep-specific results
  if (values$is_sweep_mode) {
    values$sweep_robust_hits <- drp$robust_hits
    values$sweep_cutoff_summary <- drp$cutoff_summary
    values$sweep_img_dir <- file.path(drp$out_dir, "img")
    
    # Use robust_hits as drugs_valid for compatibility
    if (!is.null(drp$robust_hits) && nrow(drp$robust_hits) > 0) {
      # Create a compatible drugs_valid from robust_hits
      values$drugs_valid <- data.frame(
        name = drp$robust_hits$name,
        cmap_score = drp$robust_hits$aggregated_score,
        q = drp$robust_hits$min_q,
        n_support = drp$robust_hits$n_support,
        stringsAsFactors = FALSE
      )
    }
  } else {
    # Single mode: use drugs_valid as normal
    values$results <- drp$drugs
    values$drugs_valid <- drp$drugs_valid
  }
}
```

### 2. Add Sweep Results UI

```r
output$sweepResultsUI <- renderUI({
  if (!values$is_sweep_mode) {
    return(fluidRow(
      box(
        title = "Not Applicable",
        width = 12,
        status = "warning",
        p("Sweep results are only available when running in Sweep Mode."),
        p("To use sweep mode, select 'Sweep Mode' in the configuration step.")
      )
    ))
  }
  
  if (is.null(values$sweep_robust_hits)) {
    return(fluidRow(
      box(
        title = "No Results",
        width = 12,
        status = "info",
        p("No sweep results available. Please run an analysis first.")
      )
    ))
  }
  
  fluidRow(
    # Summary boxes
    valueBoxOutput("sweepTotalHitsBox"),
    valueBoxOutput("sweepCutoffsTestedBox"),
    valueBoxOutput("sweepTopDrugBox"),
    
    # Robust hits table
    box(
      title = "Robust Drug Hits (Passed Filtering Across Thresholds)",
      width = 12,
      status = "success",
      solidHeader = TRUE,
      p(paste("These drugs appeared consistently across multiple log2FC thresholds,",
              "indicating robust repurposing candidates.")),
      downloadButton("downloadSweepRobustHits", "Download Robust Hits CSV"),
      hr(),
      DTOutput("sweepRobustHitsTable")
    ),
    
    # Cutoff summary table
    box(
      title = "Threshold Performance Summary",
      width = 12,
      status = "info",
      solidHeader = TRUE,
      p("Performance metrics for each log2FC threshold tested in sweep mode."),
      DTOutput("sweepCutoffSummaryTable")
    ),
    
    # Generated plots
    box(
      title = "Sweep Analysis Plots",
      width = 12,
      status = "primary",
      solidHeader = TRUE,
      p("Plots generated during sweep mode analysis:"),
      uiOutput("sweepPlotsDisplay")
    )
  )
})
```

### 3. Add Sweep Results Outputs

```r
# Value boxes for sweep mode
output$sweepTotalHitsBox <- renderValueBox({
  hits <- if (!is.null(values$sweep_robust_hits)) nrow(values$sweep_robust_hits) else 0
  valueBox(hits, "Robust Hits", icon = icon("pills"), 
          color = if(hits > 0) "green" else "red")
})

output$sweepCutoffsTestedBox <- renderValueBox({
  cutoffs <- if (!is.null(values$sweep_cutoff_summary)) nrow(values$sweep_cutoff_summary) else 0
  valueBox(cutoffs, "Thresholds Tested", icon = icon("sliders-h"), color = "blue")
})

output$sweepTopDrugBox <- renderValueBox({
  top <- if (!is.null(values$sweep_robust_hits) && nrow(values$sweep_robust_hits) > 0) {
    values$sweep_robust_hits$name[1]
  } else "None"
  valueBox(top, "Top Drug", icon = icon("star"), color = "purple")
})

# Tables
output$sweepRobustHitsTable <- renderDT({
  req(values$sweep_robust_hits)
  datatable(values$sweep_robust_hits, 
           options = list(scrollX = TRUE, pageLength = 25), 
           filter = 'top')
})

output$sweepCutoffSummaryTable <- renderDT({
  req(values$sweep_cutoff_summary)
  datatable(values$sweep_cutoff_summary, 
           options = list(scrollX = TRUE, pageLength = 10))
})

# Display generated plots
output$sweepPlotsDisplay <- renderUI({
  req(values$sweep_img_dir)
  
  if (!dir.exists(values$sweep_img_dir)) {
    return(p("Plot directory not found."))
  }
  
  plot_files <- list.files(values$sweep_img_dir, 
                          pattern = "\\.(jpg|jpeg|png)$", 
                          full.names = TRUE)
  
  if (length(plot_files) == 0) {
    return(p("No plots were generated."))
  }
  
  # Create image outputs for each plot
  plot_outputs <- lapply(seq_along(plot_files), function(i) {
    output_name <- paste0("sweepPlot", i)
    output[[output_name]] <- renderImage({
      list(src = plot_files[i],
           contentType = 'image/jpeg',
           width = "100%",
           alt = basename(plot_files[i]))
    }, deleteFile = FALSE)
    
    box(
      title = basename(plot_files[i]),
      width = 6,
      status = "primary",
      imageOutput(output_name)
    )
  })
  
  do.call(fluidRow, plot_outputs)
})

# Download handler
output$downloadSweepRobustHits <- downloadHandler(
  filename = function() {
    paste("sweep_robust_hits_", Sys.Date(), ".csv", sep = "")
  },
  content = function(file) {
    req(values$sweep_robust_hits)
    write.csv(values$sweep_robust_hits, file, row.names = FALSE)
  }
)
```

## Testing the Implementation

1. **Run the app**: `shiny::runApp("shiny_app")`
2. **Select Single Analysis**
3. **Load example data** (e.g., Fibroid)
4. **Configure with Sweep Mode**:
   - Set Analysis Mode to "Sweep Mode"
   - Enable "Auto-generate threshold grid"
   - Set appropriate parameters
5. **Run Analysis**
6. **Check Results tab**: Should show robust hits
7. **Check Sweep Results tab**: Should show:
   - Summary statistics
   - Robust hits table
   - Cutoff summary table
   - Generated plots

## Files to Modify

1. `shiny_app/app.R` - Main app file (add sweep mode handling)
2. Or create `shiny_app/app_with_sweep.R` - New version with sweep support

## Expected Output

After implementation, when running sweep mode:
- **Results tab**: Shows the 42 robust hits
- **Visualizations tab**: Shows standard plots
- **Sweep Results tab**: Shows:
  - Value boxes with summary stats
  - Robust hits table (42 drugs)
  - Cutoff summary (4 successful thresholds: 0, 0.6, 1.2, 1.8)
  - Generated plots (4 images)

## Notes

- The sweep mode generates plots automatically in `out_dir/img/`
- Plots include:
  - `dist_rev_score.jpeg` - Distribution of reversal scores
  - `cmap_score.jpg` - CMap scores for top drugs
  - `sweep_cutoff_summary.jpg` - Performance across thresholds
  - `comprehensive_sweep_analysis.jpg` - Combined analysis view
- These plots are created by the `plot_sweep_outputs_legacy()` function in the DRpipe package

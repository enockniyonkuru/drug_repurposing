#!/usr/bin/env Rscript

library(jsonlite)
library(UpSetR)
library(grid)

json_file <- "endo_signatures_drugs.json"
drugs_data <- fromJSON(json_file)
microarray_sigs <- grep("^microarray_", names(drugs_data), value = TRUE)
single_cell_sigs <- grep("^single_cell_", names(drugs_data), value = TRUE)

get_drugs <- function(sig_data, category) {
  if (category %in% names(sig_data)) {
    return(sig_data[[category]]$list_of_drugs)
  }
  return(character(0))
}

output_dir <- "upset_plots"
dir.create(output_dir, showWarnings = FALSE)

# Helper to plot
plot_upset <- function(sigs, category, filename, title) {
  drug_lists <- lapply(sigs, function(sig) get_drugs(drugs_data[[sig]], category))
  names(drug_lists) <- gsub("^(microarray|single_cell)_", "", sigs)
  drug_lists <- drug_lists[sapply(drug_lists, length) > 0]
  
  if (length(drug_lists) < 2) {
    cat("Skipping", title, "- insufficient intersections\n\n")
    return(invisible(NULL))
  }
  
  cat("Creating:", title, "\n")
  
  png(file.path(output_dir, filename), width = 1400, height = 1050)
  
  # Use print() to force rendering inside function
  print(upset(UpSetR::fromList(drug_lists),
        nsets = 40,  # Show all sets (default is 5)
        main.bar.color = "#3498db", sets.bar.color = "#e74c3c",
        mainbar.y.label = "Intersection Size", sets.x.label = "Set Size",
        point.size = 3.5, line.size = 1.3,
        text.scale = c(1.8, 1.8, 1.5, 1.5, 1.8),
        number.angles = 45, order.by = "freq", show.numbers = "yes"))
  
  # Add title using grid
  grid.text(title, x = 0.5, y = 0.98, gp = gpar(fontsize = 18, fontface = "bold"))
  
  dev.off()
  
  cat("Saved:", filename, "\n\n")
}

cat("\n===== MICROARRAY: Individual Source Comparisons =====\n\n")
plot_upset(microarray_sigs, "in_old", "01_microarray_old_studies.png", "Microarray Old Studies")
plot_upset(microarray_sigs, "in_cmap", "02_microarray_cmap.png", "Microarray CMAP")
plot_upset(microarray_sigs, "in_tahoe", "03_microarray_tahoe.png", "Microarray TAHOE")

cat("\n===== SINGLE-CELL: Individual Source Comparisons =====\n\n")
plot_upset(single_cell_sigs, "in_old", "04_single_cell_old_studies.png", "Single-Cell Old Studies")
plot_upset(single_cell_sigs, "in_cmap", "05_single_cell_cmap.png", "Single-Cell CMAP")
plot_upset(single_cell_sigs, "in_tahoe", "06_single_cell_tahoe.png", "Single-Cell TAHOE")

cat("\n===== CMAP AND OLD STUDIES =====\n\n")
plot_upset(microarray_sigs, "cmap_and_old_studies", "07_microarray_cmap_and_old_studies.png", "Microarray CMAP & Old")
plot_upset(single_cell_sigs, "cmap_and_old_studies", "08_single_cell_cmap_and_old_studies.png", "Single-Cell CMAP & Old")

cat("\n===== TAHOE AND OLD STUDIES =====\n\n")
plot_upset(microarray_sigs, "tahoe_and_old_studies", "09_microarray_tahoe_and_old_studies.png", "Microarray TAHOE & Old")
plot_upset(single_cell_sigs, "tahoe_and_old_studies", "10_single_cell_tahoe_and_old_studies.png", "Single-Cell TAHOE & Old")

cat("\n===== ALL THREE SOURCES =====\n\n")
plot_upset(microarray_sigs, "tahoe_cmap_old", "11_microarray_tahoe_cmap_and_old.png", "Microarray All Three")
plot_upset(single_cell_sigs, "tahoe_cmap_old", "12_single_cell_tahoe_cmap_and_old.png", "Single-Cell All Three")

cat("\n===== Complete! =====\n")
cat("Plots saved to:", output_dir, "\n")

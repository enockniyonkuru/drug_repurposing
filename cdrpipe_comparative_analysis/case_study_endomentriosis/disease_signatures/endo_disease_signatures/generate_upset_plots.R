#!/usr/bin/env Rscript

library(jsonlite)
library(UpSetR)
library(grid)

json_file <- "endo_signatures_drugs.json"
drugs_data <- fromJSON(json_file)
tomiko_sigs <- grep("^tomiko_", names(drugs_data), value = TRUE)
laura_sigs <- grep("^laura_", names(drugs_data), value = TRUE)

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
  names(drug_lists) <- gsub("^(tomiko|laura)_", "", sigs)
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

cat("\n===== TOMIKO: Individual Source Comparisons =====\n\n")
plot_upset(tomiko_sigs, "in_old", "01_tomiko_old_studies.png", "Tomiko Old Studies")
plot_upset(tomiko_sigs, "in_cmap", "02_tomiko_cmap.png", "Tomiko CMAP")
plot_upset(tomiko_sigs, "in_tahoe", "03_tomiko_tahoe.png", "Tomiko TAHOE")

cat("\n===== LAURA: Individual Source Comparisons =====\n\n")
plot_upset(laura_sigs, "in_old", "04_laura_old_studies.png", "Laura Old Studies")
plot_upset(laura_sigs, "in_cmap", "05_laura_cmap.png", "Laura CMAP")
plot_upset(laura_sigs, "in_tahoe", "06_laura_tahoe.png", "Laura TAHOE")

cat("\n===== CMAP AND OLD STUDIES =====\n\n")
plot_upset(tomiko_sigs, "cmap_and_old_studies", "07_tomiko_cmap_and_old_studies.png", "Tomiko CMAP & Old")
plot_upset(laura_sigs, "cmap_and_old_studies", "08_laura_cmap_and_old_studies.png", "Laura CMAP & Old")

cat("\n===== TAHOE AND OLD STUDIES =====\n\n")
plot_upset(tomiko_sigs, "tahoe_and_old_studies", "09_tomiko_tahoe_and_old_studies.png", "Tomiko TAHOE & Old")
plot_upset(laura_sigs, "tahoe_and_old_studies", "10_laura_tahoe_and_old_studies.png", "Laura TAHOE & Old")

cat("\n===== ALL THREE SOURCES =====\n\n")
plot_upset(tomiko_sigs, "tahoe_cmap_old", "11_tomiko_tahoe_cmap_and_old.png", "Tomiko All Three")
plot_upset(laura_sigs, "tahoe_cmap_old", "12_laura_tahoe_cmap_and_old.png", "Laura All Three")

cat("\n===== Complete! =====\n")
cat("Plots saved to:", output_dir, "\n")

#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(jsonlite)
  library(UpSetR)
  library(tidyverse)
})

# Load the JSON file with drug data
json_file <- "endo_signatures_drugs.json"
drugs_data <- fromJSON(json_file)

# Extract signatures grouped by source and combination type
tomiko_sigs <- grep("^tomiko_", names(drugs_data), value = TRUE)
laura_sigs <- grep("^laura_", names(drugs_data), value = TRUE)

# Create directory for output
output_dir <- "upset_plots"
dir.create(output_dir, showWarnings = FALSE)

# Function to extract drug list from a category
get_drugs <- function(sig_data, category) {
  if (category %in% names(sig_data)) {
    return(sig_data[[category]]$list_of_drugs)
  }
  return(character(0))
}

# Function to create proper UpSet plot
create_upset <- function(drug_lists, title, filename) {
  if (all(sapply(drug_lists, length) == 0)) {
    cat("Skipping", title, "- no data\n")
    return(NULL)
  }
  
  # Remove empty lists
  drug_lists <- drug_lists[sapply(drug_lists, length) > 0]
  
  if (length(drug_lists) < 2) {
    cat("Skipping", title, "- insufficient intersections\n\n")
    return(NULL)
  }
  
  cat("Creating:", title, "\n")
  
  # Convert to binary matrix for UpSet (needed for UpSetR)
  all_drugs <- unique(unlist(drug_lists))
  upset_data <- data.frame(row.names = all_drugs)
  
  for (sig_name in names(drug_lists)) {
    upset_data[[sig_name]] <- as.integer(all_drugs %in% drug_lists[[sig_name]])
  }
  
  # Create UpSet plot with PNG output
  png(paste0(output_dir, "/", filename), width = 1400, height = 900, res = 100)
  
  tryCatch({
    upset(upset_data, 
          colnames(upset_data),
          title = title,
          intersection_padding = 8,
          width_ratio = 0.3,
          height_ratio = 1.5,
          sort_by = "freq",
          n_intersections = NA,
          themes = upset_default_themes() + 
            theme(
              plot.title = element_text(size = 16, face = "bold", hjust = 0.5),
              axis.title = element_text(size = 12, face = "bold"),
              axis.text = element_text(size = 10)
            )
    )
    cat("Saved:", paste0(output_dir, "/", filename), "\n\n")
  }, error = function(e) {
    cat("Error creating plot:", e$message, "\n")
    cat("Trying alternative method...\n")
  })
  
  dev.off()
}

# Alternative method using base UpSetR if ComplexUpset fails
create_upset_base <- function(drug_lists, title, filename) {
  if (all(sapply(drug_lists, length) == 0)) {
    cat("Skipping", title, "- no data\n")
    return(NULL)
  }
  
  # Remove empty lists
  drug_lists <- drug_lists[sapply(drug_lists, length) > 0]
  
  if (length(drug_lists) < 2) {
    cat("Skipping", title, "- insufficient intersections\n\n")
    return(NULL)
  }
  
  cat("Creating (base method):", title, "\n")
  
  png(paste0(output_dir, "/", filename), width = 1400, height = 900, res = 100)
  
  tryCatch({
    upset(fromList(drug_lists),
          order.by = "freq",
          nsets = length(drug_lists),
          number.angles = 45,
          point.size = 3,
          line.size = 1.2,
          mainbar.y.label = "Intersection Size",
          sets.x.label = "Set Size",
          main = title,
          text.scale = c(1.4, 1.2, 1, 1.2, 1.5, 1),
          sets = rev(names(drug_lists)),
          keep.order = FALSE)
    cat("Saved:", paste0(output_dir, "/", filename), "\n\n")
  }, error = function(e) {
    cat("Error:", e$message, "\n\n")
  })
  
  dev.off()
}

# ============================================================================
# 1. TOMIKO: old, cmap, tahoe individual comparisons
# ============================================================================

cat("\n===== TOMIKO: Individual Source Comparisons =====\n\n")

tomiko_old_drugs <- lapply(tomiko_sigs, function(sig) {
  get_drugs(drugs_data[[sig]], "in_old")
})
names(tomiko_old_drugs) <- gsub("^tomiko_", "", tomiko_sigs)
tomiko_old_drugs <- tomiko_old_drugs[sapply(tomiko_old_drugs, length) > 0]

tomiko_cmap_drugs <- lapply(tomiko_sigs, function(sig) {
  get_drugs(drugs_data[[sig]], "in_cmap")
})
names(tomiko_cmap_drugs) <- gsub("^tomiko_", "", tomiko_sigs)
tomiko_cmap_drugs <- tomiko_cmap_drugs[sapply(tomiko_cmap_drugs, length) > 0]

tomiko_tahoe_drugs <- lapply(tomiko_sigs, function(sig) {
  get_drugs(drugs_data[[sig]], "in_tahoe")
})
names(tomiko_tahoe_drugs) <- gsub("^tomiko_", "", tomiko_sigs)
tomiko_tahoe_drugs <- tomiko_tahoe_drugs[sapply(tomiko_tahoe_drugs, length) > 0]

create_upset_base(tomiko_old_drugs, 
                  "Drug Overlap in Old Studies - Tomiko Signatures",
                  "01_tomiko_old_studies.png")

create_upset_base(tomiko_cmap_drugs,
                  "Drug Overlap in CMAP - Tomiko Signatures",
                  "02_tomiko_cmap.png")

create_upset_base(tomiko_tahoe_drugs,
                  "Drug Overlap in TAHOE - Tomiko Signatures",
                  "03_tomiko_tahoe.png")

# ============================================================================
# 2. LAURA: old, cmap, tahoe individual comparisons
# ============================================================================

cat("\n===== LAURA: Individual Source Comparisons =====\n\n")

laura_old_drugs <- lapply(laura_sigs, function(sig) {
  get_drugs(drugs_data[[sig]], "in_old")
})
names(laura_old_drugs) <- gsub("^laura_", "", laura_sigs)
laura_old_drugs <- laura_old_drugs[sapply(laura_old_drugs, length) > 0]

laura_cmap_drugs <- lapply(laura_sigs, function(sig) {
  get_drugs(drugs_data[[sig]], "in_cmap")
})
names(laura_cmap_drugs) <- gsub("^laura_", "", laura_sigs)
laura_cmap_drugs <- laura_cmap_drugs[sapply(laura_cmap_drugs, length) > 0]

laura_tahoe_drugs <- lapply(laura_sigs, function(sig) {
  get_drugs(drugs_data[[sig]], "in_tahoe")
})
names(laura_tahoe_drugs) <- gsub("^laura_", "", laura_sigs)
laura_tahoe_drugs <- laura_tahoe_drugs[sapply(laura_tahoe_drugs, length) > 0]

create_upset_base(laura_old_drugs,
                  "Drug Overlap in Old Studies - Laura Signatures",
                  "04_laura_old_studies.png")

create_upset_base(laura_cmap_drugs,
                  "Drug Overlap in CMAP - Laura Signatures",
                  "05_laura_cmap.png")

create_upset_base(laura_tahoe_drugs,
                  "Drug Overlap in TAHOE - Laura Signatures",
                  "06_laura_tahoe.png")

# ============================================================================
# 3. CMAP AND OLD STUDIES: Tomiko and Laura combined
# ============================================================================

cat("\n===== CMAP AND OLD STUDIES Comparisons =====\n\n")

tomiko_cmap_old_drugs <- lapply(tomiko_sigs, function(sig) {
  get_drugs(drugs_data[[sig]], "cmap_and_old_studies")
})
names(tomiko_cmap_old_drugs) <- gsub("^tomiko_", "", tomiko_sigs)
tomiko_cmap_old_drugs <- tomiko_cmap_old_drugs[sapply(tomiko_cmap_old_drugs, length) > 0]

laura_cmap_old_drugs <- lapply(laura_sigs, function(sig) {
  get_drugs(drugs_data[[sig]], "cmap_and_old_studies")
})
names(laura_cmap_old_drugs) <- gsub("^laura_", "", laura_sigs)
laura_cmap_old_drugs <- laura_cmap_old_drugs[sapply(laura_cmap_old_drugs, length) > 0]

create_upset_base(tomiko_cmap_old_drugs,
                  "Drugs in Both CMAP and Old Studies - Tomiko Signatures",
                  "07_tomiko_cmap_and_old_studies.png")

create_upset_base(laura_cmap_old_drugs,
                  "Drugs in Both CMAP and Old Studies - Laura Signatures",
                  "08_laura_cmap_and_old_studies.png")

# ============================================================================
# 4. TAHOE AND OLD STUDIES: Tomiko and Laura combined
# ============================================================================

cat("\n===== TAHOE AND OLD STUDIES Comparisons =====\n\n")

tomiko_tahoe_old_drugs <- lapply(tomiko_sigs, function(sig) {
  get_drugs(drugs_data[[sig]], "tahoe_and_old_studies")
})
names(tomiko_tahoe_old_drugs) <- gsub("^tomiko_", "", tomiko_sigs)
tomiko_tahoe_old_drugs <- tomiko_tahoe_old_drugs[sapply(tomiko_tahoe_old_drugs, length) > 0]

laura_tahoe_old_drugs <- lapply(laura_sigs, function(sig) {
  get_drugs(drugs_data[[sig]], "tahoe_and_old_studies")
})
names(laura_tahoe_old_drugs) <- gsub("^laura_", "", laura_sigs)
laura_tahoe_old_drugs <- laura_tahoe_old_drugs[sapply(laura_tahoe_old_drugs, length) > 0]

create_upset_base(tomiko_tahoe_old_drugs,
                  "Drugs in Both TAHOE and Old Studies - Tomiko Signatures",
                  "09_tomiko_tahoe_and_old_studies.png")

create_upset_base(laura_tahoe_old_drugs,
                  "Drugs in Both TAHOE and Old Studies - Laura Signatures",
                  "10_laura_tahoe_and_old_studies.png")

# ============================================================================
# 5. TAHOE, CMAP, AND OLD: Tomiko and Laura combined
# ============================================================================

cat("\n===== TAHOE, CMAP, AND OLD (All Three) =====\n\n")

tomiko_all_three_drugs <- lapply(tomiko_sigs, function(sig) {
  get_drugs(drugs_data[[sig]], "tahoe_cmap_old")
})
names(tomiko_all_three_drugs) <- gsub("^tomiko_", "", tomiko_sigs)
tomiko_all_three_drugs <- tomiko_all_three_drugs[sapply(tomiko_all_three_drugs, length) > 0]

laura_all_three_drugs <- lapply(laura_sigs, function(sig) {
  get_drugs(drugs_data[[sig]], "tahoe_cmap_old")
})
names(laura_all_three_drugs) <- gsub("^laura_", "", laura_sigs)
laura_all_three_drugs <- laura_all_three_drugs[sapply(laura_all_three_drugs, length) > 0]

create_upset_base(tomiko_all_three_drugs,
                  "Drugs in TAHOE, CMAP, and Old Studies - Tomiko Signatures",
                  "11_tomiko_tahoe_cmap_and_old.png")

create_upset_base(laura_all_three_drugs,
                  "Drugs in TAHOE, CMAP, and Old Studies - Laura Signatures",
                  "12_laura_tahoe_cmap_and_old.png")

cat("\n===== UpSet plots generation complete! =====\n")
cat("Plots saved to:", output_dir, "\n")

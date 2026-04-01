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
microarray_sigs <- grep("^microarray_", names(drugs_data), value = TRUE)
single_cell_sigs <- grep("^single_cell_", names(drugs_data), value = TRUE)

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
# 1. MICROARRAY: old, cmap, tahoe individual comparisons
# ============================================================================

cat("\n===== MICROARRAY: Individual Source Comparisons =====\n\n")

microarray_old_drugs <- lapply(microarray_sigs, function(sig) {
  get_drugs(drugs_data[[sig]], "in_old")
})
names(microarray_old_drugs) <- gsub("^microarray_", "", microarray_sigs)
microarray_old_drugs <- microarray_old_drugs[sapply(microarray_old_drugs, length) > 0]

microarray_cmap_drugs <- lapply(microarray_sigs, function(sig) {
  get_drugs(drugs_data[[sig]], "in_cmap")
})
names(microarray_cmap_drugs) <- gsub("^microarray_", "", microarray_sigs)
microarray_cmap_drugs <- microarray_cmap_drugs[sapply(microarray_cmap_drugs, length) > 0]

microarray_tahoe_drugs <- lapply(microarray_sigs, function(sig) {
  get_drugs(drugs_data[[sig]], "in_tahoe")
})
names(microarray_tahoe_drugs) <- gsub("^microarray_", "", microarray_sigs)
microarray_tahoe_drugs <- microarray_tahoe_drugs[sapply(microarray_tahoe_drugs, length) > 0]

create_upset_base(microarray_old_drugs, 
                  "Drug Overlap in Old Studies - Microarray Signatures",
                  "01_microarray_old_studies.png")

create_upset_base(microarray_cmap_drugs,
                  "Drug Overlap in CMAP - Microarray Signatures",
                  "02_microarray_cmap.png")

create_upset_base(microarray_tahoe_drugs,
                  "Drug Overlap in TAHOE - Microarray Signatures",
                  "03_microarray_tahoe.png")

# ============================================================================
# 2. SINGLE-CELL: old, cmap, tahoe individual comparisons
# ============================================================================

cat("\n===== SINGLE-CELL: Individual Source Comparisons =====\n\n")

single_cell_old_drugs <- lapply(single_cell_sigs, function(sig) {
  get_drugs(drugs_data[[sig]], "in_old")
})
names(single_cell_old_drugs) <- gsub("^single_cell_", "", single_cell_sigs)
single_cell_old_drugs <- single_cell_old_drugs[sapply(single_cell_old_drugs, length) > 0]

single_cell_cmap_drugs <- lapply(single_cell_sigs, function(sig) {
  get_drugs(drugs_data[[sig]], "in_cmap")
})
names(single_cell_cmap_drugs) <- gsub("^single_cell_", "", single_cell_sigs)
single_cell_cmap_drugs <- single_cell_cmap_drugs[sapply(single_cell_cmap_drugs, length) > 0]

single_cell_tahoe_drugs <- lapply(single_cell_sigs, function(sig) {
  get_drugs(drugs_data[[sig]], "in_tahoe")
})
names(single_cell_tahoe_drugs) <- gsub("^single_cell_", "", single_cell_sigs)
single_cell_tahoe_drugs <- single_cell_tahoe_drugs[sapply(single_cell_tahoe_drugs, length) > 0]

create_upset_base(single_cell_old_drugs,
                  "Drug Overlap in Old Studies - Single-Cell Signatures",
                  "04_single_cell_old_studies.png")

create_upset_base(single_cell_cmap_drugs,
                  "Drug Overlap in CMAP - Single-Cell Signatures",
                  "05_single_cell_cmap.png")

create_upset_base(single_cell_tahoe_drugs,
                  "Drug Overlap in TAHOE - Single-Cell Signatures",
                  "06_single_cell_tahoe.png")

# ============================================================================
# 3. CMAP AND OLD STUDIES: Microarray and Single-Cell combined
# ============================================================================

cat("\n===== CMAP AND OLD STUDIES Comparisons =====\n\n")

microarray_cmap_old_drugs <- lapply(microarray_sigs, function(sig) {
  get_drugs(drugs_data[[sig]], "cmap_and_old_studies")
})
names(microarray_cmap_old_drugs) <- gsub("^microarray_", "", microarray_sigs)
microarray_cmap_old_drugs <- microarray_cmap_old_drugs[sapply(microarray_cmap_old_drugs, length) > 0]

single_cell_cmap_old_drugs <- lapply(single_cell_sigs, function(sig) {
  get_drugs(drugs_data[[sig]], "cmap_and_old_studies")
})
names(single_cell_cmap_old_drugs) <- gsub("^single_cell_", "", single_cell_sigs)
single_cell_cmap_old_drugs <- single_cell_cmap_old_drugs[sapply(single_cell_cmap_old_drugs, length) > 0]

create_upset_base(microarray_cmap_old_drugs,
                  "Drugs in Both CMAP and Old Studies - Microarray Signatures",
                  "07_microarray_cmap_and_old_studies.png")

create_upset_base(single_cell_cmap_old_drugs,
                  "Drugs in Both CMAP and Old Studies - Single-Cell Signatures",
                  "08_single_cell_cmap_and_old_studies.png")

# ============================================================================
# 4. TAHOE AND OLD STUDIES: Microarray and Single-Cell combined
# ============================================================================

cat("\n===== TAHOE AND OLD STUDIES Comparisons =====\n\n")

microarray_tahoe_old_drugs <- lapply(microarray_sigs, function(sig) {
  get_drugs(drugs_data[[sig]], "tahoe_and_old_studies")
})
names(microarray_tahoe_old_drugs) <- gsub("^microarray_", "", microarray_sigs)
microarray_tahoe_old_drugs <- microarray_tahoe_old_drugs[sapply(microarray_tahoe_old_drugs, length) > 0]

single_cell_tahoe_old_drugs <- lapply(single_cell_sigs, function(sig) {
  get_drugs(drugs_data[[sig]], "tahoe_and_old_studies")
})
names(single_cell_tahoe_old_drugs) <- gsub("^single_cell_", "", single_cell_sigs)
single_cell_tahoe_old_drugs <- single_cell_tahoe_old_drugs[sapply(single_cell_tahoe_old_drugs, length) > 0]

create_upset_base(microarray_tahoe_old_drugs,
                  "Drugs in Both TAHOE and Old Studies - Microarray Signatures",
                  "09_microarray_tahoe_and_old_studies.png")

create_upset_base(single_cell_tahoe_old_drugs,
                  "Drugs in Both TAHOE and Old Studies - Single-Cell Signatures",
                  "10_single_cell_tahoe_and_old_studies.png")

# ============================================================================
# 5. TAHOE, CMAP, AND OLD: Microarray and Single-Cell combined
# ============================================================================

cat("\n===== TAHOE, CMAP, AND OLD (All Three) =====\n\n")

microarray_all_three_drugs <- lapply(microarray_sigs, function(sig) {
  get_drugs(drugs_data[[sig]], "tahoe_cmap_old")
})
names(microarray_all_three_drugs) <- gsub("^microarray_", "", microarray_sigs)
microarray_all_three_drugs <- microarray_all_three_drugs[sapply(microarray_all_three_drugs, length) > 0]

single_cell_all_three_drugs <- lapply(single_cell_sigs, function(sig) {
  get_drugs(drugs_data[[sig]], "tahoe_cmap_old")
})
names(single_cell_all_three_drugs) <- gsub("^single_cell_", "", single_cell_sigs)
single_cell_all_three_drugs <- single_cell_all_three_drugs[sapply(single_cell_all_three_drugs, length) > 0]

create_upset_base(microarray_all_three_drugs,
                  "Drugs in TAHOE, CMAP, and Old Studies - Microarray Signatures",
                  "11_microarray_tahoe_cmap_and_old.png")

create_upset_base(single_cell_all_three_drugs,
                  "Drugs in TAHOE, CMAP, and Old Studies - Single-Cell Signatures",
                  "12_single_cell_tahoe_cmap_and_old.png")

cat("\n===== UpSet plots generation complete! =====\n")
cat("Plots saved to:", output_dir, "\n")

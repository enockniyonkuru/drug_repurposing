#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(jsonlite)
  library(UpSetR)
})

# Load the JSON file
json_file <- "endo_signatures_drugs.json"
drugs_data <- fromJSON(json_file)

# Extract signatures
tomiko_sigs <- grep("^tomiko_", names(drugs_data), value = TRUE)
laura_sigs <- grep("^laura_", names(drugs_data), value = TRUE)

# Create output directory
output_dir <- "upset_plots"
dir.create(output_dir, showWarnings = FALSE)

# Function to extract drug list
get_drugs <- function(sig_data, category) {
  if (category %in% names(sig_data)) {
    return(sig_data[[category]]$list_of_drugs)
  }
  return(character(0))
}

# Function to create UpSet plot via PDF then convert to PNG
# This avoids macOS graphics rendering issues with direct PNG
create_upset <- function(drug_lists, title, filename) {
  if (all(sapply(drug_lists, length) == 0)) {
    cat("Skipping", title, "- no data\n\n")
    return(NULL)
  }
  
  # Remove empty lists
  drug_lists <- drug_lists[sapply(drug_lists, length) > 0]
  
  if (length(drug_lists) < 2) {
    cat("Skipping", title, "- insufficient intersections\n\n")
    return(NULL)
  }
  
  cat("Creating:", title, "\n")
  
  # Use PDF as intermediate to avoid device issues
  out_path <- file.path(output_dir, filename)
  pdf_path <- gsub("\\.png$", ".pdf", out_path)
  
  # Create PDF directly (PDF rendering is more reliable)
  pdf(pdf_path, width = 14, height = 9)
  tryCatch({
    upset(UpSetR::fromList(drug_lists),
          main.bar.color = "#3498db",
          sets.bar.color = "#e74c3c",
          mainbar.y.label = "Intersection Size",
          sets.x.label = "Set Size",
          point.size = 3.5,
          line.size = 1.3,
          text.scale = c(1.5, 1.3, 1.2, 1.2, 1.6, 1.2),
          number.angles = 45,
          order.by = "freq",
          show.numbers = "yes")
  }, finally = {
    dev.off()
  })
  
  # Convert PDF to PNG using ImageMagick or pdftoppm
  if (nzchar(Sys.which("pdftoppm"))) {
    system(sprintf('pdftoppm -png -singlefile "%s" "%s"',
                   pdf_path, gsub("\\.png$", "", out_path)))
    cat("Converted PDF to PNG\n")
  } else if (nzchar(Sys.which("convert"))) {
    system(sprintf('convert -density 144 "%s" "%s"',
                   pdf_path, out_path))
    cat("Converted PDF to PNG\n")
  } else {
    cat("Warning: ImageMagick/pdftoppm not found. PDF saved as:", pdf_path, "\n")
  }
  
  cat("Saved:", out_path, "\n\n")
}

# TOMIKO: Individual source comparisons
cat("\n===== TOMIKO: Individual Source Comparisons =====\n\n")

tomiko_old_drugs <- lapply(tomiko_sigs, function(sig) get_drugs(drugs_data[[sig]], "in_old"))
names(tomiko_old_drugs) <- gsub("^tomiko_", "", tomiko_sigs)
tomiko_old_drugs <- tomiko_old_drugs[sapply(tomiko_old_drugs, length) > 0]

tomiko_cmap_drugs <- lapply(tomiko_sigs, function(sig) get_drugs(drugs_data[[sig]], "in_cmap"))
names(tomiko_cmap_drugs) <- gsub("^tomiko_", "", tomiko_sigs)
tomiko_cmap_drugs <- tomiko_cmap_drugs[sapply(tomiko_cmap_drugs, length) > 0]

tomiko_tahoe_drugs <- lapply(tomiko_sigs, function(sig) get_drugs(drugs_data[[sig]], "in_tahoe"))
names(tomiko_tahoe_drugs) <- gsub("^tomiko_", "", tomiko_sigs)
tomiko_tahoe_drugs <- tomiko_tahoe_drugs[sapply(tomiko_tahoe_drugs, length) > 0]

create_upset(tomiko_old_drugs, "Drug Overlap in Old Studies - Tomiko Signatures", "01_tomiko_old_studies.png")
create_upset(tomiko_cmap_drugs, "Drug Overlap in CMAP - Tomiko Signatures", "02_tomiko_cmap.png")
create_upset(tomiko_tahoe_drugs, "Drug Overlap in TAHOE - Tomiko Signatures", "03_tomiko_tahoe.png")

# LAURA: Individual source comparisons
cat("\n===== LAURA: Individual Source Comparisons =====\n\n")

laura_old_drugs <- lapply(laura_sigs, function(sig) get_drugs(drugs_data[[sig]], "in_old"))
names(laura_old_drugs) <- gsub("^laura_", "", laura_sigs)
laura_old_drugs <- laura_old_drugs[sapply(laura_old_drugs, length) > 0]

laura_cmap_drugs <- lapply(laura_sigs, function(sig) get_drugs(drugs_data[[sig]], "in_cmap"))
names(laura_cmap_drugs) <- gsub("^laura_", "", laura_sigs)
laura_cmap_drugs <- laura_cmap_drugs[sapply(laura_cmap_drugs, length) > 0]

laura_tahoe_drugs <- lapply(laura_sigs, function(sig) get_drugs(drugs_data[[sig]], "in_tahoe"))
names(laura_tahoe_drugs) <- gsub("^laura_", "", laura_sigs)
laura_tahoe_drugs <- laura_tahoe_drugs[sapply(laura_tahoe_drugs, length) > 0]

create_upset(laura_old_drugs, "Drug Overlap in Old Studies - Laura Signatures", "04_laura_old_studies.png")
create_upset(laura_cmap_drugs, "Drug Overlap in CMAP - Laura Signatures", "05_laura_cmap.png")
create_upset(laura_tahoe_drugs, "Drug Overlap in TAHOE - Laura Signatures", "06_laura_tahoe.png")

# CMAP AND OLD STUDIES
cat("\n===== CMAP AND OLD STUDIES =====\n\n")

tomiko_cmap_old_drugs <- lapply(tomiko_sigs, function(sig) get_drugs(drugs_data[[sig]], "cmap_and_old_studies"))
names(tomiko_cmap_old_drugs) <- gsub("^tomiko_", "", tomiko_sigs)
tomiko_cmap_old_drugs <- tomiko_cmap_old_drugs[sapply(tomiko_cmap_old_drugs, length) > 0]

laura_cmap_old_drugs <- lapply(laura_sigs, function(sig) get_drugs(drugs_data[[sig]], "cmap_and_old_studies"))
names(laura_cmap_old_drugs) <- gsub("^laura_", "", laura_sigs)
laura_cmap_old_drugs <- laura_cmap_old_drugs[sapply(laura_cmap_old_drugs, length) > 0]

create_upset(tomiko_cmap_old_drugs, "Drugs in Both CMAP and Old Studies - Tomiko Signatures", "07_tomiko_cmap_and_old_studies.png")
create_upset(laura_cmap_old_drugs, "Drugs in Both CMAP and Old Studies - Laura Signatures", "08_laura_cmap_and_old_studies.png")

# TAHOE AND OLD STUDIES
cat("\n===== TAHOE AND OLD STUDIES =====\n\n")

tomiko_tahoe_old_drugs <- lapply(tomiko_sigs, function(sig) get_drugs(drugs_data[[sig]], "tahoe_and_old_studies"))
names(tomiko_tahoe_old_drugs) <- gsub("^tomiko_", "", tomiko_sigs)
tomiko_tahoe_old_drugs <- tomiko_tahoe_old_drugs[sapply(tomiko_tahoe_old_drugs, length) > 0]

laura_tahoe_old_drugs <- lapply(laura_sigs, function(sig) get_drugs(drugs_data[[sig]], "tahoe_and_old_studies"))
names(laura_tahoe_old_drugs) <- gsub("^laura_", "", laura_sigs)
laura_tahoe_old_drugs <- laura_tahoe_old_drugs[sapply(laura_tahoe_old_drugs, length) > 0]

create_upset(tomiko_tahoe_old_drugs, "Drugs in Both TAHOE and Old Studies - Tomiko Signatures", "09_tomiko_tahoe_and_old_studies.png")
create_upset(laura_tahoe_old_drugs, "Drugs in Both TAHOE and Old Studies - Laura Signatures", "10_laura_tahoe_and_old_studies.png")

# ALL THREE SOURCES
cat("\n===== ALL THREE SOURCES (TAHOE, CMAP, OLD) =====\n\n")

tomiko_all_three_drugs <- lapply(tomiko_sigs, function(sig) get_drugs(drugs_data[[sig]], "tahoe_cmap_old"))
names(tomiko_all_three_drugs) <- gsub("^tomiko_", "", tomiko_sigs)
tomiko_all_three_drugs <- tomiko_all_three_drugs[sapply(tomiko_all_three_drugs, length) > 0]

laura_all_three_drugs <- lapply(laura_sigs, function(sig) get_drugs(drugs_data[[sig]], "tahoe_cmap_old"))
names(laura_all_three_drugs) <- gsub("^laura_", "", laura_sigs)
laura_all_three_drugs <- laura_all_three_drugs[sapply(laura_all_three_drugs, length) > 0]

create_upset(tomiko_all_three_drugs, "Drugs in TAHOE, CMAP, and Old Studies - Tomiko Signatures", "11_tomiko_tahoe_cmap_and_old.png")
create_upset(laura_all_three_drugs, "Drugs in TAHOE, CMAP, and Old Studies - Laura Signatures", "12_laura_tahoe_cmap_and_old.png")

cat("\n===== UpSet plots generation complete! =====\n")
cat("Plots saved to:", output_dir, "\n")

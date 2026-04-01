#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(jsonlite)
  library(UpSetR)
})

# Load the JSON file
json_file <- "endo_signatures_drugs.json"
drugs_data <- fromJSON(json_file)

# Extract signatures
microarray_sigs <- grep("^microarray_", names(drugs_data), value = TRUE)
single_cell_sigs <- grep("^single_cell_", names(drugs_data), value = TRUE)

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

# MICROARRAY: Individual source comparisons
cat("\n===== MICROARRAY: Individual Source Comparisons =====\n\n")

microarray_old_drugs <- lapply(microarray_sigs, function(sig) get_drugs(drugs_data[[sig]], "in_old"))
names(microarray_old_drugs) <- gsub("^microarray_", "", microarray_sigs)
microarray_old_drugs <- microarray_old_drugs[sapply(microarray_old_drugs, length) > 0]

microarray_cmap_drugs <- lapply(microarray_sigs, function(sig) get_drugs(drugs_data[[sig]], "in_cmap"))
names(microarray_cmap_drugs) <- gsub("^microarray_", "", microarray_sigs)
microarray_cmap_drugs <- microarray_cmap_drugs[sapply(microarray_cmap_drugs, length) > 0]

microarray_tahoe_drugs <- lapply(microarray_sigs, function(sig) get_drugs(drugs_data[[sig]], "in_tahoe"))
names(microarray_tahoe_drugs) <- gsub("^microarray_", "", microarray_sigs)
microarray_tahoe_drugs <- microarray_tahoe_drugs[sapply(microarray_tahoe_drugs, length) > 0]

create_upset(microarray_old_drugs, "Drug Overlap in Old Studies - Microarray Signatures", "01_microarray_old_studies.png")
create_upset(microarray_cmap_drugs, "Drug Overlap in CMAP - Microarray Signatures", "02_microarray_cmap.png")
create_upset(microarray_tahoe_drugs, "Drug Overlap in TAHOE - Microarray Signatures", "03_microarray_tahoe.png")

# SINGLE CELL: Individual source comparisons
cat("\n===== SINGLE CELL: Individual Source Comparisons =====\n\n")

single_cell_old_drugs <- lapply(single_cell_sigs, function(sig) get_drugs(drugs_data[[sig]], "in_old"))
names(single_cell_old_drugs) <- gsub("^single_cell_", "", single_cell_sigs)
single_cell_old_drugs <- single_cell_old_drugs[sapply(single_cell_old_drugs, length) > 0]

single_cell_cmap_drugs <- lapply(single_cell_sigs, function(sig) get_drugs(drugs_data[[sig]], "in_cmap"))
names(single_cell_cmap_drugs) <- gsub("^single_cell_", "", single_cell_sigs)
single_cell_cmap_drugs <- single_cell_cmap_drugs[sapply(single_cell_cmap_drugs, length) > 0]

single_cell_tahoe_drugs <- lapply(single_cell_sigs, function(sig) get_drugs(drugs_data[[sig]], "in_tahoe"))
names(single_cell_tahoe_drugs) <- gsub("^single_cell_", "", single_cell_sigs)
single_cell_tahoe_drugs <- single_cell_tahoe_drugs[sapply(single_cell_tahoe_drugs, length) > 0]

create_upset(single_cell_old_drugs, "Drug Overlap in Old Studies - Single Cell Signatures", "04_single_cell_old_studies.png")
create_upset(single_cell_cmap_drugs, "Drug Overlap in CMAP - Single Cell Signatures", "05_single_cell_cmap.png")
create_upset(single_cell_tahoe_drugs, "Drug Overlap in TAHOE - Single Cell Signatures", "06_single_cell_tahoe.png")

# CMAP AND OLD STUDIES
cat("\n===== CMAP AND OLD STUDIES =====\n\n")

microarray_cmap_old_drugs <- lapply(microarray_sigs, function(sig) get_drugs(drugs_data[[sig]], "cmap_and_old_studies"))
names(microarray_cmap_old_drugs) <- gsub("^microarray_", "", microarray_sigs)
microarray_cmap_old_drugs <- microarray_cmap_old_drugs[sapply(microarray_cmap_old_drugs, length) > 0]

single_cell_cmap_old_drugs <- lapply(single_cell_sigs, function(sig) get_drugs(drugs_data[[sig]], "cmap_and_old_studies"))
names(single_cell_cmap_old_drugs) <- gsub("^single_cell_", "", single_cell_sigs)
single_cell_cmap_old_drugs <- single_cell_cmap_old_drugs[sapply(single_cell_cmap_old_drugs, length) > 0]

create_upset(microarray_cmap_old_drugs, "Drugs in Both CMAP and Old Studies - Microarray Signatures", "07_microarray_cmap_and_old_studies.png")
create_upset(single_cell_cmap_old_drugs, "Drugs in Both CMAP and Old Studies - Single Cell Signatures", "08_single_cell_cmap_and_old_studies.png")

# TAHOE AND OLD STUDIES
cat("\n===== TAHOE AND OLD STUDIES =====\n\n")

microarray_tahoe_old_drugs <- lapply(microarray_sigs, function(sig) get_drugs(drugs_data[[sig]], "tahoe_and_old_studies"))
names(microarray_tahoe_old_drugs) <- gsub("^microarray_", "", microarray_sigs)
microarray_tahoe_old_drugs <- microarray_tahoe_old_drugs[sapply(microarray_tahoe_old_drugs, length) > 0]

single_cell_tahoe_old_drugs <- lapply(single_cell_sigs, function(sig) get_drugs(drugs_data[[sig]], "tahoe_and_old_studies"))
names(single_cell_tahoe_old_drugs) <- gsub("^single_cell_", "", single_cell_sigs)
single_cell_tahoe_old_drugs <- single_cell_tahoe_old_drugs[sapply(single_cell_tahoe_old_drugs, length) > 0]

create_upset(microarray_tahoe_old_drugs, "Drugs in Both TAHOE and Old Studies - Microarray Signatures", "09_microarray_tahoe_and_old_studies.png")
create_upset(single_cell_tahoe_old_drugs, "Drugs in Both TAHOE and Old Studies - Single Cell Signatures", "10_single_cell_tahoe_and_old_studies.png")

# ALL THREE SOURCES
cat("\n===== ALL THREE SOURCES (TAHOE, CMAP, OLD) =====\n\n")

microarray_all_three_drugs <- lapply(microarray_sigs, function(sig) get_drugs(drugs_data[[sig]], "tahoe_cmap_old"))
names(microarray_all_three_drugs) <- gsub("^microarray_", "", microarray_sigs)
microarray_all_three_drugs <- microarray_all_three_drugs[sapply(microarray_all_three_drugs, length) > 0]

single_cell_all_three_drugs <- lapply(single_cell_sigs, function(sig) get_drugs(drugs_data[[sig]], "tahoe_cmap_old"))
names(single_cell_all_three_drugs) <- gsub("^single_cell_", "", single_cell_sigs)
single_cell_all_three_drugs <- single_cell_all_three_drugs[sapply(single_cell_all_three_drugs, length) > 0]

create_upset(microarray_all_three_drugs, "Drugs in TAHOE, CMAP, and Old Studies - Microarray Signatures", "11_microarray_tahoe_cmap_and_old.png")
create_upset(single_cell_all_three_drugs, "Drugs in TAHOE, CMAP, and Old Studies - Single Cell Signatures", "12_single_cell_tahoe_cmap_and_old.png")

cat("\n===== UpSet plots generation complete! =====\n")
cat("Plots saved to:", output_dir, "\n")

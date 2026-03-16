result_dir <- "/Users/enockniyonkuru/Desktop/drug_repurposing/tahoe_cmap_analysis/results/creed_manual_standardised_results_OG_exp_8/autoimmune_thrombocytopenic_purpura_TAHOE_20251122-100132"

csv_files <- list.files(result_dir, pattern = "\\.csv$", full.names = TRUE)
cat("CSV files found:\n")
print(basename(csv_files))

hits_file <- csv_files[grepl("hits", csv_files)]
cat("\nHits file:\n")
print(basename(hits_file))

if (length(hits_file) > 0) {
  df <- read.csv(hits_file[1], stringsAsFactors = FALSE)
  cat("\nDimensions:", nrow(df), "rows,", ncol(df), "cols\n")
  cat("First few column names:", colnames(df)[1:5], "\n")
  cat("First rows:\n")
  print(head(df))
}

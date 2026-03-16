results_base_dir <- '/Users/enockniyonkuru/Desktop/drug_repurposing/tahoe_cmap_analysis/results/creed_manual_standardised_results_OG_exp_8'

find_result_dir <- function(disease_name, platform) {
  pattern <- paste0('^', disease_name, '_', platform, '_')
  dirs <- list.dirs(results_base_dir, recursive = FALSE, full.names = TRUE)
  matching <- dirs[grepl(pattern, basename(dirs))]
  if (length(matching) > 0) return(matching[1])
  return(NULL)
}

# Test with each disease
diseases <- c('autoimmune_thrombocytopenic_purpura', 'cerebral_palsy', 'Eczema', 'chronic_lymphocytic_leukemia', 'endometriosis_of_ovary')

for (disease in diseases) {
  cmap <- find_result_dir(disease, 'CMAP')
  tahoe <- find_result_dir(disease, 'TAHOE')
  cat(sprintf('%s: CMAP=%s, TAHOE=%s\n', disease, !is.null(cmap), !is.null(tahoe)))
  if (!is.null(tahoe)) cat('  Found:', basename(tahoe), '\n')
}

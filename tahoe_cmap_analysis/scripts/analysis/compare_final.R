library(dplyr)

profiles <- c("ESE", "INII", "IIINIV", "MSE", "PE", "Unstratified")

# Read Tomiko's results
tomiko_results <- list()
for (profile in profiles) {
  file <- sprintf("tomiko_cdrpipe_comparison/old_tomiko_drug_hits_comparison/drug_instances_%s.csv", 
                  ifelse(profile == "IIINIV", "IIInIV", 
                         ifelse(profile == "INII", "InII", profile)))
  tomiko_results[[profile]] <- read.csv(file) %>%
    pull(name) %>%
    unique() %>%
    sort()
}

# Read our new results (DRpipe)
drpipe_results <- list()
for (profile in profiles) {
  search_pattern <- sprintf("scripts/results/CMAP_Endometriosis_%s_Strict_*/", profile)
  dir_match <- Sys.glob(search_pattern)[1]
  
  if (!is.na(dir_match)) {
    hits_file <- Sys.glob(file.path(dir_match, "*_q<0.*.csv"))[1]
    if (!is.na(hits_file)) {
      drpipe_results[[profile]] <- read.csv(hits_file) %>%
        pull(name) %>%
        unique() %>%
        sort()
    } else {
      drpipe_results[[profile]] <- character(0)
    }
  } else {
    drpipe_results[[profile]] <- character(0)
  }
}

# Compare results
comparison <- data.frame(
  Profile = profiles,
  Tomiko = sapply(profiles, function(p) length(tomiko_results[[p]])),
  DRpipe = sapply(profiles, function(p) length(drpipe_results[[p]])),
  Overlap = sapply(profiles, function(p) length(intersect(tomiko_results[[p]], drpipe_results[[p]]))),
  Only_Tomiko = sapply(profiles, function(p) length(setdiff(tomiko_results[[p]], drpipe_results[[p]]))),
  Only_DRpipe = sapply(profiles, function(p) length(setdiff(drpipe_results[[p]], tomiko_results[[p]])))
)

comparison$Overlap_Pct <- round(comparison$Overlap / comparison$Tomiko * 100, 1)

cat("\n=== ENDOMETRIOSIS: TOMIKO vs DRpipe ===\n")
print(comparison)

cat("\n=== DETAILED COMPARISON ===\n")
for (profile in profiles) {
  overlap <- intersect(tomiko_results[[profile]], drpipe_results[[profile]])
  only_tomiko <- setdiff(tomiko_results[[profile]], drpipe_results[[profile]])
  only_drpipe <- setdiff(drpipe_results[[profile]], tomiko_results[[profile]])
  
  cat(sprintf("\n%s (Tomiko: %d | DRpipe: %d | Overlap: %d/%d = %.1f%%)\n", 
              profile, 
              length(tomiko_results[[profile]]),
              length(drpipe_results[[profile]]),
              length(overlap),
              length(tomiko_results[[profile]]),
              length(overlap)/length(tomiko_results[[profile]])*100))
  
  if (length(overlap) > 0) {
    cat(sprintf("  Common: %s\n", paste(head(overlap, 8), collapse=", ")))
  }
  if (length(only_tomiko) > 0) {
    cat(sprintf("  Only Tomiko: %s\n", paste(head(only_tomiko, 5), collapse=", ")))
  }
  if (length(only_drpipe) > 0) {
    cat(sprintf("  Only DRpipe: %s\n", paste(head(only_drpipe, 5), collapse=", ")))
  }
}

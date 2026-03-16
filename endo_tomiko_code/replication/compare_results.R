#!/usr/bin/env Rscript
# Compare original and replicated drug_instances files

orig <- read.csv('code/unstratified/drug_instances_unstratified.csv', row.names=1)
rep <- read.csv('replication/drug_instances_unstratified_replicated.csv', row.names=1)

# Compare dimensions
cat('Original dimensions:', nrow(orig), 'x', ncol(orig), '\n')
cat('Replicated dimensions:', nrow(rep), 'x', ncol(rep), '\n\n')

# Compare key columns
key_cols <- c('exp_id', 'cmap_score', 'p', 'q', 'name')

cat('Comparing key columns:\n')
for (col in key_cols) {
  if (col %in% colnames(orig) && col %in% colnames(rep)) {
    if (col == 'name') {
      match <- all(orig[[col]] == rep[[col]])
    } else {
      match <- all(abs(orig[[col]] - rep[[col]]) < 1e-10, na.rm=TRUE)
    }
    cat(col, '- Match:', match, '\n')
    if (!match) {
      diff_idx <- which(orig[[col]] != rep[[col]])
      cat('  Differences at rows:', head(diff_idx, 5), '\n')
    }
  }
}

cat('\nFirst 5 drugs (original):\n')
print(orig[1:5, c('name', 'cmap_score', 'DrugBank.ID')])

cat('\nFirst 5 drugs (replicated):\n')
print(rep[1:5, c('name', 'cmap_score', 'DrugBank.ID')])

cat('\nLast 5 drugs (original):\n')
print(orig[(nrow(orig)-4):nrow(orig), c('name', 'cmap_score', 'DrugBank.ID')])

cat('\nLast 5 drugs (replicated):\n')
print(rep[(nrow(rep)-4):nrow(rep), c('name', 'cmap_score', 'DrugBank.ID')])

# Final verdict
all_match <- TRUE
for (col in key_cols) {
  if (col %in% colnames(orig) && col %in% colnames(rep)) {
    if (col == 'name') {
      match <- all(orig[[col]] == rep[[col]])
    } else {
      match <- all(abs(orig[[col]] - rep[[col]]) < 1e-10, na.rm=TRUE)
    }
    if (!match) all_match <- FALSE
  }
}

cat('\n========================================\n')
if (all_match && nrow(orig) == nrow(rep)) {
  cat('✓ REPLICATION SUCCESSFUL!\n')
  cat('  Identical results with original file.\n')
} else {
  cat('✗ REPLICATION FAILED!\n')
  cat('  Differences found between files.\n')
}
cat('========================================\n')

create_toy_pipeline_inputs <- function(base_dir) {
  signatures_path <- file.path(base_dir, "toy_signatures.RData")
  disease_path <- file.path(base_dir, "toy_disease.csv")
  gene_map_path <- file.path(base_dir, "gene_map.tsv")
  meta_path <- file.path(base_dir, "drug_meta.csv")
  valid_path <- file.path(base_dir, "drug_valid.csv")

  cmap_signatures <- data.frame(
    V1 = c("1", "2", "3", "4", "5", "6"),
    exp_a = c(6, 5, 4, 3, 2, 1),
    exp_b = c(1, 2, 3, 4, 5, 6),
    exp_c = c(2, 1, 4, 3, 6, 5),
    stringsAsFactors = FALSE
  )
  save(cmap_signatures, file = signatures_path)

  write.csv(
    data.frame(
      SYMBOL = c("G1", "G2", "G3", "G4", "G5", "G6"),
      log2FC = c(2, 1, -1.5, -2, 0.8, -0.7)
    ),
    disease_path,
    row.names = FALSE
  )

  write.table(
    data.frame(
      Gene_name = c("G1", "G2", "G3", "G4", "G5", "G6"),
      entrezID = c("1", "2", "3", "4", "5", "6")
    ),
    gene_map_path,
    sep = "\t",
    row.names = FALSE,
    quote = FALSE
  )

  write.csv(
    data.frame(
      id = 1:3,
      name = c("Drug A", "Drug B", "Drug C"),
      DrugBank.ID = c("DB1", "DB2", "DB3")
    ),
    meta_path,
    row.names = FALSE
  )

  write.csv(
    data.frame(
      id = 1:3,
      valid = c(1, 1, 1)
    ),
    valid_path,
    row.names = FALSE
  )

  list(
    signatures = signatures_path,
    disease = disease_path,
    gene_map = gene_map_path,
    meta = meta_path,
    valid = valid_path
  )
}

write_toy_result_file <- function(path, dataset_label = sub("\\.RData$", "", basename(path))) {
  results <- list(
    drugs = data.frame(
      exp_id = c(1, 2),
      cmap_score = c(-0.8, -0.3),
      q = c(0.01, 0.04),
      subset_comparison_id = c(dataset_label, dataset_label),
      stringsAsFactors = FALSE
    ),
    signature_clean = data.frame(
      GeneID = c("1", "2"),
      logFC = c(1.25, -1.10),
      stringsAsFactors = FALSE
    )
  )

  save(results, file = path)
  invisible(path)
}

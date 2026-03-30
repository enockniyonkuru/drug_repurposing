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

test_that("cmap_score distinguishes mimicry from reversal", {
  drug_signature <- data.frame(ids = c("1", "2", "3", "4"), rank = c(1, 2, 3, 4))

  same_direction <- cmap_score(
    sig_up = data.frame(GeneID = c("1", "2")),
    sig_down = data.frame(GeneID = c("3", "4")),
    drug_signature = drug_signature
  )

  reversed <- cmap_score(
    sig_up = data.frame(GeneID = c("3", "4")),
    sig_down = data.frame(GeneID = c("1", "2")),
    drug_signature = drug_signature
  )

  expect_gt(same_direction, 0)
  expect_lt(reversed, 0)
})

test_that("CDRP smoke test writes expected output artifacts", {
  td <- tempfile("cdrpipe-smoke-")
  dir.create(td)
  on.exit(unlink(td, recursive = TRUE), add = TRUE)

  toy <- create_toy_pipeline_inputs(td)
  out_dir <- file.path(td, "out")

  drp <- CDRP$new(
    signatures_rdata = toy$signatures,
    disease_path = toy$disease,
    drug_meta_path = toy$meta,
    drug_valid_path = toy$valid,
    gene_conversion_table = toy$gene_map,
    out_dir = out_dir,
    logfc_cutoff = 0.5,
    q_thresh = 1,
    n_permutations = 25,
    verbose = FALSE
  )

  expect_no_error(capture.output(drp$run_all(make_plots = FALSE)))

  results_file <- file.path(out_dir, "toy_disease_results.RData")
  expect_true(file.exists(results_file))

  hit_files <- list.files(
    out_dir,
    pattern = "_hits_logFC_0\\.5_q<1\\.00\\.csv$",
    full.names = TRUE
  )
  expect_length(hit_files, 1)

  result_env <- new.env(parent = emptyenv())
  load(results_file, envir = result_env)

  expect_true(exists("results", envir = result_env, inherits = FALSE))
  expect_true(is.list(result_env$results))
  expect_true(all(c("drugs", "signature_clean") %in% names(result_env$results)))

  expect_s3_class(drp$drugs_valid, "data.frame")
  expect_gt(nrow(drp$drugs_valid), 0)
  expect_true(all(c("name", "cmap_score", "q") %in% names(drp$drugs_valid)))
})

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

test_that("single-mode scoring helpers support progress-aware ncores", {
  td <- tempfile("cdrpipe-score-")
  dir.create(td)
  on.exit(unlink(td, recursive = TRUE), add = TRUE)

  toy <- create_toy_pipeline_inputs(td)
  sig_env <- new.env(parent = emptyenv())
  load(toy$signatures, envir = sig_env)
  cmap_signatures <- sig_env$cmap_signatures

  dz_up <- c("1", "2")
  dz_down <- c("5", "6")

  serial_scores <- NULL
  parallel_scores <- NULL
  capture.output(
    serial_scores <- query_score(cmap_signatures, dz_up, dz_down, ncores = 1),
    type = "output"
  )
  capture.output(
    parallel_scores <- query_score(cmap_signatures, dz_up, dz_down, ncores = 2),
    type = "output"
  )

  expect_equal(serial_scores, parallel_scores)

  random_parallel_a <- NULL
  random_parallel_b <- NULL
  capture.output(
    random_parallel_a <- random_score(cmap_signatures, 2, 2, N_PERMUTATIONS = 12, seed = 123, ncores = 2),
    type = "output"
  )
  capture.output(
    random_parallel_b <- random_score(cmap_signatures, 2, 2, N_PERMUTATIONS = 12, seed = 123, ncores = 2),
    type = "output"
  )

  expect_equal(length(random_parallel_a), 12)
  expect_equal(random_parallel_a, random_parallel_b)
})

test_that("DRP smoke test writes expected output artifacts", {
  td <- tempfile("cdrpipe-smoke-")
  dir.create(td)
  on.exit(unlink(td, recursive = TRUE), add = TRUE)

  toy <- create_toy_pipeline_inputs(td)
  out_dir <- file.path(td, "out")

  drp <- DRP$new(
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

test_that("run_dr wrapper produces expected artifacts", {
  td <- tempfile("cdrpipe-wrapper-")
  dir.create(td)
  on.exit(unlink(td, recursive = TRUE), add = TRUE)
  local_mocked_bindings(
    gconvert = function(query, ...) {
      data.frame(target = as.character(query), stringsAsFactors = FALSE)
    },
    .package = "CDRPipe"
  )

  toy <- create_toy_pipeline_inputs(td)
  out_dir <- file.path(td, "out-wrapper")
  disease_path <- file.path(td, "toy_disease_gene_ids.csv")

  write.csv(
    data.frame(
      GeneID = c("1", "2", "3", "4", "5", "6"),
      logFC = c(2, 1, -1.5, -2, 0.8, -0.7)
    ),
    disease_path,
    row.names = FALSE
  )

  expect_no_error(
    capture.output(
      run_dr(
        signatures_rdata = toy$signatures,
        disease_path = disease_path,
        drug_meta_path = toy$meta,
        drug_valid_path = toy$valid,
        out_dir = out_dir,
        gene_key = "GeneID",
        logfc_cols_pref = "logFC",
        logfc_cutoff = 0.5,
        q_thresh = 1,
        seed = 123,
        verbose = FALSE,
        make_plots = FALSE
      )
    )
  )

  expect_true(file.exists(file.path(out_dir, "toy_disease_gene_ids_results.RData")))
  expect_true(
    any(grepl("_hits_logFC_0\\.5_q<1\\.00\\.csv$", list.files(out_dir)))
  )
})

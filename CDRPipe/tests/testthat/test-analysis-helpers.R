test_that("load_run_results preserves run names and signatures", {
  td <- tempfile("cdrpipe-results-")
  dir.create(td)
  on.exit(unlink(td, recursive = TRUE), add = TRUE)

  alpha <- write_toy_result_file(file.path(td, "alpha_results.RData"), dataset_label = "alpha")
  beta <- write_toy_result_file(file.path(td, "beta_results.RData"), dataset_label = "beta")

  loaded <- load_run_results(c(alpha, beta))

  expect_named(loaded, c("drugs", "signatures"))
  expect_setequal(names(loaded$drugs), c("alpha_results", "beta_results"))
  expect_setequal(names(loaded$signatures), c("alpha_results", "beta_results"))
  expect_true(all(vapply(loaded$drugs, is.data.frame, logical(1))))
  expect_true(all(vapply(loaded$signatures, is.data.frame, logical(1))))
})

test_that("DRA load_runs honors the requested pattern", {
  td <- tempfile("cdrpipe-dra-")
  dir.create(td)
  on.exit(unlink(td, recursive = TRUE), add = TRUE)

  write_toy_result_file(file.path(td, "keep_results.RData"), dataset_label = "keep")
  write_toy_result_file(file.path(td, "skip_profile.RData"), dataset_label = "skip")

  dra <- DRA$new(
    results_dir = td,
    analysis_dir = file.path(td, "analysis"),
    verbose = FALSE
  )

  expect_no_error(dra$load_runs(pattern = "^keep_results\\.RData$"))
  expect_identical(names(dra$drugs), "keep_results")
  expect_identical(names(dra$signatures), "keep_results")
})

test_that("annotate_filter_runs filters valid reversers and deduplicates names", {
  td <- tempfile("cdrpipe-annotate-")
  dir.create(td)
  on.exit(unlink(td, recursive = TRUE), add = TRUE)

  meta_path <- file.path(td, "meta.csv")
  valid_path <- file.path(td, "valid.csv")

  write.csv(
    data.frame(
      id = 1:5,
      name = c("Drug A", "Drug A", "Drug B", "Drug C", "Drug D"),
      DrugBank.ID = c("DB1", "DB1", "DB2", "DB3", "NULL"),
      stringsAsFactors = FALSE
    ),
    meta_path,
    row.names = FALSE
  )

  write.csv(
    data.frame(
      id = 1:5,
      valid = c(1, 1, 1, 1, 1)
    ),
    valid_path,
    row.names = FALSE
  )

  drugs_list <- list(
    demo = data.frame(
      exp_id = c(1, 2, 3, 4, 5),
      q = c(0.02, 0.01, 0.04, 0.01, 0.01),
      cmap_score = c(-0.4, -0.9, -0.7, 0.3, -0.8),
      subset_comparison_id = rep("demo", 5),
      stringsAsFactors = FALSE
    )
  )

  filtered <- annotate_filter_runs(
    drugs_list,
    cmap_meta_path = meta_path,
    cmap_valid_path = valid_path,
    q_thresh = 0.03,
    reversal_only = TRUE
  )

  expect_named(filtered, "demo")
  expect_s3_class(filtered$demo, "data.frame")
  expect_equal(nrow(filtered$demo), 1)
  expect_identical(filtered$demo$name[[1]], "Drug A")
  expect_identical(filtered$demo$exp_id[[1]], 2)
})

test_that("plot helpers write files into the requested directory", {
  td <- tempfile("cdrpipe-plots-")
  dir.create(td)
  on.exit(unlink(td, recursive = TRUE), add = TRUE)

  score_plot <- pl_cmap_score(
    data.frame(name = c("Drug A", "Drug B"), cmap_score = c(-0.8, -0.5)),
    path = td,
    save = "scores.jpg",
    width = 4,
    height = 4,
    res = 150
  )

  overlap_plot <- pl_overlap(
    data.frame(
      name = c("Drug A", "Drug A", "Drug B", "Drug B"),
      subset_comparison_id = c("run1", "run2", "run1", "run2"),
      cmap_score = c(-0.8, -0.6, -0.5, -0.7)
    ),
    path = td,
    save = "overlap.jpg",
    width = 4,
    height = 3,
    res = 150
  )

  upset_plot <- pl_upset(
    list(run1 = c("Drug A", "Drug B"), run2 = c("Drug A")),
    path = td,
    save = "upset.jpg",
    width = 4,
    height = 3,
    res = 150
  )

  expect_true(file.exists(score_plot))
  expect_true(file.exists(overlap_plot))
  expect_true(file.exists(upset_plot))
})

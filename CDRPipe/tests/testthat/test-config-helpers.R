write_test_config <- function(path) {
  writeLines(
    c(
      "default:",
      "  paths:",
      "    signatures: toy_signatures.RData",
      "  params:",
      "    q_thresh: 0.05",
      "analysis:",
      "  paths:",
      "    signatures: analysis_signatures.RData",
      "  params:",
      "    q_thresh: 0.10"
    ),
    con = path
  )
}

test_that("config helpers support explicit files and DRPIPE env vars", {
  td <- tempfile("cdrpipe-config-")
  dir.create(td)
  on.exit(unlink(td, recursive = TRUE), add = TRUE)

  cfg_path <- file.path(td, "config.yml")
  write_test_config(cfg_path)

  old_profile <- Sys.getenv("DRPIPE_PROFILE", unset = NA_character_)
  old_config <- Sys.getenv("DRPIPE_CONFIG", unset = NA_character_)
  on.exit({
    do.call(Sys.setenv, list(DRPIPE_PROFILE = old_profile, DRPIPE_CONFIG = old_config))
  }, add = TRUE)

  Sys.setenv(DRPIPE_CONFIG = cfg_path, DRPIPE_PROFILE = "analysis")

  cfg <- load_dr_config()
  expect_match(cfg$paths$signatures, "analysis_signatures\\.RData$")
  expect_equal(cfg$params$q_thresh, 0.10)

  Sys.unsetenv("DRPIPE_PROFILE")
  default_cfg <- load_dr_config(profile = "default", config_file = cfg_path)
  expect_match(default_cfg$paths$signatures, "toy_signatures\\.RData$")
  expect_equal(default_cfg$params$q_thresh, 0.05)
})

test_that("path helpers handle both single files and directories", {
  td <- tempfile("cdrpipe-io-")
  dir.create(td)
  on.exit(unlink(td, recursive = TRUE), add = TRUE)

  disease_dir <- file.path(td, "diseases")
  dir.create(disease_dir)
  disease_file <- file.path(disease_dir, "toy_signature.csv")
  write.csv(data.frame(SYMBOL = "G1", log2FC = 1), disease_file, row.names = FALSE)
  disease_file_resolved <- io_resolve_path(disease_file)

  expect_equal(io_list_disease_files(disease_file), disease_file_resolved)

  from_dir <- io_list_disease_files(disease_dir, "toy_signature\\.csv$")
  expect_equal(from_dir, disease_file_resolved)
})

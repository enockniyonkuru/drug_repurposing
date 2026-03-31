args <- commandArgs(trailingOnly = TRUE)
pkg_dir <- if (length(args) >= 1) args[[1]] else "CDRPipe"

required_packages <- "testthat"
missing_packages <- required_packages[!vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)]
desc_path <- file.path(pkg_dir, "DESCRIPTION")
optional_suggests <- character()
if (file.exists(desc_path)) {
  raw_suggests <- tryCatch(read.dcf(desc_path, fields = "Suggests")[1, 1], error = function(e) NA_character_)
  if (!is.na(raw_suggests) && nzchar(raw_suggests)) {
    optional_suggests <- trimws(unlist(strsplit(gsub("\\([^\\)]*\\)", "", raw_suggests), ",")))
    optional_suggests <- optional_suggests[nzchar(optional_suggests)]
  }
}
optional_suggests <- setdiff(optional_suggests, required_packages)
missing_optional_suggests <- optional_suggests[
  !vapply(optional_suggests, requireNamespace, logical(1), quietly = TRUE)
]

if (length(missing_packages) > 0) {
  stop(
    "Missing required packages for package checks: ",
    paste(missing_packages, collapse = ", "),
    call. = FALSE
  )
}

if (length(missing_optional_suggests) > 0) {
  Sys.setenv(`_R_CHECK_FORCE_SUGGESTS_` = "false")
  cat(
    "Optional suggested packages not installed locally:",
    paste(missing_optional_suggests, collapse = ", "),
    "\n"
  )
  cat("Running R CMD check with _R_CHECK_FORCE_SUGGESTS_=false.\n")
}

cat("Running CDRPipe tests in:", pkg_dir, "\n")
testthat::test_local(path = pkg_dir, reporter = "summary", stop_on_failure = TRUE)

cat("Running R CMD check for:", pkg_dir, "\n")
if (requireNamespace("rcmdcheck", quietly = TRUE)) {
  rcmdcheck::rcmdcheck(
    pkg_dir,
    args = c("--no-manual"),
    error_on = "warning",
    check_dir = file.path(tempdir(), "cdrpipe-rcmdcheck")
  )
} else {
  tarball <- system2(
    "R",
    c("CMD", "build", pkg_dir),
    stdout = TRUE,
    stderr = TRUE
  )
  cat(paste(tarball, collapse = "\n"), "\n")

  built_candidates <- list.files(
    path = ".",
    pattern = "^CDRPipe_.*\\.tar\\.gz$",
    full.names = TRUE
  )
  built_pkg <- if (length(built_candidates) > 0) {
    built_candidates[[which.max(file.info(built_candidates)$mtime)]]
  } else {
    NA_character_
  }

  if (!nzchar(built_pkg) || !file.exists(built_pkg)) {
    stop("Could not locate the built package tarball after `R CMD build`.", call. = FALSE)
  }

  check_output <- system2(
    "R",
    c("CMD", "check", "--no-manual", built_pkg),
    stdout = TRUE,
    stderr = TRUE
  )
  cat(paste(check_output, collapse = "\n"), "\n")

  check_status <- attr(check_output, "status")
  if (is.null(check_status)) {
    check_status <- 0L
  }

  if (!identical(check_status, 0L)) {
    stop("`R CMD check` failed with exit code ", check_status, call. = FALSE)
  }

  check_log <- file.path(".", paste0(basename(normalizePath(pkg_dir)), ".Rcheck"), "00check.log")
  if (!file.exists(check_log)) {
    stop("Could not locate `00check.log` after `R CMD check`.", call. = FALSE)
  }

  log_lines <- readLines(check_log, warn = FALSE)
  status_line <- tail(grep("^Status:", log_lines, value = TRUE), 1)

  if (!identical(status_line, "Status: OK")) {
    stop("`R CMD check` completed without a clean status: ", status_line, call. = FALSE)
  }
}

cat("CDRPipe checks completed successfully.\n")

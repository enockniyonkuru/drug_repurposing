#' DRA: Drug Repurposing Analysis (R6)
#' Works from saved *_results.RData, annotates, plots, and summarizes across runs.
#' @export
DRA <- R6::R6Class(
  "DRA",
  public = list(
    results_dir   = NULL,
    analysis_dir  = NULL,
    cmap_meta_path  = NULL,
    cmap_valid_path = NULL,
    cmap_signatures_path = NULL,
    q_thresh      = 0.05,
    reversal_only = TRUE,
    verbose       = TRUE,

    drugs         = NULL, # named list per run
    signatures    = NULL, # named list per run

    initialize = function(results_dir = "scripts/results",
                          analysis_dir = "scripts/results/analysis",
                          cmap_meta_path = NULL,
                          cmap_valid_path = NULL,
                          cmap_signatures_path = NULL,
                          q_thresh = 0.05,
                          reversal_only = TRUE,
                          verbose = TRUE) {
      self$results_dir  <- io_resolve_path(results_dir)
      self$analysis_dir <- io_resolve_path(analysis_dir)
      self$cmap_meta_path <- io_resolve_path(cmap_meta_path)
      self$cmap_valid_path <- io_resolve_path(cmap_valid_path)
      self$cmap_signatures_path <- io_resolve_path(cmap_signatures_path)
      self$q_thresh     <- q_thresh
      self$reversal_only <- reversal_only
      self$verbose      <- verbose
      io_ensure_dir(self$analysis_dir)
    },

    log = function(...) if (self$verbose) cat(sprintf("[DRA] %s\n", sprintf(...))),

    load_runs = function(pattern = "_results\\.RData$") {
      files <- list.files(self$results_dir, pattern = pattern, full.names = TRUE)
      if (!length(files)) stop("No results found in ", self$results_dir, " (pattern: ", pattern, ")")
      lst <- load_run_results(files)
      self$drugs <- lst$drugs
      self$signatures <- lst$signatures
      self$log("Loaded %d runs.", length(self$drugs))
      invisible(self)
    },

    annotate_filter = function() {
      stopifnot(!is.null(self$cmap_meta_path), !is.null(self$cmap_valid_path))
      self$drugs <- annotate_filter_runs(self$drugs,
                                         cmap_meta_path  = self$cmap_meta_path,
                                         cmap_valid_path = self$cmap_valid_path,
                                         q_thresh        = self$q_thresh,
                                         reversal_only   = self$reversal_only)
      invisible(self)
    },

    per_run_reports = function() {
      stopifnot(!is.null(self$cmap_signatures_path))
      # Check optional plotting deps only here
      if (!requireNamespace("pheatmap", quietly = TRUE) ||
          !requireNamespace("UpSetR", quietly = TRUE)) {
        self$log("Note: pheatmap/UpSetR not installed; some plots may be skipped.")
      }
      report_runs(self$drugs, self$signatures,
                  cmap_signatures_path = self$cmap_signatures_path,
                  out_dir = self$analysis_dir)
      invisible(self)
    },

    cross_run_summaries = function() {
      summarize_across_runs(self$drugs, out_dir = self$analysis_dir)
      invisible(self)
    },

    run = function() {
      self$load_runs()$annotate_filter()$per_run_reports()$cross_run_summaries()
      self$log("Done. Outputs in: %s", self$analysis_dir)
      invisible(self)
    }
  )
)

# ---------- Helpers (reused from earlier suggestion) ----------

#' Load a set of pipeline result files (RData) produced by run_dr()
#' @param result_files Vector of file paths to RData files containing results
#' @export
load_run_results <- function(result_files) {
  stopifnot(length(result_files) > 0)
  out <- lapply(result_files, function(fp) {
    env <- new.env(parent = emptyenv())
    load(fp, envir = env)  # expects `results`
    if (!exists("results", envir = env)) stop("File ", fp, " lacks `results`.")
    get("results", envir = env)
  })
  names(out) <- sub("\\.RData$", "", basename(result_files))
  list(drugs = lapply(out, `[[`, 1),
       signatures = lapply(out, `[[`, 2))
}

#' Annotate/filter a list of per-run drug tables using CMAP metadata
#' @param drugs_list Named list of drug result data frames from multiple runs
#' @param cmap_meta_path Path to CMAP experiment metadata CSV file
#' @param cmap_valid_path Path to CMAP valid instances CSV file
#' @param q_thresh Q-value threshold for significance filtering (default: 0.05)
#' @param reversal_only Whether to consider only reversal scores (default: TRUE)
#' @export
annotate_filter_runs <- function(drugs_list, cmap_meta_path, cmap_valid_path,
                                 q_thresh = 0.05, reversal_only = TRUE) {
  meta  <- utils::read.csv(cmap_meta_path,  stringsAsFactors = FALSE)
  valid <- utils::read.csv(cmap_valid_path, stringsAsFactors = FALSE)
  meta_valid <- merge(meta, valid, by = "id")
  meta_valid <- subset(meta_valid, valid == 1 & meta_valid$DrugBank.ID != "NULL")
  lapply(drugs_list, function(x) {
    dv <- valid_instance(x, meta_valid)
    if (reversal_only) dv <- subset(dv, cmap_score < 0)
    dv <- subset(dv, q < q_thresh)
    if ("name" %in% names(dv)) {
      dv <- dv |>
        dplyr::group_by(name) |>
        dplyr::slice(which.min(cmap_score)) |>
        dplyr::ungroup()
    }
    dv
  })
}

#' Make standard per-run plots & CSVs
#' @param drugs_list Named list of drug result data frames from multiple runs
#' @param signatures_list Named list of signature data frames from multiple runs
#' @param cmap_signatures_path Path to RData file containing CMAP signatures
#' @param out_dir Output directory for reports and plots (default: "scripts/results/analysis")
#' @export
report_runs <- function(drugs_list, signatures_list, cmap_signatures_path,
                        out_dir = "scripts/results/analysis") {
  io_ensure_dir(out_dir); io_ensure_dir(file.path(out_dir, "img"))
  env <- new.env(parent = emptyenv())
  load(cmap_signatures_path, envir = env)
  cmap_signatures <- if (exists("cmap_signatures", envir = env)) get("cmap_signatures", envir = env) else get(ls(env)[[1]], envir = env)
  # distributions
  try(pl_hist_revsc(drugs_list, save = "dist_rev_score.jpeg",
                    path = file.path(out_dir, "img"), width = 1500), silent = TRUE)
  for (nm in names(drugs_list)) {
    x  <- drugs_list[[nm]]
    dz <- signatures_list[[nm]]
    try(pl_cmap_score(x, save = file.path(out_dir, "img", paste0(nm, "_cmap_score.jpg"))), silent = TRUE)
    try(pl_heatmap(x, dz, cmap_signatures, nm,
                   width = 12, height = 10, units = "in",
                   save = file.path(out_dir, "img", paste0(nm, "_heatmap_cmap_hits.jpg"))), silent = TRUE)
    try({
      tab <- prepare_heatmap(x, dz_sig = dz, cmap_signatures)
      utils::write.csv(tab, file = file.path(out_dir, paste0(nm, "_drug_dz_signature_all_hits.csv")), row.names = FALSE)
    }, silent = TRUE)
    if (nrow(x)) utils::write.csv(x, file = file.path(out_dir, paste0(nm, "_hits.csv")), row.names = FALSE)
  }
  invisible(TRUE)
}

#' Integrate across runs: overlaps & UpSet
#' @param drugs_list Named list of drug result data frames from multiple runs
#' @param out_dir Output directory for summary plots and files (default: "scripts/results/analysis")
#' @export
summarize_across_runs <- function(drugs_list, out_dir = "scripts/results/analysis") {
  io_ensure_dir(out_dir); io_ensure_dir(file.path(out_dir, "img"))
  drugs_integrated <- do.call("rbind", drugs_list)
  try(pl_overlap(drugs_integrated, save = file.path(out_dir, "img", "hits_overlap_heatmap.jpg")), silent = TRUE)
  try(pl_overlap(drugs_integrated, at_least2 = TRUE, width = 7,
                 save = file.path(out_dir, "img", "hits_overlap_atleast2_heatmap.jpg")), silent = TRUE)
  ls <- prepare_upset_drug(drugs_integrated)
  try(pl_upset(ls, save = file.path(out_dir, "img", "upset.jpg")), silent = TRUE)
  invisible(TRUE)
}

#' One-call analysis (batch)
#' @param results_dir Directory containing pipeline result RData files (default: "scripts/results")
#' @param analysis_dir Output directory for analysis results (default: "scripts/results/analysis")
#' @param cmap_meta_path Path to CMAP experiment metadata CSV file
#' @param cmap_valid_path Path to CMAP valid instances CSV file
#' @param cmap_signatures_path Path to RData file containing CMAP signatures
#' @param q_thresh Q-value threshold for significance filtering (default: 0.05)
#' @param reversal_only Whether to consider only reversal scores (default: TRUE)
#' @param verbose Whether to print progress messages (default: TRUE)
#' @export
analyze_runs <- function(results_dir = "scripts/results",
                         analysis_dir = "scripts/results/analysis",
                         cmap_meta_path,
                         cmap_valid_path,
                         cmap_signatures_path,
                         q_thresh = 0.05,
                         reversal_only = TRUE,
                         verbose = TRUE) {
  DRA$new(results_dir = results_dir,
          analysis_dir = analysis_dir,
          cmap_meta_path = cmap_meta_path,
          cmap_valid_path = cmap_valid_path,
          cmap_signatures_path = cmap_signatures_path,
          q_thresh = q_thresh,
          reversal_only = reversal_only,
          verbose = verbose)$run()
}

#' DRP: Drug Repurposing Pipeline (R6)
#'
#' Wraps the processing + analysis flow so users set parameters once
#' and can run the whole pipeline with a single call.
#'
#' @export
DRP <- R6::R6Class(
  "DRP",
  public = list(
    # --------- user-facing configuration ---------
    signatures_rdata = NULL,     # e.g. "scripts/data/cmap_signatures.RData"
    disease_path     = NULL,     # CSV path OR directory
    disease_pattern  = NULL,     # used if disease_path is a directory
    cmap_meta_path   = NULL,     # "scripts/data/cmap_drug_experiments_new.csv"
    cmap_valid_path  = NULL,     # "scripts/data/cmap_valid_instances.csv"
    out_dir          = "scripts/results",
    gene_key         = "SYMBOL",
    logfc_cols_pref  = "log2FC",
    logfc_cutoff     = 1,
    q_thresh         = 0.05,
    reversal_only    = TRUE,
    seed             = 123,
    verbose          = TRUE,
    
    # --------- new sweep mode configuration ---------
    mode             = "single",
    sweep_cutoffs    = NULL,
    sweep_min_frac   = 0.20,
    sweep_min_genes  = 200,
    combine_log2fc   = "average",
    robust_rule      = "all",
    robust_k         = NULL,
    aggregate        = "mean",
    weights          = NULL,

    # --------- pipeline state (filled as it runs) ---------
    cmap_signatures    = NULL,
    dz_signature_raw   = NULL,
    dz_signature       = NULL,
    dz_signature_list  = NULL,  # for combine_log2fc handling
    dz_genes_up        = NULL,
    dz_genes_down      = NULL,
    rand_scores        = NULL,
    obs_scores         = NULL,
    drugs              = NULL,
    drugs_valid        = NULL,
    dataset_label      = NULL,
    sweep_hits         = NULL,  # for sweep mode results
    cutoff_summary     = NULL,  # for sweep mode summary
    robust_hits        = NULL,  # for aggregated results

    # --------- ctor ---------
    initialize = function(
      signatures_rdata,
      disease_path,
      disease_pattern = NULL,
      cmap_meta_path  = NULL,
      cmap_valid_path = NULL,
      out_dir         = "scripts/results",
      gene_key        = "SYMBOL",
      logfc_cols_pref = "log2FC",
      logfc_cutoff    = 1,
      q_thresh        = 0.05,
      reversal_only   = TRUE,
      seed            = 123,
      verbose         = TRUE,
      mode            = c("single", "sweep"),
      sweep_cutoffs   = NULL,
      sweep_min_frac  = 0.20,
      sweep_min_genes = 200,
      combine_log2fc  = c("average", "each"),
      robust_rule     = c("all", "k_of_n"),
      robust_k        = NULL,
      aggregate       = c("mean", "median", "weighted_mean"),
      weights         = NULL
    ) {
      # Original parameters
      self$signatures_rdata <- io_resolve_path(signatures_rdata)
      self$disease_path     <- io_resolve_path(disease_path)
      self$disease_pattern  <- disease_pattern
      self$cmap_meta_path   <- if (!is.null(cmap_meta_path)) io_resolve_path(cmap_meta_path) else NULL
      self$cmap_valid_path  <- if (!is.null(cmap_valid_path)) io_resolve_path(cmap_valid_path) else NULL
      self$out_dir          <- io_resolve_path(out_dir)
      self$gene_key         <- gene_key
      self$logfc_cols_pref  <- logfc_cols_pref
      self$logfc_cutoff     <- logfc_cutoff
      self$q_thresh         <- q_thresh
      self$reversal_only    <- reversal_only
      self$seed             <- seed
      self$verbose          <- verbose
      
      # New parameters with validation
      self$mode            <- match.arg(mode)
      self$sweep_cutoffs   <- sweep_cutoffs
      self$sweep_min_frac  <- sweep_min_frac
      self$sweep_min_genes <- sweep_min_genes
      self$combine_log2fc  <- match.arg(combine_log2fc)
      self$robust_rule     <- match.arg(robust_rule)
      self$robust_k        <- robust_k
      self$aggregate       <- match.arg(aggregate)
      self$weights         <- weights
      
      io_ensure_dir(self$out_dir)
    },

    # --------- helpers ---------
    log = function(...) if (isTRUE(self$verbose)) cat(sprintf("[DRP] %s\n", sprintf(...))),

    # --------- steps: processing ---------
    load_cmap = function() {
      self$log("Loading CMAP signatures: %s", self$signatures_rdata)
      stopifnot(file.exists(self$signatures_rdata))
      env <- new.env(parent = emptyenv())
      load(self$signatures_rdata, envir = env)
      if (exists("cmap_signatures", envir = env, inherits = FALSE)) {
        self$cmap_signatures <- get("cmap_signatures", envir = env)
      } else {
        # Fallback: grab first object
        nm <- ls(env)
        if (!length(nm)) stop("No objects found in ", self$signatures_rdata)
        self$cmap_signatures <- get(nm[[1]], envir = env)
      }
      invisible(self)
    },

    load_disease = function() {
      file <- if (file.exists(self$disease_path) && !dir.exists(self$disease_path)) {
        self$disease_path
      } else {
        cand <- io_list_disease_files(self$disease_path, self$disease_pattern)
        if (!length(cand)) stop("No disease files matched in: ", self$disease_path)
        cand[[1]]
      }
      self$log("Reading disease signature CSV: %s", file)
      self$dz_signature_raw <- utils::read.csv(file, stringsAsFactors = FALSE, check.names = FALSE)
      base <- basename(file)
      self$dataset_label <- sub("\\.csv$", "", base)
      invisible(self)
    },

    clean_signature = function(cutoff = NULL) {
      # Use provided cutoff or default to instance cutoff
      use_cutoff <- if (!is.null(cutoff)) cutoff else self$logfc_cutoff
      
      # Detect all log2FC columns
      lc_cols <- grep(paste0("^", self$logfc_cols_pref), names(self$dz_signature_raw), value = TRUE)
      if (!length(lc_cols)) stop("No columns starting with '", self$logfc_cols_pref, "' found.")
      
      # Get gene universe from cmap
      db_genes <- NULL
      if (is.data.frame(self$cmap_signatures)) {
        if ("V1" %in% names(self$cmap_signatures)) db_genes <- self$cmap_signatures$V1
        if (is.null(db_genes) && "gene" %in% names(self$cmap_signatures)) db_genes <- self$cmap_signatures$gene
      }
      if (is.null(db_genes)) db_genes <- unique(unlist(self$cmap_signatures))
      
      # Initialize signature list
      self$dz_signature_list <- list()
      
      if (self$combine_log2fc == "average") {
        # Average approach: compute mean logFC across all columns
        self$dz_signature_raw$logFC <- rowMeans(self$dz_signature_raw[, lc_cols, drop = FALSE], na.rm = TRUE)
        
        cleaned <- clean_table(
          self$dz_signature_raw,
          gene_key     = self$gene_key,
          logFC_key    = "logFC",
          logFC_cutoff = use_cutoff,
          pval_key     = NULL,
          db_gene_list = db_genes
        )
        
        # Store cleaned signature and gene lists
        self$dz_signature_list[["average"]] <- list(
          signature = cleaned,
          up_ids = dplyr::filter(cleaned, logFC > 0) |> dplyr::pull(GeneID),
          down_ids = dplyr::filter(cleaned, logFC < 0) |> dplyr::pull(GeneID)
        )
        
        # For backward compatibility, also set the original fields
        self$dz_signature <- cleaned
        self$dz_genes_up <- self$dz_signature_list[["average"]]$up_ids
        self$dz_genes_down <- self$dz_signature_list[["average"]]$down_ids
        
        self$log("Cleaned signature (average): n_up=%d  n_down=%d", 
                 length(self$dz_genes_up), length(self$dz_genes_down))
        
      } else if (self$combine_log2fc == "each") {
        # Each approach: process each log2FC column separately
        for (col in lc_cols) {
          # Set logFC to current column
          self$dz_signature_raw$logFC <- self$dz_signature_raw[[col]]
          
          cleaned <- clean_table(
            self$dz_signature_raw,
            gene_key     = self$gene_key,
            logFC_key    = "logFC",
            logFC_cutoff = use_cutoff,
            pval_key     = NULL,
            db_gene_list = db_genes
          )
          
          # Store cleaned signature and gene lists
          self$dz_signature_list[[col]] <- list(
            signature = cleaned,
            up_ids = dplyr::filter(cleaned, logFC > 0) |> dplyr::pull(GeneID),
            down_ids = dplyr::filter(cleaned, logFC < 0) |> dplyr::pull(GeneID)
          )
          
          self$log("Cleaned signature (%s): n_up=%d  n_down=%d", col,
                   length(self$dz_signature_list[[col]]$up_ids),
                   length(self$dz_signature_list[[col]]$down_ids))
        }
        
        # For backward compatibility, use first column as default
        first_col <- lc_cols[[1]]
        self$dz_signature <- self$dz_signature_list[[first_col]]$signature
        self$dz_genes_up <- self$dz_signature_list[[first_col]]$up_ids
        self$dz_genes_down <- self$dz_signature_list[[first_col]]$down_ids
      }
      
      invisible(self)
    },

    score = function() {
      set.seed(self$seed)
      self$log("Scoring (random null + observed)")
      self$rand_scores <- random_score(self$cmap_signatures, length(self$dz_genes_up), length(self$dz_genes_down))
      self$obs_scores  <- query_score(self$cmap_signatures, self$dz_genes_up, self$dz_genes_down)
      self$drugs <- query(
        self$rand_scores,
        self$obs_scores,
        subset_comparison_id = sprintf("%s_logFC_%s", self$dataset_label, self$logfc_cutoff)
      )
      invisible(self)
    },

    # --------- steps: analysis / reporting ---------
    annotate_and_filter = function() {
      if (is.null(self$cmap_meta_path) || is.null(self$cmap_valid_path)) {
        self$log("Skipping annotation (metadata paths not provided).")
        self$drugs_valid <- self$drugs
        return(invisible(self))
      }
      self$log("Annotating with CMAP metadata...")
      cmap_experiments <- utils::read.csv(self$cmap_meta_path,  stringsAsFactors = FALSE)
      valid_instances  <- utils::read.csv(self$cmap_valid_path, stringsAsFactors = FALSE)
      cmap_experiments_valid <- merge(cmap_experiments, valid_instances, by = "id")
      cmap_experiments_valid <- subset(cmap_experiments_valid, valid == 1 & DrugBank.ID != "NULL")

      dv <- merge(self$drugs, cmap_experiments_valid, by.x = "exp_id", by.y = "id", all.x = TRUE)
      if (self$reversal_only) dv <- subset(dv, cmap_score < 0)
      dv <- subset(dv, q < self$q_thresh)

      if ("name" %in% names(dv)) {
        dv <- dv |>
          dplyr::group_by(name) |>
          dplyr::slice(which.min(cmap_score)) |>
          dplyr::ungroup()
      }
      self$drugs_valid <- dv
      invisible(self)
    },

    quick_report = function(top_n = 25) {
      # Use your existing analysis functions; save files to out_dir when possible
      io_ensure_dir(self$out_dir)
      try(pl_hist_revsc(list(self$drugs), save = file.path(self$out_dir, "hist_revsc.jpg")), silent = TRUE)
      try(pl_cmap_score(self$drugs_valid, save = file.path(self$out_dir, "cmap_score.jpg")), silent = TRUE)
      invisible(self)
    },

    save_outputs = function() {
      io_ensure_dir(self$out_dir)
      self$log("Saving artifacts -> %s", self$out_dir)

      results <- list(drugs = self$drugs, signature_clean = self$dz_signature)
      save(results, file = file.path(self$out_dir, sprintf("%s_results.RData", self$dataset_label)))

      # Save random scores if available
      if (!is.null(self$rand_scores)) {
        rand_scores <- self$rand_scores  # Create local copy to avoid scoping issues
        save(rand_scores, file = file.path(self$out_dir, sprintf("%s_random_scores_logFC_%s.RData",
                                                                  self$dataset_label, self$logfc_cutoff)))
      }
      
      if (!is.null(self$drugs_valid)) {
        utils::write.csv(self$drugs_valid,
          file = file.path(self$out_dir, sprintf("%s_hits_q<%.2f.csv", self$dataset_label, self$q_thresh)),
          row.names = FALSE
        )
      }
      invisible(self)
    },

    # --------- new methods for sweep mode ---------
    run_single = function() {
      self$log("Running single-cutoff mode")
      
      if (self$combine_log2fc == "average") {
        # Score once using the single entry in signature list
        sig_entry <- self$dz_signature_list[["average"]]
        
        set.seed(self$seed)
        self$rand_scores <- random_score(self$cmap_signatures, 
                                         length(sig_entry$up_ids), 
                                         length(sig_entry$down_ids))
        self$obs_scores <- query_score(self$cmap_signatures, 
                                       sig_entry$up_ids, 
                                       sig_entry$down_ids)
        self$drugs <- query(
          self$rand_scores,
          self$obs_scores,
          subset_comparison_id = sprintf("%s_logFC_%s", self$dataset_label, self$logfc_cutoff)
        )
        
      } else if (self$combine_log2fc == "each") {
        # Loop over entries, run score per entry, collect results, then aggregate
        all_results <- list()
        
        for (sig_name in names(self$dz_signature_list)) {
          sig_entry <- self$dz_signature_list[[sig_name]]
          
          set.seed(self$seed)
          rand_scores <- random_score(self$cmap_signatures, 
                                      length(sig_entry$up_ids), 
                                      length(sig_entry$down_ids))
          obs_scores <- query_score(self$cmap_signatures, 
                                    sig_entry$up_ids, 
                                    sig_entry$down_ids)
          drugs <- query(
            rand_scores,
            obs_scores,
            subset_comparison_id = sprintf("%s_%s_logFC_%s", self$dataset_label, sig_name, self$logfc_cutoff)
          )
          
          all_results[[sig_name]] <- drugs
        }
        
        # Aggregate results by drug
        self$drugs <- private$aggregate_drug_results(all_results)
        
        # Store first result for backward compatibility
        self$rand_scores <- random_score(self$cmap_signatures, 
                                         length(self$dz_signature_list[[1]]$up_ids), 
                                         length(self$dz_signature_list[[1]]$down_ids))
        self$obs_scores <- query_score(self$cmap_signatures, 
                                       self$dz_signature_list[[1]]$up_ids, 
                                       self$dz_signature_list[[1]]$down_ids)
      }
      
      invisible(self)
    },

    # --------- runners ---------
    run_processing = function() {
      self$load_cmap()$load_disease()$clean_signature()$score()$save_outputs()
      invisible(self)
    },

    run_analysis = function(make_plots = TRUE) {
      self$annotate_and_filter()
      if (isTRUE(make_plots)) self$quick_report()
      self$save_outputs()
      invisible(self)
    },

    run_all = function(make_plots = TRUE) {
      # Load data and prepare signatures
      self$load_cmap()$load_disease()$clean_signature()
      
      # Run based on mode
      if (self$mode == "single") {
        self$run_single()
      } else if (self$mode == "sweep") {
        self$run_sweep()
        # For sweep mode, we're done after run_sweep (it handles annotation/filtering/saving)
        if (!is.null(self$robust_hits) && nrow(self$robust_hits) > 0) {
          print(utils::head(self$robust_hits, 10))
        }
        return(invisible(self))
      }
      
      # Continue with single mode processing
      self$annotate_and_filter()
      if (isTRUE(make_plots)) self$quick_report()
      self$save_outputs()
      if (!is.null(self$drugs_valid)) print(utils::head(self$drugs_valid, 10)) else print(utils::head(self$drugs, 10))
      invisible(self)
    },

    run_sweep = function() {
      self$log("Running sweep mode")
      
      if (is.null(self$sweep_cutoffs)) {
        stop("sweep_cutoffs must be provided for sweep mode")
      }
      
      # Store original cutoff and get pre-filtered gene count
      original_cutoff <- self$logfc_cutoff
      n_prefiltered <- nrow(self$dz_signature_raw)
      
      # Initialize sweep results
      self$sweep_hits <- list()
      self$cutoff_summary <- data.frame(
        cutoff = numeric(0),
        n_genes_kept = integer(0),
        n_hits = integer(0),
        median_q = numeric(0)
      )
      
      for (cutoff in self$sweep_cutoffs) {
        self$log("Processing cutoff: %s", cutoff)
        
        # Temporarily set cutoff and rebuild signature list
        self$logfc_cutoff <- cutoff
        self$clean_signature(cutoff = cutoff)
        
        # Check gene count thresholds
        n_genes <- if (self$combine_log2fc == "average") {
          length(self$dz_signature_list[["average"]]$up_ids) + 
          length(self$dz_signature_list[["average"]]$down_ids)
        } else {
          # For "each", use the first signature as representative
          first_sig <- self$dz_signature_list[[1]]
          length(first_sig$up_ids) + length(first_sig$down_ids)
        }
        
        min_genes_threshold <- max(self$sweep_min_genes, 
                                   self$sweep_min_frac * n_prefiltered)
        
        if (n_genes < min_genes_threshold) {
          self$log("Skipping cutoff %s: only %d genes (< %d threshold)", 
                   cutoff, n_genes, min_genes_threshold)
          next
        }
        
        # Run scoring for this cutoff
        self$run_single()
        self$annotate_and_filter()
        
        # Save per-cutoff results
        cutoff_dir <- file.path(self$out_dir, sprintf("cutoff_%s", cutoff))
        io_ensure_dir(cutoff_dir)
        
        # Save cutoff-specific outputs
        if (!is.null(self$drugs_valid)) {
          cutoff_hits <- self$drugs_valid
          cutoff_hits$cutoff <- cutoff
          
          utils::write.csv(cutoff_hits,
            file = file.path(cutoff_dir, sprintf("%s_hits_cutoff_%s.csv", 
                                                 self$dataset_label, cutoff)),
            row.names = FALSE
          )
          
          # Store in sweep results
          self$sweep_hits[[as.character(cutoff)]] <- cutoff_hits
          
          # Update summary
          summary_row <- data.frame(
            cutoff = cutoff,
            n_genes_kept = n_genes,
            n_hits = nrow(cutoff_hits),
            median_q = median(cutoff_hits$q, na.rm = TRUE)
          )
          self$cutoff_summary <- rbind(self$cutoff_summary, summary_row)
        }
      }
      
      # Restore original cutoff
      self$logfc_cutoff <- original_cutoff
      
      # Aggregate across cutoffs
      if (length(self$sweep_hits) > 0) {
        self$aggregate_thresholds()
      }
      
      invisible(self)
    },

    aggregate_thresholds = function() {
      self$log("Aggregating results across cutoffs")
      
      if (length(self$sweep_hits) == 0) {
        self$log("No sweep hits to aggregate")
        return(invisible(self))
      }
      
      # Build long table from sweep_hits
      long_table <- do.call(rbind, lapply(names(self$sweep_hits), function(cutoff) {
        hits <- self$sweep_hits[[cutoff]]
        if (nrow(hits) > 0) {
          data.frame(
            name = hits$name,
            cutoff = as.numeric(cutoff),
            cmap_score = hits$cmap_score,
            q = hits$q,
            stringsAsFactors = FALSE
          )
        } else {
          data.frame(name = character(0), cutoff = numeric(0), 
                     cmap_score = numeric(0), q = numeric(0))
        }
      }))
      
      if (nrow(long_table) == 0) {
        self$log("No hits found across any cutoffs")
        return(invisible(self))
      }
      
      # Compute presence per drug across cutoffs
      drug_presence <- long_table |>
        dplyr::group_by(name) |>
        dplyr::summarise(
          n_cutoffs = dplyr::n(),
          cutoffs = list(cutoff),
          .groups = "drop"
        )
      
      n_cutoffs_total <- length(self$sweep_cutoffs)
      
      # Apply robust rule
      if (self$robust_rule == "all") {
        keep_drugs <- drug_presence$name[drug_presence$n_cutoffs == n_cutoffs_total]
      } else if (self$robust_rule == "k_of_n") {
        k_threshold <- if (is.null(self$robust_k)) {
          ceiling(0.7 * n_cutoffs_total)
        } else {
          self$robust_k
        }
        keep_drugs <- drug_presence$name[drug_presence$n_cutoffs >= k_threshold]
      }
      
      if (length(keep_drugs) == 0) {
        self$log("No drugs passed robust filtering")
        self$robust_hits <- data.frame()
        return(invisible(self))
      }
      
      # Filter and aggregate
      filtered_table <- long_table[long_table$name %in% keep_drugs, ]
      
      # Aggregate scores per drug
      self$robust_hits <- filtered_table |>
        dplyr::group_by(name) |>
        dplyr::summarise(
          aggregated_score = switch(self$aggregate,
            "mean" = mean(cmap_score, na.rm = TRUE),
            "median" = median(cmap_score, na.rm = TRUE),
            "weighted_mean" = {
              if (is.null(self$weights)) {
                mean(cmap_score, na.rm = TRUE)
              } else {
                # Use weights based on cutoff
                w <- sapply(cutoff, function(c) self$weights[as.character(c)] %||% 1)
                weighted.mean(cmap_score, w, na.rm = TRUE)
              }
            }
          ),
          min_q = min(q, na.rm = TRUE),
          n_support = dplyr::n(),
          .groups = "drop"
        ) |>
        dplyr::arrange(aggregated_score)
      
      # Save aggregated results
      agg_dir <- file.path(self$out_dir, "aggregate")
      io_ensure_dir(agg_dir)
      
      utils::write.csv(self$robust_hits,
        file = file.path(agg_dir, "robust_hits.csv"),
        row.names = FALSE
      )
      
      utils::write.csv(self$cutoff_summary,
        file = file.path(agg_dir, "cutoff_summary.csv"),
        row.names = FALSE
      )
      
      self$log("Aggregated %d robust hits from %d cutoffs", 
               nrow(self$robust_hits), n_cutoffs_total)
      
      invisible(self)
    }
  ),
  
  private = list(
    aggregate_drug_results = function(all_results) {
      # Combine results from multiple logFC columns
      if (length(all_results) == 0) return(data.frame())
      
      # Get all unique drugs across results
      all_drugs <- unique(unlist(lapply(all_results, function(x) x$exp_id)))
      
      # Initialize combined results
      combined <- data.frame()
      
      for (drug_id in all_drugs) {
        # Get results for this drug across all signatures
        drug_results <- lapply(all_results, function(res) {
          res[res$exp_id == drug_id, ]
        })
        
        # Remove empty results
        drug_results <- drug_results[sapply(drug_results, nrow) > 0]
        
        if (length(drug_results) > 0) {
          # Aggregate scores
          scores <- sapply(drug_results, function(x) x$cmap_score[1])
          qs <- sapply(drug_results, function(x) x$q[1])
          
          aggregated_score <- switch(self$aggregate,
            "mean" = mean(scores, na.rm = TRUE),
            "median" = median(scores, na.rm = TRUE),
            "weighted_mean" = {
              if (is.null(self$weights)) {
                mean(scores, na.rm = TRUE)
              } else {
                # Use equal weights if specific weights not provided
                weighted.mean(scores, rep(1, length(scores)), na.rm = TRUE)
              }
            }
          )
          
          min_q <- min(qs, na.rm = TRUE)
          
          # Use first result as template and update scores
          result_row <- drug_results[[1]][1, ]
          result_row$cmap_score <- aggregated_score
          result_row$q <- min_q
          
          combined <- rbind(combined, result_row)
        }
      }
      
      return(combined)
    }
  )
)

#' Run the drug repurposing pipeline in one call
#'
#' @param signatures_rdata Path to RData containing `cmap_signatures`
#' @param disease_path     CSV path OR directory containing the disease file
#' @param disease_pattern  Pattern to locate CSV inside a directory
#' @param cmap_meta_path   Path to CMAP experiment metadata CSV (optional)
#' @param cmap_valid_path  Path to CMAP valid instances CSV (optional)
#' @param out_dir          Output directory
#' @param gene_key         Column name for gene identifiers (default: "SYMBOL")
#' @param logfc_cols_pref  Prefix for log fold change columns (default: "log2FC")
#' @param logfc_cutoff     Log fold change cutoff threshold (default: 1)
#' @param q_thresh         Q-value threshold for significance (default: 0.05)
#' @param reversal_only    Whether to consider only reversal scores (default: TRUE)
#' @param seed             Random seed for reproducibility (default: 123)
#' @param verbose          Whether to print progress messages (default: TRUE)
#' @param make_plots       Whether to generate plots (default: TRUE)
#' @return Invisibly, the DRP object
#' @export
run_dr <- function(
  signatures_rdata,
  disease_path,
  disease_pattern = NULL,
  cmap_meta_path = NULL,
  cmap_valid_path = NULL,
  out_dir = "scripts/results",
  gene_key = "SYMBOL",
  logfc_cols_pref = "log2FC",
  logfc_cutoff = 1,
  q_thresh = 0.05,
  reversal_only = TRUE,
  seed = 123,
  verbose = TRUE,
  make_plots = TRUE
) {
  DRP$new(
    signatures_rdata = signatures_rdata,
    disease_path     = disease_path,
    disease_pattern  = disease_pattern,
    cmap_meta_path   = cmap_meta_path,
    cmap_valid_path  = cmap_valid_path,
    out_dir          = out_dir,
    gene_key         = gene_key,
    logfc_cols_pref  = logfc_cols_pref,
    logfc_cutoff     = logfc_cutoff,
    q_thresh         = q_thresh,
    reversal_only    = reversal_only,
    seed             = seed,
    verbose          = verbose
  )$run_all(make_plots = make_plots)
}

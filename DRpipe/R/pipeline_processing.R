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
    pval_key         = NULL,
    pval_cutoff      = 0.05,
    q_thresh         = 0.05,
    reversal_only    = TRUE,
    seed             = 123,
    verbose          = TRUE,
    
    # --------- new sweep mode configuration ---------
    mode             = "single",
    sweep_cutoffs    = NULL,
    sweep_auto_grid  = TRUE,        # auto-derive thresholds from data
    sweep_step       = 0.1,         # step size for auto-derived grid  
    sweep_min_frac   = 0.20,
    sweep_min_genes  = 200,
    sweep_stop_on_small = FALSE,    # if TRUE, stop sweep when signature too small; if FALSE, skip and continue
    combine_log2fc   = "average",
    robust_rule      = "all",
    robust_k         = NULL,
    aggregate        = "mean",
    weights          = NULL,
    
    # --------- meta-analysis filters configuration ---------
    apply_meta_filters = FALSE,     # enable hardwired meta-analysis filters
    min_studies        = 2,         # numStudies >= 2
    effect_fdr_thresh  = 0.05,      # effectSizeFDR < 0.05
    heterogeneity_thresh = 0.05,    # heterogeneityPval > 0.05
    
    # --------- gene mapping configuration ---------
    gene_conversion_table = NULL,   # path to gene_id_conversion_table.tsv
    save_count_files     = FALSE,   # save per-threshold count files
    
    # --------- permutation configuration ---------
    n_permutations    = 100000,     # fixed 100k permutations
    save_null_scores  = FALSE,      # save cmap_random_scores_*.RData files
    
    # --------- output configuration ---------
    per_threshold_dirs = FALSE,     # create threshold_X.X/ directories
    blood_label        = "blood",   # label for file naming
    
    # --------- parallel processing configuration ---------
    ncores             = NULL,      # number of CPU cores for parallel processing

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
      pval_key        = NULL,
      pval_cutoff     = 0.05,
      q_thresh        = 0.05,
      reversal_only   = TRUE,
      seed            = 123,
      verbose         = TRUE,
      mode            = c("single", "sweep"),
      sweep_cutoffs   = NULL,
      sweep_auto_grid = TRUE,
      sweep_step      = 0.1,
      sweep_min_frac  = 0.20,
      sweep_min_genes = 200,
      sweep_stop_on_small = FALSE,
      combine_log2fc  = c("average", "each"),
      robust_rule     = c("all", "k_of_n"),
      robust_k        = NULL,
      aggregate       = c("mean", "median", "weighted_mean"),
      weights         = NULL,
      apply_meta_filters = FALSE,
      min_studies        = 2,
      effect_fdr_thresh  = 0.05,
      heterogeneity_thresh = 0.05,
      gene_conversion_table = NULL,
      save_count_files     = FALSE,
      n_permutations       = 100000,
      save_null_scores     = FALSE,
      per_threshold_dirs   = FALSE,
      blood_label          = "blood",
      ncores               = NULL
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
      self$pval_key         <- pval_key
      self$pval_cutoff      <- pval_cutoff
      self$q_thresh         <- q_thresh
      self$reversal_only    <- reversal_only
      self$seed             <- seed
      self$verbose          <- verbose
      
      # New parameters with validation
      self$mode            <- match.arg(mode)
      self$sweep_cutoffs   <- sweep_cutoffs
      self$sweep_auto_grid <- sweep_auto_grid
      self$sweep_step      <- sweep_step
      self$sweep_min_frac  <- sweep_min_frac
      self$sweep_min_genes <- sweep_min_genes
      self$sweep_stop_on_small <- sweep_stop_on_small
      self$combine_log2fc  <- match.arg(combine_log2fc)
      self$robust_rule     <- match.arg(robust_rule)
      self$robust_k        <- robust_k
      self$aggregate       <- match.arg(aggregate)
      self$weights         <- weights
      
      # Meta-analysis filter parameters
      self$apply_meta_filters  <- apply_meta_filters
      self$min_studies         <- min_studies
      self$effect_fdr_thresh   <- effect_fdr_thresh
      self$heterogeneity_thresh <- heterogeneity_thresh
      
      # Gene mapping parameters
      self$gene_conversion_table <- if (!is.null(gene_conversion_table)) io_resolve_path(gene_conversion_table) else NULL
      self$save_count_files     <- save_count_files
      
      # Permutation parameters  
      self$n_permutations    <- n_permutations
      self$save_null_scores  <- save_null_scores
      
      # Output parameters
      self$per_threshold_dirs <- per_threshold_dirs
      self$blood_label        <- blood_label
      
      # Parallel processing parameters
      self$ncores             <- ncores
      
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
      
      # Apply meta-analysis filters if enabled
      if (self$apply_meta_filters) {
        self$log("Applying meta-analysis filters...")
        n_before <- nrow(self$dz_signature_raw)
        
        # Check for required columns
        if ("numStudies" %in% names(self$dz_signature_raw)) {
          self$dz_signature_raw <- self$dz_signature_raw[self$dz_signature_raw$numStudies >= self$min_studies, ]
        }
        if ("effectSizeFDR" %in% names(self$dz_signature_raw)) {
          self$dz_signature_raw <- self$dz_signature_raw[self$dz_signature_raw$effectSizeFDR < self$effect_fdr_thresh, ]
        }
        if ("heterogeneityPval" %in% names(self$dz_signature_raw)) {
          self$dz_signature_raw <- self$dz_signature_raw[self$dz_signature_raw$heterogeneityPval > self$heterogeneity_thresh, ]
        }
        
        n_after <- nrow(self$dz_signature_raw)
        self$log("Meta-analysis filters: %d -> %d genes (removed %d)", n_before, n_after, n_before - n_after)
      }
      
      invisible(self)
    },

    # --------- new helper for auto-deriving thresholds ---------
    derive_threshold_grid = function() {
      if (!self$sweep_auto_grid) return(self$sweep_cutoffs)
      
      self$log("Auto-deriving threshold grid from effect size distribution...")
      
      # Detect effect size column (should be "effectSize" for meta-analysis or log2FC columns)
      effect_col <- NULL
      if ("effectSize" %in% names(self$dz_signature_raw)) {
        effect_col <- "effectSize"
      } else {
        # Use first log2FC column as proxy
        lc_cols <- grep(paste0("^", self$logfc_cols_pref), names(self$dz_signature_raw), value = TRUE)
        if (length(lc_cols) > 0) {
          effect_col <- lc_cols[1]
        }
      }
      
      if (is.null(effect_col)) {
        stop("Cannot auto-derive thresholds: no 'effectSize' or '", self$logfc_cols_pref, "' columns found")
      }
      
      effect_sizes <- self$dz_signature_raw[[effect_col]]
      effect_sizes <- effect_sizes[!is.na(effect_sizes)]
      
      if (length(effect_sizes) == 0) {
        stop("No valid effect sizes found for threshold derivation")
      }
      
      # Original script logic: absolute_min = min(abs(max positive), abs(max negative))
      max_pos <- max(effect_sizes[effect_sizes > 0], na.rm = TRUE)
      max_neg <- min(effect_sizes[effect_sizes < 0], na.rm = TRUE)  # most negative
      
      if (is.infinite(max_pos)) max_pos <- 0
      if (is.infinite(max_neg)) max_neg <- 0
      
      absolute_min <- min(abs(max_pos), abs(max_neg))
      
      # Generate sequence from 0 to absolute_min in steps
      thresholds <- seq(0, absolute_min, by = self$sweep_step)
      
      self$log("Derived threshold grid: %s (from effect size range: %.3f to %.3f)", 
               paste(round(thresholds, 2), collapse = ", "), 
               max_neg, max_pos)
      
      return(thresholds)
    },

    clean_signature = function(cutoff = NULL) {
      # Use provided cutoff or default to instance cutoff
      use_cutoff <- if (!is.null(cutoff)) cutoff else self$logfc_cutoff
      
      # Start with pre-filtered raw data
      working_data <- self$dz_signature_raw
      
      # Detect all log2FC columns
      lc_cols <- grep(paste0("^", self$logfc_cols_pref), names(working_data), value = TRUE)
      if (!length(lc_cols)) stop("No columns starting with '", self$logfc_cols_pref, "' found.")
      
      # Get gene universe from cmap (needs to be character for comparison)
      db_genes <- NULL
      if (is.data.frame(self$cmap_signatures)) {
        if ("V1" %in% names(self$cmap_signatures)) db_genes <- as.character(self$cmap_signatures$V1)
        if (is.null(db_genes) && "gene" %in% names(self$cmap_signatures)) db_genes <- as.character(self$cmap_signatures$gene)
      }
      if (is.null(db_genes)) db_genes <- as.character(unique(unlist(self$cmap_signatures)))
      
      # Initialize signature list
      self$dz_signature_list <- list()
      
      if (self$combine_log2fc == "average") {
        # Average approach: compute mean logFC across all columns
        working_data$logFC <- rowMeans(working_data[, lc_cols, drop = FALSE], na.rm = TRUE)
        
        # Custom gene mapping and filtering (bypass clean_table's gprofiler2 mapping)
        if (!is.null(self$gene_conversion_table) && file.exists(self$gene_conversion_table)) {
          self$log("Applying Symbol→Entrez mapping from: %s", self$gene_conversion_table)
          
          # Load gene conversion table
          mapping_tbl <- utils::read.csv(self$gene_conversion_table, sep = '\t', stringsAsFactors = FALSE)
          mapping_tbl <- mapping_tbl[!is.na(mapping_tbl$entrezID), c("Gene_name", "entrezID")]
          mapping_tbl <- mapping_tbl[!duplicated(mapping_tbl), ]
          
          # Merge with disease signature
          original_count <- nrow(working_data)
          working_data <- merge(working_data, mapping_tbl, by.x = self$gene_key, by.y = "Gene_name")
          mapped_count <- nrow(working_data)
          
          self$log("Gene mapping: %d -> %d genes (mapped %d)", original_count, mapped_count, mapped_count)
          
          # Manual filtering steps (like clean_table but with our mapped data)
          # 1. Filter by p-value if pval_key is provided
          if (!is.null(self$pval_key) && self$pval_key %in% names(working_data)) {
            working_data <- working_data[working_data[[self$pval_key]] < self$pval_cutoff, ]
          }
          
          # 2. Filter by logFC cutoff
          working_data <- working_data[abs(working_data$logFC) > use_cutoff, ]
          
          # 3. Filter to CMap universe
          working_data <- working_data[as.character(working_data$entrezID) %in% db_genes, ]
          
          # 3. Create final cleaned signature
          cleaned <- data.frame(
            GeneID = working_data$entrezID,
            logFC = working_data$logFC,
            stringsAsFactors = FALSE
          )
        } else {
          # Use clean_table for standard gene symbol mapping via gprofiler2
          cleaned <- clean_table(
            working_data,
            gene_key     = self$gene_key,
            logFC_key    = "logFC",
            logFC_cutoff = use_cutoff,
            pval_key     = self$pval_key,
            pval_cutoff  = self$pval_cutoff,
            db_gene_list = db_genes
          )
        }
        
        # Store cleaned signature and gene lists
        self$dz_signature_list[["average"]] <- list(
          signature = cleaned,
          up_ids = cleaned$GeneID[cleaned$logFC > 0],
          down_ids = cleaned$GeneID[cleaned$logFC < 0]
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
          working_data$logFC <- working_data[[col]]
          
          # Custom gene mapping and filtering if conversion table provided
          if (!is.null(self$gene_conversion_table) && file.exists(self$gene_conversion_table)) {
            # Load gene conversion table
            mapping_tbl <- utils::read.csv(self$gene_conversion_table, sep = '\t', stringsAsFactors = FALSE)
            mapping_tbl <- mapping_tbl[!is.na(mapping_tbl$entrezID), c("Gene_name", "entrezID")]
            mapping_tbl <- mapping_tbl[!duplicated(mapping_tbl), ]
            
            # Merge with disease signature
            temp_data <- merge(working_data, mapping_tbl, by.x = self$gene_key, by.y = "Gene_name")
            
            # Manual filtering
            # 1. Filter by p-value if pval_key is provided
            if (!is.null(self$pval_key) && self$pval_key %in% names(temp_data)) {
              temp_data <- temp_data[temp_data[[self$pval_key]] < self$pval_cutoff, ]
            }
            
            # 2. Filter by logFC cutoff
            temp_data <- temp_data[abs(temp_data$logFC) > use_cutoff, ]
            
            # 3. Filter to CMap universe
            temp_data <- temp_data[as.character(temp_data$entrezID) %in% db_genes, ]
            
            # Create cleaned signature
            cleaned <- data.frame(
              GeneID = temp_data$entrezID,
              logFC = temp_data$logFC,
              stringsAsFactors = FALSE
            )
          } else {
            # Use clean_table with proper p-value filtering
            cleaned <- clean_table(
              working_data,
              gene_key     = self$gene_key,
              logFC_key    = "logFC",
              logFC_cutoff = use_cutoff,
              pval_key     = self$pval_key,
              pval_cutoff  = self$pval_cutoff,
              db_gene_list = db_genes
            )
          }
          
          # Store cleaned signature and gene lists
          self$dz_signature_list[[col]] <- list(
            signature = cleaned,
            up_ids = cleaned$GeneID[cleaned$logFC > 0],
            down_ids = cleaned$GeneID[cleaned$logFC < 0]
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
      img_dir <- file.path(self$out_dir, "img")
      io_ensure_dir(img_dir)
      
      self$log("Generating plots...")
      
      # Plot histogram of reversal scores
      tryCatch({
        pl_hist_revsc(list(self$drugs), 
                      save = "imgdist_rev_score.jpeg", 
                      path = img_dir)
        self$log("Generated histogram of reversal scores")
      }, error = function(e) {
        self$log("Warning: Could not generate histogram - %s", e$message)
      })
      
      # Plot CMap scores if we have valid drugs
      if (!is.null(self$drugs_valid) && nrow(self$drugs_valid) > 0) {
        tryCatch({
          pl_cmap_score(self$drugs_valid, 
                        save = file.path(img_dir, "cmap_score.jpg"))
          self$log("Generated CMap score plot")
        }, error = function(e) {
          self$log("Warning: Could not generate CMap score plot - %s", e$message)
        })
      } else {
        self$log("No valid drugs found for CMap score plot")
      }
      
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
        # Generate plots for sweep mode if requested
        if (isTRUE(make_plots)) {
          self$log("make_plots is TRUE, ensuring sweep plots are generated...")
          self$create_sweep_plots()
        }
        # For sweep mode, we're done after run_sweep (it handles annotation/filtering/saving)
        if (!is.null(self$robust_hits) && nrow(self$robust_hits) > 0) {
          print(utils::head(self$robust_hits, 10))
        }
        return(invisible(self))
      }
      
      # Continue with single mode processing
      self$annotate_and_filter()
      if (isTRUE(make_plots)) {
        self$log("make_plots is TRUE, calling quick_report...")
        self$quick_report()
      } else {
        self$log("make_plots is FALSE, skipping plots")
      }
      self$save_outputs()
      if (!is.null(self$drugs_valid)) print(utils::head(self$drugs_valid, 10)) else print(utils::head(self$drugs, 10))
      invisible(self)
    },

    run_sweep = function() {
      self$log("Running sweep mode with parallel processing")
      
      # Auto-derive cutoffs if needed
      cutoffs_to_use <- if (is.null(self$sweep_cutoffs) && self$sweep_auto_grid) {
        self$derive_threshold_grid()
      } else if (!is.null(self$sweep_cutoffs)) {
        self$sweep_cutoffs
      } else {
        stop("Either sweep_cutoffs must be provided or sweep_auto_grid must be TRUE")
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
      
      # Determine number of cores to use
      ncores <- if (!is.null(self$ncores)) {
        self$ncores
      } else if (exists("ncores", envir = .GlobalEnv)) {
        get("ncores", envir = .GlobalEnv)
      } else {
        min(20, parallel::detectCores() - 1, length(cutoffs_to_use))
      }
      
      self$log("Using %d cores for parallel threshold processing", ncores)
      
      # Process thresholds in parallel
      cutoff_results <- parallel::mclapply(cutoffs_to_use, function(cutoff) {
        tryCatch({
          # Create a temporary copy of necessary objects for this worker
          temp_raw <- self$dz_signature_raw
          temp_cmap <- self$cmap_signatures
          temp_meta_path <- self$cmap_meta_path
          temp_valid_path <- self$cmap_valid_path
          temp_gene_conversion_table <- self$gene_conversion_table
          
          # Rebuild signature list for this cutoff
          working_data <- temp_raw
          
          # Detect all log2FC columns
          lc_cols <- grep(paste0("^", self$logfc_cols_pref), names(working_data), value = TRUE)
          if (!length(lc_cols)) stop("No columns starting with '", self$logfc_cols_pref, "' found.")
          
          # Get gene universe from cmap
          db_genes <- NULL
          if (is.data.frame(temp_cmap)) {
            if ("V1" %in% names(temp_cmap)) db_genes <- as.character(temp_cmap$V1)
            if (is.null(db_genes) && "gene" %in% names(temp_cmap)) db_genes <- as.character(temp_cmap$gene)
          }
          if (is.null(db_genes)) db_genes <- as.character(unique(unlist(temp_cmap)))
          
          # Process signature based on combine_log2fc mode
          if (self$combine_log2fc == "average") {
            working_data$logFC <- rowMeans(working_data[, lc_cols, drop = FALSE], na.rm = TRUE)
            
            # Apply gene mapping and filtering
            if (!is.null(temp_gene_conversion_table) && file.exists(temp_gene_conversion_table)) {
              mapping_tbl <- utils::read.csv(temp_gene_conversion_table, sep = '\t', stringsAsFactors = FALSE)
              mapping_tbl <- mapping_tbl[!is.na(mapping_tbl$entrezID), c("Gene_name", "entrezID")]
              mapping_tbl <- mapping_tbl[!duplicated(mapping_tbl), ]
              
              working_data <- merge(working_data, mapping_tbl, by.x = self$gene_key, by.y = "Gene_name")
              
              # Filter by p-value if pval_key is provided
              if (!is.null(self$pval_key) && self$pval_key %in% names(working_data)) {
                working_data <- working_data[working_data[[self$pval_key]] < self$pval_cutoff, ]
              }
              
              working_data <- working_data[abs(working_data$logFC) > cutoff, ]
              working_data <- working_data[as.character(working_data$entrezID) %in% db_genes, ]
              
              cleaned <- data.frame(
                GeneID = working_data$entrezID,
                logFC = working_data$logFC,
                stringsAsFactors = FALSE
              )
            } else {
              cleaned <- clean_table(
                working_data,
                gene_key     = self$gene_key,
                logFC_key    = "logFC",
                logFC_cutoff = cutoff,
                pval_key     = self$pval_key,
                pval_cutoff  = self$pval_cutoff,
                db_gene_list = db_genes
              )
            }
            
            up_ids <- cleaned$GeneID[cleaned$logFC > 0]
            down_ids <- cleaned$GeneID[cleaned$logFC < 0]
          }
          
          # Check gene count thresholds
          n_genes <- length(up_ids) + length(down_ids)
          min_genes_threshold <- max(self$sweep_min_genes, self$sweep_min_frac * n_prefiltered)
          
          if (n_genes < min_genes_threshold) {
            return(list(
              cutoff = cutoff,
              status = "skipped",
              reason = sprintf("Signature too small (%.0f < %.0f)", n_genes, min_genes_threshold),
              n_genes = n_genes
            ))
          }
          
          # Set per-cutoff seed for reproducibility
          cutoff_seed <- self$seed + round(cutoff * 1000)
          set.seed(cutoff_seed)
          
          # Run scoring for this cutoff
          rand_scores <- random_score(temp_cmap, 
                                    length(up_ids), 
                                    length(down_ids),
                                    N_PERMUTATIONS = self$n_permutations)
          obs_scores <- query_score(temp_cmap, up_ids, down_ids)
          drugs <- query(
            rand_scores,
            obs_scores,
            subset_comparison_id = sprintf("%s_logFC_%s", self$dataset_label, cutoff)
          )
          
          # Annotate and filter
          drugs_valid <- drugs
          if (!is.null(temp_meta_path) && !is.null(temp_valid_path) && 
              file.exists(temp_meta_path) && file.exists(temp_valid_path)) {
            
            cmap_experiments <- utils::read.csv(temp_meta_path, stringsAsFactors = FALSE)
            valid_instances <- utils::read.csv(temp_valid_path, stringsAsFactors = FALSE)
            cmap_experiments_valid <- merge(cmap_experiments, valid_instances, by = "id")
            cmap_experiments_valid <- subset(cmap_experiments_valid, valid == 1 & DrugBank.ID != "NULL")
            
            drugs_valid <- merge(drugs, cmap_experiments_valid, by.x = "exp_id", by.y = "id", all.x = TRUE)
            if (self$reversal_only) drugs_valid <- subset(drugs_valid, cmap_score < 0)
            drugs_valid <- subset(drugs_valid, q < self$q_thresh)
            
            if ("name" %in% names(drugs_valid) && nrow(drugs_valid) > 0) {
              drugs_valid <- drugs_valid |>
                dplyr::group_by(name) |>
                dplyr::slice(which.min(cmap_score)) |>
                dplyr::ungroup()
            }
          }
          
          # Return results for this cutoff
          return(list(
            cutoff = cutoff,
            status = "success",
            n_genes = n_genes,
            drugs_valid = drugs_valid,
            signature = cleaned,
            rand_scores = if (self$save_null_scores) rand_scores else NULL,
            up_ids = up_ids,
            down_ids = down_ids
          ))
          
        }, error = function(e) {
          return(list(
            cutoff = cutoff,
            status = "error",
            error = as.character(e),
            n_genes = 0
          ))
        })
      }, mc.cores = ncores)
      
      # Process results from parallel execution
      for (result in cutoff_results) {
        cutoff <- result$cutoff
        
        if (result$status == "skipped") {
          self$log("Cutoff %s: %s", cutoff, result$reason)
          # Check if we should stop or continue based on user preference
          if (self$sweep_stop_on_small && grepl("too small", result$reason)) {
            self$log("Stopping sweep due to insufficient genes (sweep_stop_on_small = TRUE)")
            break
          }
          next  # Skip this cutoff but continue with remaining ones
        }
        
        if (result$status == "error") {
          self$log("Cutoff %s failed: %s", cutoff, result$error)
          next
        }
        
        self$log("Cutoff %s: %d genes, %d hits", cutoff, result$n_genes, nrow(result$drugs_valid))
        
        # Create output directory
        if (self$per_threshold_dirs) {
          cutoff_dir <- file.path(self$out_dir, sprintf("threshold_%s", cutoff))
          io_ensure_dir(cutoff_dir)
        } else {
          cutoff_dir <- file.path(self$out_dir, sprintf("cutoff_%s", cutoff))
          io_ensure_dir(cutoff_dir)
        }
        
        # Save per-threshold count files if requested
        if (self$save_count_files) {
          blood_suffix <- if (!is.null(self$blood_label)) paste0("_", self$blood_label) else ""
          
          utils::write.table(result$n_genes,
            file = file.path(cutoff_dir, sprintf("n_signature_genes_from_metanalysis_%s%s_threshold_%s.txt",
                                                 self$dataset_label, blood_suffix, cutoff)),
            quote = FALSE, col.names = FALSE, row.names = FALSE
          )
          
          utils::write.table(result$n_genes,
            file = file.path(cutoff_dir, sprintf("n_signature_genes_geneid_%s%s_threshold_%s.txt",
                                                 self$dataset_label, blood_suffix, cutoff)),
            quote = FALSE, col.names = FALSE, row.names = FALSE
          )
          
          utils::write.table(length(result$up_ids),
            file = file.path(cutoff_dir, sprintf("upreg_genes_%s%s_threshold_%s.txt",
                                                 self$dataset_label, blood_suffix, cutoff)),
            quote = FALSE, col.names = FALSE, row.names = FALSE
          )
          
          utils::write.table(length(result$down_ids),
            file = file.path(cutoff_dir, sprintf("downreg_genes_%s%s_threshold_%s.txt",
                                                 self$dataset_label, blood_suffix, cutoff)),
            quote = FALSE, col.names = FALSE, row.names = FALSE
          )
        }
        
        # Save null scores if requested
        if (self$save_null_scores && !is.null(result$rand_scores)) {
          rand_cmap_scores <- result$rand_scores
          save(rand_cmap_scores,
               file = file.path(cutoff_dir, sprintf("cmap_random_scores_%d_%s%s_threshold_%s.RData",
                                                    self$n_permutations, self$dataset_label, 
                                                    blood_suffix, cutoff)))
        }
        
        # Save cutoff-specific outputs
        if (!is.null(result$drugs_valid) && nrow(result$drugs_valid) > 0) {
          cutoff_hits <- result$drugs_valid
          cutoff_hits$cutoff <- cutoff
          
          blood_suffix <- if (!is.null(self$blood_label)) paste0("_", self$blood_label) else ""
          filename <- sprintf("%s%s_hits_cutoff_%s.csv", self$dataset_label, blood_suffix, cutoff)
          utils::write.csv(cutoff_hits,
            file = file.path(cutoff_dir, filename),
            row.names = FALSE
          )
          
          # Save in original script format
          results_list <- list(cutoff_hits, result$signature)
          save(results_list,
               file = file.path(cutoff_dir, sprintf("cmap_predictions_%s%s_threshold_%s.RData",
                                                    self$dataset_label, blood_suffix, cutoff)))
          
          # Store in sweep results
          self$sweep_hits[[as.character(cutoff)]] <- cutoff_hits
          
          # Update summary
          summary_row <- data.frame(
            cutoff = cutoff,
            n_genes_kept = result$n_genes,
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
        
        # Always create consolidated results and plots after sweep
        tryCatch({
          self$create_sweep_analysis_files()
          self$log("✅ Sweep analysis plots and consolidated results created successfully")
        }, error = function(e) {
          self$log("Warning: Could not create sweep analysis files - %s", e$message)
          # Still try to create basic consolidated results file
          tryCatch({
            self$create_basic_consolidated_results()
          }, error = function(e2) {
            self$log("Warning: Could not create basic consolidated results - %s", e2$message)
          })
        })
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
      
      n_cutoffs_total <- length(self$sweep_hits)
      
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
                # Use weights based on cutoff values in this group
                w <- sapply(cutoff, function(c) {
                  weight_key <- as.character(c)
                  if (weight_key %in% names(self$weights)) {
                    self$weights[[weight_key]]
                  } else {
                    1  # default weight
                  }
                })
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
               as.integer(nrow(self$robust_hits)), as.integer(n_cutoffs_total))
      
      # Auto-generate sweep plots after aggregation
      tryCatch({
        plot_success <- plot_sweep_outputs_legacy(
          run_dir = self$out_dir,
          per_cutoff_df = NULL,  # not currently used
          aggregated_df = self$robust_hits,
          cutoff_summary = self$cutoff_summary
        )
        if (plot_success) {
          self$log("Generated legacy sweep plots successfully")
        } else {
          self$log("Warning: Some sweep plots may not have been generated")
        }
      }, error = function(e) {
        self$log("Warning: Failed to generate sweep plots - %s", e$message)
      })
      
      invisible(self)
    },

    create_sweep_analysis_files = function() {
      self$log("Creating consolidated results files for analysis pipeline compatibility")
      
      if (is.null(self$robust_hits) || nrow(self$robust_hits) == 0) {
        self$log("No robust hits available to create analysis files")
        return(invisible(self))
      }
      
      # Create a consolidated drugs dataframe that mimics single mode output
      # Use the robust hits with proper column names for analysis pipeline
      consolidated_drugs <- data.frame(
        exp_id = 1:nrow(self$robust_hits),  # Create synthetic experiment IDs
        cmap_score = self$robust_hits$aggregated_score,
        q = self$robust_hits$min_q,
        subset_comparison_id = sprintf("%s_sweep_aggregated", self$dataset_label),
        name = self$robust_hits$name,
        n_support = self$robust_hits$n_support,
        stringsAsFactors = FALSE
      )
      
      # Create a representative signature (use the last successful cutoff's signature)
      representative_signature <- NULL
      if (length(self$sweep_hits) > 0) {
        # Get signature from the last successful cutoff
        last_cutoff <- names(self$sweep_hits)[length(self$sweep_hits)]
        if (!is.null(self$dz_signature)) {
          representative_signature <- self$dz_signature
        } else if (length(self$dz_signature_list) > 0) {
          representative_signature <- self$dz_signature_list[[1]]$signature
        }
      }
      
      # Create consolidated results in the format expected by analysis pipeline
      consolidated_results <- list(
        drugs = consolidated_drugs, 
        signature_clean = representative_signature
      )
      
      # Save consolidated results file
      results_file <- file.path(self$out_dir, sprintf("%s_results.RData", self$dataset_label))
      save(consolidated_results, file = results_file)
      self$log("Saved consolidated results: %s", results_file)
      
      # Rename the results object to 'results' for compatibility
      results <- consolidated_results
      save(results, file = results_file)
      
      # Create img directory and generate sweep-specific plots
      img_dir <- file.path(self$out_dir, "img")
      io_ensure_dir(img_dir)
      
      # Generate plots using the analysis functions
      tryCatch({
        # Plot histogram of aggregated reversal scores
        sweep_drugs_list <- list(sweep_aggregated = consolidated_drugs)
        pl_hist_revsc(sweep_drugs_list, 
                      save = "dist_rev_score.jpeg", 
                      path = img_dir)
        self$log("Generated sweep histogram of reversal scores")
      }, error = function(e) {
        self$log("Warning: Could not generate sweep histogram - %s", e$message)
      })
      
      # Generate CMap score plot for robust hits
      tryCatch({
        pl_cmap_score(consolidated_drugs, 
                      save = file.path(img_dir, "cmap_score.jpg"))
        self$log("Generated sweep CMap score plot")
      }, error = function(e) {
        self$log("Warning: Could not generate sweep CMap score plot - %s", e$message)
      })
      
      # Create a summary plot showing cutoff performance
      tryCatch({
        if (!is.null(self$cutoff_summary) && nrow(self$cutoff_summary) > 0) {
          jpeg(file.path(img_dir, "sweep_cutoff_summary.jpg"), 
               width = 10, height = 6, units = "in", res = 300)
          
          par(mfrow = c(1, 2))
          
          # Plot 1: Number of hits vs cutoff
          plot(self$cutoff_summary$cutoff, self$cutoff_summary$n_hits,
               type = "b", pch = 16,
               xlab = "Log2FC Cutoff", ylab = "Number of Hits",
               main = "Hits vs Cutoff Threshold",
               col = "steelblue", lwd = 2)
          grid()
          
          # Plot 2: Median q-value vs cutoff
          plot(self$cutoff_summary$cutoff, self$cutoff_summary$median_q,
               type = "b", pch = 16,
               xlab = "Log2FC Cutoff", ylab = "Median Q-value",
               main = "Significance vs Cutoff Threshold",
               col = "darkred", lwd = 2)
          abline(h = 0.05, lty = 2, col = "gray50")
          grid()
          
          dev.off()
          self$log("Generated sweep cutoff summary plot")
        }
      }, error = function(e) {
        self$log("Warning: Could not generate cutoff summary plot - %s", e$message)
      })
      
      # Save additional sweep-specific analysis files
      utils::write.csv(consolidated_drugs,
        file = file.path(self$out_dir, sprintf("%s_hits_q<%.2f.csv", self$dataset_label, self$q_thresh)),
        row.names = FALSE
      )
      
      invisible(self)
    },

    create_sweep_plots = function() {
      self$log("Creating sweep-specific plots...")
      
      # Ensure plots directory exists
      img_dir <- file.path(self$out_dir, "img")
      io_ensure_dir(img_dir)
      
      # Generate plots if we have robust hits
      if (!is.null(self$robust_hits) && nrow(self$robust_hits) > 0) {
        # Create consolidated drugs dataframe for plotting
        consolidated_drugs <- data.frame(
          exp_id = 1:nrow(self$robust_hits),
          cmap_score = self$robust_hits$aggregated_score,
          q = self$robust_hits$min_q,
          subset_comparison_id = sprintf("%s_sweep_aggregated", self$dataset_label),
          name = self$robust_hits$name,
          stringsAsFactors = FALSE
        )
        
        # Generate histogram of aggregated reversal scores
        tryCatch({
          sweep_drugs_list <- list(sweep_aggregated = consolidated_drugs)
          pl_hist_revsc(sweep_drugs_list, 
                        save = "dist_rev_score.jpeg", 
                        path = img_dir)
          self$log("Generated sweep histogram of reversal scores")
        }, error = function(e) {
          self$log("Warning: Could not generate sweep histogram - %s", e$message)
        })
        
        # Generate CMap score plot
        tryCatch({
          pl_cmap_score(consolidated_drugs, 
                        save = file.path(img_dir, "cmap_score.jpg"))
          self$log("Generated sweep CMap score plot")
        }, error = function(e) {
          self$log("Warning: Could not generate sweep CMap score plot - %s", e$message)
        })
        
        # Create cutoff summary plot
        if (!is.null(self$cutoff_summary) && nrow(self$cutoff_summary) > 0) {
          tryCatch({
            jpeg(file.path(img_dir, "sweep_cutoff_summary.jpg"), 
                 width = 10, height = 6, units = "in", res = 300)
            
            par(mfrow = c(1, 2))
            
            # Plot 1: Number of hits vs cutoff
            plot(self$cutoff_summary$cutoff, self$cutoff_summary$n_hits,
                 type = "b", pch = 16,
                 xlab = "Log2FC Cutoff", ylab = "Number of Hits",
                 main = "Hits vs Cutoff Threshold",
                 col = "steelblue", lwd = 2)
            grid()
            
            # Plot 2: Median q-value vs cutoff
            plot(self$cutoff_summary$cutoff, self$cutoff_summary$median_q,
                 type = "b", pch = 16,
                 xlab = "Log2FC Cutoff", ylab = "Median Q-value",
                 main = "Significance vs Cutoff Threshold",
                 col = "darkred", lwd = 2)
            abline(h = 0.05, lty = 2, col = "gray50")
            grid()
            
            dev.off()
            self$log("Generated sweep cutoff summary plot")
          }, error = function(e) {
            self$log("Warning: Could not generate cutoff summary plot - %s", e$message)
          })
        }
      } else {
        self$log("No robust hits available for plotting")
      }
      
      invisible(self)
    },

    create_basic_consolidated_results = function() {
      self$log("Creating basic consolidated results...")
      
      if (is.null(self$robust_hits) || nrow(self$robust_hits) == 0) {
        self$log("No robust hits available")
        return(invisible(self))
      }
      
      # Create consolidated results in basic format
      consolidated_drugs <- data.frame(
        exp_id = 1:nrow(self$robust_hits),  
        cmap_score = self$robust_hits$aggregated_score,
        q = self$robust_hits$min_q,
        subset_comparison_id = sprintf("%s_sweep_aggregated", self$dataset_label),
        name = self$robust_hits$name,
        stringsAsFactors = FALSE
      )
      
      # Use average signature as representative
      representative_signature <- if (!is.null(self$dz_signature)) {
        self$dz_signature
      } else {
        NULL
      }
      
      results <- list(
        drugs = consolidated_drugs, 
        signature_clean = representative_signature
      )
      
      # Save consolidated results file
      results_file <- file.path(self$out_dir, sprintf("%s_results.RData", self$dataset_label))
      save(results, file = results_file)
      self$log("Saved basic consolidated results: %s", results_file)
      
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

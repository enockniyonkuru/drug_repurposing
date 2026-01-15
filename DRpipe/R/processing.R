#' Core Drug Repurposing Processing Functions
#'
#' Functions for processing disease differential expression signatures and
#' comparing them against drug perturbation profiles. Includes cleaning,
#' scoring, and statistical evaluation of drug-disease connections.

# --- Dependencies via roxygen imports (populates NAMESPACE) -------------------
#' @keywords internal
#' @importFrom dplyr select all_of
#' @importFrom gprofiler2 gconvert
#' @importFrom pbapply pbsapply
#' @importFrom qvalue qvalue
NULL

#' Clean and map a DEG table to Entrez IDs
#'
#' Filters by (optional) adjusted p-value and absolute log fold-change,
#' maps gene symbols to Entrez IDs via g:Profiler, and retains only genes present
#' in a provided reference gene universe (e.g., CMap).
#'
#' @param x data.frame; a DEG table containing a gene column and a logFC column.
#' @param gene_key character; column name for gene symbols. Default: \code{"X"}.
#' @param logFC_key character; column name for log fold-change values.
#'   Default: \code{"avg_log2FC"}.
#' @param logFC_cutoff numeric; absolute logFC threshold. Default: \code{0.25}.
#' @param pval_key character or \code{NULL}; column name for adjusted p-values,
#'   or \code{NULL} if no p-values are available. Default: \code{"p_val_adj"}.
#' @param pval_cutoff numeric; adjusted p-value cutoff when \code{pval_key} is
#'   not \code{NULL}. Default: \code{0.05}.
#' @param db_gene_list vector; Entrez IDs defining the target gene universe
#'   (e.g., the set of genes present in the perturbation database).
#'
#' @return data.frame with two columns: \code{GeneID} (Entrez) and \code{logFC}
#'   (filtered and aligned to the reference gene universe).
#'
#' @details
#' This function processes a single DEG table at a time. Gene symbols are mapped
#' to Entrez IDs using \code{gprofiler2::gconvert()}. Rows that fail mapping or
#' fall outside the provided gene universe are removed.
#'
#' @seealso \code{\link{query_score}}, \code{\link{random_score}}, \code{\link{query}}
#' @export
#' @importFrom gprofiler2 gconvert

clean_table <- function(x,
                        gene_key = "X",
                        logFC_key = "avg_log2FC",
                        logFC_cutoff = 0.25,
                        pval_key = "p_val_adj",
                        pval_cutoff = 0.05,
                        db_gene_list) {

    # --- Validate key arguments ----------------------------------------------
    if (!is.character(logFC_key) || length(logFC_key) != 1) {
        stop("`logFC_key` must be a character string of length 1.", call. = FALSE)
    }
    if (!is.null(pval_key) && (!is.character(pval_key) || length(pval_key) != 1)) {
        stop("`pval_key` must be a character string of length 1.", call. = FALSE)
    }
    if (!is.character(gene_key) || length(gene_key) != 1) {
        stop("`gene_key` must be a character string of length 1.", call. = FALSE)
    }

    # Track gene counts after each filter stage
    track <- vector("integer", 5)
    names(track) <- c("init", "padj", "logFC", "entrez", "cmap")
    track["init"] <- nrow(x)

    # --- Keep essential columns; optionally filter by adjusted p-value --------
    if (is.null(pval_key)) {
        # Only gene and logFC available/kept
        x <- x[, c(gene_key, logFC_key)]
    } else {
        # Keep gene, p-value, and logFC
        x <- x[, c(gene_key, pval_key, logFC_key)]
        # Select significant genes by p-value
        x <- x[which(x[[pval_key]] < pval_cutoff), ]
    }
    track["padj"] <- nrow(x)

    # --- Filter by absolute logFC threshold -----------------------------------
    x <- x[which(abs(x[[logFC_key]]) > logFC_cutoff), ]
    track["logFC"] <- nrow(x)

    # Sort by effect size to keep output stable/readable
    x <- x[order(x[[logFC_key]]), ]

    # Standardize the gene symbol column name
    colnames(x)[colnames(x) == gene_key] <- "GeneName"

    # --- Map gene symbols -> Entrez IDs using g:Profiler ----------------------
    entrez <- gconvert(
        x$GeneName,
        organism   = "hsapiens",
        target     = "ENTREZGENE_ACC",
        numeric_ns = "",
        mthreshold = 1,
        filter_na  = FALSE
    )
    # Attach Entrez to table; drop genes that failed mapping
    x$GeneID <- entrez$target
    x <- x[!is.na(x$GeneID), ]
    track["entrez"] <- nrow(x)

    # --- Restrict to genes present in the CMap gene universe ------------------
    x <- x[which(x$GeneID %in% db_gene_list), ]
    track["cmap"] <- nrow(x)

    # --- Finalize output (Entrez + logFC) -------------------------------------
    x <- dplyr::select(x, "GeneID", dplyr::all_of(logFC_key))
    colnames(x) <- c("GeneID", "logFC")

    # Progress summary of filter stages
    print(track)

    return(x)
}
#' Compute a connectivity (reversal) score for one drug signature
#'
#' Calculates a KS-like signed statistic comparing an input disease signature
#' (up-/down-regulated Entrez IDs) to a single ranked drug signature.
#' Negative values indicate reversal (desired); positive values indicate mimicry.
#'
#' @param sig_up data.frame with a column \code{GeneID} (up-regulated genes).
#' @param sig_down data.frame with a column \code{GeneID} (down-regulated genes).
#' @param drug_signature data.frame with columns \code{ids} (Entrez) and \code{rank}.
#' @param scale logical; if \code{TRUE}, rescales the score into \code{[-1, 0]} so that
#'   more negative corresponds to stronger reversal.
#'
#' @return Numeric scalar connectivity/reversal score.
#' @export
cmap_score <- function(sig_up, sig_down, drug_signature, scale = FALSE) {
  # Total genes in current drug signature (ranked list)
  num_genes <- nrow(drug_signature)

  # Initialize KS-like statistics for up/down sets
  ks_up   <- 0
  ks_down <- 0
  connectivity_score <- 0

  # Ensure 'rank' is 1..N (some inputs may not be strict integers)
  drug_signature[, "rank"] <- rank(drug_signature[, "rank"])

  # Intersect disease sets with the drug's ranked gene list
  up_tags_rank   <- merge(drug_signature, sig_up,   by.x = "ids", by.y = 1)
  down_tags_rank <- merge(drug_signature, sig_down, by.x = "ids", by.y = 1)

  # Positions (ranks) for enrichment computation
  up_tags_position   <- sort(up_tags_rank$rank)
  down_tags_position <- sort(down_tags_rank$rank)

  num_tags_up   <- length(up_tags_position)
  num_tags_down <- length(down_tags_position)

  # --- KS-like statistic for UP set -----------------------------------------
  if (num_tags_up > 1) {
    a_up <- max(sapply(seq_len(num_tags_up), function(j) {
      j / num_tags_up - up_tags_position[j] / num_genes
    }))
    b_up <- max(sapply(seq_len(num_tags_up), function(j) {
      up_tags_position[j] / num_genes - (j - 1) / num_tags_up
    }))
    ks_up <- if (a_up > b_up) a_up else -b_up
  } else {
    ks_up <- 0
  }

  # --- KS-like statistic for DOWN set ---------------------------------------
  if (num_tags_down > 1) {
    a_down <- max(sapply(seq_len(num_tags_down), function(j) {
      j / num_tags_down - down_tags_position[j] / num_genes
    }))
    b_down <- max(sapply(seq_len(num_tags_down), function(j) {
      down_tags_position[j] / num_genes - (j - 1) / num_tags_down
    }))
    ks_down <- if (a_down > b_down) a_down else -b_down
  } else {
    ks_down <- 0
  }

  # --- Combine UP/DOWN to a single connectivity score -----------------------
  # Negative score implies reversal (desired), positive implies mimicry.
  if (ks_up == 0 && ks_down != 0) {              # only DOWN provided
    connectivity_score <- -ks_down
  } else if (ks_up != 0 && ks_down == 0) {       # only UP provided
    connectivity_score <- ks_up
  } else if (sum(sign(c(ks_down, ks_up))) == 0) {# opposite signs -> subtract
    connectivity_score <- ks_up - ks_down
  } else {
    # If both have same sign or both zero, score remains 0 (neutral)
    connectivity_score <- 0
  }

  # Optional rescaling to [-1, 0]; negative means stronger reversal
  if (scale) {
    denom <- min(connectivity_score, na.rm = TRUE)
    if (!is.finite(denom) || denom == 0) return(0)
    return(-connectivity_score / denom)
  } else {
    return(connectivity_score)
  }
}


#' Generate a null distribution of reversal scores using random genes
#'
#' @param cmap_signatures matrix/data.frame with first column = Entrez IDs,
#'        subsequent columns = ranked values per experiment
#' @param n_up integer; number of up-regulated disease genes
#' @param n_down integer; number of down-regulated disease genes
#' @param N_PERMUTATIONS integer; number of random iterations (default 1e5)
#' @param seed integer for RNG seed (default 123)
#' @return numeric vector of random (null) connectivity scores
#' @export
random_score <- function(cmap_signatures, n_up, n_down,
                         N_PERMUTATIONS = 1e5,
                         seed = 123) {
    set.seed(seed)

    # Sample experiment columns (2..ncol) with replacement for each permutation
    rand_cmap_scores <- pbapply::pbsapply(
        sample(2:ncol(cmap_signatures), N_PERMUTATIONS, replace = TRUE),
        function(exp_id) {
            # Build a minimal drug signature: (ids, rank)
            cmap_exp_signature <- subset(cmap_signatures, select = c(1, exp_id))
            colnames(cmap_exp_signature) <- c("ids", "rank")

            # Randomly sample |n_up + n_down| genes from the universe
            random_input_signature_genes <- sample(cmap_signatures$V1, (n_up + n_down))

            # Split the random sample into "up" then "down" gene sets
            rand_dz_gene_up   <- data.frame(GeneID = random_input_signature_genes[1:n_up])
            rand_dz_gene_down <- data.frame(GeneID = random_input_signature_genes[(n_up + 1):length(random_input_signature_genes)])

            # Compute connectivity (null) score for this random split
            cmap_score(rand_dz_gene_up, rand_dz_gene_down, cmap_exp_signature)
        },
        simplify = FALSE
    )

    # Flatten list of length N_PERMUTATIONS into a numeric vector
    return(unlist(rand_cmap_scores))
}

#' Compute reversal scores across all CMap drug profiles for one disease signature
#'
#' @param cmap_signatures matrix/data.frame with first column = Entrez IDs,
#'        subsequent columns = ranked values per experiment
#' @param dz_genes_up vector of Entrez IDs for up-regulated genes
#' @param dz_genes_down vector of Entrez IDs for down-regulated genes
#' @return numeric vector of connectivity scores (one per experiment)
#' @export
query_score <- function(cmap_signatures, dz_genes_up, dz_genes_down) {
    # Convert input vectors to (GeneID) data.frames expected by cmap_score()
    dz_genes_up   <- data.frame(GeneID = dz_genes_up)
    dz_genes_down <- data.frame(GeneID = dz_genes_down)

    # Iterate over experiments (columns 2..n), compute connectivity per experiment
    n_experiments <- ncol(cmap_signatures) - 1
    cat(sprintf("[QUERY_SCORE] Computing scores for %d experiments...\n", n_experiments))
    flush.console()
    
    dz_cmap_scores <- pbapply::pbsapply(
        2:ncol(cmap_signatures),
        function(exp_id) {
            cmap_exp_signature <- subset(cmap_signatures, select = c(1, exp_id))
            colnames(cmap_exp_signature) <- c("ids", "rank")
            cmap_score(dz_genes_up, dz_genes_down, cmap_exp_signature)
        }
    )

    cat(sprintf("[QUERY_SCORE] Complete! Computed %d scores\n", length(dz_cmap_scores)))
    flush.console()
    return(dz_cmap_scores)
}

#' Assemble per-experiment results with p-values and q-values
#'
#' @param rand_cmap_scores numeric vector of null scores from random_score()
#' @param dz_cmap_scores numeric vector of observed scores from query_score()
#' @param subset_comparison_id string label for this query (e.g., dataset name)
#' @param analysis_id string label for the analysis type (default: "cmap")
#' @return data.frame with experiment id, score, p, q, subset_comparison_id, analysis_id
#' @export
query <- function(rand_cmap_scores, dz_cmap_scores, subset_comparison_id, analysis_id = "cmap") {
    # --- Two-sided p-values from the empirical null (frequency method) --------
    message("COMPUTING p-values")
    p_values <- sapply(dz_cmap_scores, function(score) {
        count_extreme <- sum(abs(rand_cmap_scores) >= abs(score))
        p_val <- count_extreme / length(rand_cmap_scores)
        
        # CRITICAL FIX: Prevent p-values from being exactly 0
        # Use permutation-based minimum: 1/(N+1) as per Phipson & Smyth (2010)
        if (p_val == 0) {
            p_val <- 1 / (length(rand_cmap_scores) + 1)
        }
        
        return(p_val)
    })
    
    # --- Diagnostic logging ---------------------------------------------------
    message(sprintf("P-values computed: %d", length(p_values)))
    message(sprintf("P-values == 0: %d (%.1f%%)", 
                    sum(p_values == 0), 100 * mean(p_values == 0)))
    message(sprintf("P-value range: [%.10f, %.10f]", 
                    min(p_values), max(p_values)))
    message(sprintf("P-values < 0.05: %d (%.1f%%)", 
                    sum(p_values < 0.05), 100 * mean(p_values < 0.05)))

    # --- q-values (FDR correction) --------------------------------------------
    message("COMPUTING q-values")
    
    # Add error handling for qvalue package
    q_values <- tryCatch({
        qvalue::qvalue(p_values)$qvalues
    }, error = function(e) {
        warning(sprintf("qvalue() failed: %s. Using p.adjust() instead.", e$message))
        p.adjust(p_values, method = "BH")
    })
    
    # --- Diagnostic logging for q-values --------------------------------------
    message(sprintf("Q-values computed: %d", length(q_values)))
    message(sprintf("Q-values == 0: %d (%.1f%%)", 
                    sum(q_values == 0), 100 * mean(q_values == 0)))
    message(sprintf("Q-value range: [%.10f, %.10f]", 
                    min(q_values), max(q_values)))
    message(sprintf("Q-values < 0.05: %d (%.1f%%)", 
                    sum(q_values < 0.05), 100 * mean(q_values < 0.05)))
    
    # --- Final safety check ---------------------------------------------------
    if (all(q_values == 0)) {
        stop("CRITICAL ERROR: All q-values are 0. This indicates a problem with FDR correction.")
    }

    # Annotate result set with provided analysis_id
    drugs <- data.frame(
        exp_id = seq_along(dz_cmap_scores),
        cmap_score = dz_cmap_scores,
        p = p_values,
        q = q_values,
        subset_comparison_id = subset_comparison_id,
        analysis_id = analysis_id
    )

    return(drugs)
}

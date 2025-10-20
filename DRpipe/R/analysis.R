# ------------------------------------------------------------------------------
# File: analysis.R
#
# Visualization and downstream analysis utilities for the drug-repurposing
# pipeline. These functions:
#   • summarize and plot score distributions across datasets,
#   • filter/annotate valid drug instances via CMAP metadata,
#   • prepare matrices for reversal heatmaps and overlap summaries,
#   • draw heatmaps and UpSet/venn-style intersections,
#   • assemble per-drug score/q-value tables for reporting.
# Use together with the processing step to compare disease signatures to CMAP
# and visualize consistent candidate drugs across datasets.
# ------------------------------------------------------------------------------


# ---- Plot the distribution of reversal scores --------------------------------
#' Plot histograms of CMap reversal scores per dataset
#'
#' Draws a grid of histograms (one per element in \code{drug_list}) showing the
#' distribution of \code{cmap_score} values for quick QC.
#'
#' @param drug_list A named list of data frames (one per comparison) each
#'   containing a numeric column \code{cmap_score}.
#' @param width,height,res Numeric device settings for the JPEG.
#' @param save Character; output filename.
#' @param path Character; directory to save the image (created upstream).
#'
#' @return Invisibly, the file path written.
#' @details Uses base graphics; layout is 2 columns by ceiling(n/2) rows.
#' @export
#' @importFrom grDevices jpeg dev.off
#' @importFrom graphics par hist
pl_hist_revsc <- function(drug_list,
                          width = 1200, height = 1500, res = 300,
                          save = "dist_rev_score.jpg", path = getwd()) {
    n_rows <- ceiling(length(drug_list) / 2)
    fp <- file.path(path, save)
    jpeg(fp, width = width, height = height, res = res)
    par(mfrow = c(n_rows, 2))
    par(mar = c(3.1, 4.1, 3.1, 2.1))
    for (nm in names(drug_list)) {
        hist(drug_list[[nm]]$cmap_score, breaks = 10, main = nm, xlab = "CMap Score")
    }
    dev.off()
    invisible(fp)
}


# ---- Filter out valid instances ----------------------------------------------
#' Filter and deduplicate valid drug instances
#'
#' Merges hits with CMAP experiment metadata, keeps significant reversers
#' (\code{q < 0.05} & negative \code{cmap_score}), and retains the strongest
#' (most negative) instance per drug name.
#'
#' @param x Data frame of hits with columns \code{exp_id}, \code{q},
#'   \code{cmap_score}, \code{subset_comparison_id}.
#' @param cmap_exp Data frame of experiment metadata with columns \code{id},
#'   \code{name}, \code{DrugBank.ID}, \code{valid}, etc.
#'
#' @return A data frame of valid, deduplicated instances ordered by cmap_score.
#' @export
#' @importFrom dplyr group_by slice ungroup
valid_instance <- function(x, cmap_exp) {
    title <- x$subset_comparison_id[1]
    x <- merge(x, cmap_exp, by.x = "exp_id", by.y = "id")
    x <- subset(x, q < 0.05 & cmap_score < 0)
    message(title, ": # instances including duplicates: ", nrow(x))
    x <- x %>%
        group_by(name) %>%
        dplyr::slice(which.min(cmap_score)) %>%
        ungroup()
    message(title, ": # instances excluding duplicates: ", nrow(x))
    x <- x[order(x$cmap_score), ]
    x
}



# ---- Convert Vxxx experiment column names to drug names ----------------------
#' Replace experiment column labels with drug names
#'
#' Converts CMAP matrix column names like \code{"V2"} to human-readable drug
#' names by mapping to experiment IDs in \code{cmap_exp}.
#'
#' @param cmap_sig Matrix/data frame; CMAP signatures with experiment columns.
#' @param cmap_exp Data frame with \code{id} and drug \code{name}.
#'
#' @return The input matrix with column names replaced by drug names.
#' @export
h_drug_names <- function(cmap_sig, cmap_exp = cmap_experiments_valid) {
    if (!is.null(dim(cmap_sig))) {
        old_id <- colnames(cmap_sig)
        new_id <- strtoi(sub("^V", "", old_id)) - 1
        rownames(cmap_exp) <- cmap_exp$id
        drug_names <- cmap_exp[as.character(new_id), "name"]
        colnames(cmap_sig) <- drug_names
        return(cmap_sig)
    } else {
        stop("`cmap_sig` must be a non-empty matrix/data.frame.", call. = FALSE)
    }
}


#' Prepare ranked disease–drug matrix for heatmap
#'
#' Merges a disease signature (GeneID, logFC) with selected CMAP signatures,
#' converts columns to ranks (disease ranks flipped), and returns a data frame
#' of GeneID, disease rank, and ranked drug signature columns (named by drug).
#'
#' @param x data.frame with at least \code{exp_id} for selected experiments.
#' @param dz_sig data.frame with columns \code{GeneID}, \code{logFC}.
#' @param cmap_sig matrix/data.frame: first column Entrez IDs, others ranks.
#' @return data.frame with \code{GeneID}, disease rank, and ranked drug columns.
#' @export
prepare_heatmap <- function(x, dz_sig, cmap_sig = cmap_signatures) {
    # Convert `exp_id` (1-based across experiments) to CMAP column indices (+1 to account for GeneID column)
    cmap_idx <- x$exp_id + 1

    # Subset CMAP to (GeneID + selected experiment columns)
    drug_sig <- cmap_sig[, c(1, cmap_idx)]  # first col is gene id

    if (!is.null(dim(drug_sig))) {
        # Merge DZ signature with selected drug signatures on GeneID
        drug_dz_sig <- merge(dz_sig, drug_sig, by.x = "GeneID", by.y = "V1")

        # Column 2 of dz_sig is the logFC ("value") after prior cleaning
        colnames(drug_dz_sig)[2] <- "value"
        drug_dz_sig <- drug_dz_sig[order(drug_dz_sig$value), ]

        # Convert disease and drug values to ranks
        # Higher rank = more overexpressed; flip DZ so "more overexpressed" ranks high on the same scale
        drug_dz_sig[, 2] <- -drug_dz_sig[, 2]
        for (i in 2:ncol(drug_dz_sig)) {
            drug_dz_sig[, i] <- rank(drug_dz_sig[, i])
        }

        # Replace generic "Vxxx" experiment labels with drug names
        temp <- h_drug_names(drug_dz_sig[, c(-1, -2), drop = FALSE])
        drug_dz_sig <- cbind(drug_dz_sig[, 1:2], temp)
        return(drug_dz_sig)
    } else {
        return(NULL)
    }
}

# ---- Plot reversal heatmap per dataset ---------------------------------------
#' Plot disease–drug reversal heatmap for one dataset
#'
#' Generates a heatmap visualizing how a disease signature aligns or reverses
#' with selected CMap drug signatures for a single dataset.
#'
#' @param x Data frame of drug hits for one dataset (must include \code{exp_id}, \code{cmap_score}, etc.).
#' @param dz_sig Data frame with disease signature (\code{GeneID}, \code{logFC}).
#' @param cmap_sig Matrix or data frame of CMap signatures (first column = gene IDs, others = experiment ranks).
#' @param dataset Character label used in the plot and output filename.
#' @param width,height,units,res Graphics device parameters controlling plot size and resolution.
#' @param save Character string for the output filename (JPEG).
#' @param path Character directory where the image file will be saved.
#'
#' @return Invisibly returns the file path of the saved JPEG image.
#' @export
#' @importFrom gplots redblue
#' @importFrom grDevices jpeg dev.off
#' @importFrom graphics layout par image axis text
pl_heatmap <- function(x, dz_sig, cmap_sig = cmap_signatures, dataset,
                       width = 12, height = 10, units = "in", res = 300,
                       save = "heatmap_cmap_hits.jpg", path = dir.out.img) {
    drug_dz_sig <- prepare_heatmap(x, dz_sig, cmap_sig)
    if (!is.null(drug_dz_sig)) {
        # Drop the GeneID column for image()
        drug_dz_sig <- drug_dz_sig[, -1]

        # Build output path and open device
        fp <- file.path(path, paste0(dataset, "_", save))
        jpeg(fp, width = width, height = height, units = units, res = res)
        layout(matrix(1))
        par(mar = c(6, 4, 1, 0.5))

        # Color palette: requires gplots::redblue
        colPal <- redblue(100)

        # image() expects a matrix; transpose to get drugs on x-axis
        image(t(as.matrix(drug_dz_sig)), col = colPal, axes = FALSE)

        # Minimal axes; labels drawn with text() so we can rotate/position them
        axis(1, at = seq(0, 1, length.out = ncol(drug_dz_sig)), labels = FALSE)
        axis(2, at = seq(0, 1, length.out = nrow(drug_dz_sig)), labels = FALSE)

        # Column labels: dataset name then drug names (exclude first col "value")
        text(x = seq(0, 1, length.out = ncol(drug_dz_sig)),
             y = -0.015,
             labels = c(dataset, colnames(drug_dz_sig)[-1]),
             srt = 45, pos = 2, offset = -0.2, xpd = TRUE, cex = 0.7, col = "black")

        dev.off()
        return(invisible(fp))
    }
    invisible(NULL)
}


# ---- Prepare overlap matrix across datasets ----------------------------------
#' Build drug-by-dataset overlap matrix
#'
#' Produces a wide matrix where each row is a drug and columns are datasets.
#' Values are scaled magnitudes of reversal (negative scores -> positive scale).
#'
#' @param x Integrated table of valid instances (rbind across datasets).
#' @param at_least2 Logical; keep drugs present in at least 2 datasets.
#'
#' @return Wide matrix (rows = drugs, columns = datasets).
#' @export
#' @importFrom reshape2 dcast
prepare_overlap <- function(x, at_least2 = FALSE) {
    # Scale by min (most negative) to get positive magnitudes for plotting
    df <- data.frame(
        name   = x$name,
        source = x$subset_comparison_id,
        value  = x$cmap_score / min(x$cmap_score)
    )

    # Long -> wide (one column per dataset)
    df <- dcast(df, name ~ source, value.var = "value")

    # Replace NAs with 0 (no hit in that dataset)
    df[is.na(df)] <- 0

    # Row names are drug names
    rownames(df) <- df[, "name"]

    # Optionally filter to drugs appearing in ≥ 2 datasets
    if (at_least2) {
        has_2plus <- apply(df, 1, function(r) sum(as.numeric(r[-1]) != 0) > 1)
        df <- df[has_2plus, ]
    }
    df
}

# ---- Plot heatmap showing overlap across datasets ----------------------------
#' Plot overlap heatmap across datasets
#'
#' @param x Integrated table of valid instances (rbind).
#' @param at_least2 Logical; keep drugs present in at least 2 datasets.
#' @param width,height,units,res Device settings.
#' @param save,path Output filename and directory.
#'
#' @return Invisibly, the file path written.
#' @export
#' @import pheatmap
#' @importFrom grDevices jpeg
#' @importFrom grDevices colorRampPalette
pl_overlap <- function(x, at_least2 = FALSE,
                       width = 12, height = 3.5, units = "in", res = 600,
                       save = "combined_PE_hits_heatmap.jpg", path = dir.out.img) {
    mat <- prepare_overlap(x, at_least2 = at_least2)
    if (nrow(mat) != 0) {
        jpeg(paste0(path, save), width = width, height = height, units = units, res = res)
        pheatmap(t(mat[, 2:ncol(mat)]),
                 color         = colorRampPalette(c("grey", "red3"))(100),
                 border_color  = "grey60",
                 angle_col     = "90",
                 angle_row     = c("30"),
                 fontsize_row  = 16,
                 fontsize_col  = 12,
                 cluster_rows  = FALSE,
                 legend        = FALSE)
        dev.off()
    }
}

#' Build a drugs-per-dataset list for UpSet plots
#'
#' @param x data.frame combining valid drug instances across datasets; must
#'   contain \code{subset_comparison_id} and \code{name}.
#' @return A named list; each element is the character vector of drugs for one dataset.
#' @export
prepare_upset_drug <- function(x) {
    comparisons <- unique(x$subset_comparison_id)
    drugs.list <- lapply(comparisons, function(cmp) {
        x[x$subset_comparison_id == cmp, ] %>% pull(name)
    })
    names(drugs.list) <- comparisons
    drugs.list
}

# ---- Draw UpSet plot ----------------------------------------------------------
#' Draw an UpSet plot of shared drugs across datasets
#'
#' @param x Named list (from \code{prepare_upset_drug}).
#' @param title Optional title.
#' @param width,height,units,res Device settings.
#' @param save,path Output filename and directory.
#'
#' @return Invisibly, the file path written.
#' @export
#' @importFrom UpSetR upset fromList
#' @importFrom grid grid.text gpar
#' @importFrom grDevices jpeg dev.off
pl_upset <- function(x, title = "",
                     width = 6, height = 3, units = "in", res = 600,
                     save = "upset.jpg", path = dir.out.img) {
    jpeg(paste0(path, save), width = width, height = height, units = units, res = res)
    p <- upset(fromList(x), nsets = 10, order.by = "freq")
    print(p)
    grid.text(title, x = 0.65, y = 0.95, gp = gpar(fontsize = 12))
    dev.off()
}

# ---- Assemble per-drug CMap scores across datasets ---------------------------
#' Collect minimal CMap scores for selected drugs
#'
#' For each drug and dataset, selects the strongest reversal (minimal score).
#'
#' @param x List of per-dataset data frames (before/after filtering).
#' @param drugs Character vector of drug names to keep.
#'
#' @return A wide matrix (rows = drugs, columns = datasets) of minimal scores.
#' @export
#' @importFrom dplyr filter group_by slice
#' @importFrom tidyr pivot_wider
#' @importFrom tibble column_to_rownames
get_cmap_score <- function(x, drugs) {
    hit <- do.call("rbind", x) %>%
        filter(name %in% drugs)

    df <- data.frame(
        name   = hit$name,
        exp_id = hit$exp_id,
        source = hit$subset_comparison_id,
        value  = hit$cmap_score
    ) %>%
        group_by(name, source) %>%
        dplyr::slice(which.min(value)) %>%     # take strongest reversal per dataset
        tidyr::pivot_wider(id_cols = "name", names_from = "source", values_from = "value") %>%
        as.data.frame() %>%
        tibble::column_to_rownames("name")

    df
}

# ---- Assemble per-drug q-values across datasets ------------------------------
#' Collect minimal q-values for selected drugs
#'
#' Aligns with \code{get_cmap_score} selection (same minimal-score instances).
#'
#' @param x List of per-dataset data frames (before/after filtering).
#' @param drugs Character vector of drug names to keep.
#'
#' @return A wide matrix (rows = drugs, columns = datasets) of minimal q-values.
#' @export
#' @importFrom dplyr filter group_by slice
#' @importFrom tidyr pivot_wider
#' @importFrom tibble column_to_rownames
get_qval <- function(x, drugs) {
    hit <- do.call("rbind", x) %>%
        filter(name %in% drugs)

    df <- data.frame(
        name   = hit$name,
        exp_id = hit$exp_id,
        source = hit$subset_comparison_id,
        value  = hit$cmap_score,
        q      = hit$q
    ) %>%
        group_by(name, source) %>%
        dplyr::slice(which.min(value)) %>%     # align with get_cmap_score selection
        tidyr::pivot_wider(id_cols = "name", names_from = "source", values_from = "q") %>%
        as.data.frame() %>%
        tibble::column_to_rownames("name")

    df
}

# ---- Drop drugs with any positive CMap scores --------------------------------
#' Remove drugs that show any positive CMap score
#'
#' @param x Matrix/data frame of CMap scores (rows = drugs, cols = datasets).
#'
#' @return The filtered matrix/data frame with only non-positive rows kept.
#' @export
remove_pos <- function(x) {
    has_pos <- apply(x, 1, function(r) any(r > 0))
    x[!has_pos, , drop = FALSE]
}

# ---- Plot summary heatmap of CMap scores (with q-value stars) ----------------
#' Plot a summary heatmap of scores with significance stars
#'
#' Draws a heatmap of \code{cmap_score} with stars marking \code{q < 0.05}.
#'
#' @param cmap_score Data frame of per-drug scores (rows) across datasets (cols).
#' @param qval Data frame of per-drug q-values aligned to \code{cmap_score}.
#' @param annot_col_col Named list of colors for \code{annotation_col}.
#' @param annot_col Data frame of per-column annotations (e.g., cell type).
#' @param cluster_cols,cluster_rows Logical; clustering options passed to pheatmap.
#' @param path,save,width,height,units,res Output file settings.
#'
#' @return Invisibly, the file path written.
#' @export
#' @import pheatmap
#' @importFrom grDevices colorRampPalette jpeg
#' @importFrom grid grid.newpage grid.draw
pl_cmap_score <- function(cmap_score, qval = NULL, annot_col_col = NULL, annot_col = NULL,
                          cluster_cols = FALSE, cluster_rows = TRUE,
                          path = NULL, save = "cmap_score.jpg",
                          width = 8, height = 12, units = "in", res = 900) {

    # Handle simple case where we just have a data frame of drugs
    if (is.data.frame(cmap_score) && "cmap_score" %in% names(cmap_score)) {
        # Simple bar plot for single dataset
        if (!is.null(path)) {
            jpeg(file.path(path), width = width, height = height, units = units, res = res)
        } else {
            jpeg(save, width = width, height = height, units = units, res = res)
        }
        
        # Filter out rows with NA in the name column before selecting top drugs
        cmap_score_clean <- cmap_score[!is.na(cmap_score$name), ]
        
        # Create a simple plot of the top drugs
        top_drugs <- head(cmap_score_clean[order(cmap_score_clean$cmap_score), ], 20)
        par(mar = c(5, 10, 4, 2))
        barplot(top_drugs$cmap_score, 
                names.arg = top_drugs$name,
                horiz = TRUE, las = 1,
                main = "Top Drug Reversal Scores",
                xlab = "CMap Score",
                col = "steelblue")
        dev.off()
        return(invisible(save))
    }
    
    # Original complex heatmap code for matrix input
    if (!requireNamespace("pheatmap", quietly = TRUE)) {
        warning("pheatmap package not available, skipping heatmap")
        return(invisible(NULL))
    }
    
    # Set default path if not provided
    if (is.null(path)) path <- getwd()
    
    # Mark significant cells with a star if qval provided
    qval_sig <- if (!is.null(qval)) ifelse(qval < 0.05, "*", "") else NULL

    # Symmetric breakpoints if any positive values exist; otherwise go negative->0
    rg <- max(abs(cmap_score), na.rm = TRUE)
    if (max(cmap_score, na.rm = TRUE) > 0) {
        breaks <- seq(-rg, rg, length.out = 100)
        color  <- c("blue3", "white", "red3")
    } else {
        breaks <- seq(-rg, 0, length.out = 100)
        color  <- c("blue3", "white")
    }

    p <- pheatmap::pheatmap(cmap_score,
                  color            = colorRampPalette(color)(100),
                  breaks           = breaks,
                  border_color     = "grey60",
                  display_numbers  = qval_sig, number_color = "red",
                  annotation_col   = annot_col,
                  annotation_colors= annot_col_col,
                  angle_col        = "90", angle_row = c("30"),
                  fontsize_row     = 10, fontsize_col = 12,
                  cluster_cols     = cluster_cols,
                  cluster_rows     = cluster_rows,
                  legend           = TRUE)

    jpeg(file.path(path, save), width = width, height = height, units = units, res = res)
    grid::grid.newpage()
    grid::grid.draw(p$gtable)
    dev.off()
    
    invisible(file.path(path, save))
}

# ---- Get the row order from a clustered heatmap ------------------------------
#' Get row order from a clustered heatmap
#'
#' Computes a temporary clustered heatmap and returns the row order for
#' consistent downstream table/figure ordering.
#'
#' @param cmap_score Matrix/data frame of scores.
#'
#' @return Integer vector of row indices (order).
#' @export
#' @import pheatmap
#' @importFrom grDevices colorRampPalette
get_order <- function(cmap_score) {
    p <- pheatmap(cmap_score,
                  color           = colorRampPalette(c("blue3", "white", "red3"))(100),
                  border_color    = "grey60",
                  angle_col       = "90", angle_row = c("30"),
                  fontsize_row    = 10, fontsize_col = 12,
                  cluster_cols    = FALSE, cluster_rows = TRUE,
                  legend          = TRUE)
    p$tree_row$order
}

# ---- Save score/q-value tables with drug info to Excel -----------------------
#' Save CMap scores and q-values with drug annotations to an .xlsx file
#'
#' Writes multiple sheets using writexl: "Scores", "Qvalues", and "SignifMarks"
#' (a star "*" where q < 0.05). Requires the 'writexl' package (in Suggests).
#'
#' @param cmap_score data.frame | matrix of scores (rows = drugs, cols = datasets)
#' @param qval       data.frame | matrix of q-values aligned to \code{cmap_score}
#' @param drug_info  data.frame with at least a \code{name} column to join
#' @param path       output directory (will be created if missing)
#' @param sheet      (ignored; kept for backward compatibility)
#' @param save       filename of the Excel file (default: "combined_hits_sig_heatmap.xlsx")
#' @return (invisible) character path to the saved Excel file
#' @export
save_fin_table <- function(cmap_score, qval, drug_info,
                           path = dir.out, sheet = "All",
                           save = "combined_hits_sig_heatmap.xlsx") {

  # Ensure writexl is available (Suggests, not Imports)
  if (!requireNamespace("writexl", quietly = TRUE)) {
    stop("Package 'writexl' is required. Install it with install.packages('writexl').", call. = FALSE)
  }

  # Ensure output directory exists
  dir.create(path, showWarnings = FALSE, recursive = TRUE)

  # Order rows for readability using the clustered order
  ord <- get_order(cmap_score)

  # Join external drug_info (expects a 'name' column)
  drugInfo <- dplyr::left_join(
    data.frame(name = rownames(cmap_score)[ord]),
    drug_info,
    by = "name"
  )

  # Align and assemble outputs
  scores_out <- cbind(cmap_score[drugInfo$name, , drop = FALSE], drugInfo)
  qval_out   <- qval[drugInfo$name, , drop = FALSE]

  # Significance marks (writexl can't do cell formatting; provide as separate sheet)
  signif_out <- ifelse(qval_out < 0.05, "*", "")

  # Write multi-sheet workbook
  out_path <- file.path(path, save)
  writexl::write_xlsx(
    x = list(
      Scores      = as.data.frame(scores_out),
      Qvalues     = as.data.frame(qval_out),
      SignifMarks = as.data.frame(signif_out)
    ),
    path = out_path
  )

  invisible(out_path)
}

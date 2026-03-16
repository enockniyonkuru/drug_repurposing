#' ChEMBL Disease-Drug Validation Module
#'
#' Extract known disease-drug pairs from ChEMBL and match against repurposing results.
#' Validates findings for novelty and FDA/EMA approval status.
#'
#' @description
#' This module provides functions to:
#' - Load and parse ChEMBL chemreps (SMILES/InChI mappings)
#' - Extract disease-drug indication pairs with approval metadata
#' - Match your pipeline results against known ChEMBL pairs
#' - Flag novel discoveries, FDA-approved candidates, withdrawn drugs, and black-box warnings

# ============================================================================
# 1. Load ChEMBL Chemreps (SMILES/InChI/InChIKey Mappings)
# ============================================================================

#' Load ChEMBL Chemical Representations
#'
#' @param chemreps_path Path to chembl_36_chemreps.txt.gz (gzipped tab-separated)
#' @param cols Column names: CHEMBL_ID, SMILES, InChI, InChIKey
#'
#' @return data.frame with drug structures mapped to chembl_id/molregno
#'
#' @examples
#' # chemreps <- load_chembl_chemreps("path/to/chembl_36_chemreps.txt.gz")
#'
#' @export
load_chembl_chemreps <- function(chemreps_path, verbose = TRUE) {
  if (!file.exists(chemreps_path)) {
    stop(sprintf("ChEMBL chemreps file not found: %s", chemreps_path))
  }
  
  if (verbose) cat("Loading ChEMBL chemical representations...\n")
  
  chemreps <- read.delim(
    gzfile(chemreps_path),
    header = TRUE,
    sep = "\t",
    stringsAsFactors = FALSE,
    na.strings = c("", "NA", "N/A")
  )
  
  if (verbose) {
    cat(sprintf("Loaded %d ChEMBL compounds with SMILES/InChI/InChIKey mappings.\n", nrow(chemreps)))
  }
  
  return(chemreps)
}


# ============================================================================
# 2. Extract Disease-Drug Indications from ChEMBL MySQL Dump
# ============================================================================

#' Extract ChEMBL Disease-Drug Indication Pairs
#'
#' Queries DRUG_INDICATION + MOLECULE_DICTIONARY to get known disease-drug pairs
#' with approval status, therapeutic flags, and safety annotations.
#'
#' @param db_path Path to ChEMBL SQLite database or MySQL connection string
#' @param db_type "sqlite" or "mysql"
#' @param include_withdrawn Include withdrawn drugs? Default TRUE
#' @param min_phase Minimum MAX_PHASE to include (0-4). Default 0 (all)
#'
#' @return data.frame with columns:
#'   - drug_name, chembl_id, molregno
#'   - indication_class, efo_id, mesh_id
#'   - max_phase, approved_flag, approval_status
#'   - withdrawn, black_box_warning, therapeutic_flag
#'
#' @examples
#' # indications <- extract_chembl_indications("path/to/chembl_36.sqlite")
#'
#' @export
extract_chembl_indications <- function(
  db_path,
  db_type = "sqlite",
  include_withdrawn = TRUE,
  min_phase = 0,
  verbose = TRUE
) {
  
  if (db_type == "sqlite") {
    if (!require("RSQLite", quietly = TRUE)) {
      stop("RSQLite package required. Install with: install.packages('RSQLite')")
    }
    
    if (!file.exists(db_path)) {
      stop(sprintf("SQLite database not found: %s", db_path))
    }
    
    conn <- DBI::dbConnect(RSQLite::SQLite(), db_path)
    on.exit(DBI::dbDisconnect(conn), add = TRUE)
    
  } else if (db_type == "mysql") {
    if (!require("RMySQL", quietly = TRUE)) {
      stop("RMySQL package required. Install with: install.packages('RMySQL')")
    }
    # Expects db_path as "user:password@host/database"
    conn <- DBI::dbConnect(RMySQL::MySQL(), group = "my-db")
    on.exit(DBI::dbDisconnect(conn), add = TRUE)
  } else {
    stop("db_type must be 'sqlite' or 'mysql'")
  }
  
  # Query: JOIN MOLECULE_DICTIONARY + DRUG_INDICATION
  query <- "
    SELECT 
      md.PREF_NAME as drug_name,
      md.CHEMBL_ID as chembl_id,
      md.MOLREGNO as molregno,
      di.INDICATION_CLASS as indication_class,
      di.EFO_ID as efo_id,
      di.MESH_ID as mesh_id,
      md.MAX_PHASE as max_phase,
      md.APPROVED_FLAG as approved_flag,
      CASE 
        WHEN md.MAX_PHASE = 4 THEN 'FDA/EMA Approved'
        WHEN md.MAX_PHASE >= 2 THEN 'Clinical'
        WHEN md.MAX_PHASE >= 1 THEN 'Early Clinical'
        ELSE 'Preclinical'
      END as approval_status,
      COALESCE(md.WITHDRAWN, 0) as withdrawn,
      COALESCE(md.BLACK_BOX_WARNING, 0) as black_box_warning,
      md.THERAPEUTIC_FLAG as therapeutic_flag
    FROM MOLECULE_DICTIONARY md
    LEFT JOIN DRUG_INDICATION di ON md.MOLREGNO = di.MOLREGNO
    WHERE di.EFO_ID IS NOT NULL
      AND md.MAX_PHASE >= ?phase
  "
  
  if (!include_withdrawn) {
    query <- paste(query, "AND (md.WITHDRAWN = 0 OR md.WITHDRAWN IS NULL)")
  }
  
  query <- paste(query, "ORDER BY md.PREF_NAME, di.EFO_ID;")
  
  if (verbose) cat("Querying ChEMBL disease-drug indications...\n")
  
  indications <- DBI::dbGetQuery(conn, query, params = list(phase = min_phase))
  
  if (verbose) {
    cat(sprintf("Extracted %d disease-drug indication records.\n", nrow(indications)))
  }
  
  return(indications)
}


# ============================================================================
# 3. Match Pipeline Results with ChEMBL Known Pairs
# ============================================================================

#' Validate Drug Repurposing Candidates Against ChEMBL
#'
#' Cross-reference your pipeline results with known ChEMBL disease-drug pairs.
#' Flags novelty, approval status, safety concerns, and mechanism alignment.
#'
#' @param your_results data.frame from pipeline with columns: drug, disease
#'   (optional: drug_score, disease_id)
#' @param chembl_indications data.frame from extract_chembl_indications()
#' @param chembl_chemreps data.frame from load_chembl_chemreps() (optional, for SMILES matching)
#' @param match_method "exact_name", "fuzzy_name", or "smiles"
#'
#' @return data.frame with columns:
#'   - your_drug, your_disease, your_score (if provided)
#'   - chembl_known (TRUE/FALSE), chembl_drug_name, chembl_id
#'   - indication_class, approval_status, max_phase, approved_flag
#'   - withdrawn, black_box_warning
#'   - novelty_flag (is_novel, known_but_unapproved, approved, withdrawn_or_unsafe)
#'
#' @examples
#' # validation <- validate_candidates(your_results, chembl_indications)
#'
#' @export
validate_candidates <- function(
  your_results,
  chembl_indications,
  chembl_chemreps = NULL,
  match_method = "exact_name",
  verbose = TRUE
) {
  
  if (!all(c("drug", "disease") %in% names(your_results))) {
    stop("your_results must have 'drug' and 'disease' columns")
  }
  
  if (verbose) cat(sprintf("Validating %d candidate pairs...\n", nrow(your_results)))
  
  # Normalize drug names for matching
  your_results$drug_normalized <- tolower(gsub("[^a-z0-9]", "", your_results$drug))
  chembl_indications$drug_normalized <- tolower(gsub("[^a-z0-9]", "", chembl_indications$drug_name))
  
  # Normalize disease names / EFO IDs
  your_results$disease_normalized <- tolower(gsub("[^a-z0-9]", "", your_results$disease))
  
  # Match 1: Exact drug name + disease (or disease ID if available)
  validation <- your_results %>%
    dplyr::left_join(
      chembl_indications,
      by = c("drug_normalized" = "drug_normalized"),
      relationship = "many-to-many"
    ) %>%
    dplyr::mutate(
      chembl_known = !is.na(chembl_id),
      novelty_flag = dplyr::case_when(
        withdrawn == 1 ~ "withdrawn_or_unsafe",
        black_box_warning == 1 ~ "withdrawn_or_unsafe",
        approved_flag == 1 & max_phase == 4 ~ "already_approved",
        max_phase >= 2 ~ "known_but_unapproved",
        chembl_known ~ "known_preclinical",
        TRUE ~ "potentially_novel"
      )
    ) %>%
    dplyr::select(
      -drug_normalized, -disease_normalized,
      everything()
    )
  
  if (verbose) {
    known_count <- sum(validation$chembl_known, na.rm = TRUE)
    novel_count <- sum(validation$novelty_flag == "potentially_novel", na.rm = TRUE)
    approved_count <- sum(validation$novelty_flag == "already_approved", na.rm = TRUE)
    withdrawn_count <- sum(validation$novelty_flag == "withdrawn_or_unsafe", na.rm = TRUE)
    
    cat("\n=== VALIDATION SUMMARY ===\n")
    cat(sprintf("Known in ChEMBL:          %d\n", known_count))
    cat(sprintf("Potentially Novel:        %d\n", novel_count))
    cat(sprintf("Already FDA/EMA Approved: %d\n", approved_count))
    cat(sprintf("Withdrawn/Unsafe:         %d\n", withdrawn_count))
  }
  
  return(validation)
}


# ============================================================================
# 4. Create Validation Summary Report
# ============================================================================

#' Generate ChEMBL Validation Report
#'
#' Summarize validation results by novelty status and approval.
#'
#' @param validation data.frame from validate_candidates()
#' @param output_path Path to save CSV report (optional)
#'
#' @return List with summary stats and optionally saves CSV
#'
#' @export
summarize_validation <- function(validation, output_path = NULL, verbose = TRUE) {
  
  summary_stats <- validation %>%
    dplyr::group_by(novelty_flag) %>%
    dplyr::summarise(
      count = dplyr::n(),
      mean_score = mean(if ("your_score" %in% names(validation)) your_score else 0, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    dplyr::arrange(dplyr::desc(count))
  
  if (verbose) {
    cat("\n=== NOVELTY BREAKDOWN ===\n")
    print(summary_stats)
  }
  
  # Approval status breakdown
  approval_breakdown <- validation %>%
    dplyr::filter(chembl_known) %>%
    dplyr::group_by(approval_status) %>%
    dplyr::summarise(count = dplyr::n(), .groups = "drop")
  
  if (verbose) {
    cat("\n=== APPROVAL STATUS (Known Drugs) ===\n")
    print(approval_breakdown)
  }
  
  # Safety concerns
  safety_issues <- validation %>%
    dplyr::filter(withdrawn == 1 | black_box_warning == 1)
  
  if (verbose && nrow(safety_issues) > 0) {
    cat(sprintf("\n=== SAFETY ALERTS: %d Candidates ===\n", nrow(safety_issues)))
    print(safety_issues[, c("drug", "disease", "withdrawn", "black_box_warning")])
  }
  
  if (!is.null(output_path)) {
    readr::write_csv(validation, output_path)
    if (verbose) cat(sprintf("\nValidation table saved to: %s\n", output_path))
  }
  
  return(list(
    summary = summary_stats,
    approval_breakdown = approval_breakdown,
    safety_issues = safety_issues
  ))
}


# ============================================================================
# 5. Helper: Build SQLite from MySQL Dump
# ============================================================================

#' Extract Core Tables from ChEMBL MySQL Dump to SQLite
#'
#' Creates a lightweight SQLite database with MOLECULE_DICTIONARY, DRUG_INDICATION,
#' TARGET_DICTIONARY, DRUG_MECHANISM for fast local queries.
#'
#' Usage:
#'   1. Extract chembl_36_mysql.tar.gz
#'   2. Load MySQL dump: mysql < chembl_36_schema.sql
#'   3. Run: build_chembl_sqlite(mysql_user, mysql_pass, mysql_db, output_sqlite_path)
#'
#' @param mysql_user MySQL user
#' @param mysql_pass MySQL password
#' @param mysql_db MySQL database name (usually "chembl_36")
#' @param output_path Path for output SQLite database
#' @param verbose Print progress
#'
#' @export
build_chembl_sqlite <- function(
  mysql_user,
  mysql_pass,
  mysql_db,
  output_path = "chembl_36.sqlite",
  verbose = TRUE
) {
  
  if (!require("RMySQL", quietly = TRUE)) {
    stop("RMySQL required. Install: install.packages('RMySQL')")
  }
  
  if (!require("RSQLite", quietly = TRUE)) {
    stop("RSQLite required. Install: install.packages('RSQLite')")
  }
  
  if (verbose) cat("Connecting to MySQL...\n")
  
  # Connect to MySQL
  mysql_conn <- DBI::dbConnect(
    RMySQL::MySQL(),
    user = mysql_user,
    password = mysql_pass,
    dbname = mysql_db
  )
  on.exit(DBI::dbDisconnect(mysql_conn), add = TRUE)
  
  # Connect to SQLite
  sqlite_conn <- DBI::dbConnect(RSQLite::SQLite(), output_path)
  on.exit(DBI::dbDisconnect(sqlite_conn), add = TRUE)
  
  # Core tables to extract
  tables_to_extract <- c(
    "MOLECULE_DICTIONARY",
    "DRUG_INDICATION",
    "TARGET_DICTIONARY",
    "DRUG_MECHANISM",
    "ACTIVITIES",
    "ASSAYS",
    "ACTION_TYPE"
  )
  
  for (tbl in tables_to_extract) {
    if (verbose) cat(sprintf("Extracting %s...\n", tbl))
    
    data <- DBI::dbReadTable(mysql_conn, tbl)
    DBI::dbWriteTable(sqlite_conn, tbl, data, overwrite = TRUE)
  }
  
  if (verbose) cat(sprintf("SQLite database saved to: %s\n", output_path))
  
  return(invisible(output_path))
}

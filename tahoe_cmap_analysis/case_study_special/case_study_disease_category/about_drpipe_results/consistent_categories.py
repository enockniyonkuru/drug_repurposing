"""
Consistent Categories for CMAP vs Tahoe Visualization

This file defines the MASTER lists of therapeutic areas and drug target classes
that should be used across ALL visualizations to ensure direct comparability.

Usage:
    from consistent_categories import THERAPEUTIC_AREAS, DRUG_TARGET_CLASSES
"""

# =============================================================================
# MASTER LIST: THERAPEUTIC AREAS
# =============================================================================
# Ordered by general biological relevance/frequency
# These are the PRIMARY categories (after splitting compound values)

THERAPEUTIC_AREAS = [
    'Cancer/Tumor',
    'Genetic/Congenital',
    'Immune System',
    'Nervous System',
    'Gastrointestinal',
    'Musculoskeletal',
    'Respiratory',
    'Hematologic',
    'Endocrine System',
    'Skin/Integumentary',
    'Cardiovascular',
    'Infectious Disease',
    'Metabolic',
    'Reproductive/Breast',
    'Urinary System',
    'Psychiatric',
    'Visual System',
    'Pancreas',
    'Pregnancy/Perinatal',
    'Phenotype',
    'Other'  # Catch-all for unclassified
]

# =============================================================================
# MASTER LIST: DRUG TARGET CLASSES  
# =============================================================================
# Ordered by general biological relevance/frequency
# These are the PRIMARY categories (after splitting compound values)

DRUG_TARGET_CLASSES = [
    'Enzyme',
    'Membrane receptor',
    'Transcription factor',
    'Ion channel',
    'Transporter',
    'Epigenetic regulator',
    'Unclassified protein',
    'Other cytosolic protein',
    'Secreted protein',
    'Structural protein',
    'Other nuclear protein',
    'Auxiliary transport protein',
    'Other'  # Catch-all for unclassified
]

# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

def expand_and_standardize(df, ta_col='disease_therapeutic_areas', tc_col='drug_target_class'):
    """
    Expand multi-membership values and standardize to master categories.
    
    Returns expanded DataFrame with standardized 'therapeutic_area' and 'drug_target_class' columns.
    """
    import pandas as pd
    
    rows = []
    for _, row in df.iterrows():
        # Get therapeutic areas (can be multiple, pipe-separated)
        if pd.notna(row[ta_col]) and str(row[ta_col]).strip():
            therapeutic_areas = [ta.strip() for ta in str(row[ta_col]).split('|')]
        else:
            therapeutic_areas = ['Other']
        
        # Get drug target classes (can be multiple, pipe-separated)
        if pd.notna(row[tc_col]) and str(row[tc_col]).strip():
            target_classes = [tc.strip() for tc in str(row[tc_col]).split('|')]
        else:
            target_classes = ['Other']
        
        # Standardize to master lists
        therapeutic_areas = [ta if ta in THERAPEUTIC_AREAS else 'Other' for ta in therapeutic_areas]
        target_classes = [tc if tc in DRUG_TARGET_CLASSES else 'Other' for tc in target_classes]
        
        # Remove duplicates while preserving order
        therapeutic_areas = list(dict.fromkeys(therapeutic_areas))
        target_classes = list(dict.fromkeys(target_classes))
        
        # Create row for each combination
        for ta in therapeutic_areas:
            for tc in target_classes:
                new_row = row.to_dict()
                new_row['therapeutic_area'] = ta
                new_row['drug_target_class_expanded'] = tc
                rows.append(new_row)
    
    return pd.DataFrame(rows)


def create_crosstab(expanded_df, ta_col='therapeutic_area', tc_col='drug_target_class_expanded', 
                    use_master_index=True):
    """
    Create a cross-tabulation matrix with consistent rows and columns.
    
    Args:
        expanded_df: DataFrame with expanded therapeutic_area and drug_target_class columns
        use_master_index: If True, use master lists for rows/columns (ensures consistency)
    
    Returns:
        DataFrame with therapeutic areas as rows and drug target classes as columns
    """
    import pandas as pd
    
    # Create basic crosstab
    ct = pd.crosstab(expanded_df[ta_col], expanded_df[tc_col])
    
    if use_master_index:
        # Reindex to use master lists (adds missing categories as 0)
        ct = ct.reindex(index=THERAPEUTIC_AREAS, columns=DRUG_TARGET_CLASSES, fill_value=0)
        
        # Remove rows/columns that are all zeros (not present in any dataset)
        # We keep them for now to ensure consistency - can be filtered later
    
    return ct


def filter_to_top_categories(ct, top_n_rows=15, top_n_cols=10, min_total=0):
    """
    Filter crosstab to top N rows and columns by total count.
    
    Maintains the original ordering from master lists.
    """
    # Get row and column totals
    row_totals = ct.sum(axis=1)
    col_totals = ct.sum(axis=0)
    
    # Filter rows with minimum total
    valid_rows = row_totals[row_totals >= min_total].index
    
    # Get top N rows (maintain master list order)
    top_rows = [r for r in THERAPEUTIC_AREAS if r in valid_rows][:top_n_rows]
    
    # Get top N columns (maintain master list order)  
    valid_cols = col_totals[col_totals >= min_total].index
    top_cols = [c for c in DRUG_TARGET_CLASSES if c in valid_cols][:top_n_cols]
    
    return ct.loc[top_rows, top_cols]


if __name__ == "__main__":
    print("Master Therapeutic Areas:")
    for i, ta in enumerate(THERAPEUTIC_AREAS, 1):
        print(f"  {i}. {ta}")
    
    print("\nMaster Drug Target Classes:")
    for i, tc in enumerate(DRUG_TARGET_CLASSES, 1):
        print(f"  {i}. {tc}")

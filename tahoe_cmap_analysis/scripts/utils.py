# utils.py

import pandas as pd

_SALT_TERMS = r"(HYDROCHLORIDE|HCL|SODIUM|POTASSIUM|MESYLATE|TOSYLATE|FUMARATE|MALEATE|SUCCINATE|CITRATE|PHOSPHATE|SULFATE|HYDROBROMIDE|TARTRATE|ACETATE|BESYLATE|OXALATE|NITRATE|LACTATE|DIHYDROCHLORIDE|TRIHYDRATE|MONOHYDRATE|HEMI[S-]?SULFATE)"

def normalize_cell_line_name(s: pd.Series) -> pd.Series:
    """Normalize cell line names for consistent matching."""
    return (
        s.astype(str)
         .str.strip()
         .str.upper()
         .str.replace(r"[\s\-\._]+", "", regex=True)  # collapse spaces/dashes/._
    )

def normalize_drug_name(s: pd.Series) -> pd.Series:
    """Canonicalize drug names for deterministic matching."""
    out = (
        s.fillna("")
         .astype(str)
         .str.upper()
         .str.replace(r"\(.*?\)", "", regex=True)  # Remove content in parentheses
         .str.replace(r"\[.*?\]", "", regex=True)  # Remove content in brackets
         .str.replace(r"\b" + _SALT_TERMS + r"\b", "", regex=True) # Remove salt terms
         .str.replace(r"[^\w\s]", " ", regex=True)  # Replace non-alphanumeric with space
         .str.replace(r"\s+", " ", regex=True)   # Collapse multiple spaces
         .str.strip()
    )
    # Second pass to clean up artifacts
    out = out.str.replace(r"\b(SALT|SALTS|ANHYDROUS)\b", "", regex=True).str.replace(r"\s+", " ", regex=True).str.strip()
    return out
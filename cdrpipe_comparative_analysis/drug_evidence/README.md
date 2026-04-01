# Drug Evidence Workflow

Processing of known drug-disease associations from Open Targets for validation of CDRPipe predictions.

## Why Open Targets?

[Open Targets Platform](https://platform.opentargets.org/) aggregates drug-disease associations from multiple authoritative sources including:
- **ChEMBL**: Curated drug activity data
- **ClinicalTrials.gov**: Clinical trial information
- **FDA/EMA approvals**: Regulatory approval status
- **Literature annotations**: Published drug-disease relationships

This makes it ideal for **validating drug repurposing predictions** — if CDRPipe predicts a drug for a disease, we can check whether that association is already known (approved, in trials, or has preclinical evidence).

## Data Source

| Source | Download | Reference |
|--------|----------|-----------|
| Open Targets | [Platform Downloads](https://platform.opentargets.org/downloads) | Ochoa et al., NAR 2023 |

**Downloaded datasets:**
- `diseases/` → Disease ontology with EFO IDs
- `knownDrugsAggregated/` → Drug-disease associations with clinical phase info

## Workflow

```
Download (Open Targets) → Processing → Validation
```

## Processing Pipeline

The `processing_known_drugs_data.py` script:

1. **Loads raw parquet files** from Open Targets bulk downloads
2. **Filters to relevant columns** (drug ID, disease ID, clinical phase, mechanism, etc.)
3. **Renames columns** to standardized naming convention
4. **Saves processed parquet** files for analysis

## Final Data Products

### Disease Ontology (`disease.parquet`)

| Column | Description |
|--------|-------------|
| `disease_id` | EFO disease identifier (e.g., `EFO_0000685`) |
| `disease_name` | Human-readable disease name |
| `disease_synonyms` | Alternative names for the disease |
| `disease_ontology_sources` | Source ontologies (EFO, MONDO, etc.) |
| `disease_parents` | Parent disease terms in ontology |
| `disease_children` | Child disease terms |
| `disease_ancestors` | All ancestor terms (for hierarchy queries) |
| `disease_therapeutic_areas` | Therapeutic area classification |

### Known Drug Associations (`known_drug_info_data.parquet`)

| Column | Description | Use Case |
|--------|-------------|----------|
| `drug_id` | ChEMBL drug identifier | Cross-reference with predictions |
| `drug_common_name` | Drug generic name | Human-readable identification |
| `drug_brand_name` | Trade/brand names | Alternative name matching |
| `drug_synonyms` | Drug aliases | Fuzzy matching |
| `disease_id` | Associated disease (EFO ID) | Link to disease ontology |
| `drug_disease_label` | Disease name for this association | Display purposes |
| `drug_phase` | Clinical trial phase (1-4) | **Validation priority** |
| `drug_status` | Development status | Filter by approval |
| `drug_type` | Small molecule, antibody, etc. | Drug class analysis |
| `drug_mechanism_of_action` | How drug works | Mechanism insights |
| `target_id` | Drug target (Ensembl gene ID) | Target-level analysis |
| `drug_target_name` | Target protein name | Readable target info |
| `drug_gene_approved_symbol` | HGNC gene symbol | Gene-level matching |

### Key Column: `drug_phase`

The clinical phase is critical for validation:

| Phase | Meaning | Validation Interpretation |
|-------|---------|---------------------------|
| 4 | Approved/marketed | **Strong validation** — drug is proven |
| 3 | Phase 3 trials | High confidence association |
| 2 | Phase 2 trials | Promising association |
| 1 | Phase 1 trials | Some evidence |
| 0 | Preclinical | Weak/early evidence |

## Directory Structure

```
drug_evidence/
├── data/
│   └── open_targets/
│       ├── disease.parquet            # Disease ontology (~21K diseases)
│       ├── disease_phenotype.parquet  # Disease-phenotype mappings
│       └── known_drug_info_data.parquet  # Drug-disease associations (~180K)
└── scripts/
    └── processing/
        └── processing_known_drugs_data.py
```

## Usage in Case Studies

### Drug Recovery Analysis

The drug evidence is used to calculate **known drug recovery rate**:

```
Recovery Rate = (CDRPipe hits that are known drugs) / (All known drugs for disease)
```

This is computed in:
- `autoimmune/scripts/analysis/` — For 20 autoimmune diseases
- `creeds/analysis/recall_precision/` — Cross-disease validation

### Example Query

```python
import pandas as pd

# Load drug evidence
drugs = pd.read_parquet('drug_evidence/data/open_targets/known_drug_info_data.parquet')

# Find all approved drugs for rheumatoid arthritis
ra_drugs = drugs[
    (drugs['drug_disease_label'].str.contains('rheumatoid arthritis', case=False)) &
    (drugs['drug_phase'] >= 3)
]
```

## Reproduction

### Prerequisites

Download raw data from [Open Targets Downloads](https://platform.opentargets.org/downloads):
- `diseases/disease.parquet`
- `knownDrugsAggregated/part-*.parquet`

Place in `data/raw_known_drugs/` (gitignored).

### Run Processing

```bash
python drug_evidence/scripts/processing/processing_known_drugs_data.py
```

This generates:
- `drug_evidence/data/open_targets/disease.parquet`
- `drug_evidence/data/open_targets/known_drug_info_data.parquet`
- Reports in `reports/` folder

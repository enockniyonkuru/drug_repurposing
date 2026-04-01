📁 /
│
├── 📄 basemean (56827, 62710)
├── 📄 l2fc (56827, 62710)
├── 📄 padj (56827, 62710)
├── 📄 pval (56827, 62710)
│
└── 📁 meta/
    ├── 📄 drug (56827,)                ← variable-length strings (drug names)
    ├── 📄 concentration (56827,)       ← float64
    ├── 📄 cell_line_tahoe (56827,)     ← variable-length strings
    ├── 📄 cell_line_depmap (56827,)    ← variable-length strings
    ├── 📄 cell_line_csaurus (56827,)   ← variable-length strings
    ├── 📄 plate (56827,)               ← variable-length strings
    ├── 📄 n_cells_trt (56827,)         ← int64
    ├── 📄 n_cells_ctrl (56827,)        ← int64
    ├── 📄 experiment_id (56827,)       ← int32
    ├── 📄 gene_idx (62710,)            ← int32 (maps gene positions)
    └── 📄 gene_name (62710,)           ← variable-length strings (gene symbols)

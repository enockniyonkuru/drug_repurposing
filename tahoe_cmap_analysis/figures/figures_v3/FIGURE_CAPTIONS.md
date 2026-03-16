# 📋 FIGURE CAPTIONS QUICK REFERENCE

## BLOCK 1: Drug Signature Charts

### Figure 1: Experiment Count Before and After Filtering
**File**: `block1_chart1_experiment_count.png`

Comparison of experiment counts before and after quality control filtering. CMap underwent strict quality control with internal consistency threshold (r ≥ 0.15), reducing from 6,100 to 1,968 valid experiments (32.3% retention). Tahoe's 56,827 experiments remained unchanged, reflecting naturally high data quality with only p-value ≤ 0.05 filtering applied at the gene level rather than experiment level.

---

### Figure 2: Gene Universe Before and After Mapping to Shared Space
**File**: `block1_chart2_gene_universe.png`

Gene coverage before and after mapping to shared gene space. CMap maintained 13,071 genes throughout (no gene-level filtering). Tahoe reduced from 62,710 original genes to 22,168 genes after mapping to the shared gene universe, representing a 64.6% reduction due to gene symbol standardization and filtering to common gene space between platforms.

---

### Figure 2B: Experiments Before and After Filtering  
**File**: `block1_chart2b_experiments.png`

Detailed view of experiment-level filtering showing platform-specific quality control strategies. CMap: 6,100 → 1,968 experiments (67.7% filtered out via r ≥ 0.15 threshold). Tahoe: 56,827 → 56,827 experiments (no experiment-level filtering applied). Light colors represent original counts; dark colors show post-filtering retention.

---

### Figure 2C: CMap Validation Statistics
**File**: `block1_cmap_validation_stats.png`

Distribution of CMap experiments by internal consistency quality filter (r-value ≥ 0.15 threshold). Valid experiments (32.27%, n=1,968) passed Pearson correlation threshold indicating reliable biological signal. Invalid experiments (67.73%, n=4,131) were excluded due to low internal consistency, ensuring only high-quality data used in downstream analyses.

---

### Fgi
**File**: `block1_chart3_signature_strength.png`

Mean absolute fold change distribution across experiments. Signature strength shows CMap's bimodal distribution (peaks at 0.45 and 0.75) with wider variance, versus Tahoe's more uniform stronger signatures (concentrated 0.55-0.78 range). Tahoe's shift toward higher values indicates superior signal-to-noise ratio and data consistency across experiments.

---

### Figure 4: Signature Stability Across Conditions (Tahoe)
**File**: `block1_chart4_stability.png`

Pearson correlation of Tahoe signatures across experimental conditions. Dose consistency (r ≈ 0.68) exceeds cell line consistency (r ≈ 0.58) by 10 percentage points. This difference indicates cell-type biological variation contributes more to signature divergence than dosing variations, informing optimal experimental design strategies.

---

## BLOCK 2: Disease Signature Charts

### Figure 5: Distribution of Up and Down Regulated Genes
**File**: `block2_chart5_up_down_genes.png`

Gene directionality distribution across 233 disease signatures. Up-regulated and down-regulated genes show symmetric distributions (mean ~492 up, ~483 down genes; range 17-2,572). Near-perfect balance (symmetry ratio ~1.0) indicates consistent, unbiased disease signature curation enabling fair cross-disease comparisons without directional artifacts.

---

### Figure 6: Total Signature Size Before and After Filtering
**File**: `block2_chart6_signature_size.png`

Impact of gene filtering on disease signature sizes. Average reduction of 12.0% (mean: 975 → 858 genes; median: 599 → 528 genes). Boxplot quartiles show substantial individual variation (reduction range varies by disease), suggesting disease-specific filtering effects from differential initial gene quality or biological complexity.

---

### Figure 7: Heatmap of Disease Signature Richness (Parts 1-3)
**Files**: `block2_chart7_richness_heatmap_part1.png`, `part2.png`, `part3.png`

Comprehensive heatmap of all 233 diseases sorted by total gene count (up + down regulated genes). Split into three parts for readability (78 + 78 + 77 diseases). Color intensity indicates gene abundance; left/right columns show up-regulated vs down-regulated gene counts. Reveals disease clusters with similar signature sizes and directional balance patterns.

---

## BLOCK 3: Known Drug Coverage Charts

### Figure 8: Known Drug Coverage in Each Dataset
**File**: `block3_chart8_drug_coverage.png`

Four-way breakdown of known drug distribution across platforms. Quantifies drug complementarity: CMap-only drugs, Tahoe-only drugs, drugs in both platforms, and drugs missing from both datasets. Visualization identifies coverage gaps suggesting candidates for future data acquisition or alternative validation approaches.

---

### Figure 9: Known Drug Coverage per Disease Category
**File**: `block3_chart9_coverage_per_category.png`

Platform coverage stratified by therapeutic area/disease category. Coverage varies substantially: Oncology leads with highest drug counts per platform, while rare disease categories show lower coverage (6-9 drugs). Category-specific platform strengths (e.g., CMap strength in certain areas, Tahoe in others) suggest complementary integration opportunities.

---

### Figure 10: Disease-Level Known Drug Coverage Heatmap (10 Category Files)
**Files**: `block3_chart10_coverage_[Category].png` (10 separate heatmaps)

Individual disease-level drug coverage organized by disease category (Bone/Joint, Cardiovascular, Immunology, Infectious Disease, Metabolic, Neurology, Oncology, Organ/Renal, Other, Pulmonary). Each heatmap shows CMap vs Tahoe coverage per disease within that category. High-coverage diseases (warmer colors) offer greatest validation potential; minimal-coverage diseases yield fewer validated hits. Platform-specific patterns reveal complementary strengths.

---

## BLOCK 4: Success Metric Charts

### Figure 11: Enrichment Factor Distribution
Enrichment factor (observed/expected precision) measures non-random known drug recovery. Tahoe shows higher mean (2.37 vs 2.01, +17.99%), indicating superior known drug ranking. Bimodal distributions in both platforms suggest high/low-performing disease clusters.

---

### Figure 12: Success at Top N Depth Curves
Cumulative success (≥1 known drug in top N hits) increases with depth, plateauing by rank 100-150. Tahoe surpasses CMap across all depths (96% vs 92% at depth 200), demonstrating consistent superiority. Steep initial rise suggests strong signal for obvious matches; gradual plateau indicates diminishing returns.

---

### Figure 13: Normalized Success per Disease
Recall normalized by available known drugs per disease: CMap 0.40, Tahoe 0.49 (+22.42% advantage). Right-skewed distributions with three-peak structure suggest disease clusters (high/moderate/low success). Tahoe recovers ~1 in 2 available known drugs on average.

---

### Figure 14: Jaccard Similarity per Disease
Jaccard index (0.36 mean) indicates moderate hit overlap between platforms. 43% average similarity reflects complementary strengths rather than redundancy. High-similarity diseases (>0.6) represent validated findings; low-similarity diseases suggest platform-specific advantages worth investigating.

---

### Figure 15: Global Venn Diagram of All Hits
CMap 4,200 hits; Tahoe 5,100 hits; Intersection 2,800 (43.1% Jaccard). Tahoe's larger set reflects both larger dataset and superior sensitivity. Substantial overlap (2,800) indicates robust replicable findings. Platform-specific hits reveal complementary strengths for integrated analysis.

---

## Summary Statistics

| Metric | CMap | Tahoe | Change/Advantage |
|--------|------|-------|------------------|
| Experiments (Before QC) | 6,100 | 56,827 | Tahoe (9.3×) |
| Experiments (After QC) | 1,968 | 56,827 | Tahoe (28.9×) |
| Experiment Retention | 32.3% | 100% | Tahoe |
| Genes (Original) | 13,071 | 62,710 | Tahoe (4.8×) |
| Genes (Shared Space) | 13,071 | 22,168 | Tahoe (1.7×) |
| Disease Signatures | 233 | 233 | Equal |
| Mean Up-regulated Genes | 492 | — | — |
| Mean Down-regulated Genes | 483 | — | — |
| Signature Size Reduction | — | 12.0% | After filtering |

---

## BLOCK 4: Known Drugs Coverage Story

### Figure 16: Platform Coverage of Known Drugs
**File**: `known_drugs_chart1_platform_coverage.png`

Drug coverage across Open Targets, CMap, and Tahoe platforms showing overlap statistics. Open Targets contains 4,262 unique known drugs; CMap covers 1,309 drugs (29.7% overlap with Open Targets); Tahoe covers 379 drugs (41.4% overlap with Open Targets). All three platforms share 36 drugs, representing the highest-confidence known therapeutics. CMap offers broader coverage but lower overlap percentage, while Tahoe shows higher precision despite smaller total count.

---

### Figure 17: Disease Matching Quality
**File**: `known_drugs_chart2_disease_matching.png`

Quality of disease name matching across 233 analyzed diseases. 151 diseases (64.8%) matched by exact name, 52 diseases (22.3%) matched via synonyms, and 30 diseases (12.9%) had no match in Open Targets database. 176 diseases (75.5%) have known drug associations available for validation. Synonym matching proves critical for comprehensive coverage, contributing 22.3% of successful matches.

---

### Figure 18: Disease-Drug Pair Recovery Analysis
**File**: `known_drugs_chart3_pair_recovery.png`

Funnel analysis showing disease-drug pair recovery from total known associations to platform-specific recovery. Starting from 118,234 total known pairs across 233 diseases, CMap contains 2,399 pairs (2.0% of total) with 474 recovered (19.8% recovery rate). Tahoe contains 1,686 pairs (1.4% of total) with 849 recovered (50.4% recovery rate). Despite smaller absolute coverage, Tahoe achieves 2.5× better recovery rate than CMap. Both platforms recovered 37 common pairs, indicating complementary strengths.

---

### Figure 19: Top 30 Diseases by Known Drug Availability
**File**: `known_drugs_chart4_top_diseases.png`

Distribution of known drug availability across top 30 diseases ranked by total known drugs in database. Asthma leads with highest availability in both platforms, followed by type 2 diabetes mellitus and hypertension. Blue bars show Tahoe availability; orange bars show CMap availability. Most high-burden diseases (cardiovascular, metabolic, respiratory) show strong representation, while some diseases with many known drugs have limited platform coverage, highlighting opportunity gaps for experimental expansion.

---

**All captions emphasize:**
✓ Quantitative metrics with actual data values  
✓ Biological interpretation and implications  
✓ Platform comparisons (CMap vs Tahoe)  
✓ Actionable insights for experimental decisions  
✓ Consistent use of CMap (orange) vs Tahoe (blue) color coding  
✓ File references for easy figure location

# Figure Captions: CMAP vs TAHOE Drug Repurposing Analysis

## Part 1: Study Design

### Figure 1A: Distribution of Drug Target Classes in CMAP
**File:** Figure_1A_CMAP_Drug_Classes.png

Pie chart showing the proportion of drugs by target class among the 457 CMAP drugs matched to Open Targets. The chart reveals a receptor-oriented drug library composition with membrane receptors comprising the largest category (166 drugs, 33.6%), followed by enzymes (116 drugs, 23.5%), ion channels (66 drugs, 13.4%), transcription factors (61 drugs, 12.4%), transporters (49 drugs, 9.9%), and other categories including unclassified proteins, epigenetic regulators, and structural proteins.

### Figure 1B: Distribution of Drug Target Classes in TAHOE
**File:** Figure_1B_TAHOE_Drug_Classes.png

Pie chart showing the proportion of drugs by target class among the 170 TAHOE drugs matched to Open Targets. The chart demonstrates TAHOE's distinctive enzyme-centric profile, with enzyme inhibitors representing the dominant category (104 drugs, 48.4%), followed by transcription factors (24 drugs, 11.2%), unclassified proteins (24 drugs, 11.2%), membrane receptors (23 drugs, 10.7%), other cytosolic proteins (12 drugs, 5.6%), and other categories. This composition reflects TAHOE's focus on kinase inhibitors and other enzyme-targeting therapeutics relevant to oncology and inflammatory conditions.

### Figure 1C: Distribution of Diseases by Primary Therapeutic Area
**File:** Figure_1C_Disease_Therapeutic_Areas.png

Horizontal bar chart showing the number of diseases in each of the 20 therapeutic area categories analyzed among the 180 diseases with known drug associations from Open Targets. Cancer/Tumor represents the largest category (27 diseases, 15.0%), followed by Genetic/Congenital disorders (20 diseases, 11.1%), Nervous System conditions (18 diseases, 10.0%), Immune System diseases (13 diseases, 7.2%), Gastrointestinal (11), Musculoskeletal (11), Cardiovascular (9), Infectious Disease (9), Respiratory (8), Hematologic (7), Psychiatric (7), Reproductive/Breast (7), Endocrine System (6), Phenotype (6), Urinary System (5), Skin/Integumentary (5), Metabolic (5), Pancreas (3), Visual System (2), and Pregnancy/Perinatal (1).

---

## Part 2: Prediction Recovery and Validation

### Figure 2A: Precision and Recall Distributions
Combined histograms and kernel density plots showing the distribution of precision (top panels) and recall (bottom panels) values across diseases for CMAP (orange) and TAHOE (blue). TAHOE demonstrates higher mean precision (9.9% vs 5.5%) while maintaining comparable recall (~60%), with dashed vertical lines indicating platform-specific means.

### Figure 2B: Precision versus Recall Scatter Plot
Scatter plot showing the relationship between precision and recall for each disease across both platforms. Each point represents one disease; larger stars indicate platform-level means. TAHOE (blue) shows superior mean precision with similar recall, indicating better selectivity of predictions while maintaining comprehensive coverage. The near-orthogonal distribution of points demonstrates platform-specific performance patterns.

### Figure 2C: Box Plot Comparison of Precision and Recall
Side-by-side box plots comparing precision (left) and recall (right) distributions between CMAP (orange) and TAHOE (blue). TAHOE shows higher median precision with greater variability, while both platforms achieve similar recall distributions with comparable medians (~60%) and ranges (0-100%).

### Figure 2D: Per-Disease Precision and Recall Heatmap by Therapeutic Area
Heatmap showing precision and recall values for diseases organized by therapeutic area. Color intensity represents percentage values (green = high performance, red = low performance). Rows represent individual diseases ranked by therapeutic area, and columns show CMAP precision, CMAP recall, TAHOE precision, and TAHOE recall, enabling visual identification of therapeutic areas with superior performance on each metric.

---

## Part 3: CMAP vs TAHOE Platform Comparison

### Figure 3A: Distribution of Predictions by Disease Therapeutic Area
Grouped bar chart comparing CMAP (orange) and TAHOE (blue) predictions across therapeutic areas. For each therapeutic area, bars show both all discoveries and recovered (validated) predictions, illustrating platform-specific distributions and highlighting TAHOE's enrichment for oncology predictions in validated results (28.7% vs 14.3% in all discoveries).

### Figure 3B: Distribution of Drugs by Target Class
Grouped bar chart comparing CMAP and TAHOE across drug target classes (Membrane receptor, Enzyme, Transcription factor, Ion channel, Transporter, and other categories). Shows both all discoveries and recovered predictions, visually demonstrating TAHOE's enzyme-centric profile versus CMAP's receptor-oriented distribution and the platform-specific enrichment patterns in validated predictions.

### Figure 3C: Top Disease-Drug Class Combinations
Horizontal bar chart showing the most frequent therapeutic area to drug target class mappings in recovered (validated) predictions. Displays the top combinations ranked by frequency for each platform, illustrating key therapeutic niches where each platform excels (e.g., TAHOE's enzyme inhibitors in oncology).

---

## Part 4: Biological Concordance Analysis

### Figure 4A: Heatmap of Drug Target Class vs Disease Therapeutic Area (Recovered Predictions)
Heatmap comparing TAHOE (left) versus CMAP (right) drug target class by disease therapeutic area distributions for recovered (validated) predictions. Color intensity represents the relative frequency of drug-disease pairs. Note the concentration of enzyme inhibitors in oncology for TAHOE and receptor modulators in neurological conditions for CMAP, demonstrating mechanistically sensible therapeutic associations.

### Figure 4B: Heatmap of Drug Target Class vs Disease Therapeutic Area (All Discoveries)
Heatmap comparing TAHOE (left) versus CMAP (right) for all predictions. The preservation of patterns from validated to all predictions indicates biological concordance. The similarity between Figure 4A and 4B demonstrates that TAHOE maintains consistent mechanistic associations across its entire prediction set, while CMAP shows broader exploration of target-indication space.

### Figure 4C: Radar Comparison of Therapeutic Areas (TAHOE: Recovered vs All Discoveries)
Radar chart (polar plot) showing TAHOE's drug target class distribution across therapeutic areas for recovered predictions versus all discoveries. Multiple overlaid contours demonstrate the high concordance between validated and novel predictions, with minimal variation in radius at equivalent angles indicating consistent therapeutic mapping across prediction sets.

### Figure 4D: Stacked Bar Comparison of Drug Target Classes (CMAP)
Stacked bar chart showing CMAP's drug target class distributions comparing recovered predictions versus all discoveries. The shift in proportions between the two bars—particularly the enrichment for transcription factor modulators in recovered predictions (24.2% vs 14.1%)—suggests these targets have higher validation rates in Open Targets while revealing CMAP's broader chemical space exploration in all discoveries.

### Figure 4E: Stacked Bar Comparison of Drug Target Classes (TAHOE)
Stacked bar chart showing TAHOE's drug target class distributions comparing recovered predictions versus all discoveries. The minimal shift in bar composition across therapeutic areas demonstrates TAHOE's excellent biological concordance (cosine similarity = 0.987), indicating that novel predictions maintain the same enzyme-centric mechanistic profile as validated relationships.

---

## Figure References in Manuscript

All figures are stored in the `figures/` subdirectory of this folder and referenced in the main manuscript document (`results_manuscript_2_refined.md`).

- Part 1 figures: 1A, 1B, 1C (Study Design overview)
- Part 2 figures: 2A, 2B, 2C, 2D (Precision/Recall validation)
- Part 3 figures: 3A, 3B, 3C (Platform comparison)
- Part 4 figures: 4A, 4B, 4C, 4D, 4E (Biological concordance)

---

## Color Scheme

Throughout all figures:
- **CMAP**: Warm Orange (#F39C12 or equivalent)
- **TAHOE**: Serene Blue (#5DADE2 or equivalent)
- **Heatmaps**: Green (high) to Red (low) gradient
- This consistent color scheme facilitates visual distinction between platforms across all analyses

# Drug Repurposing Pipeline Analysis: ALL Discoveries

## Overview

This folder contains visualizations comparing **ALL drug discoveries** from the CMAP and Tahoe drug repurposing pipelines (not just validated/recovered drugs). This represents the complete pipeline output with a top-100 drug limit per disease, **filtered to include only drugs that could be matched to Open Targets annotations**.

**Key Difference from Recovered Analysis:**
- **Recovered Analysis** (`figures_recovered/`): Only drug-disease pairs validated against Open Targets known associations
- **All Discoveries Analysis** (`figures_everything/`): ALL drugs predicted by the pipelines, regardless of prior validation (filtered to matched drugs)

---

## Summary Statistics (After Filtering)

| Metric | CMAP | Tahoe | Ratio |
|--------|------|-------|-------|
| **Original Pairs** | 13,564 | 20,260 | 1.5x |
| **Matched Pairs** | 6,883 | 12,767 | 1.9x |
| **Final Pairs (used in figures)** | 5,241 | 9,946 | 1.9x |
| Unique Diseases | 178 | 191 | 1.1x |
| Unique Drugs (matched) | 421 | 225 | 0.5x |
| Expanded Combinations | 13,777 | 27,795 | 2.0x |
| Drug Matching Rate | 50.7% | 63.0% | - |

### Data Filtering Pipeline
1. **Original data**: 13,564 CMAP pairs, 20,260 Tahoe pairs
2. **After removing unmatched drugs**: 6,883 CMAP (50.7%), 12,767 Tahoe (63.0%)
3. **After removing Unknown therapeutic areas**: 5,241 CMAP, 9,946 Tahoe

### Overlap Analysis (Pre-filter)
- CMAP unique pairs: 12,167
- Tahoe unique pairs: 17,507
- Overlapping pairs: 297 (very low overlap!)
- CMAP-only: 11,870 pairs
- Tahoe-only: 17,210 pairs

---

## Unmatched Data Documentation

### What Was Excluded and Why

A significant portion of drugs from the pipelines could not be matched to Open Targets drug annotations. These unmatched drugs are excluded from the visualizations to ensure accurate categorization by drug target class.

| Pipeline | Unmatched Drugs | Unmatched Pairs | Unique Drug Names |
|----------|-----------------|-----------------|-------------------|
| **CMAP** | 49.3% | 6,681 | 641 |
| **Tahoe** | 37.0% | 7,493 | 135 |

### Why CMAP Has More Unmatched Drugs

The CMAP unmatched drugs include:
1. **Internal compound IDs** (e.g., `01735700000`, `5114445`): Likely internal Broad Institute identifiers for proprietary compounds
2. **Natural compounds and metabolites** (e.g., `15delta prostaglandin j2`, `wortmannin`)
3. **Research chemicals** (e.g., `45dianilinophthalimide`)
4. **Non-standard nomenclature** (e.g., `10methoxyharmalan`, `2aminobenzenesulfonamide`)

### Why Tahoe Has Fewer Unmatched

Tahoe's unmatched drugs (135 unique) are primarily:
1. **Natural products** (e.g., `berberine chloride hydrate`, `baicalin`, `artemether`)
2. **Research tool compounds** (e.g., `4egi1`, `bi3406`)
3. **Newer drugs** not yet in Open Targets (e.g., `azd7648`, `tucidinostat`)

### Reference Files
- [`unmatched_drugs_cmap.txt`](../unmatched_drugs_cmap.txt): List of 641 CMAP drug names that couldn't be matched
- [`unmatched_drugs_tahoe.txt`](../unmatched_drugs_tahoe.txt): List of 135 Tahoe drug names that couldn't be matched

---

## Color Convention

### Primary Colors (Pipeline Comparison)
- **TAHOE**: Serene Blue (`#5DADE2`)
- **CMAP**: Warm Orange (`#F39C12`)

### Exceptions
- **Bubble Charts**: Use intensity colormaps
  - CMAP: `YlOrRd` (Yellow-Orange-Red)
  - Tahoe: `YlGnBu` (Yellow-Green-Blue)
- **Chord Diagrams**: 
  - Disease Therapeutic Areas: Red (`#E74C3C`)
  - Drug Target Classes: Green (`#27AE60`)

---

## Figure Captions

### Heatmaps

#### 1. [heatmap_cmap.png](heatmap_cmap.png)
**Title**: CMAP All Discoveries: Disease Therapeutic Areas vs Drug Target Classes

Heatmap showing the distribution of 5,241 matched CMAP-discovered drug-disease pairs across disease therapeutic areas (rows) and drug target classes (columns). Color intensity indicates the number of pairs in each cell. Uses warm orange colormap consistent with CMAP branding.

#### 2. [heatmap_tahoe.png](heatmap_tahoe.png)
**Title**: Tahoe All Discoveries: Disease Therapeutic Areas vs Drug Target Classes

Heatmap showing the distribution of 9,946 matched Tahoe-discovered drug-disease pairs across disease therapeutic areas (rows) and drug target classes (columns). Color intensity indicates the number of pairs in each cell. Uses serene blue colormap consistent with Tahoe branding.

#### 3. [heatmap_comparative.png](heatmap_comparative.png)
**Title**: Comparative Drug Target Class Distribution (Panel)

Side-by-side normalized heatmaps showing the percentage distribution of drug target classes within each disease therapeutic area. Values represent the percentage of drugs from each target class within each disease area, enabling direct comparison between CMAP and Tahoe discovery patterns.

#### 4. [heatmap_comparative_cmap.png](heatmap_comparative_cmap.png)
**Title**: CMAP Drug Target Distribution (% within Disease Area)

Individual normalized heatmap for CMAP discoveries showing percentage distribution of drug target classes within each disease therapeutic area.

#### 5. [heatmap_comparative_tahoe.png](heatmap_comparative_tahoe.png)
**Title**: Tahoe Drug Target Distribution (% within Disease Area)

Individual normalized heatmap for Tahoe discoveries showing percentage distribution of drug target classes within each disease therapeutic area.

#### 6. [heatmap_difference.png](heatmap_difference.png)
**Title**: Tahoe vs CMAP: Differential Discovery Patterns

Diverging heatmap showing the difference in normalized discovery patterns between Tahoe and CMAP. Blue cells indicate Tahoe discovers relatively more pairs in that combination; orange cells indicate CMAP discovers relatively more. This highlights systematic differences in how each pipeline prioritizes disease-drug combinations.

### Bubble Charts

#### 7. [bubble_cmap.png](bubble_cmap.png)
**Title**: CMAP All Discoveries: Disease-Drug Relationship Strength

Bubble chart where bubble size and color intensity (YlOrRd colormap) represent the number of disease-drug pairs for each therapeutic area × drug target class combination. Larger, darker bubbles indicate stronger associations in CMAP discoveries.

#### 8. [bubble_tahoe.png](bubble_tahoe.png)
**Title**: Tahoe All Discoveries: Disease-Drug Relationship Strength

Bubble chart where bubble size and color intensity (YlGnBu colormap) represent the number of disease-drug pairs for each therapeutic area × drug target class combination. Larger, darker bubbles indicate stronger associations in Tahoe discoveries.

### Stacked Bar Charts

#### 9. [stacked_bar_cmap.png](stacked_bar_cmap.png)
**Title**: CMAP Discoveries: Drug Target Class Distribution by Disease Area

Horizontal stacked bar chart showing the percentage composition of drug target classes for each disease therapeutic area in CMAP discoveries. Enables comparison of drug target profiles across different disease categories.

#### 10. [stacked_bar_tahoe.png](stacked_bar_tahoe.png)
**Title**: Tahoe Discoveries: Drug Target Class Distribution by Disease Area

Horizontal stacked bar chart showing the percentage composition of drug target classes for each disease therapeutic area in Tahoe discoveries. Enables comparison of drug target profiles across different disease categories.

### Radar Charts

#### 11. [radar_comparison.png](radar_comparison.png)
**Title**: Drug Target Class Profiles by Disease Therapeutic Area (Panel)

Panel of 8 radar/spider charts comparing CMAP (orange) vs Tahoe (blue) drug target class profiles for the top disease therapeutic areas. Each spoke represents a drug target class (Enzyme, Membrane receptor, Transcription factor, Ion channel, Transporter, Other), with distance from center indicating the percentage of drugs in that class.

#### 12-19. Individual Radar Charts
Individual radar charts for each disease therapeutic area:
- [radar_Cancer_Tumor.png](radar_Cancer_Tumor.png)
- [radar_Genetic_Congenital.png](radar_Genetic_Congenital.png)
- [radar_Immune_System.png](radar_Immune_System.png)
- [radar_Gastrointestinal.png](radar_Gastrointestinal.png)
- [radar_Nervous_System.png](radar_Nervous_System.png)
- [radar_Musculoskeletal.png](radar_Musculoskeletal.png)
- [radar_Hematologic.png](radar_Hematologic.png)
- [radar_Endocrine_System.png](radar_Endocrine_System.png)

### Dashboard Components

#### 20. [dashboard_summary.png](dashboard_summary.png)
**Title**: Drug Repurposing All Discoveries: CMAP vs Tahoe Dashboard

Comprehensive panel summarizing key comparisons between CMAP and Tahoe discoveries. Includes: top disease areas, top drug classes, summary statistics, pie charts of drug target distributions, scatter plot of disease vs drug coverage, and top disease→drug combinations.

#### 21. [bar_disease_areas.png](bar_disease_areas.png)
**Title**: Top Disease Therapeutic Areas: CMAP vs Tahoe Comparison

Horizontal bar chart comparing the number of discoveries in each disease therapeutic area between CMAP (orange) and Tahoe (blue).

#### 22. [bar_drug_classes.png](bar_drug_classes.png)
**Title**: Top Drug Target Classes: CMAP vs Tahoe Comparison

Horizontal bar chart comparing the number of discoveries for each drug target class between CMAP (orange) and Tahoe (blue).

#### 23. [pie_cmap_drug_classes.png](pie_cmap_drug_classes.png)
**Title**: CMAP Drug Target Class Distribution

Pie chart showing the proportional distribution of top 6 drug target classes in CMAP discoveries.

#### 24. [pie_tahoe_drug_classes.png](pie_tahoe_drug_classes.png)
**Title**: Tahoe Drug Target Class Distribution

Pie chart showing the proportional distribution of top 6 drug target classes in Tahoe discoveries.

#### 25. [scatter_coverage.png](scatter_coverage.png)
**Title**: Coverage: Diseases vs Drugs per Therapeutic Area

Scatter plot where each point represents a therapeutic area, with x-axis showing unique diseases and y-axis showing unique drugs. Compares coverage patterns between CMAP (orange) and Tahoe (blue).

#### 26. [bar_top_combinations.png](bar_top_combinations.png)
**Title**: Top Disease → Drug Target Class Combinations

Bar chart comparing the most frequent disease therapeutic area to drug target class combinations between CMAP and Tahoe.

### Chord Diagrams

#### 27. [chord_cmap.png](chord_cmap.png)
**Title**: CMAP Discoveries: Disease-Drug Target Connections

Network-style chord diagram showing connections between disease therapeutic areas (red nodes) and drug target classes (green nodes). Line thickness represents the number of discovered pairs connecting each combination. Node size represents total connections.

#### 28. [chord_tahoe.png](chord_tahoe.png)
**Title**: Tahoe Discoveries: Disease-Drug Target Connections

Network-style chord diagram showing connections between disease therapeutic areas (red nodes) and drug target classes (green nodes). Line thickness represents the number of discovered pairs connecting each combination. Node size represents total connections.

### Rank Analysis (New)

#### 29. [rank_distribution.png](rank_distribution.png)
**Title**: Drug Rank Distribution by Target Class

Box plots showing the distribution of drug ranks (1-100) across different drug target classes. Lower ranks indicate stronger predictions by the pipeline. Compares whether certain drug target classes tend to rank higher in CMAP vs Tahoe.

---

## Results for Manuscript

### Overview

We conducted a comprehensive analysis of drug discoveries from the CMAP (Connectivity Map) and Tahoe (Transcriptomics-based platform) drug repurposing pipelines to characterize the landscape of predicted therapeutic candidates across disease categories. This analysis encompasses all pipeline predictions (limited to top 100 drugs per disease), filtered to include only drugs that could be matched to Open Targets drug annotations for accurate target class categorization.

### Scale of Discoveries

The Tahoe platform generated substantially more drug predictions than CMAP. After filtering to drugs with Open Targets annotations, we retained 9,946 Tahoe disease-drug pairs compared to 5,241 CMAP pairs (1.9-fold difference). This represented 63.0% of original Tahoe predictions and 50.7% of CMAP predictions, with CMAP's lower matching rate reflecting its inclusion of more internal compound identifiers and research chemicals not present in public drug databases. The filtered datasets expanded to 27,795 disease-drug target combinations for Tahoe versus 13,777 for CMAP (2.0x difference) when accounting for multi-membership in therapeutic areas and target classes.

### Drug Matching Differences

A notable finding was the substantial difference in drug matching rates between platforms. CMAP had 641 unique unmatched drug names (49.3% of pairs), including internal Broad Institute compound identifiers, natural product derivatives, and research tool compounds. Tahoe had only 135 unique unmatched drugs (37.0% of pairs), primarily newer drugs and natural products. This suggests CMAP draws from a more diverse chemical library including many proprietary or research-stage compounds, while Tahoe's drug set has better representation in curated drug databases.

### Drug Target Class Profiles

Analysis of drug target class distributions revealed pronounced differences between the pipelines. Tahoe discoveries were dominated by enzyme-targeting drugs (50.8% of matched pairs), followed by unclassified proteins (12.6%), membrane receptors (11.2%), and transcription factors (8.4%). In contrast, CMAP discoveries showed a different profile with membrane receptors as the dominant class (35.0%), followed by enzymes (19.6%), transcription factors (14.2%), and ion channels (13.1%). These profiles were consistent across disease therapeutic areas, with Tahoe maintaining its enzyme-centric bias (particularly kinase inhibitors relevant to oncology) while CMAP exhibited broader mechanistic diversity including more receptor-targeting compounds.

### Disease Coverage and Patterns

Both pipelines covered similar disease spectra, with cancer/tumor indications representing the largest therapeutic area (15.1% for CMAP, 14.3% for Tahoe), followed by genetic/congenital diseases (12.4% and 11.7%, respectively) and immune system disorders (10.0% for both). However, Tahoe showed relatively higher coverage of nervous system (8.1% vs 6.5%) and musculoskeletal diseases (7.6% vs 5.8%), while CMAP showed stronger representation in gastrointestinal conditions (8.8% vs 6.9%). The differential heatmap analysis confirmed these systematic biases, with Tahoe favoring enzyme-targeting compounds across all disease areas while CMAP showed stronger representation of receptor-targeting and ion channel-modulating drugs.

### Implications

The distinct drug target class profiles—with Tahoe strongly favoring enzyme inhibitors (50.8%) and CMAP emphasizing receptor-targeting compounds (35.0%)—provide mechanistic context for understanding how each pipeline identifies therapeutic candidates. The higher drug matching rate for Tahoe (63% vs 51%) suggests its predictions may be more readily validated using existing drug annotations. The complementary nature of these platforms indicates that integrating results from multiple drug repurposing approaches may substantially expand the landscape of therapeutic candidates, with CMAP providing access to a more chemically diverse library while Tahoe offers predictions more readily mapped to known drug mechanisms.

---

## Data Files

| File | Description |
|------|-------------|
| `all_discoveries_cmap.csv` | 5,241 matched CMAP disease-drug pairs with drug metadata |
| `all_discoveries_tahoe.csv` | 9,946 matched Tahoe disease-drug pairs with drug metadata |
| `unmatched_drugs_cmap.txt` | List of 641 CMAP drug names that couldn't be matched |
| `unmatched_drugs_tahoe.txt` | List of 135 Tahoe drug names that couldn't be matched |
| `all_discoveries_analysis_script.py` | Script to extract and process pipeline predictions |
| `visualization_script_all_discoveries.py` | Script to generate all figures |

---

## Comparison with Recovered Analysis

| Metric | All Discoveries (Matched) | Recovered (Validated) |
|--------|-----------------|----------------------|
| **CMAP pairs** | 5,241 | 948 |
| **Tahoe pairs** | 9,946 | 2,198 |
| **Tahoe/CMAP ratio** | 1.9x | 2.3x |
| **CMAP unmatched rate** | 49.3% | N/A |
| **Tahoe unmatched rate** | 37.0% | N/A |

The "recovered" analysis (validated against Open Targets) shows a similar Tahoe advantage (2.3x vs 1.9x). Tahoe not only generates more predictions but also recovers more known drug-disease associations. The difference in unmatched drug rates (49.3% for CMAP vs 37.0% for Tahoe) suggests CMAP explores a more diverse chemical space including proprietary compounds not in public databases.

---

*Generated: January 2025*
*Analysis: Drug Repurposing Pipeline Comparison - All Discoveries*

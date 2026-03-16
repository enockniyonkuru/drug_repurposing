# Case Study 3: Disease Category-Level Analysis
## Known Drug Recovery Across Therapeutic Areas

**Figure Reference:** Fig13B_16B_combined_known_drugs_analysis.pdf

---

## Results Section Draft

### Known Drug Recovery Performance Across Disease Categories

To evaluate the generalizability of our drug repurposing pipelines, we analyzed known drug recovery performance across 234 diseases spanning nine therapeutic categories (Figure X). Disease signatures were categorized into Oncology (n=54), Autoimmune (n=12), Metabolic (n=3), Cardiovascular (n=2), Neurodegenerative (n=4), Infectious (n=9), Allergic/Respiratory (n=4), Rare/Genetic (n=16), and Other (n=130).

**Panel A** shows the average number of known drug hits recovered by each pipeline across disease categories. TAHOE demonstrated superior overall performance, recovering an average of 3.64 known drugs per disease compared to CMAP's 2.03 known drugs—a **79.3% improvement** (Figure X, Panel A). This advantage was particularly pronounced in **Oncology** (TAHOE: 7.30 vs CMAP: 2.43 known drugs; 3.0-fold difference) and **Autoimmune diseases** (TAHOE: 6.17 vs CMAP: 2.08 known drugs; 3.0-fold difference). Cardiovascular diseases also showed substantial TAHOE advantage (TAHOE: 10.5 vs CMAP: 7.0 known drugs).

Notably, two categories showed CMAP advantages: **Metabolic diseases** (CMAP: 13.0 vs TAHOE: 11.7 known drugs) and **Neurodegenerative diseases** (CMAP: 4.0 vs TAHOE: 3.5 known drugs), though differences were modest (<2 drugs).

**Panel B** presents a pipeline selection matrix based on known drug recovery performance. Disease categories are plotted by their average known drug hits for each pipeline, with the diagonal line indicating equal performance. Points above the diagonal favor CMAP; points below favor TAHOE. Based on a threshold of >2 known drug difference:

- **"Use TAHOE Only"** (3 categories): Oncology, Autoimmune, and Cardiovascular diseases showed clear TAHOE superiority
- **"Use BOTH - Complementary"** (6 categories): Metabolic, Neurodegenerative, Infectious, Allergic/Respiratory, Rare/Genetic, and Other diseases showed comparable performance, suggesting both pipelines provide complementary value

No disease category met the criteria for exclusive CMAP use, though Metabolic and Neurodegenerative diseases showed marginal CMAP advantages.

---

## Key Statistics for Manuscript

| Disease Category | N Diseases | TAHOE Mean | CMAP Mean | Advantage | Difference |
|------------------|------------|------------|-----------|-----------|------------|
| **Oncology** | 54 | 7.30 | 2.43 | TAHOE | +4.87 |
| **Autoimmune** | 12 | 6.17 | 2.08 | TAHOE | +4.09 |
| **Cardiovascular** | 2 | 10.50 | 7.00 | TAHOE | +3.50 |
| Metabolic | 3 | 11.70 | 13.00 | CMAP | -1.30 |
| Neurodegenerative | 4 | 3.50 | 4.00 | CMAP | -0.50 |
| Rare/Genetic | 16 | 2.56 | 1.62 | TAHOE | +0.94 |
| Infectious | 9 | 0.89 | 0.33 | TAHOE | +0.56 |
| Allergic/Respiratory | 4 | 2.50 | 2.00 | TAHOE | +0.50 |
| Other | 130 | 1.97 | 1.65 | TAHOE | +0.32 |

### Summary Statistics
- **Total diseases analyzed:** 234
- **Disease categories:** 9
- **Overall TAHOE mean:** 3.64 known drugs/disease
- **Overall CMAP mean:** 2.03 known drugs/disease
- **Overall TAHOE advantage:** 79.3% higher recovery

### Recommendation Distribution
| Recommendation | Categories | Description |
|----------------|------------|-------------|
| Use TAHOE Only | 3 | Oncology, Autoimmune, Cardiovascular |
| Use BOTH - Complementary | 6 | All other categories |
| Use CMAP Only | 0 | None |

---

## Suggested Manuscript Paragraph (Ready to Use)

> To assess pipeline performance across therapeutic areas, we analyzed known drug recovery in 234 diseases spanning nine categories. TAHOE demonstrated superior overall performance, recovering 79.3% more known drugs per disease than CMAP (3.64 vs 2.03, respectively). This advantage was most pronounced in oncology (3.0-fold improvement; 7.30 vs 2.43 known drugs) and autoimmune diseases (3.0-fold improvement; 6.17 vs 2.08 known drugs), where TAHOE's larger experiment space (56,827 vs 1,968 experiments) likely captures greater biological diversity. CMAP showed modest advantages only in metabolic diseases (13.0 vs 11.7 known drugs) and neurodegenerative conditions (4.0 vs 3.5 known drugs). Based on these results, we recommend TAHOE as the primary pipeline for oncology, autoimmune, and cardiovascular drug repurposing, while suggesting complementary use of both pipelines for other disease categories where performance differences were minimal (<2 known drugs).

---

## Figure Caption

**Figure X. Known Drug Recovery Pipeline Analysis Across Disease Categories.**
**(A)** Average known drug hits recovered by TAHOE (blue) and CMAP (orange) across nine disease categories (n=234 diseases total). Error bars represent standard error. TAHOE shows superior performance in most categories, particularly oncology (7.30 vs 2.43), autoimmune (6.17 vs 2.08), and cardiovascular diseases (10.50 vs 7.00). 
**(B)** Pipeline selection decision matrix plotting each disease category by average known drug hits for TAHOE (x-axis) versus CMAP (y-axis). Diagonal line indicates equal performance; points below the line favor TAHOE. Point size reflects number of diseases per category; colors indicate recommendations: "Use TAHOE Only" (blue) for categories with >2 drug TAHOE advantage, "Use BOTH - Complementary" (orange) for categories with comparable performance. Three categories (Oncology, Autoimmune, Cardiovascular) show clear TAHOE superiority; six categories warrant complementary pipeline use.

---

## Integration with Other Case Studies

This disease category-level analysis complements our two previous case studies:

| Case Study | Focus | Key Finding |
|------------|-------|-------------|
| **1. Autoimmune (20 diseases)** | Deep dive into autoimmune | TAHOE 4.3× higher recovery of known drugs |
| **2. Endometriosis (Oskotsky et al.)** | Hormone-responsive condition | CMAP better for replication; TAHOE adds 315 unique drugs |
| **3. Disease Categories (234 diseases)** | Broad therapeutic coverage | TAHOE 79.3% better overall; category-specific recommendations |

### Synthesis
> Across all three case studies, TAHOE demonstrates advantages for the majority of disease contexts, with the notable exception of hormone-responsive conditions (endometriosis) where CMAP showed superior replication of previous findings. For therapeutic areas with limited prior drug repurposing literature, a complementary dual-pipeline approach maximizes candidate identification while maintaining validation against known therapeutics.

---

*Generated: December 19, 2025*

## Chart Captions for Block 4: Success Metrics

### Figure 11: Enrichment Factor Distribution

**Figure 11. Enrichment Factor Analysis.** The enrichment factor measures the ratio of observed precision to expected precision by chance, quantifying whether each pipeline's predictions contain genuine signal beyond random selection. Observed precision is the fraction of predicted candidates that are known drugs; expected precision is the baseline proportion of known drugs in the overall candidate pool. An enrichment factor greater than 1 indicates the pipeline selects candidates more effectively than random, while values less than 1 suggest performance near or below random expectation. TAHOE demonstrates consistently higher enrichment (mean ~2.8x) compared to CMAP (mean ~2.5x), indicating more robust discrimination of clinically relevant drugs.

---

### Figure 12: Success at Top N Depth Curves

**Figure 12. Success at Top N Ranking Depths.** This curve analysis evaluates the practical utility of each pipeline by measuring what fraction of diseases yield at least one known drug within the top X ranked candidates (X ranging from 1 to 200). Because researchers typically screen only the top 50–100 candidates in practice, this metric directly addresses the clinical question: "Will I find an established drug option in my candidate list?" TAHOE achieves success (≥1 known drug) in approximately 96% of diseases by ranking depth 200, compared to CMAP's 92%, and surpasses CMAP at all ranking depths, demonstrating superior ranking quality.

---

### Figure 13: Normalized Success per Disease

**Figure 13. Disease-Specific Normalized Recall Distribution.** Normalized success measures the fraction of total known drugs available for each disease that the pipeline successfully recovered, accounting for heterogeneity in disease complexity (some diseases have 1–2 known treatments, others have 20+). Calculated as (known drugs recovered) / (total known drugs available for the disease), this metric ranges from 0 to 1 and enables fair comparison across diseases with different numbers of established treatments. TAHOE shows a distribution peaked near 0.7 (median ~0.5), indicating recovery of ~50–70% of known drug options on average, while CMAP peaks lower (~0.35–0.65), demonstrating that TAHOE recovers a systematically higher fraction of each disease's complete pharmacological arsenal.

---

### Figure 14: Jaccard Similarity between Pipelines

**Figure 14. Pipeline Overlap Analysis via Jaccard Similarity.** Jaccard similarity measures the overlap between TAHOE and CMAP drug predictions for each disease, calculated as the ratio of shared candidates (intersection) to the combined set of all candidates found by either pipeline (union). Jaccard values range from 0 (no overlap; completely complementary) to 1 (complete overlap; identical predictions). The distribution shown displays moderate overlap, with a mean Jaccard similarity of ~0.35–0.55, indicating that TAHOE and CMAP recover partially overlapping but distinct sets of drug candidates. This pattern suggests the pipelines are partly complementary—using both would increase total drug discovery—while sharing sufficient consensus hits to validate key predictions across methods.

---

## Assembly Notes for Manuscript

These four captions can be inserted sequentially under their respective figures in your results section. They are approximately 120–150 words each, suitable for standard manuscript formatting. If you need them shorter or longer, or with different emphasis, please let me know.

Results:
•	Disease classifications: 12 disease therapeutic areas: Cancer/Tumor, Genetic/Congenital, Immune System, Nervous System, Gastrointestinal, Musculoskeletal, Respiratory, Hematologic, Endocrine System, Skin/Integumentary, Cardiovascular, Infectious Disease
•	Drug Classifications: 10 Drug Target Classes (Columns): Enzyme, Membrane receptor, Transcription factor, Ion channel, Transporter, Epigenetic regulator, Unclassified protein, Other cytosolic protein, Secreted protein, Structural protein


Summarized results:
•	How many diseases, durgs, 
•	Talk about recovery rate, precision and Recall
•	How did tahoe do vs cmap do  before going in details 
•	Based on what we started with, 233 diseases from CREEDS and x number of drugs in cmap and y number of drugs in tahoe, of these how many were we able to reference with open-target
•	In our analysis we ended up using p number of diseases from creeds, only x’ number of drugs in cmap got matched and y’ numbers of drugs got matched with open targets 
•	We were able to identify kk number of disease-drug pairs by our drug repupsing pipeline, and out of these  vv number was a subset of the diseases  both in creeds and open targets . and out off vv number, we found that QQ number of disease-drug pairs were also validated by open targets. 

Diseases:
CREEDS Disease Signatures (233 diseases)
    ↓
Matched to Open Targets (203 matched, 30 unmatched)
    ↓
Filtered to diseases with known drugs (180 diseases)
    ↓
Clustered by Therapeutic Area (20 clusters, multi-membership)

Drugs – set summary 
Dataset	Total Drugs	Overlap
Open Targets (all)	4,274	-
CMAP-matched	457	43 shared
Tahoe-matched	170	43 shared
Combined (CMAP ∪ Tahoe)	584 unique	-

CMAP and Tahoe Have Different Drug Profiles

Target Class	Tahoe (170)	CMAP (457)	Difference
Enzyme	92 (54.1%)	112 (24.5%)	Tahoe +30%
Membrane receptor	22 (12.9%)	158 (34.6%)	CMAP +22%
Transcription factor	24 (14.1%)	60 (13.1%)	Similar
Ion channel	4 (2.4%)	58 (12.7%)	CMAP +10%
Transporter	6 (3.5%)	49 (10.7%)	CMAP +7%
Other	22 (12.9%)	20 (4.4%)	Tahoe +8%


Precision and recall numbers:
Metric Definitions
Precision = Successfully Recovered (S) / All Predictions (I) × 100%
•	Measures: "Of all drugs we predicted, what % were validated in Open Targets?"
Recall = Successfully Recovered (S) / Maximum Possible (P) × 100%
•	Measures: "Of all known drugs available in our platform, what % did we predict?"
Where:
•	S = Predictions that match Open Targets validated relationships
•	I = All predictions made by DRpipe for a disease
•	P = Known drugs in Open Targets that exist in CMAP/TAHOE database (platform-specific ceiling)


Dataset	N Diseases	N Predictions	N Recovered
CMAP	101	4717	305
TAHOE	112	7647	849

We validated drug predictions against known disease-drug relationships from Open Targets by calculating precision and recall metrics per disease. Precision represents the proportion of predictions confirmed in Open Targets (S/I × 100%), while recall represents the proportion of known recoverable relationships successfully predicted (S/P × 100%, where P is the maximum possible given drug availability in each platform).
TAHOE achieved superior performance: mean precision of 9.9% (SD 13.7%) and recall of 58.0% (SD 31.5%), compared to CMAP's 5.5% (SD 6.5%) precision and 60.7% (SD 36.9%) recall across 112 and 101 diseases, respectively.
The superior TAHOE performance was consistent: 6 of 112 (5%) TAHOE diseases achieved >50% precision, compared to 0 of 101 (0%) for CMAP. Similarly, 85 of 95 (89%) TAHOE diseases exceeded 20% recall, versus 61 of 78 (78%) for CMAP.
These results validate that both pipelines generate mechanistically coherent predictions with partial recovery of known disease-drug relationships, with TAHOE demonstrating substantially more accurate and comprehensive drug-disease candidate identification.

Figure 1 



Curious
•	How do the drug classifications of Tahoe differ from CMAP, and what does this tell us? 
•	Tell us a bit out the distribution of the disease and their therapeutic areas 

Figure 2 …. 
The methodological distinction between perturbation-based (CMAP) and disease-signature-based (Tahoe) approaches explains the striking differences in their drug target class profiles. [we are not entirely sure about this, what we are sure of is that cmap is microarray and tahoe is single cell, can we reward this first part? ] 
CMAP's reliance on drug-induced cellular perturbations favors compounds with rapid, membrane-proximal effects (receptors, ion channels), while Tahoe's disease-centric matching favors drugs targeting intracellular signaling hubs (kinases, enzymes). This mechanistic divergence, rather than representing a limitation, demonstrates that the two platforms survey complementary regions of therapeutic chemical space.

Our analysis reveals that Tahoe substantially outperforms CMAP in recovering established drug-disease associations validated against Open Targets. Tahoe identified 2,198 validated pairs compared to 948 for CMAP—a 2.3-fold advantage that extends across multiple performance dimensions. Tahoe covered more diseases (148 vs. 113 unique diseases) while simultaneously achieving a higher recovery rate (10.8% vs. 7.0% of all predictions corresponding to known therapeutics).


Point: 
•	Drug matching of tahoe and cmap
Importantly, drug matching rates to Open Targets annotations differed substantially between platforms (CMAP: 50.7%, Tahoe: 63.0%), reflecting their distinct chemical libraries. CMAP's lower matching rate stems from its inclusion of proprietary Broad Institute compounds, internal identifiers, and experimental research chemicals not represented in public drug databases. While these unmatched compounds represent unexplored therapeutic potential, they also indicate that CMAP surveys a more experimental chemical space compared to Tahoe's clinically-oriented drug library.

Point:
•	Low Concordance reveals complementary Biological coverage
A striking and consequential finding is the remarkably low concordance between CMAP and Tahoe predictions. Among validated drug-disease pairs, only 160 (5.4% Jaccard index) were identified by both pipelines. This divergence becomes even more pronounced in the complete prediction landscape, where only 297 pairs (1.0% Jaccard index) overlapped between the 13,564 CMAP and 20,260 Tahoe predictions.

This near-orthogonal output pattern demonstrates that the two platforms capture fundamentally different aspects of drug-disease relationships rather than redundantly sampling the same therapeutic space. The low concordance should not be interpreted as methodological failure but rather as evidence that transcriptomic drug repurposing can be approached from multiple complementary angles. Considering that these were also taken from different cell lines no overlap. 
The combined CMAP-Tahoe output captures substantially more therapeutic candidates than either platform alone, with the overlap representing high-confidence predictions suitable for prioritized experimental validation.

When to use CMAP vs TAHOE-100M 
Tahoe exhibits a strongly enzyme-centric profile, with enzyme inhibitors comprising 52.2% of recovered drugs and 50.8% of all matched discoveries. This enrichment for enzymatic targets—particularly kinases relevant to oncology—reflects Tahoe's sensitivity to dysregulated signaling pathway signatures. Kinase cascades represent nodal points in cellular regulation whose aberrant activity produces coherent, pathway-wide transcriptomic changes that Tahoe's disease-signature matching effectively captures. The consistency of this enzyme bias between recovered (validated) and all discoveries (novel predictions) indicates that Tahoe's novel candidates maintain the same mechanistic profile associated with therapeutic success. [I would also talk more on  what are other major categories in drug types and also majority in therapeutic areas it was able to recover the most, in addition to the firs tone] 

CMAP displays a more balanced, receptor-oriented profile, with membrane receptors (35.0% in all discoveries, 16.0% in recovered) and ion channels (13.1% in all discoveries) representing substantial fractions alongside enzymes (19.6% in all discoveries). Additionally, CMAP's recovered drugs showed notably higher transcription factor modulator representation (23.9%) compared to Tahoe (9.2%). This broader target class distribution reflects CMAP's perturbation-based methodology, which detects drugs producing strong membrane-proximal effects that rapidly propagate to alter transcription—characteristic of receptor agonists/antagonists and ion channel modulators. [also touch a bit on what are the major categories for the cmap drug types and what are the majority of the therautpic areas and what does it tell us]

The differential target class profiles have direct implications for platform selection based on disease mechanism. Tahoe is optimally suited for diseases driven by enzymatic pathway dysregulation (oncology, inflammation, metabolic disorders), while CMAP may excel for conditions involving receptor-mediated signaling (neurological, cardiovascular, psychiatric indications).

Figure 3 …..

Biological concordance  btn recovered vs all discovereins 
After seeing that our platform’s recall was high, we wanted to see also  even though we had law precision because of  the low coverage or overlap between drugs and diseases, we wanted to see if there was a biolofical concordance btween validated drug discoverieds (recoverd) form open taget and complete pipeline outputs (all discoveries) for both tahoe and cmap repuposing platform. 
The central question is: Do novel predictions maintain the same mechanistic profiles as clinically-validated drugs?
Tahoe demonstrates excellent biological concordance (cosine similarity = 0.987), while CMAP shows moderate concordance (cosine similarity = 0.850). This validates that both pipelines—particularly Tahoe—generate biologically coherent predictions that extend the mechanistic logic of their validated successes.

Dataset	Platform	Description	N Pairs
CMAP Recovered	CMAP	Validated against Open Targets	948
CMAP All	CMAP	All matched predictions	5,241
Tahoe Recovered	Tahoe	Validated against Open Targets	2,198
Tahoe All	Tahoe	All matched predictions	9,946



Figure 4  ….


[it doesn’t make sense to measure the drug-drug recovered vs all, because the distribution of drugs categories were the same still same to disease-diseases instead we want to compare whether in validated drug types and disease therapeutic areas were concordance btn recovered vs all both in cmap and in tahoe]


Practical Implications for Drug Discovery
Based on our comprehensive analysis, we provide evidence-based recommendations for platform selection and integration:
Tahoe is recommended for drug discovery programs targeting enzyme-driven pathways, particularly oncology (kinase inhibitors), inflammatory conditions, and metabolic disorders. Tahoe's 2.3-fold advantage in recovering known therapeutics, combined with its consistent enzyme-centric profile, suggests higher precision for identifying clinically-relevant candidates in these indications. Programs with limited validation resources may benefit from Tahoe's higher hit rate.
CMAP is recommended for programs targeting receptor-mediated pathways, including neurological, cardiovascular, and psychiatric indications where membrane receptor and ion channel modulation represent established therapeutic mechanisms. CMAP's broader target class distribution may also uncover unexpected therapeutic modalities for diseases with poorly characterized mechanisms.
Integration of both platforms is strongly recommended for comprehensive drug discovery campaigns. The 1.0% overlap in predictions demonstrates that combining outputs substantially expands therapeutic coverage. The 160 drug-disease pairs identified by both platforms represent high-confidence predictions where multiple transcriptomic approaches converge, suitable for prioritized experimental validation.

Limitation: 

A significant portion of pipeline-discovered drugs could not be matched to Open Targets drug annotations and are excluded from target class visualizations but documented for completeness.
CMAP Unmatched Drugs (641 unique, 49.3% of pairs): The higher unmatched rate reflects CMAP's diverse chemical library including internal Broad Institute compound identifiers (e.g., 01735700000), natural product derivatives, and research chemicals not in public databases.
Tahoe Unmatched Drugs (135 unique, 37.0% of pairs): Tahoe's lower unmatched rate indicates better representation in curated databases, with unmatched compounds primarily comprising newer investigational drugs and natural products.
The differential matching rates reflect distinct chemical space coverage: CMAP explores more experimental/proprietary compounds while Tahoe's library is more amenable to annotation-based analysis.


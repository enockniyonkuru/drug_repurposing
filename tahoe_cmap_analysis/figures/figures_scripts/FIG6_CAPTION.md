**Figure 6: Precision vs Recall Performance**

This scatter plot compares precision and recall across 234 diseases for TAHOE and CMAP pipelines (Q value = 0.05). Recall measures the fraction of known drugs identified by each pipeline (known drugs found / total known drugs available), while precision measures the fraction of predictions that are known drugs (known drugs in predictions / total candidates predicted). TAHOE (blue) achieves ~50% recall with higher precision, while CMAP (orange) shows lower recall (~20%) and precision, reflecting its more conservative candidate selection. Users seeking comprehensive recovery of established treatments should choose TAHOE, while those preferring a tighter, curated list should select CMAP.




"""
Generate two figures displaying biological concordance metrics
(Cosine Similarity and Jensen-Shannon Divergence) between
recovered and all predictions for CMap and Tahoe-100M.
"""

import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
import numpy as np
import os

# ── Style ────────────────────────────────────────────────────────────────────
plt.style.use("seaborn-v0_8-whitegrid")
plt.rcParams.update({
    "font.family": "Arial",
    "font.size": 10,
    "figure.dpi": 300,
    "axes.labelsize": 13,
    "axes.titlesize": 14,
})

# ── Colors (matching existing figures) ───────────────────────────────────────
CMAP_COLOR = "#F39C12"
TAHOE_COLOR = "#5DADE2"

# ── Data ─────────────────────────────────────────────────────────────────────
platforms = ["CMap", "Tahoe-100M"]
cosine_sim = [0.850, 0.987]
jsd = [0.221, 0.150]
colors = [CMAP_COLOR, TAHOE_COLOR]

# ── Output directory ─────────────────────────────────────────────────────────
out_dir = os.path.join(
    os.path.dirname(__file__), "..", "..",
    "figures", "biological_concordance"
)
os.makedirs(out_dir, exist_ok=True)


# ── Figure 1: Cosine Similarity ─────────────────────────────────────────────
fig1, ax1 = plt.subplots(figsize=(4.5, 4))

bars1 = ax1.bar(platforms, cosine_sim, color=colors, width=0.55,
                edgecolor="white", linewidth=1.2, zorder=3)

# Annotate values
for bar, val in zip(bars1, cosine_sim):
    ax1.text(bar.get_x() + bar.get_width() / 2, bar.get_height() + 0.012,
             f"{val:.3f}", ha="center", va="bottom", fontsize=13, fontweight="bold")

ax1.set_ylabel("Cosine Similarity", fontsize=13)
ax1.set_title("Biological Concordance:\nRecovered vs. All Predictions",
              fontsize=14, fontweight="bold", pad=12)
ax1.set_ylim(0, 1.12)
ax1.axhline(y=1.0, color="grey", linestyle="--", linewidth=0.8, alpha=0.5, zorder=1)
ax1.text(1.02, 1.0, "perfect", va="center", ha="left", fontsize=8,
         color="grey", transform=ax1.get_yaxis_transform())
ax1.spines["top"].set_visible(False)
ax1.spines["right"].set_visible(False)
ax1.tick_params(axis="x", labelsize=12)
ax1.tick_params(axis="y", labelsize=11)

fig1.tight_layout()
path1 = os.path.join(out_dir, "cosine_similarity_comparison.png")
fig1.savefig(path1, dpi=300, bbox_inches="tight", facecolor="white")
print(f"Saved: {path1}")
plt.close(fig1)


# ── Figure 2: Jensen-Shannon Divergence ─────────────────────────────────────
fig2, ax2 = plt.subplots(figsize=(4.5, 4))

bars2 = ax2.bar(platforms, jsd, color=colors, width=0.55,
                edgecolor="white", linewidth=1.2, zorder=3)

# Annotate values
for bar, val in zip(bars2, jsd):
    ax2.text(bar.get_x() + bar.get_width() / 2, bar.get_height() + 0.008,
             f"{val:.3f}", ha="center", va="bottom", fontsize=13, fontweight="bold")

ax2.set_ylabel("Jensen-Shannon Divergence", fontsize=13)
ax2.set_title("Distribution Divergence:\nRecovered vs. All Predictions",
              fontsize=14, fontweight="bold", pad=12)
ax2.set_ylim(0, 0.35)
ax2.axhline(y=0.0, color="grey", linestyle="--", linewidth=0.8, alpha=0.5, zorder=1)
ax2.text(1.02, 0.0, "identical", va="center", ha="left", fontsize=8,
         color="grey", transform=ax2.get_yaxis_transform())
ax2.spines["top"].set_visible(False)
ax2.spines["right"].set_visible(False)
ax2.tick_params(axis="x", labelsize=12)
ax2.tick_params(axis="y", labelsize=11)

# Downward arrow to indicate lower = better
ax2.annotate("lower = better", xy=(0.98, 0.96), xycoords="axes fraction",
             ha="right", va="top", fontsize=9, fontstyle="italic", color="grey")

fig2.tight_layout()
path2 = os.path.join(out_dir, "jsd_comparison.png")
fig2.savefig(path2, dpi=300, bbox_inches="tight", facecolor="white")
print(f"Saved: {path2}")
plt.close(fig2)

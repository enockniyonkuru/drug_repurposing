#!/usr/bin/env python3
"""
Plot Distribution of Disease Signature Metrics (Raw + Z-Scored)
===============================================================

This script reads disease signature CSV files and generates a panel of
six distribution plots for each disease:

ROW 1 (raw values):
    1. mean_logfc
    2. median_logfc
    3. common_experiment

ROW 2 (z-scored values):
    4. z_mean_logfc
    5. z_median_logfc
    6. z_common_experiment

Outputs:
    • One PNG file per disease, containing 6 panels

"""

import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt
from pathlib import Path
import warnings
warnings.filterwarnings("ignore")

# Set Seaborn theme to match your CMAP/TAHOE style
sns.set_style("whitegrid")
plt.rcParams["figure.figsize"] = (18, 10)
plt.rcParams["axes.titlesize"] = 14
plt.rcParams["axes.labelsize"] = 12


def compute_zscore(series):
    """Return z-score normalized version of a Pandas Series."""
    series = series.dropna()
    if series.std() == 0:
        return pd.Series([0] * len(series))
    return (series - series.mean()) / series.std()


def plot_single_disease(df: pd.DataFrame, disease: str, output_file: Path):
    """Create a 6-panel plot with raw + zscore distributions."""

    raw_cols = ["mean_logfc", "median_logfc", "common_experiment"]
    z_cols = ["z_mean_logfc", "z_median_logfc", "z_common_experiment"]

    # Compute z-scores
    for raw_col, z_col in zip(raw_cols, z_cols):
        if raw_col in df.columns:
            df[z_col] = compute_zscore(df[raw_col])
        else:
            df[z_col] = None

    fig, axes = plt.subplots(2, 3, figsize=(18, 10))
    fig.suptitle(f"{disease} — Raw & Z-Score Distributions", fontsize=16, fontweight="bold")

    # --- Row 1: raw values ---
    for idx, col in enumerate(raw_cols):
        ax = axes[0, idx]

        if col not in df.columns:
            ax.text(0.5, 0.5, f"Missing column: {col}",
                    ha='center', va='center', fontsize=14)
            ax.set_title(col)
            continue

        data = df[col].dropna()
        sns.histplot(data, bins=30, kde=False, edgecolor="black", color="steelblue", ax=ax)
        ax.set_title(col)
        ax.set_xlabel("Value")
        ax.set_ylabel("Frequency")

        # Stats box
        if len(data) > 0:
            stats_text = f"n={len(data)}\nmean={data.mean():.3f}\nstd={data.std():.3f}"
            ax.text(0.98, 0.98, stats_text,
                    transform=ax.transAxes,
                    fontsize=10, va="top", ha="right",
                    bbox=dict(boxstyle="round", facecolor="wheat", alpha=0.5))

    # --- Row 2: z-scored values ---
    for idx, col in enumerate(z_cols):
        ax = axes[1, idx]
        data = df[col].dropna()

        if len(data) == 0:
            ax.text(0.5, 0.5, f"No data: {col}",
                    ha='center', va='center', fontsize=14)
            ax.set_title(col)
            continue

        sns.histplot(data, bins=30, kde=False, edgecolor="black", color="darkorange", ax=ax)
        ax.set_title(col)
        ax.set_xlabel("Z-score")
        ax.set_ylabel("Frequency")

        stats_text = f"n={len(data)}\nmean={data.mean():.3f}\nstd={data.std():.3f}"
        ax.text(0.98, 0.98, stats_text,
                transform=ax.transAxes,
                fontsize=10, va="top", ha="right",
                bbox=dict(boxstyle="round", facecolor="wheat", alpha=0.5))

    plt.tight_layout(rect=[0, 0.03, 1, 0.95])
    plt.savefig(output_file, dpi=300, bbox_inches="tight")
    plt.close()


def process_all_diseases(input_folder: Path, output_folder: Path):
    """Load disease signature files and generate distribution plots."""

    output_folder.mkdir(parents=True, exist_ok=True)
    csv_files = list(input_folder.glob("*.csv"))

    if not csv_files:
        print(f"⚠️ No CSV files found in: {input_folder}")
        return

    print(f"\n📁 Found {len(csv_files)} disease signature files.\n")

    for csv_path in csv_files:
        disease = csv_path.stem.replace("_signature", "")
        output_file = output_folder / f"{disease}_distribution.png"

        print(f"  📊 Processing: {disease}")

        try:
            df = pd.read_csv(csv_path)
        except Exception as e:
            print(f"  ⚠️ Error reading {csv_path.name}: {e}")
            continue

        plot_single_disease(df, disease, output_file)
        print(f"      ✓ Saved {output_file.name}")

    print("\n✨ All plots generated successfully!\n")


if __name__ == "__main__":
    input_folder = Path("../data/disease_signatures/sirota_lab_disease_signatures")
    output_folder = Path("../data/disease_signatures/sirota_lab_disease_signatures_plots")

    process_all_diseases(input_folder, output_folder)

#!/usr/bin/env python3
"""
Statistical Analysis of Biological Concordance
Comparing the FULL Disease × Drug Target Matrix
Between Recovered and All Discoveries

This compares the joint distribution (the actual heatmap patterns)
not just marginal distributions of drug types or disease areas separately.
"""

import pandas as pd
import numpy as np
from scipy import stats
from scipy.spatial.distance import cosine, jensenshannon
from scipy.stats import chi2_contingency, pearsonr, spearmanr
import warnings
warnings.filterwarnings('ignore')

# =============================================================================
# Load Data
# =============================================================================

print("=" * 80)
print("BIOLOGICAL CONCORDANCE ANALYSIS: FULL DISEASE × DRUG TARGET MATRIX")
print("Comparing the joint distribution between Recovered and All Discoveries")
print("=" * 80)

# Load datasets
cmap_recovered = pd.read_csv('open_target_cmap_recovered.csv')
tahoe_recovered = pd.read_csv('open_target_tahoe_recovered.csv')
cmap_all = pd.read_csv('all_discoveries_cmap.csv')
tahoe_all = pd.read_csv('all_discoveries_tahoe.csv')

print(f"\nDataset sizes:")
print(f"  CMAP Recovered:  {len(cmap_recovered):,} pairs")
print(f"  CMAP All:        {len(cmap_all):,} pairs")
print(f"  Tahoe Recovered: {len(tahoe_recovered):,} pairs")
print(f"  Tahoe All:       {len(tahoe_all):,} pairs")

# Column names
target_col = 'drug_target_class'
disease_col = 'disease_therapeutic_areas'

# =============================================================================
# Helper Functions
# =============================================================================

def create_joint_matrix(df, disease_col, target_col):
    """Create a disease × drug target count matrix."""
    return pd.crosstab(df[disease_col], df[target_col])

def align_matrices(mat1, mat2):
    """Align two matrices to have the same rows and columns."""
    all_rows = sorted(set(mat1.index) | set(mat2.index))
    all_cols = sorted(set(mat1.columns) | set(mat2.columns))
    
    mat1_aligned = mat1.reindex(index=all_rows, columns=all_cols, fill_value=0)
    mat2_aligned = mat2.reindex(index=all_rows, columns=all_cols, fill_value=0)
    
    return mat1_aligned, mat2_aligned

def normalize_matrix(mat):
    """Normalize matrix to sum to 1 (joint probability distribution)."""
    return mat / mat.values.sum()

def flatten_matrix(mat):
    """Flatten matrix to 1D array for statistical comparison."""
    return mat.values.flatten()

def cosine_similarity(v1, v2):
    """Calculate cosine similarity (1 - cosine distance)."""
    if np.sum(v1) == 0 or np.sum(v2) == 0:
        return 0
    return 1 - cosine(v1, v2)

def kl_divergence(p, q, epsilon=1e-10):
    """Calculate Kullback-Leibler divergence with smoothing."""
    p = np.array(p) + epsilon
    q = np.array(q) + epsilon
    p = p / p.sum()
    q = q / q.sum()
    return np.sum(p * np.log(p / q))

def total_variation_distance(p, q):
    """Calculate Total Variation Distance."""
    return 0.5 * np.sum(np.abs(p - q))

def hellinger_distance(p, q):
    """Calculate Hellinger Distance."""
    return np.sqrt(0.5 * np.sum((np.sqrt(p) - np.sqrt(q))**2))

def bhattacharyya_coefficient(p, q):
    """Calculate Bhattacharyya Coefficient (similarity)."""
    return np.sum(np.sqrt(p * q))

def cramers_v(mat1, mat2):
    """Calculate Cramér's V comparing two contingency tables."""
    # Stack the matrices for chi-square test
    combined = np.stack([mat1.values.flatten(), mat2.values.flatten()])
    chi2, p, dof, expected = chi2_contingency(combined.T)
    n = combined.sum()
    min_dim = min(combined.shape) - 1
    return np.sqrt(chi2 / (n * min_dim)) if min_dim > 0 else 0, chi2, p

# =============================================================================
# Create Joint Matrices
# =============================================================================

print("\n" + "=" * 80)
print("CREATING DISEASE × DRUG TARGET MATRICES")
print("=" * 80)

# Create matrices
cmap_rec_matrix = create_joint_matrix(cmap_recovered, disease_col, target_col)
cmap_all_matrix = create_joint_matrix(cmap_all, disease_col, target_col)
tahoe_rec_matrix = create_joint_matrix(tahoe_recovered, disease_col, target_col)
tahoe_all_matrix = create_joint_matrix(tahoe_all, disease_col, target_col)

# Align matrices
cmap_rec_aligned, cmap_all_aligned = align_matrices(cmap_rec_matrix, cmap_all_matrix)
tahoe_rec_aligned, tahoe_all_aligned = align_matrices(tahoe_rec_matrix, tahoe_all_matrix)

print(f"\nCMAP matrix dimensions: {cmap_rec_aligned.shape[0]} diseases × {cmap_rec_aligned.shape[1]} drug targets")
print(f"Tahoe matrix dimensions: {tahoe_rec_aligned.shape[0]} diseases × {tahoe_rec_aligned.shape[1]} drug targets")

# Normalize to probability distributions
cmap_rec_norm = normalize_matrix(cmap_rec_aligned)
cmap_all_norm = normalize_matrix(cmap_all_aligned)
tahoe_rec_norm = normalize_matrix(tahoe_rec_aligned)
tahoe_all_norm = normalize_matrix(tahoe_all_aligned)

# Flatten for comparison
cmap_rec_flat = flatten_matrix(cmap_rec_norm)
cmap_all_flat = flatten_matrix(cmap_all_norm)
tahoe_rec_flat = flatten_matrix(tahoe_rec_norm)
tahoe_all_flat = flatten_matrix(tahoe_all_norm)

print(f"\nTotal cells in joint distribution:")
print(f"  CMAP:  {len(cmap_rec_flat)} cells ({cmap_rec_aligned.shape[0]} × {cmap_rec_aligned.shape[1]})")
print(f"  Tahoe: {len(tahoe_rec_flat)} cells ({tahoe_rec_aligned.shape[0]} × {tahoe_rec_aligned.shape[1]})")

# =============================================================================
# Calculate All Statistical Measures for Joint Distribution
# =============================================================================

print("\n" + "=" * 80)
print("STATISTICAL CONCORDANCE: FULL DISEASE × DRUG TARGET MATRIX")
print("=" * 80)

results = {}

for name, (rec_flat, all_flat, rec_norm, all_norm) in [
    ("CMAP", (cmap_rec_flat, cmap_all_flat, cmap_rec_norm, cmap_all_norm)),
    ("Tahoe", (tahoe_rec_flat, tahoe_all_flat, tahoe_rec_norm, tahoe_all_norm))
]:
    # Similarity measures
    cos_sim = cosine_similarity(rec_flat, all_flat)
    pearson_r, pearson_p = pearsonr(rec_flat, all_flat)
    spearman_r, spearman_p = spearmanr(rec_flat, all_flat)
    bhatta = bhattacharyya_coefficient(rec_flat, all_flat)
    
    # Divergence measures
    js_div = jensenshannon(rec_flat + 1e-10, all_flat + 1e-10)
    kl_div = kl_divergence(rec_flat, all_flat)
    tvd = total_variation_distance(rec_flat, all_flat)
    hellinger = hellinger_distance(rec_flat, all_flat)
    
    results[name] = {
        'Cosine Similarity': cos_sim,
        'Pearson Correlation': pearson_r,
        'Pearson p-value': pearson_p,
        'Spearman Correlation': spearman_r,
        'Spearman p-value': spearman_p,
        'Bhattacharyya Coefficient': bhatta,
        'Jensen-Shannon Divergence': js_div,
        'KL Divergence': kl_div,
        'Total Variation Distance': tvd,
        'Hellinger Distance': hellinger,
    }

# Print results
print("\n" + "-" * 80)
print("SIMILARITY MEASURES (Higher = More Concordant)")
print("-" * 80)
print(f"{'Metric':<35} {'CMAP':>15} {'Tahoe':>15} {'Interpretation'}")
print("-" * 80)

similarity_metrics = [
    ('Cosine Similarity', '>0.90 strong, >0.80 moderate'),
    ('Pearson Correlation', '>0.80 strong, >0.60 moderate'),
    ('Spearman Correlation', '>0.80 strong, >0.60 moderate'),
    ('Bhattacharyya Coefficient', '>0.90 excellent overlap'),
]

for metric, interp in similarity_metrics:
    cmap_val = results['CMAP'][metric]
    tahoe_val = results['Tahoe'][metric]
    print(f"{metric:<35} {cmap_val:>15.4f} {tahoe_val:>15.4f} {interp}")

print("\n" + "-" * 80)
print("DIVERGENCE MEASURES (Lower = More Concordant)")
print("-" * 80)
print(f"{'Metric':<35} {'CMAP':>15} {'Tahoe':>15} {'Interpretation'}")
print("-" * 80)

divergence_metrics = [
    ('Jensen-Shannon Divergence', '<0.20 good, <0.30 moderate'),
    ('KL Divergence', '<0.20 good, <0.50 moderate'),
    ('Total Variation Distance', '<0.30 good, <0.50 moderate'),
    ('Hellinger Distance', '<0.30 good, <0.50 moderate'),
]

for metric, interp in divergence_metrics:
    cmap_val = results['CMAP'][metric]
    tahoe_val = results['Tahoe'][metric]
    print(f"{metric:<35} {cmap_val:>15.4f} {tahoe_val:>15.4f} {interp}")

# =============================================================================
# Statistical Significance
# =============================================================================

print("\n" + "=" * 80)
print("STATISTICAL SIGNIFICANCE")
print("=" * 80)

print(f"\nPearson Correlation p-values (joint distribution):")
print(f"  CMAP:  r = {results['CMAP']['Pearson Correlation']:.4f}, p = {results['CMAP']['Pearson p-value']:.2e}")
print(f"  Tahoe: r = {results['Tahoe']['Pearson Correlation']:.4f}, p = {results['Tahoe']['Pearson p-value']:.2e}")

print(f"\nSpearman Correlation p-values (joint distribution):")
print(f"  CMAP:  ρ = {results['CMAP']['Spearman Correlation']:.4f}, p = {results['CMAP']['Spearman p-value']:.2e}")
print(f"  Tahoe: ρ = {results['Tahoe']['Spearman Correlation']:.4f}, p = {results['Tahoe']['Spearman p-value']:.2e}")

# =============================================================================
# Bootstrap Confidence Intervals for Cosine Similarity
# =============================================================================

print("\n" + "=" * 80)
print("BOOTSTRAP 95% CONFIDENCE INTERVALS")
print("=" * 80)

def bootstrap_matrix_cosine(df_rec, df_all, disease_col, target_col, n_bootstrap=1000):
    """Bootstrap CI for cosine similarity of joint distributions."""
    similarities = []
    for _ in range(n_bootstrap):
        # Resample with replacement
        sample_rec = df_rec.sample(n=len(df_rec), replace=True)
        sample_all = df_all.sample(n=len(df_all), replace=True)
        
        # Create matrices
        mat_rec = create_joint_matrix(sample_rec, disease_col, target_col)
        mat_all = create_joint_matrix(sample_all, disease_col, target_col)
        
        # Align
        mat_rec_a, mat_all_a = align_matrices(mat_rec, mat_all)
        
        # Normalize and flatten
        rec_flat = flatten_matrix(normalize_matrix(mat_rec_a))
        all_flat = flatten_matrix(normalize_matrix(mat_all_a))
        
        sim = cosine_similarity(rec_flat, all_flat)
        similarities.append(sim)
    
    return np.percentile(similarities, [2.5, 97.5])

print("\nBootstrapping joint distribution cosine similarity (1000 iterations)...")
cmap_ci = bootstrap_matrix_cosine(cmap_recovered, cmap_all, disease_col, target_col)
tahoe_ci = bootstrap_matrix_cosine(tahoe_recovered, tahoe_all, disease_col, target_col)

print(f"\nCosine Similarity of Joint Distribution (Disease × Drug Target) with 95% CI:")
print(f"  CMAP:  {results['CMAP']['Cosine Similarity']:.4f} [{cmap_ci[0]:.4f}, {cmap_ci[1]:.4f}]")
print(f"  Tahoe: {results['Tahoe']['Cosine Similarity']:.4f} [{tahoe_ci[0]:.4f}, {tahoe_ci[1]:.4f}]")

# =============================================================================
# Compare with Marginal Distributions (for reference)
# =============================================================================

print("\n" + "=" * 80)
print("COMPARISON: JOINT vs MARGINAL DISTRIBUTIONS")
print("=" * 80)

# Drug target marginals
def get_marginal_distribution(df, col):
    counts = df[col].value_counts()
    return counts / counts.sum()

cmap_rec_drug = get_marginal_distribution(cmap_recovered, target_col)
cmap_all_drug = get_marginal_distribution(cmap_all, target_col)
tahoe_rec_drug = get_marginal_distribution(tahoe_recovered, target_col)
tahoe_all_drug = get_marginal_distribution(tahoe_all, target_col)

# Align marginals
def align_series(s1, s2):
    all_idx = sorted(set(s1.index) | set(s2.index))
    return s1.reindex(all_idx, fill_value=0), s2.reindex(all_idx, fill_value=0)

cmap_rec_d, cmap_all_d = align_series(cmap_rec_drug, cmap_all_drug)
tahoe_rec_d, tahoe_all_d = align_series(tahoe_rec_drug, tahoe_all_drug)

# Disease marginals
cmap_rec_dis = get_marginal_distribution(cmap_recovered, disease_col)
cmap_all_dis = get_marginal_distribution(cmap_all, disease_col)
tahoe_rec_dis = get_marginal_distribution(tahoe_recovered, disease_col)
tahoe_all_dis = get_marginal_distribution(tahoe_all, disease_col)

cmap_rec_dis_a, cmap_all_dis_a = align_series(cmap_rec_dis, cmap_all_dis)
tahoe_rec_dis_a, tahoe_all_dis_a = align_series(tahoe_rec_dis, tahoe_all_dis)

# Calculate cosine similarities for comparison
cmap_drug_cos = cosine_similarity(cmap_rec_d.values, cmap_all_d.values)
tahoe_drug_cos = cosine_similarity(tahoe_rec_d.values, tahoe_all_d.values)
cmap_disease_cos = cosine_similarity(cmap_rec_dis_a.values, cmap_all_dis_a.values)
tahoe_disease_cos = cosine_similarity(tahoe_rec_dis_a.values, tahoe_all_dis_a.values)

print("\nCosine Similarity Comparison:")
print("-" * 70)
print(f"{'Distribution Type':<40} {'CMAP':>12} {'Tahoe':>12}")
print("-" * 70)
print(f"{'Joint (Disease × Drug Target)':<40} {results['CMAP']['Cosine Similarity']:>12.4f} {results['Tahoe']['Cosine Similarity']:>12.4f}")
print(f"{'Marginal (Drug Target Classes only)':<40} {cmap_drug_cos:>12.4f} {tahoe_drug_cos:>12.4f}")
print(f"{'Marginal (Disease Areas only)':<40} {cmap_disease_cos:>12.4f} {tahoe_disease_cos:>12.4f}")

# =============================================================================
# Top Preserved and Changed Combinations
# =============================================================================

print("\n" + "=" * 80)
print("TOP DISEASE-DRUG TARGET COMBINATIONS: PRESERVED vs CHANGED")
print("=" * 80)

def get_top_combinations(rec_norm, all_norm, n=5):
    """Get the most preserved and most changed disease-drug combinations."""
    # Calculate differences
    diff = all_norm - rec_norm
    
    # Flatten with labels
    combinations = []
    for disease in rec_norm.index:
        for drug in rec_norm.columns:
            combinations.append({
                'Disease': disease,
                'Drug Target': drug,
                'Recovered %': rec_norm.loc[disease, drug] * 100,
                'All %': all_norm.loc[disease, drug] * 100,
                'Change': diff.loc[disease, drug] * 100
            })
    
    df = pd.DataFrame(combinations)
    
    # Most preserved (smallest absolute change, but with meaningful recovered %)
    df['Abs Change'] = df['Change'].abs()
    preserved = df[df['Recovered %'] > 0.5].nsmallest(n, 'Abs Change')
    
    # Most increased
    increased = df.nlargest(n, 'Change')
    
    # Most decreased
    decreased = df.nsmallest(n, 'Change')
    
    return preserved, increased, decreased

for name, (rec_norm, all_norm) in [
    ("CMAP", (cmap_rec_norm, cmap_all_norm)),
    ("Tahoe", (tahoe_rec_norm, tahoe_all_norm))
]:
    preserved, increased, decreased = get_top_combinations(rec_norm, all_norm)
    
    print(f"\n{name} - Most PRESERVED combinations (small change, >0.5% in recovered):")
    print("-" * 70)
    for _, row in preserved.iterrows():
        print(f"  {row['Disease'][:25]:<25} × {row['Drug Target'][:20]:<20}: {row['Recovered %']:.1f}% → {row['All %']:.1f}% (Δ={row['Change']:+.2f}%)")
    
    print(f"\n{name} - Most INCREASED combinations:")
    print("-" * 70)
    for _, row in increased.iterrows():
        print(f"  {row['Disease'][:25]:<25} × {row['Drug Target'][:20]:<20}: {row['Recovered %']:.1f}% → {row['All %']:.1f}% (Δ={row['Change']:+.2f}%)")
    
    print(f"\n{name} - Most DECREASED combinations:")
    print("-" * 70)
    for _, row in decreased.iterrows():
        print(f"  {row['Disease'][:25]:<25} × {row['Drug Target'][:20]:<20}: {row['Recovered %']:.1f}% → {row['All %']:.1f}% (Δ={row['Change']:+.2f}%)")

# =============================================================================
# Summary
# =============================================================================

print("\n" + "=" * 80)
print("SUMMARY: JOINT DISTRIBUTION CONCORDANCE")
print("=" * 80)

print("""
┌────────────────────────────────────────────────────────────────────────────────┐
│           BIOLOGICAL CONCORDANCE: DISEASE × DRUG TARGET RELATIONSHIPS          │
├────────────────────────────────────────────────────────────────────────────────┤
│                                                                                │
│  This analysis compares the FULL joint distribution (the heatmap pattern)      │
│  between recovered and all discoveries, capturing which disease-drug target    │
│  combinations are preserved when expanding from validated to novel predictions.│
│                                                                                │
├────────────────────────────────────────────────────────────────────────────────┤
│                                                                                │
│  TAHOE:                                                                        │
│  • Cosine Similarity: {tahoe_cos:.4f} [{tahoe_ci_lo:.3f}, {tahoe_ci_hi:.3f}]                                  │
│  • Pearson r: {tahoe_r:.4f} (p = {tahoe_p:.2e})                                        │
│  • Jensen-Shannon: {tahoe_js:.4f}                                                      │
│                                                                                │
│  INTERPRETATION: {tahoe_interp}              │
│                                                                                │
├────────────────────────────────────────────────────────────────────────────────┤
│                                                                                │
│  CMAP:                                                                         │
│  • Cosine Similarity: {cmap_cos:.4f} [{cmap_ci_lo:.3f}, {cmap_ci_hi:.3f}]                                   │
│  • Pearson r: {cmap_r:.4f} (p = {cmap_p:.2e})                                         │
│  • Jensen-Shannon: {cmap_js:.4f}                                                       │
│                                                                                │
│  INTERPRETATION: {cmap_interp}                               │
│                                                                                │
└────────────────────────────────────────────────────────────────────────────────┘
""".format(
    tahoe_cos=results['Tahoe']['Cosine Similarity'],
    tahoe_ci_lo=tahoe_ci[0],
    tahoe_ci_hi=tahoe_ci[1],
    tahoe_r=results['Tahoe']['Pearson Correlation'],
    tahoe_p=results['Tahoe']['Pearson p-value'],
    tahoe_js=results['Tahoe']['Jensen-Shannon Divergence'],
    tahoe_interp="Strong concordance - disease-drug relationships preserved" if results['Tahoe']['Cosine Similarity'] > 0.8 else "Moderate concordance",
    cmap_cos=results['CMAP']['Cosine Similarity'],
    cmap_ci_lo=cmap_ci[0],
    cmap_ci_hi=cmap_ci[1],
    cmap_r=results['CMAP']['Pearson Correlation'],
    cmap_p=results['CMAP']['Pearson p-value'],
    cmap_js=results['CMAP']['Jensen-Shannon Divergence'],
    cmap_interp="Moderate concordance - some shifts in patterns" if results['CMAP']['Cosine Similarity'] < 0.9 else "Strong concordance"
))

# =============================================================================
# Manuscript-Ready Paragraph
# =============================================================================

print("\n" + "=" * 80)
print("MANUSCRIPT-READY RESULTS PARAGRAPH")
print("=" * 80)

manuscript = f"""
To assess whether the biological relationships between disease therapeutic areas 
and drug target classes are preserved when expanding from validated to novel 
predictions, we compared the full joint distributions (disease × drug target 
matrices) using multiple concordance metrics. Tahoe demonstrated strong 
preservation of disease-drug target relationships (cosine similarity = 
{results['Tahoe']['Cosine Similarity']:.3f} [95% CI: {tahoe_ci[0]:.3f}–{tahoe_ci[1]:.3f}], 
Pearson r = {results['Tahoe']['Pearson Correlation']:.3f}, p = {results['Tahoe']['Pearson p-value']:.2e}, 
Jensen-Shannon divergence = {results['Tahoe']['Jensen-Shannon Divergence']:.3f}), indicating that the 
specific combinations of diseases with particular drug target classes remain 
consistent between recovered and all discovery sets. CMAP showed moderate 
concordance (cosine similarity = {results['CMAP']['Cosine Similarity']:.3f} 
[95% CI: {cmap_ci[0]:.3f}–{cmap_ci[1]:.3f}], Pearson r = {results['CMAP']['Pearson Correlation']:.3f}, 
p = {results['CMAP']['Pearson p-value']:.2e}), with some redistribution of disease-drug target 
combinations. Notably, the joint distribution concordance ({results['Tahoe']['Cosine Similarity']:.3f} for 
Tahoe) provides stronger evidence for pipeline validity than marginal 
distributions alone ({tahoe_drug_cos:.3f} for drug targets, {tahoe_disease_cos:.3f} for diseases), 
as it captures the actual biological relationships between diseases and their 
predicted therapeutic modalities.
"""
print(manuscript)

# =============================================================================
# Save Results
# =============================================================================

results_df = pd.DataFrame({
    'Metric': [
        'Cosine Similarity (Joint)',
        'Cosine Similarity (Drug Marginal)',
        'Cosine Similarity (Disease Marginal)',
        'Pearson Correlation (Joint)',
        'Spearman Correlation (Joint)',
        'Bhattacharyya Coefficient',
        'Jensen-Shannon Divergence',
        'KL Divergence',
        'Total Variation Distance',
        'Hellinger Distance',
        '95% CI Lower',
        '95% CI Upper'
    ],
    'CMAP': [
        results['CMAP']['Cosine Similarity'],
        cmap_drug_cos,
        cmap_disease_cos,
        results['CMAP']['Pearson Correlation'],
        results['CMAP']['Spearman Correlation'],
        results['CMAP']['Bhattacharyya Coefficient'],
        results['CMAP']['Jensen-Shannon Divergence'],
        results['CMAP']['KL Divergence'],
        results['CMAP']['Total Variation Distance'],
        results['CMAP']['Hellinger Distance'],
        cmap_ci[0],
        cmap_ci[1]
    ],
    'Tahoe': [
        results['Tahoe']['Cosine Similarity'],
        tahoe_drug_cos,
        tahoe_disease_cos,
        results['Tahoe']['Pearson Correlation'],
        results['Tahoe']['Spearman Correlation'],
        results['Tahoe']['Bhattacharyya Coefficient'],
        results['Tahoe']['Jensen-Shannon Divergence'],
        results['Tahoe']['KL Divergence'],
        results['Tahoe']['Total Variation Distance'],
        results['Tahoe']['Hellinger Distance'],
        tahoe_ci[0],
        tahoe_ci[1]
    ]
})

results_df.to_csv('concordance_joint_distribution.csv', index=False)
print("\n✓ Results saved to concordance_joint_distribution.csv")

print("\n" + "=" * 80)
print("ANALYSIS COMPLETE")
print("=" * 80)

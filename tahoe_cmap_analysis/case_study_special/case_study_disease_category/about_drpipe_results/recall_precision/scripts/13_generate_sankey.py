#!/usr/bin/env python3
"""
Generate Sankey diagram for CMAP vs TAHOE comparison
"""

import plotly.graph_objects as go
import pandas as pd
from pathlib import Path

print("=" * 80)
print("GENERATING SANKEY DIAGRAM")
print("=" * 80)

# Setup paths
base_dir = Path(__file__).parent.parent
output_dir = base_dir / "outputs"
fig_dir = base_dir / "figures"

# Define nodes
nodes = [
    "118k Open Targets",
    "CMAP Only",
    "Available in Both",
    "TAHOE Only",
    "Recovered CMAP",
    "Not Recovered (CMAP)",
    "Recovered TAHOE",
    "Not Recovered (TAHOE)"
]

# Define edges (source, target, value)
# Starting from all 118k targets to the splits
source = [
    0, 0, 0,  # From 118k to different availability groups
    1, 1,     # From CMAP Only to outcomes
    2, 2,     # From Available in Both to outcomes
    3, 3      # From TAHOE Only to outcomes
]

target = [
    1, 2, 3,  # To CMAP Only, Both, TAHOE Only
    4, 5,     # To Recovered/Not Recovered CMAP
    4, 5,     # To Recovered/Not Recovered CMAP
    6, 7      # To Recovered/Not Recovered TAHOE
]

value = [
    364, 44, 177,  # Drug split
    305, 4412,     # CMAP results
    0, 0,          # Both (included in recovery counts)
    849, 6798      # TAHOE results
]

# Colors for flows
link_colors = [
    'rgba(243, 156, 18, 0.4)',  # CMAP to CMAP only
    'rgba(52, 152, 219, 0.4)',  # Both
    'rgba(52, 152, 219, 0.4)',  # TAHOE only
    'rgba(243, 156, 18, 0.6)',  # CMAP recovered
    'rgba(189, 195, 199, 0.4)',  # CMAP not recovered
    'rgba(243, 156, 18, 0.6)',  # Both to recovered
    'rgba(189, 195, 199, 0.4)',  # Both to not recovered
    'rgba(52, 152, 219, 0.6)',  # TAHOE recovered
    'rgba(189, 195, 199, 0.4)'   # TAHOE not recovered
]

# Node colors
node_colors = [
    'rgba(44, 62, 80, 0.8)',    # 118k Open Targets
    'rgba(243, 156, 18, 0.8)',  # CMAP Only (Orange)
    'rgba(155, 89, 182, 0.8)',  # Available in Both (Purple)
    'rgba(52, 152, 219, 0.8)',  # TAHOE Only (Blue)
    'rgba(46, 204, 113, 0.8)',  # Recovered CMAP (Green)
    'rgba(189, 195, 199, 0.8)',  # Not Recovered CMAP (Gray)
    'rgba(46, 204, 113, 0.8)',  # Recovered TAHOE (Green)
    'rgba(189, 195, 199, 0.8)'   # Not Recovered TAHOE (Gray)
]

# Create figure
fig = go.Figure(data=[go.Sankey(
    node=dict(
        pad=15,
        thickness=20,
        line=dict(color='black', width=0.5),
        label=nodes,
        color=node_colors
    ),
    link=dict(
        source=source,
        target=target,
        value=value,
        color=link_colors,
        label=[f"{nodes[s]} → {nodes[t]}: {v:,}" for s, t, v in zip(source, target, value)]
    )
)])

fig.update_layout(
    title={
        'text': 'Drug Repurposing Pipeline Comparison: CMAP vs TAHOE<br><sub>118k Open Targets with 2,668 Available in CMAP & TAHOE</sub>',
        'x': 0.5,
        'xanchor': 'center',
        'font': {'size': 16, 'color': '#2c3e50'}
    },
    font=dict(size=11, family='Arial'),
    height=600,
    width=1200,
    margin=dict(l=50, r=50, t=100, b=50),
    paper_bgcolor='rgba(240, 240, 240, 1)',
    plot_bgcolor='rgba(255, 255, 255, 1)'
)

# Save as HTML and PNG
print("✓ Generating Sankey diagram...")
fig.write_html(output_dir / "sankey_cmap_vs_tahoe.html")
print(f"✓ Saved: sankey_cmap_vs_tahoe.html (interactive)")

# Also create a static PNG version
fig.write_image(fig_dir / "Sankey_CMAP_vs_TAHOE_Comparison.png", width=1200, height=600)
print(f"✓ Saved: Sankey_CMAP_vs_TAHOE_Comparison.png (static)")

print("\n" + "=" * 80)
print("SANKEY DIAGRAM GENERATED SUCCESSFULLY")
print("=" * 80)
print(f"\nGenerated Files:")
print(f"  ✓ outputs/sankey_cmap_vs_tahoe.html (interactive - open in browser)")
print(f"  ✓ figures/Sankey_CMAP_vs_TAHOE_Comparison.png (static image)")
print(f"\nFlow Summary:")
print(f"  • 118k Open Targets total")
print(f"  • 2,668 available in CMAP & TAHOE")
print(f"  • 4,717 CMAP predictions → 305 recovered (6.5%)")
print(f"  • 7,647 TAHOE predictions → 849 recovered (11.1%)")
print(f"  • TAHOE recovers 71% more drugs")

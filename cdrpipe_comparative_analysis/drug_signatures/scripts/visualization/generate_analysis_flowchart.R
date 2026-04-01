# ==============================================================================
# UPDATED STUDY FLOWCHART: HIERARCHICAL INPUTS
# ==============================================================================

library(DiagrammeR)
library(DiagrammeRsvg)
library(rsvg)

# DEFINE THE GRAPH
# ----------------
study_graph_v3 <- grViz("digraph study_flow_v3 {

  # --- Graph Settings ---
  graph [layout = dot,
         rankdir = TB,            # Top to Bottom flow
         nodesep = 0.5,           # Horizontal spacing
         ranksep = 0.6,           # Vertical spacing
         fontname = 'Arial',
         fontsize = 12,
         splines = ortho]         # Orthogonal lines (clean right angles)

  # --- Node Styles ---
  node [fontname = 'Arial',
        shape = box,
        style = 'filled,rounded',
        penwidth = 1.2,
        fontsize = 10,
        color = '#555555']

  # --- Edge Styles ---
  edge [fontname = 'Arial',
        fontsize = 9,
        color = '#666666',
        penwidth = 1.0,
        arrowsize = 0.7]

  # =========================================================
  # 1. INPUT GROUP A: DRUG SIGNATURES (THE SPLIT)
  # =========================================================
  subgraph cluster_drugs {
    label = ''; penwidth = 0; # Invisible container

    # The Parent Node
    node [shape = cylinder, fillcolor = '#0288d1', fontcolor = 'white', width = 2.5]
    DRUG_ROOT [label = 'INPUT 1: DRUG SIGNATURES\n(Transcriptomic Libraries)']

    # The Split Nodes
    node [shape = box, fillcolor = '#b3e5fc', fontcolor = 'black', width = 2.2]
    CMAP [label = <<b>CMAP</b><br/>(Bulk L1000)<br/><i>1,309 Drugs</i><br/><font size='8'>6,100 experiments</font><br/><font size='8'>~13k genes</font>>]
    
    node [shape = box, fillcolor = '#b2dfdb', fontcolor = 'black', width = 2.2]
    TAHOE [label = <<b>TAHOE</b><br/>(Single-Cell)<br/><i>379 Drugs</i><br/><font size='8'>56,827 experiments</font><br/><font size='8'>62,710 genes</font>>]

    # Connection: Split
    DRUG_ROOT -> CMAP
    DRUG_ROOT -> TAHOE
  }

  # =========================================================
  # 1b. PREPROCESSING GROUP A: DRUG SIGNATURES
  # =========================================================
  subgraph cluster_drug_preproc {
    label = ''; penwidth = 0;

    node [shape = ellipse, style = filled, fillcolor = '#ffe0b2', fontcolor = 'black', width = 2.0]
    CMAP_PREPROC [label = <<b>CMAP Preprocessing</b><br/><font size='8'>• Leave-one-out validation</font><br/><font size='8'>• Pearson r &#62; 0, p &#60; 0.05</font><br/><font size='8'>• Valid: 32.27%</font><br/><font size='8'>• Pre-ranked signatures</font>>]
    
    node [shape = ellipse, style = filled, fillcolor = '#ffe0b2', fontcolor = 'black', width = 2.0]
    TAHOE_PREPROC [label = <<b>TAHOE Preprocessing</b><br/><font size='8'>• Filter significant logFC</font><br/><font size='8'>• Rank signatures</font><br/><font size='8'>• Match CMAP format</font><br/><font size='8'>• Full transcriptome</font>>]

    CMAP -> CMAP_PREPROC
    TAHOE -> TAHOE_PREPROC
  }

  # =========================================================
  # 2. INPUT GROUP B: DISEASE SIGNATURES
  # =========================================================
  subgraph cluster_disease {
    label = ''; penwidth = 0;

    node [shape = note, fillcolor = '#bdbdbd', fontcolor = 'black', width = 2.5]
    DISEASE [label = <<b>INPUT 2: DISEASE SIGNATURES</b><br/>(CREEDS Manual Cohort)<br/><i>233 Diseases</i>>]
    
    node [shape = ellipse, style = filled, fillcolor = '#fff4e1', fontcolor = 'black', width = 2.0]
    DIS_PREPROC [label = <<b>Disease Standardization</b><br/><font size='8'>• QC1 filter applied</font><br/><font size='8'>• Mean/median consistency</font><br/><font size='8'>• |median_logFC| ≥ 0.02</font><br/><font size='8'>• UP/DOWN gene sets</font>>]
    
    DISEASE -> DIS_PREPROC
  }

  # =========================================================
  # 3. INPUT GROUP C: KNOWN DRUGS (VALIDATION)
  # =========================================================
  subgraph cluster_known {
    label = ''; penwidth = 0;

    node [shape = cylinder, fillcolor = '#ffb74d', fontcolor = 'black', width = 2]
    KNOWN [label = <<b>INPUT 3: KNOWN DRUGS</b><br/>(Open Targets / DrugBank)<br/><i>Reference Standards</i>>]
    
    # This node waits until the end to merge
  }

  # =========================================================
  # 4. ANALYSIS ENGINE (THE CONVERGENCE)
  # =========================================================
  
  # Ensure drug preprocessing and disease preprocessing align horizontally
  { rank = same; CMAP_PREPROC; TAHOE_PREPROC; DIS_PREPROC }

  node [shape = rect, style = filled, fillcolor = '#e1bee7', width = 4, height = 1]
  PIPELINE [label = <<b>CDRPipe v2.0 ANALYSIS ENGINE</b><br/>Comparative Drug Repurposing<br/>(Bidirectional Scoring)>]

  # Connections from preprocessing to pipeline
  CMAP_PREPROC -> PIPELINE
  TAHOE_PREPROC -> PIPELINE
  DIS_PREPROC -> PIPELINE

  # =========================================================
  # 5. RESULTS AND VALIDATION MERGE
  # =========================================================

  node [shape = diamond, style = filled, fillcolor = '#fff9c4']
  THRESHOLD [label = 'FDR q < 0.5']

  node [shape = box, fillcolor = '#ffe0b2', width = 3]
  RAW_HITS [label = 'Predicted Drug-Disease Associations\n(6,161+ Hits)']

  # The Validation Step where Input 3 enters
  node [shape = rect, fillcolor = '#ff9800', fontcolor = 'white', width = 4]
  FINAL_VAL [label = <<b>VALIDATION &amp; ANNOTATION</b><br/>Annotate predictions with Known Drugs<br/>Identify Consensus Hits>]

  # =========================================================
  # CONNECTIONS
  # =========================================================
  
  # Pipeline Flow
  PIPELINE -> THRESHOLD
  THRESHOLD -> RAW_HITS
  
  # Merge Raw Hits with Known Drugs
  RAW_HITS -> FINAL_VAL
  KNOWN -> FINAL_VAL [constraint = false] # Constraint false allows side-entry arrow

}")

# RENDER AND EXPORT
# -----------------
print(study_graph_v3)

# Export
svg_code <- export_svg(study_graph_v3)
rsvg_pdf(charToRaw(svg_code), "hierarchy_workflow.pdf")
rsvg_png(charToRaw(svg_code), "hierarchy_workflow.png", width = 3000)
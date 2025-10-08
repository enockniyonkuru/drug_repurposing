# Plan to Merge Comparative Analysis + Sweep Customization

## Current Situation

1. **app_backup.R** has:
   - ✅ Comparative analysis mode
   - ✅ Single analysis mode
   - ✅ Profile management
   - ❌ Missing sweep parameter customization

2. **app.R** (current) has:
   - ✅ Sweep parameter customization
   - ✅ Fixed navigation
   - ❌ Missing comparative analysis mode
   - ❌ Missing separate visualization tabs

## Required Merge

### Features to Combine:

1. **From app_backup.R:**
   - Analysis type selection (Single vs Comparative)
   - Multiple profile selection for comparison
   - Comparative results visualization
   - Profile overlap heatmaps
   - Comparison summary tables

2. **From app.R (current):**
   - Full sweep mode parameter customization:
     - sweep_auto_grid
     - sweep_step
     - sweep_min_frac
     - sweep_min_genes
     - sweep_stop_on_small
     - combine_log2fc
     - robust_rule
     - robust_k
     - aggregate

3. **New Features to Add:**
   - Separate visualization tabs:
     - Tab for Single Analysis visualizations
     - Tab for Comparative Analysis visualizations
     - Tab for Sweep Mode visualizations

## Implementation Steps

### Step 1: Restore Analysis Type Selection
- Add back "Choose Analysis Type" tab
- Restore single vs comparative selection UI

### Step 2: Update Configuration Tab
- Keep profile selection from backup
- Add sweep parameter inputs to custom profile creation
- Make sweep parameters conditional (show only when mode="sweep")

### Step 3: Restore Comparative Analysis Logic
- Bring back run_comparative_analysis() function
- Restore comparison results storage
- Add comparison log rendering

### Step 4: Create Separate Visualization Tabs
Instead of one "Visualizations" tab, create three:

**Tab 6a: Single Analysis Plots**
- Score distribution
- Volcano plot
- Top drugs bar chart
- Q-value distribution
- Score vs Q scatter

**Tab 6b: Comparative Analysis Plots**
- Profile overlap heatmap
- Score distribution by profile
- Venn diagram of drug overlap
- Comparison summary

**Tab 6c: Sweep Mode Plots**
- Threshold support distribution
- Score vs support scatter
- Cutoff performance line plot
- Top robust drugs
- Sweep results table

### Step 5: Update Navigation
- Maintain fixed navigation from current app.R
- Add conditional tab visibility based on analysis type

## File Structure After Merge

```
shiny_app/
├── app.R (merged version with all features)
├── README.md (updated documentation)
├── run.R (helper script)
└── app_backup.R (original backup - can be removed after merge)
```

## Testing Checklist

After merge, test:
- [ ] Single analysis with default parameters
- [ ] Single analysis with custom sweep parameters
- [ ] Comparative analysis with 2+ profiles
- [ ] Navigation between all tabs
- [ ] All visualization tabs render correctly
- [ ] Download buttons work
- [ ] Example data loading works
- [ ] Custom profile creation works

## Key Code Sections to Merge

### 1. UI - Add Analysis Type Tab
```r
menuItem("1. Choose Analysis Type", tabName = "choose_type", ...)
```

### 2. UI - Update Config Tab
Add sweep parameters to custom profile forms:
```r
conditionalPanel(
  condition = "input.customMode == 'sweep'",
  # All sweep parameter inputs here
)
```

### 3. Server - Restore Comparative Logic
```r
run_comparative_analysis <- function() {
  # Full implementation from backup
}
```

### 4. Server - Add Sweep Parameters to Profile Creation
```r
custom_profile <- list(
  params = list(
    # ... existing params ...
    sweep_auto_grid = input$customSweepAutoGrid,
    sweep_step = input$customSweepStep,
    # ... all sweep params ...
  )
)
```

## Timeline

This merge requires careful integration to avoid breaking existing functionality. Estimated time: 2-3 hours for a complete, tested implementation.

## Alternative Approach

Given the complexity, we could:
1. Keep current app.R as "simple mode" (single analysis only, full sweep customization)
2. Restore app_backup.R as "advanced mode" (comparative + single, add sweep params)
3. Let user choose which version to use

However, the ideal solution is a single unified app with all features.

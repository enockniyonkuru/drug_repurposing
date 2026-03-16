#!/usr/bin/env python3
"""
Master Script: Run All Phases of Precision & Recall Analysis

This script executes all analysis phases in sequence with progress tracking
and error handling.
"""

import subprocess
import sys
from pathlib import Path
import time

print("=" * 80)
print("PRECISION & RECALL ANALYSIS - MASTER SCRIPT")
print("=" * 80)

# Setup paths
script_dir = Path(__file__).parent
base_dir = script_dir.parent

# List of scripts to run
scripts = [
    ("01_prepare_data.py", "Data Preparation"),
    ("02_calculate_precision_recall.py", "Precision & Recall Calculation"),
    ("03_aggregate_statistics.py", "Aggregate Statistics"),
    ("04_generate_figures.py", "Generate Visualizations"),
    ("05_generate_report.py", "Generate Final Report")
]

# Execute scripts
print("\nStarting analysis pipeline...\n")

failed_scripts = []
execution_times = {}

for script_name, description in scripts:
    script_path = script_dir / script_name
    
    if not script_path.exists():
        print(f"✗ SKIPPED: {description} - Script not found: {script_path}")
        failed_scripts.append((script_name, "Script not found"))
        continue
    
    print(f"\n{'=' * 80}")
    print(f"RUNNING: {description}")
    print(f"Script: {script_name}")
    print(f"{'=' * 80}")
    
    start_time = time.time()
    
    try:
        result = subprocess.run(
            [sys.executable, str(script_path)],
            cwd=str(script_dir),
            capture_output=False,
            timeout=300  # 5 minute timeout per script
        )
        
        elapsed = time.time() - start_time
        execution_times[script_name] = elapsed
        
        if result.returncode == 0:
            print(f"\n✓ COMPLETED: {description} ({elapsed:.1f}s)")
        else:
            print(f"\n✗ FAILED: {description} (exit code: {result.returncode})")
            failed_scripts.append((script_name, f"Exit code: {result.returncode}"))
    
    except subprocess.TimeoutExpired:
        print(f"\n✗ TIMEOUT: {description} (exceeded 300 seconds)")
        failed_scripts.append((script_name, "Timeout exceeded"))
    except Exception as e:
        print(f"\n✗ ERROR: {description}")
        print(f"  Exception: {str(e)}")
        failed_scripts.append((script_name, str(e)))

# Final summary
print("\n" + "=" * 80)
print("ANALYSIS PIPELINE SUMMARY")
print("=" * 80)

total_scripts = len(scripts)
completed_scripts = total_scripts - len(failed_scripts)

print(f"\nExecution Summary:")
print(f"  Total scripts: {total_scripts}")
print(f"  Completed: {completed_scripts}")
print(f"  Failed: {len(failed_scripts)}")

if execution_times:
    total_time = sum(execution_times.values())
    print(f"  Total execution time: {total_time:.1f} seconds ({total_time/60:.1f} minutes)")

if failed_scripts:
    print(f"\nFailed Scripts:")
    for script_name, reason in failed_scripts:
        print(f"  ✗ {script_name}: {reason}")
else:
    print(f"\n✓ All phases completed successfully!")

# Output locations
output_dir = base_dir / "intermediate_data"
fig_dir = base_dir / "figures"
outputs_dir = base_dir / "outputs"

if len(failed_scripts) == 0:
    print(f"\n" + "=" * 80)
    print("OUTPUT FILES")
    print("=" * 80)
    
    print(f"\nIntermediate Data ({output_dir}):")
    if output_dir.exists():
        for f in sorted(output_dir.glob("*.csv"))[:5]:
            print(f"  ✓ {f.name}")
        print(f"  ... and more")
    
    print(f"\nFigures ({fig_dir}):")
    if fig_dir.exists():
        for f in sorted(fig_dir.glob("*.png")):
            print(f"  ✓ {f.name}")
    
    print(f"\nFinal Reports ({outputs_dir}):")
    if outputs_dir.exists():
        for f in sorted(outputs_dir.glob("*")):
            print(f"  ✓ {f.name}")

print("\n" + "=" * 80)
print("PIPELINE EXECUTION COMPLETE")
print("=" * 80)

sys.exit(0 if len(failed_scripts) == 0 else 1)

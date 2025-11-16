

# Getting Started with Drug Repurposing Pipeline on UCSF HPC (Protected Accounts)

This guide explains how to configure and run the **Drug Repurposing Pipeline** (`DRpipe`) on the **UCSF Wynton Protected HPC** environment using **Singularity containers** for R 4.3.1.

Your working directory is assumed to be:

```
/wynton/protected/home/rotation/enockniyonkuru/sirota_lab/drug_repurposing
```

---

## 🧭 Table of Contents

1. [Initial Setup](#1-initial-setup)
2. [Environment Configuration (Singularity R)](#2-environment-configuration-singularityr)
3. [Data Preparation](#3-data-preparation)
4. [Running Analyses](#4-running-analyses)
5. [Monitoring Jobs](#5-monitoring-jobs)
6. [Troubleshooting](#6-troubleshooting)
7. [Best Practices](#7-best-practices)
8. [Quick Reference](#8-quick-reference)
9. [Support](#9-support)

---

## 1. Initial Setup

### 1.1 Connect to Wynton Protected

```bash
ssh enockniyonkuru@plog1.wynton.ucsf.edu   # login node
ssh pdev1.wynton.ucsf.edu                  # dev node for testing
```

### 1.2 Navigate to your project

```bash
cd /wynton/protected/home/rotation/enockniyonkuru/sirota_lab/drug_repurposing
```

### 1.3 Check folder layout

```bash
ls -la
# DRpipe/   scripts/   tahoe_cmap_analysis/   README.md
```

### 1.4 Create log/results folders

```bash
mkdir -p ~/hpc_logs scripts/results tahoe_cmap_analysis/results
```

---

## 2. Environment Configuration (Singularity R)

Protected nodes don’t have R modules; use **Singularity** to run Rocker R 4.3.1.
Singularity is already installed system-wide—you don’t need `module load`.

### 2.1 Cache the Rocker image (optional but faster)

```bash
singularity pull ~/rocker_r431.sif docker://rocker/r-ver:4.3.1
```

### 2.2 Run R directly

```bash
singularity exec ~/rocker_r431.sif R --version
# or, if not pulled yet:
# singularity exec docker://rocker/r-ver:4.3.1 R --version
```

Expected:

```
R version 4.3.1 (2023-06-16)
```

### 2.3 (Recommended) Add aliases

Edit `~/.bashrc`:

```bash
nano ~/.bashrc
```

Add at the bottom:

```bash
# ---- Singularity R aliases ----
alias R='singularity exec ~/rocker_r431.sif R'
alias Rscript='singularity exec ~/rocker_r431.sif Rscript'
```

Reload:

```bash
source ~/.bashrc
```

Now you can simply run:

```bash
Rscript myscript.R
```

---

## 3. Data Preparation

### 3.1 Transfer data via Protected transfer nodes

```bash
scp /local/path/cmap_signatures.RData \
enockniyonkuru@pdt1.wynton.ucsf.edu:/wynton/protected/home/rotation/enockniyonkuru/sirota_lab/drug_repurposing/scripts/data/
```

### 3.2 Verify files

```bash
cd scripts/data
ls -lh
```

### 3.3 Test loading in R

```bash
Rscript -e "load('scripts/data/cmap_signatures.RData'); cat('✅ Data loaded OK\n')"
```

---

## 4. Running Analyses

### 4.1 Interactive test (small runs)

```bash
qlogin -l mem_free=8G,h_rt=02:00:00 -A sirota_lab
cd /wynton/protected/home/rotation/enockniyonkuru/sirota_lab/drug_repurposing/scripts
Rscript runall.R
exit
```

### 4.2 Batch job (large runs)

**Job script `~/my_drug_run.sh`:**

```bash
#!/bin/bash
#$ -S /bin/bash
#$ -cwd
#$ -N drpipe_run
#$ -j y
#$ -pe smp 4
#$ -l mem_free=8G
#$ -l h_rt=48:00:00
#$ -A sirota_lab
#$ -m bea
#$ -M enock.niyonkuru@ucsf.edu

LOG_DIR="$HOME/hpc_logs"
mkdir -p "$LOG_DIR"
exec > "${LOG_DIR}/drpipe_run_${JOB_ID}.log" 2>&1

echo "🚀 Starting DRpipe analysis at $(date)"
echo "Node: $(hostname)"
cd /wynton/protected/home/rotation/enockniyonkuru/sirota_lab/drug_repurposing/scripts

# Run inside Singularity
singularity exec ~/rocker_r431.sif Rscript runall.R

echo "✅ Completed at $(date)"
```

Submit:

```bash
chmod +x ~/my_drug_run.sh
qsub ~/my_drug_run.sh
```

---

## 5. Monitoring Jobs

```bash
qstat -u $USER               # list jobs
qstat -j <job_id>            # job details
qacct -j <job_id>            # finished job stats
tail -f ~/hpc_logs/drpipe_run_<job_id>.log
qdel <job_id>                # cancel
```

---

## 6. Troubleshooting

| Problem                | Cause           | Fix                                     |
| ---------------------- | --------------- | --------------------------------------- |
| `R: command not found` | No R module     | Use aliases or full Singularity command |
| “Cannot open file”     | Wrong directory | `cd` to your `scripts` folder           |
| “Out of memory”        | Not enough RAM  | raise `#$ -l mem_free=12G`              |
| “Job killed”           | Time limit      | raise `#$ -l h_rt=72:00:00`             |
| Package install fails  | No permission   | install to `~/R/library`                |

---

## 7. Best Practices

* Prototype on `pdev1` before submitting.
* Use `/wynton/protected/scratch/` for temporary data (auto-cleared after 2 weeks).
* Organize outputs:

  ```bash
  mkdir -p results/$(date +%Y%m%d)
  tar -czf results_archive_$(date +%Y%m%d).tar.gz results/old/
  ```

---

## 8. Quick Reference

| Task       | Command                                    |
| ---------- | ------------------------------------------ |
| Login      | `ssh enockniyonkuru@plog1.wynton.ucsf.edu` |
| Dev node   | `ssh pdev1.wynton.ucsf.edu`                |
| Run R      | `R`                                        |
| Run script | `Rscript myscript.R`                       |
| Submit job | `qsub my_drug_run.sh`                      |
| Job status | `qstat -u $USER`                           |
| Cancel job | `qdel <job_id>`                            |
| Logs       | `tail -f ~/hpc_logs/*.log`                 |

---

## 9. Support

**Cluster help:**  📧 `wynton-help@ucsf.edu` 🌐 [https://wynton.ucsf.edu](https://wynton.ucsf.edu)
**Pipeline:**  📦 [https://github.com/enockniyonkuru/drug_repurposing](https://github.com/enockniyonkuru/drug_repurposing) 📧 `enock.niyonkuru@ucsf.edu`

---

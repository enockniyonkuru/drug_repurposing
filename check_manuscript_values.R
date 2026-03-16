library(readr)
library(dplyr)

# Load the per-disease precision/recall data
tahoe <- read_csv("/Users/enockniyonkuru/Desktop/drug_repurposing/tahoe_cmap_analysis/case_study_special/case_study_disease_category/about_drpipe_results/recall_precision/intermediate_data/tahoe_precision_recall_per_disease.csv")
cmap <- read_csv("/Users/enockniyonkuru/Desktop/drug_repurposing/tahoe_cmap_analysis/case_study_special/case_study_disease_category/about_drpipe_results/recall_precision/intermediate_data/cmap_precision_recall_per_disease.csv")

cat("=== ORIGINAL DATA ===\n")
cat("TAHOE n rows:", nrow(tahoe), "\n")
cat("CMAP n rows:", nrow(cmap), "\n")

cat("\n=== ALL DISEASES ===\n")
cat("TAHOE Precision: Mean =", mean(tahoe$`Precision_%`, na.rm=TRUE), "SD =", sd(tahoe$`Precision_%`, na.rm=TRUE), "\n")
cat("TAHOE Recall:    Mean =", mean(tahoe$`Recall_%`, na.rm=TRUE), "SD =", sd(tahoe$`Recall_%`, na.rm=TRUE), "\n")
cat("CMAP Precision:  Mean =", mean(cmap$`Precision_%`, na.rm=TRUE), "SD =", sd(cmap$`Precision_%`, na.rm=TRUE), "\n")
cat("CMAP Recall:     Mean =", mean(cmap$`Recall_%`, na.rm=TRUE), "SD =", sd(cmap$`Recall_%`, na.rm=TRUE), "\n")

cat("\n=== WITH P > 0 FILTER (recoverable diseases) ===\n")
tahoe_p_gt_0 <- tahoe %>% filter(P > 0)
cmap_p_gt_0 <- cmap %>% filter(P > 0)

cat("TAHOE n =", nrow(tahoe_p_gt_0), "diseases\n")
cat("CMAP n =", nrow(cmap_p_gt_0), "diseases\n")

cat("\nTAHOE Precision: Mean =", mean(tahoe_p_gt_0$`Precision_%`, na.rm=TRUE), 
    "% SD =", sd(tahoe_p_gt_0$`Precision_%`, na.rm=TRUE), "\n")
cat("TAHOE Recall:    Mean =", mean(tahoe_p_gt_0$`Recall_%`, na.rm=TRUE), 
    "% SD =", sd(tahoe_p_gt_0$`Recall_%`, na.rm=TRUE), "\n")

cat("\nCMAP Precision:  Mean =", mean(cmap_p_gt_0$`Precision_%`, na.rm=TRUE), 
    "% SD =", sd(cmap_p_gt_0$`Precision_%`, na.rm=TRUE), "\n")
cat("CMAP Recall:     Mean =", mean(cmap_p_gt_0$`Recall_%`, na.rm=TRUE), 
    "% SD =", sd(cmap_p_gt_0$`Recall_%`, na.rm=TRUE), "\n")

cat("\n=== MATCH TO MANUSCRIPT VALUES ===\n")
cat("Manuscript says:\n")
cat("  Precision: TAHOE 4.2% (SD 7.2%) vs CMAP 3.2% (SD 5.5%)\n")
cat("  Recall (P>0): TAHOE 20.3% (SD 20.5%) vs CMAP 8.9% (SD 12.0%)\n")
cat("\nCalculated (P>0):\n")
cat("  Precision: TAHOE", round(mean(tahoe_p_gt_0$`Precision_%`, na.rm=TRUE), 1), 
    "% (SD", round(sd(tahoe_p_gt_0$`Precision_%`, na.rm=TRUE), 1), 
    "%) vs CMAP", round(mean(cmap_p_gt_0$`Precision_%`, na.rm=TRUE), 1),
    "% (SD", round(sd(cmap_p_gt_0$`Precision_%`, na.rm=TRUE), 1), "%)\n")
cat("  Recall:    TAHOE", round(mean(tahoe_p_gt_0$`Recall_%`, na.rm=TRUE), 1), 
    "% (SD", round(sd(tahoe_p_gt_0$`Recall_%`, na.rm=TRUE), 1), 
    "%) vs CMAP", round(mean(cmap_p_gt_0$`Recall_%`, na.rm=TRUE), 1),
    "% (SD", round(sd(cmap_p_gt_0$`Recall_%`, na.rm=TRUE), 1), "%)\n")

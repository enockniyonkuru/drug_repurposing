# Current fix status: ESE Comparison with 1000 permutations

cat("=======================================================\n")
cat("CURRENT FIX STATUS: ESE Comparison (1000 permutations)\n")
cat("=======================================================\n\n")

# Load Tomiko ESE results
tomiko <- read.csv("endo_tomiko_code/replication/drug_instances_ESE_replicated.csv")

# Load DRpipe ESE results
drpipe <- read.csv("scripts/results/ESE_test_fallback/endomentriosis_ese_disease_signature_hits_logFC_1.1_q<0.00.csv")

# Both filter to q=0 and negative score
tomiko_rev <- tomiko[tomiko$q == 0 & tomiko$cmap_score < 0, ]
drpipe_rev <- drpipe[drpipe$q == 0 & drpipe$cmap_score < 0, ]

cat("Tomiko drugs (q=0, score<0):", nrow(tomiko_rev), "\n")
cat("DRpipe drugs (q=0, score<0):", nrow(drpipe_rev), "\n")

# Overlap
overlap <- length(intersect(tomiko_rev$exp_id, drpipe_rev$exp_id))
only_tomiko <- length(setdiff(tomiko_rev$exp_id, drpipe_rev$exp_id))
only_drpipe <- length(setdiff(drpipe_rev$exp_id, tomiko_rev$exp_id))
jaccard <- overlap / length(union(tomiko_rev$exp_id, drpipe_rev$exp_id))

cat("\nOverlap:", overlap, "\n")
cat("Only in Tomiko:", only_tomiko, "\n")
cat("Only in DRpipe:", only_drpipe, "\n")
cat("Jaccard:", round(jaccard*100, 1), "%\n")

# Top 20 comparison
tomiko_top20 <- head(tomiko_rev[order(tomiko_rev$cmap_score), ], 20)
drpipe_top20 <- head(drpipe_rev[order(drpipe_rev$cmap_score), ], 20)
top20_overlap <- length(intersect(tomiko_top20$exp_id, drpipe_top20$exp_id))
cat("\nTop 20 overlap (by exp_id):", top20_overlap, "/ 20\n")
cat("Top 20 overlap (by name):", length(intersect(tomiko_top20$name, drpipe_top20$name)), "/ 20\n")

cat("\nTomiko top 5:", paste(tomiko_top20$name[1:5], collapse=", "), "\n")
cat("DRpipe top 5:", paste(drpipe_top20$name[1:5], collapse=", "), "\n")

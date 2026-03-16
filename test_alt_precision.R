library(readxl)
library(dplyr)

df <- read_excel("tahoe_cmap_analysis/data/analysis/Exp8_Analysis.xlsx", sheet = "exp_8_0.05")

cat("=== COLUMN NAMES ===\n")
print(names(df))

tahoe_p <- as.numeric(df$`Tahoe Precision`)
cmap_p <- as.numeric(df$`CMAP Precision`)

cat("\n=== METHOD 1: VALUES AS-IS (ALREADY PERCENTAGES?) ===\n")
cat("TAHOE Mean:", mean(tahoe_p, na.rm=TRUE), "SD:", sd(tahoe_p, na.rm=TRUE), "\n")
cat("CMAP Mean:", mean(cmap_p, na.rm=TRUE), "SD:", sd(cmap_p, na.rm=TRUE), "\n")

cat("\n=== METHOD 2: VALUES * 100 ===\n")
cat("TAHOE Mean:", mean(tahoe_p * 100, na.rm=TRUE), "% SD:", sd(tahoe_p * 100, na.rm=TRUE), "\n")
cat("CMAP Mean:", mean(cmap_p * 100, na.rm=TRUE), "% SD:", sd(cmap_p * 100, na.rm=TRUE), "\n")

cat("\n=== WITH NAME/SYNONYM FILTER ===\n")
df_filtered <- df %>% filter(match_type %in% c("name", "synonym"))
t_p <- as.numeric(df_filtered$`Tahoe Precision`)
c_p <- as.numeric(df_filtered$`CMAP Precision`)
cat("TAHOE Mean Precision:", mean(t_p * 100, na.rm=TRUE), "% SD:", sd(t_p * 100, na.rm=TRUE), "\n")
cat("CMAP Mean Precision:", mean(c_p * 100, na.rm=TRUE), "% SD:", sd(c_p * 100, na.rm=TRUE), "\n")

cat("\n=== PER-DISEASE AVERAGE (filtered) ===\n")
disease_avgs <- df_filtered %>%
  group_by(disease_id, disease_name) %>%
  summarise(
    tahoe_p_mean = mean(as.numeric(`Tahoe Precision`) * 100, na.rm=TRUE),
    cmap_p_mean = mean(as.numeric(`CMAP Precision`) * 100, na.rm=TRUE),
    .groups = 'drop'
  )
cat("Unique diseases:", nrow(disease_avgs), "\n")
cat("TAHOE Mean of disease means:", mean(disease_avgs$tahoe_p_mean, na.rm=TRUE), "% SD:", sd(disease_avgs$tahoe_p_mean, na.rm=TRUE), "\n")
cat("CMAP Mean of disease means:", mean(disease_avgs$cmap_p_mean, na.rm=TRUE), "% SD:", sd(disease_avgs$cmap_p_mean, na.rm=TRUE), "\n")

# Check if the manuscript might be referring to different columns
cat("\n=== CHECK FOR OTHER PRECISION COLUMNS ===\n")
precision_cols <- grep("precision", names(df), ignore.case=TRUE, value=TRUE)
print(precision_cols)

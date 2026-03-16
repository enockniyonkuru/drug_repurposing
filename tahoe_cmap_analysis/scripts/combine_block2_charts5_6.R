#!/usr/bin/env Rscript

# Combine Block 2 Charts 5 and 6 into a Single Panel Figure
# Panel A (Left): Signature Size Distribution Before/After Filtration (Chart 6)
# Panel B (Right): Up/Down Genes Distribution (Chart 5)

library(png)
library(grid)
library(gridExtra)
library(ggplot2)

# Set output directory
output_dir <- "tahoe_cmap_analysis/figures"
if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
}

# Read the PNG files
img_a <- readPNG("tahoe_cmap_analysis/figures/figures_v2/block2_chart6_signature_size.png")
img_b <- readPNG("tahoe_cmap_analysis/figures/figures_v2/block2_chart5_up_down_genes.png")

# Create grobs from the images
grob_a <- rasterGrob(img_a, interpolate = TRUE)
grob_b <- rasterGrob(img_b, interpolate = TRUE)

# Create text grobs for panel labels
label_a <- textGrob("A: Signature Size Before and After Filtration",
                    gp = gpar(fontsize = 16, fontface = "bold"),
                    x = 0.05, y = 0.95, just = c("left", "top"), vjust = 1)

label_b <- textGrob("B: Up/Down Gene Distribution Across Signatures",
                    gp = gpar(fontsize = 16, fontface = "bold"),
                    x = 0.05, y = 0.95, just = c("left", "top"), vjust = 1)

# Create overall title
main_title <- textGrob("Gene Expression Signature Characteristics",
                       gp = gpar(fontsize = 20, fontface = "bold"),
                       x = 0.5, y = 0.98, just = c("center", "top"))

# Arrange horizontally (A on left, B on right) with title at top
combined_plot <- gridExtra::grid.arrange(
  main_title,
  gridExtra::grid.arrange(
    gridExtra::grid.arrange(
      label_a,
      grob_a,
      nrow = 2,
      heights = c(0.08, 1)
    ),
    gridExtra::grid.arrange(
      label_b,
      grob_b,
      nrow = 2,
      heights = c(0.08, 1)
    ),
    nrow = 1,
    ncol = 2,
    widths = c(1, 1)
  ),
  nrow = 2,
  heights = c(0.06, 1)
)

# Save as PNG at high resolution
output_file_png <- file.path(output_dir, "Block2_Charts5_6_combined_panel.png")
png(output_file_png, width = 16, height = 7, units = "in", res = 300)
grid.draw(combined_plot)
dev.off()

# Also save as PDF for publication quality
output_file_pdf <- file.path(output_dir, "Block2_Charts5_6_combined_panel.pdf")
pdf(output_file_pdf, width = 16, height = 7)
grid.draw(combined_plot)
dev.off()

cat("\n✓ Combined panel figure created successfully!\n")
cat(sprintf("  • PNG: %s (16\" × 7\", 300 DPI)\n", output_file_png))
cat(sprintf("  • PDF: %s (16\" × 7\", 300 DPI)\n", output_file_pdf))
cat("\nPanel Layout:\n")
cat("  Title: Gene Expression Signature Characteristics\n")
cat("  Panel A (Left):  Signature Size Before and After Filtration\n")
cat("  Panel B (Right): Up/Down Gene Distribution Across Signatures\n")

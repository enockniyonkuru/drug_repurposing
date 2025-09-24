#' @keywords internal
#' @importFrom dplyr %>% group_by slice ungroup filter pull select all_of
#' @importFrom tidyr pivot_wider
#' @importFrom tibble column_to_rownames
#' @importFrom gprofiler2 gconvert
#' @importFrom pheatmap pheatmap
#' @importFrom UpSetR upset fromList
#' @importFrom gplots redblue
#' @importFrom reshape2 dcast
#' @importFrom grDevices colorRampPalette dev.off jpeg
#' @importFrom graphics axis hist image layout par text
#' @importFrom grid grid.text gpar grid.newpage grid.draw
NULL

utils::globalVariables(c(
  "name","value","exp_id","subset_comparison_id","q","cmap_score","Cell",
  "dir.out","dir.out.img","cmap_signatures","cmap_experiments_valid"
))
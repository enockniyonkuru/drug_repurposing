libs <- c('shiny', 'DRpipe', 'shinydashboard', 'fresh', 'shinyWidgets', 'shinycssloaders', 'DT', 'plotly', 'tidyverse', 'yaml', 'shinyjs')
missing <- libs[!sapply(libs, function(lib) require(lib, character.only = TRUE, quietly = TRUE))]
if (length(missing) > 0) {
  cat('Missing packages:', paste(missing, collapse = ', '), '\n')
} else {
  cat('All required packages are installed!\n')
}

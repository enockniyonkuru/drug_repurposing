# Test script for DRpipe package
cat("Testing DRpipe package installation and functionality...\n")

# Check if devtools is available
if (!require('devtools', quietly = TRUE)) {
  cat("Installing devtools...\n")
  install.packages('devtools', repos = 'https://cran.r-project.org')
}

# Try to install DRpipe from DRpipe directory
cat("Installing DRpipe package...\n")
tryCatch({
  devtools::install('DRpipe', quiet = FALSE)
  cat("DRpipe installation completed.\n")
}, error = function(e) {
  cat("Error installing DRpipe:", e$message, "\n")
})

# Try to load the package
cat("Loading DRpipe package...\n")
tryCatch({
  library(DRpipe)
  cat("DRpipe loaded successfully!\n")
}, error = function(e) {
  cat("Error loading DRpipe:", e$message, "\n")
})

# Check package information
cat("Checking package information...\n")
tryCatch({
  packageVersion("DRpipe")
  cat("Package version:", as.character(packageVersion("DRpipe")), "\n")
}, error = function(e) {
  cat("Could not get package version:", e$message, "\n")
})

# List available functions
cat("Available functions in DRpipe:\n")
tryCatch({
  funcs <- ls("package:DRpipe")
  cat(paste(funcs, collapse = ", "), "\n")
}, error = function(e) {
  cat("Could not list functions:", e$message, "\n")
})

cat("Test completed.\n")

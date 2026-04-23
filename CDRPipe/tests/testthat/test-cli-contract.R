test_that("CLI version string matches the package version", {
  expect_identical(
    CDRPipe:::dr_cli_version(),
    sprintf("DRPipe CLI %s", utils::packageVersion("CDRPipe"))
  )
})

test_that("CDRPipe exports the preferred branded aliases", {
  expect_true(is.function(CDRPipe::cdrpipe_cli))
  expect_true(is.function(CDRPipe::dr_cli))
  expect_true(is.function(CDRPipe::load_cdr_config))
  expect_true(is.function(CDRPipe::load_dr_config))
  expect_true(is.function(CDRPipe::run_cdrpipe))
  expect_true(is.function(CDRPipe::run_dr))

  expect_identical(CDRPipe::CDRP, CDRPipe::DRP)
  expect_identical(CDRPipe::CDRA, CDRPipe::DRA)
})

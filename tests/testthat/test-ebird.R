test_that("birddb works", {
  
  Sys.setenv("BIRDDB_HOME" = tempdir()) 
  Sys.setenv("BIRDDB_DUCKDB" = tempdir()) 
  
  tar <- system.file("extdata", "ebd_sample.tar", package = "birddb", 
                     mustWork = TRUE)
  import_ebird(tar)
  df <- ebird()
  
  expect_true(inherits(df, "tbl"))
  expect_true(inherits(df, "tbl_dbi"))
  
  out <- df %>% dplyr::count(country) %>% dplyr::collect()
  expect_true(nrow(out) > 0)
})



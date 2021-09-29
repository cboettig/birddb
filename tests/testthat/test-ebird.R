test_that("birddb works", {
  temp_dir <- file.path(tempdir(), "birddb")
  Sys.setenv("BIRDDB_HOME" = temp_dir)
  
  import_ebird(sample_observation_data())
  import_ebird(sample_checklist_data())
  
  # observations
  con <- ebird_conn("observations")
  observations <- observations(con)
  expect_s3_class(observations, "tbl")
  expect_s3_class(observations, "tbl_dbi")
  expect_equal(DBI::dbListTables(con), "observations")
  
  out <- observations %>% dplyr::count(common_name) %>% dplyr::collect()
  expect_s3_class(out, "data.frame")
  expect_gt(nrow(out), 0)
  
  # checklists 
  con <- ebird_conn("checklists")
  checklists <- checklists(con)
  expect_s3_class(checklists, "tbl")
  expect_s3_class(checklists, "tbl_dbi")
  # ensure that both tables are in the same database
  expect_equal(sort(DBI::dbListTables(con)), 
               c("checklists", "observations"))
  
  out <- checklists %>% dplyr::count(country) %>% dplyr::collect()
  expect_s3_class(out, "data.frame")
  expect_gt(nrow(out), 0)
  
  # cleanup
  DBI::dbDisconnect(con, shutdown = TRUE)
  unlink(temp_dir, recursive = TRUE)
})

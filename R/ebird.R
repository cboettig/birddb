
#' Return a remote data.frame connection to your local ebird database
#' 
#' @export
ebird <- function() {
  
  assert_ebird_imported()
  
  tblname <- "ebd"
  parquet <- ebird_parquet_files()
  conn <- DBI::dbConnect(duckdb::duckdb())
  
  ## Create a "View" in duckdb to the parquet file
  query <- paste0("CREATE VIEW '", tblname,
                  "' AS SELECT * FROM parquet_scan('",
                  parquet, "');")
  DBI::dbSendQuery(conn, query)
  
  ## Creates a lazy remote connection using `dplyr::tbl`
  dplyr::tbl(conn, tblname)
}


assert_ebird_imported <- function(){
  parquet_data <- file.path(ebird_data_dir(), "parquet")
  stopifnot(file.exists(parquet_data))
}

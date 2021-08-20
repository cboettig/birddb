
#' A `[DBI]`-style database connection to the imported eBird data
#' 
#' Returns a database connection to the local eBird dataset.
#' @export
#' 
#' @examples
#' 
#' Sys.setenv("BIRDDB_HOME"=tempdir())
#' tar <- ebird_sample_data()
#' import_ebird(tar)
#' con <- ebird_conn()
#' 
ebird_conn <- function() {
  
  tblname <- "ebd"
  parquet <- ebird_parquet_files()
  
  ## Seems to use ~ 9 GB RAM still -- maybe just duckdb taking advantage of available RAM
  conn <- DBI::dbConnect(duckdb::duckdb())
  
  ## Create a "View" in duckdb to the parquet file
  query <- paste0("CREATE VIEW '", tblname,
                  "' AS SELECT * FROM parquet_scan('",
                  parquet, "');")
  
  
  DBI::dbSendQuery(conn, query)
  
  conn
  
}

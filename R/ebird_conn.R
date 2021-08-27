
#' A `[DBI]`-style database connection to the imported eBird data
#' 
#' Returns a database connection to the local eBird dataset.
#' @export
#' 
#' @examples
#' # tempdir settings are just for testing! Don't copy this.
#' Sys.setenv("BIRDDB_HOME"=tempdir())
#' 
#' tar <- ebird_sample_data()
#' import_ebird(tar)
#' con <- ebird_conn()
#' 
ebird_conn <- function() {
  
  tblname <- "ebd"
  parquet <- ebird_parquet_files()
  
  ## Is it worth persisting the duckdb connection on disk to avoid
  ## recreating the View? (~ 9m operation)
  conn <- DBI::dbConnect(duckdb::duckdb(), file.path(ebird_db_dir()))
  #conn <- DBI::dbConnect(duckdb::duckdb())
  
  #limit <- 4
  #DBI::dbExecute(con, paste0("PRAGMA memory_limit='", limit, "GB'"))
  
  ## Create a "View" in duckdb to the parquet file
  if(! tblname %in% DBI::dbListTables(conn)){
    query <- paste0("CREATE VIEW '", tblname,
                  "' AS SELECT * FROM parquet_scan('",
                  parquet, "');")
    DBI::dbSendQuery(conn, query)
  }
  conn
  
}


## 
ebird_conn_arrow <- function() {
  con <- DBI::dbConnect(duckdb::duckdb())
  dir <- file.path(ebird_data_dir(), "parquet")
  
  # ds <- arrow_open_ebird_txt("/minio/shared-data/ebd_relJul-2021.txt.gz", dir)
  ds <- arrow::open_dataset(dir)
  ## OOM & crashes
  duckdb::duckdb_register_arrow(con, "ebd", ds)
  con
}



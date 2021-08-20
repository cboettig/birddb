
#' Return a remote data.frame connection to your local ebird database
#' 
#' @export
ebird <- function() {
  assert_ebird_imported()
  conn <- ebird_conn()
  dplyr::tbl(conn, "ebd")
}



assert_ebird_imported <- function(){
  parquet_data <- file.path(ebird_data_dir(), "parquet")
  stopifnot(file.exists(parquet_data))
}

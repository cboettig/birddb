
#' Return a remote data.frame connection to your local ebird database
#' 
#' @param conn a connection to the local ebird database, see `[ebird_conn]`.
#' @export
#' @examples
#' 
#' Sys.setenv("BIRDDB_HOME"=tempdir())
#' tar <- ebird_sample_data()
#' import_ebird(tar)
#' df <- ebird()
#' 
ebird <- function(conn = ebird_conn()) {
  assert_ebird_imported()
  dplyr::tbl(conn, "ebd")
}



assert_ebird_imported <- function(){
  parquet_data <- file.path(ebird_data_dir(), "parquet")
  stopifnot(file.exists(parquet_data))
}

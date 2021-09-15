#' Retrieve directory used to store eBird data parquet files
#'
#' Show the location used by `birddb` to store eBird data parquet files. The
#' default location is that chosen by R based on your OS, see
#' [tools::R_user_dir()]. Alternately, users can configure a different permanent
#' storage location by setting their desired path in the environmental variable
#' `BIRDDB_HOME`. This may be desirable when multiple users of the same machine
#' or server want to access a single copy of the eBird data. To set
#' `BIRDDB_HOME`, add it to your `.Renviron` file, for example by using
#' `usethis::edit_r_environ()`.
#' 
#' @export
#' @examples
#' ebird_data_dir()
ebird_data_dir <- function() {
  Sys.getenv("BIRDDB_HOME", 
             tools::R_user_dir("birddb", "data")
  )
}

# a location for duckdb view files
# very small, but should not be shared between users
# currently defaults to storing in memory, making it ephemeral
ebird_db_dir <- function() {
  path <- Sys.getenv("BIRDDB_DUCKDB", ":memory:")
  if (path == ":memory:") {
    return(path)
  }
  dir.create(path, recursive = TRUE, showWarnings = FALSE)
  file.path(path, "database")
}
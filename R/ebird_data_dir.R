
#' ebird data dir
#' 
#' Show the location ebird uses to store data. The default location is that 
#' chosen by R based on your OS, see `[tools::R_user_dir]`. 
#' Alternately, users can configure a different permanent storage location by
#' setting their desired path in the environmental variable BIRDDB_HOME.
#' This may be desirable when multiple users of the same machine or server want
#' to access a single copy of the ebird data.
#' @export
#' @examples
#' ebird_data_dir()
ebird_data_dir <- function() {
  Sys.getenv("BIRDDB_HOME", 
             tools::R_user_dir("birddb", "data")
  )
}

# a location for duckdb view files.  very small, but should not be shared between users
ebird_db_dir <- function() {
  path <- Sys.getenv("BIRDDB_DUCKDB", ":memory:")
  if(path == ":memory:") return(path)
  dir.create(path, recursive = TRUE)
  file.path(path, "database")
}

ebird_parquet_files <- function() {
  dir <- file.path(ebird_data_dir(), "parquet")
  # List of all parquet files
  file <- list.files(dir, pattern = "[.]parquet", 
                     full.names = TRUE, recursive = TRUE)
  
  ## duckdb does not exploit partitioning
  #paste0(dir, "/*/*/*/*")  
  file
}

#' Provide path to a small subset of ebird data
#' 
#' Sample data is based on the official sample download from July 2021.
#' Sample is modified slightly to better match the official full download:
#' archive uses `tar` format instead of `zip`, and the `ebd_*` table is 
#' compressed with `gzip`, as in the full tar archive distributions.
#' This data should be used for testing purposes only.
#' @export
#' @examples
#' ebird_sample_data()
ebird_sample_data <- function(){
  system.file("extdata", "ebd_relJul-2021.tar", package = "birddb", 
              mustWork = TRUE)
}


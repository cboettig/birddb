
#' ebird data dir
#' 
#' Show the location ebird uses to store data. The default location is that 
#' chosen by R based on your OS, see `[tools::R_user_dir]`. 
#' Alternately, users can configure a different permanent storage location by
#' setting their desired path in the environmental variable BIRDDB_HOME.
#' This may be desirable when multiple users of the same machine or server want
#' to access a single copy of the ebird data.
#' @export
ebird_data_dir <- function() {
  Sys.getenv("BIRDDB_HOME", 
             tools::R_user_dir("birddb", "data")
  )
}


ebird_parquet_files <- function() {
  dir <- file.path(ebird_data_dir(), "parquet")
  # List of all parquet files
  list.files(dir, pattern = "[.]parquet", full.names = TRUE, recursive = TRUE)
}


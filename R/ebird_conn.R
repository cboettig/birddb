#' Set up a `DBI`-style database connection to the imported eBird data
#' 
#' Parquet files can be accessed as though they were relational database tables 
#' by setting up a view to the file using DuckDB. This function sets up a view 
#' on either the checklist or observation dataset and returns a [DBI]-style 
#' database connection to the data. The returned object can then be queried 
#' with SQL syntax via [DBI] or with [dplyr] syntax via [dbplyr]. For the latter 
#' approach, consider using the [checklists()] and [observations()] functions 
#' which will return [tbl] objects ready for access using [dplyr] syntax.
#' 
#' @param dataset the type of dataset to set up a connection to, either the 
#'   observations of checklists.
#' @param memory_limit the memory limit for DuckDB.
#' 
#' @return A [DBI] connection object using to communicate with the DuckDB 
#'   database containing the eBird data.
#' @export
#' @examples
#' # only use a tempdir for this example, don't copy this for real data
#' temp_dir <- file.path(tempdir(), "birddb")
#' Sys.setenv("BIRDDB_HOME" = temp_dir)
#' 
#' # get the path to a sample dataset provided with the package
#' tar <- sample_observation_data()
#' # import the sample dataset to parquet
#' import_ebird(tar)
#' # set up the database connection
#' con <- ebird_conn(dataset = "observations")
#' 
#' unlink(temp_dir, recursive = TRUE)
ebird_conn <- function(dataset = c("observations", "checklists"), 
                       memory_limit = 4) {
  dataset <- match.arg(dataset)
  stopifnot(is.numeric(memory_limit), length(memory_limit) == 1,
            !is.na(memory_limit), memory_limit > 0)
  parquet <- ebird_parquet_files(dataset = dataset)
  
  ## Is it worth persisting the duckdb connection on disk to avoid
  ## recreating the View? (~ 9m operation)
  conn <- DBI::dbConnect(drv = duckdb::duckdb(), ebird_db_dir())
  
  DBI::dbExecute(conn = conn, 
                 paste0("PRAGMA memory_limit='", memory_limit, "GB'"))
  
  # create a "View" in duckdb to the parquet file
  if (!dataset %in% DBI::dbListTables(conn)) {
    query <- paste0("CREATE VIEW '", dataset,
                    "' AS SELECT * FROM parquet_scan('",
                    parquet, "');")
    DBI::dbSendQuery(conn, query)
  }
  return(conn)
}

ebird_parquet_files <- function(dataset = c("observations", "checklists")) {
  dataset <- match.arg(dataset)
  
  # list of all parquet files
  dir <- file.path(ebird_data_dir(), dataset)
  file <- list.files(dir, pattern = "[.]parquet", 
                     full.names = TRUE, recursive = TRUE)
  
  # currently we're assuming no partitioning is being used hence 1 file
  # will need to modify later if partitioning is implemented
  if (length(file) == 0) {
    stop("No parquet files found in: ", dir)
  } else if (length(file) > 1) {
    stop("Expecting one parquet file, multiple files found in: ", dir)
  }
  
  return(file)
}

# ebird_conn_arrow <- function() {
#   con <- DBI::dbConnect(duckdb::duckdb())
#   dir <- file.path(ebird_data_dir(), "parquet")
# 
#   # ds <- arrow_open_ebird_txt("/minio/shared-data/ebd_relJul-2021.txt.gz", dir)
#   ds <- arrow::open_dataset(dir)
#   ## OOM & crashes
#   duckdb::duckdb_register_arrow(con, "ebd", ds)
#   con
# }

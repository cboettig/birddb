#' Return a remote connection to a table in your local eBird database
#'
#' Parquet files setup with a view in a DuckDB database, as done by
#' [ebird_conn()], can be queried with [dplyr] syntax. This function sets up
#' [tbl_dbi] object, which are remote tables referencing either the checklist or
#' observation dataset. These remote tables can then by queried with [dplyr]
#' similarly to a [data.frame].
#' 
#' @param conn a connection to the local eBird database, see [ebird_conn()].
#' 
#' @details 
#' When working with a remote table in [dplyr], the primary different compared
#' to working with a normal [data.frame] is that calls are evaluated lazily,
#' generating SQL that is only sent to the database when you request the data. 
#' The [dplyr] functions [collect()] and [compute()] can be used to force 
#' evaluation.
#' 
#' @return A [tbl_dbi] object referencing either the checklist or observation 
#'   data in DuckDB.
#' @name ebird_tbl
#' @examples
#' # only use a tempdir for this example, don't copy this for real data
#' temp_dir <- file.path(tempdir(), "birddb")
#' Sys.setenv("BIRDDB_HOME" = temp_dir)
#' 
#' # get the path to a sample dataset provided with the package
#' tar <- sample_observation_data()
#' # import the sample dataset to parquet
#' import_ebird(tar)
#' 
#' # set up the database connection to the observations data
#' observations <- observations()
#' # query the data, number of observations of each species
#' dplyr::count(observations, common_name)
#' 
#' unlink(temp_dir, recursive = TRUE)
NULL

#' @rdname ebird_tbl
#' @export
observations <- function(conn = ebird_conn("observations")) {
  dplyr::tbl(conn, "observations")
}

#' @rdname ebird_tbl
#' @export
checklists <- function(conn = ebird_conn("checklists")) {
  dplyr::tbl(conn, "checklists")
}

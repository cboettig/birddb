

#' ebird remote
#'
#' Connect to an eBird snapshot remote. Can be much faster than downloading
#' for one-off use or when using the package from a server in the same region
#' as the data.
#'
#' @param version eBird snapshot date
#' @param bucket eBird bucket name (including region)
#' @param to_duckdb Return a remote duckdb connection or arrow connection?
#'   Note that leaving as FALSE may be faster but is limited to the dplyr-style
#'   operations supported by [arrow] alone.
#' @param ... additional parameters passed to the s3_bucket() (e.g. for remote
#'  access to independently hosted buckets)
#' @examplesIf interactive()
#' @export
#'
ebird_remote <-
    function(version = "Jul-2021",
            bucket = "ebird",
            to_duckdb = FALSE,
            host = "minio.cirrus.carlboettiger.info",
            ...) {

    server <- arrow::s3_bucket(bucket, endpoint_override = host)
    path <- server$path(paste0(version, "/observations"))
    df <- arrow::open_dataset(path)
    if (to_duckdb) {
        if (!requireNamespace("dplyr", quietly = TRUE))
            stop("please install dplyr to use duckdb-based format")
        tbl <- getExportedValue("dplyr", "tbl")
        df <- arrow::to_duckdb(df)
    }
    df
}

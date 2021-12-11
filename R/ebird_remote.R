

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
#' @param dataset name of dataset (table) to access.
#' @param host Remote S3-based host of eBird parquet data
#' @param ... additional parameters passed to the s3_bucket() (e.g. for remote
#'  access to independently hosted buckets)
#' @examplesIf interactive()
#' @export
#'
ebird_remote <-
  function(dataset = c("observations", "checklists"),
           version = "Oct-2021",
           bucket = "ebird",
           to_duckdb = FALSE,
           host = "minio.cirrus.carlboettiger.info",
           ...) {
    dataset <- match.arg(dataset)
    
    ## Not ideal, but these will cause problems if set
    unset_aws_env()
    
    server <- arrow::s3_bucket(bucket,
                               endpoint_override = host,
                               ...)
    
    path <- server$path(file.path(version, dataset, fsep = "/"))
    df <- arrow::open_dataset(path)
    if (to_duckdb) {
      df <- arrow::to_duckdb(df)
    }
    df
  }



unset_aws_env <- function() {
  ## Consider re-setting these afterwards.
  ## What about ~/.aws ?
  ## Maybe set these to empty strings instead of unsetting?
  
  ## Would be nice if we could simply override the detection of these
  Sys.unsetenv("AWS_DEFAULT_REGION")
  Sys.unsetenv("AWS_S3_ENDPOINT")
  Sys.unsetenv("AWS_ACCESS_KEY_ID")
  Sys.unsetenv("AWS_SECRET_ACCESS_KEY")
}

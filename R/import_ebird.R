
#' import ebird
#' 
#' Given a path to the ebird tarfile, this function will extract and import the 
#' tar archive into a parquet-based database in your [`ebird_data_dir()`]
#' 
#' @param tarfile path to the copy of `ebd_rel<DATE>.tar` file you downloaded
#' 
#' @export
#' @examples
#' 
#' Sys.setenv("BIRDDB_HOME"=tempdir())
#' tar <- ebird_sample_data()
#' import_ebird(tar)
#' 
import_ebird <- function(tarfile){
  
  source_dir <- tempfile("ebird_tmp")
  dir.create(source_dir, recursive = TRUE)
  
  utils::untar(tarfile = tarfile, exdir = source_dir)
  ebd <-list.files(source_dir, pattern="ebd.*\\.txt\\.gz", full.names = TRUE, recursive = TRUE)
  
  ## a bit of ugliness in determining the schema arrow wants, can probably be improved now
  ds <- arrow::open_dataset(ebd, format="text", delim="\t")
  col_names <- names(ds)
  col_names <- col_names[col_names != ""] # drop empty column (in sample data)
  col_types <- "stisssssssssssssssssisssssddtssssssiddiisiiisss"
  x <- strsplit(col_types, "")[[1]]
  expand_schema = list(s = arrow::string(), i = arrow::int64(), 
                       d = arrow::float64(), t= arrow::timestamp(unit="us"),
                       D = arrow::date64())
  ebd_schema <- expand_schema[x]
  names(ebd_schema) <- col_names
  sch <- do.call(arrow::schema, ebd_schema)
  
  # Once we have the schema, streaming is easy!
  dest <- file.path(ebird_data_dir(), "parquet")
  ds <- arrow::open_dataset(ebd, format="text", delim="\t", schema = sch)
  
  # Consider alternative partitions that might speed common queries
  # partitioning = c("COUNTRY", "STATE", "SUBSPECIES SCIENTIFIC NAME")
  # NOPE: duckdb doesn't yet support partitioning; multiple parquet files 
  # can be read in but partition columns are lost this way.
  
  arrow::write_dataset(ds, dest, format="parquet")
  
  invisible(dest)
}


# Download URLs, eg https://download.ebird.org/ebd/prepackaged/ebd_relJul-2021.tar
# Note, may take > 24hrs to complete

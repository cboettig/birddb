
#' import ebird
#' 
#' Given a path to the ebird tarfile, this function will extract and import the 
#' tar archive into a parquet-based database in your [`ebird_data_dir()`]
#' 
#' @param tarfile path to the copy of ebd_rel<DATE>.tar file you downloaded
#' 
#' @export
import_ebird <- function(tarfile){
  
  source_dir <- tempfile("ebird")
  dir.create(source_dir)
  
  ## Untar is slow, consider progress bars? consider `archive` packages
  untar(tarfile = tarfile, exdir = source_dir)
  
  ebd <-list.files(source_dir, pattern="ebd.*\\.txt\\.gz", full.names = TRUE)
  
  ## a bit of ugliness in determining the schema arrow wants, can probably be improved now
  ds <- arrow::open_dataset(ebd, format="text", delim="\t")
  col_names <- names(ds)
  col_types <- "stissssssssssssssssisssssddtssssssiddiisiiisss"
  x <- strsplit(col_types, "")[[1]]
  expand_schema = list(s = arrow::string(), i = arrow::int64(), d = arrow::float64(), t= arrow::timestamp())
  ebd_schema <- expand_schema[x]
  names(ebd_schema) <- col_names
  sch <- do.call(arrow::schema, ebd_schema)
  
  # Once we have the schema, streaming is easy!
  dest <- file.path(ebird_data_dir(), "parquet")
  ds <- arrow::open_dataset(ebd, format="text", delim="\t", schema = sch)
  # Consider `partitioning = c("COUNTRY", "STATE"))`
  arrow::write_dataset(ds, dest, format="parquet") 
  
  invisible(dest)
}

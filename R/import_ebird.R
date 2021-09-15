#' Import eBird data to parquet
#' 
#' eBird data are released as tab-separated text files, packaged into tar
#' archives. Given a path to an eBird tarfile, this function will extract and
#' import the tar archive into a parquet-based database in your
#' [`ebird_data_dir()`].
#' 
#' @param tarfile path to the tar archive file downloaded from the eBird
#'   website. Files containing either observation data (e.g.
#'   `ebd_rel<DATE>.tar`) or checklist (e.g. `ebd_sampling_rel<DATE>.tar`) data
#'   can be provided
#' 
#' @export
#' @examples
#' # only use a tempdir for this example, don't copy this line for real data
#' Sys.setenv("BIRDDB_HOME" = tempdir())
#' # get the path to a sample dataset provided with the package
#' tar <- ebird_sample_data()
#' import_ebird(tar)
import_ebird <- function(tarfile) {
  file_metadata <- parse_ebd_filename(tarfile)
  dest <- file.path(ebird_data_dir(), file_metadata[["type"]])
  
  # extract the tarfile to a temp directory
  source_dir <- tempfile("ebird_tmp")
  dir.create(source_dir, recursive = TRUE)
  utils::untar(tarfile = tarfile, exdir = source_dir)
  ebd <- list.files(source_dir, pattern = "ebd.*\\.txt\\.gz",
                   full.names = TRUE, recursive = TRUE)
  if (length(ebd) != 1 || !file.exists(ebd)) {
    stop("txt.gz file not successfully extracted from tarfile.")
  }
  
  # open tsv and stream to parquet
  ds <- arrow_open_ebird_txt(ebd, dest)
  
  # confirm overwrite
  if (dir.exists(dest)) {
    if (interactive()) {
      msg <- paste("eBird", file_metadata[["type"]], 
                   "data already exists in BIRDDB_HOME,",
                   "would you like to overwrite this data?")
      overwrite <- utils::askYesNo(msg, default = NA)
      if (isTRUE(overwrite)) {
        unlink(dest, recursive = TRUE)
      } else {
        stop("Cancelling data import to avoid overwriting existing data.")
      }
    } else {
      message("Overwriting existing eBird ", file_metadata[["type"]], " data.")
      unlink(dest, recursive = TRUE)
    }
  }
  
  arrow::write_dataset(ds, dest, format = "parquet")
  
  unlink(source_dir, recursive = TRUE)
  invisible(dest)
}

arrow_open_ebird_txt <- function(ebd, dest) {
  ds <- arrow::open_dataset(ebd, format = "text", delim = "\t")
  col_names <- names(ds)
  # drop the empty column that appears at the end of edb files
  col_names <- col_names[col_names != ""] 
  col_types <- ebird_col_type(col_names)
  expand_schema = list(string = arrow::string(), 
                       binary = arrow::binary(),
                       integer = arrow::int64(), 
                       double = arrow::float64(),
                       timestamp = arrow::timestamp(unit = "us"),
                       date = arrow::date64())
  ebd_schema <- expand_schema[col_types]
  names(ebd_schema) <- col_names
  sch <- do.call(arrow::schema, ebd_schema)
  
  # based on the schema defined above open tsv file for streaming
  ds <- arrow::open_dataset(ebd, format = "text", delim = "\t", schema = sch)
  
  # clean up column names
  col_names <- names(ds)
  names(col_names) <- gsub("[/ ]", "_", tolower(col_names))
  ds <- dplyr::select(ds, dplyr::all_of(col_names))
  
  return(ds)
}

ebird_col_type <- function(col_names) {
  # types for columns that are not character
  col_types <- c(`LAST EDITED DATE` = "timestamp", 
                 `TAXONOMIC ORDER` = "integer", 
                 `BCR CODE` = "integer", 
                 `LATITUDE` = "double", `LONGITUDE` = "double", 
                 `OBSERVATION DATE` = "timestamp",
                 `DURATION MINUTES` = "integer", 
                 `EFFORT DISTANCE KM` = "double", 
                 `EFFORT AREA HA` = "double", 
                 `NUMBER OBSERVERS` = "integer", 
                 `ALL SPECIES REPORTED` = "integer", 
                 `HAS MEDIA` = "integer", 
                 `APPROVED` = "integer", 
                 `REVIEWED` = "integer")
  # assume anything else is character
  col_types <- col_types[col_names]
  col_types[is.na(col_types)] <- "string"
  setNames(col_types, col_names)
}

parse_ebd_filename <- function(tarfile) {
  stopifnot(is.character(tarfile), length(tarfile) == 1, file.exists(tarfile))
  
  f <- basename(tarfile)
  # checks for validity of filename
  if (!grepl("\\.tar$", f)) {
    stop("The provided file does not appear to be a tar archive. The file ",
         "extension should be .tar.")
  }
  if (grepl("ebd_sampling_rel[A-Z]{1}[a-z]{2}-[0-9]{4}\\.tar$", f)) {
    data_type <- "checklist"
    subset <- NA_character_
  } else if (grepl("ebd_rel[A-Z]{1}[a-z]{2}-[0-9]{4}\\.tar$", f)) {
    data_type <- "observation"
    subset <- NA_character_
  } else if (grepl("ebd_[-_A-Za-z0-9]+_rel[A-Z]{1}[a-z]{2}-[0-9]{4}\\.tar$", f)) {
    data_type <- "observation"
    subset <- sub("ebd_([-_A-Za-z0-9]+)_rel[A-Z]{1}[a-z]{2}-[0-9]{4}\\.tar", 
                  "\\1", f)
  } else {
    stop("The provided tar filename does not appear to contain eBird data. ", 
         "The expected format is, e.g., ebd_relJul-2021.tar.")
  }
  
  # parse date from filename
  rawdate <- sub("ebd[-_A-Za-z0-9]*_rel([A-Z]{1}[a-z]{2}-[0-9]{4})\\.tar", 
                 "\\1", f)
  date <- strsplit(rawdate, "-")[[1]]
  date[1] <- match(date[1], month.abb)
  date <- paste(date[2], date[1], "1", sep = "-")
  date <- as.Date(date, format = "%Y-%m-%d")
  if (is.na(date)) {
    stop("Month and year could not be parsed from filename: ", rawdate)
  }
  version = format(date, "%Y-%m")

  msg <- sprintf("Importing %s data from the %s eBird Basic Dataset: %s",
                 data_type, version, f)
  message(msg)
  if (!is.na(subset)) {
    message("EBD subset detected for: ", subset)
  }
  
  # sha256 file hash
  hash <- openssl::sha256(file(tarfile))
  return(data.frame(type = data_type, 
                    version = version,
                    subset = subset, 
                    source_file = tarfile,
                    file_size = file.size(tarfile),
                    hash_sha256 = as.character(hash)[],
                    timestamp = Sys.time()))
}

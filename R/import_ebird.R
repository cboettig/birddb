#' Import eBird data to parquet
#' 
#' eBird data are released as tab-separated text files, packaged into tar
#' archives. Given a path to an eBird tarfile, this function will extract and
#' import the tar archive into a parquet-based database in your
#' [ebird_data_dir()].
#' 
#' @param tarfile path to the tar archive file downloaded from the eBird
#'   website. Files containing either observation data (e.g.
#'   `ebd_rel<DATE>.tar`) or checklist (e.g. `ebd_sampling_rel<DATE>.tar`) data
#'   can be provided
#' @param temp_dir a temporary directory used to store the untarred input file. 
#'   In general, this parameter should be left as the default, which stores will 
#'   use the system temp directory. However, the untarred file is very large (> 
#'   100 GB), and if you run into disk space issues, you may need to change the 
#'   `temp_dir`, for example, to an external drive. Note that **all temporary 
#'   files created by [import_ebird()] prior to the function returning.**.
#'   
#' @details 
#' [eBird](https://ebird.org/home) data are collected and organized around the
#' concept of a checklist, representing observations from a single birding
#' event. Each checklist contains a list of species observed, counts of the
#' number of individuals seen of each species, the location and time of the
#' observations, and a measure of the effort expended while collecting these
#' data. The majority of the [eBird](https://ebird.org/home) database is
#' available for download in the form of the [eBird Basic Dataset
#' (EBD)](https://ebird.org/data/download), a set of two tab-separated text
#' files. 
#' 
#' The **checklist** dataset (referred to as the Sampling Event Data on the
#' eBird website) consists of one row for each eBird checklist and columns
#' contain checklist-level information such as location, date, and search
#' effort. The **observation** dataset consists of one row for each species
#' observed on each checklist and columns contain checklist-level information
#' such as number of individuals detected. This dataset also contains all
#' checklist-level variables, duplicated for each species on the same checklist.
#'
#' After [submitting a request for data
#' access](https://ebird.org/data/download), users can download either or both
#' of these datasets as tar archive files. `import_ebird()` takes the path to a
#' tar file as input and imports the text file contained within to a parquet
#' file, which will allow much easier access to the data. This function will
#' automatically detect whether you are importing a checklist or observation
#' dataset provided you **do not change the name of the downloaded file or
#' unarchive the tar file**. The parquet files will be stored in the directory
#' specified by [ebird_data_dir()], consult the help for that function to learn
#' how to modify the parquet directory.
#' 
#' @return Invisibly return the path to the directory containing eBird parquet
#'   files.
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
#' 
#' unlink(temp_dir, recursive = TRUE)
import_ebird <- function(tarfile, temp_dir = tempdir(check = TRUE)) {
  if (is_checklists(tarfile)) {
    dataset <- "checklists"
  } else if (is_observations(tarfile, allow_subset = FALSE)) {
    dataset <- "observations"
  } else if (is_observations(tarfile, allow_subset = TRUE)) {
    stop("It appears you downloaded a subset of eBird data using the ",
         "Custom Download form. birddb currently only supports importing ",
         "the full eBird Basic Dataset.")
  } else {
    stop("Non-stardard eBird data filename provided: ", basename(tarfile))
  }
  dest <- file.path(ebird_data_dir(), dataset)
  
  stopifnot(is.character(temp_dir), length(temp_dir) == 1, dir.exists(temp_dir))
  
  # confirm overwrite
  if (dir.exists(dest)) {
    if (interactive()) {
      msg <- paste("eBird", dataset, "data already exists in BIRDDB_HOME,",
                   "would you like to overwrite this data?")
      overwrite <- utils::askYesNo(msg, default = NA)
      if (!isTRUE(overwrite)) {
        warning("Cancelling data import to avoid overwriting existing data.")
        return(invisible())
      }
    } else {
      message("Overwriting existing eBird ", dataset, " data.")
    }
  }
  
  message(sprintf("Importing %s data from the eBird Basic Dataset: %s",
                  dataset, basename(tarfile)))
  
  # extract the tarfile to a temp directory
  source_dir <- tempfile("ebird_tmp", tmpdir = temp_dir)
  dir.create(source_dir, recursive = TRUE)
  utils::untar(tarfile = tarfile, exdir = source_dir)
  ebd <- list.files(source_dir, pattern = "ebd.*\\.txt\\.gz",
                    full.names = TRUE, recursive = TRUE)
  if (length(ebd) != 1 || !file.exists(ebd)) {
    stop("txt.gz file not successfully extracted from tarfile.")
  }
  
  # open tsv and set up data schema
  ds <- arrow_open_ebird_txt(ebd, dest)
  
  # stream to parquet
  arrow::write_dataset(ds, dest, format = "parquet")
  
  # save metadata
  record_metadata(tarfile)
  
  unlink(source_dir, recursive = TRUE)
  invisible(dest)
}

arrow_open_ebird_txt <- function(ebd, dest) {
  ds <- arrow::open_dataset(ebd, format = "text", delim = "\t")
  col_names <- names(ds)
  
  # provide names to empty columns to be dropped later
  empty_cols <- which(col_names == "")
  if (length(col_names) > 0) {
    col_names[empty_cols] <- paste0(".dropcol_", seq_along(empty_cols))
  }
  
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
  ds <- dplyr::select(ds, -dplyr::starts_with(".dropcol"))
  
  return(ds)
}

ebird_col_type <- function(col_names) {
  # types for columns that are not character
  col_types <- c(`LAST EDITED DATE` = "timestamp", 
                 `TAXONOMIC ORDER` = "integer", 
                 `LATITUDE` = "double", `LONGITUDE` = "double", 
                 `OBSERVATION DATE` = "date",
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
  names(col_types) <- col_names
  return(col_types)
}

record_metadata <- function(tarfile) {
  stopifnot(is.character(tarfile), length(tarfile) == 1, file.exists(tarfile))
  
  f <- basename(tarfile)
  if (is_checklists(f)) {
    dataset <- "checklists"
    subset <- NA_character_
  } else if (is_observations(f, allow_subset = FALSE)) {
    dataset <- "observations"
    subset <- NA_character_
  # todo: implement ability to import ebd subset, currently in a zip file
  # } else if (is_observations(f, allow_subset = TRUE)) {
  #   dataset <- "observations"
  #   subset <- sub("ebd_([-_A-Za-z0-9]+)_rel[A-Z]{1}[a-z]{2}-[0-9]{4}\\.tar",
  #                 "\\1", f)
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
  
  if (!is.na(subset)) {
    message("EBD subset detected for: ", subset)
  }
  
  # sha256 file hash
  hash <- digest::digest(tarfile, algo = "crc32", file = TRUE)
  
  # save to csv
  file_metadata <- data.frame(dataset = dataset, 
                              version = version,
                              subset = subset, 
                              source_file = tarfile,
                              file_size = file.size(tarfile),
                              hash_crc32 = as.character(hash)[],
                              timestamp = Sys.time())
  f_metadata <- file.path(ebird_data_dir(),
                          paste0(dataset, "-metadata.csv"))
  utils::write.csv(file_metadata, file = f_metadata, row.names = FALSE, na = "")
  
  invisible(file_metadata)
}


is_checklists <- function(x) {
  x <- basename(x)
  if (!grepl("\\.tar$", x)) {
    stop("The provided file does not appear to be a tar archive. The file ",
         "extension should be .tar.")
  }
  grepl("ebd_sampling_rel[A-Z]{1}[a-z]{2}-[0-9]{4}\\.tar$", x)
}

is_observations <- function(x, allow_subset = FALSE) {
  x <- basename(x)
  if (!grepl("\\.tar$", x)) {
    stop("The provided file does not appear to be a tar archive. The file ",
         "extension should be .tar.")
  }
  is_obs <- grepl("ebd_rel[A-Z]{1}[a-z]{2}-[0-9]{4}\\.tar$", x)
  if (allow_subset) {
    is_ss <- grepl("ebd[-_A-Za-z0-9]*_rel[A-Z]{1}[a-z]{2}-[0-9]{4}\\.zip$", x)
    is_obs <- is_obs | is_ss
  }
  return(is_obs)
}
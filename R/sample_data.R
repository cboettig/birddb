#' Provide path to a small subset of eBird data
#' 
#' These small sample dataset consists of all observations from Hong Kong in the 
#' year 2012. Sample files are provided for checklist and observation data, both 
#' packaged as tar archive files to mimic the format of the eBird Basic Dataset 
#' download.
#' 
#' @name sample_data
#' @return The path to the sample tar archive file.
#' @examples
#' sample_checklist_data()
#' sample_observation_data()
NULL

#' @export
#' @rdname sample_data
sample_checklist_data <- function() {
  system.file("extdata", "ebd_sampling_relAug-2021.tar", package = "birddb", 
              mustWork = TRUE)
}

#' @export
#' @rdname sample_data
sample_observation_data <- function() {
  system.file("extdata", "ebd_relAug-2021.tar", package = "birddb", 
              mustWork = TRUE)
}

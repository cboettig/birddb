
## fixme: group_by scientific_name instead?
subspecies_merge_counts <- function(obs) {
  groups <- c("sampling_event_identifier", "scientific_name")
  obs |>
    # try to read in with "X" as `NA` instead?
    #dplyr::mutate(observation_count = as.integer(observation_count)) %>% 
    # re-join or add additional columns so they are not lost
    dplyr::group_by(dplyr::any_of(groups)) |> 
    dplyr::summarize(observation_count = sum(observation_count),
                     species_detected = any(is.na(observation_count) | 
                                            observation_count > 0), 
                     .groups = "drop")
}
#' @importFrom utils globalVariables
globalVariables("observation_count", package="birddb")


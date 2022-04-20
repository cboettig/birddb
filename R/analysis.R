
## fixme: group_by scientific_name instead?
subspecies_merge_counts <- function(obs) {
  ## ick still crashes
  merged_counts <- obs |> 
    dplyr::select(sampling_event_identifier, scientific_name, observation_count) |>
    dplyr::group_by(sampling_event_identifier, scientific_name) |>
    dplyr::summarize(count = sum(observation_count, na.rm=TRUE),  .groups = "drop")  |>
    dplyr::mutate(species_detected = count > 0)
                    
  x <- merged_counts |> dplyr::compute()
  
}
#' @importFrom utils globalVariables
globalVariables("observation_count", package="birddb")


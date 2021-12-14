


## fixme: group_by scientific_name instead?
subspecies_merge_counts <- function(obs) {
  obs %>%
    # try to read in with "X" as `NA` instead?
    #dplyr::mutate(observation_count = as.integer(observation_count)) %>% 
    
    # re-join or add additional columns so they are not lost
    dplyr::group_by(sampling_event_identifier, scientific_name) %>% 
    dplyr::summarize(observation_count = sum(observation_count),
                     species_detected = any(is.na(observation_count) | 
                                            observation_count > 0), 
                     .groups = "drop")
}


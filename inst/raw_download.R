base <- "https://download.ebird.org/ebd/prepackaged/"
snapshot <- "Mar-2022"
checklists <- paste0(base, "ebd_sampling_rel", snapshot, ".tar") 
observations <- paste0(base, "ebd_rel", snapshot, ".tar")
raw <- file.path(ebird_data_dir(), "raw")


download.file(checklists,
              file.path(raw,basename(checklists)),
              method="wget")
download.file(observations,
              file.path(raw,basename(observations)),
              method="wget")


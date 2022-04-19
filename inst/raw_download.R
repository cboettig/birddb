base <- "https://download.ebird.org/ebd/prepackaged/"
snapshot <- "Mar-2022"
checklists <- paste0(base, "ebd_sampling_rel", snapshot, ".tar") 
observations <- paste0(base, "ebd_rel", snapshot, ".tar")
raw <- file.path(birddb::ebird_data_dir(), "raw")
dir.create(raw)

download.file(checklists,
              file.path(raw,basename(checklists)),
              method="wget", quiet=TRUE)
download.file(observations,
              file.path(raw,basename(observations)),
              method="wget", quiet=TRUE)



base <- "https://minio.thelio.carlboettiger.info/ebird/"

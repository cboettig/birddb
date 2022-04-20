base <- "https://minio.thelio.carlboettiger.info/ebird/"
base <- "https://download.ebird.org/ebd/prepackaged/"
snapshot <- "Mar-2022"
checklists <- paste0(base, "ebd_sampling_rel", snapshot, ".tar") 
observations <- paste0(base, "ebd_rel", snapshot, ".tar")
raw <- file.path(birddb::ebird_data_dir(), "raw")
dir.create(raw)

## 
download.file(checklists,
              file.path(raw,basename(checklists)),
              method="wget", quiet=TRUE)
download.file(observations,
              file.path(raw,basename(observations)),
              method="wget", quiet=TRUE)


raw <- file.path(birddb::ebird_data_dir(), "raw")
occurrences <- file.path(raw, "ebd_relJul-2021.tar")
checklists <- file.path(raw, "ebd_sampling_relMar-2022.tar")

import_ebird(checklists)
import_ebird(occurrences)



## 
library(arrow)
library(duckdb)
library(birddb)
#chklst <- arrow::open_dataset( file.path(ebird_data_dir(), "checklists") )
obs <- arrow::open_dataset(file.path(ebird_data_dir(), "observations") )

obs <- obs |> to_duckdb()

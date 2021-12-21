
<!-- README.md is generated from README.Rmd. Please edit that file -->

# birddb

<!-- badges: start -->

[![R-CMD-check](https://github.com/cboettig/birddb/workflows/R-CMD-check/badge.svg)](https://github.com/cboettig/birddb/actions)
[![Codecov test
coverage](https://codecov.io/gh/cboettig/birddb/branch/main/graph/badge.svg)](https://codecov.io/gh/cboettig/birddb?branch=main)
[![CRAN
status](https://www.r-pkg.org/badges/version/birddb)](https://CRAN.R-project.org/package=birddb)
<!-- badges: end -->

The goal of `birddb` is to provide a relational database interface to a
local copy of eBird. `birddb` works by importing the text-based ebird
file into a local parquet file using
[arrow](https://cran.r-project.org/package=arrow), which can be queried
as a relational database using the familiar `dplyr` interface. `dplyr`
translates R-based queries into SQL commands which are past to
[`duckdb`](https://duckdb.org), which then queries the parquet database.
Unlike the native `arrow` interface, `duckdb` supports the full set of
SQL instructions, including windowed operations like
`group_by`+`summarise` as well as table joins.

## Installation

<!-- 
You can install the released version of `birddb` from
[CRAN](https://CRAN.R-project.org) with:

``` r
install.packages("birddb")
```
--> 

And the development version from [GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
devtools::install_github("cboettig/birddb")
```

## Getting Started

``` r
library(birddb)
library(dplyr)
```

Before you can use `birddb` you will need to download the latest version
of the eBird Basic Dataset from <http://ebird.org/ebird/data/download>.
Once you have obtained a downloaded copy of the `tar` file, `birddb` can
import it for you. The one-time import of the full data dump is a little
slow (about 1 hr in my benchmark) due to the time required to extract
the tar file and convert the text data into parquet format.

For illustration and testing purposes, we will use the small eBird
sample data, included in the package for convenience and testing
purposes:

``` r
observations_tar <- birddb::sample_observation_data()
checklists_tar <- birddb::sample_checklist_data()
```

Importing will now create the local parquet-based copies in the default
directory given by `ebird_data_dir()`. Users can set an alternative
location by setting the environmental variable `BIRDDB_HOME` to the
desired path.

``` r
import_ebird(observations_tar)
#> Importing observations data from the eBird Basic Dataset: ebd_relAug-2021.tar
#> Extracting from tar archive...
#> Importing to parquet...
import_ebird(checklists_tar)
#> Importing checklists data from the eBird Basic Dataset: ebd_sampling_relAug-2021.tar
#> Extracting from tar archive...
#> Importing to parquet...
```

Once the data have been downloaded and imported successfully, a user can
access the full eBird dataset quite quickly:

``` r
observations <- observations()
checklists <- checklists()
```

To see the available columns in each dataset use:

``` r
colnames(observations)
#>  [1] "global_unique_identifier"   "last_edited_date"          
#>  [3] "taxonomic_order"            "category"                  
#>  [5] "common_name"                "scientific_name"           
#>  [7] "subspecies_common_name"     "subspecies_scientific_name"
#>  [9] "observation_count"          "breeding_code"             
#> [11] "breeding_category"          "behavior_code"             
#> [13] "age_sex"                    "country"                   
#> [15] "country_code"               "state"                     
#> [17] "state_code"                 "county"                    
#> [19] "county_code"                "iba_code"                  
#> [21] "bcr_code"                   "usfws_code"                
#> [23] "atlas_block"                "locality"                  
#> [25] "locality_id"                "locality_type"             
#> [27] "latitude"                   "longitude"                 
#> [29] "observation_date"           "time_observations_started" 
#> [31] "observer_id"                "sampling_event_identifier" 
#> [33] "protocol_type"              "protocol_code"             
#> [35] "project_code"               "duration_minutes"          
#> [37] "effort_distance_km"         "effort_area_ha"            
#> [39] "number_observers"           "all_species_reported"      
#> [41] "group_identifier"           "has_media"                 
#> [43] "approved"                   "reviewed"                  
#> [45] "reason"                     "trip_comments"             
#> [47] "species_comments"
colnames(checklists)
#>  [1] "last_edited_date"          "country"                  
#>  [3] "country_code"              "state"                    
#>  [5] "state_code"                "county"                   
#>  [7] "county_code"               "iba_code"                 
#>  [9] "bcr_code"                  "usfws_code"               
#> [11] "atlas_block"               "locality"                 
#> [13] "locality_id"               "locality_type"            
#> [15] "latitude"                  "longitude"                
#> [17] "observation_date"          "time_observations_started"
#> [19] "observer_id"               "sampling_event_identifier"
#> [21] "protocol_type"             "protocol_code"            
#> [23] "project_code"              "duration_minutes"         
#> [25] "effort_distance_km"        "effort_area_ha"           
#> [27] "number_observers"          "all_species_reported"     
#> [29] "group_identifier"          "trip_comments"
```

Now, we can use `dplyr` to perform standard queries. For example, to see
the number of observations for each species in the sample dataset:

``` r
observations %>% count(scientific_name, sort = TRUE)
#> # Source:     lazy query [?? x 2]
#> # Database:   duckdb_connection
#> # Ordered by: desc(n)
#>    scientific_name                n
#>    <chr>                      <dbl>
#>  1 Pycnonotus sinensis          275
#>  2 Pycnonotus jocosus           270
#>  3 Streptopelia chinensis       258
#>  4 Milvus migrans               251
#>  5 Copsychus saularis           228
#>  6 Zosterops simplex            201
#>  7 Acridotheres cristatellus    181
#>  8 Passer montanus              174
#>  9 Pterorhinus perspicillatus   172
#> 10 Motacilla alba               172
#> # … with more rows
```

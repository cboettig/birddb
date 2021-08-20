
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

You can install the released version of `birddb` from
[CRAN](https://CRAN.R-project.org) with:

``` r
install.packages("birddb")
```

And the development version from [GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
devtools::install_github("cboettig/birddb")
```

## Getting Started

``` r
library(birddb)
library(dplyr)
#> 
#> Attaching package: 'dplyr'
#> The following objects are masked from 'package:stats':
#> 
#>     filter, lag
#> The following objects are masked from 'package:base':
#> 
#>     intersect, setdiff, setequal, union
```

Before you can use `birddb` you will need to download the latest version
of eBird from <http://ebird.org/ebird/data/download>. Once you have
obtained a downloaded copy of the `tar` file, `birddb` can import it for
you: The one-time import of the full data dump is a little slow (about 1
hr in my benchmark) due to the time required to extract the tar file and
convert the text data into parquet format.

For illustration & testing purposes, we will use the small eBird sample
data, included in the package for convenience and testing purposes:

``` r
tar <- ebird_sample_data()
```

Importing will now create the local parquet-based copies in the default
directory given by `ebird_data_dir()`. Users can set an alternative
location by setting the environmental variable `BIRDDB_HOME` to the
desired path.

``` r
import_ebird(tar)
```

Once the data have been downloaded and imported successfully, a user can
access the full ebird record quite quickly:

``` r
df <- ebird()
df
#> # Source:   table<ebd> [?? x 47]
#> # Database: duckdb_connection
#>    `GLOBAL UNIQUE I… `LAST EDITED DATE`  `TAXONOMIC ORDE… CATEGORY `COMMON NAME`
#>    <chr>             <dttm>                         <dbl> <chr>    <chr>        
#>  1 URN:CornellLabOf… 2021-03-20 21:48:09            25797 species  Ruby-crowned…
#>  2 URN:CornellLabOf… 2021-03-20 21:48:09            26950 species  Brown Thrash…
#>  3 URN:CornellLabOf… 2021-04-03 23:33:38             7029 species  American Whi…
#>  4 URN:CornellLabOf… 2021-03-20 21:48:09            31943 species  White-throat…
#>  5 URN:CornellLabOf… 2021-03-20 21:48:09            32155 species  Eastern Towh…
#>  6 URN:CornellLabOf… 2021-03-25 12:14:45             2316 species  White-winged…
#>  7 URN:CornellLabOf… 2021-03-08 12:45:11            31986 species  Savannah Spa…
#>  8 URN:CornellLabOf… 2021-03-19 21:23:57            21225 species  Tufted Titmo…
#>  9 URN:CornellLabOf… 2021-03-03 21:23:28            27031 species  Eastern Blue…
#> 10 URN:CornellLabOf… 2021-03-22 01:11:30             5942 species  Wilson's Sni…
#> # … with more rows, and 42 more variables: SCIENTIFIC NAME <chr>,
#> #   SUBSPECIES COMMON NAME <chr>, SUBSPECIES SCIENTIFIC NAME <chr>,
#> #   OBSERVATION COUNT <chr>, BREEDING CODE <chr>, BREEDING CATEGORY <chr>,
#> #   BEHAVIOR CODE <chr>, AGE/SEX <chr>, COUNTRY <chr>, COUNTRY CODE <chr>,
#> #   STATE <chr>, STATE CODE <chr>, COUNTY <chr>, COUNTY CODE <chr>,
#> #   IBA CODE <chr>, BCR CODE <dbl>, USFWS CODE <chr>, ATLAS BLOCK <chr>,
#> #   LOCALITY <chr>, LOCALITY ID <chr>, LOCALITY TYPE <chr>, LATITUDE <dbl>, …
```

Now, we can use `dplyr` to perform standard queries:

``` r
colnames(df)
#>  [1] "GLOBAL UNIQUE IDENTIFIER"   "LAST EDITED DATE"          
#>  [3] "TAXONOMIC ORDER"            "CATEGORY"                  
#>  [5] "COMMON NAME"                "SCIENTIFIC NAME"           
#>  [7] "SUBSPECIES COMMON NAME"     "SUBSPECIES SCIENTIFIC NAME"
#>  [9] "OBSERVATION COUNT"          "BREEDING CODE"             
#> [11] "BREEDING CATEGORY"          "BEHAVIOR CODE"             
#> [13] "AGE/SEX"                    "COUNTRY"                   
#> [15] "COUNTRY CODE"               "STATE"                     
#> [17] "STATE CODE"                 "COUNTY"                    
#> [19] "COUNTY CODE"                "IBA CODE"                  
#> [21] "BCR CODE"                   "USFWS CODE"                
#> [23] "ATLAS BLOCK"                "LOCALITY"                  
#> [25] "LOCALITY ID"                "LOCALITY TYPE"             
#> [27] "LATITUDE"                   "LONGITUDE"                 
#> [29] "OBSERVATION DATE"           "TIME OBSERVATIONS STARTED" 
#> [31] "OBSERVER ID"                "SAMPLING EVENT IDENTIFIER" 
#> [33] "PROTOCOL TYPE"              "PROTOCOL CODE"             
#> [35] "PROJECT CODE"               "DURATION MINUTES"          
#> [37] "EFFORT DISTANCE KM"         "EFFORT AREA HA"            
#> [39] "NUMBER OBSERVERS"           "ALL SPECIES REPORTED"      
#> [41] "GROUP IDENTIFIER"           "HAS MEDIA"                 
#> [43] "APPROVED"                   "REVIEWED"                  
#> [45] "REASON"                     "TRIP COMMENTS"             
#> [47] "SPECIES COMMENTS"
```

``` r
df %>% count(`SCIENTIFIC NAME`, sort=TRUE)
#> # Source:     lazy query [?? x 2]
#> # Database:   duckdb_connection
#> # Ordered by: desc(n)
#>    `SCIENTIFIC NAME`            n
#>    <chr>                    <dbl>
#>  1 Cardinalis cardinalis      125
#>  2 Mimus polyglottos           86
#>  3 Haemorhous mexicanus        73
#>  4 Turdus migratorius          68
#>  5 Sialia sialis               67
#>  6 Zenaida asiatica            66
#>  7 Thryothorus ludovicianus    64
#>  8 Zenaida macroura            64
#>  9 Spinus pinus                54
#> 10 Spizella passerina          44
#> # … with more rows
```

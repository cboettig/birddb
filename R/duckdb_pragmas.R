

duckdb_mem_limit <- function(conn, memory_limit = 16, units = "GB"){
  DBI::dbExecute(conn = conn, 
                 paste0("PRAGMA memory_limit='", memory_limit, units, "'"))
}
# set CPU parallel
duckdb_parallel <- function(conn, mc.cores = options("mc.cores", 2L)){
  DBI::dbExecute(conn, paste0("PRAGMA threads=", mc.cores))
}

## Used by in-memory connections when creating temporary tables
duckdb_set_tempdir <- function(conn, temp = tempdir()){
  DBI::dbExecute(conn, paste0("PRAGMA temp_directory='", temp, "'"))
}

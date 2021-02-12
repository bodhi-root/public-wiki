---
title: RScript
---

R scripts can be run from the command line using:

```
Rscript <file_name> [<arg1> <arg2> ... ]
```

There are various ways to parse the arguments passed to the script.  Below is some sample code that demonstrates one approach:

```
usage <- function() {
  cat("USAGE: Rscript load-division-data.R <date> <table> [<div1> <div2> ...]\n")
  cat("\n")
  cat("Loads data for the given divisions into the database\n")
  cat("\n")
  cat("  date          The date to load (yyyymmdd)\n")
  cat("  table         The name of the table to load\n")
  cat("  div1, div2    A list of divisions to load (ddd format)\n")
  cat("\n")
  cat("Options:\n")
  cat("  --newonly     Only loads new data.  Existing divisions will be skipped.\n")
  cat("\n")
}

DATE   <- NA
TABLES <- c()
DIVISIONS <- c()
NEW.ONLY <- FALSE

args <- commandArgs(trailingOnly = TRUE)

i <- 1
while (i <= length(args)) {

  {
    if (args[i] == "--help") {
      usage()
      quit(status=100)
    } else if (args[i] == "--newonly") {
      NEW.ONLY <- TRUE
      i <- i+1
    } else if (is.na(DATE)) {
      DATE <- as.Date(args[i], "%Y%m%d")
      i <- i+1
    } else if (length(TABLES) == 0) {
      TABLES <- c(args[i])
      i <- i+1
    } else {
      DIVISIONS <- c(DIVISIONS, args[i])
      i <- i+1
    }
  }

}

ALL_TABLES <- c(...)
ALL_DIVISIONS <- c(...)

if (is.na(DATE)) {
  cat("ERROR: Missing required parameter 'DATE'\n\n")
  usage()
  quit(status=100)
}
if (length(TABLES) == 0) {
  cat("ERROR: Missing required parameter 'TABLE'\n\n")
  usage()
  quit(status=100)
}
if (length(DIVISIONS) == 0) {
  DIVISIONS <- ALL_DIVISIONS
}

cat(paste0("DATE      = ", DATE, "\n"))
cat(paste0("TABLES    = ", paste(TABLES, collapse=", "), "\n"))
cat(paste0("DIVISIONS = ", paste(DIVISIONS, collapse=", "), "\n"))
cat(paste0("NEW.ONLY  = ", NEW.ONLY, "\n"))

for (table in TABLES) {
  if (!(table %in% ALL_TABLES)) {
    cat(paste0("ERROR: Unknown table '", table, "'\n"))
    cat(paste0("Valid tables are: ", paste(ALL_TABLES, collapse=", "), "\n\n"))
    usage()
    quit(status=100)
  }
}
```

The script above demonstrates several good features:

* A "usage()" function to explain how to run the program
* Parameters initialized to either NA or default values
* Any incorrect, unexpected, or missing parameters will print usage() and exit with a non-zero exit code
* A "--help" argument exists to print usage() on purpose
* Variables are checked after being parsed for correctness
* Variables are also printed so the user can ensure everything was read correctly

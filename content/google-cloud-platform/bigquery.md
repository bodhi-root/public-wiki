---
title: BigQuery
---

## Connecting to BigQuery from R (on-prem)

To connect to BigQuery from R you will want to use the "bigrquery" package:

```
library(bigrquery)
```

You might need to install this from GitHub to get the latest features though:

```
install.packages('devtools')
devtools::install_github("rstats-db/bigrquery")
```

Then you should be able to run queries with:

```
project <- "my-gcp-project"
sql <- "SELECT COUNT(*) FROM my_dataset.my_table"

df <- query_exec(sql, project = project, useLegacySql = FALSE)
```

This will bring up a browser window to ask you to authenticate.  To get this working through the corporate proxy you will want to run the following before doing your query:

```
library("httr") # needed to set global httr config


# Set global proxy settings for httr/curl
set_config(use_proxy("http://proxy.domain.com", port = port_number, username = .EUID, password = .PASSWORD, auth = "basic"), override = TRUE)
```
(source: https://github.com/ropensci/osmdata/issues/111 )

Connecting to R from Python
The following code was used to query BigQuery for the 75th project to test connectivity.  It just produces a simple row count.

```
from google.cloud import bigquery

bq_client = bigquery.Client()

results = bq_client.query("SELECT COUNT(*) FROM my_dataset.my_table").result()

for row in results:
    print(row)
    #print("{}: {} views".format(row.url, row.view_count))
```

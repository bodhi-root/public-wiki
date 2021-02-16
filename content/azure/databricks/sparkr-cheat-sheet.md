---
title: SparkR Cheat Sheet
---

## Overview

A reference of useful code snippets that I find myself looking up repeatedly.  Do not expect a lot of explanations here - just a quick code reference.  Also, I don't do a lot of analysis in SparkR.  I tend to use PySpark.  So there probably won't be much content here.

## Registering Tables

```
SparkR::registerTempTable(df, "sample_df")
```

You can also read from a table that has been registered with:

```
df = SparkR::sql("SELECT * FROM sample_df")
```

Unfortunately, there does not seem to be an analog to PySparks: "spark.table(table_name)" command.

## SQL

```
sql <- sprintf("
SELECT
  ...
FROM my_table
WHERE name = '%s'
",
  NAME
)

df <- SparkR::sql(sql)
display(head(df, 50))
```

## Interacting with JDBC Databases

```
%r
library(SparkR)

MY_JDBC_URL <- "jdbc:sqlserver://myserver.database.windows.net:1433"

df <- SparkR::read.jdbc(
    url       = MY_JDBC_URL,
    tableName = sprintf("(%s) AS TMP", "SELECT * FROM MY_TABLE"),
    user      = USER,
    password  = PASSWORD
  )

SparkR::write.jdbc(
  SparkR::createDataFrame(df),
  url      = MY_JDBC_URL,
  database = "MYDATABASE",
  table    = "SCHEMA.TABLE",
  mode     = "append",
  user     = USER,
  password = PASSWORD
  )
```

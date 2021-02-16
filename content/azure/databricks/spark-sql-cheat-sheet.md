---
title: Spark SQL Cheat Sheet
---

## Overview

A reference of useful code snippets that I find myself looking up repeatedly.  Do not expect a lot of explanations here - just a quick code reference.

## Creating Views

### General Syntax

Views can be created to expose data from an existing data source.  There are 3 types of views:

* TEMPORARY VIEW - Exists only within your session and is automatically destroyed when your session ends
* GLOBAL TEMPORARY VIEW - Can be accessed by multiple sessions, but is not registered in the metastore.  Must be manually deleted.
* GLOBAL VIEW - Permanent global view that can be accessed by multiple users/sessions

```
CREATE [OR REPLACE] [[GLOBAL] TEMPORARY] VIEW [db_name.]view_name
  [(col_name1 [COMMENT col_comment1], ...)]
  [COMMENT table_comment]
  [TBLPROPERTIES (key1=val1, key2=val2, ...)]
    AS select_statement
```

### Delta Lake

```
CREATE OR REPLACE TEMPORARY VIEW tlog_basket
USING DELTA
OPTIONS (
  path "abfss://conatiner@storage.dfs.core.windows.net/path/to/delta"
);
```

### Parquet

```
SET spark.sql.sources.partitionColumnTypeInference.enabled=false;

CREATE OR REPLACE TEMPORARY VIEW tlog_basket
USING org.apache.spark.sql.parquet
OPTIONS (
  path "abfss://container@storage.dfs.core.windows.net/path/to/parquet"
);
```

## Creating Tables

If the data you want to access already exists, you don't want to create a table; you want to create a view.  If you are creating a new place to store data, then you will need to create the table definition.  This typically involves specifying all of the column names and types for your table as well as some optional comments.  We make extensive use of delta lake tables since these are very good at enforcing schema when writing data, support schema evolution, support MERGE and DELETE statements, and are able to automatically partition your data for you when you write it.

### Delta Lake

```
-- Create a table by path (new in DataBricks 7.0)
CREATE OR REPLACE TABLE delta.`/mnt/delta/events` (
  date DATE,
  eventId STRING,
  eventType STRING,
  data STRING)
USING DELTA
PARTITIONED BY (date);

-- Create a table in the metastore
CREATE OR REPLACE TABLE events (
  date DATE,
  eventId STRING,
  eventType STRING,
  data STRING)
USING DELTA
PARTITIONED BY (date);
```

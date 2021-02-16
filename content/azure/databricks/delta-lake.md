---
title: Delta Lake
---

## Creating Tables

Beginning in DataBricks 7.0 you can create a Delta Lake table in ADLS storage without having to register it in the Hive metastore.  Instead of a table name you specify the path to the storage location in ADLS.  This is the preferred way to do it in our "Create Table" scripts.  A sample CREATE TABLE command looks like this:

```
%sql
CREATE TABLE delta.`abfss://marts@storage.dfs.core.windows.net/mart_name/table_name` (
  id           string        COMMENT "Unique ID for item",
  value        string        COMMENT "String value",
  dec_value    decimal(9,3)  COMMENT "Decimal value"
  cycle_dt     date          COMMENT "Data the data was loaded"
)
USING DELTA
PARTITIONED BY (cycle_dt);
```

Notice that you can specify the partitioning at this time.  This partitioning will automatically be enforced when writing new data to this table.

## Re-Naming Columns

If you mess up your table and need to re-name a column you can do so with the following command:

```
path = "abfss://marts@storage.dfs.core.windows.net/mart_name/table_name"
display(spark.read.format("delta").load(path)
  .withColumnRenamed("new_name", "old_name")
  .write
  .format("delta")
  .partitionBy("col1", "col2")
  .mode("overwrite")
  .option("overwriteSchema", "true")
  .save(path)
)
```

There is no SQL equivalent for this command.  Notice that we have to set the "overwriteSchema" option to true in order for this to work.  This is all documented here:

* https://docs.databricks.com/delta/delta-batch.html#explicit-schema-update

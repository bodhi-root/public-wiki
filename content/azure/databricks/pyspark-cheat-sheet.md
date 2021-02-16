---
title: PySpark Cheat Sheet
---

## Overview

A reference of useful code snippets that I find myself looking up repeatedly.  Do not expect a lot of explanations here - just a quick code reference.

## API Reference

The complete PySPark API can be found here: https://spark.apache.org/docs/latest/api/python/index.html

## Registering Tables

The primary way to pass data between PySpark and other languages is by registering a data frame as a table/view.  This can be done in a couple of ways:

```
df.createOrReplaceTempView("my_table")
df.createTempView("my_table")
```

The functions above are from Spark 2.0.  The older 1.0 functions are still available and seen in some code though.  These are:

```
df.registerTempTable("my_table")  # calls df.createOrReplaceTempView()
```

To load data from a table into a PySpark DataFrame you can use either of the methods below:

```
df = spark.table("my_table")
df = spark.sql("SELECT * FROM my_table")
```

## Persist and Cache DataFrame

You can persist a DataFrame with:

```
df.persist(storageLevel)
```

Storage level is typically:

* MEMORY_AND_DISK (default)
* MEMORY_ONLY
* DISK_ONLY

Good article here: http://www.lifeisafile.com/Apache-Spark-Caching-Vs-Checkpointing/

You can also use:

```
df.cache()   # equivalent to df.persist(MEMORY_ONLY)
```

You can unpersist these with:

```
df.unpersist()
```

If you have registered your data as a table you can cache it by name:

```
spark.catalog.cacheTable("tableName")
spark.catalog.uncacheTable("tableName")
```

## SQL

```
sql = """
SELECT ...
FROM ...
WHERE field = '{}'
""".format(
  field_value
)

df = spark.sql(sql)
```

## Reading Data

### Text Files

This is handy for previewing the first few lines of a file and seeing what it looks like:

```
df = spark.read.format("text").load(path)
display(df.limit(5))
```

### Delimited Files

If your file doesn't have a header you will need to specify a schema to get reasonable column names.  You can specify an all-string schema with:

```
from pyspark.sql.types import *

def get_schema():
  cols = ["col1", "col2", ... ]

  fields = list()
  for col in cols:
    fields.append(StructField(col, StringType(), True))

  return StructType(fields)
```

Then load with:

```
schema = get_schema()

df = (spark.read
      .format("csv")
      .options(header=False, delimiter="|")
      .schema(schema)
      .load(path))
```

### Parquet Files

```
# use the following line if you want partition columns to be type string (rather than inferred)
spark.conf.set("spark.sql.sources.partitionColumnTypeInference.enabled", "false")

df = spark.read.format("parquet").load(path)
```

### Databases (JDBC)

```
jdbcUrl = "jdbc:sqlserver://hostname.database.windows.net:1433;databaseName=db_name"
props = {
  "user" : "user",
  "password" : "password",
  "driver" : "com.microsoft.sqlserver.jdbc.SQLServerDriver"   # not really needed
}

pushdown_query = "(select * from my_table) results_alias"
df = spark.read.jdbc(url=jdbcUrl, table=pushdown_query, properties=connectionProperties)
```

## Transforming Data

### Raw-to-Curated Transformations

Some common operations in raw-to-curated transformations include:

* Changing data types
* Re-naming fields
* Dropping columns
* Adding new columns

The transformation below shows examples of these:

```
from pyspark.sql.types import *
import pyspark.sql.functions as F

def transform(df, cycle_dt):

  # filter rows:
  df = (df.filter(F.col("typ") == "B"))

  # drop columns:
  df = df.drop("_corrupt_record", "col1", "col2", ...)

  # cast data types
  df = (df.withColumn("sto_no",         F.trim(df["sto_no"]))   # trim string
          .withColumn("value_dt",       F.to_date(df["value_dt"], "yyyyMMdd"))   # date with custom format
          .withColumn("value_no",         df["value_no"].cast(ShortType()))
          .withColumn("value_id",         df["value_id"].cast(IntegerType()))
          .withColumn("value_dol_am",     df["value_dol_am"].cast(DecimalType(9,2)))
       )

  # rename columns:
  df = (df.withColumnRenamed("old_name", "new_name")
          .withColumnRenamed("old_name2","new_name2")
       )

  # select columns (in specific order):
  df = df.select("col1", "col2", ...)

  # add a column:
  df = df.withColumn("cycle_dt", F.to_date(F.lit(cycle_dt)))

  return df
```

### Split Column

The code below splits a column named "value" of the form "014_123" into a 'first' column with "014" and a 'second' column with "123":

```
value_split = F.split(df['value'], '_')
df = (df.withColumn('first',  value_split.getItem(0))
        .withColumn('second', value_split.getItem(1))
     )
```

## Writing Files

### Text and Delimited

I rarely use Spark to write to text or CSV files.  Spark likes to put a bunch of files into a folder.  Even if you use coalesce(1) to force it to output 1 file it will do this as a file with an auto-generated name inside of the directory you pass in as the path.  One way around this is to use "collect()" to pull the data back to the driver node and save it with normal Python functions.  Then you can copy your file back to your destination (such as ADLS storage).

### Parquet Files

```
df.write.parquet(path)

# you can also manually specify the number of partitions ("part-###" files in the folder) with:
df.coalesce(num_partitions).write.parquet(path)

# or you can partition into sub-folders using certain fields as the partition keys:
df.write.partitionBy("field1", "field2", ...).parquet(path)
```

### Databases (JDBC)

```
jdbcUrl = "jdbc:sqlserver://hostname.database.windows.net:1433;databaseName=db_name"
props = {
  "user" : "user",
  "password" : "password",
  "driver" : "com.microsoft.sqlserver.jdbc.SQLServerDriver"  # not really needed
}

df.write.jdbc(url=jdbcUrl, table="my_table", mode="overwrite", properties=props)
```

### Synapse

When writing to Synapse you should use the "com.databricks.spark.sqldw" connector rather than the simple JDBC connector.  This will improve the write speed significantly (by over 100x in my experience!).

```
JDBC_URL = "jdbc:sqlserver://my_server.database.windows.net:1433;databaseName=my_database"

# use COPY statement rather than Polybase (DataBricks 7.0).  This improves performance.
spark.conf.set("spark.databricks.sqldw.writeSemantics", "copy")

(df.write
   .format("com.databricks.spark.sqldw")
   .option("url", JDBC_URL)
   .option("user", "username")
   .option("password", "password")
   .option("dbTable", table_name)
   .option("tempDir", "wasbs://tmp@my_storage.blob.core.windows.net/data_warehouse_ingest")
   .option("forwardSparkAzureStorageCredentials", "true")
   .mode("append")
   .save()
)
```

This works by first writing the data to a staging location and then having Synapse load the data either using Polybase or a COPY command.  The "tempDir" can be blob storage or ADLS Gen 2, in which case the URL should begin with "abfss://" and use "dfs.core.windows.net" in the URL.  There are two ways to have Synapse authenticate with the storage account.  The first is to set the storage account key in your DataBricks environment with:

```
spark.conf.set("fs.azure.account.key.my_storage.blob.core.windows.net", "secret_key")
```

and then use "forwardSparkAzureStorageCredentials" to "true" (as shown above) to forward this key to Synapse.  (This is the preferred method according to DataBricks.)  Or you can have Synapse authenticate as itself using a managed identity.  In this case you will not have to set the key in your DataBricks session.  But you will replace the "forwardSparkAzureStorageCredentials" option with:

```
.option("useAzureMSI", "true")
```

to use the Azure Managed Service Identity.

For complete documentation on this connector see: https://docs.databricks.com/data/data-sources/azure/synapse-analytics.html.

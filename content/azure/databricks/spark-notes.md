---
title: Spark Notes
---

## Overview

This page is intended to cover general notes about Spark.  These shouldn't pertain to DataBricks specifically (although some DataBricks-specific commands might creep into this).

## Reading Files

The generic method for reading from file-like sources in PySpark is:

```
df = (spark.read
        .format(...)    # usually "csv" or "parquet"
        .options(...)   # typically specific to format
        .schema(schema) # optional, if you want to define/enforce schema
        .load(path))
```

If you want to preview your file you can do it with the "display" command.  Make sure you limit it to just the first few rows though:

```
display(df.limit(50))   # databricks (gives you a nice UI/format)

print(df.limit(50).toPandas())  # works in non-Databricks
```

### Parquet Files

Parquet files are among the easiest to read.  They follow a strict format that has schema information embedded in the file.  This means you can usually read a parquet file simply with:

```
df = spark.read.format("parquet").load(path)
```

or, equivalently:

```
df = spark.read.parquet(path)
```

### CSV Files

DataBricks Docs: https://docs.databricks.com/data/data-sources/read-csv.html

CSV files are a little more difficult.  They can use different delimiters, different quoting/escaping methods, and may require special handling of NULL values.  CSV files may have a header or they may not.  If they don't have a header, you will likely have to specify the schema of the file manually.

If your file has a header you can load it with:

```
df = (spark.read
      .format("csv")
      .options(header=True)
      .load(path))
```

This will work for regular CSV files (".csv") and even for Gzip-compressed files (".csv.gz").  Column names will be parsed from the header in the first row.  All values will have their type set to "StringType".

If your file uses a different delimiter you can specify it using the "sep=" option.

If you don't have a header or if you want to specify a schema manually you will likely end up with something like:

```
from pyspark.sql.types import StructType, StructField, StringType, DecimalType

def load_raw_file(path):

  schema = StructType([
    StructField("id",     StringType(),  True),
    StructField("name",   StringType(),  True),
    StructField("value",  DecimalType(10, 2), True)
  ])

  df = (spark.read
        .format("csv")
        .options(header=False, sep="|")
        .schema(schema)
        .load(path))

  return df
```

In this example, we read a pipe-delimited file that doesn't have a header.  We manually specify all of the column names and types.  We also encapsulate all of this into a function since it's starting to get a bit complicated and this will keep our code that processes the file simpler.

The following page provides a good overview of the different data types in Spark:

* https://jaceklaskowski.gitbooks.io/mastering-spark-sql/spark-sql-DataType.html

### Handling Invalid Records

The links below provide some good info on how to handle invalid records in our data:

* https://docs.azuredatabricks.net/_static/notebooks/read-csv-corrupt-record.html
* https://stackoverflow.com/questions/53296257/handling-schema-mismatches-in-spark

The short version is that you can specify an option named "mode" indicating how to handle invalid records.  Valid values for "mode" are:

* PERMISSIVE : try to parse all lines: nulls are inserted for missing tokens and extra tokens are ignored.
* DROPMALFORMED : drop lines that have fewer or more tokens than expected or tokens which do not match the schema.
* FAILFAST : abort with a  RuntimeException  if any malformed line is encountered.

It is also possible to parse the file in a way that separates and saves information on invalid records.  This is done by defining a column named "_corrupt_record" of type string.  When used with PERMISSIVE mode, this will save the raw text of the line to "_corrupt_record" while putting NULLs in all other columns (just like PERMISSIVE mode does normally).  Then you can view the invalid rows by filtering to non-null values in "_corrupt_record".

```
%scala
import org.apache.spark.sql.types._

val schema = new StructType()
  .add("_c0",IntegerType,true)
  .add("carat",DoubleType,true)
  .add("cut",StringType,true)
  .add("color",StringType,true)
  .add("clarity",StringType,true)
  .add("depth",IntegerType,true) // The depth field is defined wrongly. The actual data contains floating point numbers, while the schema specifies an integer.
  .add("table",DoubleType,true)
  .add("price",IntegerType,true)
  .add("x",DoubleType,true)
  .add("y",DoubleType,true)
  .add("z",DoubleType,true)
  .add("_corrupt_record", StringType, true) // The schema contains a special column _corrupt_record, which does not exist in the data. This column captures rows that did not parse correctly.

val diamonds_with_wrong_schema = spark.read.format("csv")
  .option("header", "true")
  .schema(schema)
  .load("/databricks-datasets/Rdatasets/data-001/csv/ggplot2/diamonds.csv")

val badRows = diamonds_with_wrong_schema.filter($"_corrupt_record".isNotNull)
badRows.cache()
val numBadRows = badRows.count()
badRows.unpersist()
```

The PySpark equivalent would be:

```
%python
from pyspark.sql.types import *
import pyspark.sql.functions as F

schema = StructType([
    StructField("_c0",   IntegerType(), True),
    StructField("carat", DoubleType(),  True),
    StructField("cut",   StringType(),  True),
    StructField("color", StringType(),  True),
    StructField("depth", IntegerType(), True),
    StructField("table", DoubleType(),  True),
    StructField("price", IntegerType(), True),
    StructField("x",     DoubleType(),  True),
    StructField("y",     DoubleType(),  True),
    StructField("z",     DoubleType(),  True),
    StructField("_corrupt_header", StringType(),    True)
])

df_diamonds_with_wrong_schema = (spark.read
  .format("csv")
  .option(header = True)
  .schema(schema)
  .load("/databricks-datasets/Rdatasets/data-001/csv/ggplot2/diamonds.csv"))

df_bad_rows = df.where(F.col("_corrupt_record").isNotNull()).cache() # have to cache or you'll get an error
display(df_bad_rows.select(['_corrupt_record']).limit(5))

df_bad_rows.unpersist()
```

## SQL API

Many Spark operations - especially data transformations - can be represented in SQL.  In fact, the "sparkyr" library for R provides a dplyr-like syntax for Spark, but under the hood it is just translating everything to SQL and sending it through Spark's SQL API.

### SQL (with %sql)

You can write SQL directly into a notebook with:

```
%sql
SELECT ...
```

If you need to save the results of your query you can do so by creating a new table with your results:

```
%sql
CREATE [OR REPLACE] [[GLOBAL] TEMPORARY] VIEW [db_name.]view_name
  [(col_name1 [COMMENT col_comment1], ...)]
  [COMMENT table_comment]
  [TBLPROPERTIES (key1=val1, key2=val2, ...)]
    AS select_statement
```

DataBricks docs on the above command: https://docs.databricks.com/spark/latest/spark-sql/language-manual/create-view.html

One of the big limitations of using the "%sql" method in a notebook is that you can only pass in variables to your query if they are defined as widgets on the notebook.  In this case the syntax would be:

```
%sql
SELECT ...
FROM ...
WHERE field = $Variable1
```

Usually your variables will not be notebook widgets.  In these cases you can use the Python or R methods to run SQL with a query built dynamically in those languages.

### PySpark

```
%python
sql = """
SELECT ...
FROM ...
WHERE field = '{}'
""".format(
  field_value
)

df = spark.sql(sql)
```

### R (SparkR)

```
%r
sql <- sprintf(
"SELECT ...
FROM ...
WHERE field = '%s'
",
  field_value
)

df <- SparkR::sql(sql)
```

## SQL Databases
DataBricks Documentation: https://docs.databricks.com/data/data-sources/sql-databases.html

### Spark JDBC API

Spark uses JDBC behind-the-scenes to interact with databases (since it is written in Scala).  DataBricks comes with built-in support for MySQL, SQL Server, and Azure SQL Database.  This makes these databases easy to talk to.  If all you want to write data to a database you can do it with:

```
%r
url <- "jdbc:sqlserver://sqlservername.database.windows.net:1433"
SparkR::write.jdbc(SparkR::createDataFrame(df), url,
  database = "MY_DATABASE",
  table    = "SCHEMA.TABLE",
  mode     = "append",
  user     = dbutils.secrets.get("scope", "SQL_SERVER_USER"),
  password = dbutils.secrets.get("scope", "SQL_SERVER_PASSWORD")
  )
```

Notice that you have to convert your data to a SparkDataFrame first.  A regular R data.frame will not work.

If you want to read from a database you can use:

```
%r
sql <- "SELECT * FROM MY_TABLE"
df <- SparkR::read.jdbc(
  url       = url,
  tableName = sprintf("(%s) AS TMP", sql),
  user      = dbutils.secrets.get("scope", "SQL_SERVER_USER"),
  password  = dbutils.secrets.get("scope", "SQL_SERVER_PASSWORD")
)
```

The code above sets 'tableName' equal to the results of an SQL query.  You can also separate the table name (or SELECT criteria) from your predicates (your WHERE clause) using the syntax below.  This is said to help pushdown SQL to the database itself rather than filtering the data in Spark, but it doesn't seem to be necessary.  According to this site, Spark automatically will pushdown criteria from your WHERE clause, and I can verify that I've seen this behavior.

```
df <- SparkR::read.jdbc(
  url = url,
  tableName = "MY_TABLE",    # or "(SELECT year, income FROM MY_TABLE) AS tmp"
  predicates = list("(income < 70 and year = 2005) or
                   (income > 100 and year in (2006,2007))"),
  user = user,
  password = password
)
```

When specified this way, Spark can push the predicates down into the SQL database.  Otherwise, Spark is doing the filtering and any aggregations in the query itself.  For more examples see: https://github.com/UrbanInstitute/sparkr-tutorials/blob/master/08_databases-with-jdbc.md.

You can also create a table in Spark to act as a proxy for this table:

```
%sql
CREATE TABLE <jdbcTable>
USING org.apache.spark.sql.jdbc
OPTIONS (
  url "jdbc:<databaseServerType>://<jdbcHostname>:<jdbcPort>",
  dbtable "<jdbcDatabase>.atable",
  user "<jdbcUsername>",
  password "<jdbcPassword>"
)
```

Doing it this way will enable you to interact with the table from any Spark language.  You can easily query the database using "SELECT", append to it with "INSERT INTO <table>" and overwrite it with "INSERT OVERWRITE TABLE <table>".

> WARNING: Spark SQL does not support the UPDATE or DELETE command.  You can either append or overwrite.  The documentation says that delta lake storage might offer these commands.  If you want to interact with

TODO: Figure out how to inject password securely using SQL syntax.  Might have to use sqlContext to run the CREATE TABLE command.

### Direct JDBC Connections (Driver Node)

Sometimes you may want to connect directly to a database using JDBC.  This will give you access to the full range of SQL commands that the database supports instead of the restricted one offered by the Spark JDBC API.  In order to do this from R you need to first install "rJava" and "RJDBC".  This process consists of running the commands below (as documented [here](https://docs.microsoft.com/en-us/azure/databricks/kb/r/install-rjava-rjdbc-libraries)):

```
%sh
ls -l /usr/bin/java
ls -l /etc/alternatives/java
ln -s /usr/lib/jvm/java-8-openjdk-amd64 /usr/lib/jvm/default-java
R CMD javareconf

%r
install.packages(c("rJava", "RJDBC"))

dyn.load('/usr/lib/jvm/java-8-openjdk-amd64/jre/lib/amd64/server/libjvm.so')
library("RJDBC")
```

You can then create a database connection with:

```
%r
conn <- dbConnect(
  JDBC(
    "com.microsoft.sqlserver.jdbc.SQLServerDriver",
    identifier.quote="`"
  ),
  "jdbc:sqlserver://<server>.database.windows.net:1433;databaseName=<database>",
  dbutils.secrets.get("secret-scope", "SQL_SERVER_USER"),,
  dbutils.secrets.get("secret-scope", "SQL_SERVER_USER"),
)
```

This connects to a SQL Server database.  The details for all options to configure this connection are available here.  Notice that we load the user name and password for the database from a secret scope rather than embedding credentials in our notebook.

Once the connection is established you can use the regular DBI methods like dbGetQuery to query the database:

```
%r
df <- dbGetQuery(conn, "SELECT * FROM MY_TABLE")
print(df)

dbDisconnect(conn)
```

### Direct JDBC Connections (Executor Nodes)

The method described above for direct JDBC connections configures this for the driver node only.  The "%sh" commands only execute on the driver node, and the "install.packages" command runs there as well.  You will also find that the JDBC drivers used to access databases are not exposed by default on the executor nodes.  In order to get your executor nodes setup to use RJDBC you will need to:

1. Use a cluster init script to run the "%sh" commands described above
2. Install the RJDBC library on your cluster
3. Install the JDBC driver(s) on your cluster (optional)
4. Avoid using commands like "dbutils.secrets" that will not work on the executor nodes

More detail on these steps is provided below.

First, you will need to run those "%sh" commands on each node in the cluster.  The best way to do this is using a cluster init script.  You can create the script using the commands below:

```
%python
dbutils.fs.mkdirs("dbfs:/databricks/scripts/")

dbutils.fs.put("/databricks/scripts/rjdbc-setup.sh",
"""#!/bin/bash
#ls -l /usr/bin/java
#ls -l /etc/alternatives/java
ln -s /usr/lib/jvm/java-8-openjdk-amd64 /usr/lib/jvm/default-java
R CMD javareconf
""",
True)
```

Once created, you can view this script with:

```
display(dbutils.fs.ls("dbfs:/databricks/scripts/rjdbc-setup.sh"))

print(dbutils.fs.head("dbfs:/databricks/scripts/rjdbc-setup.sh"))
```

You can then specify this as the init script in the "Advanced Options" portion of your cluster settings:

![Screenshot](databricks/assets/init-scripts.png)

When you save this configuration it will restart the cluster and apply the new init script.  If there are any problems running this script, the cluster will be unable to start.

The above script does the required initialization in order to make the RJDBC library install nicely.  You can now install the RJDBC library on your cluster's library page using the normal method, and it won't fail.  The screenshot below shows the RJDBC library installed successfully:

![Screeshot](databricks/assets/installed-libraries.png)

The screenshot also shows the Microsoft SQL Server driver was installed as a JAR file.  This is one way to make the driver available to your notebook.  When you initialize the JDBC connection via RJDBC, you can supply this as a parameter to load it to the classpath.  Take note of the location of the jar file in the screen above.  This is the path you will want to reference in your connection, replacing the "dbfs:/" with "/dbfs/".  If you don't do this, you will get a "ClassNotFound" exception.  The code below shows an example connecting to a database using this driver:

```
USER     <- dbutils.secrets.get("secret-scope", "SQL_SERVER_USER")
PASSWORD <- dbutils.secrets.get("secret-scope", "SQL_SERVER_PASSWORD")

conn <- dbConnect(
  JDBC(
    "com.microsoft.sqlserver.jdbc.SQLServerDriver",
    identifier.quote="`",
    classPath="/dbfs/FileStore/jars/26f65cab_0c6a_4df1_a4a7_281745f468b9-mssql_jdbc_8_2_0_jre8-9dac0.jar"
    #classPath="/databricks/jars/spark--maven-trees--spark_2.4--com.microsoft.sqlserver--mssql-jdbc--com.microsoft.sqlserver__mssql-jdbc__6.2.2.jre8.jar"
  ),
  "jdbc:sqlserver://myserver.database.windows.net:1433;databaseName=mydatabase",
  USER,
  PASSWORD
)
```

Notice that we don't use "dbutils.secrets.get" to get the user name and password.  If you try to do this it will fail with a rather obscure error indicating that Spark is not properly initialized.  It looks like this command is intended to only be run on the driver node.  Instead, you will need to get the secrets first (on the head node) and store them as variables.  Then these can be accessed by the code above on the executors.

Also notice that instead of installing the JDBC driver (the jar file) ourselves, we can also reference the one available in Spark by default.  The commented out line in the code above shows the path for this jar file in a cluster running DataBricks version 6.2.  This path will likely be different for different versions of Spark.  The manual install isn't any better though, since part of the path is auto-generated and looks like it will also be different if installed on different clusters.  I suppose using the JDBC driver already available in Spark would be the preferred route since it makes use of what is already available instead of requiring the user to add a new dependency to their solution.

If you need to find the path to the "mssql" JDBC driver on your cluster, try:

```
%sh ls /databricks/jars/*mssql*
```

## Parallelizing Code

One of the big reasons to use Spark is to parallelize operations across a large cluster.  For built-in Spark and SQL functions this works well.  But if you need to parallelize your own code things can be trickier.

In R you will you "spark.lapply" or "gapply".  The pages below provide good documentation of these:

* https://docs.microsoft.com/en-us/azure/databricks/kb/r/sparkr-lapply
* https://docs.microsoft.com/en-us/azure/databricks/kb/r/sparkr-gapply

"spark.lapply" is the easier of the two.  This applies a custom function to each element in a list.  The input is an R list and the output is an R list.  You don't have to deal with any Spark constructs.  However, you are limited in that you can only take one object as input to the function.  "gapply" is more like dplyr's "group_by" and "do".  The input is a Spark data frame.  You can group by columns in this data frame and then apply a function to the a subset DataFrame for each of these groups.  Your output is also a Spark DataFrame, and all of the outputs of each function get joined up into one big DataFrame.  However, this means you have to specify a Spark schema for your data frame.  You can also use "gapplyCollect()" to convert the Spark DataFrame back to an R data.frame.  In this case you don't need to specify a Spark schema.  But be careful with this one.  As with "collect()", all of your results will be loaded into memory on the driver node.  This isn't a good approach if you are returning a lot of data.

In my experience these can be pretty tricky.  You have to make sure all the libraries your function needs are on the worker nodes.  Using "install.packages" in your notebook is not sufficient for this.  It appears to only install the library on the driver node.  You can use the cluster install GUI in databricks.  However, I couldn't get it to install RJDBC.  This requires custom setup, and I don't know how to automate this on each node.  Maybe an install script... But it's annoying to have to install the libraries every time you start your cluster.  Shouldn't they just be there?

At least it appears that all the variables and functions I've defined in my notebook are available on the worker nodes.  That's a nice surprise.

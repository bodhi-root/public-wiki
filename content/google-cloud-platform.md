---
title: Google Cloud Platform
---

The Google Cloud Platform (GCP) provides resources to manage data and compute in the cloud.  It is a competitor to Amazon Web Services (AWS) and Microsoft Azure.  The platform provides a large portfolio of products - which can be intimidating at first - but once you learn the basic building blocks, you will find that it isn't that hard.  Overall, the focused set of products (one tool for each job) actually helps you understand when to use what and better apply good architectural principles.  You will also see patterns begin to emerge as many of the GCP offerings relate directly to similar products in AWS and Azure.  Many of them also have open source equivalents that can run on your own on-prem systems, although the investment needed to run dedicated, full-time platforms like Hadoop on-prem can be prohibitive.

## Product Overview

A complete list of products is available here: https://cloud.google.com/products/

## Compute

"Compute" refers to the ability to process data.  This takes the form of generic VMs, Kubernetes clusters, or the more specialized web services and functions.

| Product | Description | Related Concepts |
|---------|-------------|------------------|
| __Compute Engine__ | The ability to run a VM in the cloud. This lets you do pretty much anything you'd want to do: configure the system, install software, and run whatever you'd like. In general, you should try to avoid using this option except as a last resort. For most tasks (storage, web sites, web services, and analytics) there are products tailored to those specific needs. Those custom products may also be cheaper since they can be created and destroyed based on need instead of left running all the time. __A standard VM with 2 CPUs and 7.5 GB of RAM will cost about $15/month__. (See full price list [here](https://cloud.google.com/compute/pricing)) | VM, Docker, AWS EC2 |
| __Kubernetes Engine__ | If you want to run more than one VM and are instead looking at running a cluster of VMs, Kubernetes is a way to define your cluster programatically and spin it up on demand. This can get very tricky as you need to define system architecture, network topology, disk mappings, etc., but it's there if you need it. | Kubernetes Cluster |
| __App Engine__ | A way to run web services in the cloud. RESTful web services using Swagger/OpenAPI specs are the norm here. These can be spun up when called so that you are only charged for when they are active. | Web Services, PCF |
| __Cloud Functions__ | Imagine a web service, but smaller. (I think) | AWS Lambda Functions

## Storage

If you need to store data, these are your options.  Google Cloud Storage (GCS) is the most generic and widely-used type of storage.  It's also the cheapest.  Use it when you can.  But if you need an OLTP or OLAP database, there are products for those too.

| Product | Description | Related Concepts |
|---------|-------------|------------------|
| __Cloud Storage__ | Generic way to store files in collections called "buckets". These can be made to emulate a file system and are the main unit of storage in most applications. These can be used for anything from hosting a static website to fserving as a Data Lake and landing zone for all of your company's data. __Cloud storage costs $0.02 / GB/month (or $20 / TB/month)__ but can be even cheaper if high-performance is not required. | Amazon S3, Key-Value Store for Files/BLOBs, File System |
| __Cloud SQL__ | For OLTP systems. If you need a MySQL or PostreSQL database, this is the place. | Traditional RDBM system for OLTP applications |
| Datastore | Document store similar to Mongo. Can be used by operational systems. | Mongo |
| __Cloud Bigtable__ | High-performance database for data that is "narrow" and "long". Very similar to Cassandra. This is a good choice when your data gets too big to be performant, and you have specific, pre-defined queries that allow you to optimize the data for retrieval based on keys. (Good for time series data.) | Cassandra, HBase |
| __Spanner__ | Mission-critical relational database. (But that comes at a cost. Only needed when Cloud SQL just isn't good enough.) | |
| __BigQuery__ | Used to build data warehouses and data marts (OLAP systems). Google lists this product under "Big Data", but it also has its own internal storage and can be used to replace traditional databases in the data warehouse space. BigQuery can store data internally or expose external data kept in Cloud Storage. External data is typically just CSV, JSON, Avro, or Parquet files kept in a "folder" in Cloud Storage.	| Data Warehouse, Apache Drill |

## Big Data & Analytics

| Product | Description | Related Concepts |
|---------|-------------|------------------|
| __Dataprep__ | Web tool to let you preview data and perform "data wrangling" (or "data munging") tasks. This lets you explore data, check completeness/conformity/consistency, view histograms, detect outliers, and perform data prep tasks (like modifying or joining disparate data sets) to get a data set ready for analysis. This is not intended to be a full-blown ETL solution, but since they say it uses Dataflow behind the scenes perhaps this will be possible in the future.<br/><br/>[Here's a good link](https://tdwi.org/articles/2017/02/10/data-wrangling-and-etl-differences.aspx) (Thanks, Sameer!) describing the differences between "data wrangling" and "ETL" - mainly that it is geared towards business users and able to handle diverse data sets with or without well-defined schemas. | Data munging/wrangling, IDQ Analyst, Alteryx |
| __Dataflow__ | A way to write ETL jobs using the Apache Beam API. Apache Beam is a Java/Python API to write batch or streaming data processing jobs. Personally, I find the syntax to be rather horrible. There has to be a better way to do ETL. Google's solution for deploying these Dataflow jobs is to either 1) Write a web service (via App Engine) to kick off the job and then create a cron entry in App Engine to call your web service at a specified frequency, or 2) Install [Apache Airflow](https://airflow.apache.org/) on a Compute Engine instance and kick off the job that way. Neither of these is especially simple, and community forums are ripe with examples of people asking Google to provide a managed solution for ETL. | ETL Jobs |
| Data Studio | Data visualization product that lets you build interactive reports and dashboards. This can query data exposed by other databases or BigQuery. It is clearly inspired by Tableau and uses a similar UI.	| Tableau, Business Objects |
| __Datalab__ | An interactive notebook for data science work. This is basically a [Jupyter Notebook](http://jupyter.org/) (IPython) solution that interacts with data in GCP. It only supports Python at the moment. (Come on! Wheres's support for R !??)	| Jupyter Notebooks (IPython) |
| __Dataproc__ | A way to stand up a Hadoop cluster consisting of possibly hundreds of nodes for running large-scale analytics, data science, and data processing jobs. I haven't used this yet (It's taking me forever to figure out the basic Hadoop/Spark concepts), but there is a new paradigm when running in the cloud: instead of creating large, 100-node clusters and keeping them on indefinitely (as we do with our on-prem solutions), customers are encouraged to use GCS for file storage and Dataproc only for processing. This offers substantial cost savings since you only need to create the cluster and operate it when needed and can then spin it down. However, this means you should not persist any data on the Hadoop cluster itself. Instead, the on-board storage in the cluster should be considered transient. Data should be persisted somewhere else (like GCS).<br/><br/>NOTE: I've been going back-and-forth about whether I'd rather run large, parallel R jobs on a Dataproc cluster or using a large, 96-core VM. I've costed them out and the Dataproc solution is actually cheaper (both were under $5 for an hour of processing at 96 cores). The VM seems a bit easier, but obviously it won't scale beyond 96 cores. In contrast, a Dataproc cluster can scale to thousands of nodes. Both approaches have difficulties, the biggest of which is how do you install your dependencies and libraries before you run the job if your cluster disk is transient? | Hadoop / Spark |

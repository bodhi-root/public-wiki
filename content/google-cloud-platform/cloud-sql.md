---
title: Cloud SQL
---

Cloud SQL refers to Google's database offerings.  As of August 2019 these include:

* MySQL
* PostgreSQL
* SQL Server (alpha)

Prices are based upon the size of the machine allocated to running the database (number of CPUs and memory size) and the size of the SSD disk storing the database data.  Cloud SQL offers a fully-managed service that automatically handles backups, data duplication, and disaster recovery.  Of course, you end up paying a premium for all this.

As of August 2019, the rates were as shown:

| Service Type | Storage Space | Monthly Price* |
|--------------|---------------|----------------|
| MySQL database, Second Generation (db-f1-micro) | 375 GB | $71.42 |
| PostgreSQL database (db-pg-f1-micro) | 375 GB | $71.42 |
| GCE instance (f1-micro).  Install and manage MySQL or PostgreSQL yourself | 375 GB | $33.88 |

*Monthly price includes a 30% sustained use discount (assuming service is running all month).  This applies to everything in the table.

As shown, you are paying a little over twice the price for Google to manage the database for you.  Given this, it may be preferable to just install a database and manage it yourself.  This post discusses the pros and cons of each approach.  It also mentions that there is a way for the database to go inactive after 15 minutes without being queried and spin back up again when needed.  Sadly, this was a feature in First Generation Cloud SQL - which is being deprecated January 30, 2020.  This "per use" billing feature is not being offered in Second Generation Cloud SQL.  According to Google's docs:

> "Second Generation instances do not support the ON_DEMAND activation policy. You can stop your instance manually, but it does not respond to any incoming connection requests until you start it again."

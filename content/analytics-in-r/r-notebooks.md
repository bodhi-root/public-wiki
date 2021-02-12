---
title: R Notebooks
---

## Overview

R Notebooks are a great way to share code and knowledge with others.  R Notebooks use a simple markdown language that also lets you embed runnable R code into your document.  These notebooks focus on explaining what the code is doing and usually provide much more context and detail than you'd get in R code with inline comments.  Notebooks are great for doing exploratory data analysis or demonstrating how a particular technique can be applied to sample data.  There is a growing ecosystem of tooling being built around notebooks to make it easy to publish and share them as well.

## Getting Started

The intent of this page is not to describe every nuance of R Notebooks.  Instead, please refer to the following source:

* [R Markdown: The Definite Guide](https://bookdown.org/yihui/rmarkdown/)

## Useful Snippets

Here are some of the things I'm constantly looking up to try and remember.

### Notebook Header

A good notebook header looks something like this:

```
title: My Page Title
description: |
  A description of your page.
  This can be multi-line, and some advanced parsers can extract this to build a list of pages.
author: Some Dude
date: 10-02-2018
output: html
```

### Table of Contents

```
output:
  html_document:
    toc: true
    toc_depth: 2
```

### SQL Block

You can execute SQL using something like the following:

```{sql, connection=CONN, output.var=df.data}
SELECT * FROM MY_TABLE
WHERE DIVISION = ?DIVISION
AND STORE = ?STORE
```

This command is identical to running the following in R:

```
sql <- "
SELECT * FROM MY_TABLE
WHERE DIVISION = ?DIVISION
AND STORE = ?STORE
"
sql <- sqlInterpolate(CONN, sql, DIVISION=DIVISION, STORE=STORE)
df.data <- dbGetQuery(CONN, sql)
```

sqlInterpolate is used to substitute in the values of "DIVISION" and "STORE".  Strings will be escaped appropriately to avoid SQL-injection errors.  The connection variable must be a DBI-compliant database driver.  The output will be stored in the given data frame.  The SQL code block is usually preferable to running the equivalent R code because the SQL is easier to read and understand what it i doing.

## Radix Websites & Blogs

Recently (as of October, 2018), R Studio released the ability to build R websites and blogs using Radix.  The Ops Research team is experimenting with this method to see if it could work as a Knowledge Sharing mechanism for the team.  Radix blogs have several advantages over stand-alone R Notebooks:

* They automatically build a home page that lists all blog posts in reverse chronological order
* Summaries of each notebook/article are automatically produced, including a description and optional image
* Posts can be tagged so that users can quickly navigate to tagged content
* They are also working on a search feature
* They use consistent styles that look a lot prettier than the default HTML notebooks

Unfortunately, it wasn't as simple to build Radix notebooks as it was to build simple HTML notebooks.  Unlike HTML notebooks that are rendered automatically whenever you hit "save" - allowing you to work iteratively on different parts of the notebook without re-running all your code -  the Radix notebooks must be knit and run as a single unit to produce the output.  Some notebooks that require significant computation may be difficult to knit into the proper output.  It seems like producing a Radix article requires a bit more intent and some focus on making the article easier to knit than we might be used to.

### Installing Radix

Radix requires pandoc and version 1.2 of R Studio.  This is currently (as of October, 2018) only available in preview.  So you will need to start by downloading a new version of R Studio.

After that, the Radix package should be installed from the github repository (which presents a bit of a challenge behind the corporate firewall).  It should be as simple as running:

```
library("devtools")
devtools::install_github("rstudio/radix")
```

But in order to get past the proxy you will need to first run this (see note here):

```
library(httr)
set_config(
  use_proxy(url="proxy.domain.com", port=port, username="user",password="pass")
)
```

This also failed, complaining that it was missing two dependencies: whisker and downloader.  These need to be installed from CRAN and will require a different proxy setup:

```
Sys.setenv(http_proxy = "http://proxy.domain.com:port/", http_proxy_user = "ask")
options(download.file.method= "internal")
```

Then you'll be able to run:

```
install.packages("whisker")
install.packages("downloader")
```

I typically run these commands in R rather than R Studio as I have more success with them there.

For some reason, after running this I was still getting an error saying that "::" was defunct.  I had to re-open R and run just the radix installation (with the httr proxy setup) after installing whisker and downloader.  Not sure why this install was so complicated, but eventually it worked.

### Radix Documentation

* [Radix Introduction](https://blog.rstudio.com/2018/09/19/radix-for-r-markdown/)
* [Publishing a Radix Blog](https://rstudio.github.io/radix/blog.html)
* Example Blog: [TensorFlow](https://blogs.rstudio.com/tensorflow/)  (GitHub source [here](https://github.com/rstudio/tensorflow-blog))

EDA of FCB inventory detail data from KCMS.VW_FCT_INV_DAY_STO_CON.  This includes item-level details for FCB audits, including whether  the item is on the salesfloor or backroom.  This data set allows  us to calculate what percentage of inventory is in the backroom.

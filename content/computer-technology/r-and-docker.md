---
title: R and Docker
---

## Overview

R is notorious for being difficult to deploy in production environments.  At least, that is one of the major complaints when people choose to use Python for production data science work over R.  If you've ever had to manage a production R server, you've probably run into some of the following problems:

* Need to maintain different versions of R
* Need to manage and coordinate package use.  This is not easy because:
  * Different data science solutions might want different versions of the packages
  * R installs at the system level (as do the packages), so there's not an easy way to isolate the dependencies for different applications

These dependency management problems - especially involving system-level dependencies for applications - is exactly what docker was built to address.  But installing R in a docker environment isn't necessarily the easiest thing either.  This page will describe some options for how to use R inside docker and some best practices as well.

## Rocker (pre-built docker images)

One of the easier ways to get going is to just use the pre-built docker images provided by the [Rocker Project](https://www.rocker-project.org/).  Rocker offers docker images such as:

* rocker/rstudio - R and R Studio installed on Debian 8 or 9 (depending on R version)
* rocker/tidyverse - An extension of rocker/rstudio that installs the tidyverse packages
* rocker/shiny - A shiny server installed on top of rocker/rstudio

For each of these you just specify the version of R that you want (example: "rocker/rstudio:3.6.3"), and you should be good to go.

The downside to these images is that they can be pretty big (which is true of all R images).  You're also going to want to modify the underlying install eventually.  This means you're going to have to peak under the covers at some point and get familiar with how these images work so you can modify and extend them.

## Custom R Docker Images (on Ubuntu)

Personally, I opted to start building my own docker images for R early on because I had a lot of applications that required ODBC connections to SQL Server Database.  The ODBC drivers had to be installed at the OS level, and I was having the hardest time doing this on Debian for some reason.  Someone on my team had a working image with R and ODBC running on Ubuntu, and I decided to copy this.  I ended up with the following 3 core docker images.  They are separated for re-usability, but they can easily be combined as well.

### ubuntu-odbc

The first Dockerfile begins with Ubuntu 16.04 and installs the ODBC drivers required to connect to a SQL Server Database.

```
# File: Dockerfile
FROM ubuntu:16.04

RUN echo "Installing ODBC drivers..." \
  && apt-get update \
  && apt-get install -y --no-install-recommends \
     unixodbc-dev \
     gnupg2 \
     curl \
     libssl1.0.0 \
     gcc \
     apt-transport-https \
     ca-certificates \
     apt-utils \
  && curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add - \
  && curl https://packages.microsoft.com/config/ubuntu/16.04/prod.list > /etc/apt/sources.list.d/mssql-release.list \
  && apt-get update \
  && ACCEPT_EULA=Y apt-get install msodbcsql17
```

### ubuntu-r

The next Dockerfile extends the first one and installs base R.  This installs the latest version of R (3.6) instead of the default version available through apt (3.2):

```
# File: Dockerfile
FROM ubuntu-odbc:16.04

RUN echo "Installing R Base..." \
  && echo \
     "deb https://cloud.r-project.org/bin/linux/ubuntu xenial-cran35/" >> \
     /etc/apt/sources.list \
  && apt-key adv \
     --keyserver keyserver.ubuntu.com \
     --recv-keys E298A3A825C0D65DFD57CBB651716619E084DAB9 \
  && apt-get update \
  && apt-get install -y r-base
```

### ubuntu-shiny-server

Next we install the Shiny Server on top of the previous image:

```
# File: Dockerfile
FROM ubuntu-r:1.0

RUN echo "Installing Shiny Server..." \
  && R -e "install.packages(c('shiny', 'rmarkdown'), repos='https://cran.rstudio.com/')" \
  && apt-get install -y \
     gdebi-core \
     wget \
     xtail \
  && wget https://download3.rstudio.org/ubuntu-14.04/x86_64/shiny-server-1.5.9.923-amd64.deb \
  && gdebi -n shiny-server-1.5.9.923-amd64.deb \
  && rm shiny-server-1.5.9.923-amd64.deb \
  && cp -R /usr/local/lib/R/site-library/shiny/examples/* /srv/shiny-server/ \
  && chown shiny:shiny /var/lib/shiny-server

EXPOSE 3838

COPY shiny-server.sh /usr/bin/shiny-server.sh

CMD ["/usr/bin/shiny-server.sh"]
```

This is actually based on the rocker/shiny image at: https://hub.docker.com/r/rocker/shiny/dockerfile.

It's essentially the same thing but on Ubuntu instead of Debian.  It also doesn't RStudio installed, but it does have the ODBC drivers I needed.

The "shiny-server.sh" script mentioned in the build file is a simple script that runs Shiny Server:

```
#!/bin/sh
# File: shiny-server.sh

# Make sure the directory for individual app logs exists
mkdir -p /var/log/shiny-server
chown shiny.shiny /var/log/shiny-server

if [ "$APPLICATION_LOGS_TO_STDOUT" != "false" ];
then
    # push the "real" application logs to stdout with xtail in detached mode
    exec xtail /var/log/shiny-server/ &
fi

# start shiny server
exec shiny-server 2>&1
```

## Installing Packages

OK, so we have a base image with R installed and whatever other customizations we require for the base operating system.  Now how do we install the specific set of packages that your program needs?  My solution to this is based on the repo2docker project which specifies all kinds of different config files to help build docker environments.  Their preferred solution for R is to have a "install.R" file that installs all of the packages your application needs.  My typical install.R file has evolved over time and is shown below:

```
# File: install.R
#
# Script used to install R dependencies.  This uses a helper function
# that ensures any failure to load a package results in immediate failure
# of the script with a non-zero exit code.  This is suitable for use in
# docker builds where the non-zero exit code will result in a failed build
# and allow the problem to be investigated.

#' Installs the given package(s) or quit with an error.
install_or_die <- function(pkg, version=NA, ...) {
  if (is.na(version)) {
    install.packages(pkg, ...)
  } else {
    devtools::install_version(pkg, version, ...)
  }

  if (!require(pkg, character.only=TRUE)) {
    cat(paste0("Error installing package: ", pkg, "\n"))
    quit(save="no", status=100)
  }
}

install_or_die("devtools") # load first, since install_or_die needs this
install_or_die("tidyr", version="1.1.0")  # 1.1.1 has compile error

PACKAGES <- c(
  "shinydashboard",
  "shinydashboardPlus",
  "shinyEffects",
  "stringr",
  "DT",
  "scales",
  "plotly",
  "tidyverse",
  "odbc",
  "R6"
)

for (pkg in PACKAGES) {
  install_or_die(pkg)
}
```

You'll notice that we don't just use the typical "install.packages()" command.  Instead, we define a custom function "install_or_die()" which does two things:

1. It enables us to specify the exact version of the package we want to install
2. It checks to see if that package installed successfully and quits with a non-zero exit code in the event of an error

The first option is important because you don't always want the latest version of a library.  In fact, as shown above, we ran into a problem with tidyr version 1.1.1 not compiling on Ubuntu, and had to specify version 1.1.0 instead.  The second option is important because if you run this from a Dockerfile, you want your build to fail in the event of an error.  If you just use "install.packages()" by itself, it will print out an error but keep going if a package fails to load.  This makes it look like your build succeeded - until you try to run it.  Then you're scouring your log files trying to figure out what went wrong.

The "install.R" file gives you a lot of flexibility with how you load your libraries.  Once it's ready, you can easily include it in your Dockerfile with:

```
COPY install.R install.R
RUN echo "Installing R packages..." \
  && RScript install.R
```

Some R packages require libraries to be installed at the OS level as well.  In fact, the packages in the example above will not load successfully unless you first run the following commands:

```
apt-get install -y \
     libcurl4-openssl-dev \
     libssl-dev \
     libxml2-dev \
     libv8-3.14-dev
```

These commands can be put in your Dockerfile before you load the R packages.

### install.R without Docker

The "install.R" file has proved itself to be so useful that I actually use it even in projects where I'm not using docker.  In one case I was manually administering an Ubuntu server with Shiny Server running on it.  We deployed new applications by copying them to the server.  However, it could become quite a chore to install all the packages that the app developers needed - especially when we had to migrate servers and I then found myself looking through code to try and see what libraries each application needed.  This process was greatly simplified by creating an "install.R" file for each application that showed exactly what dependencies it needed.  Any system-level dependencies were captured in a separate "install.sh" file.  I won't claim that it's as easy as running these two scripts to get everything installed correctly.  In fact, this is where I discovered the problems with tidyr 1.1.1 and had to instead install version 1.1.0.  But even when stepping through the file manually and having to modify the install process slightly, keeping a record of what you did in the "install.R" file is incredibly helpful and valuable.  It very clearly documents what you did to install a specific application, and it will make your life much easier if you ever have to do it again.

If you are developing an application and having a hard time finding all the packages you used, a useful trick is to run the "sessionInfo()" command.  This will print out information such as that below:

```
R version 3.5.2 (2018-12-20)
Platform: x86_64-w64-mingw32/x64 (64-bit)
Running under: Windows >= 8 x64 (build 9200)

Matrix products: default

locale:
[1] LC_COLLATE=English_United States.1252  LC_CTYPE=English_United States.1252    LC_MONETARY=English_United States.1252
[4] LC_NUMERIC=C                           LC_TIME=English_United States.1252   

attached base packages:
[1] stats     graphics  grDevices utils     datasets  methods   base    

other attached packages:
[1] ggplot2_3.1.0 odbc_1.1.6    dplyr_0.8.0.1 tidyr_0.8.3

loaded via a namespace (and not attached):
 [1] Rcpp_1.0.0       rstudioapi_0.9.0 magrittr_1.5     hms_0.4.2        munsell_0.5.0    tidyselect_0.2.5 bit_1.1-14       colorspace_1.4-0
 [9] R6_2.4.0         rlang_0.3.1      plyr_1.8.4       blob_1.1.1       tools_3.5.2      grid_3.5.2       gtable_0.2.0     DBI_1.0.0      
[17] withr_2.1.2      lazyeval_0.2.1   yaml_2.2.0       bit64_0.9-7      assertthat_0.2.0 tibble_2.0.1     crayon_1.3.4     purrr_0.3.0    
[25] glue_1.3.0       compiler_3.5.2   pillar_1.3.1     scales_1.0.0     pkgconfig_2.0.2
```

The list of "other attached packages" shows you all of the packages that you have loaded and the specific versions that you are using.  This is the list of packages you will want to put in your "install.R" file.

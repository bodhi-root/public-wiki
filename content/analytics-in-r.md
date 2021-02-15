---
title: Analytics in R
---

## Getting Started

R can be a difficult language to get used to.  It's functional programming style can be difficult for programmers used to object-oriented design.  It tends to have very powerful functions with lots of optional parameters that let you do large amounts of processing with a single call.  Some R scripts may just be a few lines of code, but those few lines can take an hour to write, to understand, and to analyze/optimize.  Don't get discouraged when you start.  Mastering this language will yield numerous benefits over the long-run, and you'll soon forget the difficulties of writing those first few scripts.  Things will also be infinitely easier if you use Hadley Wickham's libraries - specifically, the "dplyr" library makes all the basic data munging tasks a snap!

## Installing R and R Studio

R can be downloaded from https://www.r-project.org/.  You will also want to download R Studio from: https://www.rstudio.com/.  R Studio is a development environment that lets you write scripts, execute code, and provides integrated help, chart tools, and environment management utilities.  You will also need to install various packages depending on the type of work you want to do.  A good list of starting packages is:

* [tidyverse](https://www.tidyverse.org/) -  "An opinionated [collection of R packages](https://www.tidyverse.org/packages) designed for data science. All packages share an underlying philosophy and common APIs."   
  * [dplyr](http://dplyr.tidyverse.org/) -  (great intro to dplyr available here)
  * [ggplot2](http://ggplot2.tidyverse.org/) - Charting library
  * [stringr](http://readr.tidyverse.org/) - String utilities
  * [readr](http://readr.tidyverse.org/) - Advanced data reading tools
  * [tidyr](http://tidyr.tidyverse.org/) - Reshape data from wide to long format (sometimes needed for data from Excel)
  * [readxl](https://readxl.tidyverse.org/) - Used for creation/manipulation of Excel file
* [RJDBC](https://cran.r-project.org/web/packages/RJDBC/RJDBC.pdf) - Used to connect to databases through a Java/JDBC bridge
* [RODBC](https://cran.r-project.org/web/packages/RODBC/RODBC.pdf) - Used to connect to databases via ODBC connections
* [forecast](https://cran.r-project.org/web/packages/forecast/forecast.pdf) - If you're going to do any forecasting

Two other good libraries for machine learning are below.  Be careful with these ones.  They can be monster installs!  Both of these are packages that provide a common interface for various machine learning algorithms.  The actual algorithms are typically each installed as their own package.  If you install these with all of their suggested dependencies the install can take as much as an hour for each one.

* [mlr](https://cran.r-project.org/web/packages/mlr/mlr.pdf) - Machine learning library ([tutorial](https://mlr-org.github.io/mlr-tutorial/devel/html/))
* [caret](https://cran.r-project.org/web/packages/caret/caret.pdf) - Machine learning library

## Helpful Resources

### R Cheatsheets

https://www.rstudio.com/resources/cheatsheets/

### QuickR

https://www.statmethods.net/

Quick introduction with useful code snippets. This is very helpful when first learning R. Includes sections on Data Input, Data Management, Statistics, Advanced Statistics, Graphs, and Advanced Graphs.

### DataCamp

https://www.datacamp.com/courses/free-introduction-to-r

Numerous courses on R, Python, SQL, GIT, and Shell

### R for Data Science

http://r4ds.had.co.nz/

R for Data Science is a book by Hadley Wickham covering a wide range of topics. Hadley Wickham is one of the top contributors to R, providing paradigm-changing libraries like: tidyr, dplyr, ggplot2, reshape2, stringr, and readr.

The online resource for this book is a great resource for getting started and learning best practices with R:

### Style Guides

Hadley Wickham's: http://adv-r.had.co.nz/Style.html

Google: https://google.github.io/styleguide/Rguide.xml

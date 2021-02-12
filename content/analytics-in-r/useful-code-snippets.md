---
title: Useful Code Snippets
---

This page contains useful code that I frequently have to look up for syntax examples.  This code can be copied and pasted and modified as needed, but it should illustrate the general approach of some useful methods.

## dplyr "group_by" & "do" Command

The one function in dplyr for which I can never seem to remember the syntax is "apply".  This function allows you to take a grouped data frame and apply any transformation you'd like to each group.  A function can be provided which performs the transformation, and the data frames it returns are joined together via rbind.

```
my.function <- function(df) {
  # some function that takes a data frame as input and returns a data frame
}

df.result <- df %>%
  group_by(item) %>%
  do(my.function(.))
```

## Foreach Loop (and parallel processing)

The "foreach" package provides a nice extension to the regular "for" loop, allowing us to combine the results at the end of the loop and also to quickly enable parallel processing.  The following code snippet is a simple loop:

```
library("foreach")
df.result <- foreach (i = 1:n.files, .combine=rbind) %do% {
  ...
}
```

The loop will be executed with values of i ranging from 1 to 'n.files.'  Each iteration is expected to return a data frame (although it could return anything or even nothing, if you want).  The return values of each iteration will be combined at the end with 'rbind'.  (Other popular implementations are to return numeric outputs and combine them at the end with 'c').

A loop written this way can easily be turned into a parallel processing job with the "doParallel" package.  We need only setup the parallel environment and change the "%do%" to "%dopar%" as shown below.  When running in parallel, you have to specify required packages in the ".packages" parameter.

```
library("doParallel") # imports "foreach" as a dependency

registerDoParallel(cores=N.CORES) # specify number of parallel cores to use

df.result <- foreach (i = 1:n.files, .combine=rbind, .packages="dplyr") %dopar% {
  ...
}
```

## Obtaining the Size of an Object

In RStudio you can just hover the mouse over an object, and it will tell you the size in bytes.  If you want to do this programmatically the "pryr" library has a useful function.  Additional information can be found at: http://adv-r.had.co.nz/memory.html.

```
library("pryr")
object_size(df)
```

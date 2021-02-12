---
title: Object Oriented R
---

## Overview

R has several paradigms for creating object-oriented code.  These include:

* S3
* S4
* RC (Reference Classes)
* R6

Hadley Wickham has a [section of his website](https://adv-r.hadley.nz/oo.html) that provides an overview of each of these in detail.  Hadley believes that S3 is the most important of these systems (due to it's widespread use in base R and extensibility).  However, many traditional programmers (like myself) would argue that S3 is not really an object-oriented system.  It is definitely a [functional programming model](https://en.wikipedia.org/wiki/Functional_programming).  S4 is just a pain in the butt. For these reasons, I'd recommend RC or R6.

Hadley Wickham used to have [a page documenting RC](http://adv-r.had.co.nz/R5.html).  However, he has since moved on to recommending R6 as his preferred method of building true object-oriented code in R.  His reasons are:

* R6 is much simpler. Both R6 and RC are built on top of environments, but while R6 uses S3, RC uses S4. This means to fully understand RC, you need to understand how the more complicated S4 works.
* R6 has comprehensive online documentation at https://r6.r-lib.org.
* R6 has a simpler mechanism for cross-package subclassing, which just works without you having to think about it. For RC, read the details in the “External Methods; Inter-Package Superclasses” section of ?setRefClass.
* RC mingles variables and fields in the same stack of environments so that you get (field) and set (field <<- value) fields like regular values. R6 puts fields in a separate environment so you get (self$field) and set (self$field <- value) with a prefix. The R6 approach is more verbose but I like it because it is more explicit.
* R6 is much faster than RC. Generally, the speed of method dispatch is not important outside of microbenchmarks. However, RC is quite slow, and switching from RC to R6 led to a substantial performance improvement in the shiny package. For more details, see vignette("Performance", "R6").
* RC is tied to R. That means if any bugs are fixed, you can only take advantage of the fixes by requiring a newer version of R. This makes it difficult for packages (like those in the tidyverse) that need to work across many R versions.
* Finally, because the ideas that underlie R6 and RC are similar, it will only require a small amount of additional effort to learn RC if you need to.

With that said, Hadley still recommends using S3 whenever possible instead of any of the other approaches.

## S3

S3 is the most common object-oriented system in R.  In fact, you've used it every time you run a function like "print", "plot", or "summary" that can take different types of values.  The way this is achieved is by defining a "class" as a structure (basically just a list) with an additional piece of metadata providing the class name.  We could create a simple "Person" object like this:

```
p1 <- structure(
  list = (
    name = "Daniel"
  ),
  class="Person"
)
```

Then we define and call functions as shown below:

```
# Define a generic function that dispatches to class-specific functions
say_hello <- function(obj) {
  UseMethod("say_hello")
}

# Class-specific function that will be called if "obj" is of class "Person"
say_hello.Person <- function(obj) {
  message(sprintf("Hi! My name is %s", obj$name))
}

# Invoke the function like this:
say_hello(p1)
```

Notice that all functions are defined in the global namespace.  They are not encapsulated in any one object or class.  This is why many don't consider this a true object-oriented paradigm.  This approach means that you need to be careful with function names.  You don't want to have collisions with other functions from other packages.  If you are writing a package you will only want to export functions that you want others to see.  In the code above, we would typically hide the "say_hello.Person" function and just expose the generic function.  It is also advisable to create helper functions to create objects.  Hadley recommends the following:

```
# Constructor to create "Person" objects.
# Can be very strict and expect variables of specific types.
# Goal is speed over ease-of-use or safety.
# Typically only called from inside your own code/package.
#
new_Person <- function(name) {
  structure(
    list(
      name = name
    ),
    class = "Person"
  )
}

# Helper method to create a "Person" object.  Can be flexible,
# safe, or validate parameters and throw errors if invalid.
#
Person <- function(name) {
  name <- as.character(name)
  new_Person(name)
}
```

The real beauty of S3 is that someone can later define their own classes and still use existing functions such as "print", "plot", and "summary".  They just need to implement a class-specific version for each of these functions.

## R6

[Link to Hadley's docs](https://adv-r.hadley.nz/r6.html)

R6 is Hadley's preferred method for doing true object-oriented programming in R and is actually used in packages like shiny.  An R6 class looks like this:

```
Person <- R6Class(
  "Person",
  public = list(
    name = NA,
    initialize = function(name) {
      self$name <- name
    },
    say_hello = function() {
      message(sprintf("Hi! My name is %s", self$name))
    }
  )
)

p1 <- Person$new("Daniel")
p1$say_hello()
```

This is very similar to the built-in RC model.  However, methods can be defined as either "public", "private", or "active".  Each is defined in its own list.  Methods can also be added after the initial class is defined.  The code below is equivalent to above:

```
Person <- R6Class(
  "Person",
  public = list(
    name = NA,
    initialize = function(name) {
      self$name <- name
    }
  )
)

Person$set("public", "say_hello", function() {
  message(sprintf("Hi! My name is %s", self$name))
})
```

Public methods/fields can be called/accessed by anyone.  Private means that only the class can call these methods or use these variables.  If a function is defined as "active", that means it is actually defining an "active field."  Active fields look like regular fields/properties, but reading or writing them invokes a function where additional code can be executed.  Hadley provides the following example:

```
Rando <- R6::R6Class("Rando", active = list(
  random = function(value) {
    if (missing(value)) {
      runif(1)
    } else {
      stop("Can't set `$random`", call. = FALSE)
    }
  }
))
x <- Rando$new()
x$random
#> [1] 0.0808
x$random
#> [1] 0.834
x$random
#> [1] 0.601
```

Notice how each time the field "random" is accessed it returns a different random number.  If the user were to try to assign a value to "random", the code would throw an error - making this a read-only field.

## Reference Classes (RC)

[Link to Hadley's docs](http://adv-r.had.co.nz/R5.html)

A simple reference class might look like this:

```
Person <- setRefClass(
  "Person",
  fields = c("name"),
  methods = list(
    initialize = function(name) {
      .self$name <<- name
    },
    say_hello = function() {
      message(sprintf("Hi! My name is %s", .self$name))
    }
  )
)

p1 <- getRefClass("Person")$new("Daniel")
p1$say_hello()
```

If you ever write large objects with multiple methods, you'll find this becomes a pain in the butt.  The biggest problem I have is that the functions must all be specified in one big list and separated by commas.  If you forget one comma or make one mistake anywhere inside a function, the entire class definition will fail to evaluate - usually with one of R's not-so-helpful errors that doesn't even tell you where the problem is.  For this reason it is helpful to define methods separately.  R lets you do this with:

```
Person <- setRefClass(
  "Person",
  fields = c("name"),
  methods = list(
    initialize = function(name) {
      .self$name <<- name
    }
  )
)


# define say_hello() in separate code block
Person$methods(say_hello = function() {
  message(sprintf("Hi! My name is %s", .self$name))
})
```

This will generate exactly the same object as before.  However, this time when you are writing and debugging your code you can get examine one function at a time.  If you get an error, you know it came from that particular function.

## S4

Don't use S4.  It looks awful.  Use R6 or S3 instead.

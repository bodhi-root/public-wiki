---
title: Optimization in R
---

## Overview

R offers multiple ways to perform optimization.  The solutions you use will depend on the type of problem you want to solve.  The following table lists common types of problems and some of the ways to solve them in R:

| Type | Description | R Method |
|------|-------------|-----------|
| Univariate (Smooth) | You have a continuous univariate function, "y=f(x)", where you want to find the value of "x" that minimizes "y". You may or may not have bounds on the allowed values of "x". | optimize() |
| Multivariate (Smooth) | You have a continuous multivariate function, "y = f(x1, x2, x3, ...)", where you want to find the vector "x" that minimizes "y". You may or may not have bounds on the allowed values of "x". | optim() |
| LP | Linear programming. You have a linear objective function that can be written as "y = ax + b" (where a, x, and b are vectors). These types of problems do not have optimas unless you restrict the values of "x". The type of solver needed for this will depend upon the types of constraints you place upon x. In the simplest case, these are linear constraints that can also be expressed in the form above. | Glpk, lpSolve, clpAPI |
| MILP | Mixed integer linear programming. This is a linear program where you also have integer or binary constraints on the allowed values of x.	 |
| Quadratic | Your objective function is multivariate and quadratic (it has an "x^2" and "x" term). | quadprog |
| Other | If you have something funky... why not try a genetic or evolutionary algorithm? | rgenoud |

If you really get deep into this you will find that there are many different types of optimization problems and a slew of optimization packages that have various capabilities.  There doesn't really seem to be a "silver bullet" library that will take care of any problem you may encounter.  For an extensive list of available libraries see:

https://cran.r-project.org/web/views/Optimization.html

It is also helpful to become acquainted with packages such as "ROI" that try to provide a unified interface to different types of optimization problems, hiding some of the complexities of the underlying solvers and their individual packages.

## Resources

[Presentation on ROI library](https://www.r-project.org/conferences/useR-2010/slides/Theussl+Hornik+Meyer.pdf)

## Simple Univariate Optimization with optimize()

Suppose you have a univariate function such as the following:

![Image of Function](assets/univariate-function.png)

```
f <- function(x) {
 (x+4)*(x+1)*(x-1)*(x-3)/14 + 0.5
}
```

You can do a simple optimization with:

```
> optimize(f, c(-5, 4), tol=.0001)
$minimum
[1] -2.935373

$objective
[1] -2.9377
```

Notice that this function has two local optima.  If we just want to get the one where x > 0, we can use:

```
> optimize(f, c(0, 4), tol=.0001)
$minimum
[1] 2.223662
$objective
[1] -0.8613813
```

You have to provide boundaries for "x" when using this function, so it's good to have some idea of your domain.  You can also maximize by setting "maximize=TRUE".

## Simple Multivariate Optimization with optim()

If you have a multivariate objective function taking a vector "x" and producing a single value "y" such as:

```
f <- function(x) {
  (x[1] - 2)^2 + (x[2] - 5)^2
}
```

you can optimize with:

```
> optim(c(0,0), f)
$par
[1] 1.999940 5.000212

$value
[1] 4.841302e-08

$counts
function gradient
      75       NA

$convergence
[1] 0

$message
NULL
```

The example used here is a curved surface with a minimum at (2,5).  The solver didn't find this exactly, but it came pretty darn close.

"optim()" uses a gradient descent method and an initial starting point.  The search can be sped up if you can supply the gradient function, but this is not really needed.  You can also specify lower and upper boundaries on the domain of "x".  These are provided as vectors.

## Linear Programming with ROI

There are several different packages available in R for linear optimization.  The one you use might depend on your preferences or on the type of constraints you have.  Interfaces are available to several commercial solvers like CPLEX that are best-in-class.  Sandia Research laboratory did a study (link here) of different open source solvers that are alternatives to CPLEX.  They found that CLP (the Coin-OR Linear Programming) package was the best alternative, followed by GLPK and lpSolve.

The following example shows how to perform a typical linear optimization using the ROI library.  We'll use ROI so that you can easily change the solver that you want to use.  The example is taken from the [documentation page for the CLP ROI plugin](https://github.com/datastorm-open/ROI.plugin.clp) (and slightly modified):

```
require(ROI)
require(ROI.plugin.glpk)  # switch to "ROI.plugin.clp" if desired

## Simple linear program.
## maximize:   2 x_1 + 4 x_2 + 3 x_3
## subject to: 3 x_1 + 4 x_2 + 2 x_3 <= 60
##             2 x_1 +   x_2 + 2 x_3 <= 40
##               x_1 + 3 x_2 + 2 x_3 <= 80
##               x_1, x_2, x_3 are non-negative real numbers

LP <- ROI::OP(
  c(2, 4, 3),
  ROI::L_constraint(
    L = matrix(c(
      3, 4, 2,
      2, 1, 2,
      1, 3, 2), nrow = 3, byrow=T),
    dir = c("<=", "<=", "<="),
    rhs = c(60, 40, 80)
  ),
  max = TRUE)

res_lp <- ROI::ROI_solve(x = LP, solver = "glpk")   # solver="clp" for CLP
res_lp$solution
res_lp$objval
```

This should produce the following optimal values:

```
> res_lp$solution
[1]  0.000000  6.666667 16.666667
> res_lp$objval
[1] 76.66667
````

## ompr

'ompr' is a library that sits on top of the ROI interface and provides a more intuitive way to define optimization problems.  An example of an optimization problem solved by ompr is given below:

```
library(dplyr)
library(ROI)
library(ROI.plugin.glpk)
library(ompr)
library(ompr.roi)

result <- MIPModel() %>%
  add_variable(x, type = "integer") %>%
  add_variable(y, type = "continuous", lb = 0) %>%
  set_bounds(x, lb = 0) %>%
  set_objective(x + y, "max") %>%
  add_constraint(x + y <= 11.25) %>%
  solve_model(with_ROI(solver = "glpk"))

result
result$solution
get_solution(result, x)
get_solution(result, y)
```

Notice that several libraries are used.  As mentioned, 'ompr' is a wrapper for 'ROI'.  'ompr' provides a way to specify models.  'ompr.roi' is the binding between 'ompr' and the 'ROI' library.  We then need 'ROI' (which itself is just a way to define problems) and an optimizer plugin like 'ROI.plugin.glpk' to perform the actual optimization.

'ompr' only works for linear objective functions.  You also may need to specify your objective function using 'sum_expr()' as shown [here](https://dirkschumacher.github.io/ompr/).

## Genetic Algorithms (rgenoud)

For complicated, non-linear problems you may want to try a genetic algorithm.  One such library that supports both continuous and integer variables is 'rgenoud'.  An example is shown below:

```
library("rgenoud")

f.obj <- function(x) {
  if (sum(x) != 6) {return(-1000)}
  mean((m.random %*% x)^2)
}

result <- genoud(
  f.obj, nvars=n, max=TRUE,
  Domains=matrix(data=rep(c(0,1), n), nrow=n, ncol=2, byrow=T),
  #starting.values=c(0,0,rep(1,6),rep(0,32)),
  boundary.enforcement=1,
  data.type.int=TRUE)

result$value
result$par
```

'genoud' can take any objective function and try to optimize it.  Simples upper and lower boundaries can be placed upon the variables using the 'Domain' parameter.  Variables can also be restricted to be integer.  The example above further limits these to being binary values by indicating they are integers and in the range 0 to 1.  As noted in the [documentation for 'genoud'](https://www.rdocumentation.org/packages/rgenoud/versions/5.7-12.4/topics/genoud), we can also impose additional constraints by changing our objective function.  In this example, we only allow 6 of the values in 'x' to be 1 at any given time.  Any other solution returns a low result so that the optimizer will avoid it.

## Resources

* [Mixed Integer Programming in R with the ompr package](http://blog.revolutionanalytics.com/2016/12/mixed-integer-programming-in-r-with-the-ompr-package.html) (R blog)
* ['ompr' on github](https://dirkschumacher.github.io/ompr/) (with a good intro page)

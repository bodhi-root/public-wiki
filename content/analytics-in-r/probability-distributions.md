---
title: Probability Distributions
---

## Overview

Probability distributions are commonly used in R to simulate random data.  A vector of 1000 random values drawn from a normal distribution with mean 10 and standard deviation of 5 can be simulated with:

```
x <- rnorm(1000, mean=10, sd=5)
```

There are several probability distribution implemented in base R (and many more in add-on packages).  Each distribution implements a similar set of functions.  Using the normal distribution to illustrate, we have:

```
dnorm(x, mean=0, sd=1, log=FALSE)                     # Probability Density Function (PDF)
pnorm(q, mean=0, sd=1, lower.tail=TRUE, log.p=FALSE)  # Cumulative Distribution Function (CDF)
qnorm(p, mean=0, sd=1, lower.tail=TRUE, log.p=FALSE)  # Quantile function (inverse CDF)
rnorm(n, mean=0, sd=1)                                # Random sample generator
```

See “?Distributions” in R for more details

## List of Probability Distributions in R

Ever wonder what probability distributions might be good candidates for your data?  Here is my cheat sheet.  First, ask yourself if it is continuous or discrete. Then determine the range of support for your distribution. Is it -inf to +inf or just 0 to +inf?  Once you narrow in on a specific set of distributions that work, try them all and see which fits best!

### Continuous Distributions

| Name | Support | R Density Function | Links |
|------|---------|--------------------|-------|
| Normal | (-inf, +inf) | dnorm(x, mean=0, sd=1) | [Wikipedia](https://en.wikipedia.org/wiki/Normal_distribution) |
| Student's T | (-inf, +inf) | dt(x, df, ncp) | [Wikipedia](https://en.wikipedia.org/wiki/Student%27s_t-distribution) |
| Cauchy      | (-inf, +inf) | dcauchy(x, location=0, scale=1) | [Wikipedia](https://en.wikipedia.org/wiki/Cauchy_distribution) |
| Logistic    | (-inf, +inf) | dlogis(x, location=0, scale=1) | [Wikipedia](https://en.wikipedia.org/wiki/Logistic_distribution) |
| Log-Normal  | (0, inf)     | dlnorm(x, meanlog=0, sdlog=1) |[] Wikipedia](https://en.wikipedia.org/wiki/Log-normal_distribution) |
| Gamma       | (0, inf)     | dgamma(x, shape, rate=1, scale=1/rate) | [Wikipedia](https://en.wikipedia.org/wiki/Gamma_distribution) |
| F           | [0, inf)     | df(x, df1, df2, ncp) | [Wikipedia](https://en.wikipedia.org/wiki/F-distribution) |
| Exponential | [0, inf)     | dexp(x, rate=1)      | [Wikipedia](https://en.wikipedia.org/wiki/Exponential_distribution) |
| Weibull     | [0, inf)     | dweibull(x, shape, scale=1) | [Wikipedia](https://en.wikipedia.org/wiki/Weibull_distribution) |
| Chi-Squared | [0, inf)     | dchisq(x, df, ncp=0)        | [Wikipedia](https://en.wikipedia.org/wiki/Chi-squared_distribution) |
| Uniform     | (a,b)        | dunif(x, min=0, max=1)      | [Wikipedia](https://en.wikipedia.org/wiki/Uniform_distribution_(continuous)) |
| Triangle    | (a,b)        |                             |           |
| Beta        | (0, 1)       | dbeta(x, shape1, shape2, ncp=0) | [Wikipedia](https://en.wikipedia.org/wiki/Beta_distribution) |

### Discrete Distributions

| Name | Support | R Density Function | Links |
|------|---------|--------------------|-------|
| Binomial | {0, ..., n} | dbinom(x, size, prob) | [Wikipedia](https://en.wikipedia.org/wiki/Binomial_distribution) |
| Multinomial | {0, ..., n} | dmultinom(x, size, prob) | [Wikipedia](https://en.wikipedia.org/wiki/Multinomial_distribution) |
| Poisson     | {0, ..., inf} | dpois(x, lambda) | [Wikipedia] (https://en.wikipedia.org/wiki/Poisson_distribution)|
| Negative Binomial | {0, ..., inf} | dnbinom(x, size, prob, mu) | [Wikipedia](https://en.wikipedia.org/wiki/Negative_binomial_distribution) |
| Geometric | {0, ..., inf} | dgeom(x, prob) | [Wikipedia](https://en.wikipedia.org/wiki/Geometric_distribution) |
| Hypergeometric | | dypher | [Wikipedia](https://en.wikipedia.org/wiki/Hypergeometric_distribution) |

## Random Vectors of Correlated Values

The "MASS" library provides a handy function for creating a sample of random vectors where each of the values is normally distributed and where the underlying distributions may be correlated with each other.  The following code demonstrates:

```
library("MASS")
m.random <- mvrnorm(n=100, mu=v.mu, Sigma=m.cov)
```

In this case "v.mu" is a vector of means and "m.cov" is a covariance matrix.  If "n=1" a vector will be returned.  Otherwise, an "n x length(mu)" matrix will be returned with sample vectors in each row.

The covariance matrix must be positive-definite and symmetric.  If you are trying to create this from data that has gaps in it, you may not get a result that fits this criteria.  In this case the "nearPD" function can be used to find the nearest positive-definite matrix to the one you obtain empirically.  The following code should help:

```
v.mu <- colMeans(df.data)
m.cov <- cov(df.data, use="pairwise.complete.obs")

pd <- Matrix::nearPD(m.cov, keepDiag=TRUE, maxit=10000)  # not always needed
m.cov <- pd$mat

m.random <- mvrnorm(n=100, mu=v.mu, Sigma=m.cov)
```

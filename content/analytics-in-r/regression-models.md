---
title: Regression Models
---

This page contains quick code-snippets and samples for Linear Models (lm), Generalized Linear Models (glm), and Stepwise Regression Models (step).

## Linear Models (lm)

If the dependent and independent variables are in the same data frame, a linear model can be built and inspected very easily with:

```
model <- lm(Y ~ X1 + X2 + X3, data=my.data.frame)
summary(model)
```

If you want to use all of the variables in the data frame (except for the dependent variable), you can use the handy shortcut below (Y ~ .):

```
model <- lm(Y ~ ., data=my.data.frame)
```

By default, the model will include an implicit intercept term.  If you want to build a model that does not include the intercept, you must specify this in the model by adding a zero to the formula:

```
model <- lm(Y ~ X1 + X2 + X3 + 0, data=my.data.frame)
# NOTE: The "+ 0" specifies "no intercept"
```

## Generalized Linear Models (glm)

The "glm" function allows us to be build generalized linear models.  This extends the concepts of basic linear models, but allows different transformations to be performed.  The only time I have used this is to generate Logistic Regression Models using the following code:

```
# build and inspect model:
model <- glm(Y ~ X1 + X2 + X3, data=df, family="binomial")
summary(model)

# predict responses (probabilities of event)
Y.pred <- predict(model, type="response")

# get average predictions for events and non-events:
tapply(Y.pred, df$Y, mean)

# confusion matrix (threshold = 0.5):
table(df$Y, Y.pred > 0.5)
```

The code below is also useful for logistic models.  It displays the ROC curve and also calculates the area under the curve (AUC), a very important measure of model quality.

```
library("ROCR")
ROC.pred <- prediction(Y.pred, df$Y)
ROC.perf <- performance(ROC.pred, "tpr", "fpr")
plot(ROC.perf,
     colorize=TRUE,
     print.cutoffs.at=seq(0,1,by=0.1), text.adj=c(-0.2,1.7))

# area under curve:
as.numeric(performance(ROC.pred, "auc")@y.values)
```

## Stepwise Regression Models (step)

Determining which variables should be included in a regression and which should be omitted can require a lot of manual intervention, analysis, and sometimes subjective judgement calls.  Stepwise regression is an automated method to try and build a model with only the variables that are statistically significant and which improve goodness-of-fit statistics like R2 and AIC.  Stepwise regression can be applied to either linear models or generalized models.  The typical approach I use is as follows:

```
# Build a model using all variables (the "full" model)
model.full <- lm(Y ~ ., data=my.data.frame)
summary(model.full)

# Build a "minimal" model which uses no variables, only an intercept
model.min <- lm(Y ~ 1, data=my.data.frame)
summary(model.min)

# Iteratively add and remove variables to improve the model:
model.step <- step(model.min, scope=formula(model.full), direction='both')
summary(model.step)
```

The "step" function at the end is doing the real work here.  It requires:

1. __A starting model__.  In this case we begin with just the intercept so that "step" will begin by adding variables to the model)
2. __The scope or search space to examine__.  This is just a formula indicating all of the variables that can be added to the model.  Building a linear model against the full dataset allows us to easily obtain this.
3. __A direction to search__.  The direction can be "forward" (adding variables), "backward" (subtracting variables), or "both" (find the best variable to add and the best variable to subtract and do whichever operation produces a better result).  I typically use "both" since this should lead to a more exhaustive search and a better model.

## Advanced Usage ("caret" package)

The "caret" package provides several additional functions that allow us to use these models at an even more advanced level.  Topics covered by "caret" include:

1. Automatic detection and removal (or modification using PCA) of correlated input variables
2. Out-of-sample testing and model building that partitions the training set into "training" and "test" samples and builds models that avoid over-fitting

See the documentation for the "caret" package for more information.

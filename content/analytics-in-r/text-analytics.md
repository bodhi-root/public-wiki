---
title: Text Analytics
---

## Bag-of-Words Model

The bag-of-words model (see [Wikipedia](https://en.wikipedia.org/wiki/Bag-of-words_model)) treats text a collection of words.  Word order is ignored, and we are instead more interested in how many times each word occurs.  Text is usually normalized by:

1. Converting all text to lower- or upper-case
2. Removing symbols and punctuation (if appropriate)
3. Removing "stop words" (filler words like "the", "of", "and" which don't capture meaning)
4. "Stemming" words so that variations on a word (such as "working", "worked", "work") all resolve to a common stem ("work-")

Then we can take a representative set of words and convert it into a data frame, using the frequency with which each word occurs as an input to a model.  The following code shows how to do this using the "tm" (text mining) package:

```
# read data:
df.data <- read.csv("file.csv", stringsAsFactors=FALSE)

# create "corpus" and normalize:
corpus <- Corpus(VectorSource(df.data$text)) # create a corpus from a vector of strings
corpus <- tm_map(corpus, removePunctuation)  # remove punctuation
corpus <- tm_map(corpus, removeWords, stopwords("english")) # remove stop words
corpus <- tm_map(corpus, stemDocument)                      # stem words

# create term frequency matrix and filter to high-frequency terms:
frequencies = DocumentTermMatrix(corpus)
findFreqTerms(frequencies, lowfreq=20)
sparse = removeSparseTerms(frequencies, 0.995)

# convert to data frame:
df.model = as.data.frame(as.matrix(sparse))
colnames(df.model) = make.names(colnames(df.model)) # make column-names "R-friendly"
```

The data frame that's created contains a column for each term and the rows contain frequency counts for how often that term appears in a given entry.

At this point a model can be build using various techniques based on what you are trying to predict.  The following code shows how to build a simple CART model to the predict a binary variable called "outcome":

```
library(rpart)
model <- rpart(outcome ~ ., data=df.model, method="class")
```

---
title: Logistic Regression
date: 2023-09-05
categories: [Machine Learning]
tags: [logistic_regression, algorithms_implementation]
---

Logistic Regression is one of the most popular machine learning algorithms that is easy to understand and implement from scratch. The algorithm predominantly finds its application in binary classification tasks where the objective is to identify whether the input data belongs to our target group or not (logic '1' or '0', 'yes' or 'no', 'positive' or 'negative', 'cat' or 'not cat', etc.). Understanding the underlying working mechanisms of Logistic Regression can serve as a valuable foundation for understanding artificial neural networks (ANN) since it works quite similarly to how an individual neuron works. Consequently, neural networks can be seen as a sequence of stacked logistic regression classifiers.

# Introduction

After reading this post, you will be able to -

- Understand how the logistic regression works under the hood
- Implement the algorithm from scratch just using the python math library such as numpy
- Implement the algorithm using the tensorflow framework.

Before we dive deep into the mathematical part of the algorithm, it is beneficial to treat it as a black box that accepts an array of values (features representation) that describe an object (training example/input observation) and conduct predictions (inference) to determine the object's class in terms of probability.

# References

- [Logistic Regression For Binary Classification With Core APIs](https://www.tensorflow.org/guide/core/logistic_regression_core)
- [What is logistic regression? - by IBM](https://www.ibm.com/topics/logistic-regression)
- [Logistic Regression Detailed Overview](https://towardsdatascience.com/logistic-regression-detailed-overview-46c4da4303bc)
- [Chapter 5 - Logistic Regression - Speech and Language Processing. Daniel Jurafsky & James H. Martin](https://web.stanford.edu/~jurafsky/slp3/5.pdf)

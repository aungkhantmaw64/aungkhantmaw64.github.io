---
title: Logistic Regression
date: 2023-09-05
categories: [Machine Learning]
tags: [logistic_regression, algorithms_implementation]
---

Logistic Regression is one of the popular machine learning algorithms that is easy to understand and implement from scratch. The algorithm is mainly used in binary classification tasks for simple datasets and understanding its underlying working mechanisms can be helpful in understanding artificial neural networks (ANN) since it works quite similarly to how a single neuron work.

# Introduction

After reading this post, you will be able to -

- Understand how the logistic regression works under the hood
- Implement the algorithm from scratch just using the python math library such as numpy

Before we deep dive into the mathematical part of the algorithm, we need to approach it as a black box that accepts an array of values (features) that describes an object (training example) and predicts (inference) what that object is in terms of probability.

# References

- [Logistic Regression For Binary Classification With Core APIs](https://www.tensorflow.org/guide/core/logistic_regression_core)

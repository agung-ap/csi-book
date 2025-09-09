# 5 [](/book/grokking-continuous-delivery/chapter-5/)[](/book/grokking-continuous-delivery/chapter-5/)Dealing with noisy tests

### In this chapter

- explaining why tests are crucially important to CD
- creating and executing a plan to go from noisy test failures to a useful signal
- understanding what makes tests noisy
- treating test failures as bugs
- defining flaky tests and understanding why they are harmful
- retrying tests appropriately

It’d be nearly[](/book/grokking-continuous-delivery/chapter-5/) impossible to have continuous delivery (CD) without tests! For a lot of folks, tests are synonymous with at least the CI side of CD, but over time some test suites seem to degrade in value. In this chapter, we’ll take a look at how to take care of noisy test suites.

## [](/book/grokking-continuous-delivery/chapter-5/)[](/book/grokking-continuous-delivery/chapter-5/)Continuous delivery and tests

[](/book/grokking-continuous-delivery/chapter-5/)How do tests[](/book/grokking-continuous-delivery/chapter-5/)[](/book/grokking-continuous-delivery/chapter-5/) fit into CD? From chapter 1, CD is all about getting to a state where

-  you can safely deliver changes to your software at any time.
-  delivering that software is as simple as pushing a button.

How do you know you can safely deliver changes? You need to be confident that your code will do what you intended it to do. In software, you gain confidence about your code by testing it. Tests confirm to you that your code does what you meant for it to do.

This book isn’t going to teach you to write tests; you can refer to many great books written on the subject. I'm going to assume that not only do you know how to write tests, but also that most modern software projects have at least *some* tests defined for them (if that’s not the case for your project, it’s worth investing in adding tests as soon as possible).

## [](/book/grokking-continuous-delivery/chapter-5/)[](/book/grokking-continuous-delivery/chapter-5/)Ice Cream for All outage

## [](/book/grokking-continuous-delivery/chapter-5/)[](/book/grokking-continuous-delivery/chapter-5/)Signal vs. noise

## [](/book/grokking-continuous-delivery/chapter-5/)[](/book/grokking-continuous-delivery/chapter-5/)Noisy successes

## [](/book/grokking-continuous-delivery/chapter-5/)[](/book/grokking-continuous-delivery/chapter-5/)How failures become noise

## [](/book/grokking-continuous-delivery/chapter-5/)[](/book/grokking-continuous-delivery/chapter-5/)Going from noise to signal

## [](/book/grokking-continuous-delivery/chapter-5/)[](/book/grokking-continuous-delivery/chapter-5/)Getting to green

## [](/book/grokking-continuous-delivery/chapter-5/)[](/book/grokking-continuous-delivery/chapter-5/)Another outage!

## [](/book/grokking-continuous-delivery/chapter-5/)[](/book/grokking-continuous-delivery/chapter-5/)[](/book/grokking-continuous-delivery/chapter-5/)Passing tests can be noisy

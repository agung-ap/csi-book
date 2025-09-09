# 7 [](/book/grokking-continuous-delivery/chapter-7/)[](/book/grokking-continuous-delivery/chapter-7/)Give the right signals at the right times

### In this chapter

- identifying the points in a change’s life cycle when bugs can be introduced
- guaranteeing that bugs will not be introduced by conflicting changes
- weighing the pros and cons of conflict mitigation techniques
- catching bugs at all points in a change’s life cycle by running CI before merging, after merging, and periodically

In the previous[](/book/grokking-continuous-delivery/chapter-7/) chapters, you’ve seen CI pipelines running at different stages in a change’s life cycle. You’ve seen them run after a change is committed, leading to an important rule: *when the pipeline breaks, stop merging*. You’ve also seen cases where linting and tests are made to run before changes are merged, ideally to prevent getting to a state where the codebase is broken.

In this chapter, I’ll show the life cycle of a change. You’ll learn about all the places where bugs can be introduced, and how to run pipelines at the right times to get the signal if bug exists—and fix it as quickly as possible.

## [](/book/grokking-continuous-delivery/chapter-7/)[](/book/grokking-continuous-delivery/chapter-7/)CoinExCompare

[](/book/grokking-continuous-delivery/chapter-7/)CoinExCompare is a website[](/book/grokking-continuous-delivery/chapter-7/)[](/book/grokking-continuous-delivery/chapter-7/) that publishes exchange rates between digital currencies. Users can log onto the website and compare exchange rates—for example, between currencies such as CatCoin and DogCoin.

![](https://drek4537l1klr.cloudfront.net/wilson3/Figures/07-01.png)

The company has been growing rapidly, but lately has been facing bugs and outages. The engineers are especially confused because they’ve been looking carefully at their pipelines, and they think they’ve done a pretty good job of covering all the bases.

![](https://drek4537l1klr.cloudfront.net/wilson3/Figures/07-02.png)

## [](/book/grokking-continuous-delivery/chapter-7/)[](/book/grokking-continuous-delivery/chapter-7/)Life cycle of a change

## [](/book/grokking-continuous-delivery/chapter-7/)[](/book/grokking-continuous-delivery/chapter-7/)CI only before merge

## [](/book/grokking-continuous-delivery/chapter-7/)[](/book/grokking-continuous-delivery/chapter-7/)Timeline of a change’s bugs

## [](/book/grokking-continuous-delivery/chapter-7/)[](/book/grokking-continuous-delivery/chapter-7/)CI only before merging misses bugs

## [](/book/grokking-continuous-delivery/chapter-7/)[](/book/grokking-continuous-delivery/chapter-7/)A tale of two graphs: Default to seven days

## [](/book/grokking-continuous-delivery/chapter-7/)[](/book/grokking-continuous-delivery/chapter-7/)A tale of two graphs: Default to 30 days

## [](/book/grokking-continuous-delivery/chapter-7/)[](/book/grokking-continuous-delivery/chapter-7/)Conflicts aren’t always caught

## [](/book/grokking-continuous-delivery/chapter-7/)[](/book/grokking-continuous-delivery/chapter-7/)What about the unit tests?

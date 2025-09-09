# 6 [](/book/grokking-continuous-delivery/chapter-6/)[](/book/grokking-continuous-delivery/chapter-6/)Speeding up slow test suites

### In this chapter

- speeding up slow test suites by running faster tests first
- using the test pyramid to identify the most effective ratio of unit to integration to system tests
- using test coverage measurement to get to and maintain the appropriate ratio
- getting a faster signal from slow tests by using parallel and sharded execution
- understanding when parallel and sharded execution are viable and how to use them

In the preceding[](/book/grokking-continuous-delivery/chapter-6/) chapter, you learned how to deal with test suites that aren’t giving a good signal—but what about tests that are just plain old slow? No matter how good the signal is, if it takes too long to get it, it’ll slow down your whole development process! Let’s see what you can do with even the most hopelessly slow suites.

## [](/book/grokking-continuous-delivery/chapter-6/)[](/book/grokking-continuous-delivery/chapter-6/)Dog Picture Website

[](/book/grokking-continuous-delivery/chapter-6/)Remember Cat Picture[](/book/grokking-continuous-delivery/chapter-6/)[](/book/grokking-continuous-delivery/chapter-6/) Website from chapter 2? Its biggest competitor, Dog Picture Website, has been struggling with its velocity. Jada, the product manager, is upset because it’s taking months for even the simple features that users are demanding to make it to production.

![](https://drek4537l1klr.cloudfront.net/wilson3/Figures/06-01.png)

To understand why development is so slow for Dog Picture Website, let’s take a quick look at the architecture and pipeline. You might notice that the Dog Picture Website architecture is a bit less complex than some of the other architectures we’ve looked at: the engineers have separated their frontend and backend services, but they haven’t gone any further than that, and they haven’t moved any of their storage to the cloud.

![](https://drek4537l1klr.cloudfront.net/wilson3/Figures/06-02.png)

With such a simple architecture, why are they running into trouble?

##### Is moving to the cloud the answer?

One big difference between Dog Picture Website and Cat Picture Website you might notice is that Cat Picture Website uses cloud storage. Is that the answer here? Not to solve this problem! If anything, that would complicate the testing story because fewer of the components would be in the engineer’s control. (Other benefits outweigh these downsides, but that’s a topic for a different book!)

## [](/book/grokking-continuous-delivery/chapter-6/)[](/book/grokking-continuous-delivery/chapter-6/)When simple is too simple

[](/book/grokking-continuous-delivery/chapter-6/)The pipeline[](/book/grokking-continuous-delivery/chapter-6/)[](/book/grokking-continuous-delivery/chapter-6/) that Dog Picture Website is using seems simple and reasonable. At first glance, it might seem the same as the pipelines you’ve seen so far. But there is an important difference.

![](https://drek4537l1klr.cloudfront.net/wilson3/Figures/06-03.png)

This is the *only* pipeline that Dog Picture website uses. Its engineers use this to test, build, and upload both their frontend and backend images. There is no other pipeline. Back in chapter 2, you saw the architecture and pipeline design used by Dog Picture Website’s biggest competitor: Cat Picture Website.

![](https://drek4537l1klr.cloudfront.net/wilson3/Figures/06-04.png)

Cat Picture Website uses a separate pipeline for each of its services:

![](https://drek4537l1klr.cloudfront.net/wilson3/Figures/06-05.png)

Dog Picture Website has decided instead to have one pipeline for its entire system, which is a reasonable starting point, but also one that the company never evolved beyond. In particular, the task that runs tests runs all of the tests at once. In the sophistication of its pipeline design, Dog Picture Website is way behind its closest competitor!

## [](/book/grokking-continuous-delivery/chapter-6/)[](/book/grokking-continuous-delivery/chapter-6/)New engineer tries to submit code

[](/book/grokking-continuous-delivery/chapter-6/)Let’s take a look[](/book/grokking-continuous-delivery/chapter-6/)[](/book/grokking-continuous-delivery/chapter-6/) at what it’s like to try to submit code to Dog Picture Website and how the pipeline design, particularly the test aspect, impacts velocity. Sridhar, who is new to Dog Picture Website, has been working on the new Favorites feature that Jada was asking about. In fact, he’s already written the code that he thinks the feature needs and has written some tests as well. What happens next?

![](https://drek4537l1klr.cloudfront.net/wilson3/Figures/06-06.png)

Dog Picture Website’s problems are different from the ones we looked at in the previous chapter: its test suite is always green, but the tests are run only once a day in the evening, and in the morning they have to sort out who broke what. And just as we saw in chapter 2, this really slows things down!

## [](/book/grokking-continuous-delivery/chapter-6/)[](/book/grokking-continuous-delivery/chapter-6/)Tests and continuous delivery

[](/book/grokking-continuous-delivery/chapter-6/)This is a good[](/book/grokking-continuous-delivery/chapter-6/)[](/book/grokking-continuous-delivery/chapter-6/) time to ask an interesting question: with this process, is Dog Picture Website practicing continuous delivery (CD)? To some extent, the answer is always yes, in that the company has some elements of the practice, including deployment automation and *continuous testing*, but let’s look back again at what you learned in chapter 1. You’re doing CD when

-  you can safely deliver changes to your software at any time.
-  delivering that software is as simple as pushing a button.

Thinking about the first element, can Dog Picture Website safely deliver changes at any time? Sridhar merged his changes hours before the nightly automation noticed that the tests were broken. What if Dog Picture Website had wanted to do a deployment that afternoon; would that have been safe?

No! Definitely not! Because their tests run only at night:

-  The engineers will always have to wait until at least the day after a change has been pushed to deploy it.
-  The only time they know they are in a releasable state is immediately after the tests pass, before any other changes are added (say the tests pass at night and someone pushes a change at 8 a.m.: that immediately puts them back into the state where they don’t know whether they can release).

In conclusion, Dog Picture Website is falling short of the first element of CD.

#####  Vocab time

*Continuous testing*[](/book/grokking-continuous-delivery/chapter-6/) refers to running tests as part of your CD pipelines. It’s not so much a separate practice on its own as it is an acknowledgment that tests need to be run *continuously*. Just having tests isn’t enough: you may have tests but never run them, or you may automate your tests but run them only once in a while.

## [](/book/grokking-continuous-delivery/chapter-6/)[](/book/grokking-continuous-delivery/chapter-6/)Diagnosis: Too slow

[](/book/grokking-continuous-delivery/chapter-6/)Fortunately, Sridhar[](/book/grokking-continuous-delivery/chapter-6/) is an experienced engineer and has seen this kind of problem before!

![](https://drek4537l1klr.cloudfront.net/wilson3/Figures/06-07.png)

His manager is skeptical, but Sridhar is confident and Jada, their product manager, is overjoyed at the idea of doing something to fix their slow velocity. Sridhar looks at the average run times of the test suite over the past few weeks: 2 hours and 35 minutes. He sets the following goals:

-  Tests should run on every change, before the change gets pushed.
-  The entire test suite should run in an average of 30 minutes or less.
-  The integration and unit tests should run in less than 5 minutes.
-  The unit tests should run in less than 1 minute.

The numbers you choose to aim for with your test suite will depend on your project, but in most cases should be in the same order of magnitude as the ones Sridhar chose.

##### If it hurts, bring the pain forward!

Jez Humble[](/book/grokking-continuous-delivery/chapter-6/) and David Farley[](/book/grokking-continuous-delivery/chapter-6/) said it best in their 2011 book *Continuous Delivery*[](/book/grokking-continuous-delivery/chapter-6/) (Addison-Wesley): “If it hurts, do it more frequently, and bring the pain forward.” When something is difficult or takes a long time, our instinct might be to delay it as long as possible, but the best approach is the opposite! If you isolate yourself from the problem, you’ll be less motivated to ever fix it. So the best way to deal with bad processes is do them more often!

## [](/book/grokking-continuous-delivery/chapter-6/)[](/book/grokking-continuous-delivery/chapter-6/)The test pyramid

[](/book/grokking-continuous-delivery/chapter-6/)You may have[](/book/grokking-continuous-delivery/chapter-6/)[](/book/grokking-continuous-delivery/chapter-6/) noticed that the goals Sridhar set are different depending on the type of test involved:

-  The entire test suite should run in an average of 30 minutes or less.
-  The integration and unit tests should run in less than 5 minutes.
-  The unit tests should run in less than 1 minute.

![](https://drek4537l1klr.cloudfront.net/wilson3/Figures/06-08.png)

What are these kinds of tests I’m talking about? Sridhar is referring to the *test pyramid*, a common visualization for the kinds of tests that most software projects need and the approximate ratio of each kind of test that’s appropriate.

I don’t go into detail about the specific differences between these kinds of tests in general. Take at look at a book about testing to learn more!

The idea is that the vast majority of tests in the suite will be unit tests, a significantly smaller number of integration tests, and finally a small number of end-to-end tests. Sridhar has used this pyramid to set the goals for the Dog Picture website test suite:

![](https://drek4537l1klr.cloudfront.net/wilson3/Figures/06-09.png)

##### Service tests vs. UI tests vs. end-to-end tests vs. integration tests vs. . . .

If you have seen test pyramids before, you may have seen slightly different terminology used. The terminology is less important than the idea that different kinds of tests exist, and that the tests at the bottom of the pyramid are the least coupled and the tests at the top are the most coupled. (*Coupled* refers to the increasing interdependencies among components being tested, usually resulting in more complicated tests that take longer to run.)

## [](/book/grokking-continuous-delivery/chapter-6/)[](/book/grokking-continuous-delivery/chapter-6/)Fast tests first

[](/book/grokking-continuous-delivery/chapter-6/)One of the big[](/book/grokking-continuous-delivery/chapter-6/)[](/book/grokking-continuous-delivery/chapter-6/) reasons Sridhar is taking an approach to the tests based on the pyramid is that he knows that one immediate way to get feedback faster is to start grouping and running the tests based on the kinds of tests they are. Paul M. Duvall[](/book/grokking-continuous-delivery/chapter-6/) in *Continuous Integration*[](/book/grokking-continuous-delivery/chapter-6/) (Addison-Wesley, 2007) suggests the following:

**Run the fastest tests first**.

At the moment, Dog Picture Website is running all of its tests simultaneously, but when Sridhar identifies the unit tests in the codebase and runs them on their own, he finds that they already run in less than a minute. He’s already accomplished his first goal!

If he can make it easy for all the Dog Picture Website developers to run just the unit tests, they’ll have a quick way to get some immediate feedback about their changes. They can run these tests locally, and they can immediately start running these tests on their changes before they get merged. All he needs to do is find a way to make it easy to run these tests in isolation. He has a few choices:

-  Conventions around test location is the easiest way—for example, you could always store your unit tests beside the code that they test, and keep integration and system tests in different folders. To run just the unit tests, run the tests in the folders with the code (or in a folder called unit); to run the integration tests, run the tests in the integration test folder, and so forth.
-  Many languages allow you to specify the type of test somehow—for example, by using a build flag in Go (you can isolate integration tests by requiring them to be run with a build flag such as `integration`) or by using a decorator to mark tests of different types if you use the pytest package in Python.

Fortunately, Dog Picture Website has already been more or less following a convention based on test location: browser tests are in a folder called tests/browser and the unit tests live next to the code. The integration tests were mixed in with the unit tests, so Sridhar moved them into a folder called tests/integration and then updated their pipeline to look like this:

![](https://drek4537l1klr.cloudfront.net/wilson3/Figures/06-10.png)

## [](/book/grokking-continuous-delivery/chapter-6/)[](/book/grokking-continuous-delivery/chapter-6/)Two pipelines

[](/book/grokking-continuous-delivery/chapter-6/)Up until now, engineers[](/book/grokking-continuous-delivery/chapter-6/)[](/book/grokking-continuous-delivery/chapter-6/) had to wait until the nightly pipeline run to get feedback on their changes, because the pipeline takes so long to run. However the new “Run unit tests” task that Sridhar has made runs in less than a minute, so it’s safe to run that on every change, even before the change is merged. Sridhar updates the Dog Picture Website automation so that the following pipeline, containing only one task, runs on every change before merging:

![](https://drek4537l1klr.cloudfront.net/wilson3/Figures/06-11.png)

Dog Picture Website now has two pipelines, the preceding pipeline that runs on every change, and the longer, slower pipeline that runs every night:

![](https://drek4537l1klr.cloudfront.net/wilson3/Figures/06-12.png)

Is it bad to have two pipelines? The goal is to always s*hift left* and get as much information as early as possible (more about this in the next chapter), so this situation is not ideal. But by creating the separate, faster pipeline that can run on every change, Sridhar was able to improve the situation: previously, engineers got no feedback at all on their changes before they were merged. Now they will at least get some feedback. Depending on your project’s needs, you may have one pipeline, or you may have many. See chapter 13 for more on this.

#####  Takeaway

When dealing with a slow suite of tests, get an immediate gain by making it possible to run the fastest tests on their own, and by running those tests first, before any others. Even though the entire suite of tests will still be just as slow as ever, this will let you get some amount of the signal out faster.

## [](/book/grokking-continuous-delivery/chapter-6/)[](/book/grokking-continuous-delivery/chapter-6/)Getting the right balance

[](/book/grokking-continuous-delivery/chapter-6/)Sridhar has improved[](/book/grokking-continuous-delivery/chapter-6/)[](/book/grokking-continuous-delivery/chapter-6/) the situation, but his change has had virtually no effect on the integration and browser tests. They are just as slow as ever, and developers still have to wait until the next morning after pushing their changes to find out the results.

For his next improvement, Sridhar is once again going back to the testing pyramid. When he last looked at it, he was thinking about the relative speed of each set of tests. But now he’s going to look at the relative distribution of tests.

The pyramid also gives you guidelines as to how many tests of each type (literally, the quantity) you want to aim for. Why is that? Because as you go up the pyramid, the tests are slower. (And also harder to maintain, but that’s a story for another book!)

![](https://drek4537l1klr.cloudfront.net/wilson3/Figures/06-13.png)

Sridhar counts up the tests in the Dog Picture Website suite so he can compare its pyramid to the ideal. The Dog Picture Website looks more like this:

![](https://drek4537l1klr.cloudfront.net/wilson3/Figures/06-14.png)

## [](/book/grokking-continuous-delivery/chapter-6/)[](/book/grokking-continuous-delivery/chapter-6/)Changing the pyramid

[](/book/grokking-continuous-delivery/chapter-6/)Why is Sridhar[](/book/grokking-continuous-delivery/chapter-6/)[](/book/grokking-continuous-delivery/chapter-6/) looking at ratios in the pyramid? Because he knows that the ratios in this pyramid are not set in stone. Not only is it possible to change these ratios, but changing the ratios can lead to faster test suites. Let’s look again at the goals he set around execution time:

![](https://drek4537l1klr.cloudfront.net/wilson3/Figures/06-15.png)

Sridhar wants the integration and unit tests to run in less than 5 minutes. Currently, the integration tests are 65% of the total number of tests. The rest are 10% browser tests and 25% unit tests. Given that integration tests are slower than unit tests, imagine what a difference it could make if the ratio was changed (assuming the same total number of tests)—if the integration tests were only 20% of the total number of tests, and the unit tests were instead 70%. This would mean removing about two-thirds of the existing (slow) integration tests, and replacing them with (faster) unit tests, which would immediately impact the overall execution time.

With the ultimate goal of adjusting the ratios to speed up the test suite overall, Sridhar sets some new goals:

-  Increase the percentage of unit tests from 25% to 70%.
-  Decrease the percentage of integration tests from 65% to 20%.
-  Keep the percentage of browser tests at 10%.

## [](/book/grokking-continuous-delivery/chapter-6/)[](/book/grokking-continuous-delivery/chapter-6/)Safely adjusting tests

[](/book/grokking-continuous-delivery/chapter-6/)Sridhar wants[](/book/grokking-continuous-delivery/chapter-6/)[](/book/grokking-continuous-delivery/chapter-6/) to make changes in the ratio of unit tests to integration tests. He wants to do the following:

-  Increase the percentage of unit tests from 25% to 70%
-  Decrease the percentage of integration tests from 65% to 20%

He needs to increase the number of unit tests, while decreasing the number of integration tests. How will he do this safely, and where can he even start?

Measuring coverage will also run the unit tests, so sometimes you’ll see these combined as one task. (If the unit-test task fails, the coverage measurement task will probably fail too!)

Sridhar notices that Dog Picture Website’s pipeline doesn’t include any concept of test-coverage measurement. The pipeline runs tests, then builds and deploys, but at no point does it measure the code coverage provided by any of the tests. The very first change he’s going to make is to add test-coverage measurement into this pipeline, parallel to running the tests:

![](https://drek4537l1klr.cloudfront.net/wilson3/Figures/06-16.png)

Since the coverage task is just as fast as the unit-test task, he’s able to add it to the pipeline that runs before changes are merged.

##### Wait! Where’s the linting? I read chapter 4 and know linting is important, too. Shouldn’t Sridhar be adding linting?

I totally agree, and that’s probably going to be Sridhar’s next step once he deals with these tests, but he can tackle only one problem at a time! In chapter 2, you can see an overview of all the elements a CD pipeline should have, including linting.

## [](/book/grokking-continuous-delivery/chapter-6/)[](/book/grokking-continuous-delivery/chapter-6/)Test Coverage

[](/book/grokking-continuous-delivery/chapter-6/)Sridhar decides[](/book/grokking-continuous-delivery/chapter-6/)[](/book/grokking-continuous-delivery/chapter-6/) the first step toward safely adjusting the ratio of unit test to integration tests is to start measuring test coverage. What is test-coverage measurement, and why is it important?

*Test coverage* is a way of evaluating how effectively your tests exercise the code they are testing. Specifically, test coverage reports will tell you, line by line, which code under test is being used by tests, and which isn’t. For example, Dog Picture Website has this unit test for its search-by-tag logic:

```
def test_search_by_tag(self):
   search = _new_search()
   results = search.by_tags(["fluffy"])
   self.assertDogResultsEqual(results, "fluffy", [Dog("sheldon")])
```

This test is testing the method `by_tags`[](/book/grokking-continuous-delivery/chapter-6/) on the `Search` object, which looks like this:

```
def by_tags(self, tags):
   try:
     query = build_query_from_tags(tags)
   except EmptyQuery:
     raise InvalidSearch()
   result = self._db.query(query)
   return result
```

Test-coverage measurement will run the test `test_search_by_tag` and observe which lines of code in `by_tags` are executing, producing a report about the percentage of lines covered. The coverage for `by_tags` by `test_search_by_tag` looks this, with the light shading indicating lines that are executed by the text and the dark shading indicating lines that aren’t:

![](https://drek4537l1klr.cloudfront.net/wilson3/Figures/06-17.png)

It’s reasonable that this test doesn’t exercise any error conditions; good unit testing practice would leave that for another test. But in this case, `test_search_by_tag` is the only unit test for `by_tags`[](/book/grokking-continuous-delivery/chapter-6/). So those lines are not covered by any test at all. For this method, the test coverage is three out of five lines, or 60%.

##### Coverage criteria

The preceding example uses a coverage criteria called *statement coverage*[](/book/grokking-continuous-delivery/chapter-6/), which evaluates each statement to see whether it has been executed. Other, more fine-grained criteria can be used, such as *condition coverage*[](/book/grokking-continuous-delivery/chapter-6/). If an `if` statement has multiple conditions, statement coverage would consider the statement covered if it’s hit at all, but condition coverage would require that every condition be explored fully. In this chapter, I’ll stick to statement coverage, which is a great go-to.

## [](/book/grokking-continuous-delivery/chapter-6/)[](/book/grokking-continuous-delivery/chapter-6/)Enforcing test coverage

[](/book/grokking-continuous-delivery/chapter-6/)It’s important[](/book/grokking-continuous-delivery/chapter-6/)[](/book/grokking-continuous-delivery/chapter-6/) to remember that while Sridhar is making these changes, people are still working and submitting features. People are submitting more features (and bug fixes), and sometimes (hopefully, most of the time!) tests as well. This means that even as Sridhar looks at the test coverage, it could be going down!

But, fortunately, Sridhar knows a way to not only stop this from happening, but also use this to help his quest to increase the number of unit tests.

Does this sound familiar? You might recognize this as a very similar approach to the one Becky took in chapter 4 with linting. Measuring linting and measuring coverage have a lot in common.

Before going any further, Sridhar is going to update the coverage-measurement task to fail the pipeline if the coverage goes down. From the moment he introduces this change onward, he can be confident that the test coverage in the code base will at the very least not go down, but ideally go up as well.

Besides helping the overall problem, this is a great way to share the load such that Sridhar isn’t the only one doing all the work! He updates the task that runs the test coverage to run this script:

```bash
# when the pipeline runs, it will pass paths to the files
  # that changed in the PR as arguments
  paths_to_changes = get_arguments()
  
  # measure the code coverage for the files that were changed
  coverage = measure_coverage(paths_to_changes)
  
  # measure the coverage of the files before the changes; this
  # could be by retrieving the values from storage somewhere,
  # or it could be as simple as running the coverage again
  # against the same files in trunk (i.e. before the changes)
  prev_coverage = get_previous_coverage(paths_to_changes)
  
  # compare the coverage with the changes to the previous coverage
  if coverage < prev_coverage:
    # the changes should not be merged if they decrease coverage
    fail('coverage reduced from {} to {}'.format(prev_coverage, coverage))
```

You might recognize this as a variation on the linting script that Becky created in chapter 4.

## [](/book/grokking-continuous-delivery/chapter-6/)[](/book/grokking-continuous-delivery/chapter-6/)Test coverage in the pipeline

[](/book/grokking-continuous-delivery/chapter-6/)By introducing this[](/book/grokking-continuous-delivery/chapter-6/)[](/book/grokking-continuous-delivery/chapter-6/)[](/book/grokking-continuous-delivery/chapter-6/) script into the pre-merge pipeline, Sridhar has triaged the existing coverage problem: folks weren’t being fastidious about how they introduced unit tests. By adding automation to measure coverage and block PRs that reduce coverage, engineers can make more informed decisions about what to cover and not to. With Sridhar updating the unit-test coverage task to enforce requirements on test coverage, the pre-merge pipeline looks like this:

![](https://drek4537l1klr.cloudfront.net/wilson3/Figures/06-18.png)

This is a very subtle change from the previous iteration, but now Sridhar can continue on with his work and be sure that the features and bug fixes being merged as he works are going to either increase the coverage, or in the worst case, leave it the same.

##### Do I need to build this myself?

It depends! For most languages, you can choose from a lot of existing tools to measure your coverage, and even store and report on it over time. Many folks choose to write their own tools regardless, because it’s not very hard to implement and you have slightly more control over the behavior. You’ll need to investigate the tools available and decide for yourself.

## [](/book/grokking-continuous-delivery/chapter-6/)[](/book/grokking-continuous-delivery/chapter-6/)Moving tests in the pyramid with coverage

[](/book/grokking-continuous-delivery/chapter-6/)At this point[](/book/grokking-continuous-delivery/chapter-6/)[](/book/grokking-continuous-delivery/chapter-6/)[](/book/grokking-continuous-delivery/chapter-6/), the number of unit tests is likely to start to steadily increase, even without any further intervention, because Sridhar has made it a requirement to include unit tests alongside the changes that the engineers are making.

Will this be enough for him to achieve his goals? Remember that his goals are as follows:

-  Increase the percentage of unit tests from 25% to 70%
-  Decrease the percentage of integration tests from 65% to 20%

Over time, the ratios will likely trend in these directions, but not fast enough to make the dramatic kinds of changes Sridhar is looking for. Sridhar is going to need to write additional unit tests and probably also remove existing integration tests. How will he know which to add and which to remove?

![](https://drek4537l1klr.cloudfront.net/wilson3/Figures/06-19.png)

Sridhar looks at the code coverage reports, finds the code with the lowest coverage percentages, and looks at which lines are not covered. For example, he looks at the coverage of the `by_tags` function from a few pages ago.

The error case of having an empty query is not covered by unit tests. So Sridhar knows that this is a place where he can add a unit test. Additionally, if he can find an integration test that covers the same logic, he can potentially delete it. So he goes looking through the integration tests and finds a test called `test_invalid_queries`. This test creates an instance of the running backend service (this is what all the integration tests do), then makes invalid queries, and ensures that they fail. Looking at this test, Sridhar realizes he can cover all of the invalid query test cases with unit tests. He writes the unit tests, which execute in less than a second, and is able to delete `test_invalid_queries`, which took around 20 seconds or more. He still feels confident that the test suite would catch the same errors that it did before the change.

##### Should I measure coverage for my integration and end-to-end tests?

To get a complete idea of your test suite coverage, you may be tempted to measure coverage for your integration and end-to-end tests. This is sometimes possible, usually requiring the systems under test to be built with extra debug information that can be used to measure code coverage while these higher-level tests execute. You may find this useful; however, it’s usually something you have to build yourself and might give you a false sense of confidence. Your best bet will always be high unit-test coverage, so that metric is important in isolation, and you might miss it if you look at only the total test suite coverage as a whole.

## [](/book/grokking-continuous-delivery/chapter-6/)[](/book/grokking-continuous-delivery/chapter-6/)What to move down the pyramid?

[](/book/grokking-continuous-delivery/chapter-6/)To continue[](/book/grokking-continuous-delivery/chapter-6/)[](/book/grokking-continuous-delivery/chapter-6/) to increase the percentage of unit tests, Sridhar applies this pattern to the test suite:

1.  He looks for gaps in unit-test coverage (lines of code that are not covered). He looks at the packages and files with the lowest percentages first in order to maximize his impact.
1.  For the code he finds that isn’t covered, he adds unit tests that cover those lines.
1.  He looks through the slower tests (specifically, in this case, the integration tests) to find any tests that cover the logic now covered by the unit tests, and updates or deletes them.

By doing this, he is able to both dramatically increase the number of unit tests and reduce the number of integration tests (increase the number of fast tests and decrease the number of slow tests). Lastly, he audits the integration tests to look for duplicate coverage; for every integration test, he asks these questions:

-  Is this case covered in the unit tests?
-  What would cause this test case to fail when the unit tests pass?

If the case is covered in the unit tests already, and if there isn’t anything (that isn’t covered somewhere else) that would cause the integration test to fail when the unit tests pass, it is safe to delete the integration test.

##### Hold on, won’t I lose some information if I do this? Aren’t integration tests better than my unit tests? I’ve seen the memes; unit tests aren’t enough.

You’re right! The question is, how many integration tests do you need? The purpose of the integration tests is to make sure that all the individual units are wired together correctly. If you test the individual units, and then you test that the units are connected together correctly, you’ve covered nearly everything. At this point, it becomes a cost benefit tradeoff: is it worth the cost of running and maintaining integration tests that cover the same ground as unit tests, on the off chance that they might catch a corner case you missed? The answer depends on what you’re working on. If people’s lives are at stake, the answer may be yes; it’s important to make the right tradeoff for your software.

#####  It’s your turn: Identify the missing tests

[](/book/grokking-continuous-delivery/chapter-6/)Sridhar has found that the `Search` class has very low coverage in general, and he’s working his way through the reports to increase it. He looks at the coverage for the `from_favorited_search` method and sees this:

![](https://drek4537l1klr.cloudfront.net/wilson3/Figures/06-20.png)

He looks for the integration tests that cover the favorited search behavior and finds these tests:

`test_favorited_search_many_results`

`test_favorited_search_no_results`

`test_favorited_search_cache_connection_error`

`test_favorited_search_many_results_cached`

`test_favorited_search_no_results_cached`

Which integration tests should Sridhar consider removing? What unit tests might he add?

#####  Answers

This looks like a classic scenario in which the integration tests are doing all the heavy lifting. The unit tests are covering only one path—the path with no cached result and no errors—and the integration tests are trying to cover everything. Sridhar’s plan is to invert this: instead of covering one happy path with unit tests, and handling all the other cases with integration tests, he’ll replace all of the integration tests with `test_favorited_search`, and he’ll add unit tests to cover all of the integration test cases.

## [](/book/grokking-continuous-delivery/chapter-6/)[](/book/grokking-continuous-delivery/chapter-6/)Legacy tests and FUD

[](/book/grokking-continuous-delivery/chapter-6/)It can feel scary[](/book/grokking-continuous-delivery/chapter-6/)[](/book/grokking-continuous-delivery/chapter-6/)[](/book/grokking-continuous-delivery/chapter-6/)[](/book/grokking-continuous-delivery/chapter-6/) to make changes to, or even remove, tests that have been around for a long time! This is a place where you can often encounter *FUD*: fear, uncertainty and doubt[](/book/grokking-continuous-delivery/chapter-6/)[](/book/grokking-continuous-delivery/chapter-6/).

If you listen to the FUD, you might decide it’s too dangerous to make changes to the existing test suites: there are too many tests, it’s too hard to tell what they’re testing, and you become afraid of being the person who removed the test that, as it turned out, was holding the whole thing up.

If you find yourself thinking this way, it’s worth taking a moment to consider what FUD really is and where it comes from. It’s ultimately all about the *F*: fear. It’s fear that you might do something wrong, or make things worse, and it holds you back from making changes.

Then, think about why we have all the tests we do: the tests are meant to empower us, to make us feel confident that we can make changes that do what we want them to, without fear. FUD is the very opposite of what our tests are meant to do for us. Our tests are meant to give us confidence, and FUD takes that confidence away.

Don’t let FUD hold you back! When you hear FUD whispering to you that it’s too dangerous to make any changes, you can counter it with cold hard facts. Remember what tests are: they are a codification of how the test author thought the system was supposed to behave—nothing more or less than that. They aren’t even the system itself! Instead of giving in to the fear, take a deep breath and ask yourself: do I understand what this test is trying to do? If not, take the time to read it and understand it. If you understand it, consider yourself empowered to make changes. If you don’t make them, maybe no one will, and the sense of FUD that people feel about the test suite will only grow over time.

Just say no to FUD!

In general, working from a fear-based mindset, and giving into FUD, will prevent you from trying anything new. And that will prevent you from improving, and if you don’t improve your test suite over time, I can guarantee you that it will only get worse.

#####  Takeaway

When dealing with slow tests suites, looking at them through the lens of the testing pyramid can help you focus on where things are going wrong. If your pyramid is too top heavy (a common problem), you can use test coverage to immediately start to improve your ratios, and help you identify which tests can be replaced with faster and easier-to-maintain unit tests.

## [](/book/grokking-continuous-delivery/chapter-6/)[](/book/grokking-continuous-delivery/chapter-6/)Running tests in parallel

[](/book/grokking-continuous-delivery/chapter-6/)After working[](/book/grokking-continuous-delivery/chapter-6/)[](/book/grokking-continuous-delivery/chapter-6/) hard on the integration and unit tests, Sridhar has made as much improvement as he thinks he can for now. He met the goals he set for their relative quantities:

-  He has increased the percentage of unit tests from 25% to 72% (his goal was 70%).
-  He has decreased the percentage of integration tests from 65% to 21% (his goal was 20%).

The unit tests still run in less than a minute, but even meeting these goals, the integration tests still take around 35 minutes to run. His overall goal was for the integration and unit tests together to run in less than 5 minutes. Even though he has improved the overall time (shaving more than 1 hour from the total), these tests are still slower than he wants them to be. He’d like to be able to include them in the pre-merge tests, and at 35 minutes, this might be almost reasonable, but he has trick up his sleeve that will let him improve this substantially before he adds them.

He’s going to run the integration tests in parallel. Most test suites will by default run tests one at a time. For example, here are some of the integration tests that are left after Sridhar has reduced their number, and their average execution time:

1.  `test_search_query` (20 seconds)
1.  `test_view_latest_dog_pics` (10 seconds)
1.  `test_log_in` (20 seconds)
1.  `test_unauthorized_edit` (10 seconds)
1.  `test_picture_upload` (30 seconds)

Running these tests one at a time takes 90 seconds on average (20 + 10 + 20 + 10 + 30 = 90). Instead, Sridhar updates the integration test task to run these tests in parallel, running as many of them as possible at once individually. In most cases, this means running one test at a time per CPU core. On an eight-core machine, the five tests can easily run in parallel, meaning that executing them all will take only as long as the longest test: 30 seconds, instead of the entire 90 seconds.

If one test runs waaaaay longer than the others, you’ll still be held hostage to this test; for example, if one test took 30 minutes on its own, parallelization isn’t going to help and the solution is going to be to fix the test itself.

After his cleanup, Dog Picture Website has 116 integration tests. Running at an average of 18 seconds each, one at a time, they take about 35 minutes to run. Running them in parallel on an eight-core machine means that eight tests can execute at once, and the entire suite can execute in approximately one-eighth of the time, or about 4.5 minutes. By running the integration tests in parallel, Sridhar finally meets his goal of being able to run the unit and integration tests in less than 5 minutes.

## [](/book/grokking-continuous-delivery/chapter-6/)[](/book/grokking-continuous-delivery/chapter-6/)When can tests run in parallel?

[](/book/grokking-continuous-delivery/chapter-6/)Can any tests[](/book/grokking-continuous-delivery/chapter-6/)[](/book/grokking-continuous-delivery/chapter-6/) be run in parallel? Not exactly. For tests to be able to run in parallel, they need to meet these criteria:

-  The tests must not depend on each other.
-  The tests must be able to run in any order.
-  The tests must not interfere with each other (e.g., by sharing common memory).

##### Running unit tests in parallel is a smell

Remember, the goal of unit tests is to test functionality in isolation and to be *fast*, on the order of seconds or faster. If your unit tests are taking minutes or longer, tempting you to speed them up by running them in parallel, this is a sign that your unit tests are doing too much and are likely integration or system tests; there is a good chance you are missing unit tests entirely.

It is good practice to write tests that do not depend on or interfere with one another in any way. Therefore, if you are writing good tests, then you might not have any trouble at all making them run in parallel.

The trickiest requirement is probably making sure that tests do not interfere with one another. This can easily happen by accident, especially when testing code that uses any kind of global storage. With a little finesse, you’ll be able to find ways to fix your tests so that they can be totally isolated, and then the result will likely be better code overall (code that is less coupled and more cohesive).

When Sridhar updates the Dog Picture Website test suite to run in parallel, he finds a few tests that interfered with each other and have to be updated, but once he makes those fixes, he is able to run both the unit and integration tests in less than 5 minutes.

##### Do I need to build this “tests in parallel” functionality myself, too?

Probably not! This is such a common way of optimizing test execution that most languages will provide you with a way to run your tests in parallel, either out of the box or with the help of common libraries. For example, you can run tests in parallel with Python by using a library such as testtools or an extension to the popular pytest library. In Go, you get the functionality out of the box via the ability to mark a test as parallelizable when you write it with `t.Parallel()`. Find the relevant information for your language by looking up documentation on running tests in parallel or concurrently.

## [](/book/grokking-continuous-delivery/chapter-6/)[](/book/grokking-continuous-delivery/chapter-6/)Updating the pipelines

[](/book/grokking-continuous-delivery/chapter-6/)Now that Sridhar[](/book/grokking-continuous-delivery/chapter-6/)[](/book/grokking-continuous-delivery/chapter-6/)[](/book/grokking-continuous-delivery/chapter-6/) has met his goal of running both the unit tests and the integration tests in less than 5 minutes, he can add the integration tests to the pre-merge pipeline. Engineers will then get feedback on both the unit and integration tests before their changes merge.

Therefore, he has to make some tweaks to the set of tasks in the Dog Picture Website pipeline, because one task still runs the integration and browser tests together.

![](https://drek4537l1klr.cloudfront.net/wilson3/Figures/06-21.png)

Fortunately, the tests are already set up well for this change. You may recall that the browser tests are already in a separate folder called tests/browser. When Sridhar updated the pipeline to run the unit tests first, he separated the integration tests and put them into a folder called tests/integration. This makes it easy to take the final step of running the integration and browser tests separately.

![](https://drek4537l1klr.cloudfront.net/wilson3/Figures/06-22.png)

##### Why not run all the test tasks in parallel?

Sridhar has assumed that if the unit tests, which take seconds to execute, fail, there’s no point in running the integration tests because they’ll probably fail, but both are good options. See chapter 13 on pipeline design for more.

And then Sridhar can add the integration test task to the pre-merge pipeline. The pipeline will fail quickly if there is a problem with the unit tests, and the entire thing will run in less than 5 minutes.

![](https://drek4537l1klr.cloudfront.net/wilson3/Figures/06-23.png)

## [](/book/grokking-continuous-delivery/chapter-6/)[](/book/grokking-continuous-delivery/chapter-6/)Still too slow!

[](/book/grokking-continuous-delivery/chapter-6/)After working[](/book/grokking-continuous-delivery/chapter-6/) hard on the integration and unit tests, Sridhar has made as much improvement as he thinks he can for now. He met the goals he set for their relative quantities:

-  He has increased the percentage of unit tests from 25% to 72% (his goal was 70%).
-  He has decreased the percentage of integration tests from 65% to 21% (his goal was 20%).

Is he done? He steps back and looks at his overall goals:

-  *Tests should run on every change, before the change gets pushed*. He’s almost there: now the unit and integration tests run, but not the browser tests.
-  *The entire test suite should run in an average of 30 minutes or less*. Sridhar has reduced the execution time of the integration tests; they used to take 35 minutes and now take around 5. The entire suite used to take 2 hours and 35 minutes and now is down to just over 2 hours. This is a big improvement, but Sridhar still hasn’t met his goal.
-  *The integration and unit tests should run in less than 5 minutes*. Done!
-  *The unit tests should run in less than 1 minute*. Done!

The entire test suite is running in an average of 2 hours and 5 minutes:

-  *Unit tests*[](/book/grokking-continuous-delivery/chapter-6/)—Less than 1 minute
-  *Integration tests*—Around 5 minutes
-  *Browser tests*[](/book/grokking-continuous-delivery/chapter-6/)—The other 2 hours

The last remaining problem is the browser tests. All along, the browser tests have been the slowest part of the test suite. At an average runtime of 2 hours, no matter how much Sridhar optimizes the rest of the test suite, if he doesn’t do something about the browser tests, it’s always going to take more than 2 hours.

Can Sridhar take a similar approach and remove browser tests, replacing them with integration and unit tests? This is definitely an option, but when Sridhar looks at the suite of browser tests, he can’t find any candidates to remove! The tests are already very focused and well factored, and at only 10% of the total test suite (with around 50 individual tests), the number of browser tests is quite reasonable.

## [](/book/grokking-continuous-delivery/chapter-6/)[](/book/grokking-continuous-delivery/chapter-6/)Test sharding, aka parallel++

[](/book/grokking-continuous-delivery/chapter-6/)Sridhar is stuck[](/book/grokking-continuous-delivery/chapter-6/)[](/book/grokking-continuous-delivery/chapter-6/) with the browser tests as they are, and they take about 2 hours to run. Does this mean he has to say goodbye to his goals of running the entire suite on every change in less than 30 minutes?

Fortunately not! Because Sridhar has one last trick up his sleeve: *sharding*. Sharding is a technique that is very similar to running tests in parallel, but increases the number of tests that can be executed at once *by parallelizing them across multiple machines*.

Right now, all of the 50 browser tests run on one machine, one at a time. Each test runs in an average of about 2.5 minutes. Sridhar first tries running the tests in parallel, but they are so CPU and memory intensive that the gains are negligible (and in some cases, the tests steal resources from one another, effectively slowing down). One executing machine can really run only one test at a time.

By sharding the test execution, Sridhar will divide up the set of browser tests so that he uses multiple machines, which will each execute a subset of the tests, one at a time, allowing him to decrease the overall execution time.

#####  Vocab time

We’re referring to parallelizing tests across multiple machines as *sharding*, but you will find different terminology used by CD systems. Some systems will call this *test splitting*[](/book/grokking-continuous-delivery/chapter-6/), and others will simply refer to this as *running tests in parallel*[](/book/grokking-continuous-delivery/chapter-6/). In this context, *in parallel* means across multiple machines as opposed to this chapter’s use of *in parallel* to refer to running multiple tests on one machine. Regardless, you can think of sharding as the same basic idea as test parallelization (multicore), but across multiple machines (multimachine).

##### What if Sridhar beefed up the machines? Could he then get away with running the tests in parallel on one machine?

This might help, but as you probably know, machines are getting more and more powerful all the time—and we respond by creating more complex software and more complex tests! So while using more powerful machines might help Sridhar here, I’m going to show what you can do when this isn’t an option. I’m not going to dive into the specific CPU and memory capacity of the machines he’s using because what seems powerful today will seem trivial tomorrow!

## [](/book/grokking-continuous-delivery/chapter-6/)[](/book/grokking-continuous-delivery/chapter-6/)How to shard

[](/book/grokking-continuous-delivery/chapter-6/)Sharding test[](/book/grokking-continuous-delivery/chapter-6/)[](/book/grokking-continuous-delivery/chapter-6/) execution allows you to take a suite of long-running tests, and execute it faster by running it across more hardware (several executing machines instead of just one). But how does it actually work? You might be imagining a complex system requiring some kind of worker nodes coordinating with a central controller, but don’t worry, it can be much simpler than that!

The basic idea is that you have multiple shards, and each is instructed to run a subset of the tests. You can use various approaches to decide which tests to run on which shard. In increasing order of complexity:

1.  Run tests in a deterministic order and assign each shard a set of indexes to run.
1.  Assign each shard an explicit set of tests to run (for example, by name).
1.  Keep track of attributes of tests from previous test runs (for example, how long it takes each to run) and use those attributes to distribute tests across shards (probably using their names, as in option 2).

#####  Vocab time

Each machine available to execute a subset of your tests is referred to as a *shard*.

Let’s get a better handle on test sharding by looking at option 1 in a bit more detail. For example, imagine sharding the following 13 tests across three executing machines:

![](https://drek4537l1klr.cloudfront.net/wilson3/Figures/06-24.png)

You can use the first method to shard these tests by running a subset of the preceding tests on each of our three shards. If you’re using Python, one way to do this is with the Python library pytest-shard:

```
pytest --shard-id=$SHARD_ID --num-shards=$NUM_SHARDS
```

For example, shard 1 would run the following:

```
pytest --shard-id=1 --num-shards=3
```

## [](/book/grokking-continuous-delivery/chapter-6/)[](/book/grokking-continuous-delivery/chapter-6/)More complex sharding

[](/book/grokking-continuous-delivery/chapter-6/)Sharding by index[](/book/grokking-continuous-delivery/chapter-6/)[](/book/grokking-continuous-delivery/chapter-6/) is fairly straightforward, but what about outliers? Sridhar’s browser tests run in an average of 2.5 minutes, but what if some of them take way longer?

This is where more complex sharding schemes come in handy. The third option we listed, for example, would keep track of attributes of tests from previous test runs and use those attributes to distribute tests across shards using their names.

To do this, you need to store timing data for tests as you execute them. For example, take the 13 tests in the preceding example and imagine storing how many minutes each had taken to run across the last three runs:

![](https://drek4537l1klr.cloudfront.net/wilson3/Figures/06-25a.png)

To determine the sharding for the next run, you’d look at the average timing data and create groupings such that each of the three shards would execute the test in roughly the same amount of time.

![](https://drek4537l1klr.cloudfront.net/wilson3/Figures/06-25b.png)

We’re going to skip going into the details of this algorithm (though it does make for a fun and surprisingly practical interview question!). If you want this kind of sharding, it’s possible that you might need to build it yourself, but you also might find that the CD system you’re using (or tools in your language) will do it for you. For example, the CD system CircleCI lets you do this by feeding the names of your tests into a language-agnostic splitting command:

```
circleci tests split --split-by=timings
```

## [](/book/grokking-continuous-delivery/chapter-6/)[](/book/grokking-continuous-delivery/chapter-6/)Sharded pipeline

[](/book/grokking-continuous-delivery/chapter-6/)You may decide[](/book/grokking-continuous-delivery/chapter-6/)[](/book/grokking-continuous-delivery/chapter-6/)[](/book/grokking-continuous-delivery/chapter-6/) to do all of the steps for sharding within one task of your pipeline, or if your CD system supports it, you might break this out into multiple tasks.

![](https://drek4537l1klr.cloudfront.net/wilson3/Figures/06-26.png)

To support being run with sharding, a set of tests must meet the following requirements:

-  The tests must not depend on each other.
-  The tests must not interfere with each other. If the tests share resources (for example, all connecting to the same instance of a dependency), they may conflict with each other (or maybe not—the easiest way to find out is to try).
-  If you want to distribute your tests by index, it must be possible to run the tests in a deterministic order so that the test represented by an index is consistent across all shards.

##### If running unit tests in parallel is a smell, sharding them is a stink!

As mentioned earlier, if your unit tests are slow enough that you need to run them in parallel for them to run in a reasonable length of time, then that’s a smell that something is not quite right with your unit tests (they are probably doing too much). If they are *so slow* that you want to shard them, then I can say with 99.99999% certainty that what you have are not unit tests, and your codebase would be well served by replacing some of these integration/system tests in disguise with unit tests. (I hereby propose calling really bad code smells *code stinks*[](/book/grokking-continuous-delivery/chapter-6/).)

## [](/book/grokking-continuous-delivery/chapter-6/)[](/book/grokking-continuous-delivery/chapter-6/)Sharding the browser tests

[](/book/grokking-continuous-delivery/chapter-6/)Sridhar is going[](/book/grokking-continuous-delivery/chapter-6/)[](/book/grokking-continuous-delivery/chapter-6/)[](/book/grokking-continuous-delivery/chapter-6/) to solve the problem of the slow browser tests by applying sharding! Here’s the overall goal Sridhar is aiming for:

**The entire test suite should run in an average of 30 minutes or less**.

The unit and the integration tests take an average of 5 minutes in total, so Sridhar needs to get the browser tests to run in about 25 minutes.

The browser tests take an average of 2.5 minutes, and there are 50 of them. The time each test takes to execute is fairly uniform, so Sridhar decides to use the simpler route and shard by index. How many shards does he need to meet his goal?

![](https://drek4537l1klr.cloudfront.net/wilson3/Figures/06-27.png)

Since the goal is to complete all the tests in 25 minutes, this means each shard can run for up to 25 minutes. How many browser tests can run in 25 minutes?

If each takes an average of 2.5 minutes, 25 minutes / 2.5 minutes = 10. In 25 minutes, one shard can run 10 tests.

![](https://drek4537l1klr.cloudfront.net/wilson3/Figures/06-28.png)

With 50 tests in total, and each shard able to run 10 tests in 25 minutes, he needs 50 / 10 = 5 shards.

![](https://drek4537l1klr.cloudfront.net/wilson3/Figures/06-29.png)

Using 5 shards will meet his goal, but he knows they have enough hardware available that he can be even more generous, and he decides to allocate 7 shards for the browser tests.

![](https://drek4537l1klr.cloudfront.net/wilson3/Figures/06-30.png)

With 7 shards, each shard will need to run 50 / 7 tests; the shards with the most will run with the ceiling of 50 / 7 = 8 tests. Eight tests at an average of 2.5 minutes will complete in 20 minutes. This lets Sridhar slightly beat his goal of 25 minutes, and gives everyone a bit more room to add more tests, before more shards will need to be added.

## [](/book/grokking-continuous-delivery/chapter-6/)[](/book/grokking-continuous-delivery/chapter-6/)Sharding in the pipeline

[](/book/grokking-continuous-delivery/chapter-6/)Simple index-based[](/book/grokking-continuous-delivery/chapter-6/)[](/book/grokking-continuous-delivery/chapter-6/)[](/book/grokking-continuous-delivery/chapter-6/) sharding will work for the browser tests, so all Sridhar has to do is add tasks that run in parallel, one for each shard, and have each use pytest-shard to run a subset of the browser tests. His sharded browser test tasks will run this Python script, using Python to call pytest:

```bash
# when the pipeline runs, it will pass to this script
  # the index of the the shard and the total number of shards
  # as arguments
  shard_index, num_shards, path_to_tests = get_arguments()
  
  # we'll invoke pytest as command to run the correct set of tests
  # for this shard
  run_command(
    "pytest --shard-id={} --num-shards={} {}".format(
      shard_index, num_shards, path_to_tests
  ))
```

To add this script to his pipeline, all he has to do is add a set of tasks that run in parallel, in his case seven, one for each of the seven shards. Does he need to hardcode seven individual tasks into his pipeline to make this happen? It depends on the features of the CD system he’s using. Most will provide a way to parallelize tasks, allowing you to specify how many instances of the task you’d like to run, and then providing as arguments (often environment variables) information to the running tasks on how many instances are running in total and which instance they are. For example, using GitHub Actions, you can use a matrix strategy to run the same job multiple times:

```
jobs:                   #1
  tests:
    strategy:
      fail-fast: false  #2
      matrix:
        total_shards: [7]
        shard_indexes: [0, 1, 2, 3, 4, 5, 6]
```

![](https://drek4537l1klr.cloudfront.net/wilson3/Figures/06-31.png)

With this configuration, the `tests` job would be run seven times, and steps in each job can be provided with the following context variables so they’ll know the number of shards in total and which shard they are running as:

```
${{ matrix.total_shards }}
${{ matrix.shard_indexes }}  #1
```

## [](/book/grokking-continuous-delivery/chapter-6/)[](/book/grokking-continuous-delivery/chapter-6/)Dog Picture Website’s pipelines

[](/book/grokking-continuous-delivery/chapter-6/)Now that Sridhar[](/book/grokking-continuous-delivery/chapter-6/)[](/book/grokking-continuous-delivery/chapter-6/) has met his goal of running the browser tests in 25 minutes (in fact, in 20 minutes), he can combine all the tests together, and the entire suite can run in an average of 30 minutes or less. This means he can go back to his last goal:

**Tests should run on every change, before the change gets pushed**.

Sridhar adds the browser tests to the pre-merge pipeline, running them in parallel with the integration tests. The pre-merge pipeline can now run all of the tests and will take only the length of the sharded browser tests (20 minutes) + the unit tests (less than 1 minute).

![](https://drek4537l1klr.cloudfront.net/wilson3/Figures/06-32.png)

##### Why is the pre-merge pipeline different from the nightly pipeline?

That’s a good question! It doesn’t have to be; see chapter 13 on pipeline design for more about the tradeoffs.

Sridhar makes the same updates to the nightly release pipeline as well so that it gets the same speed boost:

![](https://drek4537l1klr.cloudfront.net/wilson3/Figures/06-33.png)

#####  Takeaway

Running tests in parallel will increase your hardware footprint, but it will save you another invaluable asset: time! When tests are slow, first optimize the test distribution by leveraging unit tests; then leverage parallelization and sharding if needed.

#####  Noodle on it

[](/book/grokking-continuous-delivery/chapter-6/)Sridhar needs 5 shards to run the 50 tests in 25 minutes or less, and he adds an extra 2 shards for a total of 7, speeding up the test execution time and adding a buffer for future tests. *But what if the number of tests keeps growing—does that mean adding more and more shards?* Will that work?

Once the number of browser tests increases from 50 to 70, each of the 7 shards will be running 10 tests, and the overall execution time will be 25 minutes.

![](https://drek4537l1klr.cloudfront.net/wilson3/Figures/06-34.png)

If any more tests are added, the browser tests will take more than 25 minutes to run, and more shards will need to be added. Does this mean they’ll have to keep adding shards indefinitely? Won’t that eventually be too much?

That could happen; you may remember that the architecture of Dog Picture Website is quite monolithic:

**If Dog Picture Website continues to grow its feature base, the company will need to start dividing up responsibilities of the backend service into separate services, and each can have its own test suites**.

This will mean that when something is changed, the engineers can run only the tests that are related to that change, instead of needing to run absolutely everything*.* This kind of division of responsibilities will probably be required in order to match the growth of the company as well (as more people are added, they will need to be divided into effective teams that each have independent areas of ownership).

![](https://drek4537l1klr.cloudfront.net/wilson3/Figures/06-35.png)

Food for thought: fast-forward to the future, where Dog Picture Website is made up of multiple services, each with its own set of end-to-end tests. Is running each set separately enough for the engineers to be confident that the entire system works? Should all of the tests be run together before a release in order to be certain? The answer is, it depends; but remember, you can never be 100% certain. The key is to make the tradeoffs that work for your project.

#####  It’s your turn: Speed up the tests

[](/book/grokking-continuous-delivery/chapter-6/)Dog Picture Website and Cat Picture Website share a common competitor: the up-and-coming Bird Picture Website. Bird Picture Website is dealing with a similar problem around slow tests, but its situation is a bit different.

Its entire test suite runs in about 3 hours, but unlike for Dog Picture Website, the engineers run this entire suite for every PR. When the engineers are ready to submit changes, they open up a PR and then leave it, often until the next day, to wait for the tests to run. One advantage to this approach is that they catch a lot of problems before they get merged, but engineers will often spend days trying to get their changes merged (sometimes called *wrestling with the tests*).

The test suite Bird Picture Website uses has the following distribution:

-  10% unit tests
-  No integration tests
-  90% end-to-end tests

![](https://drek4537l1klr.cloudfront.net/wilson3/Figures/06-36.png)

The unit tests cover 34% of the codebase, and they take 20 minutes to run. What are some good next steps for Bird Picture Website to go about speeding up its test suite?

#####  Answers

[](/book/grokking-continuous-delivery/chapter-6/)A few things stand out immediately about Bird Picture Website’s test suites:

-  The tests they are calling “unit tests” are quite slow for unit tests; ideally, they would run in a couple of minutes max, if not in seconds. There is a good chance that they are more like integration tests.
-  The unit test (or maybe “integration test”) coverage is quite low.
-  The company has a *lot* of end-to-end tests in comparison to the number of unit tests; it could be that there just aren’t very many tests in general, but there’s also a good chance that Bird Picture Website is relying too much on these end-to-end tests.

Based on this information, the folks at Bird Picture website could do a few things:

-  Sort through the slow unit tests; if any of these are actually unit tests (running in seconds or less), run those separately from the other slower tests (which are actually integration tests). These unit tests can be run quickly first and give an immediate signal.
-  Measure the coverage of these fast unit tests; it will be even lower than the already low 34% coverage. Compare the areas without coverage to the huge set of end-to-end tests, and identify end-to-end tests that can be replaced with unit tests.
-  Introduce a task to measure and report on unit-test coverage on every PR, and don’t merge any PRs that decrease the unit-test coverage.
-  From there, take a fresh look at the distribution of tests and decide what to do next. There’s a good chance that many of the end-to-end tests could be downgraded to integration tests; instead of needing the entire system to be up and running, maybe the same cases could be covered with just a couple of components, which will probably be faster.

## [](/book/grokking-continuous-delivery/chapter-6/)Conclusion

[](/book/grokking-continuous-delivery/chapter-6/)Over time, Dog Picture Website’s test suite had taken longer and longer to run. Instead of facing this problem directly and finding ways to speed up the tests, the engineers removed the tests from their daily routine, basically postponing dealing with the pain as long as possible. Though this may have helped them speed up initially, it was now slowing them down. Sridhar knew that the answer was to look critically at the test suite and optimize it as much as possible. And when it couldn’t be optimized any further, he was able to use parallelization and sharding to make the tests fast enough that the tests could once again become part of the pre-merge routine and engineers could get feedback faster.

## [](/book/grokking-continuous-delivery/chapter-6/)Summary

-  Get an immediate gain from a slow test suite by making it possible to run the fastest tests independently and running them first.
-  Before solving slow test-suite problems with technology, first take a critical look at the tests themselves. Using the test pyramid will help you focus your efforts, and enforcing test coverage will help you maintain a strong unit-test base.
-  That being said, perhaps your test suite is super solid, but the tests just take a long time to run. When you’ve reached this point, you can use parallelization and sharding to speed up your tests by trading time for hardware.

## [](/book/grokking-continuous-delivery/chapter-6/)Up next . . .

In the next chapter, I’ll expand on the theme of getting signals at the right time by looking at when bugs can sneak in. You’ll learn about the processes to have in place to get the signal that something has gone wrong as early as possible.

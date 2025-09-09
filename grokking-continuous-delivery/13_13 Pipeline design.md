# 13 [](/book/grokking-continuous-delivery/chapter-13/)[](/book/grokking-continuous-delivery/chapter-13/)Pipeline design

### In this chapter

- ensuring required actions happen regardless of failures
- speeding up pipelines by running tasks in parallel instead of sequentially
- reusing pipelines by parameterizing them
- weighing the tradeoffs when deciding how many pipelines to use and what to put into each
- identifying the features you need in a CD system to express pipeline graphs

Welcome to the[](/book/grokking-continuous-delivery/chapter-13/) last chapter of *Grokking Continuous Delivery*. In this chapter, I’ll show the overall structure of continuous delivery (CD) pipelines, and the features you need to look for in CD systems in order to structure your pipelines effectively.

A big piece of this story is CD systems that optimize for reuse. This approach builds on our overall theme of config as code—specifically, using software design best practices when writing CD pipelines, just like you would with any other code.

## [](/book/grokking-continuous-delivery/chapter-13/)[](/book/grokking-continuous-delivery/chapter-13/)PetMatch

[](/book/grokking-continuous-delivery/chapter-13/)To help you understand[](/book/grokking-continuous-delivery/chapter-13/)[](/book/grokking-continuous-delivery/chapter-13/) the importance of pipeline design, I’ll show the pipelines used at PetMatch. This company provides a service that allows potential pet owners to search for pets available for adoption. The company’s unique matchmaking algorithm helps match the best pet to the best owner.

![](https://drek4537l1klr.cloudfront.net/wilson3/Figures/13-01.png)

The company is no longer a start-up and has been operating for just over eight years. During this time, its has put a lot of emphasis on CD automation, so it has built up multiple pipelines across various services.

However, the Matchmaking service engineers have recently been questioning the value they’ve been getting from their pipelines. The architecture of the service itself is relatively simple, with all the business logic contained in the running Python service that exposes a REST API to the rest of the PetMatch stack, and it is backed by a database:

![](https://drek4537l1klr.cloudfront.net/wilson3/Figures/13-02.png)

This service has extensive automation and testing defined across several CD pipelines, but execution is slow, and the engineers feel they’re not getting the information they need when they need it. In fact, they are starting to feel that their CD automation is letting them down!

## [](/book/grokking-continuous-delivery/chapter-13/)[](/book/grokking-continuous-delivery/chapter-13/)Matchmaking CD pipelines

[](/book/grokking-continuous-delivery/chapter-13/)The Matchmaking[](/book/grokking-continuous-delivery/chapter-13/)[](/book/grokking-continuous-delivery/chapter-13/)[](/book/grokking-continuous-delivery/chapter-13/) service has three separate pipelines, and the engineers have very different experiences with each of them:

-  The *CI pipeline* is run on every PR before merging.
-  The *end-to-end test pipeline* is run once every night.
-  The *release pipeline* is triggered to run every time the team is ready to create a release (every few weeks or so).

The team is happy with the CI test pipeline. It runs on every PR in less than 5 minutes and provides a useful signal.

The other two pipelines, however, not so much. The end-to-end test pipeline has several problems:

-  Since it runs nightly, people don’t find out that it has been broken until the next day. At that point, it’s frustrating to try to detangle the failures, figure out who is responsible, and then have to go back and fix something that was already merged.
-  Running these tests only once a day means the team is rarely confident that the code is in a releasable state. The team members would not feel confident if they wanted to make the move to continuous deployment.
-  The reason the pipeline is run nightly is that it is slow: it takes over an hour to run, and no one on the team wants to wait that long while iterating on a PR.
-  The final problem is that the end-to-end tests set up a test environment, but if tests fail, they don’t clean up after themselves, meaning that over time more and more resources are consumed for testing, and someone has to manually clean them up.

The problems with the release pipeline can be summed up in one point:

-  Problems with the service and the configuration are often caught by this pipeline. But this pipeline is run only when the team is ready to do a release, so releases are frequently interrupted and put on hold while the team members have to scramble to fix the new problems that they’ve found.

Let’s look at these problems from a slightly different angle and see if we can find any themes across the two problematic pipelines.

## [](/book/grokking-continuous-delivery/chapter-13/)[](/book/grokking-continuous-delivery/chapter-13/)CD pipeline problems

[](/book/grokking-continuous-delivery/chapter-13/)Can we identify any common themes across these two pipelines? Let’s look at them again. These are the problems with the end-to-end test pipeline:

-  Engineers find out they broke something the day after they merge. (a)
-  Code is not in a releasable state. (b)
-  Too slow to run on every PR. (c)
-  Doesn’t clean up after itself. (d)

(a) The signal comes late.

(b) The delay in the signal that something is broken causes this.

(c) Speed is a problem.

(d) This is a bug or error in the pipeline itself.

(e) Another instance of the signal coming late.

And the release pipeline has just one glaring problem:

-  Reveals problems with the codebase that were introduced much earlier (e)

These problems can be grouped into three categories:

-  *Errors*[](/book/grokking-continuous-delivery/chapter-13/)—When the pipelines don’t do what they should, for example, the end-to-end tests leaving the test environments in a bad state.
-  *Speed*—The speed of the end-to-end test pipeline prevents the team from being able to run this when they need to.
-  *Signal*—Both pipelines, because of when they are run, are providing their signals too late, after (sometimes long after) code is already merged.

You’ll see how to address each of these issues across the Matchmaking service’s pipelines.

## [](/book/grokking-continuous-delivery/chapter-13/)[](/book/grokking-continuous-delivery/chapter-13/)End-to-end test pipeline

[](/book/grokking-continuous-delivery/chapter-13/)I’ll start with[](/book/grokking-continuous-delivery/chapter-13/)[](/book/grokking-continuous-delivery/chapter-13/)[](/book/grokking-continuous-delivery/chapter-13/) the Matchmaking service’s end-to-end test pipeline. This pipeline has problems in all three areas we identified: *errors*, *speed**,* and *signal*. Here is the current pipeline:

![](https://drek4537l1klr.cloudfront.net/wilson3/Figures/13-03.png)

## [](/book/grokking-continuous-delivery/chapter-13/)[](/book/grokking-continuous-delivery/chapter-13/)End-to-end test pipeline and errors

[](/book/grokking-continuous-delivery/chapter-13/)The first issue to address is around the *errors* in the end-to-end test pipeline, specifically, that the cleanup task runs only if the rest of the pipeline was successful. Most of the teams at PetMatch use GitHub Actions, and this is what the GitHub Actions workflow for the Matchmaking service looks like:

```
name: Run System tests 
on: 
  schedule: 
  - cron: '0 23 * * *'                              #1
jobs: 
  build-image: ... 
  setup-sut: 
    needs: build-image                              #2
    outputs: 
      env-ip: ${{ steps.provision.outputs.env-ip }} #3
    ...
  deploy-image-sut: 
    needs: setup-sut 
    ... 
  end-to-end-tests: 
    needs: [setup-sut, deploy-image-sut]            #3
    env: 
      SUT_IP: ${{ needs.setup-sut.outputs.env-ip}} 
    ... 
  clean-up-sut: 
    needs: [setup-sut, end-to-end-tests]            #4
    ...
```

![](https://drek4537l1klr.cloudfront.net/wilson3/Figures/13-04.png)

#####  Takeaway

Allowing tasks to emit *outputs*[](/book/grokking-continuous-delivery/chapter-13/) that can be used as *inputs*[](/book/grokking-continuous-delivery/chapter-13/) by other tasks in a pipeline allows for tasks to be designed as individual units that are highly cohesive, loosely coupled, and can themselves be reused between pipelines.

#####  Takeaway

GitHub Actions uses *workflows*[](/book/grokking-continuous-delivery/chapter-13/) for what this book calls *pipelines*. This book’s *tasks*[](/book/grokking-continuous-delivery/chapter-13/) are roughly equivalent to *jobs* and *actions*[](/book/grokking-continuous-delivery/chapter-13/). Actions are reusable and can be referenced across workflows, while jobs are defined within workflows and are not reusable.

## [](/book/grokking-continuous-delivery/chapter-13/)[](/book/grokking-continuous-delivery/chapter-13/)Finally behavior

[](/book/grokking-continuous-delivery/chapter-13/)The functionality[](/book/grokking-continuous-delivery/chapter-13/)[](/book/grokking-continuous-delivery/chapter-13/)[](/book/grokking-continuous-delivery/chapter-13/) that the Matchmaking service team needs in the pipeline is to make the cleanup task execute regardless of what happens with the rest of the pipeline. In many pipelines, certain tasks need to run even if other parts of the pipeline fail. This is similar to the concept of *finally behavior* in programming languages, for example, the `finally` clause in Python:

```
try: 
    print("hello world!") 
    raise Exception("oh no") 
finally:    #1 
    print("goodbye world")
```

To be more precise, the cleanup needs to happen if the SUT setup task executed, but for now I’ll keep the logic simple and execute the cleanup task regardless. To update the cleanup to happen only if the setup task executed, use the conditions feature that you’ll see in a few pages.

Including finally behavior into a pipeline means your pipeline will execute in two phases. First the main part of the pipeline executes, and once that is complete (whether it succeeded or failed), the finally portion of the pipeline executes:

![](https://drek4537l1klr.cloudfront.net/wilson3/Figures/13-05.png)

## [](/book/grokking-continuous-delivery/chapter-13/)[](/book/grokking-continuous-delivery/chapter-13/)Finally as a graph

[](/book/grokking-continuous-delivery/chapter-13/)Another useful[](/book/grokking-continuous-delivery/chapter-13/)[](/book/grokking-continuous-delivery/chapter-13/)[](/book/grokking-continuous-delivery/chapter-13/)[](/book/grokking-continuous-delivery/chapter-13/) way to think about pipelines, especially when you start executing tasks in parallel, is as a graph—as a *directed acyclic graph* (*DAG*[](/book/grokking-continuous-delivery/chapter-13/)[](/book/grokking-continuous-delivery/chapter-13/)*)*. A DAG is a graph in which edges have direction (in our case, from one task to the next), and there are no cycles (you never start off at one task, follow the edges, and end up back at the same task).

![](https://drek4537l1klr.cloudfront.net/wilson3/Figures/13-06.png)

When thinking about pipelines as DAGs, including finally behavior is like creating edges from every single pipeline task to the finally tasks, which execute on failure. If the task fails, execution of the finally tasks starts immediately:

![](https://drek4537l1klr.cloudfront.net/wilson3/Figures/13-07.png)

## [](/book/grokking-continuous-delivery/chapter-13/)[](/book/grokking-continuous-delivery/chapter-13/)Finally in the matchmaking pipeline

[](/book/grokking-continuous-delivery/chapter-13/)The matchmaking[](/book/grokking-continuous-delivery/chapter-13/)[](/book/grokking-continuous-delivery/chapter-13/)[](/book/grokking-continuous-delivery/chapter-13/)[](/book/grokking-continuous-delivery/chapter-13/)[](/book/grokking-continuous-delivery/chapter-13/) team needs to represent this finally functionality by using the GitHub Action expression syntax. In this syntax, to mark a job as needing to execute regardless of the status of the rest of the jobs in the workflow, use `if: ${{ always() }}`. This is what their matchmaking pipeline looks like after this update:

```
name: Run System tests 
on: 
  schedule: 
  - cron: '0 23 * * *' 
jobs: 
  build-image: ... 
  setup-sut: 
    needs: build-image     outputs: 
      env-ip: ${{ steps.provision.outputs.env-ip }} 
    ... 
  deploy-image-sut: 
    needs: setup-sut     ...   end-to-end-tests: 
    needs: [setup-sut, deploy-image-sut] 
    env: 
      SUT_IP: ${{ needs.setup-sut.outputs.env-ip}} 
    ... 
  clean-up-sut: 
    if: ${{ always() }}    #1
     needs: [setup-sut, end-to-end-tests] 
    ...
#1 The if statement tells GitHub Actions to always run this job. If the rest of the jobs succeed, GitHub Actions will respect the “needs” statement immediately after this and execute after end-to-end-tests, but if that or any other job fails, clean-up-sut will execute next.
```

The error in the matchmaking CD pipeline is fixed: the cleanup will always occur.

#####  Takeaway

The pipeline syntax provided by your CD system should allow you to express finally behavior in your pipelines, i.e., tasks in your pipeline that must always be executed, even if other parts of the pipeline fail.

#####  Takeaway

Having support for conditional execution (which GitHub Actions supports via `if` statements) allows for more flexible pipelines. You could, for example, run a pipeline on every PR, but include some tasks that run only after merging.

## [](/book/grokking-continuous-delivery/chapter-13/)[](/book/grokking-continuous-delivery/chapter-13/)End-to-end test pipeline and speed

[](/book/grokking-continuous-delivery/chapter-13/)The matchmaking[](/book/grokking-continuous-delivery/chapter-13/)[](/book/grokking-continuous-delivery/chapter-13/)[](/book/grokking-continuous-delivery/chapter-13/) team has fixed their problem with errors in their CD pipeline, but they still have problems with speed and signal:

-  *Errors*[](/book/grokking-continuous-delivery/chapter-13/)—The end-to-end tests leave the test environments in a bad state. Fixed!
-  *Speed*—The end-to-end test pipeline is too slow to run when needed.
-  *Signal*—End-to-end test and release pipelines provide signals too late.

Next, they are going to address the speed problem, which will also start to address the signal problem, because if the pipeline can run faster, it can be run more frequently.

![](https://drek4537l1klr.cloudfront.net/wilson3/Figures/13-08.png)

## [](/book/grokking-continuous-delivery/chapter-13/)[](/book/grokking-continuous-delivery/chapter-13/)Parallel execution of tasks

[](/book/grokking-continuous-delivery/chapter-13/)The matchmaking[](/book/grokking-continuous-delivery/chapter-13/)[](/book/grokking-continuous-delivery/chapter-13/)[](/book/grokking-continuous-delivery/chapter-13/)[](/book/grokking-continuous-delivery/chapter-13/) team members notice that although all the tasks in the pipeline run one after the other, some don’t actually depend on others. Looking at the tasks that aren’t run as part of the finally behavior, they identify the following dependencies between the tasks:

-  *End-to-end tests*[](/book/grokking-continuous-delivery/chapter-13/)—Requires the image to be deployed to the SUT
-  *Deploy image to SUT*—Requires the image to be built and the SUT environment to be set up
-  *Set up SUT environment*—Doesn’t require anything
-  *Build image*—Doesn’t require anything

Since building the image and setting up the SUT environment don’t require any other tasks, they don’t need to run one after the other: they can run *in parallel* (aka *concurrently*). Running tasks in parallel is a way to speed up execution of pipelines. If two tasks run one after the other (aka *sequentially*), the total time to execute them is the sum of the time it takes each one to run. If they run in parallel instead, the time to execute both tasks will be limited to just whichever of the two tasks is slower.

![](https://drek4537l1klr.cloudfront.net/wilson3/Figures/13-09.png)

#####  Takeaway

Running tasks in parallel is a way to reduce the time it takes your pipelines to execute. To determine which tasks could execute in parallel in your pipelines, examine the dependencies between the tasks. When comparing CD systems, be on the lookout for systems that allow you to execute tasks in parallel.

## [](/book/grokking-continuous-delivery/chapter-13/)[](/book/grokking-continuous-delivery/chapter-13/)End-to-end test pipeline and test speed

[](/book/grokking-continuous-delivery/chapter-13/)Although the matchmaking[](/book/grokking-continuous-delivery/chapter-13/)[](/book/grokking-continuous-delivery/chapter-13/) CD pipeline is now taking advantage of parallel execution, the overall impact on execution time is quite small. Just 1 minute is saved by building the image at the same time that the SUT environment is being set up.

![](https://drek4537l1klr.cloudfront.net/wilson3/Figures/13-10.png)

The real problem with this pipeline’s speed is the end-to-end tests themselves. No amount of tweaks to the rest of the pipeline will make up for them: the total time taken by the rest of the tasks is ~6 minutes, and the tests alone take more than an hour to run.

## [](/book/grokking-continuous-delivery/chapter-13/)[](/book/grokking-continuous-delivery/chapter-13/)Parallel execution and test sharding

[](/book/grokking-continuous-delivery/chapter-13/)When addressing[](/book/grokking-continuous-delivery/chapter-13/)[](/book/grokking-continuous-delivery/chapter-13/)[](/book/grokking-continuous-delivery/chapter-13/)[](/book/grokking-continuous-delivery/chapter-13/) any problems with slow tests, the first step is to evaluate the tests themselves to identify any fundamental underlying problems. Addressing these problems directly is better for long-term health and maintainability.

See chapter 6 for more on speeding up slow test suites, including using test sharding.

The matchmaking team members are convinced that they have already done this (no fundamental problems with the test suite have been identified), and so their next option is to use test sharding to run subsets of the end-to-end test suite in parallel.

Their end-to-end test suite has around 50 separate tests, and each takes around 60 to 90 seconds to execute. The entire time to execute the end-to-end suite currently is as follows:

**50 tests × 60–90 seconds / test = 50–75 minutes total**

In order for the end-to-end pipeline to be fast enough to run on every PR, they’d like running the tests to take 15 minutes or less:

**15 minutes / (60–90 seconds / test) = 10–15 tests per shard**

In the 15-minute window they have identified, they can run 10 tests in the worst case:

**50 tests / 10 tests / shard = 5 shards**

They decide to run the tests across six shards to give themselves a bit of wiggle room:

**50 tests / 6 shards = 8.3 tests per shard ~= rounding up to 9 tests per shard**

**9 × 60–90 seconds = 9–13.5 minutes per shard**

By running the tests across six shards, the total time to execute the tests will be only the time it takes the longest shard. This should be 13.5 minutes in the worst case.

To update the end-to-end test task to shard the tests across six shards, the matchmaking team uses the same approach that Sridhar used in chapter 6, which is to make use of the pytest-shard library in Python to handle the sharding, combined with using GitHub Action’s `matrix` functionality:

```
end-to-end-tests:
    needs: [setup-sut, deploy-image-sut]
    runs-on: ubuntu-latest
    env:
      SUT_IP: ${{ needs.setup-sut.outputs.env-ip}}
    strategy:
      fail-fast: false
      matrix:                                        #1
        total_shards: [6]
        shard_indexes: [0, 1, 2, 3, 4, 5]
    steps:
      ...
      - name: Install pytest-shard
        run: |
          pip install pytest-shard==0.1.2
      - name: Run tests
        run: |
          pytest \
            --shard-id=${{ matrix.shard_indexes }} \
            --num-shards=${{ matrix.total_shards }}  #2
#1 Using the matrix strategy tells GitHub Actions to run the job once for each combination of the items in total_shards and shard_indexes, which in this case would be six combinations, one for each shard.
#2 Each instance of the test job that is run by GitHub Actions will get a different combination of values for matrix.shard_indexes and matrix.total_shards: [6, 0], [6, 1], [6, 2], [6, 3], [6, 4], [6, 5].
```

## [](/book/grokking-continuous-delivery/chapter-13/)[](/book/grokking-continuous-delivery/chapter-13/)End-to-end test pipeline with sharding

[](/book/grokking-continuous-delivery/chapter-13/)Now that the tests[](/book/grokking-continuous-delivery/chapter-13/)[](/book/grokking-continuous-delivery/chapter-13/)[](/book/grokking-continuous-delivery/chapter-13/)[](/book/grokking-continuous-delivery/chapter-13/) are sharded, the end-to-end test pipeline looks a bit different:

![](https://drek4537l1klr.cloudfront.net/wilson3/Figures/13-11.png)

The total execution time for the end-to-end test pipeline is 13.5 minutes in the worst case. The entire pipeline will run in less than 20 minutes in the worst case, and as quickly as 15 minutes. This pipeline is now fast enough that it can be run on every PR. If the engineers wanted to make it even faster, they could add more end-to-end tests shards.

#####  Takeaway

Supporting matrix-based execution in a pipeline supports easily parallelizing execution (e.g., for test sharding), which is a powerful way to improve the execution time of a pipeline while making it easy to reuse tasks.

## [](/book/grokking-continuous-delivery/chapter-13/)[](/book/grokking-continuous-delivery/chapter-13/)End-to-end test pipeline and signal

[](/book/grokking-continuous-delivery/chapter-13/)Now that they have addressed[](/book/grokking-continuous-delivery/chapter-13/)[](/book/grokking-continuous-delivery/chapter-13/)[](/book/grokking-continuous-delivery/chapter-13/)[](/book/grokking-continuous-delivery/chapter-13/) their problems with speed, the matchmaking team can address their signal problems:

-  *Errors*[](/book/grokking-continuous-delivery/chapter-13/)—The end-to-end tests leave the test environments in a bad state. Fixed!
-  *Speed*—The end-to-end test pipeline is too slow to run when needed. Fixed!
-  *Signal*—End-to-end and release pipelines provide signals too late.

Signals from the end-to-end test pipeline and the release pipeline are arriving too late. The end-to-end test pipeline was running only on a nightly basis, because it was too slow. But now that the entire pipeline runs in less than 20 minutes, the engineers can run it on every PR and get a signal from it right away!

They were already running the CI pipeline on every PR. To add the end-to-end test pipeline, they have two options:

-  Running the end-to-end test pipeline after the CI pipeline
-  Running the end-to-end test pipeline in parallel with the CI pipeline

To choose one approach or the other, the matchmaking team needs to weigh a couple of factors:

-  *Use of resources*—The end-to-end test pipeline consumes resources to run the SUT. If the CI pipeline fails, do the engineers still want to consume these resources (run in parallel) or would they rather be conservative and consume these resources only if the unit and integration tests in the CI pipeline pass (run one pipeline after the other)?
-  *Getting comprehensive failure info*—If the end-to-end tests are run only after the CI pipeline pass, the PR author might find it frustrating to spend time fixing the tests in the CI pipeline, only to find that once those are fixed, the end-to-end tests fail.

## [](/book/grokking-continuous-delivery/chapter-13/)[](/book/grokking-continuous-delivery/chapter-13/)One CI pipeline

[](/book/grokking-continuous-delivery/chapter-13/)The matchmaking[](/book/grokking-continuous-delivery/chapter-13/)[](/book/grokking-continuous-delivery/chapter-13/)[](/book/grokking-continuous-delivery/chapter-13/) team members decide to run the end-to-end tests in parallel with the existing CI pipeline in order to optimize for getting the most signal they can, as fast as they can, even if that means paying for more resources to run the SUT environments. Instead of using two separate pipelines, they combine both existing pipelines into one larger CI pipeline that runs all three kinds of tests (and linting too!):

![](https://drek4537l1klr.cloudfront.net/wilson3/Figures/13-12.png)

As soon as the pipeline starts, it will run linting, image building, setting up the SUT environment, unit tests, and integration tests all in parallel.

## [](/book/grokking-continuous-delivery/chapter-13/)[](/book/grokking-continuous-delivery/chapter-13/)Release pipeline and signal

[](/book/grokking-continuous-delivery/chapter-13/)Because the end-to-end[](/book/grokking-continuous-delivery/chapter-13/)[](/book/grokking-continuous-delivery/chapter-13/)[](/book/grokking-continuous-delivery/chapter-13/)[](/book/grokking-continuous-delivery/chapter-13/)[](/book/grokking-continuous-delivery/chapter-13/) test pipeline is now combined with the existing CI pipeline—and run on every PR—the signal problem with that pipeline has been fixed.

-  *Errors*[](/book/grokking-continuous-delivery/chapter-13/)—The end-to-end tests leave the test environments in a bad state. Fixed!
-  *Speed*—The end-to-end test pipeline is too slow to run when needed. Fixed!
-  *Signal*—End to end and release pipelines provide signals too late.

But the release pipeline still has a signal problem. The release pipeline runs only when deployments happen (which is every few weeks at best).

![](https://drek4537l1klr.cloudfront.net/wilson3/Figures/13-13.png)

This pipeline often catches problems that have been missed up until that point. For example, these are recent problems it caught:

-  A change required that an environment variable be set at build time, but this change was made in the Makefile used by the end-to-end tests and wasn’t made in the build task shown previously. When the release pipeline ran, that task failed.
-  A command-line option in the Matchmaking service was changed, but the configuration used to deploy it wasn’t updated. When the deploy task ran, it used configuration that tried to use the old option, and the deployment failed.

## [](/book/grokking-continuous-delivery/chapter-13/)[](/book/grokking-continuous-delivery/chapter-13/)Differences in CI

[](/book/grokking-continuous-delivery/chapter-13/)Why is the release[](/book/grokking-continuous-delivery/chapter-13/)[](/book/grokking-continuous-delivery/chapter-13/)[](/book/grokking-continuous-delivery/chapter-13/) pipeline catching issues that the CI pipeline isn’t? The end-to-end test portion of the CI pipeline also needs to build and deploy, after all. The reason the issues aren’t being caught by CI is that the building and deploying logic in CI is different from the same logic in the release pipeline.

![](https://drek4537l1klr.cloudfront.net/wilson3/Figures/13-14.png)

As you saw in chapter 7 with CoinExCompare, using different logic to build and deploy in CI than is used to do production builds and deployments allows bugs to slip in. The solution is to update the CI pipeline to use the release pipeline for the build and deploy portion. If the same pipeline (running the same tasks) is being used, chances are much higher that any potential issues will be caught.

##### What about using continuous deployment to get a signal earlier?

Good point—if PetMatch was using continuous deployment to deploy the Matchmaking service, it would be deploying on every change, and any problems introduced would be caught immediately. However, the problems would still be caught *after* the merge occurred, at which point the codebase would be in an unreleasable state until the issue was fixed. As much as possible, it is better to catch issues before they are committed to the main codebase.

## [](/book/grokking-continuous-delivery/chapter-13/)[](/book/grokking-continuous-delivery/chapter-13/)Combining pipelines

[](/book/grokking-continuous-delivery/chapter-13/)The matchmaking[](/book/grokking-continuous-delivery/chapter-13/)[](/book/grokking-continuous-delivery/chapter-13/)[](/book/grokking-continuous-delivery/chapter-13/) team wants to use the existing release pipeline in two different contexts:

-  When they want to do a deployment (this is how they are currently using it)
-  To build and deploy to the SUT in their CI pipeline

To accomplish the second option, they need a way to reuse the existing pipeline from within the CI pipeline. There are two ways they could accomplish this:

-  *Duplicate the pipeline*—Use the same tasks that the release pipeline is using within the CI pipeline.
-  *Call the release pipeline from the CI pipeline*—Use the release pipeline as is from the CI pipeline, i.e., invoke one pipeline from another pipeline.

Both options would solve the problem you just saw, since in both cases the CI pipeline would now be using the same tasks as the release pipeline. But the first option comes with some downsides:

-  If the release pipeline changes, whoever makes the change would need to remember to change the CI pipeline too, or they would no longer be in sync.
-  There is a greater chance that over time the way the tasks are defined and used in each pipeline will diverge than if the exact same pipeline was used in both cases.

The matchmaking team agrees that calling the release pipeline in its entirety from the CI pipeline is the better option.

#####  Takeaway

By allowing pipelines to invoke other pipelines, CD systems with this feature support more reuse (and less unnecessary duplication and error-prone maintenance) than systems that support reuse at only the task level (or no reuse at all).

## [](/book/grokking-continuous-delivery/chapter-13/)[](/book/grokking-continuous-delivery/chapter-13/)Release pipeline

[](/book/grokking-continuous-delivery/chapter-13/)To be able to use the release[](/book/grokking-continuous-delivery/chapter-13/)[](/book/grokking-continuous-delivery/chapter-13/)[](/book/grokking-continuous-delivery/chapter-13/)[](/book/grokking-continuous-delivery/chapter-13/) pipeline from the CI pipeline, the matchmaking team needs to make a few changes. This is the release pipeline as it is currently defined as a GitHub workflow:

```
name: Build and deploy to production from tag
on:
  push:
    tags:
      - '*'
jobs:
  build-matchmaking-service-image:
    runs-on: ubuntu-latest
    outputs:
      built-image: ${{ steps.build-and-push.outputs.built-image }}                            #1
    steps:
      - uses: actions/checkout@v2
      - id: build-and-push                                                                    #2
        run: |
          IMAGE_REGISTRY="10.10.10.10"
          IMAGE_NAME="petmatch/matchmaking"
          VERSION=$(echo ${{ github.ref }} | cut -d / -f 3)
          IMAGE_URL="$IMAGE_REGISTRY/$IMAGE_NAME:$VERSION"
          BUILT_IMAGE=$(./build.sh $IMAGE_URL)
          echo "::set-output name=built-image::${BUILT_IMAGE}"                                #3
  deploy-matchmaking-service-image:
    runs-on: ubuntu-latest
    needs: build-matchmaking-service-image
    steps:
      - uses: actions/checkout@v2
      - id: deploy
        run: |
          ./update_config.sh ${{ needs.build-matchmaking-service-image.outputs.built-image }} #4
          ./deploy.sh
#1 This job defines an output—the full URL and digest of the built image—which is produced by the step that follows and can be used by the next job as an input.
#2 This step with id build-and-push will create the output previously declared.
#3 This is where the build job sets the value of the built-image output.
#4 The full URL and digest of the built image (output of the previous job) can be used by this job as an input.
```

The first job in the pipeline declares an output called `built-image`, which is consumed by the next job as an input. This allows the deploy job to be flexible enough to work for any built image URL and allows the logic to be separated into two separate well-factored jobs.

##### Scripts vs. inline bash

Chapter 12 recommended writing bash inline within tasks to increase reusability instead of storing it separately in scripts (as well as switching to general-purpose languages if the bash starts to get long). These examples use a separate script to avoid getting into the details of how each task is implemented, so I can focus on the pipeline and task features that this chapter is about.

## [](/book/grokking-continuous-delivery/chapter-13/)[](/book/grokking-continuous-delivery/chapter-13/)Hardcoding in the release pipeline

[](/book/grokking-continuous-delivery/chapter-13/)Although the existing[](/book/grokking-continuous-delivery/chapter-13/)[](/book/grokking-continuous-delivery/chapter-13/)[](/book/grokking-continuous-delivery/chapter-13/)[](/book/grokking-continuous-delivery/chapter-13/)[](/book/grokking-continuous-delivery/chapter-13/) pipeline makes good use of inputs and outputs at the level of tasks, it isn’t quite as good about this at the level of the pipeline itself. In fact, several values are hardcoded into the release pipeline that prevent the pipeline from being for the system tests:

```
name: Build and deploy to production from tag
on:
  push:
    tags:
      - '*'
jobs:
  build-matchmaking-service-image:
    runs-on: ubuntu-latest
    outputs:
      built-image: ${{ steps.build-and-push.outputs.built-image }}
    steps:
      - uses: actions/checkout@v2
      - id: build-and-push
        run: |
          IMAGE_REGISTRY="10.10.10.10"
          IMAGE_NAME="petmatch/matchmaking"
          VERSION=$(echo ${{ github.ref }} | cut -d / -f 3)  #1
          IMAGE_URL="$IMAGE_REGISTRY/$IMAGE_NAME:$VERSION"
          BUILT_IMAGE=$(./build.sh $IMAGE_URL)
          echo $BUILT_IMAGE
          echo "::set-output name=built-image::${BUILT_IMAGE}"
  deploy-matchmaking-service-image:
    runs-on: ubuntu-latest
    needs: build-matchmaking-service-image
    steps:
      - uses: actions/checkout@v2
      - id: deploy
        run: |
          ./update_config.sh ${{ needs.build-matchmaking-service-image.outputs.built-image }}
          ./deploy.sh                                        #2
#1 The registry, image name, and the way the version is defined are all hardcoded. The end-to-end tests need to push images to a different registry, and they need to name them slightly differently, with a different versioning scheme.
#2 The deploy.sh script is hardcoded to deploy to the production Matchmaking service, but the end-to-end tests need to deploy to the SUT environment instead.
```

To be able to use this pipeline from the end-to-end test pipeline, it must be possible to vary the hardcoded values as follows:

-  Pushing to either the production image registry or the one used for system tests.
-  Varying how the version and name of the image are determined. In production, the name is always the same and the version comes from the tag. For end-to-end tests, there is no tag and the image name is different.
-  Deploying to either the production environment or the SUT environment created by the CI pipeline.

## [](/book/grokking-continuous-delivery/chapter-13/)[](/book/grokking-continuous-delivery/chapter-13/)Pipeline reuse with parameterization

[](/book/grokking-continuous-delivery/chapter-13/)To be able[](/book/grokking-continuous-delivery/chapter-13/)[](/book/grokking-continuous-delivery/chapter-13/)[](/book/grokking-continuous-delivery/chapter-13/)[](/book/grokking-continuous-delivery/chapter-13/) to use the release pipeline from the CI pipeline, the matchmaking team makes a few changes. The engineers create a reusable GitHub Actions workflow for deployment that takes parameters, allowing it to be used for both the end-to-end tests and for the final deployment:

```
name: Build and deploy
on:
  workflow_call:            #1
    inputs:
      image-registry:       #2
        required: true      #2
        type: string        #2
      image-name:           #2
        required: true      #2
        type: string        #2
      version-from-tag:     #2
        required: true      #2
        type: boolean       #2
      deploy-target:        #2
        required: true      #2
        type: string        #2
jobs:
  build-matchmaking-service-image:
    runs-on: ubuntu-latest
    outputs:
      built-image: ${{ steps.build-and-push.outputs.built-image }}
    steps:
      - uses: actions/checkout@v2
      - id: build-and-push
        run: |
          if [ "${{ inputs.version-from-tag }}" = "true" ]                           #3
          then
            VERSION=$(echo ${{ github.ref }} | cut -d / -f 3)
          else
            VERSION=${{ github.sha }}
          fi
          IMAGE_URL="${{ inputs.image-registry }}/${{ inputs.image-name }}:$VERSION" #4
          BUILT_IMAGE=$(./build.sh $IMAGE_URL)
          echo "::set-output name=built-image::${BUILT_IMAGE}"
  deploy-matchmaking-service-image:
    runs-on: ubuntu-latest
    needs: build-matchmaking-service-image
    steps:
      - uses: actions/checkout@v2
      - id: deploy
        run: |
          ./update_config.sh ${{ ... }}
          ./deploy.sh  ${{ inputs.deploy-target }}                                   #5
#1 This workflow is configured to run on workflow_call, which means it can be called from other workflows.
#2 These parameters must be provided by the calling workflow. These parameters make it possible to use this workflow for both testing and production deployments.
#3 The workflow can be configured to either generate the version from a tag (extracted from github .ref) or use the commit (provided via github.sha). Production builds will use a tag, and tests will use the commit.
#4 The image registry and image name are now configurable.
#5 The deploy task will now be passed the IP of the environment to deploy to, instead of being hardcoded to always deploy to production.
```

##### Where are the secrets?

Deploying to the SUT will likely require different credentials than deploying to production. Those details have been left out of this example, but being able to parameterize these is important as well.

## [](/book/grokking-continuous-delivery/chapter-13/)[](/book/grokking-continuous-delivery/chapter-13/)Using reusable pipelines

[](/book/grokking-continuous-delivery/chapter-13/)The reusable pipeline[](/book/grokking-continuous-delivery/chapter-13/)[](/book/grokking-continuous-delivery/chapter-13/)[](/book/grokking-continuous-delivery/chapter-13/)[](/book/grokking-continuous-delivery/chapter-13/) (stored in the matchmaking repository in a file called .github/workflows/deployment.yaml) is designed to be called only from other workflows, so the matchmaking team updates its existing workflow (configured to run when a new version is tagged) to use it:

```
name: Build and deploy to production from tag              #1 
on:                                                        #1 
  push:                                                    #1 
    tags:                                                  #1 
      - '*'                                                #1 
jobs:                                                      #1 
  deploy:                                                  #1 
    uses: ./.github/workflows/deployment.yaml              #1 
    with:                                                  #1 
      image-registry: '10.10.10.10'                        #1 
      image-name: 'petmatch/matchmaking'                   #1 
      version-from-tag: true                               #1 
      deploy-target: '10.11.11.11'                         #1
#1 When a new version is tagged, the deployment workflow will be called using parameters that ensure the production image will be built with the tag’s version, pushed to the production image registry, and deployed to the production instance.
```

The CI workflow is also updated to use the reusable deployment workflow. The previous build and deploy tasks (which were specific to the end-to-end tests) are removed and are replaced with a call to the reusable workflow:

```
name: Run CI                                               #1 
..                                                         #1 
jobs:                                                      #1 
  setup-sut: ...                                           #1 
  deploy-to-sut:                                           #1 
    needs: setup-sut
     uses: ./.github/workflows/deployment.yaml
     with:
       image-registry: '10.12.12.12' 
      image-name: 'petmatch/matchmaking-e2e-test' 
      version-from-tag: false
       deploy-target: ${{ needs.setup-sut.outputs.env-ip}} #2 
  end-to-end-tests: ... 
  clean-up-sut: ...
#1 When a PR runs, the deployment workflow will be called using parameters that ensure that the test image is built with the expected name, versioned with the commit, pushed to the test image registry, and deployed to the SUT.
#2 setup-sut creates the SUT environment to deploy to and provides the IP as an output. This can be passed to the reusable workflow as an input.
```

## [](/book/grokking-continuous-delivery/chapter-13/)[](/book/grokking-continuous-delivery/chapter-13/)Updated pipelines

[](/book/grokking-continuous-delivery/chapter-13/)The CI pipeline[](/book/grokking-continuous-delivery/chapter-13/)[](/book/grokking-continuous-delivery/chapter-13/)[](/book/grokking-continuous-delivery/chapter-13/)[](/book/grokking-continuous-delivery/chapter-13/) has been updated to use the reusable release pipeline (the exact pipeline used for production deployments, but called with different parameters) and now looks like this:

![](https://drek4537l1klr.cloudfront.net/wilson3/Figures/13-15.png)

#####  Takeaway

To be able to use pipelines in different scenarios (such as when being called by other pipelines), it must be possible to parameterize them.

## [](/book/grokking-continuous-delivery/chapter-13/)[](/book/grokking-continuous-delivery/chapter-13/)Solving PetMatch’s CD problems

[](/book/grokking-continuous-delivery/chapter-13/)With the release[](/book/grokking-continuous-delivery/chapter-13/)[](/book/grokking-continuous-delivery/chapter-13/) pipeline now being used as part of end-to-end tests on every PR, the matchmaking engineers revisit the list of pipeline problems they were trying to solve:

-  *Errors*[](/book/grokking-continuous-delivery/chapter-13/)—The end-to-end tests leave the test environments in a bad state. Fixed! Using finally behavior means that the test cleanup will always happen.
-  *Speed*—The end-to-end test pipeline is too slow to run when needed. Fixed! Using test sharding and matrix execution, the end to end pipeline can now run on every PR.
-  *Signal*—End to end and release pipelines provide signals too late. Fixed! Both the end-to-end tests and the release pipeline are now run on every PR. Problems with the release pipeline are now likely to be caught when the CI runs.

Since all of their CI now runs on every PR, and they’re using the release pipeline as part of that CI, the PetMatch engineers have maximized the amount of signal they can get. They needed to consider a few tradeoffs to get to this point:

-  *The speed of the signal*—The CI pipeline offers more signals than it did before, but it now takes up to nearly 20 minutes to run. Without the end-to-end tests, the pipeline used to take a couple of minutes at most.
-  *The frequency of the signal*—The matchmaking team has traded the speed of the CI signals for frequency: they get more signals sooner, but have to wait longer each time the pipeline runs, which can mean more time waiting for PRs to be ready to merge.
-  *Impact of the codebase not being releasable*—Their previous approach left their codebase in an unknown state; bugs wouldn’t be caught until nightly end-to-end tests ran, or until release time. Being in this state negatively impacts the foundation of CD, as you’ve seen in previous chapters.
-  *Resources required to execute pipelines*—Each invocation of the CI pipeline (which can happen multiple times per PR) will now need an SUT environment provisioned for it, and will run tests across six separate shards. Compared to running these tests once nightly, the matchmaking team’s CI is going to be consuming a lot more resources.

## [](/book/grokking-continuous-delivery/chapter-13/)[](/book/grokking-continuous-delivery/chapter-13/)CD features to look for

[](/book/grokking-continuous-delivery/chapter-13/)The matchmaking[](/book/grokking-continuous-delivery/chapter-13/) engineers were able to solve their CD problems by reorganizing their tasks and pipelines. They used a CD system that provided the following features:

-  *Supporting both tasks and pipelines*—Supporting in some form both small cohesive bundles of functionality (tasks) and the orchestration of those reusable bundles (pipelines) allows for flexibility in CD pipeline design.
-  *Outputs*[](/book/grokking-continuous-delivery/chapter-13/)—Allowing tasks to emit outputs that can be used by other tasks supports creating well-factored, highly cohesive, loosely coupled, reusable tasks.
-  *Inputs*[](/book/grokking-continuous-delivery/chapter-13/)—Similarly, allowing tasks and pipelines to consume inputs also supports making them reusable.
-  *Conditional execution*[](/book/grokking-continuous-delivery/chapter-13/)—Pipelines can be more reusable if you can gate execution of some tasks in the pipeline on the pipeline’s inputs.
-  *Finally behavior*[](/book/grokking-continuous-delivery/chapter-13/)—Many CD pipelines will have tasks that need to run even if other parts of the pipeline fail, e.g., in order to leave resources in a good state after execution or to notify developers of successes and failings, which means being able to specify tasks that must always run.
-  *Parallel execution*—Running tasks in parallel that don’t depend on each other is an easy way to get immediate speed gains in pipeline execution.
-  *Matrix-based execution*[](/book/grokking-continuous-delivery/chapter-13/)—Many CD pipelines will have tasks that need to be run for every combination of a set of values (for example, for test sharding), and having a matrix (or looping) syntax for this supports task reuse and parallelization.
-  *Pipelines invoking pipelines*—Making pipelines themselves reusable not only makes it easier to construct complex pipelines when needed but also makes it easy to ensure that the same logic is used across the board even when the circumstances are slightly different (for example, deploying to a test environment versus deploying to production).

##### What do I do if my CD system doesn’t have these features?

If your CD system doesn’t have these features, you’ll have to either keep your pipelines very simple (limiting the use you can get from them) or build the features yourself. This often means creating your own libraries for functionality like looping, but it limits you in the performance impact these solutions can have (for example, your looping functionality might be limited to running within one machine). Lack of these features often means building complex tasks with many responsibilities, including orchestration logic. If possible, choose a CD system that does more of this heavy lifting for you. See appendix A for features of some common CD systems.

## [](/book/grokking-continuous-delivery/chapter-13/)Conclusion

[](/book/grokking-continuous-delivery/chapter-13/)Fixing CD pipeline problems can sometimes be as simple as redesigning the pipelines themselves. The matchmaking engineers didn’t need to change the functionality of their tasks and pipelines. By making use of CD system pipeline features and reorganizing what they already had, they greatly increased the value of their pipelines—at the cost of speed and resource consumption, a price they were more than willing to pay.

## [](/book/grokking-continuous-delivery/chapter-13/)Summary

Look for theses features in your CD systems and consider leveraging them when you find that your pipelines aren’t giving you the signal you need:

-  Tasks (reusable units of functionality) and pipelines (which orchestrate tasks)
-  Inputs and outputs (as features of tasks and of pipelines)
-  Conditional execution
-  Finally behavior
-  Parallel execution and matrix support
-  Reusable pipelines

Also consider the following tradeoffs when designing your pipelines and deciding what will run when:

-  Speed of the signal (how fast your pipelines run)
-  Frequency of the signal (when you run them)
-  Impact of an unreleasable codebase
-  Resources required (and available) to execute these pipelines

## [](/book/grokking-continuous-delivery/chapter-13/)Up next . . .

You’ve reached the end of the chapters! I hope you have enjoyed this CD journey as much as I have. In the appendices at the end of this book, we’ll take a look at some of the features we’ve discussed across a few common CD and version control systems.

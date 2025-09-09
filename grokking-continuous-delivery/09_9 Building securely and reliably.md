# 9 [](/book/grokking-continuous-delivery/chapter-9/)[](/book/grokking-continuous-delivery/chapter-9/)Building securely and reliably

### In this chapter

- building securely by automating builds, treating build configuration as code, and running builds on a dedicated service with ephemeral environments
- unambiguously and uniquely identifying artifacts by using semantic versioning and hashes
- eliminating surprise bugs from dependencies by pinning them at specific unique versions

Building is such[](/book/grokking-continuous-delivery/chapter-9/) an integral part of the continuous delivery (CD) process that CD tasks and pipelines are often referred to as *builds*. The automation we’ve come to know and love today originated from automation created to successfully build software artifacts from their source code to the form required to actually distribute and run them.

In this chapter, I’m going to show you common pitfalls in building software artifacts that let bugs sneak in and make life difficult for consumers of those artifacts, and how to build CD pipelines that dodge those problems entirely.

## [](/book/grokking-continuous-delivery/chapter-9/)[](/book/grokking-continuous-delivery/chapter-9/)Top Dog Maps

[](/book/grokking-continuous-delivery/chapter-9/)The company Top[](/book/grokking-continuous-delivery/chapter-9/)[](/book/grokking-continuous-delivery/chapter-9/) Dog Maps runs a website for finding dog parks. It allows users to find dog parks within a certain area, rate the parks, and even check into them. The user with the most check-ins becomes the pack leader for the park.

![](https://drek4537l1klr.cloudfront.net/wilson3/Figures/09-01.png)

The architecture of Top Dog Maps is broken into several services, each owned by a separate team: the Frontend service, the Map Search service, and the User Account service.

![](https://drek4537l1klr.cloudfront.net/wilson3/Figures/09-02.png)

Each service is distributed and run as a container image, and the installation of the services is managed by the frontend team. The map search and user account teams release built container images, and the frontend team decides when and where to install them, so they can consume updates at their leisure.

The map search team has recently had a bit of a shake-up: Julia had been in charge of building the container image for the Map Search service, but she recently moved on to a different company, leaving a gap on the team.

## [](/book/grokking-continuous-delivery/chapter-9/)[](/book/grokking-continuous-delivery/chapter-9/)When the build process is a doc

[](/book/grokking-continuous-delivery/chapter-9/)Now that Julia[](/book/grokking-continuous-delivery/chapter-9/)[](/book/grokking-continuous-delivery/chapter-9/) has left Top Dog Maps, someone on the map search team needs to take over building the image for that service. Fortunately, existing team member Miguel is eager to improve their build processes and quickly volunteers to take on the work.

His first step is to assess how building the map search image currently works. He quickly learns that the build process consists of following along with the instructions Julia has written in a doc:

| **Building the map search image**<br>  **Step 1:**<br>  Clone the map search repo:<br>  $ git clone git@github.com:topdogmaps/map-search.git<br><br>  **Step 2:**<br>  Change directory into the repo:<br>  $ cd map-search<br><br>  **Step 3:**<br>  Build the container image:<br>  $ docker build --tag top-dog-maps/map-search . ❶<br><br>  **Step 4:**<br>  Push the image to the top dog maps registry:<br>  $ docker push top-dog-maps/map-search ❶ Are you already noticing that the image isn’t being tagged with a version? Don’t worry, I’ll get to that! But first Miguel has bigger fish to fry. |
| --- |

![](https://drek4537l1klr.cloudfront.net/wilson3/Figures/09-04.png)

Miguel identifies a couple of problems with this process right off the bat:

-  The process relies on a person to read the doc and correctly execute each of the listed instructions. This can be error prone; it’s easy to accidentally skip an instruction or make a typo.
-  The steps could be run anywhere: on Julia’s machine, on Miguel’s machine, who knows! There is no consistency, meaning that even building the same source code could have different results when the steps are executed on different machines.

## [](/book/grokking-continuous-delivery/chapter-9/)[](/book/grokking-continuous-delivery/chapter-9/)Attributes of secure and reliable builds

[](/book/grokking-continuous-delivery/chapter-9/)As he works[](/book/grokking-continuous-delivery/chapter-9/)[](/book/grokking-continuous-delivery/chapter-9/)[](/book/grokking-continuous-delivery/chapter-9/) on a plan to improve the build process, Miguel makes a list of the attributes of secure and reliable builds that he wants the Map Search service to start following—and eventually the rest of the teams at Top Dog Maps as well:

| **Always releasable** | Source code should always be in a releasable state. |
| --- | --- |
| **Automated builds** | Execution of builds should be automated, not created manually. |
| **Build as code** | Build configuration should be treated like code and stored in version control. |
| **Use a CD service** | Builds should happen via CD service, not just random machines such as a developer’s workstation. |
| **Ephemeral environments** | Builds should happen in ephemeral environments that are created and torn down for each build. |

#####  Vocab time

When someone refers to *builds* or *the build*, they are talking about the task(s) that build software artifacts from source code.

##### Standards for secure CD artifacts: SLSA

The preceding requirements come from a recently emerging set of standards for securely building software artifacts. Called *Supply Chain Levels for Software Artifacts*[](/book/grokking-continuous-delivery/chapter-9/)[](/book/grokking-continuous-delivery/chapter-9/), or *SLSA* (pronounced “salsa”), they were inspired by the standards that Google uses internally for securing production workloads. SLSA ([https://slsa.dev](https://slsa.dev)) defines a series of levels of security for building artifacts that can be achieved incrementally. The requirements I’m discussing here specifically come from the build process requirements for achieving SLSA version 0.1 level 3. If you are interested in securing your software supply chain, the SLSA levels are a great resource for outlining how to go from where your process is currently at to gradually more and more secure processes.

#####  Hermetic and reproducible builds

[](/book/grokking-continuous-delivery/chapter-9/)Once your build[](/book/grokking-continuous-delivery/chapter-9/)[](/book/grokking-continuous-delivery/chapter-9/)[](/book/grokking-continuous-delivery/chapter-9/) process meets the previously listed requirements, it will meet the SLSA version 0.1 level 3 requirements for builds. (Note there are additional requirements for SLSA level 3 in general; we are focusing here on the requirements for building specifically).

If you want to make your process even more secure, the next step is to look at the SLSA level 4 requirements, especially making your builds *hermetic* (the build process has no external network access and can’t be impacted by anything other than its inputs) and *reproducible* (every time you do a build with the same inputs, you get an exactly identical output).

These are great goals to aim for, but can be a lot of work to achieve, especially since the current state of CD tooling doesn’t have great support for hermetic and/or reproducible builds: even if you are using container-based builds, most CD systems don’t make it easy to guarantee that their execution is hermetic (e.g., locking down network access from within the container), and it’s extremely easy to create builds that aren’t reproducible (even differences as small as timestamps within the resulting artifact violate the reproducible requirement).

That being said, keep an eye out for more support for this in the space in the near future. In the meantime, just meeting the requirements listed previously should give you a lot of confidence!

## [](/book/grokking-continuous-delivery/chapter-9/)[](/book/grokking-continuous-delivery/chapter-9/)Always releasable

[](/book/grokking-continuous-delivery/chapter-9/)Let’s take a look[](/book/grokking-continuous-delivery/chapter-9/)[](/book/grokking-continuous-delivery/chapter-9/)[](/book/grokking-continuous-delivery/chapter-9/) at each of the requirements Miguel outlined in more detail, starting with keeping the source code *always releasable*. Keeping the codebase in a releasable state is what we’ve spent most of the book so far examining, specifically using CI to make sure your software is in a releasable state at all times. Remember, continuous integration is

**the process of combining code changes frequently, with each change verified on check-in**.

When each change is verified on check-in (see chapter 7 for more on when exactly the verification should occur), you can be confident that your software is always in a releasable state.

Fortunately, the map search team already has a robust CI pipeline that runs on every change (including unit tests, system tests, and linting), so the team already feels confident that a new image can be built at any time.

![](https://drek4537l1klr.cloudfront.net/wilson3/Figures/09-05.png)

#####  Takeaway

Use CI (as described in chapters 3–7) to keep your codebase in a releasable state.

## [](/book/grokking-continuous-delivery/chapter-9/)[](/book/grokking-continuous-delivery/chapter-9/)Automated builds

[](/book/grokking-continuous-delivery/chapter-9/)The second requirement[](/book/grokking-continuous-delivery/chapter-9/)[](/book/grokking-continuous-delivery/chapter-9/) that Miguel has listed is to use *automated builds*. This breaks into two further requirements:

-  All of the steps required to build an artifact must be defined in a *script*[](/book/grokking-continuous-delivery/chapter-9/).
-  Execution of that script should be triggered by automation, not by a person.

Contrast this with some examples of having builds that are not automated:

-  Assuming the person creating the artifact “just knows” what to do (keeping the steps in your head and passing them on by word of mouth)
-  Writing down the steps in a document that is meant to be read and acted on by a person
-  Creating a script for building the artifact, but requiring a person to run it manually in order to create the artifact

What the map search team is doing to build its container image currently is in opposition to both of the requirements for automated builds: the build steps are defined in a document meant to be read by a person, and the intention is that a person would execute each of these steps.

#####  Takeaway

To create automated builds, define all of your build steps in a script and trigger that script automatically.

#####  Vocab time

We’re using *script*[](/book/grokking-continuous-delivery/chapter-9/) to refer to a series of instructions that are executed by software (rather than people). Scripting languages are usually interpreted: each command is understood and run as is rather than needing to be compiled first. We’ll be using bash as our scripting language in the examples in this chapter. See chapter 12 for how to use scripts effectively in your tasks and pipelines.

## [](/book/grokking-continuous-delivery/chapter-9/)[](/book/grokking-continuous-delivery/chapter-9/)Build as code

[](/book/grokking-continuous-delivery/chapter-9/)The second requirement[](/book/grokking-continuous-delivery/chapter-9/)[](/book/grokking-continuous-delivery/chapter-9/) outlined by Miguel is to treat the build as code. *Build as code*[](/book/grokking-continuous-delivery/chapter-9/) is referring back to the idea of *config as code*[](/book/grokking-continuous-delivery/chapter-9/) (see chapter 3). Practicing config as code means the following:

**Storing all plain-text data that defines your software in version control**.

*Build as code*[](/book/grokking-continuous-delivery/chapter-9/) is just a fancy way of saying that the build configuration (and any scripts required) is part of the plain-text data that defines your software: it defines how your software goes from source code to released artifact.

##### Are you saying I should write tests for my builds?

It depends! We’ll get into this more in chapter 12, but here’s a sneak preview: once you move beyond just a few simple lines in a script, it’s a good idea to test it, just as you would any other code you write.

This means that in order to be treating your build configuration as code, you should be storing it in version control, and where you can, applying the same CI best practices we’ve been looking at for source code, including linting it and, if it’s complicated enough to warrant it, testing it. But even if you don’t go that far, the key to this requirement is to store your build configuration in version control, alongside the code it builds.

What does it look like if you’re *not* treating your builds as code?

-  Setting up and configuring your builds solely via a web interface
-  Storing your build instructions and scripts in a doc
-  Writing scripts to define your builds but not storing them in version control (for example, storing them on your machine or in a shared drive)

Since the maps search team members currently have all of their build instructions in a doc (intended to be read and executed by a person), they are not (yet!) meeting the build-as-code requirement.

#####  Takeaway

To practice build as code, check your build configuration and scripts into version control.

## [](/book/grokking-continuous-delivery/chapter-9/)[](/book/grokking-continuous-delivery/chapter-9/)Use a CD service

[](/book/grokking-continuous-delivery/chapter-9/)Miguel is also requiring[](/book/grokking-continuous-delivery/chapter-9/) that secure builds occur via a CD service of some kind. The goal of this requirement is to ensure consistency in the way the build is triggered and run.

If your company is hosting and running its own CD service, this service should be treated like any other production service, i.e., run on hardware configured and managed using the same best practices as production software (e.g., config as code).

The *CD service*[](/book/grokking-continuous-delivery/chapter-9/) that executes the builds could be a service that is built, hosted, and run within the company; it could be an instance of a third-party solution like GitLab hosted within the company; or it could be a complete cloud offering of a CD service, hosted externally. The important thing is that builds occur on a *CD system*[](/book/grokking-continuous-delivery/chapter-9/) that is hosted and offered as a running service (see appendix A for an overview of CD systems). This can be contrasted with the following approaches that do *not* use a CD service:

-  Having no requirements whatsoever around where build artifacts originate from
-  Running builds on a developer’s own workstation
-  Running builds on a specific workstation (e.g., a computer under someone’s desk) or random virtual machine (VM) in the cloud setup just for building
-  Running builds on the production servers the artifacts will be running on

The maps search team currently has no requirements at all around where the builds are run, and most likely Julia has been executing the build steps on her machine up until this point, so the team’s build process definitely isn’t meeting this criteria.

#####  Takeaway

To ensure consistency in your builds, use a CD service to run them.

##### Was Julia doing a bad job?

It seems like the build process Julia defined is falling short of nearly every criteria that Miguel has come up with; does this mean she was doing a bad job? It’s true that their build process up until this point wasn’t particularly secure or reliable, but consider the fact that it has worked up until this point. Creating CD processes is often a cycle of setting up something that is good enough at the time it is created—even if you can see flaws in the process already—and revisiting those processes after time passes, once they become a priority. Because the truth is that there is no perfect process, and your processes will (and should) always evolve over time. What Julia set up had worked well enough (and often that’s all you need), and until now there hadn’t been a reason to revisit it. Don’t let the perfect be the enemy of the good!

## [](/book/grokking-continuous-delivery/chapter-9/)[](/book/grokking-continuous-delivery/chapter-9/)Ephemeral build environments

[](/book/grokking-continuous-delivery/chapter-9/)The last requirement[](/book/grokking-continuous-delivery/chapter-9/)[](/book/grokking-continuous-delivery/chapter-9/) Miguel defined is that builds should take place in *ephemeral environments*[](/book/grokking-continuous-delivery/chapter-9/). The word *ephemeral* means “lasting a very short time,” and that’s exactly what ephemeral environments are: environments that last a very short time. Specifically, they exist *only for the duration of the build itself* and are never reused.

These environments are torn down and destroyed after a build completes, and are not used for anything else prior to the build. They can be created on demand or pooled and made ready for use quickly; the key is that they exist for one build and one build only. Common approaches that do not use ephemeral environments include the following:

-  Using one physical machine for multiple builds (e.g., a computer under someone’s desk)
-  Provisioning a VM and using it for multiple builds

##### Are VM build environments more secure than containers?

Containers share some of the underlying operating system with one another and their host, so a small chance of cross contamination exists. However, this can be minimized by ensuring that containers run with the bare minimum permissions they need and do not have the ability to write to parts of the filesystem that could impact other containers.

Never reusing a build environment means there is no chance of anything persisting from a build that might influence another build. You may try to get the same effect by reusing an environment with automation to clean it up between builds, but this is risky because there is always a chance that you will miss something. Using an ephemeral environment guarantees that you’ll avoid cross contamination between builds.

The most common ways to ensure that you have an ephemeral environment are to use a fresh VM or a fresh container for each build. More and more, containers are becoming the go-to for ephemeral builds, because (relative to VMs) they are so fast to start and tear down.

As you’ve seen already, the map search build process currently could be run anywhere, so they definitely aren’t meeting the ephemeral environment requirement.

#####  Vocab time

The *build environment*[](/book/grokking-continuous-delivery/chapter-9/) is the context in which the build occurs (i.e., the source code is transformed into a software artifact). This includes the kernel, operating system, installed programs, and files. Another way of thinking about the *build environment*[](/book/grokking-continuous-delivery/chapter-9/) is that it is all the files and programs that are available for use by the build itself and could impact the resulting artifact. Examples of common build environments are containers or VMs, or they could be an entire computer (aka “bare metal”) if no virtualization or containerization is involved.

## [](/book/grokking-continuous-delivery/chapter-9/)[](/book/grokking-continuous-delivery/chapter-9/)Miguel’s plan

[](/book/grokking-continuous-delivery/chapter-9/)After defining the requirements for secure and reliable builds, Miguel evaluates the map search build process against them:

| **Always releasable** | Yes—map search is already following good CI practices and verifying each change on check-in with linting, unit tests, and system tests |
| --- | --- |
| **Automated builds** | No—builds are executed manually |
| **Build as code** | No—build steps exist in a document meant to be consumed by people |
| **Use a CD service** | No—most likely builds have been occurring on Julia’s machine |
| **Ephemeral environments** | No—there is no control whatsoever over the environment the build takes place in |

They clearly have a ways to go, but Miguel is excited to get started because now that he’s defined these requirements, and evaluated their current process against them, he has a very clear idea of what needs to be done next. His plan has two phases:

1.  Go from manual instructions in a doc to a script checked into version control. This gives him build as code and half of what he needs for automated builds, i.e., a scripted build.
1.  Go from building on a developer machine to using a CD service and executing builds in containers. This gives him the rest of the missing requirements: the other half of automated builds (automated triggering), the use of a CD service, and finally ephemeral build environments.

## [](/book/grokking-continuous-delivery/chapter-9/)[](/book/grokking-continuous-delivery/chapter-9/)From a doc to a script in version control

[](/book/grokking-continuous-delivery/chapter-9/)The first phase[](/book/grokking-continuous-delivery/chapter-9/)[](/book/grokking-continuous-delivery/chapter-9/)[](/book/grokking-continuous-delivery/chapter-9/)[](/book/grokking-continuous-delivery/chapter-9/) of the map search build process transformation is to go from manual instructions in a doc to a script checked into version control. Fortunately, Julia has made this easy for Miguel because even though she didn’t go as far as creating a script, she did write down all the commands that need to go into the eventual script in her doc:

| **Building the map search image**<br><br>  **Step 1:**<br>  Clone the map search repo: <br>  $ git clone git@github.com:topdogmaps/map-search.git<br><br>  **Step 2:**<br>  Change directory into the repo: <br>  $ cd map-search<br><br>  **Step 3:**<br>  Build the container image:<br>  $ docker build --tag top-dog-maps/map-search .<br><br>  **Step 4:**<br>  Push the image to the top dog maps registry:<br>  $ docker push top-dog-maps/map-search |
| --- |

Using Julia’s doc as a starting point, Miguel creates an initial bash script:

```bash
#!/usr/bin/env sh                            #1
set -xe                                      #1
                                             #1
cd "$(dirname "$0")"                         #1

docker build --tag top-dog-maps/map-search . #2
docker push top-dog-maps/map-search
```

Since this will live in the same repo as the source code, Miguel doesn’t include steps 1 and 2 in the script, but they’ll come into play in the next phase. He commits the script to the repo, and the first phase is done. The repo contents look like this:

```
.pylintrc
Dockerfile  #1
map/
search/
test/
build.sh    #2
app.py
README.md
requirements.txt
```

## [](/book/grokking-continuous-delivery/chapter-9/)[](/book/grokking-continuous-delivery/chapter-9/)Automated containerized builds

[](/book/grokking-continuous-delivery/chapter-9/)The script has[](/book/grokking-continuous-delivery/chapter-9/)[](/book/grokking-continuous-delivery/chapter-9/)[](/book/grokking-continuous-delivery/chapter-9/) gotten them part of the way there, but Miguel doesn’t rest for long! What he needs next is to introduce logic that makes the build:

-  Triggered by automation
-  Run via a CD service
-  Run in containers

Top Dog Maps has already been using GitHub Actions for its CI, so Miguel decides to use GitHub Actions for for automating building of the Map Search service as well:

```
name: Build Map Search Service
on:
  push:
    branches: [main]               #1
jobs:
  build-and-push:
    runs-on: ubuntu-latest
    container: docker:20.10.12
    steps:
      - uses: actions/checkout@v2  #2
      - name: Run Build Script
        run: ./build.sh            #3
```

With this change, Miguel has completed the second phase of his update to the Map Search service build process!

The GitHub Actions workflow configuration must be committed to the repository in order for GitHub to pick it up (and also because you’d want to commit this configuration to the repo regardless, to meet the build-as-code requirement), so the repo contents now look like this:

```
.github/
  workflows/
    build.yml  #1
.pylintrc
Dockerfile
map/
search/
test/
build.sh
app.py
README.md
requirements.txt
```

#####  Automating builds with Github Actions

[](/book/grokking-continuous-delivery/chapter-9/)**Should I be creating a script to do my container builds like Miguel did?**

There’s a good[](/book/grokking-continuous-delivery/chapter-9/)[](/book/grokking-continuous-delivery/chapter-9/)[](/book/grokking-continuous-delivery/chapter-9/) chance you won’t need to. Popular CD systems often come with specialized and reusable tasks, or in the GitHub Actions case, Actions.

For example, Miguel could be using the Docker-specific GitHub Action instead of creating his own script, which takes care of checking out the source code, building it, and pushing it.

However the step-by-step incremental progression that Miguel is taking is a really solid approach, i.e., changing one thing at a time from the original process. The next logical evolution of this configuration would be for Miguel to start using the official Docker GitHub Action and probably replacing the script entirely. (And the less you need to write your own scripts, the better! See chapter 12 for more on scripts.)

**What if I’m not using GitHub Actions?**

Absolutely fine! We’re just using GitHub Actions as an example. Whichever CD system you’re using (see appendix A on CD systems for some options), the key is to make sure you meet the requirements that Miguel outlined.

If possible, choose a CD system that supports container-based execution, which is becoming the standard for isolated task execution. VM-based execution will also meet your isolation needs, but relying solely on VMs tends to result in slower execution time, and more temptation to execute multiple tasks on one VM to combat this, leading to bloated tasks that do far too many things and aren’t easy to maintain or reuse.

## [](/book/grokking-continuous-delivery/chapter-9/)[](/book/grokking-continuous-delivery/chapter-9/)Secure and reliable build process

[](/book/grokking-continuous-delivery/chapter-9/)Now that Miguel[](/book/grokking-continuous-delivery/chapter-9/)[](/book/grokking-continuous-delivery/chapter-9/)[](/book/grokking-continuous-delivery/chapter-9/) has completed both phases of his plan by creating a script, configuring it all to trigger using GitHub Actions, and checked it into GitHub, he reevaluates the team’s process:

| **Always releasable** | Yes—map search is already following good CI practices and verifying each change on check-in with linting, unit tests, and system tests |
| --- | --- |
| **Automated builds** | Yes—the build steps are defined in a script that is triggered by GitHub Actions whenever the main branch is up |
| **Build as code** | Yes—both the script with the build steps and the GitHub Actions config (i.e., the complete build configuration) are committed to GitHub |
| **Use a CD service** | Yes—they are using GitHub Actions |
| **Ephemeral environments** | Yes—by default GitHub Actions will execute each job in a fresh VM, and Miguel is using a fresh container inside that VM as well |

Miguel has succeeded in meeting the requirements he set out to meet. He now feels confident reporting to the other teams at Top Dog Maps that map search has achieved a secure and reliable build process!

##### Do I need to release with every commit in order to be doing automated builds?

Miguel has set up the GitHub Actions configuration to build a new image on every commit, but that isn’t required to do automated builds. What is required is that the triggering is in some way automated. Another common approach is to trigger new builds when a tag is added to the repo, which you’ll see a bit more about in a few pages.

#####  Takeaway

To achieve secure and reliable builds, use a CD service that can execute tasks in containers, and practice build as code (aka config as code) by committing all scripts and configuration to the repo alongside the code being built.

#####  It’s your turn: What’s missing?

[](/book/grokking-continuous-delivery/chapter-9/)The other teams are interested in what Miguel has discovered, and as he works with them, he uncovers some quirks in their current processes that clearly do not meet the requirements he has laid out. For each of the following process decisions, identify which requirement it is violating:

1.  All builds for the Frontend service are run on a VM that was provisioned several months ago. They run a script before and after each build to clean up the VM and erase anything that might have been left behind by other builds.
1.  Builds for the User Account service are run once a week by the build engineer on the team.
1.  The Frontend service team members have a comprehensive set of system tests that they run before they create a new release and deploy it. This is the only point when these tests are run.
1.  The User Account service build steps are defined in a Makefile, which is executed by the team’s build engineer.
1.  Frontend service builds are executed by a CD service with a comprehensive web interface. All configuration for the builds is defined and edited via the web interface.

#####  Answers

1.  This misses the ephemeral build environment requirement. Even though the team is trying to keep the VM clean with a script, there is no guarantee they’ll catch everything.
1.  Running the builds manually means that the user account builds are not meeting the automation requirement.
1.  The frontend service team is completely failing to do CI! By delaying their system tests, the team members have no guarantee that their codebase is in a releasable state.
1.  Using a Makefile is fine (as long as it’s committed to the repo), but the real problem here is that the builds are being executed by the build engineer wherever that person sees fit, and not by a CD service.
1.  By allowing all of the configuration to live only in the web interface, the team is failing to practice build as code.

## [](/book/grokking-continuous-delivery/chapter-9/)[](/book/grokking-continuous-delivery/chapter-9/)Interface changes and bugs

[](/book/grokking-continuous-delivery/chapter-9/)Miguel may have[](/book/grokking-continuous-delivery/chapter-9/)[](/book/grokking-continuous-delivery/chapter-9/)[](/book/grokking-continuous-delivery/chapter-9/) greatly improved the build process for the Map Search service, but unfortunately something still manages to go wrong! And it starts with the best of intentions: cleaning up technical debt.

The map search team gets some time to address some of its long-standing technical debt and decides to change the interface of the most important method their service exposes: the `search` method. Since the Map Search service has been created, new parameters have been organically added to the `search` method, resulting in this interface:

```
def search(self, lat, long, zoom, park_types, pack_leader_only): #1
```

The team members realize they’d keep on adding new parameters indefinitely if this keeps up, and they decide to start using a query language instead, so they can arbitrarily add new attributes to query on as needed. With this update, the `search` method now looks very different:

```
def search(self, query):  #1
```

To consume this updated interface, the frontend team needs to completely change the way they call the `search` method. For example, with the original interface, this is how they would do a search for dog parks in downtown Vancouver, British Columbia, with training equipment:

```
maps.search(49.2827, -123.1207, 8, [ParkTypes.training.name], False)
```

To make the same request with the new interface, they’d need to transform the preceding parameters into a query like this:

```
maps.search(
   "lat=49.2827 && long=-123.1207 && zoom=8 && type in [{}]".format(
     ParkTypes.training.name))
```

This is a pretty big change—and unfortunately as you’re about to see, this change is released before the map search team gets a chance to warn the frontend team!

## [](/book/grokking-continuous-delivery/chapter-9/)[](/book/grokking-continuous-delivery/chapter-9/)When builds cause bugs

[](/book/grokking-continuous-delivery/chapter-9/)The Map Search[](/book/grokking-continuous-delivery/chapter-9/)[](/book/grokking-continuous-delivery/chapter-9/) service has made a substantial change to the most important method the engineers expose via their service, the `search` method, and they forgot to warn the frontend team about it! The Map Search service is used by the Frontend service. The frontend team is in charge of deployments of not just its own service, but also the services it depends on: the Map Search service and the User Account service.

![](https://drek4537l1klr.cloudfront.net/wilson3/Figures/09-06.png)

The frontend team usually deploys new versions of the Map Search and User Account services once a week. This GitHub Actions configuration that Miguel set up is configured to build a new version of the map search container image every time the main branch is updated:

```
name: Build Map Search Service
on:
  push:
    branches: [main] #1
```

The Map Search service team does plan to tell the frontend team about the change, but not everyone on the team fully realizes the consequences of Miguel’s change. They don’t realize that they are effectively doing *continuous releasing*[](/book/grokking-continuous-delivery/chapter-9/), i.e., releasing with every change. And, unfortunately, they don’t realize that the frontend team coincidentally plans to update the Map Search service deployment shortly after the new interface is merged:

![](https://drek4537l1klr.cloudfront.net/wilson3/Figures/09-07.png)

This unfortunate sequence of events means that in production, the frontend service is still trying to call the old search interface, but the version of map search currently running doesn’t support it. This causes a massive outage!

##### Is continuous releasing different from continuous deployment?

In chapter 1, when I defined *continuous deployment*[](/book/grokking-continuous-delivery/chapter-9/), I noted that *continuous releasing*[](/book/grokking-continuous-delivery/chapter-9/) would be a more accurate name for it. That’s what Miguel is doing here, i.e., releasing to users directly with every change. Since no actual deployment occurs, it is less confusing if we call this practice *continuous releasing*[](/book/grokking-continuous-delivery/chapter-9/).

## [](/book/grokking-continuous-delivery/chapter-9/)[](/book/grokking-continuous-delivery/chapter-9/)Builds and communication

[](/book/grokking-continuous-delivery/chapter-9/)The outage[](/book/grokking-continuous-delivery/chapter-9/)[](/book/grokking-continuous-delivery/chapter-9/) is stressful for both the frontend team and the map search team. After the frontend team figures out what happened and the teams work together to fix it, a bit of tension understandably remains between the two teams. The frontend team was on call when the outage happened and wasn’t impressed upon realizing that the outage was caused by changes to the Map Search service that no one had told them about.

Fortunately, while he understands how the frontend engineers feel, Miguel is not discouraged and is excited to rise to the challenge! He discusses what happened with Dani from the frontend team:

![](https://drek4537l1klr.cloudfront.net/wilson3/Figures/09-08.png)

Miguel and Dani work together to be really clear about what went wrong before they jump to any conclusions about the solution. They boil it down to three main problems with the current process that is used for the Map Search service:

-  There is no way to tell the difference between releases of the service.
-  There is no way for the frontend team to control which release it’s using.
-  There is no automated way to communicate what has changed between releases.

These three problems can be boiled down to one major underlying problem: the Map Search service isn’t versioning its releases at all! You may have already noticed this when looking at the build process Julia outlined and the build script Miguel created:

```bash
#!/usr/bin/env sh
set -xe

cd "$(dirname "$0")"

docker build --tag top-dog-maps/map-search . #1
docker push top-dog-maps/map-search
#1 Every release builds and pushes an image with exactly the same name.
```

Every release overwrites the previous one! This means that only one version of the Map Search service is ever available (the latest one), leading to the three problems Miguel and Dani have identified.

## [](/book/grokking-continuous-delivery/chapter-9/)[](/book/grokking-continuous-delivery/chapter-9/)Semantic versioning

[](/book/grokking-continuous-delivery/chapter-9/)To avoid causing[](/book/grokking-continuous-delivery/chapter-9/)[](/book/grokking-continuous-delivery/chapter-9/)[](/book/grokking-continuous-delivery/chapter-9/) future outages and frustration, the map search team needs to let the frontend team control which version of the Map Search service is being used, and needs to communicate the differences between the versions.

At a bare minimum, the map search team needs to be producing more than one version of the service. The release process can’t just overwrite the previous release; it needs to create a new one and allow for the previous one to still be available for use.

A popular standard for versioning software is to use *semantic versioning*. This standard defines a way of assigning versions to your software such that you can communicate at a high level what has changed between versions. Semantic versioning uses a string version made up of three numbers separated by periods: *`MAJOR`*, *`MINOR`*, and *`PATCH`*:

```
MAJOR.MINOR.PATCH
```

-  The major version is *bumped*[](/book/grokking-continuous-delivery/chapter-9/) (incremented) when non-backward-compatible changes are made.
-  The minor version is bumped when new backward-compatible features are added.
-  The patch version is bumped when backward-compatible fixes are added.

Semantic versioning allows for even more labels and metadata to be included in the version if needed; see the semantic versioning specification at [https://semver.org/](https://semver.org/)

![](https://drek4537l1klr.cloudfront.net/wilson3/Figures/09-09.png)

#####  Vocab time

*Backward-compatible* changes[](/book/grokking-continuous-delivery/chapter-9/) are changes that can be used without the consumer needing to make any updates. *Backward-incompatible* changes[](/book/grokking-continuous-delivery/chapter-9/) are the opposite: the consumer of the software will need to make changes in the way they are using it, or risk bugs and outages. Changing the signature of the search method was a backward-incompatible change. This change could have been backward compatible if the team had added a new method instead of altering the existing signature. Minimizing backward-incompatible changes as much as possible makes life easier for the consumers of your software.

## [](/book/grokking-continuous-delivery/chapter-9/)[](/book/grokking-continuous-delivery/chapter-9/)The importance of being versioned

[](/book/grokking-continuous-delivery/chapter-9/)For the map search[](/book/grokking-continuous-delivery/chapter-9/)[](/book/grokking-continuous-delivery/chapter-9/)[](/book/grokking-continuous-delivery/chapter-9/) team to adopt semantic versioning, it will need to stop overwriting the previous release each time it makes a new one, and instead identify each release with a unique semantic version. Miguel updates the build and push lines of build.sh to look like this:

```bash
docker build --tag top-dog-maps/map-search:$VERSION . #1
docker push top-dog-maps/map-search:$VERSION
#1 The build script now tags the built image with a semantic version provided via the $VERSION environment variable.
```

With this change, the map search team has addressed the three problems Miguel and Dani identified:

-  Previously, there was no way to tell the difference between releases of the service, but now each release will be identified by a different unique semantic version.
-  Instead of having no way to control which release it’s using, the frontend team can explicitly specify the version it wants to use when deploying.
-  The semantic version will now provide high-level information about what has changed between versions. By looking at whether the major, minor, or patch version has been bumped, the frontend team will know whether the release is just for bug fixes (a patch bump), contains new features (a minor bump), or contains backward-incompatible changes (a major bump).

#####  Takeaway

Versioning your software with a clear, consistent versioning scheme such as semantic versioning gives consumers of your software the control and information they need to allow them to not be negatively impacted by changes you make.

##### Even with semantic versioning, you still need release notes

The semantic version says at a high level the kind of changes to expect, but the consumer of your software will likely want more information (i.e., what exactly changed: what bugs were fixed, what new features were added, and what backward-incompatible changes were made). This is where *release notes* come in.

Release notes accompany a release and list all the detailed changes that consumers need to know about. These are especially important because the reality is that even if the major version isn’t bumped, backward-incompatible changes still sneak in. Sometimes this is just a mistake, but often it will be because it’s very hard to predict how some changes will impact consumers of the software (stated in Hyrum’s law as “all observable behaviors of your system will be depended on by somebody,” [https://www.hyrumslaw.com/](https://www.hyrumslaw.com/)). Release note creation can be automated from commit messages and PR descriptions, but I won’t go into any more detail about them here.

#####  Including the version in the build

[](/book/grokking-continuous-delivery/chapter-9/)Looking at Miguel’s[](/book/grokking-continuous-delivery/chapter-9/)[](/book/grokking-continuous-delivery/chapter-9/)[](/book/grokking-continuous-delivery/chapter-9/) updates to the build script, you might wonder where the value of `$VERSION` is actually going to come from:

```bash
#!/usr/bin/env sh
set -xe

cd "$(dirname "$0")"

docker build --tag top-dog-maps/map-search:$VERSION .
docker push top-dog-maps/map-search:$VERSION
```

One popular approach is to get the version from a Git tag that contains the semantic version. When using this approach, you can configure your automation to be triggered by the act of adding the tag. For example, using GitHub Actions, you can use a triggering syntax like this:

```
on:
  push:
    tags:
      - ‘*’ #1
```

And inside the steps, the value of the tag that triggered the push can be obtained from what GitHub actions calls the *context*: for example, when triggered by the tag `v0.0.1`, the value of `${{` `github.ref` `}}` will be `refs/tags/v0.0.1`. (See the GitHub Actions docs at [https://docs.github.com/en/actions](https://docs.github.com/en/actions) for more.)

However, if Miguel were to take this approach, he would no longer be releasing continuously; he’d be releasing only when a tag is added to the repo. One way that he could release continually *and* use semantic versioning would be to store the current version in a file in the repo, and require that every commit with a code change bumps the value. This would mean updating his build pipeline to first parse the version out of the file in the repo, and then pass that value to the build script:

![](https://drek4537l1klr.cloudfront.net/wilson3/Figures/09-10.png)

Miguel would likely want to make the pipeline a bit more complicated than that. Sometimes folks might forget to bump the version number, so the pipeline should fail when that happens. Also, if no user-facing changes occur (for example, if a change updates only a unit test or a developer doc), a new version shouldn’t be created. That would look something like this:

![](https://drek4537l1klr.cloudfront.net/wilson3/Figures/09-11.png)

## [](/book/grokking-continuous-delivery/chapter-9/)[](/book/grokking-continuous-delivery/chapter-9/)Another outage!

[](/book/grokking-continuous-delivery/chapter-9/)Just when Miguel[](/book/grokking-continuous-delivery/chapter-9/)[](/book/grokking-continuous-delivery/chapter-9/) and Dani finish working hard to repair the tension between their two teams by giving the frontend team control over when and how to consume updates from the map search team, another production outage happens.

You’ll find more on rollbacks (and other techniques for safe deployments) in chapter 10.

Investigation into the outage reveals a bug in the Map Search service itself. Fortunately, now that the Map Search service is versioned, the frontend team is able to quickly roll back to a previous working version of the service. The frontend team reports the issue to the map search team and leaves them to figure out what went wrong. (Fortunately, thanks to the mitigation being so fast and easy for the frontend team, the relationship between the teams isn’t harmed!)

#####  Vocab time

*Third-party* software[](/book/grokking-continuous-delivery/chapter-9/) is software that was created outside of the company itself, e.g., by another company or an open source project.

Miguel helps debug the issue and is surprised to discover that the problem is a change to a third-party library (querytosql) that the Map Search service depends on for executing search queries in SQL.

![](https://drek4537l1klr.cloudfront.net/wilson3/Figures/09-12.png)

The library has changed the interface of one of its methods in a seemingly harmless way, but unfortunately it’s enough to cause the Map Search service to not work properly. The function being called as part of the search functionality in the querytosql lib previously looked like this:

```
def execute(query, db_host, db_username, db_password, db_name):
```

In the latest version, the authors of querytosql realized that they could clean up the function signature by creating an object to hold all the DB connection info, updating the signature to look a lot simpler:

```
def execute(query, db_conn): #1
```

The new code is much cleaner, but unfortunately this is a backward-incompatible change, so all of the uses of the `execute` function in the Map Search service are now broken! The team needs to update every instance where it called `execute` to use the new interface in order to be compatible with these changes.

## [](/book/grokking-continuous-delivery/chapter-9/)[](/book/grokking-continuous-delivery/chapter-9/)Build-time dependency bugs

[](/book/grokking-continuous-delivery/chapter-9/)The irony is not[](/book/grokking-continuous-delivery/chapter-9/)[](/book/grokking-continuous-delivery/chapter-9/) lost on Miguel that the Map Search service has been bitten by almost exactly the problem that his team members recently caused for the frontend service when they updated the signature of their search method! But Miguel is a bit confused: why wasn’t this issue caught by tests executed as part of CI?

You may remember from chapter 7 that bugs can sneak in at multiple points—and one of them is at build time, if the dependencies change:

![](https://drek4537l1klr.cloudfront.net/wilson3/Figures/09-13.png)

It turns out that this was exactly what happened to the Map Search service:

![](https://drek4537l1klr.cloudfront.net/wilson3/Figures/09-14.png)

In chapter 7, the team encountering this problem worked around it by introducing periodic builds to catch changes in dependencies. But even with periodic builds, a window still remains in which dependency changes can sneak in (i.e., between a periodic build and a release). While mitigation is to use the periodic build to generate release artifacts, the best way to be sure you aren’t bitten by changes to your dependencies is to explicitly *pin* your software to specific versions of your dependencies.

##### That change was backward incompatible—why didn’t querytosql bump their major version?

That’s a good point! The reality is that a lot of variation exists in how strictly projects will follow and interpret strict semantic versioning. Unfortunately, seeing this kind of change without an accompanying major version bump is pretty common. That’s another reason it’s a good practice to explicitly pin your dependencies, so you can control when you take in updates and keep an eye out for sneaky backward-incompatible changes!

## [](/book/grokking-continuous-delivery/chapter-9/)[](/book/grokking-continuous-delivery/chapter-9/)Pinning dependencies

[](/book/grokking-continuous-delivery/chapter-9/)The best way[](/book/grokking-continuous-delivery/chapter-9/)[](/book/grokking-continuous-delivery/chapter-9/) to minimize bugs and other unexpected behavior caused by changes to dependencies is to use the same approach that Miguel and Dani developed for the frontend team. In the same way that the frontend team now explicitly relies on a specific version of the Map Search service, the service needs to be explicit about the versions of dependencies that it relies on. Here are the contents of requirements.txt for the Map Search service:

```
beautifulsoup4 #1
pytest > 6.0.0 #1
querytosql     #1
```

Since no requirements are specified for querytosql, any version will do. That’s why, when the most recent build executed for the map search container image, the latest version was pulled in. Once Miguel realizes what has happened, he quickly updates requirements.txt to specify explicit versions to pin to:

```
beautifulsoup4 == 4.10.0
pytest == 6.2.5
querytosql == 1.3.2 #1
```

Now the map search team members can control when they consume updates to the libraries they depend on, and build securely without worrying about surprise functionality changes from their dependencies!

##### What if I’m using a Pipfile instead? Or not using Python at all?

Regardless of the languages or tools that you are using, pinning your dependencies to a specific version is your safest option. Pipfiles also support a syntax for specifying versions for your dependencies, and the same holds true for most languages and tools. If a language or tool doesn’t give you this control, consider that a strike against it and find an alternative if you can (or build your own tooling around it).

##### Why pin the patch version? Shouldn’t I pull in bug fixes automatically?

Instead of pinning to an explicit version, for some tools and languages you could specify a range of versions. For example, in requirements.txt you could specify `querytosql == 1.3.*` to indicate that all any patch releases of version 1.3 are allowed. However, not all tools and languages will support syntax like this. Even bug fixes are changes in functionality (another instance of Hyrum’s law!). Being in control of when you consume all changes makes your built artifacts more stable.

## [](/book/grokking-continuous-delivery/chapter-9/)[](/book/grokking-continuous-delivery/chapter-9/)Version pinning alone isn’t a guarantee

[](/book/grokking-continuous-delivery/chapter-9/)It turns out that with most languages and tools, pinning to a specific version isn’t a rock-solid guarantee that changes won’t happen in the library you are using between two points in time. This may sound impossible, but the reason is that it’s usually possible to overwrite a previous version of a lib, image, and so forth, with a totally new one that uses the same version. This is because versions are usually treated like tags, and there is nothing to prevent changing what that tag points at. For example, it’s possible that at some point querytosql could decide to overwrite its 1.3.2 version with a new one:

![](https://drek4537l1klr.cloudfront.net/wilson3/Figures/09-15.png)

Overwriting already-released versions like this is a bad practice because it negates the entire point of using versions (i.e., giving your consumers control and information about changes), but it does happen from time to time (often when someone with good intentions wants to get a fix out as quickly and easily as possible before anyone picks up the version with the bug).

But all hope is not lost! It’s possible to pin dependencies with *even more control* than just specifying the version number, and the key to that is to additionally specify what you expect the *hash*[](/book/grokking-continuous-delivery/chapter-9/) of the package contents to be. This way, you can make sure that you don’t accidentally consume changes you aren’t prepared for—if the dependency’s contents change, so will the hash.

#####  Vocab time

The term *hash*[](/book/grokking-continuous-delivery/chapter-9/) here is shorthand for the output of a cryptographic hashing function applied to data. In the context of builds and dependencies, we’re talking about applying a hash function to the contents of a software artifact. The idea is that the hash produced (i.e., the result of applying the hashing function to the artifact) will always be the same, so if the contents of the artifact change, so will the hash. Examples of hashing functions you might encounter are `md5` and various versions of `sha` such as `sha256`.

## [](/book/grokking-continuous-delivery/chapter-9/)[](/book/grokking-continuous-delivery/chapter-9/)Pinning to hashes

[](/book/grokking-continuous-delivery/chapter-9/)Miguel wants[](/book/grokking-continuous-delivery/chapter-9/)[](/book/grokking-continuous-delivery/chapter-9/) to be absolutely sure that the map search team image is reliable and that none of its dependencies will change unexpectedly, so he makes one more update to requirements.txt to include the expected hashes of the dependencies:

```
beautifulsoup4 == 4.10.0 \
  --hash=sha256:9a315ce70049920ea4572a4055bc4bd700c940521d36fc858205ad4fcde149bf
pytest == 6.2.5 \
  --hash=sha256:7310f8d27bc79ced999e760ca304d69f6ba6c6649c0b60fb0e04a4a77cacc134
querytosql == 1.3.2 \
  --hash=sha256:abcd1234abcd1234abcd1234abcd1234abcd1234abcd1234abcd1234abcd1234 #1
...
```

By pinning to the hash of the package, the team is using *unambiguous identifiers*[](/book/grokking-continuous-delivery/chapter-9/)—identifiers that cannot be used to identify more than one thing. Versions and tags are ambiguous because they can be reused or changed to point at different data.

##### Using unambiguous identifiers with other languages and tools

It’s reasonable to expect whatever language or tools you’re using to also support specifying the expected hashes of the artifacts you are using. In fact, one of the big wins of using container images is that the contents are hashed automatically and the hashes can be used when pulling and running images.

#####  Takeaway

To be absolutely sure your dependencies (and dependencies of your dependencies) don’t change out from under you and introduce bugs and unwanted changes in behavior, explicitly pin them not only to just specific versions, but also to the hashes of the specific versions you want to use.

#####  Monorepos and version pinning

[](/book/grokking-continuous-delivery/chapter-9/)Another way[](/book/grokking-continuous-delivery/chapter-9/)[](/book/grokking-continuous-delivery/chapter-9/) of looking at how the bug between the Map Search service and the querytosql library came about is that the code for the service and for the library were stored in separate repositories:

![](https://drek4537l1klr.cloudfront.net/wilson3/Figures/09-16.png)

This was a problem because it meant that at build time, the Map Search service image would be built with whatever was the current state of the querytosql repo. The team fixed this problem by always consistently pulling code from the querytosql repo from the same tagged commit:

![](https://drek4537l1klr.cloudfront.net/wilson3/Figures/09-17.png)

An alternative approach is to avoid pulling this code at build time at all by copying it into the Map Search service repo:

![](https://drek4537l1klr.cloudfront.net/wilson3/Figures/09-18.png)

This approach ensures that the same version of querytosql will always be used at build time, because at that point nothing is fetched.

This idea can be taken even further. In chapter 3, I briefly mentioned the concept of a *monorepo*: one repo that stores all of the source code, not just for a project but for an entire company. If Top Dog Maps used a monorepo, all of the code for the Map Search service, the frontend, and all of the dependencies would be stored and versioned within one repository.

This approach can reduce the need for explicit versioning in some cases, but it doesn’t always do away with it entirely (for example, the Frontend service actually depends on an image of the Map Search service, not the source code, so that image itself still needs to be versioned). This can also introduce additional complications (most tools are not created with monorepos in mind), but it can also reduce a lot of uncertainty (i.e., you can always see exactly the source code in use) and make some things easier (e.g., wide sweeping changes across all projects).

## [](/book/grokking-continuous-delivery/chapter-9/)Conclusion

[](/book/grokking-continuous-delivery/chapter-9/)Even if a build process works initially for a project, it’s a good idea to regularly revisit it and see if anything needs to be improved. Early in a project, shortcuts like relying on someone to manually build an artifact might make perfect sense, but may not stand the test of time. Fortunately, as Miguel found at Top Dog Maps, it’s relatively simple to move from a manual process to an automated one and gain a significantly elevated level of confidence. Miguel also discovered firsthand the importance of using good build practices to make life easier for consumers of his software, and how to protect against issues introduced by the software he depends on.

## [](/book/grokking-continuous-delivery/chapter-9/)Summary

-  Secure and reliable builds are automated and follow the SLSA build requirements: use build as code (just a fancy subset of config as code), run on a CD service, and run in ephemeral environments.
-  Versioning software with a consistent versioning scheme such as semantic versioning is a great way to give users of your software control and information about changes between versions.
-  Protect against unwanted changes in your dependencies, and integrate with them at your leisure, by pinning them not just to explicit versions but also to hashes of explicit versions.

## [](/book/grokking-continuous-delivery/chapter-9/)Up next . . .

Automated (and maybe even continuous) releasing is great, but if you’re running a service, you may be wondering about how to deploy those newly built artifacts. In the next chapter, we’ll look at how to include deployment as a phase in your CD pipelines by using methodologies that make deployments easy and stress free.

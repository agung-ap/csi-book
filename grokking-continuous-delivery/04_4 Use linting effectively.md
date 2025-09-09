# 4 [](/book/grokking-continuous-delivery/chapter-4/)[](/book/grokking-continuous-delivery/chapter-4/)Use linting effectively

### In this chapter

- identifying the types of problems linting can find in your code: bugs, errors, and style problems
- aiming for the ideal of zero problems identified but tempering this against the reality of legacy codebases
- linting large existing codebases by approaching the problem iteratively
- weighing the risks of introducing new bugs against the benefits of addressing problems

Let’s get started[](/book/grokking-continuous-delivery/chapter-4/) building your pipelines! Linting is a key component to the CI portion of your pipeline: it allows you to identify and flag known issues and coding standard violations, reducing bugs in your code and making it easier to maintain.

## [](/book/grokking-continuous-delivery/chapter-4/)[](/book/grokking-continuous-delivery/chapter-4/)Becky and Super Game Console

[](/book/grokking-continuous-delivery/chapter-4/)Becky just joined[](/book/grokking-continuous-delivery/chapter-4/)[](/book/grokking-continuous-delivery/chapter-4/) the team at Super Game Console and is really excited! Super Game Console, a video game console that runs simple Python games, is very popular. The best feature is its huge library of Python games, to which anyone can contribute.

![](https://drek4537l1klr.cloudfront.net/wilson3/Figures/04-01.png)

The folks at Super Game Console have a submission process that allows everyone from the hobbyist to the professional to sign up as a developer and submit their own games.

![](https://drek4537l1klr.cloudfront.net/wilson3/Figures/04-02.png)

But these games have a *lot* of bugs, and it is starting to become a problem. Becky and Ramon, who has been on the team for a while now, have been working their way through the massive backlog of game bugs. Becky has noticed a few things:

-  Some of the games won't even compile! And a lot of the other bugs are caused by simple mistakes like trying to use variables that aren’t initialized.
-  Lots of mistakes do not actually cause bugs but get in the way of Becky’s work (for example, unused variables).
-  The code in every single game looks different from the one before it. The inconsistent style makes it hard for her to debug.

## [](/book/grokking-continuous-delivery/chapter-4/)[](/book/grokking-continuous-delivery/chapter-4/)Linting to the rescue!

[](/book/grokking-continuous-delivery/chapter-4/)Looking at the types[](/book/grokking-continuous-delivery/chapter-4/) of problems causing the bugs she and Ramon have been fixing, they remind Becky a lot of the kinds of problems that linters catch.

![](https://drek4537l1klr.cloudfront.net/wilson3/Figures/04-03.png)

What is *linting* anyway? Well, it’s the action of finding lint, using a linter! And what’s lint? You might think of the lint that accumulates in your clothes dryer.

![](https://drek4537l1klr.cloudfront.net/wilson3/Figures/04-04.png)

By themselves, the individual fibers don’t cause any problems, but when they build up over time, they can interfere with the effective functioning of your dryer. Eventually, if they are neglected for too long, the lint builds up, and the hot air in the dryer eventually sets it on fire!

![](https://drek4537l1klr.cloudfront.net/wilson3/Figures/04-05.png)

And it’s the same for programming errors and inconsistencies that may seem minor: they build up over time. Just as in Becky and Ramon’s case, the code they are looking at is inconsistent and full of simple mistakes. These problems are not only causing bugs, but also getting in the way of maintaining the code effectively.

## [](/book/grokking-continuous-delivery/chapter-4/)[](/book/grokking-continuous-delivery/chapter-4/)The lowdown on linting

[](/book/grokking-continuous-delivery/chapter-4/)Linters come in all different shapes and sizes. Since they analyze and interact with code, they are usually specific to a particular language (e.g., Pylint for Python). Some linters apply generically to anything you might be doing in the language, and some are specific to particular domains and tools—for example, linters for working effectively with HTTP libraries.

We’ll be focusing on linters that apply generically to the language you are using. Different linters will categorize the problems they raise differently, but they can all be viewed as falling into one of three buckets. Let’s take a look at the problems Becky noticed and how they demonstrate the three kinds of problems:

-  Some of the games won't even compile! And a lot of the other bugs are caused by simple mistakes like trying to use variables that aren’t initialized. (a)
-  Lots of mistakes do not actually cause bugs but get in the way of Becky’s work (for example, unused variables). (b)
-  The code in every single game looks different from the one before it! The inconsistent style makes it hard for her to debug. (c)

(a) Bugs: code misuses that lead to behavior you probably don’t want!

(b) Errors: code misuses that do not affect behavior

(c) Style violations: inconsistent code style decisions and code smells

##### What’s the difference between static analysis and linting?

Using *static analysis* lets you analyze your code without executing it. In the next chapter, we’ll talk about tests, which are a kind of *dynamic analysis* because they require executing your code. *Linting* is a kind of static analysis; the term *static analysis* can encompass many ways of analyzing code. In the context of continuous delivery (CD[](/book/grokking-continuous-delivery/chapter-4/)), most of the static analysis we’ll be discussing is done with linters. Otherwise the distinction isn’t that important. The name *linter* comes from the 1978 tool of the same name, created by Bell Labs. Most of the time, especially in the context of CD, the terms *static analysis* and *linting* can be used interchangeably, but some forms of static analysis go beyond what linters can do.

## [](/book/grokking-continuous-delivery/chapter-4/)[](/book/grokking-continuous-delivery/chapter-4/)The tale of Pylint and many, many issues

[](/book/grokking-continuous-delivery/chapter-4/)Since the games[](/book/grokking-continuous-delivery/chapter-4/)[](/book/grokking-continuous-delivery/chapter-4/) for Super Game Console are all in Python, Becky and Ramon decide that using the tool Pylint is a good place to start. This is the layout of the Super Game Console codebase:

```
console/
docs/
games/   #1
test/
setup.py
LICENSE
README.md
requirements.txt
```

The games folder has thousands of games in it. Becky is excited to see what Pylint can tell them about all these games. She and Ramon watch eagerly as Becky types in the command and presses Enter . . .

```bash
$ pylint games
```

And they are rewarded with screen after screen filled with warnings and errors! This is a small sample of what they see:

```
games/bridge.py:40:0: W0311: Bad indentation. Found 2 spaces, expected 4 (bad-indentation)
games/bridge.py:41:0: W0311: Bad indentation. Found 4 spaces, expected 8 (bad-indentation)
games/bridge.py:46:0: W0311: Bad indentation. Found 2 spaces, expected 4 (bad-indentation)
games/bridge.py:1:0: C0114: Missing module docstring (missing-module-docstring)
games/bridge.py:3:0: C0116: Missing function or method docstring (missing-function-docstring)
games/bridge.py:13:15: E0601: Using variable 'board' before assignment (used-before-assignment)
games/bridge.py:8:2: W0612: Unused variable 'cards' (unused-variable)
games/bridge.py:23:0: C0103: Argument name "x" doesn’t conform to snake_case naming style (invalid-name)
games/bridge.py:23:0: C0116: Missing function or method docstring (missing-function-docstring)
games/bridge.py:26:0: C0115: Missing class docstring (missing-class-docstring)
games/bridge.py:30:2: C0116: Missing function or method docstring (missing-function-docstring)
games/bridge.py:30:2: R0201: Method could be a function (no-self-use)
games/bridge.py:26:0: R0903: Too few public methods (1/2) (too-few-public-methods)
games/snakes.py:30:4: C0103: Method name "do_POST" doesn’t conform to snake_case naming style (invalid-name)
games/snakes.py:30:4: C0116: Missing function or method docstring (missing-function-docstring)
games/snakes.py:39:4: C0103: Constant name "httpd" doesn’t conform to UPPER_CASE naming style (invalid-name)
games/snakes.py:2:0: W0611: Unused import logging (unused-import)
games/snakes.py:3:0: W0611: Unused argv imported from sys (unused-import)
```

##### What about other languages and linters?

Becky and Ramon are using Python and Pylint, but the same principles apply regardless of the language or linter you are using. All good linters should give you the same flexibility of configuration that we’ll demonstrate with Pylint and should catch the same variety of issues.

## [](/book/grokking-continuous-delivery/chapter-4/)[](/book/grokking-continuous-delivery/chapter-4/)Legacy code: Using a systematic approach

![](https://drek4537l1klr.cloudfront.net/wilson3/Figures/04-06.png)

[](/book/grokking-continuous-delivery/chapter-4/)The first time you[](/book/grokking-continuous-delivery/chapter-4/)[](/book/grokking-continuous-delivery/chapter-4/) run a linting tool against an existing codebase, the number of issues it finds can be overwhelming! (In a few pages, we’ll talk about what to do if you don’t have to deal with a huge existing codebase.)

Fortunately, Becky has dealt with applying linting to legacy codebases before and has a systematic approach that she and Ramon can use to both speed things up and use their time effectively:

1.  Before doing anything else, they need to configure the linting tools. The options that Pylint is applying out of the box might not make sense for Super Game Console.
1.  Measure a baseline and keep measuring. Becky and Ramon don’t necessarily need to fix every single issue; if all they do is make sure the number of issues goes down over time, that’s time well spent!
1.  Once they have the measurements, every time a developer submits a new game, Becky and Ramon can measure again, and stop the game from being submitted if it introduces more problems. This way, the number won’t ever go up!
1.  At this point, Becky and Ramon have ensured that things won’t get any worse; with that in place, they can start tackling the existing problems. Becky knows that not all linting problems are created equal, so she and Ramon will be dividing and conquering so that they can make the most effective use of their valuable time.

![](https://drek4537l1klr.cloudfront.net/wilson3/Figures/04-07.png)

The key to Becky’s plan is that she knows that they don’t have to fix everything: just by preventing new problems from getting in, they’ve already improved things. And the truth is, not everything has to be fixed—or even should be.

## [](/book/grokking-continuous-delivery/chapter-4/)[](/book/grokking-continuous-delivery/chapter-4/)Step 1: Configure against coding standards

[](/book/grokking-continuous-delivery/chapter-4/)Ramon has been[](/book/grokking-continuous-delivery/chapter-4/)[](/book/grokking-continuous-delivery/chapter-4/) looking through some of the errors Pylint has been spitting out and notices that it’s complaining they should be indenting with four spaces instead of two:

```
bridge.py:2:0: W0311: Bad indentation. Found 2 spaces, expected 4 (bad-indentation)
```

![](https://drek4537l1klr.cloudfront.net/wilson3/Figures/04-08.png)

##### Already familiar with configuring linting?

Then you can probably skip this! Read this page if you’ve never configured a linting tool before.

This is often the case when coding standards aren’t backed up by automation, so Becky isn’t surprised. But the great news is that the (currently ignored) coding standards have most of the information that Becky and Ramon need, information like this:

-  Indent with tabs or spaces? If spaces, how many?
-  Are variables named with `snake_case` or `camelCase`?
-  Is there a maximum line length? What is it?

##### Features to look for

When evaluating linting tools, expect them to be configurable. Not all codebases and teams are the same, so it’s important to be able to tune your linter. Linters need to work for you, not the other way around!

The answers to these questions can be fed into Pylint as configuation options, into a file usually called .pylintrc.

Becky didn’t find everything she needed in the existing coding style, so she and Ramon had to make some decisions themselves. They invited the rest of the team at Super Game Console to give input as well, but no one could agree on some items; in the end, Becky and Ramon just had to make a decision. When in doubt, they leaned on Python language idioms, which mostly meant sticking with Pylint’s defaults.

##### Automation is essential to maintain coding standards

Without automation, it’s up to individual engineers to remember to apply coding standards, and it’s up to reviewers to remember to review for them. People are people: we’re going to miss stuff! But machines aren’t: linters let us automate coding standards so no one has to worry about them.

## [](/book/grokking-continuous-delivery/chapter-4/)[](/book/grokking-continuous-delivery/chapter-4/)Step 2: Establish a baseline

[](/book/grokking-continuous-delivery/chapter-4/)Now that Becky[](/book/grokking-continuous-delivery/chapter-4/)[](/book/grokking-continuous-delivery/chapter-4/) and Ramon have tweaked Pylint according to the existing and newly established coding standard, they have slightly fewer errors, but still in the tens of thousands.

![](https://drek4537l1klr.cloudfront.net/wilson3/Figures/04-09.png)

Becky knows that even if she and Ramon left the codebase exactly the way it is, by just reporting on the number of issues and observing it over time, this can help motivate the team to decrease the number of errors. And in the next step, they’ll use this data to stop the number of errors from going up.

Becky writes a script that runs Pylint and counts the number of issues it reports. She creates a pipeline that runs every night and publishes this data to blob storage. After a week, she collects the data and creates this graph showing the number of issues:

![](https://drek4537l1klr.cloudfront.net/wilson3/Figures/04-10.png)

The number keeps going up because even as Becky and Ramon work on this, developers are eagerly submitting more games and updates to Super Game Console. Each new game and new update has the potential to include a new issue.

##### Do I need to build this myself?

Yes, in this case, you probably will. Becky had to write the tool herself to measure the baseline number of issues and track them over time. If you want to do this, there’s a good chance you’ll need to build the tool yourself. This will depend on the language you are using and the tools available; you also can sign up for services that will track this information for you over time. Most CD systems do not offer this functionality because it is so language and domain specific.

## [](/book/grokking-continuous-delivery/chapter-4/)[](/book/grokking-continuous-delivery/chapter-4/)Step 3: Enforce at submission time

[](/book/grokking-continuous-delivery/chapter-4/)Ramon notices that[](/book/grokking-continuous-delivery/chapter-4/)[](/book/grokking-continuous-delivery/chapter-4/) as submissions come in, the number of issues Pylint finds is going up, but Becky has a solution for that: block submissions that increase the number of issues. This means enforcing a new rule on each PR:

**Every PR must reduce the number of linting issues or leave it the same**.

##### What’s a PR again?

*PR* stands for *pull request*, a way to propose and review changes to a codebase. See chapter 3 for more.

Becky creates this script to add to the pipeline that Super Game Console runs against all PRs:

```bash
# when the pipeline runs, it will pass paths to the files
  # that changed in the PR as arguments
  paths_to_changes = get_arguments()

  # run the linting against the files that changed to see
  # how many problems are found
  problems = run_lint(paths_to_changes)
  
  # becky created a pipeline that runs every night and
  # writes the number of observed issues to a blob store;
  # here the lint script will download that data
  known_problems = get_known_problems(paths_to_changes)

  # compare the number of problems seen in the changed code
  # to the number of problems seen last night
  if len(problems) >  len(known_problems):
    # the PR should not be merged if it increases the
    # number of linting issues
    fail("number of lint issues increased from {} to {}".format(
      len(known_problems), len(problems)))
```

##### Shouldn’t you look at more than just the number of issues?

It’s true that just comparing the number of issues glosses over some things; for example, the changes could fix one issue but introduce another. But the really important thing for this situation is the overall trend over time, and not so much the individual issues.

The next step is for Becky to add this to the existing pipeline that runs against every PR.

![](https://drek4537l1klr.cloudfront.net/wilson3/Figures/04-11.png)

##### Greenfield or small codebase

We’ll talk about this a bit more in a few pages, but if you’re working with a small or brand-new codebase, you can skip measuring the baseline and just clean up everything at once. Then, instead of adding a check to your pipeline to ensure that the number doesn’t go up, add a check that fails if linting finds any problems at all.

## [](/book/grokking-continuous-delivery/chapter-4/)[](/book/grokking-continuous-delivery/chapter-4/)Adding enforcement to the pipeline

[](/book/grokking-continuous-delivery/chapter-4/)Becky wants her[](/book/grokking-continuous-delivery/chapter-4/)[](/book/grokking-continuous-delivery/chapter-4/) new check to be run every time a developer submits a new game or an update to an existing game. Super Game Console accepts new games as PRs to its GitHub repository. The game company already makes it possible for developers to include tests with their games, and they run those tests on each PR. This is what the pipeline looks like before Becky’s change:

![](https://drek4537l1klr.cloudfront.net/wilson3/Figures/04-12.png)

Becky wants to add her new check to the pipeline that Super Game Console runs against every PR.

![](https://drek4537l1klr.cloudfront.net/wilson3/Figures/04-13.png)

Now, whenever a developer opens a PR to add or change a Super Game Console game, Becky’s script will run. If this PR increases the number of linting issues in the project, the pipeline will stop. The developer must fix this before the pipeline will continue building images.

## [](/book/grokking-continuous-delivery/chapter-4/)[](/book/grokking-continuous-delivery/chapter-4/)Step 4: Divide and conquer

![](https://drek4537l1klr.cloudfront.net/wilson3/Figures/04-14.png)

[](/book/grokking-continuous-delivery/chapter-4/)Becky and Ramon[](/book/grokking-continuous-delivery/chapter-4/) have stopped the problem from getting worse. Now the pressure is off, and they are free to start tackling the existing issues, confident that more won’t be added. It’s time to start fixing issues! But Ramon quickly runs into a problem . . .

![](https://drek4537l1klr.cloudfront.net/wilson3/Figures/04-15.png)

Making *any* changes, including changes that fix linting issues, has the risk of introducing more problems. So why do we do it? Because the reward outweighs the risk! And it makes sense to do it only when that’s the case. Let’s take a look at the rewards and the risks when we fix linting problems:

| **Rewards** | **Risks** |
| --- | --- |
| Linting can catch bugs. | Making changes can introduce new bugs. |
| Linting helps remove distracting errors. | Fixing linting issues takes time. |
| Consistent code is easier to maintain. |  |

We can determine some interesting things from this list. The first reward is about catching bugs, which we need to weigh against the first risk of introducing new bugs.

Ramon introduced a new bug into a game that didn’t have any open reported bugs. Was it worth the risk of adding a bug to a game that, as far as everyone could tell, was working just fine? Maybe not!

The other two rewards are relevant only when the code is being changed. If you don’t ever need to change the code, it doesn’t matter how many distracting errors it has or how inconsistent it is.

Ramon was updating a game that hasn’t had a change in two years. Was it worth taking the time and risking introducing new bugs into a game that wasn’t being updated? Probably not! He should find a way to isolate these games so he can avoid wasting time on them.

## [](/book/grokking-continuous-delivery/chapter-4/)[](/book/grokking-continuous-delivery/chapter-4/)Isolation: Not everything should be fixed

| **Rewards** |
| --- |
| Linting can catch bugs. (a) |
| Linting helps remove distracting errors. (b) |
| Consistent code is easier to maintain. (c) |

(a) If no one is reporting any bugs, the return on investment can be small.

(b) There will always be bugs; the question is whether they are worth catching.

(c) These two rewards are relevant only if you expect to make changes to the code. If you’re never going to touch the code again, why spend the time and risk introducing new bugs?

[](/book/grokking-continuous-delivery/chapter-4/)Becky and Ramon[](/book/grokking-continuous-delivery/chapter-4/)[](/book/grokking-continuous-delivery/chapter-4/) look at all the games they have in their library, and they identify the ones that change the least. These are all more than a year old, and the developers have stopped updating them. They also look at the number of user-reported bugs with these games. They select the games that haven’t changed in more than a year and don’t have any open bugs, and move them into their own folder. Their codebase now looks like this:

```
.pylintrc  #1
console/
docs/
games/
  frozen/  #2
  ...
test/
setup.py
LICENSE
README.md
requirements.txt
```

Becky and Ramon update their .pylintrc to exclude the games in the frozen directory:

```
[MASTER]
ignore=games/frozen
```

## [](/book/grokking-continuous-delivery/chapter-4/)[](/book/grokking-continuous-delivery/chapter-4/)Enforcing isolation

![](https://drek4537l1klr.cloudfront.net/wilson3/Figures/04-18.png)

[](/book/grokking-continuous-delivery/chapter-4/)And to be extra[](/book/grokking-continuous-delivery/chapter-4/)[](/book/grokking-continuous-delivery/chapter-4/) safe, Becky creates a new script that makes sure that no one is making changes to the games in the frozen directory:

```bash
# when the pipeline runs, it will pass paths to the files
  # that changed in the PR as arguments
  paths_to_changes = get_arguments()

  # instead of hardcoding this script to look for changes
  # to games/frozen, load the ignored directories from
  # .pylintrc to make this check more general purpose
  ignored_dirs = get_ignored_dirs_from_Pylintrc()

  # check for any paths that are being changed that are in
  # the directories being ignored
  ignored_paths_with_changes = get_common_paths(
    paths_to_changes, ignored_dirs)

  if len(ignored_paths_with_changes) > 0:
    # the PR should not be merged if it
    # includes changes to ignored directories
    fail("linting checks are not run against {}, "
      "therefore changes are not allowed".format(
      ignored_paths_with_changes))
```

##### But what if you need to change a frozen game?

This error message should include guidance for what to do if you need to change a game. And the answer is that the submitter will need to then move the game out of the frozen folder and deal with all the linting issues that would undoubtedly be revealed as a result.

Next she adds it to the pipeline that runs against PRs:

![](https://drek4537l1klr.cloudfront.net/wilson3/Figures/04-19.png)

## [](/book/grokking-continuous-delivery/chapter-4/)[](/book/grokking-continuous-delivery/chapter-4/)Not all problems are created equal

[](/book/grokking-continuous-delivery/chapter-4/)Okay, *now* it is[](/book/grokking-continuous-delivery/chapter-4/) finally time to start fixing problems, right? Ramon dives right in, but two days later he’s feeling frustrated:

![](https://drek4537l1klr.cloudfront.net/wilson3/Figures/04-20.png)

Becky and Ramon want to focus on fixing the most impactful issues first. Let’s look again at the rewards and risks of fixing linting issues for some guidance:

| **Rewards** | **Risks** |
| --- | --- |
| Linting can catch bugs. | Making changes can introduce new bugs. |
| Linting helps remove distracting errors. | Fixing linting issues takes time. |
| Consistent code is easier to maintain. |  |

Ramon is running smack into the second risk: it’s taking a lot of time for him to fix all the issues. So Becky has a counterproposal: fix the most impactful issues first. That way, they can get the most value for the time they do spend, without having to fix absolutely everything.

So which issues should they tackle first? The linting rewards happen to correspond to different types of linting issues:

| **Rewards** |
| --- |
| Linting can catch bugs. (a) |
| Linting helps remove distracting errors. (b) |
| Consistent code is easier to maintain. (c) |

(a) Bugs

(b) Errors

(c) Style

## [](/book/grokking-continuous-delivery/chapter-4/)[](/book/grokking-continuous-delivery/chapter-4/)Types of linting issues

[](/book/grokking-continuous-delivery/chapter-4/)The types of[](/book/grokking-continuous-delivery/chapter-4/) issues that linters are able to find can fall into three buckets: bugs, errors, and style.

*Bugs*[](/book/grokking-continuous-delivery/chapter-4/) found by linting are common misuses of code that lead to undesirable behavior. For example:

-  Uninitialized variables
-  Formatting variable mismatches

*Errors*[](/book/grokking-continuous-delivery/chapter-4/) found by linting are common misuses of code that do not affect behavior but either cause performance problems or interfere with maintainability. For example:

-  Unused variables
-  Aliasing variables

And lastly, the *style* problems[](/book/grokking-continuous-delivery/chapter-4/) found by linters are inconsistent application of code-style decisions and code smells. For example:

-  Long function signatures
-  Inconsistent ordering in imports

While it would be great to fix all of these, if you had time to fix only one set of linting issues, which would you choose? Probably bugs, right? Makes sense, since these affect the behavior of your programs! And that’s what the hierarchy looks like:

| **Rewards** |
| --- |
| Linting can catch bugs. (a) (d) |
| Linting helps remove distracting errors. (b) (e) |
| Consistent code is easier to maintain. (c) (f) |

(a) Bugs

(b) Errors

(c) Style

(d) Deal with the style issues when and if you have time.

(e) These are mistakes, but less impactful than bugs. Fix these next.

(f) Fix these first!

## [](/book/grokking-continuous-delivery/chapter-4/)[](/book/grokking-continuous-delivery/chapter-4/)Bugs first, style later

[](/book/grokking-continuous-delivery/chapter-4/)Becky recommends[](/book/grokking-continuous-delivery/chapter-4/)[](/book/grokking-continuous-delivery/chapter-4/)[](/book/grokking-continuous-delivery/chapter-4/) to Ramon that they tackle the linting issues systematically. That way, if they need to switch to another project, they’ll know the time they spent fixing issues was well used. They might even decide to time-box their efforts: see how many issues they can fix in two weeks and then move on.

How can they tell which issues are which? Many linting tools categorize the issues they find. Let’s look again at some of the issues Pylint found:

```
games/bridge.py:46:0: W0311: Bad indentation. Found 2 spaces, expected 4 (bad-indentation)
games/bridge.py:1:0: C0114: Missing module docstring (missing-module-docstring))
games/bridge.py:13:15: E0601: Using variable 'board' before assignment (used-before-assignment)
games/bridge.py:8:2: W0612: Unused variable 'cards' (unused-variable)
games/bridge.py:30:2: R0201: Method could be a function (no-self-use)
games/bridge.py:26:0: R0903: Too few public methods (1/2) (too-few-public-methods)
games/snakes.py:30:4: C0103: Method name "do_POST" doesn’t conform to snake_case naming style (invalid-name)
```

Each issue has a letter and a number. Pylint recognizes four categories of issues: **`E`** is for *error*, which is the type we are calling *bugs*. **`W`** for *warning* is what we are calling *errors*. The last two, **`C`** for *convention* and **`R`** for *refactor**,* are what we are calling *style*.

Ramon creates a script and tracks the number of errors of each type as they work for the next week:

![](https://drek4537l1klr.cloudfront.net/wilson3/Figures/04-24.png)

The overall number of issues stays fairly high, but the number of bugs—the most important type of linting issue—is steadily decreasing!

## [](/book/grokking-continuous-delivery/chapter-4/)[](/book/grokking-continuous-delivery/chapter-4/)Jumping through the hoops

![](https://drek4537l1klr.cloudfront.net/wilson3/Figures/04-25.png)

[](/book/grokking-continuous-delivery/chapter-4/)It can be frustrating[](/book/grokking-continuous-delivery/chapter-4/)[](/book/grokking-continuous-delivery/chapter-4/) to think you’re done, just to encounter a whole new set of hoops to jump through. But the answer here is pretty simple: incorporate linters into your development process. How do you do this, and how do you make it easy for the developers you are working with? Take these two steps:

1.  Commit the configuration files for your linting alongside your code. Becky and Ramon have checked in the .pylintrc code they’re using right into the Super Game Console repo. This way, developers can use the exact same configuration that will be used by the CD pipeline, and there will be no surprises.
1.  Run the linter as you work. You could run it manually, but the easiest way to do this is to use your integrated development environment (IDE[](/book/grokking-continuous-delivery/chapter-4/)). Most IDEs, and even editors like Vim, will let you integrate linters and run them as you work. This way, when you make mistakes, you’ll find out immediately.

Becky and Ramon send out a notice to all the developers they work with recommending they turn on linting in their IDEs. They also add a message when the linting task fails on a PR, reminding the game developers that they can turn this on.

##### What about formatters?

Some languages make it easy to go a step beyond linting and eliminate many coding style questions by providing tools called *formatters*[](/book/grokking-continuous-delivery/chapter-4/) that automatically format your code as you work. They can take care of issues such as making sure imports are in the correct order and making sure spacing is consistent. If you work in a language with a formatter, this can save you a lot of headaches! Make sure to integrate the formatter with your IDE. In your pipeline, run the formatter and compare the output to the submitted code.

#####  Legacy code vs. the ideal

[](/book/grokking-continuous-delivery/chapter-4/)Becky and Ramon[](/book/grokking-continuous-delivery/chapter-4/)[](/book/grokking-continuous-delivery/chapter-4/) didn’t get a chance to fix every single issue because a lot of code already existed before they started linting. This means they have to keep tracking the baseline and making sure that the number of issues doesn’t increase, or they have to keep tweaking the Pylint configuration to ignore the issues they’ve decided to just live with.

![](https://drek4537l1klr.cloudfront.net/wilson3/Figures/04-26.png)

But what does the ideal look like? If Becky and Ramon could spend as much time as they wanted on linting, what state would they want to end up in? If you are lucky enough to be working on a brand-new or relatively small codebase, you can shoot directly for this ideal:

**The linter produces zero problems when run against your codebase**.

Is this a reasonable goal to aim for? Yes! And even if you never get there, shooting for the stars and landing on the moon isn’t too bad.

If you’re dealing with a new or small codebase, you don’t have to do everything that Becky and Ramon did. In steps 2 and 3, you’ll notice that Becky and Ramon spend a lot of time focusing on measuring and tracking the baseline. Instead of doing that, take the time to work through all of the problems. You can still apply the order as described in step 4, so if you get interrupted for some reason, you’ve still dealt with the most important issues first. But the goal is to get to the point where there are zero problems.

Then, apply a similar check to the one that Becky and Ramon added in step 3, but instead of comparing the number of linting problems to the baseline, require it to always be zero!

## [](/book/grokking-continuous-delivery/chapter-4/)Conclusion

[](/book/grokking-continuous-delivery/chapter-4/)Super Game Console had a huge backlog of bugs and issues, and the lack of consistent style across all of its games made them hard to maintain. Even though the company’s existing codebase was so huge, Becky was able to add linting to its processes in a way that brought immediate value. She did this by approaching the problem iteratively.

After reestablishing the project’s coding standards, she worked with Ramon to measure the number of linting issues they currently had, and add checks to their PR pipeline to make sure that the number didn’t increase. As Becky and Ramon started working through the issues, they realized they were not all equally important, so they focused on code that was likely to change, and tackled the issues in priority order.

## [](/book/grokking-continuous-delivery/chapter-4/)Summary

-  Linting identifies bugs and helps keep your codebase consistent and maintainable.
-  The ideal situation is that running linting tools will raise zero errors. With huge legacy codebases, we can settle for at least not introducing more errors.
-  Changing code always carries the risk of introducing more bugs, so it’s important to be intentional and consider whether the change is worth it. If the code is changing a lot and/or has a lot of known bugs, it probably is. Otherwise, you can isolate the code and leave it alone.
-  Linting typically identifies three kinds of issues, and they are not equally important. Bugs are almost always worth fixing. Errors can lead to bugs and make code harder to maintain, but aren’t as important as bugs. Lastly, fixing style issues makes your code easier to work with, but these issues aren’t nearly as important as bugs and errors.

## [](/book/grokking-continuous-delivery/chapter-4/)Up next . . .

In the next chapter, we’ll look at how to deal with noisy test suites. We’ll dive into what makes tests noisy and what the signal is that we really need from them.

# 1 [](/book/grokking-continuous-delivery/chapter-1/)[](/book/grokking-continuous-delivery/chapter-1/)Welcome to Grokking Continuous Delivery

### In this chapter

- understanding why you should care about continuous delivery
- understanding the history of continuous delivery, continuous integration, continuous deployment, and CI/CD
- defining the kinds of software that you might be delivering and understanding how continuous delivery applies to them
- defining the elements of continuous delivery: keeping software in a deliverable state at all times and making delivery easy

Hi there! Welcome[](/book/grokking-continuous-delivery/chapter-1/) to my book! I’m so excited that you’ve decided to not only learn about continuous delivery, but also really understand it. That’s what this book is all about: learning how to make continuous delivery work for you on a day-to-day basis.

## [](/book/grokking-continuous-delivery/chapter-1/)[](/book/grokking-continuous-delivery/chapter-1/)Do you need continuous delivery?

[](/book/grokking-continuous-delivery/chapter-1/)The first thing[](/book/grokking-continuous-delivery/chapter-1/) you might be wondering is whether it’s worth your time to learn about continuous delivery, and even if it is, is it worth the hassle of applying it to your projects. The quick answer is *yes* if the following is true for you:

-  You are making software professionally.
-  More than one person is involved in the project.

If both of those are true for you, continuous delivery is worth investing in. *Even if just one is true* (you’re working on a project for fun with a group of people, or you’re making professional software solo), you won’t regret investing in continuous delivery.

*But wait—you didn’t ask what I’m making. What if I’m working on kernel drivers, or firmware, or microservices?* *Are you sure I need continuous delivery?*

—You

It doesn’t matter! Whatever kind of software you’re making, you’ll benefit from applying the principles in this book. The elements of continuous delivery that I explain in this book are built on the principles that we’ve been gathering ever since we started making software. They’re not a trend that will fade in and out of popularity; they are the foundations that will remain whether we’re making microservices, monoliths, distributed container-based services, or whatever comes next.

This book covers the fundamentals of continuous delivery and will give you examples of how you can apply them to your project. The exact details of how you do continuous delivery will probably be unique, and you might not see them exactly reflected in this book, but what you will see are the components you need to put together your continuous delivery automation, and the principles to follow to be the most successful.

##### But I don’t need to deploy anything!

That’s a good point! Deployment and the related automation do not apply to all kinds of software—but continuous delivery is about far more than just deployment. We’ll get into this in the rest of this chapter.

## [](/book/grokking-continuous-delivery/chapter-1/)[](/book/grokking-continuous-delivery/chapter-1/)Why continuous delivery?

[](/book/grokking-continuous-delivery/chapter-1/)What’s this thing[](/book/grokking-continuous-delivery/chapter-1/) you’re here to learn about, anyway? I want to start with what continuous delivery (CD) means to me, and why I think it’s so important:

**Continuous delivery is the process of modern professional software engineering**.

Let’s break down this definition:

-  *Modern*—Professional software engineering has been around way longer than CD, though those folks working with punch cards would have been ecstatic for CD! One of the reasons we can have CD today, and we couldn’t then, is that CD costs a lot of CPU cycles. To have CD, you run a lot of code!

I can’t even imagine how many punch cards you’d need to define a typical CD workflow!

-  *Professional*—If you’re writing software for fun, it’s kind of up in the air whether you’re going to want to bother with CD. For the most part, CD is the process you put in place when it’s really important that the software works. The more important it is, the more elaborate the CD. And when we’re talking about professional software engineering, we’re probably not talking about one person writing code on their own. Most engineers will find themselves working with at least a few other people, if not hundreds, possibly working on exactly the same codebase.
-  *Software engineering*[](/book/grokking-continuous-delivery/chapter-1/)—Other engineering disciplines come with bodies of standards and certifications software engineering generally lacks. So let’s simplify it: software engineering is writing software. When we add the modifier *professional*, we’re talking about writing software professionally.
-  *Process*—Writing software professionally requires a certain approaches to ensure that the code we write does what we mean it to. These processes are less about how one software engineer is writing code (though that’s important too), and more about how that engineer is able to work with other engineers to deliver professional-quality software.

**Continuous delivery is the collection of processes that we need to have in place to ensure that multiple software engineers, writing professional quality software, can create software that does what they want**.

##### *Wait, are you saying* CD *stands for* continuous delivery? *I thought it meant* continuous deployment!

Some people do use it that way, and the fact that both terms came into existence around the same time made this very confusing. Most of the literature I’ve encountered (not to mention the Continuous Delivery Foundation!) favors using CD for continuous delivery, so that’s what this book uses.

#####  Continuous word soup[](/book/grokking-continuous-delivery/chapter-1/)

![](https://drek4537l1klr.cloudfront.net/wilson3/Figures/01-01.png)

1994: “Continuous integration” coined in Object-Oriented Analysis and Design with Applications by Grady Booch et al. (Addison-Wesley)

1999: “Continuous integration” practice defined in Extreme Programming Explained by Kent Beck (Addison-Wesley)

2007 “Continuous integration” practice further defined in Continuous Integration by Paul M. Duvall et al. (Addison-Wesley)

2007 “Continuous deployment” coined in the same book by Duvall

2010: “Continuous delivery” practice defined in Continuous Delivery by Jez Humble and David Farley (Addison-Wesley) inspired by the Agile Manifesto

2014: Earliest article defining “CI/CD” is “Test Automation and Continuous Integration & Deployment (CI/CD)” by the Ravello Community ([http://mng.bz/1opR](http://mng.bz/1opR))

2016: “CI/CD” entry added to Wikipedia ([http://mng.bz/J2RQ](http://mng.bz/J2RQ))

2009: “Continuous deployment” popularized in a blog post by Timothy Fitz ([http://mng.bz/2nmw](http://mng.bz/2nmw))

You might be thinking, okay Christie, that’s all well and good, but what does *deliver* actually mean? And what about *continuous deployment*? What about *CI/CD*?

It’s true, we have a lot of terms to work with! And to make matters worse, people don’t use these terms consistently. In their defense, that’s probably because some of these terms don’t even have definitions!

Let’s take a quick look at the evolution of these terms to understand more. Continuous integration, continuous delivery, and continuous deployment are all terms that were created intentionally (or in the case of continuous integration, evolved), and the creators had specific definitions in mind.

CI/CD is the odd one out: no one seems to have created this term. It seems to have popped into existence because lots of people were trying to talk about all the different continuous activities at the same time and needed a short form. (CI/CD/CD didn’t take for some reason!)

*CI/CD**,* as it’s used today, refers to the tools and automation required for any and all of continuous integration, delivery, and deployment[](/book/grokking-continuous-delivery/chapter-1/)[](/book/grokking-continuous-delivery/chapter-1/).

## [](/book/grokking-continuous-delivery/chapter-1/)[](/book/grokking-continuous-delivery/chapter-1/)Continuous delivery

[](/book/grokking-continuous-delivery/chapter-1/)**Continuous delivery[](/book/grokking-continuous-delivery/chapter-1/) is the collection of processes that we need to have in place to ensure that multiple software engineers, writing professional-quality software, can create software that does what they want**.

My definition captures what I think is really cool about CD, but it’s far from the usual definition you’ll encounter. Let’s take a look at the definition by the Continuous Delivery Foundation (CDF[](/book/grokking-continuous-delivery/chapter-1/)[](/book/grokking-continuous-delivery/chapter-1/)) ([http://mng.bz/YGXN](http://mng.bz/YGXN)):

**A software development practice in which teams release software changes to users safely, quickly, and sustainably b**.

-  **Proving that changes can be released at any time**
-  **Automating release processes**

You’ll notice that CD has two big pieces. You’re doing continuous delivery when:

-  You can safely release changes to your software at any time.
-  Releasing that software is as simple as pushing a button.

The big shift that CD represents over just CI is redefining what it means for a feature to be done. With CD, *done* means *released*. And the process for getting changes from implementation to released is automated, easy, and fast.

This book details the activities and automation that will help you achieve these two goals. Specifically:

-  To be able to safely release your changes at any time, your software must always be in a releasable state. The way to achieve this is with continuous integration (CI).
-  Once these changes have been verified with CI, the processes to release the changes should be automated and repeatable.

Before I start digging into how you can achieve these goals in the next chapters, let’s break these terms down a bit further.

*Continuous delivery*[](/book/grokking-continuous-delivery/chapter-1/) is a set of goals that we aim for; the way you get there might vary from project to project. That being said, activities have emerged as the best ways we’ve found for achieving these goals, and that’s what this book is about!

## [](/book/grokking-continuous-delivery/chapter-1/)[](/book/grokking-continuous-delivery/chapter-1/)Integration

[](/book/grokking-continuous-delivery/chapter-1/)*Continuous integration*[](/book/grokking-continuous-delivery/chapter-1/)[](/book/grokking-continuous-delivery/chapter-1/) *(CI*[](/book/grokking-continuous-delivery/chapter-1/)*)* is the oldest of the terms we’re dealing with—but still a key piece of the continuous delivery pie. Let’s start even simpler with looking at just integration.

What does it mean to *integrate* software? Actually, part of that phrase is missing: to integrate, you need to integrate something into something else. And in software, that something is code changes. When we’re talking about integrating software, what we’re really talking about is this:

**Integrating code changes into existing softwar**.

This is the primary activity that software engineers are doing on a daily basis: changing the code of an existing piece of software. This is especially interesting when you look at what a team of software engineers does: they are constantly making code changes, often to the same piece of software. Combining those changes together is *integrating* them.

**Software integration is the act of combining together code changes made by multiple people**.

As you have probably personally experienced, this can really go wrong sometimes. For example, when I make a change to the same line of code as you do, and we try to combine those together, we have a conflict and have to manually decide how to integrate those changes.

One more piece is still missing. When we integrate code changes, we do more than just put the code changes together; *we also verify that the code works*. You might say that *v* for *verification* is the missing letter in CI! Verification has been packed into the integration piece, so when we talk about software integration, what we really mean is this:

**Software integration is the act of combining together multiple code changes made by multiple people and verifying that the code does what it was intended to do**.

##### Who cares about all these definitions? Show me the code already!

It’s hard to be intentional and methodical about what we’re doing if we can’t even define it. Taking the time to arrive at a shared understanding (via a definition) and getting back to core principles is the most effective way to level up!

On some rare occasions you may be creating software for the very first time, but from every point after the first successful compile, you are once again integrating changes into existing software.

## [](/book/grokking-continuous-delivery/chapter-1/)[](/book/grokking-continuous-delivery/chapter-1/)Continuous integration

[](/book/grokking-continuous-delivery/chapter-1/)Let’s look[](/book/grokking-continuous-delivery/chapter-1/)[](/book/grokking-continuous-delivery/chapter-1/) at how to put the *continuous* into *continuous integration* with an example outside of software engineering. Holly, a chef, is cooking pasta sauce. She starts with a set of raw ingredients: onions, garlic, tomatoes, spices. To cook, she needs to *integrate* these ingredients together, in the right order and the right quantities, to get the sauce that she wants.

![](https://drek4537l1klr.cloudfront.net/wilson3/Figures/01-02.png)

To accomplish this, every time she adds a new ingredient, *she takes a quick taste*. Based on the flavor, she might decide to add a little extra, or realize she wants to add an ingredient she missed.

By tasting along the way, she’s evolving the recipe through a series of integrations. Integration here is expressing two things:

-  Combining the ingredients
-  Checking to verify the result

And that’s what the *integration*[](/book/grokking-continuous-delivery/chapter-1/) in *continuous integration*[](/book/grokking-continuous-delivery/chapter-1/) means: combining code changes together, and also verifying that they work— i.e., *combine and verify*.

Holly repeats this process as she cooks. If she waited until the end to taste the sauce, she’d have a lot less control, and it might be too late to make the needed changes. That’s where the *continuous* piece of *continuous integration* comes in. You want to be integrating (combining and verifying) your changes as frequently as you possibly can—as soon as you can.

And when we’re talking about software, what’s the soonest you can combine and
verify? As soon as you make a change:

**Continuous integration is the process of combining code changes frequently, with each change verified on check-in**.

Combining code changes together means that engineers using continuous integration are committing and pushing to shared version control every time they make a change, and they are verifying that those changes work together by applying automated verification, including tests and linting.

Automated verification? Linting? Don’t worry if you don’t know what those are all about; that’s what this book is for! In the rest of the book, we’ll look at how to create the automated verification that makes continuous integration work.

## [](/book/grokking-continuous-delivery/chapter-1/)[](/book/grokking-continuous-delivery/chapter-1/)What do we deliver?

[](/book/grokking-continuous-delivery/chapter-1/)Now as I transition[](/book/grokking-continuous-delivery/chapter-1/)[](/book/grokking-continuous-delivery/chapter-1/) from looking at continuous integration to continuous delivery, I need to take a small step back. Almost every definition we explore is going to make a reference to delivering some kind of software (for example, I’m about to start talking about *integrating* *and delivering changes to software*). It’s probably good to make sure we’re all talking about the same thing when we say *software*—and depending on the project you’re working on, it can mean some very different things.

#####  Vocab time

The term *software* exists in contrast to *hardware*. Hardware is the actual physical pieces of our computers. We do things with these physical pieces by providing them with instructions. Instructions can be built directly into hardware, or they can be provided to hardware when it runs via software.

When you are delivering software, you could be making several forms of software (and integrating and delivering each of these will look slightly different):

-  *Library*[](/book/grokking-continuous-delivery/chapter-1/)—If your software doesn’t do anything on its own, but is intended to be used as part of other software, it’s probably a library.
-  *Binary*[](/book/grokking-continuous-delivery/chapter-1/)—If your software is intended to be run, it’s probably a binary executable of some kind. This could be a service or application, or a tool that is run and completes, or an application that is installed onto a device like a tablet or phone.
-  *Configuration*[](/book/grokking-continuous-delivery/chapter-1/)—This refers to information that you can provide to a binary to change its behavior without having to recompile it. Typically, this corresponds to the levers that a system administrator has available to make changes to running software.
-  *Image*—Container images are a specific kind of binary that are currently an extremely popular format for sharing and distributing services with their configuration, so they can be run in an operating system-agnostic way.
-  *Service*[](/book/grokking-continuous-delivery/chapter-1/)—In general, services are binaries that are intended to be up and running at all times, waiting for requests that they can respond to by doing something or returning information. Sometimes they are also referred to as *applications*.

At different points in your career, you may find yourself dealing with some or all of these kinds of software. But regardless of the particular form you are dealing with, in order to create it, you need to *integrate* and *deliver* changes to it.

## [](/book/grokking-continuous-delivery/chapter-1/)[](/book/grokking-continuous-delivery/chapter-1/)Delivery

[](/book/grokking-continuous-delivery/chapter-1/)What it means[](/book/grokking-continuous-delivery/chapter-1/)[](/book/grokking-continuous-delivery/chapter-1/) to *deliver* changes to software depends on what you are making, who is using it, and how. Usually, delivering changes refers to one or all of building, releasing, and deploying:

-  *Building*[](/book/grokking-continuous-delivery/chapter-1/)—The act of taking code (including changes) and turning it into the form required for it to be used. This usually means compiling the code written in a programming language into a machine language. Sometimes it also means wrapping the code into a package, such as an image, or something that can be understood by a package manager (e.g., PyPI for Python packages).

Building is also done as part of integration in order to ensure that changes work together.

-  *Publishing*[](/book/grokking-continuous-delivery/chapter-1/)—Copying software to a repository (a storage location for software)—for example, by uploading your image or library to a package registry.
-  *Deploying*—Copying the software where it needs to be to run and putting it into a running state.

You can *deploy* without *releasing*—e.g., deploying a new version of your software but not directing any traffic to it. That being said, deploying often implies releasing; it all depends on where you are deploying to. If you are deploying to production, you’ll be deploying and releasing at the same time. See chapter 10 for more on deploying.

-  *Releasing*[](/book/grokking-continuous-delivery/chapter-1/)—Making software available to your users. This could be by uploading your image or library to a repository, or by setting a configuration value to direct a percentage of traffic to a deployed instance.

#####  Vocab time

We’ve been *building* software for as long as we’ve had programming languages. This is such a common activity that the earliest systems that did what we now call *continuous delivery* were called *build systems*. This terminology is so prevalent that even today you will often hear people refer to *the build*. What they usually mean is the tasks in a CD pipeline that transform software (more on this in chapter 2).

## [](/book/grokking-continuous-delivery/chapter-1/)[](/book/grokking-continuous-delivery/chapter-1/)Continuous delivery/deployment[](/book/grokking-continuous-delivery/chapter-1/)[](/book/grokking-continuous-delivery/chapter-1/)

[](/book/grokking-continuous-delivery/chapter-1/)Now you know what it means to deliver software changes, but what does it mean for it to be continuous? In the context of CI, we learned that *continuous* means *as soon as possible*. Is that the case for CD? Yes and no. CD’s use of *continuous* is better represented as a continuum:

![](https://drek4537l1klr.cloudfront.net/wilson3/Figures/01-02b.png)

Your software should be proven to be in a state where it could be built, released, and/or deployed at any time. But how frequently you choose to deliver that software is up to you.

2009: “Continuous deployment” popularized in blog post

2010: “Continuous delivery” practice defined in book of the same name

Around this time you might be wondering, “What about continuous deployment?” That’s a great question. Looking at the history again, you’ll notice that the two terms, *continuous delivery* and *continuous deployment*, came into popular use pretty much back-to-back. What was going on when these terms were coined?

This was an inflection point for software: the old ways of creating software, which relied on humans doing things manually, a strong software development and operations divide (interestingly, the term *DevOps* appeared at around the same time), and sharply delineated processes (e.g., *testing phase*) were starting to shift (left). Both continuous deployment and continuous delivery were naming the set of practices that emerged at this time. *Continuous deployment*[](/book/grokking-continuous-delivery/chapter-1/) means the following:

**Working software is released to users automatically on every commit**.

#####  Vocab time

*Shifting left*[](/book/grokking-continuous-delivery/chapter-1/) is a process intended to find defects as early as possible while creating software.

Continuous deployment is an optional step beyond continuous delivery. The key is that continuous delivery enables continuous deployment; always being in a releasable state and automating delivery frees you up to decide what is best for your project.

##### *If continuous deployment is actually about releasing, why not call it* continuous releasing *instead?*

Great point! *Continuous releasing* is a more accurate name, and would make it clear how this practice can apply to software that doesn’t need to be deployed, but c*ontinuous deployment* is the name that’s stuck! See chapter 9 for an example of continuous releasing.

## [](/book/grokking-continuous-delivery/chapter-1/)[](/book/grokking-continuous-delivery/chapter-1/)Elements of continuous delivery

[](/book/grokking-continuous-delivery/chapter-1/)The rest of this[](/book/grokking-continuous-delivery/chapter-1/) book will show you the fundamental building blocks of CD:

**A software development practice in which working software is released to users as quickly as it makes sense for the project and is built in such a way that it has been proven that this can safely be done at any time**.

![](https://drek4537l1klr.cloudfront.net/wilson3/Figures/01-03.png)

You will learn how to use CI to always have your software in a releasable state, and you will learn how to make delivery automated and repeatable. This combo allows you to choose whether you want to go to the extreme of releasing on every change (continuous deployment), or if you’d rather release on another cadence. Either way, you can be confident in the knowledge that you have the automation in place to deliver as frequently as you need.

And at the core of all of this automation will be your continuous delivery pipeline. In this book, I’ll dig into each of these tasks and what they look like. You’ll find that no matter what kind of software you’re making, many of these tasks will be useful to you.

##### Pipeline? Task? What are those?

Read the next chapter to find out!

The following table looks back at the forms of software we explored and what it means to deliver each of them.

|   | **Delivery includes building?** | **Delivery includes publishing?** | **Delivery includes deploying?** | **Delivery includes releasing?** |
| --- | --- | --- | --- | --- |
| **Library** | Depends | Yes | No | Yes |
| **Binary** | Yes | Usually | Depends | Yes |
| **Configuration** | No | Probably not | Usually | Yes |
| **Image** | Yes | Yes | Depends | Yes |
| **Service** | Yes | Usually | Yes | Yes |

## [](/book/grokking-continuous-delivery/chapter-1/)Conclusion

[](/book/grokking-continuous-delivery/chapter-1/)The continuous delivery space contains a lot of terms, and a lot of contradictory definitions. In this book, we use *CD* to refer to *continuous delivery*, which includes continuous integration (CI[](/book/grokking-continuous-delivery/chapter-1/)), deploying, and releasing. I’ll be focusing on how to set up the automation you need in order to use CD for whatever kind of software you’re delivering.

## [](/book/grokking-continuous-delivery/chapter-1/)Summary

-  Continuous delivery is useful for all software; it doesn’t matter what kind of software you’re making.
-  To enable teams of software developers to make professional-quality software, you need continuous delivery.
-  To be doing continuous delivery, you use continuous integration to make sure your software is always in a deliverable state.
-  Continuous integration is the process of combining code changes frequently, with each change verified on check-in.
-  The other piece of the continuous delivery puzzle is the automation required to make releasing as easy as pushing a button.
-  Continuous deployment is an optional step you can take if it makes sense for your project; with this approach software is automatically delivered on every commit.

## [](/book/grokking-continuous-delivery/chapter-1/)Up next . . .

You’ll learn all about the basics and terminology of continuous delivery automation, setting up the foundation for the rest of the book!

## Exercise 48. A Simple Network Server

We now start the part of the book where you do a long-running, more involved project in a series of exercises. The last five exercises will present the problem of creating a simple network server in a similar fashion as you did with the `logfind` project. I’ll describe each phase of the project, you’ll attempt it, and then you’ll compare your implementation to mine before continuing.

These descriptions are purposefully vague so that you have the freedom to attempt to solve the problems on your own, but I’m still going to help you. Included with each of these exercises are *two* videos. The first video shows you how the project for the exercise should work, so you can see it in action and try to emulate it. The second video shows you how *I* solved the problem, so you can compare your attempt to mine. Finally, you’ll have access to all of the code in the GitHub project, so you can see real code by me.

You should attempt the problem first, then after you get it working (or if you get totally stuck), go watch the second video and take a look at my code. When you’re done, you can either keep using your code, or just use mine for the next exercise.

### The Specification

In this first small program you’ll lay the first foundation for the remaining projects. You’ll call this program `statserve`, even though this specification doesn’t mention statistics or anything. That will come later.

The specification for this project is very simple:

**1.** Create a simple network server that accepts a connection on port 7899 from `netclient` or the `nc` command, and that echoes back anything you type.

**2.** You’ll need to learn how to bind a port, listen on the socket, and answer it. Use your research skills to study how this is done and attempt to implement it yourself.

**3.** The more important part of this project is laying out the project directory from the `c-skeleton`, and making sure you can build everything and get it working.

**4.** Don’t worry about things like daemons or anything else. Your server just has to run from the command line and keep running.

The important challenge for this project is figuring out how to create a socket server, but everything you’ve learned so far makes this possible. Watch the first lecture video where I teach you about this if you find that it’s too hard to figure out on your own.

## Exercise 2. Using Makefiles to Build

We’re going to use a program called `make` to simplify building your exercise code. The `make` program has been around for a very long time, and because of this it knows how to build quite a few types of software. In this exercise, I’ll teach you just enough `Makefile` syntax to continue with the course, and then an exercise later will teach you more complete `Makefile` usage.

### Using Make

How `make` works is you declare dependencies, and then describe how to build them or rely on the program’s internal knowledge of how to build most common software. It has decades of knowledge about building a wide variety of files from other files. In the last exercise, you did this already using commands:

```bash
$ make ex1

# or this one too

$ CFLAGS="-Wall" make ex1
```

In the first command, you’re telling `make`, “I want a file named ex1 to be created.” The program then asks and does the following:

**1.** Does the file `ex1` exist already?

**2.** No. Okay, is there another file that starts with `ex1`?

**3.** Yes, it’s called `ex1.c`. Do I know how to build `.c` files?

**4.** Yes, I run this command `cc ex1.c -o ex1` to build them.

**5.** I shall make you one `ex1` by using `cc` to build it from `ex1.c`.

The second command in the listing above is a way to pass *modifiers* to the `make` command. If you’re not familiar with how the UNIX shell works, you can create these *environment variables* that will get picked up by programs you run. Sometimes you do this with a command like `export CFLAGS="-Wall"` depending on the shell you use. You can, however, also just put them before the command you want to run, and that environment variable will be set only while that command runs.

In this example, I did `CFLAGS="-Wall" make ex1` so that it would add the command line option `-Wall` to the `cc` command that `make` normally runs. That command line option tells the compiler `cc` to report all warnings (which, in a sick twist of fate, isn’t actually all the warnings possible).

You can actually get pretty far with just using `make` in that way, but let’s get into making a `Makefile` so you can understand `make` a little better. To start off, create a file with just the following in it.

`ex2.1.mak`

---

```
CFLAGS=-Wall -g



clean:

    rm -f ex1
```

Save this file as `Makefile` in your current directory. The program automatically assumes there’s a file called `Makefile` and will just run it.

---

Warning!

Make sure you are only entering TAB characters, not mixtures of TAB and spaces.

---

This `Makefile` is showing you some new stuff with `make`. First, we set `CFLAGS` in the file so we never have to set it again, as well as adding the `-g` flag to get debugging. Then, we have a section named `clean` that tells `make` how to clean up our little project.

Make sure it’s in the same directory as your `ex1.c` file, and then run these commands:

```bash
$ make clean

$ make ex1
```

### What You Should See

If that worked, then you should see this:

`Exercise 2 Session`

---

[Click here to view code image](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch02_images.html#p011pro01a)

```bash
$ make clean

rm -f ex1

$ make ex1

cc -Wall -g    ex1.c   -o ex1

ex1.c: In function 'main':

ex1.c:3: warning: implicit declaration of function 'puts'

$
```

Here you can see that I’m running `make clean`, which tells `make` to run our `clean` target. Go look at the `Makefile` again and you’ll see that under this command, I indent and then put in the shell commands I want `make` to run for me. You could put as many commands as you wanted in there, so it’s a great automation tool.

---

Warning!

If you fixed `ex1.c` to have `#include <stdio.h>`, then your output won’t have the warning (which should really be an error) about puts. I have the error here because I didn’t fix it.

---

Notice that even though we don’t mention `ex1` in the `Makefile`, `make` still knows how to build it *and* use our special settings.

### How to Break It

That should be enough to get you started, but first let’s break this `Makefile` in a particular way so you can see what happens. Take the line `rm -f ex1` and remove the indent (move it all the way left) so you can see what happens. Rerun `make clean`, and you should get something like this:

[Click here to view code image](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch02_images.html#p012pro01a)

```bash
$ make clean

Makefile:4: *** missing separator.  Stop.
```

Always remember to indent, and if you get weird errors like this, double check that you’re consistently using tab characters because some `make` variants are very picky.

### Extra Credit

• Create an `all: ex1` target that will build `ex1` with just the command `make`.

• Read `man make` to find out more information on how to run it.

• Read `man cc` to find out more information on what the flags `-Wall` and `-g` do.

• Research `Makefile`s online and see if you can improve this one.

• Find a `Makefile` in another C project and try to understand what it’s doing.

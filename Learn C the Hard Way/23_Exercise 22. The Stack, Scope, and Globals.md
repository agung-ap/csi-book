## Exercise 22. The Stack, Scope, and Globals

The concept of scope seems to confuse quite a few people when they first start programming. It originally came from the use of the system stack (which we lightly covered earlier), and how it was used to store temporary variables. In this exercise, we’ll learn about scope by learning how a stack data structure works, and then feeding that concept back in to how modern C does scoping.

The real purpose of this exercise, though, is to learn where the hell things live in C. When someone doesn’t grasp the concept of scope, it’s almost always a failure in understanding where variables are created, exist, and die. Once you know where things are, the concept of scope becomes easier.

This exercise will require three files:

**ex22.h** A header file that sets up some external variables and some functions.

**ex22.c** This isn’t your `main` like normal, but instead a source file that will become the object file `ex22.o`, which will have some functions and variables in it defined from `ex22.h`.

**ex22_main.c** The actual `main` that will include the other two, and demonstrate what they contain, as well as other scope concepts.

### ex22.h and ex22.c

Your first step is to create your own header file named `ex22.h` that defines the functions and extern variables:

`ex22.h`

---

[Click here to view code image](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch22_images.html#p112pro01a)

```
#ifndef _ex22_h

#define _ex22_h



// makes THE_SIZE in ex22.c available to other .c files

extern int THE_SIZE;



// gets and sets an internal static variable in ex22.c

int get_age();

void set_age(int age);



// updates a static variable that's inside update_ratio

double update_ratio(double ratio);



void print_size();



#endif
```

The important thing to see here is the use of `extern int THE_SIZE`, which I’ll explain after you create this matching `ex22.c`:

`ex22.c`

---

[Click here to view code image](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch22_images.html#p113pro01a)

```
#include <stdio.h>

#include "ex22.h"

#include "dbg.h"

  4

int THE_SIZE = 1000;

  6

static int THE_AGE = 37;

  8

int get_age()

{

return THE_AGE;

}

 13

void set_age(int age)

{

THE_AGE = age;

}

 18

double update_ratio(double new_ratio)

{

static double ratio = 1.0;

 22

double old_ratio = ratio;

ratio = new_ratio;

 25

return old_ratio;

}

 28

void print_size()

{

log_info("I think size is: %d", THE_SIZE);

}
```

These two files introduce some new kinds of storage for variables:

**extern** This keyword is a way to tell the compiler “the variable exists, but it’s in another ‘external’ location.” Typically this means that one .c file is going to use a variable that’s been defined in another .c file. In this case, we’re saying `ex22.c` has a variable `THE_SIZE` that will be accessed from `ex22_main.c`.

**static (file)** This keyword is kind of the inverse of `extern`, and says that the variable is only used in this .c file and should not be available to other parts of the program. Keep in mind that `static` at the file level (as with `THE_AGE` here) is different than in other places.

**static (function)** If you declare a variable in a function `static`, then that variable acts like a `static` defined in the file, but it’s only accessible from that function. It’s a way of creating constant state for a function, but in reality it’s *rarely* used in modern C programming because they are hard to use with threads.

In these two files, you should understand the following variables and functions:

**THE_SIZE** This is the variable you declared `extern` that you’ll play with from `ex22_main.c`.

**get_age and set_age** These are taking the static variable `THE_AGE`, but exposing it to other parts of the program through functions. You can’t access `THE_AGE` directly, but these functions can.

**update_ratio** This takes a new `ratio` value, and returns the old one. It uses a function level static variable `ratio` to keep track of what the ratio currently is.

**print_size** This prints out what `ex22.c` thinks `THE_SIZE` is currently.

### ex22_main.c

Once you have that file written, you can then make the `main` function, which uses all of these and demonstrates some more scope conventions.

`ex22_main.c`

---

[Click here to view code image](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch22_images.html#p114pro01a)

```
#include "ex22.h"

#include "dbg.h"

  3

const char *MY_NAME = "Zed A. Shaw";

  5

void scope_demo(int count)

{

log_info("count is: %d", count);

  9

if (count > 10) {

int count = 100;    // BAD! BUGS!

 12

log_info("count in this scope is %d", count);

}

 15

log_info("count is at exit: %d", count);

 17

count = 3000;

 19

log_info("count after assign: %d", count);

}

 22

int main(int argc, char *argv[])

{

// test out THE_AGE accessors

log_info("My name: %s, age: %d", MY_NAME, get_age());

 27

set_age(100);

 29

log_info("My age is now: %d", get_age());

 31

// test out THE_SIZE extern

log_info("THE_SIZE is: %d", THE_SIZE);

print_size();

 35

THE_SIZE = 9;

 37

log_info("THE SIZE is now: %d", THE_SIZE);

print_size();

 40

// test the ratio function static

log_info("Ratio at first: %f", update_ratio(2.0));

log_info("Ratio again: %f", update_ratio(10.0));

log_info("Ratio once more: %f", update_ratio(300.0));

 45

// test the scope demo

int count = 4;

scope_demo(count);

scope_demo(count * 20);

 50

log_info("count after calling scope_demo: %d", count);

 52

return 0;

}
```

I’ll break this file down line by line, but as I do, you should find each variable and where it lives.

**ex22_main.c:4** A `const`, which stands for constant, and is an alternative to using a `define` to create a constant variable.

**ex22_main.c:6** A simple function that demonstrates more scope issues in a function.

**ex22_main.c:8** This prints out the value of `count` as it is at the top of the function.

**ex22_main.c:10** An `if-statement` that starts a new *scope block*, and then has another `count` variable in it. This version of `count` is actually a whole new variable. It’s kind of like the `if-statement` started a new mini function.

**ex22_main.c:11** The `count` that is local to this block is actually different from the one in the function’s parameter list.

**ex22_main.c:13** This prints it out so you can see it’s actually 100 here, not what was passed to `scope_demo`.

**ex22_main.c:16** Now for the freaky part. You have `count` in two places: the parameters to this function, and in the `if-statement`. The `if-statement` created a new block, so the `count` on line 11 *does not impact the parameter with the same name*. This line prints it out, and you’ll see that it prints the value of the parameter, not 100.

**ex22_main.c:18-20** Then, I set the parameter `count` to 3000 and print that out, which will demonstrate that you can change function parameters and they don’t impact the caller’s version of the variable.

Make sure that you trace through this function, but don’t think that you understand scope quite yet. Just start to realize that if you make a variable inside a block (as in `if-statements` or `while-loops`), then those variables are *new* variables that exist only in that block. This is crucial to understand, and is also a *source of many bugs*. We’ll address why you shouldn’t make a variable inside a block shortly.

The rest of the `ex22_main.c` then demonstrates all of these by manipulating and printing them out:

**ex22_main.c:26** This prints out the current values of `MY_NAME`, and gets `THE_AGE` from `ex22.c` by using the accessor function `get_age`.

**ex22_main.c:27-30** This uses `set_age` in `ex22.c` to change `THE_AGE` and then print it out.

**ex22_main.c:33-39** Then I do the same thing to `THE_SIZE` from `ex22.c`, but this time I’m accessing it directly. I’m also demonstrating that it’s actually changing in that file by printing it here and with `print_size`.

**ex22_main.c:42-44** Here, I show how the static variable `ratio` inside `update_ratio` is maintained between function calls.

**ex22_main.c:46-51** Finally, I’m running `scope_demo` a few times so you can see the scope in action. The big thing to notice is that the local `count` variable remains unchanged. You *must* understand that passing in a variable like this won’t let you change it in the function. To do that, you need our old friend the pointer. If you were to pass a pointer to this `count`, then the called function would have the address of it and could change it.

That explains what’s going on, but you should trace through these files and make sure you know where everything is as you study it.

### What You Should See

This time, instead of using your `Makefile`, I want you to build these two files manually so you can see how the compiler actually puts them together. Here’s what you should do and see for output:

`Exercise 22 Session`

---

[Click here to view code image](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch22_images.html#p117pro01a)

```bash
$ cc -Wall -g -DNDEBUG  -c -o ex22.o ex22.c

$ cc -Wall -g -DNDEBUG   ex22_main.c ex22.o   -o ex22_main

$ ./ex22_main

[INFO] (ex22_main.c:26) My name: Zed A. Shaw, age: 37

[INFO] (ex22_main.c:30) My age is now: 100

[INFO] (ex22_main.c:33) THE_SIZE is: 1000

[INFO] (ex22.c:32) I think size is: 1000

[INFO] (ex22_main.c:38) THE SIZE is now: 9

[INFO] (ex22.c:32) I think size is: 9

[INFO] (ex22_main.c:42) Ratio at first: 1.000000

[INFO] (ex22_main.c:43) Ratio again: 2.000000

[INFO] (ex22_main.c:44) Ratio once more: 10.000000

[INFO] (ex22_main.c:8) count is: 4

[INFO] (ex22_main.c:16) count is at exit: 4

[INFO] (ex22_main.c:20) count after assign: 3000

[INFO] (ex22_main.c:8) count is: 80

[INFO] (ex22_main.c:13) count in this scope is 100

[INFO] (ex22_main.c:16) count is at exit: 80

[INFO] (ex22_main.c:20) count after assign: 3000

[INFO] (ex22_main.c:51) count after calling scope_demo: 4
```

Make sure you trace how each variable is changing and match it to the line that gets output. I’m using `log_info` from the `dbg.h` macros so you can get the exact line number where each variable is printed, and find it in the files for tracing.

### Scope, Stack, and Bugs

If you’ve done this right, you should now see many of the different ways you can place variables in your C code. You can use `extern` or access functions like `get_age` to create globals. You can make new variables inside any blocks, and they’ll retain their own values until that block exits, leaving the outer variables alone. You also can pass a value to a function, and change the parameter but without changing the caller’s version of it.

The most important thing to realize is that all of this causes bugs. C’s ability to place things in many places in your machine, and then let you access it in those places, means that you can get easily confused about where something lives. If you don’t know where it lives, then there’s a chance you won’t manage it properly.

With that in mind, here are some rules to follow when writing C code so you can avoid bugs related to the stack:

• Do not shadow a variable like I’ve done here with `count` in `scope_demo`. It leaves you open to subtle and hidden bugs where you *think* you’re changing a value but you’re actually not.

• Avoid using too many globals, especially if across multiple files. If you have to use them, then use accessor functions like I’ve done with `get_age`. This doesn’t apply to constants, since those are read-only. I’m talking about variables like `THE_SIZE`. If you want people to modify or set this variable, then make accessor functions.

• When in doubt, put it on the heap. Don’t rely on the semantics of the stack or specialized locations. Just create things with `malloc`.

• Don’t use function static variables like I did in `update_ratio`. They’re rarely useful and end up being a huge pain when you need to make your code concurrent in threads. They’re also hard as hell to find compared to a well-done global variable.

• Avoid reusing function parameters. It’s confusing as to whether you’re just reusing it or if you think you’re changing the *caller’s* version of it.

As with all things, these rules can be broken when it’s practical. In fact, I guarantee you’ll run into code that breaks all of these rules and is perfectly fine. The constraints of different platforms even make it necessary sometimes.

### How to Break It

For this exercise, try to access or change some things you can’t to break the program.

• Try to directly access variables in `ex22.c` from `ex22_main.c` that you think you can’t access. For example, can you get at `ratio` inside `update_ratio`? What if you had a pointer to it?

• Ditch the `extern` declaration in `ex22.h` to see what errors or warnings you get.

• Add `static` or `const` specifiers to different variables, and then try to change them.

### Extra Credit

• Research the concept of pass by value versus pass by reference. Write an example of both.

• Use pointers to gain access to things you shouldn’t have access to.

• Use your debugger to see what this kind of access looks like when you do it wrong.

• Write a recursive function that causes a stack overflow. Don’t know what a recursive function is? Try calling `scope_demo` at the bottom of `scope_demo` itself so that it loops.

• Rewrite the `Makefile` so that it can build this.

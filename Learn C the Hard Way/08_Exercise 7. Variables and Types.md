## Exercise 7. Variables and Types

You should be getting a grasp of how a simple C program is structured, so let’s do the next simplest thing and make some variables of different types:

`ex7.c`

---

[Click here to view code image](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch07_images.html#p032pro01a)

```
#include <stdio.h>

 2

int main(intargc, char*argv[])

{

int distance = 100;

float power = 2.345f;

double super_power = 56789.4532;

char initial = 'A';

char first_name[] = "Zed";

char last_name[] = "Shaw";

11

printf("You are %d miles away.\n", distance);

printf("You have %f levels of power.\n", power);

printf("You have %f awesome super powers.\n", super_power);

printf("I have an initial %c.\n", initial);

printf("I have a first name %s.\n", first_name);

printf("I have a last name %s.\n", last_name);

printf("My whole name is %s %c. %s.\n",

first_name, initial, last_name);

20

int bugs = 100;

double bug_rate = 1.2;

23

printf("You have %d bugs at the imaginary rate of %f.\n",

bugs, bug_rate);

26

long universe_of_defects = 1L * 1024L * 1024L * 1024L;

printf("The entire universe has %ld bugs.\n", universe_of_defects);

29

double expected_bugs = bugs * bug_rate;

printf("You are expected to have %f bugs.\n", expected_bugs);

32

double part_of_universe = expected_bugs / universe_of_defects;

printf("That is only a %e portion of the universe.\n",

part_of_universe);

36

// this makes no sense, just a demo of something weird

char nul_byte = '\0';

int care_percentage = bugs * nul_byte;

printf("Which means you should care %d%%.\n", care_percentage);

41

return 0;

}
```

In this program, we’re declaring variables of different types and then printing them using different `printf` format strings. I can break it down as follows:

**ex7.c:1-4** The usual start of a C program.

**ex7.c:5-6** Declare an `int` and `double` for some fake bug data.

**ex7.c:8-9** Print out those two, so nothing new here.

**ex7.c:11** Declare a huge number using a new type, `long`, for storing big numbers.

**ex7.c:12-13** Print out that number using `%ld` that adds a modifier to the usual `%d`. Adding `l` (the letter) tells the program to print the number as a long decimal.

**ex7.c:15-17** This is just more math and printing.

**ex7.c:19-21** Craft a depiction of your bug rate compared to the bugs in the universe, which is a completely inaccurate calculation. It’s so small that we have to use `%e` to print it in scientific notation.

**ex7.c:24** Make a character, with a special syntax `'\0'` that creates a `nul byte` character. This is effectively the number 0.

**ex7.c:25** Multiply bugs by this character, which produces 0, as in how much you should care. This demonstrates an ugly hack you might see sometimes.

**ex7.c:26-27** Print that out, and notice we’ve used `%%` (two percent signs) so that we can print a % (percent) character.

**ex7.c:28-30** The end of the `main` function.

This source file demonstrates how some math works with different types of variables. At the end of the program, it also demonstrates something you see in C but not in many other languages. To C, a *character* is just an integer. It’s a really small integer, but that’s all it is. This means you can do math on them, and a lot of software does just that—for good or bad.

This last bit is your first glance at how C gives you direct access to the machine. We’ll be exploring that more in later exercises.

### What You Should See

As usual, here’s what you should see for the output:

`Exercise 7 Session`

---

[Click here to view code image](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch07_images.html#p034pro01a)

```bash
$ make ex7

cc -Wall -g    ex7.c   -o ex7

$ ./ex7

You have 100 bugs at the imaginary rate of 1.200000.

The entire universe has 1073741824 bugs.

You are expected to have 120.000000 bugs.

That is only a 1.117587e-07 portion of the universe.

Which means you should care 0%.

$
```

### How to Break It

Again, go through this and try to break the `printf` by passing in the wrong arguments. See what happens if you try to print out the `nul_byte` variable along with `%s` versus `%c`. When you break it, run it under the debugger to see what it says about what you did.

### Extra Credit

• Make the number you assign to `universe_of_defects` various sizes until you get a warning from the compiler.

• What do these really huge numbers actually print out?

• Change `long` to `unsigned long` and try to find the number that makes it too big.

• Go search online to find out what `unsigned` does.

• Try to explain to yourself (before I do in the next exercise) why you can multiply a `char` and an `int`.

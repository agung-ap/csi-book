## Exercise 8. If, Else-If, Else

In C, there really isn’t a *Boolean* type. Instead, any integer that’s 0 is *false* or otherwise it’s *true*. In the last exercise, the expression `argc > 1` actually resulted in 1 or 0, not an explicit `True` or `False` like in Python. This is another example of C being closer to how a computer works, because to a computer, truth values are just integers.

However, C does have a typical `if-statement` that uses this numeric idea of true and false to do branching. It’s fairly similar to what you would do in Python and Ruby, as you can see in this exercise:

`ex8.c`

---

[Click here to view code image](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch08_images.html#p036pro01a)

```
#include <stdio.h>

 2

int main(int argc, char *argv[])

{

int i = 0;

 6

if (argc == 1) {

printf("You only have one argument. You suck.\n");

} else if (argc > 1 && argc < 4) {

printf("Here's your arguments:\n");

11

for (i = 0; i < argc; i++) {

printf("%s ", argv[i]);

}

printf("\n");

} else {

printf("You have too many arguments. You suck.\n");

}

19

return 0;

}
```

The format for the `if-statement` is this:

```
if(TEST) {

    CODE;

} else if(TEST) {

    CODE;

} else {

    CODE;

}
```

This is like most other languages except for some specific C differences:

• As mentioned before, the `TEST` parts are false if they evaluate to 0, or otherwise true.

• You have to put parentheses around the `TEST` elements, while some other languages let you skip that.

• You don’t need the `{}` braces to enclose the code, but it is *very* bad form to not use them. The braces make it clear where one branch of code begins and ends. If you don’t include them then obnoxious errors come up.

Other than that, the code works the way it does in most other languages. You don’t need to have either `else if` or `else` parts.

### What You Should See

This one is pretty simple to run and try out:

`Exercise 8 Session`

---

[Click here to view code image](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch08_images.html#p037pro01a)

```bash
$ make ex8

cc -Wall -g    ex8.c   -o ex8

$ ./ex8

You only have one argument. You suck.

$ ./ex8 one

Here's your arguments:

./ex8 one

$ ./ex8 one two

Here's your arguments:

./ex8 one two

$ ./ex8 one two three

You have too many arguments. You suck.

$
```

### How to Break It

This one isn’t easy to break because it’s so simple, but try messing up the tests in the `if-statement`:

• Remove the `else` at the end, and the program won’t catch the edge case.

• Change the `&&` to a `||` so you get an or instead of an and test and see how that works.

### Extra Credit

• You were briefly introduced to `&&`, which does an and comparison, so go research online the different *Boolean operators*.

• Write a few more test cases for this program to see what you can come up with.

• Is the first test really saying the right thing? To you, the *first argument* isn’t the same first argument a user entered. Fix it.

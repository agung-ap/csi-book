## Exercise 9. While-Loop and Boolean Expressions

The first looping construct I’ll show you is the `while-loop`, and it’s the simplest, useful loop you could possibly use in C. Here’s this exercise’s code for discussion:

`ex9.c`

---

[Click here to view code image](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch09_images.html#p040pro01a)

```
#include <stdio.h>

 2

int main(int argc, char *argv[])

{

int i = 0;

while (i < 25) {

printf("%d", i);

i++;

}

10

return 0;

}
```

From this code, and from your memorization of the basic syntax, you can see that a `while-loop` is simply this:

```
while(TEST) {

    CODE;

}
```

It simply runs the `CODE` as long as `TEST` is true (1). So to replicate how the `for-loop` works, we need to do our own initializing and incrementing of `i`. Remember that `i++` increments `i` with the `post-increment operator`. Refer back to your list of tokens if you didn’t recognize that.

### What You Should See

The output is basically the same, so I just did it a little differently so that you can see it run another way.

`Exercise 9 Session`

---

[Click here to view code image](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch09_images.html#p040pro02a)

```bash
$ make ex9

cc -Wall -g    ex9.c   -o ex9

$ ./ex9

0123456789101112131415161718192021222324

$
```

### How to Break It

There are several ways to get a `while-loop` wrong, so I don’t recommend you use it unless you must. Here are a few easy ways to break it:

• Forget to initialize the first `int i;`. Depending on what `i` starts with, the loop might not run at all, or run for an extremely long time.

• Forget to initialize the second loop’s `i` so that it retains the value from the end of the first loop. Now your second loop might or might not run.

• Forget to do a `i++` increment at the end of the loop and you’ll get a *forever loop*, one of the dreaded problems common in the first decade or two of programming.

### Extra Credit

• Make the loop count backward by using `i--` to start at 25 and go to 0.

• Write a few more complex `while-loops` using what you know so far.

## Exercise 23. Meet Duff’s Device

This exercise is a brain teaser where I introduce you to one of the most famous hacks in C called Duff’s device, named after Tom Duff, its inventor. This little slice of awesome (evil?) has nearly everything you’ve been learning wrapped in one tiny, little package. Figuring out how it works is also a good, fun puzzle.

---

Warning!

Part of the fun of C is that you can come up with crazy hacks like this, but this is also what makes C annoying to use. It’s good to learn about these tricks because it gives you a deeper understanding of the language and your computer. But you should never use this. Always strive for easy-to-read code.

---

Discovered by Tom Duff, Duff’s device is a trick with the C compiler that actually shouldn’t work. I won’t tell you what it does yet since this is meant to be a puzzle for you to ponder and try to solve. You’ll get this code running and then try to figure out what it does, and *why* it does it this way.

`ex23.c`

---

[Click here to view code image](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch23_images.html#p120pro01a)

```
#include <stdio.h>

#include <string.h>

#include "dbg.h"

  4

int normal_copy(char *from, char *to, int count)

{

int i = 0;

  8

for (i = 0; i < count; i++) {

to[i] = from[i];

}

 12

return i;

}

 15

int duffs_device(char *from, char *to, int count)

{

{

int n = (count + 7) / 8;

 20

switch (count % 8) {

case 0:

do {

*to++ = *from++;

case 7:

*to++ = *from++;

case 6:

*to++ = *from++;

case 5:

*to++ = *from++;

case 4:

*to++ = *from++;

case 3:

*to++ = *from++;

case 2:

*to++ = *from++;

case 1:

*to++ = *from++;

} while (--n > 0);

}

}

 42

return count;

}

 45

int zeds_device(char *from, char *to, int count)

{

{

int n = (count + 7) / 8;

 50

switch (count % 8) {

case 0:

again:    *to++ = *from++;

 54

case 7:

*to++ = *from++;

case 6:

*to++ = *from++;

case 5:

*to++ = *from++;

case 4:

*to++ = *from++;

case 3:

*to++ = *from++;

case 2:

*to++ = *from++;

case 1:

*to++ = *from++;

if (--n > 0)

goto again;

}

}

 73

return count;

}

 76

int valid_copy(char *data, int count, char expects)

{

int i = 0;

for (i = 0; i < count; i++) {

if (data[i] != expects) {

log_err("[%d] %c != %c", i, data[i], expects);

return 0;

}

}

 86

return 1;

}

 89

int main(int argc, char *argv[])

{

char from[1000] = { 'a' };

char to[1000] = { 'c' };

int rc = 0;

 95

// set up the from to have some stuff

memset(from, 'x', 1000);

// set it to a failure mode

memset(to, 'y', 1000);

check(valid_copy(to, 1000, 'y'), "Not initialized right.");

101

// use normal copy to

rc = normal_copy(from, to, 1000);

check(rc == 1000, "Normal copy failed: %d", rc);

check(valid_copy(to, 1000, 'x'), "Normal copy failed.");

106

// reset

memset(to, 'y', 1000);

109

// duffs version

rc = duffs_device(from, to, 1000);

check(rc == 1000, "Duff's device failed: %d", rc);

check(valid_copy(to, 1000, 'x'), "Duff's device failed copy.");

114

// reset

memset(to, 'y', 1000);

117

// my version

rc = zeds_device(from, to, 1000);

check(rc == 1000, "Zed's device failed: %d", rc);

check(valid_copy(to, 1000, 'x'), "Zed's device failed copy.");

122

return 0;

error:

return 1;

}
```

In this code, I have three versions of a copy function:

**normal_copy** This is just a plain `for-loop` that copies characters from one array to another.

**duffs_device** This is called Duff’s device, named after Tom Duff, the person to blame for this delicious evil.

**zeds_device** A version of Duff’s device that just uses a `goto` so you can clue in to what’s happening with the weird `do-while` placement in `duffs_device`.

Study these three functions before continuing. Try to explain what’s going on to yourself.

### What You Should See

There’s no output from this program, it just runs and exits. Run it under your debugger to see if you can catch any more errors. Try causing some of your own, as I showed you in [Exercise 4](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch04.html#ch04).

### Solving the Puzzle

The first thing to understand is that C is rather loose regarding some of its syntax. This is why you can put half of a `do-while` in one part of a `switch-statement`, then the other half somewhere else, and the code will still work. If you look at my version with the `goto again`, it’s actually more clear what’s going on, but make sure you understand how that part works.

The second thing is how the default fallthrough semantics of `switch-statements` let you jump to a particular case, and then it will just keep running until the end of the switch.

The final clue is the `count % 8` and the calculation of `n` at the top.

Now, to solve how these functions work, do the following:

• Print this code out so that you can write on some paper.

• Write each of the variables in a table as they look when they get initialized right before the `switch-statement`.

• Follow the logic to the switch, then do the jump to the right case.

• Update the variables, including the `to`, `from`, and the arrays they point at.

• When you get to the `while` part or my `goto` alternative, check your variables, and then follow the logic either back to the top of the `do-while` or to where the `again` label is located.

• Follow through this manual tracing, updating the variables, until you’re sure you see how this flows.

#### Why Bother?

When you’ve figured out how it actually works, the final question is: Why would you ever want to do this? The purpose of this trick is to manually do loop unrolling. Large, long loops can be slow, so one way to speed them up is to find some fixed chunk of the loop, and then just duplicate the code in the loop that many times sequentially. For example, if you know a loop runs a minimum of 20 times, then you can put the contents of the loop 20 times in the source code.

Duff’s device is basically doing this automatically by chunking up the loop into eight iteration chunks. It’s clever and actually works, but these days a good compiler will do this for you. You shouldn’t need this except in the rare case where you have *proven* it would improve your speed.

### Extra Credit

• Never use this again.

• Go look at the Wikipedia entry for Duff’s device and see if you can spot the error. Read the article, compare it to the version I have here, and try to understand why the Wikipedia code won’t work for you but worked for Tom Duff.

• Create a set of macros that lets you create any length of device like this. For example, what if you wanted to have 32 case statements and didn’t want to write out all of them? Can you do a macro that lays down eight at a time?

• Change the `main` to conduct some speed tests to see which one is really the fastest.

• Read about `memcpy`, `memmove`, and `memset`, and also compare their speed.

• Never use this again!

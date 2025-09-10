## Exercise 24. Input, Output, Files

You’ve been using `printf` to print things, and that’s great and all, but you need more. In this exercise, you’ll be using the functions `fscanf` and `fgets` to build information about a person in a structure. After this simple introduction about reading input, you’ll get a full list of the functions that C has for I/O. Some of these you’ve already seen and used, so this will be another memorization exercise.

`ex24.c`

---

[Click here to view code image](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch24_images.html#p126pro01a)

```
#include <stdio.h>

#include "dbg.h"

  3

#define MAX_DATA 100

  5

typedef enum EyeColor {

BLUE_EYES, GREEN_EYES, BROWN_EYES,

BLACK_EYES, OTHER_EYES

} EyeColor;

 10

const char *EYE_COLOR_NAMES[] = {

"Blue", "Green", "Brown", "Black", "Other"

};

 14

typedef struct Person {

int age;

char first_name[MAX_DATA];

char last_name[MAX_DATA];

EyeColor eyes;

float income;

} Person;

 22

int main(int argc, char *argv[])

{

Person you = {.age = 0 };

int i = 0;

char *in = NULL;

 28

printf("What's your First Name? ");

in = fgets(you.first_name, MAX_DATA - 1, stdin);

check(in != NULL, "Failed to read first name.");

 32

printf("What's your Last Name? ");

in = fgets(you.last_name, MAX_DATA - 1, stdin);

check(in != NULL, "Failed to read last name.");

 36

printf("How old are you? ");

int rc = fscanf(stdin, "%d", &you.age);

check(rc > 0, "You have to enter a number.");

 40

printf("What color are your eyes:\n");

for (i = 0; i <= OTHER_EYES; i++) {

printf("%d) %s\n", i + 1, EYE_COLOR_NAMES[i]);

}

printf("> ");

 46

int eyes = -1;

rc = fscanf(stdin, "%d", &eyes);

check(rc > 0, "You have to enter a number.");

 50

you.eyes = eyes - 1;

check(you.eyes <= OTHER_EYES

&& you.eyes >= 0, "Do it right, that's not an option.");

 54

printf("How much do you make an hour? ");

rc = fscanf(stdin, "%f", &you.income);

check(rc > 0, "Enter a floating point number.");

 58

printf("----- RESULTS -----\n");

 60

printf("First Name: %s", you.first_name);

printf("Last Name: %s", you.last_name);

printf("Age: %d\n", you.age);

printf("Eyes: %s\n", EYE_COLOR_NAMES[you.eyes]);

printf("Income: %f\n", you.income);

 66

return 0;

error:

 69

return -1;

}
```

This program is deceptively simple, and introduces a function called `fscanf`, which is the file `scanf`. The `scanf` family of functions are the inverse of the `printf` versions. Where `printf` printed out data based on a format, `scanf` reads (or scans) input based on a format.

There’s nothing original in the beginning of the file, so here’s what the `main` is doing in the program:

**ex24.c:24-28** Sets up some variables we’ll need.

**ex24.c:30-32** Gets your first name using the `fgets` function, which reads a string from the input (in this case `stdin`), but makes sure it doesn’t overflow the given buffer.

**ex24.c:34-36** Same thing for `you.last_name`, again using `fgets`.

**ex24.c:38-39** Uses `fscanf` to read an integer from `stdin` and put it into `you.age`. You can see that the same format string is used as `printf` to print an integer. You should also see that you have to give the *address* of `you.age` so that `fscanf` has a pointer to it and can modify it. This is a good example of using a pointer to a piece of data as an out parameter.

**ex24.c:41-45** Prints out all of the options available for eye color, with a matching number that works with the `EyeColor` enum above.

**ex24.c:47-50** Using `fscanf` again, gets a number for the `you.eyes`, but make sure the input is valid. This is important because someone can enter a value outside the `EYE_COLOR_ NAMES` array and cause a segmentation fault.

**ex24.c:52-53** Gets how much you make as a `float` for the `you.income`.

**ex24.c:55-61** Prints everything out so you can see if you have it right. Notice that `EYE_COLOR_NAMES` is used to print out what the `EyeColor` enum is actually called.

### What You Should See

When you run this program, you should see your inputs being properly converted. Make sure you try to give it bogus input too, so you can see how it protects against the input.

`Exercise 24 Session`

---

[Click here to view code image](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch24_images.html#p128pro01a)

```bash
$ make ex24

cc -Wall -g -DNDEBUG    ex24.c    -o ex24

$ ./ex24

What's your First Name? Zed

What's your Last Name? Shaw

How old are you? 37

What color are your eyes:

1) Blue

2) Green

3) Brown

4) Black

5) Other

> 1

How much do you make an hour? 1.2345

----- RESULTS -----

First Name: Zed

Last Name: Shaw

Age: 37

Eyes: Blue

Income: 1.234500
```

### How to Break It

This is all fine and good, but the really important part of this exercise is how `scanf` actually sucks. It’s fine for a simple conversion of numbers, but fails for strings because it’s difficult to tell `scanf` how big a buffer is before you read it. There’s also a problem with the function `gets` (not `fgets`, the non-f version), which we avoided. That function has no idea how big the input buffer is at all and will just trash your program.

To demonstrate the problems with `fscanf` and strings, change the lines that use `fgets` so they are `fscanf(stdin, "%50s", you.first_name)`, and then try to use it again. Notice it seems to read too much and then eat your enter key? This doesn’t do what you think it does, and rather than deal with weird `scanf` issues, you should just use `fgets`.

Next, change the `fgets` to use `gets`, then run your `debugger` on `ex24`. Do this inside:

```
"run << /dev/urandom"
```

This feeds random garbage into your program. This is called fuzzing your program, and it’s a good way to find input bugs. In this case, you’re feeding garbage from the `/dev/urandom` file (device), and then watching it crash. In some platforms, you may have to do this a few times, or even adjust the `MAX_DATA` define so it’s small enough.

The `gets` function is so bad that some platforms actually warn you when the *program* runs that you’re using `gets`. You should never use this function, ever.

Finally, take the input for `you.eyes` and remove the check that the number is within the right range. Then, feed it bad numbers like -1 or 1000. Do this under the debugger so you can see what happens there, too.

### The I/O Functions

This is a short list of various I/O functions that you should look up. Create flash cards that have the function name and all the variants similar to it.

• `fscanf`

• `fgets`

• `fopen`

• `freopen`

• `fdopen`

• `fclose`

• `fcloseall`

• `fgetpos`

• `fseek`

• `ftell`

• `rewind`

• `fprintf`

• `fwrite`

• `fread`

Go through these and memorize the different variants and what they do. For example, for the card `fscanf`, you’ll have `scanf`, `sscanf`, `vscanf`, etc., and then what each of those does on the back.

Finally, use `man` to read the help for each variant to get the information you need for the flash cards. For example, the page for `fscanf` comes from `man fscanf`.

### Extra Credit

• Rewrite this to not use `fscanf` at all. You’ll need to use functions like `atoi` to convert the input strings to numbers.

• Change this to use plain `scanf` instead of `fscanf` to see what the difference is.

• Fix it so that their input names get stripped of the trailing newline characters and any white space.

• Use `scanf` to write a function that reads one character at a time and fills in the names but doesn’t go past the end. Make this function generic so it can take a size for the string, but just make sure you end the string with `'\0'` no matter what.

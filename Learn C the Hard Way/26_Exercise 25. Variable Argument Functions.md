## Exercise 25. Variable Argument Functions

In C, you can create your own versions of functions like `printf` and `scanf` by creating a *variable argument* function, or vararg function. These functions use the header `stdarg.h`, and with them, you can create nicer interfaces to your library. They are handy for certain types of builder functions, formatting functions, and anything that takes variable arguments.

Understanding vararg functions is *not* essential to creating C programs. I think I’ve used it maybe 20 times in my code in all of the years I’ve been programming. However, knowing how a vararg function works will help you debug the programs you use and gives you a better understanding of the computer.

`ex25.c`

---

[Click here to view code image](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch25_images.html#p132pro01a)

```
  1

  2

#include <stdlib.h>

#include <stdio.h>

#include <stdarg.h>

#include "dbg.h"

  7

#define MAX_DATA 100

  9

int read_string(char **out_string, int max_buffer)

{

*out_string = calloc(1, max_buffer + 1);

check_mem(*out_string);

 14

char *result = fgets(*out_string, max_buffer, stdin);

check(result != NULL, "Input error.");

 17

return 0;

 19

error:

if (*out_string) free(*out_string);

*out_string = NULL;

return -1;

}

 25

int read_int(int *out_int)

{

char *input = NULL;

int rc = read_string(&input, MAX_DATA);

check(rc == 0, "Failed to read number.");

 31

*out_int = atoi(input);

 33

free(input);

return 0;

 36

error:

if (input) free(input);

return -1;

}

 41

int read_scan(const char *fmt, ...)

{

int i = 0;

int rc = 0;

int *out_int = NULL;

char *out_char = NULL;

char **out_string = NULL;

int max_buffer = 0;

 50

va_list argp;

va_start(argp, fmt);

 53

for (i = 0; fmt[i] != '\0'; i++) {

if (fmt[i] == '%') {

i++;

switch (fmt[i]) {

case '\0':

sentinel("Invalid format, you ended with %%.");

break;

 61

case 'd':

out_int = va_arg(argp, int *);

rc = read_int(out_int);

check(rc == 0, "Failed to read int.");

break;

 67

case 'c':

out_char = va_arg(argp, char *);

*out_char = fgetc(stdin);

break;

 72

case 's':

max_buffer = va_arg(argp, int);

out_string = va_arg(argp, char **);

rc = read_string(out_string, max_buffer);

check(rc == 0, "Failed to read string.");

break;

 79

default:

sentinel("Invalid format.");

}

} else {

fgetc(stdin);

}

 86

check(!feof(stdin) && !ferror(stdin), "Input error.");

}

 89

va_end(argp);

return 0;

 92

error:

va_end(argp);

return -1;

}

 97

int main(int argc, char *argv[])

{

char *first_name = NULL;

char initial = ' ';

char *last_name = NULL;

int age = 0;

104

printf("What's your first name? ");

int rc = read_scan("%s", MAX_DATA, &first_name);

check(rc == 0, "Failed first name.");

108

printf("What's your initial? ");

rc = read_scan("%c\n", &initial);

check(rc == 0, "Failed initial.");

112

printf("What's your last name? ");

rc = read_scan("%s", MAX_DATA, &last_name);

check(rc == 0, "Failed last name.");

116

printf("How old are you? ");

rc = read_scan("%d", &age);

119

printf("---- RESULTS ----\n");

printf("First Name: %s", first_name);

printf("Initial: '%c'\n", initial);

printf("Last Name: %s", last_name);

printf("Age: %d\n", age);

125

free(first_name);

free(last_name);

return 0;

error:

return -1;

}
```

This program is similar to the previous exercise, except I have written my own `scanf` function to handle strings the way I want. The main function should be clear to you, as well as the two functions `read_string` and `read_int`, since they do nothing new.

The varargs function is called `read_scan`, and it does the same thing that `scanf` is doing using the `va_list` data structure and supporting macros and functions. Here’s how:

• I set as the last parameter of the function the keyword `...` to indicate to C that this function will take any number of arguments after the `fmt` argument. I could put many other arguments before this, but I can’t put any more after this.

• After setting up some variables, I create a `va_list` variable and initialize it with `va_start`. This configures the gear in `stdarg.h` that handles variable arguments.

• I then use a `for-loop` to loop through the format string `fmt` and process the same kind of formats that `scanf` has, only much simpler. I just have integers, characters, and strings.

• When I hit a format, I use the `switch-statement` to figure out what to do.

• Now, to *get* a variable from the `va_list argp`, I use the macro `va_arg(argp, TYPE)` where TYPE is the exact type of what I will assign this function parameter to. The downside to this design is that you’re flying blind, so if you don’t have enough parameters, then oh well, you’ll most likely crash.

• The interesting difference from `scanf` is I’m assuming that people want `read_scan` to create the strings it reads when it hits an `'s'` format sequence. When you give this sequence, the function takes two parameters off the `va_list argp` stack: the max function size to read, and the output character string pointer. Using that information, it just runs `read_string` to do the real work.

• This makes `read_scan` more consistent than `scanf`, since you *always* give an address-of `&` on variables to have them set appropriately.

• Finally, if the function encounters a character that’s not in the correct format, it just reads one char to skip it. It doesn’t care what that char is, just that it should skip it.

### What You Should See

When you run this one, it’s similar to the last one.

`Exercise 25 Session`

---

[Click here to view code image](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch25_images.html#p135pro01a)

```bash
$ make ex25

cc -Wall -g -DNDEBUG    ex25.c   -o ex25

$ ./ex25

What's your first name? Zed

What's your initial? A

What's your last name? Shaw

How old are you? 37

---- RESULTS ----

First Name: Zed

Initial: 'A'

Last Name: Shaw

Age: 37
```

### How to Break It

This program should be more robust against buffer overflows, but it doesn’t handle the formatted input as well as `scanf`. To try to break this, change the code so that you forget to pass in the initial size for ‘%s’ formats. Try giving it more data than `MAX_DATA`, and then see how omitting `calloc` in `read_string` changes how it works. Finally, there’s a problem where `fgets` eats the newlines, so try to fix that using `fgetc`, but leave out the `\0` that ends the string.

### Extra Credit

• Make double and triple sure that you know what each of the `out_` variables is doing. Most importantly, you should know what `out_string` is and how it’s a pointer to a pointer, so that you understand when you’re setting the pointer versus the contents is important.

• Write a similar function to `printf` that uses the varargs system, and rewrite `main` to use it.

• As usual, read the man page on all of this so that you know what it does on your platform. Some platforms will use macros, others will use functions, and some will have these do nothing. It all depends on the compiler and the platform you use.

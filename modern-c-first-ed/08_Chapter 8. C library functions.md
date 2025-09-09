# Chapter 8. C library functions

### This chapter covers

- Doing math, handling files, and processing strings
- Manipulating time
- Managing the runtime environment
- Terminating programs

The functionality that the C standard provides is separated into two big parts. One is the proper C language, and the other is the *C library*. We have looked at several functions that come with the C library, including **printf**, **puts**, and **strtod**, so you should have a good idea what to expect: basic tools that implement features that we need in everyday programming and for which we need clear interfaces and semantics to ensure portability.

On many platforms, the clear specification through an *application programming interface* (*API*) also allows us to separate the compiler implementation from the library implementation. For example, on Linux systems, we have a choice of different compilers, most commonly `gcc` and `clang`, and different C library implementations, such as the GNU C library (`glibc`), `dietlibc`, or `musl`; potentially, any of these choices can be used to produce an executable.

We will first discuss the general properties and tools of the C library and its interfaces, and then describe some groups of functions: mathematical (numerical) functions, input/output functions, string processing, time handling, access to the runtime environment, and program termination.

## 8.1. General properties of the C library and its functions

Roughly, library functions target one or two purposes:

- ***Platform abstraction layer:*** Functions that abstract from the specific properties and needs of the platform. These are functions that need platform-specific bits to implement basic operations such as IO, which could not be implemented without deep knowledge of the platform. For example, **puts** has to have some concept of a “terminal output” and how to address it. Implementing these functionalities would exceed the knowledge of most C programmers, because doing so requires OS- or even processor-specific magic. Be glad that some people did that job for you.
-  ***Basic tools:*** Functions that implement a task (such as **strtod**) that often occurs in programming in C and for which it is important that the interface is fixed. These should be implemented relatively efficiently, because they are used a lot, and they should be well tested and bug free so we can rely safely on them. Implementing such functions should in principle be possible for any confirmed C programmer.[[[Exs 1]](/book/modern-c/chapter-8/ch08fn-ex01)]

[Exs 1] Write a function my_strtod that implements the functionality of **strtod** for decimal floating-point constants.

A function like **printf** can be viewed as targeting both purposes: it can effectively be separated into a formatting phase providing a basic tool and an output phase that is platform specific. There is a function **snprintf** (explained much later, in [section 14.1](/book/modern-c/chapter-14/ch14lev1sec1)) that provides the same formatting functionalities as **printf** but stores the result in a string. This string could then be printed with **puts** to give the same output as **printf** as a whole.

In the following chapters, we will discuss the different header files that declare the interfaces of the C library ([section 8.1.1](/book/modern-c/chapter-8/ch08lev2sec1)), the different types of interfaces it provides ([section 8.1.2](/book/modern-c/chapter-8/ch08lev2sec2)), the various error strategies it applies ([section 8.1.3](/book/modern-c/chapter-8/ch08lev2sec3)), an optional series of interfaces intended to improve application safety ([section 8.1.4](/book/modern-c/chapter-8/ch08lev2sec4)), and tools that we can use to assert platform-specific properties at compile time ([section 8.1.5](/book/modern-c/chapter-8/ch08lev2sec5)).

### 8.1.1. Headers

The C library has a lot of functions, far more than we can handle in this book. A *header**C* file bundles interface descriptions for a number of features, mostly functions. The header files that we will discuss here provide features of the C library, but later we can create our own interfaces and collect them in headers ([chapter 10](/book/modern-c/chapter-10/ch10)).

On this level, we will discuss the functions from the C library that are necessary for basic programming with the elements of the language we have seen so far. We will complete this discussion on higher levels, when we discuss a range of concepts. [Table 8.1](/book/modern-c/chapter-8/ch08table01) has an overview of the standard header files.

### 8.1.2. Interfaces

Most interfaces in the C library are specified as functions, but implementations are free to choose to implement them as macros, where doing so is appropriate. Compared to those we saw in [section 5.6.3](/book/modern-c/chapter-5/ch05lev2sec8), this uses a second form of macros that are syntactically similar to functions, *function-like macros**C*:

```
#define putchar(A) putc(A, stdout)
```

##### Table 8.1. C library headers[(view table figure)](https://drek4537l1klr.cloudfront.net/gustedt/HighResolutionFigures/table_8-1.png)

| Name | Description | Section |
| --- | --- | --- |
| <assert.h> | Asserting runtime conditions | 8.7 |
| <complex.h> | Complex numbers | 5.7.7 |
| <ctype.h> | Character classification and conversion | 8.4 |
| <errno.h> | Error codes | 8.1.3 |
| <fenv.h> | Floating-point environment |  |
| <float.h> | Properties of floating-point types | 5.7 |
| <inttypes.h> | Formatting conversion of integer types | 5.7.6 |
| <iso646.h> | Alternative spellings for operators | 4.1 |
| <limits.h> | Properties of integer types | 5.1.3 |
| <locale.h> | Internationalization | 8.6 |
| <math.h> | Type-specific mathematical functions | 8.2 |
| <setjmp.h> | Non-local jumps | 17.5 |
| <signal.h> | Signal-handling functions | 17.6 |
| <stdalign.h> | Alignment of objects | 12.7 |
| <stdarg.h> | Functions with varying numbers of arguments | 16.5.2 |
| <stdatomic.h> | Atomic operations | 17.6 |
| <stdbool.h> | Booleans | 3.1 |
| <stddef.h> | Basic types and macros | 5.2 |
| <stdint.h> | Exact-width integer types | 5.7.6 |
| <stdio.h> | Input and output | 8.3 |
| <stdlib.h> | Basic functions | 2 |
| <stdnoreturn.h> | Non-returning functions | 7 |
| <string.h> | String handling | 8.4 |
| <tgmath.h> | Type-generic mathematical functions | 8.2 |
| <threads.h> | Threads and control structures | 18 |
| <time.h> | Handling time | 8.5 |
| <uchar.h> | Unicode characters | 14.3 |
| <wchar.h> | Wide strings | 14.3 |
| <wctype.h> | Wide character classification and conversion | 14.3 |

As before, these are just textual replacements, and since the replacement text may contain a macro argument several times, it would be bad to pass any expression with side effects to such a macro or function. Hopefully, our previous discussion about side effects ([takeaway 4.11](/book/modern-c/chapter-4/ch04note12)) has already convinced you not to do that.

Some of the interfaces we will look at have arguments or return values that are pointers. We can’t handle these completely yet, but in most cases we can get away with passing in known pointers or `0` for pointer arguments. Pointers as return values will only occur in situations where they can be interpreted as an error condition.

### 8.1.3. Error checking

C library functions usually indicate failure through a special return value. What value indicates the failure can be different and depends on the function itself. Generally, you have to look up the specific convention in the manual page for the functions. [Table 8.2](/book/modern-c/chapter-8/ch08table02) gives a rough overview of the possibilities. There are three categories that apply: a special value that indicates an error, a special value that indicates success, and functions that return some sort of positive counter on success and a negative value on failure.

##### Table 8.2. *Error return strategies for C library functions* Some functions may also indicate a specific error condition through the value of the **`errno`** macro.[(view table figure)](https://drek4537l1klr.cloudfront.net/gustedt/HighResolutionFigures/table_8-2.png)

| Failure return | Test | Typical case | Example |
| --- | --- | --- | --- |
| 0 | !value | Other values are valid | **fopen** |
| Special error code | value == code | Other values are valid | **puts**, **clock**, **mktime**, **strtod**, **fclose** |
| Nonzero value | value | Value otherwise unneeded | **fgetpos**, **fsetpos** |
| Special success code | value != code | Case distinction for failure condition | **thrd_create** |
| Negative value | value < 0 | Positive value is a counter | **printf** |

Typical error-checking code looks like the following:

```
if (puts("hello world") == EOF) {
  perror("can't output to terminal:");
  exit(EXIT_FAILURE);
}
```

Here we see that **puts** falls into the category of functions that return a special value on error, **`EOF`**, “end-of-file.” The **perror** function from `stdio.h` is then used to provide an additional diagnostic that depends on the specific error. **exit** ends the program execution. Don’t wipe failures under the carpet. In programming,

<stdio.h>##### Takeaway 8.1

*Failure is always an option.*

##### Takeaway 8.2

*Check the return value of library functions for errors.*

An immediate failure of the program is often the best way to ensure that bugs are detected and get fixed early in development.

##### Takeaway 8.3

*Fail fast, fail early, and fail often.*

C has one major state variable that tracks errors of C library functions: a dinosaur called **`errno`**. The **perror** function uses this state under the hood, to provide its diagnostic. If a function fails in a way that allows us to recover, we have to ensure that the error state also is reset; otherwise, the library functions or error checking might get confused:

![](https://drek4537l1klr.cloudfront.net/gustedt/Figures/comm.jpg)

```
void puts_safe(char const s[static 1]) {
  static bool failed = false;
  if (!failed && puts(s) == EOF) {
    perror("can't output to terminal:");
    failed = true;
    errno = 0;
  }
}
```

### 8.1.4. Bounds-checking interfaces

Many of the functions in the C library are vulnerable to *buffer overflow**C* if they are called with an inconsistent set of parameters. This led (and still leads) to a lot of security bugs and exploits and is generally something that should be handled very carefully.

C11 addressed this sort of problem by deprecating or removing some functions from the standard and by adding an optional series of new interfaces that check consistency of the parameters at runtime. These are the *bounds-checking interfaces* of *Annex K* of the C standard. Unlike most other features, this doesn’t come with its own header file but adds interfaces to others. Two macros regulate access to theses interface: **`__STDC_LIB_EXT1__`** tells whether this optional interfaces is supported, and **`__STDC_WANT_LIB_EXT1__`** switches it on. The latter must be set before any header files are included:

```
#if !__STDC_LIB_EXT1__
# error "This code needs bounds checking interface Annex K"
#endif
#define __STDC_WANT_LIB_EXT1__ 1

#include <stdio.h>

/* Use printf_s from here on. */
```

This mechanism was (and still is) open to much debate, and therefore Annex K is an optional feature. Many modern platforms have consciously chosen not to support it. There even has been an extensive study by O’Donell and Sebor [[2015](/book/modern-c/bibliography/bib13)] that concluded that the introduction of these interfaces has created many more problems than it solved. In the following, such optional features are marked with a gray background.

##### Annex K

The bounds-checking functions usually use the suffix _s on the name of the library function they replace, such as **printf_s** for **printf**. So you should not use that suffix for code of your own.

|   |
| --- |

##### Takeaway 8.4

##### Takeaway 8.4

*Identifier names terminating with* *`_s`* *are reserved.*

|   |
| --- |

If such a function encounters an inconsistency, a *runtime constraint violation**C*, it usually should end program execution after printing a diagnostic.

### 8.1.5. Platform preconditions

An important goal of programming with a standardized language such as C is portability. We should make as few assumptions about the execution platform as possible and leave it to the C compiler and library to fill in the gaps. Unfortunately, this is not always an option, in which case we should clearly identify code preconditions.

##### Takeaway 8.5

*Missed preconditions for the execution platform must abort compilation.*

The classic tools to achieve this are *preprocessor conditionals**C*, as we saw earlier:

```
#if !__STDC_LIB_EXT1__
# error "This code needs bounds checking interface Annex K"
#endif
```

As you can see, such a conditional starts with the token sequence **`# if`** on a line and terminates with another line containing the sequence **`# endif`**. The **`# error`** directive in the middle is executed only if the condition (here `!`**`__STDC_LIB_EXT1__`**) is true. It aborts the compilation process with an error message. The conditions that we can place in such a construct are limited.[[[Exs 2]](/book/modern-c/chapter-8/ch08fn-ex02)]

[Exs 2] Write a preprocessor condition that tests whether **`int`** has two’s complement sign representation.

##### Takeaway 8.6

*Only evaluate macros and integer literals in a preprocessor condition.*

As an extra feature in these conditions, identifiers that are unknown evaluate to `0`. So, in the previous example, the expression is valid, even if **`__STDC_LIB_EXT1__`** is unknown at that point.

##### Takeaway 8.7

*In preprocessor conditions, unknown identifiers evaluate to* *`0`**.*

If we want to test a more sophisticated condition, **`_Static_assert`** (a keyword) and **`static_assert`** (a macro from the header `assert.h`) have a similar effect and are at our disposal:

<assert.h>```
#include <assert.h>
static_assert(sizeof(double) == sizeof(long double),
"Extra precision needed for convergence.");
```

## 8.2. Mathematics

Mathematical *functions* come with the `math.h` header, but it is much simpler to use the type-generic macros that come with `tgmath.h`. Basically, for all functions, it has a macro that dispatches an invocation such as **`sin`**`(`x`)` or **`pow`**`(`x`,` n`)` to the function that inspects the type of x in its argument and for which the return value is of that same type.

`<math.h>`

`<tgmath.h>`

The type-generic macros that are defined are far too many to describe in detail here. [Table 8.3](/book/modern-c/chapter-8/ch08table03) gives an overview of the functions that are provided.

##### Table 8.3. *Mathematical functions* In the electronic versions of the book, type-generic macros appear in red, and plain functions in green.[(view table figure)](https://drek4537l1klr.cloudfront.net/gustedt/HighResolutionFigures/table_8-3.png)


| Function | Description |
| --- | --- |
| **abs**, **labs**, **llabs** | \|*x*\| for integers |
| **acosh** | Hyperbolic arc cosine |
| **acos** | Arc cosine |
| **asinh** | Hyperbolic arc sine |
| **asin** | Arc sine |
| **atan2** | Arc tangent, two arguments |
| **atanh** | Hyperbolic arc tangent |
| **atan** | Arc tangent |
| **cbrt** |  |
| **ceil** | ⌈*x*⌉ |
| **copysign** | Copies the sign from *y* to *x* |
| **cosh** | Hyperbolic cosine |
| **cos** | Cosine function, cos *x* |
| **div**, **ldiv**, **lldiv** | Quotient and remainder of integer division |
| **erfc** | Complementary error function, |
| **erf** | Error function, |
| **exp2** | 2*x* |
| **expm1** | *e**x* – 1 |
| **exp** | *e**x* |
| **fabs** | \|*x*\| for floating point |
| **fdim** | Positive difference |
| **floor** | *⌊**x**⌋* |
| **fmax** | Floating-point maximum |
| **fma** | *x* · *y* + *z* |
| **fmin** | Floating-point minimum |
| **fmod** | Remainder of floating-point division |
| **fpclassify** | Classifies a floating-point value |
| **frexp** | Significand and exponent |
| **hypot** |  |
| **ilogb** | ⌊log*FLT*_*RADIX**x**⌋* as integer |
| **isfinite** | Checks if finite |
| **isinf** | Checks if infinite |
| **isnan** | Checks if NaN |
| **isnormal** | Checks if normal |
| **ldexp** | *x* · 2*y* |
| **lgamma** | log*e* Γ(*x*) |
| **log10** | log10*x* |
| **log1p** | log*e*(1 + *x*) |
| **log2** | log2*x* |
| **logb** | log*FLT*_*RADIX**x* as floating point |
| **log** | log*e* *x* |
| **modf**, **modff**, **modfl** | Integer and fractional parts |
| **nan**, **nanf**, **nanl** | Not-a-number (NaN) of the corresponding type |
| **nearbyint** | Nearest integer using the current rounding mode |
| **nextafter**, **nexttoward** | Next representable floating-point value |
| **pow** | *x**y* |
| **remainder** | Signed remainder of division |
| **remquo** | Signed remainder and the last bits of the division |
| **rint**, **lrint**, **llrint** | Nearest integer using the current rounding mode |
| **round**, **lround**, **llround** | sign(x) ·⌊\|*x*\| + 0.5⌋ |
| **scalbn**, **scalbln** | *x* · **FLT_RADIX***y* |
| **signbit** | Checks if negative |
| **sinh** | Hyperbolic sine |
| **sin** | Sine function, sin *x* |
| **sqrt** |  |
| **tanh** | Hyperbolic tangent |
| **tan** | Tangent function, tan *x* |
| **tgamma** | Gamma function, Γ(*x*) |
| **trunc** | sign(x) ·⌊\|*x*\|⌋ |

Nowadays, implementations of numerical functions should be high quality, be efficient, and have well-controlled numerical precision. Although any of these functions could be implemented by a programmer with sufficient numerical knowledge, you should not try to replace or circumvent them. Many of them are not just implemented as C functions but also can use processor-specific instructions. For example, processors may have fast approximations of **`sqrt`** and **`sin`** functions, or implement a *floating-point multiply add*, **`fma`**, in a low-level instruction. In particular, there is a good chance that such low-level instructions are used for all functions that inspect or modify floating-point internals, such as **carg**, **`creal`**, **`fabs`**, **`frexp`**, **`ldexp`**, **`llround`**, **`lround`**, **`nearbyint`**, **`rint`**, **`round`**, **`scalbn`**, and **`trunc`**. So, replacing them or reimplementing them in handcrafted code is usually a bad idea.

## 8.3. Input, output, and file manipulation

We have seen some of the IO functions that come with the header file `stdio.h`: **puts** and **printf**. Whereas the second lets you format output in a convenient fashion, the first is more basic: it just outputs a string (its argument) and an end-of-line character.

<stdio.h>### 8.3.1. Unformatted text output

There is an even more basic function than **puts**: **`putchar`**, which outputs a single character. The interfaces of these two functions are as follows:

```
int putchar(int c);
int puts(char const s[static 1]);
```

The type **`int`** as a parameter for **`putchar`** is a historical accident that shouldn’t hurt you much. In contrast to that, having a return type of **`int`** is necessary so the function can return errors to its caller. In particular, it returns the argument c if successful and a specific negative value **`EOF`** (*E*nd *O*f *F*ile) that is guaranteed not to correspond to any character on failure.

![](https://drek4537l1klr.cloudfront.net/gustedt/Figures/comm.jpg)

With this function, we could actually reimplement **puts** ourselves:

```
int puts_manually(char const s[static 1]) {
for (size_t i = 0; s[i]; ++i) {
if (putchar(s[i]) == EOF) return EOF;
}
if (putchar('\n') == EOF) return EOF;
return 0;
}
```

This is just an example; it is probably less efficient than the **puts** that your platform provides.

Up to now, we have only seen how to output to the terminal. Often, you’ll want to write results to permanent storage, and the type **`FILE`**`*` for *streams**C* provides an abstraction for this. There are two functions, **fputs** and **fputc**, that generalize the idea of unformatted output to streams:

```
int fputc(int c, FILE* stream);
int fputs(char const s[static 1], FILE* stream);
```

Here, the `*` in the **`FILE`**`*` type again indicates that this is a pointer type, and we won’t go into the details. The only thing we need to know for now is that a pointer can be tested whether it is null ([takeaway 6.20](/book/modern-c/chapter-6/ch06note21)), so we will be able to test whether a stream is valid.

The identifier **`FILE`** represents an *opaque type**C*, for which we don’t know more than is provided by the functional interfaces that we will see in this chapter. The fact that it is implemented as a macro, and the misuse of the name “FILE” for a stream is a reminder that this is one of the historical interfaces that predate standardization.

![](https://drek4537l1klr.cloudfront.net/gustedt/Figures/comm.jpg)

##### Takeaway 8.8

*Opaque types are specified through functional interfaces.*

##### Takeaway 8.9

*Don’t rely on implementation details of opaque types.*

If we don’t do anything special, two streams are available for output: **`stdout`** and **`stderr`**. We have already used **`stdout`** implicitly: this is what **`putchar`** and **puts** use under the hood, and this stream is usually connected to the terminal. **`stderr`** is similar and also is linked to the terminal by default, with perhaps slightly different properties. In any case, these two are closely related. The purpose of having two of them is to be able to distinguish “usual” output (**`stdout`**) from “urgent” output (**`stderr`**).

We can rewrite the previous functions in terms of the more general ones:

```
int putchar_manually(int c) {
return fputc(c, stdout);
}
int puts_manually(char const s[static 1]) {
if (fputs(s,    stdout) == EOF) return EOF;
if (fputc('\n', stdout) == EOF) return EOF;
return 0;
}
```

Observe that **fputs** differs from **puts** in that it doesn’t append an end-of-line character to the string.

##### Takeaway 8.10

**puts** *and* **fputs** *differ in their end-of-line handling.*

### 8.3.2. Files and streams

If we want to write output to real files, we have to attach the files to our program execution by means of the function **fopen**:

```
FILE* fopen(char const path[static 1], char const mode[static 1]);
FILE* freopen(char const path[static 1], char const mode[static 1],
FILE *stream);
```

This can be used as simply as here:

```
int main(int argc, char* argv[argc+1]) {
FILE* logfile = fopen("mylog.txt", "a");
if (!logfile) {
perror("fopen failed");
return EXIT_FAILURE;
}
fputs("feeling fine today\n", logfile);
return EXIT_SUCCESS;
}
```

This *opens a file**C* called "mylog.txt" in the file system and provides access to it through the variable logfile. The mode argument "a" opens the file for appending: that is, the contents of the file are preserved, if they exist, and writing begins at the current end of that file.

There are multiple reasons why opening a file might not succeed: for example, the file system might be full, or the process might not have permission to write at the indicated place. We check for such an error condition ([takeaway 8.2](/book/modern-c/chapter-8/ch08note03)) and exit the program if necessary.

As we have seen, the **perror** function is used to give a diagnostic of the error that occurred. It is equivalent to something like the following:

```
fputs("fopen failed: some-diagnostic\n", stderr);
```

This “some-diagnostic” might (but does not have to) contain more information that helps the user of the program deal with the error.

##### Annex K

There are also bounds-checking replacements **fopen_s** and **freopen_s**, which ensure that the arguments that are passed are valid pointers. Here, **`errno_t`** is a type that comes with `stdlib.h` and encodes error returns. The **`restrict`** keyword that also newly appears only applies to pointer types and is out of our scope for the moment:

```
errno_t fopen_s(FILE* restrict streamptr[restrict],
char const filename[restrict], char const mode[restrict
]);
errno_t freopen_s(FILE* restrict newstreamptr[restrict],
char const filename[restrict], char const mode[
restrict],
FILE* restrict stream);
```

There are different modes to open a file; "a" is only one of several possibilities. [Table 8.4](/book/modern-c/chapter-8/ch08table04) contains an overview of the characters that may appear in that string. Three base modes regulate what happens to a pre-existing file, if any, and where the stream is positioned. In addition, three modifiers can be appended to them. [Table 8.5](/book/modern-c/chapter-8/ch08table05) has a complete list of the possible combinations.

##### Table 8.4. *Modes and modifiers for **fopen** and **freopen*** One of the first three must start the mode string, optionally followed by one or more of the other three. See [table 8.5](/book/modern-c/chapter-8/ch08table05) for all valid combinations.[(view table figure)](https://drek4537l1klr.cloudfront.net/gustedt/HighResolutionFigures/table_8-4.png)


| Mode | Memo |   | File status after **fopen** |
| --- | --- | --- | --- |
| 'a' | Append | w | File unmodified; position at end |
| 'w' | Write | w | Content of file wiped out, if any |
| 'r' | Read | r | File unmodified; position at start |
| Modifier | Memo |  | Additional property |
| '+' | Update | rw | Opens file for reading and writing |
| 'b' | Binary |  | Views as a binary file; otherwise a text file |
| 'x' | Exclusive |  | Creates a file for writing if it does not yet exist |

##### Table 8.5. Mode strings for **fopen** and **freopen** *These are the valid combinations of the characters in [table 8.4](/book/modern-c/chapter-8/ch08table04).*[(view table figure)](https://drek4537l1klr.cloudfront.net/gustedt/HighResolutionFigures/table_8-5.png)


| "a" | Creates an empty text file if necessary; open for writing at end-of-file |
| --- | --- |
| "w" | Creates an empty text file or wipes out content; open for writing |
| "r" | Opens an existing text file for reading |
| "a+" | Creates an empty text file if necessary; open for reading and writing at end-of-file |
| "w+" | Creates an empty text file or wipes out content; open for reading and writing |
| "r+" | Opens an existing text file for reading and writing at beginning of file |
| "ab" "rb" "wb"<br>"a+b"    "ab+"<br>"r+b"    "rb+"<br>"w+b" "wb+" | Same as above, but for a binary file instead of a text file |
| "wx" "w+x" "wbx" "w+bx" "wb+x" | Same as above, but error if the file exists prior to the call |

These tables show that a stream can be opened not only for writing but also for reading; we will see shortly how that can be done. To know which of the base modes opens for reading or writing, just use your common sense. For 'a' and 'w', a file that is positioned at its end can’t be read, since there is nothing there; thus these open for writing. For 'r', file content that is preserved and positioned at the beginning should not be overwritten accidentally, so this is for reading.

The modifiers are used less commonly in everyday coding. “Update” mode with '+' should be used carefully. Reading and writing at the same time is not easy and needs some special care. For 'b', we will discuss the difference between text and binary streams in more detail in [section 14.4](/book/modern-c/chapter-14/ch14lev1sec4).

There are three other principal interfaces to handle streams, **freopen**, **fclose**, and **fflush**:

```
int fclose(FILE* fp);
int fflush(FILE* stream);
```

The primary uses for **freopen** and **fclose** are straightforward: **freopen** can associate a given stream to a different file and eventually change the mode. This is particularly useful to associate the standard streams to a file. *E.g* our little program from above could be rewritten as

```
int main(int argc, char* argv[argc+1]) {
if (!freopen("mylog.txt", "a", stdout)) {
perror("freopen failed");
return EXIT_FAILURE;
}
puts("feeling fine today");
return EXIT_SUCCESS;
}
```

### 8.3.3. Text IO

Output to text streams is usually *buffered**C*: that is, to make more efficient use of its resources, the IO system can delay the physical write of to a stream. If we close the stream with **fclose**, all buffers are guaranteed to be *flushed**C* to where it is supposed to go. The function **fflush** is needed in places where we want to see output immediately on the terminal, or where we don’t want to close the file yet but want to ensure that all content we have written has properly reached its destination. [Listing 8.1](/book/modern-c/chapter-8/ch08ex01) shows an example that writes 10 dots to **`stdout`** with a delay of approximately one second between all writes.[[[Exs 3]](/book/modern-c/chapter-8/ch08fn-ex03)]

[Exs 3] Observe the behavior of the program by running it with zero, one, and two command-line arguments. 

##### Listing 8.1. flushing buffered output

```
1   #include <stdio.h>
2
3   /* delay execution with some crude code,
4      should use thrd_sleep, once we have that*/
5   void delay(double secs) {
6     double const magic = 4E8;   // works just on my machine
7     unsigned long long const nano = secs* magic;
8     for (unsigned long volatile count = 0;
9          count < nano;
10          ++count) {
11       /* nothing here */
12     }
13   }
14
15   int main(int argc, char* argv[argc+1]) {
16     fputs("waiting 10 seconds for you to stop me", stdout);
17     if (argc < 3) fflush(stdout);
18     for (unsigned i = 0; i < 10; ++i) {
19       fputc('.', stdout);
20       if (argc < 2) fflush(stdout);
21       delay(1.0);
22     }
23     fputs("\n", stdout);
24     fputs("You did ignore me, so bye bye\n", stdout);
25   }
```

The most common form of IO buffering for text files is *line buffering**C*. In that mode, output is only physically written if the end of a text line is encountered. So usually, text that is written with **puts** appears immediately on the terminal; **fputs** waits until it encounters an '\n' in the output. Another interesting thing about text streams and files is that there is no one-to-one correspondence between characters that are written in the program and bytes that land on the console device or in the file.

##### Takeaway 8.11

*Text input and output converts data.*

This is because internal and external representations of text characters are not necessarily the same. Unfortunately, there are still many different character encodings; the C library is in charge of doing the conversions correctly, if it can. Most notoriously, the end-of-line encoding in files is platform dependent:

##### Takeaway 8.12

*There are three commonly used conversions to encode end-of-line.*

C gives us a very suitable abstraction in using '\n' for this, regardless of the platform. Another modification you should be aware of when doing text IO is that white space that precedes the end of line may be suppressed. Therefore, the presence of *trailing white space**C* such as blank or tabulator characters cannot be relied upon and should be avoided:

##### Takeaway 8.13

*Text lines should not contain trailing white space.*

The C library additionally also has very limited support for manipulating files within the file system:

```
int remove(char const pathname[static 1]);
int rename(char const oldpath[static 1], char const newpath[static 1]);
```

These basically do what their names indicate.

##### Table 8.6. Format specifications for **printf** and similar functions, with the general syntax "%[FF][WW][.PP][LL]SS", where **`[]`** surrounding a field denotes that it is optional.[(view table figure)](https://drek4537l1klr.cloudfront.net/gustedt/HighResolutionFigures/table_8-6.png)


| FF | Flags | Special form of conversion |
| --- | --- | --- |
| WW | Field width | minimum width |
| PP | Precision |  |
| LL | Modifier | Select width of type |
| SS | Specifier | Select conversion |

### 8.3.4. Formatted output

We have covered how to use **printf** for formatted output. The function **fprintf** is very similar to that, but it has an additional parameter that allows us to specify the stream to which the output is written:

```
int printf(char const format[static 1], ...);
int fprintf(FILE* stream, char const format[static 1], ...);
```

The syntax with the three dots `...` indicates that these functions may receive an arbitrary number of items that are to be printed. An important constraint is that this number must correspond exactly to the '%' specifiers; otherwise the behavior is undefined:

##### Takeaway 8.14

*Parameters of* **printf** *must exactly correspond to the format specifiers.*

With the syntax `%[`FF`][`WW`][.`PP`][`LL`]`SS, a complete format specification can be composed of five parts: flags, width, precision, modifiers, and specifier. See [table 8.6](/book/modern-c/chapter-8/ch08table06) for details.

The specifier is not optional and selects the type of output conversion that is performed. See [table 8.7](/book/modern-c/chapter-8/ch08table07) for an overview.

As you can see, for most types of values, there is a choice of format. You should chose the one that is most appropriate for the *meaning* of the value that the output is to convey. For all numerical *values*, this should usually be a decimal format.

##### Takeaway 8.15

*Use* *`"%d"`* *and* *`"%u"`* *formats to print integer values.*

If, on the other hand, you are interested in a bit pattern, use the hexadecimal format over octal. It better corresponds to modern architectures that have 8-bit character types.

##### Takeaway 8.16

*Use the* *`"%x"`* *format to print bit patterns.*

Also observe that this format receives unsigned values, which is yet another incentive to only use unsigned types for bit sets. Seeing hexadecimal values and associating the corresponding bit pattern requires training. [Table 8.8](/book/modern-c/chapter-8/ch08table08) has an overview of the digits, the values, and the bit pattern they represent.

For floating-point formats, there is even more choice. If you do not have specific needs, the generic format is the easiest to use for decimal output.

##### Table 8.7. Format specifiers for **printf** and similar functions[(view table figure)](https://drek4537l1klr.cloudfront.net/gustedt/HighResolutionFigures/table_8-7.png)


| 'd' or 'i' | Decimal | Signed integer |
| --- | --- | --- |
| 'u' | Decimal | Unsigned integer |
| 'o' | Octal | Unsigned integer |
| 'x' or 'X' | Hexadecimal | Unsigned integer |
| 'e' or 'E' | [-]d.ddd e±dd, “scientific” | Floating point |
| 'f' or 'F' | [-]d.ddd | Floating point |
| 'g' or 'G' | generic e or f | Floating point |
| 'a' or 'A' | [-]0xh.hhhh p±d, Hexadecimal | Floating point |
| '%' | '%' character | No argument is converted. |
| 'c' | Character | Integer |
| 's' | Characters | String |
| 'p' | Address | **void*** pointer |

##### Table 8.8. Hexadecimal values and bit patterns[(view table figure)](https://drek4537l1klr.cloudfront.net/gustedt/HighResolutionFigures/table_8-8.png)


| Digit | Value | Pattern |
| --- | --- | --- |
| 0 | 0 | 0000 |
| 1 | 1 | 0001 |
| 2 | 2 | 0010 |
| 3 | 3 | 0011 |
| 4 | 4 | 0100 |
| 5 | 5 | 0101 |
| 6 | 6 | 0110 |
| 7 | 7 | 0111 |
| 8 | 8 | 1000 |
| 9 | 9 | 1001 |
| A | 10 | 1010 |
| B | 11 | 1011 |
| C | 12 | 1100 |
| D | 13 | 1101 |
| E | 14 | 1110 |
| F | 15 | 1111 |

##### Takeaway 8.17

*Use the* *`"%g"`* *format to print floating-point values.*

The modifier part is important to specify the exact type of the corresponding argument. [Table 8.9](/book/modern-c/chapter-8/ch08table09) gives the codes for the types we have encountered so far. This modifier is particularly important because interpreting a value with the wrong modifier can cause severe damage. The **printf** functions only have knowledge about their arguments through the format specifiers, so giving a function the wrong size may lead it to read more or fewer bytes than provided by the argument or to interpret the wrong hardware registers.

##### Takeaway 8.18

*Using an inappropriate format specifier or modifier makes the behavior undefined.*

A good compiler should warn about wrong formats; please take such warnings seriously. Note also the presence of special modifiers for the three semantic types. In particular, the combination "%zu" is very convenient because we don’t have to know the base type to which **`size_t`** corresponds.

##### Table 8.9. Format modifiers for **printf** and similar functions **`float`** arguments are first converted to **`double`**.[(view table figure)](https://drek4537l1klr.cloudfront.net/gustedt/HighResolutionFigures/table_8-9.png)


| Character | Type | Conversion |
| --- | --- | --- |
| "hh" | **char** types | Integer |
| "h" | **short** types | Integer |
| "" | **signed**, **unsigned** | Integer |
| "l" | **long** integer types | integer |
| "ll" | **long long** integer types | Integer |
| "j" | **intmax_t**, **uintmax_t** | Integer |
| "z" | **size_t** | Integer |
| "t" | **ptrdiff_t** | Integer |
| "L" | **long double** | Floating point |

##### Table 8.10. Format flags for **printf** and similar functions[(view table figure)](https://drek4537l1klr.cloudfront.net/gustedt/HighResolutionFigures/table_8-10.png)


| Character | Meaning | Conversion |
| --- | --- | --- |
| "#" | Alternate form, such as prefix 0x | "aAeEfFgGoxX" |
| "0" | Zero padding | Numeric |
| "-" | Left adjustment | Any |
| " " | ' ' for positive values, '-' for negative | Signed |
| "+" | '+' for positive values, '-' for negative | Signed |

The width (WW) and precision (`.`PP) can be used to control the general appearance of a printed value. For example, for the generic floating-point format "%g", the precision controls the number of significant digits. A format of "%20.10g" specifies an output field of 20 characters with at most 10 significant digits. How these values are interpreted specifically differs for each format specifier.

The flag can change the output variant, such as prefixing with signs ("%+d"), 0x for hexadecimal conversion ("%#X"), `0` for octal ("%#o"), padding with `0`, or adjusting the output within its field to the left instead of the right. See [table 8.10](/book/modern-c/chapter-8/ch08table10). Remember that a leading zero for integers is usually interpreted as introducing an octal number, not a decimal. So using zero padding with left adjustment "%-0" is not a good idea because it can confuse the reader about the convention that is applied.

If we know that the numbers we write will be read back in from a file later, the forms "%+d" for signed types, "%#X" for unsigned types, and "%a" for floating point are the most appropriate. They guarantee that the string-to-number conversions will detect the correct form and that the storage in a file will not lose information.

##### Takeaway 8.19

*Use* *`"%+d"`**,* *`"%#X"`**, and* *`"%a"`* *for conversions that have to be read later.*

##### Annex K

The optional interfaces **printf_s** and **fprintf_s** check that the stream, the format, and any string arguments are valid pointers. They don’t check whether the expressions in the list correspond to correct format specifiers:

```
int printf_s(char const format[restrict], ...);
int fprintf_s(FILE *restrict stream,
char const format[restrict], ...);
```

Here is a modified example for reopening **`stdout`**:

```
int main(int argc, char* argv[argc+1]) {
int ret = EXIT_FAILURE;
fprintf_s(stderr, "freopen of %s:", argv[1]);
if (freopen(argv[1], "a", stdout)) {
ret = EXIT_SUCCESS;
puts("feeling fine today");
}
perror(0);
return ret;
}
```

This improves the diagnostic output by adding the filename to the output string. **fprintf_s** is used to check the validity of the stream, the format, and the argument string. This function may mix the output of the two streams if they are both connected to the same terminal.

### 8.3.5. Unformatted text input

Unformatted input is best done with **fgetc** for a single character and **fgets** for a string. The **`stdin`** standard stream is always defined and usually connects to terminal input:

```
int fgetc(FILE* stream);
char* fgets(char s[restrict], int n, FILE* restrict stream);
int getchar(void);
```

##### Annex K

In addition, there are also **getchar** and **gets_s**, which read from **`stdin`** but don’t add much to the previous interfaces that are more generic:

```
char* gets_s(char s[static 1], rsize_t n);
```

Historically, in the same spirit in which **puts** specializes **fputs**, the prior version of the C standard had a **`gets`** interface. This has been removed because it was inherently unsafe.

##### Takeaway 8.20

*Don’t use* **`gets`***.*

The following listing shows a function that has functionality equivalent to **fgets**.

##### Listing 8.2. Implementing **fgets** in terms of **fgetc**

```
1   char* fgets_manually(char s[restrict], int n,
2                        FILE*restrict stream) {
3     if (!stream) return 0;
4     if (!n) return s;
5     /* Reads at most n-1 characters */
6     for (size_t pos = 0; pos < n-1; ++pos) {
7        int val = fgetc(stream);
8        switch (val) {
9          /* EOF signals end-of-file or error */
10         case EOF: if (feof(stream)) {
11           s[i] = 0;
12           /* Has been a valid call */
13           return s;
14         } else {
15           /* Error */
16           return 0;
17         }
18         /* Stop at end-of-line. */
19         case '\n': s[i] = val; s[i+1] = 0; return s;
20         /* Otherwise just assign and continue. */
21         default: s[i] = val;
22       }
23    }
24    s[n-1] = 0;
25    return s;
26  }
```

Again, such example code is not meant to replace the function, but to illustrate properties of the functions in question: here, the error-handling strategy.

##### Takeaway 8.21

**fgetc** *returns* **`int`** *to be able to encode a special error status,* **`EOF`***, in addition to all valid characters.*

Also, detecting a return of **`EOF`** alone is not sufficient to conclude that the end of the stream has been reached. We have to call **feof** to test whether a stream’s position has reached its end-of-file marker.

##### Takeaway 8.22

*End of file can only be detected* after *a failed read.*

[Listing 8.3](/book/modern-c/chapter-8/ch08ex03) presents an example that uses both input and output functions.

##### Listing 8.3. A program to dump multiple text files to **`stdout`**

```
1  #include <stdlib.h>
2  #include <stdio.h>
3  #include <errno.h>
4
5  enum { buf_max = 32, };
6
7  int main(int argc, char* argv[argc+1]) {
8    int ret = EXIT_FAILURE;
9    char buffer[buf_max] = { 0 };
10    for (int i = 1; i < argc; ++i) {        // Processes args
11      FILE* instream = fopen(argv[i], "r"); // as filenames
12    if (instream) {
13      while (fgets(buffer, buf_max, instream)) {
14        fputs(buffer, stdout);
15       }
16       fclose(instream);
17       ret = EXIT_SUCCESS;
18     } else {
19       /* Provides some error diagnostic. */
20       fprintf(stderr, "Could not open %s: ", argv[i]);
21       perror (0);
22       errno = 0;                       // Resets the error code
23     }
24   }
25   return ret;
26 }
```

This is a small implementation of cat that reads a number of files that are given on the command line and dumps the contents to **`stdout`**.[[[Exs 4]](/book/modern-c/chapter-8/ch08fn-ex04)][[[Exs 5]](/book/modern-c/chapter-8/ch08fn-ex05)][[[Exs 6]](/book/modern-c/chapter-8/ch08fn-ex06)][[[Exs 7]](/book/modern-c/chapter-8/ch08fn-ex07)]

[Exs 4] Under what circumstances will this program finish with success or failure return codes? 

[Exs 5] Surprisingly, this program even works for files with lines that have more than 31 characters. Why? 

[Exs 6] Have the program read from **`stdin`** if no command-line argument is given. 

[Exs 7] Have the program precede all output lines with line numbers if the first command-line argument is "-n". 

## 8.4. String processing and conversion

String processing in C has to deal with the fact that the source and execution environments may have different encodings. It is therefore crucial to have interfaces that work independently of the encoding. The most important tools are given by the language itself: integer character constants such as 'a' and '\n' and string literals such as "hello:\tx" should always do the right thing on your platform. As you perhaps remember, there are no constants for types that are narrower than **`int`**; and, as an historical artifact, integer character constants such as 'a' have type **`int`**, not **`char`** as you would probably expect.

![](https://drek4537l1klr.cloudfront.net/gustedt/Figures/comm.jpg)

Handling such constants can become cumbersome if you have to deal with character classes.

Therefore, the C library provides functions and macros that deal with the most commonly used classes through the header `ctype.h`. It has the classifiers **isalnum**, **isalpha**, **isblank**, **iscntrl**, **isdigit**, **isgraph**, **islower**, **isprint**, **ispunct**, **isspace**, **isupper**, and **isxdigit**, and conversions **toupper** and **tolower**. Again, for historical reasons, all of these take their arguments as **`int`** and also return **`int`**. See [table 8.11](/book/modern-c/chapter-8/ch08table11) for an overview of the classifiers. The functions **toupper** and **tolower** convert alphabetic characters to the corresponding case and leave all other characters as they are.

<ctype.h>The table has some special characters such as '\n' for a new-line character, which we have encountered previously. All the special encodings and their meaning are given in [table 8.12](/book/modern-c/chapter-8/ch08table12).

![](https://drek4537l1klr.cloudfront.net/gustedt/Figures/comm.jpg)

Integer character constants can also be encoded numerically: as an octal value of the form '\037' or as a hexadecimal value in the form '\xFFFF'. In the first form, up to three octal digits are used to represent the code. For the second, any sequence of characters after the x that can be interpreted as a hex digit is included in the code. Using these in strings requires special care to mark the end of such a character: "\xdeBruyn" is not the same as "\xde" "Bruyn"[[1](/book/modern-c/chapter-8/ch08fn01)] but corresponds to "\xdeB" "ruyn", the character with code `3563` followed by the four characters 'r', 'u', 'y', and 'n'. Using this feature is only portable in the sense that it will compile on all platforms as long as a character with code `3563` exists. Whether it exists and what that character actually is depends on the platform and the particular setting for program execution.

1 But remember that consecutive string literals are concatenated ( [takeaway 5.18](/book/modern-c/chapter-5/ch05note18)). 

##### Table 8.11. *Character classifiers* The third column indicates whether C implementations may extend these classes with platform-specific characters, such as 'ä' as a lowercase character or '€' as punctuation.[(view table figure)](https://drek4537l1klr.cloudfront.net/gustedt/HighResolutionFigures/table_8-11.png)


| Name | Meaning | C locale | Extended |
| --- | --- | --- | --- |
| **islower** | Lowercase | 'a' *...* 'z' | Yes |
| **isupper** | Uppercase | 'A' *...* 'Z' | Yes |
| **isblank** | Blank | ' ', '\t' | Yes |
| **isspace** | Space | ' ', '\f', '\n', '\r', '\t', '\v' | Yes |
| **isdigit** | Decimal | '0' *...* '9' | No |
| **isxdigit** | Hexadecimal | '0' *...* '9', 'a' *...* 'f', 'A' *...* 'F' | No |
| **iscntrl** | Control | '\a', '\b', '\f', '\n', '\r', '\t', '\v' | Yes |
| **isalnum** | Alphanumeric | **isalpha**(x)\|\|**isdigit**(x) | Yes |
| **isalpha** | Alphabet | **islower**(x)\|\|**isupper**(x) | Yes |
| **isgraph** | Graphical | (!**iscntrl**(x)) && (x != ' ') | Yes |
| **isprint** | Printable | !**iscntrl**(x) | Yes |
| **ispunct** | Punctuation | **isprint**(x)&&!(**isalnum**(x)\|\|**isspace**(x)) | Yes |

##### Table 8.12. Special characters in character and string literals[(view table figure)](https://drek4537l1klr.cloudfront.net/gustedt/HighResolutionFigures/table_8-12.png)


| '\'' | Quote |
| --- | --- |
| '\"' | Double quotes |
| '\?' | Question mark |
| '\\' | Backslash |
| '\a' | Alert |
| '\b' | Backspace |
| '\f' | Form feed |
| '\n' | New line |
| '\r' | Carriage return |
| '\t' | Horizontal tab |
| '\v' | Vertical tab |

##### Takeaway 8.23

*The interpretation of numerically encoded characters depends on the execution character set.*

So, their use is not fully portable and should be avoided.

The following function hexatridecimal uses some of these functions to provide a base 36 numerical value for all alphanumerical characters. This is analogous to hexadecimal constants, only all other letters have a value in base 36, too:[[[Exs 8]](/book/modern-c/chapter-8/ch08fn-ex08)][[[Exs 9]](/book/modern-c/chapter-8/ch08fn-ex09)][[[Exs 10]](/book/modern-c/chapter-8/ch08fn-ex10)]

[Exs 8] The second **`return`** of hexatridecimal makes an assumption about the relation between a and 'A'. What is it? 

[Exs 9] Describe an error scenario in which this assumption is not fulfilled. 

[Exs 10] Fix this bug: that is, rewrite this code such that it makes no assumption about the relation between a and 'A': 

##### `strtoul.c`

```
8   /* Supposes that lowercase characters are contiguous. */
9   static_assert('z'-'a' == 25,
10                  "alphabetic characters not contiguous");
11   #include <ctype.h>
12   /* Converts an alphanumeric digit to an unsigned */
13   /* '0' ...  '9'  =>  0 ..  9u  */
14   /* 'A' ...  'Z'  => 10 ..  35u */
15   /* 'a' ...  'z'  => 10 ..  35u */
16   /* Other values =>    Greater */
17   unsigned hexatridecimal(int a) {
18     if (isdigit(a)) {
19       /* This is guaranteed to work: decimal digits
20          are consecutive, and isdigit is not
21          locale dependent. */
22     return a -  '0';
23     } else {
24       /* Leaves a unchanged if it is not lowercase */
25       a = toupper(a);
26       /* Returns value >= 36 if not Latin uppercase*/
27       return (isupper(a)) ? 10 + (a - 'A') : -1;
28     }
29   }
```

In addition to **strtod**, the C library has **strtoul**, **strtol**, **strtoumax**, **strtoimax**, **strtoull**, **strtoll**, **strtold**, and **strtof** to convert a string to a numerical value.

Here the characters at the end of the names correspond to the type: u for **`unsigned`**, l (the letter “el") for **`long`**, d for **`double`**, f for float, and `[`i|`u`]max for **`intmax_t`** and **`uintmax_t`**.

The interfaces with an integral return type all have three parameters, such as **strtoul**

```
unsigned long int strtoul(char const nptr[restrict],
char** restrict endptr,
int base);
```

which interprets a string nptr as a number given in base base. Interesting values for base are `0`, `8`, `10`, and `16`. The last three correspond to octal, decimal, and hexadecimal encoding, respectively. The first, `0`, is a combination of these three, where the base is chosen according to the usual rules for the interpretation of text as numbers: "7" is decimal, "007" is octal, and "0x7" is hexadecimal. More precisely, the string is interpreted as potentially consisting of four different parts: white space, a sign, the number, and some remaining data.

The second parameter can be used to obtain the position of the remaining data, but this is still too involved for us. For the moment, it suffices to pass a `0` for that parameter to ensure that everything works well. A convenient combination of parameters is often **strtoul**`(`S`, 0, 0)`, which will try to interpret S as representing a number, regardless of the input format. The three functions that provide floating-point values work similarly, only the number of function parameters is limited to two.

Next, we will demonstrate how such functions can be implemented from more basic primitives. Let us first look at Strtoul_inner. It is the core of a **strtoul** implementation that uses hexatridecimal in a loop to compute a large integer from a string:

##### `strtoul.c`

```
31   unsigned long Strtoul_inner(char const s[static 1],
32                               size_t i,
33                               unsigned base) {
34     unsigned long ret = 0;
35     while (s[i]) {
36       unsigned c = hexatridecimal(s[i]);
37       if (c >= base) break;
38       /* Maximal representable value for 64 bit is
39          3w5e11264sgsf in base 36 */
40       if (ULONG_MAX/base < ret) {
41         ret = ULONG_MAX;
42         errno = ERANGE;
43         break;
44      }
45      ret *= base;
46      ret += c;
47      ++i;
48     }
49     return ret;
50   }
```

If the string represents a number that is too big for an **`unsigned long`**, this function returns **`ULONG_MAX`** and sets **`errno`** to **`ERANGE`**.

Now Strtoul gives a functional implementation of **strtoul**, as far as this can be done without pointers:

##### `strtoul.c`

```
60  unsigned long Strtoul(char const s[static 1], unsigned base) {
61    if (base > 36u) {             /* Tests if base          */
62      errno = EINVAL;             /* Extends the specification */
63      return ULONG_MAX;
64    }
65    size_t i = strspn(s, " \f\n\r\t\v"); /* Skips spaces      */
66    bool switchsign = false;      /* Looks for a sign         */
67    switch (s[i]) {
68    case '-' : switchsign = true;
69    case '+' : ++i;
70    }
71    if (!base || base == 16) {    /* Adjusts the base         */
72      size_t adj = find_prefix(s, i, "0x");
73      if (!base) base = (unsigned[]){ 10, 8, 16, }[adj];
74      i += adj;
75    }
76    /* Now, starts the real conversion*/
77    unsigned long ret = Strtoul_inner(s, i, base);
78    return (switchsign) ? -ret : ret;
79   }
```

It wraps Strtoul_inner and does the previous adjustments that are needed: it skips white space, looks for an optional sign, adjusts the base in case the base parameter was `0`, and skips an eventual `0` or 0x prefix. Observe also that if a minus sign has been provided, it does the correct negation of the result in terms of **`unsigned long`** arithmetic.[[[Exs 11]](/book/modern-c/chapter-8/ch08fn-ex11)]

[Exs 11] Implement a function find_prefix as needed by Strtoul. 

To skip the spaces, Strtoul uses **strspn**, one of the string search functions provided by `string.h`. This function returns the length of the initial sequence in the first parameter that entirely consists of any character from the second parameter. The function **strcspn** (“c” for “complement”) works similarly, but it looks for an initial sequence of characters not present in the second argument.

<string.h>This header provides at lot more memory and string search functions: **memchr**, **strchr**, **strpbrk strrchr**, **strstr**, and **strtok**. But to use them, we would need pointers, so we can’t handle them yet.

## 8.5. Time

The first class of times can be classified as calendar times, times with a granularity and range that would typically appear in a human calendar for appointments, birthdays, and so on. Here are some of the functional interfaces that deal with times and that are all provided by the `time.h` header:

<time.h>```
time_t time(time_t *t);
double difftime(time_t time1, time_t time0);
time_t mktime(struct tm tm[1]);
size_t strftime(char s[static 1], size_t max,
                char const format[static 1],
                struct tm const tm[static 1]);
int timespec_get(struct timespec ts[static 1], int base);
```

The first simply provides us with a timestamp of type **`time_t`** of the current time. The simplest form uses the return value of **time**`(0)`. As we have seen, two such times taken from different moments during program execution can then be used to express a time difference by means of **difftime**.

Let’s see what all this is doing from the human perspective. As we know, **`struct`** **`tm`** structures a calendar time mainly as you would expect. It has hierarchical date members such as **`tm_year`** for the year, **`tm_mon`** for the month, and so on, down to the granularity of a second. It has one pitfall, though: how the members are counted. All but one start with `0`: for example, **`tm_mon`** set to `0` stands for January, and **`tm_wday`** `0` stands for Sunday.

Unfortunately, there are exceptions:

- **`tm_mday`** starts counting days in the month at 1.
- **`tm_year`** must add 1900 to get the year in the Gregorian calendar. Years represented that way should be between Gregorian years 0 and 9999.
- **`tm_sec`** is in the range from 0 to 60, inclusive. The latter is for the rare occasion of leap seconds.

Three supplemental date members are used to supply additional information to a time value in a **`struct`** **`tm`**:

- **`tm_wday`** for the week day.
- **`tm_yday`** for the day in the year.
- **`tm_isdst`** is a flag that informs us whether a date is considered to be in DST for the local time zone.

The consistency of all these members can be enforced with the function **mktime**. It operates in three steps:

**1**.  The hierarchical date members are normalized to their respective ranges.

**2**.  **`tm_wday`** and **`tm_yday`** are set to the corresponding values.

**3**.  If tm_isday has a negative value, this value is modified to 1 if the date falls into DST for the local platform, or to `0` otherwise.

**mktime** also serves an extra purpose. It returns the time as a **`time_t`**. **`time_t`** represents the same calendar times as **`struct`** **`tm`** but is defined to be an arithmetic type, more suited to compute with such types. It operates on a linear time scale. A **`time_t`** value of `0` at the beginning of **`time_t`** is called the *epoch**C* in the C jargon. Often this corresponds to the beginning of Jan 1, 1970.

The granularity of **`time_t`** is usually to the second, but nothing guarantees that. Sometimes processor hardware has special registers for clocks that obey a different granularity. **difftime** translates the difference between two **`time_t`** values into seconds that are represented as a double value.

##### Annex K

Other traditional functions that manipulate time in C are a bit dangerous because they operate on global state. We will not discuss them here, but variants of these interfaces have been reviewed in Annex K in an _s form:

```
errno_t asctime_s(char s[static 1], rsize_t maxsize,
                  struct tm const timeptr[static 1]);
errno_t ctime_s(char s[static 1], rsize_t maxsize,
                const time_t timer[static 1]);
struct tm *gmtime_s(time_t const timer[restrict static 1],
                    struct tm result[restrict static 1]);
struct tm *localtime_s(time_t const timer[restrict static 1],
                       struct tm result[restrict static 1]);
```

[Figure 8.1](/book/modern-c/chapter-8/ch08fig01) shows how all these functions interact:

![Figure 8.1. Time conversion functions](https://drek4537l1klr.cloudfront.net/gustedt/Figures/08fig01_alt.jpg)

Two functions for the inverse operation from **`time_t`** into **`struct`** **`tm`** come into view:

- **localtime_s** stores the broken-down local time.
- **gmtime_s** stores the broken time, expressed as universal time, UTC.

As indicated, they differ in the time zone they assume for the conversion. Under normal circumstances, **localtime_s** and **mktime** should be inverse to each other; **gmtime_s** has no direct counterpart in the inverse direction.

Textual representations of calendar times are also available. **asctime_s** stores the date in a fixed format, independent of any locale, language (it uses English abbreviations), or platform dependency. The format is a string of the form

```
"Www Mmm DD HH:MM:SS YYYY\n"
```

**strftime** is more flexible and allows us to compose a textual representation with format specifiers.

It works similarly to the **printf** family but has special `%`-codes for dates and times; see [table 8.13](/book/modern-c/chapter-8/ch08table13). Here, the Locale column indicates that different environment settings, such as preferred language or time zone, may influence the output. How to access and eventually set these will be explained in [section 8.6](/book/modern-c/chapter-8/ch08lev1sec6). **strftime** receives three arrays: a **`char`**`[`max`]` array that is to be filled with the result string, another string that holds the format, and a **`struct`** **`tm`** **`const`**`[1]` that holds the time to be represented. The reason for passing in an array for the time will only become apparent when we know more about pointers.

##### Table 8.13. ***strftime** format specifiers* Those selected in the Locale column may differ dynamically according to locale runtime settings; see [section 8.6](/book/modern-c/chapter-8/ch08lev1sec6). Those selected in the ISO 8601 column are specified by that standard.[(view table figure)](https://drek4537l1klr.cloudfront.net/gustedt/HighResolutionFigures/table_8-13.png)

| Spec | Meaning | Locale | ISO 8601 |
| --- | --- | --- | --- |
| "%S" | Second ("00" to "60") |  |  |
| "%M" | Minute ("00" to "59") |  |  |
| "%H" | Hour ("00" to "23"). |  |  |
| "%I" | Hour ("01" to "12"). |  |  |
| "%e" | Day of the month (" 1" to "31") |  |  |
| "%d" | Day of the month ("01" to "31") |  |  |
| "%m" | Month ("01" to "12") |  |  |
| "%B" | Full month name | X |  |
| "%b" | Abbreviated month name | X |  |
| "%h" | Equivalent to "%b" | X |  |
| "%Y" | Year |  |  |
| "%y" | Year ("00" to "99") |  |  |
| "%C" | Century number (year/100) |  |  |
| "%G" | Week-based year; the same as "%Y", except if the ISO week number belongs another year |  | X |
| "%g" | Like "%G", ("00" to "99") |  | X |
| "%u" | Weekday ("1" to "7"), Monday being "1" |  |  |
| "%w" | Weekday ("0" to "6", Sunday being "0" |  |  |
| "%A" | Full weekday name | X |  |
| "%a" | Abbreviated weekday name | X |  |
| "%j" | Day of the year ("001" to "366") |  |  |
| "%U" | Week number in the year ("00" to "53"), starting at Sunday |  |  |
| "%W" | Week number in the year ("00" to "53"), starting at Monday |  |  |
| "%V" | Week number in the year ("01" to "53"), starting with first four days in the new year |  | X |
| "%Z" | Timezone name | X |  |
| "%z" | "+hhmm" or "-hhmm", the hour and minute offset from UTC |  |  |
| "%n" | Newline |  |  |
| "%t" | Horizontal tabulator |  |  |
| "%%" | Literal "%" |  |  |
| "%x" | Date | X |  |
| "%D" | Equivalent to "%m/%d/%y" |  |  |
| "%F" | Equivalent to "%Y-%m-%d" |  | X |
| "%X" | Time | X |  |
| "%p" | Either "AM" or "PM": noon is "PM", midnight is "AM" | X |  |
| "%r" | Equivalent to "%I:%M:%S %p" | X |  |
| "%R" | Equivalent to "%H:%M" |  |  |
| "%T" | Equivalent to "%H:%M:%S" |  | X |
| "%c" | Preferred date and time representation | X |  |

The opaque type **`time_t`** (and as a consequence **time** itself) only has a granularity of seconds.

If we need more precision than that, **`struct`** **`timespec`** and the **timespec_get** function can be used. With that, we have an additional member **`tv_nsec`** that provides nanosecond precision. The second argument, base, has only one value defined by the C standard: **`TIME_UTC`**. You should expect a call to **timespec_get** with that value to be consistent with calls to **time**. They both refer to Earth’s reference time. Specific platforms may provide additional values for base that specify a clock that is different from a clock on the wall. An example of such a clock could be relative to the planetary or other physical system your computer system is involved with.[[2](/book/modern-c/chapter-8/ch08fn02)] Relativity and other time adjustments can be avoided by using a *monotonic clock* that only refers to the startup time of the system. A CPU clock could refer to the time the program execution had been attributed processing resources.

2 Be aware that objects that move fast relative to Earth, such as satellites and spacecraft, may perceive relativistic time shifts compared to UTC.

For the latter, there is an additional interface that is provided by the C standard library:

```
clock_t clock(void);
```

For historical reasons, this introduces yet another type, **`clock_t`**. It is an arithmetic time that gives the processor time in **`CLOCKS_PER_SEC`** units per second.

Having three different interfaces, **time**, **timespec_get**, and **clock**, is a bit unfortunate. It would have been beneficial to provide predefined constants such as TIME_PROCESS_TIME and TIME_THREAD_TIME for other forms of clocks.

![](https://drek4537l1klr.cloudfront.net/gustedt/Figures/comm.jpg)

##### Performance comparison of sorting algorithms

Can you compare the time efficiency of your sorting programs ([challenge 1](/book/modern-c/chapter-3/ch03sb01)) with data sizes of several orders of magnitude?

Be careful to check that you have some randomness in the creation of the data and that the data size does not exceed the available memory of your computer.

For both algorithms, you should roughly observe a behavior that is proportional to *N* log *N*, where *N* is the number of elements that are sorted.

## 8.6. Runtime environment settings

A C program can access an *environment list**C*: a list of name-value pairs of strings (often called *environment variables**C*) that can transmit specific information from the runtime environment. There is a historical function **getenv** to access this list:

```
char* getenv(char const name[static 1]);
```

Given our current knowledge, with this function we are only able to test whether a name is present in the environment list:

```
bool havenv(char const name[static 1]) {
  return getenv(name);
}
```

Instead, we use the secured function **getenv_s**:

##### Annex K

```
errno_t getenv_s(size_t * restrict len,
                 char value[restrict],
                 rsize_t maxsize,
                 char const name[restrict]);
```

This function copies the value that corresponds to name (if any) from the environment into value, a **`char`**`[`maxsize`]`, provided that it fits. Printing such a value can look as this:

```
void printenv(char const name[static 1]) {
  if (getenv(name)) {
    char value[256] = { 0, };
    if (getenv_s(0, value, sizeof value, name)) {
      fprintf(stderr,
              "%s: value is longer than %zu\n",
              name, sizeof value);
    } else {
      printf("%s=%s\n", name, value);
    }
  } else {
    fprintf(stderr, "%s not in environment\n", name);
  }
}
```

As you can see, after detecting whether the environment variable exists, **getenv_s** can safely be called with the first argument set to `0`. Additionally, it is guaranteed that the value target buffer will only be written if the intended result fits in it. The len parameter could be used to detect the real length that is needed, and dynamic buffer allocation could be used to print out even large values. We will wait until higher levels to see such usages.

Which environment variables are available to programs depends heavily on the operating system. Commonly provided environment variables include "HOME" for the user’s home directory, "PATH" for the collection of standard paths to executables, and "LANG" or "LC_ALL" for the language setting.

The language or *locale**C* setting is another important part of the execution environment that a program execution inherits. At startup, C forces the locale setting to a normalized value, called the "C" locale. It has basically American English choices for numbers or times and dates.

<locale.h>The function **setlocale** from `locale.h` can be used to set or inspect the current value:

```
char* setlocale(int category, char const locale[static 1]);
```

In addition to "C", the C standard prescribes the existence of one other valid value for locale: the empty string "". This can be used to set the effective locale to the systems default. The category argument can be used to address all or only parts of the language environment. [Table 8.14](/book/modern-c/chapter-8/ch08table14) gives an overview over the possible values and the part of the C library they affect. Additional platform-dependent categories may be available.

##### Table 8.14. Categories for the **setlocale** function[(view table figure)](https://drek4537l1klr.cloudfront.net/gustedt/HighResolutionFigures/table_8-14.png)

| **LC_COLLATE** | String comparison through **strcoll** and **strxfrm** |
| --- | --- |
| **LC_CTYPE** | Character classification and handling functions; see [section 8.4](/book/modern-c/chapter-8/ch08lev1sec4). |
| **LC_MONETARY** | Monetary formatting information, **localeconv** |
| **LC_NUMERIC** | Decimal-point character for formatted I/O, **localeconv** |
| **LC_TIME** | **strftime**; see [section 8.5](/book/modern-c/chapter-8/ch08lev1sec5) |
| **LC_ALL** | All of the above |

## 8.7. Program termination and assertions

We have looked at the simplest way to terminate a program: a regular return from **main**.

##### Takeaway 8.24

*Regular program termination should use a* **`return`** *from* **main***.*

Using the function **exit** from within **main** is kind of senseless, because it can be done just as easily with a **`return`**.

##### Takeaway 8.25

*Use* **exit** *from a function that may terminate the regular control flow.*

The C library has three other functions that terminate program execution, in order of severity:

```
_Noreturn void quick_exit(int status);
_Noreturn void _Exit(int status);
_Noreturn void abort(void);
```

Now, **`return`** from **main** (or a call to **exit**) already provides the possibility to specify whether the program execution is considered to be a success. Use the return value to specify that; as long as you have no other needs or you don’t fully understand what these other functions do, don’t use them. Really: don’t.

##### Takeaway 8.26

*Don’t use functions other than* **exit** *for program termination, unless you have to inhibit the execution of library cleanups.*

Cleanup at program termination is important. The runtime system can flush and close files that are written or free other resources that the program occupied. This is a feature and should rarely be circumvented.

There is even a mechanism to install your own *handlers**C* that are to be executed at program termination. Two functions can be used for that:

```
int atexit(void func(void));
int at_quick_exit(void func(void));
```

These have a syntax we have not yet seen: *function parameters**C*. For example, the first reads “function **atexit** that returns an **`int`** and that receives a function func as a parameter.”[[3](/book/modern-c/chapter-8/ch08fn03)]

3 In fact, in C, such a notion of a function parameter func to a function **atexit** is equivalent to passing a *function pointer* *C* . In descriptions of such functions, you will usually see the pointer variant. For us, this distinction is not yet relevant; it is simpler to think of a function being passed by reference.

We will not go into detail here. An example will show how this can be used:

```
void sayGoodBye(void) {
  if (errno) perror("terminating with error condition");
  fputs("Good Bye\n", stderr);
}

int main(int argc, char* argv[argc+1]) {
  atexit(sayGoodBye);
  ...
}
```

This uses the function **atexit** to establish the **exit**-handler sayGoodBye. After normal termination of the program code, this function will be executed and give the status of the execution. This might be a nice way to impress your co-workers if you are in need of some respect. More seriously, this is the ideal place to put all kinds of cleanup code, such as freeing memory or writing a termination timestamp to a log file. Observe that the syntax for calling is **atexit**`(`sayGoodBye`)`. There are no `()` for sayGoodBye itself: here, sayGoodBye is not called at that point; only a reference to the function is passed to **atexit**.

Under rare circumstances, you might want to circumvent these established **atexit** handlers. There is a second pair of functions, **quick_exit** and **at_quick_exit**, that can be used to establish an alternative list of termination handlers. Such an alternative list may be useful if the normal execution of the handlers is too time consuming. Use with care.

The next function, **_Exit**, is even more severe: it inhibits both types of application-specific handlers to be executed. The only things that are executed are the platform-specific cleanups, such as file closure. Use this with even more care.

The last function, **abort**, is even more intrusive. Not only doesn’t it call the application handlers, but also it inhibits the execution of some system cleanups. Use this with extreme care.

At the beginning of this chapter, we looked at **`_Static_assert`** and **`static_assert`**, which should be used to make compile-time assertions. They can test for any form of compile-time Boolean expression. Two other identifiers come from `assert.h` and can be used for runtime assertions: **`assert`** and **`NDEBUG`**. The first can be used to test for an expression that must hold at a certain moment. It may contain any Boolean expression, and it may be dynamic. If the **`NDEBUG`** macro is not defined during compilation, every time execution passes by the call to this macro, the expression is evaluated. The functions gcd and gcd2 from [section 7.3](/book/modern-c/chapter-7/ch07lev1sec3) show typical use cases of **`assert`**: a condition that is supposed to hold in *every* execution.

<assert.h>If the condition doesn’t hold, a diagnostic message is printed, and **abort** is called. So, none of this should make it through into a production executable. From the earlier discussion, we know that the use of **abort** is harmful, in general, and also an error message such as

##### `Terminal`

```
0      assertion failed in file euclid.h, function gcd2(), line 6
```

is not very helpful for your customers. It *is* helpful during the debugging phase, where it can lead you to spots where you make false assumptions about the values of variables.

##### Takeaway 8.27

*Use as many* **`assert`***s as you can to confirm runtime properties.*

As mentioned, **`NDEBUG`** inhibits the evaluation of the expression and the call to **abort**. Please use it to reduce overhead.

##### Takeaway 8.28

*In production compilations, use* **`NDEBUG`** *to switch off all* **`assert`***.*

##### Image segmentation

In addition to the C standard library, there are many other support libraries out there that provide very different features. Among those are a lot that do image processing of some kind. Try to find a suitable such image-processing library that is written in or interfaced to C and that allows you to treat grayscale images as two-dimensional matrices of base type **`unsigned char`**.

The goal of this challenge is to perform a segmentation of such an image: to group the pixels (the **`unsigned char`** elements of the matrix) into connected regions that are “similar” in some sense or another. Such a segmentation forms a partition of the set of pixels, much as we saw in [challenge 4](/book/modern-c/chapter-4/ch04sb01). Therefore, you should use a Union-Find structure to represent regions, one per pixel at the start.

Can you implement a statistics function that computes a statistic for all regions? This should be another array (the third array in the game) that for each root holds the number of pixels and the sum of all values.

Can you implement a merge criterion for regions? Test whether the mean values of two regions are not too far apart: say, no more than five gray values.

Can you implement a line-by-line merge strategy that, for each pixel on a line of the image, tests whether its region should be merged to the left and/or to the top?

Can you iterate line by line until there are no more changes: that is, such that the resulting regions/sets all test negatively with their respective neighboring regions?

Now that you have a complete function for image segmentation, try it on images with assorted subjects and sizes, and also vary your merge criterion with different values for the mean distance instead of five.

## Summary

- The C library is interfaced via a bunch of header files.
- Mathematical functions are best used via the type-generic macros from `tgmath.h`.
- Input and output (IO) are interfaced via `stdio.h`. There are functions that do IO as text or as raw bytes. Text IO can be direct or structured by formats.
- String processing uses functions from `ctype.h` for character classification, from `stdlib` for numerical conversion, and from `string.h` for string manipulation.
- Time handling in `time.h` has *calendar time* that is structured for human interpretation, and *physical time* that is structured in seconds and nanoseconds.
- Standard C only has rudimentary interfaces to describe the execution environment of a running program; **getenv** provides access to environment variables, and `locale.h` regulates the interface for human languages.

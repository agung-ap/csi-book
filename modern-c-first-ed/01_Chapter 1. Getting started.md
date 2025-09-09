# Chapter 1. Getting started

### This chapter covers

- Introduction to imperative programming
- Compiling and running code

In this chapter, I will introduce you to one simple program that has been chosen because it contains many of the constructs of the C language. If you already have programming experience, you may find that parts of it feel like needless repetition. If you lack such experience, you might feel overwhelmed by the stream of new terms and concepts.

In either case, be patient. For those of you with programming experience, it’s very possible that there are subtle details you’re not aware of, or assumptions you have made about the language that are not valid, even if you have programmed C before. For those approaching programming for the first time, be assured that after approximately 10 pages your understanding will have increased a lot, and you should have a much clearer idea of what programming represents.

An important bit of wisdom for programming in general, and for this book in particular, is summarized in the following citation from the *Hitchhiker’s Guide to the Galaxy* by Douglas Adams [[1986](/book/modern-c/bibliography/bib1)]:

##### Takeaway B

*Don’t panic.*

It’s not worth it. There are many cross references, links, and bits of side information in the text, and there is an index at the end. Follow those if you have a question. Or just take a break.

Programming in C is about having the computer complete some specific tasks. A C program does that by giving orders, much as we would express such orders in the imperative tense in many human languages; thus the term *imperative programming* for this particular way of organizing computer programs. To get started and see what we are talking about, consider our first program in [listing 1.1](/book/modern-c/chapter-1/ch01ex01):

##### Listing 1.1. A first example of a C program

```
1   /* This may look like nonsense, but really is -*- mode: C -*- */
 2   #include <stdlib.h>
 3   #include <stdio.h>
 4
 5   /* The main thing that this program does. */
 6   int main(void) {
 7     // Declarations
 8     double A[5] = {
 9       [0] = 9.0,
10       [1] = 2.9,
11       [4] = 3.E+25,
12       [3] = .00007,
13     };
14
15     // Doing some work
16     for (size_t i = 0; i < 5; ++i) {
17         printf("element %zu is %g, \tits square is %g\n",
18                i,
19                A[i],
20                A[i]*A[i]);
21     }
22
23     return EXIT_SUCCESS;
24   }
```

## 1.1. Imperative programming

You probably see that this is a sort of language, containing some weird words like **main**, **`include`**, **`for`**, and so on, which are laid out and colored in a peculiar way and mixed with a lot of strange characters, numbers, and text (“*Doing some work*”) that looks like ordinary English. It is designed to provide a link between us, the human programmers, and a machine, the computer, to tell it what to do: to give it “orders.”

##### Takeaway 1.1

*C is an imperative programming language.*

In this book, we will not only encounter the C programming language, but also some vocabulary from an English dialect, C *jargon*, the language that helps us *to talk about C*. It will not be possible to immediately explain each term the first time it occurs. But I will explain each one in time, and all of them are indexed so you can easily cheat and *jump**C* to more explanatory text, at your own risk.[[1](/book/modern-c/chapter-1/ch01fn01)]

1 Such special terms from C jargon are marked with a *C*, as shown here.

As you can probably guess from this first example, such a C program has different components that form some intermixed layers. Let’s try to understand it from the inside out. The visible result of running this program is to output 5 lines of text on the command terminal of your computer. On my computer, using this program looks something like this:

##### `Terminal`

```
0   > ./getting-started
1   element 0 is 9,         its square is 81
2   element 1 is 2.9,       its square is 8.41
3   element 2 is 0,         its square is 0
4   element 3 is 7e-05,     its square is 4.9e-09
5   element 4 is 3e+25,     its square is 9e+50
```

We can easily identify within our program the parts of the text that this program outputs (*prints**C*, in C jargon): the part of line 17 between quotes. The real action happens between that line and line 20. C calls this a *statement**C*, which is a bit of a misnomer. Other languages would use the term *instruction*, which describes the purpose better. This particular statement is a *call**C* to a *function**C* named **printf**:

##### `getting-started.c`

```
17    printf("element %zu is %g, \tits square is %g\n",
18           i,
19           A[i],
20           A[i]*A[i]);
```

Here, the **printf** function receives four *arguments**C*, enclosed in a pair of *parentheses**C*, `( ... )`:

- The funny-looking text (between the quotes) is a so-called *string literal**C* that serves as a *format**C* for the output. Within the text are three markers (*format specifiers**C*) that indicate the positions in the output where numbers are to be inserted. These markers start with a `%` character. This format also contains some special *escape characters**C* that start with a backslash: `\`t and `\`n.
- After a comma character, we find the word i. The thing i stands for will be printed in place of the first format specifier, %zu.
- Another comma separates the next argument A`[`i`]`. The thing this stands for will be printed in place of the second format specifier, the first `%`g.
- Last, again separated by a comma, appears A`[`i`]*`A`[`i`]`, corresponding to the last `%`g.

We will later explain what all of these arguments mean. Just remember that we identified the main purpose of the program (to print some lines on the terminal) and that it “orders” the **printf** function to fulfill that purpose. The rest is some *sugar**C* to specify which numbers will be printed, and how many of them.

## 1.2. Compiling and running

As shown in the previous section, the program text expresses what we want our computer to do. As such, it is just another piece of text that we have written and stored somewhere on our hard disk, but the program text as such cannot be understood by your computer. There is a special program, called a *compiler*, that translates the C text into something that your machine can understand: the *binary code**C* or *executable**C*. What that translated program looks like and how this translation is done are much too complicated to explain at this stage.[[2](/book/modern-c/chapter-1/ch01fn02)] Even this entire book will not be able to explain most of it; that would be the subject of another whole book. However, for the moment, we don’t need to understand more deeply, as we have the tool that does all the work for us.

2 In fact, the *translation* itself is done in several steps that go from textual replacement, over proper compilation, to linking. Nevertheless, the tool that bundles all this is traditionally called a *compiler* and not a *translator*, which would be more accurate.

##### Takeaway 1.2

*C is a compiled programming language.*

The name of the compiler and its command-line arguments depend a lot on the *platform**C* on which you will be running your program. There is a simple reason for this: the target binary code is *platform dependent**C*: that is, its form and details depend on the computer on which you want to run it. A PC has different needs than a phone, and your refrigerator doesn’t speak the same “language” as your set-top box. In fact, that’s one of the reasons for C to exist: C provides a level of abstraction for all the different machine-specific languages (usually referred to as *assembler**C*).

##### Takeaway 1.3

*A correct C program is portable between different platforms.*

In this book, we will put a lot of effort into showing you how to write “correct” C programs that ensure portability. Unfortunately, there are some platforms that claim to be “C” but do not conform to the latest standards; and there are conforming platforms that accept incorrect programs or provide extensions to the C standard that are not widely portable. So, running and testing a program on a single platform will not always guarantee portability.

It is the job of the compiler to ensure that the little program shown earlier, once translated for the appropriate platform, will run correctly on your PC, your phone, your set-top box, and maybe even your refrigerator.

That said, if you have a POSIX system (such as Linux or macOS), there is a good chance that a program named `c99` might be present and that it is in fact a C compiler. You could try to compile the example program using the following command:

##### `Terminal`

```
0   > c99 -Wall -o getting-started getting-started.c -lm
```

The compiler should do its job without complaining and output an executable file called `getting-started` in your current directory.[[[Exs 1]](/book/modern-c/chapter-1/ch01fn-ex01)] In the example line,

[Exs 1] Try the compilation command in your terminal.

- `c99` is the compiler program.
- `-Wall` tells it to warn us about anything that it finds unusual.
- `-o getting-started` tells it to store the *compiler output**C* in a file named `getting-started`.
- `getting-started.c` names the *source file**C*, the file that contains the C code we have written. Note that the `.c` extension at the end of the filename refers to the C programming language.
- `-lm` tells it to add some standard mathematical functions if necessary; we will need those later on.

Now we can *execute**C* our newly created *executable**C*. Type in

##### `Terminal`

```
0   > ./getting-started
```

and you should see exactly the same output as I showed you earlier. That’s what *portable* means: wherever you run that program, its *behavior**C* should be the same.

If you are not lucky and the compilation command didn’t work, you will have to look up the name of your *compiler**C* in your system documentation. You might even have to install a compiler if one is not available.[[3](/book/modern-c/chapter-1/ch01fn03)] The names of compilers vary. Here are some common alternatives that might do the trick:

3 This is necessary in particular if you have a system with a Microsoft operating system. Microsoft’s native compilers do not yet fully support even C99, and many features that we discuss in this book will not work. For a discussion of the alternatives, you might have a look at Chris Wellons’ blog entry “Four Ways to Compile C for Windows” ([https://nullprogram.com/blog/2016/06/13/](https://nullprogram.com/blog/2016/06/13/)).

##### `Terminal`

```
0   > clang -Wall -lm -o getting-started getting-started.c
1   > gcc -std=c99 -Wall -lm -o getting-started getting-started.c
2   > icc -std=c99 -Wall -lm -o getting-started getting-started.c
```

Some of these, even if they are present on your computer, might not compile the program without complaining.[[[Exs 2]](/book/modern-c/chapter-1/ch01fn-ex02)]

[Exs 2] Start writing a text report about your tests with this book. Note down which command worked for you.

With the program in [listing 1.1](/book/modern-c/chapter-1/ch01ex01), we presented an ideal world: a program that works and produces the same result on all platforms. Unfortunately, when programming yourself, very often you will have a program that works only partially and that may produce wrong or unreliable results. Therefore, let us look at the program in [listing 1.2](/book/modern-c/chapter-1/ch01ex07). It looks quite similar to the previous one.

##### Listing 1.2. An example of a C program with flaws

```
1   /* This may look like nonsense, but really is -*- mode: C -*- */
 2
 3   /* The main thing that this program does. */
 4   void main() {
 5     // Declarations
 6     int i;
 7     double A[5] = {
 8       9.0,
 9       2.9,
10       3.E+25,
11       .00007,
12     };
13
14     // Doing some work
15     for (i = 0; i < 5; ++i) {
16        printf("element %d is %g, \tits square is %g\n",
17               i,
18               A[i],
19               A[i]*A[i]);
20     }
21
22     return 0;
23   }
```

If you run your compiler on this program, it should give you some *diagnostic**C* information similar to this:

##### `Terminal`

```
0   > c99 -Wall -o bad bad.c
1   bad.c:4:6: warning: return type of 'main' is not 'int' [-Wmain]
2   bad.c: In function 'main':
3   bad.c:16:6: warning: implicit declaration of function 'printf' [-Wimplicit-function...
4   bad.c:16:6: warning: incompatible implicit declaration of built-in function 'printf' ...
5   bad.c:22:3: warning: 'return' with a value, in function returning void [enabled by de...
```

Here we had a lot of long “warning” lines that are even too long to fit on a terminal screen. In the end, the compiler produced an executable. Unfortunately, the output when we run the program is different. This is a sign that we have to be careful and pay attention to details.

`clang` is even more picky than `gcc` and gives us even longer diagnostic lines:

##### `Terminal`

```
0   > clang -Wall -o getting-started-badly bad.c
 1   bad.c:4:1: warning: return type of 'main' is not 'int' [-Wmain-return-type]
 2   void main() {
 3   ^
 4   bad.c:16:6: warning: implicitly declaring library function 'printf' with type
 5         'int (const char *, ...)'
 6        printf("element %d is %g, \tits square is %g\n", /*@\label{printf-start-badly}*/
 7        ^
 8   bad.c:16:6: note: please include the header <stdio.h> or explicitly provide a declaration
 9         for 'printf'
10   bad.c:22:3: error: void function 'main' should not return a value [-Wreturn-type]
11     return 0;
12     ^      ~
13   2 warnings and 1 error generated.
```

This is a good thing! Its *diagnostic output**C* is much more informative. In particular, it gave us two hints: it expected a different return type for **main**, and it expected us to have a line such as line 3 from [listing 1.1](/book/modern-c/chapter-1/ch01ex01) to specify where the **printf** function comes from. Notice how `clang`, unlike `gcc`, did not produce an executable. It considers the problem on line 22 fatal. Consider this to be a feature.

Depending on your platform, you can force your compiler to reject programs that produce such diagnostics. For `gcc`, such a command-line option would be `-Werror`.

So we have seen two of the points in which [listings 1.1](/book/modern-c/chapter-1/ch01ex01) and [1.2](/book/modern-c/chapter-1/ch01ex07) differed, and these two modifications turned a good, standards-conforming, portable program into a bad one. We also have seen that the compiler is there to help us. It nailed the problem down to the lines in the program that cause trouble, and with a bit of experience you will be able to understand what it is telling you.[[[Exs 3]](/book/modern-c/chapter-1/ch01fn-ex03)] [[[Exs 4]](/book/modern-c/chapter-1/ch01fn-ex04)]

[Exs 3] Correct [listing 1.2](/book/modern-c/chapter-1/ch01ex07) step by step. Start from the first diagnostic line, fix the code that is mentioned there, recompile, and so on, until you have a flawless program.

[Exs 4] There is a third difference between the two programs that we didn’t mention yet. Find it.

##### Takeaway 1.4

*A C program should compile cleanly without warnings.*

## Summary

- C is designed to give computers orders. Thereby it mediates between us (the programmers) and computers.
- C must be compiled to be executed. The compiler provides the translation between the language that we understand (C) and the specific needs of the particular platform.
- C gives a level of abstraction that provides portability. One C program can be used on many different computer architectures.
- The C compiler is there to help you. If it warns you about something in your program, listen to it.

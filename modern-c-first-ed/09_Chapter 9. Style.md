# Chapter 9. Style

### This chapter covers

- Writing readable code
- Formatting code
- Naming identifiers

Programs serve both sides: first, as we have already seen, they serve to give instructions to the compiler and the final executable. But equally important, they document the intended behavior of a system for the people (users, customers, maintainers, lawyers, and so on) who have to deal with it.

Therefore, we have a prime directive:

##### Takeaway C

*All C code must be readable.*

The difficulty with that directive is knowing what constitutes “readable.” Not all experienced C programmers agree, so we will begin by trying to establish a minimal list of necessities. The first things we must have in mind when discussing the human condition is that it is constrained by two major factors: physical ability and cultural baggage.

##### Takeaway 9.1

*Short-term memory and the field of vision are small.*

Torvalds et al. [[1996](/book/modern-c/bibliography/bib18)], the coding style for the Linux kernel, is a good example that insists on that aspect and certainly is worth a detour, if you haven’t read it yet. Its main assumptions are still valid: a programming text has to be represented in a relatively small “window” (be it a console or a graphical editor) that consists of roughly 30 lines of 80 columns, making a “surface” of 2,400 characters. Everything that doesn’t fit has to be memorized. For example, our very first program in [listing 1.1](/book/modern-c/chapter-1/ch01ex01) fits into these constraints.

By its humorous reference to Kernighan and Ritchie [[1978](/book/modern-c/bibliography/bib8)], the Linux coding style also refers to another fundamental fact:

##### Takeaway 9.2

*Coding style is not a question of taste but of culture.*

Ignoring this easily leads to endless and fruitless debates about not much at all.

##### Takeaway 9.3

*When you enter an established project, you enter a new cultural space.*

Try to adapt to the habits of the inhabitants. When you create your own project, you have a bit of freedom to establish your own rules. But be careful if you want others to adhere to them; you must not deviate too much from the common sense that reigns in the corresponding community.

## 9.1. Formatting

The C language itself is relatively tolerant of formatting issues. Under normal circumstances, a C compiler will dumbly parse an entire program that is written on a single line with minimal white space and where all identifiers are composed of the letter l and the digit `1`. The need for code formatting originates in human incapacity.

##### Takeaway 9.4

*Choose a consistent strategy for white space and other text formatting.*

Formatting concerns indentation, placement of parentheses and all kinds of brackets (`{}`, `[]`, and `()`), spaces before and after operators, trailing spaces, and multiple new lines. The human eye and brain are quite peculiar in their habits, and to ensure that they work properly and efficiently, everything must be in sync.

In the introduction for [level 1](/book/modern-c/part-1/part01), you saw a lot of the coding style rules applied to the code in this book. Take them as an example of one style; you will most likely encounter other styles as you go along. Let us recall some of the rules and introduce some others that have not yet been presented:

- We use prefix notation for code blocks: that is, an opening `{` is at the end of a line.
- We bind type modifiers and qualifiers to the left. We bind function `()` to the left, but `()` of conditions are separated from their keyword (such as **`if`** or **`for`**) with a space.
- A ternary expression has spaces around the `?` and the `:`.
- Punctuation marks (`:`, `;`, and `,`) have no space before them but either one space or a new line after.

As you see, when written out, these rules can appear quite cumbersome and arbitrary. They have no value as such; they are visual aids that help you and your collaborators understand new code in the blink of an eye. They are not meant to be meticulously typed by you directly, but you should acquire and learn the tools that can help you with them.

##### Takeaway 9.5

*Have your text editor automatically format your code correctly.*

I personally use Emacs ([https://www.gnu.org/software/emacs/](https://www.gnu.org/software/emacs/)) for that task (yes, I am that old). For *me*, it is ideal since it understands a lot of the structure of a C program by itself. Your mileage will probably vary, but don’t use a tool in everyday life that gives you less. Text editors, integrated development environments (IDEs), and code generators are there for us, not the other way around.

In bigger projects, you should enforce such a formatting policy for all the code that circulates and is read by others. Otherwise, it will become difficult to track differences between versions of programming text. This can be automated by command-line tools that do the formatting. Here, I have a long-time preference for `astyle` (artistic style [http://sourceforge.net/projects/astyle/](http://sourceforge.net/projects/astyle/). Again, your mileage may vary; choose anything that ensures the task.

## 9.2. Naming

The limit of such automatic formatting tools is reached when it comes to naming.

##### Takeaway 9.6

*Choose a consistent naming policy for all identifiers.*

There are two different aspects to naming: technical restrictions on one hand and semantic conventions on the other. Unfortunately, they are often mixed up and the subject of endless ideological debate.

For C, various technical restrictions apply; they are meant to help you, so take them seriously. First of all, we target *all identifiers*: types (**`struct`** or not), **`struct`** and **`union`** members, variables, enumerations, macros, functions, function-like macros. There are so many tangled *name spaces**C* that you have to be careful.

In particular, the interaction between header files and macro definitions can have surprising effects. Here is a seemingly innocent example:

```
1   double memory_sum(size_t N, size_t I, double strip[N][I]);
N is a capitalized identifier, and thus your collaborator could be tempted to define a macro N as a big number.
I is used for the root of – 1 as soon as someone includes complex.h.
The identifier strip might be used by a C implementation for a library function or macro.
The identifier memory_sum might be used by the C standard for a type name in the future.
```

<complex.h>##### Takeaway 9.7

*Any identifier that is visible in a header file must be conforming.*

Here, *conforming* is a wide field. In C jargon, an identifier is *reserved**C* if its meaning is fixed by the C standard and you may not redefine it otherwise:

- Names starting with an underscore and a second underscore or a capital letter are reserved for language extensions and other internal use.
- Names starting with an underscore are reserved for file scope identifiers and for **`enum`**, **`struct`** and **`union`** tags.
- Macros have all-caps names.
- All identifiers that have a predefined meaning are reserved and cannot be used in file scope. This includes a lot of identifiers, such as all functions in the C library, all identifiers starting with str (like our strip, earlier), all identifiers starting with E, all identifiers ending in **`_t`**, and many more.

What makes all of these rules relatively difficult is that you might not detect any violation for years; and then, all of a sudden, on a new client machine, after the introduction of the next C standard and compiler or after a simple system upgrade, your code explodes.

A simple strategy to keep the probability of naming conflicts low is to expose as few names as possible.

##### Takeaway 9.8

*Don’t pollute the global space of identifiers.*

Expose only types and functions as interfaces that are part of the *application programming interface**C* (*API**C*): that is, those that are supposed to be used by users of your code.

A good strategy for a library that is used by others or in other projects is to use naming prefixes that are unlikely to create conflicts. For example, many functions and types in the POSIX thread API are prefixed with pthread_. For my tool box P99, I use the prefixes p99_ and P99_ for API interfaces and p00_ and P00_ for internals.

There are two sorts of names that may interact badly with macros that another programmer writes and which you might not think of immediately:

- Member names of **`struct`** and **`union`**
- Parameter names in function interfaces.

The first point is the reason why the members in standard structures usually have a prefix to their names: **`struct`** **`timespec`** has **`tv_sec`** as a member name, because an uneducated user might declare a macro sec that would interfere in unpredictable ways when including `time.h`. For the second point, we saw an example earlier. In P99, I would specify such a function something like this:

<time.h>```
1   double p99_memory_sum(size_t p00_n, size_t p00_i,
2                         double p00_strip[p00_n][p00_i]);
```

This problem gets worse when we are also exposing program internals to the public view. This happens in two cases:

- So-called **`inline`** functions, which are functions whose definition (not only declaration) is visible in a header file
- Function-like macros

We will discuss these features much later, see [section 15.1](/book/modern-c/chapter-15/ch15lev1sec1) and [chapter 16](/book/modern-c/chapter-16/ch16).

Now that we have clarified the technical points of naming, we will look at the semantic aspect.

##### Takeaway 9.9

*Names must be recognizable and quickly distinguishable.*

That has two parts: distinguishable *and* quickly. Compare the identifiers in [table 9.1](/book/modern-c/chapter-9/ch09table01).

For your personal taste, the answers on the right side of this table may be different. This reflects *my* taste: an implicit context for such names is part of my personal expectation. The difference between n and m on one side and for ffs and clz on the other is an implicit semantic.

##### Table 9.1. Some examples of well and badly distinguishable identifiers[(view table figure)](https://drek4537l1klr.cloudfront.net/gustedt/HighResolutionFigures/table_9-1.png)


|   |   | Recognizable | Distinguishable | Quickly |
| --- | --- | --- | --- | --- |
| lllll1llOll | llllll1l0ll | No | No | No |
| myLineNumber | myLimeNumber | Yes | Yes | No |
| n | m | Yes | Yes | Yes |
| ffs | clz | No | Yes | Yes |
| lowBit | highBit | Yes | Yes | Yes |
| p00Orb | p00Urb | No | Yes | No |
| p00_orb | p00_urb | Yes | Yes | Yes |

For me, because I have a heavily biased mathematical background, single-letter variable names from i to n, such as n and m, are integer variables. These usually occur inside a quite restricted scope as loop variables or similar. Having a single-letter identifier is fine (we always have the declaration in view), and they are quickly distinguished.

The function names ffs and clz are different because they compete with all other three-letter acronyms that could potentially be used for function names. Incidentally, here, ffs is shorthand for *find first (bit) set*, but this is not immediately obvious to me. What that would mean is even less clear: which bit is first, the most significant bit or the least significant?

There are several conventions that combine multiple words in one identifier. Among the most commonly used are the following:

- *Camel case**C*, using internalCapitalsToBreakWords
- *Snake case**C*, using internal_underscores_to_break_words
-  *Hungarian notation**C*,[[1](/book/modern-c/chapter-9/ch09fn01)] which encodes type information in the prefix of the identifiers, such as szName, where sz stands for *string* and *zero terminated* 
  
   1 Invented in Simonyi [[1976](/book/modern-c/bibliography/bib16)], the PhD thesis of Simonyi Károly 
   

As you might imagine, none of these is ideal. The first two tend to obscure our view: they easily clog up a whole precious line of programming text with an unreadable expression:

```
1   return theVerySeldomlyUsedConstant*theVerySeldomlyUsedConstant/
number_of_elements;
```

Hungarian notation, in turn, tends to use obscure abbreviations for types or concepts, produces unpronounceable identifiers, and completely breaks down if you have an API change.

So, in my opinion, none of these rules or strategies have absolute values. I encourage you to take a pragmatic approach to the question.

##### Takeaway 9.10

*Naming is a creative act.*

It is not easily subsumed by simple technical rules.

Obviously, good naming is more important the more widely an identifier is used. So, it is particularly important for identifiers for which the declaration is generally out of view of the programmer: global names that constitute the API.

##### Takeaway 9.11

*File-scope identifiers must be comprehensive.*

What constitutes *comprehensive* here should be derived from the type of the identifier. Type names, constants, variables, and functions generally serve different purposes, so different strategies apply.

##### Takeaway 9.12

*A type name identifies a concept.*

Examples of such concepts are *time* for **`struct`** **`timespec`**, *size* for **`size_t`**, a collection of corvidae for **`enum`** corvid, *person* for a data structure that collects data about people, *list* for a chained list of items, *dictionary* for a query data structure, and so on. If you have difficulty coming up with a concept for a data structure, an enumeration, or an arithmetic type, you should probably revisit your design.

##### Takeaway 9.13

*A global constant identifies an artifact.*

That is, a constant *stands out* for some reason from the other possible constants of the same type: it has a special meaning. It may have this meaning for some external reason beyond our control (M_PI for π), because the C standard says so (**`false`**, **`true`**), because of a restriction of the execution platform (**`SIZE_MAX`**), to be factual (corvid_num), for a reason that is culturally motivated (fortytwo), or as a design decision.

Generally, we will see shortly that file-scope variables (*globals*) are much frowned upon. Nevertheless, they are sometimes unavoidable, so we have to have an idea how to name them.

##### Takeaway 9.14

*A global variable identifies state.*

Typical names for such variables are toto_initialized to encode the fact that library *toto* has already been initialized, onError for a file-scope but internal variable that is set in a library that must be torn down, and visited_entries for a hash table that collects shared data.

##### Takeaway 9.15

*A function or functional macro identifies an action.*

Not all, but many, of the functions in the C standard library follow that rule and use verbs as a component of their names. Here are some examples:

- A standard function that compares two strings is **strcmp**.
- A standard macro that queries for a property is **`isless`**.
- A function that accesses a data member could be called toto_getFlag.
- The corresponding one that sets such a member would be toto_setFlag.
- A function that multiples two matrices is matrixMult.

## Summary

- Coding style is a matter of culture. Be tolerant and patient.
- Code formatting is a matter of visual habits. It should be automatically provided by your environment such that you and your co-workers can read and write code effortlessly.
- Naming of variables, functions, and types is an art and plays a central role in the comprehensiveness of your code.

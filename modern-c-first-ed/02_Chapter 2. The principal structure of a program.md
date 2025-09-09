# Chapter 2. The principal structure of a program

### This chapter covers

- C grammar
- Declaring identifiers
- Defining objects
- Instructing the compiler with statements

Compared to our little examples in the previous chapter, real programs will be more complicated and contain additional constructs, but their structure will be very similar. [Listing 1.1](/book/modern-c/chapter-1/ch01ex01) already has most of the structural elements of a C program.

There are two categories of aspects to consider in a C program: syntactical aspects (how do we specify the program so the compiler understands it?) and semantic aspects (what do we specify so that the program does what we want it to do?). In the following sections, we will introduce the syntactical aspects (grammar) and three different semantic aspects: declarative parts (what things are), definitions of objects (where things are), and statements (what things are supposed to do).

## 2.1. Grammar

Looking at its overall structure, we can see that a C program is composed of different types of text elements that are assembled in a kind of grammar. These elements are:

-  ***Special words:*** In [listing 1.1](/book/modern-c/chapter-1/ch01ex01), we used the following special words:[[1](/book/modern-c/chapter-2/ch02fn01)] **`#include`**, **`int`**, **`void`**, **`double`**, **`for`**, and **`return`**. In program text in this book, they will usually be printed in bold face. These special words represent concepts and features that the C language imposes and that cannot be changed.

1 In C jargon, these are *directivesC*, *keywordsC*, and *reservedC* identifiers.

-  ***PunctuationC:*** C uses several types of punctuation to structure the program text.

- There are five kinds of brackets: `{ ... }`, `( ... )`, `[ ... ]`, /* ... */, and `< ... >`. Brackets *group* certain parts of the program together and should always come in pairs. Fortunately, the `< ... >` brackets are rare in C and are only used as shown in our example, on the same logical line of text. The other four are not limited to a single line; their contents might span several lines, as they did when we used **printf** earlier.
- There are two different separators or terminators: comma and semicolon. When we used **printf**, we saw that commas *separated* the four arguments of that function; and on line 12 we saw that a comma also can follow the last element of a list of elements.

`getting-started.c`

**12**       [3] = .00007,
!@%STYLE%@!
{"css":"{\"css\": \"font-weight: bold;\"}","target":"[[{\"line\":0,\"ch\":0},{\"line\":0,\"ch\":2}]]"}
!@%STYLE%@!

copy

One of the difficulties for newcomers in C is that the same punctuation characters are used to express different concepts. For example, the pairs `{}` and `[]` are each used for three different purposes in [listing 1.1](/book/modern-c/chapter-1/ch01ex01).[[[Exs 1]](/book/modern-c/chapter-2/ch02fn-ex01)]

[Exs 1] Find these different uses of these two sorts of brackets.

##### Takeaway 2.1

*Punctuation characters can be used with several different meanings.*

-  ***CommentsC:*** The construct /* ... */ that we saw earlier tells the compiler that everything inside it is a *comment*; see, for example, line 5:

`getting-started.c`

**5**   /* The main thing that this program does. */
!@%STYLE%@!
{"css":"{\"css\": \"font-weight: bold;\"}","target":"[[{\"line\":0,\"ch\":0},{\"line\":0,\"ch\":1}]]"}
!@%STYLE%@!

copy

Comments are ignored by the compiler. It is the perfect place to explain and document your code. Such in-place documentation can (and should) greatly improve the readability and comprehensibility of your code. Another form of comment is the so-called C++-style comment, as on line 15. These are marked with //. C++-style comments extend from the // to the end of the line.
- ***LiteralsC:*** Our program contains several items that refer to fixed values that are part of the program: `0`, `1`, `3`, `4`, `5`, `9.0`, `2.9`, `3.`E`+25`, `.00007`, and "element %zu is %g, \tits square is %g\n". These are called *literals**C*.
-  ***IdentifiersC:*** These are “names” that we (or the C standard) give to certain entities in the program. Here we have A, i, **main**, **printf**, **`size_t`**, and **`EXIT_SUCCESS`**. Identifiers can play different roles in a program. Among other things, they may refer to

- *Data objects**C* (such as A and i). These are also referred to as *variables**C*.
- *Type**C* aliases, such as **`size_t`**, that specify the “sort” of a new object, here of i. Observe the trailing **`_t`** in the name. This naming convention is used by the C standard to remind you that the identifier refers to a type.
- Functions, such as **main** and **printf**.
- Constants, such as **`EXIT_SUCCESS`**.

- ***FunctionsC:*** Two of the identifiers refer to functions: **main** and **printf**. As we have already seen, **printf** is *used* by the program to produce some output. The function **main** in turn is *defined**C*: that is, its *declaration**C* **`int`** **main**`(`**`void`**`)` is followed by a *block**C* enclosed in `{ ... }` that describes what that function is supposed to do. In our example, this function *definition**C* goes from line 6 to 24. **main** has a special role in C programs, as we will encounter: it must always be present, since it is the starting point of the program’s execution.
-  ***OperatorsC:*** Of the numerous C operators, our program only uses a few:

- `=` for *initialization**C* and *assignment**C*,
- `<` for comparison,
- `++` to *increment* a variable (to increase its value by `1`), and
- `*` to multiply two values.

Just as in natural languages, the lexical elements and the grammar of C programs that we have seen here have to be distinguished from the actual meaning these constructs convey. In contrast to natural languages, though, this meaning is rigidly specified and usually leaves no room for ambiguity. In the following sections, we will dig into the three main semantic categories that C distinguishes: declarations, definitions, and statements.

## 2.2. Declarations

Before we may use a particular identifier in a program, we have to give the compiler a *declaration**C* that specifies what that identifier is supposed to represent. This is where identifiers differ from keywords: keywords are predefined by the language and must not be declared or redefined.

##### Takeaway 2.2

*All identifiers in a program have to be declared.*

Three of the identifiers we use are effectively declared in our program: **main**, A, and i. Later on, we will see where the other identifiers (**printf**, **`size_t`**, and **`EXIT_SUCCESS`**) come from. We already mentioned the declaration of the **main** function. All three declarations, in isolation as “declarations only,” look like this:

```
int main(void);
double A[5];
size_t i;
```

These three follow a pattern. Each has an identifier (**main**, A, or i) and a specification of certain properties that are associated with that identifier:

- i is of *type**C* **`size_t`**.
- **main** is additionally followed by parentheses, `( ... )`, and thus declares a function of type **`int`**.
- A is followed by brackets, `[ ... ]`, and thus declares an *array**C*. An array is an aggregate of several items of the same type; here it consists of `5` items of type **`double`**. These `5` items are ordered and can be referred to by numbers, called *indices**C*, from `0` to `4`.

Each of these declarations starts with a *type**C*, here **`int`**, **`double`**, and **`size_t`**. We will see later what that represents. For the moment, it is sufficient to know that this specifies that all three identifiers, when used in the context of a statement, will act as some sort of “numbers.”

The declarations of i and A declare *variables**C*, which are named items that allow us to store *values**C*. They are best visualized as a kind of box that may contain a “something” of a particular type:

![](https://drek4537l1klr.cloudfront.net/gustedt/Figures/pg_014_alt.jpg)

Conceptually, it is important to distinguish the box itself (the *object*), the specification (its *type*), the box contents (its *value*), and the name or label that is written on the box (the *identifier*). In such diagrams, we put `??` if we don’t know the actual value of an item.

For the other three identifiers, **printf**, **`size_t`**, and **`EXIT_SUCCESS`**, we don’t see any declaration. In fact, they are predeclared identifiers, but as we saw when we tried to compile [listing 1.2](/book/modern-c/chapter-1/ch01ex07), the information about these identifiers doesn’t come out of nowhere. We have to tell the compiler where it can obtain information about them. This is done right at the start of the program, in lines 2 and 3: **printf** is provided by `stdio.h`, whereas **`size_t`** and **`EXIT_SUCCESS`** come from `stdlib.h`. The real declarations of these identifiers are specified in `.h` files with these names somewhere on your computer. They could be something like:

`<stdio.h>`

`<stdlib.h>`

```
int printf(char const format[static 1], ...);
typedef unsigned long size_t;
#define EXIT_SUCCESS 0
```

Because the specifics of these predeclared features are of minor importance, this information is normally hidden from you in these *include files**C* or *header files**C*. If you need to know their semantics, it is usually a bad idea to look them up in the corresponding files, as these tend to be barely readable. Instead, search in the documentation that comes with your platform. For the brave, I always recommend a look into the current C standard, as that is where they all come from. For the less courageous, the following commands may help:

##### `Terminal`

```
0   > apropos printf
1   > man printf
2   > man 3 printf
```

A declaration only describes a feature but does not create it, so repeating a declaration does not do much harm but adds redundancy.

##### Takeaway 2.3

*Identifiers may have several consistent declarations.*

Clearly, it would become really confusing (for us or the compiler) if there were several contradicting declarations for the same identifier in the same part of the program, so generally this is not allowed. C is quite specific about what “the same part of the program” is supposed to mean: the *scope**C* is a part of the program where an identifier is *visible**C*.

##### Takeaway 2.4

*Declarations are bound to the scope in which they appear.*

These scopes of identifiers are unambiguously described by the grammar. In [listing 1.1](/book/modern-c/chapter-1/ch01ex01), we have declarations in different scopes:

- A is visible inside the definition of **main**, starting at its declaration on line 8 and ending at the closing `}` on line 24 of the innermost `{ ... }` block that contains that declaration.
- i has more restricted visibility. It is bound to the **`for`** construct in which it is declared. Its visibility reaches from that declaration on line 16 to the end of the `{ ... }` block that is associated with the **`for`** on line 21.
- **main** is not enclosed in a `{ ... }` block, so it is visible from its declaration onward until the end of the file.

In a slight abuse of terminology, the first two types of scope are called *block scope**C*, because the scope is limited by a *block**C* of matching `{ ... }`. The third type, as used for **main**, which is not inside a `{ ... }` pair, is called *file scope**C*. Identifiers in file scope are often referred to as *globals*.

## 2.3. Definitions

Generally, declarations only specify the kind of object an identifier refers to, not what the concrete value of an identifier is, nor where the object it refers to can be found. This important role is filled by a *definition**C*.

##### Takeaway 2.5

*Declarations specify identifiers, whereas definitions specify objects.*

We will later see that things are a little more complicated in real life, but for now we can make the simplification that we will always initialize our variables. An *initialization* is a grammatical construct that augments a declaration and provides an initial value for the object. For instance,

```
size_t i = 0;
```

is a declaration of i such that the initial value is `0`.

In C, such a declaration with an initializer also *defines* the object with the corresponding name: that is, it instructs the compiler to provide storage in which the value of the variable can be stored.

##### Takeaway 2.6

*An object is defined at the same time it is initialized.*

Our box visualization can now be completed with a value, `0` in this example:

![](https://drek4537l1klr.cloudfront.net/gustedt/Figures/pg_016-01.jpg)

A is a bit more complex because it has several components:

##### `getting-started.c`

```
8   double A[5] = {
 9     [0] = 9.0,
10     [1] = 2.9,
11     [4] = 3.E+25,
12     [3] = .00007,
13   };
```

This initializes the `5` items in A to the values `9.0`, `2.9`, `0.0`, `0.00007`, and `3.`0`E+25`, in that order:

![](https://drek4537l1klr.cloudfront.net/gustedt/Figures/pg_016-02_alt.jpg)

The form of an initializer that we see here is called *designated**C*: a pair of brackets with an integer *designate* which item of the array is initialized with the corresponding value. For example, `[4] = 3.`E`+25` sets the last item of the array A to the value `3.`E`+25`. As a special rule, any position that is not listed in the initializer is set to `0`. In our example, the missing `[2]` is filled with `0.0`.[[2](/book/modern-c/chapter-2/ch02fn02)]

2 We will see later how these number literals with dots (`.`) and exponents (E`+25`) work.

##### Takeaway 2.7

*Missing elements in initializers default to `0`.*

You might have noticed that array positions, *indices**C*, do not start with `1` for the first element, but with `0`. Think of an array position as the distance of the corresponding array element from the start of the array.

##### Takeaway 2.8

*For an array with n elements, the first element has index 0, and the last has index n-1.*

For a function, we have a definition (as opposed to only a declaration) if its declaration is followed by braces `{ ... }` containing the code of the function:

```
int main(void) {
  ...
}
```

In our examples so far, we have seen names for two different features: *objects**C*, i and A, and *functions**C*, **main** and **printf**. In contrast to object or function declarations, where several are allowed for the same identifier, definitions of objects or functions must be unique. That is, for a C program to be operational, any object or function that is used must have a definition (otherwise the execution would not know where to look for them), and there must be no more than one definition (otherwise the execution could become inconsistent).

##### Takeaway 2.9

*Each object or function must have exactly one definition.*

## 2.4. Statements

The second part of the **main** function consists primarily of *statements*. Statements are instructions that tell the compiler what to do with identifiers that have been declared so far. We have

##### `getting-started.c`

```
16   for (size_t i = 0; i < 5; ++i) {
17      printf("element %zu is %g, \tits square is %g\n",
18             i,
19             A[i],
20             A[i]*A[i]);
21   }
22
23   return EXIT_SUCCESS;
```

We have already discussed the lines that correspond to the call to **printf**. There are also other types of statements: **`for`** and **`return`** statements, and an increment operation, indicated by the *operator**C* `++`. In the following section, we will go a bit into the details of three categories of statements: *iterations* (do something several times), *function calls* (delegate execution somewhere else), and *function returns* (resume execution from where a function was called).

### 2.4.1. Iteration

The **`for`** statement tells the compiler that the program should execute the **printf** line a number of times. This is the simplest form of *domain iteration**C* that C has to offer. It has four different parts.

The code that is to be repeated is called the *loop body**C*: it is the `{ ... }` block that follows the **`for`** `( ... )`. The other three parts are those inside the `( ... )` part, divided by semicolons:

1. The declaration, definition, and initialization of the *loop variable**C* i, which we already discussed. This initialization is executed once before any of the rest of the entire **`for`** statement.
1. A *loop condition**C*, i `< 5` specifies how long the **`for`** iteration should continue. This tells the compiler to continue iterating as long as i is strictly less than `5`. The loop condition is checked before each execution of the loop body.
1. Another statement, `++`i, is executed after each iteration. In this case, it increases the value of i by `1` each time.

If we put all of these together, we ask the program to perform the part in the block five times, setting the value of i to `0`, `1`, `2`, `3`, and `4`, respectively, in each iteration. The fact that we can identify each iteration with a specific value for i makes this an iteration over the *domain**C* `0`, . . ., `4`. There is more than one way to do this in C, but **`for`** is the easiest, cleanest, and best tool for the task.

##### Takeaway 2.10

*Domain iterations should be coded with a* **`for`** *statement.*

A **`for`** statement can be written in several ways other than what we just saw. Often, people place the definition of the loop variable somewhere before the **`for`** or even reuse the same variable for several loops. Don’t do that: to help an occasional reader and the compiler understand your code, it is important to know that this variable has the special meaning of an iteration counter for that given **`for`** loop.

##### Takeaway 2.11

*The loop variable should be defined in the initial part of a* **`for`***.*

### 2.4.2. Function calls

*Function calls* are special statements that suspend the execution of the current function (at the beginning, this is usually **main**) and then hand over control to the named function. In our example

##### `getting-started.c`

```
17      printf("element %zu is %g, \tits square is %g\n",
18             i,
19             A[i],
20             A[i]*A[i]);
```

the called function is **printf**. A function call usually provides more than just the name of the function, but also *arguments*. Here, these are the long chain of characters, i, A`[`i`]`, and A`[`i`]*`A`[`i`]`. The *values* of these arguments are passed over to the function. In this case, these values are the information that is printed by **printf**. The emphasis here is on “value”: although i is an argument, **printf** will never be able to change i itself. Such a mechanism is called *call by value*. Other programming languages also have *call by reference*, a mechanism where the called function can change the value of a variable. C does not implement pass by reference, but it has another mechanism to pass the control of a variable to another function: by taking addresses and transmitting pointers. We will see these mechanism much later.

### 2.4.3. Function return

The last statement in **main** is a **`return`**. It tells the **main** function to *return* to the statement that it was called from once it’s done. Here, since **main** has **`int`** in its declaration, a **`return`** *must* send back a value of type **`int`** to the calling statement. In this case, that value is **`EXIT_SUCCESS`**.

Even though we can’t see its definition, the **printf** function must contain a similar **`return`** statement. At the point where we call the function on line 17, execution of the statements in **main** is temporarily suspended. Execution continues in the **printf** function until a **`return`** is encountered. After the return from **printf**, execution of the statements in **main** continues from where it stopped.

[Figure 2.1](/book/modern-c/chapter-2/ch02fig01) shows a schematic view of the execution of our little program: its *control flow*. First, a process-startup routine (on the left) that is provided by our platform calls the user-provided function **main** (middle). That, in turn, calls **printf**, a function that is part of the *C library**C*, on the right. Once a **`return`** is encountered there, control returns back to **main**; and when we reach the **`return`** in **main**, it passes back to the startup routine. The latter transfer of control, from a programmer’s point of view, is the end of the program’s execution.

![Figure 2.1. Execution of a small program](https://drek4537l1klr.cloudfront.net/gustedt/Figures/02fig01_alt.jpg)

## Summary

- C distinguishes the lexical structure (the punctuators, identifiers, and numbers), the grammatical structure (syntax), and the semantics (meaning) of programs.
- All identifiers (names) must be declared such that we know the properties of the concept they represent.
- All objects (things that we deal with) and functions (methods that we use to deal with things) must be defined; that is, we must specify how and where they come to be.
- Statements indicate how things are going to be done: iterations (**`for`**) repeat variations of certain tasks, functions call (**printf**`(...)`) delegate a task to a function, and function returns (**`return`** something`;`) go back where we came from.

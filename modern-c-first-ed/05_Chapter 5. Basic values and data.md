# Chapter 5. Basic values and data

### This chapter covers

- Understanding the abstract state machine
- Working with types and values
- Initializing variables
- Using named constants
- Binary representations of types

We will now change our focus from “how things are to be done” (statements and expressions) to the things on which C programs operate: *values**C* and *data**C*. A concrete program at an instance in time has to *represent* values. Humans have a similar strategy: nowadays we use a decimal presentation to write numbers on paper using the Hindu-Arabic numeral system. But we have other systems to write numbers: for example, Roman numerals (i, ii, iii, iv, and so on) or textual notation. To know that the word *twelve* denotes the value 12 is a nontrivial step and reminds us that European languages denote numbers not only in decimal but also in other systems. English and German mix with base 12, French with bases 16 and 20. For non-native French speakers like myself, it may be difficult to spontaneously associate *quatre vingt quinze* (four times twenty and fifteen) with the value 95.

Similarly, representations of values on a computer can vary “culturally” from architecture to architecture or are determined by the type the programmer gave to the value. Therefore, we should try to reason primarily about values and not about representations if we want to write portable code.

If you already have some experience in C and in manipulating bytes and bits, you will need to make an effort to actively “forget” your knowledge for most of this chapter. Thinking about concrete representations of values on your computer will inhibit you more than it helps.

##### Takeaway 5.1

*C programs primarily reason about values and not about their representation.*

The representation that a particular value has should in most cases not be your concern; the compiler is there to organize the translation back and forth between values and representations.

In this chapter, we will see how the different parts of this translation are supposed to work. The ideal world in which you will usually “argue” in your program is C’s *abstract state machine* ([section 5.1](/book/modern-c/chapter-5/ch05lev1sec1)). It gives a vision of the execution of your program that is mostly independent of the platform on which the program runs. The components of the *state* of this machine, the *objects*, all have a fixed interpretation (their *type*) and a value that varies in time. C’s basic types are described in [section 5.2](/book/modern-c/chapter-5/ch05lev1sec2), followed by descriptions of how we can express specific values for such basic types ([section 5.3](/book/modern-c/chapter-5/ch05lev1sec3)), how types are assembled in expressions ([section 5.4](/book/modern-c/chapter-5/ch05lev1sec4)), how we can ensure that our objects initially have the desired values ([section 5.5](/book/modern-c/chapter-5/ch05lev1sec5)), how we can give names to recurrent values ([section 5.6](/book/modern-c/chapter-5/ch05lev1sec6)), and how such values are represented in the abstract state machine ([section 5.7](/book/modern-c/chapter-5/ch05lev1sec7)).

## 5.1. The abstract state machine

A C program can be seen as a sort of machine that manipulates values: the particular values that variables of the program have at a given time, and also intermediate values that are the result of computed expressions. Let us consider a basic example:

```
double x = 5.0;
   double y = 3.0;
   ...
   x = (x * 1.5) - y;
   printf("x is \%g\n", x);
```

Here we have two variables, x and y, that have initial values `5.0` and `3.0`, respectively. The third line computes some expressions: a subexpression

```
x
```

that evaluates x and provides the value `5.0`;

```
(5.0 * 1.5)
```

that results in the value `7.5`;

```
y
```

that evaluates y and provides the value `3.0`;

```
7.5 - 3.0
```

that results in `4.5`;

```
x = 4.5
```

that changes the value of x to `4.5`;

```
x
```

that evaluates x again, but that now provides the value `4.5`; and

```
printf("x is \%g\n", 4.5)
```

that outputs a text line to the terminal.

Not all operations and their resulting values are *observable* from within your program. They are observable only if they are stored in *addressable* memory or written to an output device. In the example, to a certain extent, the **printf** statement “observes” what was done on the previous line by evaluating the variable x and then writing a string representation of that value to the terminal. But the other subexpressions and their results (such as the multiplication and subtraction) are not observable as such, since we never define a variable that is supposed to hold these values.

Your C compiler is allowed to shortcut any of the steps during a process called *optimization**C* only if it ensures the realization of the end results. Here, in our toy example, there are basically two possibilities. The first is that variable x is not used later in the program, and its acquired value is only relevant for our **printf** statement. In that case, the only effect of our code snippet is the output to the terminal, and the compiler may well (and will!) replace the whole snippet with the equivalent

```
printf("x is 4.5\n");
```

That is, it will do all the computations at compile time and, the executable that is produced will just print a fixed string. All the remaining code and even the definitions of the variables disappear.

The other possibility is that x might be used later. Then a decent compiler would either do something like

```
double x = 4.5;
   printf("x is 4.5\n");
```

or maybe

```
printf("x is 4.5\n");
   double x = 4.5;
```

because to use x at a later point, it is not relevant whether the assignment took place before or after the **printf**.

For an optimization to be valid, it is only important that a C compiler produces an executable that reproduces the *observable states**C*. These consist of the contents of some variables (and similar entities that we will see later) and the output as they evolve during the execution of the program. This whole mechanism of change is called the *abstract state machine**C*.

To explain the abstract state machine, we first have to look into the concepts of a *value* (what state are we in), the *type* (what this state represents), and the *representation* (how state is distinguished). As the term *abstract* suggests, C’s mechanism allows different platforms to realize the abstract state machine of a given program differently according to their needs and capacities. This permissiveness is one of the keys to C’s potential for optimization.

### 5.1.1. Values

A *value* in C is an abstract entity that usually exists beyond your program, the particular implementation of that program, and the representation of the value during a particular run of the program. As an example, the value and concept of `0` should and will always have the same effects on all C platforms: adding that value to another value *x* will again be *x*, and evaluating a value `0` in a control expression will always trigger the **`false`** branch of the control statement.

So far, most of our examples of values have been some kind of numbers. This is not an accident, but relates to one of the major concepts of C.

##### Takeaway 5.2

*All values are numbers or translate to numbers.*

This property really concerns all values a C program is about, whether these are the characters or text we print, truth values, measures that we take, or relations that we investigate. Think of these numbers as mathematical entities that are independent of your program and its concrete realization.

The *data* of a program execution consists of all the assembled values of all objects at a given moment. The *state* of the program execution is determined by:

- The executable
- The current point of execution
- The data
- Outside intervention, such as IO from the user

If we abstract from the last point, an executable that runs with the same data from the same point of execution must give the same result. But since C programs should be portable between systems, we want more than that. We don’t want the result of a computation to depend on the executable (which is platform specific) but ideally to depend only on the program specification itself. An important step to achieve this platform independence is the concept of *types**C*.

### 5.1.2. Types

A type is an additional property that C associates with values. Up to now, we have seen several such types, most prominently **`size_t`**, but also **`double`** and bool.

##### Takeaway 5.3

*All values have a type that is statically determined.*

##### Takeaway 5.4

*Possible operations on a value are determined by its type.*

##### Takeaway 5.5

*A value’s type determines the results of all operations.*

### 5.1.3. Binary representation and the abstract state machine

Unfortunately, the variety of computer platforms is not such that the C standard can completely impose the results of the operations on a given type. Things that are not completely specified as such by the standard are, for example, how the sign of a signed type is represented the (*sign representation*), and the precision to which a **`double`** floating-point operation is performed (*floating-point representation*).[[1](/book/modern-c/chapter-5/ch05fn01)] C only imposes properties on representations such that the results of operations can be deduced *a priori* from two different sources:

1 Other international standards are more restrictive about these representations. For example, the POSIX [[2009](/book/modern-c/bibliography/bib15)] standard enforces a particular sign representation, and ISO/IEC/IEEE 60559 [[2011](/book/modern-c/bibliography/bib6)] normalizes floating-point representations.

- The values of the operands
- Some characteristic values that describe the particular platform

For example, the operations on the type **`size_t`** can be entirely determined when inspecting the value of **`SIZE_MAX`** in addition to the operands. We call the model to represent values of a given type on a given platform the *binary representation**C* of the type.

##### Takeaway 5.6

*A type’s binary representation determines the results of all operations.*

Generally, all information we need to determine that model is within reach of any C program: the C library headers provide the necessary information through named values (such as **`SIZE_MAX`**), operators, and function calls.

##### Takeaway 5.7

*A type’s binary representation is observable.*

This binary representation is still a model and thus an *abstract representation* in the sense that it doesn’t completely determine how values are stored in the memory of a computer or on a disk or other persistent storage device. That representation is the *object representation*. In contrast to the binary representation, the object representation usually is not of much concern to us, as long as we don’t want to hack together values of objects in main memory or have to communicate between computers that have different platform models. Much later, in [section 12.1](/book/modern-c/chapter-12/ch12lev1sec1), we will see that we can even observe the object representation, *if* such an object is stored in memory *and* we know its address.

As a consequence, all computation is fixed through the values, types, and their binary representations that are specified in the program. The program text describes an *abstract state machine**C* that regulates how the program switches from one state to the next. These transitions are determined by value, type, and binary representation only.

##### Takeaway 5.8 (as-if)

*Programs execute* *as if* *following the abstract state machine.*

### 5.1.4. Optimization

How a concrete executable manages to follow the description of the abstract state machine is left to the discretion of the compiler creators. Most modern C compilers produce code that *doesn’t* follow the exact code prescription: they cheat wherever they can and only respect the observable states of the abstract state machine. For example, a sequence of additions with constant values such as

```
x += 5;
   /* Do something else without x in the meantime. */
   x += 7;
```

may in many cases be done as if it were specified as either

```
/* Do something without x. */
   x += 12;
```

or

```
x += 12;
   /* Do something without x. */
```

The compiler may perform such changes to the execution order as long as there will be no observable difference in the result: for example, as long as we don’t print the intermediate value of x and as long as we don’t use that intermediate value in another computation.

But such an optimization can also be forbidden because the compiler can’t prove that a certain operation will not force program termination. In our example, much depends on the type of x. If the current value of x could be close to the upper limit of the type, the innocent-looking operation x `+= 7` may produce an overflow. Such overflows are handled differently according to the type. As we have seen, overflow of an unsigned type is not a problem, and the result of the condensed operation will always be consistent with the two separate ones. For other types, such as signed integer types (**`signed`**) and floating-point types (**`double`**), an overflow may *raise an exception* and terminate the program. In that case, the optimization cannot be performed.

As we have already mentioned, this allowed slackness between program description and abstract state machine is a very valuable feature, commonly referred to as optimization. Combined with the relative simplicity of its language description, this is actually one of the main features that allows C to outperform other programming languages that have a lot more knobs and whistles. An important consequence of this discussion can be summarized as follows:

##### Takeaway 5.9

*Type determines optimization opportunities.*

## 5.2. Basic types

C has a series of basic types and means of constructing *derived types**C* from them that we will describe later, in [chapter 6](/book/modern-c/chapter-6/ch06).

Mainly for historical reasons, the system of basic types is a bit complicated, and the syntax to specify such types is not completely straightforward. There is a first level of specification that is done entirely with keywords of the language, such as **`signed`**, **`int`**, and **`double`**. This first level is mainly organized according to C internals. On top of that is a second level of specification that comes through header files, and we have already seen examples: **`size_t`** and bool. This second level is organized by type semantics, specifying what properties a particular type brings to the programmer.

![](https://drek4537l1klr.cloudfront.net/gustedt/Figures/comm.jpg)

We will start with the first-level specification of such types. As we discussed earlier ([takeaway 5.2](/book/modern-c/chapter-5/ch05note02)), all basic values in C are numbers, but there are different kinds of numbers. As a principal distinction, we have two different classes of numbers, each with two subclasses: *unsigned integers**C*, *signed integers**C*, *real floating-point numbers**C*, and *complex floating-point numbers**C*. Each of these four classes contains several types. They differ according to their *precision**C*, which determines the valid range of values that are allowed for a particular type.[[2](/book/modern-c/chapter-5/ch05fn02)] [Table 5.1](/book/modern-c/chapter-5/ch05table01) contains an overview of the 18 base types.

2 The term *precision* is used here in a restricted sense as the C standard defines it. It is different from the *accuracy* of a floating-point computation.

##### Table 5.1. Base types according to the four main type classes. *Types with a gray background don’t allow for arithmetic; they are promoted before doing arithmetic. Type* **`char`** *is special since it can be unsigned or signed, depending on the platform. All types in this table are considered to be distinct types, even if they have the same class and precision.*[(view table figure)](https://drek4537l1klr.cloudfront.net/gustedt/HighResolutionFigures/table_5-1.png)

| Class | Systematic name | Other name | Rank |   |
| --- | --- | --- | --- | --- |
| Integers | Unsigned | **_Bool** | bool | 0 |
| **unsigned char** |  | 1 |  |  |
| **unsigned short** |  | 2 |  |  |
| **unsigned int** | **unsigned** | 3 |  |  |
| **unsigned long** |  | 4 |  |  |
| **unsigned long long** |  | 5 |  |  |
| [Un]signed | **char** |  | 1 |  |
|  | **signed char** |  | 1 |  |
|  | **signed short** | **short** | 2 |  |
| Signed | **signed int** | **signed** or **int** | 3 |  |
|  | **signed long** | **long** | 4 |  |
|  | **signed long long** | **long long** | 5 |  |
| Floating point | Real | **float** |  |  |
| **double** |  |  |  |  |
| **long double** |  |  |  |  |
| Complex | **float _Complex** | **float** **complex** |  |  |
| **double _Complex** | **double** **complex** |  |  |  |
| **long double _Complex** | **long double** **complex** |  |  |  |

As you can see from the table, there are six types that we can’t use directly for arithmetic, the so-called *narrow types**C*. They are *promoted**C* to one of the wider types before they are considered in an arithmetic expression. Nowadays, on any realistic platform, this promotion will be a **`signed int`** of the same value as the narrow type, regardless of whether the narrow type was signed.

##### Takeaway 5.10

*Before arithmetic, narrow integer types are promoted to* **`signed int`***.*

Observe that among the narrow integer types, we have two prominent members: **`char`** and bool. The first is C’s type that handles printable characters for text, and the second holds truth values, **`false`** and **`true`**. As we said earlier, for C, even these are just some sort of numbers.

The 12 remaining, unpromoted, types split nicely into the four classes.

##### Takeaway 5.11

*Each of the four classes of base types has three distinct unpromoted types.*

Contrary to what many people believe, the C standard doesn’t prescribe the precision of these 12 types: it only constrains them. They depend on a lot of factors that are *implementation defined**C*.

One of the things the standard *does* prescribe is that the possible ranges of values for the signed types must include each other according to their *rank*:

![](https://drek4537l1klr.cloudfront.net/gustedt/Figures/pg_056-01_alt.jpg)

But this inclusion does not need to be strict. For example, on many platforms, the set of values of **`int`** and **`long`** are the same, although the types are considered to be different. An analogous inclusion holds for the six unsigned types:

![](https://drek4537l1klr.cloudfront.net/gustedt/Figures/pg_056-02_alt.jpg)

But remember that for any arithmetic or comparison, the narrow unsigned types are promoted to **`signed int`** and not to **`unsigned int`**, as this diagram might suggest.

The comparison of the ranges of signed and unsigned types is more difficult. Obviously, an unsigned type can never include the negative values of a signed type. For the non-negative values, we have the following inclusion of the values of types with corresponding rank:

![](https://drek4537l1klr.cloudfront.net/gustedt/Figures/pg_056-03.jpg)

That is, for a given rank, the non-negative values of the signed type fit into the unsigned type. On any modern platform you encounter, this inclusion is strict: the unsigned type has values that do not fit into the signed type. For example, a common pair of maximal values is 231–1 = 2 147 483 647 for **`signed int`** and 232–1 = 4 294 967 295 for **`unsigned int`**.

Because the interrelationship between integer types depends on the platform, choosing the “best” type for a given purpose in a portable way can be a tedious task. Luckily, we can get some help from the compiler implementation, which provides us with **`typedef`** s such as **`size_t`** that represent certain features.

##### Takeaway 5.12

*Use* **`size_t`** *for sizes, cardinalities, or ordinal numbers.*

Remember that unsigned types are the most convenient types, since they are the only types that have an arithmetic that is defined consistently with mathematical properties: the modulo operation. They can’t raise signals on overflow and can be optimized best. They are described in more detail in [section 5.7.1](/book/modern-c/chapter-5/ch05lev2sec10).

##### Takeaway 5.13

*Use* **`unsigned`** *for small quantities that can’t be negative.*

If your program really needs values that may be both positive and negative but don’t have fractions, use a signed type (see [section 5.7.5](/book/modern-c/chapter-5/ch05lev2sec14)).

##### Takeaway 5.14

*Use* **`signed`** *for small quantities that bear a sign.*

##### Takeaway 5.15

*Use* **`ptrdiff_t`** *for large differences that bear a sign.*

If you want to do fractional computation with a value such as `0.5` or `3.77189`E`+89`, use floating-point types (see [section 5.7.7](/book/modern-c/chapter-5/ch05lev2sec16)).

##### Takeaway 5.16

*Use* **`double`** *for floating-point calculations.*

##### Takeaway 5.17

*Use* **`double`** **`complex`** *for complex calculations.*

The C standard defines a lot of other types, among them other arithmetic types that model special use cases. [Table 5.2](/book/modern-c/chapter-5/ch05table02) lists some of them. The second pair represents the types with maximal width that the platform supports. This is also the type in which the preprocessor does any of its arithmetic or comparison.

##### Table 5.2. Some semantic arithmetic types for specialized use cases[(view table figure)](https://drek4537l1klr.cloudfront.net/gustedt/HighResolutionFigures/table_5-2.png)

| Type | Header | Context of definition | Meaning |
| --- | --- | --- | --- |
| **size_t** | stddef.h |  | type for “sizes” and cardinalities |
| **ptrdiff_t** | stddef.h |  | type for size differences |
| **uintmax_t** | stdint.h |  | maximum width unsigned integer, preprocessor |
| **intmax_t** | stdint.h |  | maximum width signed integer, preprocessor |
| **time_t** | time.h | **time**(0), **difftime**(t1, t0) | calendar time in seconds since epoch |
| **clock_t** | time.h | **clock**() | processor time |

The two types **`time_t`** and **`clock_t`** are used to handle times. They are semantic types, because the precision of the time computation can be different from platform to platform. The way to have a time in seconds that can be used in arithmetic is the function **difftime**: it computes the difference of two timestamps. **`clock_t`** values present the platform’s model of processor clock cycles, so the unit of time is usually much less than a second; **`CLOCKS_PER_SEC`** can be used to convert such values to seconds.

## 5.3. Specifying values

![](https://drek4537l1klr.cloudfront.net/gustedt/Figures/comm.jpg)

We have already seen several ways in which numerical constants (*literals**C*) can be specified:

| 123 | *Decimal integer constant**C*. The most natural choice for most of us. |
| --- | --- |
| 077 | *Octal integer constant**C*. This is specified by a sequence of digits, the first being 0 and the following between 0 and 7. For example, 077 has the value 63. This type of specification merely has historical value and is rarely used nowadays. Only one octal literal is commonly used: 0 itself. |
| 0xFFFF | *Hexadecimal integer constant**C*. This is specified by starting with 0x followed by a sequence of digits between 0, . . . , 9 and a . . . f. For example, 0xbeaf has the value 48815. The a .. f and x can also be written in capitals, 0XBEAF. |
| 1.7E-13 | *Decimal floating-point constants**C*. Quite familiar as the version that has a decimal point. But there is also the “scientific” notation with an exponent. In the general form, mEe is interpreted as *m* · 10*e*. |
| 0x1.7aP-13 | *Hexadecimal floating-point constants**C*. Usually used to describe floating-point values in a form that makes it easy to specify values that have exact representations. The general form 0XhPe is interpreted as *h* · 2*e*. Here, *h* is specified as a hexadecimal fraction. The exponent *e* is still specified as a decimal number. |
| 'a' | *Integer character constant**C*. These are characters put between ' apostrophes, such as 'a' or '?'. These have values that are only implicitly fixed by the C standard. For example, 'a' corresponds to the integer code for the character *a* of the Latin alphabet. Among character constants, the \ character has a special meaning. For example, we already have seen '\n' for the newline character. |
| "hello" | *String literals**C*. They specify text, such as that needed for the **printf** and **puts** functions. Again, the \ character is special, as with character constants.[[3](/book/modern-c/chapter-5/ch05fn03)] |

3 If used in the context of the **printf** function, another character also becomes “special”: the % character. If you want to print a literal % with **printf**, you have to duplicate it.

All but the last are numerical constants: they specify numbers.[[4](/book/modern-c/chapter-5/ch05fn04)] String literals are an exception and can be used to specify text that is known at compile time. Integrating larger text into our code could be tedious, if we weren’t allowed to split string literals into chunks:

4 You may have observed that complex numbers are not included in this list. We will see how to specify them in [section 5.3.1](/book/modern-c/chapter-5/ch05lev2sec5).

```
puts("first line\n"
     "another line\n"
     "first and "
     "second part of the third line");
```

##### Takeaway 5.18

*Consecutive string literals are concatenated.*

The rules for numbers are a little bit more complicated.

##### Takeaway 5.19

*Numerical literals are never negative.*

That is, if we write something like `-34` or `-1.``5`E`-23`, the leading sign is not considered part of the number but is the *negation* operator applied to the number that comes after it. We will see shortly where this is important. Bizarre as this may sound, the minus sign in the exponent is considered to be part of a floating-point literal.

We have already seen ([takeaway 5.3](/book/modern-c/chapter-5/ch05note03)) that all literals must have not only a value but also a type. Don’t mix up the fact of a constant having a positive value with its type, which can be **`signed`**.

##### Takeaway 5.20

*Decimal integer constants are signed.*

This is an important feature: we’d probably expect the expression `-1` to be a signed, negative value.

To determine the exact type for integer literals, we always have a *first fit* rule.

##### Takeaway 5.21

*A decimal integer constant has the first of the three signed types that fits it.*

This rule can have surprising effects. Suppose that on a platform, the minimal **`signed`** value is 215 = –32768 and the maximum value is 215 –1 = 32767. The constant 32768 then doesn’t fit into **`signed`** and is thus **`signed long`**. As a consequence, the expression `-32768` has type **`signed long`**. Thus the minimal value of the type **`signed`** on such a platform cannot be written as a literal constant.[[[Exs 1]](/book/modern-c/chapter-5/ch05fn-ex01)]

[Exs 1] Show that if the minimal and maximal values for **`signed long long`** have similar properties, the smallest integer value for the platform can’t be written as a combination of one literal with a minus sign.

##### Takeaway 5.22

*The same value can have different types.*

Deducing the type of an octal or hexadecimal constant is a bit more complicated. These can also be of an unsigned type if the value doesn’t fit for a signed type. In the earlier example, the hexadecimal constant `0`x7FFF has the value 32767 and thus is type **`signed`**. Other than for the decimal constant, the constant `0`x8000 (value 32768 written in hexadecimal) then is an **`unsigned`**, and expression `-0`x8000 again is **`unsigned`**.[[[Exs 2]](/book/modern-c/chapter-5/ch05fn-ex02)]

[Exs 2] Show that if the maximum **`unsigned`** is 216 –1, then `-`0x8000 has value 32768, too.

##### Takeaway 5.23

*Don’t use octal or hexadecimal constants to express negative values.*

As a consequence, there is only one choice left for negative values.

##### Takeaway 5.24

*Use decimal constants to express negative values.*

Integer constants can be forced to be unsigned or to be a type with minimal width. This is done by appending *U*, *L*, or *LL* to the literal. For example, `1`U has value 1 and type **`unsigned`**, `1`L is **`signed long`**, and `1`ULL has the same value 1 but type **`unsigned long long`**.[[[Exs 3]](/book/modern-c/chapter-5/ch05fn-ex03)] Note that we are representing C constants such as `1`ULL in typewriter font and distinguish them from their mathematical value 1 which is in normal font.

[Exs 3] Show that the expressions `-`1U, `-`1UL, and `-`1ULL have the maximum values and type as the three non-promoted unsigned types, respectively.

A common error is to try to assign a hexadecimal constant to a **`signed`** with the expectation that it will represent a negative value. Consider a declaration such as **`int`** x `= 0`xFFFFFFFF. This is done under the assumption that the hexadecimal value has the same *binary representation* as the signed value –1. On most architectures with 32-bit **`signed`**, this will be true (but not on all of them); but then nothing guarantees that the effective value +4294967295 is converted to the value –1. [Table 5.3](/book/modern-c/chapter-5/ch05table03) has some examples of interesting constants, their values and their types.

##### Table 5.3. Examples for constants and their types. This is under the supposition that **`signed`** and **`unsigned`** have the commonly used representation with 32 bits[(view table figure)](https://drek4537l1klr.cloudfront.net/gustedt/HighResolutionFigures/table_5-3.png)

| Constant *x* | Value | Type | Value of *–**x* |
| --- | --- | --- | --- |
| 2147483647 | +2147483647 | **signed** | *–*2147483647 |
| 2147483648 | +2147483648 | **signed long** | *–*2147483648 |
| 4294967295 | +4294967295 | **signed long** | *–*4294967295 |
| 0x7FFFFFFF | +2147483647 | **signed** | *–*2147483647 |
| 0x80000000 | +2147483648 | **unsigned** | +2147483648 |
| 0xFFFFFFFF | +4294967295 | **unsigned** | +1 |
| 1 | +1 | **signed** | *–*1 |
| 1U | +1 | **unsigned** | +4294967295 |

Remember that value 0 is important. It is so important that it has a lot of equivalent spellings: `0`, `0`x0, and '\0' are all the same value, a `0` of type **`signed int`**. 0 has no decimal integer spelling: `0.0` *is* a decimal spelling for the value 0 but is seen as a floating-point value with type **`double`**.

##### Takeaway 5.25

*Different literals can have the same value.*

For integers, this rule looks almost trivial, but for floating-point constants it is less obvious. Floating-point values are only an *approximation* of the value they present literally, because binary digits of the fractional part may be truncated or rounded.

##### Takeaway 5.26

*The effective value of a decimal floating-point constant may be different from its literal value.*

For example, on my machine, the constant `0.2` has the value 0.2000000000000000111, and as a consequence the constants `0.2` and `0.2000000000000000111` have the same value.

Hexadecimal floating-point constants have been designed because they better correspond to binary representations of floating-point values. In fact, on most modern architectures, such a constant (that does not have too many digits) will exactly correspond to the literal value. Unfortunately, these beasts are almost unreadable for mere humans. For example, consider the two constants `0`x1`.99999`AP`-3` and `0`xC.CCCCCCCCCCCCCCDP`-6`. The first corresponds to 1.60000002384 * 2–3 and the second to 12.8000000000000000002 * 2–6; thus, expressed as decimal floating points, their values are approximatively 0.20000000298 and 0.200000000000000000003, respectively. So the two constants have values that are very close to each other, whereas their representation as hexadecimal floating-point constants seems to put them far apart.

Finally, floating-point constants can be followed by the letter f or F to denote a **`float`** or by l or L to denote a **`long double`**. Otherwise, they are of type **`double`**. Be aware that different types of constants generally lead to different values for the same literal. Here is a typical example:

|   | **float** | **double** | **long double** |
| --- | --- | --- | --- |
| literal | 0.2F | 0.2 | 0.2L |
| value | 0x1.99999AP-3F | 0x1.999999999999AP-3 | 0xC.CCCCCCCCCCCCCCDP-6L |

##### Takeaway 5.27

*Literals have value, type, and binary representations.*

### 5.3.1. Complex constants

Complex types are not necessarily supported by all C platforms. This fact can be checked by inspecting **`__STDC_NO_COMPLEX__`**. To have full support of complex types, the header `complex.h` should be included. If you use `tgmath.h` for mathematical functions, this is already done implicitly.

`<complex.h>`

`<tgmath.h>`

Unfortunately, C provides no literals to specify constants of a complex type. It only has several macros[[5](/book/modern-c/chapter-5/ch05fn05)] that may ease the manipulation of these types.

5 We will only see in [section 5.6.3](/book/modern-c/chapter-5/ch05lev2sec8) what macros really are. For now, just take them as names to which the compiler has associated some specific property.

The first possibility to specify complex values is the macro **`CMPLX`**, which comprises two floating-point values, the real and imaginary parts, in one complex value. For example, **`CMPLX`**`(0.5, 0.5)` is a **`double`** **`complex`** value with the real and imaginary part of one-half. Analogously, there are **`CMPLXF`** for **`float`** **`complex`** and **`CMPLXL`** for **`long double`** **`complex`**.

Another, more convenient, possibility is provided by the macro I, which represents a constant value of type **`float`** **`complex`** such that I`*`I has the value –1. One-character macro names in uppercase are often used in programs for numbers that are fixed for the whole program. By itself, it is not a brilliant idea (the supply of one-character names is limited), but you should definitely leave I alone.

##### Takeaway 5.28

*`I`* *is reserved for the imaginary unit.*

I can be used to specify constants of complex types similar to the usual mathematical notation. For example, `0.5 + 0.5``*`I would be of type **`double`** **`complex`** and `0.`5F `+ 0.5`F`*`I of **`float`** **`complex`**. The compiler implicitly *converts**C* the result to the wider of the types if we mix, for example, **`float`** and **`double`** constants for real and imaginary parts.

##### Complex numbers

Can you extend the derivative ([challenge 2](/book/modern-c/chapter-3/ch03sb02)) to the complex domain: that is, functions that receive and return **`double`** **`complex`** values?

## 5.4. Implicit conversions

As we have seen in the examples, the type of an operand has an influence on the type of an operator expression such as `-1` or `-`1U: whereas the first is a **`signed int`**, the second is an **`unsigned int`**. The latter might be particularly surprising for beginners, because an **`unsigned int`** has no negative values and so the value of `-`1U is a large positive integer.

##### Takeaway 5.29

*Unary* *`-`* *and* *`+`* *have the type of their promoted argument.*

So, these operators are examples where the type usually does not change. In cases where they do change, we have to rely on C’s strategy to do *implicit conversions*: that is, to move a value with a specific type to one that has another, desired, type. Consider the following examples, again under the assumption that –2147483648 and 2147483647 are the minimal and maximal values of a **`signed int`**, respectively:

```
double          a = 1;             // Harmless; value fits type
signed short    b = -1;            // Harmless; value fits type
signed int      c = 0x80000000;    // Dangerous; value too big for type
signed int      d = -0x80000000;   // Dangerous; value too big for type
signed int      e = -2147483648;   // Harmless; value fits type
unsigned short  g = 0x80000000;    // Loses information; has value 0
```

Here, the initializations of a and b are harmless. The respective values are well in the range of the desired types, so the C compiler can convert them silently.

The next two conversions for c and d are problematic. As we have seen, `0`x80000000 is of type **`unsigned int`** and does not fit into a **`signed int`**. So c receives a value that is implementation-defined, and we have to know what our platform has decided to do in such cases. It could just reuse the bit pattern of the value on the right or terminate the program. As for all implementation-defined features, which solution is chosen should be documented by your platform, but be aware that this can change with new versions of your compiler or may be switched by compiler arguments.

For the case of d, the situation is even more complicated: `0`x80000000 has the value 2147483648, and we might expect that `-0`x80000000 is just –2147483648. But since effectively `-`0x80000000 is again 2147483648, the same problem arises as for c.[[[Exs 4]](/book/modern-c/chapter-5/ch05fn-ex04)]

[Exs 4] Under the assumption that the maximum value for **`unsigned int`** is 0xFFFFFFFF, prove that `-0`x80000000 `== 0`x80000000.

Then, e is harmless, again. This is because we used a negated decimal literal `-2147483648`, which has type **`signed long`** and whose value effectively is –2147483648 (shown earlier). Since this value fits into a **`signed int`**, the conversion can be done with no problem.

The last example for g is ambiguous in its consequences. A value that is too large for an unsigned type is converted according to the modulus. Here in particular, if we assume that the maximum value for **`unsigned short`** is 216 –1, the resulting value is 0. Whether or not such a “narrowing” conversion is the desired outcome is often difficult to tell.

##### Takeaway 5.30

*Avoid narrowing conversions.*

##### Takeaway 5.31

*Don’t use narrow types in arithmetic.*

The type rules become even more complicated for operators such as addition and multiplication that have two operands, because these then may have different types. Here are some examples of operations that involve floating-point types: Here, the first two examples are harmless: the value of the integer constant `1` fits well into the type **`double`** or **`complex`** **`float`**. In fact, for most such mixed operations, whenever the range of one type fits into the range of the other, the result has the type of the wider range.

```
1       + 0.0  // Harmless; double
1       + I    // Harmless; complex float
INT_MAX + 0.0F // May lose precision; float
INT_MAX + I    // May lose precision; complex float
INT_MAX + 0.0  // Usually harmless; double
```

The next two are problematic because **`INT_MAX`**, the maximal value for **`signed int`**, usually will not fit into a **`float`** or **`complex`** **`float`**. For example, on my machine, **`INT_MAX`** `+ 0.0`F is the same as **`INT_MAX`** `+ 1.0`F and has the value 2147483648. The last line shows that for an operation with **`double`**, this would work fine on most platforms. Nevertheless, on an existing or future platform where **`int`** is 64 bit, an analogous problem with the precision could occur.

Because there is no strict inclusion of value ranges for integer types, deducing the type of an operation that mixes signed and unsigned values can be nasty:

```
-1    < 0    // True, harmless, same signedness
-1L   < 0    // True, harmless, same signedness
-1U   < 0U   // False, harmless, same signedness
-1    < 0U   // False, dangerous, mixed signedness
-1U   < 0    // False, dangerous, mixed signedness
-1L   < 0U   // Depends, dangerous, same or mixed signedness
-1LL  < 0UL  // Depends, dangerous, same or mixed signedness
```

The first three comparisons are harmless, because even if they mix operands of different types, they do not mix signedness. Since for these cases the ranges of possible values nicely contain each other, C simply converts the other type to the wider one and does the comparison there.

The next two cases are unambiguous, but perhaps not what a naive programmer would expect. In fact, for both, all operands are converted to **`unsigned int`**. Thus both negated values are converted to large unsigned values, and the result of the comparison is **`false`**.

The last two comparisons are even more problematic. On platforms where **`UINT_MAX`** ≤ **`LONG_MAX`**, `0`U is converted to `0`L, and thus the first result is **`true`**. On other platforms with **`LONG_MAX`** *<* **`UINT_MAX`**, `-1`L is converted to `-1`U (that is, **`UINT_MAX`**), and thus the first comparison is **`false`**. Analogous observations hold for the second comparison of the last two, but be aware that there is a good chance the outcome of the two is not the same.

Examples like the last two comparisons can give rise to endless debates in favor of or against signed or unsigned types, respectively. But they show only one thing: that the semantics of mixing signed and unsigned operands is not always clear. There are cases where either possible choice of an implicit conversion is problematic.

##### Takeaway 5.32

*Avoid operations with operands of different signedness.*

##### Takeaway 5.33

*Use unsigned types whenever you can.*

##### Takeaway 5.34

*Chose your arithmetic types such that implicit conversions are harmless.*

## 5.5. Initializers

We have seen ([section 2.3](/book/modern-c/chapter-2/ch02lev1sec3)) that the initializer is an important part of an object definition. Initializers help us to guarantee that a program execution is always in a defined state: that whenever we access an object, it has a well-known value that determines the state of the abstract machine.

##### Takeaway 5.35

*All variables should be initialized.*

There are only a few exception to that rule: variable-length arrays (VLA); see [section 6.1.3](/book/modern-c/chapter-6/ch06lev2sec3), which don’t allow for an initializer, and code that must be highly optimized. The latter mainly occurs in situations that use pointers, so this is not yet relevant to us. For most code that we are able to write so far, a modern compiler will be able to trace the origin of a value to its last assignment or its initialization. Superfluous initializations or assignments will simply be optimized out.

For scalar types such as integers and floating points, an initializer just contains an expression that can be converted to that type. We have seen a lot of examples of that. Optionally, such an initializer expression may be surrounded with `{}`. Here are some examples:

```
double a = 7.8;
double b = 2 * a;
double c = { 7.8 };
double d = { 0 };
```

Initializers for other types *must* have these `{}`. For example, array initializers contain initializers for the different elements, each of which is followed by a comma:

```
double A[] = { 7.8, };
double B[3] = { 2 * A[0], 7, 33, };
double C[] = { [0] = 6, [3] = 1, };
```

![](https://drek4537l1klr.cloudfront.net/gustedt/Figures/pg_064_alt.jpg)

As we have seen, arrays that have an *incomplete type**C* because there is no length specification are completed by the initializer to fully specify the length. Here, A has only one element, whereas C has four. For the first two initializers, the element to which the scalar initialization applies is deduced from the position of the scalar in the list: for example, B`[1]` is initialized to `7`. Designated initializers as for C are by far preferable, since they make the code more robust against small changes in declarations.

##### Takeaway 5.36

*Use designated initializers for all aggregate data types.*

If you don’t know how to initialize a variable of type T, the *default initializer**C*T a `= {0}` will almost[[6](/book/modern-c/chapter-5/ch05fn06)] always do.

6 The exceptions are variable-length arrays; see [section 6.1.3](/book/modern-c/chapter-6/ch06lev2sec3).

##### Takeaway 5.37

*`{0}`* *is a valid initializer for all object types that are not VLA.*

Several things ensure that this works. First, if we omit the designation (the .membername for **`struct`** [see [section 6.3](/book/modern-c/chapter-6/ch06lev1sec3)] or `[`n`]` for arrays [see [section 6.1](/book/modern-c/chapter-6/ch06lev1sec1)]) initialization is just done in *declaration order**C*: that is, the `0` in the default initializer designates the very first member that is declared, and all other members are then initialized by default to `0` as well. Then, the `{}` form of initializers for scalars ensures that `{ 0 }` is also valid for them.

Maybe your compiler warns you about this: annoyingly, some compiler implementers don’t know about this special rule. It is explicitly designed as a catch-all initializer in the C standard, so this is one of the rare cases where I would switch off a compiler warning.

In initializers, we often have to specify values that have a particular meaning for the program.

## 5.6. Named constants

A common issue even in small programs is that they use special values for some purposes that are textually repeated all over. If for one reason or another this value changes, the program falls apart. Take an artificial setting as an example where we have arrays of strings,[[7](/book/modern-c/chapter-5/ch05fn07)] on which we would like to perform some operations:

7 This uses a *pointer*, type **`char const`**`*`**`const`**, to refer to strings. We will see later how this particular technique works.

Here we use the constant `3` in several places, and with three different “meanings” that are not very correlated. For example, an addition to our set of corvids would require two separate code changes. In a real setting, there might be many more places in the code that depend on this particular value, and in a large code base this can be very tedious to maintain.

##### Takeaway 5.38

*All constants with a particular meaning must be named.*

It is equally important to distinguish constants that are equal, but for which equality is just a coincidence.

##### Takeaway 5.39

*All constants with different meanings must be distinguished.*

C has surprisingly little means to specify named constants, and its terminology even causes a lot of confusion about which constructs effectively lead to compile-time constants. So we first have to get the terminology straight ([section 5.6.1](/book/modern-c/chapter-5/ch05lev2sec6)) before we look into the only proper named constants that C provides: enumeration constants ([section 5.6.2](/book/modern-c/chapter-5/ch05lev2sec7)). The latter will help us to replace the different versions of `3` in our example with something more explanatory. A

```
char const*const bird[3] = {
  "raven",
  "magpie",
  "jay",
};
char const*const pronoun[3] = {
  "we",
  "you",
  "they",
};
char const*const ordinal[3] = {
  "first",
  "second",
  "third",
};
...
for (unsigned i = 0; i < 3; ++i)
    printf("Corvid %u is the %s\n", i, bird[i]);
...
for (unsigned i = 0; i < 3; ++i)
    printf("%s plural pronoun is %s\n", ordinal[i], pronoun[i]);
```

second, generic, mechanism complements this feature with simple text replacement: macros ([section 5.6.3](/book/modern-c/chapter-5/ch05lev2sec8)). Macros only lead to compile-time constants if their replacements are composed of literals of base types, as we have seen. If we want to provide something close to the concept of constants for more-complicated data types, we have to provide them as temporary objects ([section 5.6.4](/book/modern-c/chapter-5/ch05lev2sec9)).

### 5.6.1. Read-only objects

Don’t confuse the term *constant*, which has a very specific meaning in C, with objects that can’t be modified. For example, in the previous code, bird, pronoun, and ordinal are not constants according to our terminology; they are **`const`**-qualified objects. This *qualifier**C* specifies that we don’t have the right to change this object. For bird, neither the array entries nor the actual strings can be modified, and your compiler should give you a diagnostic if you try to do so:

##### Takeaway 5.40

*An object of* **`const`***-qualified type is read-only.*

That doesn’t mean the compiler or run-time system may not perhaps change the value of such an object: other parts of the program may see that object without the qualification and change it. The fact that you cannot write the summary of your bank account directly (but only read it) doesn’t mean it will remain constant over time.

There is another family of read-only objects that unfortunately are not protected by their type from being modified: string literals.

![](https://drek4537l1klr.cloudfront.net/gustedt/Figures/comm.jpg)

##### Takeaway 5.41

*String literals are read-only.*

If introduced today, the type of string literals would certainly be **`char const`**`[]`, an array of **`const`**-qualified characters. Unfortunately, the **`const`** keyword was introduced to the C language much later than string literals, and therefore it remained as it is for backward compatibility.[[8](/book/modern-c/chapter-5/ch05fn08)]

8 A third class of read-only objects exist: temporary objects. We will see them later, in [section 13.2.2](/book/modern-c/chapter-13/ch13lev2sec4).

Arrays such as bird also use another technique to handle string literals. They use a *pointer**C* type, **`char const`**`*`**`const`**, to “refer” to a string literal. A visualization of such an array looks like this:

![](https://drek4537l1klr.cloudfront.net/gustedt/Figures/pg_067-01_alt.jpg)

That is, the string literals themselves are not stored inside the array bird but in some other place, and bird only refers to those places. We will see much later, in [section 6.2](/book/modern-c/chapter-6/ch06lev1sec2) and [chapter 11](/book/modern-c/chapter-11/ch11), how this mechanism works.

### 5.6.2. Enumerations

C has a simple mechanism to name small integers as we needed them in the example, called *enumerations**C*:

```
enum corvid { magpie, raven, jay, corvid_num, };
char const*const bird[corvid_num] = {
  [raven]  = "raven",
  [magpie] = "magpie",
  [jay]    = "jay",
};
...
for (unsigned i = 0; i < corvid_num; ++i)
    printf("Corvid %u is the %s\n", i, bird[i]);
```

This declares a new integer type **`enum`** corvid for which we know four different values.

##### Takeaway 5.42

*Enumeration constants have either an explicit or a positional value.*

As you might have guessed, positional values start from `0` onward, so in our example we have raven with value 0, magpie with 1, jay with 2, and corvid_num with 3. This last 3 is obviously the 3 we are interested in.

![](https://drek4537l1klr.cloudfront.net/gustedt/Figures/pg_067-02_alt.jpg)

Notice that this uses a different order for the array entries than before, and this is one of the advantages of the approach with enumerations: we do not have to manually track the order we used in the array. The ordering that is fixed in the enumeration type does that automatically.

Now, if we want to add another corvid, we just put it in the list, anywhere before corvid_num:

##### Listing 5.1. An enumeratin type and related array of strings

```
enum corvid { magpie, raven, jay, chough, corvid_num, };
char const*const bird[corvid_num] = {
  [chough] = "chough",
  [raven]  = "raven",
  [magpie] = "magpie",
  [jay]    = "jay",
};
```

As for most other narrow types, there is not really much interest in declaring variables of an enumeration type; for indexing and arithmetic, they would be converted to a wider integer, anyhow. Even the enumeration constants themselves aren’t of the enumeration type:

##### Takeaway 5.43

*Enumeration constants are of type* **`signed int`***.*

So the interest really lies in the constants, not in the newly created type. We can thus name any **`signed int`** constant that we need, without even providing a *tag**C* for the type name:

```
enum { p0 = 1, p1 = 2*p0, p2 = 2*p1, p3 = 2*p2, };
```

To define these constants, we can use *integer constant expressions**C* (*ICE*). Such an ICE provides a compile-time integer value and is much restricted. Not only must its value be determinable at compile time (no function call allowed), but also no evaluation of an object must participate as an operand to the value:

```
signed const o42 = 42;
   enum {
     b42 = 42,       // Ok: 42 is a literal.
     c52 = o42 + 10, // Error: o42 is an object.
     b52 = b42 + 10, // Ok: b42 is not an object.
   };
```

Here, o42 is an object, **`const`**-qualified but still, so the expression for c52 is not an “integer constant expression.”

##### Takeaway 5.44

*An integer constant expression doesn’t evaluate any object.*

So, principally, an ICE may consist of any operations with integer literals, enumeration constants, **`_Alignof`** and **`offsetof`** subexpressions, and eventually some **`sizeof`** subexpressions.[[9](/book/modern-c/chapter-5/ch05fn09)]

9 We will handle the latter two concepts in [sections 12.7](/book/modern-c/chapter-12/ch12lev1sec7) and [12.1](/book/modern-c/chapter-12/ch12lev1sec1).

Still, even when the value is an ICE, to be able to use it to define an enumeration constant, you have to ensure that the value fits into a **`signed`**.

### 5.6.3. Macros

Unfortunately, there is no other mechanism to declare constants of other types than **`signed int`** in the strict sense of the C language. Instead, C proposes another powerful mechanism that introduces textual replacement of the program code: *macros**C*. A macro is introduced by a *preprocessor**C* **`#define`**:

```bash
# define M_PI 3.14159265358979323846
```

This macro definition has the effect that the identifier M_PI is replaced in the following program code by the **`double`** constant. Such a macro definition consists of five different parts:

1. A starting **`#`** character that must be the first non-blank character on the line
1. The keyword **`define`**
1. An identifier that is to be declared, here M_PI
1. The replacement text, here `3.14159265358979323846`
1. A terminating newline character

With this trick, we can declare textual replacement for constants of **`unsigned`**, **`size_t`**, and **`double`**. In fact, the implementation-imposed bound of **`size_t`**, **`SIZE_MAX`**, is defined, as well as many of the other system features we have already seen: **`EXIT_SUCCESS`**, **`false`**, **`true`**, **`not_eq`**, bool, **`complex`** . . . In the color electronic versions of this book, such C standard macros are all printed in **`dark red`**.

The spelling of these examples from the C standard is not representative for the conventions that are generally used in a large majority of software projects. Most of them have quite restrictive rules such that macros visually stick out from their surroundings.

##### Takeaway 5.45

*Macro names are in all caps.*

Only deviate from that rule if you have good reasons, in particular not before you reach [level 3](/book/modern-c/part-3/part03).

### 5.6.4. Compound literals

For types that don’t have literals that describe their constants, things get even more complicated. We have to use *compound literals**C* on the replacement side of the macro. Such a compound literal has the form

```
(T){ INIT }
```

That is, a type, in parentheses, followed by an initializer. Here’s an example:

```bash
# define CORVID_NAME /**/        \
(char const*const[corvid_num]){  \
  [chough] = "chough",           \
  [raven] = "raven",             \
  [magpie] = "magpie",           \
  [jay] = "jay",                 \
}
```

With that, we could leave out the bird array and rewrite our **`for`** loop:

```
for (unsigned i = 0; i < corvid_num; ++i)
    printf("Corvid %u is the %s\n", i, CORVID_NAME[i]);
```

Whereas compound literals in macro definitions can help us to declare something that behaves similarly to a constant of a chosen type, it isn’t a constant in the narrow sense of C.

##### Takeaway 5.46

*A compound literal defines an object.*

- Overall, this form of macro has some pitfalls:
- Compound literals aren’t suitable for ICE.
- For our purpose here, to declare named constants, the type T should be **`const-`***qualified**C*. This ensures that the optimizer has a bit more slack to generate good binary code for such a macro replacement.
- There *must* be space between the macro name and the `()` of the compound literal, here indicated by the **`/`****`**`****`/`** comment. Otherwise, this would be interpreted as the start of a definition of a *function-like macro*. We will see these much later.
- A backspace character `\` at the *very end* of the line can be used to continue the macro definition to the next line.
- There must be no `;` at the end of the macro definition. Remember, it is all just text replacement.

##### Takeaway 5.47

*Don’t hide a terminating semicolon inside a macro.*

Also, for readability of macros, please pity the poor occasional reader of your code:

##### Takeaway 5.48

*Right-indent continuation markers for macros to the same column.*

As you can see in the example, this helps to visualize the entire spread of the macro definition easily.

## 5.7. Binary representions

The *binary representation* of a type is a *model* that describes the possible values for that type. It is not the same as the in-memory *object representation* that describes the more or less physical storage of values of a given type.

##### Takeaway 5.49

*The same value may have different binary representations.*

### 5.7.1. Unsigned integers

We have seen that unsigned integer types are those arithmetic types for which the standard arithmetic operations have a nice, closed mathematical description. They are closed under arithmetic operations:

##### Takeaway 5.50

*Unsigned arithmetic wraps nicely.*

In mathematical terms, they implement a *ring*, *N*, the set of integers modulo some number *N*. The values that are representable are 0*, . . . , N* – 1. The maximum value *N* – 1 completely determines such an unsigned integer type and is made available through a macro with terminating **`_MAX`** in the name. For the basic unsigned integer types, these are **`UINT_MAX`**, **`ULONG_MAX`**, and **`ULLONG_MAX`**, and they are provided through `limits.h`. As we have seen, the one for **`size_t`** is **`SIZE_MAX`** from `stdint.h`.

`<limits.h>`

`<stdint.h>`

The binary representation for non-negative integer values is always exactly what the term indicates: such a number is represented by binary digits *b*0*, b*1*. . . , b**p–1* called *bits**C*. Each of the bits has a value of 0 or 1. The value of such a number is computed as

![equation 5.1.](https://drek4537l1klr.cloudfront.net/gustedt/Figures/pg_71-1.jpg)

The value *p* in that binary representation is called the *precision**C* of the underlying type. Bit *b*0 is called the *least-significant bit**C*, and *LSB*, *b**p–1* is the *most-significant bit**C* (*MSB*).

Of the bits *b**i* that are 1, the one with minimal index *i* is called the *least-significant bit set**C*, and the one with the highest index is the *most-significant bit set**C*. For example, for an unsigned type with *p* = 16, the value `240` would have *b*4 = 1, *b*5 = 1, *b*6 = 1, and *b*7 = 1. All other bits of the binary representation are 0, the least-significant bit set *i* is *b*4, and the most-significant bit set is *b*7. From (5.1), we see immediately that 2*p* is the first value that cannot be represented with the type. Thus *N* = 2*p* and

##### Takeaway 5.51

*The maximum value of any integer type is of the form* 2*p* – 1.

Observe that for this discussion of the representation of non-negative values, we haven’t argued about the signedness of the type. These rules apply equally to signed and unsigned types. Only for unsigned types, we are lucky, and what we have said so far completely suffices to describe such an unsigned type.

##### Takeaway 5.52

*Arithmetic on an unsigned integer type is determined by its precision.*

Finally, [table 5.4](/book/modern-c/chapter-5/ch05table04) shows the bounds of some of the commonly used scalars throughout this book.

##### Table 5.4. Bounds for scalar types used in this book[(view table figure)](https://drek4537l1klr.cloudfront.net/gustedt/HighResolutionFigures/table_5-4.png)

| Name | [min, max] | Where | Typical |
| --- | --- | --- | --- |
| **size_t** | [0, **SIZE_MAX**] | <stdint.h> | [0*,* 2*w* –1], *w* = 32, 64 |
| **double** | [±**DBL_MIN**, ±**DBL_MAX**] | <**float**.h> | [±2*–w–2**,*±2*w*], *w* = 1024 |
| **signed** | [**INT_MIN**, **INT_MAX**] | <limits.h> | [–2*w**,* 2*w* –1], *w* = 31 |
| **unsigned** | [0, **UINT_MAX**] | <limits.h> | [0*,* 2*w* –1], *w* = 32 |
| bool | [**false**, **true**] | <stdbool.h> | [0*,* 1] |
| **ptrdiff_t** | [**PTRDIFF_MIN**, **PTRDIFF_MAX**] | <stdint.h> | [–2*w**,* 2*w* –1], *w* = 31*,* 63 |
| **char** | [**CHAR_MIN**, **CHAR_MAX**] | <limits.h> | [0*,* 2*w* –1], *w* = 7, 8 |
| **unsigned char** | [0, **UCHAR_MAX** ] | <limits.h> | [0, 255] |

### 5.7.2. Bit sets and bitwise operators

This simple binary representation of unsigned types allows us to use them for another purpose that is not directly related to arithmetic: as bit sets. A bit set is a different interpretation of an unsigned value, where we assume that it represents a subset of the base set *V* = {0*, . . . , p*–1} and where we take element *i* to be a member of the set, if the bit *b**i* is present.

There are three binary operators that operate on bit sets: *`|`*, *`&`*, and *`^`*. They represent the *set union* *A* *∪* *B*, *set intersection* *A* *∩* *B*, and *symmetric difference* *A*Δ*B*, respectively.

##### Table 5.5. Effects of bitwise operators[(view table figure)](https://drek4537l1klr.cloudfront.net/gustedt/HighResolutionFigures/table_5-5.png)

| Bit op | Value | Hex | *b*15 | ... | *b*0 | Set op | Set |
| --- | --- | --- | --- | --- | --- | --- | --- |
| V | 65535 | 0xFFFF | 1111111111111111 |  | {0*,* 1*,* 2*,* 3*,* 4*,* 5*,* 6*,* 7*,* 8*,* 9*,* 10*,* 11*,* 12*,* 13*,* 14*,* 15} |  |  |
| A | 240 | 0x00F0 | 0000000011110000 |  | {4*,* 5*,* 6*,* 7} |  |  |
| ~A | 65295 | 0xFF0F | 1111111100001111 | *V* *\* *A* | {0*,* 1*,* 2*,* 3*,* 8*,* 9*,* 10*,* 11*,* 12*,* 13*,* 14*,* 15} |  |  |
| -A | 65296 | 0xFF10 | 1111111100010000 |  | {4*,* 8*,* 9*,* 10*,* 11*,* 12*,* 13*,* 14*,* 15} |  |  |
| B | 287 | 0x011F | 0000000100011111 |  | {0*,* 1*,* 2*,* 3*,* 4*,* 8} |  |  |
| A\|B | 511 | 0x01FF | 0000000111111111 | *A* *∪* *B* | {0*,* 1*,* 2*,* 3*,* 4*,* 5*,* 6*,* 7*,* 8} |  |  |
| A&B | 16 | 0x0010 | 0000000000010000 | *A* *∩* *B* | {4} |  |  |
| A^B | 495 | 0x01EF | 0000000111101111 | *A*Δ*B* | {0*,* 1*,* 2*,* 3*,* 5*,* 6*,* 7*,* 8} |  |  |

For an example, let us choose *A* = 240, representing {4, 5, 6, 7}, and *B* = 287, the bit set {0, 1, 2, 3, 4, 8}; see [table 5.5](/book/modern-c/chapter-5/ch05table05). For the result of these operations, the total size of the base set, and thus the precision *p*, is not needed. As for the arithmetic operators, there are corresponding assignment operators *`&=`*, *`|=`*, and *`^=`*, respectively.[[[Exs 5]](/book/modern-c/chapter-5/ch05fn-ex05)][[[Exs 6]](/book/modern-c/chapter-5/ch05fn-ex06)][[[Exs 7]](/book/modern-c/chapter-5/ch05fn-ex07)][[[Exs 8]](/book/modern-c/chapter-5/ch05fn-ex08)]

[Exs 5] Show that *A* *\* *B* can be computed by A `-` (A&B`)`.

[Exs 6] Show that V `+ 1` is 0.

[Exs 7] Show that A`^`B is equivalent to `(`A `- (`A`&`B`)) + (`B `- (`A`&`B`))` and A `+` B `- 2*(`A`&`B`)`.

[Exs 8] Show that A`|`B is equivalent to A `+` B `- (`A`&`B`)`.

There is yet another operator that operates on the bits of the value: the complement operator *`~`*. The complement ~A would have value 65295 and would correspond to the set {0, 1, 2, 3, 8, 9, 10, 11, 12, 13, 14, 15}. This bit complement always depends on the precision *p* of the type.[[[Exs 9]](/book/modern-c/chapter-5/ch05fn-ex09)][[[Exs 10]](/book/modern-c/chapter-5/ch05fn-ex10)]

[Exs 9] Show that ~B can be computed by V `-` B.

[Exs 10] Show that -B `=` ~B `+ 1`.

All of these operators can be written with identifiers: **`bitor`**, **`bitand`**, **`xor`**, **`or_eq`**, **`and_eq`**, **`xor_eq`**, and **`compl`** if you include header `iso646.h`.

<iso646.h>A typical usage of bit sets is for *flags*, variables that control certain settings of a program:

```
enum corvid { magpie, raven, jay, chough, corvid_num, };
#define FLOCK_MAGPIE  1U
#define FLOCK_RAVEN 2U
#define FLOCK_JAY     4U
#define FLOCK_CHOUGH  8U
#define FLOCK_EMPTY   0U
#define FLOCK_FULL   15U

int main(void) {
  unsigned flock = FLOCK_EMPTY;

  ... 

  if (something) flock |= FLOCK_JAY;
  ...

  if (flock&FLOCK_CHOUGH)
    do_something_chough_specific(flock);
}
```

Here the constants for each type of corvid are a power of two, and so they have exactly one bit set in their binary representation. Membership in a flock can then be handled through the operators: `|=` adds a corvid to flock, and `&` with one of the constants tests whether a particular corvid is present.

Observe the similarity between operators `&` and `&&` or `|` and `||`: if we see each of the bits *b**i* of an **`unsigned`** as a truth value, `&` performs the *logical and* of all bits of its arguments simultaneously. This is a nice analogy that should help you memorize the particular spelling of these operators. On the other hand, keep in mind that the operators `||` and `&&` have short-circuit evaluation, so be sure to distinguish them clearly from the bit operators.

### 5.7.3. Shift operators

The next set of operators builds a bridge between interpretation of unsigned values as numbers and as bit sets. A left-shift operation *`<<`* corresponds to the multiplication of the numerical value by the corresponding power of two. For example, for *A* = 240, the set {4, 5, 6, 7}, A `<< 2` is 240 · 22 = 240 · 4 = 960, which represents the set {6, 7, 8, 9}. Resulting bits that don’t fit into the binary representation for the type are simply omitted. In our example, A `<< 9` would correspond to set {13, 14, 15, 16} (and value 122880), but since there is no bit 16, the resulting set is {13, 14, 15}, value 57344.

Thus, for such a shift operation, the precision *p* is again important. Not only are bits that don’t fit dropped, but it also restricts the possible values of the operand on the right:

##### Takeaway 5.53

*The second operand of a shift operation must be less than the precision.*

There is an analogous right-shift operation *`>>`* that shifts the binary representation toward the less-significant bits. Analogously, this corresponds to an integer division by a power of two. Bits in positions less than or equal to the shift value are omitted for the result. Observe that for this operation, the precision of the type isn’t important.[[[Exs 11]](/book/modern-c/chapter-5/ch05fn-ex11)]

[Exs 11] Show that the bits that are “lost” in an operation `x>`>n correspond to the remainder x `% (`1ULL `<<` n`)`.

- Again, there are also corresponding assignment operators *`<<=`* and *`>>=`*.
- The primary use of the left-shift operator `<<` is specifying powers of two. In our example, we can now replace the **`#define`** s:

```
#define FLOCK_MAGPIE (1U << magpie)
#define FLOCK_RAVEN    (1U << raven)
#define FLOCK_JAY      (1U << jay)
#define FLOCK_CHOUGH   (1U << chough)
#define FLOCK_EMPTY     0U
#define FLOCK_FULL    ((1U << corvid_num)-1)
```

This makes the example more robust against changes to the enumeration.

### 5.7.4. Boolean values

The Boolean data type in C is also considered an unsigned type. Remember that it has only values 0 and 1, so there are no negative values. For backward compatibility with ancient programs, the basic type is called **`_Bool`**. The name bool as well as the constants **`false`** and **`true`** only come through the inclusion of `stdbool.h`. Unless you have to maintain a `<stdbool.h>` really old code base, you should use the latter.

![](https://drek4537l1klr.cloudfront.net/gustedt/Figures/comm.jpg)

stdbool.hTreating bool as an unsigned type is a stretch of the concept. Assignment to a variable of that type doesn’t follow the modulus rule of [takeaway 4.6](/book/modern-c/chapter-4/ch04note07), but a special rule for Boolean values ([takeaway 3.1](/book/modern-c/chapter-3/ch03note01)).

You will probably rarely need bool variables. They are only useful if you want to ensure that the value is always reduced to **`false`** or **`true`** on assignment. Early versions of C didn’t have a Boolean type, and many experienced C programmers still don’t use it.

### 5.7.5. Signed integers

Signed types are *a bit* more complicated than unsigned types. A C implementation has to decide about two points:

- What happens on arithmetic overflow?
- How is the sign of a signed type represented?

Signed and unsigned types come in pairs according to their integer rank, with the notable two exceptions from [table 5.1](/book/modern-c/chapter-5/ch05table01): **`char`** and bool. The binary representation of the signed type is constrained by the inclusion diagram that we have seen above.

##### Takeaway 5.54

*Positive values are represented independently from signedness.*

Or, stated otherwise, a positive value with a signed type has the same representation as in the corresponding unsigned type. That is why the maximum value for any integer type can be expressed so easily ([takeaway 5.51](/book/modern-c/chapter-5/ch05note53)): signed types also have a precision, *p*, that determines the maximum value of the type.

The next thing the standard prescribes is that signed types have one additional bit, the *sign bit**C*. If it is 0, we have a positive value; if it is 1, the value is negative. Unfortunately, there are different concepts of how such a sign bit can be used to obtain a negative number. C allows three different *sign representations**C*:

- *Sign and magnitude**C*
- *Ones’ complement**C*
- *Two’s complement**C*

The first two nowadays probably only have historical or exotic relevance: for sign and magnitude, the magnitude is taken as positive values, and the sign bit simply specifies that there is a minus sign. Ones’ complement takes the corresponding positive value and complements all bits. Both representations have the disadvantage that two values evaluate to 0: there is a positive and a negative 0.[[10](/book/modern-c/chapter-5/ch05fn10)]

10 Since these two have fallen completely out of use on modern architectures, efforts are underway to remove them from the next revision of the C standard.

![](https://drek4537l1klr.cloudfront.net/gustedt/Figures/comm.jpg)

Commonly used on modern platforms is the two’s complement representation. It performs exactly the same arithmetic as we have seen for unsigned types, but the upper half of unsigned values (those with a high-order bit of 1) is interpreted as being negative. The following two functions are basically all that is needed to interpret unsigned values as signed values:

```
bool is_negative(unsigned a) {
  unsigned const int_max = UINT_MAX/2;
  return a > int_max;
}
bool is_signed_less(unsigned a, unsigned b) {
  if (is_negative(b) && !is_negative(a)) return false;
  else return a < b;
}
```

[Table 5.6](/book/modern-c/chapter-5/ch05table06) shows an example of how the negative of our example value `240` can be constructed. For unsigned types, -A can be computed as ~A `+ 1`.[[[Exs 12]](/book/modern-c/chapter-5/ch05fn-ex12)][[[Exs 13]](/book/modern-c/chapter-5/ch05fn-ex13)][[[Exs 14]](/book/modern-c/chapter-5/ch05fn-ex14)] Two’s complement representation performs exactly the same bit operation for signed types as for unsigned types. It only *interprets* representations that have the high-order bit as being negative.

[Exs 12] Prove that for unsigned arithmetic, A `+` `~`A is the maximum value.

[Exs 13] Prove that for unsigned arithmetic, A `+` `~`A is –1.

[Exs 14] Prove that for unsigned arithmetic, A `+ (~`A `+ 1) == 0`.

##### Table 5.6. Negation for 16-bit unsigned integer types[(view table figure)](https://drek4537l1klr.cloudfront.net/gustedt/HighResolutionFigures/table_5-6.png)

| Op | Value | *b*15 | ... | *b*0 |
| --- | --- | --- | --- | --- |
| A | 240 | 0000000011110000 |  |  |
| ~A | 65295 | 1111111100001111 |  |  |
| +1 | 65295 | 0000000000000001 |  |  |
| -A | 65296 | 1111111100010000 |  |  |

When done that way, signed integer arithmetic will again behave more or less nicely. Unfortunately, there is a pitfall that makes the outcome of signed arithmetic difficult to predict: overflow. Where unsigned values are forced to wrap around, the behavior of a signed overflow is *undefined**C*. The following two loops look much the same:

```
for (unsigned i = 1; i; ++i) do_something();
   for (  signed i = 1; i; ++i) do_something();
```

We know what happens for the first loop: the counter is incremented up to **`UINT_MAX`** and then wraps around to 0. All of this may take some time, but after **`UINT_MAX`**`-1` iterations, the loop stops because i will have reached 0.

For the second loop, everything looks similar. But because here the behavior of overflow is undefined, the compiler is allowed to *pretend* that it will never happen. Since it also knows that the value at the start is positive, it may assume that i, as long as the program has defined behavior, is never negative or 0. The *as-if* Rule ([takeaway 5.8](/book/modern-c/chapter-5/ch05note08)) allows it to optimize the second loop to

```
while (true) do_something();
```

That’s right, an *infinite loop*.

##### Takeaway 5.55

*Once the abstract state machine reaches an undefined state, no further assumption about the continuation of the execution can be made.*

Not only that, the compiler is allowed to do what it pleases for the operation itself (“*Undefined? so let’s define it*"), but it may also assume that it will never reach such a state and draw conclusions from that.

Commonly, a program that has reached an undefined state is referred to as “having” or “showing” *undefined behavior*. This wording is a bit unfortunate; in many such cases, a program does not “show” any visible signs of weirdness. In the contrary, bad things will be going on that you will not even notice for a long time.

##### Takeaway 5.56

*It is your responsibility to avoid undefined behavior of all operations.*

What makes things even worse is that on *some* platforms with *some* standard compiler options, the compilation will just look right. Since the behavior is undefined, on such a platform, signed integer arithmetic might turn out to be basically the same as unsigned. But changing the platform, the compiler, or some options can change that. All of a sudden, your program that worked for years crashes out of nowhere.

Basically, what we have discussed up to this chapter always had well-defined behavior, so the abstract state machine is always in a well-defined state. Signed arithmetic changes this, so as long as you don’t need it, avoid it. We say that a program performs a *trap**C* (or just *traps*) if it is terminated abruptly before its usual end.

##### Takeaway 5.57

*Signed arithmetic may trap badly.*

One of the things that might already overflow for signed types is negation. We have seen that **`INT_MAX`** has all bits but the sign bit set to 1. **`INT_MIN`** then has the “next” representation: the sign bit set to 1 and all other values set to 0. The corresponding value is not `-`**`INT_MAX`**.[[[Exs 15]](/book/modern-c/chapter-5/ch05fn-ex15)]

[Exs 15] Show that **`INT_MIN`**`+`**`INT_MAX`** is –1.

##### Takeaway 5.58

*In two’s complement representation,* **`INT_MIN`** *`< -`***`INT_MAX`***.*

Or, stated otherwise, in two’s complement representation, the positive value `-`**`INT_MIN`** is out of bounds since the *value* of the operation is larger than **`INT_MAX`**.

##### Takeaway 5.59

*Negation may overflow for signed arithmetic.*

For signed types, bit operations work with the binary representation. So the value of a bit operation depends in particular on the sign representation. In fact, bit operations even allow us to detect the sign representation:

```
char const* sign_rep[4] =
  {
    [1] = "sign and magnitude",
    [2] = "ones' complement",
    [3] = "two's complement",
    [0] = "weird",
  };
enum { sign_magic = -1&3, };
...
printf("Sign representation: %s.\n", sign_rep[sign_magic]);
```

The shift operations then become really messy. The semantics of what such an operation is for a negative value is not clear.

##### Takeaway 5.60

*Use unsigned types for bit operations.*

### 5.7.6. Fixed-width integer types

The precision for the integer types that we have seen so far can be inspected indirectly by using macros from `limits.h`, such as **`UINT_MAX`** and **`LONG_MIN`**. The C standard only gives us a minimal precision for them. For the unsigned types, these are

<limits.h>
| type | minimal precision |
| --- | --- |
| bool | 1 |
| **unsigned char** | 8 |
| **unsigned short** | 16 |
| **unsigned** | 16 |
| **unsigned long** | 32 |
| **unsigned long long** | 64 |

Under usual circumstances, these guarantees should give you enough information; but under some technical constraints, such guarantees might not be sufficient, or you might want to emphasize a particular precision. This may be the case if you want to use an unsigned quantity to represent a bit set of a known maximal size. If you know that 32-bit will suffice for your set, depending on your platform, you might want to choose **`unsigned`** or **`unsigned long`** to represent it.

The C standard provides names for *exact-width integer types* in `stdint.h`. As the name indicates, they are of an exact prescribed “width,” which for provided unsigned types is guaranteed to be the same as their precision.

<stdint.h>##### Takeaway 5.61

*If the type* *`uintN_t`* *is provided, it is an unsigned integer type with exactly* *N* *bits of width and precision.*

##### Takeaway 5.62

*If the type* *`intN_t`* *is provided, it is signed, with two’s complement representation and has a width of exactly* *N* *bits and a precision of* *N* – 1*.*

None of these types is guaranteed to exist, but for a convenient set of powers of two, the **`typedef`** must be provided if types with the corresponding properties exist.

##### Takeaway 5.63

*If types with the required properties exist for values of* *N* = 8, 16, 32*, and* 64*, types* *`uintN_t`* *and* *`intN_t`**, respectively, must be provided.*

Nowadays, platforms usually provide **`uint8_t`**, **`uint16_t`**, **`uint32_t`**, and **`uint64_t`** unsigned types and **`int8_t`**, **`int16_t`**, **`int32_t`**, and **`int64_t`** signed types. Their presence and bounds can be tested with the macros **`UINT8_MAX`**, . . . , **`UINT64_MAX`** for unsigned types and **`INT8_MIN`**, **`INT8_MAX`**, . . . , **`INT64_MIN`** and **`INT64_MAX`**, respectively.[[[Exs 16]](/book/modern-c/chapter-5/ch05fn-ex16)]

[Exs 16] If they exist, the values of all these macros are prescribed by the properties of the types. Think of a closed formula in *N* for these values.

To encode literals of the requested type, there are the macros **`UINT8_C`**, . . . , **`UINT64_C`**, and **`INT8_C`**, . . . , **`INT64_C`**, respectively. For example, on platforms where **`uint64_t`** is **`unsigned long`**, **`INT64_C`**`(1)` expands to 1UL.

##### Takeaway 5.64

*For any of the fixed-width types that are provided,* **`_MIN`** *(only signed), maximum* **`_MAX`***, and literals* **`_C`** *macros are provided, too.*

Since we cannot know the type behind such a fixed-width type, it would be difficult to guess the correct format specifier to use for **printf** and friends. The header `inttypes.h` provides us with macros for that. For example, for *N* = 64, we are provided with **`PRId64`**, **`PRIi64`**, **`PRIo64`**, **`PRIu64`**, **`PRIx64`**, and **`PRIX64`**, for **printf** formats "%d", "%i", "%o", "%u", "%x" and "%X", respectively:

<inttypes.h>```
uint32_t n = 78;
int64_t max = (-UINT64_C(1))>>1;    // Same value as INT64_MAX
printf("n is %" PRIu32 ", and max is %" PRId64 "\n", n, max);
```

As you can see, these macros expand to string literals that are combined with other string literals into the format string. This is certainly not the best candidate for a C coding beauty contest.

### 5.7.7. Floating-point data

Whereas integers come near the mathematical concepts of  (unsigned) or  (signed), floating-point types are close to  (non-complex) or  (complex). The way they differ from these mathematical concepts is twofold. First, there is a size restriction on what is presentable. This is similar to what we have seen for integer types. The include file `float.h`, for example, has constants **`DBL_MIN`** and **`DBL_MAX`** that provide us with the minimal and maximal values for **`double`**. But be aware that here, **`DBL_MIN`** is the smallest number that is strictly greater than `0.0`; the smallest negative **`double`** value is `-`**`DBL_MAX`**.

<float.h>But real numbers () have another difficulty when we want to represent them on a physical system: they can have an unlimited expansion, such as the value , which has an endless repetition of the digit 3 in decimal representation, or the value of π, which is “transcendent” and so has an endless expansion in any representation and doesn’t repeat in any way.

C and other programming languages deal with these difficulties by cutting off the expansion. The position where the expansion is cut is “floating” (thus the name) and depends on the magnitude of the number in question.

In a view that is a bit simplified, a floating-point value is computed from the following values:


| *s* | Sign (±1) |
| --- | --- |
| *e* | Exponent, an integer |
| *f*1*, . . . ,* *f**p* | values 0 or 1, the mantissa bits |

For the exponent, we have *e**min* ≤ *e* ≤ *e**max*. *p*, the number of bits in the mantissa, is called *precision*. The floating-point value is then given by this formula:

![](https://drek4537l1klr.cloudfront.net/gustedt/Figures/pg_79-1.jpg)

The values *p*, *emin*, and *emax* are type dependent and therefore not represented explicitly in each number. They can be obtained through macros such as **`DBL_MANT_DIG`** (for *p*, typically 53) **`DBL_MIN_EXP`** (*e**min*, –1021), and **`DBL_MAX_EXP`** (*e**max*, 1024).

If we have, for example, a number that has *s* = –1, *e* = –2, *f*1 = 1, *f*2 = 0, and *f*2 = 1, its value is

![](https://drek4537l1klr.cloudfront.net/gustedt/Figures/pg_79-2.jpg)

which corresponds to the decimal value `-0.15625`. From that calculation, we see also that floating-point values are always representable as a fraction that has some power of two in the denominator.[[[Exs 17]](/book/modern-c/chapter-5/ch05fn-ex17)]

[Exs 17] Show that all representable floating-point values with *e > p* are multiples of 2*e–p*. 

An important thing to keep in mind with such floating-point representations is that values can be cut off during intermediate computations.

##### Takeaway 5.65

*Floating-point operations are neither* associative*,* commutative*, nor* distributive*.*

So basically, they lose all the nice algebraic properties we are used to when doing pure math. The problems that arise from that are particularly pronounced if we operate with values that have very different orders of magnitude.[[[Exs 18]](/book/modern-c/chapter-5/ch05fn-ex18)] For example, adding a very small floating-point value *x* with an exponent that is less than – *p* to a value *y >* 1 just returns *y* again. As a consequence, it is really difficult to assert without further investigation whether two computations have the “same” result. Such investigations are often cutting-edge research questions, so we cannot expect to be able to assert equality or not. We are only able to tell that the results are “close."

[Exs 18] Print the results of the following expressions: `1.0`E`-13 + 1.0`E`-13` and `(1.0`E`-13 + (1.0`E`-13 + 1.0)) - 1.0`. 

##### Takeaway 5.66

*Never compare floating-point values for equality.*

<tgmath.h>The representation of the complex types is straightforward and identical to an array of two elements of the corresponding real floating-point type. To access the real and imaginary part of a complex number, two type-generic macros also come with the header `tgmath.h`: **`creal`** and **`cimag`**. For any z of one of the three complex types, we have that z `==` **`creal`**`(`z`) +` **`cimag`**`(`z`)*`I.[[11](/book/modern-c/chapter-5/ch05fn11)]

11 We will learn about such function-like macros in [section 8.1.2](/book/modern-c/chapter-8/ch08lev2sec2). 

## Summary

- C programs run in an *abstract state machine* that is mostly independent of the specific computer where it is launched.
- All basic C types are kinds of numbers, but not all of them can be used directly for arithmetic.
- Values have a type and a binary representation.
- When necessary, types of values are implicitly converted to fit the needs of particular places where they are used.
- Variables must be explicitly initialized before their first use.
- Integer computations give exact values as long as there is no overflow.
- Floating-point computations give only approximated results that are cut off after a certain number of binary digits.

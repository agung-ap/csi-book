# Chapter 3. Everything is about control

### This chapter covers

- Conditional execution with **`if`**
- Iterating over domains
- Making multiple selections

In our introductory example, [listing 1.1](/book/modern-c/chapter-1/ch01ex01), we saw two different constructs that allowed us to control the flow of a program’s execution: functions and the **`for`** iteration. Functions are a way to transfer control unconditionally. The call transfers control unconditionally *to* the function, and a **`return`** statement unconditionally transfers it *back* to the caller. We will come back to functions in [chapter 7](/book/modern-c/chapter-7/ch07).

The **`for`** statement is different in that it has a controlling condition (i `< 5` in the example) that regulates if and when the dependent block or statement (`{` **printf**`(...) }`) is executed. C has five conditional *control statements*: **`if`**, **`for`**, **`do`**, **`while`**, and **`switch`**. We will look at these statements in this chapter: **`if`** introduces a *conditional execution* depending on a Boolean expression; **`for`**, **`do`**, and **`while`** are different forms of *iterations*; and **`switch`** is a *multiple selection* based on an integer value.

C has some other conditionals that we will discuss later: the *ternary operator**C*, denoted by an expression in the form cond `?` A `:` B ([section 4.4](/book/modern-c/chapter-4/ch04lev1sec4)), the compile-time preprocessor conditionals **`#if`**`/#`**`ifdef`**`/#`**`ifndef`**`/#`**`elif`**`/#`**`else`**`/#`**`endif`** ([section 8.1.5](/book/modern-c/chapter-8/ch08lev2sec5)), and type generic expressions denoted with the keyword **`_Generic`** ([section 16.6](/book/modern-c/chapter-16/ch16lev1sec6)).

### 3.1. Conditional execution

The first construct that we will look at is specified by the keyword **`if`**. It looks like this:

```
if (i > 25) {
     j = i - 25;
   }
```

Here we compare i against the value `25`. If it is larger than 25, j is set to the value i `- 25`. In the example, i `> 25` is called the *controlling expression**C*, and the part in `{ ... }` is called the *dependent block**C*.

On the surface, this form of an **`if`** statement resembles the **`for`** statement that we already encountered. But it works differently than that: there is only one part inside the parentheses, and that determines whether the dependent statement or block is run once or not at all.

There is a more general form of the **`if`** construct:

```
if (i > 25) {
     j = i - 25;
   } else {
     j = i;
   }
```

It has a second dependent statement or block that is executed if the controlling condition is not fulfilled. Syntactically, this is done by introducing another keyword **`else`** that separates the two statements or blocks.

The **`if`** `(...) ...` **`else`** `...` is a *selection statement**C*. It selects one of the two possible *code paths**C* according to the contents of `( ... )`. The general form is

```
if (condition) statement0-or-block0
   else statement1-or-block1
```

The possibilities for condition (the controlling expression) are numerous. They can range from simple comparisons, as in this example, to very complex nested expressions. We will present all the primitives that can be used in [section 4.3.2](/book/modern-c/chapter-4/ch04lev2sec4).

The simplest of such condition specifications in an **`if`** statement can be seen in the following example, in a variation of the **`for`** loop from [listing 1.1](/book/modern-c/chapter-1/ch01ex01):

```
for (size_t i = 0; i < 5; ++i) {
     if (i) {
       printf("element %zu is %g, \tits square is %g\n",
              i,
              A[i],
              A[i]*A[i]);
     }
   }
```

Here the condition that determines whether **printf** is executed is just i: a numerical value by itself can be interpreted as a condition. The text will only be printed when the value of i is not `0`.[[[Exs 1]](/book/modern-c/chapter-3/ch03fn-ex01)]

[Exs 1] Add the **`if`** `(`i`)` condition to the program, and compare the output to the previous.

There are two simple rules for the evaluation of a numerical condition:

##### Takeaway 3.1

*The value `0` represents logical false.*

##### Takeaway 3.2

*Any value different from `0` represents logical true.*

The operators `==` and `!=` allow us to test for equality and inequality, respectively. a `==` b is true if the value of a is equal to the value of b, and false otherwise; a `!=` b is false if a is equal to b, and true otherwise. Knowing how numerical values are evaluated as conditions, we can avoid redundancy. For example, we can rewrite

```
if (i != 0) {
     ...
   }
```

as:

```
if (i) {
      ...
   }
```

Which of these two versions is more readable is a question of *coding style**C* and can be subject to fruitless debates. While the first might be easier for occasional readers of C code to read, the latter is often preferred in projects that assume some knowledge about C’s type system.

<stdbool.h>The type bool, specified in `stdbool.h`, is what we should be using if we want to store truth values. Its values are **`false`** and **`true`**. Technically, **`false`** is just another name for `0` and **`true`** for `1`. It’s important to use **`false`** and **`true`** (and not the numbers) to emphasize that a value is to be interpreted as a condition. We will learn more about the bool type in [section 5.7.4](/book/modern-c/chapter-5/ch05lev2sec13).

Redundant comparisons quickly become unreadable and clutter your code. If you have a conditional that depends on a truth value, use that truth value directly as the condition. Again, we can avoid redundancy by rewriting something like

```
bool b = ...;
   ...
   if ((b != false) == true) {
     ...
   }
```

as

```
bool b = ...;
   ...
   if (b) {
     ...
   }
```

Generally:

##### Takeaway 3.3

*Don’t compare to `0`*, **`false`**, *or* **`true`**.

Using the truth value directly makes your code clearer and illustrates one of the basic concepts of the C language:

##### Takeaway 3.4

*All scalars have a truth value.*

Here, *scalar**C* types include all the numerical types such as **`size_t`**, bool, and **`int`** that we already encountered, and *pointer**C* types; see [table 3.1](/book/modern-c/chapter-3/ch03table01) for the types that are frequently used in this book. We will come back to them in [section 6.2](/book/modern-c/chapter-6/ch06lev1sec2).

##### Table 3.1. Scalar types used in this book[(view table figure)](https://drek4537l1klr.cloudfront.net/gustedt/HighResolutionFigures/table_3-1.png)

| Level | Name | Other | Category | Where | **printf** |
| --- | --- | --- | --- | --- | --- |
| 0 | **size_t** |  | Unsigned | <stddef.h> | "%zu" "%zx" |
| 0 | **double** |  | Floating | Built in | "%e" "%f" "%g" "%a" |
| 0 | **signed** | **int** | Signed | Built in | "%d" |
| 0 | **unsigned** |  | Unsigned | Built in | "%u" "%x" |
| 0 | bool | **_Bool** | Unsigned | <stdbool.h> | "%d" as 0 or 1 |
| 1 | **ptrdiff_t** |  | Signed | <stddef.h> | "%td" |
| 1 | **char const*** |  | String | Built in | "%s" |
| 1 | **char** |  | Character | Built in | "%c" |
| 1 | **void*** |  | Pointer | Built in | "%p" |
| 2 | **unsigned char** |  | Unsigned | Built in | "%hhu" "%02hhx" |

### 3.2. Iterations

Previously, we encountered the **`for`** statement to iterate over a domain; in our introductory example, it declared a variable i that was set to the values `0`, `1`, `2`, `3`, and `4`. The general form of this statement is

```
for (clause1; condition2; expression3) statement-or-block
```

This statement is actually quite generic. Usually, clause1 is an assignment expression or a variable definition. It serves to state an initial value for the iteration domain. condition2 tests whether the iteration should continue. Then, expression3 updates the iteration variable used in clause1. It is performed at the end of each iteration. Some advice:

- Because we want iteration variables to be defined narrowly in the context for a **`for`** loop (*cf.* [takeaway 2.11](/book/modern-c/chapter-2/ch02note12)), clause1 should in most cases be a variable definition.
- Because **`for`** is relatively complex with its four different parts and not easy to capture visually, statement`-`**`or`**`-`block should usually be a `{ ... }` block.
**
**1
**

**

Let’s see some more examples:

```
for (size_t i = 10; i; --i) {
     something(i);
   }
   for (size_t i = 0, stop = upper_bound(); i < stop; ++i) {
     something_else(i);
   }
   for (size_t i = 9; i <= 9; --i) {
     something_else(i);
   }
```

The first **`for`** counts i down from `10` to `1`, inclusive. The condition is again just the evaluation of the variable i; no redundant test against value `0` is required. When i becomes `0`, it will evaluate to false, and the loop will stop. The second **`for`** declares two variables, i and stop. As before, i is the loop variable, stop is what we compare against in the condition, and when i becomes greater than or equal to stop, the loop terminates.

The third **`for`** looks as though it would go on forever, but actually it counts down from `9` to `0`. In fact, in the next chapter, we will see that “sizes” in C (numbers that have type **`size_t`**) are never negative.[[[Exs 2]](/book/modern-c/chapter-3/ch03fn-ex02)]

[Exs 2] Try to imagine what happens when i has value `0` and is decremented by means of the operator `--`.

Observe that all three **`for`** statements declare variables named i. These three variables with the same name happily live side by side, as long as their scopes don’t overlap.

There are two more iterative statements in C, **`while`** and **`do`**:

```
while (condition) statement-or-block
   do statement-or-block while(condition);
```

The following example shows a typical use of the first. It implements the so-called *Heron approximation* to compute the multiplicative inverse  of a number *x*.

```
#include <tgmath.h>

   double const eps = 1E-9;            // Desired precision
   ...
   double const a = 34.0;
   double x = 0.5;
   while (fabs(1.0 - a*x) >= eps) {    // Iterates until close
     x *= (2.0 - a*x);                 // Heron approximation
   }
```

It iterates as long as the given condition evaluates true. The **`do`** loop is very similar, except that it checks the condition *after* the dependent block:

```
do {                               // Iterates
     x *= (2.0 - a*x);                // Heron approximation
   } while (fabs(1.0 - a*x) >= eps);  // Iterates until close
```

This means if the condition evaluates to false, a **`while`** loop will not run its dependent block at all, and a **`do`** loop will run it once before terminating.

As with the **`for`** statement, with **`do`** and **`while`** it is advisable to use the `{ ... }` block variants. There is also a subtle syntactical difference between the two: **`do`** always needs a semicolon `;` after the **`while`** (conditio`n)` to terminate the statement. Later, we will see that this is a syntactic feature that turns out to be quite useful in the context of multiple nested statements; see [section 10.2.1](/book/modern-c/chapter-10/ch10lev2sec1).

All three iteration statements become even more flexible with **`break`** and **`continue`** statements. A **`break`** statement stops the loop without reevaluating the termination condition or executing the part of the dependent block after the **`break`** statement:

```
while (true) {
  double prod = a*x;
  if (fabs(1.0 - prod) < eps) {      // Stops if close enough
    break;
  }
  x *= (2.0 - prod);                 // Heron approximation
}
```

This way, we can separate the computation of the product a`*`x, the evaluation of the stop condition, and the update of x. The condition of the **`while`** then becomes trivial. The same thing can be done using a **`for`**, and there is a tradition among C programmers to write it as follows:

```
for (;;) {
  double prod = a*x;
  if (fabs(1.0 - prod) < eps) {      // Stops if close enough
    break;
  }
  x *= (2.0 - prod);                 // Heron approximation
}
```

**`for`**`(;;)` here is equivalent to **`while`**`(`**`true`**`)`. The fact that the controlling expression of a **`for`** (the middle part between the `;;`) can be omitted and is interpreted as “always **`true`**” is just a historical artifact in the rules of C and has no other special purpose.

![](https://drek4537l1klr.cloudfront.net/gustedt/Figures/pg_032.jpg)

The **`continue`** statement is less frequently used. Like **`break`**, it skips the execution of the rest of the dependent block, so all statements in the block after the **`continue`** are not executed for the current iteration. However, it then reevaluates the condition and continues from the start of the dependent block if the condition is true:

```
for (size_t i =0; i < max_iterations; ++i) {
  if (x > 1.0) {   // Checks if we are on the correct side of 1
    x = 1.0/x;
    continue;
  }
  double prod = a*x;
  if (fabs(1.0 - prod) < eps) {     // Stops if close enough
    break;
  }
  x *= (2.0 - prod);                // Heron approximation
}
```

<tgmath.h>In these examples, we use a standard macro **`fabs`**, which comes with the `tgmath.h` header[[1](/book/modern-c/chapter-3/ch03fn01)]. It calculates the absolute value of a **`double`**. [Listing 3.1](/book/modern-c/chapter-3/ch03ex02) is a complete program that implements the same algorithm, where **`fabs`** has been replaced by several explicit comparisons against certain fixed numbers: for example, eps1m24 defined to be 1 – 2–24, or eps1p24 as 1 + 2–24. We will see later ([section 5.3](/book/modern-c/chapter-5/ch05lev1sec3)) how the constants `0`x1P`-24` and similar used in these definitions work.

1 “tgmath” stands for *type generic mathematical functions*.

In the first phase, the product of the current number under investigation a with the current estimate x is compared to 1.5 and 0.5, and then x is multiplied by 0.5 or 2 until the product is close to 1. Then, the Heron approximation as shown in the code is used in a second iteration to close in and to compute the multiplicative inverse with high accuracy.

The overall task of the program is to compute the inverse of all numbers that are provided to it on the command line. An example of a program execution looks like this:

##### `Terminal`

```
0    > ./heron 0.07 5 6E+23
1    heron: a=7.00000e-02, x=1.42857e+01, a*x=0.999999999996
2    heron: a=5.00000e+00, x=2.00000e-01, a*x=0.999999999767
3    heron: a=6.00000e+23, x=1.66667e-24, a*x=0.999999997028
```

To process the numbers on the command line, the program uses another library function **strtod** from `stdlib.h`.[[[Exs 3]](/book/modern-c/chapter-3/ch03fn-ex03)][[[Exs 4]](/book/modern-c/chapter-3/ch03fn-ex04)][[[Exs 5]](/book/modern-c/chapter-3/ch03fn-ex05)]

[Exs 3] Analyze [listing 3.1](/book/modern-c/chapter-3/ch03ex02) by adding **printf** calls for intermediate values of x.

[Exs 4] Describe the use of the parameters argc and argv in [listing 3.1](/book/modern-c/chapter-3/ch03ex02).

[Exs 5] Print out the values of eps1m01, and observe the output when you change them slightly.

<stdlib.h>##### Sequential sorting algorithms

Can you do

1. A merge sort (with recursion)
1. A quick sort (with recursion)

on arrays with sort keys such as **`double`** or strings to your liking?

Nothing is gained if you don’t know whether your programs are correct. Therefore, can you provide a simple test routine that checks if the resulting array really is sorted?

This test routine should just scan once through the array and should be much, much faster than your sorting algorithms.

##### Listing 3.1. Computing multiplicative inverses of numbers

```
1   #include <stdlib.h>
 2   #include <stdio.h>
 3
 4   /* lower and upper iteration limits centered around 1.0 */
 5   static double const eps1m01 = 1.0 - 0x1P-01;
 6   static double const eps1p01 = 1.0 + 0x1P-01;
 7   static double const eps1m24 = 1.0 - 0x1P-24;
 8   static double const eps1p24 = 1.0 + 0x1P-24;
 9
10   int main(int argc, char* argv[argc+1]) {
11     for (int i = 1; i < argc; ++i) {        // process args
12       double const a = strtod(argv[i], 0);  // arg -> double
13       double x = 1.0;
14       for (;;) {                    // by powers of 2
15         double prod = a*x;
16         if (prod < eps1m01) {
17           x *= 2.0;
18         } else if (eps1p01 < prod) {
19           x *= 0.5;
20         } else {
21           break;
22         }
23       }
24       for (;;) {                    // Heron approximation
25         double prod = a*x;
26         if ((prod < eps1m24) || (eps1p24 < prod)) {
27           x *= (2.0 - prod);
28         } else {
29           break;
30         }
31       }
32       printf("heron: a=%.5e,\tx=%.5e,\ta*x=%.12f\n",
33              a, x, a*x);
34     }
35     return EXIT_SUCCESS;
36   }
```

### 3.3. Multiple selection

The last control statement that C has to offer is the **`switch`** statement and is another *selection**C* statement. It is mainly used when cascades of **`if-else`** constructs would be too tedious:

```
if (arg == 'm') {
     puts("this is a magpie");
   } else if (arg == 'r') {
     puts("this is a raven");
   } else if (arg == 'j') {
     puts("this is a jay");
   } else if (arg == 'c') {
     puts("this is a chough");
   } else {
     puts("this is an unknown corvid");
   }
```

In this case, we have a choice that is more complex than a **`false`**`-`**`true`** decision and that can have several outcomes. We can simplify this as follows:

```
switch (arg) {
     case 'm': puts("this is a magpie");
               break;
     case 'r': puts("this is a raven");
                  break;
     case 'j': puts("this is a jay");
               break;
     case 'c': puts("this is a chough");
               break;
     default: puts("this is an unknown corvid");
   }
```

Here we select one of the **puts** calls according to the value of the arg variable. Like **printf**, the function **puts** is provided by `stdio.h`. It outputs a line with the string that is passed as an argument. We provide specific cases for characters 'm', 'r', 'j', 'c', and a *fallback**C* case labeled **`default`**. The default case is triggered if arg doesn’t match any of the **`case`** values.[[[Exs 6]](/book/modern-c/chapter-3/ch03fn-ex06)]

[Exs 6] Test the example **`switch`** statement in a program. See what happens if you leave out some of the **`break`** statements.

<stdio.h>Syntactically, a **`switch`** is as simple as

```
switch (expression) statement-or-block
```

and its semantics are quite straightforward: the **`case`** and **`default`** labels serve as *jump targets**C*. According to the value of the expression, control continues at the statement that is labeled accordingly. If we hit a **`break`** statement, the whole **`switch`** under which it appears terminates, and control is transferred to the next statement after the **`switch`**.

By that specification, **`switch`** statements can be used much more widely than iterated **`if-else`** constructs:

```
switch (count) {
     default:puts("++++ ..... +++");
     case 4: puts("++++");
     case 3: puts("+++");
     case 2: puts("++");
     case 1: puts("+");
     case 0:;
   }
```

Once we have jumped into the block, execution continues until it reaches a **`break`** or the end of the block. In this case, because there are no **`break`** statements, we end up running all subsequent **puts** statements. For example, the output when the value of count is `3` is a triangle with three lines:

##### `Terminal`

```
0    +++
1    ++
2    +
```

The structure of a **`switch`** can be more flexible than **`if-else`**, but it is restricted in another way:

##### Takeaway 3.5

**`case`** *values must be integer constant expressions.*

In [section 5.6.2](/book/modern-c/chapter-5/ch05lev2sec7), we will see what these expressions are in detail. For now, it suffices to know that these have to be fixed values that we provide directly in the source, such as the `4`, `3`, `2`, `1`, `0` in the previous example. In particular, variables such as count are only allowed in the **`switch`** part, not in the individual **`case`** s.

With the greater flexibility of the **`switch`** statement also comes a price: it is more error prone. In particular, we might accidentally skip variable definitions:

##### Takeaway 3.6

**`case`** *labels must not jump beyond a variable definition.*

##### Numerical derivatives

Something we’ll deal with a lot is the concept of numerical algorithms. To get your hands dirty, see if you can implement the numerical derivative **`double`** f`(`**`double`** x`)` of a function **`double`** F`(`**`double`** x`)`.

Implement this with an example F for the function that you use for this exercise. A good primary choice for F would be a function for which you know the derivative, such as **`sin`**, **`cos`**, or **`sqrt`**. This allows you to check your results for correctness.

##### π

Compute the *N* first decimal places of *π*.

## Summary

- Numerical values can be directly used as conditions for **`if`** statements; 0 represents “false,” and all other values are “true.”
- There are three different iteration statements: **`for`**, **`do`**, and **`while`**. **`for`** is the preferred tool for domain iterations.
- A **`switch`** statement performs multiple selection. One **`case`** runs into the next, if it is not terminated by a **`break`**.

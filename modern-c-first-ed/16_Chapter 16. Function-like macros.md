# Chapter 16. Function-like macros

### This chapter covers

- Checking arguments
- Accessing the calling context
- Working with variadic macros
- Type-generic programming

We have encountered *function-like* macros explicitly in [section 10.2.1](/book/modern-c/chapter-10/ch10lev2sec1) and also implicitly. Some interfaces in the C standard library are typically implemented by using them, such as the type-generic interfaces in `tgmath.h`. We also have seen that function-like macros can easily obfuscate our code and require a certain restrictive set of rules. The easiest strategy to avoid many of the problems that come with function-like macros is to only use them where they are irreplaceable, and to use appropriate means where they are replaceable.

<tgmath.h>##### Takeaway 16.1

*Whenever possible, prefer an* **`inline`** *function to a functional macro.*

That is, in situations where we have a fixed number of arguments with a known type, we should provide a proper type-safe interface in the form of a function prototype. Let us suppose we have a simple function with side effects:

```
unsigned count(void) {
  static counter = 0;
  ++counter;
  return counter;
}
```

Now consider that this function is used with a macro to square a value:

```
#define square_macro(X) (X*X)   // Bad: do not use this.
...
  unsigned a = count();
  unsigned b = square_macro(count());
```

Here, the use of square_macro`(`count`())` is replaced by count`()*`count`()`, two executions of count:[[[Exs 1]](/book/modern-c/chapter-16/ch16fn-ex01)] That is probably not what a naive reader expects at that point.

[Exs 1] Show that b `==` a`*`a `+ 3*`a `+ 2`.

To achieve the same performance as with a function-like macro, it is completely sufficient to provide an **`inline`** definition in a header file:

```
inline unsigned square_unsigned(unsigned x) {  // Good 
  return x*x;
}
...
  unsigned c = count();
  unsigned d = square_unsigned(count());
```

Here, square_unsigned`(`count`())` leads to only one execution of count.[[[Exs 2]](/book/modern-c/chapter-16/ch16fn-ex02)]

[Exs 2] Show that d `==` c`*`c `+ 2*`c `+ 1`.

But there are many situations where function-like macros can do more than a function. They can

- Force certain type mapping and argument checking
- Trace execution
- Provide interfaces with a variable number of arguments
- Provide type-generic interfaces
- Provide default arguments to functions

In this chapter, I will try to explain how such features can be implemented. We will also discuss two other features of C that are clearly to be distinguished: one, **`_Generic`**, because it is useful in macros and would be very tedious to use without them; and the other, *variadic functions*, because they are now mostly obsolete and should *not* be used in new code.

A warning about this chapter is also in order. Macro *programming* quickly becomes ugly and barely readable, so you will need patience and good will to understand some of the code here. Let us take an example:

```
#define MINSIZE(X, Y) (sizeof(X)<sizeof(Y) ? sizeof(X) :sizeof(Y))
```

The right side, the replacement string, is quite complex. It has four **`sizeof`** evaluations and some operators that combine them. But the *usage* of this macro shouldn’t be difficult: it simply computes the minimum size of the arguments.

##### Takeaway 16.2

*A functional macro shall provide a simple interface to a complex task.*

## 16.1. How function-like macros work

To provide the features that we listed, C has chosen a path that is quite different from other popular programming languages: textual replacement. As we have seen, macros are replaced in a very early stage of compilation, called *preprocessing*. This replacement follows a strict set of rules that are specified in the C standard, and all compilers (on the same platform) should preprocess any source code to exactly the same intermediate code.

Let us add the following to our example:

```
#define BYTECOPY(T, S) memcpy(&(T), &(S), MINSIZE(T, S))
```

Now we have two macro definitions for macros MINSIZE and BYTECOPY. The first has a *parameter list* `(`X`,` Y`)` that defines two parameters X and Y, and *replacement text*

```
(sizeof(X)<sizeof(Y) ? sizeof(X) : sizeof(X))
```

that refers to X and Y. Similarly, BYTECOPY also has two parameters T and S and replacement text starting with **memcpy**.

These macros fulfill our requirements about function-like macros: they evaluate each argument only once,[[[Exs 3]](/book/modern-c/chapter-16/ch16fn-ex03)] parenthesize all arguments with `()`, and have no hidden effects such as unexpected control flow. The parameters of a macro must be identifiers. A special scope rule restricts the validity of these identifiers to use inside the replacement text.

[Exs 3] Why is this so?

When the compiler encounters the name of a functional macro followed by a closing pair of `()`, such as in BYTECOPY`(`A`,` B`)`, it considers this a *macro call* and replaces it textually according to the following rules:

1. The definition of the macro is temporarily disabled to avoid infinite recursion.
1. The text inside the `()`, the *argument list*, is scanned for parentheses and commas. Each opening parenthesis `(` must match a `)`. A comma that is not inside such additional `()` is used to separate the argument list into the arguments. For the case that we handle here, the number of arguments must match the number of parameters in the definition of the macro.
1. Each argument is recursively expanded for macros that might appear in them. In our example, A could be yet another macro and expand to some variable name such as redA.
1. The resulting text fragments from the expansion of the arguments are assigned to the parameters.
1. A copy of the replacement text is made, and all occurrences of the parameters are replaced with their respective definitions.
1. The resulting replacement text is subject to macro replacement, again.
1. This final replacement text is inserted in the source instead of the macro call.
1. The definition of the macro is re-enabled.

This procedure looks a bit complicated at first glance but is effectively quite easy to implement and provides a reliable sequence of replacements. It is guaranteed to avoid infinite recursion and complicated local variable assignments. In our case, the result of the expansion of BYTECOPY`(`A`,` B`)` would be

```
memcpy(&(redA), &(B), (sizeof((redA))<sizeof((B))?sizeof((redA)):sizeof((B))
    ))
```

We already know that identifiers of macros (function-like or not) live in a namespace of their own. This is for a very simple reason:

##### Takeaway 16.3

*Macro replacement is done in an early translation phase, before any other interpretation is given to the tokens that compose the program.*

So the preprocessing phase knows nothing about keywords, types, variables, or other constructs of later translation phases.

Since recursion is explicitly disabled for macro expansion, there can even be functions that use the same identifier as a function-like macro. For example, the following is valid C:

```
1   inline
2   char const* string_literal(char const str[static 1]){
3     return str;
4   }
5   #define string_literal(S) string_literal("" S "")
```

It defines a function string_literal that receives a character array as an argument, and a macro of the same name that calls the function with a weird arrangement of the argument, the reason for which we will see shortly. There is a more specialized rule that helps to deal with situations where we have a macro and a function with the same name. It is analogous to function decay ([takeaway 11.22](/book/modern-c/chapter-11/ch11note22)).

##### Takeaway 16.4 (macro retention)

*If a functional macro is not followed by* *`()`**, it is not expanded.*

In the previous example, the definition of the function and of the macro depend on their order of appearance. If the macro definition was given first, it would immediately expand to something like

```
1   inline
 2   char const* string_literal("" char const str[static 1] ""){ // Error 
 3     return str;
 4   }
```

which is erroneous. But if we surround the name string_literal with parentheses, it is not expanded and remains a valid definition. A complete example could look like this:

```
1   // header file 
 2   #define string_literal(S) string_literal("" S "")
  3   inline char const* (string_literal)(char const str[static 1]){
 4     return str;
 5   }
 6   extern char const* (*func)(char const str[static 1]);
 7   // One translation unit 
 8   char const* (string_literal)(char const str[static 1]);
 9   // Another translation unit 
10   char const* (*func)(char const str[static 1]) = string_literal;
```

That is, both the inline definition and the instantiating declaration of the function are protected by surrounding `()` and don’t expand the functional macro. The last line shows another common usage of this feature. Here string_literal is not followed by `()`, so both rules are applied. First macro retention inhibits the expansion of the macro, and then function decay ([takeaway 11.22](/book/modern-c/chapter-11/ch11note22)) evaluates the use of the function to a pointer to that function.

## 16.2. Argument checking

As we said earlier, in cases where we have a fixed number of arguments with types that are well-modeled by C’s type system, we should use functions and not function-like macros. Unfortunately, C’s type system doesn’t cover all special cases that we might want to distinguish.

An interesting such case is string literals that we want to pass to a potentially dangerous function such as **printf**. As we saw in [section 5.6.1](/book/modern-c/chapter-5/ch05lev2sec6), string literals are read-only but are not even **`const`** qualified. Also, an interface with `[`**`static`** `1]`, like the earlier *function* string_literal, is not enforced by the language, because prototypes without `[`**`static`** `1]` are equivalent. In C, there is no way to prescribe for a parameter str of a function interface that it should fulfill the following constraints:

- Is a character pointer
- Must be non-null
- Must be immutable[[1](/book/modern-c/chapter-16/ch16fn01)]

1 **`const`** only constrains the called function, not the caller.

- Must be `0`-terminated

All these properties could be particularly useful to check at compile time, but we simply have no way to specify them in a function interface.

The *macro* string_literal fills that gap in the language specification. The weird empty string literals in its expansion "" X "" ensure that string_literal can only be called with a string literal:

```
1   string_literal("hello");   // "" "hello" "" 
2   char word[25] = "hello";
3   ...
4   string_literal(word);      // "" word ""      // Error
```

The macro and function string_literal are just a simple example of this strategy. A more useful example would be

##### **`macro_trace.h`**

```
12   /**
13    ** @brief A simple version of the macro that just does 
14    ** a @c fprintf or nothing 
15    **/ 
16   #if NDEBUG
17   # define TRACE_PRINT0(F, X) do { /* nothing */ } while (false)
18   #else
19   # define TRACE_PRINT0(F, X) fprintf(stderr, F, X)
20   #endif
```

a macro that could be used in the context of a debug build of a program to insert debugging output:

##### **`macro_trace.c`**

```
17     TRACE_PRINT0("my favorite variable: %g\n", sum);
```

This looks harmless and efficient, but it has a pitfall: the argument F can be any pointer to **`char`**. In particular, it could be a format string that sits in a modifiable memory region. This may have the effect that an erroneous or malicious modification of that string leads to an invalid format, and thus to a crash of the program, or could divulge secrets. In [section 16.5](/book/modern-c/chapter-16/ch16lev1sec5), we will see more in detail why this is particularly dangerous for functions like **fprintf**.

In simple code as in the example, where we pass simple string literals to **fprintf**, these problems should not occur. Modern compiler implementations are able to trace arguments to **fprintf** (and similar) to check whether format specifiers and other arguments match.

This check doesn’t work if the format that is passed to **fprintf** is not a string literal but just any pointer to **`char`**. To inhibit that, we can enforce the use of a string literal here:

##### **`macro_trace.h`**

```
22   /**
23    ** @brief A simple version of the macro that ensures that the @c 
24    ** fprintf format is a string literal 
25    **
26    ** As an extra, it also adds a newline to the printout, so 
27    ** the user doesn't have to specify it each time. 
28    **/ 
29   #if NDEBUG
30   # define TRACE_PRINT1(F, X) do { /* nothing */ } while (false)
31   #else
32   # define TRACE_PRINT1(F, X) fprintf(stderr, "" F "\n", X)
33   #endif
```

Now, F must receive a string literal, and the compiler then can do the work and warn us about a mismatch.

The macro TRACE_PRINT1 still has a weak point. If it is used with **`NDEBUG`** set, the arguments are ignored and thus not checked for consistency. This can have the long-term effect that a mismatch remains undetected for a long time and all of a sudden appears when debugging.

So the next version of our macro is defined in two steps. The first uses a similar **`#if`**`/#`**`else`** idea to define a new macro: TRACE_ON.

##### **`macro_trace.h`**

```
35   /**
36    ** @brief A macro that resolves to @c 0 or @c 1 according to @c 
37    ** NDEBUG being set 
38    **/ 
39   #ifdef NDEBUG
40   # define TRACE_ON 0
41   #else
42   # define TRACE_ON 1
43   #endif
```

In contrast to the **`NDEBUG`** macro, which could be set to any value by the programmer, this new macro is guaranteed to hold either `1` or `0`. Second, TRACE_PRINT2 is defined with a regular **`if`** conditional:

##### **`macro_trace.h`**

```
45   /**
46    ** @brief A simple version of the macro that ensures that the @c 
47    ** fprintf call is always evaluated 
48    **/ 
49   #define TRACE_PRINT2(F, X)                                       \
50   do { if (TRACE_ON) fprintf(stderr, "" F "\n", X); } while (false)
```

Whenever its argument is `0`, any modern compiler should be able to optimize out the call to **fprintf**. What it shouldn’t omit is the argument check for the parameters F and X. So regardless of whether we are debugging, the arguments to the macro must always be matching, because **fprintf** expects it.

Similar to the use of the empty string literal "" earlier, there are other tricks to force a macro argument to be a particular type. One of these tricks consists of adding an appropriate `0`: `+0` forces the argument to be any arithmetic type (integer, float, or pointer). Something like `+0.`0F promotes to a floating type. For example, if we want to have a simpler variant to just print a value for debugging, without keeping track of the type of the value, this could be sufficient for our needs:

##### **`macro_trace.h`**

```
52   /**
53    ** @brief Traces a value without having to specify a format 
54    **/ 
55   #define TRACE_VALUE0(HEAD, X) TRACE_PRINT2(HEAD " %Lg", (X)+0.0L)
```

It works for any value X that is either an integer or a floating point. The format "%Lg" for a **`long double`** ensures that any value is presented in a suitable way. Evidently, the HEAD argument now must not contain any **fprintf** format, but the compiler will tell us if the there is a mismatch.

Then, compound literals can be a convenient way to check whether the value of a parameter X is assignment-compatible to a type T. Consider the following first attempt to print a pointer value:

##### **`macro_trace.h`**

```
57   /**
58    ** @brief Traces a pointer without having to specify a format 
59    **
60    ** @warning Uses a cast of @a X to @c void*
61    **/ 
62   #define TRACE_PTR0(HEAD, X)  TRACE_PRINT2(HEAD " %p", (void*)(X))
```

It tries to print a pointer value with a "%p" format, which expects a generic pointer of type **`void`**`*`. Therefore, the macro uses a *cast* to convert the value and type of X to **`void`**`*`. Like most casts, a cast here can go wrong if X isn’t a pointer: because the cast tells the compiler that we know what we are doing, all type checks are actually switched off.

This can be avoided by assigning X first to an object of type **`void`**`*`. Assignment only allows a restricted set of *implicit conversions*, here the conversion of any pointer to an object type to **`void`**`*`:

##### **`macro_trace.h`**

```
64   /**
65    ** @brief Traces a pointer without specifying a format 
66    **/
67   #define TRACE_PTR1(HEAD, X)                     \
68   TRACE_PRINT2(HEAD " %p", ((void*){ 0 } = (X)))
```

The trick is to use something like `((`T`){ 0 } = (`X`))` to check whether X is assignment-compatible to type T. Here, the compound literal `((`T`){ 0 }` first creates a temporary object of type T to which we then assign X. Again, a modern optimizing compiler should optimize away the use of the temporary object and only do the type checking for us.

## 16.3. Accessing the calling context

Since macros are just textual replacements, they can interact much more closely with the context of their caller. In general, for usual functionality, this isn’t desirable, and we are better off with the clear separation between the context of the caller (evaluation of function arguments) and that of the callee (use of function parameters).

In the context of debugging, though, we usually want to break that strict separation to observe part of the state at a specific point in our code. In principle, we could access any variable inside a macro, but generally we want some more specific information about the calling environment: a trace of the position from which particular debugging output originates.

C offers several constructs for that purpose. It has a special macro **`__LINE__`** that always expands to a decimal integer constant for the number of the actual line in the source:

##### **`macro_trace.h`**

```
70   /**
71    ** @brief Adds the current line number to the trace 
72    **/ 
73   #define TRACE_PRINT3(F, X)                               \
74   do {                                                     \
75     if (TRACE_ON)                                          \
76       fprintf(stderr, "%lu: " F "\n", __LINE__+0UL, X);   \
77   } while (false)
```

Likewise, the macros **`__DATE__`**, **`__TIME__`**, and **`__FILE__`** contain string literals with the date and time of compilation and the name of the current TU. Another construct, **`__func__`**, is a local **`static`** variable that holds the name of the current function:

##### **`macro_trace.h`**

```
79   /**
80    ** @brief Adds the name of the current function to the trace 
81    **/ 
82   #define TRACE_PRINT4(F, X)                      \
83   do {                                            \
84     if (TRACE_ON)                                 \
85      fprintf(stderr, "%s:%lu: " F "\n",          \
86              __func__, __LINE__+0UL, X);          \
87   } while (false)
```

If the following invocation

##### **`macro_trace.c`**

```
24      TRACE_PRINT4("my favorite variable: %g", sum);
```

is at line 24 of the source file and **main** is its surrounding function, the corresponding output looks similar to this:

##### `Terminal`

```
0      main:24: my favorite variable: 889
```

Another pitfall that we should have in mind if we are using **fprintf** automatically as in this example is that *all* arguments in its list must have the correct type as given in the specifier. For **`__func__`**, this is no problem: by its definition we know that this is a **`char`** array, so the "%s" specifier is fine. **`__LINE__`** is different. We know that it is a decimal constant representing the line number. So if we revisit the rules for the types of decimal constants in [section 5.3](/book/modern-c/chapter-5/ch05lev1sec3), we see that the type depends on the value. On embedded platforms, **`INT_MAX`** might be as small as 32767, and very large sources (perhaps automatically produced) may have more lines than that. A good compiler should warn us when such a situation arises.

##### Takeaway 16.5

*The line number in* **`__LINE__`** *may not fit into an* **`int`***.*

##### Takeaway 16.6

*Using* **`__LINE__`** *is inherently dangerous.*

In our macros, we avoid the problem by either fixing the type to **`unsigned long`**[[2](/book/modern-c/chapter-16/ch16fn02)] or by transforming the number to a string during compilation.

2 Hoping that no source will have more than 4 billion lines.

There is another type of information from the calling context that is often quite helpful for traces: the actual expressions that we passed to the macro as arguments. As this is often used for debugging purposes, C has a special operator for it: **`#`**. If such a **`#`** appears before a macro parameter in the expansion, the actual argument to this parameter is *stringified*: that is, all its textual content is placed into a string literal. The following variant of our trace macro has a **`#`**`X`

##### **`macro_trace.h`**

```
91   /**
92    ** @brief Adds a textual version of the expression that is evaluated 
93    **/ 
94   #define TRACE_PRINT5(F, X)                                      \
95   do {                                                            \
96    if (TRACE_ON)                                                  \
97     fprintf(stderr, "%s:" STRGY(__LINE__) ":(" #X "): " F "\n",   \
98             __func__, X);                                         \
99   } while (false)
```

that is replaced by the text of the second argument at each call of the macro. For the following invocations

##### **`macro_trace.c`**

```
25     TRACE_PRINT5("my favorite variable: %g", sum);
26     TRACE_PRINT5("a good expression: %g", sum*argc);
```

the corresponding output looks similar to

##### `Terminal`

```
0     main:25:(sum): my favorite variable: 889
1     main:26:(sum*argc): a good expression: 1778
```

Because the preprocessing phase knows nothing about the interpretation of these arguments, this replacement is purely textual and should appear as in the source, with some possible adjustments for whitespace.

##### Takeaway 16.7

*Stringification with the operator* **`#`** *does not expand macros in its argument.*

In view of the potential problems with **`__LINE__`** mentioned earlier, we also would like to convert the line number directly into a string. This has a double advantage: it avoids the type problem, and stringification is done entirely at compile time. As we said, the **`#`** operator only applies to macro arguments, so a simple use like **`#`** **`__LINE__`** does not have the desired effect. Now consider the following macro definition:

##### **`macro_trace.h`**

```
89   #define STRINGIFY(X) #X
```

Stringification kicks in before argument replacement, and the result of STRINGIFY`(`**`__LINE__`**`)` is "__LINE__"; the macro **`__LINE__`** is not expanded. So this macro still is not sufficient for our needs.

Now, STRGY`(`**`__LINE__`**`)` first expands to STRINGIFY`(25)` (if we are on line 25). This then expands to "25", the stringified line number:

##### **`macro_trace.h`**

```
90   #define STRGY(X) STRINGIFY(X)
```

For completeness, we will also mention another operator that is only valid in the preprocessing phase: the *`##`* operator. It is for even more specialized use: it is a *token concatenation operator*. It can be useful when writing entire macro libraries where we have to generate names for types or functions automatically.

## 16.4. Default arguments

Some functions of the C library have parameters that receive the same boring arguments most of the time. This is the case for **strtoul** and relatives. Remember that these receive three arguments:

```
1   unsigned long int strtoul(char const nptr[restrict],
2                             char** restrict endptr,
3                             int base);
```

The first is the string that we want to convert into an **`unsigned long`**. endptr will point to the end of the number in the string, and base is the integer base for which the string is interpreted. Two special conventions apply: if endptr may be a null pointer and if base is `0`, the string is interpreted as hexadecimal (leading "0x"), octal (leading "0"), or decimal otherwise.

Most of the time, **strtoul** is used without the endptr feature and with the symbolic base set to `0`, for example in something like

```
1   int main(int argc, char* argv[argc+1]) {
2     if (argc < 2) return EXIT_FAILURE;
3     size_t len = strtoul(argv[1], 0, 0);
4     ...
5   }
```

to convert the first command-line argument of a program to a length value. To avoid this repetition and to have the reader of the code concentrate on the important things, we can introduce an intermediate level of macros that provide these `0` arguments if they are omitted:

##### **`generic.h`**

```
114
115   /**
116    ** @brief Calls a three-parameter function with default arguments 
117    ** set to 0 
118    **/ 
119   #define ZERO_DEFAULT3(...) ZERO_DEFAULT3_0(__VA_ARGS__, 0, 0, )
120   #define ZERO_DEFAULT3_0(FUNC, _0, _1, _2, ...) FUNC(_0, _1, _2)
121
122   #define strtoul(...) ZERO_DEFAULT3(strtoul, __VA_ARGS__)
123   #define strtoull(...) ZERO_DEFAULT3(strtoull, __VA_ARGS__)
124   #define strtol(...) ZERO_DEFAULT3(strtol, __VA_ARGS__)
```

Here, the macro ZERO_DEFAULT3 works by subsequent addition and removal of arguments. It is supposed to receive a function name and at least one argument that is to be passed to that function. First, two zeros are appended to the argument list; then, if this results in more than three combined arguments, the excess is omitted. So for a call with just one argument, the sequence of replacements looks as follows:

```
strtoul(argv[1])
//      ...
ZERO_DEFAULT3(strtoul, argv[1])
//            ... 
ZERO_DEFAULT3_0(strtoul, argv[1], 0, 0, )
//              FUNC   , _0     ,_1,_2,... 
strtoul(argv[1], 0, 0)
```

Because of the special rule that inhibits recursion in macro expansion, the final function call to **strtoul** will not be expanded further and is passed on to the next compilation phases.

If instead we call **strtoul** with three arguments

```
strtoul(argv[1], ptr, 10)
//      ...
ZERO_DEFAULT3(strtoul, argv[1], ptr, 10)
//            ...
ZERO_DEFAULT3_0(strtoul, argv[1], ptr, 10, 0, 0, )
//              FUNC   , _0     , _1 , _2, ... 
strtoul(argv[1], ptr, 10)
```

the sequence of replacements effectively results in exactly the same tokens with which we started.

## 16.5. Variable-length argument lists

We have looked at functions that accept argument lists of variable length: **printf**, **scanf**, and friends. Their declarations have the token `...` at the end of the parameter list to indicate that feature: after an initial number of known arguments (such as the format for **printf**), a list of arbitrary length of additional arguments can be provided. Later, in [section 16.5.2](/book/modern-c/chapter-16/ch16lev2sec2), we will briefly discuss how such functions can be defined. Because it is not type safe, this feature is dangerous and almost obsolete, so we will not insist on it. Alternatively, we will present a similar feature, *variadic macros*, that can mostly be used to replace the feature for functions.

### 16.5.1. Variadic macros

Variable-length argument macros, *variadic macros* for short, use the same token *`...`* to indicate the feature. As with functions, this token must appear at the end of the parameter list:

##### **`macro_trace.h`**

```
101   /**
102    ** @brief Allows multiple arguments to be printed in the 
103    ** same trace 
104    **/ 
105   #define TRACE_PRINT6(F, ...)                            \
106   do {                                                    \
107     if (TRACE_ON)                                        \
108       fprintf(stderr, "%s:" STRGY(__LINE__) ": " F "\n",  \
109               __func__, __VA_ARGS__);                     \
110   } while (false)
```

Here, in TRACE_PRINT6, this indicates that after the format argument F, any non-empty list of additional arguments may be provided in a call. This list of expanded arguments is accessible in the expansion through the identifier **`__VA_ARGS__`**. Thus a call such as

##### **`macro_trace.c`**

```
27     TRACE_PRINT6("a collection: %g, %i", sum, argc);
```

just passes the arguments through to **fprintf** and results in the output

##### `Terminal`

```
0   main:27: a collection: 889, 2
```

Unfortunately, as it is written, the list in **`__VA_ARGS__`** cannot be empty or absent. So for what we have seen so far, we’d have to write a separate macro for the case where the list is absent:

##### `macro_trace.h`

```
113    ** @brief Only traces with a text message; no values printed 
114    **/
115   #define TRACE_PRINT7(...)                                     \
116   do {                                                          \
117    if (TRACE_ON)                                                \
118     fprintf(stderr, "%s:" STRGY(__LINE__) ": " __VA_ARGS__ "\n",\
119             __func__);                                          \
120   } while (false)
```

But with more effort, these two functionalities can be united into a single macro:

##### `macro_trace.h`

```
138    ** @brief Traces with or without values 
139    **
140    ** This implementation has the particularity of adding a format 
141    ** @c "%.0d" to skip the last element of the list, which was 
142    ** artificially added. 
143    **/
144   #define TRACE_PRINT8(...)                        \
145   TRACE_PRINT6(TRACE_FIRST(__VA_ARGS__) "%.0d",    \
146                TRACE_LAST(__VA_ARGS__))
```

Here, TRACE_FIRST and TRACE_LAST are macros that give access to the first and remaining arguments in the list, respectively. Both are relatively simple. They use auxiliary macros that enable us to distinguish a first parameter _0 from the remainder **`__VA_ARGS__`**. Since we want to be able to call both with one or more arguments, they add a new argument `0` to the list. For TRACE_FIRST, this goes well. This additional `0` is just ignored as are the rest of the arguments:

##### **`macro_trace.h`**

```
122   /**
123    ** @brief Extracts the first argument from a list of arguments 
124    **/ 
125   #define TRACE_FIRST(...) TRACE_FIRST0(__VA_ARGS__, 0)
126   #define TRACE_FIRST0(_0, ...) _0
```

For TRACE_LAST, this is a bit more problematic, since it extends the list in which we are interested by an additional value:

##### **`macro_trace.h`**

```
128   /**
129    ** @brief Removes the first argument from a list of arguments 
130    **
131    ** @remark This is only suitable in our context, 
132    ** since this adds an artificial last argument. 
133    **/ 
134   #define TRACE_LAST(...) TRACE_LAST0(__VA_ARGS__, 0)
135   #define TRACE_LAST0(_0, ...) __VA_ARGS__
```

Therefore, TRACE_PRINT6 compensates for this with an additional format specifier, "%.0d", that prints an **`int`** of width `0`: that is, nothing. Testing it for the two different use cases

##### **`macro_trace.c`**

```
29     TRACE_PRINT8("a collection: %g, %i", sum, argc);
30     TRACE_PRINT8("another string");
```

gives us exactly what we want:

##### `Terminal`

```
0   main:29: a collection: 889, 2
1   main:30: another string
```

The **`__VA_ARGS__`** part of the argument list also can be stringified just like any other macro parameter:

##### **`macro_trace.h`**

```
148   /**
149    ** @brief Traces by first giving a textual representation of the 
150    ** arguments 
151    **/ 
152   #define TRACE_PRINT9(F, ...)                            \
153   TRACE_PRINT6("(" #__VA_ARGS__ ") " F, __VA_ARGS__)
```

The textual representation of the arguments

##### **`macro_trace.c`**

```
31     TRACE_PRINT9("a collection: %g, %i", sum*acos(0), argc);
```

is inserted, including the commas that separate them:

##### `Terminal`

```
0      main:31: (sum*acos(0), argc) a collection: 1396.44, 2
```

So far, our variants of the trace macro that have a variable number of arguments must also receive the correct format specifiers in the format argument F. This can be a tedious exercise, since it forces us to always keep track of the type of each argument in the list that is to be printed. A combination of an **`inline`** function and a macro can help us here. First let us look at the function:

##### **`macro_trace.h`**

```
166   /**
167    ** @brief A function to print a list of values 
168    **
169    ** @remark Only call this through the macro ::TRACE_VALUES, 
170    ** which will provide the necessary contextual information. 
171    **/ 
172   inline
173   void trace_values(FILE* s,
174                     char const func[static 1],
175                     char const line[static 1],
176                     char const expr[static 1],
177                     char const head[static 1],
178                     size_t len, long double const arr[len]) {
179     fprintf(s, "%s:%s:(%s) %s %Lg", func, line,
180             trace_skip(expr), head, arr[0]);
181     for (size_t i = 1; i < len-1; ++i)
182       fprintf(s, ", %Lg", arr[i]);
183     fputc('\n', s);
184   }
```

It prints a list of **`long double`** values after preceding them with the same header information, as we have done before. Only this time, the function receives the list of values through an array of **`long double`** s of known length len. For reasons that we will see shortly, the function actually always skips the last element of the array. Using a function trace_skip, it also skips an initial part of the parameter expr.

The macro that passes the contextual information to the function comes in two levels. The first is just massaging the argument list in different ways:

##### **`macro_trace.h`**

```
204   /**
205    ** @brief Traces a list of arguments without having to specify 
206    ** the type of each argument 
207    **
208    ** @remark This constructs a temporary array with the arguments 
209    ** all converted to @c long double. Thereby implicit conversion 
210    ** to that type is always guaranteed. 
211    **/ 
212   #define TRACE_VALUES(...)                       \
213   TRACE_VALUES0(ALEN(__VA_ARGS__),                \
214                 #__VA_ARGS__,                     \
215                 __VA_ARGS__,                      \
216                 0                                 \
217                 )
```

First, with the help of ALEN, which we will see in a moment, it evaluates the number of elements in the list. Then it stringifies the list and finally appends the list itself plus an additional `0`. All this is fed into TRACE_VALUES0:

##### **`macro_trace.h`**

```
219   #define TRACE_VALUES0(NARGS, EXPR, HEAD, ...)                    \
220   do {                                                             \
221     if (TRACE_ON) {                                                \
222       if (NARGS > 1)                                               \
223         trace_values(stderr, __func__, STRGY(__LINE__),            \
224                      "" EXPR "", "" HEAD "", NARGS,               \
225                      (long double const[NARGS]){ __VA_ARGS__ });   \
226       else                                                         \
227         fprintf(stderr, "%s:" STRGY(__LINE__) ": %s\n",           \
228                 __func__, HEAD);                                   \
229     }                                                              \
```

Here, the list without HEAD is used as an initializer of a compound literal of type **`long double const`**`[`NARG`]`. The `0` that we added earlier ensures that the initializer is never empty. With the information on the length of the argument list, we are also able to make a case distinction, if the only argument is just the format string.

We also need to show ALEN:

##### **`macro_trace.h`**

```
186   /**
187    ** @brief Returns the number of arguments in the ... list 
188    **
189    ** This version works for lists with up to 31 elements. 
190    **
191    ** @remark An empty argument list is taken as one (empty) argument. 
192    **/ 
193   #define ALEN(...) ALEN0(__VA_ARGS__,                    \
194     0x1E, 0x1F, 0x1D, 0x1C, 0x1B, 0x1A, 0x19, 0x18,       \
195     0x17, 0x16, 0x15, 0x14, 0x13, 0x12, 0x11, 0x10,       \
196     0x0E, 0x0F, 0x0D, 0x0C, 0x0B, 0x0A, 0x09, 0x08,       \
197     0x07, 0x06, 0x05, 0x04, 0x03, 0x02, 0x01, 0x00)
198
199   #define ALEN0(_00, _01, _02, _03, _04, _05, _06, _07,           \
200                 _08, _09, _0A, _0B, _0C, _0D, _0F, _0E,           \
201                 _10, _11, _12, _13, _14, _15, _16, _17,           \
202                 _18, _19, _1A, _1B, _1C, _1D, _1F, _1E, ...) _1E
```

The idea is to take the **`__VA_ARGS__`** list and append a list of decreasing numbers `31`, `30`, . . . , `0`. Then, by using ALEN0, we return the 31st element of that new list. Depending on the length of the original list, this element will be one of the numbers. In fact, it is easy to see that the returned number is exactly the length of the original list, provided it contains at least one element. In our use case, there is always at least the format string, so the border case of an empty list cannot occur.

### 16.5.2. A detour: variadic functions

Let us now have a brief look at *variadic functions*: functions with variable-length argument lists. As already mentioned, these are specified by using the *`...`* operator in the function declaration, such as in

```
int printf(char const format[static 1], ...);
```

Such functions have a fundamental problem in their interface definition. Unlike normal functions, at the call side it is not clear to which parameter type an argument should be converted. For example, if we call **printf**`(`"%d"`, 0)`, it is not immediately clear to the compiler what kind of `0` the called function is expecting. For such cases, C has a set of rules to determine the type to which an argument is converted. These are almost identical to the rules for arithmetic:

##### Takeaway 16.8

*When passed to a variadic parameter, all arithmetic types are converted as for arithmetic operations, with the exception of* **`float`** *arguments, which are converted to* **`double`***.*

So in particular when they are passed to a variadic parameter, types such as **`char`** and **`short`** are converted to a wider type, usually **`int`**.

So far, so good: now we know how such functions get called. But unfortunately, these rules tell us nothing about the type that the called function should expect to receive.

##### Takeaway 16.9

*A variadic function has to receive valid information about the type of each argument in the variadic list.*

The **printf** functions get away with this difficulty by imposing a specification for the types inside the format argument. Let us look at the following short code snippet:

```
1   unsigned char zChar = 0;
2   printf("%hhu", zChar);
```

This has the effect that zChar is evaluated, promoted to **`int`**, and passed as an argument to **printf**, which then reads this **`int`** and re-interprets the value as **`unsigned char`**. This mechanism is

- *Complicated:* because the implementation of the function must provide specialized code for all the basic types
- *Error-prone:* because each call depends on the fact that the argument types are correctly transmitted to the function
- *Exigent:* because the programmer has to check the type of each argument

In particular, the latter can cause serious portability bugs, because constants can have different types from platform to platform. For example, the innocent call

```
printf("%d: %s\n", 65536, "a small number"); // Not portable
```

will work well on most platforms: those that have an **`int`** type with more than 16 bits. But on some platforms, it may fail at runtime because `65536` is **`long`**. The worst example for such a potential failure is the macro **`NULL`**:

```
printf("%p: %s\n", NULL, "print of NULL"); // Not portable
```

As we saw in [section 11.1.5](/book/modern-c/chapter-11/ch11lev2sec5), **`NULL`** is only guaranteed to be a null pointer constant. Compiler implementors are free to choose which variant they provide: some choose `(`**`void`**`*)0`, with a type of **`void`**`*`; most choose `0`, with a type of **`int`**. On platforms that have different widths for pointers and **`int`**, such as all modern 64-bit platforms, the result is a program crash.[[3](/book/modern-c/chapter-16/ch16fn03)]

3 That is one of the reasons we should not use **`NULL`** at all ([takeaway 11.14](/book/modern-c/chapter-11/ch11note14)).

##### Takeaway 16.10

*Using variadic functions is not portable unless each argument is forced to a specific type.*

This is quite different from the use of variadic macros as we saw in the example of TRACE_VALUES. There we used the variadic list as an initializer to an array, so all elements were automatically converted to the correct target type.

##### Takeaway 16.11

*Avoid variadic functions for new interfaces.*

They are just not worth the pain. But if you have to implement a variadic function, you need the C library header `stdarg.h`. It defines one type, **`va_list`**, and four function-like macros that can be used as the different arguments behind a **`va_list`**. Their pseudo interfaces look like this:

<stdarg.h>```
1   void va_start(va_list ap, parmN);
2   void va_end(va_list ap);
3   type va_arg(va_list ap, type);
4   void va_copy(va_list dest, va_list src);
```

The first example shows how to actually avoid programming the core part of a variadic function. For anything that concerns formatted printing, there are existing functions we should use:

##### **`va_arg.c`**

```
20   FILE* iodebug = 0;
21
22   /**
23    ** @brief Prints to the debug stream @c iodebug
24    **/
25   #ifdef __GNUC__
26   __attribute__((format(printf, 1, 2)))
27   #endif
28   int printf_debug(const char *format, ...) {
29     int ret = 0;
30     if (iodebug) {
31       va_list va;
32       va_start(va, format);
33       ret = vfprintf(iodebug, format, va);
34       va_end(va);
35     }
36     return ret;
37   }
```

The only thing we do with **va_start** and **va_end** is to create a **`va_list`** argument list and pass this information on to the C library function **vfprintf**. This completely spares us from doing the case analysis and tracking the arguments. The conditional __attribute__ is compiler specific (here, for `GCC` and friends). Such an add-on may be very helpful in situations where a known parameter convention is applied and where the compiler can do some good diagnostics to ensure the validity of the arguments.

Now we will look at a variadic function that receives n **`double`** values and that sums them up:[[[Exs 4]](/book/modern-c/chapter-16/ch16fn-ex04)]

[Exs 4] Variadic functions that only receive arguments that are all the same type can be replaced by a variadic macro and an **`inline`** function that takes an array. Do it. 

##### **`va_arg.c`**

```
6   /**
7    ** @brief A small, useless function to show how variadic
8    ** functions work
9    **/
10   double sumIt(size_t n, ...) {
11     double ret = 0.0;
12     va_list va;
13     va_start(va, n);
14     for (size_t i = 0; i < n; ++i)
15       ret += va_arg(va, double);
16     va_end(va);
17     return ret;
18   }
```

The **`va_list`** is initialized by using the last argument before the list. Observe that by some magic, **va_start** receives va as such and not with an address operator `&`. Then, inside the loop, every value in the list is received through the use of the **va_arg** macro, which needs an explicit specification (here, **`double`**) of its *type* argument. Also, we have to maintain the length of the list ourselves, here by passing the length as an argument to the function. The encoding of the argument type (here, implicit) and the detection of the end of the list are left up to the programmer of the function.

##### Takeaway 16.12

*The* **va_arg** *mechanism doesn’t give access to the length of the* **`va_list`***.*

##### Takeaway 16.13

*A variadic function needs a specific convention for the length of the list.*

## 16.6. Type-generic programming

One of the genuine additions of C11 to the C language has been direct language support for type-generic programming. C99 had `tgmath.h` (see [section 8.2](/book/modern-c/chapter-8/ch08lev1sec2)) for type-generic mathematical functions, but it didn’t offer much to program such interfaces yourself. The specific add-on is the keyword **`_Generic`**, which introduces a primary expression of the following form:

<tgmath.h>```
1   _Generic(controlling expression,
2     type1: expression1,
3     ... ,
4     typeN: expressionN)
```

This is very similar to a **`switch`** statement. But the *controlling expression* is only taken for its type (but see shortly), and the result is one of the expressions *expression1* . . . *expressionN* chosen by the corresponding type-specific *type1* . . . *typeN*, of which one may be simply the keyword **`default`**.

One of the simplest use cases, and primarily what the C committee had in mind, is to use **`_Generic`** for a type-generic macro interface by providing a choice between function pointers. A basic example for this is the the `tgmath.h` interfaces, such as **`fabs`**. **`_Generic`** is not a macro feature itself but can conveniently be used in a macro expansion. By ignoring complex floating-point types, such a macro for **`fabs`** could look like this:

```
1   #define fabs(X)        \
2   _Generic((X),          \
3     float: fabsf,        \
4     long double: fabsl,  \
5     default: fabs)(X)
```

This macro distinguishes two specific types, **`float`** and **`long double`**, which choose the corresponding functions **fabsf** and **fabsl**, respectively. If the argument X is of any other type, it is mapped to the **`default`** case of **`fabs`**. That is, other arithmetic types such as **`double`** and integer types are mapped to **`fabs`**.[[[Exs 5]](/book/modern-c/chapter-16/ch16fn-ex05)][[[Exs 6]](/book/modern-c/chapter-16/ch16fn-ex06)]

[Exs 5] Find the two reasons why this occurrence of **`fabs`** in the macro expansion is not itself expanded.

[Exs 6] Extend the **`fabs`** macro to cover complex floating-point types.

Now, once the resulting function pointer is determined, it is applied to the argument list `(`X`)` that follows the **`_Generic`** primary expression.

Here comes a more complete example:

##### **`generic.h`**

```
7   inline
 8   double min(double a, double b) {
 9     return a < b ? a : b;
10   }
11
12   inline
13   long double minl(long double a, long double b) {
14     return a < b ? a : b;
15   }
16
17   inline
18   float minf(float a, float b) {
19     return a < b ? a : b;
20   }
21
22   /**
23    ** @brief Type-generic minimum for floating-point values 
24    **/ 
25   #define min(A, B)                               \
26   _Generic((A)+(B),                               \
27            float: minf,                           \
28            long double: minl,                     \
29            default: min)((A), (B))
```

It implements a type-generic interface for the minimum of two real values. Three different **`inline`** functions for the three floating-point types are defined and then used in a similar way as for **`fabs`**. The difference is that these functions need two arguments, not only one, so the **`_Generic`** expression must decide on a combination of the two types. This in done by using the sum of the two arguments as a *controlling expression*. As a consequence, argument promotions and conversion are effected to the arguments of that plus operation, and so the **`_Generic`** expression chooses the function for the wider of the two types, or **`double`** if both arguments are integers.

The difference from just having one function for **`long double`**, say, is that the information about the type of the concrete arguments is not lost.

##### Takeaway 16.14

*The result type of a* **`_Generic`** *expression is the type of the chosen expression.*

This is in contrast to what is happening, for example, for the ternary operator `a`?`b`:c. Here, the return type is computed by combining the two types b and c. For the ternary operator, this must be done like that because a may be different from run to run, so either b or c may be selected. Since **`_Generic`** makes its choice based upon the type, this choice is fixed at compile time. So, the compiler can know the resulting type of the choice in advance.

In our example, we can be sure that all generated code that uses our interface will never use wider types than the programmer has foreseen. In particular, our min macro should always result in the compiler inlining the appropriate code for the types in question.[[[Exs 7]](/book/modern-c/chapter-16/ch16fn-ex07)][[[Exs 8]](/book/modern-c/chapter-16/ch16fn-ex08)]

[Exs 7] Extend the min macro to cover all wide integer types.

[Exs 8] Extend min to cover pointer types, as well.

##### Takeaway 16.15

*Using* **`_Generic`** *with* **`inline`** *functions adds optimization opportunities.*

The interpretation of what it means to talk about the *type of the controlling expression* is a bit ambiguous, so C17 clarifies this in comparison to C11. In fact, as the previous examples imply, this type is the type of the expression *as if* it were passed to a function. This means in particular:

- If there are any, type qualifiers are dropped from the type of the controlling expression.
- An array type is converted to a pointer type to the base type.
- A function type is converted to a pointer to a function.

##### Takeaway 16.16

*The type expressions in a* **`_Generic`** *expression should only be unqualified types: no array types, and no function types.*

That doesn’t mean the type expressions can’t be pointers to one of those: a pointer to a qualified type, a pointer to an array, or a pointer to a function. But generally, this rules makes the task of writing a type-generic macro easier, since we do not have to take all combinations of qualifiers into account. There are 3 qualifiers (4 for pointer types), so otherwise all different combinations would lead to 8 (or even 16) different type expressions per base type. The following example MAXVAL is already relatively long: it has a special case for all 15 orderable types. If we also had to track qualifications, we would have to specialize 120 cases!

##### `generic.h`

```
31   /**
32    ** @brief The maximum value for the type of @a X 
33    **/ 
34   #define MAXVAL(X)                                        \
35   _Generic((X),                                            \
36            bool: (bool)+1,                                 \
37            char: (char)+CHAR_MAX,                          \
38            signed char: (signed char)+SCHAR_MAX,           \
39            unsigned char: (unsigned char)+UCHAR_MAX,       \
40            signed short: (signed short)+SHRT_MAX,          \
41            unsigned short: (unsigned short)+USHRT_MAX,     \
42            signed: INT_MAX,                                \
43            unsigned: UINT_MAX,                             \
44            signed long: LONG_MAX,                          \
45            unsigned long: ULONG_MAX,                       \
46            signed long long: LLONG_MAX,                    \
47            unsigned long long: ULLONG_MAX,                 \
48            float: FLT_MAX,                                 \
49            double: DBL_MAX,                                \
50            long double: LDBL_MAX)
```

This is an example where a **`_Generic`** expression is used differently than earlier, where we “just” chose a function pointer and then called the function. Here the resulting value is an integer constant expression. This never could be realized by function calls, and it would be very tedious to implement just with macros.[[[Exs 9]](/book/modern-c/chapter-16/ch16fn-ex09)] Again, with a conversion trick, we can get rid of some cases we might not be interested in:

[Exs 9] Write an analogous macro for the minimum value.

##### **`generic.h`**

```
52   /**
53    ** @brief The maximum promoted value for @a XT, where XT 
54    ** can be an expression or a type name 
55    **
56    ** So this is the maximum value when fed to an arithmetic 
57    ** operation such as @c +. 
58    **
59    ** @remark Narrow types are promoted, usually to @c signed, 
60    ** or maybe to @c unsigned on rare architectures. 
61    **/ 
62   #define maxof(XT)                               \
63   _Generic(0+(XT)+0,                              \
64            signed: INT_MAX,                       \
65            unsigned: UINT_MAX,                    \
66            signed long: LONG_MAX,                 \
67            unsigned long: ULONG_MAX,              \
68            signed long long: LLONG_MAX,           \
69            unsigned long long: ULLONG_MAX,        \
70            float: FLT_MAX,                        \
71            double: DBL_MAX,                       \
72            long double: LDBL_MAX)
```

Here, the special form of the controlling expression adds an additional feature. The expression `0+`(identifier`)+0` is valid if identifier is a variable or if it is a type. If it is a variable, the type of the variable is used, and it is interpreted just like any other expression. Then integer promotion is applied to it, and the resulting type is deduced.

If it is a type, (identifier`)+0` is read as a cast of `+0` to type identifier. Adding `0+` from the left then still ensures that integer promotion is performed if necessary, so the result is the same if XT is a type T or an expression X of type T.[[[Exs 10]](/book/modern-c/chapter-16/ch16fn-ex10)][[[Exs 11]](/book/modern-c/chapter-16/ch16fn-ex11)][[[Exs 12]](/book/modern-c/chapter-16/ch16fn-ex12)]

[Exs 10] Write a macro PROMOTE`(`XT`,` A`)` that returns the value of A as type XT. For example, PROMOTE`(1`u`, 3)` would be `3`u.

[Exs 11] Write a macro SIGNEDNESS`(`XT`)` that returns **`false`** or **`true`** according to the signedness of the type of XT. For example, SIGNEDNESS`(1`l`)` would be **`true`**.

[Exs 12] Write a macro mix`(`A`,` B`)` that computes the maximum value of A and B. If both have the same signedness, the result type should be the wider type of the two. If both have different signedness, the return type should be an unsigned type that fits all positive values of both types.

Another requirement for the type expressions in a **`_Generic`** expression is that the choice must be unambiguous at compile time.

##### Takeaway 16.17

*The type expressions in a* **`_Generic`** *expression must refer to mutually incompatible types.*

##### Takeaway 16.18

*The type expressions in a* **`_Generic`** *expression cannot be a pointer to a VLA.*

A different model than the *function-pointer-call* variant can be convenient, but it also has some pitfalls. Let us try to use **`_Generic`** to implement the two macros TRACE_FORMAT and TRACE_CONVERT, which are used in the following:

##### **`macro_trace.h`**

```
278   /**
279    ** @brief Traces a value without having to specify a format 
280    **
281    ** This variant works correctly with pointers. 
282    **
283    ** The formats are tunable by changing the specifiers in 
284    ** ::TRACE_FORMAT. 
285    **/
286   #define TRACE_VALUE1(F, X)                                          \
287     do {                                                              \
288       if (TRACE_ON)                                                   \
289         fprintf(stderr,                                               \
290                 TRACE_FORMAT("%s:" STRGY(__LINE__) ": " F, X),       \
291                 __func__, TRACE_CONVERT(X));                          \
292     } while (false)
```

TRACE_FORMAT is straightforward. We distinguish six different cases:

##### **`macro_trace.h`**

```
232   /**
233    ** @brief Returns a format that is suitable for @c fprintf 
234    **
235    ** @return The argument @a F must be a string literal, 
236    ** so the return value will be. 
237    **
238    **/ 
239   #define TRACE_FORMAT(F, X)                      \
240   _Generic((X)+0LL,                               \
241            unsigned long long: "" F " %llu\n",    \
242            long long: "" F " %lld\n",             \
243            float: "" F " %.8f\n",                 \
244            double: "" F " %.12f\n",               \
245            long double: "" F " %.20Lf\n",         \
246            default: "" F " %p\n")
```

The **`default`** case, when no arithmetic type is matched, supposes that the argument has a pointer type. In that case, to be a correct parameter for **fprintf**, the pointer must be converted to **`void`**`*`. Our goal is to implement such a conversion through TRACE_CONVERT.

A first try could look like the following:

```
1   #define TRACE_CONVERT_WRONG(X)             \
2   _Generic((X)+0LL,                          \
3            unsigned long long: (X)+0LL,      \
4            ...                            \
5            default: ((void*){ 0 } = (X)))
```

This uses the same trick as for TRACE_PTR1 to convert the pointer to **`void`**`*`. Unfortunately, this implementation is wrong.

##### Takeaway 16.19

*All choices* expression1 *...* expressionN *in a* **`_Generic`** *must be valid.*

If, for example, X is an **`unsigned long long`**, say 1LL, the **`default`** case would read

```
((void*){ 0 } = (1LL))
```

which would be assigning a non-zero integer to a pointer, which is erroneous.[[4](/book/modern-c/chapter-16/ch16fn04)]

4 Remember that conversion from non-zero integers to pointers must be made explicit through a cast.

We tackle this in two steps. First we have a macro that returns either its argument, the **`default`**, or a literal zero:

##### **`macro_trace.h`**

```
248   /**
249    ** @brief Returns a value that forcibly can be interpreted as 
250    ** pointer value 
251    **
252    ** That is, any pointer will be returned as such, but other 
253    ** arithmetic values will result in a @c 0. 
254    **/
255   #define TRACE_POINTER(X)                  \
256   _Generic((X)+0LL,                         \
257            unsigned long long: 0,           \
258            long long: 0,                    \
259            float: 0,                        \
260            double: 0,                       \
261            long double: 0,                  \
262            default: (X))
```

This has the advantage that a call to TRACE_POINTER`(`X`)` can always be assigned to a **`void`**`*`. Either X itself is a pointer, and so is assignable to **`void*`**, or it is of another arithmetic type, and the result of the macro invocation is `0`. Put all together, TRACE_CONVERT looks as follows:

##### **`macro_trace.h`**

```
264   /**
265    ** @brief Returns a value that is promoted either to a wide 
266    ** integer, to a floating point, or to a @c void* if @a X is a 
267    ** pointer 
268    **/ 
269   #define TRACE_CONVERT(X)                                \
270   _Generic((X)+0LL,                                       \
271            unsigned long long: (X)+0LL,                   \
272            long long: (X)+0LL,                            \
273            float: (X)+0LL,                                \
274            double: (X)+0LL,                               \
275            long double: (X)+0LL,                          \
276            default: ((void*){ 0 } = TRACE_POINTER(X)))
```

## Summary

- Function-like macros are more flexible than inline functions.
- They can be used to complement function interfaces with compile-time argument checks and to provide information from the calling environment or default arguments.
- They allow us to implement type-safe features with variable argument lists.
- In combination with **`_Generic`**, they can be used to implement type-generic interfaces.

# Chapter 6. Derived data types

### This chapter covers

- Grouping objects into arrays
- Using pointers as opaque types
- Combining objects into structures
- Giving types new names with **`typedef`**

All other data types in C are derived from the basic types that we know now. There are four strategies for deriving data types. Two of them are called *aggregate data types*, because they combine multiple instances of one or several other data types:

- ***Arrays:*** These combine items that all have the same base type ([section 6.1](/book/modern-c/chapter-6/ch06lev1sec1)).
- ***Structures:*** These combine items that may have different base types ([section 6.3](/book/modern-c/chapter-6/ch06lev1sec3)).

The two other strategies to derive data types are more involved:

- ***Pointers:*** Entities that refer to an object in memory. Pointers are by far the most involved concept, and we will delay a full discussion of them to [chapter 11](/book/modern-c/chapter-11/ch11). Here, in [section 6.2](/book/modern-c/chapter-6/ch06lev1sec2), we will only discuss them as opaque data types, without even mentioning the real purpose they fulfill.
- ***Unions:*** These overlay items of different base types in the same memory location. Unions require a deeper understanding of C’s memory model and are not of much use in a programmer’s everyday life, so they are only introduced later, in [section 12.2](/book/modern-c/chapter-12/ch12lev1sec2).

There is a fifth strategy that introduces new names for types: **`typedef`** ([section 6.4](/book/modern-c/chapter-6/ch06lev1sec4)). Unlike the previous four, this does not create a new type in C’s type system, but only creates a new name for an existing type. In that way, it is similar to the definition of macros with **`#define`**; thus the choice for the keyword for this feature.

## 6.1. Arrays

Arrays allow us to group objects of the same type into an encapsulating object. We will see pointer types later ([chapter 11](/book/modern-c/chapter-11/ch11)), but many people who come to C are confused about arrays and pointers. And this is completely normal: arrays and pointers are closely related in C, and to explain them we face a *chicken and egg* problem: arrays *look like* pointers in many contexts, and pointers refer to array objects. We chose an order of introduction that is perhaps unusual: we will start with arrays and stay with them as long as possible before introducing pointers. This may seem “wrong” to some of you, but remember that everything stated here must be viewed based on the *as-if* Rule ([takeaway 5.8](/book/modern-c/chapter-5/ch05note08)): we will first describe arrays in a way that is consistent with C’s assumptions about the abstract state machine.

##### Takeaway 6.1

*Arrays are not pointers.*

Later, we will see how these two concepts relate, but for the moment it is important to read this chapter without prejudice about arrays; otherwise, you will delay your ascent to a better understanding of C.

### 6.1.1. Array declaration

We have already seen how arrays are declared: by placing something like *`[`**N`]` after* another declaration. For example:

```
double a[4];
   signed b[N];
```

Here, a comprises 4 subobjects of type **`double`** and b comprises N of type **`signed`**. We visualize arrays with diagrams like the following, with a sequence of boxes of their base type:

![](https://drek4537l1klr.cloudfront.net/gustedt/Figures/pg_082_alt.jpg)

The dots *…* here indicate that there may be an unknown number of similar items between the two boxes.

The type that composes an array may itself again be an array, forming a *multidimensional array**C*. The declarations for those become a bit more difficult to read since `[]` binds to the left. The following two declarations declare variables of exactly the same type:

```
double C[M][N];
   double (D[M])[N];
```

Both C and D are M objects of array type **`double`**`[`N`]`. This means we have to read a nested array declaration from inside out to describe its structure:

![](https://drek4537l1klr.cloudfront.net/gustedt/Figures/pg_083_alt.jpg)

We also have seen how array elements are accessed and initialized, again with a pair of `[]`. In the previous example, `a[0]` is an object of **`double`** and can be used wherever we want to use, for example, a simple variable. As we have seen, `C[0]` is itself an array, so `C[0][0]`, which is the same as `(`C`[0])[0]`, is also an object of type **`double`**.

Initializers can use *designated initializers* (also using `[]` notation) to pick the specific position to which an initialization applies. The example code in [listing 5.1](/book/modern-c/chapter-5/ch05ex01) contains such initializers. During development, designated initializers help to make our code robust against small changes in array sizes or positions.

### 6.1.2. Array operations

Arrays are really just objects of a different type than we have seen so far.

##### Takeaway 6.2

*An array in a condition evaluates to* **`true`***.*

The truth of that comes from the *array decay* operation, which we will see later. Another important property is that we can’t evaluate arrays like other objects.

##### Takeaway 6.3

*There are array objects but no array values.*

So arrays can’t be operands for the value operators in [table 4.1](/book/modern-c/chapter-4/ch04table01), and there is no arithmetic declared on arrays (themselves).

##### Takeaway 6.4

*Arrays can’t be compared.*

Arrays also can’t be on the value side of the object operators in [table 4.2](/book/modern-c/chapter-4/ch04table02). Most of the object operators are likewise ruled out from having arrays as object operands, either because they assume arithmetic or because they have a second value operand that would have to be an array, too.

##### Takeaway 6.5

*Arrays can’t be assigned to.*

From [table 4.2](/book/modern-c/chapter-4/ch04table02), we also know that there are only four operators left that work on arrays as object operators. And we know the operator `[]`.[[1](/book/modern-c/chapter-6/ch06fn01)] The *array decay* operation, the address operator `&`, and the **`sizeof`** operator will be introduced later.

1 The real C jargon story about arrays and `[]` is a bit more complicated. Let us apply the **as-if** Rule ([takeaway 5.8](/book/modern-c/chapter-5/ch05note08)) to our explanation. All C programs behave *as if* the `[]` are directly applied to an array object.

### 6.1.3. Array length

There are two categories of arrays: *fixed-length arrays**C* (FLAs) and *variable-length arrays**C* (VLAs). The first are a concept that has been present in C since the beginning; this feature is shared with many other programming languages. The second was introduced in C99 and is relatively unique to C, and it has some restrictions on its usage.

##### Takeaway 6.6

*VLAs can’t have initializers.*

##### Takeaway 6.7

*VLAs can’t be declared outside functions.*

So let’s start at the other end and see which arrays are in fact FLAs, such that they don’t fall under these restrictions.

##### Takeaway 6.8

*The length of an FLA is determined by an integer constant expression (ICE) or by an initializer.*

For the first of these alternatives, the length is known at compile time through an ICE (introduced in [section 5.6.2](/book/modern-c/chapter-5/ch05lev2sec7)). There is no type restriction for the ICE: any integer type will do.

##### Takeaway 6.9

*An array-length specification must be strictly positive.*

Another important special case leads to an FLA: when there is no length specification at all. If the `[]` are left empty, the length of the array is determined from its initializer, if any:

```
double E[] = { [3] = 42.0,  [2] = 37.0, };
   double F[] = { 22.0,  17.0, 1, 0.5, };
```

Here, E and F both are of type **`double`**`[4]`. Since such an initializer’s structure can always be determined at compile time without necessarily knowing the values of the items, the array is still an FLA.

![](https://drek4537l1klr.cloudfront.net/gustedt/Figures/pg_084_alt.jpg)

All other array variable declarations lead to VLAs.

##### Takeaway 6.10

*An array with a length that is not an integer constant expression is a VLA.*

The length of an array can be computed with the **`sizeof`** operator. That operator provides the size of any object,[[2](/book/modern-c/chapter-6/ch06fn02)] so the length of an array can be calculated using simple division.[[3](/book/modern-c/chapter-6/ch06fn03)]

2 Later, we will see what the unit of measure for such sizes is.

3 Note also that the **`sizeof`** operator comes in two different syntactical forms. If applied to an object, as it is here, it does not need parentheses, but they would be needed if we applied it to a type.

##### Takeaway 6.11

*The length of an array* *`A`* *is* *`(`***`sizeof`** *`A)/(`***`sizeof`** *`A[0])`**.*

That is, it is the total size of the array object, divided by the size of any of the array elements.

### 6.1.4. Arrays as parameters

Yet another special case occurs for arrays as parameters to functions. As we saw for the prototype of **printf**, such parameters may have empty `[]`. Since no initializer is possible for such a parameter, the array dimension can’t be determined.

##### Takeaway 6.12

*The innermost dimension of an array parameter to a function is lost.*

##### Takeaway 6.13

*Don’t use the* **`sizeof`** *operator on array parameters to functions.*

Array parameters are even more bizarre, because we cannot produce *array values* ([takeaway 6.3](/book/modern-c/chapter-6/ch06note03)), array parameters cannot be passed by value, and thus array parameters as such would not make much sense.

##### Takeaway 6.14

*Array parameters behave* as if *the array is* *passed by reference**C**.*

Take the example shown in [listing 6.1](/book/modern-c/chapter-6/ch06ex01).

##### Listing 6.1. A function with an array parameter

```
#include <stdio.h>

void swap_double(double a[static 2]) {
  double tmp = a[0];
  a[0] = a[1];
  a[1] = tmp;
}
int main(void) {
  double A[2] = { 1.0, 2.0, };
  swap_double(A);
  printf("A[0] = %g, A[1] = %g\n", A[0], A[1]);
}
```

Here, swap_double`(`A`)` will act directly on array A and not on a copy. Therefore, the program will swap the values of the two elements of A.

##### Linear algebra

Some of the most important problems for which arrays are used stem from linear algebra.

Can you write functions that do vector-to-vector or matrix-to-vector products at this point?

What about Gauß elimination or iterative algorithms for matrix inversion?

### 6.1.5. Strings are special

There is a special kind of array that we have encountered several times and that, in contrast to other arrays, even has literals: *strings**C*.

##### Takeaway 6.15

*A string is a* *`0`**-terminated array of* **`char`***.*

That is, a string like "hello" always has one more element than is visible, which contains the value 0, so here the array has length 6.

Like all arrays, strings can’t be assigned to, but they can be initialized from string literals:

```
char jay0[] = "jay";
   char jay1[] = { "jay" };
   char jay2[] = { 'j', 'a', 'y', 0, };
   char jay3[4] = { 'j', 'a', 'y', };
```

These are all equivalent declarations. Be aware that not all arrays of **`char`** are strings, such as

```
char jay4[3] = { 'j', 'a', 'y', };
char jay5[3] = "jay";
```

These both cut off after the 'y' character and so are not `0`-terminated.

![](https://drek4537l1klr.cloudfront.net/gustedt/Figures/pg_086_alt.jpg)

We briefly saw the base type **`char`** of strings among the integer types. It is a narrow integer type that can be used to encode all characters of the *basic character set**C*. This character set contains all the characters of the Latin alphabet, Arabic digits, and punctuation characters that we use for coding in C. It usually doesn’t contain special characters (for example, *ä*, *á*), and characters from completely different writing systems).

The vast majority of platforms nowadays use American Standard Code for Information Interchange (ASCII) to encode characters in the type **`char`**. We don’t have to know how the particular encoding works as long as we stay in the basic character set: everything is done in C and its standard library, which use this encoding transparently.

<string.h>To deal with **`char`** arrays and strings, there are a bunch of functions in the standard library that come with the header `string.h`. Those that just require an array argument start their names with mem, and those that in addition require that their arguments are strings start with str. [Listing 6.2](/book/modern-c/chapter-6/ch06ex02) uses some of the functions that are described next.

##### Listing 6.2. Using some of the string functions

```
1    #include <string.h>
 2    #include <stdio.h>
 3    int main(int argc, char* argv[argc+1]) {
 4      size_t const len = strlen(argv[0]); // Computes the length 
 5      char name[len+1];                   // Creates a VLA 
 6                                          // Ensures a place for 0 
 7      memcpy(name, argv[0], len);         // Copies the name 
 8      name[len] = 0;                      // Ensures a 0 character 
 9      if (!strcmp(name, argv[0])) {
10       printf("program name \"%s\" successfully copied\n",
11              name);
12     } else {
13       printf("copying %s leads to different string %s\n",
14              argv[0], name);
15     }
16   }
```

Functions that operate on **`char`** arrays are as follows:

- **memcpy**`(`target, source, len) can be used to copy one array to another. These have to be known to be distinct arrays. The number of **`char`** s to be copied must be given as a third argument len.
- **memcmp**`(`s0, s1, len) compares two arrays in lexicographic order. That is, it first scans the initial segments of the two arrays that happen to be equal and then returns the difference between the two first characters that are distinct. If no differing elements are found up to len, `0` is returned.
- **memchr**(s, c, len) searches array s for the appearance of character c.

Next are the string functions:

- **strlen**`(`s`)` returns the length of the string s. This is simply the position of the first `0` character and *not* the length of the array. It is your duty to ensure that s is indeed a string: that it is `0`-terminated.
- **strcpy**`(`target`,` source) works similarly to **memcpy**. It only copies up to the string length of the source, and therefore it doesn’t need a len parameter. Again, source must be `0`-terminated. Also, target must be big enough to hold the copy.
- **strcmp**`(`s0`,` s1`)` compares two arrays in lexicographic order, similarly to **memcmp**, but may not take some language specialties into account. The comparison stops at the first `0` character that is encountered in either s0 or s1. Again, both parameters have to be `0`-terminated.
- **strcoll**`(`s0`,` s1`)` compares two arrays in lexicographic order, respecting language-specific environment settings. We will learn how to properly set this in [section 8.6](/book/modern-c/chapter-8/ch08lev1sec6).
- **strchr**`(`s`,` c`)` is similar to **memchr**, only the string s must be `0`-terminated.
- **strspn**`(`s0`,` s1`)` returns the length of the initial segment in s0 that consists of characters that also appear in s1.
- **strcspn**`(`s0`,` s1`)` returns the length of the initial segment in s0 that consists of characters that do not appear in s1.

##### Takeaway 6.16

*Using a string function with a non-string has undefined behavior.*

In real life, common symptoms for such misuse may be:

- Long times for **strlen** or similar scanning functions because they don’t encounter a `0`-character
- Segmentation violations because such functions try to access elements after the boundary of the array object
- Seemingly random corruption of data because the functions write data in places where they are not supposed to

In other words, be careful, and make sure all your strings really are strings. If you know the length of the character array, but you do not know if it is 0-terminated, **memchr** and pointer arithmetic (see [chapter 11](/book/modern-c/chapter-11/ch11)) can be used as a safe replacement for **strlen**. Analogously, if a character array is not known to be a string, it is better to copy it by using **memcpy**.[[[Exs 1]](/book/modern-c/chapter-6/ch06fn-ex01)]

[Exs 1] Use **memchr** and **memcmp** to implement a bounds-checking version of **strcmp**.

In the discussion so far, I have been hiding an important detail from you: the prototypes of the functions. For the string functions, they can be written as

```
size_t strlen(char const s[static 1]);
char*  strcpy(char target[static 1], char const source[static 1]);
signed strcmp(char const s0[static 1], char const s1[static 1]);
signed strcoll(char const s0[static 1], char const s1[static 1]);
char* strchr(const char s[static 1], int c);
size_t strspn(const char s1[static 1], const char s2[static 1]);
size_t strcspn(const char s1[static 1], const char s2[static 1]);
```

Other than the bizarre return type of **strcpy** and **strchr**, this looks reasonable. The parameter arrays are arrays of unknown length, so the `[`**`static`** `1]`s correspond to arrays of at least one **`char`**. **strlen**, **strspn**, and **strcspn** will return a size, and **strcmp** will return a negative, 0, or positive value according to the sort order of the arguments.

The picture darkens when we look at the declarations of the array functions:

```
void* memcpy(void* target, void const* source, size_t len);
signed memcmp(void const* s0, void const* s1, size_t len);
void* memchr(const void *s, int c, size_t n);
```

You are missing knowledge about entities that are specified as **`void`**`*`. These are *pointers* to objects of unknown type. It is only in [level 2](/book/modern-c/part-2/part02), [chapter 11](/book/modern-c/chapter-11/ch11), that we will see why and how these new concepts of pointers and **`void`** type occur.

##### Adjacency matrix

The adjacency matrix of a graph *G* is a matrix A that holds a value **`true`** or **`false`** in element A`[`i`][`j`]` if there is an arc from node i to node j.

At this point, can you use an adjacency matrix to conduct a breadth-first search in a graph *G*? Can you find connected components? Can you find a spanning tree?

##### Shortest path

Extend the idea of an adjacency matrix of a graph *G* to a distance matrix D that holds the distance when going from point i to point j. Mark the absence of a direct arc with a very large value, such as **`SIZE_MAX`**.

Can you find the shortest path between two nodes x and y given as an input?

## 6.2. Pointers as opaque types

We now have seen the concept of pointers pop up in several places, in particular as a **`void`**`*` argument and return type, and as **`char const`**`*`**`const`** to manipulate references to string literals. Their main property is that they do not directly contain the information that we are interested in: rather, they refer, or *point*, to the data. C’s syntax for pointers always has the peculiar `*`:

```
char const*const p2string = "some text";
```

It can be visualized like this:

![](https://drek4537l1klr.cloudfront.net/gustedt/Figures/pg_089-01.jpg)

Compare this to the earlier array jay0, which itself contains all the characters of the string that we want it to represent:

```
char const jay0 [] = "jay";
```

![](https://drek4537l1klr.cloudfront.net/gustedt/Figures/pg_089-02_alt.jpg)

In this first exploration, we only need to know some simple properties of pointers. The binary representation of a pointer is completely up to the platform and is not our business.

##### Takeaway 6.17

*Pointers are opaque objects.*

This means we will only be able to deal with pointers through the operations that the C language allows for them. As I said, most of these operations will be introduced later; in our first attempt, we will only need initialization, assignment, and evaluation.

One particular property of pointers that distinguishes them from other variables is their state.

##### Takeaway 6.18

*Pointers are valid, null, or indeterminate.*

For example, our variable p2string is always valid, because it points to the string literal "some text", and, because of the second **`const`**, this association can never be changed.

The null state of any pointer type corresponds to our old friend `0`, sometimes known under its pseudonym **`false`**.

##### Takeaway 6.19

*Initialization or assignment with* *`0`* *makes a pointer null.*

Take the following as an example:

```
char const*const p2nothing = 0;
```

We visualize this special situation like this:

![](https://drek4537l1klr.cloudfront.net/gustedt/Figures/pg_090-01.jpg)

Note that this is different from pointing to an empty string:

```
char const*const p2empty = "";
```

![](https://drek4537l1klr.cloudfront.net/gustedt/Figures/pg_090-02.jpg)

Usually, we refer to a pointer in the null state as a *null pointer**C*. Surprisingly, disposing of null pointers is really a feature.

##### Takeaway 6.20

*In logical expressions, pointers evaluate to* **`false`** *if they are null.*

Note that such tests can’t distinguish valid pointers from indeterminate ones. So, the really “bad” state of a pointer is indeterminate, since this state is not observable.

##### Takeaway 6.21

*Indeterminate pointers lead to undefined behavior.*

An example of an indeterminate pointer could look like this:

```
char const*const p2invalid;
```

![](https://drek4537l1klr.cloudfront.net/gustedt/Figures/pg_090-03.jpg)

Because it is uninitialized, its state is indeterminate, and any use of it would do you harm and leave your program in an undefined state ([takeaway 5.55](/book/modern-c/chapter-5/ch05note59)). Thus, if we can’t ensure that a pointer is valid, we *must* at least ensure that it is set to null.

##### Takeaway 6.22

*Always initialize pointers.*

## 6.3. Structures

As we have seen, arrays combine several objects of the same base type into a larger object. This makes perfect sense where we want to combine information for which the notion of a first, second . . . element is acceptable. If it is not, or if we have to combine objects of different type, then *structures*, introduced by the keyword **`struct`** come into play.

As a first example, let us revisit the corvids from [section 5.6.2](/book/modern-c/chapter-5/ch05lev2sec7). There, we used a trick with an enumeration type to keep track of our interpretation of the individual elements of an array name. C structures allow for a more systematic approach by giving names to so-called *members* (or *field*) in an aggregate:

```
struct birdStruct {
  char const* jay;
  char const* magpie;
  char const* raven;
  char const* chough;
};
struct birdStruct const aName = {
  .chough = "Henry",
  .raven = "Lissy",
  .magpie = "Frau",
  .jay = "Joe",
};
```

That is, from line 1 to 6, we have the declaration of a new type, denoted as **`struct`** birdStruct. This structure has four *members**C*, whose declarations look exactly like normal variable declarations. So instead of declaring four elements that are bound together in an array, here we name the different members and declare types for them. Such declaration of a structure type only explains the type; it is not (yet) the declaration of an object of that type and even less a definition for such an object.

Then, starting on line 7, we declare and define a variable (called aName) of the new type. In the initializer and in later usage, the individual members are designated using a notation with a dot (`.`). Instead of bir`d[`raven`]`, as in [section 5.6.1](/book/modern-c/chapter-5/ch05lev2sec6), for the array we use aName`.`raven for the structure:

![](https://drek4537l1klr.cloudfront.net/gustedt/Figures/pg_091_alt.jpg)

Please note that in this example, the individual members again only *refer* to the strings. For example, the member aName`.`magpie refers to an entity "Frau" that is located outside the box and is not considered part of the **`struct`** itself.

Now, for a second example, let us look at a way to organize time stamps. Calendar time is a complicated way of counting, in years, month, days, minutes, and seconds; the different time periods such as months or years can have different lengths, and so on. One possible way to organize such data could be an array:

```
typedef int calArray[9];
```

![](https://drek4537l1klr.cloudfront.net/gustedt/Figures/pg_092_alt.jpg)

The use of this array type would be ambiguous: would we store the year in element `[0]` or `[5]`? To avoid ambiguities, we could again use our trick with an **`enum`**. But the C standard has chosen a different way. In `time.h`, it uses a **`struct`** that looks similar to the following:

<time.h>```
struct tm {
int tm_sec;  // Seconds after the minute      [0, 60]
int tm_min;  // Minutes after the hour        [0, 59]
int tm_hour; // Hours since midnight          [0, 23]
int tm_mday; // Day of the month              [1, 31]
int tm_mon;  // Months since January          [0, 11]
int tm_year; // Years since 1900
int tm_wday; // Days since Sunday             [0, 6]
int tm_yday; // Days since January            [0, 365]
int tm_isdst;// Daylight Saving Time flag
};
```

This **`struct`** has *named members*, such as **`tm_sec`** for the seconds and **`tm_year`** for the year. Encoding a date, such as the date of this writing

##### `Terminal`

```
0        > LC_TIME=C date -u
1      Wed Apr  3 10:00:47 UTC 2019
```

is relatively simple:

##### **`yday.c`**

```
29      struct tm today = {
30        .tm_year = 2019-1900,
31        .tm_mon  = 4-1,
32        .tm_mday = 3,
33        .tm_hour = 10,
34        .tm_min  = 0,
35        .tm_sec  = 47,
36      };
```

This creates a variable of type **`struct`** **`tm`** and initializes its members with the appropriate values. The order or position of the members in the structure usually is not important: using the name of the member preceded with a dot `.` suffices to specify where the corresponding data should go.

![](https://drek4537l1klr.cloudfront.net/gustedt/Figures/pg_093_alt.jpg)

Note that this visualization of today has an extra “box” compared to calArray. Indeed, a proper **`struct`** type creates an additional level of abstraction. This **`struct`** **`tm`** is a proper type in C’s type system.

Accessing the members of the structure is just as simple and has similar *`.`* syntax:

##### **`yday.c`**

```
37      printf("this year is %d, next year will be %d\n",
38             today.tm_year+1900, today.tm_year+1900+1);
```

A reference to a member such as toda`y.`**`tm_year`** can appear in an expression just like any variable of the same base type.

There are three other members in **`struct`** **`tm`** that we didn’t even mention in our initializer list: **`tm_wday`**, **`tm_yday`**, and **`tm_isdst`**. Since we didn’t mention them, they are automatically set to `0`.

##### Takeaway 6.23

*Omitted* **`struct`** *initializers force the corresponding member to* *`0`**.*

This can even go to the extreme that all but one of the members are initialized.

##### Takeaway 6.24

*A* **`struct`** *initializer must initialize at least one member.*

Previously ([takeaway 5.37](/book/modern-c/chapter-5/ch05note38)), we saw that there is a default initializer that works for all data types: `{0}`.

So when we initialize **`struct`** **`tm`** as we did here, the data structure is not consistent; the **`tm_wday`** and **`tm_yday`** members don’t have values that would correspond to the values of the remaining members. A function that sets this member to a value that is consistent with the others could be something like

##### **`yday.c`**

```
19   struct tm time_set_yday(struct tm t) {
20     // tm_mdays starts at 1.
21     t.tm_yday += DAYS_BEFORE[t.tm_mon] + t.tm_mday - 1;
22     // Takes care of leap years
23     if ((t.tm_mon > 1) && leapyear(t.tm_year+1900))
24       ++t.tm_yday;
25     return t;
26   }
```

It uses the number of days of the months preceding the current one, the **`tm_mday`** member, and an eventual corrective for leap years to compute the day in the year. This function has a particularity that is important at our current level: it modifies only the member of the parameter of the function, t, and not of the original object.

##### Takeaway 6.25

**`struct`** *parameters are passed by value.*

To keep track of the changes, we have to reassign the result of the function to the original:

##### **`yday.c`**

```
39      today = time_set_yday(today);
```

Later, with pointer types, we will see how to overcome that restriction for functions, but we are not there yet. Here we see that the assignment operator *`=`* is well defined for all structure types. Unfortunately, its counterparts for comparisons are not.

##### Takeaway 6.26

*Structures can be assigned with* *`=`* *but not compared with* *`==`* *or* *`!=`**.*

[Listing 6.3](/book/modern-c/chapter-6/ch06ex08) shows the complete example code for the use of **`struct`** **`tm`**. It doesn’t contain a declaration of the historical **`struct`** **`tm`** since this is provided through the standard header `time.h`. Nowadays, the types for the individual members would probably be chosen differently. But many times in C we have to stick with design decisions that were made many years ago.

![](https://drek4537l1klr.cloudfront.net/gustedt/Figures/comm.jpg)

<time.h>##### Listing 6.3. A sample program manipulating struct **`tm`**

```
1   #include <time.h>
2   #include <stdbool.h>
3   #include <stdio.h>
4
5   bool leapyear(unsigned year) {
6     /* All years that are divisible by 4 are leap years,
7        unless they start a new century, provided they
8        are not divisible by 400. */
9     return !(year % 4) && ((year % 100) || !(year % 400));
10   }
11
12   #define DAYS_BEFORE                             \
13   (int const[12]){                                \
14     [0] = 0, [1] = 31, [2] = 59, [3] = 90,        \
15     [4] = 120, [5] = 151, [6] = 181, [7] = 212,   \
16     [8] = 243, [9] = 273, [10] = 304, [11] = 334, \
17   }
18
19   struct tm time_set_yday(struct tm t) {
20     // tm_mdays starts at 1.
21     t.tm_yday += DAYS_BEFORE[t.tm_mon] + t.tm_mday - 1;
22     // Takes care of leap years
23     if ((t.tm_mon > 1) && leapyear(t.tm_year+1900))
24       ++t.tm_yday;
25     return t;
26   }
27
28   int main(void) {
29     struct tm today = {
30       .tm_year = 2019-1900,
31       .tm_mon  = 4-1,
32       .tm_mday = 3,
33       .tm_hour = 10,
34       .tm_min  = 0,
35       .tm_sec  = 47,
36     };
37     printf("this year is %d, next year will be %d\n",
38            today.tm_year+1900, today.tm_year+1900+1);
39     today = time_set_yday(today);
40     printf("day of the year is %d\n", today.tm_yday);
41   }
```

##### Takeaway 6.27

*A structure layout is an important design decision.*

You may regret your design after some years, when all the existing code that uses it makes it almost impossible to adapt it to new situations.

Another use of **`struct`** is to group objects of different types together in one larger enclosing object. Again, for manipulating times with a nanosecond granularity, the C standard already has made that choice:

```
struct timespec {
time_t tv_sec; // Whole seconds ≥0
long  tv_nsec; // Nanoseconds   [0, 999999999]
};
```

![](https://drek4537l1klr.cloudfront.net/gustedt/Figures/pg_095.jpg)

Here we see the opaque type **`time_t`** that we saw in [table 5.2](/book/modern-c/chapter-5/ch05table02) for the seconds, and a **`long`** for the nanoseconds.[[4](/book/modern-c/chapter-6/ch06fn04)] Again, the reasons for this choice are historical; nowadays the chosen types would perhaps be a bit different. To compute the difference between two **`struct`** **`timespec`** times, we can easily define a function.

4 Unfortunately, even the semantics of **`time_t`** are different here. In particular, **`tv_sec`** may be used in arithmetic. 

![](https://drek4537l1klr.cloudfront.net/gustedt/Figures/comm.jpg)

Whereas the function **difftime** is part of the C standard, such functionality here is very simple and isn’t based on platform-specific properties. So it can easily be implemented by anyone who needs it.[[[Exs 2]](/book/modern-c/chapter-6/ch06fn-ex02)]

[Exs 2] Write a function timespec_diff that computes the difference between two **`timespec`** values. 

Any data type other than a VLA is allowed as a member in a structure. So structures can also be nested in the sense that a member of a **`struct`** can again be of (another) **`struct`** type, and the smaller enclosed structure may even be declared inside the larger one:

```
struct person {
char name[256];
struct stardate {
structtm date;
structtimespec precision;
} bdate;
};
```

![](https://drek4537l1klr.cloudfront.net/gustedt/Figures/pg_096_alt.jpg)

The visibility of declaration **`struct`** stardate is the same as for **`struct`** person. A **`struct`** itself (here, person) defines no new scope for a **`struct`** (here, stardate) that is defined within the `{}` of the outermost **`struct`** declaration. This may be much different from the rules of other programming languages, such as C++.

##### Takeaway 6.28

*All* **`struct`** *declarations in a nested declaration have the same scope of visibility.*

That is, if the previous nested **`struct`** declarations appear globally, both **`struct`**s are subsequently visible for the whole C file. If they appear inside a function, their visibility is bound to the `{}` block in which they are found.

So, a more adequate version would be as follows:

```
struct stardate {
struct tm date;
struct timespec precision;
};
struct person {
char name[256];
struct stardate bdate;
};
```

This version places all **`struct`**s on the same level, because they end up there, anyhow.

## 6.4. New names for types: type aliases

![](https://drek4537l1klr.cloudfront.net/gustedt/Figures/comm.jpg)

As we saw in the previous chapter, a structure not only introduces a way to aggregate differing information into one unit, but also introduces a new type name for the beast. For historical reasons (again!), the name that we introduce for the structure always has to be preceded by the keyword **`struct`**, which makes its use a bit clumsy. Also, many C beginners run into difficulties with this when they forget the **`struct`** keyword and the compiler throws an incomprehensible error at them.

There is a general tool that can help us avoid that, by giving a symbolic name to an otherwise existing type: **`typedef`**. Using it, a type can have several names, and we can even reuse the *tag name**C* that we used in the structure declaration:

```
typedef struct birdStruct birdStructure;
typedef struct birdStruct birdStruct;
```

Then, **`struct`** birdStruct, birdStruct, and birdStructure can all be used interchangeably. My favorite use of this feature is the following idiom:

```
typedef struct birdStruct birdStruct;
struct birdStruct {
...
};
```

That is, to *precede* the proper **`struct`** declaration by a **`typedef`** using exactly the same name. This works because in the combination of **`struct`** with a following name, the *tag**C* is always valid, a *forward declaration**C* of the structure.

##### Takeaway 6.29

*Forward-declare a* **`struct`** *within a* **`typedef`** *using the same identifier as the tag name.*

C++ follows a similar approach by default, so this strategy will make your code easier to read for people who come from there.

The **`typedef`** mechanism can also be used for types other than structures. For arrays, this could look like

```
typedef double vector[64];
typedef vector vecvec[16];
vecvec A;
typedef double matrix[16][64];
matrix B;
double C[16][64];
```

Here, **`typedef`** only introduces a new name for an existing type, so A, B, and C have exactly the same type: **`double`**`[16][64]`.

##### Takeaway 6.30

*A* **`typedef`** *only creates an alias for a type, but never a new type.*

The C standard also uses **`typedef`** a lot internally. The semantic integer types such as **`size_t`** that we saw in [section 5.2](/book/modern-c/chapter-5/ch05lev1sec2) are declared with this mechanism. The standard often uses names that terminate with **`_t`** for **`typedef`**. This naming convention ensures that the introduction of such a name in an upgraded version of the standard will not conflict with existing code. So you shouldn’t introduce such names yourself in your code.

##### Takeaway 6.31

*Identifier names terminating with* **`_t`** *are reserved.*

## Summary

- Arrays combine several values of the same base type into one object.
- Pointers refer to other objects, are null, or are indeterminate.
- Structures combine values of different base types into one object.
- **`typedef`**s provide new names for existing types.

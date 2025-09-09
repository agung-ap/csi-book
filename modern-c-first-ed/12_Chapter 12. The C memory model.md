# Chapter 12. The C memory model

### This chapter covers

- Understanding object representations
- Working with untyped pointers and casts
- Restricting object access with effective types and alignment

Pointers present us with a certain abstraction of the environment and state in which our program is executed, the *C memory model*. We may apply the unary operator `&` to (almost) all objects[[1](/book/modern-c/chapter-12/ch12fn01)] to retrieve their address and use it to inspect and change the state of our execution.

1 Only objects that are declared with keyword **`register`** don’t have an address; see [section 13.2.2](/book/modern-c/chapter-13/ch13lev2sec4) on [level 2](/book/modern-c/part-2/part02).

This access to objects via pointers is still an abstraction, because seen from C, no distinction of the “real” location of an object is made. It could reside in your computer’s RAM or on a disk file, or correspond to an IO port of a temperature sensor on the moon; you shouldn’t care. C is supposed to do the right thing, regardless.

And indeed, on modern operating systems, all you get via pointers is something called *virtual memory*, basically a fiction that maps the *address space* of your process to physical memory addresses of your machine. All this was invented to ensure certain properties of your program executions:

- ***portable:*** You do not have to care about physical memory addresses on a specific machine.
- ***safe:*** Reading or writing virtual memory that your process does not own will affect neither your operating system nor any other process.

The only thing C must care about is the *type* of the object a pointer addresses. Each pointer type is derived from another type, its base type, and each such derived type is a distinct new type.

![Figure 12.1. The different levels of the value-memory model for an int32_t. Example of a platform that maps this type to a 32-bit signed int that has two’s complement sign representation and little-endian object representation.](https://drek4537l1klr.cloudfront.net/gustedt/Figures/12fig01_alt.jpg)

##### Takeaway 12.1

*Pointer types with distinct base types are distinct.*

In addition to providing a virtual view of physical memory, the memory model also simplifies the view of objects themselves. It makes the assumption that each object is a collection of bytes, the *object representation* ([section 12.1](/book/modern-c/chapter-12/ch12lev1sec1));[[2](/book/modern-c/chapter-12/ch12fn02)] see [figure 12.1](/book/modern-c/chapter-12/ch12fig01) for a schematic view. A convenient tool to inspect that object representation is *unions* ([section 12.2](/book/modern-c/chapter-12/ch12lev1sec2)). Giving direct access to the object representation ([section 12.3](/book/modern-c/chapter-12/ch12lev1sec3)) allows us to do some fine tuning; but on the other hand, it also opens the door to unwanted or conscious manipulations of the state of the abstract machine: tools for that are untyped pointers ([section 12.4](/book/modern-c/chapter-12/ch12lev1sec4)) and casts ([section 12.5](/book/modern-c/chapter-12/ch12lev1sec5)). Effective types ([section 12.6](/book/modern-c/chapter-12/ch12lev1sec6)) and alignment ([section 12.7](/book/modern-c/chapter-12/ch12lev1sec7)) describe formal limits and platform constraints for such manipulations.

2 The object representation is related to but not the same thing as the *binary representation* that we saw in [section 5.1.3](/book/modern-c/chapter-5/ch05lev2sec3).

## 12.1. A uniform memory model

Even though generally all objects are typed, the memory model makes another simplification: that all objects are an assemblage of *bytes**C*. The **`sizeof`** operator that we introduced in the context of arrays measures the size of an object in terms of the bytes that it uses. There are three distinct types that by definition use exactly one byte of memory: the character types **`char`**, **`unsigned char`**, and **`signed char`**.

##### Takeaway 12.2

*`sizeof(char)`* *is* *`1`* *by definition.*

Not only can all objects be “accounted” in size as character types on a lower level, they can even be inspected and manipulated as if they were arrays of such character types. A little later, we will see how this can be achieved, but for the moment we will just note the following:

##### Takeaway 12.3

*Every object* *`A`* *can be viewed as* **`unsigned char`***`[`***`sizeof`** *A**`]`.*

##### Takeaway 12.4

*Pointers to character types are special.*

Unfortunately, the types that are used to compose all other object types are derived from **`char`**, the type we looked at for the characters of strings. This is merely a historical accident, and you shouldn’t read too much into it. In particular, you should clearly distinguish the two different use cases.

![](https://drek4537l1klr.cloudfront.net/gustedt/Figures/193fig01.jpg)

##### Takeaway 12.5

*Use the type* **`char`** *for character and string data.*

##### Takeaway 12.6

*Use the type* **`unsigned char`** *as the atom of all object types.*

The type **`signed char`** is of much less importance than the two others.

As we have seen, the **`sizeof`** operator counts the size of an object in terms of how many **`unsigned char`** s it occupies.

##### Takeaway 12.7

*The* **`sizeof`** *operator can be applied to objects and object types.*

In the previous discussion, we can also distinguish two syntactic variants for **`sizeof`**: with and without parentheses. Whereas the syntax for an application to objects can have both forms, the syntax for types needs parentheses:

##### Takeaway 12.8

*The size of all objects of type* *`T`* *is given by* **`sizeof`***`(`**`T`**`)`**.*

## 12.2. Unions

Let us now look at a way to examine the individual bytes of objects. Our preferred tool for this is the **`union`**. These are similar in declaration to **`struct`** but have different semantics:

##### `endianness.c`

```
2   #include <inttypes.h>
3
4   typedef union unsignedInspect unsignedInspect;
5   union unsignedInspect {
6     unsigned val;
7     unsigned char bytes[sizeof(unsigned)];
8   };
9   unsignedInspect twofold = { .val = 0xAABBCCDD, };
```

The difference here is that such a **`union`** doesn’t collect objects of different type into one bigger object, but rather *overlays* an object with a different type interpretation. That way, it is the perfect tool to inspect the individual bytes of an object of another type.

Let us first try to figure out what values we would expect for the individual bytes. In a slight abuse of language, let us speak of the different parts of an unsigned number that correspond to the bytes as *representation digits*. Since we view the bytes as being of type **`unsigned char`**, they can have values `0` . . . **`UCHAR_MAX`**, inclusive, and thus we interpret the number as written with a base of **`UCHAR_MAX`**`+1`. In the example, on my machine, a value of type **`unsigned`** can be expressed with **`sizeof`**`(`**`unsigned`**`) == 4` such representation digits, and I chose the values `0`xAA, `0`xBB, `0`xCC, and `0`xDD for the highest- to lowest-order representation digit. The complete **`unsigned`** value can be computed using the following expression, where **`CHAR_BIT`** is the number of bits in a character type:

```
1   ((0xAA << (CHAR_BIT*3))
2       |(0xBB << (CHAR_BIT*2))
3       |(0xCC << CHAR_BIT)
4       |0xDD)
```

With the **`union`** defined earlier, we have two different facets to look at the same twofold object: twofold.val presents it as being an **`unsigned`**, and twofold.bytes presents it as an array of **`unsigned char`**. Since we chose the length of twofold.bytes to be exactly the size of twofold.val, it represents exactly its bytes, and thus gives us a way to inspect the *object representation**C* of an **`unsigned`** value: all its representation digits:

##### `endianness.c`

```
12      printf("value is 0x%.08X\n", twofold.val);
13      for (size_t i = 0; i < sizeof twofold.bytes; ++i)
14        printf("byte[%zu]: 0x%.02hhX\n", i, twofold.bytes[i]);
```

On my computer, I receive a result as shown here:[[3](/book/modern-c/chapter-12/ch12fn03)]

3 Test the code on your own machine.

##### `Terminal`

```
0      ~/build/modernC% code/endianness
1      value is 0xAABBCCDD
2      byte[0]: 0xDD
3      byte[1]: 0xCC
4      byte[2]: 0xBB
5      byte[3]: 0xAA
```

For my machine, we see that the output has the low-order representation digits of the integer first, then the next-lower order digits, and so on. At the end, the highest-order digits are printed. So the in-memory representation of such an integer on my machine has the low-order representation digits before the high-order ones.

This is *not* normalized by the standard, but is an implementation-defined behavior.

##### Takeaway 12.9

*The in-memory order of the representation digits of an arithmetic type is implementation defined.*

That is, a platform provider might decide to provide a storage order that has the highest-order digits first, and then print lower-order digits one by one. The storage order, the *endianness**C*, as given for my machine, is called *little-endian**C*. A system that has high-order representation digits first is called *big-endian**C*.[[4](/book/modern-c/chapter-12/ch12fn04)] Both orders are commonly used by modern processor types. Some processors are even able to switch between the two orders on the fly.

4 The names are derived from the fact that the big or small “end” of a number is stored first.

The previous output also shows another implementation-defined behavior: I used the feature of my platform that one representation digit can be printed nicely by using two hexadecimal digits. In other words, I assumed that **`UCHAR_MAX`**`+1` is `256` and that the number of value bits in an **`unsigned char`**, **`CHAR_BIT`**, is `8`. Again, this is implementation-defined behavior: although the vast majority of platforms have these properties,[[5](/book/modern-c/chapter-12/ch12fn05)] there are still some around that have wider character types.

5 In particular, all POSIX systems.

##### Takeaway 12.10

*On most architectures,* **`CHAR_BIT`** *is* *`8`* *and* **`UCHAR_MAX`** *is* *`255`**.*

In the example, we have investigated the in-memory representation of the simplest arithmetic base types, unsigned integers. Other base types have in-memory representations that are more complicated: signed integer types have to encode the sign; floating-point types have to encode the sign, mantissa, and exponent; and pointer types may follow any internal convention that fits the underlying architecture.[[[Exs 1]](/book/modern-c/chapter-12/ch12fn-ex01)][[[Exs 2]](/book/modern-c/chapter-12/ch12fn-ex02)][[[Exs 3]](/book/modern-c/chapter-12/ch12fn-ex03)]

[Exs 1] Design a similar **`union`** type to investigate the bytes of a pointer type, such as **`double`**`*`.

[Exs 2] With such a **`union`**, investigate the addresses of two consecutive elements of an array.

[Exs 3] Compare the addresses of the same variable between different executions.

## 12.3. Memory and state

The value of all objects constitutes the state of the abstract state machine, and thus the state of a particular execution. C’s memory model provides something like a unique location for (almost) all objects through the `&` operator, and that location can be accessed and modified from different parts of the program through pointers.

Doing so makes the determination of the abstract state of an execution much more difficult, if not impossible in many cases:

Here, we (as well as the compiler) only see a declaration of function blub, with no definition. So we cannot conclude much about what that function does to the objects its arguments point to. In particular, we don’t know if the variable d is modified, so the sum c `+` d could be anything. The program really has to inspect the object d in memory to find out what the values *after* the call to blub are.

Now let us look at such a function that receives two pointer arguments:

```
1   double blub(double const* a, double* b);
2
3   int main(void) {
4     double c = 35;
5     double d = 3.5;
6     printf("blub is %g\n", blub(&c, &d));
7     printf("after blub the sum is %g\n", c + d);
8   }1   double blub(double const* a, double* b) {
2     double myA = *a;
3     *b = 2*myA;
4     return *a;      // May be myA or 2*myA
5   }
```

Such a function can operate under two different assumptions. First, if called with two distinct addresses as arguments, `*`a will be unchanged, and the return value will be the same as myA. But if both arguments are the same, such as if the call is blub`(`&`c,` &`c)`, the assignment to `*`b will change `*`a, too.

The phenomenon of accessing the same object through different pointers is called *aliasing**C*; it is a common cause for missed optimization. In both cases, either that two pointers always alias or that they never alias, the abstract state of an execution is much reduced, and the optimizer often can take much advantage of that knowledge. Therefore, C forcibly restricts the possible aliasing to pointers of the same type.

##### Takeaway 12.11 (Aliasing)

*With the exclusion of character types, only pointers of the same base type may alias.*

To see this rule in effect, consider a slight modification of our previous example:

```
1   size_t blob(size_t const* a, double* b) {
2     size_t myA = *a;
3     *b = 2*myA;
4     return *a;       // Must be myA
5   }
```

Because here the two parameters have different types, C *assumes* that they don’t address the same object. In fact, it would be an error to call that function as blob`(`&`e,` &`e)`, since this would never match the prototype of blob. So at the **`return`** statement, we can be sure that the object `*`a hasn’t changed and that we already hold the needed value in variable myA.

There are ways to fool the compiler and to call such a function with a pointer that addresses the same object. We will see some of these cheats later. Don’t do this: it is a road to much grief and despair. *If* you do so, the behavior of the program becomes undefined, so you have to guarantee (prove!) that no aliasing takes place.

In the contrary, we should try to write our programs so they protect our variables from ever being aliased, and there is an easy way to achieve that.

##### Takeaway 12.12

*Avoid the* *`&`* *operator.*

Depending on the properties of a given variable, the compiler may see that the address of the variable is never taken, and thus the variable can’t alias at all. In [section 13.2](/book/modern-c/chapter-13/ch13lev1sec2), we will see which properties of a variable or object may influence such decisions and how the **`register`** keyword can protect us from taking addresses inadvertently. Later, in [section 15.2](/book/modern-c/chapter-15/ch15lev1sec2), we will see how the **`restrict`** keyword allows us to specify aliasing properties of pointer arguments, even if they have the same base type.

## 12.4. Pointers to unspecific objects

As we have seen, the object representation provides a view of an object X as an array **`unsigned char`**`[`**`sizeof`** X`]`. The starting address of that array (of type **`unsigned char`**`*`) provides access to memory that is stripped of the original type information.

C has invented a powerful tool to handle such pointers more generically. These are pointers to a sort of *non-type*, **`void`**.

##### Takeaway 12.13

*Any object pointer converts to and from* **`void`***`*`**.*

Note that this only talks about object pointers, not function pointers. Think of a **`void`**`*` pointer that holds the address of an existing object as a pointer into a *storage instance* that holds the object; see [figure 12.1](/book/modern-c/chapter-12/ch12fig01). As an analogy for such a hierarchy, you could think of entries in a phone book: a person’s name corresponds to the identifier that refers to an object; their categorization with a “mobile,” “home,” or “work” entry corresponds to a type; and their phone number itself is some sort of address (in which, by itself, you typically are not interested). But then, even the phone number abstracts away from the specific information of where the other phone is located (which would be the storage instance underneath the object), or of specific information about the other phone itself, for example if it is on a landline or the mobile network, and what the network has to do to actually connect you to the person at the other end.

##### Takeaway 12.14

*An object has storage, type, and value.*

Not only is the conversion to **`void`**`*` well defined, but it also is guaranteed to behave well with respect to the pointer value.

##### Takeaway 12.15

*Converting an object pointer to* **`void`***`*`* *and then back to the same type is the identity operation.*

So the only thing that we lose when converting to **`void`**`*` is the type information; the value remains intact.

##### Takeaway 12.16 (a*void2**)

*A*void **`void`***`*`**.*

It completely removes any type information that was associated with an address. Avoid it whenever you can. The other way around is much less critical, in particular if you have a C library call that returns a **`void`**`*`.

**`void`** as a type by itself shouldn’t be used for variable declarations since it won’t lead to an object with which we could do anything.

## 12.5. Explicit conversions

A convenient way to look at the object representation of object X would be to somehow convert a pointer to X to a pointer of type **`unsigned char`**`*`:

```
double X;
   unsigned char* Xp = &X; // error: implicit conversion not allowed
```

Fortunately, such an implicit conversion of a **`double`**`*` to **`unsigned char`**`*` is not allowed. We would have to make this conversion somehow explicit.

We already have seen that in many places, a value of a certain type is implicitly converted to a value of a different type ([section 5.4](/book/modern-c/chapter-5/ch05lev1sec4)), and that narrow integer types are first converted to **`int`** before any operation. In view of that, narrow types only make sense in very special circumstances:

- You have to save memory. You need to use a really big array of small values. *Really big* here means potentially millions or billions. In such a situation, storing these values may gain you something.
- You use **`char`** for characters and strings. But then you wouldn’t do arithmetic with them.
- You use **`unsigned char`** to inspect the bytes of an object. But then, again, you wouldn’t do arithmetic with them.

Conversions of pointer types are more delicate, because they can change the type interpretation of an object. Only two forms of implicit conversions are permitted for data pointers: conversions from and to **`void`**`*`, and conversions that add a qualifier to the target type. Let’s look at some examples:

```
1   float f = 37.0;        // Conversion: to float
2   double a = f;          // Conversion: back to double
3   float* pf = &f;        // Exact type
4   float const* pdc = &f; // Conversion: adding a qualifier
5   void* pv = &f;         // Conversion: pointer to void*
6   float* pfv = pv;       // Conversion: pointer from void*
7   float* pd = &a;        // Error: incompatible pointer type
8   double* pdv = pv;      // Undefined behavior if used
```

The first two conversions that use **`void`**`*` (pv and pfv) are already a bit tricky: we convert a pointer back and forth, but we watch that the target type of pfv is the same as f so everything works out fine.

Then comes the erroneous part. In the initialization of pd, the compiler can protect us from a severe fault: assigning a pointer to a type that has a different size and interpretation can and will lead to serious damage. Any conforming compiler *must* give a diagnosis for this line. As you have by now understood well that your code should not produce compiler warnings ([takeaway 1.4](/book/modern-c/chapter-1/ch01note05)), you know that you should not continue until you have repaired such an error.

The last line is worse: it has an error, but that error is syntactically correct. The reason this error might go undetected is that our first conversion for pv has stripped the pointer from all type information. So, in general, the compiler can’t know what type of object is behind the pointer.

In addition to the implicit conversions that we have seen until now, C also allows us to convert explicitly using *casts**C*.[[6](/book/modern-c/chapter-12/ch12fn06)] With a cast, you are telling the compiler that you know better than it does, that the type of the object behind the pointer is not what it thinks, and that it should shut up. In most use cases that I have come across in real life, the compiler was right and the programmer was wrong: even experienced programmers tend to abuse casts to hide poor design decisions concerning types.

6 A cast of an expression X to type T has the form (`T)`X. Think of it like “*to cast a spell*.”

##### Takeaway 12.17

*Don’t use casts.*

They deprive you of precious information, and if you chose your types carefully, you will only need them for very special occasions.

One such occasion is when you want to inspect the contents of an object on the byte level. Constructing a **`union`** around an object, as we saw in [section 12.2](/book/modern-c/chapter-12/ch12lev1sec2), might not always be possible (or may be too complicated), so here we can go for a cast:

##### `endianness.c`

```
15      unsigned val = 0xAABBCCDD;
16      unsigned char* valp = (unsigned char*)&val;
17      for (size_t i = 0; i < sizeof val; ++i)
18        printf("byte[%zu]: 0x%.02hhX\n", i, valp[i]);
```

In that direction (from “pointer to object” to a “pointer to character type”), a cast is mostly harmless.

## 12.6. Effective types

To cope with different views of the same object that pointers may provide, C has introduced the concept of *effective types*. It heavily restricts how an object can be accessed.

##### Takeaway 12.18 (Effective Type)

*Objects must be accessed through their effective type or through a pointer to a character type.*

Because the effective type of a **`union`** variable is the **`union`** type and none of the member types, the rules for **`union`** members can be relaxed:

##### Takeaway 12.19

*Any member of an object that has an effective* **`union`** *type can be accessed at any time, provided the byte representation amounts to a valid value of the access type.*

For all objects we have seen so far, it is easy to determine the effective type:

##### Takeaway 12.20

*The effective type of a variable or compound literal is the type of its declaration.*

Later, we will see another category of objects that are a bit more involved.

Note that this rule has no exceptions, and that we can’t change the type of such a variable or compound literal.

##### Takeaway 12.21

*Variables and compound literals must be accessed through their declared type or through a pointer to a character type.*

Also observe the asymmetry in all of this for character types. Any object can be seen as being composed of **`unsigned char`**, but no array of **`unsigned char`** s can be used through another type:

```
unsigned char A[sizeof(unsigned)] = { 9 };
   // Valid but useless, as most casts are
   unsigned* p = (unsigned*)A;
   // Error: access with a type that is neither the effective type nor a
   // character type
   printf("value \%u\n", *p);
```

Here, the access `*`p is an error, and the program state is undefined afterward. This is in strong contrast to our dealings with **`union`** earlier: see [section 12.2](/book/modern-c/chapter-12/ch12lev1sec2), where we actually could view a byte sequence as an array of **`unsigned char`** or **`unsigned`**.

The reasons for such a strict rule are multiple. The very first motivation for introducing effective types in the C standard was to deal with aliasing, as we saw in [section 12.3](/book/modern-c/chapter-12/ch12lev1sec3). In fact, the Aliasing Rule ([takeaway 12.11](/book/modern-c/chapter-12/ch12note11)) is derived from the Effective Type Rule ([takeaway 12.18](/book/modern-c/chapter-12/ch12note18)). As long as there is no **`union`** involved, the compiler knows that we cannot access a **`double`** through a **`size_t`**`*`, and so it may *assume* that the objects are different.

## 12.7. Alignment

The inverse direction of pointer conversions (from “pointer to character type” to “pointer to object”) is not harmless at all, and not only because of possible aliasing. This has to do with another property of C’s memory model: *alignment**C*. Objects of most non-character types can’t start at any arbitrary byte position; they usually start at a *word boundary**C*. The alignment of a type then describes the possible byte positions at which an object of that type can start.

If we force some data to a false alignment, really bad things can happen. To see that, have a look at the following code:

```
1   #include <stdio.h>
 2   #include <inttypes.h>
 3   #include <complex.h>
 4   #include "crash.h"
 5
 6   void enable_alignment_check(void);
 7   typedef complex double cdbl;
 8
 9   int main(void) {
10     enable_alignment_check();
11     /* An overlay of complex values and bytes. */
12     union {
13       cdbl val[2];
14       unsigned char buf[sizeof(cdbl[2])];
15     } toocomplex = {
16       .val = { 0.5 + 0.5*I, 0.75 + 0.75*I, },
17     };
18     printf("size/alignment: %zu/%zu\n",
19            sizeof(cdbl), _Alignof(cdbl));
20     /* Run over all offsets, and crash on misalignment. */
21     for (size_t offset = sizeof(cdbl); offset; offset /=2) {
22       printf("offset\t%zu:\t", offset);
23       fflush(stdout);
24       cdbl* bp = (cdbl*)(&toocomplex.buf[offset]); // align!
25       printf("%g\t+%gI\t", creal(*bp), cimag(*bp));
26       fflush(stdout);
27       *bp *= *bp;
28       printf("%g\t+%gI", creal(*bp), cimag(*bp));
29       fputc('\n', stdout);
30     }
31   }
```

This starts with a declaration of a **`union`** similar to what we saw earlier. Again, we have a data object (of type **`complex`** **`double`**`[2]` in this case) that we overlay with an array of **`unsigned char`**. Other than the fact that this part is a bit more complex, at first glance there is no major problem with it. But if I execute this program on my machine, I get

##### `Terminal`

```
0   ~/.../modernC/code (master % u=) 14:45 <516>$ ./crash
1   size/alignment: 16/8
2   offset 16: 0.75 +0.75I 0 +1.125I
3   offset 8: 0.5 +0I 0.25 +0I
4   offset 4: Bus error
```

The program crashes with an error indicated as a *bus error**C*, which is a shortcut for something like “data bus alignment error.” The real problem line is

##### `crash.c`

```
23       fflush(stdout);
24       cdbl* bp = (cdbl*)(&toocomplex.buf[offset]); // align!
```

On the right, we see a pointer cast: an **`unsigned char`**`*` is converted to a **`complex`** **`double`**`*`. With the **`for`** loop around it, this cast is performed for byte offsets offset from the beginning of toocomplex. These are powers of `2`: `16`, `8`, `4`, `2`, and `1`. As you can see in the output, above, it seems that **`complex`** **`double`** still works well for alignments of half of its size, but then with an alignment of one fourth, the program crashes.

Some architectures are more tolerant of misalignment than others, and we might have to force the system to error out on such a condition. We use the following function at the beginning to force crashing:

`crash.c`

enable_alignment_check: enable alignment check for i386 processors

Intel’s i386 processor family is quite tolerant in accepting misalignment of data. This can lead to irritating bugs when ported to other architectures that are not as tolerant.

This function enables a check for this problem also for this family or processors, such that you can be sure to detect this problem early.

I found that code on Ygdrasil’s blog: `http://orchistro.tistory.com/206`

```
void enable_alignment_check(void);
```

If you are interested in portable code (and if you are still here, you probably are), early errors in the development phase are really helpful.[[7](/book/modern-c/chapter-12/ch12fn07)] So, consider crashing a feature. See the blog entry mentioned in `crash.h` for an interesting discussion on this topic.

7 For the code that is used inside that function, please consult the source code of `crash.h` to inspect it.

In the previous code example, we also see a new operator, **`alignof`** (or **`_Alignof`**, if you don’t include `stdalign.h`), that provides us with the alignment of a specific type. You will rarely find the occasion to use it in real live code.

<stdalign.h>Another keyword can be used to force allocation at a specified alignment: **`alignas`** (respectively, **`_Alignas`**). Its argument can be either a type or expression. It can be useful where you know that your platform can perform certain operations more efficiently if the data is aligned in a certain way.

For example, to force alignment of a **`complex`** variable to its size and not half the size, as we saw earlier, you could use

```
alignas(sizeof(complex double)) complex double z;
```

Or if you know that your platform has efficient vector instructions for **`float`**`[4]` arrays:

```
alignas(sizeof(float[4])) float fvec[4];
```

These operators don’t help against the Effective Type Rule ([takeaway 12.18](/book/modern-c/chapter-12/ch12note18)). Even with

```
alignas(unsigned) unsigned char A[sizeof(unsigned)] = { 9 };
```

the example at the end of [section 12.6](/book/modern-c/chapter-12/ch12lev1sec6) remains invalid.

## Summary

- The memory and object model have several layers of abstraction: physical memory, virtual memory, storage instances, object representation, and binary representation.
- Each object can be seen as an array of **`unsigned char`**.
- **`union`**s serve to overlay different object types over the same object representation.
- Memory can be aligned differently according to the need for a specific data type. In particular, not all arrays of **`unsigned char`** can be used to represent any object type.

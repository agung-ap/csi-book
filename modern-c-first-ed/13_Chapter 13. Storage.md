# Chapter 13. Storage

### This chapter covers

- Creating objects with dynamic allocation
- The rules of storage and initialization
- Understanding object lifetime
- Handling automatic storage

So far, most objects we have handled in our programs have been *variables*: that is, objects that are declared in a regular declaration with a specific type and an identifier that refers to the object. Sometimes they were defined at a different place in the code than they were declared, but even such a definition referred to them with a type and identifier. Another category of objects that we have seen less often is specified with a type but not with an identifier: *compound literals*, as introduced in [section 5.6.4](/book/modern-c/chapter-5/ch05lev2sec9).

All such objects, variables or compound literals, have a *lifetime**C* that depends on the syntactical structure of the program. They have an object lifetime and identifier visibility that either spans the whole program execution (global variables, global literals, and variables that are declared with **`static`**) or are bound to a block of statements inside a function.[[1](/book/modern-c/chapter-13/ch13fn01)]

1 In fact, this is a bit of a simplification; we will see the gory details shortly.

We also have seen that for certain objects, it is important to distinguish different instances: when we declare a variable in a recursive function. Each call in a hierarchy of recursive calls has its own instance of such a variable. Therefore, it is convenient to distinguish another entity that is not exactly the same as an object, the storage instance.

In this chapter, we will handle another mechanism to create objects, called *dynamic allocation* ([section 13.1](/book/modern-c/chapter-13/ch13lev1sec1)). In fact, this mechanism creates storage instances that are only seen as byte arrays and do not have any interpretation as objects. They only acquire a type once we store something.

With this, we have an almost-complete picture of the different possibilities, and we can thus discuss the different rules for storage *duration*, object *lifetime*, and identifier *visibility* ([section 13.2](/book/modern-c/chapter-13/ch13lev1sec2)); we will also take a full dive into the rules for initialization ([section 13.4](/book/modern-c/chapter-13/ch13lev1sec4)), as these differ significantly for differently created objects.

Additionally, we propose two digressions. The first is a more-detailed view of object lifetime, which allows us to access objects at surprising points in the C code ([section 13.3](/book/modern-c/chapter-13/ch13lev1sec3)). The second provides a glimpse into a realization of the memory model for a concrete architecture ([section 13.5](/book/modern-c/chapter-13/ch13lev1sec5)) and in particular how automatic storage may be handled on your particular machine.

## 13.1. malloc and friends

For programs that have to handle growing collections of data, the types of objects that we have seen so far are too restrictive. To handle varying user input, web queries, large interaction graphs and other irregular data, big matrices, and audio streams, it is convenient to reclaim storage instances for objects on the fly and then release them once they are not needed anymore. Such a scheme is called *dynamic allocation**C*, or sometimes just *allocation* for short.

<stdlib.h>The following set of functions, available with `stdlib.h`, has been designed to provide such an interface to allocated storage:

##### #include

voidmallocsize_tsizevoidfreevoidptrvoidcallocsize_tnmembsize_tsizevoidreallocvoidptrsize_tsizevoidaligned_allocsize_talignmentsize_tsizeThe first two, **malloc** (memory allocate) and **free**, are by far the most prominent. As their names indicate, **malloc** creates a storage instance for us on the fly, and **free** then annihilates it. The three other functions are specialized versions of **malloc**: **calloc** (clear allocate) sets all bits of the new storage to `0`, **realloc** grows or shrinks storage, and **aligned_alloc** ensures nondefault alignment.

All these functions operate with **`void`**`*`: that is, with pointers for which no type information is known. Being able to specify such a “non-type” for this series of functions is probably the *raison d’être* for the whole game with **`void`**`*` pointers. Using that, they become universally applicable to all types. The following example allocates a large storage for a vector of **`double`**s, one element for each living person:[[[Exs 1]](/book/modern-c/chapter-13/ch13fn-ex01)]

[Exs 1] Don’t try this allocation, but compute the size that would be needed on your platform. Is allocating such a vector feasible on your platform?

size_tlengthlivingPeopledoublelargeVecmalloclengthsizeoflargeVecforsize_tiilengthilargeVecifreelargeVecBecause **malloc** knows nothing about the later use or type of the to-be-stored object, the size of the storage is specified in bytes. In the idiom given here, we have specified the type information only once, as the pointer type for largeVec. By using **`sizeof`** `*`largeVec in the parameter for the **malloc** call, we ensure that we will allocate the right number of bytes. Even if we change largeVec later to have type **`size_t`**`*`, the allocation will adapt.

Another idiom that we will often encounter strictly takes the size of the type of the object that we want to create: an array of length elements of type **`double`**:

##### double

largeVecmallocsizeofdoublelengthWe already have been haunted by the introduction of casts, which are explicit conversions. It is important to note that the call to **malloc** stands as is; the conversion from **`void`**`*`, the return type of **malloc**, to the target type is automatic and doesn’t need any intervention.

##### Takeaway 13.1

*Don’t cast the return of* **malloc** *and friends.*

Not only is such a cast superfluous, but doing an explicit conversion can even be counterproductive when we forget to include the header file `stdlib.h`:

<stdlib.h>/* If we forget to include stdlib.h, many compilersstill assume: */intmalloc// Wrong function interface!doublelargeVecvoidmallocsizeofdoublelengthintvoidOlder C compilers then suppose a return of **`int`** and trigger the wrong conversion from **`int`** to a pointer type. I have seen many crashes and subtle bugs triggered by that error, in particular in beginners’ code whose authors have been following bad advice.

In the previous code, as a next step, we initialize the storage that we just allocated through assignment: here, all `0.0`. It is only with these assignments that the individual elements of largeVec become “objects.” Such an assignment provides an effective type *and* a value.

##### Takeaway 13.2

*Storage that is allocated through* **malloc** *is uninitialized and has no type.*

### 13.1.1. A complete example with varying array size

Let us now look at an example where using a dynamic array that is allocated with **malloc** brings us more flexibility than a simple array variable. The following interface describes a circular buffer of **`double`** values called circular:

##### circular.h

circular: an opaque type for a circular buffer for **`double`** values

This data structure allows to add **`double`** values in rear and to take them out in front. Each such structure has a maximal amount of elements that can be stored in it.

```
typedef struct circular circular;
```

##### circular.h

circular_append: Append a new element with value *value* to the buffer *c*.

**Returns**: c if the new element could be appended, `0` otherwise.

```
circular* circular_append(circular* c, double value);
```

##### circular.h

circular_pop: Remove the oldest element from *c* and return its value.

**Returns**: the removed element if it exists, `0.0` otherwise.

```
double circular_pop(circular* c);
```

The idea is that, starting with `0` elements, new elements can be appended to the buffer or dropped from the front, as long as the number of elements that are stored doesn’t exceed a certain limit. The individual elements that are stored in the buffer can be accessed with the following function:

##### circular.h

circular_element: Return a pointer to position *pos* in buffer *c*.

**Returns**: a pointer to the *pos’* element of the buffer, `0` otherwise.

```
double* circular_element(circular* c,  size_t pos);
```

Since our type circular will need to allocate and deallocate space for the circular buffer, we will need to provide consistent functions for initialization and destruction of instances of that type. This functionality is provided by two pairs of functions:

##### circular.h

circular_init: Initialize a circular buffer *c* with maximally *max_len* elements.

Only use this function on an uninitialized buffer.

Each buffer that is initialized with this function must be destroyed with a call to circular_destroy.

```
circular* circular_init(circular* c, size_t max_len);
```

##### circular.h

circular_destroy: Destroy circular buffer *c*.

*c* must have been initialized with a call to circular_init

```
void circular_destroy(circular* c);
```

##### circular.h

circular_new: Allocate and initialize a circular buffer with maximally *len* elements.

Each buffer that is allocated with this function must be deleted with a call to circular_delete.

```
circular* circular_new(size_t len);
```

##### circular.h

circular_delete: Delete circular buffer *c*.

*c* must have been allocated with a call to circular_new

```
void circular_delete(circular* c);
```

The first pair is to be applied to existing objects. They receive a pointer to such an object and ensure that space for the buffer is allocated or freed. The first of the second pair creates an object and initializes it; the last destroys that object and then deallocates the memory space.

If we used regular array variables, the maximum number of elements that we could store in a circular would be fixed once we created such an object. We want to be more flexible so this limit can be raised or lowered by means of the circular_resize function and the number of elements can be queried with circular_getlength:

##### circular.h

circular_resize: Resize to capacity *max_len*.

```
circular* circular_resize(circular* c, size_t max_len);
```

##### circular.h

circular_getlength: Return the number of elements stored.

```
size_t circular_getlength(circular* c);
```

Then, with the function circular_element, it behaves like an array of **`double`**s: calling it with a position within the current length, we obtain the address of the element that is stored in that position.

The hidden definition of the structure is as follows:

##### **`circular.c`**

```
5   /** @brief the hidden implementation of the circular buffer type */
 6   struct circular {
 7     size_t start;    /**< Position of element 0 */ 
 8     size_t len;      /**< Number of elements stored */ 
 9     size_t max_len;  /**< Maximum capacity */ 
10     double* tab;     /**< Array holding the data */
11   };
```

The idea is that the pointer member tab will always point to an array object of length max_len. At a certain point in time the buffered elements will start at start, and the number of elements stored in the buffer is maintained in member len. The position inside the table tab is computed modulo max_len.

The following table symbolizes one instance of this circular data structure, with max_len=10, start`=2`, and len`=4`.

![](https://drek4537l1klr.cloudfront.net/gustedt/Figures/pg_210-01_alt.jpg)

We see that the buffer contents (the four numbers `6.0`, `7.7`, `81.0`, and `99.0`) are placed consecutively in the array object pointed to by tab.

The following scheme represents a circular buffer with the same four numbers, but the storage space for the elements wraps around.

![](https://drek4537l1klr.cloudfront.net/gustedt/Figures/pg_210-02_alt.jpg)

Initialization of such a data structure needs to call **malloc** to provide memory for the tab member. Other than that it is

##### **`circular.c`**

```
13   circular* circular_init(circular* c, size_t max_len) {
14     if (c) {
15       if (max_len) {
16         *c = (circular){
17           .max_len = max_len,
18           .tab = malloc(sizeof(double[max_len])),
19         };
20           // Allocation failed.
21         if (!c->tab) c->max_len = 0;
22       } else {
23         *c = (circular){ 0 };
24       }
25     }
26     return c;
27   }
```

Observe that this function always checks the pointer parameter c for validity. Also, it guarantees to initialize all other members to `0` by assigning compound literals in both branches of the conditional.

The library function **malloc** can fail for different reasons. For example, the memory system might be exhausted from previous calls to it, or the reclaimed size for allocation might just be too large. In a general-purpose system like the one you are probably using for your learning experience, such a failure will be rare (unless voluntarily provoked), but it still is a good habit to check for it.

##### Takeaway 13.3

**malloc** *indicates failure by returning a null pointer value.*

Destruction of such an object is even simpler: we just have to check for the pointer, and then we may **free** the tab member unconditionally.

##### **`circular.c`**

```
29   void circular_destroy(circular* c) {
30     if (c) {
31       free(c->tab);
32       circular_init(c, 0);
33     }
34   }
```

The library function **free** has the friendly property that it accepts a null parameter and does nothing in that case.

The implementation of some of the other functions uses an internal function to compute the “circular” aspect of the buffer. It is declared **`static`** so it is only visible for those functions and doesn’t pollute the identifier name space ([takeaway 9.8](/book/modern-c/chapter-9/ch09note10)).

##### **`circular.c`**

```
50   static size_t circular_getpos(circular* c, size_t pos) {
51     pos += c->start;
52     pos %= c->max_len;
53     return pos;
54   }
```

Obtaining a pointer to an element of the buffer is now quite simple.

##### **`circular.c`**

```
68   double* circular_element(circular* c, size_t pos) {
69     double* ret = 0;
70     if (c) {
71       if (pos < c->max_len) {
72         pos = circular_getpos(c, pos);
73         ret = &c->tab[pos];
74       }
75     }
76   return ret;
77   }
```

With all of that information, you should now be able to implement all but one of the function interfaces nicely.[[[Exs 2]](/book/modern-c/chapter-13/ch13fn-ex02)] The one that is more difficult is circular_resize. It starts with some length calculations and then treats the cases in which the request would enlarge or shrink the table. Here we have the naming convention of using o (old) as the first character of a variable name that refers to a feature before the change, and n (new) to its value afterward. The end of the function then uses a compound literal to compose the new structure by using the values found during the case analysis:

[Exs 2] Write implementations of the missing functions.

##### **circular.c**

```
92   circular* circular_resize(circular* c, size_t nlen) {
 93     if (c) {
 94       size_t len = c->len;
 95       if (len > nlen) return 0;
 96       size_t olen = c->max_len;
 97       if (nlen != olen) {
 98         size_t ostart = circular_getpos(c, 0);
 99         size_t nstart = ostart;
100         double* otab = c->tab;
101         double* ntab;
102         if (nlen > olen) {
```

##### **`circular.c`**

```
138         }
139         *c = (circular){
140           .max_len = nlen,
141           .start = nstart,
142           .len = len,
143           .tab = ntab,
144         };
145       }
146     }
147     return c;
148   }
```

Let us now try to fill the gap in the previous code and look at the first case of enlarging an object. The essential part of this is a call to **realloc**:

##### **`circular.c`**

```
103         ntab = realloc(c->tab, sizeof(double[nlen]));
104         if (!ntab) return 0;
```

For this call, **realloc** receives the pointer to the existing object and the new size the relocation should have. It returns either a pointer to the new object with the desired size or null. In the line immediately after, we check the latter case and terminate the function if it was not possible to relocate the object.

The function **realloc** has interesting properties:

- The returned pointer may or may not be the same as the argument. It is left to the discretion of the runtime system to determine whether the resizing can be performed in place (if there is space available behind the object, for example, or if a new object must be provided. But, regardless of that, even if the returned pointer is the same, the object is considered to be a new one (with the same data). That means in particular that all pointers derived from the original become invalid.
- If the argument pointer and the returned one are distinct (that is, the object has been copied), nothing has to be done (or even should be) with the previous pointer. The old object is taken care of.
- As far as possible, the existing content of the object is preserved:

- If the object is enlarged, the initial part of the object that corresponds to the previous size is left intact.
- If the object shrank, the relocated object has a content that corresponds to the initial part before the call.

- If `0` is returned (that is, the relocation request could not be fulfilled by the runtime system), the old object is unchanged. So, nothing is lost.

Now that we know the newly received object has the size we want, we have to ensure that tab still represents a circular buffer. If previously the situation was as in the first table, earlier (the part that corresponds to the buffer elements is contiguous), we have nothing to do. All data is nicely preserved.

If our circular buffer wrapped around, we have to make some adjustments:

##### **`circular.c`**

```
105         // Two separate chunks 
106         if (ostart+len > olen) {
107           size_t ulen = olen - ostart;
108           size_t llen = len - ulen;
109           if (llen <= (nlen - olen)) {
110             /* Copy the lower one up after the old end. */ 
111             memcpy(ntab + olen, ntab,
112                    llen*sizeof(double));
113           } else {
114             /* Move the upper one up to the new end. */ 
115             nstart = nlen - ulen;
116             memmove(ntab + nstart, ntab + ostart,
117                     ulen*sizeof(double));
118           }
119         }
```

The following table illustrates the difference in the contents between before and after the changes for the first subcase: the lower part finds enough space inside the part that was added:

![](https://drek4537l1klr.cloudfront.net/gustedt/Figures/pg_214-01_alt.jpg)

The other case, where the lower part doesn’t fit into the newly allocated part, is similar. This time, the upper half of the buffer is shifted toward the end of the new table:

![](https://drek4537l1klr.cloudfront.net/gustedt/Figures/pg_214-02_alt.jpg)

The handling of both cases shows a subtle difference, though. The first is handled with **memcpy**; the source and target elements of the copy operation can’t overlap, so using **memcpy** here is safe. For the other case, as we see in the example, the source and target elements may overlap, and thus the use of the less-restrictive **memmove** function is required.[[[Exs 3]](/book/modern-c/chapter-13/ch13fn-ex03)]

[Exs 3] Implement shrinking of the table: it is important to reorganize the table contents before calling **realloc**.

### 13.1.2. Ensuring consistency of dynamic allocations

As in both our code examples, calls to allocation functions such as **malloc**, **realloc**, and **free** should always come in pairs. This mustn’t necessarily be inside the same function, but in most cases simple counting of the occurrence of both should give the same number:

##### Takeaway 13.4

*For every allocation, there must be a* **free***.*

If not, this could indicate a *memory leak**C*: a loss of allocated objects. This could lead to resource exhaustion of your platform, showing itself in low performance or random crashes.

##### Takeaway 13.5

*For every* **free***, there must be a* **malloc***,* **calloc***,* **aligned_alloc***, or* **realloc***.*

But be aware that **realloc** can easily obfuscate simple counting of allocations: because if it is called with an existing object, it serves as deallocation (for the old object) and allocation (for the new one) at the same time.

The memory-allocation system is meant to be simple, and thus **free** is only allowed for pointers that have been allocated with **malloc** or that are null.

##### Takeaway 13.6

*Only call* **free** *with pointers as they are returned by* **malloc***,* **calloc***,* **aligned_alloc***, or* **realloc***.*

They *must not*

- Point to an object that has been allocated by other means (that is, a variable or a compound literal)
- Have been freed yet
- Only point to a smaller part of the allocated object.

Otherwise, your program will crash. Seriously, this will completely corrupt the memory of your program execution, which is one of the worst types of crashes you can have. Be careful.

## 13.2. Storage duration, lifetime, and visibility

We have seen in different places that visibility of an identifier and accessibility of the object to which it refers are not the same thing. As a simple example, take the variable(s) x in [listing 13.1](/book/modern-c/chapter-13/ch13ex10).

##### Listing 13.1. An example of shadowing with local variables

```
1     void squareIt(double* p) {
 2       *p *= *p;
 3     }
 4     int main(void) {
 5     double x = 35.0;
 6     double* xp = &x;
 7     {
 8       squareIt(&x);  /* Refers to double x */ 
 9       ...
10       int x = 0;     /* Shadow double x */ 
11       ...
12       squareIt(xp);  /* Valid use of double x */ 
13       ...
14     }
15     ...
16     squareIt(&x);    /* Refers to double x */ 
17     ...
18   }
```

Here, the visibility scope of the identifier x that is declared in line 5 starts from that line and goes to the end of the function **main**, but with a noticeable interruption: from line 10 to 14, this visibility is *shadowed**C* by another variable, also named x.

##### Takeaway 13.7

*Identifiers only have visibility inside their scope, starting at their declaration.*

##### Takeaway 13.8

*The visibility of an identifier can be shadowed by an identifier of the same name in a subordinate scope.*

We also see that the visibility of an identifier and the usability of the object it represents are not the same thing. First, the **`double`** x *object* is used by all calls to squareIt, although the identifier x is not visible at the point where the function is defined. Then, on line 12, we pass the address of the **`double`** x variable to the function squareIt, although the identifier is shadowed there.

Another example concerns declarations that are tagged with the storage class **`extern`**. These always designate an object of static storage duration that is expected to be defined at file scope;[[2](/book/modern-c/chapter-13/ch13fn02)] see [listing 13.2](/book/modern-c/chapter-13/ch13ex11).

2 In fact, such an object can be defined at file scope in another translation unit.

##### Listing 13.2. An example of shadowing with an `extern` variable

```
1   #include <stdio.h>
 2
 3   unsigned i = 1;
 4
 5   int main(void) {
 6     unsigned i = 2;        /* A new object */ 
 7     if (i) {
 8       extern unsigned i;   /* An existing object */ 
 9       printf("%u\n", i);
10     } else {
11       printf("%u\n", i);
12     }
13   }
```

This program has three declarations for variables named i, but only two definitions: the declaration and definition on line 6 shadows the one on line 3. In turn, declaration line 8 shadows line 6, but it refers to the same object as the object defined on line 3.[[[Exs 4]](/book/modern-c/chapter-13/ch13fn-ex04)]

[Exs 4] Which value is printed by this program?

##### Takeaway 13.9

*Every definition of a variable creates a new, distinct object.*

So in the following, the **`char`** arrays A and B identify distinct objects, with distinct addresses. The expression A `==` B *must* always be false:

1char const'e'n'd'\02char const'e'n'd'\03char constc"end4char constd"end5char conste"friend6char constfchar const'e'n'd'\07char constgchar const'e'n'd'\0But how many distinct array objects are there in total? It depends. The compiler has a lot of choices:

##### Takeaway 13.10

*Read-only object literals may overlap.*

In the previous example, we have three string literals and two compound literals. These are all object literals, and they are read-only: string literals are read-only by definition, and the two compound literals are **`const`**-qualified. Four of them have exactly the same base type and content ('e'`,` 'n`',` 'd`',` '\0'), so the four pointers c, d, f, and g may all be initialized to the same address of one **`char`** array. The compiler may even save more memory: this address may just be &`e[3]`, by using the fact that *end* appears at the end of *friend*.

As we have seen from these examples, the usability of an object not only is a lexical property of an identifier or of the position of definition (for literals), but also depends on the state of execution of the program. The *lifetime**C* of an object has a starting point and an end point:

##### Takeaway 13.11

*Objects have a lifetime outside of which they can’t be accessed.*

##### Takeaway 13.12

*Referring to an object outside of its lifetime has undefined behavior.*

How the start and end points of an object are defined depends on the tools we use to create it. We distinguish four different *storage durations**C* for objects in C: *static**C* when it is determined at compile time, *automatic**C* when it is automatically determined at runtime, *allocated**C*, when it is explicitly determined by function calls **malloc** and friends, and *thread**C* when it is bound to a certain thread of execution.

[Table 13.1](/book/modern-c/chapter-13/ch13table01) gives an overview of the complicated relationship between declarations and their *storage classes*, initialization, linkage, *storage duration*, and lifetime. Without going into too much detail for the moment, it shows that the usage of keywords and the underlying terminology are quite confusing.

##### Table 13.1. *Storage classes, scope, linkage of identifiers, and storage duration of the associated objects* *Tentative* indicates that a definition is implied only if there is no other definition with an initializer. *Induced* indicates that the linkage is internal if another declaration with internal linkage has been met prior to that declaration; otherwise, it is external.[(view table figure)](https://drek4537l1klr.cloudfront.net/gustedt/HighResolutionFigures/table_13-1.png)

| Class | Scope | Definition | Linkage | Duration | Lifetime |
| --- | --- | --- | --- | --- | --- |
| Initialized | File | Yes | External | Static | Whole execution |
| **extern**, initialized | File | Yes | External | Static | Whole execution |
| Compound literal | File | Yes | N/A | Static | Whole execution |
| String literal | Any | Yes | N/A | Static | Whole execution |
| **static**, initialized | Any | Yes | Internal | Static | Whole execution |
| Uninitialized | File | Tentative | External | Static | Whole execution |
| **extern**, uninitialized | Any | No | Induced | Static | Whole execution |
| **static**, uninitialized | Any | Tentative | Internal | Static | Whole execution |
| **thread_local** | File | Yes | External | Thread | Whole thread |
| **extern** **thread_local** | Any | No | External | Thread | Whole thread |
| **static** **thread_local** | Any | Yes | internal | Thread | Whole thread |
| Compound literal |  |  | N/A |  |  |
| Non-VLA |  |  | None |  |  |
| Non-VLA, **auto** | Block | Yes | None | Automatic | Block of definition |
| **register** |  |  | None |  |  |
| VLA | Block | Yes | None | Automatic | From definition to end of block |
| Function **return** with array | Block | Yes | None | Automatic | To the end of expression |

First, unlike what the name suggests, the *storage class* **`extern`** may refer to identifiers with external or internal *linkage*.[[3](/book/modern-c/chapter-13/ch13fn03)] Here, in addition to the compiler, an identifier with linkage is usually managed by another external program, the *linker**C*. Such an identifier is initialized at startup of the program, even before it enters **main**, and the linker ensures that. Identifiers that are accessed from different object files need *external* linkage so they all access the same object or function, and so the linker is able to establish the correspondence.

3 Note that linkage is a property of identifiers, not of the objects they represent.

Important identifiers with external linkage that we have seen are the functions of the C library. They reside in a system *library**C*, usually called something like `libc.so`, and not in the object file you created. Otherwise, a global, file scope, object, or function that has no connection to other object files should have *internal* linkage. All other identifiers have *no* linkage.[[4](/book/modern-c/chapter-13/ch13fn04)]

4 A better keyword for **`extern`** would perhaps be **`linkage`**.

Then, static *storage duration* is not the same as declaring a variable with the *storage class* **`static`**. The latter is merely enforcing that a variable or function has internal linkage. Such a variable may be declared in file scope (global) or in block scope (local). [[5](/book/modern-c/chapter-13/ch13fn05)]You probably have not yet called the linker of your platform explicitly. Usually, its execution is hidden behind the compiler frontend that you are calling, and a dynamic linker may only kick in as late as program startup without being noticed.

5 A better keyword for **`static`** in this context would perhaps be **`internal`**, with the understanding that any form of linkage implies static storage duration.

For the first three types of storage duration, we have seen a lot of examples. Thread storage duration (**`_Thread_local`** or **`thread_local`**) is related to C’s thread API, which we will see later, in [chapter 18](/book/modern-c/chapter-18/ch18).

Allocated storage duration is straightforward: the lifetime of such an object starts from the corresponding call to **malloc**, **calloc**, **realloc**, or **aligned_alloc** that creates it. It ends with a call to **free** or **realloc** that destroys it, or, if no such call is issued, with the end of the program execution.

The two other cases of storage duration need additional explanation, and so we will discuss them in more length next.

### 13.2.1. Static storage duration

Objects with static storage duration can be defined two ways:

- Objects that are *defined* in file scope. Variables and compound literals can have that property.
- Variables that are declared inside a function block and that have the storage class specifier **`static`**.

Such objects have a lifetime that is the entire program execution. Because they are considered alive before any application code is executed, they can only be initialized with expressions that are known at compile time or can be resolved by the system’s process startup procedure. Here’s an example:

1doubleA2doublep3double4intmainvoid5static double6This defines four objects of static storage duration, those identified with A, p, and B, and a compound literal defined in line 3. Three of them have type **`double`**, and one has type **`double`**`*`.

All four objects are properly initialized from the start; three of them are initialized explicitly, and B is initialized implicitly with `0`.

##### Takeaway 13.13

*Objects with static storage duration are always initialized.*

The initialization of p is an example that needs a bit more magic than the compiler itself can offer. It uses the address of another object. Such an address can usually only be computed when the execution starts. This is why most C implementations need the concept of a linker, as we discussed earlier.

The example of B shows that an object with a lifetime that is the entire program execution isn’t necessarily visible in the entire program. The **`extern`** example also shows that an object with static storage duration that is defined elsewhere can become visible inside a narrow scope.

### 13.2.2. Automatic storage duration

This is the most complicated case: rules for automatic storage duration are implicit and therefore need the most explanation. There are several cases of objects that can be defined explicitly or implicitly that fall into this category:

- Any block-scope variables that are not declared **`static`**, that are declared as **`auto`** (the default) or **`register`**
- Block-scope compound literals
- Some temporary objects that are returned by function calls

The simplest and most current case for the lifetime of automatic objects is when the object is not a variable-length array (VLA).

##### Takeaway 13.14

*Unless they are VLA or temporary objects, automatic objects have a lifetime corresponding to the execution of their block of definition.*

That is, most local variables are created when program execution enters the scope in which they are defined, and they are destroyed when it leaves that scope. But, because of recursion, several *instances**C* of the same object may exist at the same time:

##### Takeaway 13.15

*Each recursive call creates a new local instance of an automatic object.*

Objects with automatic storage duration have a big advantage for optimization: the compiler usually sees the full usage of such a variable and, with this information, is able to decide if it may alias. This is where the difference between the **`auto`** and **`register`** variables comes into play:

##### Takeaway 13.16

*The* *`&`* *operator is not allowed for variables declared with* **`register`***.*

With that, we can’t inadvertently take the address of a **`register`** variable ([takeaway 12.12](/book/modern-c/chapter-12/ch12note12)). As a simple consequence, we get:

##### Takeaway 13.17

*Variables declared with* **`register`** *can’t alias.*

So, with **`register`** variable declarations, the compiler can be forced to tell us where we are taking the address of a variable, so we may identify spots that may have some optimization potential. This works well for all variables that are not arrays and that contain no arrays.

##### Takeaway 13.18

*Declare local variables that are not arrays in performance-critical code as* **`register`***.*

Arrays play a particular role here because they decay to the address of their first element in almost all contexts. So, for arrays, we need to be able to take addresses.

##### Takeaway 13.19

*Arrays with storage class* **`register`** *are useless.*

There is another case where the presence of arrays needs special treatment. Some return values of functions can really be chimeras: objects with *temporary lifetime*. As you know now, functions normally return values and as such values are not addressable. But if the return type *contains* an array type, we must be able to take the address implicitly, so the `[]` operator is well defined. Therefore, the following function return is a temporary object, of which we may implicitly take an address by using the member designator .or`y[0]`:

1structdemounsignedory2structdemo memvoid34printf"mem().ory[0] is %u\n"memoryThe only reason objects with temporary lifetime exist in C is to be able to access members of such a function return value. Don’t use them for anything else.

##### Takeaway 13.20

*Objects of temporary lifetime are read-only.*

##### Takeaway 13.21

*Temporary lifetime ends at the end of the enclosing full expression.*

That is, their life ends as soon as the evaluation of the expression in which they occur is terminated. For example, in the previous example, the temporary object ceases to exist as soon as the argument for **printf** is constructed. Compare this to the definition of a compound literal: a compound literal would live on until the enclosing scope of the **printf** terminates.

## 13.3. Digression: using objects "before” their definition

The following chapter goes into more detail about how automatic objects spring to life (or not). It is a bit tough, so if you are not up to it right now, you might skip it and come back to it later. It will be needed in order to understand [section 13.5](/book/modern-c/chapter-13/ch13lev1sec5) about concrete machine models, but that section is a digression, too. Also, it introduces the new features **`goto`** and labels, which we need later, in [section 14.5](/book/modern-c/chapter-14/ch14lev1sec5) for handling errors.

Let us get back to the rule for the lifetime of ordinary automatic objects ([takeaway 13.14](/book/modern-c/chapter-13/ch13note16)). It is quite particular, if you think about it: the lifetime of such an object starts when its scope of definition is entered, not, as one would perhaps expect, later, when its definition is first encountered during execution.

To note the difference, let us look at [listing 13.3](/book/modern-c/chapter-13/ch13ex12), which is a variant of an example that can be found in the C standard document.

##### Listing 13.3. A contrived example for the use of a compound literal

```
3   void fgoto(unsigned n) {
 4     unsigned j = 0;
 5     unsigned* p = 0;
 6     unsigned* q;
 7    AGAIN:
 8     if (p) printf("%u: p and q are %s, *p is %u\n",
 9                   j,
10                   (q == p) ? "equal" : "unequal",
11                   *p);
12     q = p;
13     p = &((unsigned){ j, });
14     ++j;
15     if (j <= n) goto AGAIN;
16   }
```

We will be particularly interested in the lines printed if this function is called as fgot`o(2)`. On my computer, the output looks like this:

##### `Terminal`

```
0   1: p and q are unequal, *p is 0
 1   2: p and q are equal, *p is 1
```

Admittedly, this code is a bit contrived. It uses a new construct that we haven’t yet seen in action, **`goto`**. As the name indicates, this is a *jump statement**C*. In this case, it instructs the computer to continue execution at *label**C* **`AGAIN`**. Later, we will see contexts where using **`goto`** makes a bit more sense. The demonstrative purpose here is just to jump over the definition of the compound literal.

So, let us look at what happens with the **printf** call during execution. For n `== 2`, execution meets the corresponding line three times; but because p is `0` initially, at the first passage, the **printf** call itself is skipped. The values of our three variables in that line are

| j | p | q | **printf** |
| --- | --- | --- | --- |
| 0 | 0 | Undetermined | Skipped |
| 1 | Addr of literal of *j* = 0 | 0 | printed |
| 2 | Addr of literal of *j* = 1 | Addr of literal of *j* = 0 | printed |

Here we see that for `j==2` pointers, p and q hold addresses that are obtained at different iterations. So why, then, does my printout say that both addresses are equal? Is this just a coincidence? Or is there undefined behavior because I am using the compound literal lexically at a place before it is defined?

The C standard prescribes that the output shown here *must* be produced. In particular, for j`==2`, the values of p and q are equal and valid, and the value of the object they are pointing to is `1`. Or, stated another way, in this example, the use of `*`p is well defined, although lexically the evaluation of `*`p precedes the definition of the object. Also, there is exactly one such compound literal, and therefore the addresses are equal for `j==2`.

##### Takeaway 13.22

*For an object that is not a VLA, lifetime starts when the scope of the definition is entered, and it ends when that scope is left.*

##### Takeaway 13.23

*Initializers of automatic variables and compound literals are evaluated each time the definition is met.*

In this example, the compound literal is visited three times and set to the values `0`, `1`, and `2` in turn.

For a VLA, the lifetime is given by a different rule.

##### Takeaway 13.24

*For a VLA, lifetime starts when the definition is encountered and ends when the visibility scope is left.*

So for a VLA, our strange trick of using **`goto`** would not be valid: we are not allowed to use the pointer to a VLA in code that precedes the definition, even if we still are inside the same block. The reason for this special treatment of VLAs is that their size is a runtime property and therefore the space for it simply can’t be allocated when the block of the declaration is entered.

## 13.4. Initialization

In [section 5.5](/book/modern-c/chapter-5/ch05lev1sec5), we discussed the importance of initialization. It is crucial to guarantee that a program starts in a well-defined state and stays so throughout execution. The storage duration of an object determines how it is initialized.

##### Takeaway 13.25

*Objects of static or thread-storage duration are initialized by default.*

As you probably recall, such a default initialization is the same as initializing all members of an object by `0`. In particular, default initialization works well for base types that might have a nontrivial representation for their `0` value: namely pointers and floating point types.

For other objects, automatic or allocated, we must do something.

##### Takeaway 13.26

*Objects of automatic or allocated storage duration must be initialized explicitly.*

The simplest way to achieve initialization are initializers, which put variables and compound literals in a well-defined state as soon as they become visible. For arrays that we allocate as VLA, or through dynamic allocation, this is not possible, so we have to provide initialization through assignment. In principle, we could do this manually each time we allocate such an object, but such code becomes difficult to read and to maintain, because the initialization parts may visually separate definition and use. The easiest way to avoid this is to encapsulate initialization into functions:

##### Takeaway 13.27

*Systematically provide an initialization function for each of your data types.*

Here, the emphasis is on *systematically*: you should have a consistent convention for how such initializing functions should work and how they should be named. To see that, let us go back to rat_init, the initialization function for our rat data type. It implements a specific API for such functions:

- For a type toto, the initialization function is named toto_init.
- The first argument to such a _init function is the pointer to the object that is to be initialized.
- If that pointer to object is null, the function does nothing.
- Other arguments can be provided to pass initial values for certain members.
- The function returns the pointer to the object it received or `0` if an error occurred.

With such properties, such a function can be used easily in an initializer for a pointer:

```
rat const* myRat = rat_init(malloc(sizeof(rat)), 13, 7);
```

Observe that this has several advantages:

- If the call to **malloc** fails by returning `0`, the only effect is that myRat is initialized to `0`. Thus myRat is always in a well-defined state.
- If we don’t want the object to be changed afterward, we can qualify the pointer target as **`const`** from the start. All modification of the new object happens inside the initialization expression on the right side.

Since such initialization can then appear in many places, we can also encapsulate this into another function:

```
1   rat* rat_new(long long numerator,
 2                unsigned long long denominator) {
 3     return rat_init(malloc(sizeof(rat)),
 4                     numerator,
 5                     denominator);
 6   }
```

The initialization using that function becomes

```
rat const* myRat = rat_new(13, 7);
```

Macro addicts like myself can even easily define a type-generic macro that does such an encapsulation once and for all:

```
#define P99_NEW(T, ...) T ## _init(malloc(sizeof(T)), __VA_ARGS__)
```

With this, we could have written the earlier initialization as

```
rat const* myRat = P99_NEW(rat, 13, 7);
```

This has the advantage of being at least as readable as the rat_new variant, but it avoids the additional declaration of such a function for all types that we define.

Such macro definitions are frowned upon by many, so some projects probably will not accept this as a general strategy, but you should at least be aware that the possibility exists. It uses two features of macros that we have not yet encountered:

- Concatenation of tokens is achieved with the **`##`** operator. Here, T **`##`** _init melds the argument T and _init into one token: with rat, this produces rat_init; with toto, this produces toto_init.
- The construct `...` provides an argument list of variable length. The whole set of arguments that is passed after the first is accessible inside the macro expansion as **`__VA_ARGS__`**. That way, we can pass any number of arguments as required by the corresponding _init function to P99_NEW.

If we have to initialize arrays by means of a **`for`** loop, things get even uglier. Here also it is easy to encapsulate with a function:

```
1   rat* rat_vinit(size_t n, rat p[n]) {
 2     if (p)
 3       for (size_t i = 0; i < n; ++i)
 4         rat_init(p+i, 0, 1);
 5     return p;
 6   }
```

With such a function, again, initialization becomes straightforward:

```
rat* myRatVec = rat_vinit(44, malloc(sizeof(rat[44])));
```

Here, encapsulation into a function is really better, since repeating the size may easily introduce errors:

```
1   rat* rat_vnew(size_t size) {
 2     return rat_vinit(size, malloc(sizeof(rat[size])));
 3   }
```

## 13.5. Digression: a machine model

Up to now, we mostly argued about C code from within, using the internal logic of the language to describe what was going on. This chapter is an optional digression that deviates from that: it is a glimpse into the machine model of a concrete architecture. We will see more in detail how a simple function is translated into this model and, in particular, how automatic storage duration is realized. If you really can’t bear it yet, you may skip it for now. Otherwise, remember not to panic, and dive in.

Traditionally, computer architectures were described with the von Neumann model.[[6](/book/modern-c/chapter-13/ch13fn06)] In this model, a processing unit has a finite number of hardware *registers* that can hold integer values, a *main memory* that holds the program as well as data and that is linearly addressable, and a finite *instruction set* that describes the operations that can be done with these components.

6 Invented around 1945 by J. Presper Eckert and John William Mauchly for the ENIAC project; first described by John von Neumann (1903 – 1957, also known as Neumann János Lajos and Johann Neumann von Margitta), one of the pioneers of modern science, in von Neumann [[1945](/book/modern-c/bibliography/bib20)].

The intermediate programming languages that are usually used to describe machine instructions as they are understood by your CPU are called *assembler**C*, and they still pretty much build upon the von Neumann model. There is not one unique assembler language (like C, which is valid for all platforms) but an entire set of *dialects* that take different particularities into account: of the CPU, the compiler, or the operating system. The assembler that we use here is the one used by the `gcc` compiler for the `x86_64` processor architecture.[[[Exs 5]](/book/modern-c/chapter-13/ch13fn-ex05)] If you don’t know what that means, don’t worry; this is just an example of one such architecture.

[Exs 5] Find out which compiler arguments produce assembler output for your platform.

[Listing 13.4](/book/modern-c/chapter-13/ch13ex14) shows an assembler printout for the function fgoto from [listing 13.3](/book/modern-c/chapter-13/ch13ex12). Such assembler code operates with *instructions**C* on hardware registers and memory locations. For example, the line **`movl $`**`0, -16(`**`%`****`rbp`**`)` stores (*moves*) the value `0` to the location in memory that is `16` bytes below the one indicated by register **`%`****`rbp`**. The assembler program also contains *labels**C* that identify certain points in the program. For example, **`fgoto`** is the *entry point**C* of the function, and **`.L_AGAIN`** is the counterpart in assembler to the **`goto`** label **`AGAIN`** in C.

As you probably have guessed, the text on the right after the **`#`** character are comments that try to link individual assembler instructions to their C counterparts.

##### Listing 13.4. An assembler version of the **`fgoto`** function

```
10           .type   fgoto, @function
11   fgoto:
12           pushq   %rbp               # Save base pointer 
13           movq    %rsp, %rbp         # Load stack pointer 
14           subq    $48, %rsp          # Adjust stack pointer 
15           movl    %edi, -36(%rbp)    # fgoto#0 => n 
16           movl    $0, -4(%rbp)       # init j 
17           movq    $0, -16(%rbp)      # init p 
18   .L_AGAIN:
19           cmpq    $0, -16(%rbp)      # if (p)
20           je       .L_ELSE
21           movq    -16(%rbp), %rax    #  p ==> rax
22           movl    (%rax), %edx       # *p ==> edx
23           movq    -24(%rbp), %rax    # (   == q)?
24           cmpq    -16(%rbp), %rax    # (p  ==  )?
25           jne      .L_YES
26           movl     $.L_STR_EQ, %eax  # Yes 
27           jmp     .L_NO
28   .L_YES:
29           movl    $.L_STR_NE, %eax   # No 
30   .L_NO:
31           movl    -4(%rbp), %esi     # j     ==> printf#1
32           movl    %edx, %ecx         # *p    ==> printf#3
33           movq    %rax, %rdx         # eq/ne ==> printf#2
34           movl    $.L_STR_FRMT, %edi # frmt  ==> printf#0
35           movl    $0, %eax           # clear eax
36           call    printf
37   .L_ELSE:
38           movq    -16(%rbp), %rax    # p ==|
39           movq    %rax, -24(%rbp)    #      ==> q 
40           movl    -4(%rbp), %eax     # j ==|
41           movl    %eax, -28(%rbp)    #      ==> cmp_lit 
42           leaq    -28(%rbp), %rax    # &cmp_lit ==|
43           movq    %rax, -16(%rbp)    #             ==> p 
44           addl    $1, -4(%rbp)       # ++j 
45           movl    -4(%rbp), %eax     # if (j 
46           cmpl    -36(%rbp), %eax    #       <= n)
47           jbe     .L_AGAIN           # goto AGAIN
48           leave                      # Rearange stack 
49           ret                        # return statement
```

This assembler function uses hardware registers **`%eax`**, **`%ecx`**, **`%edi`** **`%edx`**, **`%esi`**, **`%rax`**, **`%rbp`**, **`%`****`rcx`**, **`%rdx`**, and **`%rsp`**. This is much more than the original von Neumann machine had, but the main ideas are still present: we have some general-purpose registers that are used to represent values of the state of a program’s execution. Two others have very special roles: **`%rbp`** (base pointer) and **`%rsp`** (stack pointer).

The function disposes of a reserved area in memory, often called *The Stack**C*, that holds its local variables and compound literals. The “upper” end of that area is designated by the **`%rbp`** register, and the objects are accessed with negative offsets relative to that register. For example, the variable n is found from position `-36` before **`%rbp`** encoded as `-36(`**`%`****`rbp`**`)`. The following table represents the layout of this memory chunk that is reserved for function **`fgoto`** and the values that are stored there at three different points of the execution of the function.

![](https://drek4537l1klr.cloudfront.net/gustedt/Figures/pg227_01_alt.jpg)

This example is of particular interest for learning about automatic variables and how they are set up when execution enters the function. On this particular machine, when entering **`fgoto`**, three registers hold information for this call: **`%edi`** holds the function argument, n; **`%`****`rbp`** points to the base address of the calling function; and **`%rsp`** points to the top address in memory where this call to **`fgoto`** may store its data.

Now let us consider how the above assembler code ([listing 13.4](/book/modern-c/chapter-13/ch13ex14)) sets up things. Right at the start, **`fgoto`** executes three instructions to set up its “world” correctly. It saves **`%rbp`** because it needs this register for its own purpose, it moves the value from **`%rsp`** to **`%rbp`**, and then it decrements **`%rsp`** by `48`. Here, `48` is the number of bytes the compiler has computed for all automatic objects that the **`fgoto`** needs. Because of this simple type of setup, the space reserved by that procedure is not initialized but filled with garbage. In the three following instructions, three of the automatic objects are then initialized (n, j, and p), but others remain uninitialized until later.

After this setup, the function is ready to go. In particular, it can easily call another function: **`%`****`rsp`** now points to the top of a new memory area that a called function can use. This can be seen in the middle part, after the label .L_NO. This part implements the call to **printf**: it stores the four arguments the function is supposed to receive in registers **`%edi`**, **`%esi`**, **`%ecx`**, **`%`****`rdx`**, in that order; clears **`%eax`**; and then calls the function.

To summarize, the setup of a memory area for the automatic objects (without VLA) of a function only needs a few instructions, regardless of how many automatic objects are effectively used by the function. If the function had more, the magic number `48` would need to be modified to the new size of the area.

As a consequence of the way this is done,

- Automatic objects are usually available from the start of a function or scope.
- Initialization of automatic *variables* is not enforced.

This does a good job of mapping the rules for the lifetime and initialization of automatic objects in C.

The earlier assembler output is only half the story, at most. It was produced without optimization, just to show the principle assumptions that can be made for such code generation. When using optimization, the as-if Rule ([takeaway 5.8](/book/modern-c/chapter-5/ch05note08)) allows us to reorganize the code substantially. With full optimization, my compiler produces something like [listing 13.5](/book/modern-c/chapter-13/ch13ex15).

##### Listing 13.5. An optimized assembler version of the **`fgoto`** function

```
12           .type    fgoto, @function
13   fgoto:
14           pushq    %rbp              # Save base pointer 
15           pushq    %rbx              # Save rbx register
16           subq     $8, %rsp          # Adjust stack pointer 
17           movl    %edi, %ebp         # fgoto#0 => n 
18           movl     $1, %ebx          # init j, start with 1
19           xorl    %ecx, %ecx         # 0    ==> printf#3
20           movl    $.L_STR_NE, %edx   # "ne" ==> printf#2
21           testl    %edi, %edi        # if (n > 0)
22           jne    .L_N_GT_0
23           jmp    .L_END
24   .L_AGAIN:
25           movl    %eax, %ebx         # j+1  ==> j 
26   .L_N_GT_0:
27           movl    %ebx, %esi         # j    ==> printf#1
28           movl    $.L_STR_FRMT, %edi # frmt ==> printf#0
29           xorl    %eax, %eax         # Clear eax
30           call    printf
31           leal    1(%rbx), %eax      # j+1  ==> eax
32           movl    $.L_STR_EQ, %edx   # "eq" ==> printf#2
33           movl    %ebx, %ecx         # j    ==> printf#3
34           cmpl    %ebp, %eax         # if (j <= n)
35           jbe     .L_AGAIN           # goto AGAIN
36   .L_END:
37           addq    $8, %rsp           # Rewind stack 
38           popq    %rbx               # Restore rbx
39           popq    %rbp               # Restore rbp
40           ret                        # return statement
```

As you can see, the compiler has completely restructured the code. This code just reproduces the *effects* that the original code had: its output is the same as before. But it doesn’t use objects in memory, doesn’t compare pointers for equality, and has no trace of the compound literal. For example, it doesn’t implement the iteration for `j=0` at all. This iteration has no effect, so it is simply omitted. Then, for the other iterations, it distinguishes a version with `j=1`, where the pointers p and q of the C program are known to be different. Then, the general case has to increment j and to set up the arguments for **printf** accordingly.[[[Exs 6]](/book/modern-c/chapter-13/ch13fn-ex06)][[[Exs 7]](/book/modern-c/chapter-13/ch13fn-ex07)]

[Exs 6] Using the fact that p is assigned the same value over and over again, write a C program that gets closer to what the optimized assembler version looks like.

[Exs 7] Even the optimized version leaves room for improvement: the inner part of the loop can still be shortened. Write a C program that explores this potential when compiled with full optimization.

All we have seen here is code that doesn’t use VLA. These change the picture, because the trick that simply modifies **`%rsp`** with a constant doesn’t work if the needed memory is not a constant size. For a VLA, the program has to compute the size during execution from the actual values of the bounds of the VLA, has to adjust **`%rsp`** accordingly there, and then it has to undo that modification of **`%rsp`** once execution leaves the scope of the definition of the VLA. So here the value of adjustment for **`%rsp`** cannot be computed at compile time, but must be determined during the execution of the program.

## Summary

- Storage for a large number of objects or for objects that are large in size can be allocated and freed dynamically. We have to keep track of this storage carefully.
- Identifier visibility and storage duration are different things.
- Initialization must be done systematically with a coherent strategy for each type.
- C’s allocation strategy for local variables maps well to low-level handling of function stacks.

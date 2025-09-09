# Chapter 11. Pointers

### This chapter covers

- Introduction to pointer operations
- Using pointers with structs, arrays, and functions

Pointers are the first real hurdle to a deeper understanding of C. They are used in contexts where we have to be able to access objects from different points in the code, or where data is structured dynamically on the fly.

The confusion of inexperienced programmers between pointers and arrays is notorious, so be warned that you might encounter difficulties in getting the terms correct. On the other hand, pointers are one of the most important features of C. They are a big plus to help us abstract from the bits and odds of a particular platform and enable us to write portable code. So please, equip yourself with patience when you work through this chapter, because it is crucial for the understanding of most of the rest of this book.

The term *pointer**C* stands for a special derived type construct that “points” or “refers” to something. We have seen the syntax for this construct, a type (the *referenced type**C*) that is followed by a `*` character. For example, p0 is a pointer to a **`double`**:

```
double* p0;
```

The idea is that we have one variable (the pointer) that points to the memory of another object:

![](https://drek4537l1klr.cloudfront.net/gustedt/Figures/pg_169.jpg)

An import distinction that we will have to make throughout this chapter is between the pointer (on the left of the arrow) and the unnamed object that is pointed to (on the right).

Our first usage of a pointer will be to break the barrier between the code of the caller of a function and the code inside a function, and thus allow us to write functions that are *not* pure. This example will be a function with this prototype:

```
void double_swap(double* p0, double* p1);
```

Here we see two function arguments that “point” to objects of type **`double`**. In the example, the function double_swap is supposed to interchange (*swap*) the contents of these two objects. For example, when the function is called, p0 and p1 could be pointing to **`double`** variables d0 and d1, respectively, that are defined by the caller:

![](https://drek4537l1klr.cloudfront.net/gustedt/Figures/pg_170-01_alt.jpg)

By receiving information about two such objects, the function double_swap can effectively change the contents of the two **`double`** objects without changing the pointers themselves:

![](https://drek4537l1klr.cloudfront.net/gustedt/Figures/pg_170-02_alt.jpg)

Using pointers, the function will be able to apply the change directly to the variables of the calling function; a pure function without pointers or arrays would not be able to do this.

In this chapter, we will go into the details of different operations with pointers ([section 11.1](/book/modern-c/chapter-11/ch11lev1sec1)) and specific types for which pointers have particular properties: structures ([section 11.2](/book/modern-c/chapter-11/ch11lev1sec2)), arrays ([section 11.3](/book/modern-c/chapter-11/ch11lev1sec3)), and functions ([section 11.4](/book/modern-c/chapter-11/ch11lev1sec4)).

## 11.1. Pointer operations

Pointers are an important concept, so there are several C language operations and features just for them. Most importantly, specific operators allow us to deal with the “pointing-to” and “pointed-to” relation between pointers and the objects to which they point ([section 11.1.1](/book/modern-c/chapter-11/ch11lev2sec1)). Also, pointers are considered *scalars**C*: arithmetic operations are defined for them, offset additions ([section 11.1.2](/book/modern-c/chapter-11/ch11lev2sec2)) and subtractions ([section 11.1.3](/book/modern-c/chapter-11/ch11lev2sec3)); they have state ([section 11.1.4](/book/modern-c/chapter-11/ch11lev2sec4)); and they have a dedicated “null” state ([section 11.1.5](/book/modern-c/chapter-11/ch11lev2sec5)).

### 11.1.1. Address-of and object-of operators

If we have to perform tasks that can’t be expressed with pure functions, things get more involved. We have to poke around in objects that are not variables of the function. Pointers are a suitable abstraction to do this.

So, let us use the function double_swap from earlier to swap the contents of two **`double`** objects d0 and d1. For the call, we use the unary *address-of**C* operator *“**`&`**”*. It allows us to refer to an object through its *address**C*. A call to our function could look like this:

```
double_swap(&d0, &d1);
```

The type that the address-of operator returns is a *pointer type**C* and can be specified with the `*` notation that we have seen. An implementation of the function could look like this:

```
void double_swap(double* p0, double* p1) {
  double tmp = *p0;
  *p0 = *p1;
  *p1 = tmp;
}
```

Inside the function, pointers p0 and p1 hold the addresses of the objects on which the function is supposed to operate: in our example, the addresses of d0 and d1. But the function knows nothing about the names of the two variables d0 and d1; it only knows p0 and p1.

![](https://drek4537l1klr.cloudfront.net/gustedt/Figures/pg_171-01_alt.jpg)

To access them, another construct that is the inverse of the address-of operator is used: the unary *object-of**C* operator *“**`*`**”*: `*`p0 then is the object corresponding to the first argument. With the previous call, that would be d0, and similarly `*`p1 is the object d1.[[[Exs 1]](/book/modern-c/chapter-11/ch11fn-ex01)]

[Exs 1] Write a function that receives pointers to three objects and that shifts the values of these objects cyclically.

![](https://drek4537l1klr.cloudfront.net/gustedt/Figures/pg_171-02_alt.jpg)

Please note that the `*` character plays two different roles in the definition of double_swap. In a declaration, it creates a new type (a pointer type), whereas in an expression it *dereferences**C* the object to which a pointer *refers**C*. To help distinguish these two usages of the same symbol, we usually flush the `*` to the left with no blanks in between if it modifies a type (such as **`double`**`*`) and to the right if it dereferences a pointer (`*`p0).

Remember from [section 6.2](/book/modern-c/chapter-6/ch06lev1sec2) that in addition to holding a valid address, pointers may also be null or indeterminate.

##### Takeaway 11.1

*Using* *`*`* *with an indeterminate or null pointer has undefined behavior.*

In practice, though, both cases will usually behave differently. The first might access a random object in memory and modify it. Often this leads to bugs that are difficult to trace because it will poke into objects it is not supposed to. The second, if the pointer is null, will manifest early during development and nicely crash our program. Consider this to be a feature.

### 11.1.2. Pointer addition

We already have seen that a valid pointer holds the address of an object of its reference type, but actually C assumes more than that:

##### Takeaway 11.2

*A valid pointer refers to the first element of an array of the reference type.*

Or, in other words, a pointer may be used to refer not only to one instance of the reference type, but also to an array of an unknown length *n*.

![](https://drek4537l1klr.cloudfront.net/gustedt/Figures/pg_171-03.jpg)

This entanglement between the concept of pointers and arrays is taken an important step further in the syntax. In fact, for the specification of the function double_swap, we wouldn’t even need the pointer notation. In the notation we have used so far, it can equally be written as

```
void double_swap(double p0[static 1], double p1[static 1]) {
  double tmp = p0[0];
  p0[0] = p1[0];
  p1[0] = tmp;
}
```

Both the use of array notation for the interface and the use of `[0]` to access the first element are simple *rewrite operations**C* that are built into the C language. We will see more of this later.

Simple additive arithmetic allows us to access the following elements of this array. This function sums all elements of an array:

```
double sum0(size_t len, double const* a) {
  double ret = 0.0;
  for (size_t i = 0; i < len; ++i) {
    ret += *(a + i);
  }
  return ret;
}
```

Here, the expression `a`+i is a pointer that points to the *i*th element in the array:

![](https://drek4537l1klr.cloudfront.net/gustedt/Figures/pg_172_alt.jpg)

Pointer addition can be done in different ways, so the following functions sum up the array in exactly the same order:

```
double sum1(size_t len, double const* a) {
  double ret = 0.0;
  for (double const* p = a; p < a+len; ++p) {
    ret += *p;
  }
  return ret;
}double sum2(size_t len, double const* a) {
  double ret = 0.0;
  for (double const*const aStop = a+len; a < aStop; ++a) {
    ret += *a;
  }
  return ret;
}
```

In iteration *i* of function sum1, we have the following picture:

![](https://drek4537l1klr.cloudfront.net/gustedt/Figures/pg_173-01_alt.jpg)

The pointer p walks through the elements of the array until it is greater than or equal to a`+`len, the first pointer value that lies beyond the array.

For function sum2, we have the following picture:

![](https://drek4537l1klr.cloudfront.net/gustedt/Figures/pg_173-02_alt.jpg)

Here, a refers to the *i*th element of the array. The 0th element is not referenced again inside the function, but the information about the end of the array is kept in the variable aStop.

These functions can then be called analogously to the following:

```
double A[7] = { 0, 1, 2, 3, 4, 5, 6, };
double s0_7 = sum0(7, &A[0]);    // For the whole
double s1_6 = sum0(6, &A[1]);    // For the last 6
double s2_3 = sum0(3, &A[2]);    // For the 3 in the middle
```

Unfortunately, there is no way to know the length of the array that is hidden behind a pointer, so we have to pass it as a parameter into the function. The trick with **`sizeof`**, which we saw in [section 6.1.3](/book/modern-c/chapter-6/ch06lev2sec3), doesn’t work.

##### Takeaway 11.3

*The length of an array object cannot be reconstructed from a pointer.*

So here, we see a first important difference from arrays.

##### Takeaway 11.4

*Pointers are not arrays.*

If we pass arrays through pointers to a function, it is important to retain the real length of the array. This is why we prefer the array notation for pointer interfaces throughout this book:

```
double sum0(size_t len, double const a[len]);
double sum1(size_t len, double const a[len]);
double sum2(size_t len, double const a[len]);
```

These specify exactly the same interfaces as shown earlier, but they clarify to the casual reader of the code that a is expected to have len elements.

### 11.1.3. Pointer subtraction and difference

Pointer arithmetic we have discussed so far concerned addition of an integer and a pointer. There is also an inverse operation that can subtract an integer from a pointer. If we wanted to visit the elements of the array downward, we could use this:

```
double sum3(size_t len, double const* a) {
  double ret = 0.0;
  double const* p = a+len-1;
  do {
    ret += *p;
    --p;
  } while (p > a);
  return ret;
}
```

Here, p starts out at `a+(`len`-1)`, and in the *i*th iteration the picture is:

![](https://drek4537l1klr.cloudfront.net/gustedt/Figures/pg_174_alt.jpg)

Note that the summation order in this function is inverted.[[1](/book/modern-c/chapter-11/ch11fn01)]

1 Because of differences in rounding, the result might be slightly different than for the first three functions in this series.

There is also an operation, *pointer difference**C*, that takes two pointers and evaluates to an integer value their distance apart in number of elements. To see that, we extend sum3 to a new version that checks for an error condition (one of the array elements being an infinity). In that case, we want to print a comprehensive error message and return the culprit to the caller:[[2](/book/modern-c/chapter-11/ch11fn02)]

2 **`isinf`** comes from the `math.h` header.

```
double sum4(size_t len, double const* a) {
  double ret = 0.0;
  double const* p = a+len-1;
  do {
    if (isinf(*p)) {
      fprintf(stderr,
             "element \%tu of array at \%p is infinite\n",
              p-a,           // Pointer difference!
              (void*)a);     // Prints the pointer value
      return *p;
    }
    ret += *p;
    --p;
  } while (p > a);
  return ret;
}
```

Here, we use the expression p`-`a to compute the position of the actual element in the array.

This is allowed only if the two pointers refer to elements of the same array object:

##### Takeaway 11.5

*Only subtract pointers from elements of an array object.*

The value of such a difference then is simply the difference of the indices of the corresponding array elements:

```
double A[4] = { 0.0, 1.0, 2.0, -3.0, };
double* p = &A[1];
double* q = &A[3];
assert(p-q == -2);
```

We have stressed the fact that the correct type for sizes of objects is **`size_t`**, an unsigned type that on many platforms is different from **`unsigned`**. This has its correspondence in the type of a pointer difference: in general, we cannot assume that a simple **`int`** is wide enough to hold the possible values. Therefore, the standard header `stddef.h` provides us with another type. On most architectures, it is just the signed integer type that corresponds to **`size_t`**, but we shouldn’t care much.

<stddef.h>##### Takeaway 11.6

*All pointer differences have type* **`ptrdiff_t`***.*

##### Takeaway 11.7

*Use* **`ptrdiff_t`** *to encode signed differences of positions or sizes.*

Function sum4 also shows a recipe to print a pointer value for debugging purposes. We use the format character `%`p, and the pointer argument is *cast* by `(`**`void`**`*``)`a to the obscure type **`void`**`*`. For the moment, take this recipe as a given; we do not yet have all the baggage to understand it in full (more details will follow in [section 12.4](/book/modern-c/chapter-12/ch12lev1sec4)).

##### Takeaway 11.8

*For printing, cast pointer values to* **`void`***`*`**, and use the format* *`%`**`p`**.*

### 11.1.4. Pointer validity

Earlier ([takeaway 11.1](/book/modern-c/chapter-11/ch11note01)), we saw that we must be careful about the address that a pointer contains (or does not contain). Pointers have a value, the address they contain, and that value can change.

Setting a pointer to 0 if it does not have a valid address is very important and should not be forgotten. It helps to check and keep track of whether a pointer has been set.

##### Takeaway 11.9

*Pointers have truth.*

To avoid clunky comparisons ([takeaway 3.3](/book/modern-c/chapter-3/ch03note04)), in C programs you often will see code like this:

```
char const* name = 0;

// Do something that eventually sets name

if (name) {
  printf("today's name is %s\n", name);
} else {
  printf("today we are anonymous\n");
}
```

Therefore, it is important to control the state of all pointer variables. We have to ensure that pointer variables are always null, unless they point to a valid object that we want to manipulate.

##### Takeaway 11.10

*Set pointer variables to* *`0`* *as soon as you can.*

In most cases, the simplest way to ensure this is to initialize pointer variables explicitly ([takeaway 6.22](/book/modern-c/chapter-6/ch06note23)).

We have seen some examples of *representations* of different types: that is, the way the platform stores the value of a particular type in an object. The representation of one type, **`size_t`**, say, could be completely senseless to another type, for example **`double`**. As long as we only use variables directly, C’s type system will protect us from any mixup of these representations; a **`size_t`** object will always be accessed as such and never be interpreted as a (senseless) **`double`**.

If we did not use them carefully, pointers could break that barrier and lead us to code that tries to interpret the representation of a **`size_t`** as **`double`**. More generally, C even has coined a term for bit patterns that are nonsense when they are interpreted as a specific type: a *trap representation**C* for that type. This choice of words (*trap*) is meant to intimidate.

##### Takeaway 11.11

*Accessing an object that has a trap representation of its type has undefined behavior.*

Ugly things can happen if you do, so please don’t try.

Thus, not only must a pointer be set to an object (or null), but such an object also must have the correct type.

##### Takeaway 11.12

*When dereferenced, a pointed-to object must be of the designated type.*

As a direct consequence, a pointer that points beyond array bounds must not be dereferenced:

```
double A[2] = { 0.0, 1.0, };
double* p = &A[0];
printf("element %g\n", *p); // Referencing object
++p;                        // Valid pointer
printf("element %g\n", *p); // Referencing object
++p;                        // Valid pointer, no object
printf("element %g\n", *p); // Referencing non-object
                            // Undefined behavior
```

Here, on the last line, p has a value that is beyond the bounds of the array. Even if this might be the address of a valid object, we don’t know anything about the object it is pointing to. So even if p is valid at that point, accessing the contents as a type of **`double`** makes no sense, and C generally forbids such access.

In the previous example, the pointer addition itself is correct, as long as we don’t access the object on the last line. The valid values of pointers are all addresses of array elements *and* the address beyond the array. Otherwise, **`for`** loops with pointer addition as in the example wouldn’t work reliably.

##### Takeaway 11.13

*A pointer must point to a valid object or one position beyond a valid object or be null.*

So the example only worked up to the last line because the last `++`p left the pointer value just one element after the array. This version of the example still follows a similar pattern as the one before:

```
double A[2] = { 0.0, 1.0, };
double* p = &A[0];
printf("element %g\n", *p); // Referencing object
p += 2;                     // Valid pointer, no object
printf("element %g\n", *p); // Referencing non-object 
                           // Undefined behavior
```

Whereas this last example may crash at the increment operation:

```
double A[2] = { 0.0, 1.0, };
double* p = &A[0];
printf("element %g\n", *p); // Referencing object
p += 3;                     // Invalid pointer addition
                            // Undefined behavior
```

### 11.1.5. Null pointers

You may have wondered why, in all this discussion about pointers, the macro **`NULL`** has not yet been used. The reason is that, unfortunately, the simple concept of a “generic pointer of value 0” didn’t succeed very well.

C has the concept of a *null pointer**C* that corresponds to a 0 value of any pointer type.[[3](/book/modern-c/chapter-11/ch11fn03)] Here,

3 Note the different capitalization of *null* versus **`NULL`**.

```
double const*const nix = 0;
double const*const nax = nix;
```

nix and nax would be pointer objects of value 0. But unfortunately, a *null pointer constant**C* is then not what you’d expect.

First, here the term *constant* refers to a compile-time constant, not to a **`const`***-qualified* object. So for that reason, both pointer objects *are not* null pointer constants. Second, the permissible type for these constants is restricted: it may be any constant expression of integer type or of type **`void`**`*`. Other pointer types are not permitted, and we will learn about pointers of that “type” in [section 12.4](/book/modern-c/chapter-12/ch12lev1sec4).

The definition in the C standard of a possible expansion of the macro **`NULL`** is quite loose; it just has to be a null pointer constant. Therefore, a C compiler could choose any of the following for it:

| Expansion | Type |
| --- | --- |
| 0U | **unsigned** |
| 0 | **signed** |
| '\0' |  |
| Enumeration constant of value 0 |  |
| 0UL | **unsigned long** |
| 0L | **signed long** |
| 0ULL | **unsigned long long** |
| 0LL | **signed long** |
| (**void***)0 | **void*** |

Commonly used values are `0`, `0`L, and `(`**`void`**`*``)0`.[[4](/book/modern-c/chapter-11/ch11fn04)]

4 In theory, there are even more possible expansions for **`NULL`**, such as `((`**`char`**`)+0)` and `((`**`short`**`)-0)`.

It is important that the type behind **`NULL`** is not prescribed by the C standard. Often, people use it to emphasize that they are talking about a pointer constant, which it simply isn’t on many platforms. Using **`NULL`** in a context that we have not mastered completely is even dangerous. This will in particular appear in the context of functions with a variable number of arguments, which will be discussed in [section 16.5.2](/book/modern-c/chapter-16/ch16lev2sec2). For the moment, we will go for the simplest solution:

##### Takeaway 11.14

*Don’t use* **`NULL`***.*

**`NULL`** hides more than it clarifies. Either use `0` or, if you really want to emphasize that the value is a pointer, use the magic token sequence `(`**`void`**`*``)0` directly.

## 11.2. Pointers and structures

Pointers to structure types are crucial for most coding in C, so some specific rules and tools have been put in place to ease this typical usage. For example, let us consider the task of normalizing a **`struct`** **`timespec`** as we have encountered it previously. The use of a pointer parameter in the following function allows us to manipulate the objects directly:

##### `timespec.c`

```
10   /**
11    ** @brief compute a time difference
12    **
13    ** This uses a @c double to compute the time. If we want to
14    ** be able to track times without further loss of precision
15    ** and have @c double with 52 bit mantissa, this
16    ** corresponds to a maximal time difference of about 4.5E6
17    ** seconds, or 52 days.
18    **
19    **/
20   double timespec_diff(struct timespec const* later,
21                        struct timespec const* sooner){
22     /* Be careful: tv_sec could be an unsigned type */
23     if (later->tv_sec < sooner->tv_sec)
24       return -timespec_diff(sooner, later);
25     else
26       return
27          (later->tv_sec - sooner->tv_sec)
28          /* tv_nsec is known to be a signed type. */
29          + (later->tv_nsec - sooner->tv_nsec) * 1E-9;
30   }
```

For convenience, here we use a new operator, `->`. Its arrow-like symbol is meant to represent a pointer as the left operand that “points” to a member of the underlying **`struct`** as the right operand. It is equivalent to a combination of `*` and `..` To have the same effect, we would have to use parentheses and write `(``*`a`).`**`tv_sec`** instead of a`->`**`tv_sec`**. This could quickly become a bit clumsy, so the `->` operator is what everybody uses.

![](https://drek4537l1klr.cloudfront.net/gustedt/Figures/pg_179.jpg)

Observe that a construct like a`->`**`tv_nsec`** is *not* a pointer, but an object of type **`long`**, the number itself.

As another example, let us again consider the type rat for rational numbers that we introduced in [section 10.2.2](/book/modern-c/chapter-10/ch10lev2sec2). The functions operating on pointers to that type in [listing 10.1](/book/modern-c/chapter-10/ch10ex08) could be written as follows:

##### `rationals.c`

```
95   void rat_destroy(rat* rp) {
96     if (rp) *rp = (rat){ 0 };
97   }
```

The function rat_destroy ensures that all data that might be present in the object is erased and set to all-bits `0`:

##### `rationals.c`

```
99   rat* rat_init(rat* rp,
100                 long long num,
101                 unsigned long long denom) {
102     if (rp) *rp = rat_get(num, denom);
103     return rp;
104   }
```

##### `rationals.c`

```
106   rat* rat_normalize(rat* rp) {
107     if (rp) *rp = rat_get_normal(*rp);
108     return rp;
109   }
```

##### `rationals.c`

```
111   rat* rat_extend(rat* rp, size_t f) {
112     if (rp) *rp = rat_get_extended(*rp, f);
113     return rp;
114   }
```

The other three functions are simple *wrappers**C* around the pure functions that we already know. We use two pointer operations to test validity and then, if the pointer is valid, to refer to the object in question. So, these functions can be safely used, even if the pointer argument is null.[[[Exs 2]](/book/modern-c/chapter-11/ch11fn-ex02)][[[Exs 3]](/book/modern-c/chapter-11/ch11fn-ex03)]

[Exs 2] Implement function rat_print as declared in [listing 10.1](/book/modern-c/chapter-10/ch10ex08). This function should use `->` to access the members of its rat`*` argument. The printout should have the form –*nom*/*denum*.

[Exs 3] Implement rat_print_normalized by combining rat_normalize and rat_print.

All four functions check and return their pointer argument. This is a convenient strategy to compose such functions, as we can see in the definitions of the following two arithmetic functions:

##### `rationals.c`

```
135   rat* rat_rma(rat* rp, rat x, rat y) {
136     return rat_sumup(rp, rat_get_prod(x, y));
137   }
```

The function rat_rma (“rational multiply add”) comprehensively shows its purpose: to add the product of the two other function arguments to the object referred to by rp. It uses the following function for the addition:

##### `rationals.c`

```
116   rat* rat_sumup(rat* rp, rat y) {
117     size_t c = gcd(rp->denom, y.denom);
118     size_t ax = y.denom/c;
119     size_t bx = rp->denom/c;
120     rat_extend(rp, ax);
121     y = rat_get_extended(y, bx);
122     assert(rp->denom == y.denom);
123
124     if (rp->sign == y.sign) {
125       rp->num += y.num;
126     } else if (rp->num > y.num) {
127       rp->num -= y.num;
128     } else {
129       rp->num = y.num - rp->num;
130       rp->sign = !rp->sign;
131     }
132     return rat_normalize(rp);
133   }
```

The function rat_sumup is a more complicated example, where we apply two maintenance functions to the pointer arguments.[[[Exs 4]](/book/modern-c/chapter-11/ch11fn-ex04)]

[Exs 4] Implement the function rat_dotproduct from [listing 10.1](/book/modern-c/chapter-10/ch10ex08) such that it computes  and returns that value in `*`rp.

Another special rule applies to pointers to structure types: they can be used even if the structure type itself is unknown. Such *opaque structures**C* are often used to strictly separate the interface of a library and its implementation. For example, a fictive type toto could be presented in an include file as follows:

```
/* forward declaration of struct toto */
struct toto;
struct toto* toto_get(void);
void toto_destroy(struct toto*);
void toto_doit(struct toto*, unsigned);
```

Neither the programmer nor the compiler would need more than that to use the type **`struct`** toto. The function toto_get could be used to obtain a pointer to an object of type **`struct`** toto, regardless how it might have been defined in the compilation unit that defines the functions. And the compiler gets away with it because it knows that all pointers to structures have the same representation, regardless of the specific definition of the underlying type.

Often, such interfaces use the fact that null pointers are special. In the previous example, toto_doit`(0, 42)` could be a valid use case. This is why many C programmers don’t like it if pointers are hidden inside **`typedef`**:

```
/* forward declaration of struct toto_s and user type toto */
typedef struct toto_s* toto;
toto toto_get(void);
void toto_destroy(toto);
void toto_doit(toto, unsigned);
```

This is valid C, but it hides the fact that `0` is a special value that toto_doit may receive.

##### Takeaway 11.15

*Don’t hide pointers in a* **`typedef`***.*

This is not the same as just introducing a **`typedef`** name for the **`struct`**, as we have done before:

```
/* forward declaration of struct toto and typedef toto */
typedef struct toto toto;
toto* toto_get(void);
void toto_destroy(toto*);
void toto_doit(toto*, unsigned);
```

Here, the fact that the interface receive a pointer is still sufficiently visible.

##### Text processor

For a text processor, can you use a doubly linked list to store text? The idea is to represent a “blob” of text through a **`struct`** that contains a string (for the text) and pointers to preceding and following blobs.

Can you build a function that splits a text blob in two at a given point?

One that joins two consecutive text blobs?

One that runs through the entire text and puts it in the form of one blob per line?

Can you create a function that prints the entire text or prints until the text is cut off due to the screen size?

## 11.3. Pointers and arrays

We are now able to attack the major hurdles to understanding the relationship between arrays and pointers: the fact that C uses the same syntax for pointer and array element access *and* that it rewrites array parameters of functions to pointers. Both features provide convenient shortcuts for the experienced C programmer but also are a bit difficult for novices to digest.

### 11.3.1. Array and pointer access are the same

The following statement holds regardless of whether A is an array or a pointer:

##### Takeaway 11.16

*The two expressions* *A**`[`**`i`**]* *and* *`*`**`(`**`A`**`+`**`i`**`)`* *are equivalent.*

If it is a pointer, we understand the second expression. Here, it just says that we may write the same expression as A`[`i`]`. Applying this notion of array access to pointers should improve the readability of your code. The equivalence does not mean that all of the sudden an array object appears where there was none. If A is null, A`[`i`]` should crash nicely, as should `*``(`A`+`i`)`.

If A is an array, `*``(`A`+`i`)` shows our first application of one of the most important rules in C, called *array-to-pointer decay**C*:

##### Takeaway 11.17 (array decay)

*Evaluation of an array* *`A`* *returns* *`&`**`A`**`[0]`**.*

In fact, this is the reason there are no “array values” and all the difficulties they entail ([takeaway 6.3](/book/modern-c/chapter-6/ch06note03)). Whenever an array occurs that requires a value, it decays to a pointer, and we lose all additional information.

### 11.3.2. Array and pointer parameters are the same

Because of the decay, arrays cannot be function arguments. There would be no way to call such a function with an array parameter; before any call to the function, an array that we feed into it would decay into a pointer, and thus the argument type wouldn’t match.

But we have seen declarations of functions with array parameters, so how did they work? The trick C gets away with is to rewrite array parameters to pointers.

##### Takeaway 11.18

*In a function declaration, any array parameter rewrites to a pointer.*

Think of this and what it means for a while. Understanding this “chief feature” (or character flaw) is central for coding easily in C.

To come back to our examples from [section 6.1.5](/book/modern-c/chapter-6/ch06lev2sec5), the functions that were written with array parameters could be declared as follows:

```
size_t strlen(char const* s);
char*  strcpy(char* target, char const* source);
signed strcmp(char const* s0, char const* s1);
```

These are completely equivalent, and any C compiler should be able to use both forms interchangeably.

Which one to use is a question of habit, culture, or other social contexts. The rule that we follow in this book to use array notation if we suppose it can’t be null, and pointer notation if it corresponds to a single item of the base type that also can be null to indicate a special condition.

If semantically a parameter is an array, we also note what size we expect the array to be, if possible. And to make it possible, it is usually better to specify the length before the arrays/pointers. An interface such as

```
double double_copy(size_t len,
                   double target[len],
                   double const source[len]);
```

tells a whole story. This becomes even more interesting if we handle two-dimensional arrays. A typical matrix multiplication could look as follows:

```
void matrix_mult(size_t n, size_t k, size_t m,
                 double C[n][m],
                 double A[n][k],
                 double B[k][m]) {
   for (size_t i = 0; i < n; ++i) {
     for (size_t j = 0; j < m; ++j) {
       C[i][j] = 0.0;
       for (size_t l = 0; l < k; ++l) {
         C[i][j] += A[i][l]*B[l][j];
       }
     }
   }
}
```

The prototype is equivalent to the less readable and Observe that once we have rewritten

```
void matrix_mult(size_t n, size_t k, size_t m,
                 double (C[n])[m],
                 double (A[n])[k],
                 double (B[k])[m]);void matrix_mult(size_t n, size_t k, size_t m,
                 double (*C)[m],
                 double (*A)[k],
                 double (*B)[m]);
```

the innermost dimension as a pointer, the parameter type is not an array anymore, but a *pointer to array*. So there is no need to rewrite the subsequent dimensions.

##### Takeaway 11.19

*Only the innermost dimension of an array parameter is rewritten.*

Finally, we have gained a lot by using array notation. We have without any trouble passed pointers to VLAs into the function. Inside the function, we can use conventional indexing to access the elements of the matrices. Not much in the way of acrobatics is required to keep track of the array lengths:

##### Takeaway 11.20

*Declare length parameters before array parameters.*

They simply have to be known at the point where you use them first.

Unfortunately, C generally gives no guarantee that a function with array-length parameters is always called correctly.

##### Takeaway 11.21

*The validity of array arguments to functions must be guaranteed by the programmer.*

If the array lengths are known at compile time, compilers may be able to issue warnings, though. But when array lengths are dynamic, you are mostly on your own: be careful.

## 11.4. Function pointers

There is yet another construct for which the address-of operator `&` can be used: functions. We saw this concept pop up when discussing the **atexit** function ([section 8.7](/book/modern-c/chapter-8/ch08lev1sec7)), which is a function that receives a function argument. The rule is similar to that for array decay, which we described earlier:

##### Takeaway 11.22 (function decay)

*A function* f *without a following opening* *`(`* *decays to a pointer to its start.*

Syntactically, functions and function pointers are also similar to arrays in type declarations and as function parameters:

```javascript
typedef void atexit_function(void);
// Two equivalent definitions of the same type, which hides a pointer
typedef atexit_function* atexit_function_pointer;
typedef void (*atexit_function_pointer)(void);
// Five equivalent declarations for the same function
void atexit(void f(void));
void atexit(void (*f)(void));
void atexit(atexit_function f);
void atexit(atexit_function* f);
void atexit(atexit_function_pointer f);
```

Which of the semantically equivalent ways of writing the function declaration is more readable could certainly be the subject of much debate. The second version, with the `(``*`f`)` parentheses, quickly gets difficult to read; and the fifth is frowned upon because it hides a pointer in a type. Among the others, I personally slightly prefer the fourth over the first.

The C library has several functions that receive function parameters. We have seen **atexit** and **at_quick_exit**. Another pair of functions in `stdlib.h` provides generic interfaces for searching (**bsearch**) and sorting (**qsort**):

<stdlib.h>```javascript
typedef int compare_function(void const*, void const*);

void* bsearch(void const* key, void const* base,
size_t n, size_t size,
compare_function* compar);

void qsort(void* base,
size_t n, size_t size,
compare_function* compar);
```

Both receive an array base as argument on which they perform their task. The address to the first element is passed as a **`void`** pointer, so all type information is lost. To be able to handle the array properly, the functions have to know the size of the individual elements (size) and the number of elements (n).

In addition, they receive a comparison function as a parameter that provides the information about the sort order between the elements. By using such a function pointer, the **bsearch** and **qsort** functions are very generic and can be used with any data model that allows for an ordering of values. The elements referred by the base parameter can be of any type T (**`int`**, **`double`**, string, or application defined) as long as the size parameter correctly describes the size of T and as long as the function pointed to by compar knows how to compare values of type T consistently.

A simple version of such a function would look like this:

```
int compare_unsigned(void const* a, void const* b){
unsigned const* A = a;
unsigned const* B = b;
if (*A < *B) return -1;
else if (*A > *B) return +1;
else return 0;
}
```

The convention is that the two arguments point to elements that are to be compared, and the return value is strictly negative if a is considered less than b, `0` if they are equal, and strictly positive otherwise.

The return type of **`int`** seems to suggest that **`int`** comparison could be done more simply:

```
/* An invalid example for integer comparison */
int compare_int(void const* a, void const* b){
int const* A = a;
int const* B = b;
return *A - *B;     // may overflow!
}
```

But this is not correct. For example, if `*`A is big, say **`INT_MAX`**, and `*`B is negative, the mathematical value of the difference can be larger than **`INT_MAX`**.

Because of the **`void`** pointers, a usage of this mechanism should always take care that the type conversions are encapsulated similar to the following:

```
/* A header that provides searching and sorting for unsigned. */

/* No use of inline here; we always use the function pointer. */
extern int compare_unsigned(void const*, void const*);

inline
unsigned const* bsearch_unsigned(unsigned const key[static 1],
size_t nmeb, unsigned const base[nmeb]) {
return bsearch(key, base, nmeb, sizeof base[0], compare_unsigned);
}

inline
void qsort_unsigned(size_t nmeb, unsigned base[nmeb]) {
qsort(base, nmeb, sizeof base[0], compare_unsigned);
}
```

Here, **bsearch** (binary search) searches for an element that compares equal to key`[0]` and returns it, or returns a null pointer if no such element is found. It supposes that array base is already sorted consistently to the ordering that is given by the comparison function. This assumption helps to speed up the search. Although this is not explicitly specified in the C standard, you can expect that a call to **bsearch** will never make more than *⌈*log2(*n*)*⌉* calls to compar.

If **bsearch** finds an array element that is equal to `*`key, it returns the pointer to this element. Note that this drills a hole in C’s type system, since this returns an unqualified pointer to an element whose effective type might be **`const`** qualified. Use with care. In our example, we simply convert the return value to **`unsigned const`**`*`, such that we will never even see an unqualified pointer at the call side of bsearch_unsigned.

The name **qsort** is derived from the *quick sort* algorithm. The standard doesn’t impose the choice of the sorting algorithm, but the expected number of comparison calls should be of the magnitude of *n* log2(*n*), just like quick sort. There are no guarantees for upper bounds; you may assume that its worst-case complexity is at most quadratic, *O*(*n*2).

Whereas there is a catch-all pointer type, **`void`**`*`, that can be used as a generic pointer to object types, no such generic type or implicit conversion exists for function pointers.

##### Takeaway 11.23

*Function pointers must be used with their exact type.*

Such a strict rule is necessary because the calling conventions for functions with different prototypes may be quite different[[5](/book/modern-c/chapter-11/ch11fn05)] and the pointer itself does not keep track of any of this.

5 The platform application binary interface (ABI) may, for example, pass floating points in special hardware registers. 

The following function has a subtle problem because the types of the parameters are different than what we expect from a comparison function:

```
/* Another invalid example for an int comparison function */
int compare_int(int const* a, int const* b){
if (*a < *b) return -1;
else if (*a > *b) return +1;
else return 0;
}
```

When you try to use this function with **qsort**, your compiler should complain that the function has the wrong type. The variant that we gave earlier using intermediate **`void const`**`*` parameters should be almost as efficient as this invalid example, but it also can be guaranteed to be correct on all C platforms.

*Calling* functions and function pointers with the `(...)` operator has rules similar to those for arrays and pointers and the `[...]` operator:

##### Takeaway 11.24

*The function call operator* *`(...)`* *applies to function pointers.*

```
double f(double a);

// Equivalent calls to f, steps in the abstract state machine
f(3);        // Decay → call
(&f)(3);     // Address of → call
(*f)(3);     // Decay → dereference → decay → call
(*&f)(3);    // Address of → dereference → decay → call
(&*f)(3);    // Decay → dereference → address of → call
```

So technically, in terms of the abstract state machine, the pointer decay is always performed, and the function is called via a function pointer. The first, “natural” call has a hidden evaluation of the f identifier that results in the function pointer.

Given all this, we can use function pointers almost like functions:

```javascript
// In a header
typedef int logger_function(char const*, ...);
extern logger_function* logger;
enum logs { log_pri, log_ign, log_ver, log_num };
```

This declares a global variable logger that will point to a function that prints out logging information. Using a function pointer will allow the user of this module to choose a particular function dynamically:

```
// In a .c file (TU)
extern int logger_verbose(char const*, ...);
static
int logger_ignore(char const*, ...) {
return 0;
}
logger_function* logger = logger_ignore;

static
logger_function* loggers = {
[log_pri] = printf,
[log_ign] = logger_ignore,
[log_ver] = logger_verbose,
};
```

Here, we are defining tools that implement this approach. In particular, function pointers can be used as a base type for arrays (here loggers). Observe that we use two external functions (**printf** and logger_verbose) and one **`static`** function (logger_ignore) for the array initialization: the storage class is not part of the function interface.

The logger variable can be assigned just like any other pointer type. Somewhere at startup we can have

```
if (LOGGER < log_num) logger = loggers[LOGGER];
```

Then this function pointer can be used anywhere to call the corresponding function:

```
logger("Do we ever see line \%lu of file \%s?", __LINE__+0UL, __FILE__);
```

This call uses the special macros **`__LINE__`** and **`__FILE__`** for the line number and the name of the source file. We will discuss these in more detail in [section 16.3](/book/modern-c/chapter-16/ch16lev1sec3).

When using pointers to functions, you should always be aware that doing so introduces an indirection to the function call. The compiler first has to fetch the contents of logger and can only then call the function at the address it found there. This has a certain overhead and should be avoided in time-critical code.

##### Generic derivative

Can you extend the real and complex derivatives ([challenges 2](/book/modern-c/chapter-3/ch03sb02) and [5](/book/modern-c/chapter-5/ch05sb01)) such that they receive the function F and the value x as a parameter?

Can you use the generic real derivatives to implement Newton’s method for finding roots?

Can you find the real zeros of polynomials?

Can you find the complex zeros of polynomials?

##### Generic sorting

Can you extend your sorting algorithms ([challenge 1](/book/modern-c/chapter-3/ch03sb01)) to other sort keys?

Can you condense your functions for different sort keys to functions that have the same signature as **qsort**: that is, receive generic pointers to data, size information, and a comparison function as parameters?

Can you extend the performance comparison of your sorting algorithms ([challenge 10](/book/modern-c/chapter-8/ch08sb06)) to the C library function **qsort**?

## Summary

- Pointers can refer to objects and to functions.
- Pointers are not arrays but refer to arrays.
- Array parameters of functions are automatically rewritten as object pointers.
- Function parameters of functions are automatically rewritten as function pointers.
- Function pointer types must match exactly when they are assigned or called.

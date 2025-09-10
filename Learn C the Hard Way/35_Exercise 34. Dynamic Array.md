## Exercise 34. Dynamic Array

This is an array that grows on its own and has most of the same features as a linked list. It will usually take up less space, run faster, and has other beneficial properties. This exercise will cover a few of the disadvantages, like very slow removal from the front, with a solution to just do it at the end.

A dynamic array is simply an array of `void **` pointers that’s pre-allocated in one shot and that point at the data. In the linked list, you had a full structure that stored the `void *value` pointer, but in a dynamic array, there’s just a single array with all of them. This means you don’t need any other pointers for next and previous records since you can just index into the dynamic array directly.

To start, I’ll give you the header file you should type in for the implementation:

`darray.h`

---

[Click here to view code image](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch34_images.html#p198pro01a)

```
#ifndef _DArray_h

#define _DArray_h

#include <stdlib.h>

#include <assert.h>

#include <lcthw/dbg.h>



typedef struct DArray {

    int end;

    int max;

    size_t element_size;

    size_t expand_rate;

    void **contents;

} DArray;



DArray *DArray_create(size_t element_size, size_t initial_max);



void DArray_destroy(DArray * array);



void DArray_clear(DArray * array);



int DArray_expand(DArray * array);



int DArray_contract(DArray * array);



int DArray_push(DArray * array, void *el);



void *DArray_pop(DArray * array);



void DArray_clear_destroy(DArray * array);



#define DArray_last(A) ((A)->contents[(A)->end - 1])

#define DArray_first(A) ((A)->contents[0])

#define DArray_end(A) ((A)->end)

#define DArray_count(A) DArray_end(A)

#define DArray_max(A) ((A)->max)



#define DEFAULT_EXPAND_RATE 300





static inline void DArray_set(DArray * array, int i, void *el)

{

    check(i < array->max, "darray attempt to set past max");

    if (i > array->end)

        array->end = i;

    array->contents[i] = el;

error:

    return;

}



static inline void *DArray_get(DArray * array, int i)

{

    check(i < array->max, "darray attempt to get past max");

    return array->contents[i];

error:

    return NULL;

}



static inline void *DArray_remove(DArray * array, int i)

{

    void *el = array->contents[i];



    array->contents[i] = NULL;



    return el;

}



static inline void *DArray_new(DArray * array)

{

    check(array->element_size > 0,

            "Can't use DArray_new on 0 size darrays.");



    return calloc(1, array->element_size);



error:

    return NULL;

}



#define DArray_free(E) free((E))



#endif
```

This header file is showing you a new technique where I put `static inline` functions right in the header. These function definitions will work similarly to the `#define` macros that you’ve been making, but they’re cleaner and easier to write. If you need to create a block of code for a macro and you don’t need code generation, then use a `static inline` function.

Compare this technique to the `LIST_FOREACH` that *generates* a proper `for-loop` for a list. This would be impossible to do with a `static inline` function because it actually has to generate the inner block of code for the loop. The only way to do that is with a callback function, but that’s not as fast and it’s harder to use.

I’ll then change things up and have you create the unit test for `DArray`:

`darray_tests.c`

---

[Click here to view code image](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch34_images.html#p200pro01a)

```
#include "minunit.h"

#include <lcthw/darray.h>

  3

static DArray *array = NULL;

static int *val1 = NULL;

static int *val2 = NULL;

  7

char *test_create()

{

array = DArray_create(sizeof(int), 100);

mu_assert(array != NULL, "DArray_create failed.");

mu_assert(array->contents != NULL, "contents are wrong in darray");

mu_assert(array->end == 0, "end isn't at the right spot");

mu_assert(array->element_size == sizeof(int),

"element size is wrong.");

mu_assert(array->max == 100, "wrong max length on initial size");

 17

return NULL;

}

 20

char *test_destroy()

{

DArray_destroy(array);

 24

return NULL;

}

 27

char *test_new()

{

val1 = DArray_new(array);

mu_assert(val1 != NULL, "failed to make a new element");

 32

val2 = DArray_new(array);

mu_assert(val2 != NULL, "failed to make a new element");

 35

return NULL;

}

 38

char *test_set()

{

DArray_set(array, 0, val1);

DArray_set(array, 1, val2);

 43

return NULL;

}

 46

char *test_get()

{

mu_assert(DArray_get(array, 0) == val1, "Wrong first value.");

mu_assert(DArray_get(array, 1) == val2, "Wrong second value.");

 51

return NULL;

}

 54

char *test_remove()

{

int *val_check = DArray_remove(array, 0);

mu_assert(val_check != NULL, "Should not get NULL.");

mu_assert(*val_check == *val1, "Should get the first value.");

mu_assert(DArray_get(array, 0) == NULL, "Should be gone.");

DArray_free(val_check);

 62

val_check = DArray_remove(array, 1);

mu_assert(val_check != NULL, "Should not get NULL.");

mu_assert(*val_check == *val2, "Should get the first value.");

mu_assert(DArray_get(array, 1) == NULL, "Should be gone.");

DArray_free(val_check);

 68

return NULL;

}

 71

char *test_expand_contract()

{

int old_max = array->max;

DArray_expand(array);

mu_assert((unsigned int)array->max == old_max + array->expand_rate,

"Wrong size after expand.");

 78

DArray_contract(array);

mu_assert((unsigned int)array->max == array->expand_rate + 1,

"Should stay at the expand_rate at least.");

 82

DArray_contract(array);

mu_assert((unsigned int)array->max == array->expand_rate + 1,

"Should stay at the expand_rate at least.");

 86

return NULL;

}

 89

char *test_push_pop()

{

int i = 0;

for (i = 0; i < 1000; i++) {

int *val = DArray_new(array);

*val = i * 333;

DArray_push(array, val);

}

 98

mu_assert(array->max == 1201, "Wrong max size.");

100

for (i = 999; i >= 0; i--) {

int *val = DArray_pop(array);

mu_assert(val != NULL, "Shouldn't get a NULL.");

mu_assert(*val == i * 333, "Wrong value.");

DArray_free(val);

}

107

return NULL;

}

110

char *all_tests()

{

mu_suite_start();

114

mu_run_test(test_create);

mu_run_test(test_new);

mu_run_test(test_set);

mu_run_test(test_get);

mu_run_test(test_remove);

mu_run_test(test_expand_contract);

mu_run_test(test_push_pop);

mu_run_test(test_destroy);

123

return NULL;

}

126

RUN_TESTS(all_tests);
```

This shows you how all of the operations are used, which then makes implementing the `DArray` much easier:

`darray.c`

---

[Click here to view code image](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch34_images.html#p202pro01a)

```
#include <lcthw/darray.h>

#include <assert.h>

  3

DArray *DArray_create(size_t element_size, size_t initial_max)

{

DArray *array = malloc(sizeof(DArray));

check_mem(array);

array->max = initial_max;

check(array->max > 0, "You must set an initial_max > 0.");

 10

array->contents = calloc(initial_max, sizeof(void *));

check_mem(array->contents);

 13

array->end = 0;

array->element_size = element_size;

array->expand_rate = DEFAULT_EXPAND_RATE;

 17

return array;

 19

error:

if (array)

free(array);

return NULL;

}

 25

void DArray_clear(DArray * array)

{

int i = 0;

if (array->element_size > 0) {

for (i = 0; i < array->max; i++) {

if (array->contents[i] != NULL) {

free(array->contents[i]);

}

}

}

}

 37

static inline int DArray_resize(DArray * array, size_t newsize)

{

array->max = newsize;

check(array->max > 0, "The newsize must be > 0.");

 42

void *contents = realloc(

array->contents, array->max * sizeof(void *));

// check contents and assume realloc doesn't harm the original on error

 46

check_mem(contents);

 48

array->contents = contents;

 50

return 0;

error:

return -1;

}

 55

int DArray_expand(DArray * array)

{

size_t old_max = array->max;

check(DArray_resize(array, array->max + array->expand_rate) == 0,

"Failed to expand array to new size: %d",

array->max + (int)array->expand_rate);

 62

memset(array->contents + old_max, 0, array->expand_rate + 1);

return 0;

 65

error:

return -1;

}

 69

int DArray_contract(DArray * array)

{

int new_size = array->end < (int)array->expand_rate ?

(int)array->expand_rate : array->end;

 74

return DArray_resize(array, new_size + 1);

}

 77

void DArray_destroy(DArray * array)

{

if (array) {

if (array->contents)

free(array->contents);

free(array);

}

}

 86

void DArray_clear_destroy(DArray * array)

{

DArray_clear(array);

DArray_destroy(array);

}

 92

int DArray_push(DArray * array, void *el)

{

array->contents[array->end] = el;

array->end++;

 97

if (DArray_end(array) >= DArray_max(array)) {

return DArray_expand(array);

} else {

return 0;

}

}

104

void *DArray_pop(DArray * array)

{

check(array->end - 1 >= 0, "Attempt to pop from empty array.");

108

void *el = DArray_remove(array, array->end - 1);

array->end--;

111

if (DArray_end(array) > (int)array->expand_rate

&& DArray_end(array) % array->expand_rate) {

DArray_contract(array);

}

116

return el;

error:

return NULL;

}
```

This shows you another way to tackle complex code. Instead of diving right into the `.c` implementation, look at the header file, and then read the unit test. This gives you an abstract-to-concrete understanding of how the pieces work together, making it easier to remember.

### Advantages and Disadvantages

A `DArray` is better when you need to optimize these operations:

• Iteration: You can just use a basic `for-loop` and `DArray_count` with `DArray_get`, and you’re done. No special macros needed, and it’s faster because you aren’t walking through pointers.

• Indexing: You can use `DArray_get` and `DArray_set` to access any element at random, but with a `List` you have to go through N elements to get to N+1.

• Destroying: You can just free the struct and the `contents` in two operations. A `List` requires a series of `free` calls and walking every element.

• Cloning: You can also clone it in just two operations (plus whatever it’s storing) by copying the struct and `contents`. Again, a list requires walking through the whole thing and copying every `ListNode` plus its value.

• Sorting: As you saw, `List` is horrible if you need to keep the data sorted. A `DArray` opens up a whole class of great sorting algorithms, because now you can access elements randomly.

• Large Data: If you need to keep around a lot of data, then a `DArray` wins since its base, `contents`, takes up less memory than the same number of `ListNode` structs.

However, the `List` wins on these operations:

• Insert and remove on the front (what I called shift): A `DArray` needs special treatment to be able to do this efficiently, and usually it has to do some copying.

• Splitting or joining: A `List` can just copy some pointers and it’s done, but with a `DArray`, you have copy all of the arrays involved.

• Small Data: If you only need to store a few elements, then typically the storage will be smaller in a `List` than a generic `DArray`. This is because the `DArray` needs to expand the backing store to accommodate future inserts, while a `List` only makes what it needs.

With this, I prefer to use a `DArray` for most of the things you see other people use a `List` for. I reserve using `List` for any data structure that requires a small number of nodes to be added and removed from either end. I’ll show you two similar data structures called a `Stack` and `Queue` where this is important.

### How to Improve It

As usual, go through each function and operation and add the defensive programming checks, pre-conditions, invariants, and anything else you can find to make the implementation more bulletproof.

### Extra Credit

• Improve the unit tests to cover more of the operations, and test them using a `for-loop` to ensure that they work.

• Research what it would take to implement bubble sort and merge sort for DArray, but don’t do it yet. I’ll be implementing DArray algorithms next, so you’ll do this then.

• Write some performance tests for common operations and compare them to the same operations in `List`. You did some of this already, but this time, write a unit test that repeatedly does the operation in question and then, in the main runner, do the timing.

• Look at how the `DArray_expand` is implemented using a constant increase (size + 300). Typically, dynamic arrays are implemented with a multiplicative increase (size × 2), but I’ve found this to cost needless memory for no real performance gain. Test my assertion and see when you’d want a multiplicative increase instead of a constant increase.

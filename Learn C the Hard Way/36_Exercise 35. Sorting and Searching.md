## Exercise 35. Sorting and Searching

In this exercise, I’m going to cover four sorting algorithms and one search algorithm. The sorting algorithms are going to be quick sort, heap sort, merge sort, and radix sort. I’m then going to show you how do a to binary search after you’ve done a radix sort.

However, I’m a lazy guy, and in most standard C libraries you have existing implementations of the heapsort, quicksort, and merge sort algorithms. Here’s how you use them:

`darray_algos.c`

---

[Click here to view code image](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch35_images.html#p208pro01a)

```
#include <lcthw/darray_algos.h>

#include <stdlib.h>

  3

int DArray_qsort(DArray * array, DArray_compare cmp)

{

qsort(array->contents, DArray_count(array), sizeof(void *), cmp);

return 0;

}

  9

int DArray_heapsort(DArray * array, DArray_compare cmp)

{

return heapsort(array->contents, DArray_count(array),

sizeof(void *), cmp);

}

 15

int DArray_mergesort(DArray * array, DArray_compare cmp)

{

return mergesort(array->contents, DArray_count(array),

sizeof(void *), cmp);

}
```

That’s the whole implementation of the `darray_algos.c` file, and it should work on most modern UNIX systems. What each of these does is sort the `contents` store of void pointers using the `DArray_compare` that you give it. I’ll show you the header file for this, too:

`darray_algos.h`

---

[Click here to view code image](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch35_images.html#p208pro02a)

```
#ifndef darray_algos_h

#define darray_algos_h



#include <lcthw/darray.h>



typedef int (*DArray_compare) (const void *a, const void *b);



int DArray_qsort(DArray * array, DArray_compare cmp);



int DArray_heapsort(DArray * array, DArray_compare cmp);



int DArray_mergesort(DArray * array, DArray_compare cmp);



#endif
```

It’s about the same size and should be what you expect. Next, you can see how these functions are used in the unit test for these three:

`darray_algos_tests.c`

---

[Click here to view code image](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch35_images.html#p209pro01a)

```
#include "minunit.h"

#include <lcthw/darray_algos.h>

  3

int testcmp(char **a, char **b)

{

return strcmp(*a, *b);

}

  8

DArray *create_words()

{

DArray *result = DArray_create(0, 5);

char *words[] = { "asdfasfd",

"werwar", "13234", "asdfasfd", "oioj" };

int i = 0;

 15

for (i = 0; i < 5; i++) {

DArray_push(result, words[i]);

}

 19

return result;

}

 22

int is_sorted(DArray * array)

{

int i = 0;

 26

for (i = 0; i < DArray_count(array) - 1; i++) {

if (strcmp(DArray_get(array, i), DArray_get(array, i + 1)) > 0) {

return 0;

}

}

 32

return 1;

}

 35

char *run_sort_test(int (*func) (DArray *, DArray_compare),

const char *name)

{

DArray *words = create_words();

mu_assert(!is_sorted(words), "Words should start not sorted.");

 41

debug("--- Testing %s sorting algorithm", name);

int rc = func(words, (DArray_compare) testcmp);

mu_assert(rc == 0, "sort failed");

mu_assert(is_sorted(words), "didn't sort it");

 46

DArray_destroy(words);

 48

return NULL;

}

 51

char *test_qsort()

{

return run_sort_test(DArray_qsort, "qsort");

}

 56

char *test_heapsort()

{

return run_sort_test(DArray_heapsort, "heapsort");

}

 61

char *test_mergesort()

{

return run_sort_test(DArray_mergesort, "mergesort");

}

 66

char *all_tests()

{

mu_suite_start();

 70

mu_run_test(test_qsort);

mu_run_test(test_heapsort);

mu_run_test(test_mergesort);

 74

return NULL;

}

 77

RUN_TESTS(all_tests);
```

The thing to notice, and actually what tripped me up for a whole day, is the definition of `testcmp` on line 4. You have to use a `char **` and *not* a `char *` because `qsort` gives you a pointer to *the pointers* in the `contents` array. The function `qsort` and friends are scanning the array, and handing *pointers* to each element in the array to your comparison function. Since what I have in the `contents` array are pointers, that means you get a pointer to a pointer.

With that out of the way, you have just implemented three difficult sorting algorithms in about 20 lines of code. You could stop there, but part of this book is learning how these algorithms work, so the Extra Credit section is going to involve implementing each of these.

### Radix Sort and Binary Search

Since you’re going to implement quicksort, heapsort, and merge sort on your own, I’m going to show you a funky algorithm called radix sort. It has a slightly narrow usefulness in sorting arrays of integers, but seems to work like magic. In this case, I’m going to create a special data structure called a `RadixMap` that’s used to map one integer to another.

Here’s the header file for the new algorithm, which is both algorithm and data structure in one:

`radixmap.h`

---

[Click here to view code image](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch35_images.html#p211pro01a)

```
#ifndef _radixmap_h

#include <stdint.h>



typedef union RMElement {

    uint64_t raw;

    struct {

        uint32_t key;

        uint32_t value;

    } data;

} RMElement;



typedef struct RadixMap {

    size_t max;

    size_t end;

    uint32_t counter;

    RMElement *contents;

    RMElement *temp;

} RadixMap;



RadixMap *RadixMap_create(size_t max);



void RadixMap_destroy(RadixMap * map);



void RadixMap_sort(RadixMap * map);



RMElement *RadixMap_find(RadixMap * map, uint32_t key);



int RadixMap_add(RadixMap * map, uint32_t key, uint32_t value);



int RadixMap_delete(RadixMap * map, RMElement * el);



#endif
```

You see that I have a lot of the same operations as in a `Dynamic Array` or a `List` data structure, but the difference is I’m working only with fixed size 32-bit `uin32_t` integers. I’m also introducing you to a new C concept called the `union` here.

#### C Unions

A union is a way to refer to the same piece of memory in a number of different ways. You define it like a `struct`, except every element is sharing the same space with all of the others. You can think of a union as a picture of the memory, and the elements in the union as different colored lenses to view the picture.

What they are used for is to either save memory or convert chunks of memory between formats. The first usage is typically done with variant types, where you create a structure that has tag for the type, and then a union inside it for each type. When used for converting between formats of memory, you can simply define the two structures, and then access the right one.

First, let me show you how to make a variant type with C unions:

`ex35.c`

---

[Click here to view code image](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch35_images.html#p212pro01a)

```
#include <stdio.h>

  2

typedef enum {

TYPE_INT,

TYPE_FLOAT,

TYPE_STRING,

} VariantType;

  8

struct Variant {

VariantType type;

union {

int as_integer;

float as_float;

char *as_string;

} data;

};

 17

typedef struct Variant Variant;

 19

void Variant_print(Variant * var)

{

switch (var->type) {

case TYPE_INT:

printf("INT: %d\n", var->data.as_integer);

break;

case TYPE_FLOAT:

printf("FLOAT: %f\n", var->data.as_float);

break;

case TYPE_STRING:

printf("STRING: %s\n", var->data.as_string);

break;

default:

printf("UNKNOWN TYPE: %d", var->type);

}

}

 36

int main(int argc, char *argv[])

{

Variant a_int = {.type = TYPE_INT, .data.as_integer = 100 };

Variant a_float = {.type = TYPE_FLOAT, .data.as_float = 100.34 };

Variant a_string = {.type = TYPE_STRING,

.data.as_string = "YO DUDE!" };

 43

Variant_print(&a_int);

Variant_print(&a_float);

Variant_print(&a_string);

 47

// here's how you access them

a_int.data.as_integer = 200;

a_float.data.as_float = 2.345;

a_string.data.as_string = "Hi there.";

 52

Variant_print(&a_int);

Variant_print(&a_float);

Variant_print(&a_string);

 56

return 0;

}
```

You find this in many implementations of dynamic languages. The language will define some base variant type with tags for all the base types of the language, and then usually there’s a generic object tag for the types you can create. The advantage of doing this is that the `Variant` only takes up as much space as the `VariantType type` tag and the largest member of the union. This is because C is layering each element of the `Variant.data` union together, so they overlap. To do that, C sizes the union big enough to hold the largest element.

In the `radixmap.h` file, I have the `RMElement` union, which demonstrates using a union to convert blocks of memory between types. In this case, I want to store a `uint64_t`-sized integer for sorting purposes, but I want two `uint32_t` integers for the data to represent a `key` and `value` pair. By using a union, I’m able to cleanly access the same block of memory in the two different ways I need.

#### The Implementation

I next have the actual `RadixMap` implementation for each of these operations:

`radixmap.c`

---

[Click here to view code image](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch35_images.html#p213pro01a)

```
/*

* Based on code by Andre Reinald then heavily modified by Zed A. Shaw.

*/

  4

#include <stdio.h>

#include <stdlib.h>

#include <assert.h>

#include <lcthw/radixmap.h>

#include <lcthw/dbg.h>

 10

RadixMap *RadixMap_create(size_t max)

{

RadixMap *map = calloc(sizeof(RadixMap), 1);

check_mem(map);

 15

map->contents = calloc(sizeof(RMElement), max + 1);

check_mem(map->contents);

 18

map->temp = calloc(sizeof(RMElement), max + 1);

check_mem(map->temp);

 21

map->max = max;

map->end = 0;

 24

return map;

error:

return NULL;

}

 29

void RadixMap_destroy(RadixMap * map)

{

if (map) {

free(map->contents);

free(map->temp);

free(map);

}

}

 38

#define ByteOf(x,y) (((uint8_t *)x)[(y)])

 40

static inline void radix_sort(short offset, uint64_t max,

uint64_t * source, uint64_t * dest)

{

uint64_t count[256] = { 0 };

uint64_t *cp = NULL;

uint64_t *sp = NULL;

uint64_t *end = NULL;

uint64_t s = 0;

uint64_t c = 0;

 50

// count occurences of every byte value

for (sp = source, end = source + max; sp < end; sp++) {

count[ByteOf(sp, offset)]++;

}

 55

// transform count into index by summing

// elements and storing into same array

for (s = 0, cp = count, end = count + 256; cp < end; cp++) {

c = *cp;

*cp = s;

s += c;

}

 63

// fill dest with the right values in the right place

for (sp = source, end = source + max; sp < end; sp++) {

cp = count + ByteOf(sp, offset);

dest[*cp] = *sp;

++(*cp);

}

}

 71

void RadixMap_sort(RadixMap * map)

{

uint64_t *source = &map->contents[0].raw;

uint64_t *temp = &map->temp[0].raw;

 76

radix_sort(0, map->end, source, temp);

radix_sort(1, map->end, temp, source);

radix_sort(2, map->end, source, temp);

radix_sort(3, map->end, temp, source);

}

 82

RMElement *RadixMap_find(RadixMap * map, uint32_t to_find)

{

int low = 0;

int high = map->end - 1;

RMElement *data = map->contents;

 88

while (low <= high) {

int middle = low + (high - low) / 2;

uint32_t key = data[middle].data.key;

 92

if (to_find < key) {

high = middle - 1;

} else if (to_find > key) {

low = middle + 1;

} else {

return &data[middle];

}

}

101

return NULL;

}

104

int RadixMap_add(RadixMap * map, uint32_t key, uint32_t value)

{

check(key < UINT32_MAX, "Key can't be equal to UINT32_MAX.");

108

RMElement element = {.data = {.key = key,.value = value} };

check(map->end + 1 < map->max, "RadixMap is full.");

111

map->contents[map->end++] = element;

113

RadixMap_sort(map);

115

return 0;

117

error:

return -1;

}

121

int RadixMap_delete(RadixMap * map, RMElement * el)

{

check(map->end > 0, "There is nothing to delete.");

check(el != NULL, "Can't delete a NULL element.");

126

el->data.key = UINT32_MAX;

128

if (map->end > 1) {

// don't bother resorting a map of 1 length

RadixMap_sort(map);

}

133

map->end--;

135

return 0;

error:

return -1;

}
```

As usual, enter this in and get it working, along with the unit test, and then I’ll explain what’s happening. Take *special care* with the `radix_sort` function since it’s very particular in how it’s implemented.

`radixmap_tests.c`

---

[Click here to view code image](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch35_images.html#p216pro01a)

```
#include "minunit.h"

#include <lcthw/radixmap.h>

#include <time.h>

  4

static int make_random(RadixMap * map)

{

size_t i = 0;

  8

for (i = 0; i < map->max - 1; i++) {

uint32_t key = (uint32_t) (rand() | (rand() << 16));

check(RadixMap_add(map, key, i) == 0, "Failed to add key %u.",

key);

}

 14

return i;

 16

error:

return 0;

}

 20

static int check_order(RadixMap * map)

{

RMElement d1, d2;

unsigned int i = 0;

 25

// only signal errors if any (should not be)

for (i = 0; map->end > 0 && i < map->end - 1; i++) {

d1 = map->contents[i];

d2 = map->contents[i + 1];

 30

if (d1.data.key > d2.data.key) {

debug("FAIL:i=%u, key: %u, value: %u, equals max? %d\n", i,

d1.data.key, d1.data.value,

d2.data.key == UINT32_MAX);

return 0;

}

}

 38

return 1;

}

 41

static int test_search(RadixMap * map)

{

unsigned i = 0;

RMElement *d = NULL;

RMElement *found = NULL;

 47

for (i = map->end / 2; i < map->end; i++) {

d = &map->contents[i];

found = RadixMap_find(map, d->data.key);

check(found != NULL, "Didn't find %u at %u.", d->data.key, i);

check(found->data.key == d->data.key,

"Got the wrong result: %p:%u looking for %u at %u", found,

found->data.key, d->data.key, i);

}

 56

return 1;

error:

return 0;

}

 61

// test for big number of elements

static char *test_operations()

{

size_t N = 200;

 66

RadixMap *map = RadixMap_create(N);

mu_assert(map != NULL, "Failed to make the map.");

mu_assert(make_random(map), "Didn't make a random fake radix map.");

 70

RadixMap_sort(map);

mu_assert(check_order(map),

"Failed to properly sort the RadixMap.");

 74

mu_assert(test_search(map), "Failed the search test.");

mu_assert(check_order(map),

"RadixMap didn't stay sorted after search.");

 78

while (map->end > 0) {

RMElement *el = RadixMap_find(map,

map->contents[map->end / 2].data.key);

mu_assert(el != NULL, "Should get a result.");

 83

size_t old_end = map->end;

 85

mu_assert(RadixMap_delete(map, el) == 0, "Didn't delete it.");

mu_assert(old_end - 1 == map->end, "Wrong size after delete.");

 88

// test that the end is now the old value,

// but uint32 max so it trails off

mu_assert(check_order(map),

"RadixMap didn't stay sorted after delete.");

}

 94

RadixMap_destroy(map);

 96

return NULL;

}

 99

char *all_tests()

{

mu_suite_start();

srand(time(NULL));

104

mu_run_test(test_operations);

106

return NULL;

}

109

RUN_TESTS(all_tests);
```

I shouldn’t have to explain too much about the test. It’s simply simulating placing random integers into the `RadixMap`, and then making sure it can get them out reliably. Not too interesting.

In the `radixmap.c` file, most of the operations are easy to understand if you read the code. Here’s a description of what the basic functions are doing and how they work:

**RadixMap_create** As usual, I’m allocating all of the memory needed for the structures defined in `radixmap.h`. I’ll be using the `temp` and `contents` later when I talk about `radix_sort`.

**RadixMap_destroy** Again, I’m just destroying what was created.

**radix_sort** Here’s the meat of the data structure, but I’ll explain what it’s doing in the next section.

**RadixMap_sort** This uses the `radix_sort` function to actually sort the `contents`. It does this by sorting between the `contents` and `temp` until finally `contents` is sorted. You’ll see how this works when I describe `radix_sort` later.

**RadixMap_find** This is using a binary search algorithm to find a key you give it. I’ll explain how this works shortly.

**RadixMap_add** Using the `RadixMap_sort` function, this will add the key and value you request at the end, then simply sort it again so that everything is in the right place. Once everything is sorted, the `RadixMap_find` will work properly because it’s a binary search.

**RadixMap_delete** This works the same as `RadixMap_add`, except it deletes elements of the structure by setting their values to the max for a unsigned 32-bit integer, `UINT32_MAX`. This means that you can’t use that value as an key value, but it makes deleting elements easy. Simply set it to that and then sort, and it’ll get moved to the end. Now it’s deleted.

Study the code for the functions I described. That just leaves `RadixMap_sort`, `radix_sort`, and `RadixMap_find` to understand.

#### RadixMap_find and Binary Search

I’ll start with how the binary search is implemented. Binary search is a simple algorithm that most people can understand intuitively. In fact, you could take a deck of playing cards and do this manually. Here’s how this function works, and how a binary search is done, step by step:

• Set a high and low mark based on the size of the array.

• Get the middle element between the low and high marks.

• If the key is less-than, then the key must be below the middle. Set high to one less than middle.

• If the key is greater-than, then the key must be above the middle. Set the low mark one greater than the middle.

• If it’s equal, you found it. Stop.

• Keep looping until low and high pass each other. You won’t find it if you exit the loop.

What you’re effectively doing is guessing where the key might be by picking the middle and comparing it to the high and low marks. Since the data is sorted, you know that the the key has to be above or below your guess. If it’s below, then you just divided the search space in half. You keep going until you either find it or you overlap the boundaries and exhaust the search space.

#### RadixMap_sort and radix_sort

A radix sort is easy to understand if you try to do it manually first. What this algorithm does is exploit the fact that numbers are stored with a sequence of digits that go from least significant to most significant. It then takes the numbers and buckets them by the digit, and when it has processed all of the digits, the numbers come out sorted. At first it seems like magic, and honestly, looking at the code sure seems like it is, so try doing it manually once.

To do this algorithm, write out a bunch of three-digit numbers in a random order. Let’s say we do 223, 912, 275, 100, 633, 120, and 380.

• Place the number in buckets by the ones digit: `[380, 100, 120], [912], [633, 223], [275]`.

• I now have to go through each of these buckets in order, and then sort it by the tens digit: `[100], [912], [120, 223], [633], [275], [380]`.

• Now each bucket contains numbers that are sorted by the ones digit and then the tens digit. I need to then go through these in order and fill in the final hundreds digit: `[100, 120], [223, 275], [380], [633], [912]`.

• At this point each bucket is sorted by hundreds, tens and ones, and if I take each bucket in order, I get the final sorted list: `100, 120, 223, 275, 380, 633, 912`.

Make sure you do this a few times so you understand how it works. It really is a slick little algorithm. Most importantly, it will work on numbers of arbitrary size, so you can sort really huge numbers because you’re just doing them 1 byte at a time.

In my situation, the digits (also called place values) are individual 8-bit bytes, so I need 256 buckets to store the distribution of the numbers by their digits. I also need a way to store them such that I don’t use too much space. If you look at `radix_sort`, you’ll see that the first thing I do is build a `count` histogram so I know how many occurrences of each digit there are for the given `offset`.

Once I know the counts for each digit (all 256 of them), I can then use them as distribution points into a target array. For example, if I have 10 bytes that are 0x00, then I know I can place them in the first ten slots of the target array. This gives me an index for where they go in the target array, which is the second `for-loop` in `radix_sort`.

Finally, once I know where they can go in the target array I simply go through all of the digits in the `source` array for this `offset`, and place the numbers in their slots in order. Using the `ByteOf` macro helps keep the code clean, since there’s a bit of pointer hackery to make it work. However, the end result is that all of the integers will be placed in the bucket for their digit when the final `for-loop` is done.

What becomes interesting is how I use this in `RadixMap_sort` to sort these 64-bit integers by just the first 32 bits. Remember how I have the key and value in a union for the `RMElement` type? That means that to sort this array by the key, I only need to sort the first 4 bytes (32 bits / 8 bits per byte) of every integer.

If you look at the `RadixMap_sort`, you see that I grab a quick pointer to the `contents` and `temp` for source and target arrays, and then I call `radix_sort` four times. Each time I call it, I alternate source and target, and do the next byte. When I’m done, the `radix_sort` has done its job and the final copy has been sorted into the `contents`.

### How to Improve It

There is a big disadvantage to this implementation because it has to process the entire array four times on every insertion. It does do it fast, but it’d be better if you could limit the amount of sorting by the size of what needs to be sorted.

There are two ways you can improve this implementation:

• Use a binary search to find the minimum position for the new element, then only sort from there to the end. You find the minimum, put the new element on the end, and then just sort from the minimum on. This will cut your sort space down considerably most of the time.

• Keep track of the biggest key currently being used, and then only sort enough digits to handle that key. You can also keep track of the smallest number, and then only sort the digits necessary for the range. To do this, you’ll have to start caring about CPU integer ordering (endianness).

Try these optimizations, but only after you augment the unit test with some timing information so you can see if you’re actually improving the speed of the implementation.

### Extra Credit

• Implement quicksort, heapsort, and merge sort and then provide a `#define` that lets you pick among the three, or create a second set of functions you can call. Use the technique I taught you to read the Wikipedia page for the algorithm, and then implement it with the pseudo-code.

• Compare the performance of your optimizations to the original implementations.

• Use these sorting functions to create a `DArray_sort_add` that adds elements to the `DArray` but sorts the array afterward.

• Write a `DArray_find` that uses the binary search algorithm from `RadixMap_find` and the `DArray_compare` to find elements in a sorted `DArray`.

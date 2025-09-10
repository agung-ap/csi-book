## Exercise 44. Ring Buffer

Ring buffers are incredibly useful when processing asynchronous I/O. They allow one side to receive data in random intervals of random sizes, but feed cohesive chunks to another side in set sizes or intervals. They are a variant on the `Queue` data structure but focus on blocks of bytes instead of a list of pointers. In this exercise, I’m going to show you the `RingBuffer` code, and then have you make a full unit test for it.

`ringbuffer.h`

---

[Click here to view code image](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch44_images.html#p310pro01a)

```
#ifndef _lcthw_RingBuffer_h

#define _lcthw_RingBuffer_h

  3

#include <lcthw/bstrlib.h>

  5

typedef struct {

char *buffer;

int length;

int start;

int end;

} RingBuffer;

 12

RingBuffer *RingBuffer_create(int length);

 14

void RingBuffer_destroy(RingBuffer * buffer);

 16

int RingBuffer_read(RingBuffer * buffer, char *target, int amount);

 18

int RingBuffer_write(RingBuffer * buffer, char *data, int length);

 20

int RingBuffer_empty(RingBuffer * buffer);

 22

int RingBuffer_full(RingBuffer * buffer);

 24

int RingBuffer_available_data(RingBuffer * buffer);

 26

int RingBuffer_available_space(RingBuffer * buffer);

 28

bstring RingBuffer_gets(RingBuffer * buffer, int amount);

 30

#define RingBuffer_available_data(B) (\

((B)->end + 1) % (B)->length - (B)->start - 1)

 33

#define RingBuffer_available_space(B) (\

(B)->length - (B)->end - 1)

 36

#define RingBuffer_full(B) (RingBuffer_available_data((B))\

- (B)->length == 0)

 39

#define RingBuffer_empty(B) (\

RingBuffer_available_data((B)) == 0)

 42

#define RingBuffer_puts(B, D) RingBuffer_write(\

(B), bdata((D)), blength((D)))

 45

#define RingBuffer_get_all(B) RingBuffer_gets(\

(B), RingBuffer_available_data((B)))

 48

#define RingBuffer_starts_at(B) (\

(B)->buffer + (B)->start)

 51

#define RingBuffer_ends_at(B) (\

(B)->buffer + (B)->end)

 54

#define RingBuffer_commit_read(B, A) (\

(B)->start = ((B)->start + (A)) % (B)->length)

 57

#define RingBuffer_commit_write(B, A) (\

(B)->end = ((B)->end + (A)) % (B)->length)

 60

#endif
```

Looking at the data structure, you see I have a `buffer`, `start`, and `end`. A `RingBuffer` does nothing more than move the `start` and `end` around the buffer so that it loops whenever it reaches the buffer’s end. Doing this gives the illusion of an infinite read device in a small space. I then have a bunch of macros that do various calculations based on this.

Here’s the implementation, which is a much better explanation of how this works.

`ringbuffer.c`

---

[Click here to view code image](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch44_images.html#p311pro01a)

```
#undef NDEBUG

#include <assert.h>

#include <stdio.h>

#include <stdlib.h>

#include <string.h>

#include <lcthw/dbg.h>

#include <lcthw/ringbuffer.h>

  8

RingBuffer *RingBuffer_create(int length)

{

RingBuffer *buffer = calloc(1, sizeof(RingBuffer));

buffer->length = length + 1;

buffer->start = 0;

buffer->end = 0;

buffer->buffer = calloc(buffer->length, 1);

 16

return buffer;

}

 19

void RingBuffer_destroy(RingBuffer * buffer)

{

if (buffer) {

free(buffer->buffer);

free(buffer);

}

}

 27

int RingBuffer_write(RingBuffer * buffer, char *data, int length)

{

if (RingBuffer_available_data(buffer) == 0) {

buffer->start = buffer->end = 0;

}

 33

check(length <= RingBuffer_available_space(buffer),

"Not enough space: %d request, %d available",

RingBuffer_available_data(buffer), length);

 37

void *result = memcpy(RingBuffer_ends_at(buffer), data, length);

check(result != NULL, "Failed to write data into buffer.");

 40

RingBuffer_commit_write(buffer, length);

 42

return length;

error:

return -1;

}

 47

int RingBuffer_read(RingBuffer * buffer, char *target, int amount)

{

check_debug(amount <= RingBuffer_available_data(buffer),

"Not enough in the buffer: has %d, needs %d",

RingBuffer_available_data(buffer), amount);

 53

void *result = memcpy(target, RingBuffer_starts_at(buffer), amount);

check(result != NULL, "Failed to write buffer into data.");

 56

RingBuffer_commit_read(buffer, amount);

 58

if (buffer->end == buffer->start) {

buffer->start = buffer->end = 0;

}

 62

return amount;

error:

return -1;

}

 67

bstring RingBuffer_gets(RingBuffer * buffer, int amount)

{

check(amount > 0, "Need more than 0 for gets, you gave: %d ",

amount);

check_debug(amount <= RingBuffer_available_data(buffer),

"Not enough in the buffer.");

 74

bstring result = blk2bstr(RingBuffer_starts_at(buffer), amount);

check(result != NULL, "Failed to create gets result.");

check(blength(result) == amount, "Wrong result length.");

 78

RingBuffer_commit_read(buffer, amount);

assert(RingBuffer_available_data(buffer) >= 0

&& "Error in read commit.");

 82

return result;

error:

return NULL;

}
```

This is all there is to a basic `RingBuffer` implementation. You can read and write blocks of data to it. You can ask how much is in it and how much space it has. There are some fancier ring buffers that use tricks on the OS to create an imaginary infinite store, but those aren’t portable.

Since my `RingBuffer` deals with reading and writing blocks of memory, I’m making sure that any time `end == start`, I reset them to 0 (zero) so that they go to the beginning of the buffer. In the Wikipedia version it isn’t writing blocks of data, so it only has to move `end` and `start` around in a circle. To better handle blocks, you have to drop to the beginning of the internal buffer whenever the data is empty.

### The Unit Test

For your unit test, you’ll want to test as many possible conditions as you can. The easiest way to do that is to preconstruct different `RingBuffer` structs, and then manually check that the functions and math work right. For example, you could make one where `end` is right at the end of the buffer and `start` is right before the buffer, and then see how it fails.

### What You Should See

Here’s my `ringbuffer_tests` run:

`Exercise 44.1 Session`

---

[Click here to view code image](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch44_images.html#p313pro01a)

```bash
$ ./tests/ringbuffer_tests

DEBUG tests/ringbuffer_tests.c:60: ----- RUNNING: ./tests/ringbuffer_tests

----

RUNNING: ./tests/ringbuffer_tests

DEBUG tests/ringbuffer_tests.c:53:

----- test_create

DEBUG tests/ringbuffer_tests.c:54:

----- test_read_write

DEBUG tests/ringbuffer_tests.c:55:

----- test_destroy

ALL TESTS PASSED

Tests run: 3

$
```

You should have at least three tests that confirm all of the basic operations, and then see how much more you can test beyond what I’ve done.

### How to Improve It

As usual, you should go back and add defensive programming checks to this exercise. Hopefully you’ve been doing this, because the base code in most of `liblcthw` doesn’t have the common defensive programming checks that I’m teaching you. I leave this to you so that you can get used to improving code with these extra checks.

For example, in this ring buffer, there’s not a lot of checking that an access will actually be inside the buffer.

If you read the “Circular buffer” page on Wikipedia, you’ll see the “Optimized POSIX implementation” that uses Portable Operating System Interface (POSIX)-specific calls to create an infinite space. Study that and I’ll have you try it in the Extra Credit section.

### Extra Credit

• Create an alternative implementation of `RingBuffer` that uses the POSIX trick and then create a unit test for it.

• Add a performance comparison test to this unit test that compares the two versions by fuzzing them with random data and random read/write operations. Make sure that you set up this fuzzing so that the same operations are done to each version, and you can compare them between runs.

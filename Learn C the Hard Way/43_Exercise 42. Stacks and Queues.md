## Exercise 42. Stacks and Queues

At this point in the book, you should know most of the data structures that are used to build all of the other data structures. If you have some kind of `List`, `DArray`, `Hashmap`, and `Tree`, then you can build almost anything else out there. Everything else you run into either uses these or some variant of these. If it doesn’t, then it’s most likely an exotic data structure that you probably won’t need.

`Stacks` and `Queues` are very simple data structures that are really variants of the `List` data structure. All they do is use a `List` with a discipline or convention that says you always place elements on one end of the `List`. For a `Stack`, you always push and pop. For a `Queue`, you always shift to the front, but pop from the end.

I can implement both data structures using nothing but the CPP and two header files. My header files are 21 lines long and do all of the `Stack` and `Queue` operations without any fancy `define`s.

To see if you’ve been paying attention, I’m going to show you the unit tests, and then have *you* implement the header files needed to make them work. To pass this exercise, you can’t create any `stack.c` or `queue.c` implementation files. Use only the `stack.h` and `queue.h` files to make the tests run.

`stack_tests.c`

---

[Click here to view code image](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch42_images.html#p296pro01a)

```
#include "minunit.h"

#include <lcthw/stack.h>

#include <assert.h>

 4

static Stack *stack = NULL;

char *tests[] = { "test1 data", "test2 data", "test3 data" };

 7

#define NUM_TESTS 3

 9

char *test_create()

{

stack = Stack_create();

mu_assert(stack != NULL, "Failed to create stack.");

14

return NULL;

}

17

char *test_destroy()

{

mu_assert(stack != NULL, "Failed to make stack #2");

Stack_destroy(stack);

22

return NULL;

}

25

char *test_push_pop()

{

int i = 0;

for (i = 0; i < NUM_TESTS; i++) {

Stack_push(stack, tests[i]);

mu_assert(Stack_peek(stack) == tests[i], "Wrong next value.");

}

33

mu_assert(Stack_count(stack) == NUM_TESTS, "Wrong count on push.");

35

STACK_FOREACH(stack, cur) {

debug("VAL: %s", (char *)cur->value);

}

39

for (i = NUM_TESTS - 1; i >= 0; i--) {

char *val = Stack_pop(stack);

mu_assert(val == tests[i], "Wrong value on pop.");

}

44

mu_assert(Stack_count(stack) == 0, "Wrong count after pop.");

46

return NULL;

}

49

char *all_tests()

{

mu_suite_start();

53

mu_run_test(test_create);

mu_run_test(test_push_pop);

mu_run_test(test_destroy);

57

return NULL;

}

60

RUN_TESTS(all_tests);
```

Then, the `queue_tests.c` is almost the same, only using `Queue`:

`queue_tests.c`

---

[Click here to view code image](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch42_images.html#p297pro01a)

```
#include "minunit.h"

#include <lcthw/queue.h>

#include <assert.h>

  4

static Queue *queue = NULL;

char *tests[] = { "test1 data", "test2 data", "test3 data" };

  7

#define NUM_TESTS 3

  9

char *test_create()

{

queue = Queue_create();

mu_assert(queue != NULL, "Failed to create queue.");

 14

return NULL;

}

 17

char *test_destroy()

{

mu_assert(queue != NULL, "Failed to make queue #2");

Queue_destroy(queue);

 22

return NULL;

}

 25

char *test_send_recv()

{

int i = 0;

for (i = 0; i < NUM_TESTS; i++) {

Queue_send(queue, tests[i]);

mu_assert(Queue_peek(queue) == tests[0], "Wrong next value.");

}

 33

mu_assert(Queue_count(queue) == NUM_TESTS, "Wrong count on send.");

 35

QUEUE_FOREACH(queue, cur) {

debug("VAL: %s", (char *)cur->value);

}

 39

for (i = 0; i < NUM_TESTS; i++) {

char *val = Queue_recv(queue);

mu_assert(val == tests[i], "Wrong value on recv.");

}

 44

mu_assert(Queue_count(queue) == 0, "Wrong count after recv.");

 46

return NULL;

}

 49

char *all_tests()

{

mu_suite_start();

 53

mu_run_test(test_create);

mu_run_test(test_send_recv);

mu_run_test(test_destroy);

 57

return NULL;

}

 60

RUN_TESTS(all_tests);
```

### What You Should See

Your unit test should run without your having to change the tests, and it should pass the debugger with no memory errors. Here’s what it looks like if I run `stack_tests` directly:

`Exercise 42.1 Session`

---

[Click here to view code image](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch42_images.html#p299pro01a)

```bash
$ ./tests/stack_tests

DEBUG tests/stack_tests.c:60: ----- RUNNING: ./tests/stack_tests

----

RUNNING: ./tests/stack_tests

DEBUG tests/stack_tests.c:53:

----- test_create

DEBUG tests/stack_tests.c:54:

----- test_push_pop

DEBUG tests/stack_tests.c:37: VAL: test3 data

DEBUG tests/stack_tests.c:37: VAL: test2 data

DEBUG tests/stack_tests.c:37: VAL: test1 data

DEBUG tests/stack_tests.c:55:

----- test_destroy

ALL TESTS PASSED

Tests run: 3

$
```

The `queue_test` is basically the same kind of output, so I shouldn’t have to show it to you at this stage.

### How to Improve It

The only real improvement you could make to this is switching from a `List` to a `DArray`. The `Queue` data structure is more difficult to do with a `DArray` because it works at both ends of the list of nodes.

One disadvantage of doing this entirely in a header file is that you can’t easily performance tune it. Mostly, what you’re doing with this technique is establishing a protocol for how to use a `List` in a certain style. When performance tuning, if you make `List` fast, then these two should improve as well.

### Extra Credit

• Implement `Stack` using `DArray` instead of `List`, but without changing the unit test. That means you’ll have to create your own `STACK_FOREACH`.

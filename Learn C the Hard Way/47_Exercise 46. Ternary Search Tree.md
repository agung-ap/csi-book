## Exercise 46. Ternary Search Tree

The final data structure that I’ll show you is called the *TSTree*, which is similar to the `BSTree`, except it has three branches: `low`, `equal`, and `high`. It’s primarily used just like `BSTree` and `Hashmap` to store key/value data, but it works off of the individual characters in the keys. This gives the `TSTree` some abilities that neither `BSTree` nor `Hashmap` has.

In a `TSTree`, every key is a string, and it’s inserted by walking through and building a tree based on the equality of the characters in the string. It starts at the root, looks at the character for that node, and if it’s lower, equal to, or higher than that, then it goes in that direction. You can see this in the header file:

`tstree.h`

---

[Click here to view code image](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch46_images.html#p322pro01a)

```
#ifndef _lcthw_TSTree_h

#define _lcthw_TSTree_h



#include <stdlib.h>

#include <lcthw/darray.h>



typedef struct TSTree {

    char splitchar;

    struct TSTree *low;

    struct TSTree *equal;

    struct TSTree *high;

    void *value;

} TSTree;



void *TSTree_search(TSTree * root, const char *key, size_t len);



void *TSTree_search_prefix(TSTree * root, const char *key, size_t len);



typedef void (*TSTree_traverse_cb) (void *value, void *data);



TSTree *TSTree_insert(TSTree * node, const char *key, size_t len,

        void *value);



void TSTree_traverse(TSTree * node, TSTree_traverse_cb cb, void *data);



void TSTree_destroy(TSTree * root);



#endif
```

The `TSTree` has the following elements:

**splitchar** The character at this point in the tree.

**low** The branch that’s lower than `splitchar`.

**equal** The branch that’s equal to `splitchar`.

**high** The branch that’s higher than `splitchar`.

**value** The value set for a string at that point with `splitchar`.

You can see that this implementation has the following operations:

**search** A typical operation to find a value for this `key`.

**search_prefix** This operation finds the first value that has this as a prefix of its key. This is the an operation that you can’t easily do in a `BSTree` or `Hashmap`.

**insert** This breaks the `key` down by each character and inserts them into the tree.

**traverse** This walks through the tree, allowing you to collect or analyze all the keys and values it contains.

The only thing missing is a `TSTree_delete`, and that’s because it’s a horribly expensive operation, even more expensive than `BSTree_delete`. When I use `TSTree` structures, I treat them as constant data that I plan on traversing many times, and not removing anything from them. They are very fast for this, but aren’t good if you need to insert and delete things quickly. For that, I use `Hashmap`, since it beats both `BSTree` and `TSTree`.

The implementation for the `TSTree` is actually simple, but it might be hard to follow at first. I’ll break it down after you enter it in:

`tstree.c`

---

[Click here to view code image](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch46_images.html#p323pro01a)

```
#include <stdlib.h>

#include <stdio.h>

#include <assert.h>

#include <lcthw/dbg.h>

#include <lcthw/tstree.h>

  6

static inline TSTree *TSTree_insert_base(TSTree * root, TSTree * node,

const char *key, size_t len,

void *value)

{

if (node == NULL) {

node = (TSTree *) calloc(1, sizeof(TSTree));

 13

if (root == NULL) {

root = node;

}

 17

node->splitchar = *key;

}

 20

if (*key < node->splitchar) {

node->low = TSTree_insert_base(

root, node->low, key, len, value);

} else if (*key == node->splitchar) {

if (len > 1) {

node->equal = TSTree_insert_base(

root, node->equal, key + 1, len - 1, value);

} else {

assert(node->value == NULL && "Duplicate insert into tst.");

node->value = value;

}

} else {

node->high = TSTree_insert_base(

root, node->high, key, len, value);

}

 36

return node;

}

 39

TSTree *TSTree_insert(TSTree * node, const char *key, size_t len,

void *value)

{

return TSTree_insert_base(node, node, key, len, value);

}

 45

void *TSTree_search(TSTree * root, const char *key, size_t len)

{

TSTree *node = root;

size_t i = 0;

 50

while (i < len && node) {

if (key[i] < node->splitchar) {

node = node->low;

} else if (key[i] == node->splitchar) {

i++;

if (i < len)

node = node->equal;

} else {

node = node->high;

}

}

 62

if (node) {

return node->value;

} else {

return NULL;

}

}

 69

void *TSTree_search_prefix(TSTree * root, const char *key, size_t len)

{

if (len == 0)

return NULL;

 74

TSTree *node = root;

TSTree *last = NULL;

size_t i = 0;

 78

while (i < len && node) {

if (key[i] < node->splitchar) {

node = node->low;

} else if (key[i] == node->splitchar) {

i++;

if (i < len) {

if (node->value)

last = node;

node = node->equal;

}

} else {

node = node->high;

}

}

 93

node = node ? node : last;

 95

// traverse until we find the first value in the equal chain

// this is then the first node with this prefix

while (node && !node->value) {

node = node->equal;

}

101

return node ? node->value : NULL;

}

104

void TSTree_traverse(TSTree * node, TSTree_traverse_cb cb, void *data)

{

if (!node)

return;

109

if (node->low)

TSTree_traverse(node->low, cb, data);

112

if (node->equal) {

TSTree_traverse(node->equal, cb, data);

}

116

if (node->high)

TSTree_traverse(node->high, cb, data);

119

if (node->value)

cb(node->value, data);

}

123

void TSTree_destroy(TSTree * node)

{

if (node == NULL)

return;

128

if (node->low)

TSTree_destroy(node->low);

131

if (node->equal) {

TSTree_destroy(node->equal);

}

135

if (node->high)

TSTree_destroy(node->high);

138

free(node);

}
```

For `TSTree_insert`, I’m using the same pattern for recursive structures where I have a small function that calls the real recursive function. I’m not doing any additional checks here, but you should add the usual defensive programming checks to it. One thing to keep in mind is that it’s using a slightly different design that doesn’t have a separate `TSTree_create` function. However, if you pass it a `NULL` for the `node`, then it will create it and return the final value.

That means I need to break down `TSTree_insert_base` so that you understand the insert operation:

**tstree.c:10-18** As I mentioned, if given a `NULL`, then I need to make this node and assign the `*key` (current character) to it. This is used to build the tree as we insert keys.

**tstree.c:20-21** If the `*key` is less than this, then recurse, but go to the `low` branch.

**tstree.c:22** This `splitchar` is equal, so I want to go and deal with equality. This will happen if we just create this node, so we’ll be building the tree at this point.

**tstree.c:23-24** There are still characters to handle, so recurse down the `equal` branch, but go to the next `*key` character.

**tstree.c:26-27** This is the last character, so I set the value and that’s it. I have an `assert` here in case of a duplicate.

**tstree.c:29-30** The last condition is that this `*key` is greater than `splitchar`, so I need to recurse down the `high` branch.

The key to this data structure is the fact that I’m only incrementing the character when a `splitchar` is equal. For the other two conditions, I just walk through the tree until I hit an equal character to recurse into next. What this does is make it very fast *not* to find a key. I can get a bad key, and simply walk through a few `high` and `low` nodes until I hit a dead end before I know that this key doesn’t exist. I don’t need to process every character of the key or every node of the tree.

Once you understand that, then move on to analyzing how `TSTree_search` works.

**tstree.c:46** I don’t need to process the tree recursively in the `TSTree`. I can just use a `while-loop` and a `node` for where I currently am.

**tstree.c:47-48** If the current character is less than the node `splitchar`, then go low.

**tstree.c:49-51** If it’s equal, then increment `i` and go equal as long as it’s not the last character. That’s why the `if(i < len)` is there, so that I don’t go too far past the final `value`.

**tstree.c:52-53** Otherwise, I go `high`, since the character is greater.

**tstree.c:57-61** If I have a node after the loop, then return its `value`, otherwise return `NULL`.

This isn’t too difficult to understand, and you can see that it’s almost exactly the same algorithm for the `TSTree_search_prefix` function. The only difference is that I’m not trying to find an exact match, but find the longest prefix I can. To do that, I keep track of the `last` node that was equal, and then after the search loop, walk through that node until I find a `value`.

Looking at `TSTree_search_prefix`, you can start to see the second advantage a `TSTree` has over the `BSTree` and `Hashmap` for finding strings. Given any key of *X* length, you can find any key in *X* moves. You can also find the first prefix in *X* moves, plus *N* more depending on how big the matching key is. If the biggest key in the tree is ten characters long, then you can find any prefix in that key in ten moves. More importantly, you can do all of this by comparing each character of the key *once*.

In comparison, to do the same with a `BSTree`, you would have to check the prefixes of each character in every possible matching node in the `BSTree` against the characters in the prefix. It’s the same for finding keys or seeing if a key doesn’t exist. You have to compare each character against most of the characters in the `BSTree` to find or not find a match.

A `Hashmap` is even worse for finding prefixes, because you can’t hash just the prefix. Basically, you can’t do this efficiently in a `Hashmap` unless the data is something you can parse, like a URL. Even then, that usually requires whole trees of `Hashmaps`.

The last two functions should be easy for you to analyze since they’re the typical traversing and destroying operations that you’ve already seen in other data structures.

Finally, I have a simple unit test for the whole thing to make sure it works right:

`tstree_tests.c`

---

[Click here to view code image](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch46_images.html#p328pro01a)

```
#include "minunit.h"

#include <lcthw/tstree.h>

#include <string.h>

#include <assert.h>

#include <lcthw/bstrlib.h>

  6

TSTree *node = NULL;

char *valueA = "VALUEA";

char *valueB = "VALUEB";

char *value2 = "VALUE2";

char *value4 = "VALUE4";

char *reverse = "VALUER";

int traverse_count = 0;

 14

struct tagbstring test1 = bsStatic("TEST");

struct tagbstring test2 = bsStatic("TEST2");

struct tagbstring test3 = bsStatic("TSET");

struct tagbstring test4 = bsStatic("T");

 19

char *test_insert()

{

node = TSTree_insert(node, bdata(&test1), blength(&test1), valueA);

mu_assert(node != NULL, "Failed to insert into tst.");

 24

node = TSTree_insert(node, bdata(&test2), blength(&test2), value2);

mu_assert(node != NULL,

"Failed to insert into tst with second name.");

 28

node = TSTree_insert(node, bdata(&test3), blength(&test3), reverse);

mu_assert(node != NULL,

"Failed to insert into tst with reverse name.");

 32

node = TSTree_insert(node, bdata(&test4), blength(&test4), value4);

mu_assert(node != NULL,

"Failed to insert into tst with second name.");

 36

return NULL;

}

 39

char *test_search_exact()

{

// tst returns the last one inserted

void *res = TSTree_search(node, bdata(&test1), blength(&test1));

mu_assert(res == valueA,

"Got the wrong value back, should get A not B.");

 46

// tst does not find if not exact

res = TSTree_search(node, "TESTNO", strlen("TESTNO"));

mu_assert(res == NULL, "Should not find anything.");

 50

return NULL;

}

 53

char *test_search_prefix()

{

void *res = TSTree_search_prefix(

node, bdata(&test1), blength(&test1));

debug("result: %p, expected: %p", res, valueA);

mu_assert(res == valueA, "Got wrong valueA by prefix.");

 60

res = TSTree_search_prefix(node, bdata(&test1), 1);

debug("result: %p, expected: %p", res, valueA);

mu_assert(res == value4, "Got wrong value4 for prefix of 1.");

 64

res = TSTree_search_prefix(node, "TE", strlen("TE"));

mu_assert(res != NULL, "Should find for short prefix.");

 67

res = TSTree_search_prefix(node, "TE--", strlen("TE--"));

mu_assert(res != NULL, "Should find for partial prefix.");

 70

return NULL;

}

 73

void TSTree_traverse_test_cb(void *value, void *data)

{

assert(value != NULL && "Should not get NULL value.");

assert(data == valueA && "Expecting valueA as the data.");

traverse_count++;

}

 80

char *test_traverse()

{

traverse_count = 0;

TSTree_traverse(node, TSTree_traverse_test_cb, valueA);

debug("traverse count is: %d", traverse_count);

mu_assert(traverse_count == 4, "Didn't find 4 keys.");

 87

return NULL;

}

 90

char *test_destroy()

{

TSTree_destroy(node);

 94

return NULL;

}

 97

char *all_tests()

{

mu_suite_start();

101

mu_run_test(test_insert);

mu_run_test(test_search_exact);

mu_run_test(test_search_prefix);

mu_run_test(test_traverse);

mu_run_test(test_destroy);

107

return NULL;

}

110

RUN_TESTS(all_tests);
```

### Advantages and Disadvantages

There are other interesting, practical things you can do with a `TSTree`:

• In addition to finding prefixes, you can reverse all of the keys you insert, and then find things by *suffix*. I use this to look up host names, since I want to find `*.learncodethe hardway.com`. If I go backward, I can match them quickly.

• You can do approximate matching, by gathering all of the nodes that have most of the same characters as the key, or using other algorithms to find a close match.

• You can find all of the keys that have a part in the middle.

I’ve already talked about some of the things `TSTree`s can do, but they aren’t the best data structure all the time. Here are the disadvantages of the `TSTree`:

• As I mentioned, deleting from them is murder. They are better used for data that needs to be looked up fast and rarely removed. If you need to delete, then simply disable the `value` and then periodically rebuild the tree when it gets too big.

• It uses a ton of memory compared to `BSTree` and `Hashmaps` for the same key space. Think about it. It’s using a full node for each character in every key. It might work better for smaller keys, but if you put a lot in a `TSTree`, it will get huge.

• They also don’t work well with large keys, but large is subjective. As usual, test it first. If you’re trying to store 10,000-character keys, then use a `Hashmap`.

### How to Improve It

As usual, go through and improve this by adding the defensive programming preconditions, asserts, and checks to each function. There are some other possible improvements, but you don’t necessarily have to implement all of these:

• You could allow duplicates by using a `DArray` instead of the `value`.

• As I mentioned earlier, deleting is hard, but you could simulate it by setting the values to `NULL` so that they are effectively gone.

• There are no ways to collect all of the possible matching values. I’ll have you implement that in an Extra Credit exercise.

• There are other algorithms that are more complex but have slightly better properties. Take a look at suffix array, suffix tree, and radix tree structures.

### Extra Credit

• Implement a `TSTree_collect` that returns a `DArray` containing all of the keys that match the given prefix.

• Implement `TSTree_search_suffix` and a `TSTree_insert_suffix` so you can do suffix searches and inserts.

• Use the debugger to see how this structure stores data compared to the `BSTree` and `Hashmap`.

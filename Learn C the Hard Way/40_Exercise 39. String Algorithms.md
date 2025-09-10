## Exercise 39. String Algorithms

In this exercise, I’m going to show you a supposedly faster string search algorithm, called `binstr`, and compare it to the one that exists in `bstrlib.c`. The documentation for `binstr` says that it uses a simple “brute force” string search to find the first instance. The one that I’ll implement will use the Boyer-Moore-Horspool (BMH) algorithm, which is supposed to be faster if you analyze the theoretical time. Assuming my implementation isn’t flawed, you’ll see that the practical time for BMH is much worse than the simple brute force of `binstr`.

The point of this exercise isn’t really to explain the algorithm, because it’s simple enough for you to read the “Boyer-Moore-Horspool algorithm” page on Wikipedia. The gist of this algorithm is that it calculates a *skip characters* list as a first operation, then it uses this list to quickly scan through the string. It’s supposed to be faster than brute force, so let’s get the code into the right files and see.

First, I have the header:

`string_algos.h`

---

[Click here to view code image](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch39_images.html#p248pro01a)

```
#ifndef string_algos_h

#define string_algos_h



#include <lcthw/bstrlib.h>

#include <lcthw/darray.h>



typedef struct StringScanner {

    bstring in;

    const unsigned char *haystack;

    ssize_t hlen;

    const unsigned char *needle;

    ssize_t nlen;

    size_t skip_chars[UCHAR_MAX + 1];

} StringScanner;



int String_find(bstring in, bstring what);



StringScanner *StringScanner_create(bstring in);



int StringScanner_scan(StringScanner * scan, bstring tofind);



void StringScanner_destroy(StringScanner * scan);



#endif
```

In order to see the effects of this skip characters list, I’m going to make two versions of the BMH algorithm:

**String_find** This simply finds the first instance of one string in another, doing the entire algorithm in one shot.

**StringScanner_scan** This uses a `StringScanner` state structure to separate the skip list build from the actual find. This will let me see what impact that has on performance. This model also gives me the advantage of incrementally scanning for one string in another and quickly finding all instances.

Once you have that, here’s the implementation:

`string_algos.c`

---

[Click here to view code image](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch39_images.html#p249pro01a)

```
#include <lcthw/string_algos.h>

#include <limits.h>

  3

static inline void String_setup_skip_chars(size_t * skip_chars,

const unsigned char *needle,

ssize_t nlen)

{

size_t i = 0;

size_t last = nlen - 1;

 10

for (i = 0; i < UCHAR_MAX + 1; i++) {

skip_chars[i] = nlen;

}

 14

for (i = 0; i < last; i++) {

skip_chars[needle[i]] = last - i;

}

}

 19

static inline const unsigned char *String_base_search(const unsigned

char *haystack,

ssize_t hlen,

const unsigned

char *needle,

ssize_t nlen,

size_t *

skip_chars)

{

size_t i = 0;

size_t last = nlen - 1;

 31

assert(haystack != NULL && "Given bad haystack to search.");

assert(needle != NULL && "Given bad needle to search for.");

 34

check(nlen > 0, "nlen can't be <= 0");

check(hlen > 0, "hlen can't be <= 0");

 37

while (hlen >= nlen) {

for (i = last; haystack[i] == needle[i]; i--) {

if (i == 0) {

return haystack;

}

}

 44

hlen -= skip_chars[haystack[last]];

haystack += skip_chars[haystack[last]];

}

 48

error:                   // fallthrough

return NULL;

}

 52

int String_find(bstring in, bstring what)

{

const unsigned char *found = NULL;

 56

const unsigned char *haystack = (const unsigned char *)bdata(in);

ssize_t hlen = blength(in);

const unsigned char *needle = (const unsigned char *)bdata(what);

ssize_t nlen = blength(what);

size_t skip_chars[UCHAR_MAX + 1] = { 0 };

 62

String_setup_skip_chars(skip_chars, needle, nlen);

 64

found = String_base_search(haystack, hlen,

needle, nlen, skip_chars);

 67

return found != NULL ? found - haystack : -1;

}

 70

StringScanner *StringScanner_create(bstring in)

{

StringScanner *scan = calloc(1, sizeof(StringScanner));

check_mem(scan);

 75

scan->in = in;

scan->haystack = (const unsigned char *)bdata(in);

scan->hlen = blength(in);

 79

assert(scan != NULL && "fuck");

return scan;

 82

error:

free(scan);

return NULL;

}

 87

static inline void StringScanner_set_needle(StringScanner * scan,

bstring tofind)

{

scan->needle = (const unsigned char *)bdata(tofind);

scan->nlen = blength(tofind);

 93

String_setup_skip_chars(scan->skip_chars, scan->needle, scan->nlen);

}

 96

static inline void StringScanner_reset(StringScanner * scan)

{

scan->haystack = (const unsigned char *)bdata(scan->in);

scan->hlen = blength(scan->in);

}

102

int StringScanner_scan(StringScanner * scan, bstring tofind)

{

const unsigned char *found = NULL;

ssize_t found_at = 0;

107

if (scan->hlen <= 0) {

StringScanner_reset(scan);

return -1;

}

112

if ((const unsigned char *)bdata(tofind) != scan->needle) {

StringScanner_set_needle(scan, tofind);

}

116

found = String_base_search(scan->haystack, scan->hlen,

scan->needle, scan->nlen,

scan->skip_chars);

120

if (found) {

found_at = found - (const unsigned char *)bdata(scan->in);

scan->haystack = found + scan->nlen;

scan->hlen -= found_at - scan->nlen;

} else {

// done, reset the setup

StringScanner_reset(scan);

found_at = -1;

}

130

return found_at;

}

133

void StringScanner_destroy(StringScanner * scan)

{

if (scan) {

free(scan);

}

}
```

The entire algorithm is in two `static inline` functions called `String_setup_skip_chars` and `String_base_search`. These are then used in the other functions to actually implement the searching styles I want. Study these first two functions and compare them to the Wikipedia description so that you know what’s going on.

The `String_find` then just uses these two functions to do a find and return the position found. It’s very simple, and I’ll use it to see how this build `skip_chars` phase impacts real, practical performance. Keep in mind that you could maybe make this faster, but I’m teaching you how to confirm theoretical speed after you implement an algorithm.

The `StringScanner_scan` function then follows the common pattern I use of create, scan, and destroy, and is used to incrementally scan a string for another string. You’ll see how this is used when I show you the unit test that will test this out.

Finally, I have the unit test that first confirms that this is all working, then it runs simple performance tests for all three, finding algorithms in a *commented out section*.

`string_algos_tests.c`

---

[Click here to view code image](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch39_images.html#p252pro01a)

```
#include "minunit.h"

#include <lcthw/string_algos.h>

#include <lcthw/bstrlib.h>

#include <time.h>

  5

struct tagbstring IN_STR = bsStatic(

"I have ALPHA beta ALPHA and oranges ALPHA");

struct tagbstring ALPHA = bsStatic("ALPHA");

const int TEST_TIME = 1;

 10

char *test_find_and_scan()

{

StringScanner *scan = StringScanner_create(&IN_STR);

mu_assert(scan != NULL, "Failed to make the scanner.");

 15

int find_i = String_find(&IN_STR, &ALPHA);

mu_assert(find_i > 0, "Failed to find 'ALPHA' in test string.");

 18

int scan_i = StringScanner_scan(scan, &ALPHA);

mu_assert(scan_i > 0, "Failed to find 'ALPHA' with scan.");

mu_assert(scan_i == find_i, "find and scan don't match");

 22

scan_i = StringScanner_scan(scan, &ALPHA);

mu_assert(scan_i > find_i,

"should find another ALPHA after the first");

 26

scan_i = StringScanner_scan(scan, &ALPHA);

mu_assert(scan_i > find_i,

"should find another ALPHA after the first");

 30

mu_assert(StringScanner_scan(scan, &ALPHA) == -1,

"shouldn't find it");

 33

StringScanner_destroy(scan);

 35

return NULL;

}

 38

char *test_binstr_performance()

{

int i = 0;

int found_at = 0;

unsigned long find_count = 0;

time_t elapsed = 0;

time_t start = time(NULL);

 46

do {

for (i = 0; i < 1000; i++) {

found_at = binstr(&IN_STR, 0, &ALPHA);

mu_assert(found_at != BSTR_ERR, "Failed to find!");

find_count++;

}

 53

elapsed = time(NULL) - start;

} while (elapsed <= TEST_TIME);

 56

debug("BINSTR COUNT: %lu, END TIME: %d, OPS: %f",

find_count, (int)elapsed, (double)find_count / elapsed);

return NULL;

}

 61

char *test_find_performance()

{

int i = 0;

int found_at = 0;

unsigned long find_count = 0;

time_t elapsed = 0;

time_t start = time(NULL);

 69

do {

for (i = 0; i < 1000; i++) {

found_at = String_find(&IN_STR, &ALPHA);

find_count++;

}

 75

elapsed = time(NULL) - start;

} while (elapsed <= TEST_TIME);

 78

debug("FIND COUNT: %lu, END TIME: %d, OPS: %f",

find_count, (int)elapsed, (double)find_count / elapsed);

 81

return NULL;

}

 84

char *test_scan_performance()

{

int i = 0;

int found_at = 0;

unsigned long find_count = 0;

time_t elapsed = 0;

StringScanner *scan = StringScanner_create(&IN_STR);

 92

time_t start = time(NULL);

 94

do {

for (i = 0; i < 1000; i++) {

found_at = 0;

 98

do {

found_at = StringScanner_scan(scan, &ALPHA);

find_count++;

} while (found_at != -1);

}

104

elapsed = time(NULL) - start;

} while (elapsed <= TEST_TIME);

107

debug("SCAN COUNT: %lu, END TIME: %d, OPS: %f",

find_count, (int)elapsed, (double)find_count / elapsed);

110

StringScanner_destroy(scan);

112

return NULL;

}

115

char *all_tests()

{

mu_suite_start();

119

mu_run_test(test_find_and_scan);

121

// this is an idiom for commenting out sections of code

#if 0

mu_run_test(test_scan_performance);

mu_run_test(test_find_performance);

mu_run_test(test_binstr_performance);

#endif

128

return NULL;

}

131

RUN_TESTS(all_tests);
```

I have it written here with `#if 0`, which is a way to use the CPP to comment out a section of code. Type it in like this, and then remove it and the `#endif` so that you can see these performance tests run. As you continue with the book, simply comment these out so that the test doesn’t waste development time.

There’s nothing amazing in this unit test; it just runs each of the different functions in loops that last long enough to get a few seconds of sampling. The first test (`test_find_and_scan`) just confirms that what I’ve written works, because there’s no point in testing the speed of something that doesn’t work. Then, the next three functions run a large number of searches, using each of the three functions.

The trick to notice is that I grab the starting time in `start`, and then I loop until at least `TEST_TIME` seconds have passed. This makes sure that I get enough samples to work with while comparing the three. I’ll then run this test with different `TEST_TIME` settings and analyze the results.

### What You Should See

When I run this test on my laptop, I get numbers that look like this:

`Exercise 39.1 Session`

---

[Click here to view code image](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch39_images.html#p255pro01a)

```bash
$ ./tests/string_algos_tests

DEBUG tests/string_algos_tests.c:124: ----- RUNNING:

    ./tests/string_algos_tests

----

RUNNING: ./tests/string_algos_tests

DEBUG tests/string_algos_tests.c:116:

----- test_find_and_scan

DEBUG tests/string_algos_tests.c:117:

----- test_scan_performance

DEBUG tests/string_algos_tests.c:105: SCAN COUNT:\

          110272000, END TIME: 2, OPS: 55136000.000000

DEBUG tests/string_algos_tests.c:118:

----- test_find_performance

DEBUG tests/string_algos_tests.c:76: FIND COUNT:\

          12710000, END TIME: 2, OPS: 6355000.000000

DEBUG tests/string_algos_tests.c:119:

----- test_binstr_performance

DEBUG tests/string_algos_tests.c:54: BINSTR COUNT:\

          72736000, END TIME: 2, OPS: 36368000.000000

ALL TESTS PASSED

Tests run: 4

$
```

I look at this and I want to do more than 2 seconds for each run. I want to run this many times, and then use R to check it out like I did before. Here’s what I get for ten samples for about 10 seconds each:

```
scan find binstr

71195200 6353700 37110200

75098000 6358400 37420800

74910000 6351300 37263600

74859600 6586100 37133200

73345600 6365200 37549700

74754400 6358000 37162400

75343600 6630400 37075000

73804800 6439900 36858700

74995200 6384300 36811700

74781200 6449500 37383000
```

The way I got this is using a little bit of shell help, and then editing the output:

`Exercise 39.2 Session`

---

[Click here to view code image](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch39_images.html#p256pro01a)

```bash
$ for i in 1 2 3 4 5 6 7 8 9 10

> do echo "RUN --- $i" >> times.log

> ./tests/string_algos_tests 2>&1 | grep COUNT >> times.log

> done

$ less times.log

$ vim times.log
```

Right away, you can see that the scanning system beats the pants off both of the others, but I’ll open this in R and confirm the results:

`Exercise 39.3 Session`

---

[Click here to view code image](https://learning.oreilly.com/library/view/learn-c-the/9780133124385/ch39_images.html#p256pro02a)

```
> times <- read.table("times.log", header=T)

> summary(times)

      scan               find             binstr

 Min.   :71195200   Min.   :6351300   Min.   :36811700

 1st Qu.:74042200   1st Qu.:6358100   1st Qu.:37083800

 Median :74820400   Median :6374750   Median :37147800

 Mean   :74308760   Mean   :6427680   Mean   :37176830

 3rd Qu.:74973900   3rd Qu.:6447100   3rd Qu.:37353150

 Max.   :75343600   Max.   :6630400   Max.   :37549700

>
```

To understand why I’m getting the summary statistics, I have to explain some statistics for you. What I’m looking for in these numbers is simply this: “Are these three functions (`scan`, `find`, `bsinter`) actually different?” I know that each time I run my tester function, I get slightly different numbers, and those numbers can cover a certain range. You see here that the first and third quarters do that for each sample.

What I look at first is the mean, and I want to see if each sample’s mean is different from the others. I can see that, and clearly the `scan` beats `binstr`, which also beats `find`. However, I have a problem. If I use just the mean, there’s a *chance* that the `ranges` of each sample might overlap.

What if I have means that are different, but the first and third quarters overlap? In that case, I could say that if I ran the samples again there’s a chance that the means might not be different. The more overlap I have in the ranges, the higher probability that my two samples (and my two functions) are *not* actually different. Any difference that I’m seeing in the two (in this case three) is just random chance.

There are many tools that you can use to solve this problem, but in our case, I can just look at the first and third quarters and the mean for all three samples. If the means are different, and the quarters are way off with no possibility of overlapping, then it’s alright to say that they are different.

In my three samples, I can say that `scan`, `find`, and `binstr` are different, don’t overlap in range, and I can trust the sample (for the most part).

### Analyzing the Results

Looking at the results, I can see that `String_find` is much slower than the other two. In fact, it’s so slow that I’d think there’s something wrong with how I implemented it. However, when I compare it to `StringScanner_scan`, I can see that it’s most likely the part that builds the skip list that’s costing the time. Not only is `find` slower, it’s also doing *less* than `scan` because it’s just finding the first string while `scan` finds all of them.

I can also see that `scan` beats `binstr`, as well, and by quite a large margin. Again, not only does `scan` do more than both of these, but it’s also much faster.

There are a few caveats with this analysis:

• I may have messed up this implementation or the test. At this point I would go research all of the possible ways to do a BMH algorithm and try to improve it. I would also confirm that I’m doing the test right.

• If you alter the time the test runs, you’ll get different results. There is a warm-up period that I’m not investigating.

• The `test_scan_performance` unit test isn’t quite the same as the others, but it’s doing more than the other tests, so it’s probably alright.

• I’m only doing the test by searching for one string in another. I could randomize the strings to find their position and length as a confounding factor.

• Maybe `binstr` is implemented better than simple brute force.

• I could be running these in an unfortunate order. Maybe randomizing which test runs first will give better results.

One thing to gather from this is that you need to confirm real performance even if you implement an algorithm correctly. In this case, the claim is that the BMH algorithm should have beaten the `binstr` algorithm, but a simple test proved it didn’t. Had I not done this, I would have been using an inferior algorithm implementation without knowing it. With these metrics, I can start to tune my implementation, or simply scrap it and find another one.

### Extra Credit

• See if you can make the `Scan_find` faster. Why is my implementation here slow?

• Try some different scan times and see if you get different numbers. What impact does the length of time that you run the test have on the `scan` times? What can you say about that result?

• Alter the unit test so that it runs each function for a short burst in the beginning to clear out any warm-up period, and then start the timing portion. Does that change the dependence on the length of time the test runs? Does it change how many operations per second are possible?

• Make the unit test randomize the strings to find and then measure the performance you get. One way to do this is to use the `bsplit` function from `bstrlib.h` to split the `IN_STR` on spaces. Then, you can use the `bstrList` struct that you get to access each string it returns. This will also teach you how to use `bstrList` operations for string processing.

• Try some runs with the tests in different orders to see if you get different results.

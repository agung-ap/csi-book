# Chapter 14. More involved processing and IO

### This chapter covers

- Working with pointers
- Formatting input
- Handling extended character sets
- Input and output with binary streams
- Checking errors and cleaning up

Now that we know about pointers and how they work, we will shed new light on some of the C library features. Cs text processing is incomplete without using pointers, so we will start this chapter with an elaborated example in [section 14.1](/book/modern-c/chapter-14/ch14lev1sec1). Then we will look at functions for formatted input ([section 14.1](/book/modern-c/chapter-14/ch14lev1sec1)); these require pointers as arguments, so we had to delay their presentation until now. A whole new series of functions is then presented to handle extended character sets ([section 14.3](/book/modern-c/chapter-14/ch14lev1sec3)) and binary streams ([section 14.4](/book/modern-c/chapter-14/ch14lev1sec4)), and we round out this chapter and the entire level with a discussion of clean error handling ([section 14.4](/book/modern-c/chapter-14/ch14lev1sec4))).

## 14.1. Text processing

As a first example, consider the following program, which that reads a series of lines with numbers from **`stdin`** and writes these same numbers in a normalized way to **`stdout`** as comma-separated hexadecimal numbers:

##### **`numberline.c`**

```
246   int main(void) {
247     char lbuf[256];
248     for (;;) {
249       if (fgetline(sizeof lbuf, lbuf, stdin)) {
250         size_t n;
251         size_t* nums = numberline(strlen(lbuf)+1, lbuf, &n, 0);
252         int ret = fprintnumbers(stdout, "%#zX", ",\t", n, nums);
253         if (ret < 0) return EXIT_FAILURE;
254         free(nums);
255       } else {
256         if (lbuf[0]) {  /* a partial line has been read */ 
257           for (;;) {
258             int c = getc(stdin);
259             if (c == EOF) return EXIT_FAILURE;
260             if (c == '\n') {
261               fprintf(stderr, "line too long: %s\n", lbuf);
262               break;
263             }
264           }
265         } else break;   /* regular end of input */ 
266       }
267     }
268   }
```

This program splits the job in three different tasks:

- fgetline to read a line of text
- numberline to split such a line in a series of numbers of type **`size_t`**
- fprintnumbers to print them

At the heart is the function numberline. It splits the lbuf string that it receives into numbers, allocates an array to store them, and also returns the count of these numbers through the pointer argument np if that is provided:

##### numberline.c

numberline: interpret string *lbuf* as a sequence of numbers represented with *base*

**Returns**: a newly allocated array of numbers as found in *lbuf*

**Parameters**:

| lbuf | is supposed to be a string |
| --- | --- |
| np | if non-null, the count of numbers is stored in *np |
| base | value from 0 to 36, with the same interpretation as for **strtoul** |

**Remarks**: The caller of this function is responsible to **free** the array that is returned.

```
size_t* numberline(size_t size, char const lbuf[restrict size],
                   size_t*restrict np, int base);
```

That function itself is split into two parts, which perform quite different tasks. One performs the task of interpreting the line, numberline_inner. The other, numberline itself, is just a wrapper around the first that verifies or ensures the prerequisites for the first. Function numberline_inner puts the C library function **strtoull** in a loop that collects the numbers and returns a count of them.

Now we see the use of the second parameter of **strtoull**. Here, it is the address of the variable next, and next is used to keep track of the position in the string that ends the number. Since next is a pointer to **`char`**, the argument to **strtoull** is a pointer to a pointer to **`char`**:

##### **`numberline.c`**

```
97   static
 98   size_t numberline_inner(char const*restrict act,
 99                          size_t numb[restrict], int base){
100     size_t n = 0;
101     for (char* next = 0; act[0]; act = next) {
102       numb[n] = strtoull(act, &next, base);
103       if (act == next) break;
104       ++n;
105     }
106     return n;
107   }
```

Suppose **strtoull** is called as **strtoull**("0789a"`, &`next, base`)`. According to the value of the parameter base, that string is interpreted differently. If, for example, base has the value `10`, the first non-digit is the character 'a' at the end:

| Base | Digits | Number | *next |
| --- | --- | --- | --- |
| 8 | 2 | 7 | '8' |
| 10 | 4 | 789 | 'a' |
| 16 | 5 | 30874 | '\0' |
| 0 | 2 | 7 | '8' |

Remember the special rules for base `0`. The effective base is deduced from the first (or first two) characters in the string. Here, the first character is a '0', so the string is interpreted as being octal, and parsing stops at the first non-digit for that base: '8'.

There are two conditions that may end the parsing of the line that numberline_inner receives:

- act points to a string termination: to a `0` character.
- Function **strtoull** doesn’t find a number, in which case next is set to the value of act.

These two conditions are found as the controlling expression of the **`for`** loop and as **`if-break`** condition inside.

![](https://drek4537l1klr.cloudfront.net/gustedt/Figures/comm.jpg)

Note that the C library function **strtoull** has a historical weakness: the first argument has type **`char const`**`*`, whereas the second has type **`char`**`**`, without **`const`** qualification. This is why we had to type next as **`char`**`*` and couldn’t use **`char const`**`*`. As a result of a call to **strtoull**, we could inadvertently modify a read-only string and crash the program.

##### Takeaway 14.1

*The string* *`strt`**`o...`* *conversion functions are not* **`const`***-safe.*

Now, the function numberline itself provides the glue around numberline_inner:

- If np is null, it is set to point to an auxiliary.
- The input string is checked for validity.
- An array with enough elements to store the values is allocated and tailored to the appropriate size, once the correct length is known.

We use three functions from the C library: **memchr**, **malloc**, and **realloc**. As in previous examples, a combination of **malloc** and **realloc** ensures that we have an array of the necessary length:

##### **`numberline.c`**

```
109   size_t* numberline(size_t size, char const lbuf[restrict size],
110                      size_t*restrict np, int base){
111     size_t* ret = 0;
112     size_t n = 0;
113     /* Check for validity of the string, first. */ 
114     if (memchr(lbuf, 0, size)) {
115       /* The maximum number of integers encoded. 
116          To see that this may be as much look at 
117          the sequence 08 08 08 08 ... and suppose 
118          that base is 0. */ 
119       ret = malloc(sizeof(size_t[1+(2*size)/3]));
120
121       n = numberline_inner(lbuf, ret, base);
122
123       /* Supposes that shrinking realloc will always succeed. */ 
124       size_t len = n ? n : 1;
125       ret = realloc(ret, sizeof(size_t[len]));
126     }
127     if (np) *np = n;
128     return ret;
129   }
```

The call to **memchr** returns the address of the first byte that has value `0`, if there is any, or `(`**`void`**`*``)0` if there is none. Here, this is just used to check that within the first size bytes there effectively is a `0` character. That way, it guarantees that all the string functions used underneath (in particular, **strtoull**) operate on a `0`-terminated string.

With **memchr**, we encounter another problematic interface. It returns a **`void`**`*` that potentially points into a read-only object.

![](https://drek4537l1klr.cloudfront.net/gustedt/Figures/comm.jpg)

##### Takeaway 14.2

*The* **memchr** *and* **strchr** *search functions are not* **`const`***-safe.*

In contrast, functions that return an index position within the string would be safe.

##### Takeaway 14.3

*The* **strspn** *and* **strcspn** *search functions are* **`const`***-safe.*

Unfortunately, they have the disadvantage that they can’t be used to check whether a **`char-`**array is in fact a string. So they can’t be used here.

Now, let us look at the second function in our example:

##### numberline.c

fgetline: read one text line of at most size`-1` bytes.

The '\n' character is replaced by `0`.

**Returns:** s if an entire line was read successfully. Otherwise, `0` is returned and *s* contains a maximal partial line that could be read. *s* is null terminated.

```
char* fgetline(size_t size, char s[restrict size],
               FILE*restrict stream);
```

This is quite similar to the C library function **fgets**. The first difference is the interface: the parameter order is different, and the size parameter is a **`size_t`** instead of an **`int`**. Like **fgets**, it returns a null pointer if the read from the stream failed. Thus the end-of-file condition is easily detected on stream.

More important is that fgetline handles another critical case more gracefully. It detects whether the next input line is too long or whether the last line of the stream ends without a '\n' character:

##### **`numberline.c`**

```
131   char* fgetline(size_t size, char s[restrict size],
132                  FILE*restrict stream){
133     s[0] = 0;
134     char* ret = fgets(s, size, stream);
135     if (ret) {
136       /* s is writable so can be pos. */ 
137       char* pos = strchr(s, '\n');
138       if (pos) *pos = 0;
139       else ret = 0;
140     }
141     return ret;
142   }
```

The first two lines of the function guarantee that s is always null terminated: either by the call to **fgets**, if successful, or by enforcing it to be an empty string. Then, if something was read, the first '\n' character that can be found in s is replaced with `0`. If none is found, a partial line has been read. In that case, the caller can detect this situation and call fgetline again to attempt to read the rest of the line or to detect an end-of-file condition.[[[Exs 1]](/book/modern-c/chapter-14/ch14fn-ex01)]

[Exs 1] Improve the **main** of the example such that it is able to cope with arbitrarily long input lines.

In addition to **fgets**, this uses **strchr** from the C library. The lack of **`const`**-safeness of this function is not an issue here, since s is supposed to be modifiable anyway. Unfortunately, with the interfaces as they exist now, we always have to do this assessment ourselves.

Since it involves a lot of detailed error handling, we will go into detail about the function fprintnumbers in [section 14.5](/book/modern-c/chapter-14/ch14lev1sec5). For our purpose here, we restrict ourselves to the discussion of function sprintnumbers, which is a bit simpler because it only writes to a string, instead of a stream, and because it just assumes that the buffer buf that it receives provides enough space:

##### numberline.c

sprintnumbers: print a series of numbers *nums* in *buf*, using **printf** format *form*, separated by *sep* characters and terminated with a newline character.

**Returns:** the number of characters printed to *buf*.

This supposes that *tot* and *buf* are big enough and that *form* is a format suitable to print **`size_t`**.

```
int sprintnumbers(size_t tot, char buf[restrict tot],
                  char const form[restrict static 1],
                  char const sep[restrict static 1],
                  size_t len, size_t nums[restrict len]);
```

The function sprintnumbers uses a function of the C library that we haven’t met yet: **sprintf**. Its formatting capacities are the same as those of **printf** and **fprintf**, only it doesn’t print to a stream but rather to a **`char`** array:

##### **`numberline.c`**

```
149   int sprintnumbers(size_t tot, char buf[restrict tot],
150                     char const form[restrict static 1],
151                     char const sep[restrict static 1],
152                     size_t len, size_t nums[restrict len]) {
153     char* p = buf;   /* next position in buf */ 
154     size_t const seplen = strlen(sep);
155     if (len) {
156       size_t i = 0;
157       for (;;) {
158         p += sprintf(p, form, nums[i]);
159         ++i;
160         if (i >= len) break;
161         memcpy(p, sep, seplen);
162         p += seplen;
163       }
164     }
165     memcpy(p, "\n", 2);
166     return (p-buf)+1;
167   }
```

The function **sprintf** always ensures that a `0` character is placed at the end of the string. It also returns the length of that string, which is the number of characters before the `0` character that have been written. This is used in the example to update the pointer to the current position in the buffer. **sprintf** still has an important vulnerability:

##### Takeaway 14.4

**sprintf** *makes no provision against buffer overflow.*

That is, if we pass an insufficient buffer as a first argument, bad things will happen. Here, inside sprintnumbers, much like **sprintf** itself, we *suppose* the buffer is large enough to hold the result. If we aren’t sure the buffer can hold the result, we can use the C library function **snprintf**, instead:

```
1   int snprintf(char*restrict s, size_t n, char const*restrict form, ...);
```

This function ensures in addition that no more than n bytes are ever written to s. If the return value is greater than or equal to n, the string is been truncated to fit. In particular, if n is `0`, nothing is written into s.

##### Takeaway 14.5

*Use* **snprintf** *when formatting output of unknown length.*

In summary, **snprintf** has a lot of nice properties:

- The buffer s will not overflow.
- After a successful call, s is a string.
- When called with n and s set to `0`, **snprintf** just returns the length of the string that would have been written.

By using that, a simple **`for`** loop to compute the length of all the numbers printed on one line looks like this:

##### **`numberline.c`**

```
182      /* Count the chars for the numbers. */ 
183      for (size_t i = 0; i < len; ++i)
184        tot += snprintf(0, 0, form, nums[i]);
```

We will see later how this is used in the context of fprintnumbers.

##### Text processing in strings

We’ve covered quite a bit about text processing, so let’s see if we can actually use it.

Can you search for a given word in a string?

Can you replace a word in a string and return a copy with the new contents?

Can you implement some regular-expression-matching functions for strings? For example, find a character class such as `[A-Q]` or `[^0-9]`, match with `*` (meaning “anything"), or match with `?` (meaning “any character").

Or can you implement a regular-expression-matching function for POSIX character classes such as `[[:alpha:]]`, `[[:digit:]]`, and so on?

Can you stitch all these functionalities together to search for a regexp in a string?

Do query-replace with regexp against a specific word?

Extend a regexp with grouping?

Extend query-replace with grouping?

## 14.2. Formatted input

Similar to the **printf** family of functions for formatted output, the C library has a series of functions for formatted input: **fscanf** for input from an arbitrary stream, **scanf** for **`stdin`**, and **sscanf** from a string. For example, the following would read a line of three **`double`** values from **`stdin`**:

```
1   double a[3];
2   /* Read and process an entire line with three double values. */ 
3   if (scanf(" %lg %lg %lg ", &a[0], &a[1], &a[2]) < 3) {
4      printf("not enough input values!\n");
5   }
```

[Tables 14.1](/book/modern-c/chapter-14/ch14table01) to [14.3](/book/modern-c/chapter-14/ch14table03) give an overview of the format for specifiers. Unfortunately, these functions are more difficult to use than **printf** and also have conventions that diverge from **printf** in subtle ways.

##### Table 14.1. Format specifications for **scanf** and similar functions, with the general syntax **`[XX][WW][LL]SS`**[(view table figure)](https://drek4537l1klr.cloudfront.net/gustedt/HighResolutionFigures/table_14-1.png)

| XX | * | Assignment suppression |
| --- | --- | --- |
| WW | Field width | Maximum number of input characters |
| LL | Modifier | Select width of target type |
| SS | Specifier | Select conversion |

- To be able to return values for all formats, the arguments are pointers to the type that is scanned.
- Whitespace handling is subtle and sometimes unexpected. A space character, ' ', in the format matches any sequence of whitespace: spaces, tabs, and newline characters. Such a sequence may in particular be empty or contain several newline characters.
- String handling is different. Because the arguments to the **scanf** functions are pointers anyway, the formats "%c" and "%s" both refer to an argument of type **`char`**`*`. Where "%c" reads a character array of fixed size (of default `1`), "%s" matches any sequence of non-whitespace characters and adds a terminating `0` character.
- The specifications of types in the format have subtle differences compared to **printf**, in particular for floating-point types. To be consistent between the two, it is best to use "%lg" or similar for **`double`** and "%Lg" for **`long double`**, for both **printf** and **scanf**.
- There is a rudimentary utility to recognize character classes. For example, a format of "%[aeiouAEIOU]" can be used to scan for the vowels in the Latin alphabet.

##### Table 14.2. *Format specifiers for **scanf** and similar functions* With an 'l' modifier, specifiers for characters or sets of characters ('c', 's', '[') transform multibyte character sequences on input to wide-character **`wchar_t`** arguments; see subection 14.3.[(view table figure)](https://drek4537l1klr.cloudfront.net/gustedt/HighResolutionFigures/table_14-2.png)

| SS | Conversion | Pointer to | Skip space | Analogous to function |
| --- | --- | --- | --- | --- |
| 'd' | Decimal | Signed type | Yes | **strtol**, base 10 |
| 'i' | Decimal, octal, or hex | Signed type | Yes | **strtol**, base 0 |
| 'u' | Decimal | Unsigned type | Yes | **strtoul**, base 10 |
| 'o' | Octal | Unsigned type | Yes | **strtoul**, base 8 |
| 'x' | Hexadecimal | Unsigned type | Yes | **strtoul**, base 16 |
| 'aefg' | Floating point | Floating point | Yes | **strtod** |
| '%' | '%' character | No assignment | No |  |
| 'c' | Characters | **char** | No | **memcpy** |
| 's' | Non-whitespace | **char** | Yes | **strcspn** with |
|  |  |  |  | " \f\n\r\t\v" |
| '[' | Scan set | String | No | **strspn** or **strcspn** |
| 'p' | Address | **void** | Yes |  |
| 'n' | Character count | Signed type | No |  |

- In such a character class specification, the caret `^` negates the class if it is found at the beginning. Thus "%[^\n]%*[\n]" scans a whole line (which must be nonempty) and then discards the newline character at the end of the line.

These particularities make the **scanf** family of functions difficult to use. For example, our seemingly simple example has the flaw (or feature) that it is not restricted to read a single input line, but it would happily accept three **`double`** values spread over several lines.[[[Exs 2]](/book/modern-c/chapter-14/ch14fn-ex02)] In most cases where you have a regular input pattern such as a series of numbers, they are best avoided.

[Exs 2] Modify the format string in the example such that it only accepts three numbers on a single line, separated by blanks, and such that the terminating newline character (eventually preceded by blanks) is skipped.

## 14.3. Extended character sets

Up to now, we have used only a limited set of characters to specify our programs or the contents of string literals that we printed on the console: a set consisting of the Latin alphabet, Arabic numerals, and some punctuation characters. This limitation is a historical accident that originated in the early market domination by the American computer industry, on one hand, and the initial need to encode characters with a very limited number of bits on the other.[[1](/book/modern-c/chapter-14/ch14fn01)] As we saw with the use of the type name **`char`** for the basic data cell, the concepts of a text character and an indivisible data component were not very well separated at the start.

1 The character encoding that is dominantly used for the basic character set is referred to as ASCII: *A*merican *s*tandard *c*ode for *i*nformation *i*nterchange.

##### Table 14.3. *Format modifiers for **scanf** and similar functions* Note that the significance of **`float`**`*` and **`double`**`*` arguments is different than for **printf** formats.[(view table figure)](https://drek4537l1klr.cloudfront.net/gustedt/HighResolutionFigures/table_14-3.png)

| Character | Type |
| --- | --- |
| "hh" | **char** types |
| "h" | **short** types |
| "" | **signed**, **unsigned**, **float**, **char** arrays and strings |
| "l" | **long** integer types, **double**, **wchar_t** characters and strings |
| "ll" | **long long** integer types |
| "j" | **intmax_t**, **uintmax_t** |
| "z" | **size_t** |
| "t" | **ptrdiff_t** |
| "L" | **long double** |

Latin, from which we inherited our character set, is long dead as a spoken language. Its character set is not sufficient to encode the particularities of the phonetics of other languages. Among the European languages, English has the peculiarity that it encodes missing sounds with combinations of letters such as *ai*, *ou*, and *gh* (*fair enough*), not with diacritical marks, special characters, or ligatures (*fär ínó*), as do most of its cousins. So for other languages that use the Latin alphabet, the possibilities were already quite restricted; but for languages and cultures that use completely different scripts (Greek, Russian) or even completely different concepts (Japanese, Chinese), this restricted American character set was clearly not sufficient.

During the first years of market expansion around the world, different computer manufacturers, countries, and organizations provided native language support for their respective communities more or less randomly, and added specialized support for graphical characters, mathematical typesetting, musical scores, and so on without coordination. It was an utter chaos. As a result, interchanging textual information between different systems, countries, and cultures was difficult if not impossible in many cases; writing portable code that could be used in the context of different languages *and* different computing platforms resembled the black arts.

Luckily, these years-long difficulties are now mainly mastered, and on modern systems we can write portable code that uses “extended” characters in a unified way. The following code snippet shows how this is supposed to work:

##### **`mbstrings-main.c`**

```
87   setlocale(LC_ALL, "");
88   /* Multibyte character printing only works after the locale 
89     has been switched. */ 
90   draw_sep(TOPLEFT " © 2014 jεnz 'g℧ztεt ", TOPRIGHT);
```

That is, near the beginning of our program, we switch to the “native” locale, and then we can use and output text containing *extended characters*: here, phonetics (so-called IPA). The output of this looks similar to

![](https://drek4537l1klr.cloudfront.net/gustedt/Figures/241fig01_alt.jpg)

The means to achieve this are quite simple. We have some macros with magic string literals for vertical and horizontal bars, and top-left and top-right corners:

##### **`mbstrings-main.c`**

```
43   #define VBAR "\u2502"      /**< a vertical bar character   */
44   #define HBAR "\u2500"      /**< a horizontal bar character */
45   #define TOPLEFT "\u250c"   /**< topleft corner character   */
46   #define TOPRIGHT "\u2510"  /**< topright corner character  */
```

And an ad hoc function that nicely formats an output line:

##### mbstrings-main.c

draw_sep: Draw multibyte strings *start* and *end* separated by a horizontal line.

```
void draw_sep(char const start[static 1],
                char const end[static 1]) {
    fputs(start, stdout);
    size_t slen = mbsrlen(start, 0);
    size_t elen = 90 - mbsrlen(end, 0);
    for (size_t i = slen; i < elen; ++i) fputs(HBAR, stdout);
    fputs(end, stdout);
    fputc('\n', stdout);
  }
```

This uses a function to count the number of print characters in a multibyte string (mbsrlen) and our old friends **fputs** and **fputc** for textual output.

The start of all of this with the call to **setlocale** is important. Chances are, otherwise you’d see garbage if you output characters from the extended set to your terminal. But once you have issued that call to **setlocale** and your system is well installed, such characters placed inside multibyte strings "fär ínó*`ff`*" should not work out too badly.

A *multibyte character* is a sequence of bytes that is interpreted as representing a single character of the extended character set, and a *multibyte string* is a string that contains such multibyte characters. Luckily, these beasts are compatible with ordinary strings as we have handled them so far.

##### Takeaway 14.6

*Multibyte characters don’t contain null bytes.*

##### Takeaway 14.7

*Multibyte strings are null terminated.*

Thus, many of the standard string functions such as **strcpy** work out of the box for multibyte strings. They introduce one major difficulty, though: the fact that the number of printed characters can no longer be directly deduced from the number of elements of a **`char`** array or by the function **strlen**. This is why, in the previous code, we use the (nonstandard) function mbsrlen:

##### mbstrings.h

mbsrlen: Interpret a mb string in *mbs* and return its length when interpreted as a wide character string.

**Returns**: the length of the mb string or `-1` if an encoding error occured.

This function can be integrated into a sequence of searches through a string, as long as a *state* argument is passed to this function that is consistent with the mb character starting in *mbs*. The state itself is not modified by this function.

**Remarks**: *state* of `0` indicates that *mbs* can be scanned without considering any context.

```
size_t mbsrlen(char const*restrict mbs,
               mbstate_t const*restrict state);
```

As you can see from that description, parsing multibyte strings for the individual multibyte characters can be a bit more complicated. In particular, generally we need to keep a parsing state by means of the type **`mbstate_t`** that is provided by the C standard in the header files `wchar.h`.[[2](/book/modern-c/chapter-14/ch14fn02)] This header provides utilities for multibyte strings and characters, and also for a *wide character* type **`wchar_t`**. We will see that later.

2 The header `uchar.h` also provides this type.

<wchar.h>But first, we have to introduce another international standard: ISO 10646, or *Unicode [[2017](/book/modern-c/bibliography/bib19)]*. As the naming indicates, Unicode ([http://www.joelonsoftware.com/articles/Unicode.html](http://www.joelonsoftware.com/articles/Unicode.html)) attempts to provide a unified framework for character codes. It provides a huge table[[3](/book/modern-c/chapter-14/ch14fn03)] of basically all character *concepts* that have been conceived by mankind so far. *Concept* here is really important: we have to understand from the print form or *glyph* of a particular character in a certain type that, for example, “Latin capital letter A” can appear as A, *A*, A, or `A` in the present text. Other such conceptual characters like the character “Greek capital letter Alpha” may even be printed with the same or similar glyph A.

3 Today, Unicode has about 110,000 code points.

Unicode places each character concept, or *code point* in its own jargon, into a linguistic or technical context. In addition to the definition of the character, Unicode classifies it, for example, as being a capital letter, and relates it to other code points, such as by stating that *A* is the capitalization of *a*.

If you need special characters for your particular language, there is a good chance that you have them on your keyboard and that you can enter them into multibyte strings for coding in C as is. That is, your system may be configured to insert the whole byte sequence for ä, say, directly into the text and do all the required magic for you. If you don’t have or want that, you can use the technique that we used for the macros HBAR earlier. There we used an escape sequence that was new in C11 ([http://dotslashzero.net/2014/05/21/the-interesting-state-of-unicode-in-c/](http://dotslashzero.net/2014/05/21/the-interesting-state-of-unicode-in-c/)): a backslash and a *u* followed by four hexadecimal digits encode a Unicode code point. For example, the code point for “latin small letter a with diaeresis” is 228 or 0xE4. Inside a multibyte string, this then reads as "\u00E4". Since four hexadecimal digits can address only 65,536 code points, there is also the option to specify 8 hexadecimal digits, introduced with a backslash and a capital *U*, but you will encounter this only in very specialized contexts.

In the previous example, we encoded four graphical characters with such Unicode specifications, characters that most likely are not on any keyboard. There are several online sites that allow you to find the code point for any character you need.

If we want to do more than simple input/output with multibyte characters and strings, things become a bit more complicated. Simple counting of the characters already is not trivial: **strlen** does not give the right answer, and other string functions such as **strchr**, **strspn**, and **strstr** don’t work as expected. Fortunately, the C standard gives us a set of replacement functions, usually prefixed with **`wcs`** instead of str, that will work on *wide character strings*, instead. The mbsrlen function that we introduced earlier can be coded as

##### **`mbstrings.c`**

```
30   size_t mbsrlen(char const*s, mbstate_t const*restrict state) {
31     if (!state) state = MBSTATE;
32     mbstate_t st = *state;
33     size_t mblen = mbsrtowcs(0, &s, 0, &st);
34     if (mblen == -1) errno = 0;
35     return mblen;
36   }
```

The core of this function is the use of the library function **mbsrtowcs** (“*multibyte string (mbs), restartable, to wide character string (wcs)*"), which constitutes one of the primitives that the C standard provides to handle multibyte strings:

```
1   size_t mbsrtowcs(wchar_t*restrict dst, char const**restrict src,
2                    size_t len, mbstate_t*restrict ps);
```

So once we decrypt the abbreviation of the name, we know that this function is supposed to convert an mbs, src, to a wcs, dst. Here, *wide characters* (wc) of type **`wchar_t`** are use to encode exactly one character of the extended character set, and these wide characters are used to form wcs pretty much in the same way as **`char`** s compose ordinary strings: they are null-terminated arrays of such wide characters.

The C standard doesn’t restrict the encoding used for **`wchar_t`** much, but any sane environment nowadays should use Unicode for its internal representations. You can check this with two macros as follows:

##### **`mbstrings.h`**

```
24   #ifndef __STDC_ISO_10646__
25   # error "wchar_t wide characters have to be Unicode code points" 
26   #endif
27   #ifdef __STDC_MB_MIGHT_NEQ_WC__
28   # error "basic character codes must agree on char and wchar_t" 
29   #endif
```

Modern platforms typically implement **`wchar_t`** with either 16-bit or 32-bit integer types. Which one usually should not be of much concern to you, if you only use the code points that are representable with four hexadecimal digits in the \uXXXX notation. Those platforms that use 16-bit effectively can’t use the other code points in \UXXXXXXXX notation, but this shouldn’t bother you much.

Wide characters and wide character string literals follow analogous rules to those we have seen for **`char`** and strings. For both, a prefix of L indicates a wide character or string: for example, L'ä' and L'\u00E4' are the same character, both of type **`wchar_t`**, and L"b\u00E4" is an array of three elements of type **`wchar_t`** that contains the wide characters L'b', L'ä', and `0`.

Classification of wide characters is also done in a similar way as for simple **`char`**. The header `wctype.h` provides the necessary functions and macros.

<wctype.h>To come back to **mbsrtowcs**, this function *parses* the multibyte string src into snippets that correspond to *multibyte characters* (mbc), and assigns the corresponding code point to the wide characters in dst. The parameter len describes the maximal length that the resulting wcs may have. The parameter state points to a variable that stores an eventual *parsing state* of the mbs; we will discuss this concept briefly a bit later.

As you can see, the function **mbsrtowcs** has two peculiarities. First, when called with a null pointer for dst, it simply doesn’t store the wcs but only returns the size that such a wcs would have. Second, it can produce a *coding error* if the mbs is not encoded correctly. In that case, the function returns `(`**`size_t`**`)-1` and sets **`errno`** to the value **`EILSEQ`** (see `errno.h`). Part of the code for mbsrlen is actually a repair of that error strategy by setting **`errno`** to `0` again.

<errno.h>Let’s now look at a second function that will help us handle mbs:

##### mbstrings.h

mbsrdup: Interpret a sequence of bytes in *s* as mb string and convert it to a wide character string.

**Returns**: a newly malloc’ed wide character string of the appropriate length, `0` if an encoding error occurred.

**Remarks**: This function can be integrated into a sequence of such searches through a string, as long as a *state* argument is passed to this function that is consistent with the mb character starting in *c*. The state itself is not modified by this function.

*state* of `0` indicates that *s* can be scanned without considering any context.

```
wchar_t* mbsrdup(char const*s, mbstate_t const*restrict state);
```

This function returns a freshly allocated wcs with the same contents as the mbs s that it receives on input. Other than for the state parameter, its implementation is straightforward:

##### **`mbstrings.c`**

```
38   wchar_t* mbsrdup(char const*s, mbstate_t const*restrict state) {
39     size_t mblen = mbsrlen(s, state);
40     if (mblen == -1) return 0;
41     mbstate_t st = state ? *state : *MBSTATE;
42     wchar_t* S = malloc(sizeof(wchar_t[mblen+1]));
43     /* We know that s converts well, so no error check */ 
44     if (S) mbsrtowcs(S, &s, mblen+1, &st);
45     return S;
46   }
```

After determining the length of the target string, we use **malloc** to allocate space and **mbsrtowcs** to copy over the data.

To have more fine-grained control over the parsing of an mbs, the standard provides the function **mbrtowc**:

```
1   size_t mbrtowc(wchar_t*restrict pwc,
2                  const char*restrict s, size_t len,
3                  mbstate_t* restrict ps);
```

In this interface, parameter len denotes the maximal position in s that is scanned for a single multibyte character. Since in general we don’t know how such a multibyte encoding works on the target machine, we have to do some guesswork that helps us determine len. To encapsulate such a heuristic, we cook up the following interface. It has semantics similar to **mbrtowc** but avoids the specification of len:

##### mbstrings.h

mbrtow: Interpret a sequence of bytes in *c* as mb character and return that as wide character through *C*.

**Returns**: the length of the mb character or `-1` if an encoding error occured.

This function can be integrated into a sequence of such searches through a string, as long as the same *state* argument passed to all calls to this or similar functions.

**Remarks**: *state* of `0` indicates that *c* can be scanned without considering any context.

```
size_t mbrtow(wchar_t*restrict C, char const c[restrict static 1],
              mbstate_t*restrict state);
```

This function returns the number of bytes that were identified for the first multibyte character in the string, or `-1` on error. **mbrtowc** has another possible return value, `-2`, for the case that len wasn’t big enough. The implementation uses that return value to detect such a situation and to adjust len until it fits:

##### **`mbstrings.c`**

```
14   size_t mbrtow(wchar_t*restrict C, char const c[restrict static 1],
15                 mbstate_t*restrict state) {
16     if (!state) state = MBSTATE;
17     size_t len = -2;
18     for (size_t maxlen = MB_LEN_MAX; len == -2; maxlen *= 2)
19       len = mbrtowc(C, c, maxlen, state);
20     if (len == -1) errno = 0;
21     return len;
22   }
```

Here, **`MB_LEN_MAX`** is a standard value that is a good upper bound for len in most situations.

Let us now go to a function that uses the capacity of mbrtow to identify mbc and to use that to search inside a mbs:

##### mbstrings.h

mbsrwc: Interpret a sequence of bytes in *s* as mb string and search for wide character *C*.

**Returns**: the *occurrence’th* position in *s* that starts a mb sequence corresponding to *C* or `0` if an encoding error occurred.

If the number of occurrences is less than *occurrence* the last such position is returned. So in particular using **`SIZE_MAX`** (or `-1`) will always return the last occurrence.

**Remarks**: This function can be integrated into a sequence of such searches through a string, as long as the same *state* argument passed to all calls to this or similar functions and as long as the continuation of the search starts at the position that is returned by this function.

*state* of `0` indicates that *s* can be scanned without considering any context.

```
char const* mbsrwc(char const s[restrict static 1],
                   mbstate_t*restrict state,
                   wchar_t C, size_t occurrence);
```

##### **`mbstrings.c`**

```
68   char const* mbsrwc(char const s[restrict static 1], mbstate_t*restrict state
         ,
69                      wchar_t C, size_t occurrence) {
70     if (!C || C == WEOF) return 0;
71     if (!state) state = MBSTATE;
72     char const* ret = 0;
73
74     mbstate_t st = *state;
75     for (size_t len = 0; s[0]; s += len) {
76       mbstate_t backup = st;
77       wchar_t S = 0;
78       len = mbrtow(&S, s, &st);
79       if (!S) break;
80       if (C == S) {
81         *state = backup;
82         ret = s;
83         if (!occurrence) break;
84         --occurrence;
85       }
86     }
87     return ret;
88   }
```

As we said, all of this encoding with multibyte strings and simple IO works fine if we have an environment that is consistent: that is, if it uses the same multibyte encoding within your source code as for other text files and on your terminal. Unfortunately, not all environments use the same encoding yet, so you may encounter difficulties when transferring text files (including sources) or executables from one environment to another. In addition to the definition of the big character table, Unicode also defines three encodings that are now widely used and that hopefully will replace all others eventually: *UTF-8*, *UTF-16*, and *UTF-32*, for *U*nicode *T*ransformation *F*ormat with 8-bit, 16-bit, and 32-bit words, respectively. Since C11, the C language includes rudimentary direct support for these encodings without having to rely on the locale. String literals with these encodings can be coded as u8"text", u"text", and U"text", which have types **`char`**`[]`, **`char16_t`**`[]`, and **`char32_t`**`[]`, respectively.

Chances are that the multibyte encoding on a modern platform is UTF-8, and then you won’t need these special literals and types. They are mostly useful in a context where you have to ensure one of these encodings, such as in network communication. Life on legacy platforms might be more difficult; see [http://www.nubaria.com/en/blog/?p=289](http://www.nubaria.com/en/blog/?p=289) for an overview for the Windows platform.

## 14.4. Binary streams

In [section 8.3](/book/modern-c/chapter-8/ch08lev1sec3), we briefly mentioned that input and output to streams can also be performed in *binary* mode in contrast to the usual *text mode* we have used up to now. To see the difference, remember that text mode IO doesn’t write the bytes that we pass to **printf** or **fputs** one-to-one to the target file or device:

- Depending on the target platform, a '\n' character can be encoded as one or several characters.
- Spaces that precede a newline can be suppressed.
- Multibyte characters can be transcribed from the execution character set (the program’s internal representation) to the character set of the file system underlying the file.

Similar observations hold for reading data from text files.

If the data that we manipulate is effectively human-readable text, all of this is fine; we can consider ourselves happy that the IO functions together with **setlocale** make this mechanism as transparent as possible. But if we are interested in reading or writing binary data just as it is present in some C objects, this can be quite a burden and lead to serious difficulties. In particular, binary data could implicitly map to the end-of-line convention of the file, and thus a write of such data could change the file’s internal structure.

As indicated previously, streams can be opened in binary mode. For such a stream, all the translation between the external representation in the file and the internal representation is skipped, and each byte of such a stream is written or read as such. From the interfaces we have seen up to now, only **fgetc** and **fputc** can handle binary files portably. All others may rely on some form of end-of-line transformation.

To read and write binary streams more easily, the C library has some interfaces that are better suited:

```
1   size_t fread(void* restrict ptr, size_t size, size_t nmemb,
2                FILE* restrict stream);
3   size_t fwrite(void const*restrict ptr, size_t size, size_t nmemb,
4                 FILE* restrict stream);
5   int fseek(FILE* stream, long int offset, int whence);
6   long int ftell(FILE* stream);
```

The use of **fread** and **fwrite** is relatively straightforward. Each stream has a current *file position* for reading and writing. If successful, these two functions read or write size`*`nmemb bytes from that position onward and then update the file position to the new value. The return value of both functions is the number of bytes that have been read or written, usually size`*`nmemb, and thus an error occurred if the return value is less than that.

The functions **ftell** and **fseek** can be used to operate on that file position: **ftell** returns the position in terms of bytes from the start of the file, and **fseek** positions the file according to the arguments offset and whence. Here, whence can have one of these values: **`SEEK_SET`** refers to the start of the file, and **`SEEK_CUR`** to the current file position before the call.[[4](/book/modern-c/chapter-14/ch14fn04)]

4 There is also **`SEEK_END`** for the end-of-file position, but it may have platform-defined glitches.

By means of these four functions, we may effectively move forward and backward in a stream that represents a file and read or write any byte of it. This can, for example, be used to write out a large object in its internal representation to a file and read it in later with a different program, without performing any modifications.

This interface has some restrictions, though. To work portably, streams have to be opened in binary mode. On some platforms, IO is *always* binary, because there is no effective transformation to perform. So, unfortunately, a program that does not use binary mode may work reliably on these platforms, but then fail when ported to others.

##### Takeaway 14.8

*Open streams on which you use* **fread** *or* **fwrite** *in binary mode.*

Since this works with internal representations of objects, it is only portable between platforms and program executions that use that same representation: the same endian-ness. Different platforms, operating systems, and even program executions can have different representations.

##### Takeaway 14.9

*Files that are written in binary mode are not portable between platforms.*

The use of the type **`long`** for file positions limits the size of files that can easily be handled with **ftell** and **fseek** to **`LONG_MAX`** bytes. On most modern platforms, this corresponds to 2GiB.[[[Exs 3]](/book/modern-c/chapter-14/ch14fn-ex03)]

[Exs 3] Write a function fseekmax that uses **`intmax_t`** instead of **`long`** and achieves large seek values by combining calls to **fseek**.

##### Takeaway 14.10

**fseek** *and* **ftell** *are not suitable for very large file offsets.*

## 14.5. Error checking and cleanup

C programs can encounter a lot of error conditions. Errors can be programming errors, bugs in the compiler or OS software, hardware errors, in some cases resource exhaustion (such as out of memory), or any malicious combination of these. For a program to be reliable, we have to detect such error conditions and deal with them gracefully.

As a first example, take the following description of a function fprintnumbers, which continues the series of functions that we discussed in [section 14.1](/book/modern-c/chapter-14/ch14lev1sec1):

##### numberline.c

fprintnumbers: print a series of numbers *nums* on *stream*, using **printf** format *form*, separated by *sep* characters and terminated with a newline character.

Returns: the number of characters printed to *stream*, or a negative error value on error.

If *len* is `0`, an empty line is printed and `1` is returned.

Possible error returns are:

- **`EOF`** (which is negative) if *stream* was not ready to be written to
- `-`**`EOVERFLOW`** if more than **`INT_MAX`** characters would have to be written, including the case that *len* is greater than **`INT_MAX`**.
- `-`**`EFAULT`** if *stream* or *numb* are `0`
- `-`**`ENOMEM`** if a memory error occurred

This function leaves **`errno`** to the same value as occurred on entry.

```
int fprintnumbers(FILE*restrict stream,
                    char const form[restrict static 1],
                    char const sep[restrict static 1],
                    size_t len, size_t numb[restrict len]);
```

As you can see, this function distinguishes four different error conditions, which are indicated by the return of negative constant values. The macros for these values are generally provided by the platform in `errno.h`, and all start with the capital letter E. Unfortunately, the C standard imposes only **`EOF`** (which is negative) and **`EDOM`**, **`EILSEQ`**, and **`ERANGE`**, which are positive. Other values may or may not be provided. Therefore, in the initial part of our code, we have a sequence of preprocessor statements that give default values for those that are missing:

<errno.h>##### **`numberline.c`**

```
36   #include <limits.h>
37   #include <errno.h>
38   #ifndef EFAULT
39   # define EFAULT EDOM
40   #endif
41   #ifndef EOVERFLOW
42   # define EOVERFLOW (EFAULT-EOF)
43   # if EOVERFLOW > INT_MAX
44   #  error EOVERFLOW constant is too large
45   # endif
46   #endif
47   #ifndef ENOMEM
48   # define ENOMEM (EOVERFLOW+EFAULT-EOF)
49   # if ENOMEM > INT_MAX
50   #  error ENOMEM constant is too large
51   # endif
52   #endif
```

The idea is that we want to be sure to have distinct values for all of these macros. Now the implementation of the function itself looks as follows:

##### **`numberline.c`**

```
169   int fprintnumbers(FILE*restrict stream,
170                     char const form[restrict static 1],
171                     char const sep[restrict static 1],
172                     size_t len, size_t nums[restrict len]) {
173     if (!stream)       return -EFAULT;
174     if (len && !nums)  return -EFAULT;
175     if (len > INT_MAX) return -EOVERFLOW;
176
177     size_t tot = (len ? len : 1)*strlen(sep);
178     int err = errno;
179     char* buf = 0;
180
181     if (len) {
182       /* Count the chars for the numbers. */ 
183       for (size_t i = 0; i < len; ++i)
184         tot += snprintf(0, 0, form, nums[i]);
185       /* We return int so we have to constrain the max size. */ 
186       if (tot > INT_MAX) return error_cleanup(EOVERFLOW, err);
187     }
188
189     buf = malloc(tot+1);
190     if (!buf) return error_cleanup(ENOMEM, err);
191
192     sprintnumbers(tot, buf, form, sep, len, nums);
193     /* print whole line in one go */ 
194     if (fputs(buf, stream) == EOF) tot = EOF;
195     free(buf);
196     return tot;
197   }
```

Error handling pretty much dominates the coding effort for the whole function. The first three lines handle errors that occur on entry to the function and reflect missed preconditions or, in the language of Annex K (see [section 8.1.4](/book/modern-c/chapter-8/ch08lev2sec4)), *runtime constraint violations**C*.

Dynamic runtime errors are a bit more difficult to handle. In particular, some functions in the C library may use the pseudo-variable **`errno`** to communicate an error condition. If we want to capture and repair all errors, we have to avoid any change to the global state of the execution, including to **`errno`**. This is done by saving the current value on entry to the function and restoring it in case of an error with a call to the small function error_cleanup:

##### **`numberline.c`**

```
144   static inline int error_cleanup(int err, int prev) {
145     errno = prev;
146     return -err;
147   }
```

The core of the function computes the total number of bytes that should be printed in a **`for`** loop over the input array. In the body of the loop, **snprintf** with two `0` arguments is used to compute the size for each number. Then our function sprintnumbers from [section 14.1](/book/modern-c/chapter-14/ch14lev1sec1) is used to produce a big string that is printed using **fputs**.

Observe that there is no error exit after a successful call to **malloc**. If an error is detected on return from the call to **fputs**, the information is stored in the variable tot, but the call to **free** is not skipped. So even if such an output error occurs, no allocated memory is left leaking. Here, taking care of a possible IO error was relatively simple because the call to **fputs** occurred close to the call to **free**.

The function fprintnumbers_opt requires more care:

##### **`numberline.c`**

```
199   int fprintnumbers_opt(FILE*restrict stream,
200                     char const form[restrict static 1],
201                     char const sep[restrict static 1],
202                     size_t len, size_t nums[restrict len]) {
203     if (!stream)       return -EFAULT;
204     if (len && !nums)  return -EFAULT;
205     if (len > INT_MAX) return -EOVERFLOW;
206
207     int err = errno;
208     size_t const seplen = strlen(sep);
209
210     size_t tot = 0;
211     size_t mtot = len*(seplen+10);
212     char* buf = malloc(mtot);
213
214     if (!buf) return error_cleanup(ENOMEM, err);
215
216     for (size_t i = 0; i < len; ++i) {
217       tot += sprintf(&buf[tot], form, nums[i]);
218       ++i;
219       if (i >= len) break;
220       if (tot > mtot-20) {
221         mtot *= 2;
222         char* nbuf = realloc(buf, mtot);
223         if (buf) {
224           buf = nbuf;
225         } else {
226           tot = error_cleanup(ENOMEM, err);
227           goto CLEANUP;
228         }
229       }
230       memcpy(&buf[tot], sep, seplen);
231       tot += seplen;
232       if (tot > INT_MAX) {
233         tot = error_cleanup(EOVERFLOW, err);
234         goto CLEANUP;
235       }
236     }
237     buf[tot] = 0;
238
239     /* print whole line in one go */ 
240     if (fputs(buf, stream) == EOF) tot = EOF;
241    CLEANUP:
242     free(buf);
243     return tot;
244   }
```

It tries to optimize the procedure even further by printing the numbers immediately instead of counting the required bytes first. This may encounter more error conditions as we go, and we have to take care of them by guaranteeing to issue a call to **free** at the end. The first such condition is that the buffer we allocated initially is too small. If the call to **realloc** to enlarge it fails, we have to retreat carefully. The same is true if we encounter the unlikely condition that the total length of the string exceeds **`INT_MAX`**.

In both cases, the function uses **`goto`**, to jump to the cleanup code that then calls **free**. With C, this is a well-established technique that ensures that the cleanup takes place and that also avoids hard-to-read nested **`if`**`-`**`else`** conditions. The rules for **`goto`** are relatively simple:

##### Takeaway 14.11

*Labels for* **`goto`** *are visible in the entire function that contains them.*

##### Takeaway 14.12

**`goto`** *can only jump to a label inside the same function.*

##### Takeaway 14.13

**`goto`** *should not jump over variable initializations.*

The use of **`goto`** and similar jumps in programming languages has been subject to intensive debate, starting from an article by Dijkstra [[1968](/book/modern-c/bibliography/bib3)]. You will still find people who seriously object to code as it is given here, but let us try to be pragmatic about that: code with or without **`goto`** can be ugly and hard to follow. The main idea is to have the “normal” control flow of the function be mainly undisturbed and to clearly mark changes to the control flow that only occur under exceptional circumstances with a **`goto`** or **`return`**. Later, in [section 17.5](/book/modern-c/chapter-17/ch17lev1sec5), we will see another tool in C that allows even more drastic changes to the control flow: **setjmp**`/`**longjmp**, which enables us to jump to other positions on the stack of calling functions.

##### Text processing in streams

For text processing in streams, can you read on **`stdin`**, dump modified text on **`stdout`**, and report diagnostics on **`stderr`**? Count the occurrences of a list of words? Count the occurrences of a regexp? Replace all occurrences of a word with another?

##### Text processor sophistication

Can you extend your text processor ([challenge 12](/book/modern-c/chapter-11/ch11sb01)) to use multibyte characters?

Can you also extend it to do regular expression processing, such as searching for a word, running a simple query-replace of one word against another, performing a query-replace with a regex against a specific word, and applying regexp grouping?

## Summary

- The C library has several interfaces for text processing, but we must be careful about **`const`**-qualification and buffer overflow.
- Formatted input with **scanf** (and similar) has subtle issues with pointer types, null termination of strings, white space, and new-line separation. If possible, you should use the combination of **fgets** with **strtod** or similar, more specialized, functions.
- Extended character sets are best handled by using multibyte strings. With some caution, these can be used much like ordinary strings for input and output.
- Binary data should be written to binary files by using **fwrite** and **fread**. Such files are platform dependent.
- Calls to C library functions should be checked for error returns.
- Handling error conditions can lead to complicated case analysis. It can be organized by a function-specific code block to which we jump with **`goto`** statements.

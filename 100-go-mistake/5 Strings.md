# 5 Strings

### This chapter covers
- Understanding the fundamental concept of the rune in Go
- Preventing common mistakes with string iteration and trimming
- Avoiding inefficient code due to string concatenations or useless conversions
- Avoiding memory leaks with substrings

In Go, a string is an immutable data structure holding the following:

- A pointer to an immutable byte sequence
- The total number of bytes in this sequence

We will see in this chapter that Go has a pretty unique way to deal with strings. Go introduces a concept called *runes*; this concept is essential to understand and may confuse newcomers. Once we know how strings are managed, we can avoid common mistakes while iterating on a string. We will also look at common mistakes made by Go developers while using or producing strings. In addition, we will see that sometimes we can work directly with `[]byte`, avoiding extra allocations. Finally, we will discuss how to avoid a common mistake that can create leaks from substrings. The primary goal of this chapter is to help you understand how strings work in Go by presenting common string mistakes.

## 5.1 #36: Not understanding the concept of a rune

We couldn’t start this chapter about strings without discussing the concept of the rune in Go. As you will see in the following sections, this concept is key to thoroughly understanding how strings are handled and avoiding common mistakes. But before delving into Go runes, we need to make sure we are aligned about some fundamental programming concepts.

We should understand the distinction between a charset and an encoding:

- A charset, as the name suggests, is a set of characters. For example, the Unicode charset contains 2^21 characters.
- An encoding is the translation of a character’s list in binary. For example, UTF-8 is an encoding standard capable of encoding all the Unicode characters in a variable number of bytes (from 1 to 4 bytes).

We mentioned characters to simplify the charset definition. But in Unicode, we use the concept of a *code point* to refer to an item represented by a single value. For example, the 汉 character is identified by the U+6C49 code point. Using UTF-8, 汉 is encoded using three bytes: 0xE6, 0xB1, and 0x89. Why is this important? Because in Go, a rune *is* a Unicode code point.

Meanwhile, we mentioned that UTF-8 encodes characters into 1 to 4 bytes, hence, up to 32 bits. This is why in Go, a rune is an alias of `int32`:

```go
type rune = int32
```

Another thing to highlight about UTF-8: some people believe that Go strings are always UTF-8, but this isn’t true. Let’s consider the following example:

```go
s := "hello"
```

We assign a string literal (a string constant) to `s`. In Go, a source code is encoded in UTF-8. So, all string literals are encoded into a sequence of bytes using UTF-8. However, a string is a sequence of arbitrary bytes; it’s not necessarily based on UTF-8. Hence, when we manipulate a variable that wasn’t initialized from a string literal (for example, reading from the filesystem), we can’t necessarily assume that it uses the UTF-8 encoding.

> ##### NOTE
>
> `golang.org/x`, a repository that provides extensions to the standard library, contains packages to work with UTF-16 and UTF-32.

Let’s get back to the `hello` example. We have a string composed of five characters: *h*, *e*, *l*, *l*, and *o*.

These *simple* characters are encoded using a single byte each. This is why getting the length of `s` returns `5`:

```go
s := "hello"
fmt.Println(len(s)) // 5
```

But a character isn’t always encoded into a single byte. Coming back to the 汉 character, we mentioned that with UTF-8, this character is encoded into three bytes. We can validate this with the following example:

```go
s := "汉"
fmt.Println(len(s)) // 3
```

Instead of printing `1`, this example prints `3`. Indeed, the `len` built-in function applied on a string doesn’t return the number of characters; it returns the number of bytes.

Conversely, we can create a string from a list of bytes. We mentioned that the 汉 character was encoded using three bytes, 0xE6, 0xB1, and 0x89:

```go
s := string([]byte{0xE6, 0xB1, 0x89})
fmt.Printf("%s\n", s)
```

Here, we build a string composed of these three bytes. When we print the string, instead of printing three characters, the code prints a single one: 汉.

In summary:

- A charset is a set of characters, whereas an encoding describes how to translate a charset into binary.
- In Go, a string references an immutable slice of arbitrary bytes.
- Go source code is encoded using UTF-8. Hence, all string literals are UTF-8 strings. But because a string can contain arbitrary bytes, if it’s obtained from somewhere else (not the source code), it isn’t guaranteed to be based on the UTF-8 encoding.
- A rune corresponds to the concept of a Unicode code point, meaning an item represented by a single value.
- Using UTF-8, a Unicode code point can be encoded into 1 to 4 bytes.
- Using `len` on a string in Go returns the number of bytes, not the number of runes.

Having these concepts in mind is essential because runes as everywhere in Go. Let’s see a concrete application of this knowledge involving a common mistake related to string iteration.

## 5.2 #37: Inaccurate string iteration

Iterating on a string is a common operation for developers. Perhaps we want to perform an operation for each rune in the string or implement a custom function to search for a specific substring. In both cases, we have to iterate on the different runes of a string. But it’s easy to get confused about how iteration works.

Let’s look at a concrete example. Here, we want to print the different runes in a string and their corresponding positions:

```go
s := "hêllo"            // #1
for i := range s {
    fmt.Printf("position %d: %c\n", i, s[i])
}
fmt.Printf("len=%d\n", len(s))
```

We use the `range` operator to iterate over `s`, and then we want to print each rune using its index in the string. Here’s the output:

```
position 0: h
position 1: Ã
position 3: l
position 4: l
position 5: o
len=6
```

This code doesn’t do what we want. Let’s highlight three points:

- The second rune is `Ã` in the output instead of `ê`.
- We jumped from position 1 to position 3: what is at position 2?
- `len` returns a count of 6, whereas `s` contains only 5 runes.

Let’s start with the last observation. We already mentioned that `len` returns the number of bytes in a string, not the number of runes. Because we assigned a string literal to `s`, `s` is a UTF-8 string. Meanwhile, the special character `ê` isn’t encoded in a single byte; it requires 2 bytes. Therefore, calling `len(s)` returns `6`.

> ##### Calculating the number of runes in a string
>
> What if we want to get the number of runes in a string, not the number of bytes? How we can do this depends on the encoding.
>
> In the previous example, because we assigned a string literal to `s`, we can use the `unicode/utf8` package:
>
> ```go
> fmt.Println(utf8.RuneCountInString(s)) // 5
> ```

Let’s get back to the iteration to understand the remaining surprises:

```go
for i := range s {
    fmt.Printf("position %d: %c\n", i, s[i])
}
```

We have to recognize that in this example, we don’t iterate over each rune; instead, we iterate over each starting index of a rune, as shown in figure 5.1.

![Figure 5.1 Printing s[i] prints the UTF-8 representation of each byte at index i.](https://drek4537l1klr.cloudfront.net/harsanyi/HighResolutionFigures/figure_5-1.png)

Printing `s[i]` doesn’t print the `i`th rune; it prints the UTF-8 representation of the byte at index `i`. Hence, we printed `hÃllo` instead of `hêllo`. So how do we fix the code if we want to print all the different runes? There are two main options.

We have to use the value element of the `range` operator:

```go
s := "hêllo"
for i, r := range s {
    fmt.Printf("position %d: %c\n", i, r)
}
```

Instead of printing the rune using `s[i]`, we use the `r` variable. Using a `range` loop on a string returns two variables, the starting index of a rune and the rune itself:

```
position 0: h
position 1: ê
position 3: l
position 4: l
position 5: o
```

The other approach is to convert the string into a slice of runes and iterate over it:

```go
s := "hêllo"
runes := []rune(s)
for i, r := range runes {
    fmt.Printf("position %d: %c\n", i, r)
}
position 0: h
position 1: ê
position 2: l
position 3: l
position 4: o
```

Here, we convert `s` into a slice of runes using `[]rune(s)`. Then we iterate over this slice and use the value element of the `range` operator to print all the runes. The only difference has to do with the position: instead of printing the starting index of the rune’s byte sequence, the code prints the rune’s index directly.

Note that this solution introduces a run-time overhead compared to the previous one. Indeed, converting a string into a slice of runes requires allocating an additional slice and converting the bytes into runes: an *O(n)* time complexity with n the number of bytes in the string. Therefore, if we want to iterate over all the runes, we should use the first solution.

However, if we want to access the `i`th rune of a string with the first option, we don’t have access to the rune index; rather, we know the starting index of a rune in the byte sequence. Hence, we should favor the second option in most cases:

```go
s := "hêllo"
r := []rune(s)[4]
fmt.Printf("%c\n", r) // o
```

This code prints the fourth rune by first converting the string into a rune slice.

> ##### A possible optimization to access a specific rune
>
> One optimization is possible if a string is composed of single-byte runes: for example, if the string contains the letters `A` to `Z` and `a` to `z`. We can access the `i`th rune without converting the whole string into a slice of runes by accessing the byte directly using `s[i]`:
>
> ```go
> s := "hello"
> fmt.Printf("%c\n", rune(s[4])) // o
> ```

In summary, if we want to iterate over a string’s runes, we can use the `range` loop on the string directly. But we have to recall that the index corresponds not to the rune index but rather to the starting index of the byte sequence of the rune. Because a rune can be composed of multiple bytes, if we want to access the rune itself, we should use the value variable of `range`, not the index in the string. Meanwhile, if we are interested in getting the `i`th rune of a string, we should convert the string into a slice of runes in most cases.

In the next section, we look at a common source of confusion when using trim functions in the `strings` package.

## 5.3 #38: Misusing trim functions

One common mistake made by Go developers when using the `strings` package is to mix `TrimRight` and `TrimSuffix`. Both functions serve a similar purpose, and it can be fairly easy to confuse them. Let’s take a look.

In the following example, we use `TrimRight`. What should be the output of this code?

```go
fmt.Println(strings.TrimRight("123oxo", "xo"))
```

The answer is `123`. Is that what you expected? If not, you were probably expecting the result of `TrimSuffix`, instead. Let’s review both functions.

`TrimRight` removes all the trailing runes contained in a given set. In our example, we passed as a set `xo`, which contains two runes: `x` and `o`. Figure 5.2 shows the logic.

![Figure 5.2 TrimRight iterates backward until it finds a rune that is not part of the set.](https://drek4537l1klr.cloudfront.net/harsanyi/HighResolutionFigures/figure_5-2.png)

`TrimRight` iterates backward over each rune. If a rune is part of the provided set, the function removes it. If not, the function stops its iteration and returns the remaining string. This is why our example returns `123`.

On the other hand, `TrimSuffix` returns a string without a provided trailing suffix:

```go
fmt.Println(strings.TrimSuffix("123oxo", "xo"))
```

Because `123oxo` ends with `xo`, this code prints `123o`. Also, removing the trailing suffix isn’t a repeating operation, so `TrimSuffix("123xoxo", "xo")` returns `123xo`.

The principle is the same for the left-hand side of a string with `TrimLeft` and `TrimPrefix`:

```go
fmt.Println(strings.TrimLeft("oxo123", "ox")) // 123
fmt.Println(strings.TrimPrefix("oxo123", "ox")) /// o123
```

`strings.TrimLeft` removes all the leading runes contained in a set and hence prints `123`. `TrimPrefix` removes the provided leading prefix, printing `o123`.

One last note related to this topic: `Trim` applies both `TrimLeft` and `TrimRight` on a string. So, it removes all the leading and trailing runes contained in a set:

```go
fmt.Println(strings.Trim("oxo123oxo", "ox")) // 123
```

In summary, we have to make sure we understand the difference between `TrimRight`/`TrimLeft`, and `TrimSuffix`/`TrimPrefix`:

- `TrimRight`/`TrimLeft` removes the trailing/leading runes in a set.
- `TrimSuffix`/`TrimPrefix` removes a given suffix/prefix.

In the next section, we will delve into string concatenation.

## 5.4 #39: Under-optimized string concatenation

When it comes to concatenating strings, there are two main approaches in Go, and one of them can be really inefficient in some conditions. Let’s examine this topic to understand which option we should favor and when.

Let’s write a `concat` function that concatenates all the string elements of a slice using the `+=` operator:

```go
func concat(values []string) string {
    s := ""
    for _, value := range values {
        s += value
    }
    return s
}
```

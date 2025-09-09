# 3 Data types

### This chapter covers
- Common mistakes related to basic types
- Fundamental concepts for slices and maps to prevent possible bugs, leaks, or inaccuracies
- Comparing values

Dealing with data types is a frequent operation for software engineers. This chapter delves into the most common mistakes related to basic types, slices, and maps. The only data type that we omit is strings because a later chapter deals with this type exclusively.

## 3.1 #17: Creating confusion with octal literals

Let’s first look at a common misunderstanding with octal literal representation, which can lead to confusion or even bugs. What do you believe should be the output of the following code?

```go
sum := 100 + 010
fmt.Println(sum)
```

At first glance, we may expect this code to print the result of 100 + 10 = 110. But it prints 108 instead. How is that possible?

In Go, an integer literal starting with 0 is considered an octal integer (base 8), so 10 in base 8 equals 8 in base 10. Thus, the sum in the previous example is equal to 100 + 8 = 108. This is an important property of integer literals to keep in mind—for example, to avoid confusion while reading existing code.

Octal integers are useful in different scenarios. For instance, suppose we want to open a file using `os.OpenFile`. This function requires passing a permission as a `uint32`. If we want to match a Linux permission, we can pass an octal number for readability instead of a base 10 number:

```go
file, err := os.OpenFile("foo", os.O_RDONLY, 0644)
```

In this example, `0644` represents a specific Linux permission (read for all and write only for the current user). It’s also possible to add an `o` character (the letter o in lowercase) following the zero:

```go
file, err := os.OpenFile("foo", os.O_RDONLY, 0o644)
```

Using `0o` as a prefix instead of only `0` means the same thing. However, it can help make the code clearer.

> **NOTE**
> We can also use an uppercase `O` character instead of a lowercase `o`. But passing `0O644` can increase confusion because, depending on the character font, `0` can look very similar to `O`.

We should also note the other integer literal representations:

- *Binary*—Uses a `0b` or `0B` prefix (for example, `0b100` is equal to 4 in base 10)
- *Hexadecimal*—Uses an `0x` or `0X` prefix (for example, `0xF` is equal to 15 in base 10)
- *Imaginary*—Uses an `i` suffix (for example, `3i`)

Finally, we can also use an underscore character (`_`) as a separator for readability. For example, we can write 1 billion this way: `1_000_000_000`. We can also use the underscore character with other representations (for example, `0b00_00_01`).

In summary, Go handles binary, hexadecimal, imaginary, and octal numbers. Octal numbers start with a 0. However, to improve readability and avoid potential mistakes for future code readers, make octal numbers explicit using a `0o` prefix.

The next section digs into integers, and we discuss how overflows are handled in Go.

## 3.2 #18: Neglecting integer overflows

Not understanding how integer overflows are handled in Go can lead to critical bugs. This section delves into this topic. But first, let’s remind ourselves of a few concepts related to integers.

### 3.2.1 Concepts

Go provides a total of 10 integer types. There are four signed integer types and four unsigned integer types, as the following table shows.

| Signed integers | Unsigned integers |
| --- | --- |
| `int8` (8 bits) | `uint8` (8 bits) |
| `int16` (16 bits) | `uint16` (16 bits) |
| `int32` (32 bits) | `uint32` (32 bits) |
| `int64` (64 bits) | `uint64` (64 bits) |

The other two integer types are the most commonly used: `int` and `uint`. These two types have a size that depends on the system: 32 bits on 32-bit systems or 64 bits on 64-bit systems.

Let’s now discuss overflow. Suppose we want to initialize an `int32` to its maximum value and then increment it. What should be the behavior of this code?

```go
var counter int32 = math.MaxInt32
counter++
fmt.Printf("counter=%d\n", counter)
```

This code compiles and doesn’t panic at run time. However, the `counter++` statement generates an integer overflow:

```
counter=-2147483648
```

An integer overflow occurs when an arithmetic operation creates a value outside the range that can be represented with a given number of bytes. An `int32` is represented using 32 bits. Here is the binary representation of the maximum `int32` value (`math.MaxInt32`):

```
01111111111111111111111111111111
 |------31 bits set to 1-------|
```

Because an `int32` is a signed integer, the bit on the left represents the integer’s sign: 0 for positive, 1 for negative. If we increment this integer, there is no space left to represent the new value. Hence, this leads to an integer overflow. Binary-wise, here’s the new value:

```
10000000000000000000000000000000
 |------31 bits set to 0-------|
```

As we can see, the bit sign is now equal to 1, meaning negative. This value is the smallest possible value for a signed integer represented with 32 bits.

> **NOTE**
> The smallest possible negative value isn’t `111111111111111111111111 11111111`. Indeed, most systems rely on the two’s complement operation to represent binary numbers (invert every bit and add 1). The main goal of this operation is to make x + (–x) equal 0 regardless of *x*.

In Go, an integer overflow that can be detected at compile time generates a compilation error. For example,

```
var counter int32 = math.MaxInt32 + 1
constant 2147483648 overflows int32
```

However, at run time, an integer overflow or underflow is silent; this does not lead to an application panic. It is essential to keep this behavior in mind, because it can lead to sneaky bugs (for example, an integer increment or addition of positive integers that leads to a negative result).

Before delving into how to detect an integer overflow with common operations, let’s think about when to be concerned about it. In most contexts, like handling a counter of requests or basic additions/multiplications, we shouldn’t worry too much if we use the right integer type. But in some cases, like memory-constrained projects using smaller integer types, dealing with large numbers, or doing conversions, we may want to check possible overflows.

> **NOTE**
> The Ariane 5 launch failure in 1996 (https://www.bugsnag.com/blog/bug-day-ariane-5-disaster) was due to an overflow resulting from converting a 64-bit floating-point to a 16-bit signed integer.

### 3.2.2 Detecting integer overflow when incrementing

If we want to detect an integer overflow during an increment operation with a type based on a defined size (`int8`, `int16`, `int32`, `int64`, `uint8`, `uint16`, `uint32`, or `uint64`), we can check the value against the `math` constants. For example, with an `int32`:

```go
func Inc32(counter int32) int32 {
    if counter == math.MaxInt32 {    #1
        panic("int32 overflow")
    }
    return counter + 1
}
```

This function checks whether the input is already equal to `math.MaxInt32`. We know whether the increment leads to an overflow if that’s the case.

What about `int` and `uint` types? Before Go 1.17, we had to build these constants manually. Now, `math.MaxInt`, `math.MinInt`, and `math.MaxUint` are part of the `math` package. If we have to test an overflow on an `int` type, we can do it using `math.MaxInt`:

```go
func IncInt(counter int) int {
    if counter == math.MaxInt {
        panic("int overflow")
    }
    return counter + 1
}
```

The logic is the same for a `uint`. We can use `math.MaxUint`:

```go
func IncUint(counter uint) uint {
    if counter == math.MaxUint {
        panic("uint overflow")
    }
    return counter + 1
}
```

In this section, we learned how to check integer overflows following an increment operation. Now, what about addition?

### 3.2.3 Detecting integer overflows during addition

How can we detect an integer overflow during an addition? The answer is to reuse `math.MaxInt`:

```go
func AddInt(a, b int) int {
    if a > math.MaxInt-b {       #1
        panic("int overflow")
    }
 
    return a + b
}
```

In the example, `a` and `b` are the two operands. If `a` is greater than `math.MaxInt - b`, the operation will lead to an integer overflow. Now, let’s look at the multiplication operation.

### 3.2.4 Detecting an integer overflow during multiplication

Multiplication is a bit more complex to handle. We have to perform checks against the minimal integer, `math.MinInt`:

```go
func MultiplyInt(a, b int) int {
    if a == 0 || b == 0 {                       #1
        return 0
    }
 
    result := a * b
    if a == 1 || b == 1 {                       #2
        return result
    }
    if a == math.MinInt || b == math.MinInt {   #3
        panic("integer overflow")
    }
    if result/b != a {                          #4
        panic("integer overflow")
    }
    return result
}
```

Checking an integer overflow with multiplication requires multiple steps. First, we need to test if one of the operands is equal to `0`, `1`, or `math.MinInt`. Then we divide the multiplication result by `b`. If the result isn’t equal to the original factor (`a`), it means an integer overflow occurred.

In summary, integer overflows (and underflows) are silent operations in Go. If we want to check for overflows to avoid sneaky errors, we can use the utility functions described in this section. Also remember that Go provides a package to deal with large numbers: `math/big`. This might be an option if an `int` isn’t enough.

We continue talking about basic Go types in the next section with floating points.

## 3.3 #19: Not understanding floating points

In Go, there are two floating-point types (if we omit imaginary numbers): `float32` and `float64`. The concept of a floating point was invented to solve the major problem with integers: their inability to represent fractional values. To avoid bad surprises, we need to know that floating-point arithmetic is an approximation of real arithmetic. Let’s examine the impact of working with approximations and how to increase accuracy. For that, we’ll look at a multiplication example:

```go
var n float32 = 1.0001
fmt.Println(n * n)
```

We may expect this code to print the result of 1.0001 * 1.0001 = 1.00020001, right? However, running it on most x86 processors prints 1.0002, instead. How do we explain that? We need to understand the arithmetic of floating points first.

Let’s take the `float64` type as an example. Note that there’s an infinite number of real values between `math.SmallestNonzeroFloat64` (the `float64` minimum) and `math.MaxFloat64` (the `float64` maximum). Conversely, the `float64` type has a finite number of bits: 64. Because making infinite values fit into a finite space isn’t possible, we have to work with approximations. Hence, we may lose precision. The same logic goes for the `float32` type.

Floating points in Go follow the IEEE-754 standard, with some bits representing a mantissa and other bits representing an exponent. A *mantissa* is a base value, whereas an *exponent* is a multiplier applied to the mantissa. In single-precision floating-point types (`float32`), 8 bits represent the exponent, and 23 bits represent the mantissa. In double-precision floating-point types (`float64`), the values are 11 and 52 bits, respectively, for the exponent and the mantissa. The remaining bit is for the sign. To convert a floating point into a decimal, we use the following calculation:

```
sign * 2^exponent * mantissa
```

![Figure 3.1 Representation of 1.0001 in float32](https://drek4537l1klr.cloudfront.net/harsanyi/HighResolutionFigures/figure_3-1.png)

Once we understand that `float32` and `float64` are approximations, what are the implications for us as developers? The first implication is related to comparisons. Using the `==` operator to compare two floating-point numbers can lead to inaccuracies. Instead, we should compare their difference to see if it is less than some small error value. For example, the `testify` testing library (https://github.com/stretchr/testify) has an `InDelta` function to assert that two values are within a given delta of each other.

Also bear in mind that the result of floating-point calculations depends on the actual processor. Most processors have a floating-point unit (FPU) to deal with such calculations. There is no guarantee that the result executed on one machine will be the same on another machine with a different FPU. Comparing two values using a delta can be a solution for implementing valid tests across different machines.

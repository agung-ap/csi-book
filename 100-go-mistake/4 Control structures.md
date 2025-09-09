# 4 Control structures

### This chapter covers
- How a `range` loop assigns the element values and evaluates the provided expression
- Dealing with `range` loops and pointers
- Preventing common map iteration and loop- breaking mistakes
- Using `defer` inside a loop

Control structures in Go are similar to those in C or Java but differ from them in significant ways. For example, there is no `do` or `while` loop in Go, only a generalized `for`. This chapter delves into the most common mistakes related to control structures, with a strong focus on the `range` loop, which is a common source of misunderstanding.

## 4.1: Ignoring the fact that elements are copied in range loops

A `range` loop is a convenient way to iterate over various data structures. We don’t have to handle an index and the termination state. Go developers may forget or be unaware of how a `range` loop assigns values, leading to common mistakes. First, let’s remind ourselves how to use a `range` loop; then we’ll look at how values are assigned.

### 4.1.1 Concepts

A `range` loop allows iterating over different data structures:

- String
- Array
- Pointer to an array
- Slice
- Map
- Receiving channel

Compared to a classic `for` loop, a `range` loop is a convenient way to iterate over all the elements of one of these data structures, thanks to its concise syntax. It’s also less error-prone because we don’t have to handle the condition expression and iteration variable manually, which may avoid mistakes such as off-by-one errors. Here is an example with an iteration over a slice of strings:

```go
s := []string{"a", "b", "c"}
for i, v := range s {
    fmt.Printf("index=%d, value=%s\n", i, v)
}
```

This code loops over each element of the slice. In each iteration, as we iterate over a slice, `range` produces a pair of values: an index and an element value, assigned to `i` and `v`, respectively. In general, `range` produces two values for each data structure except a receiving channel, for which it produces a single element (the value).

In some cases, we may only be interested in the element value, not the index. Because not using a local variable would lead to a compilation error, we can instead use the blank identifier to replace the index variable, like so:

```go
s := []string{"a", "b", "c"}
for _, v := range s {
    fmt.Printf("value=%s\n", v)
}
```

Thanks to the blank identifier, we iterate over each element by ignoring the index and assigning only the element value to `v`.

If we’re not interested in the value, we can omit the second element:

```go
for i := range s {}
```

Now that we’ve refreshed our minds on using a `range` loop, let’s see what kind of value is returned during an iteration.

### 4.1.2 Value copy

Understanding how the value is handled during each iteration is critical for using a `range` loop effectively. Let’s see how it works with a concrete example.

We create an `account` struct containing a single `balance` field:

```go
type account struct {
    balance float32
}
```

Next, we create a slice of `account` structs and iterate over each element using a `range` loop. During each iteration, we increment the `balance` of each `account`:

```go
accounts := []account{
    {balance: 100.},
    {balance: 200.},
    {balance: 300.},
}
for _, a := range accounts {
    a.balance += 1000
}
```

Following this code, which of the following two choices do you think shows the slice’s content?

- `[{100} {200} {300}]`
- `[{1100} {1200} {1300}]`

The answer is `[{100} {200} {300}]`. In this example, the `range` loop does not affect the slice’s content. Let’s see why.

In Go, everything we assign is a copy:

- If we assign the result of a function returning a *struct*, it performs a copy of that struct.
- If we assign the result of a function returning a *pointer*, it performs a copy of the memory address (an address is 64 bits long on a 64-bit architecture).

It’s crucial to keep this in mind to avoid common mistakes, including those related to `range` loops. Indeed, when a `range` loop iterates over a data structure, it performs a copy of each element to the value variable (the second item).

Coming back to our example, iterating over each `account` element results in a struct copy being assigned to the value variable `a`. Therefore, incrementing the balance with `a.balance += 1000` mutates only the value variable (`a`), not an element in the slice.

So, what if we want to update the slice elements? There are two main options. The first option is to access the element using the slice index. This can be achieved with either a classic `for` loop or a `range` loop using the index instead of the value variable:

```go
for i := range accounts {                // #1
    accounts[i].balance += 1000
}
 
for i := 0; i < len(accounts); i++ {     // #2
    accounts[i].balance += 1000
}
```

Both iterations have the same effect: updating the elements in the `accounts` slice.

Which one should we favor? It depends on the context. If we want to go over each element, the first loop is shorter to write and read. But if we need to control which element we want to update (such as one out of two), we should instead use the second loop.

> ##### Updating slice elements: A third option
>
> Another option is to keep using the `range` loop and access the value but modify the slice type to a slice of `account` pointers:
>
> ```go
> accounts := []*account{       // #1
>     {balance: 100.},
>     {balance: 200.},
>     {balance: 300.},
> }
> for _, a := range accounts {
>     a.balance += 1000         // #2
> }
> ```
>
> In this case, as we mentioned, the `a` variable is a copy of the `account` pointer stored in the slice. But as both pointers reference the same struct, the `a.balance += 1000` statement updates the slice element.
>
> However, this option has two main downsides. First, it requires updating the slice type, which may not always be possible. Second, if performance is important, we should note that iterating over a slice of pointers may be less efficient for a CPU because of the lack of predictability (we will discuss this point in mistake #91, “Not understanding CPU caches”).

In general, we should remember that the value element in a `range` loop is a copy. Therefore, if the value is a struct we need to mutate, we will only update the copy, not the element itself, unless the value or field we modify is a pointer. The favored options are to access the element via the index using a `range` loop or a classic `for` loop.

In the next section, we keep working with `range` loops and see how the provided expression is evaluated.

## 4.2 #31: Ignoring how arguments are evaluated in range loops

The `range` loop syntax requires an expression. For example, in `for` `i,` `v` `:=` `range` `exp`, `exp` is the expression. As we have seen, it can be a string, an array, a pointer to an array, a slice, a map, or a channel. Now, let’s discuss the following question: how is this expression evaluated? When using a `range` loop, this is an essential point to avoid common mistakes.

Let’s look at the following example, which appends an element to a slice we iterate over. Do you believe the loop will terminate?

```go
s := []int{0, 1, 2}
for range s {
    s = append(s, 10)
}
```

To understand this question, we should know that when using a `range` loop, the provided expression is evaluated only once, before the beginning of the loop. In this context, “evaluated” means the provided expression is copied to a temporary variable, and then `range` iterates over this variable. In this example, when the `s` expression is evaluated, the result is a slice copy, as shown in figure 4.1.

![Figure 4.1 s is copied to a temporary variable used by range.](https://drek4537l1klr.cloudfront.net/harsanyi/HighResolutionFigures/figure_4-1.png)

The `range` loop uses this temporary variable. The original slice `s` is also updated during each iteration. Hence, after three iterations, the state is as shown in figure 4.2.

![Figure 4.2 The temporary variable remains a three-length slice; hence, the iteration completes.](https://drek4537l1klr.cloudfront.net/harsanyi/HighResolutionFigures/figure_4-2.png)

Each step results in appending a new element. However, after three steps, we have gone over all the elements. Indeed, the temporary slice used by `range` remains a three-length slice. Hence, the loop completes after three iterations.

The behavior is different with a classic `for` loop:

```go
s := []int{0, 1, 2}
for i := 0; i < len(s); i++ {
    s = append(s, 10)
}
```

In this example, the loop never ends. The `len(s)` expression is evaluated during each iteration, and because we keep adding elements, we will never reach a termination state. It’s essential to keep this difference in mind to use Go loops accurately.

Coming back to the `range` operator, we should know that the behavior we described (expression evaluated only once) also applies to all the data types provided. As an example, let’s look at the implication of this behavior with two other types: channels and arrays.

### 4.2.1 Channels

Let’s see a concrete example based on iterating over a channel using a `range` loop. We create two goroutines, both sending elements to two distinct channels. Then, in the parent goroutine, we implement a consumer on one channel using a `range` loop that tries to switch to the other channel during the iteration:

```go
ch1 := make(chan int, 3)     // #1
go func() {
    ch1 <- 0
    ch1 <- 1
    ch1 <- 2
    close(ch1)
}()
 
ch2 := make(chan int, 3)     // #2
go func() {
    ch2 <- 10
    ch2 <- 11
    ch2 <- 12
    close(ch2)
}()
 
ch := ch1                    // #3
for v := range ch {          // #4
    fmt.Println(v)
    ch = ch2                 // #5
}
```

In this example, the same logic applies regarding how the `range` expression is evaluated. The expression provided to `range` is a `ch` channel pointing to `ch1`. Hence, `range` evaluates `ch`, performs a copy to a temporary variable, and iterates over elements from this channel. Despite the `ch = ch2` statement, `range` keeps iterating over `ch1`, not `ch2`:

```
0
1
2
```

The `ch = ch2` statement isn’t without effect, though. Because we assigned `ch` to the second variable, if we call `close(ch)` following this code, it will close the second channel, not the first.

Let’s now see the impact of the `range` operator evaluating each expression only once when used with an array.

### 4.2.2 Array

What’s the impact of using a `range` loop with an array? Because the `range` expression is evaluated before the beginning of the loop, what is assigned to the temporary loop variable is a copy of the array. Let’s see this principle in action with the following example that updates a specific array index during the iteration:

```go
a := [3]int{0, 1, 2}      // #1
for i, v := range a {     // #2
    a[2] = 10             // #3
    if i == 2 {           // #4
        fmt.Println(v)
    }
}
```

This code updates the last index to 10. However, if we run this code, it does not print `10`; it prints `2`, instead, as figure 4.3 shows.

![Figure 4.3 range iterates over the array copy (left) while the loop modifies a (right).](https://drek4537l1klr.cloudfront.net/harsanyi/HighResolutionFigures/figure_4-3.png)

As we mentioned, the `range` operator creates a copy of the array. Meanwhile, the loop doesn’t update the copy; it updates the original array: `a`. Therefore, the value of `v` during the last iteration is `2`, not `10`.

If we want to print the actual value of the last element, we can do so in two ways:

- By accessing the element from its index:

```go
a := [3]int{0, 1, 2}
for i := range a {
    a[2] = 10
    if i == 2 {
        fmt.Println(a[2])     // #1 
    }
}
```

Because we access the original array, this code prints `2` instead of `10`.

- Using an array pointer:

```go
a := [3]int{0, 1, 2}
for i, v := range &a {     // #1 
    a[2] = 10
    if i == 2 {
        fmt.Println(v)
    }
}
```

We assign a copy of the array pointer to the temporary variable used by `range`. But because both pointers reference the same array, accessing `v` also returns `10`.

Both options are valid. However, the second option doesn’t lead to copying the whole array, which may be something to keep in mind in case the array is significantly large.

In summary, the `range` loop evaluates the provided expression only once, before the beginning of the loop, by doing a copy (regardless of the type). We should remember this behavior to avoid common mistakes that might, for example, lead us to access the wrong element.

In the next section, we see how to avoid common mistakes using `range` loops with pointers.

## 4.3 #32: Ignoring the impact of using pointer elements in range loops

This section looks at a specific mistake when using a `range` loop with pointer elements. If we’re not cautious enough, it can lead us to an issue where we reference the wrong elements. Let’s examine this problem and how to fix it.

Before we begin, let’s clarify the rationale for using a slice or map of pointer elements. There are three main cases:

- In terms of semantics, storing data using pointer semantics implies sharing the element. For example, the following method holds the logic to insert an element into a cache:

```go
type Store struct {
    m map[string]*Foo
}
 
func (s Store) Put(id string, foo *Foo) {
    s.m[id] = foo
    // ...
}
```

Here, using the pointer semantics implies that the `Foo` element is shared by both the caller of `Put` and the `Store` struct.

- Sometimes we already manipulate pointers. Hence, it can be handy to store pointers directly in our collection instead of values.
- If we store large structs, and these structs are frequently mutated, we can use pointers instead to avoid a copy and an insertion for each mutation:

```go
func updateMapValue(mapValue map[string]LargeStruct, id string) {
    value := mapValue[id]              // #1
    value.foo = "bar"
    mapValue[id] = value               // #2
}
 
func updateMapPointer(mapPointer map[string]*LargeStruct, id string) {
    mapPointer[id].foo = "bar"         // #3
}
```

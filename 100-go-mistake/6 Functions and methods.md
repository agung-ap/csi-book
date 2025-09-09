# 6 Functions and methods

This chapter covers:
- When to use value or pointer receivers
- When to use named result parameters and their potential side effects
- Avoiding a common mistake while returning a nil receiver
- Why using functions that accept a filename isn’t a best practice
- Handling `defer` arguments

A *function* wraps a sequence of statements into a unit that can be called elsewhere. It can take some input(s) and produces some output(s). On the other hand, a *method* is a function attached to a given type. The attached type is called a *receiver* and can be a pointer or a value. We start this chapter by discussing how to choose one receiver type or the other, as this is usually a source of debate. Then we discuss named parameters, when to use them, and why they can sometimes lead to mistakes. We also discuss common mistakes when designing a function or returning specific values such as a nil receiver.

## 6.1 #42: Not knowing which type of receiver to use

Choosing a receiver type for a method isn’t always straightforward. When should we use value receivers? When should we use pointer receivers? In this section, we look at the conditions to make the right decision.

In chapter 12, we will thoroughly discuss values versus pointers. So, this section will only scratch the surface in terms of performance. Also, in many contexts, using a value or pointer receiver should be dictated not by performance but rather by other conditions that we will discuss. But first, let’s refresh our memories about how receivers work.

In Go, we can attach either a value or a pointer receiver to a method. With a value receiver, Go makes a copy of the value and passes it to the method. Any changes to the object remain local to the method. The original object remains unchanged.

As an illustration, the following example mutates a value receiver:

```go
type customer struct {
    balance float64
}

func (c customer) add(v float64) {              // 1
    c.balance += v
}

func main() {
    c := customer{balance: 100.}
    c.add(50.)
    fmt.Printf("balance: %.2f\n", c.balance)    // 2
}
```
1. Value receiver
2. The customer balance remains unchanged.

Because we use a value receiver, incrementing the balance in the `add` method doesn’t mutate the `balance` field of the original `customer` struct:

```
100.00
```

On the other hand, with a pointer receiver, Go passes the address of an object to the method. Intrinsically, it remains a copy, but we only copy a pointer, not the object itself (passing by reference doesn’t exist in Go). Any modifications to the receiver are done on the original object. Here is the same example, but now the receiver is a pointer:

```go
type customer struct {
    balance float64
}

func (c *customer) add(operation float64) {    // 1
    c.balance += operation
}

func main() {
    c := customer{balance: 100.0}
    c.add(50.0)
    fmt.Printf("balance: %.2f\n", c.balance)   // 2
}
```
1. Pointer receiver
2. The customer balance is updated.

Because we use a pointer receiver, incrementing the balance mutates the `balance` field of the original `customer` struct:

```
150.00
```

Choosing between value and pointer receivers isn’t always straightforward. Let’s discuss some of the conditions to help us choose.

A receiver *must* be a pointer
- If the method needs to mutate the receiver. This rule is also valid if the receiver is a slice and a method needs to append elements:

```go
type slice []int

func (s *slice) add(element int) {
    *s = append(*s, element)
}
```
- If the method receiver contains a field that cannot be copied: for example, a type part of the `sync` package (we will discuss this point in mistake #74, “Copying a sync type”).

A receiver *should* be a pointer
- If the receiver is a large object. Using a pointer can make the call more efficient, as doing so prevents making an extensive copy. When in doubt about how large is large, benchmarking can be the solution; it’s pretty much impossible to state a specific size, because it depends on many factors.

A receiver *must* be a value
- If we have to enforce a receiver’s immutability.
- If the receiver is a map, function, or channel. Otherwise, a compilation error occurs.

A receiver *should* be a value
- If the receiver is a slice that doesn’t have to be mutated.
- If the receiver is a small array or struct that is naturally a value type without mutable fields, such as `time.Time`.
- If the receiver is a basic type such as `int`, `float64`, or `string`.

One case needs more discussion. Let’s say that we design a different `customer` struct. Its mutable fields aren’t part of the struct directly but are inside another struct:

```go
type customer struct {
    data *data                                   // 1
}

type data struct {
    balance float64
}

func (c customer) add(operation float64) {       // 2
    c.data.balance += operation
}

func main() {
    c := customer{data: &data{
        balance: 100,
    }}
    c.add(50.)
    fmt.Printf("balance: %.2f\n", c.data.balance)
}
```
1. balance isn’t part of the customer struct directly but is in a struct referenced by a pointer field.
2. Uses a value receiver

Even though the receiver is a value, calling `add` changes the actual balance in the end:

```
150.00
```

In this case, we don’t need the receiver to be a pointer to mutate `balance`. However, for clarity, we may favor using a pointer receiver to highlight that `customer` as a whole object is mutable.

> ##### Mixing receiver types
>
> Are we allowed to mix receiver types, such as a struct containing multiple methods, some of which have pointer receivers and others of which have value receivers? The consensus tends toward forbidding it. However, there are some counterexamples in the standard library, for example, `time.Time`.
>
> The designers wanted to enforce that a `time.Time` struct is immutable. Hence, most methods such as `After`, `IsZero`, and `UTC` have a value receiver. But to comply with existing interfaces such as `encoding.TextUnmarshaler`, `time.Time` has to implement the `UnmarshalBinary([]byte)` `error` method, which mutates the receiver given a byte slice. Thus, this method has a pointer receiver.
>
> Consequently, mixing receiver types should be avoided in general but is not forbidden in 100% of cases.

We should now have a good understanding of whether to use value or pointer receivers. Of course, it’s impossible to be exhaustive, as there will always be edge cases, but this section’s goal was to provide guidance to cover most cases. By default, we can choose to go with a value receiver unless there’s a good reason not to do so. In doubt, we should use a pointer receiver.

In the next section, we discuss named result parameters: what they are and when to use them.

## 6.2 #43: Never using named result parameters

Named result parameters are an infrequently used option in Go. This section looks at when it’s considered appropriate to use named result parameters to make our API more convenient. But first, let’s refresh our memory about how they work.

When we return parameters in a function or a method, we can attach names to these parameters and use them as regular variables. When a result parameter is named, it’s initialized to its zero value when the function/method begins. With named result parameters, we can also call a naked return statement (without arguments). In that case, the current values of the result parameters are used as the returned values.

Here’s an example that uses a named result parameter `b`:

```go
func f(a int) (b int) {    // 1
    b = a
    return                 // 2
}
```
1. Names the int result parameter b
2. Returns the current value of b

In this example, we attach a name to the result parameter: `b`. When we call `return` without arguments, it returns the current value of `b`.

When is it recommended that we use named result parameters? First, let’s consider the following interface, which contains a method to get the coordinates from a given address:

```go
type locator interface {
    getCoordinates(address string) (float32, float32, error)
}
```

Because this interface is unexported, documentation isn’t mandatory. Just by reading this code, can you guess what these two `float32` results are? Perhaps they are a latitude and a longitude, but in which order? Depending on the conventions, latitude isn’t always the first element. Therefore, we have to check the implementation to understand the results.

In that case, we should probably use named result parameters to make the code easier to read:

```go
type locator interface {
    getCoordinates(address string) (lat, lng float32, err error)
}
```

With this new version, we can understand the meaning of the method signature by looking at the interface: latitude first, longitude second.

Now, let’s pursue the question of when to use named result parameters with the method implementation. Should we also use named result parameters as part of the implementation itself?

```go
func (l loc) getCoordinates(address string) (
    lat, lng float32, err error) {
    // ...
}
```

In this specific case, having an expressive method signature can also help code readers. Hence, we probably want to use named result parameters as well.

> **NOTE**
>
> If we need to return multiple results of the same type, we can also think about creating an ad hoc struct with meaningful field names. However, this isn’t always possible: for example, when satisfying an existing interface that we can’t update.

Next, let’s consider another function signature that allows us to store a `Customer` type in a database:

```go
func StoreCustomer(customer Customer) (err error) {
    // ...
}
```

Here, naming the `error` parameter `err` isn’t helpful and doesn’t help readers. In this case, we should favor not using named result parameters.

So, when to use named result parameters depends on the context. In most cases, if it’s not clear whether using them makes our code more readable, we shouldn’t use named result parameters.

Also note that having the result parameters already initialized can be quite handy in some contexts, even though they don’t necessarily help readability. The following example proposed in *Effective Go* (https://go.dev/doc/effective_go) is inspired by the `io.ReadFull` function:

```go
func ReadFull(r io.Reader, buf []byte) (n int, err error) {
    for len(buf) > 0 && err == nil {
        var nr int
        nr, err = r.Read(buf)
        n += nr
        buf = buf[nr:]
    }
    return
}
```

In this example, having named result parameters doesn’t really increase readability. However, because both `n` and `err` are initialized to their zero value, the implementation is shorter. On the other hand, this function can be slightly confusing for readers at first sight. Again, it’s a question of finding the right balance.

One note regarding naked returns (returns without arguments): they are considered acceptable in short functions; otherwise, they can harm readability because the reader must remember the outputs throughout the entire function. We should also be consistent within the scope of a function, using either only naked returns or only returns with arguments.

So what are the rules regarding named result parameters? In most cases, using named result parameters in the context of an interface definition can increase readability without leading to any side effects. But there’s no strict rule in the context of a method implementation. In some cases, named result parameters can also increase readability: for example, if two parameters have the same type. In other cases, they can also be used for convenience. Therefore, we should use named result parameters sparingly when there’s a clear benefit.

> **NOTE**
>
> In mistake #54, “Not handling defer errors,” we will discuss another use case for using named result parameters in the context of `defer` calls.

Furthermore, if we’re not careful enough, using named result parameters can lead to side effects and unintended consequences, as we see in the next section.

## 6.3 #44: Unintended side effects with named result parameters

We mentioned why named result parameters can be useful in some situations. But as these result parameters are initialized to their zero value, using them can sometimes lead to subtle bugs if we’re not careful enough. This section illustrates such a case.

Let’s enhance our previous example of a method that returns the latitude and longitude from a given address. Because we return two `float32`s, we decide to use named result parameters to make the latitude and longitude explicit. This function will first validate the given address and then get the coordinates. In between, it will perform a check on the input context to make sure it wasn’t canceled and that its deadline hasn’t passed.

> **NOTE**
>
> We will delve into the concept of context in Go in mistake #60, “Misunderstanding Go contexts.” If you’re not familiar with contexts, briefly, a context can carry a cancellation signal or a deadline. We can check those by calling the `Err` method and testing that the returned error isn’t nil.

Here’s the new implementation of the `getCoordinates` method. Can you spot what’s wrong with this code?

```go
func (l loc) getCoordinates(ctx context.Context, address string) (
    lat, lng float32, err error) {
    isValid := l.validateAddress(address)          // 1
    if !isValid {
        return 0, 0, errors.New("invalid address")
    }

    if ctx.Err() != nil {                          // 2
        return 0, 0, err
    }

    // Get and return coordinates
}
```
1. Validates the address
2. Checks whether the context was canceled or the deadline has passed

The error might not be obvious at first glance. Here, the error returned in the `if ctx.Err()` `!=` `nil` scope is `err`. But we haven’t assigned any value to the `err` variable. It’s still assigned to the zero value of an `error` type: `nil`. Hence, this code will always return a nil error.

Furthermore, this code compiles because `err` was initialized to its zero value due to named result parameters. Without attaching a name, we would have gotten the following compilation error:

```
Unresolved reference 'err'
```

One possible fix is to assign `ctx.Err()` to `err` like so:

```go
if err := ctx.Err(); err != nil {
    return 0, 0, err
}
```

We keep returning `err`, but we first assign it to the result of `ctx.Err()`. Note that `err` in this example shadows the result variable.

> ##### Using a naked return statement
>
> Another option is to use a naked return statement:
>
> ```go
> if err = ctx.Err(); err != nil {
>     return
> }
> ```
>
> However, doing so would break the rule stating that we shouldn’t mix naked returns and returns with arguments. In this case, we should probably stick with the first option. Remember that using named result parameters doesn’t necessarily mean using naked returns. Sometimes we can just use named result parameters to make a signature clearer.

We conclude this discussion by emphasizing that named result parameters can improve code readability in some cases (such as returning the same type multiple times) and be quite handy in others. But we must recall that each parameter is initialized to its zero value. As we have seen in this section, this can lead to subtle bugs that aren’t always straightforward to spot while reading code. Therefore, let’s remain cautious when using named result parameters, to avoid potential side effects.

In the next section, we discuss a common mistake made by Go developers when a function returns an interface.

## 6.4 #45: Returning a nil receiver

In this section, we discuss the impact of returning an interface and why doing so may lead to errors in some conditions. This mistake is probably one of the most widespread in Go because it may be considered counterintuitive, at least before we’ve made it.

Let’s consider the following example. We will work on a `Customer` struct and implement a `Validate` method to perform sanity checks. Instead of returning the first error, we want to return a list of errors. To do that, we will create a custom error type to convey multiple errors:

```go
type MultiError struct {
    errs []string
}

func (m *MultiError) Add(err error) {      // 1
    m.errs = append(m.errs, err.Error())
}

func (m *MultiError) Error() string {      // 2
    return strings.Join(m.errs, ";")
}
```
1. Adds an error
2. Implements the error interface

`MultiError` satisfies the `error` interface because it implements `Error()` `string`. Meanwhile, it exposes an `Add` method to append an error. Using this struct, we can implement a `Customer.Validate` method in the following manner to check the customer’s age and name. If the sanity checks are OK, we want to return a nil error:

```go
func (c Customer) Validate() error {
    var m *MultiError                           // 1

    if c.Age < 0 {
        m = &MultiError{}
        m.Add(errors.New("age is negative"))    // 2
    }
    if c.Name == "" {
        if m == nil {
            m = &MultiError{}
        }
        m.Add(errors.New("name is nil"))        // 3
    }

    return m
}
```
1. Instantiates an empty *MultiError
2. Appends an error if the age is negative
3. Appends an error if the name is nil

# 7 Error management

### This chapter covers
* Understanding when to panic
* Knowing when to wrap an error
* Comparing error types and error values efficiently since Go 1.13
* Handling errors idiomatically
* Understanding how to ignore an error
* Handling errors in `defer` calls

Error management is a fundamental aspect of building robust and observable applications, and it should be as important as any other part of a codebase. In Go, error management doesn’t rely on the traditional try/catch mechanism as most programming languages do. Instead, errors are returned as normal return values.

This chapter will cover the most common mistakes related to errors.

## 7.1 #48: Panicking

It’s pretty common for Go newcomers to be somewhat confused about error handling. In Go, errors are usually managed by functions or methods that return an `error` type as the last parameter. But some developers may find this approach surprising and be tempted to reproduce exception handling in languages such as Java or Python using `panic` and `recover`. So, let’s refresh our minds about the concept of panic and discuss when it’s considered appropriate or not to panic.

In Go, `panic` is a built-in function that stops the ordinary flow:

```go
func main() {
    fmt.Println("a")
    panic("foo")
    fmt.Println("b")
}
```

This code prints `a` and then stops before printing `b`:

```
a
panic: foo
 
goroutine 1 [running]:
main.main()
        main.go:7 +0xb3
```

Once a panic is triggered, it continues up the call stack until either the current goroutine has returned or `panic` is caught with `recover`:

```go
func main() {
    defer func() {                       // #1
        if r := recover(); r != nil {
            fmt.Println("recover", r)
        }
    }()
 
    f()                                  // #2
}
 
func f() {
    fmt.Println("a")
    panic("foo")
    fmt.Println("b")
}
```
> #1 Calls recover within a defer closure
> #2 Calls f, which panics. This panic is caught by the previous recover.

In the `f` function, once `panic` is called, it stops the current execution of the function and goes up the call stack: `main`. In `main`, because the panic is caught with `recover`, it doesn’t stop the goroutine:

```
a
recover foo
```

Note that calling `recover()` to capture a goroutine panicking is only useful inside a `defer` function; otherwise, the function would return `nil` and have no other effect. This is because `defer` functions are also executed when the surrounding function panics.

Now, let’s tackle this question: when is it appropriate to panic? In Go, `panic` is used to signal genuinely exceptional conditions, such as a programmer error. For example, if we look at the `net/http` package, we notice that in the `WriteHeader` method, there is a call to a `checkWriteHeaderCode` function to check whether the status code is valid:

```go
func checkWriteHeaderCode(code int) {
    if code < 100 || code > 999 {
        panic(fmt.Sprintf("invalid WriteHeader code %v", code))
    }
}
```

This function panics if the status code is invalid, which is a pure programmer error.

Another example based on a programmer error can be found in the `database/sql` package while registering a database driver:

```go
func Register(name string, driver driver.Driver) {
    driversMu.Lock()
    defer driversMu.Unlock()
    if driver == nil {
        panic("sql: Register driver is nil")                     // #1
    }
    if _, dup := drivers[name]; dup {
        panic("sql: Register called twice for driver " + name)   // #2
    }
    drivers[name] = driver
}
```
> #1 Panics if the driver is nil
> #2 Panics if the driver is already registered

This function panics if the driver is `nil` (`driver.Driver` is an interface) or has already been registered. Both cases would again be considered programmer errors. Also, in most cases (for example, with `go-sql-driver/mysql` [https://github.com/go-sql-driver/mysql], the most popular MySQL driver for Go), `Register` is called via an `init` function, which limits error handling. For all these reasons, the designers made the function panic in case of an error.

Another use case in which to panic is when our application requires a dependency but fails to initialize it. For example, let’s imagine that we expose a service to create new customer accounts. At some stage, this service needs to validate the provided email address. To implement this, we decide to use a regular expression.

In Go, the `regexp` package exposes two functions to create a regular expression from a string: `Compile` and `MustCompile`. The former returns a `*regexp.Regexp` and an error, whereas the latter returns only a `*regexp.Regexp` but panics in case of an error. In this case, the regular expression is a mandatory dependency. Indeed, if we fail to compile it, we will never be able to validate any email input. Hence, we may favor using `MustCompile` and panicking in case of an error.

Panicking in Go should be used sparingly. We have seen two prominent cases, one to signal a programmer error and another where our application fails to create a mandatory dependency. Hence, there are exceptional conditions that lead us to stop the application. In most other cases, error management should be done with a function that returns a proper `error` type as the last return argument.

Let’s now start our discussion of errors. In the next section, we see when to wrap an error. 

## 7.2 #49: Ignoring when to wrap an error

Since Go 1.13, the `%w` directive allows us to wrap errors conveniently. But some developers may be confused about when to wrap an error (or not). So, let’s remind ourselves what error wrapping is and then when to use it.

Error wrapping is about wrapping or packing an error inside a wrapper container that also makes the source error available (see figure 7.1). In general, the two main use cases for error wrapping are the following:

* Adding additional context to an error 
* Marking an error as a specific error 

![Figure 7.1 Wrap the error inside a wrapper.](https://drek4537l1klr.cloudfront.net/harsanyi/Figures/CH07_F01_Harsanyi.png)

Regarding adding context, let’s consider the following example. We receive a request from a specific user to access a database resource, but we get a “permission denied” error during the query. For debugging purposes, if the error is eventually logged, we want to add extra context. In this case, we can wrap the error to indicate who the user is and what resource is being accessed, as shown in figure 7.2.

![Figure 7.2 Adding additional context to the “permission denied” error](https://drek4537l1klr.cloudfront.net/harsanyi/Figures/CH07_F02_Harsanyi.png)

Now let’s say that instead of adding context, we want to mark the error. For example, we want to implement an HTTP handler that checks whether all the errors received while calling functions are of a `Forbidden` type so we can return a 403 status code. In that case, we can wrap this error inside `Forbidden` (see figure 7.3).

![Figure 7.3 Marking the error Forbidden](https://drek4537l1klr.cloudfront.net/harsanyi/Figures/CH07_F03_Harsanyi.png)

In both cases, the source error remains available. Hence, a caller can also handle an error by unwrapping it and checking the source error. Also note that sometimes we want to combine both approaches: adding context and marking an error.

Now that we have clarified the main use cases in which to wrap an error, let’s see different ways in Go to return an error we receive. We will consider the following piece of code and explore different options inside the `if err != nil` block:

```go
func Foo() error {
    err := bar()
    if err != nil {
        // ?          // #1
    }
    // ...
}
```
> #1 How do we return the error?

The first option is to return this error directly. If we don’t want to mark the error and there’s no helpful context we want to add, this approach is fine:

```go
if err != nil {
    return err
}
```

Figure 7.4 shows that we return the same error returned by `bar`.

![Figure 7.4 We can return the error directly.](https://drek4537l1klr.cloudfront.net/harsanyi/Figures/CH07_F04_Harsanyi.png)

Before Go 1.13, to wrap an error, the only option without using an external library was to create a custom error type:

```go
type BarError struct {
    Err error
}
 
func (b BarError) Error() string {
    return "bar failed:" + b.Err.Error()
}
```

Then, instead of returning `err` directly, we wrapped the error into a `BarError` (see figure 7.5):

```go
if err != nil {
    return BarError{Err: err}
}
```

![Figure 7.5 Wrapping the error inside BarError](https://drek4537l1klr.cloudfront.net/harsanyi/Figures/CH07_F05_Harsanyi.png)

The benefit of this option is its flexibility. Because `BarError` is a custom struct, we can add any additional context if needed. However, being obliged to create a specific error type can quickly become cumbersome if we want to repeat this operation.

To overcome this situation, Go 1.13 introduced the `%w` directive:

```go
if err != nil {
    return fmt.Errorf("bar failed: %w", err)
}
```

This code wraps the source error to add additional context without having to create another error type, as shown in figure 7.6.

![Figure 7.6 Wrap an error into a standard error.](https://drek4537l1klr.cloudfront.net/harsanyi/Figures/CH07_F06_Harsanyi.png)

Because the source error remains available, a client can unwrap the parent error and then check whether the source error was of a specific type or value (we discuss these points in the following sections).

The last option we will discuss is to use the `%v` directive, instead:

```go
if err != nil {
    return fmt.Errorf("bar failed: %v", err)
}
```

The difference is that the error itself isn’t wrapped. We transform it into another error to add context, and the source error is no longer available, as shown in figure 7.7.

![Figure 7.7 Converting the error](https://drek4537l1klr.cloudfront.net/harsanyi/Figures/CH07_F07_Harsanyi.png)

The information about the source of the problem remains available. However, a caller can’t unwrap this error and check whether the source was `bar` `error`. So, in a sense, this option is more restrictive than `%w`. Should we prevent that, since the `%w` directive has been released? Not necessarily.

Wrapping an error makes the source error available for callers. Hence, it means introducing potential coupling. For example, imagine that we use wrapping and the caller of `Foo` checks whether the source error is `bar error`. Now, what if we change our implementation and use another function that will return another type of error? It will break the error check made by the caller.

To make sure our clients don’t rely on something that we consider implementation details, the error returned should be transformed, not wrapped. In such a case, using `%v` instead of `%w` can be the way to go.

Let’s review all the different options we tackled.

| **Option** | **Extra context** | **Marking an error** | **Source error available** |
| :--- | :--- | :--- | :--- |
| Returning error directly | No | No | Yes |
| Custom error type | Possible (if the error type contains a string field, for example) | Yes | Possible (if the source error is exported or accessible via a method) |
| `fmt.Errorf` with `%w` | Yes | No | Yes |
| `fmt.Errorf` with `%v` | Yes | No | No |

To summarize, when handling an error, we can decide to wrap it. Wrapping is about adding additional context to an error and/or marking an error as a specific type. If we need to mark an error, we should create a custom error type. However, if we just want to add extra context, we should use `fmt.Errorf` with the `%w` directive as it doesn’t require creating a new error type. Yet, error wrapping creates potential coupling as it makes the source error available for the caller. If we want to prevent it, we shouldn’t use error wrapping but error transformation, for example, using `fmt.Errorf` with the `%v` directive.

This section has shown how to wrap an error with the `%w` directive. But once we start using it, what’s the impact of checking an error type?

## 7.3 #50: Checking an error type inaccurately

The previous section introduced a possible way to wrap errors using the `%w` directive. However, when we use that approach, it’s also essential to change our way of checking for a specific error type; otherwise, we may handle errors inaccurately.

Let’s discuss a concrete example. We will write an HTTP handler to return the transaction amount from an ID. Our handler will parse the request to get the ID and retrieve the amount from a database (DB). Our implementation can fail in two cases:

* If the ID is invalid (string length other than five characters) 
* If querying the DB fails 

In the former case, we want to return `StatusBadRequest` `(400)`, whereas in the latter, we want to return `ServiceUnavailable` `(503)`. To do so, we will create a `transientError` type to mark that an error is temporary. The parent handler will check the error type. If the error is a `transientError`, it will return a 503 status code; otherwise, it will return a 400 status code.

Let’s first focus on the error type definition and the function the handler will call:

```go
type transientError struct {
    err error
}
 
func (t transientError) Error() string {              // #1
    return fmt.Sprintf("transient error: %v", t.err)
}
 
func getTransactionAmount(transactionID string) (float32, error) {
    if len(transactionID) != 5 {
        return 0, fmt.Errorf("id is invalid: %s",
            transactionID)                            // #2
    }
 
    amount, err := getTransactionAmountFromDB(transactionID)
    if err != nil {
        return 0, transientError{err: err}            // #3
    }
    return amount, nil
}
```
> #1 Creates a custom transientError
> #2 Returns a simple error if the transaction ID is invalid
> #3 Returns a transientError if we fail to query the DB

`getTransactionAmount` returns an error using `fmt.Errorf` if the identifier is invalid. However, if getting the transaction amount from the DB fails, `getTransactionAmount` wraps the error into a `transientError` type.

Now, let’s write the HTTP handler that checks the error type to return the appropriate HTTP status code:

```go
func handler(w http.ResponseWriter, r *http.Request) {
    transactionID := r.URL.Query().Get("transaction")      // #1
 
    amount, err := getTransactionAmount(transactionID)     // #2
    if err != nil {
        switch err := err.(type) {                         // #3
        case transientError:
            http.Error(w, err.Error(), http.StatusServiceUnavailable)
        default:
            http.Error(w, err.Error(), http.StatusBadRequest)
        }
        return
    }
 
    // Write response
}
```
> #1 Extracts the transaction ID
> #2 Calls getTransactionAmount that contains all the logic
> #3 Checks the error type and returns a 503 if the error is a transient one; otherwise, a 400

Using a `switch` on the error type, we return the appropriate HTTP status code: 400 in the case of a bad request or 503 in the case of a transient error.

This code is perfectly valid. However, let’s assume that we want to perform a small refactoring of `getTransactionAmount`. The `transientError` will be returned by `getTransactionAmountFromDB` instead of `getTransactionAmount`. `getTransactionAmount` now wraps this error using the `%w` directive:

```go
func getTransactionAmount(transactionID string) (float32, error) {
    // Check transaction ID validity
 
    amount, err := getTransactionAmountFromDB(transactionID)
    if err != nil {
        return 0, fmt.Errorf("failed to get transaction %s: %w",
            transactionID, err)                // #1
    }
    return amount, nil
}
 
func getTransactionAmountFromDB(transactionID string) (float32, error) {
    // ...
    if err != nil {
        return 0, transientError{err: err}     // #2
    }
    // ...
}
```
> #1 Wraps the error instead of returning a transientError directly
> #2 This function now returns the transientError.

If we run this code, it always returns a 400 regardless of the error case, so the `case Transient` error will never be hit. How can we explain this behavior?

Before the refactoring, `transientError` was returned by `getTransactionAmount` (see figure 7.8). After the refactoring, `transientError` is now returned by `getTransactionAmountFromDB` (figure 7.9).

![Figure 7.8 Because getTransactionAmount returned a transientError if the DB failed, the case was true.](https://drek4537l1klr.cloudfront.net/harsanyi/Figures/CH07_F08_Harsanyi.png)

![Figure 7.9 Now getTransactionAmount returns a wrapped error. Hence, case transientError is false.](https://drek4537l1klr.cloudfront.net/harsanyi/Figures/CH07_F09_Harsanyi.png)

What `getTransactionAmount` returns isn’t a `transientError` directly: it’s an error wrapping `transientError`. Therefore `case transientError` is now false.

For that exact purpose, Go 1.13 came with a directive to wrap an error and a way to check whether the wrapped error is of a certain type with `errors.As`. This function recursively unwraps an error and returns `true` if an error in the chain matches the expected type.

Let’s rewrite our implementation of the caller using `errors.As`:

```go
func handler(w http.ResponseWriter, r *http.Request) {
    // Get transaction ID
 
    amount, err := getTransactionAmount(transactionID)
    if err != nil {
        if errors.As(err, &transientError{}) {      // #1
            http.Error(w, err.Error(),
                http.StatusServiceUnavailable)      // #2
        } else {
            http.Error(w, err.Error(),
                http.StatusBadRequest)              // #3
        }
        return
    }
 
    // Write response
}
```
> #1 Calls errors.As by providing a pointer to transientError
> #2 Returns a 503 if the error is transient
> #3 Else returns a 400

We got rid of the `switch` case type in this new version, and we now use `errors.As`. This function requires the second argument (the target error) to be a pointer. Otherwise, the function will compile but panic at runtime. Regardless of whether the runtime error is directly a `transientError` type or an error wrapping `transientError`, `errors.As` returns `true`; hence, the handler will return a 503 status code.

In summary, if we rely on Go 1.13 error wrapping, we must use `errors.As` to check whether an error is a specific type. This way, regardless of whether the error is returned directly by the function we call or wrapped inside an error, `errors.As` will be able to recursively unwrap our main error and see if one of the errors is a specific type.

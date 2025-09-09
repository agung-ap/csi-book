# 9 Concurrency: Practice

### This chapter covers
* Preventing common mistakes with goroutines and channels
* Understanding the impacts of using standard data structures alongside concurrent code
* Using the standard library and some extensions
* Avoiding data races and deadlocks

In the previous chapter, we discussed the foundations of concurrency. Now it’s time to look at practical mistakes made by Go developers when working with the concurrency primitives.

## 9.1 #61: Propagating an inappropriate context

Contexts are omnipresent when working with concurrency in Go, and in many situations, it may be recommended to propagate them. However, context propagation can sometimes lead to subtle bugs, preventing subfunctions from being correctly executed.

Let’s consider the following example. We expose an HTTP handler that performs some tasks and returns a response. But just before returning the response, we also want to send it to a Kafka topic. We don’t want to penalize the HTTP consumer latency-wise, so we want the publish action to be handled asynchronously within a new goroutine. We assume that we have at our disposal a `publish` function that accepts a context so the action of publishing a message can be interrupted if the context is canceled, for example. Here is a possible implementation:

```go
func handler(w http.ResponseWriter, r *http.Request) {
    response, err := doSomeTask(r.Context(), r)         // #1
    if err != nil {
        http.Error(w, err.Error(), http.StatusInternalServerError)
        return
    }
 
    go func() {                                         // #2
        err := publish(r.Context(), response)
        // Do something with err
    }()
 
    writeResponse(response)                             // #3
}
```

> #1 Performs some task to compute the HTTP response
> #2 Creates a goroutine to publish the response to Kafka
> #3 Writes the HTTP response

First we call a `doSomeTask` function to get a `response` variable. It’s used within the goroutine calling `publish` and to format the HTTP response. Also, when calling `publish`, we propagate the context attached to the HTTP request. Can you guess what’s wrong with this piece of code?

We have to know that the context attached to an HTTP request can cancel in different conditions:

* When the client’s connection closes
* In the case of an HTTP/2 request, when the request is canceled
* When the response has been written back to the client

In the first two cases, we probably handle things correctly. For example, if we get a response from `doSomeTask` but the client has closed the connection, it’s probably OK to call `publish` with a context already canceled so the message isn’t published. But what about the last case?

When the response has been written to the client, the context associated with the request will be canceled. Therefore, we are facing a race condition:

* If the response is written after the Kafka publication, we both return a response and publish a message successfully.
* However, if the response is written before or during the Kafka publication, the message shouldn’t be published.

In the latter case, calling `publish` will return an error because we returned the HTTP response quickly.

How can we fix this issue? One idea is to not propagate the parent context. Instead, we would call `publish` with an empty context:

```go
err := publish(context.Background(), response)    // #1
```

> #1 Uses an empty context instead of the HTTP request context

Here, that would work. Regardless of how long it takes to write back the HTTP response, we can call `publish`.

But what if the context contained useful values? For example, if the context contained a correlation ID used for distributed tracing, we could correlate the HTTP request and the Kafka publication. Ideally, we would like to have a new context that is detached from the potential parent cancellation but still conveys the values.

The standard package doesn’t provide an immediate solution to this problem. Hence, a possible solution is to implement our own Go context similar to the context provided, except that it doesn’t carry the cancellation signal.

A `context.Context` is an interface containing four methods:

```go
type Context interface {
    Deadline() (deadline time.Time, ok bool)
    Done() <-chan struct{}
    Err() error
    Value(key any) any
}
```

The context’s deadline is managed by the `Deadline` method and the cancellation signal is managed via the `Done` and `Err` methods. When a deadline has passed or the context has been canceled, `Done` should return a closed channel, whereas `Err` should return an error. Finally, the values are carried via the `Value` method.

Let’s create a custom context that detaches the cancellation signal from a parent context:

```go
type detach struct {                  // #1
    ctx context.Context
}
 
func (d detach) Deadline() (time.Time, bool) {
    return time.Time{}, false
}
 
func (d detach) Done() <-chan struct{} {
    return nil
}
 
func (d detach) Err() error {
    return nil
}
 
func (d detach) Value(key any) any {
    return d.ctx.Value(key)           // #2
}
```

> #1 Custom struct acting as a wrapper on top of the initial context
> #2 Delegates the get value call to the parent context

Except for the `Value` method that calls the parent context to retrieve a value, the other methods return a default value so the context is never considered expired or canceled.

Thanks to our custom context, we can now call `publish` and detach the cancellation signal:

```go
err := publish(detach{ctx: r.Context()}, response)    // #1
```

> #1 Uses detach on top of the HTTP context

Now the context passed to `publish` will never expire or be canceled, but it will carry the parent context’s values.

In summary, propagating a context should be done cautiously. We illustrated that in this section with an example of handling an asynchronous action based on a context associated with an HTTP request. Because the context is canceled once we return the response, the asynchronous action can also be stopped unexpectedly. Let’s bear in mind the impacts of propagating a given context and, if necessary, that it is always possible to create a custom context for a specific action.

The following section discusses a common concurrency mistake: starting a goroutine without plans to stop it. 

## 9.2 #62: Starting a goroutine without knowing when to stop it

Goroutines are easy and cheap to start—so easy and cheap that we may not necessarily have a plan for when to stop a new goroutine, which can lead to leaks. Not knowing when to stop a goroutine is a design issue and a common concurrency mistake in Go. Let’s understand why and how to prevent it.

First, let’s quantify what a goroutine leak means. In terms of memory, a goroutine starts with a minimum stack size of 2 KB, which can grow and shrink as needed (the maximum stack size is 1 GB on 64-bit and 250 MB on 32-bit). Memory-wise, a goroutine can also hold variable references allocated to the heap. Meanwhile, a goroutine can hold resources such as HTTP or database connections, open files, and network sockets that should eventually be closed gracefully. If a goroutine is leaked, these kinds of resources will also be leaked.

Let’s look at an example in which the point where a goroutine stops is unclear. Here, a parent goroutine calls a function that returns a channel and then creates a new goroutine that will keep receiving messages from this channel:

```go
ch := foo()
go func() {
    for v := range ch {
        // ...
    }
}()
```

The created goroutine will exit when `ch` is closed. But do we know exactly when this channel will be closed? It may not be evident, because `ch` is created by the `foo` function. If the channel is never closed, it’s a leak. So, we should always be cautious about the exit points of a goroutine and make sure one is eventually reached.

Let’s discuss a concrete example. We will design an application that needs to watch some external configuration (for example, using a database connection). Here’s a first implementation:

```go
func main() {
    newWatcher()
 
    // Run the application
}
 
type watcher struct { /* Some resources */ }
 
func newWatcher() {
    w := watcher{}
    go w.watch()      // #1
}
```

> #1 Creates a goroutine that watches some external configuration

We call `newWatcher`, which creates a `watcher` struct and spins up a goroutine in charge of watching the configuration. The problem with this code is that when the main goroutine exits (perhaps because of an OS signal or because it has a finite workload), the application is stopped. Hence, the resources created by `watcher` aren’t closed gracefully. How can we prevent this from happening?

One option could be to pass to `newWatcher` a context that will be canceled when `main` returns:

```go
func main() {
    ctx, cancel := context.WithCancel(context.Background())
    defer cancel()
 
    newWatcher(ctx)      // #1
 
    // Run the application
}
 
func newWatcher(ctx context.Context) {
    w := watcher{}
    go w.watch(ctx)      // #2
}
```

> #1 Passes to newWatcher a context that will eventually cancel
> #2 Propagates this context

We propagate the context created to the `watch` method. When the context is canceled, the `watcher` struct should close its resources. However, can we guarantee that `watch` will have time to do so? Absolutely not—and that’s a design flaw.

The problem is that we used signaling to convey that a goroutine had to be stopped. We didn’t block the parent goroutine until the resources had been closed. Let’s make sure we do:

```go
func main() {
    w := newWatcher()
    defer w.close()     // #1
 
    // Run the application
}
 
func newWatcher() watcher {
    w := watcher{}
    go w.watch()
    return w
}
 
func (w watcher) close() {
    // Close the resources
}
```

> #1 Defers the call to the close method

`watcher` has a new method: `close`. Instead of signaling `watcher` that it’s time to close its resources, we now call this `close` method, using `defer` to guarantee that the resources are closed before the application exits.

In summary, let’s be mindful that a goroutine is a resource like any other that must eventually be closed to free memory or other resources. Starting a goroutine without knowing when to stop it is a design issue. Whenever a goroutine is started, we should have a clear plan about when it will stop. Last but not least, if a goroutine creates resources and its lifetime is bound to the lifetime of the application, it’s probably safer to wait for this goroutine to complete before exiting the application. This way, we can ensure that the resources can be freed.

Let’s now discuss one of the most common mistakes while working in Go: mishandling goroutines and loop variables. 

## 9.3 #63: Not being careful with goroutines and loop variables

Mishandling goroutines and loop variables is probably one of the most common mistakes made by Go developers when writing concurrent applications. Let’s look at a concrete example; then we will define the conditions of such a bug and how to prevent it.

In the following example, we initialize a slice. Then, within a closure executed as a new goroutine, we access this element:

```go
s := []int{1, 2, 3}
 
for _, i := range s {      // #1
    go func() {
        fmt.Print(i)       // #2
    }()
}
```

> #1 Iterates over each element
> #2 Accesses the loop variable

We might expect this code to print `123` in no particular order (as there is no guarantee that the first goroutine created will complete first). However, the output of this code isn’t deterministic. For example, sometimes it prints `233` and other times `333`. What’s the reason?

In this example, we create new goroutines from a closure. As a reminder, a closure is a function value that references variables from outside its body: here, the `i` variable. We have to know that when a closure goroutine is executed, it doesn’t capture the values when the goroutine is created. Instead, all the goroutines refer to the exact same variable. When a goroutine runs, it prints the value of `i` at the time `fmt.Print` is executed. Hence, `i` may have been modified since the goroutine was launched.

Figure 9.1 shows a possible execution when the code prints `233`. Over time, the value of `i` varies: `1`, `2`, and then `3`. In each iteration, we spin up a new goroutine. Because there’s no guarantee when each goroutine will start and complete, the result varies as well. In this example, the first goroutine prints `i` when it’s equal to `2`. Then the other goroutines print `i` when the value is already equal to `3`. Therefore, this example prints `233`. The behavior of this code isn’t deterministic.

![Figure 9.1 The goroutines access an i variable that isn’t fixed but varies over time.](https://drek4537l1klr.cloudfront.net/harsanyi/Figures/CH09_F01_Harsanyi.png)

What are the solutions if we want each closure to access the value of `i` when the goroutine is created? The first option, if we want to keep using a closure, involves creating a new variable:

```go
for _, i := range s {
    val := i            // #1
    go func() {
        fmt.Print(val)
    }()
}
```

> #1 Creates a variable local to each iteration

Why does this code work? In each iteration, we create a new local `val` variable. This variable captures the current value of `i` before the goroutine is created. Hence, when each closure goroutine executes the print statement, it does so with the expected value. This code prints `123` (again, in no particular order).

The second option no longer relies on a closure and instead uses an actual function:

```go
for _, i := range s {
    go func(val int) {     // #1
        fmt.Print(val)
    }(i)                   // #2
}
```

> #1 Executes a function that takes an integer as an argument
> #2 Calls this function and passes the current value of i

We still execute an anonymous function within a new a goroutine (we don’t run `go f(i)`, for example), but this time it isn’t a closure. The function doesn’t reference `val` as a variable from outside its body; `val` is now part of the function input. By doing so, we fix `i` in each iteration and make our application work as expected.

We have to be cautious with goroutines and loop variables. If the goroutine is a closure that accesses an iteration variable declared from outside its body, that’s a problem. We can fix it either by creating a local variable (for example, as we have seen using `val := i` before executing the goroutine) or by making the function no longer a closure. Both options work, and there isn’t one that we should favor over the other. Some developers may find the closure approach handier, whereas others may find the function approach more expressive.

What happens with a `select` statement on multiple channels? Let’s find out. 

## 9.4 #64: Expecting deterministic behavior using select and channels

One common mistake made by Go developers while working with channels is to make wrong assumptions about how `select` behaves with multiple channels. A false assumption can lead to subtle bugs that may be hard to identify and reproduce.

Let’s imagine that we want to implement a goroutine that needs to receive from two channels:

* `messageCh` for new messages to be processed.
* `disconnectCh` to receive notifications conveying disconnections. In that case, we want to return from the parent function.

Of these two channels, we want to prioritize `messageCh`. For example, if a disconnection occurs, we want to ensure that we have received all the messages before returning.

We may decide to handle the prioritization like so:

```go
for {
    select {                         // #1
    case v := <-messageCh:           // #2
        fmt.Println(v)
    case <-disconnectCh:             // #3
        fmt.Println("disconnection, return")
        return
    }
}
```

> #1 Uses the select statement to receive from multiple channels
> #2 Receives new messages
> #3 Receives disconnections

We use `select` to receive from multiple channels. Because we want to prioritize `messageCh`, we might assume that we should write the `messageCh` case first and the `disconnectCh` case next. But does this code even work? Let’s give it a try by writing a dummy producer goroutine that sends 10 messages and then sends a disconnection notification:

```go
for i := 0; i < 10; i++ {
    messageCh <- i
}
disconnectCh <- struct{}{}
```

If we run this example, here is a possible output if `messageCh` is buffered:

```
0
1
2
3
4
disconnection, return
```

Instead of consuming the 10 messages, we only received 5 of them. What’s the reason? It lies in the specification of the `select` statement with multiple channels (https://go.dev/ref/spec):

> If one or more of the communications can proceed, a single one that can proceed is chosen via a uniform pseudo-random selection.

Unlike a `switch` statement, where the first case with a match wins, the `select` statement selects randomly if multiple options are possible.

This behavior might look odd at first, but there’s a good reason for it: to prevent possible starvation. Suppose the first possible communication chosen is based on the source order. In that case, we may fall into a situation where, for example, we only receive from one channel because of a fast sender. To prevent this, the language designers decided to use a random selection.

Coming back to our example, even though `case` `v` `:=` `<-messageCh` is first in source order, if there’s a message in both `messageCh` and `disconnectCh`, there is no guarantee about which case will be chosen. For that reason, the example’s behavior isn’t deterministic. We may receive 0 messages, or 5, or 10.

How can we overcome this situation? There are different possibilities if we want to receive all the messages before returning in case of a disconnection.

If there’s a single producer goroutine, we have two options:

* Make `messageCh` an unbuffered channel instead of a buffered channel. Because the sender goroutine blocks until the receiver goroutine is ready, this approach guarantees that all the messages from `messageCh` are received before the disconnection from `disconnectCh`.
* Use a single channel instead of two channels. For example, we can define a `struct` that conveys either a new message or a disconnection. Channels guarantee that the order for the messages sent is the same as for the messages received, so we can ensure that the disconnection is received last.

If we fall into the case where we have multiple producer goroutines, it may be impossible to guarantee which one writes first. Hence, whether we have an unbuffered `messageCh` channel or a single channel, it will lead to a race condition among the producer goroutines. In that case, we can implement the following solution:

1. Receive from either `messageCh` or `disconnectCh`.
2. If a disconnection is received
    * Read all the existing messages in `messageCh`, if any.
    * Then return.

Here is the solution:

```go
for {
    select {
    case v := <-messageCh:
        fmt.Println(v)
    case <-disconnectCh:
        for {                          // #1
            select {
            case v := <-messageCh:     // #2
                fmt.Println(v)
            default:                   // #3
                fmt.Println("disconnection, return")
                return
            }
        }
    }
}
```

> #1 Inner for/select
> #2 Reads the remaining messages
> #3 Then returns

This solution uses an inner `for/select` with two cases: one on `messageCh` and a `default` case. Using `default` in a `select` statement is chosen only if none of the other cases match. In this case, it means we will return only after we have received all the remaining messages in `messageCh`.

Let’s look at an example of how this code works. We will consider the case where we have two messages in `messageCh` and one disconnection in `disconnectCh`, as shown in figure 9.2.

![Figure 9.2 Initial state](https://drek4537l1klr.cloudfront.net/harsanyi/Figures/CH09_F02_Harsanyi.png)

In this situation, as we have said, `select` chooses one case or the other randomly. Let’s assume `select` chooses the second case; see figure 9.3.

![Figure 9.3 Receiving the disconnection](https://drek4537l1klr.cloudfront.net/harsanyi/Figures/CH09_F03_Harsanyi.png)

So, we receive the disconnection and enter in the inner `select` (figure 9.4). Here, as long as messages remain in `messageCh`, `select` will always prioritize the first case over `default` (figure 9.5).

![Figure 9.4 Inner select](https://drek4537l1klr.cloudfront.net/harsanyi/Figures/CH09_F04_Harsanyi.png)

# 10 The standard library

### This chapter covers
* Providing a correct time duration
* Understanding potential memory leaks while using `time.After`
* Avoiding common mistakes in JSON handling and SQL
* Closing transient resources
* Remembering the `return` statement in HTTP handlers
* Why production-grade applications shouldn’t use default HTTP clients and servers

The Go standard library is a set of core packages that enhance and extend the language. For example, Go developers can write HTTP clients or servers, handle JSON data, or interact with SQL databases. All of these features are provided by the standard library. However, it can be easy to misuse the standard library, or we may have a limited understanding of its behavior, which can lead to bugs and writing applications that shouldn’t be considered production-grade. Let’s look at some of the most common mistakes while using the standard library.

## 10.1 #75: Providing a wrong time duration

The standard library provides common functions and methods that accept a `time.Duration`. However, because `time.Duration` is an alias for the `int64` type, newcomers to the language can get confused and provide a wrong duration. For example, developers with a Java or JavaScript background are used to passing numeric types.

To illustrate this common error, let’s create a new `time.Ticker` that will deliver the ticks of a clock every second:

```go
ticker := time.NewTicker(1000)
for {
    select {
    case <-ticker.C:
        // Do something
    }
}
```

If we run this code, we notice that ticks aren’t delivered every second; they are delivered every microsecond.

Because `time.Duration` is based on the `int64` type, the previous code is correct since `1000` is a valid `int64`. But `time.Duration` represents the elapsed time between two instants in *nanoseconds*. Therefore, we provided `NewTicker` with a duration of 1,000 nanoseconds = 1 microsecond.

This mistake happens frequently. Indeed, standard libraries in languages such as Java and JavaScript sometimes ask developers to provide durations in milliseconds.

Furthermore, if we want to purposely create a `time.Ticker` with an interval of 1 microsecond, we shouldn’t pass an `int64` directly. We should instead always use the `time.Duration` API to avoid possible confusion:

```go
ticker = time.NewTicker(time.Microsecond)
// Or
ticker = time.NewTicker(1000 * time.Nanosecond)
```

This is not the most complex mistake in this book, but developers with a background in other languages can easily fall into the trap of believing that milliseconds are expected for the functions and methods in the `time` package. We must remember to use the `time.Duration` API and provide an `int64` alongside a time unit.

Now, let’s discuss a common mistake when using the `time` package with `time.After`. 

## 10.2 #76: time.After and memory leaks

`time.After(time.Duration)` is a convenient function that returns a channel and waits for a provided duration to elapse before sending a message to this channel. Usually, it’s used in concurrent code; otherwise, if we want to sleep for a given duration, we can use `time.Sleep(time.Duration)`. The advantage of `time.After` is that it can be used to implement scenarios such as “If I don’t receive any message in this channel for 5 seconds, I will ... .” But codebases often include calls to `time.After` in a loop, which, as we describe in this section, may be a root cause of memory leaks.

Let’s consider the following example. We will implement a function that repeatedly consumes messages from a channel. We also want to log a warning if we haven’t received any messages for more than 1 hour. Here is a possible implementation:

```go
func consumer(ch <-chan Event) {
    for {
        select {
        case event := <-ch:               // #1
            handle(event)
        case <-time.After(time.Hour):     // #2
            log.Println("warning: no messages received")
        }
    }
}
```

> #1 Handles the event
> #2 Increments the idle counter

Here, we use `select` in two cases: receiving a message from `ch` and after 1 hour without messages (`time.After` is evaluated during each iteration, so the timeout is *reset* every time). At first sight, this code looks OK. However, it may lead to memory usage issues.

As we said, `time.After` returns a channel. We may expect this channel to be closed during each loop iteration, but this isn’t the case. The resources created by `time.After` (including the channel) are released once the timeout expires and use memory until that happens. How much memory? In Go 1.15, about 200 bytes of memory are used per call to `time.After`. If we receive a significant volume of messages, such as 5 million per hour, our application will consume 1 GB of memory to store the `time.After` resources.

Can we fix this issue by closing the channel programmatically during each iteration? No. The returned channel is a `<-chan time.Time`, meaning it is a receive-only channel that can’t be closed.

We have several options to fix our example. The first is to use a context instead of `time.After`:

```go
func consumer(ch <-chan Event) {
    for {                                                                   // #1
        ctx, cancel := context.WithTimeout(context.Background(), time.Hour) // #2
        select {
        case event := <-ch:
            cancel()                                                        // #3
            handle(event)
        case <-ctx.Done():                                                  // #4
            log.Println("warning: no messages received")
        }
    }
}
```

> #1 Main loop
> #2 Creates a context with timeout
> #3 Cancels context if we receive a message
> #4 Context cancellation

The downside of this approach is that we have to re-create a context during every single loop iteration. Creating a context isn’t the most lightweight operation in Go: for example, it requires creating a channel. Can we do better?

The second option comes from the `time` package: `time.NewTimer`. This function creates a `time.Timer` struct that exports the following:

* A `C` field, which is the internal timer channel 
* A `Reset(time.Duration)` method to reset the duration 
* A `Stop()` method to stop the timer 

> ##### time.After internals
> We should note that `time.After` also relies on `time.Timer`. However, it only returns the `C` field, so we don’t have access to the `Reset` method:
> ```go
> package time
>  
> func After(d Duration) <-chan Time {
>     return NewTimer(d).C                // #1
> }
> ```
> > #1 Creates a new time.Timer and returns the channel field

Let’s implement a new version using `time.NewTimer`:

```go
func consumer(ch <-chan Event) {
    timerDuration := 1 * time.Hour
    timer := time.NewTimer(timerDuration)     // #1
 
    for {                                     // #2
        timer.Reset(timerDuration)            // #3
        select {
        case event := <-ch:
            handle(event)
        case <-timer.C:                       // #4
            log.Println("warning: no messages received")
        }
    }
}
```

> #1 Creates a new timer
> #2 Main loop
> #3 Resets the duration
> #4 Timer expiration

In this implementation, we keep a recurring action during each loop iteration: calling the `Reset` method. However, calling `Reset` is less cumbersome than having to create a new context every time. It’s faster and puts less pressure on the garbage collector because it doesn’t require any new heap allocation. Therefore, using `time.Timer` is the best possible solution for our initial problem.

> ##### NOTE
>  For the sake of simplicity, in the example, the previous goroutine doesn’t stop. As we mentioned in mistake #62, “Starting a goroutine without knowing when to stop it,” this isn’t a best practice. In production-grade code, we should find an exit condition such as a context that can be cancelled. In that case, we should also remember to stop the `time.Timer` using `defer timer.Stop()`, for example, right after the `timer` creation.

Using `time.After` in a loop isn’t the only case that may lead to a peak in memory consumption. The problem relates to code that is repeatedly called. A loop is one case, but using `time.After` in an HTTP handler function can lead to the same issues because the function will be called multiple times.

In general, we should be cautious when using `time.After`. Remember that the resources created will only be released when the timer expires. When the call to `time.After` is repeated (for example, in a loop, a Kafka consumer function, or an HTTP handler), it may lead to a peak in memory consumption. In this case, we should favor `time.NewTimer`.

The following section discusses the most common mistakes during JSON handling. 

## 10.3 #77: Common JSON-handling mistakes

Go has excellent support for JSON with the `encoding/json` package. This section covers three common mistakes related to encoding (marshaling) and decoding (unmarshaling) JSON data.

### 10.3.1 Unexpected behavior due to type embedding

In mistake #10, “Not being aware of the possible problems with type embedding,” we looked at issues related to type embedding. In the context of JSON handling, let’s discuss another potential impact of type embedding that can lead to unexpected marshaling/unmarshaling results.

In the following example, we create an `Event` struct containing an ID and an embedded timestamp:

```go
type Event struct {
    ID int
    time.Time       // #1
}
```

> #1 Embedded field

Because `time.Time` is embedded, in the same way we described previously, we can access the `time.Time` methods directly at the `Event` level: for example, `event .Second()`.

What are the possible impacts of embedded fields with JSON marshaling? Let’s find out in the following example. We will instantiate an `Event` and marshal it into JSON. What should be the output of this code?

```go
event := Event{
    ID:   1234,
    Time: time.Now(),       // #1
}
 
b, err := json.Marshal(event)
if err != nil {
    return err
}
 
fmt.Println(string(b))
```

> #1 The name of an anonymous field during a struct instantiation is the name of the struct (Time).

We may expect this code to print something like the following:

```go
{"ID":1234,"Time":"2021-05-18T21:15:08.381652+02:00"}
```

Instead, it prints this:

```go
"2021-05-18T21:15:08.381652+02:00"
```

How can we explain this output? What happened to the `ID` field and the `1234` value? Because this field is exported, it should have been marshaled. To understand this problem, we have to highlight two points.

First, as discussed in mistake #10, if an embedded field type implements an interface, the struct containing the embedded field will also implement this interface. Second, we can change the default marshaling behavior by making a type implement the `json.Marshaler` interface. This interface contains a single `MarshalJSON` function:

```go
type Marshaler interface {
    MarshalJSON() ([]byte, error)
}
```

Here is an example with custom marshaling:

```go
type foo struct{}                             // #1
 
func (foo) MarshalJSON() ([]byte, error) {    // #2
    return []byte(`"foo"`), nil               // #3
}
 
func main() {
    b, err := json.Marshal(foo{})             // #4
    if err != nil {
        panic(err)
    }
    fmt.Println(string(b))
}
```

> #1 Defines the struct
> #2 Implements the MarshalJSON method
> #3 Returns a static response
> #4 json.Marshal then relies on the custom MarshalJSON implementation.

Because we have changed the default JSON marshaling behavior by implementing the `Marshaler` interface, this code prints `"foo"`.

Having clarified these two points, let’s get back to the initial problem with the `Event` struct:

```go
type Event struct {
    ID int
    time.Time
}
```

We have to know that `time.Time` *implements* the `json.Marshaler` interface. Because `time.Time` is an embedded field of `Event`, the compiler promotes its methods. Therefore, `Event` also implements `json.Marshaler`.

Consequently, passing an `Event` to `json.Marshal` uses the marshaling behavior provided by `time.Time` instead of the default behavior. This is why marshaling an `Event` leads to ignoring the `ID` field.

> ##### NOTE
>  We would also face the issue the other way around if we were unmarshaling an `Event` using `json.Unmarshal`.

To fix this issue, there are two main possibilities. First, we can add a name so the `time.Time` field is no longer embedded:

```go
type Event struct {
    ID   int
    Time time.Time      // #1
}
```

> #1 time.Time is no longer an embedded type.

This way, if we marshal a version of this `Event` struct, it will print something like this:

```go
{"ID":1234,"Time":"2021-05-18T21:15:08.381652+02:00"}
```

If we want or have to keep the `time.Time` field embedded, the other option is to make `Event` implement the `json.Marshaler` interface:

```go
func (e Event) MarshalJSON() ([]byte, error) {
    return json.Marshal(
        struct {            // #1
            ID   int
            Time time.Time
        }{
            ID:   e.ID,
            Time: e.Time,
        },
    )
}
```

> #1 Creates an anonymous struct

In this solution, we implement a custom `MarshalJSON` method while defining an anonymous struct reflecting the structure of `Event`. But this solution is more cumbersome and requires that we ensure that the `MarshalJSON` method is always up to date with the `Event` struct.

We should be careful with embedded fields. While promoting the fields and methods of an embedded field type can sometimes be convenient, it can also lead to subtle bugs because it can make the parent struct implement interfaces without a clear signal. Again, when using embedded fields, we should clearly understand the possible side effects.

In the next section, we see another common JSON mistake related to using `time.Time`. 

### 10.3.2 JSON and the monotonic clock

When marshaling or unmarshaling a struct that contains a `time.Time` type, we can sometimes face unexpected comparison errors. It’s helpful to examine `time.Time` to refine our assumptions and prevent possible mistakes.

An OS handles two different clock types: wall and monotonic. This section looks first at these clock types and then at a possible impact while working with JSON and `time.Time`.

The wall clock is used to determine the current time of day. This clock is subject to variations. For example, if the clock is synchronized using the Network Time Protocol (NTP), it can jump backward or forward in time. We shouldn’t measure durations using the wall clock because we may face strange behavior, such as negative durations. This is why OSs provide a second clock type: monotonic clocks. The monotonic clock guarantees that time always moves forward and is not impacted by jumps in time. It can be affected by frequency adjustments (for example, if the server detects that the local quartz clock is moving at a different pace than the NTP server) but never by jumps in time.

In the following example, we consider an `Event` struct containing a single `time.Time` field (not embedded):

```go
type Event struct {
    Time time.Time
}
```

We instantiate an `Event`, marshal it into JSON, and unmarshal it into another struct. Then we compare both structs. Let’s find out if the marshaling/unmarshaling process is always symmetric:

```go
t := time.Now()                    // #1
event1 := Event{                   // #2
    Time: t,
}
 
b, err := json.Marshal(event1)     // #3
if err != nil {
    return err
}
 
var event2 Event
err = json.Unmarshal(b, &event2)   // #4
if err != nil {
    return err
}
 
fmt.Println(event1 == event2)
```

> #1 Gets the current local time
> #2 Instantiates an Event struct
> #3 Marshals into JSON
> #4 Unmarshals JSON

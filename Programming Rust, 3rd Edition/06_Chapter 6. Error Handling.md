# Chapter 6. Error Handling

# A Note for Early Release Readers

With Early Release ebooks, you get books in their earliest form—the author’s raw and unedited content as they write—so you can take advantage of these technologies long before the official release of these titles.

This will be the 7th chapter of the final book. Please note that the GitHub repo will be made active later on.

If you’d like to be actively involved in reviewing and commenting on this draft, please reach out to the editor at *jbleiel@oreilly.com*.

I knew if I stayed around long enough, something like this would happen.

George Bernard Shaw on dying

Rust’s approach to error handling is unusual enough to warrant a short chapter on the topic. There aren’t any difficult ideas here, just ideas that might be new to you. This chapter covers the two different kinds of error handling in Rust: panic and `Result`s.

Ordinary errors are handled using the `Result` type. `Result`s typically represent problems caused by things outside the program, like erroneous input, a network outage, or a permissions problem. That such situations occur is not up to us; even a bug-free program will encounter them from time to time. Most of this chapter is dedicated to that kind of error. We’ll cover panic first, though, because it’s the simpler of the two.

Panic is for the other kind of error, the kind that *should never happen*.

# Panic

A program panics when it encounters something so messed up that there must be a bug in the program itself. Something like:

-

Out-of-bounds array access

-

Integer division by zero

-

Calling `.expect()` on a `Result` that happens to be `Err`

-

Assertion failure

(There’s also the macro `panic!()`, for cases where your own code discovers that it has gone wrong, and you therefore need to trigger a panic directly. `panic!()` accepts optional `println!()`-style arguments, for building an error message.)

What these conditions have in common is that they are all—not to put too fine a point on it—the programmer’s fault. A good rule of thumb is: “Don’t panic.”

But we all make mistakes. When these errors that shouldn’t happen do happen—what then? Remarkably, Rust gives you a choice. Rust can either unwind the stack when a panic happens or abort the process. Unwinding is the default.

## Unwinding

When pirates divvy up the booty from a raid, the captain gets half of the loot. Ordinary crew members earn equal shares of the other half. (Pirates hate fractions, so if either division does not come out even, the result is rounded down, with the remainder going to the ship’s parrot.)

```
fn pirate_share(total: u64, crew_size: usize) -> u64 {
    let half = total / 2;
    half / crew_size as u64
}
```

This may work fine for centuries until one day it transpires that the captain is the sole survivor of a raid. If we pass a `crew_size` of zero to this function, it will divide by zero. In C‍++, this would be undefined behavior. In Rust, it triggers a panic, which typically proceeds as follows:

-

An error message is printed to the terminal:

`thread 'main' panicked at pirates.rs:3780:9:`
`attempt to divide by zero`
`note: Run with `RUST_BACKTRACE=1` for a backtrace.`

If you set the `RUST_BACKTRACE` environment variable, as the messages suggests, Rust will also dump the stack at this point.

-

The stack is unwound. This is a lot like C‍++ exception handling.

Any temporary values, local variables, or arguments that the current function was using are dropped. Dropping a value simply means cleaning up after it: any `String`s or `Vec`s the program was using are freed, any open `File`s are closed, and so on. User-defined `drop` methods are called too; see [Link to Come]. In the particular case of `pirate_share()`, there’s nothing to clean up.

Once the current function call is cleaned up, we move on to its caller, dropping its variables and arguments the same way. Then we move to *that* function’s caller, and so on up the stack.

-

Finally, the thread exits. If the panicking thread was the main thread, then the whole process exits (with a nonzero exit code).

Perhaps *panic* is a misleading name for this orderly process. A panic is not a crash. It’s not undefined behavior. It’s more like a `RuntimeException` in Java or a `std::logic_error` in C‍++. The behavior is well-defined; it just shouldn’t be happening.

Panic is safe. It doesn’t violate any of Rust’s safety rules; even if you manage to panic in the middle of a standard library method, it will never leave a dangling pointer or a half-initialized value in memory. The idea is that Rust catches the invalid array access, or whatever it is, *before* anything bad happens. It would be unsafe to proceed, so Rust unwinds the stack. But the rest of the process can continue running.

Panic is per thread. One thread can be panicking while other threads are going on about their normal business. In [Link to Come], we’ll show how a parent thread can find out when a child thread panics and handle the error gracefully.

There is also a way to *catch* stack unwinding, allowing the thread to survive and continue running. The standard library function `std::panic::catch_unwind()` does this. We won’t cover how to use it, but this is the mechanism used by Rust’s test harness to recover when an assertion fails in a test. (It can also be necessary when writing Rust code that can be called from C or C‍++, because unwinding across non-Rust code is undefined behavior; see [Link to Come].)

You can use threads and `catch_unwind()` to handle panic, making your program more robust. One important caveat is that these tools only catch panics that unwind the stack. Not every panic proceeds this way.

## Aborting

Stack unwinding is the default panic behavior, but there are two circumstances in which Rust does not try to unwind the stack.

If a `.drop()` method triggers a second panic while Rust is still trying to clean up after the first, this is considered fatal. Rust stops unwinding and aborts the whole process.

Also, Rust’s panic behavior is customizable. If you compile with `-C panic=abort`, the *first* panic in your program aborts the process. (With this option, Rust does not need to know how to unwind the stack, so this can reduce the size of your compiled code.)

## The Panic Hook

The first thing a panicking thread does, before unwinding or aborting, is call the *panic hook*, a function that can be configured by calling `std::panic::set_hook()`. The default panic hook writes its message and (depending on `RUST_BACKTRACE`) a stack trace to `stderr`.

If your program uses a logging library, it’s a good idea to set a panic hook that ensures all panic messages are recorded to the log. Otherwise, panics might easily go unreported by accident, especially panics in non-main threads and async tasks.

```
use std::backtrace::Backtrace;
use std::panic::PanicHookInfo;

/// Panic hook to send panic info to `tracing` instead of stderr. (Use this
/// only if you're using the `tracing` crate.)
fn report_panic(panic_info: &PanicHookInfo) {
    let stack = Backtrace::force_capture();
    tracing::error!("{panic_info}\n\n{stack}");
}

fn main() {
    setup_logging();
    std::panic::set_hook(Box::new(report_panic));
    ...
}
```

Calling `set_hook` once sets the panic hook for the whole process.

This concludes our discussion of panic in Rust. There is not much to say, because ordinary Rust code has no obligation to handle panic. Even if you do use threads, `catch_unwind()`, or a panic hook, all your panic-handling code will likely be concentrated in a few places. It’s unreasonable to expect every function in a program to anticipate and cope with bugs in its own code. Errors caused by other factors are another kettle of fish.

# Result

Rust doesn’t have exceptions. Instead, functions that can fail have a return type that says so:

```
fn get_weather(location: LatLng) -> Result<WeatherReport, io::Error>
```

The `Result` type indicates possible failure. When we call the `get_weather()` function, it will return either a *success result* `Ok(weather)`, where `weather` is a new `WeatherReport` value, or an *error result* `Err(error_value)`, where `error_value` is an `io::Error` explaining what went wrong.

Rust requires us to write some kind of error handling whenever we call this function. We can’t get at the `WeatherReport` without doing *something* to the `Result`, and you’ll get a compiler warning if a `Result` value isn’t used.

In [Chapter 9](https://learning.oreilly.com/library/view/programming-rust-3rd/9781098176228/ch09.html#enums-and-patterns), we’ll see how the standard library defines `Result` and how you can define your own similar types. For now, we’ll take a “cookbook” approach and focus on how to use `Result`s to get the error-handling behavior you want. We’ll look at how to catch, propagate, and report errors, as well as common patterns for organizing and working with `Result` types.

## Catching Errors

The most thorough way of dealing with a `Result` is the way we showed in [Chapter 1](https://learning.oreilly.com/library/view/programming-rust-3rd/9781098176228/ch01.html#a-tour-of-rust): use a `match` expression.

```
match get_weather(hometown) {
    Ok(report) => {
        display_weather(hometown, &report);
    }
    Err(err) => {
        eprintln!("error querying the weather: {err}");
        schedule_weather_retry();
    }
}
```

This is Rust’s equivalent of `try/catch` in other languages. It’s what you use when you want to handle errors head-on, not pass them on to your caller.

`match` is a bit verbose, so `Result<T, E>` offers a variety of methods that are useful in particular common cases. Each of these methods has a `match` expression in its implementation. (For the full list of `Result` methods, consult the online documentation. The methods listed here are the ones we use the most.)

result.is_ok(),result.is_err()Returnabooltelling ifresultis a success result or an error result.result.ok()Returnsthe success value, if any, as anOption<T>. Ifresultis a success result, this returnsSome(success_value); otherwise, it returnsNone, discarding the error value.result.err()Returnsthe error value, if any, as anOption<E>.result.unwrap_or(fallback)Returns the success value, if `result` is a success result. Otherwise, it returns `fallback`, discarding the error value.

```
// A fairly safe prediction for Southern California.
const THE_USUAL: WeatherReport = WeatherReport::Sunny(72);

// Get a real weather report, if possible.
// If not, fall back on the usual.
let report = get_weather(los_angeles).unwrap_or(THE_USUAL);
display_weather(los_angeles, &report);
```

This is a nice alternative to `.ok()` because the return type is `T`, not `Option<T>`. Of course, it works only when there’s an appropriate fallback value.

result.unwrap_or_else(fallback_fn)This is the same, but instead of passing a fallback value directly, you pass a function or closure. This is for cases where it would be wasteful to compute a fallback value if you’re not going to use it. The `fallback_fn` is called only if we have an error result.

```
let report =
    get_weather(hometown)
    .unwrap_or_else(|_err| vague_prediction(hometown));
```

([Link to Come] covers closures in detail.)

result.unwrap()Also returnsthe success value, ifresultis a success result. However, ifresultis an error result, this method panics. This method has its uses; we’ll talk more about it later.result.expect(message)Thisthe same as.unwrap(), but lets you provide a message that it prints in case of panic.result.map(convert_fn)This method provides a way to change the value in the `Result` only if it’s an `Ok` value. The argument is usually a closure, which will be called only if the result is `Ok`. If it’s an `Err` result, `map` returns it unchanged.

```
reqwest::blocking::get(url)             // do an HTTP request...
    .map(|response| response.status())  // ...but we only care about the status code
```

In this example, `reqwest::blocking::get(url)` returns a `Result<Response, reqwest::Error>`. We use `.map()` to transform that into a `Result<StatusCode, reqwest::Error>`.

result.map_err(convert_fn)The `map_err` method is the mirror image of `map`. It transforms only `Err` values, and thus the result’s error type. This can be handy when working with errors of multiple types, as we’ll see in a few pages.

Lastly, methods for working with references in a `Result`:

result.as_ref()ConvertsaResult<T, E>to aResult<&T, &E>.result.as_mut()Thisis the same, but borrows a mutable reference. The return type isResult<&mut T, &mut E>.One reason these last two methods are useful is that all of the other methods listed here, except `.is_ok()` and `.is_err()`, *consume* the `result` they operate on. That is, they take the `self` argument by value. Sometimes it’s quite handy to access data inside a `result` without destroying it, and this is what `.as_ref()` and `.as_mut()` do for us. For example, suppose you’d like to call `result.ok()`, but you need `result` to be left intact. You can write `result.as_ref().ok()`, which merely borrows `result`, returning an `Option<&T>` rather than an `Option<T>`.

## Result Type Aliases

Sometimes you’ll see Rust documentation that seems to omit the error type of a `Result`:

```
fn remove_file(path: &Path) -> Result<()>
```

This means that a `Result` type alias is being used.

A type alias is a kind of shorthand for type names. Modules often define a `Result` type alias to avoid having to repeat an error type that’s used consistently by almost every function in the module. For example, the standard library’s `std::io` module includes this line of code:

```
pub type Result<T> = result::Result<T, Error>;
```

This defines a public type `std::io::Result<T>`. It’s an alias for `Result<T, E>`, but hardcodes `std::io::Error` as the error type. If you write `use std::io;`, then Rust will understand `io::Result<String>` as shorthand for `Result<String, io::Error>`.

When something like `Result<()>` appears in the online documentation, you can click on the identifier `Result` to see which type alias is being used and learn the error type. In practice, it’s usually obvious from context.

## Printing Errors

Sometimes the only way to handle an error is by dumping it to the terminal and moving on. We already showed one way to do this:

```
eprintln!("error querying the weather: {err}");
```

The standard library defines several error types with boring names: `std::io::Error`, `std::fmt::Error`, `std::str::Utf8Error`, and so on. All of them implement a common interface, the `std::error::Error` trait, which means they share the following features and methods:

println!(), etc.All error types support the `Display` and `Debug` traits, so they can be used with any of the macros that use format strings, including `println!()`, `eprintln!()`, `format!()`, and `panic!()`. Printing an error with the `{}` format specifier typically displays only a brief error message. Alternatively, you can print with the `{:?}` format specifier to get a `Debug` view of the error. This is less human-friendly, but sometimes includes extra technical information.

```yaml
// result of `eprintln!("error: {err}");`
error: No such file or directory (os error 2)

// result of `eprintln!("error: {err:?}");`
error: Os { code: 2, kind: NotFound, message: "No such file or directory" }
```

err.to_string()Returnsan error message as aString. This is equivalent to `format!(“{err}”)`.err.source()ReturnsanOptionof the underlying error, if any, that causederr. For example, a networking error might cause a banking transaction to fail, which could in turn cause your boat to be repossessed. Iferr.to_string()is"boat was repossessed", thenerr.source()might return an error about the failed transaction. That error’s.to_string()might be"failed to transfer $300 toUnitedYacht Supply", and its.source()might be anio::Errorwith details about the specific network outage that caused all the fuss. This third error is the root cause, so its.source()method would returnNone. Since the standard library only includes rather low-level features, the source of errors returned from the standard library is usuallyNone.Printing an error value does not also print out its source. If you want to be sure to print all the available information, use this function:

```
use std::error::Error;
use std::io::{self, Write};

/// Dump an error message to `stderr`.
///
/// If another error happens while building the error message or
/// writing to `stderr`, it is ignored.
fn print_error(mut err: &dyn Error) {
    let _ = writeln!(io::stderr(), "error: {err}");
    while let Some(source) = err.source() {
        let _ = writeln!(io::stderr(), "caused by: {source}");
        err = source;
    }
}
```

The `writeln!` macro works like `println!`, except that it writes the data to a stream of your choice. Here, we write the error messages to the standard error stream, `std::io::stderr`. We could use the `eprintln!` macro to do the same thing, but `eprintln!` panics if an error occurs. In `print_error`, we want to ignore errors that arise while writing the message; we explain why in [“Ignoring Errors”](https://learning.oreilly.com/library/view/programming-rust-3rd/9781098176228/ch06.html#ignoring-errors), later in the chapter.

The standard library’s error types do not include a stack trace, but the popular `anyhow` crate provides a ready-made error type that does, when used with an unstable version of the Rust compiler. (As of Rust 1.56, the standard library’s functions for capturing backtraces were not yet stabilized.)

## Propagating Errors

In most places where we try something that could fail, we don’t want to catch and handle the error immediately. It is simply too much code to use a 10-line `match` statement every place where something could go wrong.

Instead, if an error occurs, we usually want to let our caller deal with it. We want errors to *propagate* up the call stack.

Rust has a `?` operator that does this. You can add a `?` to any expression that produces a `Result`, such as the result of a function call:

```
let weather = get_weather(hometown)?;
```

The behavior of `?` depends on whether this function returns a success result or an error result:

-

On success, it unwraps the `Result` to get the success value inside. The type of `weather` here is not `Result<WeatherReport, io::Error>` but simply `WeatherReport`.

-

On error, it immediately returns from the enclosing function, passing the error result up the call chain. To ensure that this works, `?` can only be used on a `Result` in functions that have a `Result` return type.

There’s nothing magical about the `?` operator. You can express the same thing using a `match` expression, although it’s much wordier:

```
let weather = match get_weather(hometown) {
    Ok(success_value) => success_value,
    Err(err) => return Err(err),
};
```

The only differences between this and the `?` operator are some fine points involving types and conversions. We’ll cover those details in the next section.

It’s easy to forget just how pervasive the possibility of errors is in a program, particularly in code that interfaces with the operating system. The `?` operator sometimes shows up on almost every line of a function:

```
use std::fs;
use std::io;
use std::path::Path;

fn move_all(src: &Path, dst: &Path) -> io::Result<()> {
    for entry_result in src.read_dir()? {  // opening dir could fail
        let entry = entry_result?;         // reading dir could fail
        let dst_file = dst.join(entry.file_name());
        fs::rename(entry.path(), dst_file)?;  // renaming could fail
    }
    Ok(())  // phew!
}
```

`?` also works similarly with the `Option` type. In a function that returns `Option`, you can use `?` to unwrap a value and return early in the case of `None`:

```
let weather = get_weather(hometown).ok()?;
```

## Working with Multiple Error Types

Often, more than one thing could go wrong. Suppose we are simply reading numbers from a text file:

```
use std::io::{self, BufRead};

/// Read integers from a text file.
/// The file should have one number on each line.
fn read_numbers(file: &mut dyn BufRead) -> io::Result<Vec<i64>> {
    let mut numbers = vec![];
    for line_result in file.lines() {
        let line = line_result?;         // reading lines can fail
        numbers.push(line.parse()?);     // parsing integers can fail
    }
    Ok(numbers)
}
```

Rust gives us a compiler error:

```
error: `?` couldn't convert the error to `std::io::Error`

  numbers.push(line.parse()?);     // parsing integers can fail
                           ^
            the trait `std::convert::From<std::num::ParseIntError>`
            is not implemented for `std::io::Error`

note: the question mark operation (`?`) implicitly performs a conversion
on the error value using the `From` trait
```

The terms in this error message will make more sense when we reach [Chapter 10](https://learning.oreilly.com/library/view/programming-rust-3rd/9781098176228/ch10.html#traits-and-generics), which covers traits. For now, just note that Rust is complaining that the `?` operator can’t convert a `std::num::ParseIntError` value to the type `std::io::Error`.

The problem here is that reading a line from a file and parsing an integer produce two different potential error types. The type of `line_result` is `Result<String, std::io::Error>`. The type of `line.parse()` is `Result<i64, std::num::Parse​IntError>`. The return type of our `read_numbers()` function only accommodates `io::Error`s. Rust tries to cope with the `ParseIntError` by converting it to a `io::Error`, but there’s no such conversion, so we get a type error.

We need a single error type. One way to achieve this is by converting all other errors to `std::io::Error` manually.

```
let num = line.parse()
            .map_err(|err| io::Error::new(io::ErrorKind::Other, err))?;
        numbers.push(num);
```

The `.map_err()` method calls the closure only if `line.parse()` returns an error. Here are using it to convert the type of the error, from a `ParseIntError` into an `io::Error`. The method therefore returns a `Result<i64, std::io::Error>`. We can then dispense with the error in the usual way, using the `?` operator.

This works, but the line of code calling `.map_err()` is awkward busywork, and bogus lines of data in the file aren’t what we normally think of as I/O errors. If we applied this technique too freely, the code would become cluttered, and our use of `io::Error` would become rather deceptive. The Rust ecosystem has settled on two other solutions to this problem. Both are implemented as open source crates.

## A Universal Error Type: anyhow

The `anyhow` crate defines a single error type, `anyhow::Error`, that supports conversions from all error types. We must add the crate as a dependency in our *Cargo.toml* file:

```
[dependencies]
anyhow = "1"
```

With `anyhow`, we don’t need to call `.map_err()`. We simply change the return type to use the `anyhow::Result` type alias, as shown below. The `?` operators we already had in the code will then automatically convert either type of error to an `anyhow::Error` as needed:

```
fn read_numbers(file: &mut dyn BufRead) -> anyhow::Result<Vec<i64>> {
    ...
        let line = line_result?;      // converts io::Error to anyhow::Error
        numbers.push(line.parse()?);  // same for ParseIntError
    ...
}
```

Using `anyhow` is not the only way to get this functionality. A similar type is built into the Rust standard library. All types that implement the `std::error::Error` trait can be automatically converted to `Box<dyn std::error::Error + Send + Sync + 'static>`. This type is a bit of a mouthful, but `dyn std::error::Error` represents “any error,” and `+ Send + Sync + 'static` narrows it down to types that are safe to pass between threads. Therefore a rough approximation of `anyhow` in one line of code would look like this:

```
type AnyError = Box<dyn std::error::Error + Send + Sync + 'static>;
```

However, `anyhow` offers some features that this one-liner does not provide:

- Printing an `anyhow::Error` automatically prints the `source` chain.
- `anyhow::Context` provides a convenient way for your program to add information about what it was trying to do when an error occurred, for better error messages.
- The `anyhow::bail!()` and `anyhow::ensure!()` macros provide convenient ways to return an error without having to declare a new type. Like `panic!()` and `assert!()`, they take string formatting arguments, but instead of panicking they simply return an error result.
- When an `anyhow::Error` is created, it automatically captures a backtrace if the `RUST_BACKTRACE` environment variable is set. (Note, however, that this captures the stack where the error is converted to an `anyhow` error, not where the error initially happened. For some programs, these backtraces are expensive to capture and not very helpful. They can be disabled by setting `RUST_LIB_BACKTRACE=0`.)

The `anyhow` crate documentation covers these features in more detail.

The downside of the `anyhow` approach is that the return type no longer communicates precisely what kinds of errors the caller can expect. The caller must be ready for anything.

If you’re writing code to handle an `anyhow::Error`, and you want to handle one particular kind of error but let all others propagate out, use the generic method `err.downcast_ref::<T>()`. It borrows a reference to the error, *if* it happens to be the particular type of error you’re looking for:

```
loop {
    match compile_project() {
        Ok(()) => return Ok(()),
        Err(err) => {
            if let Some(mse) = err.downcast_ref::<MissingSemicolonError>() {
                insert_semicolon_in_source_code(mse.file(), mse.line())?;
                continue;  // try again!
            }
            return Err(err);
        }
    }
}
```

`anyhow` is ideal for code close to `main`, at the top levels of an executable. Using it in the public API of a library has some drawbacks. First, it effectively imposes an extra dependency on your users, forcing them to accommodate `anyhow::Error` in their own codebase. Second, it obscures the actual types of errors that can occur. When you return an error created by `anyhow::bail!`, or by a third-party crate you’re using that isn’t part of your public API, your users can’t downcast to that specific error: there’s no public type that pinpoints the kind of error they want. They’ll fall back on running regular expressions on the error messages, like barbarians. Nobody wants that. Lastly, if the `anyhow` crate ever made a breaking change to its API, users would have to reconcile different crates’ usage of incompatible versions of `anyhow`, a dependency nightmare. This last concern, at least, has never materialized. `anyhow` has remained at `1.0`, publishing only backward-compatible point releases, since 2019. Still, it’s generally recommended to use `anyhow` only in applications, not in libraries.

## Defining Custom Error Types

Rather than use `anyhow::Error` for everything, crates usually define a custom error type for use in their public API. The `reqwest` HTTP client crate has `reqwest::Error`, the `sqlx` crate for accessing SQL databases has `sqlx::Error`, `regex` has `regex::Error`, and so on.

We haven’t covered user-defined types yet; that’s coming up in a few chapters. But error types are handy, so we’ll include a bit of a sneak preview here.

For our `read_numbers` function, we need an error type that can contain either an `io::Error` or a `ParseIntError`. In Rust, this can be written as an `enum`:

```
use std::io;
use std::num::ParseIntError;

#[derive(Debug)]
pub enum NumberFileError {
    Io(io::Error),
    Parse(ParseIntError),
}
```

To make the `?` operator work, we must define how to convert each of the two types to a `NumberFileError`:

```
impl From<io::Error> for NumberFileError {
    fn from(err: io::Error) -> NumberFileError {
        NumberFileError::Io(err)
    }
}

impl From<ParseIntError> for NumberFileError {
    fn from(err: ParseIntError) -> NumberFileError {
        NumberFileError::Parse(err)
    }
}
```

This is enough to go on. Changing the return type of `read_numbers` to `Result<Vec<i64>, NumberFileError>` again suffices to make the example compile. However, if you want your error type to be printable, like the standard error types, then you have a bit more work to do:

```
use std::fmt::{self, Display, Formatter};

// Errors should be printable.
impl Display for NumberFileError {
    fn fmt(&self, f: &mut Formatter) -> fmt::Result {
        let msg = match self {
            NumberFileError::Io(_) => "error reading config file",
            NumberFileError::Parse(_) => "invalid data in config file",
        };
        write!(f, "{msg}")
    }
}

// Errors should implement the std::error::Error trait.
impl std::error::Error for NumberFileError {
    fn source(&self) -> Option<&(dyn std::error::Error + 'static)> {
        match self {
            NumberFileError::Io(err) => Some(err),
            NumberFileError::Parse(err) => Some(err),
        }
    }
}
```

It’s not important to understand every line of this. All the unfamiliar syntax will be explained in the next few chapters. We mainly want to show that error types can be written out by hand—it’s not magic—but it’s a lot of boilerplate code. The `thiserror` crate can generate most of this for you.

```
[dependencies]
thiserror = "2"
```

With `thiserror`, the same error type can be implemented in a few lines:

```
#[derive(Debug, thiserror::Error)]
pub enum NumberFileError {
    #[error("error reading config file")]
    Io(#[from] io::Error),

    #[error("invalid data in config file")]
    Parse(#[from] ParseIntError),
}
```

Several attributes direct `thiserror`’s implementation of the new error type:

-

`#[derive(Debug, thiserror::Error)]` tells Rust that in addition to the usual `Debug` formatting for this type, we also want some code generated by the `thiserror::Error` derive macro. The Rust compiler generates the code for `Debug`, and the `thiserror` library generates the code for `Error`. (If you like, you can view the generated code using `cargo expand`, as described in [Link to Come]. Note, however, that generated code is usually a little strange-looking, for reasons we’ll explore in that chapter.)

-

`#[error(...)]` tells `thiserror` how we would like each variant to appear in `Display` formatting. The string argument is a kind of format string, able to access fields of the error object. For details, see the `thiserror` documentation.

-

`#[from]` tells `thiserror` which type conversions to generate and how to implement the `source` method.

You can use `thiserror` to define a crate’s public error types without requiring the crate’s users to know about `thiserror` or add it to their own dependencies. `thiserror` does all its work by generating code for you, and it never generates anything you couldn’t write yourself.

## Dealing with Errors That “Can’t Happen”

Sometimes we just *know* that an error can’t happen. For example, suppose we’re writing code to parse a configuration file, and at one point we find that the next thing in the file is a string of digits:

```
if next_char.is_ascii_digit() {
    let start = current_index;
    current_index = skip_digits(line, current_index);
    let digits = &line[start..current_index];
    ...
```

We want to convert this string of digits to an actual number. There’s a standard method that does this:

```
let num = digits.parse::<u64>();
```

Now the problem: the `str.parse::<u64>()` method doesn’t return a `u64`. It returns a `Result`. It can fail, because some strings aren’t numeric:

```
"bleen".parse::<u64>()  // ParseIntError: invalid digit
```

But we happen to know that in this case, `digits` consists entirely of digits. What should we do?

If the code we’re writing already returns a `anyhow::Result`, we can tack on a `?` and forget about it. Otherwise, we face the irritating prospect of having to write error-handling code for an error that can’t happen. The best choice then would be to use `.unwrap()`, a `Result` method that panics if the result is an `Err`, but simply returns the success value of an `Ok`:

```
let num = digits.parse::<u64>().unwrap();
```

This is just like `?` except that if we’re wrong about this error, if it *can* happen, then in that case we would panic.

In fact, we are wrong about this particular case. If the input contains a long enough string of digits, the number will be too big to fit in a `u64`:

```
"99999999999999999999".parse::<u64>()    // overflow error
```

Using `.unwrap()` in this particular case would therefore be a bug. Bogus input shouldn’t cause a panic.

That said, situations do come up where a `Result` value truly can’t be an error. For example, in [Link to Come], you’ll see that the `Write` trait defines a common set of methods (`.write()` and others) for text and binary output. All of those methods return `io::Result`s, but if you happen to be writing to a `Vec<u8>`, they can’t fail. In such cases, it’s acceptable to use `.unwrap()` or `.expect(message)` to dispense with the `Result`s.

These methods are also useful when an error would indicate a condition so severe or bizarre that panic is exactly how you want to handle it:

```
fn print_file_age(filename: &Path, last_modified: SystemTime) {
    let age = last_modified.elapsed().expect("system clock drift");
    ...
}
```

Here, the `.elapsed()` method can fail only if the system time is *earlier* than when the file was created. This can happen if the file was created recently, and the system clock was adjusted backward while our program was running. Depending on how this code is used, it’s a reasonable judgment call to panic in that case, rather than handle the error or propagate it to the caller.

## Ignoring Errors

Occasionally we just want to ignore an error altogether. For example, in our `print_error()` function, we had to handle the unlikely situation where printing the error triggers another error. This could happen, for example, if `stderr` is piped to another process, and that process is killed. The original error we were trying to report is probably more important to propagate, so we just want to ignore the troubles with `stderr`, but the Rust compiler warns about unused `Result` values:

```
writeln!(io::stderr(), "error: {err}");  // warning: unused result
```

The idiom `let _ = ...` is used to silence this warning:

```
let _ = writeln!(io::stderr(), "error: {err}");  // ok, ignore result
```

## Handling Errors in main()

In most places where a `Result` is produced, letting the error bubble up to the caller is the right behavior. This is why `?` is a single character in Rust. As we’ve seen, in some programs it’s used on many lines of code in a row.

But if you propagate an error long enough, eventually it reaches `main()`, and something has to be done with it. Normally, `main()` can’t use `?` because its return type is not `Result`:

```
fn main() {
    calculate_tides()?;  // error: can't pass the buck any further
}
```

The simplest way to handle errors in `main()` is to use `.expect()`:

```
fn main() {
    calculate_tides().expect("error");  // the buck stops here
}
```

If `calculate_tides()` returns an error result, the `.expect()` method panics. Panicking in the main thread prints an error message and then exits with a nonzero exit code, which is roughly the desired behavior. We use this all the time for tiny programs. It’s a start.

The error message is a little intimidating, though:

```bash
$ tidecalc --planet mercury
thread 'main' panicked at src/main.rs:2:23:
error: "moon not found"
note: run with `RUST_BACKTRACE=1` environment variable to display a backtrace
```

The error message is lost in the noise. Also, `RUST_BACKTRACE=1` is bad advice in this particular case.

However, you can also change the type signature of `main()` to return a `Result` type, so you can use `?`:

```
fn main() -> Result<(), TideCalcError> {
    let tides = calculate_tides()?;
    print_tides(tides);
    Ok(())
}
```

The `main` function can return any type that implements the `std::process::Termination` trait. This trait has a single `report()` method which Rust calls just after `main` returns. For `()`, the `report` method does nothing and returns the default exit code of 0. For error `Result`s, it prints the `Debug` form of the error and returns a non-zero exit code, indicating failure.

This prints a somewhat nicer error message, but still not exactly human-friendly:

```bash
$ tidecalc --planet mercury
Error: TideCalcError { error_type: NoMoon, message: "moon not found" }
```

If you care about the finer details of how errors are presented, there’s no substitute for reporting the error yourself:

```
fn main() {
    if let Err(err) = calculate_tides() {
        print_error(&err);
        std::process::exit(1);
    }
}
```

This code uses an `if let` expression to print the error message only if the call to `calculate_tides()` returns an error result. For details about `if let` expressions, see [Chapter 9](https://learning.oreilly.com/library/view/programming-rust-3rd/9781098176228/ch09.html#enums-and-patterns). The `print_error` function is listed in [“Printing Errors”](https://learning.oreilly.com/library/view/programming-rust-3rd/9781098176228/ch06.html#printing-errors).

Now the output is nice and tidy:

```bash
$ tidecalc --planet mercury
error: moon not found
```

## Why Results?

Now we know enough to understand what Rust is getting at by choosing `Result`s over exceptions. Here are the key points of the design:

-

Rust requires the programmer to make some sort of decision, and record it in the code, at every point where an error could occur. This is good because otherwise it’s easy to get error handling wrong through neglect.

-

The most common decision is to allow errors to propagate, and that’s written with a single character, `?`. Thus, error plumbing does not clutter up your code the way it does in C and Go. Yet it’s still visible: you can look at a chunk of code and see at a glance all places where errors are propagated.

-

Since the possibility of errors is part of every function’s return type, it’s clear which functions can fail and which can’t. If you change a function to be fallible, you’re changing its return type, so the compiler will make you update that function’s downstream users.

-

Rust checks that `Result` values are used, so you can’t accidentally let an error pass silently (a common mistake in C).

-

Since `Result` is a data type like any other, it’s easy to store success and error results in the same collection. This makes it easy to model partial success. For example, if you’re writing a program that loads millions of records from a text file and you need a way to cope with the likely outcome that most will succeed, but some will fail, you can represent that situation in memory using a vector of `Result`s.

The cost is that you’ll find yourself thinking about and engineering error handling more in Rust than you would in other languages. As in many other areas, Rust’s take on error handling is wound just a little tighter than what you’re used to. For systems programming, it’s worth it.

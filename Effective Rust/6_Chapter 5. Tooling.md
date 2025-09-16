# Chapter 5. Tooling

Titus Winters (Google’s C++ library lead) describes  software engineering as programming
integrated over time, or sometimes as programming integrated over time and people.  Over longer timescales, and a wider
team, there’s more to a codebase than just the code held within it.

Modern languages, including Rust, are aware of this and come with an ecosystem of tooling that goes way beyond just
converting the program into executable binary code (the compiler).

This chapter explores the Rust tooling ecosystem, with a general recommendation to make use of all of this
infrastructure.  Obviously, doing so needs to be proportionate—setting up CI, documentation builds, and six
types of test would be overkill for a throwaway program that is run only twice.  But for most of the things described
in this chapter, there’s lots of “bang for the buck”: a little bit of investment into tooling integration will yield
worthwhile benefits.

# Item 27: Document public interfaces

If your crate is going to be used by other programmers, then it’s a good idea to add documentation for its contents,
particularly its public API.  If your crate is more than just ephemeral, throwaway code, then that “other programmer”
includes the you-of-the-future, when you have forgotten the details of your current code.

This is not advice that’s specific to Rust, nor is it new advice—for example,  [Effective Java](https://www.oreilly.com/library/view/effective-java-2nd/9780137150021/) 2nd edition (from 2008) has Item 44:
“Write doc comments for all exposed API elements.”

The particulars of Rust’s documentation comment format—Markdown-based, delimited with `///` or `//!`—are
covered in the [Rust book](https://oreil.ly/_WGEv), for
example:

```
/// Calculate the [`BoundingBox`] that exactly encompasses a pair
/// of [`BoundingBox`] objects.
pub fn union(a: &BoundingBox, b: &BoundingBox) -> BoundingBox {
    // ...
}
```

However, there are some specific details about the format that are worth highlighting:

Use a code font for codeFor anything that would be typed into source code as is, surround it with
back-quotes to ensure that the resulting documentation is in a fixed-width font, making the distinction between `code`
and text clear.

Add copious cross-referencesAdd a  Markdown link for anything that might provide context for
someone reading the documentation. In particular, *cross-reference identifiers* with the convenient
`[`SomeThing`]` syntax—if `SomeThing` is in scope, then the resulting documentation will hyperlink to the
right place.

Consider including example codeIf it’s not trivially obvious how to use an entrypoint, adding an `# Examples` section with  sample code can be helpful.  Note that sample code in
[doc comments](https://doc.rust-lang.org/rustdoc/write-documentation/documentation-tests.html) gets compiled and
executed when you run `cargo test` (see [Item 30](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch05.html#file_testing_md)), which helps it stay in sync with the code it’s demonstrating.

Document panics andunsafeconstraintsIf there are inputs that cause a function to panic, document (in
a `# Panics` section) the preconditions that are required to avoid the  `panic!`.  Similarly, document (in a `# Safety` section) any requirements for  `unsafe` code.

The documentation for Rust’s [standard library](https://doc.rust-lang.org/std/index.html) provides an excellent example
to emulate for all of these details.

## Tooling

The Markdown format that’s used for documentation comments results in elegant output, but this also means that there
is an explicit conversion step  (`cargo doc`).  This in turn raises the possibility that something goes
wrong along the way.

The simplest advice for this is just to *read the rendered documentation* after writing it, by running
`cargo doc --open` (or `cargo doc --no-deps --open` to restrict the generated documentation to just the current crate).

You could also check that all the generated hyperlinks are valid, but that’s a job more suited to a machine—via
the `broken_intra_doc_links` crate attribute:[1](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch05.html#id1626)

#

```
#![deny(broken_intra_doc_links)]

/// The bounding box for a [`Polygone`].
#[derive(Clone, Debug)]
pub struct BoundingBox {
    // ...
}
```

With this attribute enabled, `cargo doc` will detect invalid links:

```
error: unresolved link to `Polygone`
 --> docs/src/main.rs:4:30
  |
4 | /// The bounding box for a [`Polygone`].
  |                              ^^^^^^^^ no item named `Polygone` in scope
  |
```

You can also *require* documentation, by enabling the `#![warn(missing_docs)]` attribute for the crate.  When this is
enabled, the compiler will emit a warning for every undocumented public item.  However, there’s a risk that enabling
this option will lead to poor-quality documentation comments that are rushed out just to get the compiler to shut
up—more on this to come.

As ever, any tooling that detects potential problems should form a part of your CI system
([Item 32](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch05.html#file_ci_md)), to catch any regressions that creep in.

## Additional Documentation Locations

The output from `cargo doc` is the primary place where your crate is documented, but it’s not the only place—other
parts of a Cargo project can help users figure out how to use your code.

The *examples/* subdirectory of a Cargo project can hold the code for standalone binaries that make use of your crate.
These programs are built and run very similarly to integration tests ([Item 30](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch05.html#file_testing_md)) but are specifically intended to hold
example code that illustrates the correct use of your crate’s interface.

On a related note, bear in mind that the integration tests under the `tests/` subdirectory can also serve as
examples for the confused user, even though their primary purpose is to test the crate’s external interface.

## Published Crate Documentation

If you publish your crate to  `crates.io`, the documentation for your project will be visible at [docs.rs](https://docs.rs/), which is an official Rust project that builds and hosts documentation for
published crates.

Note that `crates.io` and `docs.rs` are intended for slightly different audiences: `crates.io` is aimed at people who
are choosing what crate to use, whereas `docs.rs` is intended for people figuring out how to use a crate they’ve already
included (although there’s obviously considerable overlap between the two).

As a result, the home page for a crate shows different content in each location:

docs.rsShows the top-level page from the output of `cargo doc`, as generated from `//!` comments in the top-level
*src/lib.rs* file.

crates.ioShows the content of any top-level *README.md* file
that’s included in the project’s repo.[2](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch05.html#id1639)

## What *Not* to Document

When a project *requires* that documentation be included for all public items (as mentioned in the first section), it’s
very easy to fall into the trap of having documentation that’s a pointless waste of valuable pixels.  Having the
compiler warn about missing doc comments is only a proxy for what you really want—useful documentation—and
is likely to incentivize programmers to do the minimum needed to silence the
warning.

Good doc comments are a boon that helps users understand the code they’re using; bad doc comments impose a maintenance
burden and increase the chance of user confusion when they get out of sync with the code. So how to distinguish between
the two?

The primary advice is to *avoid repeating in text something that’s clear from the code*.  [Item 1](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch01.html#file_use-types_md) exhorted
you to encode as much semantics as possible into Rust’s type system; once you’ve done that, allow the type system to
document those semantics.  Assume that the reader is familiar with Rust—possibly because they’ve read a helpful
collection of Items describing effective use of the language—and don’t repeat things that are clear from the
signatures and types involved.

Returning to the previous example, an overly verbose documentation comment might be as follows:

#

```
/// Return a new [`BoundingBox`] object that exactly encompasses a pair
/// of [`BoundingBox`] objects.
///
/// Parameters:
///  - `a`: an immutable reference to a `BoundingBox`
///  - `b`: an immutable reference to a `BoundingBox`
/// Returns: new `BoundingBox` object.
pub fn union(a: &BoundingBox, b: &BoundingBox) -> BoundingBox {
```

This comment repeats many details that are clear from the function signature, to no benefit.

Worse, consider what’s likely to happen if the code gets refactored to store the result in one of the original arguments
(which would be a  breaking change; see [Item 21](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch04.html#file_semver_md)). No compiler or tool complains that the
comment isn’t updated to match, so it’s easy to end up with an out-of-sync comment:

#

```
/// Return a new [`BoundingBox`] object that exactly encompasses a pair
/// of [`BoundingBox`] objects.
///
/// Parameters:
///  - `a`: an immutable reference to a `BoundingBox`
///  - `b`: an immutable reference to a `BoundingBox`
/// Returns: new `BoundingBox` object.
pub fn union(a: &mut BoundingBox, b: &BoundingBox) {
```

In contrast, the original comment survives the refactoring unscathed, because its text describes behavior, not syntactic
details:

```
/// Calculate the [`BoundingBox`] that exactly encompasses a pair
/// of [`BoundingBox`] objects.
pub fn union(a: &mut BoundingBox, b: &BoundingBox) {
```

The mirror image of the preceding advice also helps improve documentation: *include in text anything that’s* not
*clear from the code*.  This includes preconditions, invariants, panics, error conditions, and anything else that might
surprise a user; if your code can’t comply with the  [principle of least astonishment](https://en.wikipedia.org/wiki/Principle_of_least_astonishment), make sure that the surprises are
documented so you can at least say, “I told you so.”

Another common failure mode is when doc comments describe how some other code uses a method, rather than what the method
does:

```
/// Return the intersection of two [`BoundingBox`] objects, returning `None`
/// if there is no intersection. The collision detection code in `hits.rs`
/// uses this to do an initial check to see whether two objects might overlap,
/// before performing the more expensive pixel-by-pixel check in
/// `objects_overlap`.
pub fn intersection(
    a: &BoundingBox,
    b: &BoundingBox,
) -> Option<BoundingBox> {
```

Comments like this are almost guaranteed to get out of sync: when the using code (here, `hits.rs`) changes, the comment that
describes the behavior is nowhere nearby.

Rewording the comment to focus more on the *why* makes it more robust to future changes:

```
/// Return the intersection of two [`BoundingBox`] objects, returning `None`
/// if there is no intersection.  Note that intersection of bounding boxes
/// is necessary but not sufficient for object collision -- pixel-by-pixel
/// checks are still required on overlap.
pub fn intersection(
    a: &BoundingBox,
    b: &BoundingBox,
) -> Option<BoundingBox> {
```

When writing software, it’s good advice to “program in the future tense”:[3](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch05.html#id1654) structure the code to accommodate future changes.  The same
principle is true for documentation: focusing on the semantics, the *whys* and the *why nots*, gives text that is more
likely to remain helpful in the long run.

## Things to Remember

-

Add doc comments for public API items.

-

Describe aspects of the code—such as panics and safety criteria—that aren’t obvious from the code
itself.

-

*Don’t* describe things that are obvious from the code itself.

-

Make navigation clearer by providing cross-references and by making identifiers stand out.

# Item 28: Use macros judiciously

In some cases it’s easy to decide to write a macro instead of a function, because only a macro can do what’s
needed.

Paul Graham, *On Lisp* (Prentice Hall)

Rust’s macro systems allow you to perform *metaprogramming*: to write code that emits code into your project.
This is most valuable when there are chunks of “boilerplate” code that are deterministic and repetitive and that would
otherwise need to be kept in sync manually.

Programmers coming to Rust may have previously encountered the macros provided by     C/C++’s
preprocessor, which perform textual substitution on the tokens of the input text. Rust’s macros
are a different beast, because they work on either the parsed tokens of the program or on the  *abstract
syntax tree* (AST) of the program, rather than just its textual content.

This means Rust macros can be aware of code structure and can consequently avoid entire classes of macro-related
footguns. In particular, we see in the following section that Rust’s declarative macros are  [hygienic](https://en.wikipedia.org/wiki/Hygienic_macro)—they cannot accidentally refer to (“capture”)
local variables in the surrounding code.

One way to think about macros is to see them as a different level of abstraction in the code.  A simple form of abstraction
is a function: it abstracts away the differences between different values of the same *type*, with implementation code
that can use any of the features and methods of that type, regardless of the current value being operated on.  A
generic is a different level of abstraction: it abstracts away the difference between different *types* that
satisfy a  trait bound, with implementation code that can use any of the methods provided by the trait bounds,
regardless of the current type being operated on.

A macro abstracts away the difference between different fragments of the program that play the same role (type,
identifier, expression, etc.); the implementation can then include any code that makes use of those fragments in the
same role.

Rust provides two ways to define macros:

-

Declarative macros, also known as “macros by example,” allow the insertion of arbitrary Rust code into the program,
based on the input parameters to the macro (which are categorized according to their role in the AST).

-

Procedural macros allow the insertion of arbitrary Rust code into the program, based on the parsed tokens of the
source code.  This is most commonly used for  `derive` macros, which can generate code based on the
contents of data structure definitions.

## Declarative Macros

Although this Item isn’t the place to reproduce the [documentation for declarative macros](https://oreil.ly/Vm7AZ), a few reminders of details to watch out for are in
order.

First, be aware that the scoping rules for using a declarative macro are different than for other Rust items.  If a
declarative macro is defined in a source code file, only the code *after* the macro definition
can make use of it:

#

```
fn before() {
    println!("[before] square {} is {}", 2, square!(2));
}

/// Macro that squares its argument.
macro_rules! square {
    { $e:expr } => { $e * $e }
}

fn after() {
    println!("[after] square {} is {}", 2, square!(2));
}
```

```
error: cannot find macro `square` in this scope
 --> src/main.rs:4:45
  |
4 |     println!("[before] square {} is {}", 2, square!(2));
  |                                             ^^^^^^
  |
  = help: have you added the `#[macro_use]` on the module/import?
```

The  `#[macro_export]` attribute makes a macro more widely visible, but this also has an oddity: a
macro appears at the top level of a crate, even if it’s defined in a module:

```
mod submod {
    #[macro_export]
    macro_rules! cube {
        { $e:expr } => { $e * $e * $e }
    }
}

mod user {
    pub fn use_macro() {
        // Note: *not* `crate::submod::cube!`
        let cubed = crate::cube!(3);
        println!("cube {} is {}", 3, cubed);
    }
}
```

Rust’s declarative macros are what’s known as  *hygienic*: the expanded code in the body of the
macro is not allowed to make use of local variable bindings.  For example, a macro that assumes that some variable `x`
exists:

```
// Create a macro that assumes the existence of a local `x`.
macro_rules! increment_x {
    {} => { x += 1; };
}
```

will trigger a compilation failure when it is used:

#

```
let mut x = 2;
increment_x!();
println!("x = {}", x);
```

```
error[E0425]: cannot find value `x` in this scope
   --> src/main.rs:55:13
    |
55  |     {} => { x += 1; };
    |             ^ not found in this scope
...
314 |     increment_x!();
    |     -------------- in this macro invocation
    |
    = note: this error originates in the macro `increment_x`
```

This hygienic property means that Rust’s macros are safer than C preprocessor macros. However, there are still a couple
of minor gotchas to be aware of when using them.

The first is to realize that even if a macro invocation *looks* like a function invocation, it’s not.  A macro
generates code at the point of invocation, and that generated code can perform manipulations of its arguments:

```
macro_rules! inc_item {
    { $x:ident } => { $x.contents += 1; }
}
```

This means that the normal intuition about whether parameters are moved or `&`-referred-to doesn’t apply:

```
let mut x = Item { contents: 42 }; // type is not `Copy`

// Item is *not* moved, despite the (x) syntax,
// but the body of the macro *can* modify `x`.
inc_item!(x);

println!("x is {x:?}");
```

```
x is Item { contents: 43 }
```

This becomes clear if we remember that the macro inserts code at the point of invocation—in this case, adding a
line of code that increments `x.contents`.  The  [cargo-expand](https://github.com/dtolnay/cargo-expand) tool
shows the code that the compiler sees, after macro expansion:

```
let mut x = Item { contents: 42 };
x.contents += 1;
{
    ::std::io::_print(format_args!("x is {0:?}\n", x));
};
```

The expanded code includes the modification in place, via the owner of the item, not a reference.  (It’s also interesting
to see the expanded version of `println!`, which relies on the `format_args!` macro, to be discussed shortly.)[4](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch05.html#id1683)

So the  exclamation mark serves as a warning: the expanded code for the macro may do arbitrary things to or with
its arguments.

The expanded code can also include control flow operations that aren’t visible in the calling code, whether they be
loops, conditionals,  `return` statements, or use of the  `?` operator.  Obviously, this is likely to violate
the  [principle of least astonishment](https://en.wikipedia.org/wiki/Principle_of_least_astonishment), so *prefer macros whose behavior aligns with normal Rust* where possible and appropriate.  (On the other hand, if the
*purpose* of the macro is to allow weird control flow, go for it! But help out your users by making sure the control
flow behavior is clearly documented.)

For example, consider a macro (for checking HTTP status codes) that silently includes a `return` in its body:

```
/// Check that an HTTP status is successful; exit function if not.
macro_rules! check_successful {
    { $e:expr } => {
        if $e.group() != Group::Successful {
            return Err(MyError("HTTP operation failed"));
        }
    }
}
```

Code that uses this macro to check the result of some kind of HTTP operation can end up with control flow that’s
somewhat obscure:

```
let rc = perform_http_operation();
check_successful!(rc); // may silently exit the function

// ...
```

An alternative version of the macro that generates code that emits a `Result`:

```
/// Convert an HTTP status into a `Result<(), MyError>` indicating success.
macro_rules! check_success {
    { $e:expr } => {
        match $e.group() {
            Group::Successful => Ok(()),
            _ => Err(MyError("HTTP operation failed")),
        }
    }
}
```

gives code that’s easier to follow:

```
let rc = perform_http_operation();
check_success!(rc)?; // error flow is visible via `?`

// ...
```

The second thing to watch out for with  declarative macros is a problem shared with the
C preprocessor: if the argument to a macro is an expression with side effects, beware of
repeated use of the argument in the macro.  The `square!` macro defined earlier takes an arbitrary expression as an
argument and then uses that argument twice, which can lead to surprises:

#

```
let mut x = 1;
let y = square!({
    x += 1;
    x
});
println!("x = {x}, y = {y}");
// output: x = 3, y = 6
```

Assuming that this behavior isn’t intended, one way to fix it is simply to evaluate the expression once and assign the
result to a local variable:

```
macro_rules! square_once {
    { $e:expr } => {
        {
            let x = $e;
            x*x // Note: there's a detail here to be explained later...
        }
    }
}
// output now: x = 2, y = 4
```

The other alternative is not to allow an arbitrary expression as input to the macro.  If the [expr syntax fragment specifier](https://oreil.ly/8u0NJ) is replaced with an `ident`
fragment specifier, then the macro will only accept identifiers as inputs, and the attempt to feed it an arbitrary
expression will no longer compile.

# Formatting Values

One common style of declarative macro involves assembling a message that includes various values from the current state
of the code. For example, the standard library includes
[format!](https://doc.rust-lang.org/std/macro.format.html) for assembling a `String`,
[println!](https://doc.rust-lang.org/std/macro.println.html) for printing to standard output,
[eprintln!](https://doc.rust-lang.org/std/macro.eprintln.html) for printing to standard error, and so on.  The
[documentation](https://doc.rust-lang.org/std/fmt/index.html) describes the syntax of the formatting directives, which
are roughly equivalent to  C’s  `printf` statement.  However, the format arguments are type safe
and checked at compile time, and the implementations of the macro use the `Display` and `Debug` traits described in [Item 10](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch02.html#file_std-traits_md)
to format individual values.[5](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch05.html#id1712)

You can (and should) use the same formatting syntax for any macros of your own that perform a similar function.  For
example, the logging macros provided by the  [log](https://docs.rs/log) crate use the same syntax as `format!`.
To do this, *use  [format_args!](https://doc.rust-lang.org/std/macro.format_args.html) for macros that
perform argument formatting* rather than attempting to reinvent the wheel:

```
/// Log an error including code location, with `format!`-like arguments.
/// Real code would probably use the `log` crate.
macro_rules! my_log {
    { $($arg:tt)+ } => {
        eprintln!("{}:{}: {}", file!(), line!(), format_args!($($arg)+));
    }
}
```

```
let x = 10u8;
// Format specifiers:
// - `x` says print as hex
// - `#` says prefix with '0x'
// - `04` says add leading zeroes so width is at least 4
//   (this includes the '0x' prefix).
my_log!("x = {:#04x}", x);
```

```
src/main.rs:331: x = 0x0a
```

## Procedural Macros

Rust also supports  *procedural macros*, often known as *proc macros*.  Like a declarative macro,
a [procedural macro](https://doc.rust-lang.org/reference/procedural-macros.html) has the ability to insert arbitrary
Rust code into the program’s source code.  However, the inputs to the macro are no longer just the specific arguments
passed to it; instead, a procedural macro has access to the parsed tokens corresponding to some chunk of the original
source code.  This gives a level of expressive power that approaches the flexibility of dynamic languages such as
Lisp—but still with compile-time guarantees.  It also helps mitigate the limitations of reflection in Rust, as
discussed in [Item 19](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch03.html#file_reflection_md).

Procedural macros must be defined in a separate crate (of crate type `proc-macro`) from where they are used, and that
crate will almost certainly need to depend on either [proc-macro](https://doc.rust-lang.org/proc_macro/index.html)
(provided by the standard toolchain) or [proc-macro2](https://docs.rs/proc-macro2) (provided by  David Tolnay) as a support library, to make it possible to work with the input tokens.

There are three distinct types of procedural macro:

Function-like macrosInvoked with an argument

Attribute macrosAttached to some chunk of syntax in the program

Derive macrosAttached to the definition of a data structure

### Function-like macros

Function-like procedural macros are invoked with an argument, and the macro definition has access to the parsed tokens
that make up the argument, and emits arbitrary tokens as a result.  Note that the previous sentence says “argument,”
singular—even if a function-like macro is invoked with what looks like multiple arguments:

```
my_func_macro!(15, x + y, f32::consts::PI);
```

the macro itself receives a single argument, which is a stream of parsed tokens.  A macro implementation that just
prints (at compile time) the contents of the stream:

```
use proc_macro::TokenStream;

// Function-like macro that just prints (at compile time) its input stream.
#[proc_macro]
pub fn my_func_macro(args: TokenStream) -> TokenStream {
    println!("Input TokenStream is:");
    for tt in args {
        println!("  {tt:?}");
    }
    // Return an empty token stream to replace the macro invocation with.
    TokenStream::new()
}
```

shows the stream corresponding to the input:

```yaml
Input TokenStream is:
  Literal { kind: Integer, symbol: "15", suffix: None,
            span: #0 bytes(10976..10978) }
  Punct { ch: ',', spacing: Alone, span: #0 bytes(10978..10979) }
  Ident { ident: "x", span: #0 bytes(10980..10981) }
  Punct { ch: '+', spacing: Alone, span: #0 bytes(10982..10983) }
  Ident { ident: "y", span: #0 bytes(10984..10985) }
  Punct { ch: ',', spacing: Alone, span: #0 bytes(10985..10986) }
  Ident { ident: "f32", span: #0 bytes(10987..10990) }
  Punct { ch: ':', spacing: Joint, span: #0 bytes(10990..10991) }
  Punct { ch: ':', spacing: Alone, span: #0 bytes(10991..10992) }
  Ident { ident: "consts", span: #0 bytes(10992..10998) }
  Punct { ch: ':', spacing: Joint, span: #0 bytes(10998..10999) }
  Punct { ch: ':', spacing: Alone, span: #0 bytes(10999..11000) }
  Ident { ident: "PI", span: #0 bytes(11000..11002) }
```

The low-level nature of this input stream means that the macro implementation has to do its own parsing.  For example,
separating out what appear to be separate arguments to the macro involves looking for `TokenTree::Punct` tokens that
hold the commas dividing the arguments.  The  [syn](https://docs.rs/syn) crate (from  David
Tolnay) provides a parsing library that can help with this, as [“Derive macros”](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch05.html#derive-macros-sect) describes.

Because of this, it’s usually easier to use a declarative macro than a function-like procedural macro, because the
expected structure of the macro’s inputs can be expressed in the matching pattern.

The flip side of this need for manual processing is that function-like proc macros have the flexibility to accept inputs
that *don’t* parse as normal Rust code.  That’s not often needed (or sensible), so function-like macros are
comparatively rare as a result.

### Attribute macros

Attribute macros are invoked by placing them before some item in the program, and the parsed tokens for that item are
the input to the macro.  The macro can again emit arbitrary tokens as output, but the output is typically some
transformation of the input.

For example, an attribute macro can be used to  wrap the body of a function:

```
#[log_invocation]
fn add_three(x: u32) -> u32 {
    x + 3
}
```

so that invocations of the function are logged:

```
let x = 2;
let y = add_three(x);
println!("add_three({x}) = {y}");
```

```
log: calling function 'add_three'
log: called function 'add_three' => 5
add_three(2) = 5
```

The implementation of this macro is too large to include here, because the code needs to check the structure of the
input tokens and to build up the new output tokens, but the `syn` crate can again help with this processing.

### Derive macros

The final type of procedural macro is the  derive macro, which allows generated code to be automatically attached
to a data structure definition (a `struct`, `enum`, or `union`). This is similar to an attribute macro
but there are a few `derive`-specific aspects to be aware of.

The first is that `derive` macros *add* to the input tokens, instead of replacing them altogether.  This means that the data
structure definition is left intact but the macro has the opportunity to append related code.

The second is that a `derive` macro can declare associated helper attributes, which can then be used to mark parts of the
data structure that need special processing.  For example,  [serde](https://docs.rs/serde)’s
[Deserialize](https://docs.rs/serde/latest/serde/derive.Deserialize.html) derive macro has a `serde` helper attribute
that can provide metadata to guide the deserialization process:

```
fn generate_value() -> String {
    "unknown".to_string()
}

#[derive(Debug, Deserialize)]
struct MyData {
    // If `value` is missing when deserializing, invoke
    // `generate_value()` to populate the field instead.
    #[serde(default = "generate_value")]
    value: String,
}
```

The final aspect of `derive` macros to be aware of is that the  [syn](https://docs.rs/syn) crate can take care of
much of the heavy lifting involved in parsing the input tokens into the equivalent nodes in the AST.  The
[syn::parse_macro_input!](https://docs.rs/syn/latest/syn/macro.parse_macro_input.html) macro converts the tokens into
a [syn::DeriveInput](https://docs.rs/syn/latest/syn/struct.DeriveInput.html) data structure that describes the content
of the item, and `Deri⁠ve​Input` is much easier to deal with than a raw stream of tokens.

In practice, `derive` macros are the most commonly encountered type of procedural macro—the ability to generate
field-by-field (for `struct`s) or variant-by-variant (for `enum`s) implementations allows for a lot of functionality to
be provided with little effort from the programmer—for example, by adding a single line like `#[derive(Debug, Clone, PartialEq, Eq)]`.

Because the `derive`d implementations are auto-generated, it also means that the implementations automatically stay in
sync with the data structure definition.  For example, if you were to add a new field to a `struct`, a manual
implementation of `Debug` would need to be manually updated, whereas an automatically `derive`d version would display
the new field with no additional effort (or would fail to compile if that wasn’t possible).

## When to Use Macros

The primary reason to use macros is to avoid repetitive code—especially repetitive code that would otherwise
have to be manually kept in sync with other parts of the code.  In this respect, writing a macro is just an extension of
the same kind of generalization process that normally forms part of programming:

-

If you repeat exactly the same code for multiple values of a specific type, encapsulate that code into a common
function and call the function from all of the repeated places.

-

If you repeat exactly the same code for multiple types, encapsulate that code into a  generic
with a trait bound and use the generic from all of the repeated places.

-

If you repeat the same structure of code in multiple places, encapsulate that code into a  macro and
use the macro from all of the repeated places.

For example, avoiding repetition for code that works on different  `enum` variants can be done only by a macro:

```
enum Multi {
    Byte(u8),
    Int(i32),
    Str(String),
}

/// Extract copies of all the values of a specific enum variant.
#[macro_export]
macro_rules! values_of_type {
    { $values:expr, $variant:ident } => {
        {
            let mut result = Vec::new();
            for val in $values {
                if let Multi::$variant(v) = val {
                    result.push(v.clone());
                }
            }
            result
        }
    }
}

fn main() {
    let values = vec![
        Multi::Byte(1),
        Multi::Int(1000),
        Multi::Str("a string".to_string()),
        Multi::Byte(2),
    ];

    let ints = values_of_type!(&values, Int);
    println!("Integer values: {ints:?}");

    let bytes = values_of_type!(&values, Byte);
    println!("Byte values: {bytes:?}");

    // Output:
    //   Integer values: [1000]
    //   Byte values: [1, 2]
}
```

Another scenario where macros help avoid manual repetition is when information about a collection of data values would
otherwise be spread out across different areas of the code.

For example, consider a data structure that encodes information about HTTP status codes; a macro can help keep all of
the related information together:

```
// http.rs module

#[derive(Debug, PartialEq, Eq, Clone, Copy)]
pub enum Group {
    Informational, // 1xx
    Successful,    // 2xx
    Redirection,   // 3xx
    ClientError,   // 4xx
    ServerError,   // 5xx
}

// Information about HTTP response codes.
http_codes! {
    Continue           => (100, Informational, "Continue"),
    SwitchingProtocols => (101, Informational, "Switching Protocols"),
    // ...
    Ok                 => (200, Successful, "Ok"),
    Created            => (201, Successful, "Created"),
    // ...
}
```

The macro invocation holds all the related information—numeric value, group, description—for each HTTP
status code, acting as a kind of  domain-specific language (DSL) holding the source of truth for the data.

The macro definition then describes the generated code; each line of the form `$( ... )+` expands to multiple lines in
the generated code, one per argument to the macro:

```
macro_rules! http_codes {
    { $( $name:ident => ($val:literal, $group:ident, $text:literal), )+ } => {
        #[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
        #[repr(i32)]
        enum Status {
            $( $name = $val, )+
        }
        impl Status {
            fn group(&self) -> Group {
                match self {
                    $( Self::$name => Group::$group, )+
                }
            }
            fn text(&self) -> &'static str {
                match self {
                    $( Self::$name => $text, )+
                }
            }
        }
        impl core::convert::TryFrom<i32> for Status {
            type Error = ();
            fn try_from(v: i32) -> Result<Self, Self::Error> {
                match v {
                    $( $val => Ok(Self::$name), )+
                    _ => Err(())
                }
            }
        }
    }
}
```

As a result, the overall output from the macro takes care of generating all of the code that derives from the
source-of-truth values:

-

The definition of an `enum` holding all the variants

-

The definition of a `group()` method, which indicates which group an HTTP status belongs to

-

The definition of a `text()` method, which maps a status to a text description

-

An implementation of `TryFrom<i32>` to convert numbers to status `enum` values

If an extra value needs to be added later, all that’s needed is a single additional line:

```
ImATeapot => (418, ClientError, "I'm a teapot"),
```

Without the macro, four different places would have to be manually updated.  The compiler would point out some of them
(because `match` expressions need to cover all cases) but not all—`TryFrom<i32>` could easily be forgotten.

Because macros are expanded in place in the invoking code, they can also be used to automatically emit additional
diagnostic information—in particular, by using the standard library’s
[file!()](https://doc.rust-lang.org/std/macro.file.html) and
[line!()](https://doc.rust-lang.org/std/macro.line.html) macros, which emit source code location information:

```
macro_rules! log_failure {
    { $e:expr } => {
        {
            let result = $e;
            if let Err(err) = &result {
                eprintln!("{}:{}: operation '{}' failed: {:?}",
                          file!(),
                          line!(),
                          stringify!($e),
                          err);
            }
            result
        }
    }
}
```

When failures occur, the log file then automatically includes details of what failed and where:

```
use std::convert::TryInto;

let x: Result<u8, _> = log_failure!(512.try_into()); // too big for `u8`
let y = log_failure!(std::str::from_utf8(b"\xc3\x28")); // invalid UTF-8
```

```
src/main.rs:340: operation '512.try_into()' failed: TryFromIntError(())
src/main.rs:341: operation 'std::str::from_utf8(b"\xc3\x28")' failed:
                 Utf8Error { valid_up_to: 0, error_len: Some(1) }
```

## Disadvantages of Macros

The primary disadvantage of using a macro is the impact that it has on code readability and maintainability. [“Declarative Macros”](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch05.html#declarative-macros) explains that macros allow you to create a DSL to
concisely express key features of your code and data. However, this means that anyone reading or maintaining the code
now has to understand this DSL—and its implementation in macro definitions—in addition to understanding
Rust.  For example, the `http_codes!` example in the previous section creates a Rust `enum` named `Status`, but it’s not
visible in the DSL used for the macro invocation.

This potential impenetrability of macro-based code extends beyond other engineers: various tools that analyze and
interact with Rust code may treat the code as opaque, because it no longer follows the syntactical conventions of Rust
code.  The `square_once!` macro shown earlier provided one trivial example of this: the body of the macro has not been
formatted according to the normal  `rustfmt` rules:

```json
{
    let x = $e;
    // The `rustfmt` tool doesn't really cope with code in
    // macros, so this has not been reformatted to `x * x`.
    x*x
}
```

Another example is the earlier `http_codes!` macro, where the DSL uses `Group` enum variant names like `Informational`
with neither a `Group::` prefix nor a `use` statement, which may confuse some code navigation tools.

Even the compiler itself is less helpful: its error messages don’t always follow the chain of macro use and definition.
(However, there are parts of the tooling ecosystem [see [Item 31](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch05.html#file_use-tools_md)] that can help with this, such as  David Tolnay’s  [cargo-expand](https://github.com/dtolnay/cargo-expand), used earlier.)

Another possible downside for macro use is the possibility of code bloat—a single line of macro invocation can
result in hundreds of lines of generated code, which will be invisible to a cursory survey of the code.  This is less
likely to be a problem when the code is first written, because at that point the code is needed and saves the humans
involved from having to write it themselves.  However, if the code subsequently stops being necessary, it’s not so
obvious that there are large amounts of code that could be deleted.

## Advice

Although the previous section listed some downsides of macros, they are still fundamentally the right tool for the job
when there are different chunks of code that need to be kept consistent but that cannot be coalesced any other way:
*use a macro whenever it’s the only way to ensure that disparate code stays in sync*.

Macros are also the tool to reach for when there’s boilerplate code to be squashed: *use a macro for repeated
boilerplate code* that can’t be coalesced into a function or a generic.

To reduce the impact on readability, try to avoid syntax in your macros that clashes with Rust’s normal syntax rules;
either make the macro invocation look like normal code or make it look sufficiently *different* so that no one could
confuse the two.  In particular, follow these guidelines:

-

*Avoid macro expansions that insert references* where possible—a macro invocation like `my_macro!(&list)`
aligns better with normal Rust code than `my_macro!(list)` would.

-

*Prefer to avoid nonlocal control flow operations in macros* so that anyone reading the code is able to
follow the flow without needing to know the details of the macro.

This preference for Rust-like readability sometimes affects the choice between declarative macros and procedural macros.
If you need to emit code for each field of a structure, or each variant of an enum, *prefer a  derive macro to a procedural macro that emits a type* (despite the example shown in [“When to Use Macros”](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch05.html#when_macros_sect))—it’s more idiomatic and makes the code easier to read.

However, if you’re adding a derive macro with functionality that’s not specific to your project, check whether an
external crate already provides what you need (see [Item 25](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch04.html#file_dep-graph_md)).  For example, the problem of converting integer values
into the appropriate variant of a C-like  `enum` is well-covered: all of
[enumn::N](https://docs.rs/enumn/latest/enumn/derive.N.html),
[num_enum::TryFromPrimitive](https://docs.rs/num_enum/latest/num_enum/derive.TryFromPrimitive.html),
[num_derive::FromPrimitive](https://docs.rs/num-derive/latest/num_derive/derive.FromPrimitive.html), and
[strum::FromRepr](https://docs.rs/strum/latest/strum/derive.FromRepr.html) cover some aspect of this
problem.

# Item 29: Listen to Clippy

It looks like you’re writing a letter. Would you like help?

Microsoft Clippit

[Item 31](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch05.html#file_use-tools_md) describes the ecosystem of helpful tools available in the Rust toolbox, but one tool is sufficiently helpful and
important to get promoted to an Item of its very own:  [Clippy](https://github.com/rust-lang/rust-clippy#clippy).

Clippy is an additional component for  Cargo (`cargo clippy`) that emits warnings about your Rust usage, across
a variety of categories:

CorrectnessWarns about common programming errors

IdiomWarns about code constructs that aren’t quite in standard Rust style

ConcisionPoints out variations on the code that are more compact

PerformanceSuggests alternatives that avoid unnecessary processing or allocation

ReadabilityDescribes alterations to the code that would make it easier for humans to read and understand

For example, the following code builds fine:

#

```
pub fn circle_area(radius: f64) -> f64 {
    let pi = 3.14;
    pi * radius * radius
}
```

but Clippy points out that the local approximation to  π is unnecessary and inaccurate:

```
error: approximate value of `f{32, 64}::consts::PI` found
 --> src/main.rs:5:18
  |
5 |         let pi = 3.14;
  |                  ^^^^
  |
  = help: consider using the constant directly
  = help: for further information visit
    https://rust-lang.github.io/rust-clippy/master/index.html#approx_constant
  = note: `#[deny(clippy::approx_constant)]` on by default
```

The linked webpage explains the problem and points the way to a suitable modification of the code:

```
pub fn circle_area(radius: f64) -> f64 {
    std::f64::consts::PI * radius * radius
}
```

As shown previously, each Clippy warning comes with a link to a webpage describing the error, which explains *why* the code
is considered bad.  This is vital, because it allows you to decide whether those reasons apply to your code or whether
there is some particular reason why the lint check isn’t relevant.  In some cases, the text also describes known
problems with the lint, which might explain an otherwise confusing false positive.

If you decide that a lint warning isn’t relevant for your code, you can disable it either for that particular item
(`#[allow(clippy::some_lint)]`) or for the entire crate (`#![allow(clippy::some_lint)]`, with an extra
`!`, at the top level).  However, it’s usually better to take the cost of a minor refactoring of the code than to
waste time and energy arguing about whether the warning is a genuine false positive.

Whether you choose to fix or disable the warnings, you should *make your code Clippy-warning free*.

That way, when new warnings appear—whether because the code has been changed or because Clippy has been
upgraded to include new checks—they will be obvious. Clippy should also be enabled in your CI system ([Item 32](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch05.html#file_ci_md)).

Clippy’s warnings are particularly helpful when you’re learning Rust, because they reveal gotchas you might not have
noticed and help you become familiar with Rust idiom.

Many of the Items in this book also have corresponding Clippy warnings, when it’s possible to mechanically check the
relevant concern:

-

[Item 1](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch01.html#file_use-types_md) suggests using more expressive types than plain `bool`s, and Clippy will also point out the use of multiple
`bool`s in [function parameters](https://rust-lang.github.io/rust-clippy/stable/index.html#fn_params_excessive_bools) and
[structures](https://rust-lang.github.io/rust-clippy/stable/index.html#struct_excessive_bools).

-

[Item 3](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch01.html#file_transform_md) covers manipulations of `Option` and `Result` types, and Clippy points out a few possible
redundancies, such as the following:

-

[Unnecessarily converting Result to Option](https://rust-lang.github.io/rust-clippy/stable/index.html#ok_expect)

-

[Opportunities to use unwrap_or_default](https://rust-lang.github.io/rust-clippy/stable/index.html#unwrap_or_else_default)

-

[Item 3](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch01.html#file_transform_md) also suggests that errors should be returned to the caller where possible; Clippy [points out some missing opportunities to do that](https://rust-lang.github.io/rust-clippy/stable/index.html#unwrap_in_result).

-

[Item 5](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch01.html#file_casts_md) suggests implementing `From` rather than `Into`, which [Clippy also suggests](https://rust-lang.github.io/rust-clippy/stable/index.html#from_over_into).

-

[Item 5](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch01.html#file_casts_md) also describes casts, and Clippy has (disabled by default) warnings for the following:

-

[as casts that could be from instead](https://rust-lang.github.io/rust-clippy/stable/index.html#cast_lossless)

-

[as casts that might truncate](https://rust-lang.github.io/rust-clippy/stable/index.html#cast_possible_truncation)

-

[as casts that might wrap](https://rust-lang.github.io/rust-clippy/stable/index.html#cast_possible_wrap)

-

[as casts that lose precision](https://rust-lang.github.io/rust-clippy/stable/index.html#cast_precision_loss)

-

[as casts that might convert signed negative numbers to large positive numbers](https://rust-lang.github.io/rust-clippy/stable/index.html#cast_sign_loss)

-

[any use of as](https://rust-lang.github.io/rust-clippy/stable/index.html#as_conversions)

-

[Item 8](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch01.html#file_references_md) describes  fat pointer types, and various Clippy
lints point out scenarios where there are unnecessary extra pointer indirections:

-

[Holding a heap-allocated collection in a Box](https://rust-lang.github.io/rust-clippy/stable/index.html#box_collection)

-

[Holding a heap-allocated collection of Box items](https://rust-lang.github.io/rust-clippy/stable/index.html#vec_box)

-

[Taking a reference to a Box](https://rust-lang.github.io/rust-clippy/stable/index.html#borrowed_box)

-

[Item 9](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch01.html#file_iterators_md) describes the myriad ways to manipulate  `Iterator` instances; Clippy
[includes](https://rust-lang.github.io/rust-clippy/stable/index.html#explicit_counter_loop)
[a](https://rust-lang.github.io/rust-clippy/stable/index.html#explicit_iter_loop)
[truly](https://rust-lang.github.io/rust-clippy/stable/index.html#explicit_into_iter_loop)
[astonishing](https://rust-lang.github.io/rust-clippy/stable/index.html#filter_map_identity)
[number](https://rust-lang.github.io/rust-clippy/stable/index.html#from_iter_instead_of_collect)
[of](https://rust-lang.github.io/rust-clippy/stable/index.html#into_iter_on_ref)
[lints](https://rust-lang.github.io/rust-clippy/stable/index.html#iter_count)
[that](https://rust-lang.github.io/rust-clippy/stable/index.html#iter_next_loop)
[point](https://rust-lang.github.io/rust-clippy/stable/index.html#iter_not_returning_iterator)
[out](https://rust-lang.github.io/rust-clippy/stable/index.html#manual_filter_map)
[combinations](https://rust-lang.github.io/rust-clippy/stable/index.html#manual_find_map)
[of](https://rust-lang.github.io/rust-clippy/stable/index.html#map_clone)
[iterator](https://rust-lang.github.io/rust-clippy/stable/index.html#needless_range_loop)
[methods](https://rust-lang.github.io/rust-clippy/stable/index.html#search_is_some)
[that](https://rust-lang.github.io/rust-clippy/stable/index.html#skip_while_next)
[could](https://rust-lang.github.io/rust-clippy/stable/index.html#suspicious_map)
[be](https://rust-lang.github.io/rust-clippy/stable/index.html#unnecessary_filter_map)
[simplified](https://rust-lang.github.io/rust-clippy/stable/index.html#unnecessary_fold).

-

[Item 10](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch02.html#file_std-traits_md) describes Rust’s standard traits and included some implementation requirements that Clippy checks:

-

[Ord must agree with PartialOrd](https://rust-lang.github.io/rust-clippy/stable/index.html#derive_ord_xor_partial_ord).

-

[PartialEq::ne should not need a nondefault implementation](https://rust-lang.github.io/rust-clippy/stable/index.html#partialeq_ne_impl) (see [Item 13](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch02.html#file_default-impl_md)).

-

[Hash and Eq must be consistent](https://rust-lang.github.io/rust-clippy/stable/index.html#derived_hash_with_manual_eq).

-

[Clone for Copy types should match](https://rust-lang.github.io/rust-clippy/stable/index.html#expl_impl_clone_on_copy).

-

[Item 18](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch03.html#file_panic_md) suggests limiting the use of
[panic!](https://rust-lang.github.io/rust-clippy/stable/index.html#panic) or related methods like
[expect](https://rust-lang.github.io/rust-clippy/stable/index.html#expect_used), which Clippy also
detects.

-

[Item 21](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch04.html#file_semver_md) observes that importing a  wildcard version of a crate isn’t sensible; Clippy
[agrees](https://rust-lang.github.io/rust-clippy/stable/index.html#wildcard_dependencies).

-

[Item 23](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch04.html#file_wildcard_md) suggests avoiding  wildcard imports, as does
[Clippy](https://rust-lang.github.io/rust-clippy/stable/index.html#wildcard_imports).

-

Items [24](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch04.html#file_re-export_md) and [25](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch04.html#file_dep-graph_md) touch on the fact that multiple versions of the same crate can appear in your dependency graph;
Clippy can be configured to [complain when this happens](https://rust-lang.github.io/rust-clippy/stable/index.html#multiple_crate_versions).

-

[Item 26](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch04.html#file_features_md) explains the additive nature of Cargo  features, and Clippy includes a warning about [“negative” feature names](https://rust-lang.github.io/rust-clippy/stable/index.html#negative_feature_names) (e.g., `"no_std"`) that
are likely to indicate a feature that falls foul of this.

-

[Item 26](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch04.html#file_features_md) also explains that a crate’s optional dependencies form part of its feature set, and Clippy warns if there
are [explicit feature names (e.g., "use-crate-x")](https://rust-lang.github.io/rust-clippy/stable/index.html#redundant_feature_names) that
could just make use of this instead.

-

[Item 27](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch05.html#file_documentation_md) describes conventions for documentation comments, and Clippy will also point out the following:

-

[Missing descriptions of panic!s](https://rust-lang.github.io/rust-clippy/stable/index.html#missing_panics_doc)

-

[Missing descriptions](https://rust-lang.github.io/rust-clippy/stable/index.html#missing_safety_doc) of   [unsafe concerns](https://rust-lang.github.io/rust-clippy/stable/index.html#undocumented_unsafe_blocks)

As the size of this list should make clear, it can be a valuable learning experience to *read the [list of Clippy lint warnings](https://oreil.ly/Nt5zE)*—including the checks
that are disabled by default because they are overly pedantic or because they have a high rate of false positives. Even
though you’re unlikely to want to enable these warnings for your code, understanding the reasons why they were written
in the first place will improve your understanding of Rust and its idiom.

# Item 30: Write more than unit tests

All companies have test environments.

The lucky ones have production environments separate from the test environment.

[@FearlessSon](https://oreil.ly/UzBRq)

Like most other modern languages, Rust includes features that make it easy to  [write tests](https://doc.rust-lang.org/book/ch11-00-testing.html) that live alongside your code
and that give you confidence that the code is working
correctly.

This isn’t the place to expound on the importance of tests; suffice it to say that if code isn’t tested, it probably
doesn’t work the way you think it does.  So this Item assumes that you’re already signed up to *write tests for
your code*.

Unit tests and integration tests, described in the next two sections, are the key forms of tests. However, the Rust
toolchain, and extensions to the toolchain, allow for various other types of tests.  This Item describes their distinct
logistics and rationales.

## Unit Tests

The most common form of test for Rust code is a  unit test, which might look something like this:

```
// ... (code defining `nat_subtract*` functions for natural
//      number subtraction)

#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn test_nat_subtract() {
        assert_eq!(nat_subtract(4, 3).unwrap(), 1);
        assert_eq!(nat_subtract(4, 5), None);
    }

    #[should_panic]
    #[test]
    fn test_something_that_panics() {
        nat_subtract_unchecked(4, 5);
    }
}
```

Some aspects of this example will appear in every unit test:

-

A collection of unit test functions.

-

Each test function is marked with the `#[test]` attribute.

-

The module holding the test functions is annotated with a `#[cfg(test)]` attribute, so the code gets built only in test configurations.

Other aspects of this example illustrate things that are optional and may be relevant only for particular tests:

-

The test code here is held in a separate  module, conventionally called `tests` or `test`.  This module may be
inline (as here) or held in a separate *tests.rs* file.  Using a separate file for the test module has the advantage
that it’s easier to spot whether code that uses a function is test code or “real” code.

-

The test module might have a wildcard `use super::*` to pull in everything from the parent module under test.  This
makes it more convenient to add tests (and is an exception to the general advice in [Item 23](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch04.html#file_wildcard_md) to avoid wildcard
imports).

-

The normal visibility rules for modules mean that a unit test has the ability to use anything from the parent module,
whether it is  `pub` or not.  This allows for  “open-box” testing of the code, where the unit
tests exercise internal features that aren’t visible to normal users.

-

The test code makes use of `expect()` or `unwrap()` for its expected results.  The advice in [Item 18](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch03.html#file_panic_md) isn’t really
relevant for test-only code, where `panic!` is used to signal a failing test.  Similarly, the test code also checks
expected results with `assert_eq!`, which will panic on failure.

-

The code under test includes a function that panics on some kinds of invalid input; to exercise that, there’s a unit test function that’s marked with the `#[should_panic]` attribute. This might be needed when testing an internal function that normally expects the rest of the code to respect its invariants and preconditions, or it might be a public function that has some reason to ignore the advice in [Item 18](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch03.html#file_panic_md). (Such a function should have a “Panics” section in its doc comment, as described in [Item 27](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch05.html#file_documentation_md).)

[Item 27](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch05.html#file_documentation_md) suggests *not* documenting things that are already expressed by the type system.  Similarly, there’s no need to
test things that are guaranteed by the type system. If your `enum` types start holding values that aren’t in the
list of allowed variants, you’ve got bigger problems than a failing unit test!

However, if your code relies on specific functionality from your dependencies, it can be helpful to include basic tests
of that functionality.  The aim here is not to repeat testing that’s already done by the dependency itself but instead
to have an early warning system that indicates whether the behavior that you need from the dependency has
changed—separately from whether the public API signature has changed, as indicated by the  semantic version number ([Item 21](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch04.html#file_semver_md)).

## Integration Tests

The other common form of test included with a Rust project is  *integration tests*, held under
*tests/*.  Each file in that directory is run as a separate test program that executes all of the functions marked with
`#[test]`.

Integration tests do *not* have access to crate internals and so act as  behavior tests that can exercise only
the public API of the crate.

## Doc Tests

[Item 27](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch05.html#file_documentation_md) described the inclusion of short code samples in documentation comments, to illustrate the use of a particular
public API item.  Each such chunk of code is enclosed in an implicit `fn main() { ... }` and run as part of
`cargo test`, effectively making it an additional test case for your code, known as a  *doc test*.  Individual
tests can also be executed selectively by running `cargo test --doc <item-name>`.

Regularly running tests as part of your CI environment ([Item 32](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch05.html#file_ci_md)) ensures that your code
samples don’t drift too far from the current reality of your API.

## Examples

[Item 27](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch05.html#file_documentation_md) also described the ability to provide example programs that exercise your public API. Each Rust file under
`examples/` (or each subdirectory under `examples/` that includes a `main.rs`) can be run as a standalone binary
with `cargo run --example <name>` or `cargo test --example <name>`.

These programs have access to only the public API of your crate and are intended to illustrate the use of your API as a
whole.  Examples are not specifically designated as test code (no `#[test]`, no `#[cfg(test)]`), and they’re a poor
place to put code that exercises obscure nooks and crannies of your crate—particularly as examples are *not*
run by `cargo test` by default.

Nevertheless, it’s a good idea to ensure that your CI system ([Item 32](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch05.html#file_ci_md)) builds and runs all
the associated examples for a crate (with `cargo test --examples`), because it can act as a good early warning system
for regressions that are likely to affect lots of users.  As noted, if your examples demonstrate mainline use of
your API, then a failure in the examples implies that something significant is wrong:

-

If it’s a genuine  bug, then it’s likely to affect lots of users—the
very nature of example code means that users are likely to have copied, pasted, and adapted the example.

-

If it’s an intended change to the API, then the examples need to be updated to match.  A change to the API also
implies a  backward incompatibility, so if the crate is published, then the semantic version
number needs a corresponding update to indicate this ([Item 21](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch04.html#file_semver_md)).

The likelihood of users copying and pasting example code means that it should have a different style than test code. In
line with [Item 18](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch03.html#file_panic_md), you should set a good example for your users by avoiding `unwrap()` calls for
`Result`s. Instead, make each example’s  `main()` function return something like `Result<(), Box<dyn Error>>`, and then use the  question mark operator throughout ([Item 3](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch01.html#file_transform_md)).

## Benchmarks

[Item 20](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch03.html#file_optimize_md) attempts to persuade you that fully optimizing the performance of your code isn’t always necessary.
Nevertheless, there are definitely times when performance is critical, and if that’s the case, then it’s a good
idea to measure and track that performance. Having  *benchmarks* that are run regularly (e.g., as part of CI; [Item 32](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch05.html#file_ci_md)) allows you to detect when changes to the code or the toolchains adversely affect that
performance.

The  [cargo bench](https://doc.rust-lang.org/cargo/commands/cargo-bench.html) command runs special
test cases that repeatedly perform an operation, and emits average timing information for the operation.  At the time of
writing, support for benchmarks is not stable, so the precise command may need to be `cargo +nightly bench`. (Rust’s
unstable features, including the [test](https://doc.rust-lang.org/unstable-book/library-features/test.html) feature
used here, are described in [The Unstable Book](https://oreil.ly/tDaYl).)

However, there’s a danger that compiler optimizations may give misleading results, particularly if you restrict the
operation that’s being performed to a small subset of the real code.  Consider a simple arithmetic function:

```
pub fn factorial(n: u128) -> u128 {
    match n {
        0 => 1,
        n => n * factorial(n - 1),
    }
}
```

A naive benchmark for this code:

```
#![feature(test)]
extern crate test;

#[bench]
fn bench_factorial(b: &mut test::Bencher) {
    b.iter(|| {
        let result = factorial(15);
        assert_eq!(result, 1_307_674_368_000);
    });
}
```

gives incredibly positive results:

```
test bench_factorial             ... bench:           0 ns/iter (+/- 0)
```

With fixed inputs and a small amount of code under test, the compiler is able to optimize away the iteration and
directly emit the result, leading to an unrealistically optimistic result.

The  [std::hint::black_box](https://doc.rust-lang.org/std/hint/fn.black_box.html)
function can help with this; it’s an identity function [whose implementation the compiler is “encouraged, but not required”](https://oreil.ly/UEpFk) (their italics) to pessimize.

Moving the benchmark code to use this hint:

```
#[bench]
fn bench_factorial(b: &mut test::Bencher) {
    b.iter(|| {
        let result = factorial(std::hint::black_box(15));
        assert_eq!(result, 1_307_674_368_000);
    });
}
```

gives more realistic results:

```
test blackboxed::bench_factorial ... bench:          16 ns/iter (+/- 3)
```

The  [Godbolt compiler explorer](https://rust.godbolt.org/) can also help by showing the actual machine code
emitted by the compiler, which may make it obvious when the compiler has performed optimizations that would be
unrealistic for code running a real scenario.

Finally, if you are including benchmarks for your Rust code, the  [criterion](https://crates.io/crates/criterion)
crate may provide an alternative to the standard
[test::bench::Bencher](https://doc.rust-lang.org/test/bench/struct.Bencher.html) functionality that is more convenient (it runs with stable Rust) and more fully featured (it has support for statistics and graphs).

## Fuzz Testing

Fuzz testing is the process of exposing code to randomized inputs in the hope of finding  bugs, particularly
crashes that result from those inputs. Although this can be a useful technique in general, it becomes much more
important when your code is exposed to inputs that may be controlled by someone who is deliberately trying to attack the
code—so you should *run  fuzz tests if your code is exposed to potential attackers*.

Historically, the majority of defects in  C/C++ code that have been exposed by fuzzers have been memory safety problems,
typically found by combining fuzz testing with runtime instrumentation (e.g.,
[AddressSanitizer](https://clang.llvm.org/docs/AddressSanitizer.html) or
[ThreadSanitizer](https://clang.llvm.org/docs/ThreadSanitizer.html)) of memory access patterns.

Rust is immune to some (but not all) of these memory safety problems, particularly when there is no  `unsafe` code
involved ([Item 16](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch03.html#file_unsafe_md)).  However, Rust does not prevent bugs in general, and a code path that triggers a  `panic!`
(see [Item 18](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch03.html#file_panic_md)) can still result in a  denial-of-service (DoS) attack on the codebase as a whole.

The most effective forms of fuzz testing are *coverage-guided*: the test infrastructure monitors which parts of the code
are executed and favors random mutations of the inputs that explore new code paths.   [“American fuzzy lop” (AFL)](https://lcamtuf.coredump.cx/afl/) was the original heavyweight champion of this technique, but in more recent
years equivalent functionality has been included in the LLVM toolchain as
[libFuzzer](https://llvm.org/docs/LibFuzzer.html).

The Rust compiler is built on LLVM, and so the [cargo-fuzz](https://github.com/rust-fuzz/cargo-fuzz) subcommand
exposes `libFuzzer` functionality for Rust (albeit for only a limited number of platforms).

The primary requirement for a fuzz test is to identify an entrypoint of your code that takes (or can be adapted to take)
arbitrary bytes of data as input:

#

```
/// Determine if the input starts with "FUZZ".
pub fn is_fuzz(data: &[u8]) -> bool {
    if data.len() >= 3 /* oops */
    && data[0] == b'F'
    && data[1] == b'U'
    && data[2] == b'Z'
    && data[3] == b'Z'
    {
        true
    } else {
        false
    }
}
```

With a target entrypoint identified, the [Rust Fuzz Book](https://oreil.ly/xF0Ex) gives instructions on how
to arrange the fuzzing subproject.  At its core is a small driver that connects the target entrypoint to the fuzzing
infrastructure:

```
// fuzz/fuzz_targets/target1.rs file
#![no_main]
use libfuzzer_sys::fuzz_target;

fuzz_target!(|data: &[u8]| {
    let _ = somecrate::is_fuzz(data);
});
```

Running `cargo +nightly fuzz run target1` continuously executes the fuzz target with random data, stopping only if a
crash is found.  In this case, a failure is found almost immediately:

```
INFO: Running with entropic power schedule (0xFF, 100).
INFO: Seed: 1607525774
INFO: Loaded 1 modules: 1624 [0x108219fa0, 0x10821a5f8),
INFO: Loaded 1 PC tables (1624 PCs): 1624 [0x10821a5f8,0x108220b78),
INFO:        9 files found in fuzz/corpus/target1
INFO: seed corpus: files: 9 min: 1b max: 8b total: 46b rss: 38Mb
#10	INITED cov: 26 ft: 26 corp: 6/22b exec/s: 0 rss: 39Mb
thread panicked at 'index out of bounds: the len is 3 but the index is 3',
     testing/src/lib.rs:77:12
stack backtrace:
   0: rust_begin_unwind
             at /rustc/f77bfb7336f2/library/std/src/panicking.rs:579:5
   1: core::panicking::panic_fmt
             at /rustc/f77bfb7336f2/library/core/src/panicking.rs:64:14
   2: core::panicking::panic_bounds_check
             at /rustc/f77bfb7336f2/library/core/src/panicking.rs:159:5
   3: somecrate::is_fuzz
   4: _rust_fuzzer_test_input
   5: ___rust_try
   6: _LLVMFuzzerTestOneInput
   7: __ZN6fuzzer6Fuzzer15ExecuteCallbackEPKhm
   8: __ZN6fuzzer6Fuzzer6RunOneEPKhmbPNS_9InputInfoEbPb
   9: __ZN6fuzzer6Fuzzer16MutateAndTestOneEv
  10: __ZN6fuzzer6Fuzzer4LoopERNSt3__16vectorINS_9SizedFileENS_
      16fuzzer_allocatorIS3_EEEE
  11: __ZN6fuzzer12FuzzerDriverEPiPPPcPFiPKhmE
  12: _main
```

and the input that triggered the failure is emitted.

Normally, fuzz testing does not find failures so quickly, and so it does *not* make sense to run fuzz tests as part of
your CI.  The open-ended nature of the testing, and the consequent compute costs, mean that
you need to consider how and when to run fuzz tests—perhaps only for new releases or major changes, or perhaps
for a limited period of time.[6](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch05.html#id1875)

You can also make subsequent runs of the fuzzing infrastructure more efficient, by storing and reusing a  *corpus*
of previous inputs that the fuzzer found to explore new code paths; this helps subsequent runs of the fuzzer explore
new ground, rather than retesting code paths previously visited.

## Testing Advice

An Item about testing wouldn’t be complete without repeating some common advice (which is mostly not Rust-specific):

-

As this Item has endlessly repeated, *run all your tests in CI on every change* (with
the exception of fuzz tests).

-

When you’re fixing a bug, *write a test that exhibits the bug before fixing the  bug*.  That way you
can be sure that the bug is fixed and that it won’t be accidentally reintroduced in the future.

-

If your crate has features ([Item 26](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch04.html#file_features_md)), *run tests over every possible combination of available features*.

-

More generally, if your crate includes any config-specific code (e.g., `#[cfg(target_os = "windows")]`), *run
tests for every platform* that has distinct code.

This Item has covered a lot of different types of tests, so it’s up to you to decide how much each of them is relevant and
worthwhile for your project.

If you have a lot of test code and you are publishing your crate to  [crates.io](https://crates.io/), then you
might need to consider which of the tests make sense to include in the published crate.  By default, `cargo` will
include unit tests, integration tests, benchmarks, and examples (but not fuzz tests, because the `cargo-fuzz` tools
store these as a separate crate in a subdirectory), which may be more than end users need.  If that’s the case, you can
either [exclude](https://oreil.ly/SCuug) some of the
files or (for behavior tests) move the tests out of the crate and into a separate test crate.

## Things to Remember

-

Write unit tests for comprehensive testing that includes testing of internal-only code.  Run them with `cargo test`.

-

Write integration tests to exercise your public API.  Run them with `cargo test`.

-

Write doc tests that exemplify how to use individual items in your public API. Run them with `cargo test`.

-

Write example programs that show how to use your public API as a whole.  Run them with `cargo test --examples` or `cargo run --example <name>`.

-

Write benchmarks if your code has significant performance requirements.  Run them with `cargo bench`.

-

Write fuzz tests if your code is exposed to untrusted inputs.  Run them (continuously) with `cargo fuzz`.

# Item 31: Take advantage of the tooling ecosystem

The Rust ecosystem has a rich collection of additional tools, which provide functionality above and beyond the essential
task of converting Rust into machine code.

When setting up a Rust development environment, you’re likely to
want most of the following basic tools:[7](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch05.html#id1899)

-

The  [cargo](https://doc.rust-lang.org/cargo/) tool for organizing dependencies ([Item 25](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch04.html#file_dep-graph_md)) and driving
the compiler

-

The  [rustup](https://github.com/rust-lang/rustup) tool, which manages the installed Rust toolchains

-

An IDE with Rust support, or an IDE/editor plug-in like
[rust-analyzer](https://github.com/rust-lang/rust-analyzer), that allows you to quickly
navigate around a Rust codebase, and provides autocompletion support for writing Rust code

-

The  [Rust playground](https://play.rust-lang.org/), for standalone
explorations of Rust’s syntax and for sharing the results with colleagues

-

A bookmarked link to the [documentation for the Rust standard library](https://doc.rust-lang.org/std/)

Beyond these basics, Rust includes many tools that help with the wider task of maintaining a codebase and improving the
quality of that codebase. The [tools that are included](https://doc.rust-lang.org/cargo/commands/index.html) in the
official Cargo toolchain cover various essential tasks beyond the basics of `cargo build`, `cargo test`, and `cargo run`, for example:

cargo fmtReformats Rust code according to standard conventions.

cargo checkPerforms compilation checks without generating machine code, which can be useful to get a fast
syntax check.

cargo clippyPerforms lint checks, detecting inefficient or unidiomatic code ([Item 29](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch05.html#file_clippy_md)).

cargo docGenerates documentation ([Item 27](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch05.html#file_documentation_md)).

cargo benchRuns benchmarking tests ([Item 30](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch05.html#file_testing_md)).

cargo updateUpgrades dependencies to the latest versions, selecting versions that are compliant with
semantic versioning ([Item 21](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch04.html#file_semver_md)) by default.

cargo treeDisplays the dependency graph ([Item 25](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch04.html#file_dep-graph_md)).

cargo metadataEmits metadata about the packages that are present in the workspace and in their dependencies.

The last of these is particularly useful, albeit indirectly: because there’s a tool that emits information about crates
in a well-defined format, it’s much easier for people to produce other tools that make use of that information
(typically via the  [cargo_metadata](https://docs.rs/cargo_metadata/latest/cargo_metadata/) crate, which provides
a set of Rust types to hold the metadata information).

[Item 25](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch04.html#file_dep-graph_md) described some of the tools that are enabled by this metadata availability, such as  `cargo-udeps` (which
allows detection of unused dependencies) or  `cargo-deny` (which allows checks for many things, including
duplicate dependencies, allowed licenses, and security advisories).

The extensibility of the Rust toolchain is not just limited to package metadata; the compiler’s  abstract syntax
tree can also be built upon, [often via](https://crates.io/crates/syn/reverse_dependencies) the
[syn](https://docs.rs/syn) crate.  This information is what makes procedural macros ([Item 28](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch05.html#file_macros_md)) so potent but
also powers a variety of other tools:

cargo-expandShows the complete source code produced by macro
expansion, which can be essential for debugging tricky macro definitions.

cargo-tarpaulinSupports the generation and tracking of code coverage
information.

Any list of specific tools will always be subjective, out of date, and incomplete; the more general point is to
*explore the available tools*.

For example, a [search for cargo-<something> tools](https://docs.rs/releases/search?query=cargo-) gives dozens of
results; some will be inappropriate and some will be abandoned, but some might just do exactly what you want.

There are also various efforts to    [apply formal verification to Rust code](https://oreil.ly/51DfU), which may be helpful if your code needs
higher levels of assurance about its correctness.

Finally, a reminder: if a tool is useful on more than a one-off basis, you should *integrate the tool into your
CI system* (as per [Item 32](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch05.html#file_ci_md)).  If the tool is fast and false-positive free, it may also make sense
to *integrate the tool into your editor or IDE*; the Rust [Tools page](https://rust-lang.org/tools)
provides links to relevant documentation for this.

## Tools to Remember

In addition to the tools that should be configured to run over your codebase regularly and automatically ([Item 32](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch05.html#file_ci_md)),
there are various other tools that have been mentioned elsewhere in the book. For reference, these are collated
here—but remember that there are many more tools out there:

-

[Item 16](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch03.html#file_unsafe_md) recommends the use of  [Miri](https://github.com/rust-lang/miri) when writing subtle `unsafe` code.

-

Items [21](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch04.html#file_semver_md) and [25](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch04.html#file_dep-graph_md) include mention of
[Dependabot](https://docs.github.com/en/code-security/dependabot), for managing dependency updates.

-

[Item 21](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch04.html#file_semver_md) also mentions  [cargo-semver-checks](https://github.com/obi1kenobi/cargo-semver-checks) as a possible
option for checking that semantic versioning has been done correctly.

-

[Item 28](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch05.html#file_macros_md) explains that  [cargo-expand](https://github.com/dtolnay/cargo-expand) can help when debugging macro
problems.

-

[Item 29](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch05.html#file_clippy_md) is entirely dedicated to the use of  Clippy.

-

The  [Godbolt compiler explorer](https://rust.godbolt.org/) allows you to explore the machine code
corresponding to your source code, as described in [Item 30](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch05.html#file_testing_md).

-

[Item 30](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch05.html#file_testing_md) also mentions additional testing tools, such as
[cargo-fuzz](https://github.com/rust-fuzz/cargo-fuzz) for fuzz testing and
[criterion](https://crates.io/crates/criterion) for benchmarking.

-

[Item 35](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch06.html#file_bindgen_md) covers the use of  [bindgen](https://rust-lang.github.io/rust-bindgen/) for auto-generating Rust FFI
wrappers from C code.

# Item 32: Set up a continuous integration (CI) system

A  CI system is a mechanism for automatically running tools over your codebase, which is
triggered whenever there’s a change to the codebase—or a proposed change to the codebase.

The recommendation to *set up a CI system* is not at all Rust-specific, so this Item is a
mélange of general advice mixed with Rust-specific tool suggestions.

## CI Steps

Moving to specifics, what kinds of steps should be included in your CI system?  The obvious initial candidates
are the following:

-

Build the code.

-

Run the tests for the code.

In each case, a CI step should run cleanly, quickly, deterministically, and with a zero false positive rate; more on this
in the next section.

The “deterministic” requirement also leads to advice for the build step: *use rust-toolchain.toml to specify
a fixed version of the toolchain in your CI build*.

The
[rust-toolchain.toml](https://rust-lang.github.io/rustup/overrides.html#the-toolchain-file) file indicates which
version of Rust should be used to build the code—either a specific version (e.g., `1.70`), or a channel
(`stable`, `beta`, or `nightly`) possibly with an optional date  (e.g., `nightly-2023-09-19`).[8](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch05.html#id1945)  Choosing a floating channel value here would make the CI results vary as new
toolchain versions are released; a fixed value is more deterministic and allows you to deal with toolchain upgrades
separately.

Throughout this book, various Items have suggested tools and techniques that can help improve your codebase; wherever
possible, these should be included with the CI system.  For example, the two fundamental parts of a CI system previously mentioned can be enhanced:

-

Build the code.

-

[Item 26](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch04.html#file_features_md) describes the use of  *features* to conditionally include different chunks of code. If your
crate has features, *build every valid combination of features in CI* (and realize that this may involve
2N different variants—hence the advice to avoid feature creep).

-

[Item 33](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch06.html#file_no-std_md) suggests that you consider making library code  `no_std` compatible where possible. You can be
confident that your code is genuinely `no_std` compatible only if you *test `no_std` compatibility in CI*.  One
option is to make use of the Rust compiler’s cross-compilation abilities and build for an explicitly `no_std`
target (e.g., `thumbv6m-none-eabi`).

-

[Item 21](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch04.html#file_semver_md) includes a discussion around declaring a  minimum supported Rust version (MSRV) for your code. If you
have this, *check your MSRV in CI* by including a step that tests with that specific Rust version.

-

Run the tests for the code.

-

[Item 30](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch05.html#file_testing_md) describes the various different styles of test; *run all test types in CI*.  Some test types are
automatically included in `cargo test`  (unit tests,  integration tests, and
doc tests), but other test types (e.g., example programs) may need to be explicitly triggered.

However, there are other tools and suggestions that can help improve the quality of your codebase:

-

[Item 29](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch05.html#file_clippy_md) waxes lyrical about the advantages of running  Clippy over your code; *run Clippy in CI*.
To ensure that failures are flagged, set the `-Dwarnings` option (for example, via `cargo clippy -- -Dwarnings`).

-

[Item 27](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch05.html#file_documentation_md) suggests documenting your public API; use the  `cargo doc` tool to check that the documentation
generates correctly and that any hyperlinks in it resolve correctly.

-

[Item 25](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch04.html#file_dep-graph_md) mentions tools such as  `cargo-udeps` and  `cargo-deny` that can help manage your dependency
graph; running these as a CI step prevents regressions.

-

[Item 31](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch05.html#file_use-tools_md) discusses the Rust tool ecosystem; consider which of these tools are worth regularly running over your
codebase.  For example, running  `rustfmt` / `cargo fmt` in CI allows detection of code that doesn’t comply with
your project’s style guidelines. To ensure that failures are flagged, set the `--check` option.

You can also include CI steps that measure particular aspects of your code:

-

Generate code coverage statistics (e.g., with  [cargo-tarpaulin](https://docs.rs/cargo-tarpaulin)) to show what
proportion of your codebase is exercised by your tests.

-

Run benchmarks (e.g., with  `cargo-bench`; [Item 30](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch05.html#file_testing_md)) to measure the performance of your code on key scenarios.
However, note that most CI systems run in shared environments where external factors can affect the results; getting
more reliable benchmark data is likely to require a more dedicated environment.

These measurement suggestions are a bit more complicated to set up, because the output of a measurement step is more
useful when it’s compared to previous results.  In an ideal world, the CI system would detect when a code change is not
fully tested or has an adverse effect on performance; this typically involves integration with some external tracking
system.

Here are other suggestions for CI steps that may or may not be relevant for your codebase:

-

If your project is a library, recall (from [Item 25](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch04.html#file_dep-graph_md)) that any checked-in  *Cargo.lock* file will be ignored by
the users of your library. In theory, the semantic version constraints ([Item 21](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch04.html#file_semver_md)) in *Cargo.toml* should mean that
everything works correctly anyway; in practice, consider including a CI step that builds without any local
*Cargo.lock*, to detect whether the current versions of dependencies still work correctly.

-

If your project includes any kind of machine-generated resources that are version-controlled (e.g., code
generated from  protocol buffer messages by  [prost](https://docs.rs/prost)), then include a CI step that
regenerates the resources and checks that there are no differences compared to the checked-in version.

-

If your codebase includes platform-specific (e.g., `#[cfg(target_arch = "arm")]`) code, run CI steps that confirm that
the code builds and (ideally) works on that platform.  (The former is easier than the latter because the Rust
toolchain includes support for cross-compilation.)

-

If your project manipulates secret values such as access tokens or cryptographic keys, consider including a CI step
that searches the codebase for secrets that have been inadvertently checked in.  This is particularly important if
your project is public (in which case it may be worth moving the check from CI to a [version-control presubmit check](https://git-scm.com/book/en/v2/Customizing-Git-Git-Hooks)).

CI checks don’t always need to be integrated with Cargo and the Rust toolchains; sometimes a simple
shell script can give more bang for the buck, particularly when a codebase has a local convention that’s not universally
followed.  For example, a codebase might include a convention that any panic-inducing method invocation ([Item 18](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch03.html#file_panic_md)) has a
special marker comment or that every `TODO:` comment has an owner (a person or a tracking ID), and a shell script is ideal
for checking this.

Finally, consider examining the CI systems of public Rust projects to get ideas for additional CI steps that might be
useful for your project.  For example,  Cargo has a [CI system](https://oreil.ly/DOqCc) that includes many steps that may
provide
inspiration.

## CI Principles

Moving from the specific to the general, there are some overall principles that should guide the details of your CI system.

The most fundamental principle is *don’t waste the time of humans*.  If a CI system unnecessarily wastes
people’s time, they will start looking for ways to avoid it.

The most annoying waste of an engineer’s time is a *flaky* test: sometimes it passes and sometimes it fails, even when the setup and codebase are identical. Whenever possible, be ruthless with flaky tests: hunt them
down, and put in the time up front to investigate and fix the cause of the flakiness—it will pay for itself in
the long run.

Another common waste of engineering time is a CI system that takes a long time to run and that runs only *after* a request for a code review has been triggered.  In this situation, there’s the potential to waste two
people’s time: both the author and also the code reviewer, who may spend time spotting and pointing out issues with the
code that the CI bots could have flagged.

To help with this, try to make it easy to run the CI checks manually, independent from the automated system. This allows
engineers to get into the habit of triggering them regularly so that code reviewers never even see problems that the CI
would have flagged.  Better still, make the integration even more continuous by incorporating some of the tools into your
editor or IDE setup so that (for example) poorly formatted code never even makes it to disk.

This may also require splitting the checks up if there are time-consuming tests that rarely find problems but are
there as a backstop to prevent obscure scenarios
breaking.

More generally, a large project may need to divide up its CI checks according to the cadence at which they are run:

-

Checks that are integrated into each engineer’s development environment (e.g., `rustfmt`)

-

Checks that run on every code review request (e.g., `cargo build`, `cargo clippy`) and are easy to run
manually

-

Checks that run on every change that makes it to the main branch of the project (e.g., full `cargo test` in all
supported environments)

-

Checks that run at scheduled intervals (e.g., daily or weekly), which can catch rare regressions after the fact
(e.g., long-running integration tests and benchmark comparison tests)

-

Checks that run on the current code at all times (e.g., fuzz tests)

It’s important that the CI system be integrated with whatever code review system is used for your project so that a
code review can clearly see a green set of checks and be confident that its code review can focus on the important
meaning of the code, not on trivial details.

This need for a green build also means that there can be no exceptions to whatever checks your CI system has put in
place.  This is worthwhile even if you have to work around an occasional false positive from a tool; once your CI system
has an accepted failure (“Oh, everyone knows that test never passes”), then it’s vastly harder to spot new regressions.

[Item 30](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch05.html#file_testing_md) included the common advice of adding a test to reproduce a bug, before fixing the  bug. The same principle
applies to your CI system: when you discover process problems *add a CI step that detects a process issue,
before fixing the issue*.  For example, if you discover that some auto-generated code has gotten out of sync with its
source, add a check for this to the CI system.  This check will initially fail but then turn green once the problem is
solved—giving you confidence that this category of process error will not occur again in the future.

## Public CI Systems

If your codebase is open source and visible to the public, there are a few extra things to think about with your
CI system.

First is the good news: there are lots of free, reliable options for building a CI system for
open source code.  At the time of writing,  [GitHub Actions](https://docs.github.com/en/actions) are probably the
best choice, but it’s far from the only choice, and more systems appear all the time.

Second, for open source code it’s worth bearing in mind that your CI system can act as a guide for how to set up any
prerequisites needed for the codebase.  This isn’t a concern for pure Rust crates, but if your codebase requires
additional dependencies—databases, alternative toolchains for FFI code, configuration, etc.—then your
CI scripts will be an existence proof of how to get all of that working on a fresh system. Encoding these setup steps in
reusable scripts allows both the humans and the bots to get a working system in a straightforward way.

Finally, there’s bad news for publicly visible crates: the possibility of abuse and attacks. This can range from
attempts to perform cryptocurrency mining in your CI system to [theft of codebase access tokens](https://oreil.ly/yP-8m),  supply chain
attacks, and worse. To mitigate these risks, consider these guidelines:

-

Restrict access so that CI scripts run automatically only for known collaborators and have to
be triggered manually for new contributors.

-

Pin the versions of any external scripts to particular versions, or (better yet) specific known hashes.

-

Closely monitor any integration steps that need more than just read access to the codebase.

[1](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch05.html#id1626-marker) Historically, this option used to be called `intra_doc_link_resolution_failure`.

[2](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch05.html#id1639-marker) The default behavior of automatically including *README.md* can be overridden with the [readme field in Cargo.toml](https://doc.rust-lang.org/cargo/reference/manifest.html#the-readme-field).

[3](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch05.html#id1654-marker) Scott Meyers,  *More Effective C++* (Addison-Wesley), Item 32.

[4](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch05.html#id1683-marker) An eagle-eyed reader might notice that `format_args!` still looks like a macro invocation, even after macros have been expanded.  That’s because it’s a special macro that’s built into the compiler.

[5](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch05.html#id1712-marker) The [std::fmt module](https://doc.rust-lang.org/std/fmt/index.html) also includes various other traits that are used when displaying data in particular formats. For example, [LowerHex](https://doc.rust-lang.org/std/fmt/trait.LowerHex.html) is used when an `x` format specifier indicates that lower-case hexadecimal output is required.

[6](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch05.html#id1875-marker) If your code is a widely used open source crate, the  [Google OSS-Fuzz program](https://google.github.io/oss-fuzz/getting-started/accepting-new-projects/) may be willing to run fuzzing on your behalf.

[7](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch05.html#id1899-marker) This list may be reduced in some environments. For example, [Rust development in Android](https://oreil.ly/nptNC) has a centrally controlled toolchain (so no `rustup`) and integrates with  Android’s  Soong build system (so no `cargo`).

[8](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch05.html#id1945-marker) If your code relies on particular features that are available only in the nightly compiler, a *rust-toolchain.toml* file also makes that toolchain dependency clear.

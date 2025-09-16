# Chapter 6. Beyond Standard Rust

The Rust toolchain includes support for a much wider variety of environments than just pure Rust application code,
running in userspace:

-

It supports  *cross-compilation*, where the system running the toolchain (the *host*) is not the same as
the system that the compiled code will run on (the *target*), which makes it easy to target embedded systems.

-

It supports linking with code compiled from languages other than Rust, via built-in FFI capabilities.

-

It supports configurations without the full standard library `std`, allowing systems that do not have a full operating
system (e.g., no filesystem, no networking) to be targeted.

-

It even supports configurations that do not support heap allocation but only have a stack (by omitting use of
the standard `alloc` library).

These nonstandard Rust environments can be harder to work in and may be less safe—they can even be
`unsafe`—but they give more options for getting the job done.

This chapter of the book discusses just a few of the basics for working in these environments. Beyond these basics, you’ll
need to consult more environment-specific documentation (such as the
[Rustonomicon](https://doc.rust-lang.org/nomicon/)).

# Item 33: Consider making library code
`no_std` compatible

Rust comes with a standard library called  `std`, which includes code for a wide variety of common tasks, from standard
data structures to networking, from multithreading support to file I/O.  For convenience, several of the items from `std`
are automatically imported into your program, via the
[prelude](https://doc.rust-lang.org/std/prelude/index.html): a set of common  `use` statements that
make common types available without needing to use their full names (e.g., `Vec` rather than `std::vec::Vec`).

Rust also supports building code for environments where it’s not possible to provide this full standard library, such as
bootloaders, firmware, or embedded platforms in general.  Crates indicate that they should be built in this way by
including the
`#![no_std]` crate-level attribute at the top of *src/lib.rs*.

This Item explores what’s lost when building for `no_std` and what library functions you can still rely on—which
turns out to be quite a lot.

However, this Item is specifically about `no_std` support in *library* code.  The difficulties of making a `no_std`
*binary* are beyond this text,[1](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch06.html#id1968) so the focus here is how to make sure that library code is available
for those poor souls who do have to work in such a minimal environment.

## `core`

Even when building for the most restricted of platforms, many of the fundamental types from the standard library are
still available.  For example,  [Option](https://doc.rust-lang.org/core/option/enum.Option.html) and
[Result](https://doc.rust-lang.org/core/result/enum.Result.html) are still available, albeit under a different
name, as are various flavors of  [Iterator](https://doc.rust-lang.org/core/iter/trait.Iterator.html).

The different names for these fundamental types start with `core::`, indicating that they come from the  `core`
library, a standard library that’s available even in the most `no_std` of environments. These `core::` types behave
exactly the same as the equivalent `std::` types, because they’re actually the same types—in each case, the
`std::` version is just a  re-export of the underlying `core::` type.

This means that there’s a quick and dirty way to tell if a `std::`
item is available in a `no_std` environment: visit the [doc.rust-lang.org](https://doc.rust-lang.org/std/index.html)
page for the `std` item you’re interested in and follow the “source” link (at the top right).[2](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch06.html#id1977)  If that takes you to a
*src/core/…​* location, then the item is available under `no_std` via `core::`.

The types from `core` are available for all Rust programs automatically.  However, they typically need to be
explicitly `use`d in a `no_std` environment, because the `std`  prelude is absent.

In practice, relying purely on `core` is too limiting for many environments, even `no_std` ones.  A
core (pun intended) constraint of `core` is that it performs *no heap allocation*.

Although Rust excels at putting items on the stack and safely tracking the corresponding lifetimes ([Item 14](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch03.html#file_lifetimes_md)), this
restriction still means that standard data structures—vectors, maps, sets—can’t be provided,
because they need to allocate  heap space for their contents.  In turn, this also drastically reduces the number of
available crates that work in this environment.

## `alloc`

However, if a `no_std` environment *does* support heap allocation, then many of the standard data structures from `std` can
still be supported.  These data structures, along with other allocation-using functionality, are grouped into Rust’s
[alloc](https://doc.rust-lang.org/alloc/) library.

As with `core`, these `alloc` variants are actually the same types under the covers.  For example, the real name of
[std::vec::Vec](https://doc.rust-lang.org/std/vec/struct.Vec.html) is actually
[alloc::vec::Vec](https://doc.rust-lang.org/alloc/vec/struct.Vec.html).

A `no_std` Rust crate needs to explicitly opt in to the use of `alloc`, by adding an  `extern crate alloc;` declaration to *src/lib.rs*:[3](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch06.html#id1991)

```
//! My `no_std` compatible crate.
#![no_std]

// Requires `alloc`.
extern crate alloc;
```

Pulling in the `alloc` crate enables many familiar friends, now addressed by their true names:

-

[alloc::boxed::Box<T>](https://doc.rust-lang.org/alloc/boxed/struct.Box.html)

-

[alloc::rc::Rc<T>](https://doc.rust-lang.org/alloc/rc/struct.Rc.html)

-

[alloc::sync::Arc<T>](https://doc.rust-lang.org/alloc/sync/struct.Arc.html)

-

[alloc::vec::Vec<T>](https://doc.rust-lang.org/alloc/vec/struct.Vec.html)

-

[alloc::string::String](https://doc.rust-lang.org/alloc/string/struct.String.html)

-

[alloc::format!](https://doc.rust-lang.org/alloc/macro.format.html)

-

[alloc::collections::BTreeMap​<K, V>](https://doc.rust-lang.org/alloc/collections/btree_map/struct.BTreeMap.html)

-

[alloc::collections::BTreeSet<T>](https://doc.rust-lang.org/alloc/collections/btree_set/struct.BTreeSet.html)

With these things available, it becomes possible for many library crates to be `no_std` compatible—for
example, if a library doesn’t involve I/O or networking.

There’s a notable absence from the data structures that `alloc` makes available, though—the
collections
[HashMap](https://doc.rust-lang.org/std/collections/struct.HashMap.html) and
[HashSet](https://doc.rust-lang.org/std/collections/hash_set/struct.HashSet.html) are specific to `std`, not `alloc`.
That’s because these hash-based containers rely on random seeds to protect against hash collision attacks, but safe random
number generation requires assistance from the operating system—which `alloc` can’t assume exists.

Another notable absence is synchronization functionality like
[std::sync::Mutex](https://doc.rust-lang.org/std/sync/struct.Mutex.html), which is required for
multithreaded code ([Item 17](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch03.html#file_deadlock_md)).  These types are specific to  `std` because they rely on OS-specific synchronization
primitives, which aren’t available without an OS.  If you need to write code that is both `no_std` and multithreaded,
third-party crates such as  [spin](https://docs.rs/spin/) are probably your only option.

## Writing Code for `no_std`

The previous sections made it clear that for *some* library crates, making the code `no_std` compatible just involves the following:

-

Replacing `std::` types with identical `core::` or `alloc::` crates (which requires  `use` of the full type name,
due to the absence of the `std`  prelude)

-

Shifting from `HashMap`/`HashSet` to `BTreeMap`/`BTreeSet`

However, this only makes sense if all of the crates that you depend on ([Item 25](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch04.html#file_dep-graph_md)) are also `no_std`
compatible—there’s no point in becoming `no_std` compatible if any user of your crate is forced to link in `std`
anyway.

There’s also a catch here: the Rust compiler will not tell you if your `no_std` crate depends on a `std`-using
dependency. This means that it’s easy to undo the work of making a crate `no_std` compatible—all it
takes is an added or updated dependency that pulls in `std`.

To protect against this, *add a CI check for a `no_std` build* so that your  CI system ([Item 32](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch05.html#file_ci_md)) will
warn you if this happens.  The Rust toolchain supports cross-compilation out of the box, so this can be as simple as
performing a
[cross-compile](https://oreil.ly/DAbwt) for a
target system that does not support `std` (e.g., `--target thumbv6m-none-eabi`); any code that inadvertently requires
`std` will then fail to compile for this target.

So: if your dependencies support it, and the simple transformations above are all that’s needed, then *consider
making library code `no_std` compatible*.  When it is possible, it’s not much additional work, and it allows for the
widest reuse of the library.

If those transformations *don’t* cover all of the code in your crate but the parts that aren’t covered are only a small
or well-contained fraction of the code, then consider adding a  feature ([Item 26](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch04.html#file_features_md)) to your crate that turns on just
those parts.

Such a feature is conventionally named either `std`, if it enables use of `std`-specific functionality:

```
#![cfg_attr(not(feature = "std"), no_std)]
```

or `alloc`, if it turns on use of `alloc`-derived functionality:

```
#[cfg(feature = "alloc")]
extern crate alloc;
```

Note that there’s a trap for the unwary here: don’t have a `no_std` feature that *disables* functionality requiring
`std` (or a `no_alloc` feature similarly).  As explained in [Item 26](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch04.html#file_features_md), features need to be additive, and there’s no way
to combine two users of the crate where one configures `no_std` and one doesn’t—the former will trigger the
removal of code that the latter relies on.

As ever with feature-gated code, make sure that your CI system ([Item 32](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch05.html#file_ci_md)) builds all the relevant
combinations—including a build with the `std` feature disabled on an explicitly `no_std` platform.

## Fallible Allocation

The earlier sections of this Item considered two different `no_std` environments: a fully embedded environment with no
heap allocation whatsoever (`core`) and a more generous environment where heap allocation is allowed (`core` +
`alloc`).

However, there are some important environments that fall between these two camps⁠—​in particular, those where heap
allocation is possible but may fail because there’s a limited amount of heap.

Unfortunately, Rust’s standard  `alloc` library includes a pervasive assumption that  heap allocations cannot fail, and that’s not always a valid assumption.

Even a simple use of `alloc::vec::Vec` could potentially allocate on every line:

```
let mut v = Vec::new();
v.push(1); // might allocate
v.push(2); // might allocate
v.push(3); // might allocate
v.push(4); // might allocate
```

None of these operations returns a `Result`, so what happens if those allocations fail?

The answer depends on the toolchain, target, and
[configuration](https://oreil.ly/5kPxH) but is likely to descend into
`panic!` and program termination.  There is certainly no answer that allows an allocation failure on line 3 to be
handled in a way that allows the program to move on to line 4.

This assumption of  *infallible allocation* gives good ergonomics for code that runs in a “normal”
userspace, where there’s effectively infinite memory—or at least where running out of memory indicates that the
computer as a whole has bigger problems
elsewhere.

However, infallible allocation is utterly unsuitable for code that needs to run in environments where memory is
limited and programs are required to cope.  This is a (rare) area where there’s better support in older, less
memory-safe, languages:

-

C is sufficiently low-level that allocations are manual, and so the return value from `malloc` can be checked for `NULL`.

-

C++ can use its  exception mechanism to catch allocation failures in the form
of [std::bad_alloc](https://en.cppreference.com/w/cpp/memory/new/bad_alloc) exceptions.[4](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch06.html#id2028)

Historically, the inability of Rust’s standard library to cope with failed allocation was flagged in some high-profile
contexts (such as the [Linux kernel](https://oreil.ly/hzzCR), Android, and the [Curl tool](https://oreil.ly/jvfOw)), and so work to fix the
omission is ongoing.

The first step was the  [“fallible collection allocation” changes](https://oreil.ly/gyhpR), which added  fallible alternatives to many of the collection
APIs that involve allocation.  This generally adds a `try_<operation>` variant that results in a `Result<_,`
`AllocError>`;
for example:

-

[Vec::try_reserve](https://doc.rust-lang.org/std/vec/struct.Vec.html#method.try_reserve) is available as an
alternative to
[Vec::reserve](https://doc.rust-lang.org/std/vec/struct.Vec.html#method.reserve).

-

[Box::try_new](https://doc.rust-lang.org/std/boxed/struct.Box.html#method.try_new) is available (with the nightly
toolchain) as an alternative to [Box::new](https://doc.rust-lang.org/std/boxed/struct.Box.html#method.new).

These fallible APIs only go so far; for example, there is (as yet) no fallible equivalent to
[Vec::push](https://doc.rust-lang.org/std/vec/struct.Vec.html#method.push), so code that assembles a vector may need
to do careful calculations to ensure that allocation errors can’t happen:

```
fn try_build_a_vec() -> Result<Vec<u8>, String> {
    let mut v = Vec::new();

    // Perform a careful calculation to figure out how much space is needed,
    // here simplified to...
    let required_size = 4;

    v.try_reserve(required_size)
        .map_err(|_e| format!("Failed to allocate {} items!", required_size))?;

    // We now know that it's safe to do:
    v.push(1);
    v.push(2);
    v.push(3);
    v.push(4);

    Ok(v)
}
```

As well as adding fallible allocation entrypoints, it’s also possible to disable *infallible* allocation operations,
by turning off the  [no_global_oom_handling](https://github.com/rust-lang/rust/pull/84266) config flag (which is
on by default).  Environments with limited heap (such as the Linux kernel) can explicitly disable this flag, ensuring
that no use of infallible allocation can inadvertently creep into the code.

## Things to Remember

-

Many items in the `std` crate actually come from `core` or `alloc`.

-

As a result, making library code `no_std` compatible may be more straightforward than you might think.

-

Confirm that `no_std` code remains `no_std` compatible by checking it in CI.

-

Be aware that working in a limited-heap environment currently has limited library support.

# Item 34: Control what crosses FFI boundaries

Even though Rust comes with a comprehensive [standard library](https://doc.rust-lang.org/std/index.html) and a
burgeoning [crate ecosystem](https://crates.io/), there is still a lot more non-Rust code in the world
than there is Rust code.

As with other recent languages, Rust helps with this problem by offering a *foreign function interface* (FFI)
mechanism, which allows interoperation with code and data structures written in different languages—despite the
name, FFI is not restricted to just functions.  This opens up the use of existing libraries in different languages, not
just those that have succumbed to the Rust community’s efforts to  “rewrite it in Rust” (RiiR).

The default target for Rust’s interoperability is the  C programming language, which is the same interop target
that other languages aim at.  This is partly driven by the ubiquity of C libraries but is also driven by simplicity: C
acts as a “least common denominator” of interoperability, because it doesn’t need toolchain support of any of the more
advanced features that would be necessary for compatibility with other languages (e.g., garbage collection for Java or
Go, exceptions and templates for C++, function overrides for Java and C++, etc.).

However, that’s not to say that interoperability with plain C is simple.  By including code written in a different
language, all of the guarantees and protections that Rust offers are up for grabs, particularly those involving memory
safety.

As a result, FFI code in Rust is automatically `unsafe`, and the advice in [Item 16](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch03.html#file_unsafe_md) has to be bypassed. This Item
explores some replacement advice, and [Item 35](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch06.html#file_bindgen_md) will explore some tooling that helps to avoid some (but not all) of the
footguns involved in working with FFI.  (The [FFI chapter](https://oreil.ly/2jHBA) of the
[Rustonomicon](https://doc.rust-lang.org/nomicon/) also contains helpful advice and information.)

## Invoking C Functions from Rust

The simplest FFI interaction is for Rust code to invoke a C function, taking “immediate” arguments that don’t involve
pointers, references, or memory addresses:

```
/* File lib.c */
#include "lib.h"

/* C function definition. */
int add(int x, int y) {
  return x + y;
}
```

This C code provides a *definition* of the function and is typically accompanied by a  header file
that provides a *declaration* of the function, which allows other C code to use it:

```
/* File lib.h */
#ifndef LIB_H
#define LIB_H

/* C function declaration. */
int add(int x, int y);

#endif  /* LIB_H */
```

The declaration roughly says: somewhere out there is a function called `add`, which takes two integers as input and
returns another integer as output.  This allows C code to use the `add` function, subject to a promise that the actual
code for `add` will be provided at a later date—specifically, at  link time.

Rust code that wants to use `add` needs to have a similar declaration, with a similar purpose: to describe the
signature of the function and to indicate that the corresponding code will be available later:

```
use std::os::raw::c_int;
extern "C" {
    pub fn add(x: c_int, y: c_int) -> c_int;
}
```

The declaration is
marked as  `extern "C"` to indicate that an external C library will provide the code for the function.[5](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch06.html#id2050)   The `extern "C"` marker also automatically marks the function as
[no_mangle](https://doc.rust-lang.org/reference/abi.html?highlight=no_mangle#the-no_mangle-attribute),
which we explore in [“Name mangling”](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch06.html#name-mingling).

### Linking logistics

The details of how the C toolchain generates an external C library—and its format—are environment-specific
and beyond the scope of a Rust book like this.  However, one simple variant that’s common on Unix-like systems is a
*static library* file, which will normally have the form *lib<something>.a* (e.g., *libcffi.a*) and
which can be generated using the  [ar](https://man7.org/linux/man-pages/man1/ar.1.html) tool.

The Rust build system then needs an indication of which library holds the relevant C code. This can be specified either
via the [link attribute](https://oreil.ly/_N-Fv) in the
code:

```
#[link(name = "cffi")] // An external library like `libcffi.a` is needed
extern "C" {
    // ...
}
```

or via a  [build script](https://doc.rust-lang.org/cargo/reference/build-scripts.html) that emits a
[cargo:rustc-link-lib](https://doc.rust-lang.org/cargo/reference/build-scripts.html#rustc-link-lib)
instruction to `cargo`:[6](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch06.html#id2059)

```
// File build.rs
fn main() {
    // An external library like `libcffi.a` is needed
    println!("cargo:rustc-link-lib=cffi");
}
```

The latter option is more flexible, because the build script can examine its environment and behave differently
depending on what it finds.

In either case, the Rust build system is also likely to need information about how to find the C library, if it’s not in
a standard system location.  This can be specified by having a build script that emits a
[cargo:rustc-link-search](https://doc.rust-lang.org/cargo/reference/build-scripts.html#rustc-link-search) instruction
to `cargo`, containing the library location:

```
// File build.rs
fn main() {
    // ...

    // Retrieve the location of `Cargo.toml`.
    let dir = std::env::var("CARGO_MANIFEST_DIR").unwrap();
    // Look for native libraries one directory higher up.
    println!(
        "cargo:rustc-link-search=native={}",
        std::path::Path::new(&dir).join("..").display()
    );
}
```

### Code concerns

Returning to the source code, even this simplest of examples comes with some gotchas.  First, use of FFI functions is
automatically `unsafe`:

```
let x = add(1, 1);
```

```
error[E0133]: call to unsafe function is unsafe and requires unsafe function
              or block
   --> src/main.rs:176:13
    |
176 |     let x = add(1, 1);
    |             ^^^^^^^^^ call to unsafe function
    |
    = note: consult the function's documentation for information on how to
            avoid undefined behavior
```

and so needs to be wrapped in `unsafe { }`.

The next thing to watch out for is the use of C’s `int` type, represented as
[std::os::raw::c_int](https://doc.rust-lang.org/std/os/raw/type.c_int.html). How big is an `int`?  It’s
*probably* true that the following two things are the same:

-

The size of an `int` for the toolchain that compiled the C library

-

The size of a `std::os::raw::c_int` for the Rust toolchain

But why take the chance?  *Prefer sized types at FFI boundaries*, where possible—which for C means
making use of the types (e.g., `uint32_t`) defined in `<stdint.h>`.  However, if you’re dealing with an existing codebase
that already uses `int`/`long`/`size_t`, this may be a luxury you don’t have.

The final practical concern is that the C code and the equivalent Rust declaration need to exactly match.  Worse still,
if there’s a mismatch, the build tools will not emit a warning—they will just silently emit incorrect code.

[Item 35](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch06.html#file_bindgen_md) discusses the use of the  `bindgen` tool to prevent this problem, but it’s worth understanding the basics
of what’s going on under the covers to understand *why* the build tools can’t detect the problem on their
own.  In particular, it’s worth understanding the basics of  *name mangling*.

### Name mangling

Compiled languages generally support  *separate compilation*, where different parts of the program are converted
into machine code as separate chunks (object files), which can then be combined into a complete program by the
*linker*.  This means that if only one small part of the program’s source code changes, only the corresponding
object file needs to be regenerated; the link step then rebuilds the program, combining both the changed object and all
the other unmodified objects.

The [link step is (roughly speaking) a “join-the-dots” operation](https://oreil.ly/gzfEl): some
object files provide definitions of functions and variables, and other object files have placeholder markers indicating that
they expect to use a definition from some other object, but it wasn’t available at compile time.  The linker combines
the two: it ensures that any placeholder in the compiled code is replaced with a reference to the corresponding concrete
definition.

The linker performs this correlation between the placeholders and the definitions by simply checking for a matching
name, meaning that there is a single global namespace for all of these correlations.

Historically, this was fine for linking C language programs, where a single name could not be reused in any
way—the name of a function is exactly what appears in the object file.  (As a result, a common convention for C
libraries is to manually add a prefix to all symbols so that `lib1_process` doesn’t clash with `lib2_process`.)

However, the introduction of  C++ caused a problem because C++ allows overridden definitions with the same name:

```
// C++ code
namespace ns1 {
int32_t add(int32_t a, int32_t b) { return a+b; }
int64_t add(int64_t a, int64_t b) { return a+b; }
}
namespace ns2 {
int32_t add(int32_t a, int32_t b) { return a+b; }
}
```

The solution for this is  *name mangling*: the [compiler encodes the signature and type information](https://lurklurk.org/linkers/linkers.html#namemangling) for the overridden functions into the name that’s
emitted in the object file, and the linker continues to perform its simple-minded 1:1 correlation between placeholders
and definitions.

On Unix-like systems, the  [nm](https://en.wikipedia.org/wiki/Nm_%28Unix%29) tool can help show what the linker
works with:

```
% nm ffi-lib.o | grep add  # what the linker sees for C
0000000000000000 T _add

% nm ffi-cpp-lib.o | grep add  # what the linker sees for C++
0000000000000000 T __ZN3ns13addEii
0000000000000020 T __ZN3ns13addExx
0000000000000040 T __ZN3ns23addEii
```

In this case, it shows three mangled symbols, all of which refer to code (the `T` indicates the  *text section* of
the binary, which is the traditional name for where code lives).

The  [c++filt](https://man7.org/linux/man-pages/man1/c%2b%2bfilt.1.html) tool helps translate this back into what
would be visible in C++ code:

```
% nm ffi-cpp-lib.o | grep add | c++filt  # what the programmer sees
0000000000000000 T ns1::add(int, int)
0000000000000020 T ns1::add(long long, long long)
0000000000000040 T ns2::add(int, int)
```

Because the mangled name includes type information, the linker can and will complain about any mismatch in the type
information between placeholder and definition. This gives some measure of type safety: if the definition changes but
the place using it is not updated, the toolchain will complain.

Returning to Rust, `extern "C"` foreign functions are implicitly marked as  `#[no_mangle]`, and the
symbol in the object file is the bare name, exactly as it would be for a C program.  This means that the type safety of
function signatures is lost: because the linker sees only the bare names for functions, if there are any differences in
type expectations between definition and use, the linker will carry on regardless and problems will arise only at
runtime.

## Accessing C Data from Rust

The C `add` example in the previous section passed the simplest possible type of data back and forth between Rust and C:
an integer that fits in a machine register.  Even so, there were still things to be careful about, so it’s no surprise
then that dealing with more complex data structures also has wrinkles to watch out for.

Both C and Rust use the  `struct` to combine related data into a single data structure.  However, when a `struct`
is realized in memory, the two languages may well choose to put different fields in different places or even in
different orders (the  *[layout](https://oreil.ly/cjkXO)*).  To prevent mismatches,
*use  `#[repr(C)]` for Rust types used in FFI*; this [representation is designed for the purpose of allowing C interoperability](https://doc.rust-lang.org/reference/type-layout.html#the-c-representation):

```
/* C data structure definition. */
/* Changes here must be reflected in lib.rs. */
typedef struct {
    uint8_t byte;
    uint32_t integer;
} FfiStruct;
```

```
// Equivalent Rust data structure.
// Changes here must be reflected in lib.h / lib.c.
#[repr(C)]
pub struct FfiStruct {
    pub byte: u8,
    pub integer: u32,
}
```

The structure definitions have a comment to remind the humans involved that the two places need to be kept in sync.
Relying on the constant vigilance of humans is likely to go wrong in the long term; as for function signatures, it’s
better to automate this synchronization between the two languages via a tool like `bindgen` ([Item 35](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch06.html#file_bindgen_md)).

One particular type of data that’s worth thinking about carefully for FFI interactions is strings.  The default
definitions of what makes up a string are somewhat different between C and Rust:

-

A Rust  [String](https://doc.rust-lang.org/alloc/string/struct.String.html) holds  UTF-8 encoded data,
possibly including zero bytes,  with an explicitly known length.

-

A C string (`char *`) holds byte values (which may or may not be signed), with its length implicitly determined by the
first zero byte (`\0`) found in the data.

Fortunately, dealing with C-style strings in Rust is comparatively straightforward, because the Rust library designers
have already done the heavy lifting by providing a pair of types to encode them. *Use the
[CString](https://doc.rust-lang.org/alloc/ffi/struct.CString.html) type* to hold (owned) strings that need to
be interoperable with C, and use the corresponding
[CStr](https://doc.rust-lang.org/core/ffi/struct.CStr.html) type when dealing with borrowed string
values.  The latter type includes the [as_ptr()](https://doc.rust-lang.org/core/ffi/struct.CStr.html#method.as_ptr)
method, which can be used to pass the string’s contents to any FFI function that’s expecting a `const char*` C string.
Note that the `const` is important: this can’t be used for an FFI function that needs to modify the contents (`char *`)
of the string that’s passed to it.

## Lifetimes

Most data structures are too big to fit in a register and so have to be held in memory instead.  That in turn means that
access to the data is performed via the location of that memory. In C terms, this means a  *pointer*: a number
that encodes a memory address—with no other semantics attached ([Item 8](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch01.html#file_references_md)).

In Rust, a location in memory is generally represented as a  *reference*, and its numeric value can be extracted
as a  *raw pointer*, ready to feed into an FFI boundary:

```
extern "C" {
    // C function that does some operation on the contents
    // of an `FfiStruct`.
    pub fn use_struct(v: *const FfiStruct) -> u32;
}
```

```
let v = FfiStruct {
    byte: 1,
    integer: 42,
};
let x = unsafe { use_struct(&v as *const FfiStruct) };
```

However, a Rust reference comes with additional constraints around the  *lifetime* of the associated chunk of
memory, as described in [Item 14](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch03.html#file_lifetimes_md); these constraints get lost in the conversion to a raw pointer.

As a result, the use of raw pointers is inherently `unsafe`, as a marker that  Here Be Dragons: the C code on the
other side of the FFI boundary could do any number of things that will destroy Rust’s memory safety:

-

The C code could hang onto the value of the pointer and use it at a later point when the associated memory has
either been freed from the heap or reused on the stack  (*use-after-free*).

-

The C code could decide to cast away the `const`-ness of a pointer that’s passed to it and modify data that Rust
expects to be immutable.

-

The C code is not subject to Rust’s `Mutex` protections, so the specter of data races ([Item 17](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch03.html#file_deadlock_md))
rears its ugly head.

-

The C code could mistakenly return associated heap memory to the allocator (by calling C’s   `free()`
library function), meaning that the *Rust* code might now be performing use-after-free operations.

All of these dangers form part of the cost-benefit analysis of using an existing library via FFI.  On the plus side, you
get to reuse existing code that’s (presumably) in good working order, with only the need to write (or auto-generate)
corresponding declarations.  On the minus side, you lose the memory protections that are a big reason to use Rust in the
first place.

As a first step to reduce the chances of memory-related problems, *allocate and free memory on the same side of
the FFI boundary*.  For example, this might appear as a symmetric pair of functions:

```
/* C functions. */

/* Allocate an `FfiStruct` */
FfiStruct* new_struct(uint32_t v);
/* Free a previously allocated `FfiStruct` */
void free_struct(FfiStruct* s);
```

with corresponding Rust FFI declarations:

```
extern "C" {
    // C code to allocate an `FfiStruct`.
    pub fn new_struct(v: u32) -> *mut FfiStruct;
    // C code to free a previously allocated `FfiStruct`.
    pub fn free_struct(s: *mut FfiStruct);
}
```

To make sure that allocation and freeing are kept in sync, it can be a good idea to implement an  RAII wrapper that
automatically prevents C-allocated memory from being leaked ([Item 11](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch02.html#file_raii_md)).  The wrapper structure owns the C-allocated
memory:

```
/// Wrapper structure that owns memory allocated by the C library.
struct FfiWrapper {
    // Invariant: inner is non-NULL.
    inner: *mut FfiStruct,
}
```

and the  `Drop` implementation returns that memory to the C library to avoid the potential for
leaks:

```
/// Manual implementation of [`Drop`], which ensures that memory allocated
/// by the C library is freed by it.
impl Drop for FfiWrapper {
    fn drop(&mut self) {
        // Safety: `inner` is non-NULL, and besides `free_struct()` copes
        // with NULL pointers.
        unsafe { free_struct(self.inner) }
    }
}
```

The same principle applies to more than just heap memory: *implement `Drop` to apply RAII to FFI-derived resources*—open files, database connections, etc. (see [Item 11](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch02.html#file_raii_md)).

Encapsulating the interactions with the C library into a wrapper `struct` also makes it possible to catch some other
potential footguns, for example, by transforming an otherwise invisible failure into a `Result`:

```
type Error = String;

impl FfiWrapper {
    pub fn new(val: u32) -> Result<Self, Error> {
        let p: *mut FfiStruct = unsafe { new_struct(val) };
        // Raw pointers are not guaranteed to be non-NULL.
        if p.is_null() {
            Err("Failed to get inner struct!".into())
        } else {
            Ok(Self { inner: p })
        }
    }
}
```

The wrapper structure can then offer safe methods that allow use of the C library’s functionality:

```
impl FfiWrapper {
    pub fn set_byte(&mut self, b: u8) {
        // Safety: relies on invariant that `inner` is non-NULL.
        let r: &mut FfiStruct = unsafe { &mut *self.inner };
        r.byte = b;
    }
}
```

Alternatively, if the underlying C data structure has an equivalent Rust mapping, and if it’s safe
to directly manipulate that data structure, then implementations of the  `AsRef` and
`AsMut` traits (described in [Item 8](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch01.html#file_references_md)) allow more direct use:

```
impl AsMut<FfiStruct> for FfiWrapper {
    fn as_mut(&mut self) -> &mut FfiStruct {
        // Safety: `inner` is non-NULL.
        unsafe { &mut *self.inner }
    }
}
```

```
let mut wrapper = FfiWrapper::new(42).expect("real code would check");
// Directly modify the contents of the C-allocated data structure.
wrapper.as_mut().byte = 12;
```

This example illustrates a useful principle for dealing with FFI: *encapsulate access to an `unsafe` FFI
library inside safe Rust code*. This allows the rest of the application to follow the advice in [Item 16](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch03.html#file_unsafe_md) and avoid
writing `unsafe` code.  It also concentrates all of the dangerous code in one place, which you can then study (and test)
carefully to uncover problems—and treat as the most likely suspect when something does go wrong.

## Invoking Rust from C

What counts as “foreign” depends on where you’re standing: if you’re writing an application in C, then it may be a
*Rust* library that’s accessed via a foreign function interface.

The basics of exposing a Rust library to C code are similar to the opposite direction:

-

Rust functions that are exposed to C need an  `extern "C"` marker to ensure they’re C-compatible.

-

Rust symbols are name mangled by default (like C++),[7](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch06.html#id2121) so function
definitions also need a `#[no_mangle]` attribute to ensure that they’re accessible via a simple name.  This in turn
means that the function name is part of a single global namespace that can clash with any other symbol defined in the
program.  As such, *consider using a prefix for exposed names* to avoid ambiguities (`mylib_…​`).

-

Data structure definitions need the `#[repr(C)]` attribute to ensure that the layout of the contents is compatible
with an equivalent C data structure.

Also like the opposite direction, more subtle problems arise when dealing with pointers, references, and lifetimes.
A C pointer is different from a Rust reference, and you forget that at your peril:

#

```
#[no_mangle]
pub extern "C" fn add_contents(p: *const FfiStruct) -> u32 {
    // Convert the raw pointer provided by the caller into
    // a Rust reference.
    let s: &FfiStruct = unsafe { &*p }; // Ruh-roh
    s.integer + s.byte as u32
}
```

```
/* C code invoking Rust. */
uint32_t result = add_contents(NULL); // Boom!
```

When you’re dealing with raw pointers, it’s your responsibility to ensure that any use of them complies with Rust’s
assumptions and guarantees around references:

```
#[no_mangle]
pub extern "C" fn add_contents_safer(p: *const FfiStruct) -> u32 {
    let s = match unsafe { p.as_ref() } {
        Some(r) => r,
        None => return 0, // Pesky C code gave us a NULL.
    };
    s.integer + s.byte as u32
}
```

In these examples, the C code provides a raw pointer to the Rust code, and the Rust code converts it to a reference
in order to operate on the structure.  But where did that pointer come from?  What does the Rust reference refer to?

The very first example in [Item 8](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch01.html#file_references_md) showed how Rust’s memory safety prevents references to expired stack objects from
being returned; those problems reappear if you hand out a raw pointer:

#

```
impl FfiStruct {
    pub fn new(v: u32) -> Self {
        Self {
            byte: 0,
            integer: v,
        }
    }
}
```

```
// No compilation errors here.
#[no_mangle]
pub extern "C" fn new_struct(v: u32) -> *mut FfiStruct {
    let mut s = FfiStruct::new(v);
    &mut s // return raw pointer to a stack object that's about to expire!
}
```

Any pointers passed back from Rust to C should generally refer to heap memory, not stack memory.  But naively trying to
put the object on the heap via a `Box` doesn’t help:

#

```
// No compilation errors here either.
#[no_mangle]
pub extern "C" fn new_struct_heap(v: u32) -> *mut FfiStruct {
    let s = FfiStruct::new(v); // create `FfiStruct` on stack
    let mut b = Box::new(s); // move `FfiStruct` to heap
    &mut *b // return raw pointer to a heap object that's about to expire!
}
```

The owning `Box` is on the stack, so when it goes out of scope, it will free the heap object and the returned raw pointer
will again be invalid.

The tool for the job here is
[Box::into_raw](https://doc.rust-lang.org/std/boxed/struct.Box.html#method.into_raw), which abnegates
responsibility for the heap object, effectively “forgetting” about it:

```
#[no_mangle]
pub extern "C" fn new_struct_raw(v: u32) -> *mut FfiStruct {
    let s = FfiStruct::new(v); // create `FfiStruct` on stack
    let b = Box::new(s); // move `FfiStruct` to heap

    // Consume the `Box` and take responsibility for the heap memory.
    Box::into_raw(b)
}
```

This raises the question of how the heap object now gets freed. The previous advice was to perform allocation and
freeing of memory on the same side of the FFI boundary, which means that we need to persuade the Rust side of things to
do the freeing.  The corresponding tool for the job is
[Box::from_raw](https://doc.rust-lang.org/std/boxed/struct.Box.html#method.from_raw), which builds a `Box` from
a raw pointer:

```
#[no_mangle]
pub extern "C" fn free_struct_raw(p: *mut FfiStruct) {
    if p.is_null() {
        return; // Pesky C code gave us a NULL
    }
    let _b = unsafe {
        // Safety: p is known to be non-NULL
        Box::from_raw(p)
    };
} // `_b` drops at end of scope, freeing the `FfiStruct`
```

This still leaves the Rust code at the mercy of the C code; if the C code gets confused and asks Rust to free the
same pointer twice, Rust’s allocator is likely to become terminally confused.

That illustrates the general theme of this Item: using FFI exposes you to risks that aren’t present in standard Rust.
That may well be worthwhile, as long as you’re aware of the dangers and costs involved.  Controlling the details of what
passes across the FFI boundary helps to reduce that risk but by no means eliminates it.

Controlling the FFI boundary for C code invoking Rust also involves one final concern: if your Rust code ignores the
advice in [Item 18](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch03.html#file_panic_md), you should *prevent  `panic!`s from crossing the FFI boundary*, as this
always results in undefined behavior—undefined but
[bad](https://oreil.ly/qmUe0)![8](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch06.html#id2140)

## Things to Remember

-

Interfacing with code in other languages uses C as a least common denominator, which means that symbols all live
in a single global namespace.

-

Minimize the chances of problems at the FFI boundary by doing the following:

-

Encapsulating `unsafe` FFI code in safe wrappers

-

Allocating and freeing memory consistently on one side of the boundary or the other

-

Making data structures use C-compatible layouts

-

Using sized integer types

-

Using FFI-related helpers from the standard library

-

Preventing `panic!`s from escaping from Rust

# Item 35: Prefer `bindgen` to manual FFI mappings

[Item 34](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch06.html#file_ffi_md) discussed the mechanics of invoking C code from a Rust program, describing how declarations of C structures and
functions need to have an equivalent Rust declaration to allow them to be used over FFI. The C and Rust declarations
need to be kept in sync, and [Item 34](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch06.html#file_ffi_md) also warned that the toolchain wouldn’t help with this—mismatches would be
silently ignored, hiding problems that would arise later.

Keeping two things perfectly in sync sounds like a good target for automation, and the Rust project provides the
right tool for the job:  [bindgen](https://rust-lang.github.io/rust-bindgen/). The primary function of `bindgen`
is to parse a C header file and emit the corresponding Rust declarations.

Taking some of the example C declarations from [Item 34](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch06.html#file_ffi_md):

```
/* File lib.h */
#include <stdint.h>

typedef struct {
    uint8_t byte;
    uint32_t integer;
} FfiStruct;

int add(int x, int y);
uint32_t add32(uint32_t x, uint32_t y);
```

the `bindgen` tool can be manually invoked (or invoked by a  `build.rs` [build script](https://doc.rust-lang.org/cargo/reference/build-scripts.html)) to create a corresponding Rust file:

```
% bindgen --no-layout-tests \
          --allowlist-function="add.*" \
          --allowlist-type=FfiStruct \
          -o src/generated.rs \
          lib.h
```

The generated Rust is identical to the handcrafted declarations in [Item 34](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch06.html#file_ffi_md):

```
/* automatically generated by rust-bindgen 0.59.2 */

#[repr(C)]
#[derive(Debug, Copy, Clone)]
pub struct FfiStruct {
    pub byte: u8,
    pub integer: u32,
}
extern "C" {
    pub fn add(
        x: ::std::os::raw::c_int,
        y: ::std::os::raw::c_int,
    ) -> ::std::os::raw::c_int;
}
extern "C" {
    pub fn add32(x: u32, y: u32) -> u32;
}
```

and can be pulled into Rust code with the source-level  [include! macro](https://doc.rust-lang.org/std/macro.include.html):

```
// Include the auto-generated Rust declarations.
include!("generated.rs");
```

For anything but the most trivial FFI declarations, *use `bindgen` to generate Rust bindings for C
code*—this is an area where machine-made, mass-produced code is definitely preferable to artisanal handcrafted
declarations.  If a C function definition changes, the C compiler will complain if the C declaration no longer matches
the C definition, but nothing will complain that a handcrafted Rust declaration no longer matches the C declaration;
auto-generating the Rust declaration from the C declaration ensures that the two stay in sync

This also means that the `bindgen` step is an ideal candidate to include in a CI system ([Item 32](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch05.html#file_ci_md));
if the generated code is included in source control, the CI system can error out if a freshly generated file doesn’t
match the checked-in version.

The `bindgen` tool comes into its own when you’re dealing with an existing C codebase that has a large API.  Creating
Rust equivalents to a big *lib_api.h* header file is manual and tedious, and therefore error-prone—and as noted, many categories of mismatch error will not be detected by the toolchain.  `bindgen` also has a
[panoply](https://rust-lang.github.io/rust-bindgen/allowlisting.html) of
[options](https://oreil.ly/WSC8t) that allow specific subsets of an API to be
targeted (such as the `--allowlist-function` and `--allowlist-type` options previously illustrated).[9](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch06.html#id2147)

This also allows a layered approach for exposing an existing C library in Rust; a common convention for wrapping some
`xyzzy` library is to have the following:

-

An `xyzzy-sys` crate that holds (just) the `bindgen`-erated code—use of which is necessarily `unsafe`

-

An `xyzzy` crate that encapsulates the `unsafe` code and provides safe Rust access to the underlying functionality

This concentrates the `unsafe` code in one layer and allows the rest of the program to follow the advice in [Item 16](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch03.html#file_unsafe_md).

## Beyond C

The `bindgen` tool has the ability to [handle some C++ constructs](https://oreil.ly/vn8Hf)
but only a subset and in a limited fashion. For better (but still somewhat limited) integration, *consider using
the  [cxx](https://cxx.rs/) crate for C++/Rust interoperation*. Instead of generating Rust code from C++
declarations, `cxx` takes the approach of auto-generating *both* Rust and C++ code from a common schema, allowing for
tighter integration.

[1](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch06.html#id1968-marker) See [The Embedonomicon](https://oreil.ly/x74WK) or Philipp Oppermann’s [older blog post](https://oreil.ly/WTn-j) for information about what’s involved in creating a `no_std` binary.

[2](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch06.html#id1977-marker) Be aware that this can occasionally go wrong.  For example, at the time of writing, the  `Error` trait is defined in [core::](https://doc.rust-lang.org/1.70.0/core/error/trait.Error.html) but is marked as unstable there; only the [std:: version](https://doc.rust-lang.org/1.70.0/std/error/trait.Error.html) is stable.

[3](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch06.html#id1991-marker) Prior to Rust 2018, `extern crate` declarations were used to pull in dependencies.  This is now entirely handled by *Cargo.toml*, but the `extern crate` mechanism is still used to pull in those parts of the Rust standard library (the  *[sysroot crates](https://oreil.ly/sJzAv)*) that are optional in `no_std` environments.

[4](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch06.html#id2028-marker) It’s also possible to add the  [std::nothrow](https://en.cppreference.com/w/cpp/memory/new/nothrow) overload to calls to `new` and check for `nullptr` return values.  However, there are still container methods like [vector<T>::push_back](https://en.cppreference.com/w/cpp/container/vector/push_back) that allocate under the covers and that can therefore signal allocation failure only via an exception.

[5](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch06.html#id2050-marker) If the FFI functionality you want to use is part of the standard C  library, then you don’t need to create these declarations—the [libc](https://docs.rs/libc) crate already provides them.

[6](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch06.html#id2059-marker) A corresponding [links](https://doc.rust-lang.org/cargo/reference/build-scripts.html#the-links-manifest-key) key in the  *Cargo.toml* manifest can help to make this dependency visible to Cargo.

[7](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch06.html#id2121-marker) A Rust equivalent of the `c++filt` tool for translating mangled names back to programmer-visible names is  [rustfilt](https://crates.io/crates/rustfilt), which builds on the [rustc-demangle](https://github.com/rust-lang/rustc-demangle) command.

[8](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch06.html#id2140-marker) Note that Rust version 1.71 includes the [C-unwind ABI](https://oreil.ly/VVqVY), which makes some cross-language unwinding functionality possible.

[9](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch06.html#id2147-marker) The example also used the `--no-layout-tests` option to keep the output simple; by default, the generated code will include `#[test]` code to check that structures are indeed  laid out correctly.

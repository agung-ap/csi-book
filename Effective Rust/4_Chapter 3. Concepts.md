# Chapter 3. Concepts

The first two chapters of this book covered Rust’s types and traits, which helps provide the vocabulary needed to work
with some of the *concepts* involved in writing Rust code—the subject of this chapter.

The  borrow checker and  lifetime checks are central to what makes Rust unique; they are also a common
stumbling block for newcomers to Rust and so are the focus of the first two Items in this chapter.

The other Items in this chapter cover concepts that are easier to grasp but are nevertheless a bit different from
writing code in other languages.  This includes the
following:

-

Advice on Rust’s `unsafe` mode and how to avoid it ([Item 16](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch03.html#file_unsafe_md))

-

Good news and bad news about writing multithreaded code in Rust ([Item 17](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch03.html#file_deadlock_md))

-

Advice on avoiding runtime aborts ([Item 18](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch03.html#file_panic_md))

-

Information about Rust’s approach to reflection ([Item 19](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch03.html#file_reflection_md))

-

Advice on balancing optimization against maintainability ([Item 20](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch03.html#file_optimize_md))

It’s a good idea to try to align your code with the consequences of these concepts.  It’s *possible* to re-create (some
of) the behavior of   C/C++ in Rust, but why bother to use Rust if you do?

# Item 14: Understand lifetimes

This Item describes Rust’s  *lifetimes*, which are a more precise formulation of a concept that existed in
previous compiled languages like C and C++—in practice if not in theory.  Lifetimes are a required input for the
*borrow checker* described in [Item 15](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch03.html#file_borrows_md); taken together, these features form the heart of Rust’s memory safety
guarantees.

## Introduction to the Stack

Lifetimes are fundamentally related to the *stack*, so a quick introduction/reminder is in order.

While a program is running, the memory that it uses is divided up into different chunks, sometimes called
*segments*.  Some of these chunks are a fixed size, such as the ones that hold the program code or the program’s
global data, but two of the chunks—the *heap* and the *stack*—change size as the program
runs.  To allow for this, they are typically arranged at opposite ends of the program’s virtual memory space, so one
can grow downward and the other can grow upward (at least until your program runs out of memory and crashes), as
summarized in [Figure 3-1](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch03.html#fig_3_1).

![Representation of program memory layout, shown as a vertical rectangle divided into chunks.  From bottom to top the chunks are marked: Code, Global Data, Stack, but there is also an unlabelled chunk between Heap and Stack. In this empty chunk are two arrows each labelled Grows: the bottom arrow points up to indicate that the heap grows up into the empty space, the top arrow points down to indicate that the stack grows down into the empty space.](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781098151393/files/assets/efru_0301.png)

###### Figure 3-1. Program memory layout, including heap growing up and stack growing down

Of these two dynamically sized chunks, the stack is used to hold state related to the currently executing function.
This state can include these elements:

-

The parameters passed to the function

-

The local variables used in the function

-

Temporary values calculated within the function

-

The return address within the code of the function’s caller

When a function `f()` is called, a new stack frame is added to the stack, beyond where the stack frame for the calling
function ends, and the CPU normally updates a register—the  *stack pointer*—to point to the new
stack frame.

When the inner function `f()` returns, the stack pointer is reset to where it was before the call, which will be the
caller’s stack frame, intact and unmodified.

If the caller subsequently invokes a different function `g()`, the process happens again, which means that the stack
frame for `g()` will reuse the same area of memory that `f()` previously used (as depicted in [Figure 3-2](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch03.html#fig_3_2)):

```
fn caller() -> u64 {
    let x = 42u64;
    let y = 19u64;
    f(x) + g(y)
}

fn f(f_param: u64) -> u64 {
    let two = 2u64;
    f_param + two
}

fn g(g_param: u64) -> u64 {
    let arr = [2u64, 3u64];
    g_param + arr[1]
}
```

![The diagram shows four pictures of a stack, evolving from left to right as different functions are called. The first stack is for the caller function itself, and just has two entries: an x value of 42 and a y value of 19. These two entries are repeated at the top of all four stack diagrams.  The second stack shows caller invoking f, and has two added stack entries at the bottom: an f_param value of 42 and a two value of 2.  The third stack is back to just being for the caller function itself, and is a repeat of the first stack, holding just x and y.  The final stack shows caller invoking g, and has new stack entries below x and y in the space space that was used in the second stack.  These extra stack entries are a g_param value of 19, then a pair of values jointly labelled arr holding values 3 and 2.](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781098151393/files/assets/efru_0302.png)

###### Figure 3-2. Evolution of stack usage as functions are called and returned from

Of course, this is a dramatically simplified version of what really goes on—putting things on and off the stack
takes time, and so real processors will have many optimizations.  However, the simplified conceptual picture is enough
for understanding the subject of this Item.

## Evolution of Lifetimes

The previous section explained how parameters and local variables are stored on the stack and pointed out that those
values are stored only ephemerally.

Historically, this allowed for some dangerous footguns: what happens if you hold onto a pointer to one of these
ephemeral stack values?

Starting back with  C, it was perfectly OK to return a pointer to a local variable (although modern compilers will
emit a warning for it):

#

```
/* C code. */
struct File {
  int fd;
};

struct File* open_bugged() {
  struct File f = { open("README.md", O_RDONLY) };
  return &f;  /* return address of stack object! */
}
```

You *might* get away with this, if you’re unlucky and the calling code uses the returned value immediately:

#

```
struct File* f = open_bugged();
printf("in caller: file at %p has fd=%d\n", f, f->fd);
```

```
in caller: file at 0x7ff7bc019408 has fd=3
```

This is unlucky because it only *appears* to work.  As soon as any other function calls happen, the stack area will
be reused and the memory that used to hold the object will be overwritten:

#

```
investigate_file(f);
```

```
/* C code. */
void investigate_file(struct File* f) {
  long array[4] = {1, 2, 3, 4}; // put things on the stack
  printf("in function: file at %p has fd=%d\n", f, f->fd);
}
```

```
in function: file at 0x7ff7bc019408 has fd=1592262883
```

Trashing the contents of the object has an additional bad effect for this example: the file descriptor corresponding to
the open file is lost, and so the program leaks the resource that was held in the data structure.

Moving forward in time to  C++, this latter problem of losing access to resources was solved by the inclusion of
*destructors*, enabling  RAII (see [Item 11](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch02.html#file_raii_md)).  Now, the things on the stack have the ability to tidy themselves up:
if the object holds some kind of resource, the destructor can tidy it up, and the C++ compiler guarantees that the
destructor of an object on the stack gets called as part of tidying up the stack frame:

```
// C++ code.
File::~File() {
  std::cout << "~File(): close fd " << fd << "\n";
  close(fd);
  fd = -1;
}
```

The caller now gets an (invalid) pointer to an object that’s been destroyed and its resources reclaimed:

#

```
File* f = open_bugged();
printf("in caller: file at %p has fd=%d\n", f, f->fd);
```

```
~File(): close fd 3
in caller: file at 0x7ff7b6a7c438 has fd=-1
```

However, C++ did nothing to help with the problem of dangling pointers: it’s still possible to hold onto a pointer to an
object that’s gone (with a destructor that has been called):

```
// C++ code.
void investigate_file(File* f) {
  long array[4] = {1, 2, 3, 4}; // put things on the stack
  std::cout << "in function: file at " << f << " has fd=" << f->fd << "\n";
}
```

```
in function: file at 0x7ff7b6a7c438 has fd=-183042004
```

As a C/C++ programmer, it’s up to you to notice this and make sure that you don’t dereference a pointer that points to
something that’s gone.  Alternatively, if you’re an  attacker and you find one of these dangling pointers, you’re
more likely to  cackle maniacally and gleefully dereference the pointer on your way to an exploit.

Enter Rust.  One of Rust’s core attractions is that it fundamentally solves the problem of dangling pointers,
immediately solving a large fraction of security problems.[1](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch03.html#id1018)

Doing so requires moving the concept of lifetimes from the background (where
C/C++ programmers just have to know to
watch out for them, without any language support) to the foreground: every type that includes an ampersand `&` has
an associated lifetime (`'a`), even if the compiler lets you omit mention of it much of the time.

## Scope of a Lifetime

The lifetime of an item on the stack is the period where that item is guaranteed to stay in the same place; in other
words, this is exactly the period where a  *reference* (pointer) to the item is guaranteed not to become invalid.

This starts at the point where the item is created, and extends to where it is either *dropped* (Rust’s equivalent to object destruction in C++) or *moved*.

The ubiquity of the latter is sometimes surprising for programmers coming from
C/C++: Rust moves items from one place on
the stack to another, or from the stack to the heap, or from the heap to the stack, in lots of situations.

Precisely where an item gets automatically dropped depends on whether an item has a name or not.

Local variables and function parameters have names, and the corresponding item’s lifetime starts when the item is
created and the name is populated:

-

For a local variable: at the `let var = ...` declaration

-

For a function parameter: as part of setting up the execution frame for the function invocation

The lifetime for a named item ends when the item is either moved somewhere else or when the name goes out of
scope:

```
#[derive(Debug, Clone)]
/// Definition of an item of some kind.
pub struct Item {
    contents: u32,
}
```

```
{
    let item1 = Item { contents: 1 }; // `item1` created here
    let item2 = Item { contents: 2 }; // `item2` created here
    println!("item1 = {item1:?}, item2 = {item2:?}");
    consuming_fn(item2); // `item2` moved here
} // `item1` dropped here
```

It’s also possible to build an item “on the fly,” as part of an expression that’s then fed into something else.  These
unnamed temporary items are then dropped when they’re no longer needed.  One oversimplified but helpful way to think
about this is to imagine that each part of the expression gets expanded to its own block, with temporary variables being
inserted by the compiler.  For example, an expression like:

```
let x = f((a + b) * 2);
```

would be roughly equivalent to:

```
let x = {
    let temp1 = a + b;
    {
        let temp2 = temp1 * 2;
        f(temp2)
    } // `temp2` dropped here
}; // `temp1` dropped here
```

By the time execution reaches the semicolon at the end of the original line, the temporaries have all been dropped.

One way to see what the compiler calculates as an item’s lifetime is to insert a deliberate error for the borrow checker
([Item 15](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch03.html#file_borrows_md)) to detect.  For example, hold onto a reference to an item beyond the scope of the item’s lifetime:

#

```
let r: &Item;
{
    let item = Item { contents: 42 };
    r = &item;
}
println!("r.contents = {}", r.contents);
```

The error message indicates the exact endpoint of `item`’s lifetime:

```
error[E0597]: `item` does not live long enough
   --> src/main.rs:190:13
    |
189 |         let item = Item { contents: 42 };
    |             ---- binding `item` declared here
190 |         r = &item;
    |             ^^^^^ borrowed value does not live long enough
191 |     }
    |     - `item` dropped here while still borrowed
192 |     println!("r.contents = {}", r.contents);
    |                                 ---------- borrow later used here
```

Similarly, for an unnamed temporary:

#

```
let r: &Item = fn_returning_ref(&mut Item { contents: 42 });
println!("r.contents = {}", r.contents);
```

the error message shows the endpoint at the end of the expression:

```
error[E0716]: temporary value dropped while borrowed
   --> src/main.rs:209:46
    |
209 | let r: &Item = fn_returning_ref(&mut Item { contents: 42 });
    |                                      ^^^^^^^^^^^^^^^^^^^^^ - temporary
    |                                      |           value is freed at the
    |                                      |           end of this statement
    |                                      |
    |                                      creates a temporary value which is
    |                                      freed while still in use
210 | println!("r.contents = {}", r.contents);
    |                             ---------- borrow later used here
    |
    = note: consider using a `let` binding to create a longer lived value
```

One final point about the lifetimes of *references*: if the compiler can prove to itself that there is no use of a
reference beyond a certain point in the code, then it treats the endpoint of the reference’s lifetime as the last place
it’s used, rather than at the end of the enclosing scope.  This feature, known as  [non-lexical lifetimes](https://oreil.ly/4uJ73), allows the borrow checker to be a little bit more
generous:

```
{
    // `s` owns the `String`.
    let mut s: String = "Hello, world".to_string();

    // Create a mutable reference to the `String`.
    let greeting = &mut s[..5];
    greeting.make_ascii_uppercase();
    // .. no use of `greeting` after this point

    // Creating an immutable reference to the `String` is allowed,
    // even though there's a mutable reference still in scope.
    let r: &str = &s;
    println!("s = '{}'", r); // s = 'HELLO, world'
} // The mutable reference `greeting` would naively be dropped here.
```

## Algebra of Lifetimes

Although lifetimes are ubiquitous when dealing with references in Rust, you don’t get to specify them in any
detail—there’s no way to say, “I’m dealing with a lifetime that extends from line 17 to line 32 of
`ref.rs`.”  Instead, your code refers to lifetimes with arbitrary names, conventionally `'a`, `'b`, `'c`,
…, and the compiler has its own internal, inaccessible representation of what that equates to in the source code.
(The one exception to this is the `'static` lifetime, which is a special case that’s covered in a subsequent section.)

You don’t get to do much with these lifetime names; the main thing that’s possible is to compare one name with
another, repeating a name to indicate that two lifetimes are the “same.”

This algebra of lifetimes is easiest to illustrate with function signatures: if the inputs and outputs of a function
deal with references, what’s the relationship between their lifetimes?

The most common case is a function that receives a single reference as input and emits a reference as output.  The
output reference must have a lifetime, but what can it be?  There’s only one possibility (other than `'static`) to
choose from: the lifetime of the input, which means that they both share the same name, say, `'a`.  Adding that name as a
lifetime annotation to both types gives:

```
pub fn first<'a>(data: &'a [Item]) -> Option<&'a Item> {
    // ...
}
```

Because this variant is so common, and because there’s (almost) no choice about what the output lifetime can be, Rust
has  *lifetime elision* rules that mean you don’t have to explicitly write the lifetime names for this case.  A
more idiomatic version of the same function signature would be the following:

```
pub fn first(data: &[Item]) -> Option<&Item> {
    // ...
}
```

The references involved still have lifetimes—the elision rule just means that you don’t have to make up an
arbitrary lifetime name and use it in both places.

What if there’s more than one choice of input lifetimes to map to an output lifetime?  In this case, the compiler can’t
figure out what to do:

#

```
pub fn find(haystack: &[u8], needle: &[u8]) -> Option<&[u8]> {
    // ...
}
```

```
error[E0106]: missing lifetime specifier
   --> src/main.rs:56:55
   |
56 | pub fn find(haystack: &[u8], needle: &[u8]) -> Option<&[u8]> {
   |                       -----          -----            ^ expected named
   |                                                     lifetime parameter
   |
   = help: this function's return type contains a borrowed value, but the
           signature does not say whether it is borrowed from `haystack` or
           `needle`
help: consider introducing a named lifetime parameter
   |
56 | pub fn find<'a>(haystack: &'a [u8], needle: &'a [u8]) -> Option<&'a [u8]> {
   |            ++++            ++                ++                  ++
```

A shrewd guess based on the function and parameter names is that the intended lifetime for the output here is expected
to match the `haystack` input:

```
pub fn find<'a, 'b>(
    haystack: &'a [u8],
    needle: &'b [u8],
) -> Option<&'a [u8]> {
    // ...
}
```

Interestingly, the compiler suggested a different alternative: having both inputs to the function use the *same*
lifetime `'a`.  For example, the following is a function where this combination of lifetimes might make sense:

```
pub fn smaller<'a>(left: &'a Item, right: &'a Item) -> &'a Item {
    // ...
}
```

This *appears* to imply that the two input lifetimes are the “same,” but the scare quotes (here and previously) are included
to signify that that’s not quite what’s going on.

The raison d’être of lifetimes is to ensure that references to items don’t outlive the items themselves; with this in
mind, an output lifetime `'a` that’s the “same” as an input lifetime `'a` just means that the input has to live longer
than the output.

When there are two input lifetimes `'a` that are the “same,” that just means that the output lifetime has to be
contained within the lifetimes of *both* of the inputs:

```
{
    let outer = Item { contents: 7 };
    {
        let inner = Item { contents: 8 };
        {
            let min = smaller(&inner, &outer);
            println!("smaller of {inner:?} and {outer:?} is {min:?}");
        } // `min` dropped
    } // `inner` dropped
} // `outer` dropped
```

To put it another way, the output lifetime has to be subsumed within the *smaller* of the lifetimes of the two inputs.

In contrast, if the output lifetime is unrelated to the lifetime of one of the inputs, then there’s no requirement for
those lifetimes to nest:

```
{
    let haystack = b"123456789"; // start of  lifetime 'a
    let found = {
        let needle = b"234"; // start of lifetime 'b
        find(haystack, needle)
    }; // end of lifetime 'b
    println!("found={:?}", found); // `found` used within 'a, outside of 'b
} // end of lifetime 'a
```

## Lifetime Elision Rules

In addition to the “one in, one out” elision rule described in [“Algebra of Lifetimes”](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch03.html#algebra_lifetimes_sect), there are two other elision rules that mean that
lifetime names can be
omitted.

The first occurs when there are no references in the outputs from a function; in this case, each of the input references
automatically gets its own lifetime, different from any of the other input parameters.

The second occurs for  methods that use a reference to `self` (either `&self` or `&mut self`); in this case, the
compiler assumes that any output references take the lifetime of `self`, as this turns out to be (by far) the most
common situation.

Here’s a summary of the  elision rules for functions:

-

One input, one or more outputs: assume outputs have the “same” lifetime as the input:

`fn` `f``(``x`: `&``Item``)```-> `(``&``Item``,````&``Item``)```
`// ... is equivalent to ...`
`fn` `f``<'``a``>``(``x`: `&``'``a` `Item``)```-> `(``&'``a````Item``,````&'``a````Item``)```

-

Multiple inputs, no output: assume all the inputs have different lifetimes:

`fn` `f``(``x`: `&``Item``,````y`: `&``Item``,````z`: `&``Item``)```-> `i32`
`// ... is equivalent to ...`
`fn` `f``<'``a``,````'``b``,````'``c``>``(``x`: `&``'``a` `Item``,````y`: `&``'``b` `Item``,````z`: `&``'``c` `Item``)```-> `i32`

-

Multiple inputs including `&self`, one or more outputs: assume output lifetime(s) are the “same” as `&self`’s lifetime:

`fn` `f``(``&``self``,````y`: `&``Item``,````z`: `&``Item``)```-> `&``Thing```
`// ... is equivalent to ...`
`fn` `f``(``&'``a````self``,````y`: `&``'``b` `Item``,````z`: `&``'``c` `Item``)```-> `&``'``a` `Thing```

Of course, if the elided lifetime names don’t match what you want, you can always explicitly write lifetime names that
specify which lifetimes are related to each other.  In practice, this is likely to be triggered by a compiler error that
indicates that the elided lifetimes don’t match how the function or its caller are using the references involved.

## The `'static` Lifetime

The previous section described various possible mappings between the input and output reference lifetimes for
a function, but it neglected to cover one special case.  What happens if there are *no* input lifetimes, but the output
return value includes a reference anyway?

#

```
pub fn the_answer() -> &Item {
    // ...
}
```

```
error[E0106]: missing lifetime specifier
   --> src/main.rs:471:28
    |
471 |     pub fn the_answer() -> &Item {
    |                            ^ expected named lifetime parameter
    |
    = help: this function's return type contains a borrowed value, but there
            is no value for it to be borrowed from
help: consider using the `'static` lifetime
    |
471 |     pub fn the_answer() -> &'static Item {
    |                             +++++++
```

The only allowed possibility is for the returned reference to have a lifetime that’s guaranteed to never go out of
scope.  This is indicated by the special lifetime  `'static`, which is also the only lifetime that
has a specific name rather than an arbitrary placeholder name:

```
pub fn the_answer() -> &'static Item {
```

The simplest way to get something with the `'static` lifetime is to take a reference to a  global variable that’s
been marked as  [static](https://doc.rust-lang.org/std/keyword.static.html):

```
static ANSWER: Item = Item { contents: 42 };

pub fn the_answer() -> &'static Item {
    &ANSWER
}
```

The Rust compiler guarantees that a `static` item always has the same address for the entire duration of the program
and never moves.  This means that a reference to a `static` item has a `'static` lifetime, logically enough.

In many cases, a reference to a `const` item will also be
[promoted](https://doc.rust-lang.org/reference/destructors.html#constant-promotion) to have a `'static` lifetime, but
there are a couple of minor complications to be aware of. The first is that this promotion doesn’t happen if the type
involved has a destructor or interior
mutability:

#

```
pub struct Wrapper(pub i32);

impl Drop for Wrapper {
    fn drop(&mut self) {}
}

const ANSWER: Wrapper = Wrapper(42);

pub fn the_answer() -> &'static Wrapper {
    // `Wrapper` has a destructor, so the promotion to the `'static`
    // lifetime for a reference to a constant does not apply.
    &ANSWER
}
```

```
error[E0515]: cannot return reference to temporary value
   --> src/main.rs:520:9
    |
520 |         &ANSWER
    |         ^------
    |         ||
    |         |temporary value created here
    |         returns a reference to data owned by the current function
```

The second potential complication is that only the *value* of a `const` is guaranteed to be the same everywhere; the
compiler is allowed to make as many copies as it likes, wherever the variable is used. If you’re doing nefarious things
that rely on the underlying pointer value behind the `'static` reference, be aware that multiple memory
locations may be involved.

There’s one more possible way to get something with a `'static` lifetime.  The key promise of `'static` is that the
lifetime should outlive any other lifetime in the program; a value that’s allocated on the  heap but *never freed*
also satisfies this constraint.

A normal heap-allocated `Box<T>` doesn’t work for this, because there’s no guarantee (as described in the next section)
that the item won’t get dropped along the way:

#

```json
{
    let boxed = Box::new(Item { contents: 12 });
    let r: &'static Item = &boxed;
    println!("'static item is {:?}", r);
}
```

```
error[E0597]: `boxed` does not live long enough
   --> src/main.rs:344:32
    |
343 |     let boxed = Box::new(Item { contents: 12 });
    |         ----- binding `boxed` declared here
344 |     let r: &'static Item = &boxed;
    |            -------------   ^^^^^^ borrowed value does not live long enough
    |            |
    |            type annotation requires that `boxed` is borrowed for `'static`
345 |     println!("'static item is {:?}", r);
346 | }
    | - `boxed` dropped here while still borrowed
```

However, the  [Box::leak](https://doc.rust-lang.org/std/boxed/struct.Box.html#method.leak) function
converts an owned `Box<T>` to a mutable reference to `T`.  There’s no longer an owner for the value, so it can never be
dropped—which satisfies the requirements for the `'static` lifetime:

```
{
    let boxed = Box::new(Item { contents: 12 });

    // `leak()` consumes the `Box<T>` and returns `&mut T`.
    let r: &'static Item = Box::leak(boxed);

    println!("'static item is {:?}", r);
} // `boxed` not dropped here, as it was already moved into `Box::leak()`

// Because `r` is now out of scope, the `Item` is leaked forever.
```

The inability to drop the item also means that the memory that holds the item can never be reclaimed using safe Rust,
possibly leading to a permanent memory leak. (Note that leaking memory doesn’t violate Rust’s memory safety
guarantees—an item in memory that you can no longer access is still safe.)

## Lifetimes and the Heap

The discussion so far has concentrated on the lifetimes of items on the stack, whether function parameters, local
variables, or temporaries. But what about items on the  heap?

The key thing to realize about heap values is that every item has an owner (excepting special cases like the deliberate
leaks described in the previous section).  For example, a simple `Box<T>` puts the `T` value on the heap, with the owner
being the variable holding the `Box<T>`:

```
{
    let b: Box<Item> = Box::new(Item { contents: 42 });
} // `b` dropped here, so `Item` dropped too.
```

The owning `Box<Item>` drops its contents when it goes out of scope, so the lifetime of the `Item` on the heap is the
same as the lifetime of the `Box<Item>` variable on the stack.

The owner of a value on the heap may itself be on the heap rather than the stack, but then who owns the owner?

```
{
    let b: Box<Item> = Box::new(Item { contents: 42 });
    let bb: Box<Box<Item>> = Box::new(b); // `b` moved onto heap here
} // `bb` dropped here, so `Box<Item>` dropped too, so `Item` dropped too.
```

The chain of ownership has to end somewhere, and there are only two possibilities:

-

The chain ends at a local variable or function parameter—in which case the lifetime of everything in the chain
is just the lifetime `'a` of that stack variable.  When the stack variable goes out of scope, everything in the chain
is dropped too.

-

The chain ends at a global variable marked as `static`—in which case the lifetime of everything in the chain
is `'static`.  The `static` variable never goes out of scope, so nothing in the chain ever gets automatically dropped.

As a result, the lifetimes of items on the heap are fundamentally tied to stack
lifetimes.

## Lifetimes in Data Structures

The earlier section on the algebra of lifetimes concentrated on inputs and outputs for functions, but there are similar
concerns when references are stored in data
structures.

If we try to sneak a reference into a data structure without mentioning an associated lifetime, the compiler brings us
up sharply:

#

```
pub struct ReferenceHolder {
    pub index: usize,
    pub item: &Item,
}
```

```
error[E0106]: missing lifetime specifier
   --> src/main.rs:548:19
    |
548 |         pub item: &Item,
    |                   ^ expected named lifetime parameter
    |
help: consider introducing a named lifetime parameter
    |
546 ~     pub struct ReferenceHolder<'a> {
547 |         pub index: usize,
548 ~         pub item: &'a Item,
    |
```

As usual, the compiler error message tells us what to do. The first part is simple enough: give the reference type an
explicit lifetime name `'a`, because there are no lifetime elision rules when using references in data structures.

The second part is less obvious and has deeper consequences: the data structure itself has to have a
lifetime parameter `<'a>` that matches the lifetime of the reference contained within it:

```
// Lifetime parameter required due to field with reference.
pub struct ReferenceHolder<'a> {
    pub index: usize,
    pub item: &'a Item,
}
```

The lifetime parameter for the data structure is infectious: any containing data structure that uses the type also has
to acquire a lifetime parameter:

```
// Lifetime parameter required due to field that is of a
// type that has a lifetime parameter.
pub struct RefHolderHolder<'a> {
    pub inner: ReferenceHolder<'a>,
}
```

The need for a lifetime parameter also applies if the data structure contains slice types, as these are again references
to borrowed data.

If a data structure contains multiple fields that have associated lifetimes, then you have to choose what combination of
lifetimes is appropriate.  An example that finds common substrings within a pair of strings is a good candidate to have
independent lifetimes:

```
/// Locations of a substring that is present in
/// both of a pair of strings.
pub struct LargestCommonSubstring<'a, 'b> {
    pub left: &'a str,
    pub right: &'b str,
}

/// Find the largest substring present in both `left`
/// and `right`.
pub fn find_common<'a, 'b>(
    left: &'a str,
    right: &'b str,
) -> Option<LargestCommonSubstring<'a, 'b>> {
    // ...
}
```

whereas a data structure that references multiple places within the same string would have a common lifetime:

```
/// First two instances of a substring that is repeated
/// within a string.
pub struct RepeatedSubstring<'a> {
    pub first: &'a str,
    pub second: &'a str,
}

/// Find the first repeated substring present in `s`.
pub fn find_repeat<'a>(s: &'a str) -> Option<RepeatedSubstring<'a>> {
    // ...
}
```

The propagation of lifetime parameters makes sense: anything that contains a reference, no matter how deeply nested, is
valid only for the lifetime of the item referred to. If that item is moved or dropped, then the whole chain of data
structures is no longer valid.

However, this also means that data structures involving references are harder to use—the owner of the data
structure has to ensure that the lifetimes all line up.  As a result, *prefer data structures that own their
contents* where possible, particularly if the code doesn’t need to be highly optimized ([Item 20](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch03.html#file_optimize_md)).  Where that’s not
possible, the various smart pointer types (e.g., [Rc](https://doc.rust-lang.org/std/rc/struct.Rc.html))
described in [Item 8](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch01.html#file_references_md) can help untangle the lifetime
constraints.

## Anonymous Lifetimes

When it’s not possible to stick to data structures that own their contents, the data structure will necessarily end up
with a lifetime parameter, as described in the previous section.  This can create a slightly unfortunate interaction with
the lifetime elision rules described earlier in the Item.

For example, consider a function that returns a data structure with a lifetime parameter.  The fully explicit signature
for this function makes the lifetimes involved clear:

```
pub fn find_one_item<'a>(items: &'a [Item]) -> ReferenceHolder<'a> {
    // ...
}
```

However, the same signature with lifetimes elided can be a little misleading:

```
pub fn find_one_item(items: &[Item]) -> ReferenceHolder {
    // ...
}
```

Because the lifetime parameter for the return type is elided, a human reading the code doesn’t get much of a hint that
lifetimes are involved.

The  anonymous lifetime `'_` allows you to mark an elided lifetime as being present, without having to fully
restore *all* of the lifetime names:

```
pub fn find_one_item(items: &[Item]) -> ReferenceHolder<'_> {
    // ...
}
```

Roughly speaking, the `'_` marker asks the compiler to invent a unique lifetime name for us, which we can use in
situations where we never need to use the name elsewhere.

That means it’s also useful for other lifetime elision scenarios.  For example, the declaration for the
[fmt](https://doc.rust-lang.org/std/fmt/trait.Debug.html#tymethod.fmt) method of the
[Debug](https://doc.rust-lang.org/std/fmt/trait.Debug.html) trait uses the anonymous lifetime to indicate that
the `Formatter` instance has a different lifetime than `&self`, but it’s not important what that lifetime’s name is:

```
pub trait Debug {
    fn fmt(&self, f: &mut Formatter<'_>) -> Result<(), Error>;
}
```

## Things to Remember

-

All Rust references have an associated lifetime, indicated by a lifetime label (e.g., `'a`). The lifetime labels for function parameters and return values can be elided in some common cases (but are still
present under the covers).

-

Any data structure that (transitively) includes a reference has an associated lifetime parameter; as a result, it’s
often easier to work with data structures that own their contents.

-

The `'static` lifetime is used for references to items that are guaranteed never to go out of scope, such as global data
or items on the heap that have been explicitly leaked.

-

Lifetime labels can be used only to indicate that lifetimes are the “same,” which means that the output lifetime is
contained within the input lifetime(s).

-

The anonymous lifetime label `'_` can be used in places where a specific lifetime label is not needed.

# Item 15: Understand the borrow checker

Values in Rust have an owner, but that owner can lend the values out to other places in the code. This *borrowing*
mechanism involves the creation and use of  *references*, subject to rules policed by the  *borrow
checker*—the subject of this Item.

Under the covers, Rust’s references use the same kind of *pointer* values ([Item 8](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch01.html#file_references_md)) that are so prevalent in  C
or  C++ code but are girded with rules and restrictions to make sure that the sins of C/C++ are avoided. As a quick
comparison:

-

Like a C/C++ pointer, a Rust reference is created with an ampersand: `&value`.

-

Like a C++ reference, a Rust reference can never be  `nullptr`.

-

Like a C/C++ pointer or reference, a Rust reference can be modified after creation to refer to something different.

-

Unlike C++, producing a reference from a value always involves an explicit (`&`) conversion—if you see
code like `f(value)`, you know that `f` is receiving ownership of the value.  (However, it may be ownership of a
*copy* of the item, if the `value`’s type implements
[Copy](https://doc.rust-lang.org/std/marker/trait.Copy.html)—see [Item 10](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch02.html#file_std-traits_md).)

-

Unlike C/C++, the mutability of a newly created reference is always explicit (`&mut`).  If you see code like
`f(&value)`, you know that `value` won’t be modified (i.e., is `const` in C/C++ terminology).  Only
expressions like `f(&mut value)` have the potential to change the contents
of `value`.[2](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch03.html#id1082)

The most important difference between a C/C++ pointer and a Rust reference is indicated by the term  *borrow*: you
can take a reference (pointer) to an item, *but you can’t keep that reference forever*.  In particular, you can’t keep
it longer than the lifetime of the underlying item, as tracked by the compiler and explored in [Item 14](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch03.html#file_lifetimes_md).

These restrictions on the use of references enable Rust to make its memory safety guarantees, but they also mean that you have
to accept the cognitive costs of the borrow rules, and accept that it will change how you design your
software—particularly its data structures.

This Item starts by describing what Rust references can do, and the borrow checker’s rules for using them.  The rest of
the Item focuses on dealing with the consequences of those rules: how to refactor, rework, and redesign your code so
that you can win fights against the borrow checker.

## Access Control

There are three ways to access the contents of a Rust item: via the item’s *owner* (`item`), a *reference*
(`&item`), or a *mutable reference* (`&mut item`). Each of these ways of accessing the item comes with different powers over the item.  Putting things roughly in
terms of the  [CRUD](https://en.wikipedia.org/wiki/Create,_read,_update_and_delete) (create/read/update/delete)
model for storage (using Rust’s *drop* terminology in place of *delete*):

-

The owner of an item gets to *create* it, *read* from it, *update* it, and *drop* it.

-

A mutable reference can be used to *read* from the underlying item and *update* it.

-

A (normal) reference can be used only to *read* from the underlying item.

There’s an important Rust-specific aspect to these data access rules: only the item’s owner can  *move* the item.  This makes sense if you think of a move as being some combination of *creating* (in the
new location) and *dropping* the item’s memory (at the old location).

This can lead to some oddities for code that has a mutable reference to an item.  For example, it’s OK to overwrite an
`Option`:

```
/// Some data structure used by the code.
#[derive(Debug)]
pub struct Item {
    pub contents: i64,
}

/// Replace the content of `item` with `val`.
pub fn replace(item: &mut Option<Item>, val: Item) {
    *item = Some(val);
}
```

but a modification to also return the previous value falls foul of the move restriction:[3](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch03.html#id1093)

#

```
/// Replace the content of `item` with `val`, returning the previous
/// contents.
pub fn replace(item: &mut Option<Item>, val: Item) -> Option<Item> {
    let previous = *item; // move out
    *item = Some(val); // replace
    previous
}
```

```
error[E0507]: cannot move out of `*item` which is behind a mutable reference
  --> src/main.rs:34:24
   |
34 |         let previous = *item; // move out
   |                        ^^^^^ move occurs because `*item` has type
   |                              `Option<inner::Item>`, which does not
   |                              implement the `Copy` trait
   |
help: consider removing the dereference here
   |
34 -         let previous = *item; // move out
34 +         let previous = item; // move out
   |
```

Although it’s valid to *read* from a mutable reference, this code is attempting to *move* the value out, just prior to
replacing the moved value with a new value—in an attempt to avoid making a copy of the original value.  The
borrow checker has to be conservative and notices that there’s a moment between the two lines when the mutable
reference isn’t referring to a valid value.

As humans, we can see that this combined operation—extracting the old value and replacing it with a new
value—is both safe and useful, so the standard library provides the
[std::mem::replace](https://doc.rust-lang.org/std/mem/fn.replace.html) function to perform it.  Under
the covers, `replace` uses  `unsafe` (as per [Item 16](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch03.html#file_unsafe_md)) to perform the swap in one go:

```
/// Replace the content of `item` with `val`, returning the previous
/// contents.
pub fn replace(item: &mut Option<Item>, val: Item) -> Option<Item> {
    std::mem::replace(item, Some(val)) // returns previous value
}
```

For  `Option` types in particular, this is a sufficiently common pattern that there is also a
[replace](https://doc.rust-lang.org/std/option/enum.Option.html#method.replace) method on `Option` itself:

```
/// Replace the content of `item` with `val`, returning the previous
/// contents.
pub fn replace(item: &mut Option<Item>, val: Item) -> Option<Item> {
    item.replace(val) // returns previous value
}
```

## Borrow Rules

There are two key rules to remember when borrowing references in Rust.

The first rule is that the scope of any reference must be smaller than the lifetime of the item that it refers
to. Lifetimes are explored in detail in [Item 14](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch03.html#file_lifetimes_md), but it’s worth noting that the compiler has special behavior for
reference lifetimes; the  *non-lexical lifetimes* feature allows reference lifetimes to be shrunk so they end
at the point of last use, rather than the enclosing block.

The second rule for borrowing references is that, in addition to the owner of an item, there can be either of the following:

-

Any number of immutable references to the item

-

A single mutable reference to the item

However, there can’t be both (at the same point in the code).

So a function that takes multiple immutable references can be fed references to the same item:

```
/// Indicate whether both arguments are zero.
fn both_zero(left: &Item, right: &Item) -> bool {
    left.contents == 0 && right.contents == 0
}

let item = Item { contents: 0 };
assert!(both_zero(&item, &item));
```

but one that takes *mutable* references cannot:

#

```
/// Zero out the contents of both arguments.
fn zero_both(left: &mut Item, right: &mut Item) {
    left.contents = 0;
    right.contents = 0;
}

let mut item = Item { contents: 42 };
zero_both(&mut item, &mut item);
```

```
error[E0499]: cannot borrow `item` as mutable more than once at a time
   --> src/main.rs:131:26
    |
131 |     zero_both(&mut item, &mut item);
    |     --------- ---------  ^^^^^^^^^ second mutable borrow occurs here
    |     |         |
    |     |         first mutable borrow occurs here
    |     first borrow later used by call
```

The same restriction is true for a function that uses a mixture of mutable and immutable references:

#

```
/// Set the contents of `left` to the contents of `right`.
fn copy_contents(left: &mut Item, right: &Item) {
    left.contents = right.contents;
}

let mut item = Item { contents: 42 };
copy_contents(&mut item, &item);
```

```
error[E0502]: cannot borrow `item` as immutable because it is also borrowed
              as mutable
   --> src/main.rs:159:30
    |
159 |     copy_contents(&mut item, &item);
    |     ------------- ---------  ^^^^^ immutable borrow occurs here
    |     |             |
    |     |             mutable borrow occurs here
    |     mutable borrow later used by call
```

The borrowing rules allow the compiler to make better decisions around
[aliasing](https://en.wikipedia.org/wiki/Aliasing_(computing)): tracking when two different pointers
may or may not refer to the same underlying item in memory.  If the compiler can be sure (as in Rust) that the memory
location pointed to by a collection of immutable references cannot be altered via an aliased *mutable* reference, then
it can generate code that has the following advantages:

It’s better optimizedValues can be, for example, cached in registers, secure in the knowledge that the underlying memory
contents will not change in the meantime.

It’s saferData races arising from unsynchronized access to memory between threads ([Item 17](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch03.html#file_deadlock_md)) are not possible.

## Owner Operations

One important consequence of the rules around the existence of references is that they also affect what operations can
be performed by the owner of the item.  One way to help understand this is to imagine that operations involving the
owner are performed by creating and using references under the covers.

For example, an attempt to update the item via its owner is equivalent to making an ephemeral mutable reference and then
updating the item via that reference.  If another reference already exists, this notional second mutable reference can’t
be
created:

#

```
let mut item = Item { contents: 42 };
let r = &item;
item.contents = 0;
// ^^^ Changing the item is roughly equivalent to:
//   (&mut item).contents = 0;
println!("reference to item is {:?}", r);
```

```
error[E0506]: cannot assign to `item.contents` because it is borrowed
   --> src/main.rs:200:5
    |
199 |     let r = &item;
    |             ----- `item.contents` is borrowed here
200 |     item.contents = 0;
    |     ^^^^^^^^^^^^^^^^^ `item.contents` is assigned to here but it was
    |                       already borrowed
...
203 |     println!("reference to item is {:?}", r);
    |                                           - borrow later used here
```

On the other hand, because multiple *immutable* references are allowed, it’s OK for the owner to read from the item
while there are immutable references in existence:

```
let item = Item { contents: 42 };
let r = &item;
let contents = item.contents;
// ^^^ Reading from the item is roughly equivalent to:
//   let contents = (&item).contents;
println!("reference to item is {:?}", r);
```

but not if there is a *mutable* reference:

#

```
let mut item = Item { contents: 42 };
let r = &mut item;
let contents = item.contents; // i64 implements `Copy`
r.contents = 0;
```

```
error[E0503]: cannot use `item.contents` because it was mutably borrowed
   --> src/main.rs:231:20
    |
230 |     let r = &mut item;
    |             --------- `item` is borrowed here
231 |     let contents = item.contents; // i64 implements `Copy`
    |                    ^^^^^^^^^^^^^ use of borrowed `item`
232 |     r.contents = 0;
    |     -------------- borrow later used here
```

Finally, the existence of any sort of active reference prevents the owner of the item from moving or
dropping the item, exactly because this would mean that the reference now refers to an invalid item:

#

```
let item = Item { contents: 42 };
let r = &item;
let new_item = item; // move
println!("reference to item is {:?}", r);
```

```
error[E0505]: cannot move out of `item` because it is borrowed
   --> src/main.rs:170:20
    |
168 |     let item = Item { contents: 42 };
    |         ---- binding `item` declared here
169 |     let r = &item;
    |             ----- borrow of `item` occurs here
170 |     let new_item = item; // move
    |                    ^^^^ move out of `item` occurs here
171 |     println!("reference to item is {:?}", r);
    |                                           - borrow later used here
```

This is a scenario where the non-lexical lifetime feature described in [Item 14](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch03.html#file_lifetimes_md) is particularly helpful, because
(roughly speaking) it terminates the lifetime of a reference at the point where the reference is last used, rather than
at the end of the enclosing scope.  Moving the final use of the reference up before the move happens means that the
compilation error evaporates:

```
let item = Item { contents: 42 };
let r = &item;
println!("reference to item is {:?}", r);

// Reference `r` is still in scope but has no further use, so it's
// as if the reference has already been dropped.
let new_item = item; // move works OK
```

## Winning Fights Against the Borrow Checker

Newcomers to Rust (and even more experienced folk!) can often feel that they are spending time fighting against the
borrow checker. What kinds of things can help you win these battles?

### Local code refactoring

The first tactic is to pay attention to the compiler’s error messages, because the Rust developers have put a lot of
effort into making them as helpful as possible:

#

```
/// If `needle` is present in `haystack`, return a slice containing it.
pub fn find<'a, 'b>(haystack: &'a str, needle: &'b str) -> Option<&'a str> {
    haystack
        .find(needle)
        .map(|i| &haystack[i..i + needle.len()])
}
// ...

let found = find(&format!("{} to search", "Text"), "ex");
if let Some(text) = found {
    println!("Found '{text}'!");
}
```

```
error[E0716]: temporary value dropped while borrowed
   --> src/main.rs:353:23
    |
353 | let found = find(&format!("{} to search", "Text"), "ex");
    |                   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^       - temporary value
    |                   |                 is freed at the end of this statement
    |                   |
    |                   creates a temporary value which is freed while still in
    |                   use
354 | if let Some(text) = found {
    |                     ----- borrow later used here
    |
    = note: consider using a `let` binding to create a longer lived value
```

The first part of the error message is the important part, because it describes what borrowing rule the compiler thinks
you have broken and why.  As you encounter enough of these errors—which you will—you can build up an
intuition about the borrow checker that matches the more theoretical version encapsulated in the previously stated rules.

The second part of the error message includes the compiler’s suggestions for how to fix the problem, which in this
case is simple:

```
let haystack = format!("{} to search", "Text");
let found = find(&haystack, "ex");
if let Some(text) = found {
    println!("Found '{text}'!");
}
// `found` now references `haystack`, which outlives it
```

This is an instance of one of the two simple code tweaks that can help mollify the borrow checker:

Lifetime extensionConvert a temporary (whose lifetime extends only to the end of the expression) into a new named
local variable (whose lifetime extends to the end of the block) with a  `let` binding.

Lifetime reductionAdd an additional block `{ ... }` around the use of a reference so that its lifetime ends at the
end of the new block.

The latter is less common, because of the existence of  non-lexical lifetimes: the compiler can often figure out
that a reference is no longer used, ahead of its official drop point at the end of the block. However, if you do find
yourself repeatedly introducing an artificial block around similar small chunks of code, consider whether that code
should be encapsulated into a method of its own.

The compiler’s suggested fixes are helpful for simpler problems, but as you write more sophisticated code, you’re likely
to find that the suggestions are no longer useful and that the explanation of the broken borrowing rule is harder to
follow:

#

```
let x = Some(Rc::new(RefCell::new(Item { contents: 42 })));

// Call function with signature: `check_item(item: Option<&Item>)`
check_item(x.as_ref().map(|r| r.borrow().deref()));
```

```
error[E0515]: cannot return reference to temporary value
   --> src/main.rs:293:35
    |
293 |     check_item(x.as_ref().map(|r| r.borrow().deref()));
    |                                   ----------^^^^^^^^
    |                                   |
    |                                   returns a reference to data owned by the
    |                                       current function
    |                                   temporary value created here
```

In this situation, it can be helpful to temporarily introduce a sequence of local variables, one for each step of a
complicated transformation, and each with an explicit type annotation:

#

```
let x: Option<Rc<RefCell<Item>>> =
    Some(Rc::new(RefCell::new(Item { contents: 42 })));

let x1: Option<&Rc<RefCell<Item>>> = x.as_ref();
let x2: Option<std::cell::Ref<Item>> = x1.map(|r| r.borrow());
let x3: Option<&Item> = x2.map(|r| r.deref());
check_item(x3);
```

```
error[E0515]: cannot return reference to function parameter `r`
   --> src/main.rs:305:40
    |
305 |     let x3: Option<&Item> = x2.map(|r| r.deref());
    |                                        ^^^^^^^^^ returns a reference to
    |                                      data owned by the current function
```

This narrows down the precise conversion that the compiler is complaining about, which in turn allows the code to be
restructured:

```
let x: Option<Rc<RefCell<Item>>> =
    Some(Rc::new(RefCell::new(Item { contents: 42 })));

let x1: Option<&Rc<RefCell<Item>>> = x.as_ref();
let x2: Option<std::cell::Ref<Item>> = x1.map(|r| r.borrow());
match x2 {
    None => check_item(None),
    Some(r) => {
        let x3: &Item = r.deref();
        check_item(Some(x3));
    }
}
```

Once the underlying problem is clear and has been fixed, you’re then free to recoalesce the local variables back
together so that you can pretend you got it right all along:

```
let x = Some(Rc::new(RefCell::new(Item { contents: 42 })));

match x.as_ref().map(|r| r.borrow()) {
    None => check_item(None),
    Some(r) => check_item(Some(r.deref())),
};
```

### Data structure design

The next tactic that helps for battles against the borrow checker is to design your data structures with the borrow
checker in mind.  The panacea is your data structures owning all of the data that they use, avoiding any use of
references and the consequent propagation of  lifetime annotations described in [Item 14](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch03.html#file_lifetimes_md).

However, that’s not always possible for real-world data structures; any time the internal connections of the data
structure form a graph that’s more interconnected than a tree pattern (a `Root` that owns multiple `Branch`es, each of
which owns multiple `Leaf`s, etc.), then simple single-ownership isn’t possible.

To take a simple example, imagine a simple register of guest details recorded in the order in which they arrive:

```
#[derive(Clone, Debug)]
pub struct Guest {
    name: String,
    address: String,
    // ... many other fields
}

/// Local error type, used later.
#[derive(Clone, Debug)]
pub struct Error(String);

/// Register of guests recorded in order of arrival.
#[derive(Default, Debug)]
pub struct GuestRegister(Vec<Guest>);

impl GuestRegister {
    pub fn register(&mut self, guest: Guest) {
        self.0.push(guest)
    }
    pub fn nth(&self, idx: usize) -> Option<&Guest> {
        self.0.get(idx)
    }
}
```

If this code *also* needs to be able to efficiently look up guests by arrival and alphabetically by name, then there are
fundamentally two distinct data structures involved, and only one of them can own the data.

If the data involved is both small and immutable, then just cloning the data can be a quick solution:

```
mod cloned {
    use super::Guest;

    #[derive(Default, Debug)]
    pub struct GuestRegister {
        by_arrival: Vec<Guest>,
        by_name: std::collections::BTreeMap<String, Guest>,
    }

    impl GuestRegister {
        pub fn register(&mut self, guest: Guest) {
            // Requires `Guest` to be `Clone`
            self.by_arrival.push(guest.clone());
            // Not checking for duplicate names to keep this
            // example shorter.
            self.by_name.insert(guest.name.clone(), guest);
        }
        pub fn named(&self, name: &str) -> Option<&Guest> {
            self.by_name.get(name)
        }
        pub fn nth(&self, idx: usize) -> Option<&Guest> {
            self.by_arrival.get(idx)
        }
    }
}
```

However, this approach of cloning copes poorly if the data can be modified. For example, if the address for a `Guest`
needs to be updated, you have to find both versions and ensure they stay in sync.

Another possible approach is to add another layer of indirection, treating the `Vec<Guest>` as the owner and using an
index into that vector for the name lookups:

```
mod indexed {
    use super::Guest;

    #[derive(Default)]
    pub struct GuestRegister {
        by_arrival: Vec<Guest>,
        // Map from guest name to index into `by_arrival`.
        by_name: std::collections::BTreeMap<String, usize>,
    }

    impl GuestRegister {
        pub fn register(&mut self, guest: Guest) {
            // Not checking for duplicate names to keep this
            // example shorter.
            self.by_name
                .insert(guest.name.clone(), self.by_arrival.len());
            self.by_arrival.push(guest);
        }
        pub fn named(&self, name: &str) -> Option<&Guest> {
            let idx = *self.by_name.get(name)?;
            self.nth(idx)
        }
        pub fn named_mut(&mut self, name: &str) -> Option<&mut Guest> {
            let idx = *self.by_name.get(name)?;
            self.nth_mut(idx)
        }
        pub fn nth(&self, idx: usize) -> Option<&Guest> {
            self.by_arrival.get(idx)
        }
        pub fn nth_mut(&mut self, idx: usize) -> Option<&mut Guest> {
            self.by_arrival.get_mut(idx)
        }
    }
}
```

In this approach, each guest is represented by a single `Guest` item, which allows the `named_mut()` method to return a
mutable reference to that item.  That in turn means that changing a guest’s address works fine—the (single)
`Guest` is owned by the `Vec` and will always be reached that way under the covers:

```
let new_address = "123 Bigger House St";
// Real code wouldn't assume that "Bob" exists...
ledger.named_mut("Bob").unwrap().address = new_address.to_string();

assert_eq!(ledger.named("Bob").unwrap().address, new_address);
```

However, if guests can deregister, it’s easy to inadvertently introduce a bug:

#

```
// Deregister the `Guest` at position `idx`, moving up all
// subsequent guests.
pub fn deregister(&mut self, idx: usize) -> Result<(), super::Error> {
    if idx >= self.by_arrival.len() {
        return Err(super::Error::new("out of bounds"));
    }
    self.by_arrival.remove(idx);

    // Oops, forgot to update `by_name`.

    Ok(())
}
```

Now that the `Vec` can be shuffled, the `by_name` indexes into it are effectively acting like pointers, and we’ve
reintroduced a world where a bug can lead those “pointers” to point to nothing (beyond the `Vec` bounds) or to point to
incorrect data:

#

```
ledger.register(alice);
ledger.register(bob);
ledger.register(charlie);
println!("Register starts as: {ledger:?}");

ledger.deregister(0).unwrap();
println!("Register after deregister(0): {ledger:?}");

let also_alice = ledger.named("Alice");
// Alice still has index 0, which is now Bob
println!("Alice is {also_alice:?}");

let also_bob = ledger.named("Bob");
// Bob still has index 1, which is now Charlie
println!("Bob is {also_bob:?}");

let also_charlie = ledger.named("Charlie");
// Charlie still has index 2, which is now beyond the Vec
println!("Charlie is {also_charlie:?}");
```

The code here uses a custom `Debug` implementation (not shown), in order to reduce the size of the output; this
truncated output is as follows:

```
Register starts as: {
  by_arrival: [{n: 'Alice', ...}, {n: 'Bob', ...}, {n: 'Charlie', ...}]
  by_name: {"Alice": 0, "Bob": 1, "Charlie": 2}
}
Register after deregister(0): {
  by_arrival: [{n: 'Bob', ...}, {n: 'Charlie', ...}]
  by_name: {"Alice": 0, "Bob": 1, "Charlie": 2}
}
Alice is Some(Guest { name: "Bob", address: "234 Bobton" })
Bob is Some(Guest { name: "Charlie", address: "345 Charlieland" })
Charlie is None
```

The preceding example showed a bug in the `deregister` code, but even after that bug is fixed, there’s nothing to prevent a
caller from hanging onto an index value and using it with `nth()`—getting unexpected or invalid results.

The core problem is that the two data structures need to be kept in sync.  A better approach for handling this is to use
Rust’s smart pointers instead ([Item 8](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch01.html#file_references_md)).  Shifting to a combination of
[Rc](https://doc.rust-lang.org/std/rc/struct.Rc.html) and
[RefCell](https://doc.rust-lang.org/std/cell/struct.RefCell.html) avoids the invalidation problems of using indices as
pseudo-pointers.  Updating the example—but keeping the bug in it—gives the
following:

#

```
mod rc {
    use super::{Error, Guest};
    use std::{cell::RefCell, rc::Rc};

    #[derive(Default)]
    pub struct GuestRegister {
        by_arrival: Vec<Rc<RefCell<Guest>>>,
        by_name: std::collections::BTreeMap<String, Rc<RefCell<Guest>>>,
    }

    impl GuestRegister {
        pub fn register(&mut self, guest: Guest) {
            let name = guest.name.clone();
            let guest = Rc::new(RefCell::new(guest));
            self.by_arrival.push(guest.clone());
            self.by_name.insert(name, guest);
        }
        pub fn deregister(&mut self, idx: usize) -> Result<(), Error> {
            if idx >= self.by_arrival.len() {
                return Err(Error::new("out of bounds"));
            }
            self.by_arrival.remove(idx);

            // Oops, still forgot to update `by_name`.

            Ok(())
        }
        // ...
    }
}
```

```
Register starts as: {
  by_arrival: [{n: 'Alice', ...}, {n: 'Bob', ...}, {n: 'Charlie', ...}]
  by_name: [("Alice", {n: 'Alice', ...}), ("Bob", {n: 'Bob', ...}),
            ("Charlie", {n: 'Charlie', ...})]
}
Register after deregister(0): {
  by_arrival: [{n: 'Bob', ...}, {n: 'Charlie', ...}]
  by_name: [("Alice", {n: 'Alice', ...}), ("Bob", {n: 'Bob', ...}),
            ("Charlie", {n: 'Charlie', ...})]
}
Alice is Some(RefCell { value: Guest { name: "Alice",
                                       address: "123 Aliceville" } })
Bob is Some(RefCell { value: Guest { name: "Bob",
                                     address: "234 Bobton" } })
Charlie is Some(RefCell { value: Guest { name: "Charlie",
                                         address: "345 Charlieland" } })
```

The output no longer has mismatched names, but a lingering entry for Alice remains until we fix the bug by
ensuring that the two collections stay in sync:

```
pub fn deregister(&mut self, idx: usize) -> Result<(), Error> {
    if idx >= self.by_arrival.len() {
        return Err(Error::new("out of bounds"));
    }
    let guest: Rc<RefCell<Guest>> = self.by_arrival.remove(idx);
    self.by_name.remove(&guest.borrow().name);
    Ok(())
}
```

```
Register after deregister(0): {
  by_arrival: [{n: 'Bob', ...}, {n: 'Charlie', ...}]
  by_name: [("Bob", {n: 'Bob', ...}), ("Charlie", {n: 'Charlie', ...})]
}
Alice is None
Bob is Some(RefCell { value: Guest { name: "Bob",
                                     address: "234 Bobton" } })
Charlie is Some(RefCell { value: Guest { name: "Charlie",
                                         address: "345 Charlieland" } })
```

### Smart pointers

The final variation of the previous section is an example of a more general approach: *use Rust’s smart
pointers for interconnected data structures*.

[Item 8](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch01.html#file_references_md) described the most common smart pointer types provided by Rust’s standard library:

-

`Rc` allows shared ownership, with multiple things referring to the same item. `Rc` is often combined with `RefCell`.

-

`RefCell` allows interior mutability so that internal state can be modified without needing a mutable
reference.  This comes at the cost of moving borrow checks from compile time to runtime.

-

`Arc` is the multithreading equivalent to `Rc`.

-

`Mutex` (and  `RwLock`) allows interior mutability in a multithreading environment, roughly equivalent to
`RefCell`.

-

`Cell` allows interior mutability for `Copy` types.

For programmers who are adapting from C++ to Rust, the most common tool to reach for is `Rc<T>` (and its
thread-safe cousin `Arc<T>`), often combined with `RefCell` (or the thread-safe alternative `Mutex`).  A naive
translation of shared pointers (or even  [std::shared_ptr](https://en.cppreference.com/w/cpp/memory/shared_ptr)s) to `Rc<RefCell<T>>` instances will
generally give something that works in Rust without too much complaint from the borrow checker.

However, this approach means that you miss out on some of the protections that Rust gives you.  In particular,
situations where the same item is mutably borrowed (via
[borrow_mut()](https://doc.rust-lang.org/std/cell/struct.RefCell.html#method.borrow_mut)) while another reference
exists result in a runtime  `panic!` rather than a compile-time error.

For example, one pattern that breaks the one-way flow of ownership in tree-like data structures is when there’s an
“owner” pointer back from an item to the thing that owns it, as shown in [Figure 3-3](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch03.html#fig_3_3).  These `owner` links are useful
for moving around the data structure; for example, adding a new sibling to a `Leaf` needs to involve the owning
`Branch`.

![Representation of a tree data structure. At the top left is a rectangle representing a Tree struct. It has boxes for the id and branches fields, an arrow leads from the branches field to a stack of rectangles representing the Branch struct. The Branch struct has 3 boxes for fields: id, leaves and owner.  The owner field has an arrow that points back to the Tree struct in the top left.  The leaves field has an arrow that leads to a stack of rectangles representing the Leaf struct in the bottom right.  The Leaf struct has id and owner fields, and the owner field has an arrow pointing back to the Branch struct.](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781098151393/files/assets/efru_0303.png)

###### Figure 3-3. Tree data structure layout

Implementing this pattern in Rust can make use of `Rc<T>`’s more tentative partner,
[Weak<T>](https://doc.rust-lang.org/std/rc/struct.Weak.html):

```
use std::{
    cell::RefCell,
    rc::{Rc, Weak},
};

// Use a newtype for each identifier type.
struct TreeId(String);
struct BranchId(String);
struct LeafId(String);

struct Tree {
    id: TreeId,
    branches: Vec<Rc<RefCell<Branch>>>,
}

struct Branch {
    id: BranchId,
    leaves: Vec<Rc<RefCell<Leaf>>>,
    owner: Option<Weak<RefCell<Tree>>>,
}

struct Leaf {
    id: LeafId,
    owner: Option<Weak<RefCell<Branch>>>,
}
```

The `Weak` reference doesn’t increment the main refcount and so has to explicitly check whether the underlying item has
gone away:

```
impl Branch {
    fn add_leaf(branch: Rc<RefCell<Branch>>, mut leaf: Leaf) {
        leaf.owner = Some(Rc::downgrade(&branch));
        branch.borrow_mut().leaves.push(Rc::new(RefCell::new(leaf)));
    }

    fn location(&self) -> String {
        match &self.owner {
            None => format!("<unowned>.{}", self.id.0),
            Some(owner) => {
                // Upgrade weak owner pointer.
                let tree = owner.upgrade().expect("owner gone!");
                format!("{}.{}", tree.borrow().id.0, self.id.0)
            }
        }
    }
}
```

If Rust’s smart pointers don’t seem to cover what’s needed for your data structures, there’s always the final fallback of
writing  `unsafe` code that uses raw (and decidedly un-smart) pointers.  However, as per [Item 16](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch03.html#file_unsafe_md), this should very
much be a last resort—someone else might have already implemented the semantics you want, inside a safe
interface, and if you search the standard library and  `crates.io`, you might find just the tool for the job.

For example, imagine that you have a function that sometimes returns a reference to one of its inputs but sometimes
needs to return some freshly allocated data. In line with [Item 1](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch01.html#file_use-types_md), an  `enum` that encodes these two possibilities
is the natural way to express this in the type system, and you could then implement various pointer traits
described in [Item 8](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch01.html#file_references_md).  But you don’t have to: the standard library already includes the
[std::borrow::Cow](https://doc.rust-lang.org/std/borrow/enum.Cow.html) type that covers
exactly this scenario once you know it exists.[4](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch03.html#id1162)

### Self-referential data structures

One particular battle with the borrow checker always stymies programmers arriving at Rust from other languages:
attempting to create self-referential data structures, which contain a mixture of owned data together with references to
within that owned data:

#

```
struct SelfRef {
    text: String,
    // The slice of `text` that holds the title text.
    title: Option<&str>,
}
```

At a syntactic level, this code won’t compile because it doesn’t comply with the lifetime rules described in [Item 14](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch03.html#file_lifetimes_md):
the reference needs a lifetime annotation, and that means the containing data structure would also need a lifetime
parameter.  But a lifetime would be for something external to this `SelfRef` struct, which is not the intent: the data
being referenced is internal to the struct.

It’s worth thinking about the reason for this restriction at a more semantic level.  Data structures in Rust can *move*:
from the stack to the heap, from the heap to the stack, and from one place to another.  If that happens, the “interior”
`title` pointer would no longer be valid, and there’s no way to keep it in sync.

A simple alternative for this case is to use the indexing approach explored earlier: a range of offsets into the `text`
is not invalidated by a move and is invisible to the borrow checker because it doesn’t involve references:

```
struct SelfRefIdx {
    text: String,
    // Indices into `text` where the title text is.
    title: Option<std::ops::Range<usize>>,
}
```

However, this indexing approach works only for simple examples and has the same drawbacks as noted previously: the
index itself becomes a pseudo-pointer that can become out of sync or even refer to ranges of the `text` that no longer
exist.

A more general version of the self-reference problem turns up when the compiler deals with  `async`
code.[5](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch03.html#id1167)  Roughly speaking, the compiler bundles up a pending chunk of
`async` code into a closure, which holds both the code and any captured parts of the environment that the code works
with (as described in [Item 2](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch01.html#file_use-types-2_md)).  This captured environment can include both values and references to those values.
That’s inherently a self-referential data structure, and so `async` support was a prime motivation for the
[Pin](https://doc.rust-lang.org/std/pin/struct.Pin.html) type in the standard library.  This pointer type “pins”
its value in place, forcing the value to remain at the same location in memory, thus ensuring that internal
self-references remain valid.

So `Pin` is available as a possibility for self-referential types, but it’s tricky to use correctly—be sure to
read the [official docs](https://doc.rust-lang.org/std/pin/index.html).

Where possible, *avoid self-referential data structures*, or try to find library crates that encapsulate the
difficulties for you (e.g.,  [ouroborous](https://crates.io/crates/ouroboros)).

## Things to Remember

-

Rust’s references are *borrowed*, indicating that they cannot be held forever.

-

The borrow checker allows multiple immutable references or a single mutable reference to an item but not both. The lifetime of a reference stops at the point of last use, rather than at the end of the enclosing scope, due to
non-lexical lifetimes.

-

Errors from the borrow checker can be dealt with in various ways:

-

Adding an additional `{ ... }` scope can reduce the extent of a value’s lifetime.

-

Adding a named local variable for a value extends the value’s lifetime to the end of the scope.

-

Temporarily adding multiple local variables can help narrow down what the borrow checker is complaining about.

-

Rust’s smart pointer types provide ways around the borrow checker’s rules and so are useful for interconnected data
structures.

-

However, self-referential data structures remain awkward to deal with in Rust.

# Item 16: Avoid writing `unsafe` code

The memory safety guarantees—without runtime overhead—of Rust are its unique selling point; it is the
Rust language feature that is not found in any other mainstream language.  These guarantees come at a cost:
writing Rust requires you to reorganize your code to mollify the  borrow checker ([Item 15](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch03.html#file_borrows_md)) and to precisely
specify the reference types that you use ([Item 8](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch01.html#file_references_md)).

Unsafe Rust is a superset of the Rust language that weakens some of these restrictions—and the corresponding
guarantees.  Prefixing a block with the  `unsafe` keyword switches that block into unsafe mode, which allows things
that are not supported in normal Rust.  In particular, it allows the use of  *raw pointers* that work
more like old-style C pointers. These pointers are not subject to the borrowing rules, and the programmer is responsible
for ensuring that they still point to valid memory whenever they’re dereferenced.

So at a superficial level, the advice of this Item is trivial: why move to Rust if you’re just going to write C code in
Rust?  However, there are occasions where `unsafe` code is absolutely required: for low-level library code or for when
your Rust code has to interface with code in other languages ([Item 34](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch06.html#file_ffi_md)).

The wording of this Item is quite precise, though: *avoid* writing *`unsafe` code*.  The emphasis is on the
“writing,” because much of the time, the `unsafe` code you’re likely to need has already been written for you.

The Rust standard libraries contain a lot of `unsafe` code; a quick search finds around 1,000 uses of `unsafe` in the
`alloc` library, 1,500 in `core`, and a further 2,000 in `std`. This code has been written by experts and is
battle-hardened by use in many thousands of Rust codebases.

Some of this `unsafe` code happens under the covers in standard library features that we’ve already covered:

-

The  smart pointer  types—`Rc`, `RefCell`, `Arc`, and friends—described in [Item 8](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch01.html#file_references_md) use `unsafe` code (often raw pointers) internally to be able to present their particular semantics to
their users.

-

The synchronization  primitives—`Mutex`,  `RwLock`, and associated guards—from [Item 17](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch03.html#file_deadlock_md)
use `unsafe` OS-specific code internally. [Rust Atomics and Locks](https://marabos.nl/atomics/) by  Mara Bos (O’Reilly) is recommended if you want to understand the subtle details involved in these primitives.

The standard library also has other functionality covering more advanced
features, implemented with `unsafe` internally:[6](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch03.html#id1198)

-

[std::pin::Pin](https://doc.rust-lang.org/std/pin/struct.Pin.html) forces an item to not move in memory
([Item 15](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch03.html#file_borrows_md)).  This allows self-referential data structures, often a [bête noire](https://oreil.ly/JBnWU) for new arrivals to Rust.

-

[std::borrow::Cow](https://doc.rust-lang.org/std/borrow/enum.Cow.html) provides a  clone-on-write
smart pointer: the same pointer can be used for both reading and writing, and a clone of the underlying data
happens only if and when a write occurs.

-

Various functions ([take](https://doc.rust-lang.org/std/mem/fn.take.html), [swap](https://doc.rust-lang.org/std/mem/fn.swap.html), [replace](https://doc.rust-lang.org/std/mem/fn.replace.html)) in [std::mem](https://doc.rust-lang.org/std/mem/index.html) allow items in memory to be manipulated without
falling foul of the  borrow checker.

These features may still need a little caution to be used correctly, but the `unsafe` code has been encapsulated in a
way that removes whole classes of problems.

Moving beyond the standard library, the  [crates.io](https://crates.io/) ecosystem also includes many crates that
encapsulate `unsafe` code to provide a frequently used feature:

once_cellProvides a way to have something like global variables, initialized
exactly once.

randProvides random number generation, making use of the lower-level underlying features
provided by the operating system and CPU.

byteorderAllows raw bytes of data to be converted to and from numbers.

cxxAllows  C++ code and Rust code to interoperate (also mentioned in [Item 35](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch06.html#file_bindgen_md)).

There are many other examples, but hopefully the general idea is clear.  If you want to do something that doesn’t
obviously fit within the constraints of Rust (especially Items [14](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch03.html#file_lifetimes_md) and [15](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch03.html#file_borrows_md)), hunt through the standard library to see
if there’s existing functionality that does what you need.  If you don’t find what you need, try also hunting through
`crates.io`. After all, it’s unusual to encounter a unique problem that no one else has ever faced before.

Of course, there will always be places where `unsafe` is forced, for example, when you need to interact with code written
in other languages via a  foreign function interface (FFI), as discussed in [Item 34](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch06.html#file_ffi_md).  But when it’s necessary,
*consider writing a wrapper layer that holds all the `unsafe` code* that’s required so that other programmers
can then follow the advice given in  this Item.  This also helps to localize problems: when something goes wrong, the `unsafe`
wrapper can be the first suspect.

Also, if you’re forced to write `unsafe` code, pay attention to the warning implied by the keyword  itself: [Hic sunt dracones](https://en.wikipedia.org/wiki/Here_be_dragons).

-

Add  [safety comments](https://oreil.ly/MHQvh) that document the
preconditions and invariants that the `unsafe` code relies on.  Clippy ([Item 29](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch05.html#file_clippy_md)) has a
[warning](https://rust-lang.github.io/rust-clippy/master/index.html#/missing_safety_doc) to remind you about this.

-

Minimize the amount of code contained in an `unsafe` block, to limit the potential blast radius of a mistake.
Consider enabling the   [unsafe_op_in_unsafe_fn lint](https://doc.rust-lang.org/rustc/lints/listing/allowed-by-default.html#unsafe-op-in-unsafe-fn) so that explicit
`unsafe` blocks are required when performing `unsafe` operations, even when those operations are performed in a
function that is `unsafe` itself.

-

Write even more tests ([Item 30](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch05.html#file_testing_md)) than usual.

-

Run additional diagnostic tools ([Item 31](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch05.html#file_use-tools_md)) over the code. In particular, *consider running  Miri over your
`unsafe` code*—[Miri](https://github.com/rust-lang/miri) interprets the intermediate level output from the
compiler, that allows it to detect classes of errors that are invisible to the Rust compiler.

-

Think carefully about multithreaded use, particularly if there’s  shared state ([Item 17](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch03.html#file_deadlock_md)).

Adding the `unsafe` marker doesn’t mean that no rules apply—it means that *you* (the programmer) are now
responsible for maintaining Rust’s safety guarantees, rather than the compiler.

# Item 17: Be wary of shared-state parallelism

Even the most daring forms of sharing are guaranteed safe in Rust.

[Aaron Turon](https://oreil.ly/wKFxX)

The official documentation describes Rust as enabling [“fearless concurrency”](https://oreil.ly/R7eq9), but this Item will explore why (sadly) there are
still some  reasons to be afraid of concurrency, even in Rust.

This Item is specific to  *shared-state* parallelism: where different threads of execution communicate with each
other by sharing memory. Sharing state between threads generally comes with *two* terrible problems, regardless of the
language involved:

Data racesThese can lead to corrupted data.

DeadlocksThese can lead to your program grinding to a halt.

Both of these problems are terrible (“causing or likely to cause terror”) because they can be very hard to debug in
practice: the failures occur nondeterministically and are often more likely to happen under load—which means
that they don’t show up in unit tests, integration tests, or any other sort of
test ([Item 30](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch05.html#file_testing_md)), but they do show up in production.

Rust is a giant step forward, because it completely solves one of these two problems. However, the other still remains,
as we shall see.

## Data Races

Let’s start with the good news, by exploring  *data races* and Rust. The precise technical definition of
a data race varies from language to language, but we can summarize the key components as follows:

A data race is defined to occur when two distinct threads access the same memory location, under the following conditions:

-

At least one of them is a write.

-

There is no synchronization mechanism that enforces an ordering on the accesses.

### Data races in C++

The basics of this are best illustrated with an example. Consider a data structure that tracks a bank account:

#

```
// C++ code.
class BankAccount {
 public:
  BankAccount() : balance_(0) {}

  int64_t balance() const {
    if (balance_ < 0) {
      std::cerr << "** Oh no, gone overdrawn: " << balance_ << "! **\n";
      std::abort();
    }
    return balance_;
  }
  void deposit(uint32_t amount) {
    balance_ += amount;
  }
  bool withdraw(uint32_t amount) {
    if (balance_ < amount) {
      return false;
    }
    // What if another thread changes `balance_` at this point?
    std::this_thread::sleep_for(std::chrono::milliseconds(500));

    balance_ -= amount;
    return true;
  }

 private:
  int64_t balance_;
};
```

This example is in  C++, not Rust, for reasons that will become clear shortly.  However, the same general concepts
apply in many other (non-Rust)  languages—Java, or Go, or Python, etc.

This class works fine in a single-threaded setting, but consider a multithreaded
setting:

```
BankAccount account;
account.deposit(1000);

// Start a thread that watches for a low balance and tops up the account.
std::thread payer(pay_in, &account);

// Start 3 threads that each try to repeatedly withdraw money.
std::thread taker(take_out, &account);
std::thread taker2(take_out, &account);
std::thread taker3(take_out, &account);
```

Here several threads are repeatedly trying to withdraw from the account, and there’s an additional thread that tops up
the account when it runs low:

```
// Constantly monitor the `account` balance and top it up if low.
void pay_in(BankAccount* account) {
  while (true) {
    if (account->balance() < 200) {
      log("[A] Balance running low, deposit 400");
      account->deposit(400);
    }
    // (The infinite loop with sleeps is just for demonstration/simulation
    // purposes.)
    std::this_thread::sleep_for(std::chrono::milliseconds(5));
  }
}

// Repeatedly try to perform withdrawals from the `account`.
void take_out(BankAccount* account) {
  while (true) {
    if (account->withdraw(100)) {
      log("[B] Withdrew 100, balance now " +
          std::to_string(account->balance()));
    } else {
      log("[B] Failed to withdraw 100");
    }
    std::this_thread::sleep_for(std::chrono::milliseconds(20));
  }
}
```

Eventually, things will go wrong:

```
** Oh no, gone overdrawn: -100! **
```

The problem isn’t hard to spot, particularly with the helpful comment in the `withdraw()` method: when multiple threads
are involved, the value of the balance can change between the check and the modification. However, real-world  bugs
of this sort are much harder to spot—particularly if the compiler is allowed to perform all kinds of tricks and
reorderings of code under the covers (as is the case for C++).

The various  `sleep` calls are included in order to artificially raise the chances of this bug being hit and thus
detected early; when these problems are encountered in the wild, they’re likely to occur rarely and
intermittently—making them very hard to debug.

The `BankAccount` class is  *thread-compatible*, which means that it can be used in a multithreaded environment as
long as the users of the class ensure that access to it is governed by some kind of external synchronization mechanism.

The class can be converted to a  *thread-safe* class—meaning that it is safe to use from multiple threads—by adding internal synchronization
operations:[7](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch03.html#id1231)

```
// C++ code.
class BankAccount {
 public:
  BankAccount() : balance_(0) {}

  int64_t balance() const {
    // Lock mu_ for all of this scope.
    const std::lock_guard<std::mutex> with_lock(mu_);
    if (balance_ < 0) {
      std::cerr << "** Oh no, gone overdrawn: " << balance_ << " **!\n";
      std::abort();
    }
    return balance_;
  }
  void deposit(uint32_t amount) {
    const std::lock_guard<std::mutex> with_lock(mu_);
    balance_ += amount;
  }
  bool withdraw(uint32_t amount) {
    const std::lock_guard<std::mutex> with_lock(mu_);
    if (balance_ < amount) {
      return false;
    }
    balance_ -= amount;
    return true;
  }

 private:
  mutable std::mutex mu_; // protects balance_
  int64_t balance_;
};
```

The internal `balance_` field is now protected by a *mutex* `mu_`: a synchronization object that ensures that only one
thread can successfully hold the mutex at a time. A caller can acquire the mutex with a call to `std::mutex::lock()`;
the second and subsequent callers of `std::mutex::lock()` will block until the original caller invokes
`std::mutex::unlock()`, and then *one* of the blocked threads will unblock and proceed through `std::mutex::lock()`.

All access to the balance now takes place with the mutex held, ensuring that its value is consistent between check and
modification. The  [std::lock_guard](https://en.cppreference.com/w/cpp/thread/lock_guard) is
also worth highlighting: it’s an  RAII class (see [Item 11](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch02.html#file_raii_md)) that calls `lock()` on creation and `unlock()` on
destruction.  This ensures that the mutex is unlocked when the scope exits, reducing the chances of making a mistake
around balancing manual `lock()` and `unlock()` calls.

However, the thread safety here is still fragile; all it takes is one erroneous modification to the class:

```
// Add a new C++ method...
void pay_interest(int32_t percent) {
  // ...but forgot about mu_
  int64_t interest = (balance_ * percent) / 100;
  balance_ += interest;
}
```

and the thread safety has been destroyed.[8](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch03.html#id1236)

### Data races in Rust

For a book about Rust, this Item has covered a lot of C++, so consider a straightforward translation of this class into
Rust:

```
pub struct BankAccount {
    balance: i64,
}

impl BankAccount {
    pub fn new() -> Self {
        BankAccount { balance: 0 }
    }
    pub fn balance(&self) -> i64 {
        if self.balance < 0 {
            panic!("** Oh no, gone overdrawn: {}", self.balance);
        }
        self.balance
    }
    pub fn deposit(&mut self, amount: i64) {
        self.balance += amount
    }
    pub fn withdraw(&mut self, amount: i64) -> bool {
        if self.balance < amount {
            return false;
        }
        self.balance -= amount;
        true
    }
}
```

along with the functions that try to pay into or withdraw from an account forever:

```
pub fn pay_in(account: &mut BankAccount) {
    loop {
        if account.balance() < 200 {
            println!("[A] Running low, deposit 400");
            account.deposit(400);
        }
        std::thread::sleep(std::time::Duration::from_millis(5));
    }
}

pub fn take_out(account: &mut BankAccount) {
    loop {
        if account.withdraw(100) {
            println!("[B] Withdrew 100, balance now {}", account.balance());
        } else {
            println!("[B] Failed to withdraw 100");
        }
        std::thread::sleep(std::time::Duration::from_millis(20));
    }
}
```

This works fine in a single-threaded context—even if that thread is not the main thread:

```json
{
    let mut account = BankAccount::new();
    let _payer = std::thread::spawn(move || pay_in(&mut account));
    // At the end of the scope, the `_payer` thread is detached
    // and is the sole owner of the `BankAccount`.
}
```

but a naive attempt to use the `BankAccount` across multiple threads:

#

```json
{
    let mut account = BankAccount::new();
    let _taker = std::thread::spawn(move || take_out(&mut account));
    let _payer = std::thread::spawn(move || pay_in(&mut account));
}
```

immediately falls foul of the compiler:

```
error[E0382]: use of moved value: `account`
   --> src/main.rs:102:41
    |
100 | let mut account = BankAccount::new();
    |     ----------- move occurs because `account` has type
    |                 `broken::BankAccount`, which does not implement the
    |                 `Copy` trait
101 | let _taker = std::thread::spawn(move || take_out(&mut account));
    |                                 -------               ------- variable
    |                                 |                         moved due to
    |                                 |                         use in closure
    |                                 |
    |                                 value moved into closure here
102 | let _payer = std::thread::spawn(move || pay_in(&mut account));
    |                                 ^^^^^^^             ------- use occurs due
    |                                 |                        to use in closure
    |                                 |
    |                                 value used here after move
```

The rules of the borrow checker ([Item 15](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch03.html#file_borrows_md)) make the problem clear: there are two mutable references
to the same item, one more than is allowed.  The rules of the borrow checker are that you can have a single mutable
reference to an item, or multiple (immutable) references, but not both at the same time.

This has a curious resonance with the definition of a data race at the start of this Item: enforcing that there is a
single writer, or multiple readers (but never both), means that there can be no data races.  By enforcing memory safety,
[Rust gets thread safety “for free”](https://oreil.ly/wKFxX).

As with C++, some kind of  synchronization is needed to make this `struct`  thread-safe. The most common
mechanism is also called  [Mutex](https://doc.rust-lang.org/std/sync/struct.Mutex.html), but the Rust version
“wraps” the protected data rather than being a standalone object (as in C++):

```
pub struct BankAccount {
    balance: std::sync::Mutex<i64>,
}
```

The [lock()](https://doc.rust-lang.org/std/sync/struct.Mutex.html#method.lock) method on this `Mutex` generic returns
a  [MutexGuard](https://doc.rust-lang.org/std/sync/struct.MutexGuard.html) object with RAII behavior, like C++’s
`std::lock_guard`: the mutex is automatically released at the end of the scope when the guard is `drop`ped.  (In
contrast to C++, Rust’s `Mutex` has no methods that manually acquire or release the mutex, as they would expose
developers to the danger of forgetting to keep these calls exactly in sync.)

To be more precise, `lock()` actually returns a `Result` that holds the `MutexGuard`, to cope with the possibility that
the `Mutex` has been *poisoned*.  Poisoning happens if a thread fails while holding the lock, because this might mean
that any mutex-protected invariants can no longer be relied on.  In practice, lock poisoning is sufficiently rare (and
it’s sufficiently desirable that the program terminates when it happens) that it’s common to just `.unwrap()` the
`Result` (despite the advice in [Item 18](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch03.html#file_panic_md)).

The `MutexGuard` object also acts as a proxy for the data that is enclosed by the `Mutex`, by implementing the `Deref` and `DerefMut` traits ([Item 8](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch01.html#file_references_md)), allowing it to be used both for read operations:

```
impl BankAccount {
    pub fn balance(&self) -> i64 {
        let balance = *self.balance.lock().unwrap();
        if balance < 0 {
            panic!("** Oh no, gone overdrawn: {}", balance);
        }
        balance
    }
}
```

and for write operations:

```
impl BankAccount {
    // Note: no longer needs `&mut self`.
    pub fn deposit(&self, amount: i64) {
        *self.balance.lock().unwrap() += amount
    }
    pub fn withdraw(&self, amount: i64) -> bool {
        let mut balance = self.balance.lock().unwrap();
        if *balance < amount {
            return false;
        }
        *balance -= amount;
        true
    }
}
```

There’s an interesting detail lurking in the signatures of these methods: although they are modifying the balance of the
`BankAccount`, the methods now take `&self` rather than `&mut self`.  This is inevitable: if multiple threads are going
to hold references to the same `BankAccount`, by the rules of the borrow checker, those references had better not be
mutable.  It’s also another instance of the  *interior mutability* pattern described in [Item 8](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch01.html#file_references_md): borrow checks are
effectively moved from compile time to runtime but now with cross-thread synchronization behavior.  If a mutable
reference already exists, an attempt to get a second blocks until the first reference is dropped.

Wrapping up shared state in a `Mutex` mollifies the borrow checker, but there are still lifetime issues ([Item 14](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch03.html#file_lifetimes_md)) to fix:

#

```json
{
    let account = BankAccount::new();
    let taker = std::thread::spawn(|| take_out(&account));
    let payer = std::thread::spawn(|| pay_in(&account));
    // At the end of the scope, `account` is dropped but
    // the `_taker` and `_payer` threads are detached and
    // still hold (immutable) references to `account`.
}
```

```
error[E0373]: closure may outlive the current function, but it borrows `account`
              which is owned by the current function
   --> src/main.rs:206:40
    |
206 |     let taker = std::thread::spawn(|| take_out(&account));
    |                                    ^^           ------- `account` is
    |                                    |                     borrowed here
    |                                    |
    |                                    may outlive borrowed value `account`
    |
note: function requires argument type to outlive `'static`
   --> src/main.rs:206:21
    |
206 |     let taker = std::thread::spawn(|| take_out(&account));
    |                 ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
help: to force the closure to take ownership of `account` (and any other
      referenced variables), use the `move` keyword
    |
206 |     let taker = std::thread::spawn(move || take_out(&account));
    |                                    ++++
error[E0373]: closure may outlive the current function, but it borrows `account`
              which is owned by the current function
   --> src/main.rs:207:40
    |
207 |     let payer = std::thread::spawn(|| pay_in(&account));
    |                                    ^^         ------- `account` is
    |                                    |                  borrowed here
    |                                    |
    |                                    may outlive borrowed value `account`
    |
note: function requires argument type to outlive `'static`
   --> src/main.rs:207:21
    |
207 |     let payer = std::thread::spawn(|| pay_in(&account));
    |                 ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
help: to force the closure to take ownership of `account` (and any other
      referenced variables), use the `move` keyword
    |
207 |     let payer = std::thread::spawn(move || pay_in(&account));
    |                                    ++++
```

The error message makes the problem clear: the `BankAccount` is going to be  `drop`ped at the end of the
block, but there are two new threads that have a reference to it and that may carry on running afterward. (The
compiler’s suggestion for how to fix the problem is less helpful—if the `BankAccount` item is moved into
the first closure, it will no longer be available for the second closure to receive a reference to it!)

The standard tool for ensuring that an object remains active until all references to it are gone is a reference-counted
pointer, and Rust’s variant of this for multithreaded use is
[std::sync::Arc](https://doc.rust-lang.org/std/sync/struct.Arc.html):

```
let account = std::sync::Arc::new(BankAccount::new());
account.deposit(1000);

let account2 = account.clone();
let _taker = std::thread::spawn(move || take_out(&account2));

let account3 = account.clone();
let _payer = std::thread::spawn(move || pay_in(&account3));
```

Each thread gets its own copy of the reference-counting pointer, moved into the closure, and the underlying
`BankAccount` will be `drop`ped only when the refcount drops to zero. This combination of `Arc<Mutex<T>>` is common in
Rust programs that use  shared-state parallelism.

Stepping back from the technical details, observe that Rust has entirely avoided the problem of data races that plagues
multithreaded programming in other languages.  Of course, this good news is restricted to *safe* Rust—`unsafe`
code ([Item 16](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch03.html#file_unsafe_md)) and FFI boundaries in particular ([Item 34](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch06.html#file_ffi_md)) may not be data-race free—but it’s
still a remarkable phenomenon.

### Standard marker traits

There are two standard traits that affect the use of Rust objects between threads.  Both of these traits are  *marker traits* ([Item 10](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch02.html#file_std-traits_md)) that have no associated methods but have special significance to the compiler in
multithreaded scenarios:

-

The  [Send](https://doc.rust-lang.org/std/marker/trait.Send.html) trait indicates that items of a type are safe
to transfer between threads; ownership of an item of this type can be passed from one thread to another.

-

The  [Sync](https://doc.rust-lang.org/std/marker/trait.Sync.html) trait indicates that items of a type can be
safely accessed by multiple threads, subject to the rules of the borrow checker.

Another way of saying this is to observe that `Send` means `T` can be transferred between threads,
and `Sync` means that `&T` can be transferred between threads.

Both of these traits are  [auto traits](https://oreil.ly/7eeE7): the compiler automatically
derives them for new types, as long as the constituent parts of the type also implement `Send`/`Sync`.

The majority of safe types implement `Send` and `Sync`, so much so that it’s clearer to understand what types *don’t*
implement these traits (written in the form `impl !Sync for Type`).

A type that doesn’t implement `Send` is one that can be used only in a single thread. The canonical example of this is
the unsynchronized reference-counting pointer [Rc<T>](https://doc.rust-lang.org/std/rc/struct.Rc.html) ([Item 8](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch01.html#file_references_md)).
The implementation of this type explicitly assumes single-threaded use (for speed); there is no attempt at synchronizing
the internal refcount for multithreaded use. As such, transferring an `Rc<T>` between threads is not allowed; use
`Arc<T>` (with its additional synchronization overhead) for this case.

A type that doesn’t implement `Sync` is one that’s not safe to use from multiple threads via *non*-`mut` references (as
the borrow checker will ensure there are never multiple `mut` references).  The canonical examples of this are the types
that provide *interior mutability* in an unsynchronized way, such as
[Cell<T>](https://doc.rust-lang.org/std/cell/struct.Cell.html) and
[RefCell<T>](https://doc.rust-lang.org/std/cell/struct.RefCell.html).  Use `Mutex<T>` or
[RwLock<T>](https://doc.rust-lang.org/std/sync/struct.RwLock.html) to provide interior mutability in a multithreaded
environment.

Raw  pointer types like `*const T` and `*mut T` also implement neither `Send` nor `Sync`; see Items [16](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch03.html#file_unsafe_md)
and [34](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch06.html#file_ffi_md).

## Deadlocks

Now for the bad news.  Although Rust has solved the problem of data races (as previously described), it is still susceptible
to the *second* terrible problem for multithreaded code with shared state:  *deadlocks*.

Consider a simplified multiple-player game server, implemented as a multithreaded application to service many
players in parallel.  Two core data structures might be a collection of players, indexed by username,
and a collection of games in progress, indexed by some unique identifier:

```
struct GameServer {
    // Map player name to player info.
    players: Mutex<HashMap<String, Player>>,
    // Current games, indexed by unique game ID.
    games: Mutex<HashMap<GameId, Game>>,
}
```

Both of these data structures are `Mutex`-protected and so are safe from data races.  However, code that manipulates *both*
data structures opens up potential problems.  A single interaction between the two might work fine:

```
impl GameServer {
    /// Add a new player and join them into a current game.
    fn add_and_join(&self, username: &str, info: Player) -> Option<GameId> {
        // Add the new player.
        let mut players = self.players.lock().unwrap();
        players.insert(username.to_owned(), info);

        // Find a game with available space for them to join.
        let mut games = self.games.lock().unwrap();
        for (id, game) in games.iter_mut() {
            if game.add_player(username) {
                return Some(id.clone());
            }
        }
        None
    }
}
```

However, a second interaction between the two independently locked data structures is where problems start:

```
impl GameServer {
    /// Ban the player identified by `username`, removing them from
    /// any current games.
    fn ban_player(&self, username: &str) {
        // Find all games that the user is in and remove them.
        let mut games = self.games.lock().unwrap();
        games
            .iter_mut()
            .filter(|(_id, g)| g.has_player(username))
            .for_each(|(_id, g)| g.remove_player(username));

        // Wipe them from the user list.
        let mut players = self.players.lock().unwrap();
        players.remove(username);
    }
}
```

To understand the problem, imagine two separate threads using these two methods, where their execution happens in the
order shown in [Table 3-1](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch03.html#table_3_1).

| Thread 1 | Thread 2 |
| --- | --- |
| Enters `add_and_join()` and immediately  <br> acquires the `players` lock. |  |
|  | Enters `ban_player()` and immediately  <br> acquires the `games` lock. |
| Tries to acquire the `games` lock; this is held   <br>by thread 2, so thread 1 blocks. |  |
|  | Tries to acquire the `players` lock; this is held   <br>by thread 1, so thread 2 blocks. |

At this point, the program is  *deadlocked*: neither thread will ever progress, nor will any other
thread that does anything with either of the two `Mutex`-protected data structures.

The root cause of this is a  *lock inversion*: one function acquires the locks in the order `players` then `games`,
whereas the other uses the opposite order (`games` then `players`).  This is a simple example of a more general problem;
the same situation can arise with longer chains of nested locks (thread 1 acquires lock A, then B, then it tries to acquire
C; thread 2 acquires C, then tries to acquire A) and across more threads (thread 1 locks A, then B; thread 2 locks B, then
C; thread 3 locks C, then A).

A simplistic attempt to solve this problem involves reducing the scope of the locks, so there is no point where both
locks are held at the same time:

```
/// Add a new player and join them into a current game.
fn add_and_join(&self, username: &str, info: Player) -> Option<GameId> {
    // Add the new player.
    {
        let mut players = self.players.lock().unwrap();
        players.insert(username.to_owned(), info);
    }

    // Find a game with available space for them to join.
    {
        let mut games = self.games.lock().unwrap();
        for (id, game) in games.iter_mut() {
            if game.add_player(username) {
                return Some(id.clone());
            }
        }
    }
    None
}
/// Ban the player identified by `username`, removing them from
/// any current games.
fn ban_player(&self, username: &str) {
    // Find all games that the user is in and remove them.
    {
        let mut games = self.games.lock().unwrap();
        games
            .iter_mut()
            .filter(|(_id, g)| g.has_player(username))
            .for_each(|(_id, g)| g.remove_player(username));
    }

    // Wipe them from the user list.
    {
        let mut players = self.players.lock().unwrap();
        players.remove(username);
    }
}
```

(A better version of this would be to encapsulate the manipulation of the `players` data structure into `add_player()`
and `remove_player()` helper methods, to reduce the chances of forgetting to close out a scope.)

This solves the deadlock problem but leaves behind a data consistency problem: the `players` and `games` data
structures can get out of sync with each other, given an execution sequence like the one shown in [Table 3-2](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch03.html#table_3_2).

| Thread 1 | Thread 2 |
| --- | --- |
| Enters `add_and_join("Alice")` and adds Alice to the   <br>`players` data structure (then releases the `players` lock). |  |
|  | Enters `ban_player("Alice")` and removes Alice from all `games` (then releases the `games` lock). |
|  | Removes Alice from the `players` data structure; thread 1 has already released the lock, so this does not block. |
| Carries on and acquires the `games` lock (already released by   <br>thread 2). With the lock held,  adds “Alice” to a game in progress. |  |

At this point, there is a game that includes a player that doesn’t exist, according to the `players` data structure!

The heart of the problem is that there are two data structures that need to be kept in sync with each other.  The
best way to do this is to have a single synchronization primitive that covers both of them:

```
struct GameState {
    players: HashMap<String, Player>,
    games: HashMap<GameId, Game>,
}

struct GameServer {
    state: Mutex<GameState>,
    // ...
}
```

## Advice

The most obvious advice for avoiding the problems that arise with shared-state parallelism is simply to avoid
shared-state parallelism.  The [Rust book](https://doc.rust-lang.org/book/ch16-02-message-passing.html) quotes from the
[Go language documentation](https://oreil.ly/HiKmp): “Do not communicate by
sharing memory; instead, share memory by communicating.”

The Go language has  *channels* that are suitable for this [built into the language](https://oreil.ly/uBPhZ); for Rust, equivalent functionality is included in the standard library
in the  [std::sync::mpsc module](https://doc.rust-lang.org/std/sync/mpsc/index.html): the [channel() function](https://doc.rust-lang.org/std/sync/mpsc/fn.channel.html) returns a `(Sender, Receiver)` pair that allows
values of a particular type to be communicated between threads.

If shared-state concurrency can’t be avoided, then there are some ways to reduce the chances of writing deadlock-prone
code:

-

*Put data structures that must be kept consistent with each other under a single lock*.

-

*Keep lock scopes small and obvious*; wherever possible, use helper methods that get and set things under the
relevant lock.

-

*Avoid invoking closures with locks held*; this puts the code at the mercy of whatever closure gets added to
the codebase in the future.

-

Similarly, *avoid returning a `MutexGuard` to a caller*: it’s like handing out a loaded gun, from a deadlock
perspective.

-

*Include deadlock detection tools* in your CI system ([Item 32](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch05.html#file_ci_md)), such as
[no_deadlocks](https://docs.rs/no_deadlocks),
[ThreadSanitizer](https://clang.llvm.org/docs/ThreadSanitizer.html), or
[parking_lot::deadlock](https://amanieu.github.io/parking_lot/parking_lot/deadlock/index.html).

-

As a last resort: design, document, test, and police a  *locking hierarchy* that describes what lock orderings are
allowed/required. This should be a last resort because any strategy that relies on engineers never making a mistake is
likely to be doomed to failure in the long term.

More abstractly, multithreaded code is an ideal place to apply the following general advice: prefer code that’s so simple that
it is obviously not wrong, rather than code that’s so complex that it’s not obviously wrong.

# Item 18: Don’t panic

It looked insanely complicated, and this was one of the reasons why the snug plastic cover it fitted into had
the words DON’T PANIC printed on it in large friendly letters.

Douglas Adams

The title of this Item would be more accurately described as *prefer returning a  `Result` to using
`panic!`* (but *don’t panic* is much catchier).

Rust’s panic mechanism is primarily designed for unrecoverable bugs in your program, and *by default* it terminates the
thread that issues the `panic!`.  However, there are alternatives to this default.

In particular, newcomers to Rust who have come from languages that have an  exception system (such as  Java or
C++) sometimes pounce on
[std::panic::catch_unwind](https://doc.rust-lang.org/std/panic/fn.catch_unwind.html) as a way to
simulate exceptions, because it appears to provide a mechanism for catching panics at a point further up the call stack.

Consider a function that panics on an invalid input:

```
fn divide(a: i64, b: i64) -> i64 {
    if b == 0 {
        panic!("Cowardly refusing to divide by zero!");
    }
    a / b
}
```

Trying to invoke this with an invalid input fails as expected:

```
// Attempt to discover what 0/0 is...
let result = divide(0, 0);
```

```
thread 'main' panicked at 'Cowardly refusing to divide by zero!', main.rs:11:9
note: run with `RUST_BACKTRACE=1` environment variable to display a backtrace
```

A wrapper that uses  `catch_unwind` to catch the panic:

```
fn divide_recover(a: i64, b: i64, default: i64) -> i64 {
    let result = std::panic::catch_unwind(|| divide(a, b));
    match result {
        Ok(x) => x,
        Err(_) => default,
    }
}
```

*appears* to work and to simulate  `catch`:

```
let result = divide_recover(0, 0, 42);
println!("result = {result}");
```

```
result = 42
```

Appearances can be deceptive, however.  The first problem with this approach is that panics don’t always unwind; there
is a [compiler option](https://doc.rust-lang.org/rustc/codegen-options/index.html#panic) (which is also accessible via a
*Cargo.toml* [profile setting](https://doc.rust-lang.org/cargo/reference/profiles.html#panic)) that shifts panic
behavior so that it immediately aborts the process:

```
thread 'main' panicked at 'Cowardly refusing to divide by zero!', main.rs:11:9
note: run with `RUST_BACKTRACE=1` environment variable to display a backtrace
/bin/sh: line 1: 29100 Abort trap: 6  cargo run --release
```

This leaves any attempt to simulate exceptions entirely at the mercy of the wider project settings. It’s also the case
that some target platforms (for example, WebAssembly) *always* abort on panic, regardless of any compiler or
project settings.

A more subtle problem that’s surfaced by panic handling is  [exception safety](https://en.wikipedia.org/wiki/Exception_safety): if a panic occurs midway through an operation on a data
structure, it removes any guarantees that the data structure has been left in a self-consistent state.  Preserving
internal invariants in the presence of exceptions has been known to be extremely difficult since the 1990s;[9](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch03.html#id1313) this is one of the main reasons why [Google (famously) bans the use of exceptions in its C++ code](https://oreil.ly/Bc-_z).

Finally, panic propagation also [interacts poorly](https://oreil.ly/flAtD) with
FFI (foreign function interface) boundaries ([Item 34](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch06.html#file_ffi_md)); *use `catch_unwind` to prevent panics in Rust
code from propagating to non-Rust calling code* across an FFI boundary.

So what’s the alternative to `panic!` for dealing with error conditions?  For library code, the best alternative is to
make the error [someone else’s problem](https://en.wikipedia.org/wiki/Somebody_else%27s_problem), by returning a
`Result` with an appropriate error type ([Item 4](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch01.html#file_errors_md)).  This allows the library user to make their own decisions
about what to do next—which may involve passing the problem on to the next caller in line, via the `?` operator.

The buck has to stop somewhere, and a useful rule of thumb is that it’s OK to `panic!` (or to `unwrap()`, `expect()`,
etc.) if you have control of  `main`; at that point, there’s no further caller that the buck could be passed to.

Another sensible use of `panic!`, even in library code, is in situations where it’s very rare to encounter errors, and
you don’t want users to have to litter their code with `.unwrap()` calls.

If an error situation *should* occur only because (say) internal data is corrupted, rather than as a result of invalid
inputs, then triggering a `panic!` is legitimate.

It can even be occasionally useful to allow panics that can be triggered by invalid input but where such invalid inputs
are out of the ordinary.  This works best when the relevant entrypoints come in pairs:

-

An “infallible” version whose signature implies it always succeeds (and which panics if it can’t succeed)

-

A “fallible” version that returns a `Result`

For the former, Rust’s [API guidelines](https://oreil.ly/vXxDV)
suggest that the `panic!` should be documented in a specific section of the inline documentation ([Item 27](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch05.html#file_documentation_md)).

The
[String::from_utf8_unchecked](https://doc.rust-lang.org/std/string/struct.String.html#method.from_utf8_unchecked)
and  [String::from_utf8](https://doc.rust-lang.org/std/string/struct.String.html#method.from_utf8)
entrypoints in the standard library are an example of the latter (although in this case, the panics are actually
deferred to the point where a `String` constructed from invalid input gets used).

Assuming that you are trying to comply with the advice in this Item, there are a few things to bear in mind.  The first
is that panics can appear in different guises; avoiding `panic!` also involves avoiding the following:

-

[unwrap()](https://doc.rust-lang.org/std/result/enum.Result.html#method.unwrap) and
[unwrap_err()](https://doc.rust-lang.org/std/result/enum.Result.html#method.unwrap_err)

-

[expect()](https://doc.rust-lang.org/std/result/enum.Result.html#method.expect) and
[expect_err()](https://doc.rust-lang.org/std/result/enum.Result.html#method.expect_err)

-

[unreachable!()](https://doc.rust-lang.org/std/macro.unreachable.html)

Harder to spot are things like these:

-

`slice[index]` when the index is out of range

-

`x / y` when `y` is zero

The second observation around avoiding panics is that a plan that involves  constant
vigilance of humans is never a good idea.

However, constant vigilance of machines is another matter: adding a check to your continuous integration (see [Item 32](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch05.html#file_ci_md))
system that spots new, potentially panicking code is much more reliable.  A simple version could be a simple grep for the
most common panicking entrypoints (as shown previously); a more thorough check could involve additional tooling from the Rust
ecosystem ([Item 31](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch05.html#file_use-tools_md)), such as setting up a build variant that pulls in the  [no_panic](https://docs.rs/no-panic)
crate.

# Item 19: Avoid reflection

Programmers coming to Rust from other languages are often used to reaching for  reflection as a tool in their toolbox.
They can waste a lot of time trying to implement reflection-based designs in Rust, only to discover that what they’re
attempting can only be done poorly, if at all.  This Item hopes to save that time wasted exploring dead ends, by
describing what Rust does and doesn’t have in the way of reflection, and what can be used instead.

*Reflection* is the ability of a program to examine itself at runtime.  Given an item at runtime, it covers these questions:

-

What information can be determined about the item’s type?

-

What can be done with that information?

Programming languages with full reflection support have extensive answers to these questions.  Languages with reflection
typically support some or all of the following at runtime, based on the reflection information:

-

Determining an item’s type

-

Exploring its contents

-

Modifying its fields

-

Invoking its methods

Languages that have this level of reflection support also *tend* to
be dynamically typed languages (e.g., [Python](https://docs.python.org/3/library/types.html#module-types),
Ruby), but there are also some notable statically typed languages that also support reflection, particularly
[Java](https://docs.oracle.com/javase/8/docs/api/java/lang/reflect/package-summary.html) and
[Go](https://golang.org/pkg/reflect/).

Rust does not support this type of reflection, which makes the advice to *avoid reflection* easy to follow at this
level—it’s just not possible.  For programmers coming from languages with support for full reflection, this
absence may seem like a significant gap at first, but Rust’s other features provide alternative ways of solving many of
the same problems.

C++ has a more limited form of reflection, known as  *run-time type identification* (RTTI).  The [typeid](https://en.cppreference.com/w/cpp/language/typeid) operator returns a unique identifier
for every type, for objects of *polymorphic type* (roughly: classes with virtual functions):

typeidCan recover the concrete class of an object referred to via a base class reference

dynamic_cast<T>Allows base
class references to be converted to derived classes, when it is safe and correct to do so

Rust does not support this RTTI style of reflection either, continuing the theme that the advice of this Item is easy to
follow.

Rust does support some features that provide *similar* functionality in the
[std::any](https://doc.rust-lang.org/std/any/index.html) module, but they’re limited (in ways we will explore) and so
best avoided unless no other alternatives are possible.

The first reflection-like feature from `std::any` *looks* like magic at first—a way of determining the name of an
item’s type.  The following example uses a user-defined `tname()` function:

```
let x = 42u32;
let y = vec![3, 4, 2];
println!("x: {} = {}", tname(&x), x);
println!("y: {} = {:?}", tname(&y), y);
```

to show types alongside values:

```
x: u32 = 42
y: alloc::vec::Vec<i32> = [3, 4, 2]
```

The implementation of `tname()` reveals what’s up the compiler’s sleeve: the function is generic
(as per [Item 12](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch02.html#file_generics_md)), and so each invocation of it is actually a  different function (`tname::<u32>`
or `tname::<Square>`):

```
fn tname<T: ?Sized>(_v: &T) -> &'static str {
    std::any::type_name::<T>()
}
```

The implementation is provided by the
[std::any::type_name<T>](https://doc.rust-lang.org/std/any/fn.type_name.html) library
function, which is also generic.  This function has access only to *compile-time* information; there is no code run that
determines the type at runtime.  Returning to the trait object types used in [Item 12](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch02.html#file_generics_md) demonstrates this:

```
let square = Square::new(1, 2, 2);
let draw: &dyn Draw = &square;
let shape: &dyn Shape = &square;

println!("square: {}", tname(&square));
println!("shape: {}", tname(&shape));
println!("draw: {}", tname(&draw));
```

Only the types of the trait objects are available, not the type (`Square`) of the concrete underlying item:

```
square: reflection::Square
shape: &dyn reflection::Shape
draw: &dyn reflection::Draw
```

The string returned by `type_name` is suitable only for diagnostics—it’s explicitly a “best-effort” helper whose
contents may change and may not be unique—so *don’t attempt to parse `type_name` results*. If you
need a globally unique type identifier, use  [TypeId](https://doc.rust-lang.org/std/any/struct.TypeId.html)
instead:

```
use std::any::TypeId;

fn type_id<T: 'static + ?Sized>(_v: &T) -> TypeId {
    TypeId::of::<T>()
}
```

```
println!("x has {:?}", type_id(&x));
println!("y has {:?}", type_id(&y));
```

```
x has TypeId { t: 18349839772473174998 }
y has TypeId { t: 2366424454607613595 }
```

The output is less helpful for humans, but the guarantee of uniqueness means that the result can be used in code.
However, it’s usually best not to use `TypeId` directly but to use the
[std::any::Any](https://doc.rust-lang.org/std/any/trait.Any.html) trait instead, because the standard
library has additional functionality for working with `Any` instances (described below).

The `Any` trait has a single method [type_id()](https://doc.rust-lang.org/std/any/trait.Any.html#tymethod.type_id),
which returns the `TypeId` value for the type that implements the trait. You can’t implement this trait yourself, though,
because `Any` already comes with a  blanket implementation for most arbitrary types `T`:

```
impl<T: 'static + ?Sized> Any for T {
    fn type_id(&self) -> TypeId {
        TypeId::of::<T>()
    }
}
```

The blanket implementation doesn’t cover *every* type `T`: the `T: 'static`  *lifetime bound* means that if `T`
includes any references that have a non-`'static` lifetime, then `TypeId` is not implemented for `T`.  This is a
[deliberate restriction](https://oreil.ly/BjglR) that’s imposed because lifetimes aren’t fully
part of the type: `TypeId::of::<&'a T>` would be the same as `TypeId::of::<&'b T>`, despite the differing lifetimes,
increasing the likelihood of confusion and unsound code.

Recall from [Item 8](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch01.html#file_references_md) that a trait object is a fat pointer that holds a pointer to the underlying item,
together with a pointer to the trait implementation’s  vtable.  For `Any`, the vtable has a single entry, for a
`type_id()` method that returns the item’s type, as shown in [Figure 3-4](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch03.html#fig_3_4):

```
let x_any: Box<dyn Any> = Box::new(42u64);
let y_any: Box<dyn Any> = Box::new(Square::new(3, 4, 3));
```

![The diagram shows a stack on the left, some concrete items in the middle, and some vtables and code objects on the right hand side.  The stack part has two trait objects labelled x_any and y_any. The x_any trait object has an arrow to a concrete item with value 42 in the middle; it also has an arrow to an Any for u64 vtable on the right hand side. This vtable has a single type_id entry, which in turn points to a code object labelled return TypeId::of::<u64>. The y_any trait object has an arrow to a concrete item that is composite, with components top_left.x=3, top_left.y=4 and size=3; it also has an arrow to an Any for Square vtable on the right hand side. This vtable has a single type_id entry, which in turn points to a code object labelled return TypeId::of::<Square>.](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781098151393/files/assets/efru_0304.png)

###### Figure 3-4. `Any` trait objects, each with pointers to concrete items and vtables

Aside from a couple of indirections, a `dyn Any` trait object is effectively a combination of a raw pointer and a type
identifier.  This means that the standard library can offer some additional  generic methods that are defined for a
`dyn Any` trait object; these methods are generic over some additional type `T`:

is::<T>()Indicates whether the trait
object’s type is equal to some specific other type `T`

downcast_ref::<T>()Returns a reference to the concrete type `T`, provided that the trait object’s type matches `T`

downcast_mut::<T>()Returns a mutable reference to the concrete type T, provided that the trait object’s type matches T

Observe that the `Any` trait is only approximating reflection functionality: the programmer chooses (at compile time) to
explicitly build something (`&dyn Any`) that keeps track of an item’s compile-time type as well as its location. The
ability to (say) downcast back to the original type is possible only if the overhead of building an `Any` trait object
has already happened.

There are comparatively few scenarios where Rust has different compile-time and runtime types associated with an item.
Chief among these is  *trait objects*: an item of a concrete type `Square` can be coerced into a trait
object `dyn Shape` for a trait that the type implements.  This coercion builds a fat pointer (object + vtable) from a
simple pointer (object/item).

Recall also from [Item 12](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch02.html#file_generics_md) that Rust’s trait objects are not really  object-oriented.  It’s not the case that a
`Square` *is-a* `Shape`; it’s just that a `Square` implements `Shape`’s interface.  The same is true for  trait
bounds: a trait bound `Shape: Draw` does *not* mean  *is-a*; it just means
*also-implements* because the vtable for `Shape` includes the entries for the methods of `Draw`.

For some simple trait bounds:

```
trait Draw: Debug {
    fn bounds(&self) -> Bounds;
}

trait Shape: Draw {
    fn render_in(&self, bounds: Bounds);
    fn render(&self) {
        self.render_in(overlap(SCREEN_BOUNDS, self.bounds()));
    }
}
```

the equivalent trait objects:

```
let square = Square::new(1, 2, 2);
let draw: &dyn Draw = &square;
let shape: &dyn Shape = &square;
```

have a layout with arrows (shown in [Figure 3-5](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch03.html#fig_3_5); repeated from [Item 12](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch02.html#file_generics_md)) that make the problem clear: given a `dyn Shape`
object, there’s no immediate way to build a `dyn Draw` trait object, because there’s no way to get back to the
vtable for `impl Draw for Square`—even though the relevant part of its contents (the address of the
`Square::bounds()` method) *is* theoretically recoverable.  (This is likely to change in later versions of Rust; see the
final section of this Item.)

![The diagram shows a stack layout on the left, and on the right are rectangles representing vtables and code methods. The stack layout includes three items; at the top is a composite item labeled square, with contents being a top_left.x value of 1, a top_left.y value of 2 and a size value of 2. The middle stack item is a trait object, containing an item pointer that links to the square item on the stack, and a vtable pointer that links to a Draw for Square vtable on the right hand side of the diagram.  This vtable has a single content marked bounds, pointing to a rectangle representing the code of Square::bounds().  The bottom stack item is also a trait object, containing an item pointer that also links to the square item on the stack, but whose vtable pointer links to a Shape for Square vtable on the right hand side of the diagram.  This vtable has three contents, labelled render_in, render and bounds.  Each of these vtable contents has a link to a different rectangle, representing the code for Square::render_in(), Shape::render() and Square::bounds() respectively.  The rectangle representing Square::bounds() therefore has two arrows leading to it, one from each of the vtables.](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781098151393/files/assets/efru_0305.png)

###### Figure 3-5. Trait objects for trait bounds, with distinct vtables for `Draw` and `Shape`

Comparing this with the previous diagram, it’s also clear that an explicitly constructed `&dyn Any` trait object doesn’t help.
`Any` allows recovery of the original concrete type of the underlying item, but there is no runtime way to
see what traits it implements, or to get access to the relevant vtable that might allow creation of a trait object.

So what’s available instead?

The primary tool to reach for is trait definitions, and this is in line with advice for other languages—*Effective
Java*  Item 65 recommends, “Prefer interfaces to reflection.”  If code needs to rely on the availability of certain
behavior for an item, encode that behavior as a trait ([Item 2](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch01.html#file_use-types-2_md)). Even if the desired behavior
can’t be expressed as a set of method signatures, use marker traits to indicate compliance with the desired
behavior—it’s safer and more efficient than (say) introspecting the name of a class to check for a particular
prefix.

Code that expects trait objects can also be used with objects having backing code that was not available at program link time,
because it has been dynamically loaded at runtime (via  `dlopen(3)` or equivalent)—which means that
monomorphization of a generic ([Item 12](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch02.html#file_generics_md)) isn’t possible.

Relatedly, reflection is sometimes also used in other languages to allow multiple incompatible versions of the same
dependency library to be loaded into the program at once, bypassing linkage constraints that  There Can Be Only
One. This is not needed in Rust, where  Cargo already copes with multiple versions of the same library ([Item 25](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch04.html#file_dep-graph_md)).

Finally,  macros—especially   `derive` macros—can be used to auto-generate
ancillary code that understands an item’s type at compile time, as a more efficient and more type-safe equivalent to
code that parses an item’s contents at runtime.  [Item 28](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch05.html#file_macros_md) discusses Rust’s macro system.

## Upcasting in Future Versions of Rust

The text of this Item was first written in 2021, and remained accurate all the way until the book was being prepared for
publication in 2024—at which point a new feature is due to be added to Rust that changes some of the details.

This [new “trait upcasting” feature](https://oreil.ly/gWJUW) enables  upcasts that
convert a trait object `dyn T` to a trait object `dyn U`, when `U` is one of `T`’s supertraits (`trait T: U {...}`).
The feature is gated on `#![feature(trait_upcasting)]` in advance of its official release, expected to be Rust version
1.76.

For the preceding example, that means a `&dyn Shape` trait object *can* now be converted to a `&dyn Draw` trait object,
edging closer to the *is-a* relationship of  [Liskov substitution](https://en.wikipedia.org/wiki/Liskov_substitution_principle).  Allowing this conversion has a knock-on
effect on the internal details of the vtable implementation, which are likely to become more complex than the versions
shown in [Figure 3-5](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch03.html#fig_3_5).

However, the central points of this Item are not affected—the `Any` trait has no supertraits, so the ability to
upcast adds nothing to its functionality.

# Item 20: Avoid the temptation to over-optimize

Just because Rust *allows* you to write super cool non-allocating zero-copy algorithms safely, doesn’t mean
*every* algorithm you write should be super cool, zero-copy and non-allocating.

[trentj](https://oreil.ly/fQMfu)

Most of the Items in this book are designed to help existing programmers become familiar with Rust and its idioms.  This
Item, however, is all about a problem that can arise when programmers stray too far in the other direction and become
obsessed with exploiting Rust’s potential for efficiency—at the expense of usability and maintainability.

## Data Structures and Allocation

Like pointers in other languages, Rust’s references allow you to reuse data without making copies.  Unlike other
languages, Rust’s rules around reference lifetimes and borrows allow you to reuse data *safely*.  However, complying
with the borrow checking rules ([Item 15](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch03.html#file_borrows_md)) that make this possible can lead to code that’s harder to use.

This is particularly relevant for data structures, where you can choose between allocating a fresh copy of something
that’s stored in the data structure or including a reference to an existing copy of it.

As an example, consider some code that parses a data stream of bytes, extracting data encoded as  type-length-value
(TLV) structures where data is transferred in the following format:

-

One byte describing the type of the value (stored in the `type_code` field here)[10](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch03.html#id1382)

-

One byte describing the length of the value in bytes (used here to create a slice of the specified length)

-

Followed by the specified number of bytes for the value (stored in the `value` field):

```
/// A type-length-value (TLV) from a data stream.
#[derive(Clone, Debug)]
pub struct Tlv<'a> {
    pub type_code: u8,
    pub value: &'a [u8],
}

pub type Error = &'static str; // Some local error type.

/// Extract the next TLV from the `input`, also returning the remaining
/// unprocessed data.
pub fn get_next_tlv(input: &[u8]) -> Result<(Tlv, &[u8]), Error> {
    if input.len() < 2 {
        return Err("too short for a TLV");
    }
    // The TL parts of the TLV are one byte each.
    let type_code = input[0];
    let len = input[1] as usize;
    if 2 + len > input.len() {
        return Err("TLV longer than remaining data");
    }

    let tlv = Tlv {
        type_code,
        // Reference the relevant chunk of input data
        value: &input[2..2 + len],
    };
    Ok((tlv, &input[2 + len..]))
}
```

This `Tlv` data structure is efficient because it holds a reference to the relevant chunk of the input data, without
copying any of the data, and Rust’s memory safety ensures that the reference is always valid.  That’s perfect for some
scenarios, but things become more awkward if something needs to hang onto an instance of the data structure (as
discussed in [Item 15](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch03.html#file_borrows_md)).

For example, consider a network server that is receiving messages in the form of TLVs.  The received data can be parsed
into `Tlv` instances, but the lifetime of those instances will match that of the incoming message—which might be
a transient `Vec<u8>` on the heap or might be a buffer somewhere that gets reused for multiple messages.

That induces a problem if the server code ever wants to store an incoming message so that it can be consulted later:

```
pub struct NetworkServer<'a> {
    // ...
    /// Most recent max-size message.
    max_size: Option<Tlv<'a>>,
}

/// Message type code for a set-maximum-size message.
const SET_MAX_SIZE: u8 = 0x01;

impl<'a> NetworkServer<'a> {
    pub fn process(&mut self, mut data: &'a [u8]) -> Result<(), Error> {
        while !data.is_empty() {
            let (tlv, rest) = get_next_tlv(data)?;
            match tlv.type_code {
                SET_MAX_SIZE => {
                    // Save off the most recent `SET_MAX_SIZE` message.
                    self.max_size = Some(tlv);
                }
                // (Deal with other message types)
                // ...
                _ => return Err("unknown message type"),
            }
            data = rest; // Process remaining data on next iteration.
        }
        Ok(())
    }
}
```

This code compiles as is but is effectively impossible to use: the lifetime of the `NetworkServer` has to be smaller
than the lifetime of any data that gets fed into its `process()` method. That means that a straightforward processing
loop:

#

```
let mut server = NetworkServer::default();
while !server.done() {
    // Read data into a fresh vector.
    let data: Vec<u8> = read_data_from_socket();
    if let Err(e) = server.process(&data) {
        log::error!("Failed to process data: {:?}", e);
    }
}
```

fails to compile because the lifetime of the ephemeral data gets attached to the longer-lived server:

```
error[E0597]: `data` does not live long enough
   --> src/main.rs:375:40
    |
372 |     while !server.done() {
    |            ------------- borrow later used here
373 |         // Read data into a fresh vector.
374 |         let data: Vec<u8> = read_data_from_socket();
    |             ---- binding `data` declared here
375 |         if let Err(e) = server.process(&data) {
    |                                        ^^^^^ borrowed value does not live
    |                                              long enough
...
378 |     }
    |     - `data` dropped here while still borrowed
```

Switching the code so it reuses a longer-lived buffer doesn’t help either:

#

```
let mut perma_buffer = [0u8; 256];
let mut server = NetworkServer::default(); // lifetime within `perma_buffer`

while !server.done() {
    // Reuse the same buffer for the next load of data.
    read_data_into_buffer(&mut perma_buffer);
    if let Err(e) = server.process(&perma_buffer) {
        log::error!("Failed to process data: {:?}", e);
    }
}
```

This time, the compiler complains that the code is trying to hang on to a reference while also handing out a mutable
reference to the same buffer:

```
error[E0502]: cannot borrow `perma_buffer` as mutable because it is also
              borrowed as immutable
   --> src/main.rs:353:31
    |
353 |         read_data_into_buffer(&mut perma_buffer);
    |                               ^^^^^^^^^^^^^^^^^ mutable borrow occurs here
354 |         if let Err(e) = server.process(&perma_buffer) {
    |                         -----------------------------
    |                         |              |
    |                         |              immutable borrow occurs here
    |                         immutable borrow later used here
```

The core problem is that the `Tlv` structure references transient data—which is fine for transient processing
but is fundamentally incompatible with storing state for later.  However, if the `Tlv` data structure is converted to
own its contents:

```
#[derive(Clone, Debug)]
pub struct Tlv {
    pub type_code: u8,
    pub value: Vec<u8>, // owned heap data
}
```

and the `get_next_tlv()` code is correspondingly tweaked to include an additional call to `.to_vec()`:

```
// ...
let tlv = Tlv {
    type_code,
    // Copy the relevant chunk of data to the heap.
    // The length field in the TLV is a single `u8`,
    // so this copies at most 256 bytes.
    value: input[2..2 + len].to_vec(),
};
```

then the server code has a much easier job.  The data-owning `Tlv` structure has no lifetime parameter, so the server
data structure doesn’t need one either, and both variants of the processing loop work fine.

## Who’s Afraid of the Big Bad Copy?

One reason why programmers can become overly obsessed with reducing copies is that Rust generally makes copies and
allocations explicit.  A visible call to a method like `.to_vec()` or `.clone()`, or to a function like `Box::new()`,
makes it clear that copying and allocation are occurring.  This is in contrast to  C++, where it’s easy to
inadvertently write code that blithely performs allocation under the covers, particularly in a copy-constructor or
assignment operator.

Making an allocation or copy operation visible rather than hidden isn’t a good reason to optimize it away, especially if
that happens at the expense of usability.  In many situations, it makes more sense to focus on usability first, and
*fine-tune for optimal efficiency only if performance is genuinely a concern*—and if
benchmarking (see [Item 30](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch05.html#file_testing_md)) indicates that reducing copies will have a significant impact.

Also, the efficiency of your code is usually important only if it needs to scale up for extensive use.  If it turns out
that the trade-offs in the code are wrong, and it doesn’t cope well when millions of users start to use it—well,
that’s a nice problem to have.

However, there are a couple of specific points to remember.  The first was hidden behind the weasel word *generally*
when pointing out that copies are generally visible.  The big exception to this is `Copy` types, where the compiler
silently makes copies willy-nilly, shifting from move semantics to copy semantics.  As such, the advice in [Item 10](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch02.html#file_std-traits_md) bears repeating here: don’t implement `Copy` unless a bitwise copy is valid and fast. But the converse is true
too: do *consider implementing `Copy` if a bitwise copy is valid and fast*. For example, `enum` types that
don’t carry additional data are usually easier to use if they derive `Copy`.

The second point that might be relevant is the potential trade-off with  `no_std` use.  [Item 33](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch06.html#file_no-std_md) suggests that it’s
often possible to write code that’s `no_std`-compatible with only minor modifications, and code that avoids allocation
altogether makes this more straightforward.  However, targeting a `no_std` environment that supports heap allocation
(via the  `alloc` library, also described in [Item 33](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch06.html#file_no-std_md)) may give the best balance of usability and `no_std` support.

## References and Smart Pointers

So very recently, I’ve consciously tried the experiment of not worrying about the hypothetical perfect code. Instead,
I call .clone() when I need to, and use Arc to get local objects into threads and futures more smoothly.

And it feels glorious.

[Josh Triplett](https://oreil.ly/1ViCT)

Designing a data structure so that it owns its contents can certainly make for better ergonomics, but there are still
potential problems if multiple data structures need to make use of the same information.  If the data is immutable, then
each place having its own copy works fine, but if the information might change (which is very commonly the case), then
multiple copies means multiple places that need to be updated, in sync with each other.

Using Rust’s smart pointer types helps solve this problem, by allowing the design to shift from a single-owner model to
a shared-owner model.  The  `Rc` (for single-threaded code) and  `Arc` (for multithreaded code) smart
pointers provide reference counting that supports this shared-ownership model.  Continuing with the assumption that
mutability is needed, they are typically paired with an inner type that allows  interior mutability, independently
of Rust’s borrow checking rules:

RefCellFor interior mutability in single-threaded code, giving the common `Rc<RefCell<T>>` combination

MutexFor interior mutability in multithreaded code (as per [Item 17](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch03.html#file_deadlock_md)), giving the common `Arc<Mutex<T>>`
combination

This transition is covered in more detail in the `GuestRegister` example in [Item 15](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch03.html#file_borrows_md), but the point here is that you
don’t have to treat Rust’s smart pointers as a last resort.  It’s not an admission of defeat if your design uses smart
pointers instead of a complex web of interconnected reference lifetimes—*smart pointers can lead to a
simpler, more maintainable, and more usable design*.

[1](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch03.html#id1018-marker) For example, the  Chromium project estimates that [70% of security bugs are due to memory safety](https://oreil.ly/GJkt0).

[2](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch03.html#id1082-marker) Note that all bets are off with expressions like `m!(value)` that involve a  macro ([Item 28](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch05.html#file_macros_md)), because that can expand to arbitrary code.

[3](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch03.html#id1093-marker) The compiler’s suggestion doesn’t help here, because `item` is needed on the subsequent line.

[4](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch03.html#id1162-marker) `Cow` stands for  clone-on-write; a copy of the underlying data is made only if a change (write) needs to be made to it.

[5](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch03.html#id1167-marker) Dealing with `async` code is beyond the scope of this book; to understand more about its need for self-referential data structures, see Chapter 8 of  [Rust for Rustaceans](https://rust-for-rustaceans.com/) by  Jon Gjengset (No Starch Press).

[6](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch03.html#id1198-marker) In practice, most of this `std` functionality is actually provided by `core` and so is available to `no_std` code as described in [Item 33](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch06.html#file_no-std_md).

[7](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch03.html#id1231-marker) The third category of behavior is  *thread-hostile*: code that’s dangerous in a multithreaded environment *even if* all access to it is externally synchronized.

[8](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch03.html#id1236-marker) The  Clang C++ compiler includes a [-Wthread-safety](https://clang.llvm.org/docs/ThreadSafetyAnalysis.html) option, sometimes known as *annotalysis*, that allows data to be annotated with information about which mutexes protect which data, and functions to be annotated with information about the locks they acquire. This gives *compile-time* errors when these invariants are broken, like Rust; however, there is nothing to enforce the use of these annotations in the first place—for example, when a thread-compatible library is used in a multithreaded environment for the first time.

[9](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch03.html#id1313-marker) Tom Cargill’s 1994 [article in the C++ Report](https://oreil.ly/J9hes) explores just how difficult exception safety is for C++ template code, as does  Herb Sutter’s [Guru of the Week #8 column](https://oreil.ly/521d9).

[10](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch03.html#id1382-marker) The field can’t be named `type` because that’s a reserved keyword in Rust.  It’s possible to work around this restriction by using the  [raw identifier prefix](https://oreil.ly/oC8VO) `r#` (giving a field `r#type: u8`), but it’s normally easier just to rename the field.

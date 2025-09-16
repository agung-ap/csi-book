# Chapter 5. Expressions

# A Note for Early Release Readers

With Early Release ebooks, you get books in their earliest form—the author’s raw and unedited content as they write—so you can take advantage of these technologies long before the official release of these titles.

This will be the 6th chapter of the final book. Please note that the GitHub repo will be made active later on.

If you’d like to be actively involved in reviewing and commenting on this draft, please reach out to the editor at *jbleiel@oreilly.com*.

LISP programmers know the value of everything, but the cost of nothing.

Alan Perlis, epigram #55

In this chapter, we’ll cover the *expressions* of Rust, the building blocks that make up the body of Rust functions and thus the majority of Rust code. We’ll cover control flow, including `if` and `match` expressions, loops, and function calls, which in Rust are all expressions, and we’ll examine how Rust’s foundational operators work in isolation and in combination.

A few concepts that technically fall into this category, such as closures and iterators, are deep enough that we will dedicate a whole chapter to them later. For now, we aim to cover as much syntax as possible in a few pages.

# An Expression Language

Rust visually resembles the C family of languages, but this is a bit of a ruse. In C, there is a sharp distinction between *expressions,* bits of code that look something like this:

```
5 * (fahr-32) / 9
```

and *statements,* which look more like this:

```
for (; begin != end; ++begin) {
    if (*begin == target)
        break;
}
```

Expressions have values. Statements don’t.

Rust is what is called an *expression language*. This means it follows an older tradition, dating back to Lisp, where expressions do all the work.

In C, `if` and `switch` are statements. They don’t produce a value, and they can’t be used in the middle of an expression. In Rust, `if` and `match` *can* produce values. We already saw a `match` expression that produces a numeric value in [Chapter 1](https://learning.oreilly.com/library/view/programming-rust-3rd/9781098176228/ch01.html#a-tour-of-rust):

```
pixels[r * bounds.0 + c] =
    match escapes(Complex { re: point.0, im: point.1 }, 255) {
        None => 0,
        Some(count) => 255 - count as u8,
    };
```

An `if` expression can be used to initialize a variable:

```
let status =
    if cpu.temperature <= MAX_TEMP {
        HttpStatus::Ok
    } else {
        HttpStatus::ServerError  // server melted
    };
```

A `match` expression can be passed as an argument to a function or macro:

```
println!("Inside the vat, you see {}.",
    match vat.contents {
        Some(brain) => brain.desc(),
        None => "nothing of interest",
    });
```

This explains why Rust does not have C’s ternary operator (`expr1 ? expr2 : expr3`). In C, it is a handy expression-level analogue to the `if` statement. It would be redundant in Rust: the `if` expression handles both cases.

Most of the control flow tools in C are statements. In Rust, they are all expressions.

# Operator Precedence and Associativity

[Table 5-1](https://learning.oreilly.com/library/view/programming-rust-3rd/9781098176228/ch05.html#expressions-table) summarizes Rust expression syntax. We will discuss all of these kinds of expressions in this chapter. Operators are grouped by precedence and ordered from highest precedence to lowest. (Like most programming languages, Rust has *operator precedence* to determine the order of operations when an expression contains multiple adjacent operators. For example, in `limit < 2 * broom.size + 1`, the `.` operator has the highest precedence, so the field access happens first.)

| Expression type | Example |
| --- | --- |
| Array literal | `[1, 2, 3]` |
| Repeat array literal | `[0; 50]` |
| Tuple | `(6, "crullers")` |
| Grouping | `(2 + 2)` |
| Block | `{ f(); g() }` |
| Control flow expressions | `if ok { f() }` |
| `if ok { 1 } else { 0 }` |  |
| `if let Some(x) = f() { x } else { 0 }` |  |
| `match x { None => 0, _ => 1 }` |  |
| `for v in e { f(v); }` |  |
| `while ok { ok = f(); }` |  |
| `while let Some(x) = it.next() { f(x); }` |  |
| `loop { next_event(); }` |  |
| `break` |  |
| `continue` |  |
| `return 0` |  |
| Macro invocation | `println!("ok")` |
| Path | `std::f64::consts::PI` |
| Struct literal | `Point {x: 0, y: 0}` |
| Tuple field access | `pair.0` |
| Struct field access | `point.x` |
| Method call | `point.translate(50, 50)` |
| Function call | `stdin()` |
| Index | `arr[0]` |
| `Err`/`None` early return | `create_dir("tmp")?` |
| Logical/bitwise NOT | `!ok` |
| Negation | `-num` |
| Dereference | `*ptr` |
| Borrow | `&val` |
| Type cast | `x as u32` |
| Multiplication | `n * 2` |
| Division | `n / 2` |
| Remainder (modulus) | `n % 2` |
| Addition | `n + 1` |
| Subtraction | `n - 1` |
| Left shift | `n << 1` |
| Right shift | `n >> 1` |
| Bitwise AND | `n & 1` |
| Bitwise exclusive OR | `n ^ 1` |
| Bitwise OR | `n \| 1` |
| Less than | `n < 1` |
| Less than or equal | `n <= 1` |
| Greater than | `n > 1` |
| Greater than or equal | `n >= 1` |
| Equal | `n == 1` |
| Not equal | `n != 1` |
| Logical AND | `x.ok && y.ok` |
| Logical OR | `x.ok \|\| backup.ok` |
| End-exclusive range | `start..stop` |
| End-inclusive range | `start..=stop` |
| Assignment | `x = val` |
| Compound assignment | `x *= 1` |
| `x /= 1` |  |
| `x %= 1` |  |
| `x += 1` |  |
| `x -= 1` |  |
| `x <<= 1` |  |
| `x >>= 1` |  |
| `x &= 1` |  |
| `x ^= 1` |  |
| `x \|= 1` |  |
| Closure | `\|x, y\| x + y` |

The arithmetic and bitwise operations and their associated compound assignments can be overloaded with arbitrary behavior for user-defined types, as discussed in [Chapter 11](https://learning.oreilly.com/library/view/programming-rust-3rd/9781098176228/ch11.html#operator-overloading).

All of the operators that can usefully be chained are left-associative. That is, a chain of operations such as `a - b - c` is grouped as `(a - b) - c`, not `a - (b - c)`. The operators that can be chained in this way are all the ones you might expect:

```
*   /   %   +   -   <<   >>   &   ^   |   &&   ||   as
```

The comparison operators, the assignment operators, and the range operators `..` and `..=` can’t be chained at all.

# Blocks

Blocks are the most general kind of expression. A block produces a value and can be used anywhere a value is needed:

```
let display_name = match post.author() {
    Some(author) => author.name(),
    None => {
        let network_info = post.get_network_metadata()?;
        let ip = network_info.client_address();
        ip.to_string()
    }
};
```

The code after `Some(author) =>` is the simple expression `author.name()`. The code after `None =>` is a block expression. It makes no difference to Rust. The value of the block is the value of its last expression, `ip.to_string()`.

Note that there is no semicolon after the `ip.to_string()` method call. Most lines of Rust code do end with either a semicolon or curly braces, just like C or Java. And if a block looks like C code, with semicolons in all the familiar places, then it will run just like a C block, and its value will be `()`. As we mentioned in [Chapter 1](https://learning.oreilly.com/library/view/programming-rust-3rd/9781098176228/ch01.html#a-tour-of-rust), when you leave the semicolon off the last line of a block, that makes the value of the block the value of its final expression, rather than the usual `()`.

In some languages, particularly JavaScript, you’re allowed to omit semicolons, and the language simply fills them in for you—a minor convenience. This is different. In Rust, the semicolon actually means something:

```
let msg = {
    // let-declaration: semicolon is always required
    let dandelion_control = puffball.open();

    // expression + semicolon: method is called, return value dropped
    dandelion_control.release_all_seeds(launch_codes);

    // expression with no semicolon: method is called,
    // return value stored in `msg`
    dandelion_control.get_status()
};
```

This ability of blocks to contain declarations and also produce a value at the end is a neat feature, one that quickly comes to feel natural. The one drawback is that it leads to an odd error message when you leave out a semicolon by accident:

```
...
if preferences.changed() {
    page.compute_size()  // oops, missing semicolon
}
...
```

If you made this mistake in a C or Java program, the compiler would simply point out that you’re missing a semicolon. Here’s what Rust says:

```
error: mismatched types
22 |         page.compute_size()  // oops, missing semicolon
   |         ^^^^^^^^^^^^^^^^^^^- help: try adding a semicolon: `;`
   |         |
   |         expected (), found tuple
   |
   = note: expected unit type `()`
              found tuple `(u32, u32)`
```

With the semicolon missing, the block’s value would be whatever `page.compute_size()` returns, but an `if` without an `else` must always return `()`. Fortunately, Rust has seen this sort of thing before and suggests adding the semicolon.

A block can also be *labeled* with a lifetime. This label can be used with `break` to exit early with a value, similarly to `return` in a function. In the following example, `'trim` is a label for the overall block. `break` exits the named block immediately, and it evalues to the given value:

```
let trimmed = 'trim: {
    if string.chars().last() != Some('\n') {
        break 'trim None;
    }
    string.pop();
    if string.chars().last() != Some('\r') {
        break 'trim Some(Newline::Unix);
    }
    string.pop();
    Some(Newline::Windows)
};
```

This is similar to a deeply nested `if ... else` chain, but can be more readable for a series of side effects.

# Declarations

In addition to expressions and semicolons, a block may contain any number of declarations. The most common are `let` declarations, which declare local variables:

```
let name: type = expr;
```

The type and initializer are optional. The semicolon is required. Like all identifiers in Rust, variable names must start with a letter or underscore, and can contain digits only after that first character. Rust has a broad definition of “letter”: it includes Greek letters, accented Latin characters, and many more symbols—anything that Unicode Standard Annex #31 declares suitable. Emoji aren’t allowed.

A `let` declaration can declare a variable without initializing it. The variable can then be initialized with a later assignment. This is occasionally useful, because sometimes a variable should be initialized from the middle of some sort of control flow construct:

```
let name;
if user.has_nickname() {
    name = user.nickname();
} else {
    name = generate_unique_name();
    user.register(&name);
}
```

Here there are two different ways the local variable `name` might be initialized, but either way it will be initialized exactly once, so `name` does not need to be declared `mut`.

It’s an error to use a variable before it’s initialized. (This is closely related to the error of using a value after it’s been moved. Rust really wants you to use values only while they exist!)

You may occasionally see code that seems to redeclare an existing variable, like this:

```
for line in file.lines() {
    let line = line?;
    ...
}
```

The `let` declaration creates a new, second variable, of a different type. The type of the first variable `line` is `Result<String, io::Error>`. The second `line` is a `String`. Its definition supersedes the first’s for the rest of the block. This is called *shadowing* and is very common in Rust programs. The code is equivalent to:

```
for line_result in file.lines() {
    let line = line_result?;
    ...
}
```

In this book, we’ll stick to using a `_result` suffix in such situations so that the variables have distinct names. In real-world code, however, shadowing can be useful to prevent future code from incorrectly referring to the previous value. Since that name now refers to the new value instead, it’s impossible to do so by mistake.

A block can also contain *item declarations*. An item is simply any declaration that could appear globally in a program or module, such as a `fn`, `struct`, or `use`.

Later chapters will cover items in detail. For now, `fn` makes a sufficient example. Any block may contain a `fn`:

```
use std::io;
use std::cmp::Ordering;

fn show_files() -> io::Result<()> {
    let mut v = vec![];
    ...

    fn cmp_by_timestamp_then_name(a: &FileInfo, b: &FileInfo) -> Ordering {
        a.timestamp.cmp(&b.timestamp)   // first, compare timestamps
            .reverse()                  // newest file first
            .then(a.path.cmp(&b.path))  // compare paths to break ties
    }

    v.sort_by(cmp_by_timestamp_then_name);
    ...
}
```

When a `fn` is declared inside a block, its scope is the entire block—that is, it can be *used* throughout the enclosing block. But a nested `fn` cannot access local variables or arguments that happen to be in scope. For example, the function `cmp_by_timestamp_then_name` could not use `v` directly. (Rust also has closures, which do see into enclosing scopes. See [Link to Come].)

A block can even contain a whole module. This may seem a bit much—do we really need to be able to nest *every* piece of the language inside every other piece?—but programmers (and particularly programmers using macros) have a way of finding uses for every scrap of orthogonality the language provides.

# if and match

The form of an `if` expression is familiar:

```
if condition1 {
    block1
} else if condition2 {
    block2
} else {
    block_n
}
```

Each `condition` must be an expression of type `bool`; true to form, Rust does not implicitly convert numbers or pointers to Boolean values.

Unlike C, parentheses are not required around conditions. In fact, `rustc` will emit a warning if unnecessary parentheses are present. The curly braces, however, are required.

The `else if` blocks, as well as the final `else`, are optional. An `if` expression with no `else` block behaves exactly as though it had an empty `else` block.

`match` expressions are something like the C `switch` statement, but more flexible. A simple example:

```
match code {
=> println!("OK"),
=> println!("Wires Tangled"),
=> println!("User Asleep"),
    _ => println!("Unrecognized Error {code}"),
}
```

This is something a `switch` statement could do. Exactly one of the four arms of this `match` expression will execute, depending on the value of `code`. The wildcard pattern `_` matches everything. This is like the `default:` case in a `switch` statement, except that it must come last; placing a `_` pattern before other patterns means that it will have precedence over them. Those patterns will never match anything (and the compiler will warn you about it).

The compiler can optimize this kind of `match` using a jump table, just like a `switch` statement in C‍++. A similar optimization is applied when each arm of a `match` produces a constant value. In that case, the compiler builds an array of those values, and the `match` is compiled into an array access. Apart from a bounds check, there is no branching at all in the compiled code.

The versatility of `match` stems from the variety of supported *patterns* that can be used to the left of `=>` in each arm. Above, each pattern is simply a constant integer. We’ve also shown `match` expressions that distinguish the two kinds of `Option` value:

```
match params.get("name") {
    Some(name) => println!("Hello, {name}!"),
    None => println!("Greetings, stranger."),
}
```

This is only a hint of what patterns can do. A pattern can match a range of values. It can unpack tuples. It can match against individual fields of structs. It can chase references, borrow parts of a value, and more. Rust’s patterns are a mini-language of their own. We’ll dedicate several pages to them in [Chapter 9](https://learning.oreilly.com/library/view/programming-rust-3rd/9781098176228/ch09.html#enums-and-patterns).

The general form of a `match` expression is:

```
match value {
    pattern => expr,
    ...
}
```

The comma after an arm may be dropped if the `expr` is a block.

Rust checks the given `value` against each pattern in turn, starting with the first. When a pattern matches, the corresponding `expr` is evaluated, and the `match` expression is complete; no further patterns are checked. At least one of the patterns must match. Rust prohibits `match` expressions that do not cover all possible values:

```
let score = match card.rank {
    Jack => 10,
    Queen => 10,
    Ace => 11,
};  // error: nonexhaustive patterns
```

All blocks of an `if` expression must produce values of the same type:

```
let suggested_pet =
    if with_wings { Pet::Buzzard } else { Pet::Hyena };  // ok

let favorite_number =
    if user.is_hobbit() { "eleventy-one" } else { 9 };  // error

let best_sports_team =
    if is_hockey_season() { "Predators" };  // error
```

(The last example is an error because in July, the result would be `()`.)

Similarly, all arms of a `match` expression must have the same type:

```
let suggested_pet =
    match favorites.element {
        Fire => Pet::RedPanda,
        Air => Pet::Buffalo,
        Water => Pet::Orca,
        _ => None,  // error: incompatible types
    };
```

# if let

There is one more `if` form, the `if let` expression:

```
if let pattern = expr {
    block1
} else {
    block2
}
```

The given `expr` either matches the `pattern`, in which case `block1` runs, or doesn’t match, and `block2` runs. Sometimes this is a nice way to get data out of an `Option` or `Result`:

```
if let Some(cookie) = request.session_cookie {
    return restore_session(cookie);
}

if let Err(err) = show_cheesy_anti_robot_task() {
    log_robot_attempt(err);
    politely_accuse_user_of_being_a_robot();
} else {
    session.mark_as_human();
}
```

It’s never strictly *necessary* to use `if let`, because `match` can do everything `if let` can do. An `if let` expression is shorthand for a `match` with just one pattern:

```
match expr {
    pattern => { block1 }
    _ => { block2 }
}
```

# let else

When there is only one acceptable pattern, Rust provides a convenient shorthand, the `let ... else` statement:

```
let pattern: type = expr else {
    divergent block
}
```

For instance, application code often needs to open a particular file in order to work, and exit otherwise. With `let ... else`, this can be written concisely as:

```
let Ok(config_file) = File::open(&config_path) else {
    panic!("Unable to open config file {}.", config_path.display());
};
let config = parse_config(config_file);
```

The else block must always be something that ends the flow of execution, such as a panic, `return`, `break`, or `continue`. (This is called “diverging”, and is discussed further below.) `let ... else` is convenient for many common control flow patterns, but like `if let`, it is always possible to do the same thing via `match`:

```
let name = match expr {
    pattern => { convergent block }
    _ => { divergent block }
}
```

# Loops

There are four looping expressions:

```
while condition {
    block
}

while let pattern = expr {
    block
}

loop {
    block
}

for pattern in iterable {
    block
}
```

Loops are expressions in Rust, but the value of a `while` or `for` loop is always `()`, so their value isn’t very useful. A `loop` expression can produce a value via the `break` keyword.

A `while` loop behaves exactly like the C equivalent, except that, again, the `condition` must be of the exact type `bool`.

The `while let` loop is analogous to `if let`. At the beginning of each loop iteration, the value of `expr` either matches the given `pattern`, in which case the block runs, or doesn’t, in which case the loop exits.

Use `loop` to write infinite loops. It executes the `block` repeatedly forever (or until a `break` or `return` is reached or the thread panics).

A `for` loop evaluates the `iterable` expression and then evaluates the `block` once for each value in the resulting iterator. Many types can be iterated over, including all the standard collections like `Vec` and `HashMap`. The standard C `for` loop:

```
for (int i = 0; i < 20; i++) {
    printf("%d\n", i);
}
```

is written like this in Rust:

```
for i in 0..20 {
    println!("{i}");
}
```

As in C, the last number printed is `19`.

The `..` operator produces a *range*, a simple struct with two fields: `start` and `end`. `0..20` is the same as `std::ops::Range { start: 0, end: 20 }`. Ranges can be used with `for` loops because `Range` is an iterable type: it implements the `std::iter::IntoIterator` trait, which we’ll discuss in [Link to Come]. The standard collections are all iterable, as are arrays and slices.

In keeping with Rust’s move semantics, a `for` loop over a value consumes the value:

```
let strings: Vec<String> = error_messages();
for s in strings {          // each String is moved into s here...
    println!("{s}");
}                           // ...and dropped here
println!("{} error(s)", strings.len());  // error: use of moved value
```

This can be inconvenient. The easy remedy is to loop over a reference to the collection instead. The loop variable, then, will be a reference to each item in the collection:

```
for s in &strings {         // `strings` is only borrowed here...
    println!("{s}");
}                           // ...nothing is moved or deallocated
println!("{} error(s)", strings.len());  // ok
```

Here the type of `&strings` is `&Vec<String>`, and the type of `s` is `&String`.

Iterating over a `mut` reference provides a `mut` reference to each element:

```
let mut strings = error_messages();
for s in &mut strings {     // the type of s is &mut String
    s.push('\n');           // add a newline to each string
}
```

[Link to Come] covers `for` loops in greater detail and shows many other ways to use iterators.

# break and continue Expressions

A `break` expression exits an enclosing loop. (In Rust, `break` works only in loops and labeled blocks. It is not necessary in `match` expressions, which are unlike `switch` statements in this regard.)

Within the body of a `loop`, you can give `break` an expression, whose value becomes that of the loop:

```
// Each call to `next_line` returns either `Some(line)`, where
// `line` is a line of input, or `None`, if we've reached the end of
// the input. Return the first line that starts with "answer: ".
// Otherwise, return "answer: nothing".
let answer = loop {
    if let Some(line) = next_line() {
        if line.starts_with("answer: ") {
            break line;
        }
    } else {
        break "answer: nothing";
    }
};
```

A `break` expression can only take a value in a `loop` (or a labeled block), unlike `for` and `while` loops, where `break` is only used to end the loop early. All the `break` expressions within a `loop` must produce values with the same type, which becomes the type of the `loop` itself.

A `continue` expression jumps to the next loop iteration:

```
// Read some data, one line at a time.
for line in input_lines {
    let trimmed = trim_comments_and_whitespace(line);
    if trimmed.is_empty() {
        // Jump back to the top of the loop and
        // move on to the next line of input.
        continue;
    }
    ...
}
```

In a `for` loop, `continue` advances to the next value in the collection. If there are no more values, the loop exits. Similarly, in a `while` loop, `continue` rechecks the loop condition. If it’s now false, the loop exits.

A loop can be labeled with a lifetime, just like a block. In the following example, `'search:` is a label for the outer `for` loop. Thus, `break 'search` exits that loop, not the inner loop:

```
'search:
for room in apartment {
    for spot in room.hiding_spots() {
        if spot.contains(keys) {
            println!("Your keys are {spot} in the {room}.");
            break 'search;
        }
    }
}
```

A `break` can have both a label and a value expression:

```
// Find the square root of the first perfect square
// in the series.
let sqrt = 'outer: loop {
    let n = next_number();
    for i in 1.. {
        let square = i * i;
        if square == n {
            // Found a square root.
            break 'outer i;
        }
        if square > n {
            // `n` isn't a perfect square, try the next
            break;
        }
    }
};
```

Labels can also be used with `continue`.

# return Expressions

A `return` expression exits the current function, returning a value to the caller.

`return` without a value is shorthand for `return ()`:

```
fn f() {     // return type omitted: defaults to ()
    return;  // return value omitted: defaults to ()
}
```

Functions don’t have to have an explicit `return` expression. The body of a function works like a block expression: if the last expression isn’t followed by a semicolon, its value is the function’s return value. In fact, this is the preferred way to supply a function’s return value in Rust.

But this doesn’t mean that `return` is useless, or merely a concession to users who aren’t experienced with expression languages. Like a `break` expression, `return` can abandon work in progress. For example, in [Chapter 1](https://learning.oreilly.com/library/view/programming-rust-3rd/9781098176228/ch01.html#a-tour-of-rust), we used the `?` operator to check for errors after calling a function that can fail:

```
let output = File::create(filename)?;
```

We explained that this is shorthand for a `match` expression:

```
let output = match File::create(filename) {
    Ok(f) => f,
    Err(err) => return Err(err),
};
```

This code starts by calling `File::create(filename)`. If that returns `Ok(f)`, then the whole `match` expression evaluates to `f`, so `f` is stored in `output`, and we continue with the next line of code following the `match`.

Otherwise, we’ll match `Err(err)` and hit the `return` expression. When that happens, it doesn’t matter that we’re in the middle of evaluating a `match` expression to determine the value of the variable `output`. We abandon all of that and exit the enclosing function, returning whatever error we got from `File::create()`.

We’ll cover the `?` operator more completely in [“Propagating Errors”](https://learning.oreilly.com/library/view/programming-rust-3rd/9781098176228/ch06.html#propagating-errors).

# Why Rust Has loop

Several pieces of the Rust compiler analyze the flow of control through your program:

-

Rust checks that every path through a function returns a value of the expected return type. To do this correctly, it needs to know whether it’s possible to reach the end of the function.

-

Rust checks that local variables are never used uninitialized. This entails checking every path through a function to make sure there’s no way to reach a place where a variable is used without having already passed through code that initializes it.

-

Rust warns about unreachable code. Code is unreachable if *no* path through the function reaches it.

These are called *flow-sensitive* analyses. They are nothing new; Java has had a “definite assignment” analysis, similar to Rust’s, for years.

When enforcing this sort of rule, a language must strike a balance between simplicity, which makes it easier for programmers to figure out what the compiler is talking about sometimes, and cleverness, which can help eliminate false warnings and cases where the compiler rejects a perfectly safe program. Rust went for simplicity. Its flow-sensitive analyses do not examine loop conditions at all, instead simply assuming that any condition in a program can be either true or false.

This causes Rust to reject some safe programs:

```
fn wait_for_process(process: &mut Process) -> i32 {
    while true {
        if process.wait() {
            return process.exit_code();
        }
    }
}  // error: mismatched types: expected i32, found ()
```

The error here is bogus. This function only exits via the `return` statement, so the fact that the `while` loop doesn’t produce an `i32` is irrelevant.

The `loop` expression is offered as a “say-what-you-mean” solution to this problem.

Rust’s type system is affected by control flow, too. Earlier we said that all branches of an `if` expression must have the same type. But it would be silly to enforce this rule on blocks that end with a `break` or `return` expression, an infinite `loop`, or a call to `panic!()` or `std::process::exit()`. What all those expressions have in common is that they never finish in the usual way, producing a value. A `break` or `return` exits the current block abruptly, a `loop` without a `break` never finishes at all, and so on.

So in Rust, these expressions don’t have a normal type. Expressions that don’t finish normally are assigned the special type `!`, and they’re exempt from the rules about types having to match. You can see `!` in the function signature of `std::process::exit()`:

```
fn exit(code: i32) -> !
```

The `!` means that `exit()` never returns. It’s a *divergent function*.

You can write divergent functions of your own using the same syntax, and this is perfectly natural in some cases:

```
fn serve_forever(socket: ServerSocket, handler: ServerHandler) -> ! {
    socket.listen();
    loop {
        let s = socket.accept();
        handler.handle(s);
    }
}
```

Of course, Rust then considers it an error if the function can return normally.

With these building blocks of large-scale control flow in place, we can move on to the finer-grained expressions typically used within that flow, like function calls and arithmetic operators.

# Function and Method Calls

The syntax for calling functions and methods is the same in Rust as in many other languages:

```
let x = gcd(1302, 462);  // function call

let room = player.location();  // method call
```

In the second example here, `player` is a variable of the made-up type `Player`, which has a made-up `.location()` method. (We’ll show how to define your own methods when we start talking about user-defined types in [Chapter 8](https://learning.oreilly.com/library/view/programming-rust-3rd/9781098176228/ch08.html#structs).)

Rust usually makes a sharp distinction between references and the values they refer to. If you pass a `&i32` to a function that expects an `i32`, that’s a type error. You’ll notice that the `.` operator relaxes those rules a bit. In the method call `player.location()`, `player` might be a `Player`, a reference of type `&Player`, or a smart pointer of type `Box<Player>` or `Rc<Player>`. The `.location()` method might take the player either by value or by reference. The same `.location()` syntax works in all cases, because Rust’s `.` operator automatically dereferences `player` or borrows a reference to it as needed.

A third syntax is used for calling type-associated functions, like `Vec::new()`:

```
let mut numbers = Vec::new();  // type-associated function call
```

These are similar to static methods in object-oriented languages: ordinary methods are called on values (like `my_vec.len()`), and type-associated functions are called on types (like `Vec::new()`).

Naturally, method calls can be chained:

```
// From the Actix-based web server in Chapter 2:
server
    .bind("127.0.0.1:3000").expect("error binding server to address")
    .run().expect("error running server");
```

One quirk of Rust syntax is that in a function call or method call, the usual syntax for generic types, `Vec<T>`, does not work:

```
return Vec<i32>::with_capacity(1000);  // error: something about chained comparisons

let ramp = (0..n).collect<Vec<i32>>();  // same error
```

The problem is that in expressions, `<` is the less-than operator. The Rust compiler helpfully suggests writing `::<T>` instead of `<T>` in this case, and that solves the problem:

```
return Vec::<i32>::with_capacity(1000);  // ok, using ::<

let ramp = (0..n).collect::<Vec<i32>>();  // ok, using ::<
```

The symbol `::<...>` is affectionately known in the Rust community as the *turbofish*.

Alternatively, it is often possible to drop the type parameters and let Rust infer them:

```
return Vec::with_capacity(10);  // ok, if the fn return type is Vec<i32>

let ramp: Vec<i32> = (0..n).collect();  // ok, variable's type is given
```

It’s considered good style to omit the types whenever they can be inferred.

# Fields and Elements

The fields of a struct are accessed using familiar syntax. Tuples are the same except that their fields have numbers rather than names:

```
game.black_pawns   // struct field
coords.1           // tuple field
```

If the value to the left of the dot is a reference or smart pointer type, it is automatically dereferenced, just as for method calls.

Square brackets access the elements of an array, slice, or vector:

```
pieces[i]          // array element
```

The value to the left of the brackets is automatically dereferenced.

Expressions like these three are called *lvalues*, because they can appear on the left side of an assignment:

```
game.black_pawns = 0x00ff0000_00000000_u64;
coords.1 = 0;
pieces[2] = Some(Piece::new(Black, Knight, coords));
```

Of course, this is permitted only if `game`, `coords`, and `pieces` are declared as `mut` variables.

Extracting a slice from an array or vector is straightforward:

```
let second_half = &game_moves[midpoint..end];
```

Here `game_moves` may be either an array, a slice, or a vector; the result, regardless, is a borrowed slice of length `end - midpoint`. `game_moves` is considered borrowed for the lifetime of `second_half`.

The `..` operator allows either operand to be omitted; it produces up to four different types of object depending on which operands are present:

```
..      // RangeFull
a..     // RangeFrom { start: a }
..b     // RangeTo { end: b }
a..b    // Range { start: a, end: b }
```

The latter two forms are *end-exclusive* (or *half-open*): the end value is not included in the range represented. For example, the range `0..3` includes the numbers `0`, `1`, and `2`.

The `..=` operator produces *end-inclusive* (or *closed*) ranges, which do include the end value:

```
..=b     // RangeToInclusive { end: b }
a..=b    // RangeInclusive::new(a, b)
```

For example, the range `0..=3` includes the numbers `0`, `1`, `2`, and `3`.

Only ranges that include a start value are iterable, since a loop must have somewhere to start. But in array slicing, all six forms are useful. If the start or end of the range is omitted, it defaults to the start or end of the data being sliced.

So an implementation of quicksort, the classic divide-and-conquer sorting algorithm, might look, in part, like this:

```
fn quicksort<T: Ord>(slice: &mut [T]) {
    if slice.len() <= 1 {
        return;  // Nothing to sort.
    }

    // Partition the slice into two parts, front and back.
    let pivot_index = partition(slice);

    // Recursively sort the front half of `slice`.
    quicksort(&mut slice[.. pivot_index]);

    // And the back half.
    quicksort(&mut slice[pivot_index + 1 ..]);
}
```

# Reference Operators

The address-of operators, `&` and `&mut`, are covered in [Chapter 4](https://learning.oreilly.com/library/view/programming-rust-3rd/9781098176228/ch04.html#references).

The unary `*` operator is used to access the value pointed to by a reference. As we’ve seen, Rust automatically follows references when you use the `.` operator to access a field or method, so the `*` operator is necessary only when we want to read or write the entire value that the reference points to.

For example, sometimes an iterator produces references, but the program needs the underlying values:

```
let padovan: Vec<u64> = compute_padovan_sequence(n);
for elem in &padovan {
    draw_triangle(turtle, *elem);
}
```

In this example, the type of `elem` is `&u64`, so `*elem` is a `u64`.

# Arithmetic, Bitwise, Comparison, and Logical Operators

Rust’s binary operators are like those in many other languages. To save time, we assume familiarity with one of those languages, and focus on the few points where Rust departs from tradition.

Rust has the usual arithmetic operators, `+`, `-`, `*`, `/`, and `%`. As mentioned in [Chapter 2](https://learning.oreilly.com/library/view/programming-rust-3rd/9781098176228/ch02.html#fundamental-types), integer overflow is detected, and causes a panic, in debug builds. The standard library provides methods like `a.wrapping_add(b)` for unchecked arithmetic.

Integer division rounds toward zero, and dividing an integer by zero triggers a panic even in release builds. Integers have a method `a.checked_div(b)` that returns an `Option` (`None` if `b` is zero) and never panics.

Unary `-` negates a number. It is supported for all the numeric types except unsigned integers. There is no unary `+` operator.

```
println!("{}", -100);     // -100
println!("{}", -100u32);  // error: can't apply unary `-` to type `u32`
println!("{}", +100);     // error: leading `+` is not supported
```

As in C, `a % b` computes the signed remainder, or modulus, of division rounding toward zero. The result has the same sign as the lefthand operand. Note that `%` can be used on floating-point numbers as well as integers:

```
let x = 1234.567 % 10.0;  // approximately 4.567
```

Rust also inherits C’s bitwise integer operators, `&`, `|`, `^`, `<<`, and `>>`. However, Rust uses `!` instead of `~` for bitwise NOT:

```
let hi: u8 = 0xe0;
let lo = !hi;  // 0x1f
```

This means that `!n` can’t be used on an integer `n` to mean “n is zero.” For that, write `n == 0`.

Bit shifting is always sign-extending on signed integer types and zero-extending on unsigned integer types. Since Rust has unsigned integers, it does not need an unsigned shift operator, like Java’s `>>>` operator.

Bitwise operations have higher precedence than comparisons, unlike C, so if you write `x & BIT != 0`, that means `(x & BIT) != 0`, as you probably intended. This is much more useful than C’s interpretation, `x & (BIT != 0)`, which tests the wrong bit!

Rust’s comparison operators are `==`, `!=`, `<`, `<=`, `>`, and `>=`. The two values being compared must have the same type.

Rust also has the two short-circuiting logical operators `&&` and `||`. Both operands must have the exact type `bool`.

# Assignment

The `=` operator can be used to assign to `mut` variables and their fields or elements. But assignment is not as common in Rust as in other languages, since variables are immutable by default.

As described in [Chapter 3](https://learning.oreilly.com/library/view/programming-rust-3rd/9781098176228/ch03.html#ownership), if the value has a non-`Copy` type, assignment *moves* it into the destination. Ownership of the value is transferred from the source to the destination. The destination’s prior value, if any, is dropped.

Compound assignment is supported:

```
total += item.price;
```

This is equivalent to `total = total + item.price;`. Other operators are supported too: `-=`, `*=`, and so forth. The full list is given in [Table 5-1](https://learning.oreilly.com/library/view/programming-rust-3rd/9781098176228/ch05.html#expressions-table), earlier in this chapter.

Unlike C, Rust doesn’t support chaining assignment: you can’t write `a = b = 3` to assign the value `3` to both `a` and `b`. Assignment is rare enough in Rust that you won’t miss this shorthand.

Rust does not have C’s increment and decrement operators `++` and `--`.

# Type Casts

Converting a value from one type to another usually requires an explicit cast in Rust. Casts use the `as` keyword:

```
let x = 17;              // x is type i32
let index = x as usize;  // convert to usize
```

Several kinds of casts are permitted:

-

Numbers may be cast from any of the built-in numeric types to any other.

Casting an integer to another integer type is always well-defined. Converting to a narrower type results in truncation. A signed integer cast to a wider type is sign-extended, an unsigned integer is zero-extended, and so on. In short, there are no surprises.

Converting from a floating-point type to an integer type rounds toward zero: the value of `-1.99 as i32` is `-1`. If the value is too large to fit in the integer type, the cast produces the closest value that the integer type can represent: the value of `1e6 as u8` is `255`.

-

Values of type `bool` or `char`, or of a C-like `enum` type, may be cast to any integer type. (We’ll cover enums in [Chapter 9](https://learning.oreilly.com/library/view/programming-rust-3rd/9781098176228/ch09.html#enums-and-patterns).)

Casting in the other direction is not allowed, as `bool`, `char`, and `enum` types all have restrictions on their values that would have to be enforced with run-time checks. For example, casting a `u16` to type `char` is banned because some `u16` values, like `0xd800`, correspond to Unicode surrogate code points and therefore would not make valid `char` values. There is a standard method, `std::char::from_u32()`, which performs the run-time check and returns an `Option<char>`; but more to the point, the need for this kind of conversion has grown rare. We typically convert whole strings or streams at once, and algorithms on Unicode text are often nontrivial and best left to libraries.

As an exception, a `u8` may be cast to type `char`, since all integers from 0 to 255 are valid Unicode code points for `char` to hold.

-

Some casts involving unsafe pointer types are also allowed. See [Link to Come].

We said that a conversion *usually* requires a cast. A few conversions involving reference types are so straightforward that the language performs them even without a cast. One trivial example is converting a `mut` reference to a non-`mut` reference.

Several more significant automatic conversions can happen, though:

-

Values of type `&String` auto-convert to type `&str` without a cast.

-

Values of type `&Vec<i32>` auto-convert to `&[i32]`.

-

Values of type `&Box<Chessboard>` auto-convert to `&Chessboard`.

These are called *deref coercions*, because they apply to types that implement the `Deref` built-in trait. The purpose of `Deref` coercion is to make smart pointer types, like `Box`, behave as much like the underlying value as possible. Using a `Box<Chessboard>` is mostly just like using a plain `Chessboard`, thanks to `Deref`.

User-defined types can implement the `Deref` trait, too. When you need to write your own smart pointer type, see [Link to Come].

# Closures

Rust has *closures*, lightweight function-like values. A closure usually consists of an argument list, given between vertical bars, followed by an expression:

```
let is_even = |x| x % 2 == 0;
```

Rust infers the argument types and return type. You can also write them out explicitly, as you would for a function. If you do specify a return type, then the body of the closure must be a block, for the sake of syntactic sanity:

```
let is_even = |x: u64| -> bool x % 2 == 0;  // error

let is_even = |x: u64| -> bool { x % 2 == 0 };  // ok
```

Calling a closure uses the same syntax as calling a function:

```
assert_eq!(is_even(14), true);
```

Closures are one of Rust’s most delightful features, and there is a great deal more to be said about them. We shall say it in [Link to Come].

# Onward

Expressions are what we think of as “running code.” They’re the part of a Rust program that compiles to machine instructions. Yet they are a small fraction of the whole language.

The same is true in most programming languages. The first job of a program is to run, but that’s not its only job. Programs have to communicate. They have to be testable. They have to stay organized and flexible so that they can continue to evolve. They have to interoperate with code and services built by other teams. And even just to run, programs in a statically typed language like Rust need some more tools for organizing data than just tuples and arrays.

Coming up, we’ll spend several chapters talking about features in this area: modules and crates, which give your program structure, and then structs and enums, which do the same for your data.

First, we’ll dedicate a few pages to the important topic of what to do when things go wrong.

# Chapter 4. Dependencies

When the Gods wish to punish us, they answer our prayers.

Oscar Wilde

For decades, the idea of code reuse was merely a dream.  The idea that code could be written once, packaged into a
library, and reused across many different applications was an ideal, realized only for a few standard libraries and for
corporate in-house tools.

The growth of the internet and the rise of open source software finally changed that. The first openly accessible
repository that held a wide collection of useful libraries, tools, and helpers, all packaged up for easy reuse, was
[CPAN](https://en.wikipedia.org/wiki/CPAN): the Comprehensive Perl Archive Network, online since 1995.  Today, almost every modern language has a comprehensive collection of open source libraries available, housed in a package
repository that makes the process of adding a new dependency easy and quick.[1](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch04.html#id1413)

However, new problems come along with that ease, convenience, and speed.  It’s *usually* still easier to reuse existing
code than to write it yourself, but there are potential pitfalls and risks that come along with dependencies on someone
else’s code.  This chapter of the book will help you be aware of these.

The focus is specifically on Rust, and with it the use of the  [cargo](https://doc.rust-lang.org/cargo) tool,
but many of the concerns, topics, and issues covered apply equally well to other toolchains (and other languages).

# Item 21: Understand what semantic versioning promises

If we acknowledge that SemVer is a lossy estimate and represents only a subset of the possible scope of
changes, we can begin to see it as a blunt instrument.

Titus Winters, *Software Engineering at Google* (O’Reilly)

Cargo, Rust’s package manager, allows automatic selection of dependencies ([Item 25](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch04.html#file_dep-graph_md)) for Rust code according to
*semantic versioning* (semver).  A  *Cargo.toml* stanza like:

```
[dependencies]
serde = "1.4"
```

indicates to `cargo` what ranges of semver versions are acceptable for this dependency.  The [official documentation](https://oreil.ly/fchXS) provides the details on specifying precise
ranges of acceptable versions, but the following are the most commonly used variants:

"1.2.3"Specifies that any version that’s semver-compatible with 1.2.3 is acceptable

"^1.2.3"Is another way of specifying the same thing more explicitly

"=1.2.3"Pins to one particular version, with no substitutes accepted

"~1.2.3"Allows versions that are semver-compatible with 1.2.3 but only where the last specified component changes
(so 1.2.4 is acceptable but 1.3.0 is not)

"1.2.*"Accepts any version that matches the wildcard

Examples of what these specifications allow are shown in [Table 4-1](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch04.html#table_4_1).

| Specification | 1.2.2 | 1.2.3 | 1.2.4 | 1.3.0 | 2.0.0 |
| --- | --- | --- | --- | --- | --- |
| `"1.2.3"` | No | Yes | Yes | Yes | No |
| `"^1.2.3"` | No | Yes | Yes | Yes | No |
| `"=1.2.3"` | No | Yes | No | No | No |
| `"~1.2.3"` | No | Yes | Yes | No | No |
| `"1.2.*"` | Yes | Yes | Yes | No | No |
| `"1.*"` | Yes | Yes | Yes | Yes | No |
| `"*"` | Yes | Yes | Yes | Yes | Yes |

When choosing dependency versions, Cargo will generally pick the largest version
that’s within the combination of all of these semver ranges.

Because semantic versioning is at the heart of `cargo`’s dependency resolution process, this Item explores more
details about what semver means.

## Semver Essentials

The essentials of semantic versioning are listed in the [summary in the semver documentation](https://oreil.ly/sBrbZ), reproduced here:

Given a version number MAJOR.MINOR.PATCH, increment the:

-

MAJOR version when you make incompatible API changes

-

MINOR version when you add functionality in a backward compatible manner

-

PATCH version when you make backward compatible bug fixes

An important point lurks in the [details](https://semver.org/#spec-item-3):

1.

Once a versioned package has been released, the contents of that version MUST NOT be modified. Any modifications
MUST be released as a new version.

Putting this into different words:

-

Changing *anything* requires a new patch version.

-

*Adding* things to the API in a way that means existing users of the crate still compile and work requires a minor
version upgrade.

-

*Removing* or *changing* things in the API requires a major version upgrade.

There is one more important [codicil](https://semver.org/#spec-item-4) to the semver rules:

1.

Major version zero (0.y.z) is for initial development. Anything MAY change at any time. The public API SHOULD NOT
be considered stable.

Cargo adapts this last rule slightly, “left-shifting” the earlier rules so that changes in the leftmost non-zero
component indicate incompatible changes.  This means that 0.2.3 to 0.3.0 can include an incompatible API change, as can
0.0.4 to 0.0.5.

## Semver for Crate Authors

In theory, theory is the same as practice. In practice, it’s not.

As a crate author, the first of these rules is easy to comply with, in theory: if you touch anything, you need a new
release. Using  Git [tags](https://git-scm.com/docs/git-tag) to match releases can help with
this—by default, a tag is fixed to a particular commit and can be moved only with a manual `--force`
option. Crates published to  [crates.io](https://crates.io/) also get automatic policing of this, as the registry
will reject a second attempt to publish the same crate version. The main danger for noncompliance is when you notice a
mistake *just after* a release has gone out, and you have to resist the temptation to just nip in a fix.

The semver specification covers API compatibility, so if you make a minor change to behavior that doesn’t alter the API,
then a patch version update should be all that’s needed.  (However, if your crate is widely depended on, then in practice
you may need to be aware of  [Hyrum’s Law](https://oreil.ly/7lQQ_): regardless of how minor a change you make
to the code, someone out there is likely to [depend on the old behavior](https://xkcd.com/1172/)—even if the API
is unchanged.)

The difficult part for crate authors is the latter rules, which require an accurate determination of whether a change is
back compatible or not.  Some changes are obviously incompatible—removing public entrypoints or types, changing
method signatures—and some changes are obviously backward compatible (e.g., adding a new method to a `struct`,
or adding a new constant), but there’s a lot of gray area left in between.

To help with this, the [Cargo book](https://oreil.ly/Y6ZLJ) goes into considerable detail as to what is and is not
back compatible. Most of these details are unsurprising, but there are a few areas worth
highlighting:

-

Adding new items is *usually* safe—but may cause clashes if code using the crate already makes use of something that
happens to have the same name as the new item.

-

This is a particular danger if the user does a  [wildcard import from the crate](https://doc.rust-lang.org/cargo/reference/semver.html#minor-adding-new-public-items), because all of the
crate’s items are then automatically in the user’s main namespace. [Item 23](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch04.html#file_wildcard_md) advises against doing this.

-

Even without a wildcard import, a [new trait method](https://doc.rust-lang.org/cargo/reference/semver.html#possibly-breaking-adding-a-defaulted-trait-item) (with
a default implementation; [Item 13](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch02.html#file_default-impl_md)) or a [new inherent method](https://doc.rust-lang.org/cargo/reference/semver.html#possibly-breaking-change-adding-any-inherent-items)
has a chance of clashing with an existing name.

-

Rust’s insistence on covering all possibilities means that changing the set of available possibilities can be a
breaking change.

-

Performing a `match` on an `enum` must cover all possibilities, so if a [crate adds a new enum variant](https://doc.rust-lang.org/cargo/reference/semver.html#major-adding-new-enum-variants-without-non_exhaustive),
that’s a breaking change (unless the `enum` is already marked as
[non_exhaustive](https://doc.rust-lang.org/reference/attributes/type_system.html#the-non_exhaustive-attribute)—*adding*
`non_exhaustive` is also a breaking change).

-

Explicitly creating an instance of a  `struct` requires an initial value for all fields, so [adding a field to a structure that can be publicly instantiated](https://doc.rust-lang.org/cargo/reference/semver.html#major-adding-a-public-field-when-no-private-field-exists)
is
a breaking change.  Structures that have private fields are OK, because crate users can’t explicitly construct
them anyway; a `struct` can also be marked
as `non_exhaustive` to prevent external users from performing explicit

construction.

-

Changing a trait so it is  [no longer object safe](https://doc.rust-lang.org/cargo/reference/semver.html#trait-object-safety) ([Item 12](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch02.html#file_generics_md)) is a breaking change; any
users that build trait objects for the trait will stop being able to compile their code.

-

Adding a new  blanket implementation for a trait is a breaking change; any users that already implement the trait
will now have two conflicting implementations.

-

Changing the  *license* of an open source crate is an incompatible change: users of your crate who have strict
restrictions on what licenses are acceptable may be broken by the change. *Consider the license to be part of
your API*.

-

Changing the  default features ([Item 26](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch04.html#file_features_md)) of a crate is potentially a breaking change. Removing a default
feature is almost certain to break things (unless the feature was already a no-op); adding a default feature may
break things depending on what it enables.  *Consider the default feature set to be part of your API*.

-

Changing library code so that it uses a new feature of Rust *might* be an incompatible change, because users of your
crate who have not yet upgraded their compiler to a version that includes the feature will be broken by the change.
However, most Rust crates treat a minimum supported Rust version (MSRV) increase as a [non-breaking change](https://oreil.ly/Tadgz), so *consider whether the MSRV forms part of your API*.

An obvious corollary of the rules is this: the fewer public items a crate has, the fewer things there are that can
induce an incompatible change ([Item 22](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch04.html#file_visibility_md)).

However, there’s no escaping the fact that comparing all public API items for compatibility from one release to the next
is a time-consuming process that is likely to yield only an *approximate* (major/minor/patch) assessment of the level of
change, at best. Given that this comparison is a somewhat mechanical process, hopefully tooling ([Item 31](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch05.html#file_use-tools_md)) will arrive
to make the process easier.[2](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch04.html#id1440)

If you do need to make an incompatible major version change, it’s nice to make life easier for your users by ensuring
that the same overall functionality is available after the change, even if the API has radically changed.  If possible,
the most helpful sequence for your crate users is as follows:

1.

Release a minor version update that includes the new version of the API and that marks the older variant as
[deprecated](https://doc.rust-lang.org/reference/attributes/diagnostics.html#the-deprecated-attribute), including an
indication of how to migrate.

1.

Release a major version update that removes the deprecated parts of the API.

A more subtle point is *make breaking changes breaking*. If your crate is changing its behavior in a
way that’s actually incompatible for existing users but that *could* reuse the same API: don’t.  Force a change in
types (and a major version bump) to ensure that users can’t inadvertently use the new version incorrectly.

For the less tangible parts of your API—such as the
[MSRV](https://oreil.ly/Gast-) or the
license—consider setting up a CI check ([Item 32](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch05.html#file_ci_md)) that detects changes, using tooling
(e.g., `cargo-deny`; see [Item 25](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch04.html#file_dep-graph_md)) as needed.

Finally, don’t be afraid of version 1.0.0 because it’s a commitment that your API is now fixed. Lots of crates fall into
the trap of staying at version 0.x forever, but that reduces the already-limited expressivity of semver from three
categories (major/minor/patch) to two (effective-major/effective-minor).

## Semver for Crate Users

For the user of a crate, the *theoretical* expectations for a new version of a dependency are as follows:

-

A new patch version of a dependency crate Should Just Work.™

-

A new minor version of a dependency crate Should Just Work,™ but the new parts of the API might be worth
exploring to see if there are now cleaner or better ways of using the crate.  However, if you do use the new parts, you
won’t be able to revert the dependency back to the old version.

-

All bets are off for a new major version of a dependency; chances are that your code will no longer compile, and you’ll
need to rewrite parts of your code to comply with the new API.  Even if your code does still compile, you should
*check that your use of the API is still valid after a major version change*, because the constraints and
preconditions of the library may have changed.

In practice, even the first two types of change *may* cause unexpected behavior changes, even in code that still
compiles fine, due to  Hyrum’s Law.

As a consequence of these expectations, your dependency specifications will commonly take a form like `"1.4.3"` or
`"0.7"`, which includes subsequent compatible versions; *avoid specifying a completely  wildcard
dependency* like `"*"` or `"0.*"`. A completely wildcard dependency says that *any* version of the dependency, with
*any* API, can be used by your crate—which is unlikely to be what you really want.
Avoiding wildcards is also a requirement for publishing to `crates.io`; submissions with `"*"` wildcards will be
[rejected](https://oreil.ly/i6ELc).

However, in the longer term, it’s not safe to just ignore major version changes in dependencies.  Once a library has had
a major version change, the chances are that no further bug fixes—and more importantly, security
updates—will be made to the previous major version.  A version specification like `"1.4"` will then fall further
and further behind as new 2.x releases arrive, with any security problems left
unaddressed.

As a result, you need to either accept the risks of being stuck on an old version or *eventually
follow major version upgrades to your dependencies*.  Tools such as `cargo update` or
[Dependabot](https://docs.github.com/en/code-security/dependabot) ([Item 31](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch05.html#file_use-tools_md)) can let you know when updates are
available; you can then schedule the upgrade for a time that’s convenient for you.

## Discussion

Semantic versioning has a cost: every change to a crate has to be assessed against its criteria, to decide the
appropriate type of version bump.  Semantic versioning is also a blunt tool: at best, it reflects a crate owner’s guess
as to which of three categories the current release falls into.  Not everyone gets it right, not everything is
clear-cut about exactly what “right” means, and even if you get it right, there’s always a chance you may fall foul of
Hyrum’s Law.

However, semver is the only game in town for anyone who doesn’t have the luxury of working in an environment like
[Google’s highly tested gigantic internal monorepo](https://oreil.ly/i-WpN).  As such, understanding
its concepts and limitations is necessary for managing dependencies.

# Item 22: Minimize visibility

Rust allows elements of the code to either be hidden from or exposed to other parts of the codebase.  This Item
explores the mechanisms provided for this and suggests advice for where and when they should be used.

## Visibility Syntax

Rust’s basic unit of visibility is the  module.  By default, a module’s items (types, methods, constants) are
*private* and accessible only to code in the same module and its submodules.

Code that needs to be more widely available is marked with the  `pub` keyword, making it public to some other scope.  For most Rust syntactic features, making the feature `pub` does not automatically expose the
contents—the types and functions in a `pub mod` are not public, nor are the fields in a `pub struct`.  However,
there are a couple of exceptions where applying the visibility to the contents makes sense:

-

Making an `enum` public automatically makes the type’s variants public too (together with any fields that might
be present in those variants).

-

Making a `trait` public automatically makes the trait’s methods public too.

So a collection of types in a module:

```
pub mod somemodule {
    // Making a `struct` public does not make its fields public.
    #[derive(Debug, Default)]
    pub struct AStruct {
        // By default fields are inaccessible.
        count: i32,
        // Fields have to be explicitly marked `pub` to be visible.
        pub name: String,
    }

    // Likewise, methods on the struct need individual `pub` markers.
    impl AStruct {
        // By default methods are inaccessible.
        fn canonical_name(&self) -> String {
            self.name.to_lowercase()
        }
        // Methods have to be explicitly marked `pub` to be visible.
        pub fn id(&self) -> String {
            format!("{}-{}", self.canonical_name(), self.count)
        }
    }

    // Making an `enum` public also makes all of its variants public.
    #[derive(Debug)]
    pub enum AnEnum {
        VariantOne,
        // Fields in variants are also made public.
        VariantTwo(u32),
        VariantThree { name: String, value: String },
    }

    // Making a `trait` public also makes all of its methods public.
    pub trait DoSomething {
        fn do_something(&self, arg: i32);
    }
}
```

allows access to `pub` things and the exceptions previously mentioned:

```
use somemodule::*;

let mut s = AStruct::default();
s.name = "Miles".to_string();
println!("s = {:?}, name='{}', id={}", s, s.name, s.id());

let e = AnEnum::VariantTwo(42);
println!("e = {e:?}");

#[derive(Default)]
pub struct DoesSomething;
impl DoSomething for DoesSomething {
    fn do_something(&self, _arg: i32) {}
}

let d = DoesSomething::default();
d.do_something(42);
```

but non-`pub` things are generally inaccessible:

```
let mut s = AStruct::default();
s.name = "Miles".to_string();
println!("(inaccessible) s.count={}", s.count);
println!("(inaccessible) s.canonical_name()={}", s.canonical_name());
```

```
error[E0616]: field `count` of struct `somemodule::AStruct` is private
   --> src/main.rs:230:45
    |
230 |     println!("(inaccessible) s.count={}", s.count);
    |                                             ^^^^^ private field
error[E0624]: method `canonical_name` is private
   --> src/main.rs:231:56
    |
86  |         fn canonical_name(&self) -> String {
    |         ---------------------------------- private method defined here
...
231 |     println!("(inaccessible) s.canonical_name()={}", s.canonical_name());
    |                                         private method ^^^^^^^^^^^^^^
Some errors have detailed explanations: E0616, E0624.
For more information about an error, try `rustc --explain E0616`.
```

The most common visibility marker is the bare `pub` keyword, which makes the item visible to anything that’s able to see
the module it’s in.  That last detail is important: if a `somecrate::somemodule` module isn’t visible to other code in
the first place, anything that’s `pub` inside it is still not visible.

However, there are also some more-specific variants of `pub` that allow the scope of the visibility to be constrained.
In descending order of usefulness, these are as follows:

pub(crate)Accessible anywhere within the owning crate.  This is particularly useful for crate-wide
internal helper functions that should not be exposed to external crate users.

pub(super)Accessible to the parent module of the current module and its submodules.  This is occasionally
useful for selectively increasing visibility in a crate that has a deep module structure. It’s also the effective
visibility level for modules: a plain `mod mymodule` is visible to its parent module or crate and the corresponding
submodules.

pub(in <path>)Accessible to code in `<path>`, which has to be a description of some ancestor module of the
current module. This can occasionally be useful for organizing source code, because it allows subsets of functionality
to be moved into submodules that aren’t necessarily visible in the public API.
For example, the Rust standard library consolidates all of the iterator
[adapters](https://doc.rust-lang.org/std/iter/index.html#adapters) into [an internal std::iter::adapters submodule](https://doc.rust-lang.org/src/core/iter/adapters/mod.rs.html) and has the following:

-

A `pub(in crate::iter)` visibility marker on all of the required adapter methods in submodules, such as
[std::iter::adapters::map::Map::new](https://oreil.ly/XbQGP).

-

A `pub use` of all of the `adapters::` types in [the outer std::iter module](https://oreil.ly/uLZ-d).

pub(self)Equivalent to `pub(in self)`, which is equivalent to not being `pub`.  Uses for this are very obscure,
such as reducing the number of special cases needed in code-generation  macros.

The Rust compiler will warn you if you have a code item that is private to the module but not used within that
module (and its submodules):

```
pub mod anothermodule {
    // Private function that is not used within its module.
    fn inaccessible_fn(x: i32) -> i32 {
        x + 3
    }
}
```

Although the warning indicates that the code is “never used” in its owning module, in practice this warning often
indicates that code *can’t* be used from outside the module, because the visibility restrictions don’t allow it:

```
warning: function `inaccessible_fn` is never used
  --> src/main.rs:56:8
   |
56 |     fn inaccessible_fn(x: i32) -> i32 {
   |        ^^^^^^^^^^^^^^^
   |
   = note: `#[warn(dead_code)]` on by default
```

## Visibility Semantics

Separate from the question of *how* to increase visibility is the question of *when* to do so.  The generally
accepted answer to this is *as little as possible*, at least for any code that may possibly get used and reused in the
future.

The first reason for this advice is that visibility changes can be hard to undo.  Once a crate item is public, it can’t
be made private again without breaking any code that uses the crate, thus necessitating a  major
version bump ([Item 21](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch04.html#file_semver_md)).  The converse is not true: moving a private item to be public generally needs only a minor
version bump and leaves crate users unaffected—read through [Rust’s API compatibility guidelines](https://oreil.ly/CkFWN) and notice how many are
relevant only if there are  `pub` items in play.

A more important—but more subtle—reason to prefer privacy is that it keeps your options open.  The more
things that are exposed, the more things there are that need to stay fixed for the future (absent an incompatible
change).  If you expose the internal implementation details of a data structure, a putative future change to use a more
efficient algorithm becomes a breaking change.  If you expose internal helper functions, it’s  inevitable that some external code will come to depend on the exact details of those functions.

Of course, this is a concern only for library code that potentially has multiple users and a long lifespan. But nothing
is as permanent as a temporary solution, and so it’s a good habit to fall into.

It’s also worth observing that this advice to restrict visibility is by no means unique to this Item or to Rust:

-

The Rust [API guidelines](https://oreil.ly/nSrkD) include this advice: [structs should have private fields](https://rust-lang.github.io/api-guidelines/future-proofing.html#structs-have-private-fields-c-struct-private).

-

[Effective Java](https://www.oreilly.com/library/view/effective-java/9780134686097/), 3rd edition, (Addison-Wesley Professional)  has the following:

-

Item 15: Minimize the accessibility of classes and members.

-

Item 16: In public classes, use accessor methods, not public fields.

-

*Effective C++* by Scott Meyers (Addison-Wesley Professional)
has the following in its second edition:

-

Item 18: Strive for class interfaces that are complete and *minimal* (my italics).

-

Item 20: Avoid data members in the public interface.

# Item 23: Avoid wildcard imports

Rust’s `use` statement pulls in a named item from another crate or module and makes that name available for
use in the local module’s code without qualification.  A  *wildcard import* (or *glob import*) of the form `use somecrate::module::*` says that *every* public symbol from that module should be added to the local namespace.

As described in [Item 21](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch04.html#file_semver_md), an external crate may add new items to its API as part of a minor version upgrade; this is
considered a  backward-compatible change.

The combination of these two observations raises the worry that a nonbreaking change to a dependency might break your
code: what happens if the dependency adds a new symbol that clashes with a name you’re already using?

At the simplest level, this turns out not to be a problem: the names in a wildcard import are treated as being lower
priority, so any matching names that are in your code take precedence:

```
use bytes::*;

// Local `Bytes` type does not clash with `bytes::Bytes`.
struct Bytes(Vec<u8>);
```

Unfortunately, there are still cases where clashes can occur.  For example, consider the case when the dependency adds a
new trait and implements it for some type:

```
trait BytesLeft {
    // Name clashes with the `remaining` method on the wildcard-imported
    // `bytes::Buf` trait.
    fn remaining(&self) -> usize;
}

impl BytesLeft for &[u8] {
    // Implementation clashes with `impl bytes::Buf for &[u8]`.
    fn remaining(&self) -> usize {
        self.len()
    }
}
```

If any method names from the new trait clash with existing method names that apply to the type, then the compiler
can no longer unambiguously figure out which method is intended:

#

```
let arr = [1u8, 2u8, 3u8];
let v = &arr[1..];

assert_eq!(v.remaining(), 2);
```

as indicated by the compile-time error:

```
error[E0034]: multiple applicable items in scope
  --> src/main.rs:40:18
   |
40 |     assert_eq!(v.remaining(), 2);
   |                  ^^^^^^^^^ multiple `remaining` found
   |
note: candidate #1 is defined in an impl of the trait `BytesLeft` for the
      type `&[u8]`
  --> src/main.rs:18:5
   |
18 |     fn remaining(&self) -> usize {
   |     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^
   = note: candidate #2 is defined in an impl of the trait `bytes::Buf` for the
           type `&[u8]`
help: disambiguate the method for candidate #1
   |
40 |     assert_eq!(BytesLeft::remaining(&v), 2);
   |                ~~~~~~~~~~~~~~~~~~~~~~~~
help: disambiguate the method for candidate #2
   |
40 |     assert_eq!(bytes::Buf::remaining(&v), 2);
   |                ~~~~~~~~~~~~~~~~~~~~~~~~~
```

As a result, you should *avoid wildcard imports from crates that you don’t control*.

If you do control the source of the wildcard import, then the previously mentioned concerns disappear.  For example, it’s common
for a `test` module to do `use super::*;`. It’s also possible for crates that use modules primarily as a way of dividing
up code to have a wildcard import from an internal module:

```
mod thing;
pub use thing::*;
```

However, there’s another common exception where wildcard imports make sense.  Some crates have a convention that common
items for the crate are  re-exported from a  *prelude* module, which is explicitly intended to be wildcard
imported:

```
use thing::prelude::*;
```

Although in theory the same concerns apply in this case, in practice such a prelude module is likely to be carefully
curated, and higher convenience may outweigh a small risk of future problems.

Finally, if you don’t follow the advice in this Item, *consider pinning dependencies that you wildcard import
to a precise version* (see [Item 21](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch04.html#file_semver_md)) so that minor version upgrades of the dependency aren’t automatically allowed.

# Item 24: Re-export dependencies whose types
appear in your API

The title of this Item is a little convoluted, but working through an example will make things clearer.[3](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch04.html#id1498)

[Item 25](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch04.html#file_dep-graph_md) describes how  `cargo` supports different versions of the same library crate being linked into a
single binary, in a transparent manner.  Consider a binary that uses the  [rand](https://docs.rs/rand) crate—more specifically, one that uses some 0.8 version of the crate:

```bash
# Cargo.toml file for a top-level binary crate.
[dependencies]
# The binary depends on the `rand` crate from crates.io
rand = "=0.8.5"

# It also depends on some other crate (`dep-lib`).
dep-lib = "0.1.0"
```

```
// Source code:
let mut rng = rand::thread_rng(); // rand 0.8
let max: usize = rng.gen_range(5..10);
let choice = dep_lib::pick_number(max);
```

The final line of code also uses a notional `dep-lib` crate as another dependency.  This crate might be another
crate from `crates.io`, or it could be a local crate that is located via Cargo’s [path mechanism](https://doc.rust-lang.org/cargo/reference/specifying-dependencies.html#specifying-path-dependencies).

This `dep-lib` crate internally uses a 0.7 version of the `rand` crate:

```bash
# Cargo.toml file for the `dep-lib` library crate.
[dependencies]
# The library depends on the `rand` crate from crates.io
rand = "=0.7.3"
```

```
// Source code:
//! The `dep-lib` crate provides number picking functionality.
use rand::Rng;

/// Pick a number between 0 and n (exclusive).
pub fn pick_number(n: usize) -> usize {
    rand::thread_rng().gen_range(0, n)
}
```

An eagle-eyed reader might notice a difference between the two code examples:

-

In version 0.7.x of `rand` (as used by the `dep-lib` library crate), the
[rand::gen_range()](https://docs.rs/rand/0.7.3/rand/trait.Rng.html#method.gen_range) method takes two
parameters, `low` and `high`.

-

In version 0.8.x of `rand` (as used by the binary crate), the
[rand::gen_range()](https://docs.rs/rand/0.8.5/rand/trait.Rng.html#method.gen_range) method takes a single
parameter `range`.

This is not a back-compatible change, and so `rand` has increased its leftmost version component
accordingly, as required by  semantic versioning ([Item 21](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch04.html#file_semver_md)).  Nevertheless, the binary that combines the two
incompatible versions works just fine—`cargo` sorts everything out.

However, things get a lot more awkward if the `dep-lib` library crate’s API exposes a type from its dependency, making
that dependency a [public dependency](https://oreil.ly/yAm3Y).

For example, suppose that the `dep-lib` entrypoint involves an `Rng` item—but specifically a version-0.7 `Rng`
item:

```
/// Pick a number between 0 and n (exclusive) using
/// the provided `Rng` instance.
pub fn pick_number_with<R: Rng>(rng: &mut R, n: usize) -> usize {
    rng.gen_range(0, n) // Method from the 0.7.x version of Rng
}
```

As an aside, *think carefully before using another crate’s types in your API*: it intimately ties your crate
to that of the dependency.  For example, a major version bump for the dependency ([Item 21](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch04.html#file_semver_md)) will automatically require a
major version bump for your crate too.

In this case, `rand` is a semi-standard crate that is widely used and pulls in only a small number of
dependencies of its own ([Item 25](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch04.html#file_dep-graph_md)), so including its types in the crate API is probably fine on balance.

Returning to the example, an attempt to use this entrypoint from the top-level binary fails:

#

```
let mut rng = rand::thread_rng();
let max: usize = rng.gen_range(5..10);
let choice = dep_lib::pick_number_with(&mut rng, max);
```

Unusually for Rust, the compiler error message isn’t [very helpful](https://github.com/rust-lang/rust/issues/22750):

```
error[E0277]: the trait bound `ThreadRng: rand_core::RngCore` is not satisfied
  --> src/main.rs:22:44
   |
22 |     let choice = dep_lib::pick_number_with(&mut rng, max);
   |                  ------------------------- ^^^^^^^^ the trait
   |                  |                `rand_core::RngCore` is not
   |                  |                 implemented for `ThreadRng`
   |                  |
   |                  required by a bound introduced by this call
   |
   = help: the following other types implement trait `rand_core::RngCore`:
             &'a mut R
```

Investigating the types involved leads to confusion because the relevant traits do *appear* to be implemented—but
the caller actually implements a (notional) `RngCore_v0_8_5` and the library is expecting an implementation of
`RngCore_v0_7_3`.

Once you’ve finally deciphered the error message and realized that the version clash is the underlying cause, how can you fix it?[4](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch04.html#id1503) The key
observation is to realize that while the binary can’t *directly* use two different versions of the same crate, it
can do so *indirectly* (as in the original example shown previously).

From the perspective of the binary author, the problem could be worked around by adding an intermediate wrapper crate
that hides the naked use of `rand` v0.7 types. A wrapper crate is distinct from the binary crate and so is allowed to
depend on `rand` v0.7 separately from the binary crate’s dependency on `rand` v0.8.

This is awkward, and a much better approach is available to the author of the library crate. It can make life easier for
its users by explicitly
[re-exporting](https://doc.rust-lang.org/reference/items/use-declarations.html#use-visibility) either of the
following:

-

The types involved in the API

-

The entire dependency crate

For this example, the latter approach works best: as well as making the version 0.7 `Rng` and `RngCore` types available,
it also makes available the methods (like `thread_rng()`) that construct instances of the type:

```
// Re-export the version of `rand` used in this crate's API.
pub use rand;
```

The calling code now has a different way to directly refer to version 0.7 of `rand`, as `dep_lib::rand`:

```
let mut prev_rng = dep_lib::rand::thread_rng(); // v0.7 Rng instance
let choice = dep_lib::pick_number_with(&mut prev_rng, max);
```

With this example in mind, the advice given in the title of the Item should now be a little less obscure: *re-export dependencies
whose types appear in your API*.

# Item 25: Manage your dependency graph

Like most modern programming languages, Rust makes it easy to pull in external libraries, in the form of *crates*.  Most
nontrivial Rust programs use external crates, and those crates may themselves have additional dependencies,
forming a  *dependency graph* for the program as a whole.

By default,  Cargo will download any crates named in the `[dependencies]` section of your  *Cargo.toml* file
from [crates.io](https://crates.io/) and find versions of those crates that match the requirements configured in
*Cargo.toml*.

A few subtleties lurk underneath this simple statement.  The first thing to notice is that crate names from
`crates.io` form a single flat namespace—and this global namespace also overlaps with the names of
*features* in a crate (see [Item 26](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch04.html#file_features_md)).[5](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch04.html#id1512)

If you’re planning on *publishing* a crate on `crates.io`, be aware that names are generally allocated on a first-come,
first-served basis; so you may find that your preferred name for a public crate is already taken.  However,
name-squatting—reserving a crate name by preregistering an empty crate—is [frowned upon](https://oreil.ly/ArljK), unless you really are going to release code
in the near future.

As a minor wrinkle, there’s also a slight difference between what’s allowed as a crate name in the crates namespace and
what’s allowed as an identifier in code: a crate can be named `some-crate`, but it will appear in code as `some_crate`
(with an underscore).  To put it another way: if you see `some_crate` in code, the corresponding crate name may be
either `some-crate` or `some_crate`.

The second subtlety to understand is that Cargo allows multiple semver-incompatible versions of the same crate to be
present in the build.  This can seem surprising to begin with, because each *Cargo.toml* file can have only a single
version of any given dependency, but the situation frequently arises with indirect dependencies: your crate depends on
`some-crate` version 3.x but also depends on `older-crate`, which in turn depends on `some-crate` version 1.x.

This can lead to confusion if the dependency is exposed in some way rather than just being used internally ([Item 24](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch04.html#file_re-export_md))—the compiler will treat the two versions as being distinct crates, but its error messages won’t necessarily
make that clear.

Allowing multiple versions of a crate can also go wrong if the crate includes  C/C++ code accessed via Rust’s
FFI mechanisms ([Item 34](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch06.html#file_ffi_md)). The Rust toolchain can internally disambiguate distinct versions of Rust code, but any
included C/C++ code is subject to the  [one definition rule](https://en.wikipedia.org/wiki/One_Definition_Rule): there can be only a single version of any function, constant,
or global variable.

There are restrictions on Cargo’s multiple-version support.  Cargo does *not* allow multiple versions of the same
crate within a semver-compatible range ([Item 21](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch04.html#file_semver_md)):

-

`some-crate` 1.2 and `some-crate` 3.1 can coexist

-

`some-crate` 1.2 and `some-crate` 1.3 cannot

Cargo also extends the semantic versioning rules for pre-1.0 crates so that the first
non-zero subversion counts like a major version, so a similar constraint applies:

-

`other-crate` 0.1.2 and `other-crate` 0.2.0 can coexist

-

`other-crate` 0.1.2 and `other-crate` 0.1.4 cannot

Cargo’s [version selection algorithm](https://oreil.ly/qIxXh) does the job of figuring
out what versions to include.  Each *Cargo.toml* dependency line specifies an acceptable range of versions, according to
semantic versioning rules, and Cargo takes this into account when the same crate appears in multiple places in the
dependency graph.  If the acceptable ranges overlap and are  semver-compatible, then Cargo will
(by default) pick the most recent version of the crate within the overlap.  If there is no semver-compatible overlap,
then Cargo will build multiple copies of the dependency at different versions.

Once Cargo has picked acceptable versions for all dependencies, its choices are recorded in the  *Cargo.lock* file.
Subsequent builds will then reuse the choices encoded in *Cargo.lock* so that the build is stable and no new downloads
are needed.

This leaves you with a choice: should you commit your *Cargo.lock* files into version control or not? The [advice from the Cargo developers](https://oreil.ly/pppkQ)
is as follows:

-

Things that produce a final product, namely applications and binaries, should commit *Cargo.lock* to ensure a
deterministic build.

-

Library crates should *not* commit a *Cargo.lock* file, because it’s irrelevant to any downstream consumers of the
library—they will have their own *Cargo.lock* file; *be aware that the Cargo.lock file for a
library crate is ignored by library users*.

Even for a library crate, it can be helpful to have a checked-in *Cargo.lock* file to ensure that regular builds and
CI ([Item 32](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch05.html#file_ci_md)) don’t have a moving target.  Although the promises of  semantic versioning
([Item 21](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch04.html#file_semver_md)) should prevent failures in theory, mistakes happen in practice, and it’s frustrating to have builds that fail
because someone somewhere recently changed a dependency of a dependency.

However, *if you version-control Cargo.lock, set up a process to handle upgrades* (such as GitHub’s
[Dependabot](https://docs.github.com/en/code-security/dependabot)). If you don’t, your dependencies will stay
pinned to versions that get older, outdated, and potentially insecure.

Pinning versions with a checked-in *Cargo.lock* file doesn’t avoid the pain of handling dependency upgrades, but it does
mean that you can handle them at a time of your own choosing, rather than immediately when the upstream crate
changes. There’s also some fraction of dependency-upgrade problems that go away on their own: a crate that’s released
with a problem often gets a second, fixed, version released in a short space of time, and a batched upgrade process
might see only the latter version.

The third subtlety of Cargo’s resolution process to be aware of is  *feature unification*: the features that get
activated for a dependent crate are the *union* of the features selected by different places in the dependency graph;
see [Item 26](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch04.html#file_features_md) for more details.

## Version Specification

The version specification clause for a dependency defines a range of allowed versions, according to the
[rules explained in the Cargo book](https://oreil.ly/9YHm-):

Avoid a too-specific version dependencyPinning to a specific version (`"=1.2.3"`) is *usually* a bad
idea: you don’t see newer versions (potentially including security fixes), and you dramatically narrow the potential
overlap range with other crates in the graph that rely on the same dependency (recall that Cargo allows only a single
version of a crate to be used within a semver-compatible range). If you want to ensure that your builds use a consistent set of dependencies, the *Cargo.lock* file is the tool for
the job.

Avoid a too-general version dependencyIt’s *possible* to specify a version dependency (`"*"`) that
allows *any* version of the dependency to be used, but it’s a bad idea.  If the dependency releases a new major
version of the crate that completely changes every aspect of its API, it’s unlikely that your code will
still work after a `cargo update` pulls in the new
version.

The most common Goldilocks specification—not too precise, not too vague—is to allow semver-compatible
versions (`"1"`) of a crate, possibly with a specific minimum version that includes a feature or fix that you require
(`"1.4.23"`). Both of these version specifications make use of Cargo’s default behavior, which is to allow versions
that are semver-compatible with the specified version.  You can make this more explicit by adding a caret:

-

A version of `"1"` is equivalent to `"^1"`, which allows all 1.x versions (and so is also equivalent to `"1.*"`).

-

A version of `"1.4.23"` is equivalent to `"^1.4.23"`, which allows any 1.x versions that are larger than
1.4.23.

## Solving Problems with Tooling

[Item 31](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch05.html#file_use-tools_md) recommends that you take advantage of the range of tools that are available within the Rust ecosystem.  This
section describes some dependency graph problems where tools can help.

The compiler will tell you pretty quickly if you use a dependency in your code but don’t include that dependency in
*Cargo.toml*.  But what about the other way around?  If there’s a dependency in *Cargo.toml* that you *don’t* use in
your code—or more likely, *no longer* use in your code—then Cargo will go on with its business.  The
[cargo-udeps](https://crates.io/crates/cargo-udeps) tool is designed to solve exactly this problem: it warns you
when your *Cargo.toml* includes an unused dependency (“udep”).

A more versatile tool is  [cargo-deny](https://crates.io/crates/cargo-deny), which analyzes your dependency graph
to detect a variety of potential problems across the full set of transitive dependencies:

-

Dependencies that have known security problems in the included version

-

Dependencies that are covered by an unacceptable  license

-

Dependencies that are just unacceptable

-

Dependencies that are included in multiple different versions across the dependency tree

Each of these features can be configured and can have exceptions specified.  The exception mechanism is usually needed
for larger projects, particularly the multiple-version warning: as the dependency graph grows, so does the chance of
transitively depending on different versions of the same crate.  It’s worth trying to reduce these duplicates where
possible—for binary-size and compilation-time reasons if nothing else—but sometimes there is no possible
combination of dependency versions that can avoid a duplicate.

These tools can be run as a one-off, but it’s better to ensure they’re executed regularly and reliably by including them
in your CI system ([Item 32](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch05.html#file_ci_md)).  This helps to catch newly introduced problems—including
problems that may have been introduced outside of your code, in an upstream dependency (for example, a newly reported
vulnerability).

If one of these tools does report a problem, it can be difficult to figure out exactly where in the dependency graph the
problem arises.  The  [cargo tree](https://doc.rust-lang.org/cargo/commands/cargo-tree.html) command
that’s included with `cargo` helps here, as it shows the dependency graph as a tree structure:

```
dep-graph v0.1.0
├── dep-lib v0.1.0
│   └── rand v0.7.3
│       ├── getrandom v0.1.16
│       │   ├── cfg-if v1.0.0
│       │   └── libc v0.2.94
│       ├── libc v0.2.94
│       ├── rand_chacha v0.2.2
│       │   ├── ppv-lite86 v0.2.10
│       │   └── rand_core v0.5.1
│       │       └── getrandom v0.1.16 (*)
│       └── rand_core v0.5.1 (*)
└── rand v0.8.3
    ├── libc v0.2.94
    ├── rand_chacha v0.3.0
    │   ├── ppv-lite86 v0.2.10
    │   └── rand_core v0.6.2
    │       └── getrandom v0.2.3
    │           ├── cfg-if v1.0.0
    │           └── libc v0.2.94
    └── rand_core v0.6.2 (*)
```

`cargo tree` includes a variety of options that can help to solve specific problems, such as these:

--invertShows what depends *on* a specific package, helping you to focus on a particular problematic dependency

--edges featuresShows what crate features are activated by a dependency link, which helps you figure out what’s
going on with feature unification ([Item 26](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch04.html#file_features_md))

--duplicatesShows crates that have multiple versions present in the dependency graph

## What to Depend On

The previous sections have covered the more mechanical aspect of working with dependencies, but there’s a more
philosophical (and therefore harder-to-answer) question: when should you take on a dependency?

Most of the time, there’s not much of a decision involved: if you need the functionality of a crate, you need that
function, and the only alternative would be to write it yourself.[6](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch04.html#id1544)

But every new dependency has a cost, partly in terms of longer builds and bigger binaries but mostly in terms of the
developer effort involved in fixing problems with dependencies when they arise.

The bigger your dependency graph, the more likely you are to be exposed to these kinds of problems.  The Rust crate
ecosystem is just as vulnerable to accidental dependency problems as other package ecosystems, where history has shown
that [one developer removing a package](https://oreil.ly/8lTZ8),
or a team [fixing the licensing for their package](https://oreil.ly/7HjSi) can have
widespread knock-on effects.

More worrying still are  supply chain attacks, where a malicious actor deliberately tries to subvert commonly used
dependencies, whether by [typo-squatting](https://en.wikipedia.org/wiki/Typosquatting), [hijacking a maintainer’s account](https://oreil.ly/b8D-f), or other more sophisticated attacks.

This kind of attack doesn’t just affect your compiled code—be aware that a dependency can run arbitrary code at
*build* time, via  [build.rs](https://doc.rust-lang.org/cargo/reference/build-scripts.html) scripts or procedural
macros ([Item 28](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch05.html#file_macros_md)). That means that a compromised dependency could end up running a cryptocurrency miner as part of your
CI system!

So for dependencies that are more “cosmetic,” it’s sometimes worth considering whether adding the dependency is
worth the cost.

The answer is usually “yes,” though; in the end, the amount of time spent dealing with
dependency problems ends up being much less than the time it would take to write equivalent functionality from
scratch.

## Things to Remember

-

Crate names on `crates.io` form a single flat namespace (which is shared with feature names).

-

Crate names can include a hyphen, but it will appear as an underscore in code.

-

Cargo supports multiple versions of the same crate in the dependency graph, but only if they are of different
semver-incompatible versions. This can go wrong for crates that include FFI code.

-

Prefer to allow semver-compatible versions of dependencies (`"1"`, or `"1.4.23"` to include a minimum version).

-

Use *Cargo.lock* files to ensure your builds are repeatable, but remember that the *Cargo.lock* file does not ship
with a published crate.

-

Use tooling (`cargo tree`, `cargo deny`, `cargo udep`, …) to help find and fix dependency problems.

-

Understand that pulling in dependencies saves you writing code but doesn’t come for free.

# Item 26: Be wary of `feature` creep

Rust allows the same codebase to support a variety of different configurations via Cargo’s  *feature* mechanism,
which is built on top of a lower-level mechanism for conditional compilation.  However, the feature mechanism has a few
subtleties to be aware of, which this Item explores.

## Conditional Compilation

Rust includes support for  [conditional compilation](https://doc.rust-lang.org/reference/conditional-compilation.html), which is controlled by
[cfg](https://doc.rust-lang.org/reference/conditional-compilation.html#the-cfg-attribute) (and
[cfg_attr](https://doc.rust-lang.org/reference/conditional-compilation.html#the-cfg_attr-attribute)) attributes.
These attributes govern whether the thing—function, line, block, etc.—that they are attached to is
included in the compiled source code or not (which is in contrast to  C/C++’s line-based preprocessor).  The
conditional inclusion is controlled by configuration options that are either plain names (e.g., `test`) or pairs of names
and values (e.g., `panic = "abort"`).

Note that the name/value variants of config options are multivalued—it’s possible to set more than one value
for the same name:

```
// Build with `RUSTFLAGS` set to:
//   '--cfg myname="a" --cfg myname="b"'
#[cfg(myname = "a")]
println!("cfg(myname = 'a') is set");
#[cfg(myname = "b")]
println!("cfg(myname = 'b') is set");
```

```
cfg(myname = 'a') is set
cfg(myname = 'b') is set
```

Other than the `feature` values described in this section, the most commonly used config values are those that the toolchain
populates automatically, with values that describe the target environment for the build.  These include the OS
([target_os](https://doc.rust-lang.org/reference/conditional-compilation.html#target_os)), CPU
architecture
([target_arch](https://doc.rust-lang.org/reference/conditional-compilation.html#target_arch)),
pointer width
([target_pointer_width](https://doc.rust-lang.org/reference/conditional-compilation.html#target_pointer_width)),
and endianness
([target_endian](https://doc.rust-lang.org/reference/conditional-compilation.html#target_endian)).
This allows for code portability, where features that are specific to some particular target are compiled in only when
building for that target.

The standard [target_has_atomic](https://doc.rust-lang.org/reference/conditional-compilation.html#target_has_atomic)
option also provides an example of the multi-valued nature of config values: both `[cfg(target_has_atomic = "32")]` and
`[cfg(target_has_atomic = "64")]` will be set for targets that support both 32-bit and 64-bit atomic operations.  (For
more information on atomics, see Chapter 2 of  Mara Bos’s [Rust Atomics and Locks](https://marabos.nl/atomics/) [O’Reilly].)

## Features

The  [Cargo](https://doc.rust-lang.org/cargo/index.html) package manager builds on this base `cfg` name/value
mechanism to provide the concept of
[features](https://doc.rust-lang.org/cargo/reference/features.html): named selective aspects of the
functionality of a crate that can be enabled when building the crate.  Cargo ensures that the `feature` option is
populated with each of the configured values for each crate that it compiles, and the values are crate-specific.

This is Cargo-specific functionality: to the Rust compiler, `feature` is just another configuration option.

At the time of writing, the most reliable way to determine what features are available for a crate is to examine the
crate’s  [Cargo.toml](https://doc.rust-lang.org/cargo/reference/manifest.html) manifest file.  For
example, the following chunk of a manifest file includes *six* features:

```
[features]
default = ["featureA"]
featureA = []
featureB = []
# Enabling `featureAB` also enables `featureA` and `featureB`.
featureAB = ["featureA", "featureB"]
schema = []

[dependencies]
rand = { version = "^0.8", optional = true }
hex = "^0.4"
```

Given that there are only five entries in the `[features]` stanza; there are clearly a couple of subtleties to watch out
for.

The first is that the  `default` line in the `[features]` stanza is a special feature name, used
to indicate to `cargo` which of the features should be enabled by default.  These features can still be disabled by
passing the `--no-default-features` flag to the build command, and a consumer of the crate can encode this in their
*Cargo.toml* file like so:

```
[dependencies]
somecrate = { version = "^0.3", default-features = false }
```

However, `default` still counts as a feature name, which can be tested in code:

```
#[cfg(feature = "default")]
println!("This crate was built with the \"default\" feature enabled.");
#[cfg(not(feature = "default"))]
println!("This crate was built with the \"default\" feature disabled.");
```

The second subtlety of feature definitions is hidden in the `[dependencies]` section of the original *Cargo.toml*
example: the `rand` crate is a dependency that is marked as `optional = true`, and that effectively makes `"rand"` into
the name of a feature.[7](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch04.html#id1581)  If the crate is compiled with `--features rand`, then that dependency is activated:

```
#[cfg(feature = "rand")]
pub fn pick_a_number() -> u8 {
    rand::random::<u8>()
}

#[cfg(not(feature = "rand"))]
pub fn pick_a_number() -> u8 {
    4 // chosen by fair dice roll.
}
```

This also means that *crate names and feature names share a namespace*, even though one is typically global (and usually
governed by `crates.io`), and one is local to the crate in question.  Consequently, *choose feature names
carefully* to avoid clashes with the names of any crates that might be relevant as potential dependencies. It is
possible to work around a clash, because Cargo includes a [mechanism that allows imported crates to be renamed](https://doc.rust-lang.org/cargo/reference/specifying-dependencies.html#renaming-dependencies-in-cargotoml) (the
`package` key), but it’s easier not to have to.

So you can *determine a crate’s features by examining `[features]`* as well as *`optional` `[dependencies]`* in the crate’s
*Cargo.toml* file.  To turn on a feature of a dependency, add the `features` option to the relevant line in the
`[dependencies]` stanza of your own manifest file:

```
[dependencies]
somecrate = { version = "^0.3", features = ["featureA", "rand" ] }
```

This line ensures that `somecrate` will be built with both the `featureA` and the `rand` feature enabled.  However, that
might not be the only features that are enabled; other features may also be enabled due to a phenomenon known as
[feature unification](https://doc.rust-lang.org/cargo/reference/features.html#feature-unification). This means that a crate will
get built with the *union* of all of the features that are requested by anything in the build graph. In other words, if
some other dependency in the build graph also relies on `somecrate`, but with just `featureB` enabled, then the crate
will be built with all of `featureA`, `featureB`, and `rand` enabled, to satisfy everyone.[8](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch04.html#id1587)  The
same consideration applies to default features: if your crate sets `default-features = false` for a dependency but some
other place in the build graph leaves the default features enabled, then enabled they will be.

Feature unification means that *features should be additive*; it’s a bad idea to have mutually incompatible features
because there’s nothing to prevent the incompatible features being simultaneously enabled by different users.

For example, if a crate exposes a `struct` and its fields publicly, it’s a bad idea to make the fields
feature-dependent:

#

```
/// A structure whose contents are public, so external users can construct
/// instances of it.
#[derive(Debug)]
pub struct ExposedStruct {
    pub data: Vec<u8>,

    /// Additional data that is required only when the `schema` feature
    /// is enabled.
    #[cfg(feature = "schema")]
    pub schema: String,
}
```

A user of the crate that tries to build an instance of the `struct` has a quandary: should they fill in the `schema`
field or not?  One way to *try* to solve this is to add a corresponding feature in the user’s *Cargo.toml*:

```
[features]
# The `use-schema` feature here turns on the `schema` feature of `somecrate`.
# (This example uses different feature names for clarity; real code is more
# likely to reuse the feature names across both places.)
use-schema = ["somecrate/schema"]
```

and to make the `struct` construction depend on this feature:

#

```
let s = somecrate::ExposedStruct {
    data: vec![0x82, 0x01, 0x01],

    // Only populate the field if we've requested
    // activation of `somecrate/schema`.
    #[cfg(feature = "use_schema")]
    schema: "[int int]",
};
```

However, this doesn’t cover all eventualities: the code will fail to compile if this code doesn’t activate
`somecrate/schema` but some other transitive dependency does.  The core of the problem is that only the crate that has
the feature can check the feature; there’s no way for the user of the crate to determine whether Cargo has turned on
`somecrate/schema` or not. As a result, you should *avoid feature-gating public fields* in structures.

A similar consideration applies to public traits, intended to be used outside the crate they’re defined in.  Consider a
trait that includes a feature gate on one of its methods:

#

```
/// Trait for items that support CBOR serialization.
pub trait AsCbor: Sized {
    /// Convert the item into CBOR-serialized data.
    fn serialize(&self) -> Result<Vec<u8>, Error>;

    /// Create an instance of the item from CBOR-serialized data.
    fn deserialize(data: &[u8]) -> Result<Self, Error>;

    /// Return the schema corresponding to this item.
    #[cfg(feature = "schema")]
    fn cddl(&self) -> String;
}
```

External trait implementors again have a quandary: should they implement the `cddl(&self)` method or not?  The external
code that tries to implement the trait doesn’t know—and can’t tell—whether to implement the feature-gated
method or not.

So the net is that you should *avoid feature-gating methods on public traits*.  A trait method with a
default implementation ([Item 13](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch02.html#file_default-impl_md)) might be a partial exception to this⁠—​but only if it never makes sense
for external code to override the default.

Feature unification also means that if your crate has *N* independent
features,[9](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch04.html#id1598) then all of the 2N possible build combinations can occur in practice.  To avoid unpleasant
surprises, it’s a good idea to ensure that your CI system ([Item 32](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch05.html#file_ci_md)) covers all of these
2N combinations, in all of the available test variants ([Item 30](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch05.html#file_testing_md)).

However, the use of optional features is very helpful in controlling exposure to an expanded dependency graph ([Item 25](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch04.html#file_dep-graph_md)).  This is particularly useful in low-level crates that are capable of being used in a  `no_std` environment
([Item 33](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch06.html#file_no-std_md))—it’s common to have a `std` or `alloc` feature that turns on functionality that relies on those
libraries.

## Things to Remember

-

Feature names overlap with dependency names.

-

Feature names should be carefully chosen so they don’t clash with potential dependency names.

-

Features should be additive.

-

Avoid feature gates on public `struct` fields or trait methods.

-

Having lots of independent features potentially leads to a combinatorial explosion of different build configurations.

[1](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch04.html#id1413-marker) With the notable exception of C and C++, where package management remains somewhat fragmented.

[2](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch04.html#id1440-marker) For example,  [cargo-semver-checks](https://github.com/obi1kenobi/cargo-semver-checks) is a tool that attempts to do something along these lines.

[3](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch04.html#id1498-marker) This example (and indeed Item) is inspired by the approach used in the  [RustCrypto crates](https://oreil.ly/7w1iF).

[4](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch04.html#id1503-marker) This kind of error can even appear when the dependency graph includes two alternatives for a crate with the *same version*, when something in the build graph uses the [path](https://doc.rust-lang.org/cargo/reference/specifying-dependencies.html#specifying-path-dependencies) field to specify a local directory instead of a `crates.io` location.

[5](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch04.html#id1512-marker) It’s also possible to configure an [alternate registry](https://doc.rust-lang.org/cargo/reference/registries.html) of crates (for example, an internal corporate registry).  Each dependency entry in *Cargo.toml* can then use the `registry` key to indicate which registry a dependency should be sourced from.

[6](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch04.html#id1544-marker) If you are targeting a `no_std` environment, this choice may be made for you: many crates are not compatible with `no_std`, particularly if `alloc` is also unavailable ([Item 33](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch06.html#file_no-std_md)).

[7](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch04.html#id1581-marker) This default behavior can be disabled by using a `"dep:<crate>"` reference elsewhere in the `features` stanza; see the [docs](https://oreil.ly/HnLOJ) for details.

[8](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch04.html#id1587-marker) The `cargo tree --edges features` command can help with determining which features are enabled for which crates, and why.

[9](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch04.html#id1598-marker) Features can force other features to be enabled; in the original example, the `featureAB` feature forces both `featureA` and `featureB` to be enabled.

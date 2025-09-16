# Chapter 11. Operator Overloading

# A Note for Early Release Readers

With Early Release ebooks, you get books in their earliest form—the author’s raw and unedited content as they write—so you can take advantage of these technologies long before the official release of these titles.

This will be the 12th chapter of the final book. Please note that the GitHub repo will be made active later on.

If you have comments about how we might improve the content and/or examples in this book, or if you notice missing material within this chapter, please reach out to the editor at *jbleiel@oreilly.com*.

In the Mandelbrot set plotter we showed in [Chapter 1](https://learning.oreilly.com/library/view/programming-rust-3rd/9781098176228/ch01.html#a-tour-of-rust), we used the `num` crate’s `Complex` type to represent a number on the complex plane:

```
#[derive(Clone, Copy, Debug)]
struct Complex<T> {
    /// Real portion of the complex number
    re: T,

    /// Imaginary portion of the complex number
    im: T,
}
```

We were able to add and multiply `Complex` numbers just like any built-in numeric type, using Rust’s `+` and `*` operators:

```
z = z * z + c;
```

You can make your own types support arithmetic and other operators, too, just by implementing a few built-in traits. This is called *operator overloading*, and the effect is much like operator overloading in C‍++, C#, Python, and Ruby.

The traits for operator overloading fall into a few categories depending on what part of the language they support, as shown in [Table 11-1](https://learning.oreilly.com/library/view/programming-rust-3rd/9781098176228/ch11.html#operator-traits-table). In this chapter, we’ll cover each category. Our goal is not just to help you integrate your own types nicely into the language, but also to give you a better sense of how to write generic functions like the dot product function described in [“Reverse-Engineering Bounds”](https://learning.oreilly.com/library/view/programming-rust-3rd/9781098176228/ch10.html#reverse-engineering-bounds) that operate on types most naturally used via these operators. The chapter should also give some insight into how some features of the language itself are implemented.

| Category | Trait | Operator |
| --- | --- | --- |
| Unary operators | `std::ops::Neg` | `-x` |
| `std::ops::Not` | `!x` |  |
| Arithmetic operators | `std::ops::Add` | `x + y` |
| `std::ops::Sub` | `x - y` |  |
| `std::ops::Mul` | `x * y` |  |
| `std::ops::Div` | `x / y` |  |
| `std::ops::Rem` | `x % y` |  |
| Bitwise operators | `std::ops::BitAnd` | `x & y` |
| `std::ops::BitOr` | `x \| y` |  |
| `std::ops::BitXor` | `x ^ y` |  |
| `std::ops::Shl` | `x << y` |  |
| `std::ops::Shr` | `x >> y` |  |
| Compound assignment  <br><br>			arithmetic operators | `std::ops::AddAssign` | `x += y` |
| `std::ops::SubAssign` | `x -= y` |  |
| `std::ops::MulAssign` | `x *= y` |  |
| `std::ops::DivAssign` | `x /= y` |  |
| `std::ops::RemAssign` | `x %= y` |  |
| Compound assignment  <br><br>			bitwise operators | `std::ops::BitAndAssign` | `x &= y` |
| `std::ops::BitOrAssign` | `x \|= y` |  |
| `std::ops::BitXorAssign` | `x ^= y` |  |
| `std::ops::ShlAssign` | `x <<= y` |  |
| `std::ops::ShrAssign` | `x >>= y` |  |
| Comparison | `std::cmp::PartialEq` | `x == y`, `x != y` |
| `std::cmp::PartialOrd` | `x < y`,  `x <= y`,  `x > y`,  `x >= y` |  |
| Indexing | `std::ops::Index` | `x[y]`,  `&x[y]` |
| `std::ops::IndexMut` | `x[y] = z`,  `&mut x[y]` |  |

# Arithmetic and Bitwise Operators

In Rust, the expression `a + b` is actually shorthand for `std::ops::Add::add(a, b)`, a call to the `add` method of the standard library’s `Add` trait. If you import the trait, you can write this as an ordinary method call, `a.add(b)`:

```
use std::ops::Add;

assert_eq!(4.125f32.add(5.75), 9.875);
assert_eq!(10.add(20), 10 + 20);
```

Rust’s standard numeric types all implement `std::ops::Add`. To make the expression `a + b` work for `Complex` values, the `num` crate implements this trait for `Complex` as well. Similar traits cover the other operators: `a * b` is shorthand for `std::ops::Mul::mul(a, b)`, `std::ops::Neg` covers the prefix `-` negation operator, and so on.

Here’s the definition of `std::ops::Add`:

```
trait Add<Rhs = Self> {
    type Output;
    fn add(self, rhs: Rhs) -> Self::Output;
}
```

In other words, the trait `Add<T>` is the ability to add a `T` value to yourself. For example, if you want to be able to add `i32` and `u32` values to your type, your type must implement both `Add<i32>` and `Add<u32>`. The trait’s type parameter `Rhs` defaults to `Self`, so if you’re implementing addition between two values of the same type, you can simply write `Add` for that case. The associated type `Output` describes the result of the addition.

For example, to be able to add `Complex<i32>` values together, `Complex<i32>` must implement `Add<Complex<i32>>`. Since we’re adding a type to itself, we just write `Add`:

```
use std::ops::Add;

impl Add for Complex<i32> {
    type Output = Complex<i32>;
    fn add(self, rhs: Self) -> Self {
        Complex {
            re: self.re + rhs.re,
            im: self.im + rhs.im,
        }
    }
}
```

Of course, we shouldn’t have to implement `Add` separately for `Complex<i32>`, `Complex<f32>`, `Complex<f64>`, and so on. All the definitions would look exactly the same except for the types involved, so we should be able to write a single generic implementation that covers them all, as long as the type of the complex components themselves supports addition:

```
use std::ops::Add;

impl<T> Add for Complex<T>
where
    T: Add<Output = T>,
{
    type Output = Self;
    fn add(self, rhs: Self) -> Self {
        Complex {
            re: self.re + rhs.re,
            im: self.im + rhs.im,
        }
    }
}
```

By writing `where T: Add<Output = T>`, we restrict `T` to types that can be added to themselves, yielding another `T` value. This is a reasonable restriction, but we could loosen things still further: the `Add` trait doesn’t require both operands of `+` to have the same type, nor does it constrain the result type. So a maximally generic implementation would let the left- and righthand operands vary independently and produce a `Complex` value of whatever component type that addition produces:

```
use std::ops::Add;

impl<L, R> Add<Complex<R>> for Complex<L>
where
    L: Add<R>,
{
    type Output = Complex<L::Output>;
    fn add(self, rhs: Complex<R>) -> Self::Output {
        Complex {
            re: self.re + rhs.re,
            im: self.im + rhs.im,
        }
    }
}
```

In practice, however, Rust tends to avoid supporting mixed-type operations. Since our type parameter `L` must implement `Add<R>`, it usually follows that `L` and `R` are going to be the same type: there simply aren’t that many types available for `L` that implement anything else. So in the end, this maximally generic version may not be much more useful than the prior, simpler generic definition.

Rust’s built-in traits for arithmetic and bitwise operators come in three groups: unary operators, binary operators, and compound assignment operators. Within each group, the traits and their methods all have the same form, so we’ll cover one example from each.

## Unary Operators

Aside from the dereferencing operator `*`, which we’ll cover separately in [Link to Come], Rust has two unary operators that you can customize, shown in [Table 11-2](https://learning.oreilly.com/library/view/programming-rust-3rd/9781098176228/ch11.html#built-in-traits-unary).

| Trait name | Expression | Equivalent method call |
| --- | --- | --- |
| `std::ops::Neg` | `-x` | `Neg::neg(x)` |
| `std::ops::Not` | `!x` | `Not::not(x)` |

These traits’ definitions are simple:

```
trait Neg {
    type Output;
    fn neg(self) -> Self::Output;
}

trait Not {
    type Output;
    fn not(self) -> Self::Output;
}
```

Negating a complex number simply negates each of its components. Here’s how we might write a generic implementation of negation for `Complex` values:

```
use std::ops::Neg;

impl<T> Neg for Complex<T>
where
    T: Neg<Output = T>,
{
    type Output = Complex<T>;
    fn neg(self) -> Complex<T> {
        Complex {
            re: -self.re,
            im: -self.im,
        }
    }
}
```

## Binary Operators

Rust’s binary arithmetic and bitwise operators and their corresponding built-in traits appear in [Table 11-3](https://learning.oreilly.com/library/view/programming-rust-3rd/9781098176228/ch11.html#built-in-traits-binary).

| Category | Trait name | Expression | Equivalent method call |
| --- | --- | --- | --- |
| Arithmetic operators | `std::ops::Add` | `x + y` | `Add::add(x, y)` |
| `std::ops::Sub` | `x - y` | `Sub::sub(x, y)` |  |
| `std::ops::Mul` | `x * y` | `Mul::mul(x, y)` |  |
| `std::ops::Div` | `x / y` | `Div::div(x, y)` |  |
| `std::ops::Rem` | `x % y` | `Rem::rem(x, y)` |  |
| Bitwise operators | `std::ops::BitAnd` | `x & y` | `BitAnd::bitand(x, y)` |
| `std::ops::BitOr` | `x \| y` | `BitOr::bitor(x, y)` |  |
| `std::ops::BitXor` | `x ^ y` | `BitXor::bitxor(x, y)` |  |
| `std::ops::Shl` | `x << y` | `Shl::shl(x, y)` |  |
| `std::ops::Shr` | `x >> y` | `Shr::shr(x, y)` |  |

All of the traits here have the same general form. The definition of `std::ops::BitXor`, for the `^` operator, looks like this:

```
trait BitXor<Rhs = Self> {
    type Output;
    fn bitxor(self, rhs: Rhs) -> Self::Output;
}
```

At the beginning of this chapter, we also showed `std::ops::Add`, another trait in this category, along with several sample implementations.

## Compound Assignment Operators

A compound assignment expression is one like `x += y` or `x &= y`: it takes two operands, performs some operation on them like addition or a bitwise AND, and stores the result back in the left operand. In Rust, the value of a compound assignment expression is always `()`, never the value stored.

The syntax `x += y` is shorthand for the method call `std::ops::AddAssign::add_assign(&mut x, y)`, using this built-in trait:

```
trait AddAssign<Rhs = Self> {
    fn add_assign(&mut self, rhs: Rhs);
}
```

If `x` doesn’t implement `AddAssign`, then `x += y` is an error; Rust does not fall back to `x = x + y`.

[Table 11-4](https://learning.oreilly.com/library/view/programming-rust-3rd/9781098176228/ch11.html#built-in-traits-compound) shows all of Rust’s compound assignment operators and the built-in traits that implement them.

| Category | Trait name | Expression | Equivalent method call |
| --- | --- | --- | --- |
| Arithmetic  <br>operators | `std::ops::AddAssign` | `x += y` | `AddAssign::add_assign(&mut x, y)` |
| `std::ops::SubAssign` | `x -= y` | `SubAssign::sub_assign(&mut x, y)` |  |
| `std::ops::MulAssign` | `x *= y` | `MulAssign::mul_assign(&mut x, y)` |  |
| `std::ops::DivAssign` | `x /= y` | `DivAssign::div_assign(&mut x, y)` |  |
| `std::ops::RemAssign` | `x %= y` | `RemAssign::rem_assign(&mut x, y)` |  |
| Bitwise  <br>operators | `std::ops::BitAndAssign` | `x &= y` | `BitAndAssign::bitand_assign(&mut x, y)` |
| `std::ops::BitOrAssign` | `x \|= y` | `BitOrAssign::bitor_assign(&mut x, y)` |  |
| `std::ops::BitXorAssign` | `x ^= y` | `BitXorAssign::bitxor_assign(&mut x, y)` |  |
| `std::ops::ShlAssign` | `x <<= y` | `ShlAssign::shl_assign(&mut x, y)` |  |
| `std::ops::ShrAssign` | `x >>= y` | `ShrAssign::shr_assign(&mut x, y)` |  |

A generic implementation of `AddAssign` for our `Complex` type is straightforward:

```
use std::ops::AddAssign;

impl<T> AddAssign for Complex<T>
where
    T: AddAssign<T>,
{
    fn add_assign(&mut self, rhs: Complex<T>) {
        self.re += rhs.re;
        self.im += rhs.im;
    }
}
```

The built-in trait for a compound assignment operator is completely independent of the built-in trait for the corresponding binary operator. Implementing `std::ops::Add` does not automatically implement `std::ops::AddAssign`; if you want Rust to permit your type as the lefthand operand of a `+=` operator, you must implement `AddAssign` yourself.

# Equivalence Comparisons

Rust’s equality operators, `==` and `!=`, are shorthand for calls to the `std::cmp::PartialEq` trait’s `eq` and `ne` methods:

```
assert_eq!(x == y, x.eq(&y));
assert_eq!(x != y, x.ne(&y));
```

Here’s the definition of `std::cmp::PartialEq`:

```
trait PartialEq<Rhs = Self>
where
    Rhs: ?Sized,
{
    fn eq(&self, other: &Rhs) -> bool;
    fn ne(&self, other: &Rhs) -> bool {
        !self.eq(other)
    }
}
```

Note that the `ne` method comes with a default definition. It’s likely you will never encounter a good reason to implement `ne` yourself. Anyone using `!=` will assume that `x != y` means exactly that `x` is not `==` to `y`, and that’s what the default definition does. So the following is a complete implementation for `Complex`:

```
impl<T: PartialEq> PartialEq for Complex<T> {
    fn eq(&self, other: &Complex<T>) -> bool {
        self.re == other.re && self.im == other.im
    }
}
```

In other words, for any component type `T` that itself can be compared for equality, this implements comparison for `Complex<T>`. Assuming we’ve also implemented `std::ops::Mul` for `Complex` somewhere along the line, we can now write:

```
let x = Complex { re: 5, im: 2 };
let y = Complex { re: 2, im: 5 };
assert_eq!(x * y, Complex { re: 0, im: 29 });
```

Implementations of `PartialEq` are almost always of the form shown here: they compare each field of the left operand to the corresponding field of the right. These get tedious to write, and equality is a common operation to support, so if you ask, Rust will generate an implementation of `PartialEq` for you automatically. Simply add `PartialEq` to the type definition’s `derive` attribute like so:

```
#[derive(Clone, Copy, Debug, PartialEq)]
struct Complex<T> {
    ...
}
```

Rust’s automatically generated implementation is essentially identical to our hand-written code, comparing each field of the type in turn. Rust can derive `PartialEq` implementations for `enum` types as well. Naturally, each field of the `struct` or `enum` must itself implement `PartialEq`.

Unlike the arithmetic and bitwise traits, which take their operands by value, `PartialEq` takes its operands by reference. This means that comparing non-`Copy` values like `String`s, `Vec`s, or `HashMap`s doesn’t cause them to be moved, which would be troublesome:

```
let s = "d\x6fv\x65t\x61i\x6c".to_string();
let t = "\x64o\x76e\x74a\x69l".to_string();
assert!(s == t);  // s and t are only borrowed...

// ... so they still have their values here.
assert_eq!(format!("{s} {t}"), "dovetail dovetail");
```

This leads us to the trait’s bound on the `Rhs` type parameter, which is of a kind we haven’t seen before:

```
where
    Rhs: ?Sized,
```

This relaxes Rust’s usual requirement that type parameters must be sized types, letting us write traits like `PartialEq<str>` or `PartialEq<[T]>`. The `eq` and `ne` methods take parameters of type `&Rhs`, and comparing something with a `&str` or a `&[T]` is completely reasonable. Since `str` implements `PartialEq<str>`, the following assertions are equivalent:

```
assert!("ungula" != "ungulate");
assert!("ungula".ne("ungulate"));
```

Here, both `Self` and `Rhs` would be the unsized type `str`, making `ne`’s `self` and `rhs` parameters both `&str` values. We’ll discuss sized types, unsized types, and the `Sized` trait in detail in [Link to Come].

You may be wondering why this trait is called `PartialEq`. Explaining this requires a bit of a detour into the weird behavior of floating-point not-a-numbers.

## The Eq Trait (Or: Equality vs. NaN)

We have already mentioned one rule about the `PartialEq` trait that all implementations ought to follow:

- `x != y` should return exactly the same result as `!(x == y)`.

Rust doesn’t enforce this rule. You can implement both `eq` and `ne` by hand to do whatever you want. Breaking the rule won’t lead to undefined behavior, but it’s bound to be confusing for your users, and programmer confusion leads to bugs.

So the `PartialEq` trait is more than just a collection of methods. It consists of two methods plus the above rule—a promise of good behavior that `PartialEq` implementations make to their users.

The traditional mathematical definition of an *equivalence relation*, of which equality is one instance, consists of three further rules. For any values `x` and `y`:

-

If `x == y` is true, then `y == x` must be true as well. In other words, swapping the two sides of an equality comparison doesn’t affect the result.

-

If `x == y` and `y == z`, then it must be the case that `x == z`. Given any chain of values, each equal to the next, each value in the chain is directly equal to every other. Equality is contagious.

-

It must always be true that `x == x`.

That last requirement might seem too obvious to be worth stating, but this is exactly where things go awry. Rust’s `f32` and `f64` are IEEE standard floating-point values. According to that standard, expressions like `0.0/0.0` and others with no appropriate value must produce special *not-a-number* values, usually referred to as NaN values. The standard further requires that a NaN value be treated as unequal to every other value—including itself. For example, the standard requires all the following behaviors:

```
let nan: f64 = 0.0 / 0.0;
assert!(nan.is_nan());
assert_eq!(nan == nan, false);
assert_eq!(nan != nan, true);
```

Furthermore, any ordered comparison with a NaN value must return false:

```
assert_eq!(nan < nan, false);
assert_eq!(nan > nan, false);
assert_eq!(nan <= nan, false);
assert_eq!(nan >= nan, false);
```

So while Rust’s `==` operator meets the first two requirements for equivalence relations, it clearly doesn’t meet the third when used on IEEE floating-point values. This is called a *partial equivalence relation*, so Rust uses the name `PartialEq` for the `==` operator’s built-in trait. If you write generic code with type parameters known only to be `PartialEq`, you may assume the first two requirements hold, but you can’t assume that values always equal themselves.

This can be more than a little inconvenient. Suppose you’re writing a generic lookup table. You might write something like `table_entry.key == search_key` to check whether an entry matches. This is the only reasonable thing to do, and it works correctly, except when the keys are floating-point numbers and we go searching for a NaN value. That exact NaN key might be present in the table, but it won’t match, because NaN isn’t `==` itself. The consequences might get quite silly. If the user decides to add a new entry whenever a match isn’t found, a single lookup table could accumulate many entries with the same NaN key.

The only way to avoid this kind of nonsense in your generic code is to rule out types with such misbehaving values. Rust provides the `std::cmp::Eq` trait for this purpose. `Eq` represents a full equivalence relation: if a type implements `Eq`, then `x == x` must be `true` for every value `x` of that type. In practice, almost every type that implements `PartialEq` should implement `Eq` as well; `f32` and `f64` are the only types in the standard library that are `PartialEq` but not `Eq`.

The standard library defines `Eq` as an extension of `PartialEq`, adding no new methods:

```
trait Eq: PartialEq<Self> {}
```

The trait has no features of its own, only those implied by the supertrait `PartialEq<Self>`. `Eq` is, indeed, nothing more than `PartialEq` plus one additional rule. Implementing it is therefore trivial:

```
impl<T: Eq> Eq for Complex<T> {}
```

Even this one line of code can be derived:

```
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
struct Complex<T> {
    ...
}
```

Derived implementations on a generic type may depend on the type parameters. With the `derive` attribute, `Complex<i32>` would implement `Eq`, because `i32` does, but `Complex<f32>` would only implement `PartialEq`, since `f32` doesn’t implement `Eq`.

If you insincerely implement `Eq` for a type where values aren’t equal to themselves, it won’t lead to undefined behavior, but other code that relies on the `Eq` promise, including standard library features like `HashMap`, may behave strangely and produce silly results.

# Ordered Comparisons

Rust specifies the behavior of the ordered comparison operators `<`, `>`, `<=`, and `>=` all in terms of a single trait, `std::cmp::PartialOrd`:

```
trait PartialOrd<Rhs = Self>: PartialEq<Rhs>
where
    Rhs: ?Sized,
{
    fn partial_cmp(&self, other: &Rhs) -> Option<Ordering>;

    fn lt(&self, other: &Rhs) -> bool { ... }
    fn le(&self, other: &Rhs) -> bool { ... }
    fn gt(&self, other: &Rhs) -> bool { ... }
    fn ge(&self, other: &Rhs) -> bool { ... }
}
```

Note that `PartialOrd<Rhs>` extends `PartialEq<Rhs>`: you can do ordered comparisons only on types that you can also compare for equality.

The only method of `PartialOrd` you must implement yourself is `partial_cmp`. When `partial_cmp` returns `Some(o)`, then `o` indicates `self`’s relationship to `other`:

```
enum Ordering {
    Less,       // self < other
    Equal,      // self == other
    Greater,    // self > other
}
```

But if `partial_cmp` returns `None`, that means `self` and `other` are unordered with respect to each other: neither is greater than the other, nor are they equal. Among all of Rust’s primitive types, only comparisons between floating-point values ever return `None`: specifically, comparing a NaN (not-a-number) value with anything else returns `None`.

Like the other binary operators, to compare values of two types `Left` and `Right`, `Left` must implement `PartialOrd<Right>`. Expressions like `x < y` or `x >= y` are shorthand for calls to `PartialOrd` methods, as shown in [Table 11-5](https://learning.oreilly.com/library/view/programming-rust-3rd/9781098176228/ch11.html#built-in-traits-ord).

| Expression | Equivalent method call | Default definition |
| --- | --- | --- |
| `x < y` | `PartialOrd::lt(&x, &y)` | `x.partial_cmp(&y) == Some(Less)` |
| `x > y` | `PartialOrd::gt(&x, &y)` | `x.partial_cmp(&y) == Some(Greater)` |
| `x <= y` | `PartialOrd::le(&x, &y)` | `matches!(x.partial_cmp(&y), Some(Less \| Equal))` |
| `x >= y` | `PartialOrd::ge(&x, &y)` | `matches!(x.partial_cmp(&y), Some(Greater \| Equal))` |

As in prior examples, the equivalent method call code shown assumes that `std::cmp::PartialOrd` and `std::cmp::Ordering` are in scope.

If a type is totally ordered, so that `partial_cmp` never returns `None`, then the type can implement the stricter `std::cmp::Ord` trait:

```
trait Ord: Eq + PartialOrd<Self> {
    fn cmp(&self, other: &Self) -> Ordering;

    fn max(self, other: Self) -> Self ...
    fn min(self, other: Self) -> Self ...
    fn clamp(self, lo: Self, hi: Self) -> Self ...
}
```

The `cmp` method here simply returns an `Ordering`, instead of an `Option<Ordering>` like `partial_cmp`: `cmp` always declares its arguments equal or indicates their relative order. Almost all types that implement `PartialOrd` should also implement `Ord`. In the standard library, `f32` and `f64` are the only exceptions to this rule. Again, as with `Eq`, this is due to NaN values.

`Ord` provides three additional methods, all with straightforward default implementations:

- **`a.max(b)`** returns the greater of the two values `a` and `b`.
- **`a.min(b)`** returns the lesser of the two values.
- **`a.clamp(lo, hi)`** applies upper and lower bounds to the value `a`. That is, it returns the value in the inclusive range from `lo` to `hi` that is closest to `a`. It panics if `hi < lo`.

Types that implement `Ord` are also sortable. As we’ll see in [Link to Come], the standard library has several sorting-related features: the `.sort()` method on slices, binary searching, B-trees, and binary heaps. All of these work only on types that implement `Ord`.

However, there are real-world cases, even setting aside NaNs, where it makes sense to implement `PartialOrd` for a type that does not qualify as `Ord`. Suppose you’re working with the following type, representing the set of numbers falling within a given half-open interval:

```
#[derive(Debug, PartialEq)]
struct Interval<T> {
    lower: T,  // inclusive
    upper: T,  // exclusive
}
```

You’d like to make values of this type partially ordered: one interval is less than another if it falls entirely before the other, with no overlap. If two unequal intervals overlap, they’re unordered: some element of each side is less than some element of the other. And two equal intervals are simply equal. The following implementation of `PartialOrd` implements those rules:

```
use std::cmp::{Ordering, PartialOrd};

impl<T: PartialOrd> PartialOrd<Interval<T>> for Interval<T> {
    fn partial_cmp(&self, other: &Interval<T>) -> Option<Ordering> {
        if self == other {
            Some(Ordering::Equal)
        } else if self.lower >= other.upper {
            Some(Ordering::Greater)
        } else if self.upper <= other.lower {
            Some(Ordering::Less)
        } else {
            None
        }
    }
}
```

With that implementation in place, you can write the following:

```
assert!(Interval { lower: 10, upper: 20 } <  Interval { lower: 20, upper: 40 });
assert!(Interval { lower: 7,  upper: 8  } >= Interval { lower: 0,  upper: 1  });
assert!(Interval { lower: 7,  upper: 8  } <= Interval { lower: 7,  upper: 8  });

// Overlapping intervals aren't ordered with respect to each other.
let left  = Interval { lower: 10, upper: 30 };
let right = Interval { lower: 20, upper: 40 };
assert!(!(left < right));
assert!(!(left >= right));
```

Since this is not a total order, we’ve implemented only `PartialOrd`, not `Ord`. Therefore, if we want to sort a vector of intervals, simply calling `.sort()` won’t work. We must explicitly specify a sort order. Sorting by upper bound, for instance, can be done with `sort_by_key`:

```
intervals.sort_by_key(|i| i.upper);
```

`Interval<i32>` doesn’t implement `Ord`, but our sort key (`i.upper`, which is an `i32`) does. For more about sorting, see [Link to Come].

# Index and IndexMut

You can specify how an indexing expression like `a[i]` works on your type by implementing the `std::ops::Index` and `std::ops::IndexMut` traits. Arrays support the `[]` operator directly, but on any other type, the expression `a[i]` is normally shorthand for `*a.index(i)`, where `index` is a method of the `std::ops::Index` trait. However, if the expression is being assigned to or borrowed mutably, it’s instead shorthand for `*a.index_mut(i)`, a call to the method of the `std::ops::IndexMut` trait.

Here are the traits’ definitions:

```
trait Index<Idx> {
    type Output: ?Sized;
    fn index(&self, index: Idx) -> &Self::Output;
}

trait IndexMut<Idx>: Index<Idx> {
    fn index_mut(&mut self, index: Idx) -> &mut Self::Output;
}
```

Note that these traits take the type of the index expression as a parameter. You can index a slice with a single `usize`, referring to a single element, because slices implement `Index<usize>`. But you can refer to a subslice with an expression like `a[i..j]` because they also implement `Index<Range<usize>>`. That expression is shorthand for:

```
*a.index(std::ops::Range { start: i, end: j })
```

Rust’s `HashMap` and `BTreeMap` collections let you use any hashable or ordered type as the index. The following code works because `HashMap<&str, i32>` implements `Index<&str>`:

```
use std::collections::HashMap;
let mut m = HashMap::new();
m.insert("十", 10);
m.insert("百", 100);
m.insert("千", 1000);
m.insert("万", 1_0000);
m.insert("億", 1_0000_0000);

assert_eq!(m["十"], 10);
assert_eq!(m["千"], 1000);
```

Those indexing expressions are equivalent to:

```
use std::ops::Index;
assert_eq!(*m.index("十"), 10);
assert_eq!(*m.index("千"), 1000);
```

The `Index` trait’s associated type `Output` specifies what type an indexing expression produces: for our `HashMap`, the `Index` implementation’s `Output` type is `i32`.

The `IndexMut` trait extends `Index` with an `index_mut` method that takes a mutable reference to `self`, and returns a mutable reference to an `Output` value. Rust automatically selects `index_mut` when the indexing expression occurs in a context where it’s necessary. For example, suppose we write the following:

```
let mut desserts =
    vec!["Howalon".to_string(), "Soan papdi".to_string()];
desserts[0].push_str(" (fictional)");
desserts[1].push_str(" (real)");
```

Because the `push_str` method operates on `&mut self`, those last two lines are equivalent to:

```
use std::ops::IndexMut;
(*desserts.index_mut(0)).push_str(" (fictional)");
(*desserts.index_mut(1)).push_str(" (real)");
```

One limitation of `IndexMut` is that, by design, it must return a mutable reference to some value. This is why you can’t use an expression like `m["十"] = 10;` to insert a value into the `HashMap` `m`: the table would need to create an entry for `"十"` first, with some default value, and return a mutable reference to that. But not all types have cheap default values, and some may be expensive to drop; it would be a waste to create such a value only to be immediately dropped by the assignment. (There are plans to improve this in later versions of the language.)

The most common use of indexing is for collections. For example, suppose we are working with bitmapped images, like the ones we created in the Mandelbrot set plotter in [Chapter 1](https://learning.oreilly.com/library/view/programming-rust-3rd/9781098176228/ch01.html#a-tour-of-rust). Recall that our program contained code like this:

```
pixels[row * bounds.0 + column] = ...;
```

It would be nicer to have an `Image<u8>` type that acts like a two-dimensional array, allowing us to access pixels without having to write out all the arithmetic:

```
image[row][column] = ...;
```

To do this, we’ll need to declare a struct:

```
struct Image<P> {
    width: usize,
    pixels: Vec<P>,
}

impl<P: Default + Copy> Image<P> {
    /// Create a new image of the given size.
    fn new(width: usize, height: usize) -> Image<P> {
        Image {
            width,
            pixels: vec![P::default(); width * height],
        }
    }
}
```

And here are implementations of `Index` and `IndexMut` that would fit the bill:

```
impl<P> std::ops::Index<usize> for Image<P> {
    type Output = [P];
    fn index(&self, row: usize) -> &[P] {
        let start = row * self.width;
        &self.pixels[start..start + self.width]
    }
}

impl<P> std::ops::IndexMut<usize> for Image<P> {
    fn index_mut(&mut self, row: usize) -> &mut [P] {
        let start = row * self.width;
        &mut self.pixels[start..start + self.width]
    }
}
```

When you index into an `Image`, you get back a slice of pixels; indexing the slice gives you an individual pixel.

Note that when we write `image[row][column]`, if `row` is out of bounds, our `.index()` method will try to index `self.pixels` out of range, triggering a panic. This is how `Index` and `IndexMut` implementations are supposed to behave: out-of-bounds access is detected and causes a panic, the same as when you index an array, slice, or vector out of bounds.

# Other Operators

Not all operators can be overloaded in Rust. As of Rust 1.56, the error-checking  `?` operator works only with `Result` and a few other standard library types, but work is in progress to expand this to user-defined types as well. Similarly, the logical operators `&&` and `||` are limited to Boolean values only. The `..` and `..=` operators always create a struct representing the range’s bounds, the `&` operator always borrows references, and the `=` operator always moves or copies values. None of them can be overloaded.

The dereferencing operator, `*val`, and the dot operator for accessing fields and calling methods, as in `val.field` and `val.method()`, can be overloaded using the `Deref` and `DerefMut` traits, which are covered in the next chapter. (We did not include them here because these traits do more than just overload a few operators.)

Rust does not support overloading the function call operator, `f(x)`. Instead, when you need a callable value, you’ll typically just write a closure. We’ll explain how this works and cover the `Fn`, `FnMut`, and `FnOnce` special traits in [Link to Come].

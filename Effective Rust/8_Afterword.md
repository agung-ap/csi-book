# Afterword

Hopefully the advice, suggestions, and information in this book will help you  become a fluent,
productive Rust programmer. As the [Preface](https://learning.oreilly.com/library/view/effective-rust/9781098151393/preface01.html#file_preface_md) describes, this book is intended to cover the second step in this process, after you’ve learned the basics from a core Rust reference book. But there are more steps you can take and directions to explore:

-

*Async Rust*   is not covered in this book but is likely to be needed for efficient, concurrent
server-side applications.  The [online documentation](https://oreil.ly/a9r1B) provides an
introduction to `async`, and the forthcoming [Async Rust](https://learning.oreilly.com/library/view/async-rust/9781098149086/) by Maxwell Flitton and Caroline
Morton (O’Reilly, 2024) may also help.

-

Moving in the other direction,  *bare-metal Rust* might align with your interests and requirements.  This goes
beyond the introduction to `no_std` in [Item 33](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch06.html#file_no-std_md) to a world where there’s no operating system and no allocation. The
[bare-metal Rust section](https://oreil.ly/h_cfR) of the  [Comprehensive Rust](https://google.github.io/comprehensive-rust) online course provides a good introduction here.

-

Regardless of whether your interests are low-level or high-level, the [crates.io](https://crates.io/) ecosystem of
third-party, open source crates is worth exploring—and contributing to.  Curated summaries like
[blessed.rs](https://blessed.rs/) or [lib.rs](https://lib.rs/) can help navigate the huge number of
possibilities.

-

Rust discussion forums such as the [Rust language forum](https://users.rust-lang.org/) or [Reddit’s r/rust](https://reddit.com/r/rust) can provide help—and include a searchable index of questions that have been
asked (and answered!) previously.

-

If you find yourself relying on an existing library that’s not written in Rust (as per [Item 34](https://learning.oreilly.com/library/view/effective-rust/9781098151393/ch06.html#file_ffi_md)), you could
*rewrite it in Rust* (RiiR).  But don’t [underestimate the effort required](https://oreil.ly/iKRzI) to reproduce a battle-tested,
mature codebase.

-

As you become more skilled in Rust,  Jon Gjengset’s  *Rust for Rustaceans* (No Starch, 2022)
is an essential reference for more advanced aspects of Rust.

Good luck!

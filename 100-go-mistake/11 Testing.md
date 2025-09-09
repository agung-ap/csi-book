# 11 Testing

### This chapter covers
* Categorizing tests and making them more robust
* Making Go tests deterministic
* Working with utility packages such as `httptest` and `iotest`
* Avoiding common benchmark mistakes
* Improving the testing process

Testing is a crucial aspect of a project’s lifecycle. It offers countless benefits, such as building confidence in an application, acting as code documentation, and making refactoring easier. Compared to some other languages, Go has strong primitives for writing tests. Throughout this chapter, we look at common mistakes that make the testing process brittle, less effective, and less accurate.

## 11.1 #82: Not categorizing tests

The testing pyramid is a model that groups tests into different categories (see figure 11.1). Unit tests occupy the base of the pyramid. Most tests should be unit tests: they’re cheap to write, fast to execute, and highly deterministic. Usually, as we go further up the pyramid, tests become more complex to write and slower to run, and it is more difficult to guarantee their determinism.

##### Figure 11.1 An example of the testing pyramid
![Figure 11.1 An example of the testing pyramid](https://drek4537l1klr.cloudfront.net/harsanyi/HighResolutionFigures/figure_11-1.png)

A common technique is to be explicit about which kind of tests to run. For instance, depending on the project lifecycle stage, we may want to run only unit tests or run all the tests in the project. Not categorizing tests means potentially wasting time and effort and losing accuracy about the scope of a test. This section discusses three main ways to categorize tests in Go.

### 11.1.1 Build tags

The most common way to classify tests is using build tags. A build tag is a special comment at the beginning of a Go file, followed by an empty line.

For example, look at this bar.go file:

```go
//go:build foo

package bar
```

This file contains the `foo` tag. Note that one package may contain multiple files with different build tags.

> **NOTE**
> As of Go 1.17, the syntax `// +build foo` was replaced by `//go:build foo`. For the time being (Go 1.18), `gofmt` synchronizes the two forms to help with migration.

Build tags are used for two primary use cases. First, we can use a build tag as a conditional option to build an application: for example, if we want a source file to be included only if `cgo` is enabled (`cgo` is a way to let Go packages call C code), we can add the `//go:build cgo` build tag. Second, if we want to categorize a test as an integration test, we can add a specific build flag, such as `integration`.

Here is an example db_test.go file:

```go
//go:build integration

package db

import (
    "testing"
)

func TestInsert(t *testing.T) {
    // ...
}
```

Here we add the `integration` build tag to categorize that this file contains integration tests. The benefit of using build tags is that we can select which kinds of tests to execute. For example, let’s assume a package contains two test files:

* The file we just created: db_test.go
* Another file that doesn’t contain a build tag: contract_test.go

If we run `go test` inside this package without any options, it will run only the test files without build tags (contract_test.go):

```
$ go test -v .
=== RUN   TestContract
--- PASS: TestContract (0.01s)
PASS
```

However, if we provide the `integration` tag, running `go test` will also include db_test.go:

```
$ go test --tags=integration -v .
=== RUN   TestInsert
--- PASS: TestInsert (0.01s)
=== RUN   TestContract
--- PASS: TestContract (2.89s)
PASS
```

So, running tests with a specific tag includes both the files without tags and the files matching this tag. What if we want to run *only* integration tests? A possible way is to add a negation tag on the unit test files. For example, using `!integration` means we want to include the test file only if the `integration` flag is *not* enabled (contract_test.go):

```go
//go:build !integration

package db

import (
    "testing"
)

func TestContract(t *testing.T) {
    // ...
}
```

Using this approach,

* Running `go test` with the `integration` flag runs only the integration tests.
* Running `go test` without the `integration` flag runs only the unit tests.

Let’s discuss an option that works at the level of a single test, not a file.

### 11.1.2 Environment variables

As mentioned by Peter Bourgon, a member of the Go community, build tags have one main drawback: the absence of signals that a test has been ignored (see http://mng.bz/qYlr). In the first example, when we executed `go test` without build flags, it showed only the tests that were executed:

```
$ go test -v .
=== RUN   TestUnit
--- PASS: TestUnit (0.01s)
PASS
ok      db  0.319s
```

If we’re not careful with the way tags are handled, we may forget about existing tests. For that reason, some projects favor the approach of checking the test category using environment variables.

For example, we can implement the `TestInsert` integration test by checking a specific environment variable and potentially skipping the test:

```go
func TestInsert(t *testing.T) {
    if os.Getenv("INTEGRATION") != "true" {
        t.Skip("skipping integration test")
    }

    // ...
}
```

If the `INTEGRATION` environment variable isn’t set to `true`, the test is skipped with a message:

```
$ go test -v .
=== RUN   TestInsert
    db_integration_test.go:12: skipping integration test     #1
--- SKIP: TestInsert (0.00s)
=== RUN   TestUnit
--- PASS: TestUnit (0.00s)
PASS
ok      db  0.319s
```
> #1 Shows the test-skipped message

One benefit of using this approach is making explicit which tests are skipped and why. This technique is probably less widely used than build tags, but it’s worth knowing about because it presents some advantages, as we discussed.

Next, let’s look at another way to categorize tests: short mode.

### 11.1.3 Short mode

Another approach to categorize tests is related to their speed. We may have to dissociate short-running tests from long-running tests.

As an illustration, suppose we have a set of unit tests, one of which is notoriously slow. We would like to categorize the slow test so we don’t have to run it every time (especially if the trigger is after saving a file, for example). Short mode allows us to make this distinction:

```go
func TestLongRunning(t *testing.T) {
    if testing.Short() {                        // #1
        t.Skip("skipping long-running test")
    }
    // ...
}
```
> #1 Marks the test as long-running

Using `testing.Short`, we can retrieve whether short mode was enabled while running the test. Then we use `Skip` to skip the test. To run tests using short mode, we have to pass `-short`:

```
% go test -short -v .
=== RUN   TestLongRunning
    foo_test.go:9: skipping long-running test
--- SKIP: TestLongRunning (0.00s)
PASS
ok      foo  0.174s
```

`TestLongRunning` is explicitly skipped when the tests are executed. Note that unlike build tags, this option works per test, not per file.

In summary, categorizing tests is a best practice for a successful testing strategy. In this section, we’ve seen three ways to categorize tests:

* Using build tags at the test file level
* Using environment variables to mark a specific test
* Based on the test pace using short mode

We can also combine approaches: for example, using build tags or environment variables to classify a test (for example, as a unit or integration test) and short mode if our project contains long-running unit tests.

In the next section, we discuss why enabling the `-race` flag matters.

## 11.2 #83: Not enabling the -race flag

In mistake #58, “Not understanding race problems,” we defined a data race as occurring when two goroutines simultaneously access the same variable, with at least one writing to the variable. We should also know that Go has a standard race-detector tool to help detect data races. One common mistake is forgetting how important this tool is and not enabling it. This section looks at what the race detector catches, how to use it, and its limitations.

In Go, the race detector isn’t a static analysis tool used during compilation; instead, it’s a tool to find data races that occur at runtime. To enable it, we have to enable the `-race` flag while compiling or running a test. For example:

```
$ go test -race ./...
```

Once the race detector is enabled, the compiler instruments the code to detect data races. *Instrumentation* refers to a compiler adding extra instructions: here, tracking all memory accesses and recording when and how they occur. At runtime, the race detector watches for data races. However, we should keep in mind the runtime overhead of enabling the race detector:

* Memory usage may increase by 5 to 10×.
* Execution time may increase by 2 to 20×.

Because of this overhead, it’s generally recommended to enable the race detector only during local testing or continuous integration (CI). In production, we should avoid it (or only use it in the case of canary releases, for example).

If a race is detected, Go raises a warning. For instance, this example contains a data race because `i` can be accessed at the same time for both a read and a write:

```go
package main

import (
    "fmt"
)

func main() {
    i := 0
    go func() { i++ }()
    fmt.Println(i)
}
```

Running this application with the `-race` flag logs the following data race warning:

```
==================
WARNING: DATA RACE
Write at 0x00c000026078 by goroutine 7:                #1
  main.main.func1()
      /tmp/app/main.go:9 +0x4e

Previous read at 0x00c000026078 by main goroutine:     #2
  main.main()
      /tmp/app/main.go:10 +0x88

Goroutine 7 (running) created at:                      #3
  main.main()
      /tmp/app/main.go:9 +0x7a
==================
```
> #1 Indicates that goroutine 7 was writing
> #2 Indicates that the main goroutine was reading
> #3 Indicates when goroutine 7 was created

Let’s make sure we are comfortable reading these messages. Go always logs the following:

* The concurrent goroutines that are incriminated: here, the main goroutine and goroutine 7.
* Where accesses occur in the code: in this case, lines 9 and 10.
* When these goroutines were created: goroutine 7 was created in `main()`.

> **NOTE**
> Internally, the race detector uses vector clocks, a data structure used to determine a partial ordering of events (and also used in distributed systems such as databases). Each goroutine creation leads to the creation of a vector clock. The instrumentation updates the vector clock at each memory access and synchronization event. Then, it compares the vector clocks to detect potential data races.

The race detector cannot catch a false positive (an apparent data race that isn’t a real one). Therefore, we know our code contains a data race if we get a warning. Conversely, it can sometimes lead to false negatives (missing actual data races).

We need to note two things regarding testing. First, the race detector can only be as good as our tests. Thus, we should ensure that concurrent code is tested thoroughly against data races. Second, given the possible false negatives, if we have a test to check data races, we can put this logic inside a loop. Doing so increases the chances of catching possible data races:

```go
func TestDataRace(t *testing.T) {
    for i := 0; i < 100; i++ {
        // Actual logic
    }
}
```

In addition, if a specific file contains tests that lead to data races, we can exclude it from race detection using the `!race` build tag:

```go
//go:build !race

package main

import (
    "testing"
)

func TestFoo(t *testing.T) {
    // ...
}

func TestBar(t *testing.T) {
    // ...
}
```

This file will be built only if the race detector is disabled. Otherwise, the entire file won’t be built, so the tests won’t be executed.

In summary, we should bear in mind that running tests with the `-race` flag for applications using concurrency is highly recommended, if not mandatory. This approach allows us to enable the race detector, which instruments our code to catch potential data races. While enabled, it has a significant impact on memory and performance, so it must be used in specific conditions such as local tests or CI.

The following section discusses two flags related to execution mode: `parallel` and `shuffle`.

## 11.3 #84: Not using test execution modes

While running tests, the `go` command can accept a set of flags to impact how tests are executed. A common mistake is not being aware of these flags and missing opportunities that could lead to faster execution or a better way to spot possible bugs. Let’s look at two of these flags: `parallel` and `shuffle`.

### 11.3.1 The parallel flag

Parallel execution mode allows us to run specific tests in parallel, which can be very useful: for example, to speed up long-running tests. We can mark that a test has to be run in parallel by calling `t.Parallel`:

```go
func TestFoo(t *testing.T) {
    t.Parallel()
    // ...
}
```

When we mark a test using `t.Parallel`, it is executed in parallel alongside all the other parallel tests. In terms of execution, though, Go first runs all the sequential tests one by one. Once the sequential tests are completed, it executes the parallel tests.

For example, the following code contains three tests, but only two of them are marked to be run in parallel:

```go
func TestA(t *testing.T) {
    t.Parallel()
    // ...
}

func TestB(t *testing.T) {
    t.Parallel()
    // ...
}

func TestC(t *testing.T) {
    // ...
}
```

Running the tests for this file gives the following logs:

```
=== RUN   TestA
=== PAUSE TestA           #1
=== RUN   TestB
=== PAUSE TestB           #2
=== RUN   TestC           #3
--- PASS: TestC (0.00s)
=== CONT  TestA           #4
--- PASS: TestA (0.00s)
=== CONT  TestB
--- PASS: TestB (0.00s)
PASS
```
> #1 Pauses TestA
> #2 Pauses TestB
> #3 Runs TestC
> #4 Resumes TestA and TestB

`TestC` is the first to be executed. `TestA` and `TestB` are logged first, but they are paused, waiting for `TestC` to complete. Then both are resumed and executed in parallel.

By default, the maximum number of tests that can run simultaneously equals the `GOMAXPROCS` value. To serialize tests or, for example, increase this number in the context of long-running tests doing a lot of I/O, we can change this value using the `-parallel` flag:

```
$ go test -parallel 16 .
```

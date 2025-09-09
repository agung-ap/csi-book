# 2 Code and project organization

### This chapter covers
- Organizing our code idiomatically
- Dealing efficiently with abstractions: interfaces and generics
- Best practices regarding how to structure a project

Organizing a Go codebase in a clean, idiomatic, and maintainable manner isn’t an easy task. It requires experience and even mistakes to understand all the best practices related to code and project organization. What are the traps to avoid (for example, variable shadowing and nested code abuse)? How do we structure packages? When and where do we use interfaces or generics, init functions, and utility packages? In this chapter, we examine common organizational mistakes.

## 2.1 #1: Unintended variable shadowing

The scope of a variable refers to the places a variable can be referenced: in other words, the part of an application where a name binding is valid. In Go, a variable name declared in a block can be redeclared in an inner block. This principle, called *variable shadowing*, is prone to common mistakes.

The following example shows an unintended side effect because of a shadowed variable. It creates an HTTP client in two different ways, depending on the value of a `tracing` Boolean:

```go
var client *http.Client
if tracing {
    client, err := createClientWithTracing()
    if err != nil {
        return err
    }
    log.Println(client)
} else {
    client, err := createDefaultClient()
    if err != nil {
        return err
    }
    log.Println(client)
}
// Use client
```

In this example, we first declare a `client` variable. Then, we use the short variable declaration operator (`:=`) in both inner blocks to assign the result of the function call to the inner `client` variables—not the outer one. As a result, the outer variable is always `nil`.

> **NOTE**
> This code compiles because the inner `client` variables are used in the logging calls. If not, we would have compilation errors such as `client declared and not used`.

How can we ensure that a value is assigned to the original `client` variable? There are two different options.

The first option uses temporary variables in the inner blocks this way:

```go
var client *http.Client
if tracing {
    c, err := createClientWithTracing()    #1
    if err != nil {
        return err
    }
    client = c                             #2
} else {
    // Same logic
}
```

Here, we assign the result to a temporary variable, `c`, whose scope is only within the `if` block. Then, we assign it back to the `client` variable. Meanwhile, we do the same for the `else` part.

The second option uses the assignment operator (`=`) in the inner blocks to directly assign the function results to the `client` variable. However, this requires creating an `error` variable because the assignment operator works only if a variable name has already been declared. For example:

```go
var client *http.Client
var err error                                  #1
if tracing {
    client, err = createClientWithTracing()    #2
    if err != nil {
        return err
    }
} else {
    // Same logic
}
```

Instead of assigning to a temporary variable first, we can directly assign the result to `client`.

Both options are perfectly valid. The main difference between the two alternatives is that we perform only one assignment in the second option, which may be considered easier to read. Also, with the second option, we can mutualize and implement error handling outside the `if`/`else` statements, as this example shows:

```go
if tracing {
    client, err = createClientWithTracing()
} else {
    client, err = createDefaultClient()
}
if err != nil {
    // Common error handling
}
```

Variable shadowing occurs when a variable name is redeclared in an inner block, but we saw that this practice is prone to mistakes. Imposing a rule to forbid shadowed variables depends on personal taste. For example, sometimes it can be convenient to reuse an existing variable name like `err` for errors. Yet, in general, we should remain cautious because we now know that we can face a scenario where the code compiles, but the variable that receives the value is not the one expected. Later in this chapter, we will also see how to detect shadowed variables, which may help us spot possible bugs.

The following section shows why it is important to avoid abusing nested code. 

## 2.2 #2: Unnecessary nested code

A mental model applied to software is an internal representation of a system’s behavior. While programming, we need to maintain mental models (about overall code interactions and function implementations, for example). Code is qualified as readable based on multiple criteria such as naming, consistency, formatting, and so forth. Readable code requires less cognitive effort to maintain a mental model; hence, it is easier to read and maintain.

A critical aspect of readability is the number of nested levels. Let’s do an exercise. Suppose that we are working on a new project and need to understand what the following `join` function does:

```go
func join(s1, s2 string, max int) (string, error) {
    if s1 == "" {
        return "", errors.New("s1 is empty")
    } else {
        if s2 == "" {
            return "", errors.New("s2 is empty")
        } else {
            concat, err := concatenate(s1, s2)     #1
            if err != nil {
                return "", err
            } else {
                if len(concat) > max {
                    return concat[:max], nil
                } else {
                    return concat, nil
                }
            }
        }
    }
}
 
func concatenate(s1 string, s2 string) (string, error) {
    // ...
}
```

This `join` function concatenates two strings and returns a substring if the length is greater than `max`. Meanwhile, it handles checks on `s1` and `s2` and whether the call to `concatenate` returns an error.

From an implementation perspective, this function is correct. However, building a mental model encompassing all the different cases is probably not a straightforward task. Why? Because of the number of nested levels.

Now, let’s try this exercise again with the same function but implemented differently:

```go
func join(s1, s2 string, max int) (string, error) {
    if s1 == "" {
        return "", errors.New("s1 is empty")
    }
    if s2 == "" {
        return "", errors.New("s2 is empty")
    }
    concat, err := concatenate(s1, s2)
    if err != nil {
        return "", err
    }
    if len(concat) > max {
        return concat[:max], nil
    }
    return concat, nil
}
 
func concatenate(s1 string, s2 string) (string, error) {
    // ...
}
```

You probably noticed that building a mental model of this new version requires less cognitive load despite doing the same job as before. Here we maintain only two nested levels. As mentioned by Mat Ryer, a panelist on the *Go Time* podcast (https://medium.com/@matryer/line-of-sight-in-code-186dd7cdea88):

Align the happy path to the left; you should quickly be able to scan down one column to see the expected execution flow.

It was difficult to distinguish the expected execution flow in the first version because of the nested `if`/`else` statements. Conversely, the second version requires scanning down one column to see the expected execution flow and down the second column to see how the edge cases are handled, as figure 2.1 shows.

![Figure 2.1 To understand the expected execution flow, we just have to scan the happy path column.](https://drek4537l1klr.cloudfront.net/harsanyi/HighResolutionFigures/figure_2-1.png)

In general, the more nested levels a function requires, the more complex it is to read and understand. Let’s see some different applications of this rule to optimize our code for readability:

- When an `if` block returns, we should omit the `else` block in all cases. For example, we shouldn’t write

```go
if foo() {
    // ...
    return true
} else {
    // ...
}
```

Instead, we omit the `else` block like this:

```go
if foo() {
    // ...
    return true
}
// ...
```

With this new version, the code living previously in the `else` block is moved to the top level, making it easier to read.
- We can also follow this logic with a non-happy path:

```go
if s != "" {
    // ...
} else {
    return errors.New("empty string")
}
```

Here, an empty `s` represents the non-happy path. Hence, we should flip the condition like so:

```go
if s == "" {                           #1
    return errors.New("empty string")
}
// ...
```

This new version is easier to read because it keeps the happy path on the left edge and reduces the number of blocks.

Writing readable code is an important challenge for every developer. Striving to reduce the number of nested blocks, aligning the happy path on the left, and returning as early as possible are concrete means to improve our code’s readability.

In the next section, we discuss a common misuse in Go projects: init functions. 

## 2.3 #3: Misusing init functions

Sometimes we misuse init functions in Go applications. The potential consequences are poor error management or a code flow that is harder to understand. Let’s refresh our minds about what an init function is. Then, we will see when its usage is or isn’t recommended.

### 2.3.1 Concepts

An init function is a function used to initialize the state of an application. It takes no arguments and returns no result (a `func()` function). When a package is initialized, all the constant and variable declarations in the package are evaluated. Then, the init functions are executed. Here is an example of initializing a `main` package:

```go
package main
 
import "fmt"
 
var a = func() int {
    fmt.Println("var")        #1
    return 0
}()
 
func init() {
    fmt.Println("init")       #2
}
 
func main() {
    fmt.Println("main")       #3
}
```

Running this example prints the following output:

```
var
init
main
```

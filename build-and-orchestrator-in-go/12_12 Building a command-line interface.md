# [](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)12 Building a command-line interface

### This chapter covers

- Core components of command-line interfaces
- Introducing the Cobra framework
- Creating command skeletons
- Producing a CLI that replaces the combined use of the `main.go` and `curl` programs

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)Throughout the book, we have been using a crude main program to operate our orchestration system (figure 12.1). This program is a single monolith that does it all: starts the workers, starts the workers’ API servers, starts the manager, and starts the manager’s API server. If we want to stop the manager for any reason, we also stop the workers, and vice versa. When we want to interact with the orchestrator, however, we do this separately via the `curl` command.

![Figure 12.1 The old way of operating and interacting with our orchestrator](https://drek4537l1klr.cloudfront.net/boring/Figures/12-01.png)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)Now that we have our orchestration system implemented, let’s turn our attention to how we operate it. Popular orchestration systems like Kubernetes and Nomad are operated by command-line interfaces (CLIs). Kubernetes uses multiple binaries to implement its CLI:[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)

-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)`kubeadm` bootstraps a Kubernetes cluster.
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)`kubelet` performs the same function as our worker (i.e., it runs tasks).
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)`kubectl` provides an interface to interact with the cluster.

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)Nomad, on the other hand, implements its CLI with a single binary called `nomad` but otherwise provides a similar interface. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)Our task in this chapter will be to implement a CLI for the Cube orchestrator. This CLI will support the following operations:

-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)Starting the worker
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)Starting the manager
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)Starting and stopping tasks
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)Getting the status of tasks [](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)

## [](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)12.1 The core components of CLIs

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)Many of the best CLIs are made up of common elements. They use a consistent pattern for each command and provide built-in help messages. The pattern we’ll use for our CLI takes the form of `APPNAME` `COMMAND` `ARG` `--FLAG`. For example, the worker command implemented later in this chapter will look like this:

```bash
$ cube worker --name worker-1 --dbtype memory
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)Built-in help messages make it easy for a user to get contextual help by passing a `--help` or `-h` flag along with the command. The output from passing `--help` typically consists of a short summary of the command, a more detailed description that provides deeper explanations and possible examples, and a list of the flags the command accepts. In the case of our worker, passing the `--help` flag will result in this message:[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)

```bash
$ cube worker --help
cube worker command.
 
The worker runs tasks and responds to the manager's requests about task
 state.
 
Usage:
  cube worker [flags]
 
Flags:
  -d, --dbtype string   Type of datastore to use for tasks ("memory" or
   "persistent") (default "memory")
  -h, --help            help for worker
  -H, --host string     Hostname or IP address (default "0.0.0.0")
  -n, --name string     Name of the worker (default
   "worker-9a385171-f980-47c4-a250-75736d3eb6f0")
  -p, --port int        Port on which to listen (default 5556)
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)Each command we’ll implement in this chapter will follow this pattern and provide a similarly useful help message (figure 12.2).

![Figure 12.2 The new way of operating and interacting with our orchestrator](https://drek4537l1klr.cloudfront.net/boring/Figures/12-02.png)

## [](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)12.2 Introducing the Cobra framework

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)We are going to use a framework to implement our CLI. Specifically, we will use the Cobra framework ([https://github.com/spf13/cobra](https://github.com/spf13/cobra)). Cobra powers popular projects like Kubernetes, Helm, Hugo, Moby (Docker), and the GitHub CLI. (For a fuller list of projects using Cobra, see [http://mng.bz/XqBE](http://mng.bz/XqBE).) [](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)Why use a framework? Technically, we don’t need a framework. We could build our CLI from the ground up using just the Go standard library.

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)In its most basic form, a CLI performs these functions:

-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)Parses arguments and flags passed on the command line
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)Calls a handler that matches the command, passing the arguments and flags as parameters
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)Presents any output from the handler to the user

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)While this list is short and appears simple, there is quite a bit of work involved. Just handling flags, for example, can turn into thousands of lines of code (see `flag.go` in the `flag`[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/) package in Go’s standard library or `flag.go` in the pflag library[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)). A CLI framework provides standard building blocks, similar to web frameworks.

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)Let’s get started by installing Cobra:

```
go get -u github.com/spf13/cobra@latest
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)We also want to install the `cobra-cli`:[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)

```
go install github.com/spf13/cobra-cli@latest
```

## [](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)12.3 Setting up our Cobra application

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)We have[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/) now installed the Cobra library, which provides the framework we will use in our CLI, and the `cobra-cli` tool, which gives us some handy shortcuts for initializing our CLI application and adding commands as we move forward. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)Before we get started, make a backup copy of the `main.go` program from past chapters. We will be overwriting it with the output from the `cobra-cli` tool. Then, from the root of your project directory, let’s initialize our Cobra CLI:

```bash
$ cobra-cli init
Your Cobra application is ready at
/home/t/workspace/personal/manning/code/ch12
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)The `init` command performs several tasks for us:[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)

-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)Generates a new `main.go`
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)Creates a `cmd` directory in our project
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)Create a `root.go` file inside the new `cmd` directory

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)The new `cmd` directory should look like this:

```bash
$ tree cmd
cmd
└── root.go
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)At this point, we have bootstrapped everything we need to build our CLI. We can run the main program to see what we have to start with:[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)

```bash
$ go run main.go
A longer description that spans multiple lines and likely contains
examples and usage of using your application. For example:

Cobra is a CLI library for Go that empowers applications.
This application is a tool to generate the needed files
to quickly create a Cobra application.
```

## [](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)12.4 Understanding the new main.go

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)After running `cobra-cli` `init`, we should have a new `main.go` file in the root of our project. As we can see in listing 12.1, this new version of our main program is much smaller, and it performs the following functions:[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)

-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)Declares the `main` package
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)Imports the `cube/cmd` package
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)Defines the `main` function, which runs the `Execute` function from the `cmd` package [](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)

##### Listing 12.1 The new `main.go` generated by `cobra-cli`

```
/*
Copyright © 2023 NAME HERE <EMAIL ADDRESS>

*/
package main

import "cube/cmd"

func main() {
   cmd.Execute()
}
```

## [](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)12.5 Understanding root.go

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)Let’s explore the `cmd/root.go` file before delving into our own commands. At the top of the file, the `cobra-cli` `init` command has added a copyright notice. This is convenient if you’re planning to publish your CLI as open source software, but it’s not necessary for our purposes. Feel free to remove it. Next, there is the package declaration, which gives the package the name `cmd`. Then there are a couple of imports, notably the importing of the Cobra library, `github.com/spf13/cobra`:[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)

```
/*
Copyright © 2023 NAME HERE <EMAIL ADDRESS>

*/
package cmd

import (
   "os"

   "github.com/spf13/cobra"
)
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)The meat of the file comes next, and it contains the `rootCmd`. As its name suggests, this is the *root* of our CLI. The important thing to note is how commands are built with Cobra. Each command is a pointer to the `cobra.Command` type, and we’re creating an instance of it and assigning it to a variable. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)In creating this instance of `cobra.Command` to assign to the `rootCmd` variable, several fields are defined. The `Use` field provides a one-line usage message. The `Short` field defines a brief description of the CLI. Finally, the `Long` field provides a more detailed description of the CLI. All three of these fields are used in the CLIs help system (i.e., when running `go` `run` `main.go` `--help`). The most important field, commented out in the generated `root.go`, is the `Run` field. It is defined as a function type that takes two arguments: a pointer to a `Command` type and a slice of strings. This function performs the work when a user invokes the command. We will see this function in action shortly:[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)

```
// rootCmd represents the base command when called without any subcommands
var rootCmd = &cobra.Command{
    Use:   "cube",
    Short: "A brief description of your application",
    Long: `A longer description that spans multiple lines and likely
     contains
examples and usage of using your application. For example:
 
Cobra is a CLI library for Go that empowers applications.
This application is a tool to generate the needed files
to quickly create a Cobra application.`,
    // Uncomment the following line if your bare application
    // has an action associated with it:
    // Run: func(cmd *cobra.Command, args []string) { },
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)The next piece of the generated `root.go` file is the `Execute` command. As the comment above the function says, this function is called by `main.main()` and occurs only once:[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)

```
// Execute adds all child commands to the root command and sets flags
 appropriately.
// This is called by main.main(). It only needs to happen once to the
 rootCmd.
func Execute() {
    err := rootCmd.Execute()
    if err != nil {
        os.Exit(1)
    }
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)The final piece of `root.go` is the definition of the `init` function. The `init` function is special in Go. It is predefined by the Go language and is used to perform configuration. In Cobra applications, the definition of flags and other configuration settings are done in an `init` function. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)In the Cobra framework, there are two types of flags: *persistent* and *local*. Persistent flags persist from the parent command where they are defined through to any children. Local flags exist only for the command where they are defined. The `init` function in the generated `root.go` file includes one of each type of flag:[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)

```
func init() {
    // Here you will define your flags and configuration settings.
    // Cobra supports persistent flags, which, if defined here,
    // will be global for your application.
 
    // rootCmd.PersistentFlags().StringVar(&cfgFile, "config", "",
     "config file (default is $HOME/.cube.yaml)")
    // Cobra also supports local flags, which will only run
    // when this action is called directly.
    rootCmd.Flags().BoolP("toggle", "t", false, "Help message for toggle")
}
```

## [](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)12.6 Implementing the worker command

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)Now that we have a basic understanding of the Cobra framework, let’s start implementing our commands. The first command we’ll build is the `worker` command. To get started, we can use the `cobra-cli` command to create a skeleton for us:[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)

```bash
$ cobra-cli add worker
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)This command creates the `worker.go` file in the `cmd` directory:

```bash
$ tree cmd
cmd
├── root.go
└── worker.go
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)The skeleton created by the `cobra-cli` `add` command should look like that shown in listing 12.2. One thing to note in this skeleton is that the `add` command included a functional `Run` field. The field value is a function that simply prints out `worker` `called`. And as we saw with the root command, the skeleton includes an `init` function where we can define flags. Also, note that the init function calls the `rootCmd.AddCommand` method, passing it the `workerCmd`. This call, as its name suggests, adds our worker command to the root, thus making it available to the CLI application. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)

##### Listing 12.2 The skeleton worker command created by the `cobra-cli add` command

```
/*
Copyright © 2023 NAME HERE <EMAIL ADDRESS>
 
*/
package cmd
 
import (
    "fmt"
 
    "github.com/spf13/cobra"
)
 
// workerCmd represents the worker command
var workerCmd = &cobra.Command{
    Use:   "worker",
    Short: "A brief description of your command",
    Long: `A longer description that spans multiple lines and likely
     contains examples
and usage of using your command. For example:
 
Cobra is a CLI library for Go that empowers applications.
This application is a tool to generate the needed files
to quickly create a Cobra application.`,
    Run: func(cmd *cobra.Command, args []string) {
        fmt.Println("worker called")
    },
}
 
func init() {
    rootCmd.AddCommand(workerCmd)
 
    // Here you will define your flags and configuration settings.
 
    // Cobra supports Persistent Flags which will work for this command
    // and all subcommands, e.g.:
    // workerCmd.PersistentFlags().String("foo", "", "A help for foo")
 
    // Cobra supports local flags which will only run when this command
    // is called directly, e.g.:
    // workerCmd.Flags().BoolP("toggle", "t", false, "Help message for
     toggle")
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)Once we have this skeleton in place, we can run it and see that it works. If we run it with the `--help` flag, we see the usage message:[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)

```bash
$ go run main.go worker --help
A longer description that spans multiple lines and likely contains examples
and usage of using your command. For example:

Cobra is a CLI library for Go that empowers applications.
This application is a tool to generate the needed files
to quickly create a Cobra application.

Usage:
 cube worker [flags]

Flags:
 -h, --help   help for worker
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)And if we run the command, we see the output `worker` `called`:

```bash
$ go run main.go worker
worker called
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)Let’s start modifying this skeleton by defining the necessary flags for the worker command. If we recall our old `main.go` program, we were reading environment variables to get the hostname and the port on which the worker would listen.

##### Listing 12.3 Getting the worker's `host` and `port` from environment variables

```
whost := os.Getenv("CUBE_WORKER_HOST")
wport, _ := strconv.Atoi(os.Getenv("CUBE_WORKER_PORT"))
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)Instead of reading environment variables, let’s use flags. In listing 12.4, we add the `host` and `port` flags. We create the `host` flag using the `StringP` method, and we create the `port` flag using the `IntP` method. Both methods take the following arguments (all as strings):[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)

-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)The name of the flag
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)A shorthand letter that can be used after a single dash
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)A default value
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)A description of the flag’s usage

##### Listing 12.4 Defining the `host` and `port` flags in the generated `init` method

```
package cmd
 
import (
    "cube/worker"
    "fmt"
    "log"
 
    "github.com/google/uuid"
    "github.com/spf13/cobra"
)
 
func init() {
    rootCmd.AddCommand(workerCmd)
    workerCmd.Flags().StringP("host", "H", "0.0.0.0",
     "Hostname or IP address")                          #1
    workerCmd.Flags().IntP("port", "p", 5556, "Port on
     which to listen")                                  #2
}
#1 The host flag can be used as either --host or -H.
#2 The port flag can be used as either --port or -p.
```

##### Note

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/) Under the hood, Cobra uses the `pFlag` ([https://github.com/spf13/pflag](https://github.com/spf13/pflag)) library. It is written by the same author as Cobra and is advertised as a “drop-in replacement for Go’s flag package.”[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)Next, let’s add two more flags. The `name` flag will be used as the name of the worker. Once again, we are creating it using the `StringP` method, and we’re using the `Sprintf` function from the `fmt` package to build a string that creates a unique name as a default. The `dbytpe` flag will be used to create the worker with the specified type of task storage, either `memory` or `persistent`, with `memory` being the default. The `name` flag can be used as either `--name` or `-n`, and the `dbtype` flag can be used as either `--dbtype` or `-d`. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)

##### Listing 12.5 The `name` flag

```
workerCmd.Flags().StringP("name", "n", fmt.Sprintf("worker-%s",
     uuid.New().String()), "Name of the worker")
    workerCmd.Flags().StringP("dbtype", "d", "memory", "Type of datastore
     to use for tasks (\"memory\" or \"persistent\")")
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)At this point, we have a functional `worker` command[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/). Let’s check the help message:[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)

```bash
$ go run main.go worker --help
A longer description that spans multiple lines and likely contains examples
and usage of using your command. For example:
 
Cobra is a CLI library for Go that empowers applications.
This application is a tool to generate the needed files
to quickly create a Cobra application.
 
Usage:
  cube worker [flags]
 
Flags:
  -d, --dbtype string   Type of datastore to use for tasks ("memory" or
   "persistent") (default "memory")
  -h, --help            help for worker
  -H, --host string     Hostname or IP address (default "0.0.0.0")
  -n, --name string     Name of the worker
   (default "worker-ed9b23bf-3070-4da6-a163-ef16bdae8c22")
  -p, --port int        Port on which to listen (default 5556)
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)As we can see, running `worker` `--help` prints out a message about the command, and it lists the flags we defined with their individual usage messages.

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)We can also call the command:

```bash
$ go run main.go worker
worker called
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)Calling the `worker` command doesn’t do anything useful. It does, however, demonstrate a working command printing out `worker` `called`.

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)With our flags defined, we can move on to the `workerCmd`. As we saw when we ran the command with the `--help` flag, the usage message was about Cobra itself. Let’s customize the help message to be more relevant. To do this, we modify the `Use`, `Short`, and `Long` fields on the `workerCmd`, as seen in the following listing. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)

##### Listing 12.6 Modifying the `workerCmd` for a more useful help message

```
var workerCmd = &cobra.Command{
    Use:   "worker",
    Short: "Worker command to operate a Cube worker node.",
    Long: `cube worker command.
 
The worker runs tasks and responds to the manager's requests about task
 state.`,
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)Now, if we run the command with the `--help` flag, we should see a more useful help message:[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)

```bash
$ go run main.go worker --help
cube worker command.
 
The worker runs tasks and responds to the manager's requests about task
 state.
 
Usage:
  cube worker [flags]
 
Flags:
  -d, --dbtype string   Type of datastore to use for tasks ("memory" or
   "persistent") (default "memory")
  -h, --help            help for worker
  -H, --host string     Hostname or IP address (default "0.0.0.0")
  -n, --name string     Name of the worker
   (default "worker-bd7dc7dc-abf7-4cea-943b-11f13f128208")
  -p, --port int        Port on which to listen (default 5556)
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)That looks much better!

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)Finally, let’s modify the `Run` field of our `workerCmd`. The first thing we need to do is get the values of the command’s flags. We do this by calling the appropriate method on the `cmd` passed into the function. In our case, we call `GetString` to get the `host`, `name`, and `dbtype` flags, and we call `GetInt` to get the `port` flag[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/). Notice that we are using the blank identifier in each of these calls. Each call returns two values: the value of the flag and an error. In our case, we are not storing the error because we have set default values for each of the flags. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)

##### Listing 12.7 The `Run` field, the core of a Cobra command

```
Run: func(cmd *cobra.Command, args []string) {
   host, _ := cmd.Flags().GetString("host")
   port, _ := cmd.Flags().GetInt("port")
   name, _ := cmd.Flags().GetString("name")
   dbType, _ := cmd.Flags().GetString("dbtype")
},
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)Next, we need to create the worker and its API and then start everything up. When we performed these tasks in our old `main.go` program, we were doing it for three workers. If you recall, it looked like this:

```
w1 := worker.New("worker-1", "persistent")
wapi1 := worker.Api{Address: whost, Port: wport, Worker: w1}

w2 := worker.New("worker-2", "persistent")
wapi2 := worker.Api{Address: whost, Port: wport + 1, Worker: w2}

w3 := worker.New("worker-3", "persistent")
wapi3 := worker.Api{Address: whost, Port: wport + 2, Worker: w3}

go w1.RunTasks()
go w1.UpdateTasks()
go wapi1.Start()
go w2.RunTasks()
go w2.UpdateTasks()
go wapi2.Start()

go w3.RunTasks()
go w3.UpdateTasks()
go wapi3.Start()
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)Because we’re creating a command that can be run multiple times, we only need to perform these tasks once. The `workerCmd` starts a worker using a simplified version of the code in our old `main.go` program.

##### Listing 12.8 The `workerCmd` starting a worker

```
Run: func(cmd *cobra.Command, args []string) {
   // previous code omitted

   log.Println("Starting worker.")
   w := worker.New(name, dbType)
   api := worker.Api{Address: host, Port: port, Worker: w}
   go w.RunTasks()
   go w.CollectStats()
   go w.UpdateTasks()
   log.Printf("Starting worker API on http://%s:%d", host, port)
   api.Start()
},
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)Now, if we run our command, we should end up with a running, fully functioning worker:

```bash
$ go run main.go worker
2023/04/29 14:36:34 Starting worker.
2023/04/29 14:36:34 Starting worker API on http://0.0.0.0:5556
2023/04/29 14:36:34 No tasks to process currently.
2023/04/29 14:36:34 Sleeping for 10 seconds.
2023/04/29 14:36:34 Checking status of tasks
2023/04/29 14:36:34 Task updates completed
2023/04/29 14:36:34 Sleeping for 15 seconds
2023/04/29 14:36:34 Collecting stats
2023/04/29 14:36:44 No tasks to process currently.
2023/04/29 14:36:44 Sleeping for 10 seconds.
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)Before moving on, try to start two more workers in separate terminals. You will need to specify a different port for each one using the `--port` flag, but otherwise the defaults should work.

## [](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)12.7 Implementing the manager command

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)With the worker command complete, let’s move on and implement the manager command. We’ll follow a similar process used for the worker command. We’ll start by creating our skeleton using the `cobra-cli` `add` command:[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)

```bash
$ cobra-cli add manager
manager created at /home/t/workspace/personal/manning/code/ch12
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)Again, the `add` command will create a skeleton for us in the `cmd` directory:[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)

```bash
$ tree cmd
cmd
├── manager.go
├── root.go
└── worker.go
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)Let’s start modifying our `manager` skeleton by defining the flags we’ll need in the `init` function. As with the `worker` command, we need to define the `host` and `port` flags to tell the manager where it should listen for traffic. Next, we define the `workers` flag, which is a list of workers identified by strings in the form of `host:port`. We did something similar in our old `main.go` program, but we built up the list of workers manually. Here, we can use the `StringSliceP` method that will allow a user to specify the workers on the command line as a string. With the `workers` flag defined, we move on and define the `scheduler` flag. Finally, we define the `dbType` flag, which will identify the type of datastore the manager will use for its tasks and events. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)

##### Listing 12.9 Customizing the `init` method of the `managerCmd` to define flags

```
package cmd
 
import (
    "cube/manager"
    "log"
 
    "github.com/spf13/cobra"
)
 
func init() {
    rootCmd.AddCommand(managerCmd)
    managerCmd.Flags().StringP("host", "H", "0.0.0.0",
     "Hostname or IP address")
    managerCmd.Flags().IntP("port", "p", 5555, "Port on which to listen")
    managerCmd.Flags().StringSliceP("workers", "w",
     []string{"localhost:5556"}, "List of workers on which the manager
     will schedule tasks.")
    managerCmd.Flags().StringP("scheduler", "s", "epvm", "Name
     of scheduler to use.")
    managerCmd.Flags().StringP("dbType", "d", "memory", "Type of datastore
     to use for events and tasks (\"memory\" or \"persistent\")")
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)The next step to modifying the `manager` skeleton is to customize the usage message that gets displayed when running the command with the `--help` flag:[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)

```
var managerCmd = &cobra.Command{
    Use:   "manager",                                      #1
    Short: "Manager command to operate a Cube manager
     node.",                                             #2
    Long: `cube manager command.                           #3
 
The manager controls the orchestration system and is responsible for:
- Accepting tasks from users
- Scheduling tasks onto worker nodes
- Rescheduling tasks in the event of a node failure
- Periodically polling workers to get task updates`,
#1 Changes the Use field to &quot;manager&quot;
#2 Changes the Short field to a more informative short version of the help message
#3 Changes the Long field to a more descriptive help message
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)At this point, we have a functioning `manager` command. If we run the `manager` command now with the `--help` flag, we see the following output:[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)

```bash
$ go run main.go manager --help
cube manager command.
 
The manager controls the orchestration system and is responsible for:
- Accepting tasks from users
- Scheduling tasks onto worker nodes
- Rescheduling tasks in the event of a node failure
- Periodically polling workers to get task updates
 
Usage:
  cube manager [flags]
 
Flags:
  -d, --dbType string      Type of datastore to use for events and tasks
   ("memory" or "persistent") (default "memory")
  -h, --help               help for manager
  -H, --host string        Hostname or IP address (default "0.0.0.0")
  -p, --port int           Port on which to listen (default 5555)
  -s, --scheduler string   Name of scheduler to use. (default "epvm")
  -w, --workers strings    List of workers on which the manager will schedule
 tasks. (default [localhost:5556])
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)As with the `worker` command, the only thing left to implement now is the `Run` field of our `managerCmd`. Again, we start by getting the values of the flags passed on the command line. And once again, we don’t check for errors because we have set default values for all our flags. Notice that the functions we use to retrieve the flag values are a combination of the word `Get` and the type, so a flag defined as a `StringP` type is retrieved via the `GetString()` function, a flag defined as a `StringSliceP` is retrieved by the `GetStringSlice()` function, and an `IntP` type is retrieved using the `GetInt()` function. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)

##### Listing 12.10 Implementing the `Run` field of our `managerCmd`

```
Run: func(cmd *cobra.Command, args []string) {
       host, _ := cmd.Flags().GetString("host")
       port, _ := cmd.Flags().GetInt("port")
       workers, _ := cmd.Flags().GetStringSlice("workers")
       scheduler, _ := cmd.Flags().GetString("scheduler")
       dbType, _ := cmd.Flags().GetString("dbType")
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)Finally, we create the manager and its API and then start it up. This should look familiar, as we’re simply performing the same calls as we did in our old `main.go` program.

##### Listing 12.11 Starting up the manager with the same calls as the old `main.go` program

```
log.Println("Starting manager.")
       m := manager.New(workers, scheduler, dbType)
       api := manager.Api{Address: host, Port: port, Manager: m}
       go m.ProcessTasks()
       go m.UpdateTasks()
       go m.DoHealthChecks()
       go m.UpdateNodeStats()
       log.Printf("Starting manager API on http://%s:%d", host, port)
       api.Start()
   },
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)Now let’s start up the manager:

```bash
$ go run main.go manager -w 'localhost:5556,localhost:5557,localhost:5558'
2023/04/29 15:03:40 Starting manager.
2023/04/29 15:03:40 Starting manager API on http://0.0.0.0:5555
2023/04/29 15:03:40 Checking for task updates from workers
2023/04/29 15:03:40 Checking worker localhost:5556 for task updates
2023/04/29 15:03:40 Processing any tasks in the queue
2023/04/29 15:03:40 No work in the queue
2023/04/29 15:03:40 Sleeping for 10 seconds
2023/04/29 15:03:40 Collecting stats for node localhost:5556
2023/04/29 15:03:40 Performing task health check
2023/04/29 15:03:40 Task health checks completed
2023/04/29 15:03:40 Sleeping for 60 seconds
2023/04/29 15:03:40 Checking worker localhost:5557 for task updates
2023/04/29 15:03:40 Collecting stats for node localhost:5557
2023/04/29 15:03:40 Checking worker localhost:5558 for task updates
2023/04/29 15:03:40 Task updates completed
2023/04/29 15:03:40 Sleeping for 15 seconds
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)And voila! At this point, we have replaced our old `main.go` program from previous chapters with individual commands to start the worker and manager independently. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)

## [](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)12.8 Implementing the run command

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)We have replaced our `main.go` program with separate commands to start up our manager and worker components. But let’s not congratulate ourselves just yet. There is more we can do to make our orchestration system feel more real. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)If you recall, in past chapters, we have started and stopped tasks by manually calling the manager’s API using the `curl` command. In case you’ve forgotten, this is how we have been starting tasks:[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)

```bash
$ curl -X POST localhost:5555/tasks -d @task1.json
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)And here is how we have been stopping them:

```bash
$ curl -X DELETE localhost:5555/tasks/bb1d59ef-9fc1-4e4b-a44d-db571eeed203
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)There is nothing technically wrong with the way we have been starting and stopping tasks up to now. It has gotten the job done. If, however, we think about existing orchestration systems like Kubernetes or Nomad, we know we don’t start and stop tasks by calling their APIs using `curl`. Instead, we use a command-line tool like `kubectl` or `nomad`.

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)So let’s create a command that will allow us to start a task. For our purposes, we’ll call this command `run`. Create the skeleton for it by using the `cobra-cli` `add` command:[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)

```bash
$ cobra-cli add run
run created at /home/t/workspace/personal/manning/code/ch12-experimental
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)Afterward, you should see the new file in the `cmd` directory:[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)

```bash
$ tree cmd/
cmd/
├── manager.go
├── root.go
├── run.go
└── worker.go
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)Again, we have a skeleton to start from:

```
/*
Copyright © 2023 NAME HERE <EMAIL ADDRESS>
 
*/
package cmd
 
import (
    "fmt"
 
    "github.com/spf13/cobra"
)
 
// runCmd represents the run command
var runCmd = &cobra.Command{
    Use:   "run",
    Short: "A brief description of your command",
    Long: `A longer description that spans multiple lines and likely
     contains examples
and usage of using your command. For example:
 
Cobra is a CLI library for Go that empowers applications.
This application is a tool to generate the needed files
to quickly create a Cobra application.`,
    Run: func(cmd *cobra.Command, args []string) {
        fmt.Println("run called")
    },
}
 
func init() {
    rootCmd.AddCommand(runCmd)
 
    // Here you will define your flags and configuration settings.
 
    // Cobra supports Persistent Flags which will work for this command
    // and all subcommands, e.g.:
    // runCmd.PersistentFlags().String("foo", "", "A help for foo")
 
    // Cobra supports local flags which will only run when this command
    // is called directly, e.g.:
    // runCmd.Flags().BoolP("toggle", "t", false, "Help message for toggle")
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)By now, the skeleton and framework should be familiar to us, so we’re going to move a little faster.

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)To start, let’s define two flags in our `init` function. The first flag is named `manager`, and it will allow a user to specify the manager to talk to. We provide a default value of `localhost:5555` since that is what we have been using. The second flag is named `filename`, and this flag allows the user to specify the name of the file containing the task definition. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)

##### Listing 12.12 The `Run` command defines the `manager` and `filename` flags

```
package cmd
 
import (
    "bytes"
    "errors"
    "fmt"
    "io/fs"
    "log"
    "net/http"
    "os"
    "path/filepath"
 
    "github.com/spf13/cobra"
)
func init() {
    rootCmd.AddCommand(runCmd)
    runCmd.Flags().StringP("manager", "m", "localhost:5555", "Manager to
     talk to")
    runCmd.Flags().StringP("filename", "f", "task.json", "Task specification
     file")
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)So we allow a user to specify a filename holding their task definition. What happens, however, if that file doesn’t exist? Let’s create the `fileExists` function in listing 12.13 to check that a file actually exists before we attempt to read it. To do this, we call the `Stat` function in the `os` package, passing it the name of the file. We discard the value returned and only store any errors. Then we use the `errors.Is` function to check whether the `err` returned from the call to `Stat` is of type `fs.ErrNotExist`. We use the `!` (`not`) operator to return `true` when `errors.Is` returns false, and `false` when it returns `true`. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)

##### Listing 12.13 The `fileExists` function

```
func fileExists(filename string) bool {
   _, err := os.Stat(filename)

   return !errors.Is(err, fs.ErrNotExist)
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)Now on to the meat of our new command, `runCmd`. Replace the skeleton values for the `Use`, `Short`, and `Long` fields, as seen in the following listing. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)

##### Listing 12.14 Updating the text used in the command’s help message

```
var runCmd = &cobra.Command{
   Use:   "run",
   Short: "Run a new task.",
   Long: `cube run command.

The run command starts a new task.`,
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)If we run the command with the `--help` flag at this point, we will see the following:[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)

```bash
$ go run main.go run --help
cube run command.

The run command starts a new task.

Usage:
 cube run [flags]

Flags:
 -f, --filename string   Task specification file (default "task.json")
 -h, --help              help for run
 -m, --manager string    Manager to talk to (default "localhost:5555")
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)The last bit of the command to implement is the `Run` field. As with the `worker` and `manager` commands, we start by getting the values from the `manager` and `filename` flags passed on the command line and storing them in variables. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)

##### Listing 12.15 Retrieving the values of the `manager` and `filename` flags

```
Run: func(cmd *cobra.Command, args []string) {
       manager, _ := cmd.Flags().GetString("manager")
       filename, _ := cmd.Flags().GetString("filename")
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)Once we have the `manager` and `filename` variables defined, we move on and check that the file specified by `filename` actually exists. We do this by first getting the absolute path of the filename using the `Abs` function from the `filepath` package. Then we pass the `fullFilePath` to our `fileExists` function, and if the file does not exist, we log a message and exit. Checking for the existence of the task file allows us to do some sanity checking and provide the user with a relevant error message. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)

##### Listing 12.16 Checking for the existence of the task file

```
fullFilePath, err := filepath.Abs(filename)
       if err != nil {
           log.Fatal(err)
       }

       if !fileExists(fullFilePath) {
           log.Fatalf("File %s does not exist.", filename)
       }
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)Having confirmed that the `filename` passed into the command exists, we can move on and start the task. We’ll use the following process:

-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)Log helpful messages about the manager and absolute file path.
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)Read the contents of the task definition file, printing out another log message.
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)Call the manager’s API (the equivalent of `curl` `-X` `POST` `localhost:5555/ tasks`).
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)Handle any errors.

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)The bulk of the `Run` field’s function deals with calling the manager’s API and handling any errors. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)

##### Listing 12.17 The remainder of the `Run` field

```
log.Printf("Using manager: %v\n", manager)                       #1
        log.Printf("Using file: %v\n", fullFilePath)
 
        data, err := os.ReadFile(filename)                       #2
        if err != nil {
            log.Fatalf("Unable to read file: %v", filename)
        }
        log.Printf("Data: %v\n", string(data))
 
        url := fmt.Sprintf("http://%s/tasks", manager)
        resp, err := http.Post(url, "application/json",
         bytes.NewBuffer(data))                                #3
        if err != nil {
            log.Panic(err)
        }
 
        if resp.StatusCode != http.StatusCreated {               #4
            log.Printf("Error sending request: %v", resp.StatusCode)
        }
 
        defer resp.Body.Close()
        log.Println("Successfully sent task request to manager")
    },
}
#1 Logs helpful errors that tell a user the manager being used and the path to the task file
#2 Reads the contents of the task file and checks for errors
#3 Calls the manager’s API via the POST method and passes the task in the request body
#4 Checks that the request was successful and the task was created
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)With this code, we’re ready to start a task! If you stopped your workers and manager from the previous sections, start them back up. Then run the `run` command:[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)

```bash
$ go run main.go run --filename task1.json
2023/04/30 15:51:40 Using manager: localhost:5555
2023/04/30 15:51:40 Using file:
 /home/t/workspace/personal/manning/code/ch12-experimental/task1.json
2023/04/30 15:51:40 Data: {
    "ID": "a7aa1d44-08f6-443e-9378-f5884311019e",
    "State": 2,
    "Task": {
        "State": 1,
        "ID": "bb1d59ef-9fc1-4e4b-a44d-db571eeed203",
        "Name": "test-chapter-9.1",
        "Image": "timboring/echo-server:latest",
        "ExposedPorts": {
            "7777/tcp": {}
        },
        "PortBindings": {
            "7777/tcp": "7777"
        },
        "HealthCheck": "/health"
    }
}
 
2023/04/30 15:51:40 Successfully sent task request to manager
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)Watching the output from the manager, you should see it start up the task. And you can confirm it by running `docker` `ps`:

```bash
$ docker ps
CONTAINER ID   IMAGE                          CREATED        STATUS
99b32646ef35   timboring/echo-server:latest   1 second ago   Up 1 second
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)We can also query the manager’s API directly to verify the task is running:

```bash
$ curl localhost:5555/tasks|jq
[
  {
    "ID": "bb1d59ef-9fc1-4e4b-a44d-db571eeed203",
    "ContainerID":
     "99b32646ef35ed3819196b0b890bebd94ae6d9085dce7914e742e133c8a86fdd",
    "Name": "test-chapter-9.1",
    "State": 2,
    "Image": "timboring/echo-server:latest",
 
    // output truncated
  }
]
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)Nice! But let’s not stop here. Now that we’ve created a command to start tasks, let’s create one to stop them. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)

## [](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)12.9 Implementing the stop command

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)By now, you should know what’s coming next. We start by creating a skeleton:[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)

```bash
$ cobra-cli add stop
stop created at /home/t/workspace/personal/manning/code/ch12-experimental

$ tree cmd
cmd/
├── manager.go
├── root.go
├── run.go
├── stop.go
└── worker.go
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)Next, we add our flags to the skeleton in the `cmd/stop.go` file. We only need a single flag, `manager`, for the `Stop` command. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)

##### Listing 12.18 Using the `manager` flag for the `Stop` command

```
package cmd
 
import (
    "fmt"
    "log"
    "net/http"
 
    "github.com/spf13/cobra"
)
 
func init() {
    rootCmd.AddCommand(stopCmd)
    stopCmd.Flags().StringP("manager", "m", "localhost:5555", "Manager to
     talk to")
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)With our flags defined, we replace the boilerplate usage strings generated by the `cobra-cli` `add` command with more relevant ones:[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)

```
var stopCmd = &cobra.Command{
   Use:   "stop",
   Short: "Stop a running task.",
   Long: `cube stop command.

The stop command stops a running task.`,
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)At this point, we can run our command with the `--help` flag and verify that our command works:[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)

```bash
$ go run main.go stop --help
cube stop command.

The stop command stops a running task.

Usage:
 cube stop [flags]

Flags:
 -h, --help             help for stop
 -m, --manager string   Manager to talk to (default "localhost:5555")
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)With our `stop` command, notice that we did not define a flag to specify the task we want to stop. Instead, the user will pass the task as an argument to the command. Here is what this will look like:

```bash
$ go run main.go stop bb1d59ef-9fc1-4e4b-a44d-db571eeed203
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)To read the argument, we define the `Args` field on our `stopCmd` variable. We give this variable a value of `cobra.MinimumNArgs(1)` to say that we expect the user to pass one argument to our command. The `Run` field should look familiar at this point. We’re performing the equivalent of calling `curl` `-X` `DELETE` `localhost:5555/tasks/ {taskID}`. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)

##### Listing 12.19 The `Stop` command using arguments in addition to flags

```
Args: cobra.MinimumNArgs(1),
    Run: func(cmd *cobra.Command, args []string) {
        manager, _ := cmd.Flags().GetString("manager")
        url := fmt.Sprintf("http://%s/tasks/%s", manager, args[0])
        client := &http.Client{}                                         #1
        req, err := http.NewRequest("DELETE", url, nil)                  #2
        if err != nil {
            log.Printf("Error creating request %v: %v", url, err)
        }
 
        resp, err := client.Do(req)                                      #3
        if err != nil {
            log.Printf("Error connecting to %v: %v", url, err)
        }
 
        if resp.StatusCode != http.StatusNoContent {                     #4
            log.Printf("Error sending request: %v", err)
            return
        }
 
        log.Printf("Task %v has been stopped.", args[0])
    },
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)Let’s try to stop the task we started using our new `stop` command:

```bash
$ go run main.go stop bb1d59ef-9fc1-4e4b-a44d-db571eeed203
2023/04/30 16:13:44 Task bb1d59ef-9fc1-4e4b-a44d-db571eeed203 has been
 stopped.
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)Now let’s verify it stopped our task by checking the output of `docker` `ps`:

```bash
$ docker ps
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)Nice! With our `stop` command, we have successfully replaced the manual processes we had been using in previous chapters. Now we can perform everything by the way of commands: starting the worker(s), starting the manager, and starting and stopping tasks. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)

## [](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)12.10 Implementing the status command

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)As long as we’re already in the headspace of our command-line tool, let’s create two more commands. The first will be the `status` command. If you recall, throughout this book, we have used the `docker` `ps` command to get a list of our running Docker containers after starting tasks:[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)

```bash
$ docker ps
CONTAINER ID   IMAGE                          CREATED          STATUS
a4a7028e5463   timboring/echo-server:latest   19 seconds ago   Up 18 seconds
92462d09ee98   timboring/echo-server:latest   50 seconds ago   Up 49 seconds
e29a26176fcb   timboring/echo-server:latest   15 minutes ago   Up 15 minutes
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)For our purposes, we want output similar to `docker` `ps`, but we want it to contain information about our tasks instead of our containers. That is, we want the output to come from the source of truth for our orchestration system (i.e., our manager).

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)So let’s create the skeleton for our `status` command using the `cobra-cli` `add` command:[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)

```bash
$ cobra-cli add status
status created at /home/t/workspace/personal/manning/code/ch12-experimental

$ tree cmd
cmd
├── manager.go
├── root.go
├── run.go
├── status.go
├── stop.go
└── worker.go
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)With our skeleton created, we can start our customization by defining our flags in its `init` function. In this case, we are only defining a single flag, `manager`, to tell the command the address of the manager from which it will get the status of our tasks. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)

##### Listing 12.20 Defining the `manager` flag in the `init` method

```
package cmd
 
import (
    "cube/task"
    "encoding/json"
    "fmt"
    "io"
    "log"
    "net/http"
    "os"
    "text/tabwriter"
    "time"
 
    "github.com/docker/go-units"
    "github.com/spf13/cobra"
)
 
func init() {
    rootCmd.AddCommand(statusCmd)
    statusCmd.Flags().StringP("manager", "m", "localhost:5555",
    "Manager to talk to")
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)Next, let’s customize our help output to make it more useful:

```
var StatusCmd = &cobra.Command{
    Use:   "status",
    Short: "Status command to list tasks.",
    Long: `cube status command.
 
The status command allows a user to get the status of tasks from
 the Cube manager.`,
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)And as we’ve seen before, we can now run the command with the `--help` flag:[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)

```bash
$ go run main.go status --help
cube status command.
 
The status command allows a user to get the status of tasks from the Cube
 manager.
 
Usage:
  cube status [flags]
 
Flags:
  -h, --help             help for status
  -m, --manager string   Manager to talk to (default "localhost:5555")
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)Last, but not least, we can implement the function for our `Run` field. The function will perform the following operations:

-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)Retrieves the manager address passed on the command line
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)Uses the manager address to build the URL for the manager’s API
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)Makes a `GET` request to the manager’s API to retrieve all tasks
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)Unmarshals the JSON body sent in the response and converts it to a slice of pointers to `task.Task`
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)Prints out a portion of each task’s info in a formatted table (similar to the output of `docker` `ps`)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)The `Run` field’s function is responsible for calling the manager’s API and printing out the response in a readable format. One thing to note is that we use the `tabwriter` ([https://pkg.go.dev/text/tabwriter](https://pkg.go.dev/text/tabwriter)) package from Go’s standard library to create our output. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)

##### Listing 12.21 The `Run` function

```
Run: func(cmd *cobra.Command, args []string) {
        manager, _ := cmd.Flags().GetString("manager")
 
        url := fmt.Sprintf("http://%s/tasks", manager)
        resp, _ := http.Get(url)
        body, err := io.ReadAll(resp.Body)
        if err != nil {
            log.Fatal(err)
        }
        defer resp.Body.Close()
 
        var tasks []*task.Task
        err = json.Unmarshal(body, &tasks)
        if err != nil {
            log.Fatal(err)
        }
 
        w := tabwriter.NewWriter(os.Stdout, 0, 0, 5, ' ', tabwriter.TabIndent)
        fmt.Fprintln(w, "ID\tNAME\tCREATED\tSTATE\tCONTAINERNAME\tIMAGE\t")
        for _, task := range tasks {
            var start string
            if task.StartTime.IsZero() {
                start = fmt.Sprintf("%s ago",
           units.HumanDuration(time.Now().UTC().Sub(time.Now().UTC())))
            } else {
                start = fmt.Sprintf("%s ago",
           units.HumanDuration(time.Now().UTC().Sub(task.StartTime)))
            }
 
            state := task.State.String()[task.State]
            fmt.Fprintf(w, "%s\t%s\t%s\t%s\t%s\t%s\t\n", task.ID, task.Name,
             start, state, task.Name, task.Image)
        }
        w.Flush()
    },
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)With that, we can run the `status` command in figure 12.3. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)

![Figure 12.3 Result of running the status command](https://drek4537l1klr.cloudfront.net/boring/Figures/12-03.png)

## [](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)12.11 Implementing the node command

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)The last command we’ll implement is the `node` command. The purpose of this command is to provide a summary of the nodes in our orchestration system. It will list the following:[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)

-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)Node name
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)Memory
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)Disk
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)Role
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)Number of tasks

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)Now, technically, we don’t really need this command. Like the `status` command, we can use the manager’s API and query the `/nodes` endpoint directly. Here’s what it looks like using the `curl` command and piping the output to `jq` to make it more readable:[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)

```bash
$ curl localhost:5555/nodes|jq
[
 {
   "Name": "localhost:5556",
   "Ip": "",
   "Api": "http://localhost:5556",
   "Memory": 32793076,
   "MemoryAllocated": 0,
   "Disk": 20411170816,
   "DiskAllocated": 0,
   "Stats": {
     "MemStats": {...},
     "DiskStats": {...},
     "CpuStats": {...},
     "LoadStats": {...},
     "TaskCount": 0
   },
   "Role": "worker",
   "TaskCount": 0
 }
]
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)This output should look familiar to you. It’s a list of `Node` types, which we implemented in chapter 10 while working on the scheduler. Notice that there is a single node in the list of nodes and that it has the `Stats` field, which should also look familiar, as it is the `Stats` type we implemented in chapter 6. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)While we can get information about the nodes in our system using `curl` to query the manager’s `/nodes` endpoint, it’s not the easiest on the eyes. This is why we’re going to implement the `node` command. We’ll condense the information down to the most essential and output it in a more readable manner. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)Again, we’ll use the `cobra-cli` `add` command to create our skeleton:[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)

```bash
$ cobra-cli add node
node created at /home/t/workspace/personal/manning/code/ch12-experimental

$ tree cmd
cmd
├── manager.go
├── node.go
├── root.go
├── run.go
├── status.go
├── stop.go
└── worker.go
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)Like the `status` command we implemented, the `node` command will have only a single flag.

##### Listing 12.22 The `node` command defining a single flag of type `StringP`

```
package cmd
 
import (
    "cube/node"
    "encoding/json"
    "fmt"
    "io"
    "net/http"
    "os"
    "text/tabwriter"
 
    "github.com/spf13/cobra"
)
 
func init() {
    rootCmd.AddCommand(nodeCmd)
    nodeCmd.Flags().StringP("manager", "m", "localhost:5555", "Manager to
     talk to")
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)Next, let’s update the `Use`, `Short`, and `Long` fields on our `nodeCmd` struct. `nodeCmd` provides information about the nodes in the orchestration system. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)

##### Listing 12.23 The `nodeCmd` struct

```
var NodeCmd = &cobra.Command{
    Use:   "node",
    Short: "Node command to list nodes.",
    Long: `cube node command.
 
The node command allows a user to get the information about the nodes in the
 cluster.`,
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)At this point, we should have a working command, which we can once again confirm by running the command with the `--help` flag:

```bash
$ go run main.go node --help
cube node command.
 
The node command allows a user to get the information about the nodes in the
 cluster.
 
Usage:
  cube node [flags]
 
Flags:
  -h, --help             help for node
  -m, --manager string   Manager to talk to (default "localhost:5555")
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)Finally, we’ll implement the `Run` field. Again, this process should look familiar, as it’s similar to the `status` command:[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)

-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)Retrieves the manager address passed on the command line
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)Uses the manager address to build the URL for the manager’s API
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)Makes a `GET` request to the manager’s `/nodes` endpoint to retrieve all nodes
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)Unmarshals the JSON body sent in the response and converts it to a slice of pointers to `node.Node`
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)Prints out a portion of each node’s info in a formatted table (similar to the output of `docker` `ps`)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)Like the `status` command, the `node` command talks to the manager’s API and formats the response in a concise manner that is easy to read. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)

##### Listing 12.24 The `node` command

```
Run: func(cmd *cobra.Command, args []string) {
        manager, _ := cmd.Flags().GetString("manager")
 
        url := fmt.Sprintf("http://%s/nodes", manager)
        resp, _ := http.Get(url)
        defer resp.Body.Close()
        body, _ := io.ReadAll(resp.Body)
        var nodes []*node.Node
        json.Unmarshal(body, &nodes)
        w := tabwriter.NewWriter(os.Stdout, 0, 0, 5, ' ',
             tabwriter.TabIndent)
        fmt.Fprintln(w, "NAME\tMEMORY (MiB)\tDISK (GiB)\tROLE\tTASKS\t")
        for _, node := range nodes {
            fmt.Fprintf(w, "%s\t%d\t%d\t%s\t%d\t\n", node.Name,
             node.Memory/1000,
             node.Disk/1000/1000/1000, node.Role, node.TaskCount)
        }
        w.Flush()
    },
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)Let’s give it a try!

```bash
$ go run main.go node
NAME               MEMORY (MiB)     DISK (GiB)     ROLE       TASKS
localhost:5556     32793            20             worker     0
localhost:5557     32793            20             worker     0
localhost:5558     32793            20             worker     0
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)Nice! As you can see, I have three nodes running. Since I’m running all three workers on the same machine, the `MEMORY` and `DISK` fields will be the same. Now let’s start up the same three tasks that we’ve used in past chapters and see how the output of the `node` command changes:[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)

```bash
$ go run main.go node
NAME               MEMORY (MiB)     DISK (GiB)     ROLE       TASKS
localhost:5556     32793            20             worker     1
localhost:5557     32793            20             worker     1
localhost:5558     32793            20             worker     1
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)As expected, the output of the `node` command has changed after starting three tasks, with each node running one of those tasks. With that, we have implemented all of our commands. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)

## [](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)Summary

-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)The Cobra framework helps build CLIs by providing standardized components, similar to web frameworks.
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)Cobra provides its own CLI, `cobra-cli`, that allows developers to initialize a new command-line project and to add commands to an existing one.
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)Commands follow the pattern of `APPNAME` `COMMAND` `ARG` `--FLAG`.
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)Commands provide built-in help.
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)We replaced the old `main.go` program with the new `worker` and `manager` commands, giving us more flexibility to start the worker and manager components independently.
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-12/)We created additional commands that made it easier to interact with our orchestration system. Instead of starting, stopping, and getting the status of tasks by calling the manager’s API using `curl`, we provided the commands `run`, `stop`, and `status`. We also provided the `node` command, which gives a user an overview of the current state of the nodes in the cluster.

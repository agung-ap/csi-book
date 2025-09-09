# [](/book/build-an-orchestrator-in-go-from-scratch/appendix/)Appendix. Environment setup

## [](/book/build-an-orchestrator-in-go-from-scratch/appendix/)A.1 Installing Go

[](/book/build-an-orchestrator-in-go-from-scratch/appendix/)Installing a version of Go is as easy as downloading it and untarring it. The latest version can be downloaded from [https://go.dev/doc/install](https://go.dev/doc/install).

[](/book/build-an-orchestrator-in-go-from-scratch/appendix/)The Go language spec is currently at version 1. In general, “programs written to the Go 1 specification will continue to compile and run correctly, unchanged, over the lifetime of that specification” ([https://tip.golang.org/doc/go1compat](https://tip.golang.org/doc/go1compat)). This means that any version of Go should work.

[](/book/build-an-orchestrator-in-go-from-scratch/appendix/)The code in this book has been tested with the following versions:

-  [](/book/build-an-orchestrator-in-go-from-scratch/appendix/)1.20
-  [](/book/build-an-orchestrator-in-go-from-scratch/appendix/)1.19
-  [](/book/build-an-orchestrator-in-go-from-scratch/appendix/)1.16

### [](/book/build-an-orchestrator-in-go-from-scratch/appendix/)A.1.1 Installing on Linux

[](/book/build-an-orchestrator-in-go-from-scratch/appendix/)The default instructions for installing Go recommend removing previous installations. If you want to work with multiple versions of Go, see the doc “Managing Go Installations” ([https://go.dev/doc/manage-install](https://go.dev/doc/manage-install)).

##### Listing A.1 Installing a version of Go on Linux

```
12345678910$ curl -L -O https://go.dev/dl/go1.21.6.linux-amd64.tar.gz
# Remove previous Go installations
$ rm -rf /usr/local/go && tar -C /usr/local -xzf go1.21.6.linux-amd64.tar.gz
# Add /usr/local/go/bin to your $PATH
$ export PATH=$PATH:/usr/local/go/bin
# check version
$ go version
```

## [](/book/build-an-orchestrator-in-go-from-scratch/appendix/)A.2 Project structure and initialization

[](/book/build-an-orchestrator-in-go-from-scratch/appendix/)Create a directory to hold the source code and other files for your work. [](/book/build-an-orchestrator-in-go-from-scratch/appendix/)[](/book/build-an-orchestrator-in-go-from-scratch/appendix/)

##### Listing A.2 Creating a directory named `cube` for our project

```bash
$ cd $HOME
$ mkdir cube
```

[](/book/build-an-orchestrator-in-go-from-scratch/appendix/)Once you have created your project directory, change into it and initialize the module:

```bash
$ cd $HOME/cube
$ go mod init cube
go: creating new go.mod: module cube
```

[](/book/build-an-orchestrator-in-go-from-scratch/appendix/)Once initialized, you should see a single file in the root of the project:

```bash
$ ls
go.mod
```

[](/book/build-an-orchestrator-in-go-from-scratch/appendix/)Next, to save some time while working through the book, you can install the dependencies we’ll use:[](/book/build-an-orchestrator-in-go-from-scratch/appendix/)[](/book/build-an-orchestrator-in-go-from-scratch/appendix/)

```bash
$ go get \
github.com/boltdb/bolt \
github.com/c9s/goprocinfo/linux \
github.com/docker/go-connections \
github.com/go-chi/chi/v5 \
github.com/golang-collections/collections \
github.com/google/go-cmp \
github.com/google/uuid \
github.com/moby/moby \
github.com/docker/docker/api/types \
github.com/docker/docker/api/types/container \
github.com/docker/docker/client \
github.com/docker/go-units \
github.com/spf13/cobra
```

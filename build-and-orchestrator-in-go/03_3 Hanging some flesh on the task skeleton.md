# [](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)3 Hanging some flesh on the task skeleton

### This chapter covers

- Reviewing how to start and stop Docker containers via the command line
- Introducing the Docker API calls for starting and stopping containers
- Implementing the `Task` concept to start and stop a container

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)Think about cooking your favorite meal. Let’s say you like making homemade pizza. To end up pulling a delicious, hot pizza out of your oven, you have to perform a number of tasks. If you like onions, green peppers, or any other veggies on your pizza, you have to cut them up. You must knead the dough and spread it on a baking sheet. Next, you spread tomato sauce across the dough and sprinkle cheese over it. Finally, on top of the cheese, you layer your veggies and other ingredients.

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)A task in an orchestration system is similar to one of the individual steps in making a pizza. Like most companies these days, yours most likely has a website. That company’s website runs on a web server, perhaps the ubiquitous Apache web server. That’s a task. The website may use a database, like MySQL or PostgreSQL, to store dynamic content. That’s a task.

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)In our pizza-making analogy, the pizza wasn’t made in a vacuum. It was created in a specific context, which is a kitchen. The kitchen provides the necessary resources to make the pizza: a refrigerator where the cheese is stored, cabinets where the pizza sauce is kept, an oven in which to cook the pizza, and a knife to cut the pizza into slices.

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)Similarly, a task operates in a specific context. In our case, that context will be a Docker container. Like the kitchen, the container will provide the resources necessary for the task to run: it will provide CPU cycles, memory, and networking according to the needs of the task.

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)As a reminder, the task is the foundation of an orchestration system. Figure 1.1 shows a modified version of our mental model from chapter 1.

![Figure 3.1 The main purpose of an orchestration system is to accept tasks from users and run them on the system’s worker nodes. Here, we see a user submitting a task to the Manager node, which then selects Worker2 to run the task. The dotted lines to Worker1 and Worker3 represent that these nodes were considered but ultimately not selected to run the task.](https://drek4537l1klr.cloudfront.net/boring/Figures/03-01.png)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)In the rest of this chapter, we’ll flesh out the `Task` skeleton we wrote in the previous chapter. But first, let’s quickly review some Docker basics. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)

## [](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)3.1 Docker: Starting, stopping, and inspecting containers from the command line

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)If you are a developer, you have probably used Docker containers to run your application and its backend database on your laptop while working on your code. If you are a DevOps engineer, you may have deployed Docker containers to your company’s production environment. Containers allow the developer to package their code, along with all its dependencies, and then ship the container to production. If a DevOps team is responsible for deployments to production, then they only have to worry about deploying the container. They don’t have to worry about whether the machine where the container will run has the correct version of the PostgreSQL library that the application uses to connect to its database. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)

##### Tip

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/) If you need a more detailed review of Docker containers and how to control them, check out chapter 2 of *Docker in Action* ([http://mng.bz/PRq8](http://mng.bz/PRq8)).

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)To run a Docker container, we can use the `docker` `run` command, an example of which can be seen in the next listing. Here, the `docker` `run` command is starting up a PostgreSQL database in a container, which might be used as a backend datastore while developing a new application. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)

##### Listing 3.1 Running the Postgres database server as a Docker container

```bash
$ docker run -it \
   -p 5432:5432 \
   --name cube-book \
   -e POSTGRES_USER=cube \
   -e POSTGRES_PASSWORD=secret \
   postgres
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)This command runs the container in the foreground, meaning we can see its log output (`-it`), gives the container the name of `postgres`, and sets the `POSTGRES_USER` and `POSTGRES_PASSWORD` environment variables. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)Once a container is running, it performs the same functions it would if you were running it as a regular process on your laptop or desktop. In the case of the Postgres database from listing 3.1, I can now log into the database server using the `psql` command-line client and create a table like that in the following listing. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)

##### Listing 3.2 Logging in to the Postgres server and creating a table

```bash
$ psql -h localhost -p 5432 -U cube
Password for user cube:
psql (9.6.22, server 13.2 (Debian 13.2-1.pgdg100+1))
WARNING: psql major version 9.6, server major version 13.
        Some psql features might not work.
Type "help" for help.

cube=# \d
No relations found.
cube=# CREATE TABLE book (
isbn char(13) PRIMARY KEY,
title varchar(240) NOT NULL,
author varchar(140)
);
CREATE TABLE
cube=# \d
      List of relations
Schema | Name | Type  | Owner
--------+------+-------+-------
public | book | table | cube
(1 row)
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)Because we specified `-p` `5432:5432` in the `docker` `run` command in the previous listing, we can tell the `psql` client to connect to that port on the local machine. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)Once a container is up and running, we can get information about it using the `docker` `inspect` command. The output from this command is extensive, so I will only list the `State` info. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)

##### Listing 3.3 Using the `docker` `inspect` command

```bash
$ docker inspect cube-book
[
   {
       "Id": "a820c7abb54b723b5efc0946900baf58e093d8fdd238d4ec7cb5647",
       "Created": "2021-05-15T20:00:41.228528102Z",
       "Path": "docker-entrypoint.sh",
       "Args": [
           "postgres"
       ],
       "State": {
           "Status": "running",
           "Running": true,
           "Paused": false,
           "Restarting": false,
           "OOMKilled": false,
           "Dead": false,
           "Pid": 27599,
           "ExitCode": 0,
           "Error": "",
           "StartedAt": "2021-05-15T20:00:42.4656334Z",
           "FinishedAt": "0001-01-01T00:00:00Z"
       },
       ....
]
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)Finally, we can stop a Docker container using the `docker` `stop` `cube-book` command. There isn’t any output from the command, but if we run the `docker` `inspect` `cube-book` command now, we’ll see that the state has changed from `running` to `exited`. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)

##### Listing 3.4 Running `docker inspect cube-book` after `docker stop cube-book`

```bash
$ docker inspect cube-book
[
   {
       "Id": "a820c7abb54b723b5efc0946900baf58e093d8fdd238d4ec7cb5647",
       "Created": "2021-05-15T20:00:41.228528102Z",
       "Path": "docker-entrypoint.sh",
       "Args": [
           "postgres"
       ],
       "State": {
           "Status": "exited",
           "Running": false,
           "Paused": false,
           "Restarting": false,
           "OOMKilled": false,
           "Dead": false,
           "Pid": 0,
           "ExitCode": 0,
           "Error": "",
           "StartedAt": "2021-05-15T20:00:42.4656334Z",
           "FinishedAt": "2021-05-15T20:18:31.698919838Z"
       },
       ....
]
```

## [](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)3.2 Docker: Starting, stopping, and inspecting containers from the API

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)In our orchestration system, the worker will be responsible for starting, stopping, and providing information about the tasks it’s running. To perform these functions, the worker will use Docker’s API. The API is accessible via the HTTP protocol using a client like `curl` or the HTTP library of a programming language. The following listing shows an example of using `curl` to get the same information we got from the `docker` `inspect` command previously. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)

##### Listing 3.5 Querying the Docker API with the `curl` HTTP client

```
curl --unix-socket \
   /var/run/docker.sock http://docker/containers/6970e8469684/json| jq .
{
 "Id": "6970e8469684d439c73577c4caee7261bf887a67433420e7dcd637cc53b8ffa7",
 "Created": "2021-05-15T20:58:36.283909602Z",
 "Path": "docker-entrypoint.sh",
 "Args": [
   "postgres"
 ],
 "State": {
   "Status": "running",
   "Running": true,
   "Paused": false,
   "Restarting": false,
   "OOMKilled": false,
   "Dead": false,
   "Pid": 270523,
   "ExitCode": 0,
   "Error": "",
   "StartedAt": "2021-05-15T20:58:36.541148947Z",
   "FinishedAt": "0001-01-01T00:00:00Z"
 },
 ....
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)Notice we’re passing the `--unix-socket` flag to the `curl` command. By default, Docker listens on a `unix` socket, but it can be configured to listen on a `tcp` socket. The URL, `http://docker/containers/6970e8469684/json`, contains the ID of the container to inspect, which I got from the `docker` `ps` command on my machine. Finally, the output from `curl` is piped to the `jq` command, which prints the output in a more readable format than `curl`’s. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)We could use Go’s HTTP library in our orchestration system, but that would force us to deal with many low-level details like HTTP methods, status codes, and serializing requests and deserializing responses. Instead, we’re going to use Docker’s SDK, which handles all the low-level HTTP details for us and allows us to focus on our primary task: creating, running, and stopping containers. The SDK provides the following six methods that will meet our needs:

-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)`NewClientWithOpts`—A helper method that instantiates an instance of the client and returns it to the caller
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)`ImagePull`—Pulls the image down to the local machine where it will be run
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)`ContainerCreate`—Creates a new container with a given configuration
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)`ContainerStart`—Sends a request to Docker Engine to start the newly created container
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)`ContainerStop`—Sends a request to Docker Engine to stop a running container
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)`ContainerRemove`—Removes the container from the host

##### Note

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/) Docker’s Golang SDK has extensive documentation ([https://pkg.go.dev/github.com/docker/docker](https://pkg.go.dev/github.com/docker/docker)) that’s worth reading. In particular, the docs about the Go client ([https://pkg.go.dev/github.com/docker/docker/client](https://pkg.go.dev/github.com/docker/docker/client)) are relevant to our work throughout the rest of this book.

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)The `docker` command-line examples we reviewed in the previous section use the Go SDK under the hood. Later in this chapter, we’ll implement a `Run()` method that uses the `ImagePull`, `ContainerCreate`, and `ContainerStart` methods to create and start a container. Figure 3.2 provides a graphic representation of our custom code and the `docker` command using the SDK. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)

![Figure 3.2 Regardless of the starting point, all paths to creating and running a container go through the Docker SDK.](https://drek4537l1klr.cloudfront.net/boring/Figures/03-02.png)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)By using the Go SDK for controlling the Docker containers in our orchestration system, we don’t have to reinvent the wheel. We can simply reuse the same code used by the `docker` command every day. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)

## [](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)3.3 Task configuration

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)To run our tasks as containers, they need a configuration. What is a configuration? Think back to our pizza analogy from the beginning of the chapter. One of the tasks in making our pizza was cutting the onions (if you don’t like onions, insert your veggie of choice). To perform that task, we would use a knife and a cutting board, and we would cut the onions in a particular way. Perhaps we cut them into thin, even slices or dice them into small cubes. This is all part of the “configuration” of the task of cutting onions. (Okay, I’m probably stretching the pizza analogy a bit far, but I think you get the point.) [](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)For a task in our orchestration system, we’ll describe its configuration using the `Config` struct in listing 3.6. This struct encapsulates all the necessary bits of information about a task’s configuration. The comments should make the intent of each field obvious, but there are a couple of fields worth highlighting. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)The `Name` field will be used to identify a task in our orchestration system, and it will perform double duty as the name of the running container. Throughout the rest of the book, we’ll use this field to name our containers like `test-container-1`. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)The `Image` field, as you probably guessed, holds the name of the image the container will run. Remember, an image can be thought of as a package: it contains the collection of files and instructions necessary to run a program. This field can be set to a value as simple as `postgres`, or it can be set to a more specific value that includes a version, like `postgres:13`. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)The `Memory` and `Disk` fields will serve two purposes. The scheduler will use them to find a node in the cluster capable of running a task. They will also be used to tell the Docker daemon the number of resources a task requires. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)The `Env` field allows a user to specify environment variables that will get passed into the container. In our command to run a Postgres container, we set two environment variables: `-e` `POSTGRES_USER=cube` to specify the database user and `-e` `POSTGRES_ PASSWORD=secret` to specify that user’s password. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)Finally, the `RestartPolicy` field tells the Docker daemon what to do if a container dies unexpectedly. This field is one of the mechanisms that provides resilience in our orchestration system. As you can see from the comment, the acceptable values are an empty string, `always`, `unless-stopped`, or `on-failure`. Setting this field to `always` will, as its name implies, restart a container if it stops. Setting it to `unless-stopped` will restart a container unless it has been stopped (e.g., by `docker` `stop`). Setting it to `on-failure` will restart the container if it exits due to an error (i.e., a nonzero exit code). There are a few details that are spelled out in the documentation ([http://mng.bz/1JdQ](http://mng.bz/1JdQ)). [](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)We’re going to add the `Config` struct in the next listing to the `task.go` file from chapter 2. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)

##### Listing 3.6 The `Config` struct that will hold the configuration for orchestration tasks

```
type Config struct {
   Name          string
   AttachStdin   bool
   AttachStdout  bool
   AttachStderr  bool
   ExposedPorts  nat.PortSet
   Cmd           []string
   Image         string
   Cpu           float64
   Memory        int64
   Disk          int64
   Env           []string
   RestartPolicy string
}
```

## [](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)3.4 Starting and stopping tasks

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)Now that we’ve talked about a task’s configuration, let’s move on to starting and stopping a task. Remember, the worker in our orchestration system will be responsible for running tasks for us. That responsibility will mostly involve starting and stopping tasks. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)Let’s start by adding the code for the `Docker` struct you see in listing 3.7 to the `task.go` file. This struct will encapsulate everything we need to run our task as a Docker container. The `Client` field will hold a Docker client object that we’ll use to interact with the Docker API. The `Config` field will hold the task’s configuration. And once a task is running, it will also contain the `ContainerId`. This ID will allow us to interact with the running task. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)

##### Listing 3.7 The `Docker` struct

```bash
type Docker struct {
   Client *client.Client
   Config  Config
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)For the sake of convenience, let’s create a struct called `DockerResult`. We can use this struct as the return value in methods that start and stop containers, providing a wrapper around common information that is useful for callers. The struct contains an `Error` field to hold any error messages. It has an `Action` field that can be used to identify the action being taken, for example, start or stop. It has a `ContainerId` field to identify the container to which the result pertains. And, finally, there is a `Result` field that can hold arbitrary text that provides more information about the result of the operation. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)

##### Listing 3.8 The `DockerResult` struct

```
type DockerResult struct {
   Error       error
   Action      string
   ContainerId string
   Result      string
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)Now we’re ready for the exciting part: actually writing the code to create and run a task as a container. To do this, let’s start by adding a method to the `Docker` struct we created earlier. Let’s call that method `Run`. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)The first part of our `Run` method will pull the Docker image our task will use from a container registry such as Docker Hub. A container registry is simply a repository of images and allows for the easy distribution of the images it hosts. To pull the image, the `Run` method first creates a context, which is a type that holds values that can be passed across boundaries such as APIs and processes. It’s common to use a context to pass along deadlines or cancellation signals in requests to an API. In our case, we’ll use an empty context returned from the `Background` function. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)Next, `Run` calls the `ImagePull` method on the Docker client object, passing the context object, the image name, and any options necessary to pull the image. The `ImagePull` method returns two values: an object that fulfills the `io.ReadCloser` interface and an error object. It stores these values in the `reader` and `err` variables. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)The next step in the method checks the error value returned from `ImagePull`. If the value is not `nil`, the method prints the error message and returns as a `DockerResult`. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)Finally, the method copies the value of the `reader` variable to `os.Stdout` via the `io.Copy` function. `io.Copy` is a function from the `io` package in Golang’s standard library, and it simply copies data to a destination (`os.Stdout`) from a source (`reader`). Because we’ll be working from the command line whenever we’re running the components of our orchestration system, it’s useful to write the `reader` variable to `Stdout` as a way to communicate what happened in the `ImagePull` method. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)

##### Listing 3.9 The start of our `Run()` method

```
func (d *Docker) Run() DockerResult {
   ctx := context.Background()
   reader, err := d.Client.ImagePull(
       ctx, d.Config.Image, types.ImagePullOptions{})
   if err != nil {
       log.Printf("Error pulling image %s: %v\n", d.Config.Image, err)
       return DockerResult{Error: err}
   }
   io.Copy(os.Stdout, reader)
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)Similar to running a container from the command line, the method begins by pulling the container’s image.

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)Once the `Run` method has pulled the image and checked for errors (and found none, we hope), the next bit of business on the agenda is to prepare the configuration to be sent to Docker. Before we do that, however, let’s take a look at the signature of the `ContainerCreate` method from the Docker client. This is the method we’ll use to create the container. As you can see in listing 3.10, `ContainerCreate` takes several arguments. Similar to the `ImagePull` method used earlier, it takes a `context.Context` as its first argument. The next argument is the actual container configuration, which is a pointer to a `container.Config` type. We’ll copy the values from our own `Config` type into this one. The third argument is a pointer to a `container.HostConfig` type. This type will hold the configuration a task requires of the host on which the container will run, for example, a Linux machine. The fourth argument is also a pointer and points to a `network.NetworkingConfig` type. This type can be used to specify networking details, such as the network ID container, any links to other containers that are needed, and IP addresses. For our purposes, we won’t use the network configuration, instead allowing Docker to handle those details for us. The fifth argument is another pointer, and it points to a `specs.Platform` type. This type can be used to specify details about the platform on which the image runs. It allows you to specify things like the CPU architecture and the operating system. We won’t be making use of this argument either. The sixth and final argument to `ContainerCreate` is the container name, passed as a string. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)

##### Listing 3.10 The Docker client’s `ContainerCreate` method

```
func (cli *Client) ContainerCreate(
   ctx context.Context,
   config *container.Config,
   hostConfig *container.HostConfig,
   networkingConfig *network.NetworkingConfig,
   platform *specs.Platform,
   containerName string) (container.ContainerCreateCreatedBody, error)
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)Now we know what information we need to pass along in the `ContainerCreate` method, so let’s gather it from our `Config` type and massage it into the appropriate types that `ContainerCreate` will accept. What we’ll end up with is what you see in listing 3.11. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)First, we’ll create a variable called `rp`. This variable will hold a `container.RestartPolicy` type, and it will contain the `RestartPolicy` we defined earlier in our `Config` struct in listing 3.6. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)Following the `rp` variable, let’s declare a variable called `r`. This variable will hold the resources required by the container in a `container.Resources` type. The most common resources we’ll use for our orchestration system will be memory. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)Next, let’s create a variable called `cc` to hold our container configuration. This variable will be of the type `container.Config`, and into it, we’ll copy two values from our `Config` type. The first is the `Image` our container will use. The second is any environment variables, which go into the `Env` field. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)Finally, we take the `rp` and `r` variables we defined and add them to a third variable called `hc`. This variable is a `container.HostConfig` type. In addition to specifying the `RestartPolicy` and `Resources` in the `hc` variable, we’ll also set the `PublishAllPorts` field to `true`. What does this field do? Remember our example `docker` `run` command in listing 3.2, where we start up a PostgreSQL container? In that command, we used `-p` `5432:5432` to tell Docker that we wanted to map port 5432 on the host running our container to port 5432 inside the container. Well, that’s not the best way to expose a container’s ports on a host. There is an easier way. Instead, we can set `PublishAllPorts` to `true`, and Docker will expose those ports automatically by randomly choosing available ports on the host. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)The following listing creates four variables to hold configuration information, which gets passed to the `ContainerCreate` method. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)

##### Listing 3.11 The next phase of running a container

```
func (d *Docker) Run() DockerResult {

   // previous code not listed

   rp := container.RestartPolicy{
       Name: d.Config.RestartPolicy,
   }

   r := container.Resources{
       Memory: d.Config.Memory,
       NanoCPUs: int64(d.Config.Cpu * math.Pow(10, 9)),
   }

   cc := container.Config{
       Image: d.Config.Image,
       Tty: false,
       Env: d.Config.Env,
       ExposedPorts: d.Config.ExposedPorts,
   }

   hc := container.HostConfig{
       RestartPolicy: rp,
       Resources:     r,
       PublishAllPorts: true,
   }
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)We’ve done all the necessary prep work, and now we can create the container and start it. We’ve already touched on the `ContainerCreate` method in listing 3.10, so all that’s left to do is to call it like in listing 3.12. One thing to notice, however, is that we pass `nil` values as the fourth and fifth arguments, which, as you’ll recall from listing 3.10, are the `networking` and `platform` arguments. We won’t be making use of these features in our orchestration system, so we can ignore them for now. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)As with the `ImagePull` method earlier, `ContainerCreate` returns two values: a response, which is a pointer to a `container.ContainerCreateCreatedBody` type, and an error type. The `ContainerCreateCreatedBody` type gets stored in the `resp` variable, and we put the error in the `err` variable. Next, we check the `err` variable for any errors and, if we find any, print them and return them in a `DockerResult` type. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)Great! We’ve got all our ingredients together, and we’ve formed them into a container. All that’s left to do is start it. To perform this final step, we call the `ContainerStart` method. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)Besides a context argument, `ContainerStart` takes the `ID` of an existing container, which we get from the `resp` variable returned from `ContainerCreate`, and any options necessary to start the container. In our case, we don’t need any options, so we simply pass an empty `types.ContainerStartOptions`. `ContainerStart` only returns one type, an error, so we check it in the same way we have with the other method calls we’ve made. If there is an error, we print it and then return it in a `DockerResult`. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)

##### Listing 3.12 The penultimate phase

```
func (d *Docker) Run() DockerResult {
 
    // previous code not listed
 
    resp, err := d.Client.ContainerCreate(ctx, &cc, &hc, nil, nil,
   d.Config.Name)
    if err != nil {
        log.Printf("Error creating container using image %s: %v\n",
     d.Config.Image, err)
        return DockerResult{Error: err}
    }
 
    err = d.Client.ContainerStart(ctx, resp.ID, types.ContainerStartOptions{})
    if err != nil {
        log.Printf("Error starting container %s: %v\n", resp.ID, err)
        return DockerResult{Error: err}
    }
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)At this point, if all was successful, we have a container running the task. All that’s left to do now is to take care of some bookkeeping, which you can see in listing 3.13. We start by adding the container ID to the configuration object (which will ultimately be stored, but let’s not get ahead of ourselves!). Similar to printing the results of the `ImagePull` operation to `stdout`, we do the same with the result of starting the container. This is accomplished by calling the `ContainerLogs` method and then writing the return value to `stdout` using the `stdcopy.StdCopy(os.Stdout,` `os.Stderr,` `out)` call. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)

##### Listing 3.13 The final phase of creating and running a container

```
func (d *Docker) Run() DockerResult {
 
    // previous code not listed
 
    d.Config.Runtime.ContainerID = resp.ID
 
    out, err := cli.ContainerLogs(
        ctx,
        resp.ID,
        types.ContainerLogsOptions{ShowStdout: true, ShowStderr: true}
    )
    if err != nil {
        log.Printf("Error getting logs for container %s: %v\n", resp.ID, err)
        return DockerResult{Error: err}
    }
 
    stdcopy.StdCopy(os.Stdout, os.Stderr, out)
    return DockerResult{ContainerId: resp.ID, Action: "start",
     Result: "success"}
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)As a reminder, the `Run` method we’ve written in listings 3.9, 3.11, 3.12, and 3.13 perform the same operations as the `docker` `run` command. When you type `docker` `run` on the command line, under the hood, the `docker` binary is using the same SDK methods we’re using in our code to create and run the container. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)Now that we can create a container and start it, let’s write the code to stop a container. Compared to our `Run` method, the `Stop` method will be much simpler, as you can see in listing 3.14. Because there isn’t the necessary prep work to do for stopping a container, the process simply involves calling the `ContainerStop` method with the `ContainerID` and then calling the `ContainerRemove` method with the `ContainerID` and the requisite options. Again, in both operations, the code checks the value of the `err` returned from the method. As with the `Run` method, our `Stop` method performs the same operations carried out by the `docker` `stop` and `docker` `rm` commands. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)

##### Listing 3.14 Stopping a container

```
func (d *Docker) Stop(id string) DockerResult {
   log.Printf("Attempting to stop container %v", id)
   ctx := context.Background()
   err := d.Client.ContainerStop(ctx, id, nil)
   if err != nil {
       log.Printf("Error stopping container %s: %v\n", id, err)
       return DockerResult{Error: err}
   }

   err = d.Client.ContainerRemove(ctx, id, types.ContainerRemoveOptions{
       RemoveVolumes: true,
       RemoveLinks:   false,
       Force:         false,
   })
   if err != nil {
       log.Printf("Error removing container %s: %v\n", id, err)
       return DockerResult{Error: err}
   }

   return DockerResult{Action: "stop", Result: "success", Error: nil}
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)Now, let’s update our `main.go` program that we created in chapter 2 to create and stop a container. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)First, add the `createContainer` function in listing 3.15 to the bottom of the `main.go` file. Inside it, we’ll set up the configuration for the task and store it in a variable called `c`, and then we’ll create a new Docker client and store it in `dc`. Next, let’s create the `d` object, which is of type `task.Docker`. From this object, we call the `Run()` method to create the container. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)

##### Listing 3.15 The `createContainer` function

```
func createContainer() (*task.Docker, *task.DockerResult) {
   c := task.Config{
       Name:  "test-container-1",
       Image: "postgres:13",
       Env: []string{
           "POSTGRES_USER=cube",
           "POSTGRES_PASSWORD=secret",
       },
   }

   dc, _ := client.NewClientWithOpts(client.FromEnv)
   d := task.Docker{
       Client: dc,
       Config: c,
   }

   result := d.Run()
   if result.Error != nil {
       fmt.Printf("%v\n", result.Error)
       return nil, nil
   }

   fmt.Printf(
       "Container %s is running with config %v\n", result.ContainerId, c)
   return &d, &result
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)Second, add the `stopContainer` function below `createContainer`. This function accepts a single argument, `d`, which is the same `d` object created in `createContainer` in listing 3.15. All that’s left to do is call `d.Stop()`. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)

##### Listing 3.16 The `stopContainer` function

```
func stopContainer(d *task.Docker, id string) *task.DockerResult {
   result := d.Docker.Stop(id)
   if result.Error != nil {
       fmt.Printf("%v\n", result.Error)
       return nil
   }

   fmt.Printf(
       "Container %s has been stopped and removed\n", result.ContainerId)
   return &result
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)Finally, we call the `createContainer` and `stopContainer` functions we created from our `main()` function in `main.go`. To do that, add the code from listing 3.17 to the bottom of your main function. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)As you can see, the code is fairly simple. It starts by printing a useful message that it’s going to create a container; it then calls the `createContainer()` function and stores the results in two variables, `dockerTask` and `createResult`. Then it checks for errors by comparing the value of `createResult.Error` to `nil`. If it finds an error, it prints it and exits by calling `os.Exit(1)`. To stop the container, the `main` function simply calls `stopContainer` and passes it the `dockerTask` object returned by the earlier call to `createContainer`. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)

##### Listing 3.17 Calling the `createContainer` and `stopContainer` functions

```
func main() {

   // previous code not shown

   fmt.Printf("create a test container\n")
   dockerTask, createResult := createContainer()
   if createResult.Error != nil {
       fmt.Printf("%v", createResult.Error)
       os.Exit(1)
   }

   time.Sleep(time.Second * 5)
   fmt.Printf("stopping container %s\n", createResult.ContainerId)
   _ = stop_container(dockerTask, createResult.ContainerId)
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)Time for another moment of truth. Let’s run the code!

##### Listing 3.18 Running the code to create and stop a container

```bash
$ go run main.go                                                           #1
 task: {2c66f7c4-2484-4cf8-a22b-81c3dd24294d Task-1 0 Image-1 1024 1
    map[] map[]  0001-01-01 00:00:00 +0000 UTC
    0001-01-01 00:00:00 +0000 UTC}
task event: {f7045213-732e-49f9-9ca0-ef781e58d30c 0 2021-05-16
    16:00:41.890181309 -0400 EDT m=+0.001923263
    {2c66f7c4-2484-4cf8-a22b-81c3dd24294d Task-1 0 Image-1 1024 1
    map[] map[]  0001-01-01 00:00:00 +0000 UTC 0001-01-01
    00:00:00 +0000 UTC}}
worker: { {<nil> <nil> 0} map[] 0}
I will collect stats
I will start or stop a task
I will start a task
I Will stop a task
manager: {{<nil> <nil> 0} map[] map[] [] map[] map[]}
I will select an appropriate worker
I will update tasks
I will send work to workers
node: {Node-1 192.168.1.1 4 1024 0 25 0 worker 0}                          #2
create a test container                                                    #3
"status":"Pulling from library/postgres","id":"13"}
{"status":"Digest: sha256:117c3ea384ce21421541515ed"}
{"status":"Status: Image is up to date for postgres:13"}                   #4
Container 20dfabd6e7f7f30948690c4352979cbc2122d90b0a22567f9f0bcbc33cc0f051
    is running with config {test-container-1 false false false
    map[] [] postgres:13 0 0
    [POSTGRES_USER=cube POSTGRES_PASSWORD=secret] }                        #5
stopping container
    20dfabd6e7f7f30948690c4352979cbc2122d90b0a22567f9f0bcbc33cc0f051
2021/05/16 16:00:47 Attempting to stop container
    20dfabd6e7f7f30948690c4352979cbc2122d90b0a22567f9f0bcbc33cc0f051
Container
    20dfabd6e7f7f30948690c4352979cbc2122d90b0a22567f9f0bcbc33cc0f051
    has been stopped and removed                                           #6
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)At this point, we have the foundation of our orchestration system in place. We can create, run, stop, and remove containers, which provide the technical implementation of our `Task` concept. The other components in our system—namely, the `Worker` and `Manager`—will use this `Task` implementation to perform their necessary roles. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)

## [](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)Summary

-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)The task concept, and its technical implementation, is the fundamental unit of our orchestration system. All the other components—worker, manager, and scheduler—exist for the purpose of starting, stopping, and inspecting tasks.
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)The Docker API provides the ability to manipulate containers programmatically. The three most important methods are `ContainerCreate`, `ContainerStart`, and `ContainerStop`. These methods allow a developer to perform the same operations from their code that they can do from the command line (i.e., `docker` `run`, `docker` `start`, and `docker` `stop`).
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)A container has a configuration. The configuration can be broken down into the following categories: identification (i.e., how to identify containers), resource allocation, networking, and error handling.
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)A task is the smallest unit of work performed by our orchestration system and can be thought of as similar to running a program on your laptop or desktop.
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)We use Docker in this book because it abstracts away many of the concerns of the underlying operating system. We could implement our orchestration system to run tasks as regular operating system processes. Doing so, however, means our system would need to be intimately familiar with the details of how processes run across OSs (e.g., Linux, Mac, Windows).
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-3/)An orchestration system consists of multiple machines, called a cluster.

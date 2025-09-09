# [](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)2 From mental model to skeleton code

### This chapter covers

- Creating skeletons for task, worker, manager, and scheduler components
- Identifying the states of a task
- Using an interface to support different types of schedulers
- Writing a test program to verify that the code will compile and run

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)Once I have a mental model for a project, I like to translate that model into skeleton code. I do this quite frequently in my day job. It’s similar to how carpenters frame a house: they define the exterior walls and interior rooms with two-by-fours and add trusses to give the roof a shape. This frame isn’t the finished product, but it marks the boundaries of the structure, allowing others to come along and add details later in the construction.

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)In the same way, *skeleton code* provides the general shape and contours of the system I want to build. The final product may not conform exactly to this skeleton code. Bits and pieces may change, new pieces may be added or removed, and that’s okay. This typically allows me to start thinking about the implementation in a concrete way without getting too deep into the weeds just yet. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)If we look again at our mental model (figure 2.1), where should we start? You can see immediately that the three most obvious components are the *manager*, *worker*, and *scheduler*. The foundation of each of these components, however, is the *task*, so let’s start with it. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)

![Figure 2.1 The Cube mental model shows the manager, worker, and scheduler as the major components of the system.](https://drek4537l1klr.cloudfront.net/boring/Figures/02-01.png)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)For the rest of the chapter, we’ll be creating new files in our project directory. Take the time now to create the following directories and files:

```
.
├── main.go
├── manager
│   └── manager.go
├── node
│   └── node.go
├── scheduler
│   └── scheduler.go
├── task
│   └── task.go
└── worker
   └── worker.go
```

## [](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)2.1 The task skeleton

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)The first thing we want to think about is the states a task will go through during its life. First, a user submits a task to the system. At this point, the task has been enqueued but is waiting to be scheduled. Let’s call this initial state `Pending`. Once the system has figured out where to run the task, we can say it has been moved into a state of `Scheduled`. The `Scheduled` state means the system has determined there is a machine that can run the task, but it is in the process of sending the task to the selected machine, or the selected machine is in the process of starting the task. Next, if the selected machine successfully starts the task, it moves into the `Running` state. Upon a task completing its work successfully or being stopped by a user, the task moves into a state of `Completed`. If at any point the task crashes or stops working as expected, the task then moves into a state of `Failed`. Figure 2.2 shows this process. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)

![Figure 2.2 The states a task will go through during its life cycle](https://drek4537l1klr.cloudfront.net/boring/Figures/02-02.png)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)Now that we have identified the states of a task, let’s create the `State` type[](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/).

##### Listing 2.1 The `State` type

```
package task

type State int

const (
   Pending State = iota
   Scheduled
   Running
   Completed
   Failed
)
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)Next, we should identify other attributes of a task that would be useful for our system. Obviously, an `ID` would allow us to uniquely identify individual tasks, and we’ll use universally unique identifiers (UUID) for these. A human-readable `Name` would be good too because it means we can talk about `Tim’s` `awesome` `task` instead of task `74560f1a-b141-40ec-885a-64e4b36b9f9c`. With these, we can sketch the beginning of our `Task` struct. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)

##### [](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)What is a UUID?

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)UUID stands for *universally unique identifier*. A UUID is 128 bits long and, in practice, unique. While it’s not impossible to generate two identical UUIDs, the probability is extremely low. For more details about UUIDs, see RFC 4122 ([https://tools.ietf.org/ html/rfc4122](https://tools.ietf.org/html/rfc4122)).

##### Listing 2.2 The initial `Task` struct

```
import (
   “github.com/google/uuid”
)

type Task struct {
   ID      uuid.UUID
   Name    string
   State   State
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)Note that the `State` field is of type `State`, which we defined previously. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)We have already said we’re going to limit our orchestrator to dealing with Docker containers. As a result, we’ll want to know what Docker image a task should use, and for that, let’s use an attribute named `Image`. Given that our tasks will be Docker containers, there are several attributes that would be useful for a task to track. `Memory` and `Disk` will help the system identify the number of resources a task needs. `ExposedPorts` and `PortBindings` are used by Docker to ensure the machine allocates the proper network ports for the task and that it is available on the network. We’ll also want a `RestartPolicy` attribute, which will tell the system what to do in the event a task stops or fails unexpectedly. With these attributes, we can update our `Task` struct. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)

##### Listing 2.3 Updating our `Task` struct with Docker-specific fields

```
import (
   "github.com/google/uuid"
   "github.com/docker/go-connections/nat"
)

type Task struct {
   ID            uuid.UUID
   Name          string
   State         State
   Image         string
   Memory        int
   Disk          int
   ExposedPorts  nat.PortSet
   PortBindings  map[string]string
   RestartPolicy string
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)Finally, to know when a task starts and stops, we can add `StartTime` and `FinishTime` fields to our struct. While these aren’t strictly necessary, they are helpful to display in a command-line interface (CLI). With these two attributes, we can flesh out the remainder of our `Task` struct. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)

##### Listing 2.4 Adding `StartTime` and `FinishTime` fields to the `Task` struct

```
import(
   ...
   "time"
)

type Task struct {
   ID            uuid.UUID
   ContainerID   string
   Name          string
   State         State
   Image         string
   CPU           float64
   Memory        int64
   Disk          int64
   ExposedPorts  nat.PortSet
   PortBindings  map[string]string
   RestartPolicy string
   StartTime     time.Time
   FinishTime    time.Time
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)We have our `Task` struct defined, which represents a task that a user wants to run on our cluster. As I previously mentioned, a `Task` can be in one of several states: `Pending`, `Scheduled`, `Running`, `Failed`, or `Completed`. The `Task` struct works fine when a user first requests a task to be run, but how does a user tell the system to stop a task? For this purpose, let’s introduce the `TaskEvent` struct. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)To identify a `TaskEvent`, it will need an `ID`, and like our `Task`, this will be done using a UUID. The event will need a `State`, which will indicate the state the task should transition to (e.g., from `Running` to `Completed`). Next, the event will have a `Timestamp` to record the time the event was requested. Finally, the event will contain a `Task` struct. Users won’t directly interact with the `TaskEvent` struct. It will be an internal object that our system uses to trigger tasks from one state to another. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)

##### Listing 2.5 The `TaskEvent` struct

```
type TaskEvent struct {
   ID        uuid.UUID
   State     State
   Timestamp time.Time
   Task      Task
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)With our `Task` and `TaskEvent` structs defined, let’s move on to sketching the next component, the `Worker`. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)

## [](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)2.2 The worker skeleton

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)If we think of the *task* as the foundation of this orchestration system, then we can think of the *worker* as the next layer that sits atop the foundation. Let’s remind ourselves what the worker’s requirements are:[](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)

1.  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)Run tasks as Docker containers
1.  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)Accept tasks to run from a manager
1.  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)Provide relevant statistics to the manager for the purpose of scheduling tasks
1.  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)Keep track of its tasks and their state

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)Using the same process we used for defining the `Task` struct, let’s create the `Worker` struct. Given the first and fourth requirements, we know that our worker will need to run and keep track of tasks. To do that, the worker will use a field named `Db`, which will be a map of UUIDs to tasks. To meet the second requirement, accepting tasks from a manager, the worker will want a `Queue` field. Using a queue will ensure that tasks are handled in first-in, first-out (FIFO) order. We won’t be implementing our own queue, however; instead, we’ll use the `Queue` from `golang-collections`. We’ll also add a `TaskCount` field as a convenient way of keeping track of the number of tasks a worker has at any given time. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)In your project directory, create a subdirectory called `worker`, and then change to that directory. Now, open a file named `worker.go` and type in the code in the following listing. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)

##### Listing 2.6 The beginnings of the `Worker` struct

```
package worker

import (
   "fmt"
   "github.com/google/uuid"
   "github.com/golang-collections/collections/queue"

   "cube/task"
)

type Worker struct {
   Name      string
   Queue     queue.Queue
   Db        map[uuid.UUID]*task.Task
   TaskCount int
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)Note that by using a `map` for the `Db` field, we get the benefit of a datastore without having to worry about the complexities of an external database server or embedded database library. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)So we’ve identified the fields of our `Worker` struct. Now let’s add some methods that will do the actual work. First, we’ll give the struct a `RunTask` method. As its name suggests, it will handle running a task on the machine where the worker is running. Since a task can be in one of several states, the `RunTask` method will be responsible for identifying the task’s current state and then either starting or stopping a task based on the state. Next, let’s add a `StartTask` and a `StopTask` method, which will do exactly as their names suggest—start and stop tasks. Finally, let’s give our worker a `CollectStats` method, which can be used to periodically collect statistics about the worker. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)

##### Listing 2.7 The skeleton of the `Worker` component

```
func (w *Worker) CollectStats() {
   fmt.Println("I will collect stats")
}

func (w *Worker) RunTask() {
   fmt.Println("I will start or stop a task")
}

func (w *Worker) StartTask() {
   fmt.Println("I will start a task")
}

func (w *Worker) StopTask() {
   fmt.Println("I will stop a task")
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)Notice that each method simply prints out a line stating what it will do. Later in the book, we will revisit these methods to implement the real behavior represented by these statements. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)

## [](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)2.3 The manager skeleton

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)Along with the `Worker`, the `Manager` is the other major component of our orchestration system. It will handle the bulk of the work. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)As a reminder, here are the requirements for the manager we defined in chapter 1:

1.  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)Accept requests from users to start and stop tasks
1.  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)Schedule tasks onto worker machines
1.  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)Keep track of tasks, their states, and the machine on which they run

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)In the `manager.go` file, let’s create the struct named `Manager`. The `Manager` will have a queue, represented by the `pending` field, in which tasks will be placed upon first being submitted. The queue will allow the `Manager` to handle tasks on a FIFO basis. Next, the `Manager` will have two in-memory databases: one to store tasks and another to store task events. The databases are maps of strings to `Task` and `TaskEvent`, respectively. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)Our `Manager` will need to keep track of the workers in the cluster. For this, let’s use a field named, surprisingly, `workers`, which will be a slice of strings. Finally, let’s add a couple of convenience fields that will make our lives easier down the road. It’s easy to imagine that we’ll want to know the jobs that are assigned to each worker. We’ll use a field called `WorkerTaskMap`, which will be a map of strings to task UUIDs. Similarly, it’d be nice to have an easy way to find the worker running a task given a task name. Here we’ll use a field called `TaskWorkerMap`, which is a map of task UUIDs to strings, where the string is the name of the worker. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)

##### Listing 2.8 The beginnings of our `Manager` skeleton

```
package manager

import(
   "cube/task"
   "fmt"

   "github.com/golang-collections/collections/queue"
   "github.com/google/uuid"
)

type Manager struct {
   Pending       queue.Queue
   TaskDb        map[string][]*task.Task
   EventDb       map[string][]*task.TaskEvent
   Workers       []string
   WorkerTaskMap map[string][]uuid.UUID
   TaskWorkerMap map[uuid.UUID]string
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)From our requirements, you can see that the manager needs to schedule tasks onto workers. So let’s create a method on our `Manager` struct called `selectWorker` to perform that task. This method will be responsible for looking at the requirements specified in a `Task` and evaluating the resources available in the pool of workers to see which worker is best suited to run the task. Our requirements also say the `Manager` must keep track of tasks, their states, and the machine on which they run. To meet this requirement, create a method called `UpdateTasks`. Ultimately, this method will end up triggering a call to a worker’s `CollectStats` method, but more about that later in the book. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)Is our `Manager` skeleton missing anything? Ah, yes. So far, it can select a worker for a task and update existing tasks. There is another requirement that is implied in the requirements: the `Manager` obviously needs to send tasks to workers. Let’s add this to our requirements and create a method on our `Manager` struct.

##### Listing 2.9 Adding methods to the `Manager`

```
func (m *Manager) SelectWorker() {
   fmt.Println("I will select an appropriate worker")
}

func (m *Manager) UpdateTasks() {
   fmt.Println("I will update tasks")
}

func (m *Manager) SendWork() {
   fmt.Println("I will send work to workers")
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)Like the `Worker`’s methods, the `Manager`’s methods only print out what they will do. The work of implementing these methods’ actual behavior will come later. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)

## [](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)2.4 The scheduler skeleton

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)The last of the four major components of our mental model is the scheduler. Its requirements are as follows:[](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)

1.  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)Determine a set of candidate workers on which a task could run
1.  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)Score the candidate workers from best to worst
1.  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)Pick the worker with the best score

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)This skeleton, which we’ll create in the `scheduler.go` file, will be different from our previous ones. Instead of defining structs and the methods of those structs, we’re going to create an *interface*.

##### [](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)Interfaces in Go

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)Interfaces are the mechanism by which Go supports polymorphism. They are contracts that specify a set of behaviors, and any type that implements the behaviors can then be used anywhere that the interface type is specified.

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)For more details about interfaces, see the Interfaces and Other Types section of the *Effective Go* blog post at [http://mng.bz/j1n9](http://mng.bz/j1n9). [](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)Why an interface? As with everything in software engineering, tradeoffs are the norm. During my initial experiments with writing an orchestrator, I wanted a simple scheduler because I wanted to focus on other core features like running a task. For this purpose, my initial scheduler used a round-robin algorithm that kept a list of workers and identified which worker got the most recent task. Then, when the next task came in, the scheduler simply picked the next worker in its list.

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)While the round-robin scheduler worked for this particular situation, it obviously has flaws. What happens if the next worker to be assigned a task doesn’t have the available resources? Maybe the current tasks are using up all the memory and disk. Furthermore, I might want more flexibility in how tasks are assigned to workers. Maybe I’d want the scheduler to fill up one worker with tasks instead of spreading the tasks across multiple workers, where each worker could potentially only be running a single task. Conversely, maybe I’d want to spread out the tasks across the pool of resources to minimize the likelihood of resource starvation.

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)Thus, we’ll use an interface to specify the methods a type must implement to be considered a `Scheduler`. As you can see in the next listing, these methods are `SelectCandidateNodes`, `Score`, and `Pick`. Each of these methods map nicely onto the requirements for our scheduler. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)

##### Listing 2.10 The skeleton of the `Scheduler` component

```
package scheduler

type Scheduler interface {
   SelectCandidateNodes()
   Score()
   Pick()
}
```

## [](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)2.5 Other skeletons

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)At this point, we’ve created skeletons for the four primary objects we see in our mental model: `Task`, `Worker`, `Manager`, and `Scheduler`. There is, however, another object that is hinted at in this model, the `Node`. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)Up to now, we’ve talked about the `Worker`. The `Worker` is the component that deals with our logical workload (i.e., tasks). The `Worker` has a physical aspect to it, however, in that it runs on a physical machine itself, and it also causes tasks to run on a physical machine. Moreover, it needs to know about the underlying machine to gather stats about the machine that the manager will use for scheduling decisions. We’ll call this physical aspect of the `Worker` a `Node`.

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)In the context of Cube, a *node* is an object that represents any machine in our cluster. For example, the manager is one type of node in Cube. The worker, of which there can be more than one, is another type of node. The manager will make extensive use of node objects to represent workers.

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)For now, we’re only going to define the fields that make up a `Node` struct, as seen in listing 2.11. First, a node will have a `Name`, for example, something as simple as “node-1.” Next, a node will have an `Ip` address, which the manager will want to know in order to send tasks to it. A physical machine also has a certain amount of `Memory` and `Disk` space that tasks can use. These attributes represent maximum amounts. At any point in time, the tasks on a machine will be using some amount of memory and disk, which we can call `MemoryAllocated` and `DiskAllocated`. Finally, a `Node` will have zero or more tasks, which we can track using a `TaskCount` field. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)

##### Listing 2.11 The `Node` struct, representing a physical machine

```
package node

type Node struct {
   Name            string
   Ip              string
   Cores           int
   Memory          int
   MemoryAllocated int
   Disk            int
   DiskAllocated   int
   Role            string
   TaskCount       int
}
```

## [](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)2.6 Taking our skeletons for a spin

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)Now that we’ve created these skeletons, let’s see whether we can use them in a simple test program. We want to ensure that the code we just wrote will compile and run. To do this, we’re going to create instances of each of the skeletons, print the skeletons, and, finally, call each skeleton’s methods. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)The following list summarizes in more detail what our test program will do:

-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)Create a `Task` object
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)Create a `TaskEvent` object
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)Print the `Task` and `TaskEvent` objects
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)Create a `Worker` object
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)Print the `Worker` object
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)Call the worker’s methods
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)Create a `Manager` object
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)Call the manager’s methods
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)Create a `Node` object
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)Print the `Node` object

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)Before we write this program, however, let’s take care of a small administrative task that’s necessary to get our code to compile. Remember, we said we’re going to use the `Queue` implementation from the `golang-collections` package, and we’re also using the `UUID` package from Google. We’ve also used the `nat` package from Docker. While we have imported them into our code, we haven’t yet installed them locally. So let’s do that now. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)

##### Listing 2.12 Using the `go get` command to install the third-party packages

```bash
$ go get github.com/golang-collections/collections/queue
$ go get github.com/google/uuid
$ go get github.com/docker/go-connections/nat
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)Now we are ready to test our skeletons, which we’ll do in the following two listings.

##### Listing 2.13 Testing the skeletons with a minimal program: Part 1

```
package main

import (
   "cube/node"
   "cube/task"
   "fmt"
   "time"

   "github.com/golang-collections/collections/queue"
   "github.com/google/uuid"

   "cube/manager"
   "cube/worker"
)

func main() {
   t := task.Task{
       ID:     uuid.New(),
       Name:   "Task-1",
       State:  task.Pending,
       Image:  "Image-1",
       Memory: 1024,
       Disk:   1,
   }
```

##### Listing 2.14 Testing the skeletons with a minimal program: Part 2

```
te := task.TaskEvent{
       ID:        uuid.New(),
       State:     task.Pending,
       Timestamp: time.Now(),
       Task:      t,
   }

   fmt.Printf("task: %v\n", t)
   fmt.Printf("task event: %v\n", te)

   w := worker.Worker{
       Name: "worker-1",
       Queue: *queue.New(),
       Db:    make(map[uuid.UUID]*task.Task),
   }
   fmt.Printf("worker: %v\n", w)
   w.CollectStats()
   w.RunTask()
   w.StartTask()
   w.StopTask()

   m := manager.Manager{
       Pending: *queue.New(),
       TaskDb:  make(map[string][]task.Task),
       EventDb: make(map[string][]task.TaskEvent),
       Workers: []string{w.Name},
   }

   fmt.Printf("manager: %v\n", m)
   m.SelectWorker()
   m.UpdateTasks()
   m.SendWork()

   n := node.Node{
       Name:   "Node-1",
       Ip:     "192.168.1.1",
       Cores:  4,
       Memory: 1024,
       Disk:   25,
       Role:   "worker",
   }

   fmt.Printf("node: %v\n", n)
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)Now is the moment of truth! Time to compile and run our program. Do this using the `go` `run` `main.go` command, and you should see output like that in the following listing.

##### Listing 2.15 Testing the skeletons by running our minimal program

```bash
$ go run main.go                                                       #1
task: {389e41e6-95ca-4d48-8211-c2f4aca5127f Task-1 0 Image-1 1024 1
     map[] map[] 0001-01-01 00:00:00 +0000 UTC
     0001-01-01 00:00:00 +0000 UTC}                                  #2
task event: {69de4b79-9023-4099-9210-d5c0791a2c32 0 2021-04-10
     17:38:22.758451604 -0400 EDT m=+0.000186851
     {389e41e6-95ca-4d48-8211-c2f4aca5127f Task-1 0 Image-1 1024 1
     map[] map[]  0001-01-01 00:00:00 +0000 UTC
     0001-01-01 00:00:00 +0000 UTC}}                                 #3
worker: { {<nil> <nil> 0} map[] 0}                                     #4
I will collect stats                                                   #5
I will start or stop a task
I will start a task
I Will stop a task
manager: {{<nil> <nil> 0} map[] map[] [] map[] map[]}                  #6
I will select an appropriate worker                                    #7
I will update tasks
I will send work to workers
node: {Node-1 192.168.1.1 4 1024 0 25 0 worker 0}                      #8
#1 Compiling and running the program with go run
#2 The output from printing the Task
#3 The output from printing the TaskEvent
#4 The output from printing the Worker
#5 These four lines are output from calling the worker’s methods.
#6 The output from printing the Manager
#7 These three lines are output from calling the manager’s methods.
#8 The output from printing the Node
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)Congrats! You’ve just written the skeleton of an orchestration system that compiles and runs. Take a moment to celebrate. In the following chapters, we’ll use these skeletons as a starting point for more detailed discussions of each component before diving into the technical implementations. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)

## [](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)Summary

-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)The code for the Cube orchestrator is organized into separate subdirectories inside our project: `Manager`, `Node`, `Scheduler`, `Task`, and `Worker`.
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)Writing skeletons can help translate a mental model from an abstract concept into working code. Thus, we created skeletons for the `Task`, `Worker`, `Manager`, and `Scheduler` components of our orchestration system. This step also helped us identify additional concepts we didn’t initially think of. The `TaskEvent` and `Node` components were not represented in our model but will be useful later in the book.
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)We exercised our skeletons by writing a `main` program. While this program did not perform any operations, it did print messages to the terminal, allowing us to get a general idea of how things work.
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)A task can be in one of five states: `Pending`, `Scheduled`, `Running`, `Completed`, or `Failed`. The worker and manager will use these states to perform actions on tasks, such as stopping and starting them.
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)Go implements polymorphism by using interfaces. An interface is a type that specifies a set of behaviors, and any other type that implements those behaviors will be considered of the same type as the interface. Using an interface will allow us to implement multiple schedulers, each with slightly different behavior. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-2/)

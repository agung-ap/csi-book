# [](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)4 Workers of the Cube, unite!

### This chapter covers

- Reviewing the purpose of the worker component in an orchestration system
- Reviewing the `Task` and `Docker` structs
- Defining and implementing an algorithm for processing incoming tasks
- Building a simple state machine to transition tasks between states
- Implementing the worker’s methods for starting and stopping tasks

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)Think about running a web server that serves static pages. In many cases, running a single instance of our web server on a single physical or virtual machine is good enough. As the site grows in popularity, however, this setup poses several problems:

-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)*Resource availability*—Given the other processes running on the machine, is there enough memory, CPU, and disk space to meet the needs of our web server?
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)*Resilience*—If the machine running the web server goes down, our site goes down with it.

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)Running multiple instances of our web server helps us solve these problems.

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)In this chapter, we will focus on fleshing out the `Worker` skeleton sketched out in chapter 2. It will use the `Task` implementation we covered in chapter 3. At the end of the chapter, we’ll use our implementation of the worker to run multiple instances of a simple web server like that in our previously described scenario.

## [](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)4.1 The Cube worker

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)With an orchestration system, the worker component allows us to easily scale applications such as our web server in the previous scenario. Figure 4.1 shows how we could run three instances of our website, represented by the boxes `W1`, `W2`, and `W3`, with each instance running on a separate worker. In this diagram, it’s important to realize that the term `Worker` is doing double duty: it represents a physical or virtual machine and the worker component of the orchestration system that runs on that machine. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)

![Figure 4.1 The worker boxes serve double duty in this diagram. They represent a physical or virtual machine on which the Worker component of the orchestration system runs.](https://drek4537l1klr.cloudfront.net/boring/Figures/04-01.png)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)Now we’re less likely to experience resource availability issues. Because we’re running three instances of our site on three different workers, user requests can be spread across the three instances instead of going to a single instance running on a single machine.

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)Similarly, our site is now more resilient to failures. For example, if `Worker1` in figure 4.2 crashes, it will take the `W3` instance of our site with it. While this might make us sad and create some work for us to bring `Worker1` back online, the users of our site shouldn’t notice the difference. They’ll be able to continue making requests to our site and getting back the expected static content.

![Figure 4.2 In the scenario where a worker node fails, our web server running on the other nodes can still respond to requests.](https://drek4537l1klr.cloudfront.net/boring/Figures/04-02.png)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)The worker is composed of smaller pieces that perform specific roles. Those pieces, seen in figure 4.3, are an API, a runtime, a task queue, a task database (DB), and metrics. In this chapter, we’re going to focus only on three of these components: the runtime, the task queue, and the task DB. We’ll work with the other two components in the following chapters. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)

![Figure 4.3 Our worker will be made up of these five components, but this chapter will focus only on the runtime, task queue, and task DB.](https://drek4537l1klr.cloudfront.net/boring/Figures/04-03.png)

## [](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)4.2 Tasks and Docker

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)In chapter 1, we said a *task* is the smallest unit of work in an orchestration system. Then, in chapter 3, we implemented that definition in the `Task` struct, which we can see again in listing 4.1. This struct is the primary focus of the worker. It receives a task from the manager and then runs it. We’ll use this struct throughout this chapter. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)As the smallest unit of work, a task performs its work by being run as a Docker container. So there is a one-to-one correlation between a task and a container. The worker uses this struct to start and stop tasks.

##### Listing 4.1 `Task` struct defined in chapter 2

```
type Task struct {
   ID            uuid.UUID
   ContainerID   string
   Name          string
   State         State
   Image         string
   Memory        int64
   Disk          int64
   ExposedPorts  nat.PortSet
   PortBindings  map[string]string
   RestartPolicy string
   StartTime     time.Time
   FinishTime    time.Time
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)In chapter 3, we also defined the `Docker` struct seen in the following listing. The worker will use this struct to start and stop the tasks as Docker containers. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)

##### Listing 4.2 `Docker` struct defined in chapter 3

```bash
type Docker struct {
   Client      *client.Client
   Config      Config
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)The two objects will be the core of the process that will allow our worker to start and stop tasks.

## [](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)4.3 The role of the queue

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)Take a peek at listing 4.3 to remind yourself what the `Worker` struct looks like. The struct is in the same state in which we left it in chapter 2. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)The worker will use the `Queue` field in the `Worker` struct as a temporary holding area for incoming tasks that need to be processed. When the manager sends a task to the worker, the task lands in the queue, which the worker will process on a first in, first out basis. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)

##### Listing 4.3 Worker skeleton from chapter 2

```
package worker


import (
   "fmt"

   "github.com/google/uuid"
   "github.com/golang-collections/collections/queue"
)


type Worker struct {
   Name      string
   Queue     queue.Queue
   Db        map[uuid.UUID]*task.Task
   TaskCount int
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)It’s important to note that the `Queue` field is itself a struct, which defines several methods we can use to push items onto the queue (`Enqueue`), pop items off of the queue (`Dequeue`), and get the length of the queue (`Len`). The `Queue` field is an example of *composition* in Go. Thus, we can use other structs to compose new, higher-level objects. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)Also notice that `Queue` is being imported from the `github.com/golang-collections/collections/queue` package. So we’re reusing a `Queue` implementation that someone else has written for us. If you haven’t done so already, you’ll need to specify this package as a dependency (see the appendix). [](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)

## [](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)4.4 The role of the DB

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)The worker will use the `Db` field to store the state about its tasks. This field is a `map`, where keys are of type `uuid.UUID` from the `github.com/google/uuid` package and values are of type `task` from our `task` package. There is one thing to note about using a map for the `Db` field. We’re starting with a map here out of convenience. This will allow us to write working code quickly. But this comes with a tradeoff: anytime we restart the worker, we will lose data. This tradeoff is acceptable for the purpose of getting started, but later we’ll replace this map with a persistent data store that won’t lose data when we restart the worker. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)

## [](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)4.5 Counting tasks

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)Finally, the `TaskCount` field provides a simple count of the tasks the worker has been assigned. We won’t make use of this field until the next chapter. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)

## [](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)4.6 Implementing the worker’s methods

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)Now that we’ve reviewed the fields in our `Worker` struct, let’s move on and talk about the methods that we stubbed out in chapter 2. The `RunTask`, `StartTask`, and `StopTask` methods seen in the next listing don’t do much right now other than print out a statement, but by the end of the chapter, we will have fully implemented each of them. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)

##### Listing 4.4 The stubbed-out versions of `RunTask`, `StartTask`, and `StopTask`

```
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

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)We’re going to implement these methods in reverse order from what you see in listing 4.4. The reason for implementing them in this order is that the `RunTask` method will use the other two methods to start and stop tasks.

### [](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)4.6.1 Implementing the StopTask method

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)There is nothing complicated about the `StopTask` method. It has a single purpose: to stop running tasks, remembering that a task corresponds to a running container. The implementation, seen in listing 4.5, can be summarized as the following set of steps:[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)

1.  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)Create an instance of the `Docker` struct that allows us to talk to the Docker daemon using the Docker SDK. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)
1.  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)Call the `Stop()` method on the `Docker` struct. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)
1.  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)Check whether there were any errors in stopping the task.
1.  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)Update the `FinishTime` field on the task `t`.
1.  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)Save the updated task `t` to the worker’s `Db` field.
1.  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)Print an informative message and return the result of the operation.

##### Listing 4.5 Our implementation of the `StopTask` method

```
func (w *Worker) StopTask(t task.Task) task.DockerResult {
    config := task.NewConfig(&t)
    d := task.NewDocker(config)
 
    result := d.Stop(t.ContainerID)
    if result.Error != nil {
        log.Printf("Error stopping container %v: %v\n", t.ContainerID,
             result.Error)
    }
    t.FinishTime = time.Now().UTC()
    t.State = task.Completed
    w.Db[t.ID] = &t
    log.Printf("Stopped and removed container %v for task %v\n",
         t.ContainerID, t.ID)
 
    return result
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)Notice that the `StopTask` method returns a `task.DockerResult` type. The definition of that type can be seen in listing 4.6. If you remember, Go supports multiple return types. We could have enumerated each field in the `DockerResult` struct as a return type to the `StopTask` method. While there is nothing technically wrong with that approach, using the `DockerResult` approach allows us to wrap all the bits related to the outcome of an operation into a single struct. When we want to know anything about the result of an operation, we simply consult the `DockerResult` struct. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)

##### Listing 4.6 A reminder of what the `DockerResult` type looks like

```
type DockerResult struct {
   Error       error
   Action      string
   ContainerId string
   Result      string
}
```

### [](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)4.6.2 Implementing the StartTask method

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)Next, let’s implement the `StartTask` method. Similar to the `StopTask` method, `StartTask` is fairly simple, but the process to start a task has a few more steps. The enumerated steps are as follows:[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)

1.  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)Update the `StartTime` field on the task `t`.
1.  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)Create an instance of the `Docker` struct to talk to the Docker daemon. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)
1.  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)Call the `Run()` method on the `Docker` struct. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)
1.  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)Check whether there were any errors in starting the task.
1.  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)Add the running container’s ID to the tasks `t.Runtime.ContainerId` field.
1.  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)Save the updated task `t` to the worker’s `Db` field.
1.  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)Return the result of the operation.

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)The implementation of these steps can be seen in the following listing.

##### Listing 4.7 Our implementation of the `StartTask` method

```
func (w *Worker) StartTask(t task.Task) task.DockerResult {
   t.StartTime = time.Now().UTC()
   config := task.NewConfig(&t)
   d := task.NewDocker(config)
   result := d.Run()
   if result.Error != nil {
       log.Printf("Err running task %v: %v\n", t.ID, result.Error)
       t.State = task.Failed
       w.Db[t.ID] = &t
       return result
   }

   t.ContainerID = result.ContainerId
   t.State = task.Running
   w.Db[t.ID] = &t

   return result
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)By recording the `StartTime` in the `StartTask` method, combined with recording `FinishTime` in the `StopTask` method, we’ll later be able to use these timestamps in other output. For example, later in the book, we’ll write a command-line interface that allows us to interact with our orchestrator, and the `StartTime` and `FinishTime` values can be output as part of a task’s status. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)Before we move on from these two methods, I want to point out that neither of them interact directly with the Docker SDK. Instead, they simply call the `Run` and `Stop` methods on the `Docker` object we created. It is the `Docker` object that handles the direct interaction with the Docker client. By encapsulating the interaction with Docker in the `Docker` object, our worker does not need to know anything about the underlying implementation details. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)The `StartTask` and `StopTask` methods are the foundation of our worker. But looking at the skeleton we created in chapter 2, we see there is another foundational method missing. How do we add a task to the worker? Remember, we said the worker would use its `Queue` field as a temporary storage for incoming tasks, and when it was ready, it would pop a task of the queue and perform the necessary operation. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)Let’s fix this problem by adding the `AddTask` method seen in the next listing. This method performs a single task: it adds the task `t` to the `Queue`. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)

##### Listing 4.8 The worker’s `AddTask` method

```
func (w *Worker) AddTask(t task.Task) {
   w.Queue.Enqueue(t)
}
```

### [](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)4.6.3 An interlude on task state

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)All that’s left to do now is to implement the `RunTask` method. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/) Before we do that, however, let’s pause for a moment and recall the purpose of the `RunTask` method. In chapter 2, we said the `RunTask` method will be responsible for identifying the task’s current state and then either starting or stopping a task based on the state. But why do we even need `RunTask`?[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)There are two possible scenarios for handling tasks:

-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)A task is being submitted for the first time, so the worker will not know about it.
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)A task is being submitted for the *n_th* time, where the task submitted represents the *desired* state to which the *current* task should transition.

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)When processing the tasks it receives from the manager, the worker will need to determine which of these scenarios it is dealing with. We’re going to use a naive heuristic to help the worker solve this problem.

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)Remember that our worker has the `Queue` and `Db` fields. For our naive implementation, the worker will use the `Queue` field to represent the desired state of a task. When the worker pops a task off the queue, it will interpret it as “put task *t* in the state *s*.” The worker will interpret tasks it already has in its `Db` field as existing tasks—that is, tasks it has already seen at least once. If a task is in the `Queue` but not the `Db`, then this is the first time the worker is seeing the task, and we default to starting it. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)In addition to identifying which of the two scenarios it is dealing with, the worker will also need to verify if the transition from the current state to the desired state is a valid one.

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)Let’s review the states we defined in chapter 2. The next listing shows that we have states `Pending`, `Scheduled`, `Running`, `Completed`, and `Failed`. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)

##### Listing 4.9 The `State` type, which defines the valid states for a task

```
const (
   Pending State = iota
   Scheduled
   Running
   Completed
   Failed
)
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)But what do these states represent? We explained these states in chapter 2, but let’s do a quick refresher:[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)

-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)*Pending*—This is the initial state, the starting point, for every task.
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)*Scheduled*—A task moves to this state once the manager has scheduled it onto a worker.
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)*Running*—A task moves to this state when a worker successfully starts the task (i.e., starts the container).
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)*Completed*—A task moves to this state when it completes its work in a normal way (i.e., it does not fail).
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)*Failed*—If a task fails, it moves to this state.

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)To reinforce what these states represent, we can also recall the state diagram from chapter 2, seen here in figure 4.4.

![Figure 4.4 The states a task will go through during its life cycle](https://drek4537l1klr.cloudfront.net/boring/Figures/04-04.png)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)So we’ve defined what the states mean as they relate to a task, but we still haven’t defined *how* a task transitions from one state to the next. Nor have we talked about what transitions are valid. For example, if a worker is already running a task, which means it’s in the `Running` state, can it transition to the `Scheduled` state? If a task has failed, should it be able to transition from the `Failed` state to the `Scheduled` state?[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)So before getting back to the `RunTask` method, it looks like we need to figure out this issue of how to handle state transitions. To do this, we can model our states and transitions using the state table seen in table 4.1. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)This table has three columns that represent the `CurrentState` of a task, an `Event` that triggers a state transition, and the `NextState` to which the task should transition. Each row in the table represents a specific *valid* transition. Notice that there is not a transition from `Running` to `Scheduled`, or from `Failed` to `Scheduled`. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)

##### [](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)Table 4.1 State transition table showing the valid transitions from one state to another[(view table figure)](https://drek4537l1klr.cloudfront.net/boring/HighResolutionFigures/table_4-1.png)

| [](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)CurrentState | [](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)Event | [](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)NextState |
| --- | --- | --- |
| [](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)Pending | [](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)ScheduleEvent | [](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)Scheduled |
| [](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)Pending | [](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)ScheduleEvent | [](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)Failed |
| [](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)Scheduled | [](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)StartTask | [](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)Running |
| [](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)Scheduled | [](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)StartTask | [](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)Failed |
| [](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)Running | [](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)StopTask | [](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)Completed |

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)Now that we have a better understanding of the states and transitions between them, we can translate our understanding into code. Orchestrators like Borg, Kubernetes, and Nomad use a state machine to deal with the issue of state transitions. However, to keep the number of concepts and technologies we have to deal with to a minimum, we’re going to hard-code our state transitions into the `stateTransitionMap` type you see in listing 4.10. This map encodes the transitions we identified in table 4.1. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)The `stateTransitionMap` creates a map between a `State` and a slice of states, `[]State`. Thus, the keys in this map are the current state, and the values are the valid transition states. For example, the `Pending` state can only transition to the `Scheduled` state. The `Scheduled` state, however, can transition to `Running`, `Completed`, or `Failed`. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)

##### Listing 4.10 The `stateTransitionMap` map

```
var stateTransitionMap = map[State][]State{
   Pending:   []State{Scheduled},
   Scheduled: []State{Scheduled, Running, Failed},
   Running:   []State{Running, Completed, Failed},
   Completed: []State{},
   Failed:    []State{},
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)In addition to `stateTransitionMap`, we’re going to implement the `Contains` and `ValidStateTransition` helper functions, seen in listing 4.11. These functions will perform the actual logic to verify that a task can transition from one state to the next. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)Let’s start with the `Contains` function. It takes two arguments: `states`, a slice of type `State`, and `state` of type `State`. If it finds `state` in the slice of `states`, it returns `true`; otherwise, it returns `false`. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)The `ValidStateTransition` function is a wrapper around the `Contains` function. It provides a convenient way for callers of the function to ask, “Hey, can a task transition from this state to that state?” All the heavy lifting is done by the `Contains` function. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)You should add the code in the following listing to the `state.go` file in the `task` directory of your project.

##### Listing 4.11 Helper methods

```
func Contains(states []State, state State) bool {
   for _, s := range states {
       if s == state {
           return true
       }
   }
   return false
}

func ValidStateTransition(src State, dst State) bool {
   return Contains(stateTransitionMap[src], dst)
}
```

### [](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)4.6.4 Implementing the RunTask method

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)Now we can finally talk more specifically about the `RunTask` method. It took us a while to get here, but we needed to iron out those other details before it even made sense to discuss this method. And because we did that leg work, implementing the `RunTask` method will go a bit more smoothly. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)As we said earlier in the chapter, the `RunTask` method will identify the task’s current state and then either start or stop it based on that state. We can use a fairly naive algorithm to determine whether the worker should start or stop a task. It looks like this:[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)

1.  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)Pull a task off the queue.
1.  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)Convert it from an interface to a `task.Task` type. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)
1.  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)Retrieve the task from the worker’s `Db`.
1.  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)Check whether the state transition is valid.
1.  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)If the task from the queue is in the state `Scheduled`, call `StartTask`.
1.  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)If the task from the queue is in the state `Completed`, call `StopTask`.
1.  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)Else, there is an invalid transition, so return an error.

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)All that’s left to do now is to implement these steps in our code, which can be seen in the following listing.

##### Listing 4.12 Our implementation of the `RunTask` method

```
func (w *Worker) RunTask() task.DockerResult {
    t := w.Queue.Dequeue()                                #1
    if t == nil {
        log.Println("No tasks in the queue")
        return task.DockerResult{Error: nil}
    }
 
    taskQueued := t.(task.Task)                           #2
 
    taskPersisted := w.Db[taskQueued.ID]                  #3
    if taskPersisted == nil {
        taskPersisted = &taskQueued
        w.Db[taskQueued.ID] = &taskQueued
    }
 
    var result task.DockerResult
    if task.ValidStateTransition(
         taskPersisted.State, taskQueued.State) {
        switch taskQueued.State {
        case task.Scheduled:
            result = w.StartTask(taskQueued)             #4
        case task.Completed:
            result = w.StopTask(taskQueued)              #5
        default:
            result.Error = errors.New("We should not get here")
        }
    } else {
        err := fmt.Errorf("Invalid transition from %v to %v",
             taskPersisted.State, taskQueued.State)
        result.Error = err                               #6
    }
    return result                                        #7
}
#1 Calls the Dequeue() method
#2 Converts the task to the proper type
#3 Attempts to retrieve the same task from the Db
#4 If there is a valid state transition and a task from the queue has a state of Scheduled, calls the StartTask method
#5 If the task from the queue has a state of Completed, calls the StopTask method
#6 If there is no valid transition, sets the Error field of the result variable
#7 Returns the result
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)We start by calling the `Dequeue()` method to pop a task off the worker’s queue. Notice that we’re checking whether we received a task from the queue. If we didn’t, which means the queue was empty, then we log a message and return a result with a nil `Error` field. Next, we have to convert the task we popped off the queue to the proper type, which is `task.Task`. This step is necessary because the `Queue`’s `Dequeue` method returns an interface type. Now we have a task from the queue, so we need to attempt to get the same task from the `Db`. If we don’t find the task in the `Db`, it means this is the first time we’re seeing the task, and we add it. Then we get to use the `ValidStateTransition` function we created earlier in the chapter. Notice that we’re passing the state from the `Db`, `taskPersisted.State`, and the state from the `Queue`, `taskQueued.State`. If there is a valid state transition and a task from the queue has a state of `Scheduled`, then we call the `StartTask` method. Or if there is a valid state transition but the task from the queue has a state of `Completed`, we call the `StopTask` method. If there isn’t a valid transition—in other words, transitioning from `taskPersisted.State` to `taskQueued.State` is not valid—then we set the `Error` field of the `result` variable. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)

## [](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)4.7 Putting it all together

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)Whew, we’ve made it. We covered a lot of territory in implementing the methods for our worker. If you remember chapter 3, we ended by writing a program that used the work we did earlier in the chapter. We’re going to continue that practice in this chapter. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)Before we do, however, remember that in chapter 3, we built out the `Task` and `Docker` structs, and that work allowed us to start and stop containers. The work we did in this chapter sits on top of the work from the last chapter. So once again, we’re going to write a program that will start and stop tasks. The worker operates on the level of the `Task`, and the `Docker` struct operates on the lower level of the container. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)Now let’s write a program to pull everything together into a functioning worker. You can either comment out the code from the `main.go` file you used in the last chapter or create a new `main.go` file to use for this chapter.

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)The program is simple. We create a worker `w`, which has the `Queue` and `Db` fields as we talked about at the beginning of the chapter. Next, we create a task `t`. This task starts with a state of `Scheduled`, and it uses a Docker image named `strm/helloworld-http`. More about this image in a bit. After creating a worker and a task, we call the worker’s `AddTask` method and pass it task `t`. Then it calls the worker’s `RunTask` method. This method will pull the task `t` off the queue and do the right thing. It captures the return value from the `RunTask` method and stores it in the variable `result`. (Bonus points if you remember what type is returned from `RunTask`.) [](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)At this point, we have a running container. After sleeping for 30 seconds (feel free to change the sleep time to whatever you want), we start the process of stopping the task. We change the task’s state to `Completed`, call `AddTask` again and pass it the same task, and finally call `RunTask` again. This time, when `RunTask` pulls the task off the queue, the task will have a container ID and a different state. As a result, the task gets stopped. The following listing shows our program to create a worker, add a task, start it, and finally stop it.

##### Listing 4.13 Pulling everything together into a functioning worker

```
// previous code not shown

func main() {
   db := make(map[uuid.UUID]*task.Task)
   w := worker.Worker{
       Queue: *queue.New(),
       Db:    db,
   }

   t := task.Task{
       ID:    uuid.New(),
       Name:  "test-container-1",
       State: task.Scheduled,
       Image: "strm/helloworld-http",
   }

   // first time the worker will see the task
   fmt.Println("starting task")
   w.AddTask(t)
   result := w.RunTask()
   if result.Error != nil {
       panic(result.Error)
   }

   t.ContainerID = result.ContainerId
   fmt.Printf("task %s is running in container %s\n", t.ID, t.ContainerID)
   fmt.Println("Sleepy time")
   time.Sleep(time.Second * 30)

   fmt.Printf("stopping task %s\n", t.ID)
   t.State = task.Completed
   w.AddTask(t)
   result = w.RunTask()
   if result.Error != nil {
       panic(result.Error)
   }
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)Let’s pause for a moment and talk about the image used in the previous code listing. At the beginning of the chapter, we talked about the scenario of scaling a static website using an orchestrator, specifically the worker component. This image, `strm/ helloworld-http` provides a concrete example of a static website: it runs a web server that serves a single file. To verify this behavior, when you run the program, type the `docker` `ps` command in a separate terminal. You should see output similar to listing 4.14. In that output, you can find the port the web server is running on by looking at the `PORTS` column. Then open your browser and type `localhost:<port>`. In the case of the output in the following listing, I would type `localhost:49161` in my browser. The output has been truncated to make it more readable. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)

##### Listing 4.14 Truncated output from the `docker ps` command

```bash
$ docker ps
CONTAINER ID  IMAGE                 PORTS                  NAMES
4723a4201829  strm/helloworld-http  0.0.0.0:49161->80/tcp  test-container-1
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)When I browse to the server on my machine, I see “Hello from 90566e236f88”. Go ahead and run the program. You should see output similar to the following listing.

##### Listing 4.15 Running your main program

```bash
$ go run main.go
starting task
{"status":"Pulling from strm/helloworld-http","id":"latest"}
{"status":"Digest:
     sha256:bd44b0ca80c26b5eba984bf498a9c3bab0eb1c59d30d8df
     cb2c073937ee4e45"}
{"status":"Status: Image is up to date for strm/helloworld-http:latest"}
task bfe7d381-e56b-4c4d-acaf-cbf47353a30a is running in
     container e13af1f4b9cbac6f871d1d343ea8f7958dae5f1897954bf6
     b4a2c58ad7520dcb
Sleepy time
stopping task bfe7d381-e56b-4c4d-acaf-cbf47353a30a
2021/08/08 21:13:09 Attempting to stop container
     e13af1f4b9cbac6f871d1d343ea8f7958dae5f1897954bf6b4a2c58ad7520dcb
2021/08/08 21:13:19 Stopped and removed container
     e13af1f4b9cbac6f871d1d343ea8f7958dae5f1897954bf6b4a2c58ad7520dcb
     for task bfe7d381-e56b-4c4d-acaf-cbf47353a30a
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)Congratulations! You now have a functional worker. Before moving on to the next chapter, play around with what you’ve built. In particular, modify the `main` function from listing 4.13 to create multiple workers, and then add tasks to each them. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)

## [](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)Summary

-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)Tasks are executed as containers, meaning there is a one-to-one relationship between a task and a container.
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)The worker performs two basic actions on tasks, either starting or stopping them. These actions result in tasks transitioning from one state to the next valid state.
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)The worker shows how the Go language supports object composition. The worker itself is a composition of other objects; in particular, the worker’s `Queue` field is a struct defined in the `github.com/golang-collections/collections/ queue` package
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)The worker, as we’ve designed and implemented it, is simple. We’ve used clear and concise processes that are easy to implement in code.
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)The worker does not interact directly with the Docker SDK. Instead, it uses our `Docker` struct, which is a wrapper around the SDK. By encapsulating the interaction with the SDK in the `Docker` struct, we can keep the `StartTask` and `StopTask` methods small and readable. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-4/)

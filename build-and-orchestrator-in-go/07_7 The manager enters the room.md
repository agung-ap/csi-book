# [](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)7 The manager enters the room

### This chapter covers

- Reviewing the purpose of the manager
- Designing a naive scheduling algorithm
- Implementing the manager’s methods for scheduling and updating tasks

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)In chapters 4, 5, and 6, we implemented the `Worker` component of Cube, our orchestration system. We focused on the core functionality of the worker in chapter 4, which enabled the worker to start and stop tasks. In chapter 5, we added an API to the worker. This API wrapped the functionality we built in chapter 4 and made it available from standard HTTP clients (e.g., `curl`). And finally, in chapter 6, we added the ability for our worker to collect metrics about itself and expose those on the same API. With this work, we can run multiple workers, with each worker running multiple tasks. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)Now, we’ll move our attention to the `Manager` component of Cube. As we mentioned in chapter 1, the manager is the brain of an orchestrator. While we have multiple workers, we wouldn’t want to ask the users of our orchestration system to submit their tasks directly to a worker. Why? This would place an unnecessary burden on users, forcing them to be aware of how many workers existed and how many tasks they were already running and to then pick one. Instead, we encapsulate all of that administrative work into the manager. The users submit their tasks to the manager, and it figures out which worker in the system can best handle the task. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)Unlike workers, the Cube orchestrator will have a single manager. This is a practical design decision meant to simplify the number of problems we need to consider in our manager implementation.

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)By the end of this chapter, we will have implemented a manager that can submit tasks to workers, using a naive round-robin scheduling algorithm.

## [](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)7.1 The Cube manager

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)The manager component allows us to isolate administrative concerns from execution concerns. This is a design principle known as *separation of concerns*. *Administrative* concerns in an orchestration system (figure 7.1) include things like the following:[](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)

-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)Handling requests from users
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)Assigning tasks to workers who are best able to perform them (i.e., scheduling)
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)Keeping track of task and worker state
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)Restarting failed tasks

![Figure 7.1 The manager is responsible for administrative tasks, similar to the function of a restaurant host seating customers. It will use the worker’s /tasks and /stats API endpoints to perform its administrative duties.](https://drek4537l1klr.cloudfront.net/boring/Figures/07-01.png)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)Every orchestration system has a manager component. Google’s Borg calls it the *BorgMaster*[](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/). HashiCorp’s Nomad uses the unimaginative yet functional term *server*. Kubernetes doesn’t have a singular name for this component, but instead specifically identifies the subcomponents (API server, controller manager, etcd, scheduler).

##### [](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)Control plane vs. data plane

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)Another way to think of the separation of concerns is the concept of *control plane* *versus* *data plane*. In the world of networking, you’ll find these terms used frequently, and they refer to the plane of existence. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)In a network, the control plane *controls* how data moves from point A to point B. This plane is responsible for things like creating routing tables, which are determined by different protocols, such as the Border Gateway Protocol (BGP) and the Open Shortest Path First (OSPF) protocol. This plane performs functions similar to the administrative concerns of our manager. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)Unlike the control plane, the data plane does the actual work of moving the data around. This plane performs functions similar to the execution concerns of our worker.

### [](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)7.1.1 The components that make up the manager

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)Like our worker, our manager will comprise several subcomponents, as seen in figure 7.2. The manager will have a `Task` `DB`, which, like the worker, will store tasks. In contrast to the worker’s `Task` `DB`, however, the manager’s will contain all tasks in the system. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)

![Figure 7.2 The manager’s components are similar to the worker’s, with the addition of an Event DB and a list of Workers.](https://drek4537l1klr.cloudfront.net/boring/Figures/07-02.png)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)The manager will also have an `Event` `DB`, which will store events (i.e., `task.TaskEvent`). This subcomponent is mostly a convenient way for us to separate metadata from task-specific data. Metadata includes things like the timestamp when a user submitted a task to the system. We’ll make use of it later in chapter 12 when we implement a CLI for the manager. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)Like the worker, for the initial implementation of the manager, we’re going to use an in-memory map to store tasks and events. The manager’s `Workers` subcomponent is a list of the workers it manages. Like the worker, it will also have a `Task` `Queue`. And finally, the manager will have an `API`, similar to the worker (figure 7.2). (As we did with the worker, we’re going to address the manager’s API in a separate chapter, so we’ll defer further discussion of it until then.) [](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)With this foundation laid, we can move on to implementation. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)

## [](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)7.2 The Manager struct

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)Like the worker, we created a skeleton of the manager implementation in chapter 2. At the core of that manager skeleton is the `Manager` struct, which will contain fields that represent the subcomponents previously identified. You can see this struct in listing 7.1, which should be in the same state we left it in chapter 2. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)Since it has been a while, let’s remind ourselves of the requirements for our manager. In chapter 1, we identified these requirements:

1.  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)Accepts requests from users to start and stop tasks
1.  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)Schedules tasks onto worker machines
1.  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)Keeps track of tasks, their states, and the machine on which they run

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)If you need more of a reminder about the `Manager` struct and its field, please look back at section 2.3.

##### Listing 7.1 The `Manager` struct

```
package manager

import (
   "bytes"
   "cube/task"
   "cube/worker"
   "encoding/json"
   "fmt"
   "log"
   "net/http"

   "github.com/golang-collections/collections/queue"
   "github.com/google/uuid"
)

type Manager struct {
   Pending       queue.Queue
   TaskDb        map[uuid.UUID]*task.Task
   EventDb       map[uuid.UUID]*task.TaskEvent
   Workers       []string
   WorkerTaskMap map[string][]uuid.UUID
   TaskWorkerMap map[uuid.UUID]string
}
```

## [](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)7.3 Implementing the manager’s methods

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)Now that we’ve reminded ourselves of what the `Manager` struct looks like, let’s move forward and remember what skeleton methods we had previously defined on the struct. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)

##### Listing 7.2 The stubbed-out versions of the manager’s methods

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

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)We’re going to implement these methods in the following order:

-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)`SelectWorker`
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)`SendWork`
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)`UpdateTasks`

### [](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)7.3.1 Implementing the SelectWorker method

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)The `SelectWorker` method will serve as the scheduler in this early phase of implementing our manager. Its sole purpose will be to pick one of the workers from the manager’s list of workers (i.e., the `Workers` field, which is a slice of strings). We’re going to start with a naive round-robin scheduling algorithm that begins by simply selecting the first worker from the list of `Workers` and storing it in a variable. From this point forward, the algorithm looks like so:[](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)

1.  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)Check whether we are at the end of the `Workers` list.
1.  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)If we are not, select the next worker in the list.
1.  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)Else, return to the beginning and select the first worker in the list.

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)To implement this algorithm, we need to make a minor change to the `Manager` struct. As you can see in the following listing, we’ve added the field `LastWorker`. We’ll use this field to store an integer, which will be an index into the `Workers` slice, thus giving us a worker.

##### Listing 7.3 Adding the `LastWorker` field to the `Manager` struct

```
type Manager struct {
   // previous fields omitted
   LastWorker    int
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)Let’s move on now to the actual scheduling algorithm. As you can see in listing 7.4, it’s only nine lines of code (not counting the method signature). We start the process by declaring the variable `newWorker`, which represents the lucky worker chosen to run a task. Then we use an `if`/`else` block to choose the worker. In this block, we first check whether the worker we chose during the last run is the last worker in our list of workers. If not, we set `newWorker` to the next worker in the list of workers, and we increment the value of `LastWorker` by `1`. If the previous worker chosen is the last one in our list, we start over from the beginning, selecting the first worker in the list and setting `LastWorker` accordingly. Finally, we return the worker to the caller.

##### Listing 7.4 Implementing a naive scheduling algorithm

```
func (m *Manager) SelectWorker() string {
    var newWorker int                         #1
    if m.LastWorker+1 < len(m.Workers) {      #2
        newWorker = m.LastWorker + 1          #3
        m.LastWorker++                        #4
    } else {                                  #5
        newWorker = 0                         #6
        m.LastWorker = 0                      #7
    }
 
    return m.Workers[newWorker]               #8
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)It’s worth taking a moment to talk about the format of the strings stored in the manager’s `Workers` field. The field itself is of type `[]string`, so technically, the value of the strings could be anything. In practice, however, these are going to take the form of `<hostname>:<port>`. If you recall from chapters 5 and 6, when we started the worker’s API, we specified the `CUBE_HOST` and `CUBE_PORT` environment variables. The former we set to `localhost`, and the latter we set to `5555`. So the manager’s `Workers` field contains a list of `<hostname>:<port>` values, which specify the address where the worker’s API is running. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)

### [](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)7.3.2 Implementing the SendWork method

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)The next method we need to implement is the manager’s `SendWork` method. It is the workhorse of the manager and performs the following process:[](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)

1.  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)Checks whether there are task events in the `Pending` queue
1.  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)If there are, selects a worker to run a task
1.  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)Pulls a task event off the pending queue
1.  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)Sets the state of the task to `Scheduled`
1.  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)Performs some administrative work that makes it easy for the manager to keep track of which workers tasks are running on
1.  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)JSON-encodes the task event
1.  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)Sends the task event to the selected worker
1.  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)Checks the response from the worker

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)Let’s implement steps 1 to 6 in the process with the code in listing 7.5. We use an `if`/`else` block that sets up our conditional flow: it checks the length of the manager’s `Pending` queue, and if the length is greater than zero—meaning there are tasks to process—it moves on to the next steps.

##### Listing 7.5 The manager’s `SendWork` method

```
func (m *Manager) SendWork() {
    if m.Pending.Len() > 0 {
        w := m.SelectWorker()                                         #1
 
        e := m.Pending.Dequeue()
        te := e.(task.TaskEvent)                                      #2
        t := te.Task
        log.Printf("Pulled %v off pending queue\n", t)
 
        m.EventDb[te.ID] = &te                                        #3
        m.WorkerTaskMap[w] = append(m.WorkerTaskMap[w], te.Task.ID)   #4
        m.TaskWorkerMap[t.ID] = w                                     #5
 
        t.State = task.Scheduled
        m.TaskDb[t.ID] = &t
 
        data, err := json.Marshal(te)                                 #6
        if err != nil {
            log.Printf("Unable to marshal task object: %v.\n", t)
        }
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)Once the `SendWork` method has pulled a task off the `Pending` queue and encoded it as JSON, all that’s left to do is send the task to the selected worker. These final two steps are implemented in listing 7.6. Sending the task to the worker involves building the URL using the worker’s `host` and `port`, which we got when we called the manager’s `SelectWorker` method previously. From there, we use the `Post` function from the `net/http` package in the standard library. Then we decode the response body and print it. Notice that we’re also checking errors along the way.[](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)

##### Listing 7.6 The final two steps of the `SendWork` method

```
url := fmt.Sprintf("http://%s/tasks", w)
       resp, err := http.Post(url, "application/json", bytes.NewBuffer(data))
       if err != nil {
           log.Printf("Error connecting to %v: %v\n", w, err)
           m.Pending.Enqueue(te)
           return
       }
       d := json.NewDecoder(resp.Body)
       if resp.StatusCode != http.StatusCreated {
           e := worker.ErrResponse{}
           err := d.Decode(&e)
           if err != nil {
               fmt.Printf("Error decoding response: %s\n", err.Error())
               return
           }
           log.Printf("Response error (%d): %s", e.HTTPStatusCode, e.Message)
           return
       }

       t = task.Task{}
       err = d.Decode(&t)
       if err != nil {
           fmt.Printf("Error decoding response: %s\n", err.Error())
           return
       }
       log.Printf("%#v\n", t)
   } else {
       log.Println("No work in the queue")
   }
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)As you can see from this code, the manager is interacting with the worker via the worker API we implemented in chapter 5.

### [](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)7.3.3 Implementing the UpdateTasks method

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)At this point, our manager can select a worker to run a task and then send that task to the selected worker. It has also stored the task in its `TaskDB` and `EventsDB` databases. But the manager’s view of the task is only from its own perspective. Sure, it sent the task to the worker, and if all went well, the worker responded with `http.StatusCreated` (i.e., `201`). But even if we receive an `http.StatusCreated` response, that just tells us that the worker received the task and added it to its queue. This response gives us no indication that the task was started successfully and is currently running. What if the task failed when the worker attempted to start it? How might a task fail, you ask? Here are a few ways:[](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)

-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)The user specified a nonexistent Docker image so that when the worker attempts to start the task, Docker complains that it can’t find the image.
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)The worker’s disk is full, so it doesn’t have enough space to download the Docker image.
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)There is a bug in the application running inside the Docker container that prevents it from starting correctly (maybe the creator of the container image left out an important environment variable that the application needs to start up properly).

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)These are just several ways a task might fail. While the manager doesn’t necessarily need to know about every possible way a task might fail, what it does need to do is check in with the worker periodically to get status updates on the tasks it’s running. Moreover, the manager needs to get status updates for every worker in the cluster. With this in mind, let’s implement the manager’s `UpdateTasks` method.

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)The general shape of updating tasks from each worker is straightforward. For each worker, we perform the following steps:

1.  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)Query the worker to get a list of its tasks.
1.  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)For each task, update its state in the manager’s database so it matches the state from the worker.

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)The first step can be seen in listing 7.7. It should look familiar by this point. The manager starts by making a `GET` `/tasks` HTTP request to a worker using the `Get` method from the `net/http` package. It checks for any errors, such as connection problems (maybe the worker was down for some reason). If the manager was able to connect to the worker, it then checks the response code and ensures it received an `http.StatusOK` (i.e., `200`) response code. Finally, it decodes the JSON data in the body of the response, which should result in a list of the worker’s tasks. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)

##### Listing 7.7 Step 1 of the process to update the manager’s tasks

```
func (m *Manager) UpdateTasks() {
   for _, worker := range m.Workers {
       log.Printf("Checking worker %v for task updates", worker)
       url := fmt.Sprintf("http://%s/tasks", worker)
       resp, err := http.Get(url)
       if err != nil {
           log.Printf("Error connecting to %v: %v\n", worker, err)
       }

       if resp.StatusCode != http.StatusOK {
           log.Printf("Error sending request: %v\n", err)
       }

       d := json.NewDecoder(resp.Body)
       var tasks []*task.Task
       err = d.Decode(&tasks)
       if err != nil {
           log.Printf("Error unmarshalling tasks: %s\n", err.Error())
       }
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)The second step, seen in listing 7.8, runs inside the main `for` loop from listing 7.7. There is nothing particularly sophisticated or clever about how we’re updating the tasks. We start by checking whether the task’s state in the manager is the same as that of the worker; if not, we set the state to the state reported by the worker. (In this way, the manager treats the workers as the authoritative source for the “state of the world”—that is, the current state of the tasks in the system.) Once we’ve updated the task’s state, we then update its `StartTime` and `FinishTime`. And finally, we update the task’s `ContainerID`.

##### Listing 7.8 Step 2 of the process to update the manager’s tasks

```
for _, t := range tasks {
           log.Printf("Attempting to update task %v\n", t.ID)

           _, ok := m.TaskDb[t.ID]
           if !ok {
               log.Printf("Task with ID %s not found\n", t.ID)
               return
           }

           if m.TaskDb[t.ID].State != t.State {
               m.TaskDb[t.ID].State = t.State
           }

           m.TaskDb[t.ID].StartTime = t.StartTime
           m.TaskDb[t.ID].FinishTime = t.FinishTime
           m.TaskDb[t.ID].ContainerID = t.ContainerID
       }
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)With the implementation of the `UpdateTasks` method, we have now completed the core functionality of our manager. Let’s quickly summarize what we’ve accomplished thus far before continuing:

-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)With the `SelectWorker` method, we’ve implemented a simple but naive scheduling algorithm to assign tasks to workers.
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)With the `SendWork` method, we’ve implemented a process that uses the `SelectWorker` method and sends individual tasks to assigned workers via that worker’s API.
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)With the `UpdateTasks` method, we’ve implemented a process for the manager to update its view of the state of all the tasks in the system.

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)That’s a large chunk of work that we’ve just completed. Take a moment to celebrate your achievement before moving on to the next section![](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)

### [](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)7.3.4 Adding a task to the manager

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)While we have implemented the core functionality of the manager, there are a couple more methods that we still need to implement. The first of these methods is the `AddTask` method, as seen in listing 7.9. This method should look familiar, as it’s similar to the `AddTask` method we created for the worker. It also serves a similar purpose: it’s how tasks are added to the manager’s queue. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)

##### Listing 7.9 The manager’s `AddTask` method

```
func (m *Manager) AddTask(te task.TaskEvent) {
   m.Pending.Enqueue(te)
}
```

### [](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)7.3.5 Creating a manager

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)Finally, let’s create the `New` function, as shown in listing 7.10. This is a helper function that takes in a list of workers, creates an instance of the manager, and returns a pointer to it. The bulk of the work performed by this function is initializing the necessary subcomponents used by the manager. It sets up the `taskDB` and `eventDb` databases. Next, it initializes the `workerTaskMap` and `taskWorkerMap` maps that help the manager more easily identify where tasks are running. While this function isn’t technically called a *constructor*, as in some other object-oriented languages, it performs a similar function and will be used in the process of starting the manager. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)

##### Listing 7.10 Initializing a new manager with the `New()` function

```
func New(workers []string) *Manager {
   taskDb := make(map[uuid.UUID]*task.Task)
   eventDb := make(map[uuid.UUID]*task.TaskEvent)
   workerTaskMap := make(map[string][]uuid.UUID)
   taskWorkerMap := make(map[uuid.UUID]string)
   for worker := range workers {
       workerTaskMap[workers[worker]] = []uuid.UUID{}
   }

   return &Manager{
       Pending:       *queue.New(),
       Workers:       workers,
       TaskDb:        taskDb,
       EventDb:       eventDb,
       WorkerTaskMap: workerTaskMap,
       TaskWorkerMap: taskWorkerMap,
   }
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)With the addition of the `AddTask` method and `New` function, we’ve completed the initial implementation of the Cube manager. Now all that’s left to do is take it for a spin![](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)

## [](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)7.4 An interlude on failures and resiliency

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)It’s worth pausing here for a moment to identify a weakness in our implementation. While the manager can select a worker from a pool of workers and send it a task to run, it is not dealing with failures. The manager is simply recording the state of the world in its `Task` `DB`.

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)What we are building toward, however, is a declarative system where a user declares the desired state of a task. The manager’s job is to honor that request by making a reasonable effort to bring the task into the declared state. For now, a *reasonable effort* means making a single attempt to bring the task into the desired state. We are going to revisit this topic later in chapter 9, where we will consider additional steps the manager can take in the face of failures to build a more resilient system.

## [](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)7.5 Putting it all together

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)By now, the pattern we are using to build Cube should be clear. We spend the bulk of the chapter writing the core pieces we need; then, at the end of the chapter, we write or update a `main()` function in our project’s `main.go` file to make use of our work. We’ll continue using this same pattern here and for the next few chapters. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)For this chapter, we’re going to start by using the `main.go` file from chapter 6 as our starting point. Whereas in past chapters we focused exclusively on running a worker, now we want to run a worker and a manager. We want to run them both because running a manager in isolation makes no sense: the need for a manager only makes sense in the context of having one or more workers.

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)Let’s make a copy of the `main.go` file from chapter 6. As we said, this is our starting point for running the worker and the manager. Our previous work already knows how to start an instance of the worker. As we can see in listing 7.11, we create an instance of the worker, `w`, and then we create an instance of the worker API, `api`. Next, we call the `runTasks` function, also defined in `main.go`, and pass it a pointer to our worker `w`. We make the call to `runTasks` using a goroutine, identified by the `go` keyword before the function call. Similarly, we use a second goroutine to call the worker’s `CollectStats()` method, which periodically collects stats from the machine where the worker is running (as we saw in chapter 6). Finally, we call the API’s `Start()` method, which starts up the API server and listens for requests. Here is where we make our first change. Instead of calling `api.Start()` in our main goroutine, we call it using a third goroutine, which allows us to run all the necessary pieces of the worker concurrently. We will reuse the `main()` function from the previous chapter and make one minor change to run all the worker’s components in separate goroutines. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)

##### Listing 7.11 Running all the worker’s components in separate goroutines

```
func main() {
   host := os.Getenv("CUBE_HOST")
   port, _ := strconv.Atoi(os.Getenv("CUBE_PORT"))

   fmt.Println("Starting Cube worker")

   w := worker.Worker{
       Queue: *queue.New(),
       Db:    make(map[uuid.UUID]*task.Task),
   }
   api := worker.Api{Address: host, Port: port, Worker: &w}

   go runTasks(&w)
   go w.CollectStats()
   go api.Start()
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)At this point, we have an instance of our worker running. Now, we want to start an instance of our manager.

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)To do this, we create a list of workers and assign it to a variable named `workers`. This list is a slice of strings, and we add our single worker to it. Next, we create an instance of our manager by calling the `New` function created earlier and passing it to our list of workers.

##### Listing 7.12 Calling the `manager.New()` function

```
workers := []string{fmt.Sprintf("%s:%d", host, port)}
   m := manager.New(workers)
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)With an instance of our worker running and an instance of a manager created, the next step is to add some tasks to the manager. In listing 7.13, we create three tasks. This is a random decision. Feel free to choose more or less. Creating the `Task` and `TaskEvent` should look familiar since it’s the same thing we’ve done in previous chapters in working with the worker. Now, however, instead of adding the `TaskEvent` to the worker directly, we add it to the manager by calling `AddTask` on the manager `m` and passing it the task event `te`. The final step in this loop is to call the `SendWork` method on manager `m`, which will select the only worker we currently have and, using the worker’s API, send the worker the task event. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)

##### Listing 7.13 Adding tasks to the manager

```
for i := 0; i < 3; i++ {
       t := task.Task{
           ID:    uuid.New(),
           Name:  fmt.Sprintf("test-container-%d", i),
           State: task.Scheduled,
           Image: "strm/helloworld-http",
       }
       te := task.TaskEvent{
           ID:    uuid.New(),
           State: task.Running,
           Task:  t,
       }
       m.AddTask(te)
       m.SendWork()
   }
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)Reaching this point, let’s pause for a moment and think about what has happened:

-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)We created an instance of the worker, and it’s running and listening for API requests.
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)We created an instance of the manager, and it has a list of workers containing the single worker we created earlier.
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)We created three tasks and added those tasks to the manager.
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)The manager selected a worker (in this case, the only one that exists) and sent it the three tasks.
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)The worker received the tasks and at least attempted to start them.

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)From this list, it’s clear there are two perspectives on the state of the tasks in this system: there is the manager’s perspective, and there is the worker’s perspective. From the manager’s perspective, it has sent the tasks to the worker. Unless there is an error returned from the request to the worker’s API, the manager’s work in this process could be considered complete.

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)From the worker’s perspective, things are more complicated. The worker has received the request from the manager. However, we must remember how we built the worker. Upon receiving the request, the worker API’s request handlers don’t directly perform any operations; instead, the handlers take the requests and put them on the worker’s queue. In a separate goroutine, the worker performs the direct operations to start and stop tasks. As mentioned in chapter 5, this design decision allows us to separate the concern of handling API requests from the concern of performing the actual operations to start and stop tasks.

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)Once the worker picks a task off of its queue and attempts to perform the necessary operation, any number of things can go wrong. As we enumerated earlier, examples of things going wrong can include user errors (e.g., a user specifying a nonexisting Docker image in the task specification) or machine errors (e.g., a machine doesn’t have enough disk space to download the task’s Docker image).

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)As we can see, for the manager to be an effective component in our orchestration system, it can’t just use a fire-and-forget approach to task management. It must constantly check in with the workers it is managing to reconcile its perspective with that of the workers’.

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)We discussed this problem earlier in the chapter, and it was our motivation for implementing the manager’s `UpdateTasks` method. So, now, let’s make use of our foresight. Once the manager has sent tasks off to the worker, we want to call the manager’s `UpdateTasks` method. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)To accomplish our objective, we’ll use another goroutine, which will call an *anonymous function*. Like other programming languages, an anonymous function in Go is simply a function that is defined where it’s called. Inside of this anonymous function, we use an infinite loop. Inside this loop, we print an informative log message that tells us the manager is updating tasks from its workers. Then we call the manager’s `UpdateTasks` method to update its perspective on the tasks in the system. And finally, it sleeps for 15 seconds. As we’ve done previously, we’re using sleep here purely for the purpose of slowing down the system so we can observe and understand our work. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)While we’re on the topic of observing our work, let’s also add another infinite loop that ranges over the tasks and prints out the `ID` and `State` of each task in the system. This will allow us to observe the tasks’ state changing as the `UpdateTasks` method does its job. This pattern of using an anonymous function to run a piece of code in a separate goroutine is common in the Go ecosystem. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)

##### Listing 7.14 Using an anonymous function

```
go func() {                                                       #1
    for {                                                         #2
        fmt.Printf("[Manager] Updating tasks from %d workers\n", len(m.Workers))
        m.UpdateTasks()                                           #3
        time.Sleep(15 * time.Second)
    }
}()                                                               #4
 
for {                                                             #5
    for _, t := range m.TaskDb {                                  #6
        fmt.Printf("[Manager] Task: id: %s, state: %d\n", t.ID, t.State)
        time.Sleep(15 * time.Second)
    }
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)At this point, we’ve written all the necessary code to run our worker and manager together. So let’s switch from writing code to running it.

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)To run our `main.go` program, call it with `go` `run` `main.go`. Also, it’s important to define the `CUBE_HOST` and `CUBE_PORT` environment variables as part of the command, as this tells the worker API on what port to listen. These environment variables will also be used by the manager to populate its `Workers` field. When we start our program, the initial output should look familiar. We should see the following:[](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)

```bash
$ CUBE_HOST=localhost CUBE_PORT=5555 go run main.go
Starting Cube worker                                                     #1
2022/01/30 14:17:12 Pulled {9f122e79-6623-4986-a9df-38a5216286fb ....    #2
2022/01/30 14:17:12 No tasks to process currently.                       #3
2022/01/30 14:17:12 Sleeping for 10 seconds.
2022/01/30 14:17:12 Collecting stats                                     #4
2022/01/30 14:17:12 Added task 9f122e79-6623-4986-a9df-38a5216286fb      #5
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)After this initial output, we should see the worker start the tasks. Then, once all three tasks are started, you should start seeing output from the `main.go` program. Our code is calling the manager’s `UpdateTasks` method in one `for` loop, ranging over the manager’s tasks, and printing out the `ID` and `State` of each task in a separate `for` loop:[](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)

```
[Manager] Updating tasks from 1 workers
[Manager] Task: id: 9f122e79-6623-4986-a9df-38a5216286fb, state: 2
[Manager] Updating tasks from 1 workers
[Manager] Task: id: 792427a7-e306-44ef-981a-c0b76bfaab8e, state: 2
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)Interleaved in the output, you should also see output like the following. This output is coming from our manager itself:

```
2022/01/30 14:18:57 Checking worker localhost:5555 for task updates
2022/01/30 14:18:57 Attempting to update task
 792427a7-e306-44ef-981a-c0b76bfaab8e
2022/01/30 14:18:57 Attempting to update task
 2507e136-7eb7-4530-aeb9-d067eeb34394
2022/01/30 14:18:57 Attempting to update task
 9f122e79-6623-4986-a9df-38a5216286fb
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)While our `main.go` program is running in one terminal, open a second terminal and query the worker API. Depending on how quickly you run the `curl` command after starting up the `main.go` program, you may not see all three tasks. Eventually, though, you should see them:[](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)

```bash
$ curl http://localhost:5555/tasks |jq .
[
  {
    "ID": "723143b3-4cb8-44a7-8dad-df553c15bce3",
    "ContainerID":
         "14895e61db8d08ba5d0e4bb96d6bd75023349b53eb4ba5915e4e15ecda82e907",
    "Name": "test-container-0",
    "State": 2,
    [....]
  },
  {
    "ID": "a85013fb-2918-47fb-82b0-f2e8d63f433b",
    "ContainerID":
         "f307d7045a36501059092f06ff3d323e6246a7c854bfabeb5ff17b2185ffd9ec",
    "Name": "test-container-1",
    "State": 2,
    [....]
  },
  {
    "ID": "7a7eb0ef-8516-4103-84a7-9f964ba47cb8",
    "ContainerID":
         "fffc1cf5b8ca7d33eb3c725f4190b81e0978f3efc8405562f9dfe4d315decbec",
    "Name": "test-container-2",
    "State": 2,
    [....]
  }
]
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)In addition to querying the worker API, we can use the `docker`[](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/) command to verify that our tasks are indeed running. Note that I’ve removed some of the columns from the output of `docker` `ps` for readability:

```bash
$ docker ps
CONTAINER ID   CREATED         STATUS         NAMES
fffc1cf5b8ca   5 minutes ago   Up 5 minutes   test-container-2
f307d7045a36   5 minutes ago   Up 5 minutes   test-container-1
14895e61db8d   5 minutes ago   Up 5 minutes   test-container-0
```

## [](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)Summary

-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)The manager records user requests in the form of `task.TaskEvent` items and stores them in its `EventDB`. This task event, which includes the `task.Task` itself, serves as the user’s desired state for the task.
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)The manager records the “state of the world” (i.e., the actual state of a task from the perspective of a worker) in its `TaskDB`. For this initial implementation of the manager, we do not attempt to retry failed tasks and instead simply record the state. We will revisit this problem later in chapter 9.
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)The manager serves a purely administrative function. It accepts requests from users, records those requests in its internal databases, selects a worker to run the task, and passes the task along to the worker. It periodically updates its internal state by querying the worker’s API. It is not directly involved in any of the operations to actually run a task.
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)We’ve used a simple, extremely naive algorithm to assign tasks to workers. This decision allowed us to code a working implementation of the manager in a relatively small number of lines of code. We will revisit this decision in chapter 10. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-7/)

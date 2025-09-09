# [](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)8 An API for the manager

### This chapter covers

- Understanding the purpose of the manager API
- Implementing methods to handle API requests
- Creating a server to listen for API requests
- Starting, stopping, and listing tasks via the API

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)In chapter 7, we implemented the core functionality of the manager component: pulling tasks off its queue, selecting a worker to run those tasks, sending them to the selected workers, and periodically updating the state of tasks. That functionality is just the foundation and doesn’t provide a simple way for users to interact with the manager.

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)So, like we did with the worker in chapter 5, we’re going to build an API for the manager. This API wraps the manager’s core functionality and exposes it to users. In the case of the manager, `users` means *end users*, that is, developers who want to run their application in our orchestration system.

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)The manager’s API, like the worker’s, will be simple. It will provide the means for users to perform these basic operations:

-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)Send a task to the manager
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)Get a list of tasks
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)Stop a task

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)This API will be constructed using the same components used for the worker’s API. It will comprise *handlers*, *routes*, and a *mux*. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)

## [](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)8.1 Overview of the manager API

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)Before we get too far into our code, let’s zoom out for a minute and take a more holistic view of where we’re going. We’ve been focusing pretty tightly for the last couple of chapters, so it will be a good reminder to see how the technical details fit together. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)We’re not building a manager and worker just for the sake of it. The purpose of building them is to fulfill a need: developers need a way to run their applications in a reliable and resilient way. The manager and worker are abstractions that free the developer from having to think too deeply about the underlying infrastructure (whether physical or virtual) on which their applications run. Figure 8.1 reminds us of what this abstraction looks like.

![Figure 8.1 The manager comprises an API server and manager components, and similarly, the worker comprises an API server and worker components. The user communicates with the manager, and the manager communicates with one or more workers.](https://drek4537l1klr.cloudfront.net/boring/Figures/08-01.png)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)With that reminder, let’s zoom back to the details of constructing the manager’s API. Because it will be similar to the worker’s, we won’t spend as much time going into the details of handlers, routes, and muxes. If you need a refresher, please refer to section 5.1.

## [](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)8.2 Routes

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)Let’s start by identifying the routes that our manager API should handle. It shouldn’t be too surprising that the routes are identical to that of the worker’s API. In some ways, our manager is acting as a reverse proxy: instead of balancing requests for, say, web pages across a number of web servers, it’s balancing requests to run tasks across a number of workers. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)Thus, like the worker’s, the manager’s API will handle `GET` requests to `/tasks`, which will return a list of all the tasks in the system (table 8.1). This enables our users to see what tasks are currently in the system. It will handle `POST` requests to `/tasks`, which will start a task on a worker. This allows our users to run their tasks in the system. Finally, it will handle `DELETE` requests to `/tasks/{taskID}`, which will stop a task specified by the `taskID` in the route. This allows our users to stop their tasks. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/) [](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)

##### [](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)Table 8.1 Routes used by our manager API[(view table figure)](https://drek4537l1klr.cloudfront.net/boring/HighResolutionFigures/table_8-1.png)

| [](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)Method | [](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)Route | [](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)Description |
| --- | --- | --- |
| [](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)`GET` | [](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)`/tasks` | [](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)Gets a list of all tasks |
| [](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)`POST` | [](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)`/tasks` | [](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)Creates a task |
| [](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)`DELETE` | [](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)`/tasks/{taskID}` | [](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)Stops the task identified by `taskID` |

## [](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)8.3 Data format, requests, and responses

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)If the routes we use for the manager’s API are similar to the worker’s, then what about the data format and the requests and responses that the manager will receive and return? Again, it should not be surprising that the manager’s API will use the same data format, JSON, as the worker’s API. If the worker’s API speaks JSON, the manager’s API should speak the same language to minimize unnecessary translation between data formats. Thus, any data sent to the manager’s API must be JSON-encoded, and any data returned by the API will also be encoded as JSON. Table 8.2 shows an updated route table. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)

##### [](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)Table 8.2 An updated route table showing whether the routes send a request body and return a response body and the status code for a successful request[(view table figure)](https://drek4537l1klr.cloudfront.net/boring/HighResolutionFigures/table_8-2.png)

| [](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)Method | [](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)Route | [](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)Description | [](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)Request body | [](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)Response body | [](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)Status code |
| --- | --- | --- | --- | --- | --- |
| [](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)`GET` | [](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)`/tasks` | [](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)Gets a list of all tasks | [](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)None | [](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)List of tasks | [](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)`200` |
| [](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)`POST` | [](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)`/tasks` | [](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)Creates a task | [](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)JSON-encoded `task.TaskEvent` | [](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)None | [](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)`201` |
| [](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)`DELETE` | [](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)`/tasks/{taskID}` | [](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)Stop the task identified by `taskID` | [](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)None | [](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)None | [](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)`204` |

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)We can see how these routes are used in figure 8.2, which shows a `POST` request to create a new task and a `GET` request to get a list of tasks. The developer issues requests to the manager, and the manager returns responses. In the first example, the developer issues a POST request with a body that specifies a task to run. The manager responds with a status code of `201`. In the second example, the developer issues a `GET` request, and the manager responds with a status code of `200` and a list of its tasks. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)

![Figure 8.2 Two examples of how a developer uses the manager’s API](https://drek4537l1klr.cloudfront.net/boring/Figures/08-02.png)

## [](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)8.4 The API struct

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)Drilling down a little further, we notice another similarity with the worker’s API. The manager’s API also uses an `Api` struct, which will encapsulate the necessary behavior of its API. The only difference will be swapping out a single field: the `Worker` field gets replaced by a `Manager` field, which contains a pointer to an instance of our manager. Otherwise, the `Address`, `Port`, and `Router` fields all have the same types and serve the same purposes as they did in the worker API. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)

##### Listing 8.1 The manager’s `Api` struct

```
type Api struct {
   Address string
   Port    int
   Manager *Manager
   Router  *chi.Mux
}
```

## [](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)8.5 Handling requests

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)Continuing to drill down, let’s talk about the handlers for the manager API. These should look familiar, as they are the same three handlers we implemented for the worker:[](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)

-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)`StartTaskHandler(w` `http.ResponseWriter,` `r` `*http.Request)`
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)`GetTasksHandler(w` `http.ResponseWriter,` `r` `*http.Request)`
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)`StopTaskHandler(w` `http.ResponseWriter,` `r` `*http.Request)`

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)We’ll implement these handlers in a file named `handlers.go`, which you should create in the `manager` directory next to the existing `manager.go` file. To reduce the amount of typing necessary, feel free to copy the handlers from the worker’s API and paste them into the manager’s `handlers.go` file. The only changes we’ll need to make are to update any references to `a.Worker` and `a.Manager`. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)Let’s start with the `StartTaskHandler`, which works the same as its worker counterpart. It expects a request body encoded as JSON. It decodes that request body into a `task.TaskEvent`, checking for any decoding errors. Then it adds the task event to the manager’s queue using the manager’s `AddTask` method implemented in chapter 7. The implementation can be seen in the following listing. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)

##### Listing 8.2 The manager’s `StartTaskHandler`

```
func (a *Api) StartTaskHandler(w http.ResponseWriter, r *http.Request) {
    d := json.NewDecoder(r.Body)                                          #1
    d.DisallowUnknownFields()
 
    te := task.TaskEvent{}
    err := d.Decode(&te)                                                  #2
    if err != nil {                                                       #3
        msg := fmt.Sprintf("Error unmarshalling body: %v\n", err)
        log.Printf(msg)
        w.WriteHeader(400)
        e := ErrResponse{
            HTTPStatusCode: 400,
            Message:        msg,
        }
        json.NewEncoder(w).Encode(e)
        return
    }
 
    a.Manager.AddTask(te)                                                 #4
    log.Printf("Added task %v\n", te.Task.ID)
    w.WriteHeader(201)                                                    #5
    json.NewEncoder(w).Encode(te.Task)                                    #6
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)Next up is the `GetTasksHandler`. Like the `StartTaskHandler`, `GetTasksHandler` works similarly to its counterpart in the worker API. We do, however, need to implement a helper method that will make it easy for us to get a list of the tasks from the manager. We create the `GetTasks()` helper on the `Manager` struct. The `GetTasks()`[](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/) method is straightforward:[](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)

-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)Instantiate a variable named `tasks` as a slice of pointers to `task.Task` types.
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)Range over the manager’s `TaskDb` field and add each task to the `tasks` slice.
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)Return the slice of tasks.

##### Listing 8.3 The `GetTasks` helper function returning a slice of pointers to `task.Task` types

```
func (m *Manager) GetTasks() []*task.Task {
   tasks := []*task.Task{}
   for _, t := range m.TaskDb {
       tasks = append(tasks, t)
   }
   return tasks
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)With the `GetTasks()` function written, we can now use it in the `GetTasksHandler` method. The only change we need to make from the worker’s implementation is to pass the manager’s `GetTasks()` function to the encoder.

##### Listing 8.4 The manager’s `GetTasksHandler`

```
func (a *Api) GetTasksHandler(w http.ResponseWriter, r *http.Request) {
   w.Header().Set("Content-Type", "application/json")
   w.WriteHeader(200)
   json.NewEncoder(w).Encode(a.Manager.GetTasks())
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)Finally, let’s implement the `StopTaskHandler`. Again, the method works the same way as its worker counterpart, so there isn’t much new to add to the discussion. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)

##### Listing 8.5 The manager’s `StopTaskHandler`

```
func (a *Api) StopTaskHandler(w http.ResponseWriter, r *http.Request) {
    taskID := chi.URLParam(r, "taskID")                #1
    if taskID == "" {
        log.Printf("No taskID passed in request.\n")
        w.WriteHeader(400)
    }
 
    tID, _ := uuid.Parse(taskID)
    taskToStop, ok := a.Manager.TaskDb[tID]            #2
    if !ok {
        log.Printf("No task with ID %v found", tID)
        w.WriteHeader(404)
    }
 
    te := task.TaskEvent{                              #3
        ID:        uuid.New(),
        State:     task.Completed,
        Timestamp: time.Now(),
    }
 
    taskCopy := *taskToStop                            #4
    taskCopy.State = task.Completed
    te.Task = taskCopy
    a.Manager.AddTask(te)                              #5
 
    log.Printf("Added task event %v to stop task %v\n", te.ID, taskToStop.ID)
    w.WriteHeader(204)                                 #6
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)As a reminder, as we did in the worker, the manager’s handler methods are not operating directly on tasks. We have separated the concerns of responding to API requests and the operations to start and stop tasks. So the API simply puts the request on the manager’s queue via the `AddTask` method, and then the manager picks up the task from its queue and performs the necessary operation.

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)So far, we’ve been able to implement the handlers in the manager’s API by copying and pasting the handlers from the worker’s API and making a few minor adjustments. At this point, we’ve implemented the meat of the API. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)

## [](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)8.6 Serving the API

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)Now that we have implemented the manager’s handlers, let’s complete our work that will let us serve the API to users. We’ll start by copying and pasting the `initRouter` method from the worker. This method sets up our router and creates the required endpoints, and since the endpoints will be the same as the worker’s, we don’t need to modify anything. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)

##### Listing 8.6 The manager API’s `initRouter` method

```
func (a *Api) initRouter() {
   a.Router = chi.NewRouter()
   a.Router.Route("/tasks", func(r chi.Router) {
       r.Post("/", a.StartTaskHandler)
       r.Get("/", a.GetTasksHandler)
       r.Route("/{taskID}", func(r chi.Router) {
           r.Delete("/", a.StopTaskHandler)
       })
   })
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)For the icing on the cake, let’s take care of starting the API by copying the `Start` method from the worker’s API. The manager’s API will start up in the same way, so like the `initRouter` method, we don’t need to make any changes. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)

##### Listing 8.7 The manager API’s `Start` method

```
func (a *Api) Start() {
   a.initRouter()
   http.ListenAndServe(fmt.Sprintf("%s:%d", a.Address, a.Port), a.Router)
}
```

## [](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)8.7 A few refactorings to make our lives easier

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)At this point, we’ve implemented everything we need to have a functional API for the manager. But now that we’re at a point in our journey where we have APIs for both the worker and the manager, let’s make a few minor tweaks that will make it easier to run these APIs. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)If you recall from chapter 5, we created the function `runTasks` in our `main.go` file. We used it as a way to continuously check for new tasks that the worker needed to run. If it found any tasks in the worker’s queue, it called the workers `RunTask` method. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)Instead of having this function be part of the `main.go` file, let’s move it into the worker itself. This change will then encapsulate all the necessary worker behavior in the `Worker` object. Copy the `runTasks` function from the `main.go` file, and paste it into the `worker.go` file. Then, to clean everything up so the code will run, we’re going to make three changes:[](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)

-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)Rename the existing `RunTask` method to `runTask` [](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)Rename the `runTasks` method from `main.go` to `RunTasks` [](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)Change the `RunTasks` method to call the newly renamed `runTask` method [](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)You can see these changes in the following listing.

##### Listing 8.8 Moving the `runTasks` function from `main.go` to the worker

```
func (w *Worker) runTask() task.DockerResult {   #1
}
 
func (w *Worker) RunTasks() {                    #2
    for {
        if w.Queue.Len() != 0 {
            result := w.runTask()                #3
            if result.Error != nil {
                log.Printf("Error running task: %v\n", result.Error)
            }
        } else {
            log.Printf("No tasks to process currently.\n")
        }
        log.Println("Sleeping for 10 seconds.")
        time.Sleep(10 * time.Second)
    }
 
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)In a similar fashion, we’re going to make some changes to the `Manager` struct that will make it easier to use the manager in our `main.go` file. For starters, let’s rename the manager’s `UpdateTasks` method to `updateTasks`. The method should look like this (the body of the method stays the same):[](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)

```
func (m *Manager) updateTasks() {
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)Next, let’s create a new method on our `Manager` struct called `UpdateTasks`. This method serves a similar purpose to the `RunTasks` method we added to the worker. It runs an endless loop, inside which it calls the manager’s `updateTasks` method. This change makes it possible for us to remove the anonymous function we used in the `main.go` file in chapter 7 that performed the same function. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)

##### Listing 8.9 Adding the `UpdateTasks` method to the manager

```
func (m *Manager) UpdateTasks() {
   for {
       log.Println("Checking for task updates from workers")
       m.updateTasks()
       log.Println("Task updates completed")
       log.Println("Sleeping for 15 seconds")
       time.Sleep(15 * time.Second)
   }
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)Finally, let’s add the `ProcessTasks` method you see in the next listing to the manager. This method also works similarly to the worker’s `RunTasks` method: it runs an endless loop, repeatedly calling the manager’s `SendWork` method. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)

##### Listing 8.10 The manager’s `ProcessTasks` method

```
func (m *Manager) ProcessTasks() {
   for {
       log.Println("Processing any tasks in the queue")
       m.SendWork()
       log.Println("Sleeping for 10 seconds")
       time.Sleep(10 * time.Second)
   }
}
```

## [](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)8.8 Putting it all together

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)Alright, it’s that time again—time to take what we’ve built in the chapter and run it. Before we do that, however, let’s quickly summarize what we’ve built so far:[](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)

-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)We wrapped the manager component in an API that allows users to communicate with the manager.
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)We constructed the manager’s API using the same types of components we used for the worker’s API: *handlers*, *routes*, and a *router*.
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)The *router* listens for requests to the *routes*, and dispatches those requests to the appropriate *handlers*.

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)Let’s start by copying and pasting the `main` function from the `main.go` file in chapter 7. This will be our starting point.

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)There is one major difference between our situation at the end of this chapter and that of the last: we now have APIs for both the worker and the manager. So while we will be creating instances of each, we will not be interacting with them directly as we have in the past. Instead, we will be passing these instances into their respective APIs and then starting those APIs so they are listening to HTTP requests.

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)In past chapters where we started instances of the worker’s API, we set two environment variables: `CUBE_HOST` and `CUBE_PORT`. These were used to set up the worker API to listen for requests at `http://localhost:5555`. Now, however, we have two APIs that we need to start. To handle our new circumstances, let’s set up our `main` function to extract a set of `host:port` environment variables for each API. As you can see in the following listing, these will be called `CUBE_WORKER_HOST`, `CUBE_WORKER_PORT`, `CUBE_MANAGER_HOST`, and `CUBE_MANAGER_PORT`. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)

##### Listing 8.11 Extracting the host and port for each API from environment variables

```
func main() {
   whost := os.Getenv("CUBE_WORKER_HOST")
   wport, _ := strconv.Atoi(os.Getenv("CUBE_WORKER_PORT"))

   mhost := os.Getenv("CUBE_MANAGER_HOST")
   mport, _ := strconv.Atoi(os.Getenv("CUBE_MANAGER_PORT"))
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)Next, after extracting the host and port values from the environment and storing them in appropriately named variables, let’s start up the worker API. This process should look familiar from chapter 7. The only difference here, however, is that we’re calling the `RunTasks` method on the worker object, instead of a separate `runTasks` function that we previously defined in `main.go`. As we did in chapter 7, we call each of these methods using the `go` keyword, thus running each in a separate goroutine. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)

##### Listing 8.12 Starting up the worker API

```
fmt.Println("Starting Cube worker")

   w := worker.Worker{
       Queue: *queue.New(),
       Db:    make(map[uuid.UUID]*task.Task),
   }
   wapi := worker.Api{Address: whost, Port: wport, Worker: &w}

   go w.RunTasks()
   go w.CollectStats()
   go wapi.Start()
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)Finally, we’ll start up the manager API. This process starts the same as it did in the last chapter. We create a list of workers that contains the single previously created worker, represented as a string by its `<host>:<port>`. Then we create an instance of our manager, passing in the list of `workers`. Next, we create an instance of the manager’s API and store it in a variable called `mapi`.

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)The next two lines in our `main` function set up two goroutines that will run in parallel with the main goroutine running the API. The first goroutine will run the manager’s `ProcessTasks` method. This ensures the manager will process any incoming tasks from users. The second goroutine will run the manager’s `UpdateTasks` method. It will ensure the manager updates the state of tasks by querying the worker’s API to get up-to-date states for each task. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)Then comes what we’ve been waiting for. We start the manager’s API by calling the `Start` method. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)

##### Listing 8.13 Starting up the manager API

```
fmt.Println("Starting Cube manager")

   workers := []string{fmt.Sprintf("%s:%d", whost, wport)}
   m := manager.New(workers)
   mapi := manager.Api{Address: mhost, Port: mport, Manager: m}

   go m.ProcessTasks()
   go m.UpdateTasks()

   mapi.Start()

}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)At this point, all that’s left to do is to run our main program so both the manager and worker APIs are running. As you can see, both the worker and the manager get started:

```bash
$ CUBE_WORKER_HOST=localhost \
CUBE_WORKER_PORT=5555 \
CUBE_MANAGER_HOST=localhost \
CUBE_MANAGER_PORT=5556 \
go run main.go
Starting Cube worker
Starting Cube manager
2022/03/06 14:45:47 Collecting stats
2022/03/06 14:45:47 Checking for task updates from workers
2022/03/06 14:45:47 Processing any tasks in the queue
2022/03/06 14:45:47 Checking worker localhost:5555 for task updates
2022/03/06 14:45:47 No work in the queue
2022/03/06 14:45:47 Sleeping for 10 seconds
2022/03/06 14:45:47 No tasks to process currently.
2022/03/06 14:45:47 Sleeping for 10 seconds.
2022/03/06 14:45:47 Task updates completed
2022/03/06 14:45:47 Sleeping for 15 seconds
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)Let’s do a quick sanity check to verify that our manager does indeed respond to requests. Let’s issue a `GET` request to get a list of the tasks it knows about. It should return an empty list:

```bash
$ curl -v localhost:5556/tasks
*   Trying 127.0.0.1:5556...
* Connected to localhost (127.0.0.1) port 5556 (#0)
> GET /tasks HTTP/1.1
> Host: localhost:5556
> User-Agent: curl/7.81.0
> Accept: */*
>
* Mark bundle as not supporting multiuse
< HTTP/1.1 200 OK
< Content-Type: application/json
< Date: Sun, 06 Mar 2022 19:52:46 GMT
< Content-Length: 3
<
[]
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)Cool! Our manager is listening for requests as we expected. As we can see, though, it doesn’t have any tasks because we haven’t told it to run any yet. Let’s take the next step and send a request to the manager that instructs it to start a task for us.

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)For this purpose, let’s create a file named `task.json` in the same directory where our `main.go` file is. Inside this file, let’s create the JSON representation of a task, as seen in the next listing. This representation is similar to what we used in `main.go` in chapter 7, except we’re moving it into a separate file.

##### Listing 8.14 JSON representation of our task

```json
{
   "ID": "6be4cb6b-61d1-40cb-bc7b-9cacefefa60c",
   "State": 2,
   "Task": {
       "State": 1,
       "ID": "21b23589-5d2d-4731-b5c9-a97e9832d021",
       "Name": "test-chapter-5",
       "Image": "strm/helloworld-http"
   }
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)Now that we’ve created our `task.json` file with the task we want to send to the manager via its API, let’s use `curl` to send a POST request to the manager API’s `/tasks` endpoint. As expected, the manager’s API responds with a `201` response code:[](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)

```bash
$ curl -v --request POST \
--header 'Content-Type: application/json' \
--data @task.json \
localhost:5556/tasks
*   Trying 127.0.0.1:5556...
* Connected to localhost (127.0.0.1) port 5556 (#0)
> POST /tasks HTTP/1.1
> Host: localhost:5556
> User-Agent: curl/7.81.0
> Accept: */*
> Content-Type: application/json
> Content-Length: 230
>
* Mark bundle as not supporting multiuse
< HTTP/1.1 201 Created
< Date: Sun, 06 Mar 2022 20:04:36 GMT
< Content-Length: 286
< Content-Type: text/plain; charset=utf-8
<
{
   "ID":"21b23589-5d2d-4731-b5c9-a97e9832d021",
   "ContainerID":"",
   "Name":"test-chapter-5",
   "State":1,
   "Image":"strm/helloworld-http",
   "Cpu":0,
   "Memory":0,
   "Disk":0,
   "ExposedPorts":null,
   "PortBindings":null,
   "RestartPolicy":"",
   "StartTime":"0001-01-01T00:00:00Z",
   "FinishTime":"0001-01-01T00:00:00Z"
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)There’s one thing to note about the JSON returned by the manager’s API. Notice that the `ContainerID` field is empty. The reason for this is that like the worker’s API, the manager’s API doesn’t operate directly on tasks. As tasks come into the API, they are added to the manager’s queue, and the manager works on them independently of the request. At the time of our request, the manager hasn’t shipped the task to the worker, so it can’t know what the `ContainerID` will be. If we make a subsequent request to the manager’s API to `GET` `/tasks`, we should see a `ContainerID` for our task:

```bash
$ curl -v localhost:5556/tasks|jq
*   Trying 127.0.0.1:5556...
> GET /tasks HTTP/1.1
> Host: localhost:5556
> User-Agent: curl/7.81.0
> Accept: */*
>
* Mark bundle as not supporting multiuse
< HTTP/1.1 200 OK
< Content-Type: application/json
< Date: Sun, 06 Mar 2022 20:16:43 GMT
< Content-Length: 352
[
  {
    "ID": "21b23589-5d2d-4731-b5c9-a97e9832d021",
    "ContainerID":
     "428115c14a41243ec29e5b81feaccbf4b9632e2caaeb58f166df595726889312",
    "Name": "test-chapter-8",
    "State": 2,
    "Image": "strm/helloworld-http",
    "Cpu": 0,
    "Memory": 0,
    "Disk": 0,
    "ExposedPorts": null,
    "PortBindings": null,
    "RestartPolicy": "",
    "StartTime": "0001-01-01T00:00:00Z",
    "FinishTime": "0001-01-01T00:00:00Z"
  }
]
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)There is one minor thing to keep in mind when querying the manager’s API, as we did previously. Depending on how quickly we issue our `GET` `/tasks` request after sending the initial `POST` `/tasks` request, we may still not see a `ContainerID`. Why is that? If you recall, the manager updates its view of tasks by making a `GET` `/tasks` request to the worker’s API. It then uses the response to that request to update the state of the tasks in its own datastore. If you look back at listing 8.13, you can see that our `main.go` program is running the manager’s `UpdateTasks` method in a separate goroutine, and that method sleeps for 15 seconds between each attempt to update tasks.

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)Once the manager shows the task running—that is, we get a `ContainerID` in our `GET` `/tasks` Response—we can further verify that the task is running using the `docker` `ps` command:[](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)

```bash
$ docker ps --format "table {{.ID}}\t{{.Image}}\t{{.Status}}\t{{.Names}}"
CONTAINER ID   IMAGE                  STATUS              NAMES
428115c14a41   strm/helloworld-http   Up About a minute   test-chapter-8
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)Now that we’ve seen that we can use the manager’s API to start a task and to get a list of tasks, let’s use it to stop our running task. To do this, we issue a `DELETE` `/tasks/{taskID}` request, like the following:

```bash
$ curl -v --request DELETE \
   'localhost:5556/tasks/21b23589-5d2d-4731-b5c9-a97e9832d021'
*   Trying 127.0.0.1:5556...
* Connected to localhost (127.0.0.1) port 5556 (#0)
> DELETE /tasks/21b23589-5d2d-4731-b5c9-a97e9832d021 HTTP/1.1
> Host: localhost:5556
> User-Agent: curl/7.81.0
> Accept: */*
>
* Mark bundle as not supporting multiuse
< HTTP/1.1 204 No Content
< Date: Sun, 06 Mar 2022 20:29:27 GMT
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)As we can see, the manager’s API accepted our request, and it responded with a `204` response, as expected. You should also see it in the following output from our `main.go` program (I’ve truncated some of the output to make it easier to read):

```
2022/03/06 15:29:27 Added task event 937e85eb to stop task 21b23589
Found task in queue:
2022/03/06 15:29:32 attempting to transition from 2 to 3
2022/03/06 15:29:32 Attempting to stop container 442a439de
2022/03/06 15:29:43 Stopped and removed container 442a439de
 for task 21b23589
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)Again, we can use the `docker` `ps` command to confirm that our manager did what we expected it to do, which, in this case, is to stop the task:[](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)

```bash
$ docker ps
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES
```

## [](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)Summary

-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)Like the worker’s API, the manager wraps its core functionality and exposes it as an HTTP server. Unlike the worker’s API, whose primary user is the manager, the primary users of the manager’s API are end users—in other words, developers. Thus, the manager’s API is what users interact with to run their tasks on the orchestration system.
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)The manager and worker APIs provide an abstraction over our infrastructure, either physical or virtual, that removes the need for developers to concern themselves with such low-level details. Instead of thinking about how their application runs on a machine, they only have to be concerned about how their application runs in a container. If it runs as expected in a container on their machine, it can run on any machine that’s also running the same container framework (i.e., Docker).
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)Like the worker API, the manager’s API is a simple REST-based API. It defines routes that enable users to create, query, and stop tasks. Also, when sent data, it expects that data to be encoded as JSON, and it likewise encodes any data it sends as JSON. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-8/)

# [](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)5 An API for the worker

### This chapter covers

- Understanding the purpose of the worker API
- Implementing methods to handle API requests
- Creating a server to listen for API requests
- Starting, stopping, and listing tasks via the API

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)In chapter 4, we implemented the core features of the worker: pulling tasks off its queue and then starting or stopping them. Those core features alone, however, do not make the worker complete. We need a way to expose those core features so a manager, which will be the exclusive user, running on a different machine can make use of them. To do this, we’re going to wrap the worker’s core functionality in an application programming interface, or API. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)The API will be simple, as you can see in figure 5.1, providing the means for a manager to perform these basic operations:

-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)Send a task to the worker (which results in the worker starting the task as a container)
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)Get a list of the worker’s tasks
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)Stop a running task

![Figure 5.1 The API for our orchestrator provides a simple interface to the worker.](https://drek4537l1klr.cloudfront.net/boring/Figures/05-01.png)

## [](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)5.1 Overview of the worker API

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)We’ve enumerated the operations that the worker’s API will support: sending a task to a worker to be started, getting a list of tasks, and stopping a task. But how will we implement those operations? We’re going to implement those operations using a web API. This choice means that the worker’s API can be exposed across a network and that it will use the HTTP protocol. Like most web APIs, the worker’s API will use three primary components:[](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)

-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)*Handlers*—Functions that are capable of responding to requests
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)*Routes*—Patterns that can be used to match the URL of incoming requests
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)*Router*—An object that uses routes to match incoming requests with the appropriate handler

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)We could implement our API using nothing but the `http` package from the Go standard library. That can be tedious, however, because the `http` package is missing one critical piece: the ability to define *parameterized routes*. What is a parameterized route? It’s a route that defines a URL where one or more parts of the URL path are unknown and may change from one request to the next. This is particularly useful for things like identifiers. For example, if a route like `/tasks` called with an HTTP `GET` request returns a list of all tasks, then a route like `/tasks/5` returns a single item, the task whose identifier is the integer 5. Since each task should have a unique identifier, however, we need to provide a pattern when defining this kind of route in a web API. The way to do this is to use a parameter for the part of the URL path that can be different with each request. In the case of tasks, we can use a route defined as `/tasks/{taskID}`. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)Because the `http` package from the standard library doesn’t provide a robust and easy way to define parameterized routes, we’re going to use a lightweight, third-party router called chi ([https://github.com/go-chi/chi](https://github.com/go-chi/chi)). Conceptually, our API will look like what you see in figure 5.2. Requests will be sent to an HTTP server, which you can see in the box. This server provides a function called `ListenAndServe`, which is the lowest layer in our stack and will handle the low-level details of listening for incoming requests. The next three layers—routes, router, and handlers—are all provided by chi. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)

![Figure 5.2 Internally, the worker’s API is composed of an HTTP server from the Go standard library; the routes, router, and handlers from the chi package; and, finally, our own worker.](https://drek4537l1klr.cloudfront.net/boring/Figures/05-02.png)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)For our worker API, we’ll use the routes defined in table 5.1. Because we’re exposing our worker’s functionality via a web API, the routes will involve standard HTTP methods like `GET`, `POST`, and `DELETE`. The first route in the table, `/tasks`, will use the HTTP `GET` method and will return a list of tasks. The second route is the same as the first, but it uses the `POST` method, which will start a task. The third route, `/tasks/{taskID}`, will stop the running task identified by the parameter `{taskID}`.

##### [](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)Table 5.1 Routes used by our worker API[(view table figure)](https://drek4537l1klr.cloudfront.net/boring/HighResolutionFigures/table_5-1.png)

| [](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)Method | [](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)Route | [](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)Description |
| --- | --- | --- |
| [](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)`GET` | [](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)`/tasks` | [](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)Gets a list of all tasks |
| [](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)`POST` | [](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)`/tasks` | [](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)Creates a task |
| [](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)`DELETE` | [](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)`/tasks/{taskID}` | [](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)Stops the task identified by `taskID` |

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)If you work with REST (representational state transfer) APIs at your day job, this should look familiar. If you’re not familiar with REST or you are new to the world of APIs, don’t worry. It’s not necessary to be a REST expert to grok what we’re building in this chapter. At a very hand-wavy level, REST is an architectural style that builds on the client-server model of application development. If you want to learn more about REST, you can start with a gentle introduction like the blog post “API 101: What Is a REST API?” ([https://blog.postman.com/rest-api-definition/](https://blog.postman.com/rest-api-definition/)). [](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)

## [](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)5.2 Data format, requests, and responses

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)Before we get into writing any code, we need to address one more important item. From your experience browsing the internet, you know that when you type an address into your browser, you get back data. Type in [https://espn.com](https://espn.com), and you get data about sports. Type in [https://nytimes.com](https://nytimes.com), and you get data about current events. Type in [https://www.funnycatpix.com](https://www.funnycatpix.com), and you get data that is pictures of cats. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)Like these websites, the worker API deals with data, both sending and receiving it. However, its data is not about news or cats but tasks. Furthermore, the data that the worker API deals with will take a specific form, and that form is JSON, which stands for *JavaScript* *Object Notation*. You’re probably already familiar with JSON, as it’s the lingua franca of many modern APIs. This decision has two consequences:[](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)

-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)Any data sent to the API (e.g., for our `POST` `/tasks` route in table 5.1) must be encoded as JSON data in the body of the request.
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)Any data returned from the API (e.g., for our `GET` `/tasks` route) must be encoded as JSON data in the body of the response.

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)For our worker, we only have one route, the `POST` `/tasks` route, that will accept a body. But what data does our worker expect to be in the body of that request?

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)If you remember from the last chapter, the worker has a `StartTask` method that takes a `task.Task` type as an argument. That type holds all the necessary data we need to start the task as a Docker container. But what the worker API will receive (from the manager) is a `task.TaskEvent` type, which contains a `task.Task`. So the job of the API is to extract that task from the request and add it to the worker’s queue. Thus, a request to our `POST` `/tasks` route will look like that in the following listing. The `task.TaskEvent` here was used in chapter 4. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)

##### Listing 5.1 The worker API receiving a `task.TaskEvent` from the manager

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

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)The response to our `POST` `/tasks` request will have a status code of `201` and includes a JSON-encoded representation of the task in the response body. Why a `201` and not a `200` response code? We could use a `200` response status. According to the HTTP spec described in RFC 7231, “The 200 (OK) status code indicates that the request has succeeded. The payload sent in a 200 response depends on the request method” ([https://datatracker.ietf.org/doc/html/rfc7231#section-6.3.1](https://datatracker.ietf.org/doc/html/rfc7231#section-6.3.1)). Thus, the `200` response code is the generic case telling the requester, “Yes, I received your request, and it was successful.” The `201` response code, however, handles the more specific case. For a POST request, it tells the requester, “Yes, I received your request, and I created a new resource.” In our case, that new resource is the task sent in the request body.

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)Like the `POST` `/tasks` route, the `GET` `/tasks` route returns a body in its response. This route ultimately calls the `GetTasks` method on our worker, which returns a slice of pointers to `task.Task` types, effectively a list of tasks. Our API in this situation will take that slice returned from `GetTasks`, encode it as JSON, and then return it. The following listing shows an example of what such a response might look like. In this example, there are two tasks. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)

##### Listing 5.2 The worker API returning a list of tasks for the `GET /tasks` route

```
[
 {
   "ID": "21b23589-5d2d-4731-b5c9-a97e9832d021",
   "ContainerID": "4f67af51b173564ffd50a3c7f",
   "Name": "test-chapter-5",
   "State": 2,
   "Image": "strm/helloworld-http",
   "Memory": 0,
   "Disk": 0,
   "ExposedPorts": null,
   "PortBindings": null,
   "RestartPolicy": "",
   "StartTime": "0001-01-01T00:00:00Z",
   "FinishTime": "0001-01-01T00:00:00Z"
 },
 {
   "ID": "266592cd-960d-4091-981c-8c25c44b1018",
   "ContainerID": "180d207fa788d5261e6ccf927",
   "Name": "test-chapter-5-1",
   "State": 2,
   "Image": "strm/helloworld-http",
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

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)In addition to the list of tasks, the response will also have a status code of `200`.

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)Finally, let’s talk about the `DELETE` `/tasks/{taskID}` route. Like the `GET` `/tasks` route, this one will not take a body in the request. Remember, we said earlier that the `{taskID}` part of the route is a parameter and allows the route to be called with arbitrary IDs. So this route allows us to stop a task for the given `taskID`. This route will only return a status code of `204`; it will not include a body in the response. So with this new information, let’s update table 5.1. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)

##### [](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)Table 5.2 Updated table 5.1 showing for each request whether the route accepts a request body, whether it returns a response body, and what status code is returned for a successful request[(view table figure)](https://drek4537l1klr.cloudfront.net/boring/HighResolutionFigures/table_5-2.png)

| [](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)Method | [](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)Route | [](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)Description | [](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)Request body | [](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)Response body | [](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)Status code |
| --- | --- | --- | --- | --- | --- |
| [](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)`GET` | [](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)`/tasks` | [](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)Gets a list of all tasks | [](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)None | [](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)List of tasks | [](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)`200` |
| [](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)`POST` | [](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)`/tasks` | [](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)Creates a task | [](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)JSON-encoded `task.TaskEvent` | [](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)None | [](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)`201` |
| [](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)`DELETE` | [](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)`/tasks/{taskID}` | [](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)Stops the task identified by `taskID` | [](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)None | [](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)None | [](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)`204` |

## [](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)5.3 The API struct

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)At this point, we’ve set the stage for writing the code for the worker API. We’ve identified the main components of our API, defined the data format used by that API, and enumerated the routes the API will support. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)We’re going to start by representing our API in code as the struct seen in listing 5.3. You should create a file named `api.go` in the `worker/` directory of your code where you can place this struct.

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)This struct serves several purposes. First, it contains the `Address` and `Port` fields, which define the local IP address of the machine where the API runs and the port on which the API will listen for requests. These fields will be used to start the API server, which we will implement later in the chapter. Second, it contains the `Worker` field, which will be a reference to an instance of a `Worker` object. Remember, we said the API will wrap the worker to expose the worker’s core functionality to the manager. This field is the means by which that functionality is exposed. Third, the struct contains the `Router` field, which is a pointer to an instance of `chi.Mux`. This field brings in all the functionality provided by the chi router. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)

##### Listing 5.3 The API struct that will power our worker

```
type Api struct {
   Address string
   Port    int
   Worker  *Worker
   Router  *chi.Mux
}
```

##### [](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)Definition

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)The term *mux* stands for *multiplexer* and can be used synonymously with *request router*. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)

## [](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)5.4 Handling requests

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)With the API struct defined[](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/), we’ve given the API a general shape, or form, at a high level. This shape will contain the API’s three components: handlers, routes, and a router. Let’s dive deeper into the API and implement the handlers that will be able to respond to the routes we defined in table 5.1. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)As we’ve already said, a *handler* is a function capable of responding to a request. For our API to handle incoming requests, we need to define handler methods on the `API` struct. We’re going to use the following three methods, which I’ll list here with their method signatures:[](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)

-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)`StartTaskHandler(w` `http.ResponseWriter,` `r` `*http.Request)`
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)`GetTasksHandler(w` `http.ResponseWriter,` `r` `*http.Request)`
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)`StopTaskHandler(w` `http.ResponseWriter,` `r` `*http.Request)`

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)There is nothing terribly complicated about these handler methods. Each method takes the same arguments, an `http.ReponseWriter` type and a pointer to an `http.Request` type. Both of these types are defined in the `http` package in Go’s standard library. The `http.ResponseWriter`’s `w` will contain data related to responses. The `http.Request`’s `r` will hold data related to requests. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)To implement these handlers, create a file named `handlers.go` in the `worker` directory of your project and then open that file in a text editor. We’ll start by adding the `StartTaskHandler` method seen in listing 5.4. At a high level, this method reads the body of a request from `r.Body`, converts the incoming data it finds in that body from JSON to an instance of our `task.TaskEvent` type, and then adds that `task.TaskEvent` to the worker’s queue. It wraps up by printing a log message and then adding a response code to the `http.ResponseWriter`. It takes incoming requests to start a task, reads the body of the request, converts it from JSON to a `task.TaskEvent`, and then puts that on the worker’s queue. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)

##### Listing 5.4 The worker’s `StartTaskHandler` method

```
func (a *Api) StartTaskHandler(w http.ResponseWriter, r *http.Request) {
    d := json.NewDecoder(r.Body)                      #1
    d.DisallowUnknownFields()                         #2
 
    te := task.TaskEvent{}                            #3
    err := d.Decode(&te)                              #4
    if err != nil {                                   #5
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
 
    a.Worker.AddTask(te.Task)                         #6
    log.Printf("Added task %v\n", te.Task.ID)         #7
    w.WriteHeader(201)                                #8
    json.NewEncoder(w).Encode(te.Task)                #9
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)The next method we’ll implement is the `GetTasksHandler` method in listing 5.5. This method looks simple, but there is a lot going on inside it. It starts off by setting the `Content-Type` header to let the client know we’re sending it JSON data. Then, similar to `StartTaskHandler`, it adds a response code. And then we come to the final line in the method. It may look a little complicated, but it’s really just a compact way to express the following operations:[](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)

-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)Gets an instance of a `json.Encoder` type by calling the `json.NewEncoder()` method [](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)Gets all the worker’s tasks by calling the worker’s `GetTasks` method [](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)Transforms the list of tasks into JSON by calling the `Encode` method on the `json.Encoder` object [](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)

##### Listing 5.5 The worker’s `GetTasksHandler`

```
func (a *Api) GetTasksHandler(w http.ResponseWriter, r *http.Request) {
   w.Header().Set("Content-Type", "application/json")
   w.WriteHeader(200)
   json.NewEncoder(w).Encode(a.Worker.GetTasks())
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)The final handler to implement is the `StopTaskHandler`. If we glance back at table 5.2, we can see that stopping a task is accomplished by sending a request with a path of `/tasks/{taskID}`. An example of what this path will look like when a real request is made is `/tasks/6be4cb6b-61d1-40cb-bc7b-9cacefefa60c`. This is all that’s needed to stop a task because the worker already knows about the task: it has it stored in its `Db` field. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)The first thing the `StopTaskHandler` must do is read the `taskID` from the request path. As you can see in listing 5.6, we’re doing that by using a helper function named `URLParam` from the chi package. We’re not going to worry about how the helper method is getting the `taskID` for us; all we care about is that it simplifies our life a bit and gives us the data we need to get on with the job of stopping a task. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)Now that we have the `taskID`, we have to convert it from a string, which is the type that `chi.URLParam` returns to us, into a `uuid.UUID` type. This conversion is done by calling the `uuid.Parse()` method and passing it the string version of the `taskID`. Why do we have to perform this step? It’s necessary because the worker’s `Db` field is a map that has keys of type `uuid.UUID`. So if we were to try to look up a task using a string, the compiler would yell at us. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)Okay, now we have a `taskID` and have converted it to the correct type. The next thing we want to do is check whether the worker knows about this task. If it doesn’t, we should return a response with a `404` status code. If it does, we change the state to `task.Completed` and add it to the worker’s queue. This is what the remaining of the method is doing. The worker’s `StopTaskHandler` uses the `taskID` from the request path to add a task to the worker’s queue that will stop the specified task. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)

##### Listing 5.6 The worker’s `StopTaskHandler`

```
func (a *Api) StopTaskHandler(w http.ResponseWriter, r *http.Request) {
    taskID := chi.URLParam(r, "taskID")                                  #1
    if taskID == "" {                                                    #2
        log.Printf("No taskID passed in request.\n")
        w.WriteHeader(400)
    }
 
    tID, _ := uuid.Parse(taskID)                                         #3
    _, ok := a.Worker.Db[tID]                                            #4
    if !ok {                                                             #5
        log.Printf("No task with ID %v found", tID)
        w.WriteHeader(404)
    }
 
    taskToStop := a.Worker.Db[tID]                                       #6
    taskCopy := *taskToStop                                              #7
    taskCopy.State = task.Completed                                      #8
    a.Worker.AddTask(taskCopy)                                           #9
 
    log.Printf("Added task %v to stop container %v\n", taskToStop.ID,
         taskToStop.ContainerID)                                       #10
    w.WriteHeader(204)                                                   #11
}
#1 Extracts the {taskID} from the request path and stores it in taskID
#2 Checks whether taskID is an empty string; if it is, returns a 400 status code
#3 Converts the taskID from a string to a uuid.UUID and stores it in tID
#4 Queries the worker’s datastore for the UUID. This idiom is called the “comma, ok” idiom, and will set the ok variable to true if the tID key is found in the datastore; otherwise, it will set ok to false. Also, we’re using the blank identifier, which is a placeholder whose value we don’t care about.
#5 Checks the value of ok; if it’s false, returns a 404 status code because the worker doesn’t know about the task
#6 Retrieves a pointer to the task with an ID of tID and stores it in taskToStop
#7 Makes a copy of taskToStop and stores it in taskCopy
#8 Sets the state of TaskCopy to task.Completed
#9 Adds the task to the worker’s queue
#10 Writes a log message
#11 Returns a response with a status code of 204
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)There is one little gotcha in our `StopTaskHandler` that’s worth explaining in more detail. Notice that we’re making a copy of the task in the worker’s datastore. Why is this necessary?

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)As I mentioned in chapter 4, we’re using the worker’s datastore to represent the current state of tasks, while we’re using the worker’s queue to represent the desired state of tasks. As a result of this decision, the API cannot simply retrieve the task from the worker’s datastore, set the state to `task.Completed`, and then put the task onto the worker’s queue. The reason is that the values in the datastore are pointers to `task.Task` types. If we were to change the state on `taskToStop`, we would be changing the state field on the task in the datastore. We would then add the same task to the worker’s queue, and when it popped the task off to work on it, it would complain about not being able to transition a task from the state `task.Completed` to `task.Completed`. Hence, we make a copy, change the state on the copy, and add it to the queue[](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/). [](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)

## [](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)5.5 Serving the API

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)Up to this point, we’ve been setting the stage for serving the worker’s API. We’ve created our `API` struct that contains the two components that will make this possible: the `Worker` and `Router` fields. Each of these is a pointer to another type. The `Worker` field is a pointer to our own `Worker` type that we created in chapter 3, and it will provide all the functionality to start and stop tasks and get a list of tasks the worker knows about. The `Router` field is a pointer to a `Mux` object provided by the chi package, and it will provide the functionality for defining routes and routing requests to the handlers we defined earlier. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)To serve the worker’s API, we need to make two additions to the code we’ve written so far. Both additions will be made to the `api.go` file.

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)The first addition is to add the `initRouter()` method to the `Api` struct, as you see in listing 5.7. This method, as its name suggests, initializes our router. It starts by creating an instance of a `Router` by calling `chi.NewRouter()`. Then it goes about setting up the routes we defined in table 5.2. We won’t get into the internals of how the chi package creates these routes. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)

##### Listing 5.7 The `initRouter()` method

```
func (a *Api) initRouter() {
    a.Router = chi.NewRouter()                         #1
    a.Router.Route("/tasks", func(r chi.Router) {      #2
        r.Post("/", a.StartTaskHandler)                #3
        r.Get("/", a.GetTasksHandler)
        r.Route("/{taskID}", func(r chi.Router) {      #4
            r.Delete("/", a.StopTaskHandler)           #5
        })
    })
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)The final addition is to add the `Start()` method to the `Api` struct, as you see in listing 5.8. This method calls the `initRouter` method defined in listing 5.4, and then it starts an HTTP server that will listen for requests. The `ListenAndServe` function is provided by the `http` package from Go’s standard library. It takes an address (e.g. `127.0.0.1:5555`), which we’re building with the `fmt.Sprintf` function, and a handler, which for our purposes is the router that gets created in the `initRouter()` method. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)

##### Listing 5.8 The `Start()` method: Initializes our router and starts listening for requests

```
func (a *Api) Start() {
   a.initRouter()
   http.ListenAndServe(fmt.Sprintf("%s:%d", a.Address, a.Port), a.Router)
}
```

## [](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)5.6 Putting it all together

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)Like we’ve done in previous chapters, it’s time to take the code we’ve written and actually run it. To do this, we’re going to continue our use of `main.go`, in which we’ll write our `main` function. You can either reuse the `main.go` file from the last chapter and just delete the contents of the main function or start with a fresh file. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)In your `main.go` file, add the `main()` function from listing 5.9. This function uses all the work we’ve done up to this point. It creates an instance of our worker, `w`, which has a `Queue` and a `Db`. It creates an instance of our API, `api`, which uses the `host` and `port` values that it reads from the local environment. Finally, the `main()` function performs the two operations that bring everything to life.

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)The first of these operations is to call a function `runTasks` and pass it a pointer to the worker `w`. But it also does something else. It has this funny `go` term before calling the `runTasks` function. What is that about? If you’ve used threads in other languages, the `go` `runTasks(&w)` line is similar to using threads. In Go, threads are called *goroutines*, and they provide the ability to perform concurrent programming. We won’t go into the details of goroutines here because there are other resources dedicated solely to this topic. For our purposes, all we need to know is that we’re creating a goroutine, and inside it, we will run the `runTasks` function. After creating the goroutine, we can continue on in the main function and start our API by calling `api.Start()`. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)

##### Listing 5.9 Running our worker from `main.go`

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
   api.Start()
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)Now, let’s talk about the `runTasks` function, which you can see in listing 5.10. This function runs in a separate goroutine from the main function, and it’s fairly simple. It’s a continuous loop that checks the worker’s queue for tasks and calls the worker’s `RunTask` method when it finds tasks that need to run. For our own convenience, we’re sleeping for 10 seconds between each iteration of the loop. This slows things down for us so we can easily read any log messages.

##### Listing 5.10 The `runTasks` function

```
func runTasks(w *worker.Worker) {
   for {
       if w.Queue.Len() != 0 {
           result := w.RunTask()
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

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)There is a reason that we’ve structured our main function like this. Recall the handler functions we wrote earlier in the chapter; they were performing a very narrow set of operations, namely:

-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)Reading requests sent to the server
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)Getting a list of tasks from the worker (in the case of the `GetTasksHandler`)
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)Putting a task on the worker’s queue
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)Sending a response to the requester

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)Notice that the API is not calling any worker methods that perform task operations (i.e., it is not starting or stopping tasks). Structuring our code in this way allows us to separate the concern of handling requests from the concern of performing the operations to start and stop tasks. Thus, we make it easier on ourselves to reason about our codebase. If we want to add a feature or fix a bug with the API, we know we need to work in the `api.go` file. If we want to do the same for request handling, we need to work in the `handlers.go` file. And for anything related to the operations of starting and stopping tasks, we need to work in the `worker.go` file.

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)Okay, time to make some magic. Running our code should result in a number of log messages being printed to the terminal like this:

```bash
$ CUBE_HOST=localhost CUBE_PORT=5555 go run main.go    #1
Starting Cube worker                                   #2
2021/11/05 14:17:53 No tasks to process currently.     #3
2021/11/05 14:17:53 Sleeping for 10 seconds.
2021/11/05 14:18:03 No tasks to process currently.     #4
2021/11/05 14:18:03 Sleeping for 10 seconds.
2021/11/05 14:18:13 No tasks to process currently.     #5
2021/11/05 14:18:13 Sleeping for 10 seconds.
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)As you can see when we first start the worker API, it doesn’t do much. It tells us it doesn’t have any tasks to process, sleeps for 10 seconds, and then wakes up again and tells us the same thing. This isn’t very exciting. Let’s spice things up by interacting with the worker API. We’ll start with getting a list of tasks using the `curl` command in a separate terminal:[](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)

```bash
$ curl -v localhost:5555/tasks                        #1
*   Trying 127.0.0.1:5555...
* Connected to localhost (127.0.0.1) port 5555 (#0)   #2
> GET /tasks HTTP/1.1                                 #3
> Host: localhost:5555
> User-Agent: curl/7.78.0
> Accept: */*
>
* Mark bundle as not supporting multiuse
< HTTP/1.1 200 OK                                     #4
< Content-Type: application/json
< Date: Fri, 05 Nov 2021 18:27:25 GMT
< Content-Length: 3
<
[]                                                    #5
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)Great! We can query the API to get a list of tasks. As expected, though, the response is an empty list because the worker doesn’t have any tasks yet. Let’s remedy that by sending it a request to start a task:

```
curl -v --request POST \                              #1
  --header 'Content-Type: application/json' \         #2
  --data '{                                           #3
    "ID": "266592cd-960d-4091-981c-8c25c44b1018",
    "State": 2,
    "Task": {                                         #1
        "State": 1,
        "ID": "266592cd-960d-4091-981c-8c25c44b1018",
        "Name": "test-chapter-5-1",
        "Image": "strm/helloworld-http"
    }
}'
localhost:5555/tasks
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)When you run the `curl` command, you should see output like the following. Notice that the status code in the response is `HTTP/1.1` `201` `Created`, and there is no response body:[](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)

```
*   Trying 127.0.0.1:5555...
* Connected to localhost (127.0.0.1) port 5555 (#0)
> POST /tasks HTTP/1.1
> Host: localhost:5555
> User-Agent: curl/7.80.0
> Accept: */*
> Content-Type: application/json
> Content-Length: 243
>
* Mark bundle as not supporting multiuse
< HTTP/1.1 201 Created
< Date: Mon, 29 Nov 2021 22:24:51 GMT
<
* Connection #0 to host localhost left intact
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)At the same time that you run the `curl` command, you should see log messages in the terminal where the API is running. Those log messages should look like this:[](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)

```
2021/11/05 14:47:47 Added task 266592cd-960d-4091-981c-8c25c44b1018
Found task in queue: {266592cd-960d-4091-981c-8c25c44b1018
     test-chapter-5-1 1 strm/helloworld-http 0 0 map[] map[]
     0001-01-01 00:00:00 +0000 UTC 0001-01-01 00:00:00 +0000 UTC}:
{"status":"Pulling from strm/helloworld-http","id":"latest"}
{"status":"Digest:
     sha256:bd44b0ca80c26b5eba984bf49"}
{"status":"Status: Image is up to date for strm/helloworld-http:latest"}
2021/11/05 14:47:53 Sleeping for 10 seconds.
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)Great! At this point, we’ve created a task by calling the worker API’s `POST` `/tasks` route. Now, when we make a `GET` request to `/tasks`, instead of seeing an empty list, we should see output like this:[](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)

```bash
$ curl -v localhost:5555/tasks
*   Trying 127.0.0.1:5555...
* Connected to localhost (127.0.0.1) port 5555 (#0)
> GET /tasks HTTP/1.1
> Host: localhost:5555
> User-Agent: curl/7.78.0
> Accept: */*
>
* Mark bundle as not supporting multiuse
< HTTP/1.1 200 OK
< Content-Type: application/json
< Date: Fri, 05 Nov 2021 19:17:55 GMT
< Content-Length: 346
<
[
 {
   "ID":"266592cd-960d-4091-981c-8c25c44b1018",
   "ContainerID": "6df4e15a5c840b0ece1aede53",
   "Name":"test-chapter-5-1",
   "State":2,
   "Image":"strm/helloworld-http",
   "Memory":0,
   "Disk":0,
   "ExposedPorts":null,
   "PortBindings":null,
   "RestartPolicy":"",
   "StartTime":"0001-01-01T00:00:00Z",
   "FinishTime":"0001-01-01T00:00:00Z"
 }
]
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)Also, we should see a container running on our local machine, which we can verify using the `docker` `ps`:

```bash
$ docker ps --format "table {{.ID}}\t{{.Image}}\t{{.Status}}\t{{.Names}}"
CONTAINER ID   IMAGE                  STATUS          NAMES
6df4e15a5c84   strm/helloworld-http   Up 35 minutes   test-chapter-5-1
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)So far, we’ve queried the worker API to get a list of tasks by making a `GET` request to the `/tasks` route. Seeing the worker didn’t have any, we created one by making a `POST` request to the `/tasks` route. Upon querying the API again by making a subsequent `GET` request `/tasks`, we got back a list containing our task. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)Now let’s exercise the last bit of the worker’s API functionality and stop our task. We can do this by making a `DELETE` request to the `/tasks/<taskID>` route, using the `ID` field from our previous `GET` request:[](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)

```bash
$ curl -v --request DELETE
     "localhost:5555/tasks/266592cd-960d-4091-981c-8c25c44b1018"
*   Trying 127.0.0.1:5555...
* Connected to localhost (127.0.0.1) port 5555 (#0)
> DELETE /tasks/266592cd-960d-4091-981c-8c25c44b1018 HTTP/1.1
> Host: localhost:5555
> User-Agent: curl/7.78.0
> Accept: */*
>
* Mark bundle as not supporting multiuse
< HTTP/1.1 204 No Content
< Date: Fri, 05 Nov 2021 19:25:47 GMT
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)In addition to seeing that our request received an `HTTP/1.1` `204` `No` `Content` response, we should see log output from the worker API that looks like the following:

```
2021/11/05 15:25:47 Added task 266592cd-960d-4091-981c-8c25c44b1018 to stop
     container 6df4e15a5c840b0ece1aede53
Found task in queue:
     {266592cd-960d-4091-981c-8c25c44b1018
     6df4e15a5c840b0ece1aede5378e344fb672c2516196117dd37c3ae055b402d2
     test-chapter-5-1 3 strm/helloworld-http 0 0 map[] map[]
     0001-01-01 00:00:00 +0000 UTC 0001-01-01 00:00:00 +0000 UTC}:
2021/11/05 15:25:54 Attempting to stop container
     6df4e15a5c840b0ece1aede53
2021/11/05 15:26:05 Stopped and removed container
     6df4e15a5c840b0ece1aede5378e344fb672c2516196117dd37c3ae055b402d2
     for task 266592cd-960d-4091-981c-8c25c44b1018
2021/11/05 15:26:05 Sleeping for 10 seconds.
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)We can confirm it’s been stopped by checking the output of `docker` `ps` again:

```bash
$ docker ps
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)We can also confirm by querying the API and checking the state of our task. In the response to our `GET` `/tasks` request, we should see the `State` of the task is `3`:[](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)

```bash
$ curl -v localhost:5555/tasks
*   Trying 127.0.0.1:5555...
* Connected to localhost (127.0.0.1) port 5555 (#0)
> GET /tasks HTTP/1.1
> Host: localhost:5555
> User-Agent: curl/7.78.0
> Accept: */*
>
* Mark bundle as not supporting multiuse
< HTTP/1.1 200 OK
< Content-Type: application/json
< Date: Fri, 05 Nov 2021 19:31:36 GMT
< Content-Length: 356
<
[
  {
    "ID":"266592cd-960d-4091-981c-8c25c44b1018",
    "ContainerID":
      "20d50c12fb2243f96183b81c00942a123cd2a48e463cc971dafedcadedfbd2d8",
    "Name":"test-chapter-5-1",
    "State":3,
    "Image":"strm/helloworld-http",
    "Memory":0,
    "Disk":0,
    "ExposedPorts":null,
    "PortBindings":null,
    "RestartPolicy":"",
    "StartTime":"0001-01-01T00:00:00Z",
    "FinishTime":"2021-11-05T19:30:04.661208966Z"
  }
]
```

## [](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)Summary

-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)The API wraps the worker’s functionality and exposes it as an HTTP server, thus making it accessible over a network. This strategy of exposing the worker’s functionality as a web API will allow the manager to start and stop tasks, as well as query the state of tasks across one or more workers.
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)The API is made up of handlers, routes, and a router. *Handlers* are functions that accept a request and know how to process it and return a response. *Routes* are patterns that can be used to match the URL of incoming requests (e.g., `/tasks`). Finally, a *router* is the glue that makes it all work by using the routes to route requests to the handlers.
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)The API uses the standard HTTP methods like `GET`, `POST`, and `DELETE` to define the operations that will occur for a given route. For example, calling `GET` `/tasks` will return a list of tasks from the worker.
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)While the API wraps the worker’s functionality, it does not interact with that functionality itself. Instead, it simply performs some administrative work and then places the task on the worker’s queue. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-5/)

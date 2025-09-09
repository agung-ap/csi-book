# [](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)11 Implementing persistent storage for tasks

### This chapter covers

- Describing the purpose of a datastore in an orchestration system
- Defining the requirements for our persistent datastore
- Defining the `Store` interface
- Introducing BoltDB
- Implementing the persistent datastore using the `Store` interface
- Discussing the special concerns that exist for the manager’s datastore

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)The fundamental unit of our orchestration system is the `task`. Up until now, we have been keeping track of this fundamental unit by storing it in Go’s built-in `map` type. Both our worker and our manager store their respective tasks in a map. This strategy has served us well, but you may have noticed a major problem with it: any time we restart the worker or the manager, they lose all their tasks. The reason they lose their tasks is that Go’s built-in map is an in-memory data structure and is not persisted to disk. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)Similar to how we revisited our earlier decisions around scheduling tasks, we’re now going to return to our decision about how we store them. We’re going to talk briefly about the purpose of a datastore in an orchestration system, and then we’re going to start the process of replacing our previous in-memory map datastore with a persistent one.

## [](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)11.1 The storage problem

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)Why do we need to store the tasks in our orchestration system? While we haven’t talked much about the problem, the storage of tasks is crucial to a working orchestration system. Storing tasks in some kind of datastore enables the higher-level functionality of our system:[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)

-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)It enables the system to keep track of each task’s current state.
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)It enables the system to make informed decisions about scheduling.
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)It enables the system to help tasks recover from failures.

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)As we mentioned earlier, our current implementation uses Go’s built-in map type, which means we’re storing tasks in memory. If we stop the manager and then start it back up because, say, we made a code change, the manager loses the state of all its tasks. We then have no way to recover the system as a whole. If we start our system with three workers and a manager, restarting the manager means we can’t gracefully stop running tasks by calling the manager’s API. For example, we can’t call `curl` `-X` `DELETE` `http:localhost:5555/tasks/1234567890`. The manager no longer has any knowledge of that task.

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)At a basic level, the solution to the problem is to replace the in-memory map with a persistent datastore. Such a solution will write the task state to disk, thus enabling the manager and worker to be restarted without any loss of state. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)

## [](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)11.2 The Store interface

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)Before jumping directly to a persistent storage solution, let’s follow the same process we used in the last chapter. Remember, we didn’t just jump straight to the E-PVM scheduler. Instead, we started by creating the `Scheduler` interface, and then we adapted the existing round-robin scheduler to the interface. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)The mental model of our store interface looks like that shown in figure 11.1. At the top of the model, we have the `Manager` and `Worker`, each using the same `Store` interface. That interface is abstract, but as we can see, it sits on top of two concrete implementations: an `In-memory` `Store` and a `Persistent` `Store`. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)

![Figure 11.1 The mental model of our store interface](https://drek4537l1klr.cloudfront.net/boring/Figures/11-01.png)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)If we think about the operations we have been using to store and retrieve tasks and task events, we can identify four methods to create an interface. Those four methods are

-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)`Put(key` `string,` `value` `interface{})`
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)`Get(key)`
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)`List()`
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)`Count()`

##### Note

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/) You might be wondering why the list doesn’t include a `Remove` or `Delete` method. Theoretically, the datastore serves as a historical record of the tasks in an orchestration system, so it doesn’t make sense to provide a method to remove history. In practice, however, it could be useful to provide such a method. For example, over time, an orchestration system would build up a datastore containing tens of thousands of tasks, if not hundreds of thousands or more. If the datastore supports the `Remove` operation, it could be used to perform maintenance on the datastore itself. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)The `Put` method, as its name suggests, puts an item, identified by a `key`, into the store. Until now, we have been interacting with our store by saving tasks and task events directly in a map. For example, in the manager’s `SendWork` method, we can see several examples of interacting directly with the `TaskDb` and `EventDb` stores. In the first example, we pop a task event off the manager’s `Pending` queue, convert it to the `task .TaskEvent` type, and then store a pointer to the `task.TaskEvent` in the `EventDb` using the task event’s ID as the key. In the second example, we extract the task from the task event and then store a pointer to it in the `TaskDb` using the task’s ID as the key. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)

##### Listing 11.1 Examples of using Go’s built-in map to store tasks and events

```
e := m.Pending.Dequeue()
te := e.(task.TaskEvent)
m.EventDb[te.ID] = &te          #1
 
t := te.Task
// code hidden for the sake of brevity
 
t.State = task.Scheduled
 
m.TaskDb[t.ID] = &t             #2
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)There is nothing technically wrong with how we’ve implemented the task and task event stores up to now. It is quick and easy. More importantly, it just works. One downside to this implementation, however, is that it is dependent on the underlying data structure underpinning the store. In this case, the manager must know how to put items into and retrieve them from Go’s built-in map. In other words, we have tightly coupled the manager to the built-in map type. We cannot easily change out this implementation of the store for some other implementation. For example, what if we wanted to use SQLite, a popular SQL-based embedded datastore?

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)To make it easier for us to use different implementations of a datastore, let’s create the `Store` interface seen in the next listing. The interface includes the four methods we listed previously, `Put`, `Get`, `List`, and `Count`.

##### Listing 11.2 The `Store` interface

```
type Store interface {
   Put(key string, value interface{}) error
   Get(key string) (interface{}, error)
   List() (interface{}, error)
   Count() (int, error)
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)One thing to note in our `Store` interface is that we have declared several values in the method signatures as being of type `interface{}`. The *empty interface*, as this is called, means that the value can be of any type. For example, the `Put` method takes a `key` that is a string and a `value` that is an empty interface or any type. This means the `Put` method can accept a `value` that is a `task.Task`, `task.TaskEvent`, or some other type. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)With the `Store` interface defined, let’s move on and implement an in-memory store that can replace our existing one. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)

## [](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)11.3 Implementing an in-memory store for tasks

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)We’re going to start with an implementation of the task store, and then we’ll move on to the task events store. Both the manager and worker use task stores, but only the manager uses an event store. The new implementations of the task and event stores will both wrap Go’s built-in map type. By wrapping the built-in map type, we can remove the manager’s coupling to the underlying data structure. Instead of needing to understand the mechanics of a map, the manager will simply call the methods of the `Store` interface, and the implementation of the interface will handle all the lower-level details of how to interact with the underlying data structure. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)For our purposes, we’re going to implement separate types for the task and event stores. We could create a generate store that is able to operate on both tasks and events, but that is more complex and would involve additional concepts that are beyond the scope of this book.

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)The first implementation is the `InMemoryTaskStore`, which provides a wrapper around Go’s built-in map type for the purpose of storing tasks. We start by defining a struct and giving it a single field called `Db`. Not surprisingly, this field is of type `map[string]*task.Task`, the same as the current implementation. Next, let’s define a helper function that will return an instance of the `InMemoryTaskStore`. We’ll call this helper function `NewInMemoryTaskStore`, and it takes no arguments and returns a pointer to an `InMemoryTaskStore` that has its `Db` field initialized to an empty map of type `map[string]*task.Task`. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)

##### Listing 11.3 The `InMemoryTaskStore` struct

```
type InMemoryTaskStore struct {
   Db map[string]*task.Task
}

func NewInMemoryTaskStore() *InMemoryTaskStore {
   return &InMemoryTaskStore{
       Db: make(map[string]*task.Task),
   }
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)Let’s move on and implement the `Put` method. The sequence diagram in figure 11.2 shows how the `Put` method will be used. When a user calls the manager’s API to start a task (`POST` `/tasks`), the manager will call the `Put` method to store the task in its own datastore. Then the manager sends the task to the worker by calling the worker’s API. The worker, in turn, calls the `Put` method to store the task in its datastore. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)

![Figure 11.2 Sequence diagram illustrating how the manager and worker save tasks to their respective datastores using the Put method](https://drek4537l1klr.cloudfront.net/boring/Figures/11-02.png)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)The implementation of the `Put` method, seen in listing 11.4, is fairly straightforward. The method takes two arguments: a `key` that is of type string and a `value` that is of the empty interface type. In the body of the method, we first attempt to convert the `value` to a concrete type using a *type assertion*. What we are doing is asserting that `value` is not `nil` and that the value in `value` is a pointer to a `task.Task`. We also capture a Boolean named `ok`, which tells us whether the assertion was successful. If the assertion is not successful, we return an error; otherwise, we store the task `t` in the map. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)

##### Listing 11.4 The `Put` method

```
func (i *InMemoryTaskStore) Put(key string, value interface{}) error {
   t, ok := value.(*task.Task)
   if !ok {
       return fmt.Errorf("value %v is not a task.Task type", value)
   }
   i.Db[key] = t
   return nil
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)Next, we’ll implement the `Get` method. The sequence diagram in figure 11.3 shows how the `Get` method will be used. When a user calls the manager’s API to get a task (`Get` `/tasks/{taskID}`), the manager will call the `Get` method to retrieve the task from its datastore and return it. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)

![Figure 11.3 Sequence diagram illustrating how the manager retrieves tasks from its datastore using the Get method](https://drek4537l1klr.cloudfront.net/boring/Figures/11-03.png)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)The implementation of the `Get` method takes a `key` of type string and returns an empty interface and potentially an error. We start by looking for the `key` in the store’s `Db`. Notice that we’re using the “comma ok” idiom here too. If the `key` exists in `Db`, `t` will contain the task identified by the `key`, and we will return it. If it does not exist, `t` will be `nil`, `ok` will be `false`, and we will return an error.

##### Listing 11.5 The `Get` method

```
func (i *InMemoryTaskStore) Get(key string) (interface{}, error) {
   t, ok := i.Db[key]
   if !ok {
       return nil, fmt.Errorf("task with key %s does not exist", key)
   }

   return t, nil
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)The next method we’ll implement is the `List` method. The `List` method builds up a slice of tasks by ranging over the map. This method always returns `nil` for the `error` value. This is necessary in order to conform to the contract specified by the `Store` interface. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)Unlike the `Get` method, which returns a single task, this method returns all the tasks in the store. As you can see in listing 11.6, we start by creating a variable called `tasks` as a slice of pointers to `task.Task`. This slice will hold all the tasks in the store. Then we range over the map in the `Db` field and append each task to the `tasks` slice. Once we’ve ranged over all the tasks and appended them to the slice, we return it.

##### Listing 11.6 The `List` method

```
func (i *InMemoryTaskStore) List() (interface{}, error) {
   var tasks []*task.Task
   for _, t := range i.Db {
       tasks = append(tasks, t)
   }
   return tasks, nil
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)The final method in our task store is `Count`. As its name implies, this method returns the number of tasks contained in the store’s `Db` field. Because `Db` is a map, we can get the count of items using the built-in `len` function. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)

##### Listing 11.7 The `Count` function

```
func (i *InMemoryTaskStore) Count() (int, error) {
   return len(i.Db), nil
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)Now that we’ve implemented an in-memory version of the task store, let’s move on and do the same thing for task events. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)

## [](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)11.4 Implementing an in-memory store for task events

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)The store for the task events will be identical to the one for tasks. The obvious difference will be that the task events store will operate on the `task.TaskEvent` type and not `task.Task`. Because the differences are minor, we won’t go into the details. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)

##### Listing 11.8 The `InMemoryTaskEventStore`

```
type InMemoryTaskEventStore struct {
   Db map[string]*task.TaskEvent
}

func NewInMemoryTaskEventStore() *InMemoryTaskEventStore {
   return &InMemoryTaskEventStore{
       Db: make(map[string]*task.TaskEvent),
   }
}

func (i *InMemoryTaskEventStore) Put(key string, value interface{}) error {
   e, ok := value.(*task.TaskEvent)
   if !ok {
       return fmt.Errorf("value %v is not a task.TaskEvent type", value)
   }
   i.Db[key] = e
   return nil
}

func (i *InMemoryTaskEventStore) Get(key string) (interface{}, error) {
   e, ok := i.Db[key]
   if !ok {
       return nil, fmt.Errorf("task event with key %s does not exist", key)
   }

   return e, nil
}

func (i *InMemoryTaskEventStore) List() (interface{}, error) {
   var events []*task.TaskEvent
   for _, e := range i.Db {
       events = append(events, e)
   }
   return events, nil
}

func (i *InMemoryTaskEventStore) Count() (int, error) {
   return len(i.Db), nil
}
```

## [](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)11.5 Refactoring the manager to use the new in-memory stores

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)At this point, we have defined an interface that will allow us to store tasks and events. We have also implemented two concrete types of our store interface, both of which wrap Go’s built-in map type and remove the need for the manager and worker to interact with it directly. Let’s make some changes to the manager and worker so they can make use of our new code. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)Starting with the manager, we need to update the `TaskDb` and `EventDb` fields on the `Manager` struct. Instead of these fields being of type `map[uuid.UUID]*task.Task` and `map[uuid.UUID]*task.TaskEvent`, let’s change them both to be of type `store.Store`. With this change, our manager can now use any kind of store that implements the `store.Store` interface:[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)

```
type Manager struct {
   // fields omitted for convenience
   TaskDb        store.Store
   EventDb       store.Store
   // fields omitted
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)Changing the `TaskDb` and `EventDb` fields to an interface type should look familiar to you. If you remember, in chapter 10, we did something similar when we introduced the `Scheduler` field, which was of type `scheduler.Scheduler`, also an interface. That change allowed us to configure the manager to use different types of schedulers, and now we have configured it to use different types of stores. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)Next, let’s modify the `New` function in the manager package. In the last chapter, we updated it so it accepted a `schedulerType` in addition to a slice of `workers`. Now let’s add another argument to the `New` function, one called `dbType`. The new signature will look like the following:[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)

```
func New(workers []string, schedulerType string, dbType string) *Manager
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)There are several changes to the body of the `New` function that we’ll need to make next. The first of these changes is to remove the initialization of the `taskDb` and `eventDb` variables using the `make()` built-in function. Just delete those two lines for now. We’re going to do something slightly different here in a bit. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)Now we want to change how we’re returning from the function. We are currently returning a pointer to the `Manager` type like this:[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)

```
return &Manager{ ... }
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)Instead of returning a pointer using what’s called a *struct literal*[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/), let’s assign it to a variable named `m`. It will look like the following listing.

##### Listing 11.9 Assigning a struct literal to the `m` variable instead of returning it

```
m := Manager{
   Pending:       *queue.New(),
   Workers:       workers,
   WorkerTaskMap: workerTaskMap,
   TaskWorkerMap: taskWorkerMap,
   WorkerNodes:   nodes,
   Scheduler:     s,
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)At this point, we have an instance of our `Manager` type, but it does not have any stores for tasks and events. We’re going to use the `dbType` variable we added to the `New` function’s signature as part of a `switch` statement to allow us to set up different types of datastores based on the value of `dbType`. Because we’ve only implemented in-memory stores, we’re going to start by only supporting the case where the value of `dbType` is `memory`. In this case, we call the `NewInMemoryTaskStore` function to create an instance of our in-memory task store, and we call the `NewInMemoryTaskEventStore` function to create an instance of our in-memory event store. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)All that’s left to do now is to assign the value of the `ts` variable to the manager’s `TaskDb` field and assign the `es` value to the manager’s `EventDb` field. Then return a pointer to the manager:[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)

```
var ts store.Store                         #1
var es store.Store
switch dbType {                            #2
case "memory":                             #3
    ts = store.NewInMemoryTaskStore()
    es = store.NewInMemoryTaskEventStore()
}
 
m.TaskDb = ts                              #4
m.EventDb = es                             #5
return &m                                  #6
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)Now we’re ready for the substantive changes! We need to change the manager’s methods so it interacts with the datastore using the methods of our new `Store` interface instead of operating directly on the map structures. The first method we’ll work on is `updateTasks`. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)All of the changes we need to make in the `updateTasks` method occur inside the `for` loop that ranges over a slice of pointers to `task.Task` types. The first change to make involves replacing the block of code that checks whether an individual task reported by a worker exists in the manager’s task store. The current code uses the “comma ok” idiom to perform this check. We’ll replace this block with a call to the store interface’s `Get` method and check the `err` value to indicate that the task doesn’t exist in the manager’s store. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)We can see this change in listing 11.10. The existing code is commented out, and its replacement follows just afterward. Now our updated code is calling the `Get` method on the manager’s `TaskDb` store, passing it the `ID` of the task as a string. If the task exists in the manager’s store, it will be assigned to the `result` variable, and if there is an error, it will be assigned to the `err` variable. Next, we perform the usual error checking, and if there is an error, we log it and move on to the next task using the `continue` statement. Finally, we use a type assertion to convert the `result`, which is of type `interface{}` to the concrete `task.Task` type (actually a pointer to a `task.Task`). If the type assertion fails, we log a message and continue to the next task. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)

##### Listing 11.10 Using the new datastore interface to get a task from TaskDb

```
for _, t := range tasks {

   // previous code omitted for convenience

   // existing code to be replaced
   // _, ok := m.TaskDb[t.ID]
   // if !ok {
   //     log.Printf("[manager] Task with ID %s not found\n", t.ID)
   //     continue
   // }

   result, err := m.TaskDb.Get(t.ID.String())
   if err != nil {
           log.Printf("[manager] %s\n", err)
           continue
   }
   taskPersisted, ok := result.(*task.Task)
   if !ok {
           log.Printf("cannot convert result %v to task.Task type\n", result)
           continue
   }
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)The last set of changes to make in the `updateTasks` method involves replacing the remaining direct operations on the existing map structure with calls to the appropriate methods of the `Store` interface. The existing code can be seen in the next listing. Here we are modifying a task by directly changing its fields in the map. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)

##### Listing 11.11 Existing code directly accessing the TaskDB map

```
if m.TaskDb[t.ID].State != t.State {

   m.TaskDb[t.ID].State = t.State

}
m.TaskDb[t.ID].StartTime = t.StartTime

m.TaskDb[t.ID].FinishTime = t.FinishTime

m.TaskDb[t.ID].ContainerID = t.ContainerID

m.TaskDb[t.ID].HostPorts = t.HostPorts
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)We want to replace the previous code with that shown in listing 11.12. Since we have already retrieved the task from the manager’s task store and converted it from an empty interface type to a pointer to the concrete `task.Task` type, we can simply update the necessary fields on the `taskPersisted` variable. Then we finish up by calling the store’s `Put` method to save the updated task. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)

##### Listing 11.12 Using the new datastore interface to put a task in the TaskDb

```
if taskPersisted.State != t.State {
       taskPersisted.State = t.State
}

taskPersisted.StartTime = t.StartTime
taskPersisted.FinishTime = t.FinishTime
taskPersisted.ContainerID = t.ContainerID
taskPersisted.HostPorts = t.HostPorts

m.TaskDb.Put(taskPersisted.ID.String(), taskPersisted)
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)The `GetTasks` method is the next method we need to update. It uses a `for` loop to range over all the tasks in the manager’s task store. Up to now, this method has been ranging directly over the map of tasks. So we need to change `GetTasks` to use the `Store` interface’s `List` method, convert the result from a slice of empty interfaces to a slice of pointers to `task.Task` types, and return that slice. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)

##### Listing 11.13 The `GetTasks` method

```
func (m *Manager) GetTasks() []*task.Task {
    taskList, err := m.TaskDb.List()                          #1
    if err != nil {                                           #2
        log.Printf("error getting list of tasks: %v\n", err)
        return nil
    }
 
    return taskList.([]*task.Task)                            #3
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)The next method that needs updating is the `restartTask` method. This one is easy. It currently has a single interaction with the map built-in, so all we need to do is replace it with a call to the store’s `Put` method. So it’s just a matter of replacing the first line with the second:[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)

```
// m.TaskDb[t.ID] = t
m.TaskDb.Put(t.ID.String(), t)
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)The final method to update is the `SendWork` method. Despite being a long method that encompasses a multistep process to send tasks to workers, we have only a few updates to make here. The first update involves our first interaction with the new `EventDb` store. We want to change from interacting directly with the old task events map to using the new `EventDb` store. Early on in the `SendWork` method, we popped an event off the manager’s `Pending` queue and converted it to `task.TaskEvent` type. Now we want to call the `Put` method on the events store, passing it the event `ID` as a string and a pointer to the task event `te`. If the call to `Put` returns an error, we log it and return. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)

##### Listing 11.14 The first change to the `SendWork` method, using the new `Put` method

```
e := m.Pending.Dequeue()
te := e.(task.TaskEvent)
err := m.EventDb.Put(te.ID.String(), &te)
if err != nil {
        log.Printf("error attempting to store task event %s: %s\n",
     te.ID.String(), err)
        return
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)The second update involves this method’s use of the tasks store. In listing 11.15, we can see the existing code where we are again interacting directly with the `TaskDb` map. Since this code is getting a task from the map, we want to convert the code to use the store interface’s `Get` method as we’ve done previously. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)

##### Listing 11.15 Existing code that gets a task from the store by operating directly on the map

```
taskWorker, ok := m.TaskWorkerMap[te.Task.ID]
if ok {
        persistedTask := m.TaskDb[te.Task.ID]
        if te.State == task.Completed && task.ValidStateTransition(
       persistedTask.State, te.State) {
            m.stopTask(taskWorker, te.Task.ID.String())
            return
        }
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)To change the code to use our new `Get` method on the store interface, we need to rearrange our code a little:

```
result, err := m.TaskDb.Get(te.Task.ID.String())                 #1
if err != nil {                                                  #2
        log.Printf("unable to schedule task: %s", err)
        return
}
 
persistedTask, ok := result.(*task.Task)                         #3
if !ok {                                                         #4
        log.Printf("unable to convert task to task.Task type")
        return
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)The final update to the `SendWork` method, and our final update to the manager, involves another change to use the task store’s `Put` method instead of inserting a task directly in a map:[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)

```
t.State = task.Scheduled
// m.TaskDb[t.ID] = &t
m.TaskDb.Put(t.ID.String(), &t)
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)In addition to the changes we just made on the `Manager` struct, we need to make one small change to the manager’s `StopTaskHandler` method on the `API` struct. There is one line where we are accessing the manager’s `TaskDb` map directly. Instead, we simply need to change this line to use the `Store` interface’s `Get` method. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)

##### Listing 11.16 Calling the `Store` interface’s `Get` method

```
// taskToStop, ok := a.Manager.TaskDb[tID]
taskToStop, err := a.Manager.TaskDb.Get(tID.String())
```

## [](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)11.6 Refactoring the worker

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)At this point, our manager is using the new `Store` interface. Our worker, however, is not. It’s still operating directly on the built-in map type. Let’s perform the same refactoring on the worker so it, too, uses the `Store` interface. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)Like the manager, the first order of business is to change the worker’s [](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)`Db` type from a `map[uuid.UUID]*task.Task` to the `store.Store` interface type. By doing so, it can use any type of store that implements the `store.Store` interface:

```
type Worker struct {
   // fields omitted
   Db    store.Store
   // fields omitted
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)Next, we need to update the `New` helper function in the `worker` package. Let’s update its function signature to take another argument. This new argument is named `taskDbType` and is a string. We then create a variable `s` that is of the new `store.Store` type. Now we use a switch statement on the `taskDbType` argument and assign the result of the `NewInMemoryTaskStore` function call to the variable `s`. Finally, we assign `s` to the worker’s `Db` field. We can then return a pointer to the worker `w`, which will include the store interface. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)

##### Listing 11.17 The `New` helper function creating an instance of the `InMemoryTaskStore`

```
func New(name string, taskDbType string) *Worker {
   w := Worker{
       Name:  name,
       Queue: *queue.New(),
   }

   var s store.Store
   switch taskDbType {
   case "memory":
       s = store.NewInMemoryTaskStore()
   }
   w.Db = s
   return &w
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)With the change to the `New` helper function, let’s move on to the worker’s methods. The first to modify is the `GetTasks` method. Remember, this method was previously operating directly on the worker’s `Db` map field. Since we’ve moved the logic that operates directly on the underlying store (in this case, a built-in map), we want `GetTasks` to use the store interface instead. We want to replace the body of `GetTasks` with the simplified version seen in the following listing. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)

##### Listing 11.18 The `GetTasks` method using the store interface’s `List` method

```
func (w *Worker) GetTasks() []*task.Task {
   taskList, err := w.Db.List()
   if err != nil {
       log.Printf("error getting list of tasks: %v\n", err)
       return nil
   }

   return taskList.([]*task.Task)
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)Next, we need to modify the `runTask` method. Like all of the previous code, it has been operating directly on the `Db` map. The beginning steps of this method are the following:[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)

1.  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)Pop a task off the worker’s `Queue`.
1.  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)Convert the task from an empty interface to a `task.Task` type.
1.  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)Get the task from the `Db` map.
1.  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)If the task doesn’t exist, create it.

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)Notice steps 3 and 4. The process attempts to get the task from the map by looking it up using the task’s `ID`. This operation, however, doesn’t return an error if the task isn’t in the map. Our `InMemoryTaskStore` implements the `Store` interface’s `Get` method, which returns an `error`. That error could be due to any number of factors. It could be because the task simply didn’t exist in the store or because there was some problem with interacting with the underlying store itself. So if we were to use the same order of operations when we switch to using the new `Store` interface, we’d have a problem. If the call to the store’s `Get` method returns an error, how do we distinguish whether it’s because the task didn’t exist or there was an error with the underlying store itself? In the former case, we want to create the task; in the latter case, we want to return an error. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)As we’ve done in the past, our solution is making a tradeoff. We’re going to switch the order of operations so that we call the store’s `Put` method first, which will effectively overwrite the task if it exists. If the call to `Put` does not return an error, then we call the store’s `Get` method to retrieve the task from the store. The `runTask` method changes the order of operations to account for our `Store` interface, including errors in return values. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)

##### Listing 11.19 The modified `runTask` method

```
func (w *Worker) runTask() task.DockerResult {
    // previous code omitted
 
    err := w.Db.Put(taskQueued.ID.String(), &taskQueued)
    if err != nil {
        msg := fmt.Errorf("error storing task %s: %v",
     taskQueued.ID.String(), err)
        log.Println(msg)
        return task.DockerResult{Error: msg}
    }
 
    queuedTask, err := w.Db.Get(taskQueued.ID.String())
    if err != nil {
        msg := fmt.Errorf("error getting task %s from database: %v",
     taskQueued.ID.String(), err)
        log.Println(msg)
        return task.DockerResult{Error: msg}
    }
 
    taskPersisted := *queuedTask.(*task.Task)
 
    // code omitted
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)The `StartTask` method is the next one that requires changes. It performs two operations on the task store. Each one is updating the state of the task and storing the updated task in the `Db`. In these cases, we can simply swap the direct operation on the map with a call to the new `Put` method, as seen in the following listing. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)

##### Listing 11.20 Using the `Put` method instead of directly operating on a map

```
func (w *Worker) StartTask(t task.Task) task.DockerResult {
   config := task.NewConfig(&t)
   d := task.NewDocker(config)
   result := d.Run()
   if result.Error != nil {
       log.Printf("Err running task %v: %v\n", t.ID, result.Error)
       t.State = task.Failed
       w.Db.Put(t.ID.String(), &t)
       return result
   }

   t.ContainerID = result.ContainerId
   t.State = task.Running
   w.Db.Put(t.ID.String(), &t)
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)Next, the `StopTask` method operates on the task store just once. Similar to the `StartTask` method, it updates the state of the task and saves it to the map. Again, we can simply swap out the direct interaction with the map and replace it with a call to the store’s `Put` method:[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)

```
func (w *Worker) StopTask(t task.Task) task.DockerResult {
    config := task.NewConfig(&t)
    d := task.NewDocker(config)
 
    stopResult := d.Stop(t.ContainerID)
    if stopResult.Error != nil {
        log.Printf("%v\n", stopResult.Error)
    }
    removeResult := d.Remove(t.ContainerID)
    if removeResult.Error != nil {
        log.Printf("%v\n", removeResult.Error)
    }
 
    t.FinishTime = time.Now().UTC()
    t.State = task.Completed
    w.Db.Put(t.ID.String(), &t)
    log.Printf("Stopped and removed container %v for task %v\n",
     t.ContainerID, t.ID)
 
    return removeResult
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)Finally, the `updateTasks` method operates on the task store four times. The first operation is a `for` loop that ranges over the worker’s `Db` map. Because Go supports iterating over a map, we were able to loop over the store directly. Go doesn’t support iterating over function call—it only returns once: [](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)

```
func (w *Worker) updateTasks() {
    tasks, err := w.Db.List()                                                      #1
    if err != nil {
        log.Printf("error getting list of tasks: %v\n", err)
        return
    }
    for _, t := range tasks.([]*task.Task) {                                      #2
        if t.State == task.Running {
            resp := w.InspectTask(*t)
            if resp.Error != nil {
                fmt.Printf("ERROR: %v\n", resp.Error)
            }
 
            if resp.Container == nil {
                log.Printf("No container for running task %s\n", t.ID)
                t.State = task.Failed
                w.Db.Put(t.ID.String(), t)                                        #3
            }
 
            if resp.Container.State.Status == "exited" {
                log.Printf("Container for task %s in non-running state %s\n", t.ID,
         resp.Container.State.Status)
                t.State = task.Failed
                w.Db.Put(t.ID.String(), t)                                        #4
            }
 
            t.HostPorts = resp.Container.NetworkSettings.NetworkSettingsBase.Ports#5
            w.Db.Put(t.ID.String(), t)                                            #6
        }
    }
}
#1 Calls the List method and assigns the results to variables
#2 Ranges over the tasks, which are converted from an empty interface to a slice of pointers to task.Task
#3 Updates the task’s state to task.Failed if it doesn’t have a container, calling Put to store the change
#4 Updates the task’s state to task.Failed if the task’s container status isn’t &quot;exited&quot;, calling Put to store the change
#5 Updates the task’s network ports
#6 Calls the Put method to store the change
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)Similar to the changes we made to the manager, we also need to update the worker’s API handlers to use the `Store` interface. There are two changes we need to make, one to the `InspectTaskHandler` and one to the `StopTaskHandler`. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)In the `InspectTaskHandler`, we need to call the `Store` interface’s `Get` method instead of directly accessing the task map:[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)

```
// t, ok := a.Worker.Db[tID]
t, err := a.Worker.Db.Get(tID.String())
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)We need to make a similar change in the `StopTaskHandler`:

```
// taskToStop, ok := a.Worker.Db[tID]
taskToStop, err := a.Worker.Db.Get(tID.String())
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)With those last two changes, we have completed the refactoring of the worker and the manager. Both now use the methods from our new `Store` interface. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)

## [](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)11.7 Putting it all together

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)At this point, we’re almost ready to spin up our manager and workers and have them use the new `Store` interface. All that’s needed are a few minor tweaks to our `main.go` program. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)The first tweak to make involves how we create our workers. If you recall, we had been creating them by assigning a struct literal to a variable:

```
w1 := worker.Worker{
       Queue: *queue.New(),
       Db:    store.NewInMemoryTaskStore(),
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)Now, however, we can simplify this part of our code by using the `New` helper function in the worker package. We’ll replace the three lines with a single call to the `New` function:[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)

```
w1 := worker.New("worker-1", "memory")
w2 := worker.New("worker-2", "memory")
w3 := worker.New("worker-3", "memory")
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)The second tweak involves how we’re creating the manager. We already had a `New` helper function that we were using. We now need to add an argument to our call to `New` that specifies what type of datastore the manager should use:

```
m := manager.New(workers, "epvm", "memory")
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)With these changes, we can now run our main program and see what we get:

```bash
$ CUBE_WORKER_HOST=localhost CUBE_WORKER_PORT=5556
   CUBE_MANAGER_HOST=localhost CUBE_MANAGER_PORT=5555 go run main.go
Starting Cube worker
Starting Cube manager
2023/03/04 16:19:38 No tasks to process currently.
2023/03/04 16:19:38 Sleeping for 10 seconds.
2023/03/04 16:19:38 Checking status of tasks
2023/03/04 16:19:38 Task updates completed
2023/03/04 16:19:38 Sleeping for 15 seconds
2023/03/04 16:19:38 Checking status of tasks
2023/03/04 16:19:38 Task updates completed
2023/03/04 16:19:38 Sleeping for 15 seconds
2023/03/04 16:19:38 Processing any tasks in the queue
2023/03/04 16:19:38 No work in the queue
2023/03/04 16:19:38 Sleeping for 10 seconds
2023/03/04 16:19:38 No tasks to process currently.
2023/03/04 16:19:38 Sleeping for 10 seconds.
2023/03/04 16:19:38 Checking for task updates from workers
2023/03/04 16:19:38 Checking worker localhost:5556 for task updates
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)As you can see, not much has changed. The workers and manager start up as expected and do their respective jobs.

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)Let’s send a task to the manager:

```bash
$ curl -X POST localhost:5555/tasks -d @task1.json
 
2023/03/04 16:19:42 Add event {a7aa1d44-08f6-443e-9378-f5884311019e
2023/03/04 16:19:48 Pulled {a7aa1d44-08f6-443e-9378-f5884311019e
2023/03/04 16:19:57 [manager] selected worker localhost:5556 for task
   bb1d59ef-9fc1-4e4b-a44d-db571eeed203
2023/03/04 16:19:57 [worker] Added task bb1d59ef-9fc1-4e4b-a44d-db571eeed203
2023/03/04 16:19:57 [manager] received response from worker
[worker] Found task in queue: {bb1d59ef-9fc1-4e4b-a44d-db571eeed203
2023/03/04 21:19:59 Listening on http://localhost:7777
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)It works! We have successfully refactored the manager and worker to use an interface representing a datastore instead of operating directly on the datastore itself. There is still one problem. If we stop and restart either the manager or the worker, they will forget about any tasks they have previously seen. We can solve this problem by implementing a persistent datastore. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)

## [](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)11.8 Introducing BoltDB

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)In moving from an in-memory datastore to a persistent one, there are some high-level questions we have to ask ourselves. First, do we need a *server-based* datastore? A server-based datastore is like PostgreSQL, MySQL, Cassandra, Mongo, or any other datastore that runs as its own process. For our purposes, a server-based datastore is overkill. It would be another process we’d have to start and then manage, and most server-based systems can get complex quickly. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)Instead, we’re going to choose an *embedded* datastore. It’s called an *embedded* datastore because it uses a library that you embed directly in your application. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)The second question involves the data model that we want to use. The most popular data model is the relational model, which systems like PostgreSQL and MySQL use. There is even an embedded relational datastore, SQLite. While such datastores are popular and robust, they also require the use of the *Structured Query Language*, or SQL, to insert and query data. SQL datastores are highly structured and require strict schemas defining tables and columns. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)Another data model that has become popular in the last decade is the key-value datastore, sometimes also referred to as NoSQL. Popular open source key-value datastores include Cassandra and Redis.

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)If you recall our in-memory datastore using Go’s built-in `map` type, it had a simple interface: we *put* data into the datastore, and we *got* data out of it. The main mechanism by which we put or got tasks into this datastore was the `key`—in our case, a `UUID`. Our tasks are the *values* to which the *keys* refer. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)Because we are already using a key-value datastore, it makes sense to pick a persistent datastore that uses the same paradigm. And to keep this as simple as possible, we’re going to use an embedded library called BoltDB ([https://github.com/boltdb/ bolt](https://github.com/boltdb/bolt)). As mentioned in BoltDB’s README, it is “a pure Go key/value store” and the “goal of the project is to provide a simple, fast, and reliable database for projects that don’t require a full database server such as Postgres or MySQL.”[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)To use the BoltDB library, we will need to install it. From your project directory, install the library using the following command:

```bash
$ go get github.com/boltdb/bolt/...
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)As we did with the in-memory version of the task and event datastores, we are now going to implement persistent versions of each store.

## [](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)11.9 Implementing a persistent task store

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)The first persistent store we will implement is the `TaskStore`. It will implement the `Store` interface, the same as the in-memory stores do. The only difference will be in the implementation details. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)The first thing to do is to create the `TaskStore` struct, as shown in listing 11.21. There are several differences from the in-memory version to note. The first is that the `TaskStore` struct uses a different type for its `Db` field. Whereas the `InMemoryTaskStore` used a `map[string]*task.Task` type, here the field is a pointer to the `bolt.DB` type. This type is defined in the BoltDB library. Next, the `TaskStore` struct defines the `DbFile` and `FileMode` fields. BoltDB uses a file on disk to persist data, the `DbFile` field tells BoltDB the name of the file it will operate on, and the `FileMode` ensures we have the necessary permissions to read and write to the file. In BoltDB, key-value pairs are stored in collections called *buckets*, so the struct’s `Bucket` field defines the name of the bucket we want to use for the `TaskStore.`[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)

##### Listing 11.21 The persistent version of our task store, called `TaskStore`

```
import (
       // previous imports omitted

       "github.com/boltdb/bolt"
)

type TaskStore struct {
   Db       *bolt.DB
   DbFile   string
   FileMode os.FileMode
   Bucket   string
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)The next thing to do is to create a helper function to create an instance of our persistent datastore. We did the same thing with our in-memory datastores. The `NewTaskStore` helper takes three arguments: a string `file` that provides the name of the file we want to use, the `mode` of the file as an `os.FileMode` type, and a string that provides the name of the bucket in which we want to store our tasks. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)

##### Listing 11.22 The `NewTaskStore` helper function

```
func NewTaskStore(file string, mode os.FileMode, bucket string)
   (*TaskStore, error) {
    db, err := bolt.Open(file, mode, nil)                   #1
    if err != nil {
        return nil, fmt.Errorf("unable to open %v", file)
    }
    t := TaskStore{                                        #2
        DbFile:   file,
        FileMode: mode,
        Db:       db,
        Bucket:   bucket,
    }
 
    err = t.CreateBucket()                                 #3
    if err != nil {
        log.Printf("bucket already exists, will use it instead
     of creating new one")
    }
 
    return &t, nil                                         #4
}
#1 Creates a datastore by calling the BoltDB library’s Open function, passing in the file, mode, and bucket from our function signature, and checks for any errors
#2 Creates an instance of the TaskStore and assigns it to the variable t
#3 Creates the bucket by calling the CreateBucket method and checks for any errors
#4 Returns a pointer to the newly created task store
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)With the `TaskStore` struct defined and our helper function created, let’s turn our attention to the methods of the `TaskStore`. In addition to the methods defined by the `Store` interface—`Put`, `Get`, `List`, and `Count`—we’re going to define a `Close` method. Why do we need such a method? Remember, our persistent datastore is writing its data to a file on disk. Moreover, in the `NewTaskStore` helper function, we called the `Open` function to open the file. The `Close` method will close the file when we’re done with it:[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)

```
func (t *TaskStore) Close() {
   t.Db.Close()
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)The first method of the `Store` interface to implement is `Count`. As with the in-memory stores, the persistent version will return the number of tasks in the datastore. Unlike the in-memory versions, this one is a little more involved. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)Similar to relational datastores like PostgreSQL and MySQL, BoltDB supports transactions. Per the BoltDB README, each transaction in BoltDB “has a consistent view of the data as it existed when the transaction started.” BoltDB supports three types of transactions:

-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)Read-write
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)Read-only
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)Batch read-write

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)For our purposes, we will only be using the first two.

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)Since our `Count` method needs to get the number of tasks, we can use a read-only transaction. Unlike the in-memory stores, where we were able to use Go’s built-in `len` method on Go’s map type, here we have to iterate over all the keys in the bucket to construct our count. BoltDB provides the `ForEach` method to simplify this process. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)To perform a read-only transaction, we use Bolt’s `View` function. This method takes a function, which itself takes an argument of a pointer to a `bolt.Tx` type and returns an error. This is the mechanism that provides the transaction. Inside the transaction, we identify the bucket on which we want to operate, then iterate over each key in that bucket and increment the `taskCount` value. After iterating over all the keys, we check for any errors before finally returning the `taskCount`:[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)

```
func (t *TaskStore) Count() (int, error) {
    taskCount := 0
    err := t.Db.View(func(tx *bolt.Tx) error {    #1
        b := tx.Bucket([]byte("tasks"))           #2
        b.ForEach(func(k, v []byte) error {       #3
            taskCount++                           #4
            return nil
        })
        return nil
    })
    if err != nil {                               #5
        return -1, err
    }
 
    return taskCount, nil                         #6
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)Let’s move on and implement another method that is specific to the persistent store and is thus not part of the `Store` interface. The method, `CreateBucket`, as seen in listing 11.22, is a wrapper around a function of the same name in the BoltDB library. It takes no arguments and returns an error. In this method, we create the bucket that will hold all of our tasks as key-value pairs. Because we are creating a bucket, we need to use a read-write transaction, and we do this with the `Update` function. Using `Update` works similarly to `View`. It takes a function that takes a pointer to a `bolt.Tx` type and returns an error. We then call the `CreateBucket` function and pass in the name of the bucket to create. We then check for any errors. Our `CreateBucket` method is shown in the next listing.[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)

##### Listing 11.23 The `CreateBucket` method

```
func (t *TaskStore) CreateBucket() error {
   return t.Db.Update(func(tx *bolt.Tx) error {
       _, err := tx.CreateBucket([]byte(t.Bucket))
       if err != nil {
           return fmt.Errorf("create bucket %s: %s", t.Bucket, err)
       }
       return nil
   })
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)Now let’s return to the methods of the `Store` interface and implement the second of these methods, `Put`. The signature of this `Put` method is the same as for the in-memory versions, so there is nothing new here. What is new is how we store the key-value pair. As we did in the `CreateBucket` method, we will use the `Update` function to get a read-write transaction. We identify the bucket where we will store the key-value pair using the `tx.Bucket` function, passing it the name as a string. To store the value in the BoltDB bucket, we have to convert the value to a slice of bytes. We do this by calling the `Marshal` function from the `json` package and passing it the `value` converted to a pointer to the `task.Task` type. Once the value has been converted to a slice of bytes, we call the `Put` function on the bucket, passing it the key and value (both as slices of bytes), as shown in the following listing.[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)

##### Listing 11.24 The `Put` method for the persistent task store

```
func (t *TaskStore) Put(key string, value interface{}) error {
   return t.Db.Update(func(tx *bolt.Tx) error {
       b := tx.Bucket([]byte(t.Bucket))

       buf, err := json.Marshal(value.(*task.Task))
       if err != nil {
           return err
       }

       err = b.Put([]byte(key), buf)
       if err != nil {
           return err
       }
       return nil
   })
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)The third method of the `Store` interface to implement is the `Get` method. It takes a string, which is the key we want to retrieve. It returns an `interface{}`, which is the task we wanted, and an error. We start by defining the variable `task` of type `task.Task`. Next, we use a read-only transaction by way of the `View` function, which we’ve previously seen. Again, we identify the bucket on which we want to operate. Then we look up the task using the `Get` function, passing it the `key` as a slice of bytes. Notice that we do not check the `Get` call for any errors. The reason for this is that the BoltDB library guarantees `Get` will work unless there is a system failure (e.g., the datastore file is deleted from disk). If there is no task in the bucket for the `key`, `Get` returns `nil`. Once we have the task, we have to decode it from a slice of bytes back into a `task.Type`, which we do using the `Unmarshal` function from the `json` package. Finally, we do some error checking and then return a pointer to the task.[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)

##### Listing 11.25 The `Get` method for the persistent task store

```
func (t *TaskStore) Get(key string) (interface{}, error) {
   var task task.Task
   err := t.Db.View(func(tx *bolt.Tx) error {
       b := tx.Bucket([]byte(t.Bucket))
       t := b.Get([]byte(key))
       if t == nil {
           return fmt.Errorf("task %v not found", key)
       }
       err := json.Unmarshal(t, &task)
       if err != nil {
           return err
       }
       return nil
   })
   if err != nil {
       return nil, err
   }
   return &task, nil
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)The fourth and final method to implement is the `List` method. Like `Get`, `List` uses a read-only transaction. Instead of getting a single task, however, it iterates over all the tasks in the bucket and creates a slice of tasks. In this, it is similar to the `Count` method:[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)

```
func (t *TaskStore) List() (interface{}, error) {
   var tasks []*task.Task
   err := t.Db.View(func(tx *bolt.Tx) error {
       b := tx.Bucket([]byte(t.Bucket))
       b.ForEach(func(k, v []byte) error {
           var task task.Task
           err := json.Unmarshal(v, &task)
           if err != nil {
               return err
           }
           tasks = append(tasks, &task)
           return nil
       })
       return nil
   })
   if err != nil {
       return nil, err
   }

   return tasks, nil
}
```

## [](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)11.10 Implementing a persistent task event store

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)The persistent store for task events will look almost the same as the one for tasks. The obvious differences will be in naming. Our struct is named `EventStore` instead of `TaskStore`, and it will operate on the `task.TaskEvent` type instead of `task.Task`. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)The `EventStore` struct and `NewEventStore` helper functions should look familiar. There isn’t much to discuss here:[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)

```
type EventStore struct {
    DbFile   string
    FileMode os.FileMode
    Db       *bolt.DB
    Bucket   string
}
 
func NewEventStore(file string, mode os.FileMode, bucket string)
   (*EventStore, error) {
    db, err := bolt.Open(file, mode, nil)
    if err != nil {
        return nil, fmt.Errorf("unable to open %v", file)
    }
    e := EventStore{
        DbFile:   file,
        FileMode: mode,
        Db:       db,
        Bucket:   bucket,
    }
 
    err = e.CreateBucket()
    if err != nil {
        log.Printf("bucket already exists, will use it instead
     of creating new one")
    }
 
    return &e, nil
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)Likewise, the `Close` and `CreateBucket` methods on the `EventStore` type should also look familiar. The former is closing the datastore file opened in `NewEventStore`, and the latter is creating a bucket to store events:[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)

```
func (e *EventStore) Close() {
   e.Db.Close()
}

func (e *EventStore) CreateBucket() error {
   return e.Db.Update(func(tx *bolt.Tx) error {
       _, err := tx.CreateBucket([]byte(e.Bucket))
       if err != nil {
           return fmt.Errorf("create bucket %s: %s", e.Bucket, err)
       }
       return nil
   })
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)The `Count` method counts the number of events in the persistent store, returning the `Count`:[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)

```
func (e *EventStore) Count() (int, error) {
   eventCount := 0
   err := e.Db.View(func(tx *bolt.Tx) error {
       b := tx.Bucket([]byte(e.Bucket))
       b.ForEach(func(k, v []byte) error {
           eventCount++
           return nil
       })
       return nil
   })
   if err != nil {
       return -1, err
   }

   return eventCount, nil
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)The `Put` and `Get` methods are also identical to their counterparts in the `TaskStore` type. `Put` takes a key and a value, writes it to the datastore, and returns any errors. `Get` takes a key, looks it up in the datastore, and returns the value if found:[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)

```
func (e *EventStore) Put(key string, value interface{}) error {
   return e.Db.Update(func(tx *bolt.Tx) error {
       b := tx.Bucket([]byte(e.Bucket))

       buf, err := json.Marshal(value.(*task.TaskEvent))
       if err != nil {
           return err
       }

       err = b.Put([]byte(key), buf)
       if err != nil {
           log.Printf("unable to save item %s", key)
           return err
       }
       return nil
   })
}

func (e *EventStore) Get(key string) (interface{}, error) {
   var event task.TaskEvent
   err := e.Db.View(func(tx *bolt.Tx) error {
       b := tx.Bucket([]byte(e.Bucket))
       t := b.Get([]byte(key))
       if t == nil {
           return fmt.Errorf("event %v not found", key)
       }
       err := json.Unmarshal(t, &event)
       if err != nil {
           return err
       }
       return nil
   })

   if err != nil {
       return nil, err
   }
   return &event, nil
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)And last but not least, the `List` method builds a list of all the events in the datastore and returns it:[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)

```
func (e *EventStore) List() (interface{}, error) {
   var events []*task.TaskEvent
   err := e.Db.View(func(tx *bolt.Tx) error {
       b := tx.Bucket([]byte(e.Bucket))
       b.ForEach(func(k, v []byte) error {
           var event task.TaskEvent
           err := json.Unmarshal(v, &event)
           if err != nil {
               return err
           }
           events = append(events, &event)
           return nil
       })
       return nil
   })
   if err != nil {
       return nil, err
   }

   return events, nil
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)With the persistent versions of our task and event stores implemented, we can change our main program to use them instead of their in-memory counterparts. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)

## [](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)11.11 Switching out the in-memory stores for permanent ones

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)We need to make a couple of minor changes in our manager and worker code to use the new persistent stores. Both changes involve adding cases for creating persistent datastores in the `New` helper functions in the manager and worker packages. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)Let’s start with the manager. We need to add the `persistent` case to our `switch` statement, seen in listing 11.26. Thus, when a caller of the `New` function passes in `persistent` as the value of `dbType`, we call the `NewTaskStore` and `NewEventStore` functions instead of their in-memory equivalents. Notice that each function takes three arguments: the name of the file to use for the datastore, the filemode of the file, and the name of the bucket that will store the key-value pairs. The `0600` in the function calls represents the filemode argument, which means only the owner of the file can read and write it. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)

##### Listing 11.26 Adding the `persistent` case to the manager’s `New` function

```
var err error
switch dbType {
case "memory":
   ts = store.NewInMemoryTaskStore()
   es = store.NewInMemoryTaskEventStore()
case "persistent":
   ts, err = store.NewTaskStore("tasks.db", 0600, "tasks")
   es, err = store.NewEventStore("events.db", 0600, "events")
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)The changes in the worker’s `New` function are similar. We add a `persistent` case, which calls the `NewTaskStore` helper function. We’re starting three workers, so we use the `filename` variable to create a unique filename for each worker. Because the worker only operates on tasks, there is no need to set up an event store. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)

##### Listing 11.27 Changing workers to use the `persistent` store

```
case "persistent":
   filename := fmt.Sprintf("%s_tasks.db", name)
   s, err = store.NewTaskStore(filename, 0600, "tasks")
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)At this point, changing our main program to use the new persistent store is just a matter of changing four lines of existing code. In all four lines, we simply change the string `memory` to `persistent`:

```
//w1 := worker.New("worker-1", "memory")
w1 := worker.New("worker-1", "persistent")

//w2 := worker.New("worker-2", "memory")
w2 := worker.New("worker-2", "persistent")

// w3 := worker.New("worker-3", "memory")
w3 := worker.New("worker-3", "persistent")

//m := manager.New(workers, "epvm", "memory")
m := manager.New(workers, "epvm", "persistent")
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)With these changes, start up the main program and perform the same operations we performed earlier in the chapter. You should notice that everything looks the same from the outside as when we used the in-memory stores. The only difference is that you will now see several files with the `.db` extension in the working directory. These are the files BoltDB is using to persist the system’s tasks and events. The files you should see are

-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)`tasks.db`
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)`worker-1_tasks.db`
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)`worker-2_tasks.db`
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)`worker-3_tasks.db`

## [](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)Summary

-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)Storing the orchestrator’s tasks and events in persistent datastores allows the system to keep track of task and event state, to make informed decisions about scheduling, and to help recover from failures. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)The `store.Store` interface lets us swap out datastore implementations based on our needs. For example, while doing development work, we can use an in-memory store, while we use a persistent store for production. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)While we adapted our old stores that were based on Go’s built-in map type to the new `store.Store` interface, these in-memory implementations suffer the same problem—that is, the manager and worker will still lose their tasks when they restart. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)With the `store.Store` interface and a concrete implementation, we made changes to the manager and worker to remove their operating directly on the datastore. For example, instead of operating on a map of `map[uuid.UUID]*task .Task`, we changed them to operate on the `store.Store` interface. In doing this, we decoupled the manager and worker from the underlying datastore implementation. They no longer needed to know the internal workings of the specific datastore; they only needed to know how to call the methods of the interface while all the technical details were handled by an implementation. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)The BoltDB library provides an embedded key-value datastore on top of which we built our `TaskStore` and `EventStore` stores. These datastores persist their data to files on disk, thus allowing the manager and worker to gracefully restart without losing their tasks. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)Once we created the `store.Store` interface and two implementations (one in-memory, one persistent), we could switch between the implementations by simply passing a string of either `memory` or `persistent` to the `New` helper functions. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-11/)

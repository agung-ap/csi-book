# [](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)10 Implementing a more sophisticated scheduler

### This chapter covers

- Describing the scheduling problem
- Defining the phases of scheduling
- Re-implementing the round-robin scheduler
- Discussing the enhanced parallel virtual machine (E-PVM) concept and algorithm
- Implementing the E-PVM scheduler

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)We implemented a simple round-robin scheduler in chapter 7. Now let’s return and dig a little deeper into the general problem of scheduling and see how we might implement a more sophisticated scheduler.

## [](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)10.1 The scheduling problem

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)Whether we realize it or not, the scheduling problem lives with us in our daily lives. In our homes, we have work to do, like sweeping the floors, cooking meals, washing clothes, mowing the grass, and so on. Depending on the size of our family, we have one or more people to perform the necessary work. If you live by yourself, then you have a single worker, yourself. If you live with a partner, you have two workers. If you live with a partner and children, you have three or more workers. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)Now, how do we assign our housework to our workers? Do you take it all on yourself because your partner is taking the kids to soccer practice? Do you mow the grass and wash the clothes, while your partner will sweep the floors and cook dinner after returning from taking the kids to soccer practice? Do you take the kids to soccer practice while your partner cooks dinner, and when you return, your oldest child will mow the grass, and the youngest will do the laundry while your partner sweeps the floors?

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)In chapter 6, we described the scheduling problem using the scenario of a host seating customers at a busy restaurant on a Friday night. The host has six servers waiting on customers sitting at tables spread across the room. Each customer at each of those tables has different requirements. One customer might be there to have drinks and appetizers with a group of friends they haven’t seen in a while. Another customer might be there for a full dinner, complete with an appetizer and dessert. Yet another customer might have strict dietary requirements and only eat plant-based food.

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)Now a new group of customers walks in. It’s a family of four: two adults and two teenage children. Where does the host seat them? Do they place them at the table in the section being served by John, who already has three tables with four customers each? Do they place them at the table in Jill’s section, which has six tables with a single customer each? Or do they place them in Willie’s section, which has a single table with three customers?

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)The same scheduling problem also exists in our work lives. Most of us work on a team, and we have work that needs to get done: writing documentation for a new feature or a new piece of infrastructure, fixing a critical bug that a customer reported over the weekend, drafting team goals for the next quarter. How do we divvy up this work among ourselves? As we can see from the previous examples, scheduling is all around us. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)

## [](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)10.2 Scheduling considerations

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)When we implemented the round-robin scheduler in chapter 7, we didn’t take much into consideration. We just wanted a simple implementation of a scheduler that we could implement quickly so we could focus on other areas of our orchestration system.

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)There are, however, a wide range of things to consider if we take the time. What goals are we trying to achieve?

-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)Seating customers as quickly as possible to avoid a large queue of customers having to wait
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)Distributing customers evenly across our servers so they get the best service
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)Getting customers in and out as quickly as possible because we want high volume

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)The same considerations exist in an orchestration system. Instead of seating customers at tables, we’re placing tasks on machines:

-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)Do we want the task to be placed and running as quickly as possible?
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)Do we want to place the task on a machine that is best capable of meeting the unique needs of the task?
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)Do we want to place the task on a machine that will distribute the load evenly across all of our workers?

## [](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)10.3 Scheduler interface

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)Unfortunately, there is no one-size-fits-all approach to scheduling. How we schedule tasks depends on the goals we want to achieve. For this reason, most orchestrators support multiple schedulers. Kubernetes achieves this through scheduling *Profiles* (see [https://kubernetes.io/docs/reference/scheduling/config/](https://kubernetes.io/docs/reference/scheduling/config/)), while Nomad achieves it through four scheduler types (see [https://developer.hashicorp.com/nomad/docs/schedulers](https://developer.hashicorp.com/nomad/docs/schedulers)).

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)Like Kubernetes and Nomad, we want to support more than one type of scheduler. We can accomplish this by using an interface. In fact, we already defined such an interface in chapter 2:

```
type Scheduler interface {
   SelectCandidateNodes()
   Score()
   Pick()
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)Our interface is simple. It has three methods:

-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)`SelectCandidateNodes`
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)`Score`
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)`Pick`

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)We can think of these methods as the different phases of the scheduling problem, as seen in figure 10.1[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/).

![Figure 10.1 The scheduling problem can be broken down into three phases: selecting candidate nodes, scoring candidate nodes, and finally, picking one of the nodes.](https://drek4537l1klr.cloudfront.net/boring/Figures/10-01.png)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)Using just these three methods, we can implement any number of schedulers. However, before we dive into writing any new code, let’s revise our `Scheduler` interface with a few more details.

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)To start, we want our `SelectCandidateNodes` method to accept a task and a list of nodes. As we will soon see, this method acts as a filter early in the scheduling process, reducing the number of possible workers to only those we are confident can run the task. For example, if our task needs 1 GB of disk space because we haven’t taken the time to reduce the size of our Docker image, then we only want to consider scheduling the task onto workers that have at least 1 GB of disk space available to download our image. As a result, `SelectCandidateNodes` returns a list of nodes that will, at a minimum, meet the resource requirements of the task.

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)Next, we want our `Score` method to also accept a task and list of nodes as parameters. This method performs the heavy lifting. Depending on the scheduling algorithm we’re implementing, this method assigns a score to each candidate node it receives. Then it returns a `map[string]float64`, where the map key is the name of the node and the value is its score.

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)Finally, our `Pick` method needs to accept a map of scores (i.e., the output of the `Score` method) and a list of candidate nodes. Then it picks the node with the best score. The definition of *best* is left as an implementation detail.

##### Listing 10.1 The updated `Scheduler` interface

```
type Scheduler interface {
   SelectCandidateNodes(t task.Task, nodes []*node.Node) []*node.Node
   Score(t task.Task, nodes []*node.Node) map[string]float64
   Pick(scores map[string]float64, candidates []*node.Node) *node.Node
}
```

## [](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)10.4 Adapting the round-robin scheduler to the scheduler interface

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)Since we have already implemented a round-robin scheduler, let’s adapt that code to our scheduler interface. The sequence diagram in figure 10.2 illustrates how our manager will interact with the `Scheduler` interface to select a node for running a task. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)

![Figure 10.2 Sequence diagram showing the interactions between the manager, scheduler, and worker](https://drek4537l1klr.cloudfront.net/boring/Figures/10-02.png)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)Let’s start by opening the `scheduler.go` file and creating the `RoundRobin` struct seen in listing 10.2. Our struct has two fields: `Name`, which allows us to give it a descriptive name, and `LastWorker`, which will take over the role of the field with the same name from the `Manager` struct. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)

##### Listing 10.2 The `RoundRobin` struct

```
type RoundRobin struct {
   Name       string
   LastWorker int
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)Next, let’s implement the `SelectCandidateNodes` method for our round-robin scheduler. Because we are adapting our original implementation, not improving upon it, we’re going to simply return the list of nodes that are passed in as one of the two method parameters. While it might seem a bit silly for this method to just return what it received, the `RoundRobin` scheduler needs to implement this method to meet the contract of the `Scheduler` interface. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)

##### Listing 10.3 The `SelectCandidateNodes` method for the round-robin scheduler

```
func (r *RoundRobin) SelectCandidateNodes(t task.Task, nodes []*node.Node) []*node.Node {
   return nodes
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)Now let’s implement the `Score` method for our round-robin implementation. Here we’re effectively taking the code from the existing manager’s `SelectWorker` method and pasting it into the `Score` method. We do, however, need to make a few modifications. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)First, we define the `nodeScores` variable, which is of type `map[string]float64`. This variable will hold the scores we assign to each node. Depending on the number of nodes we’re using, the resulting map will look something like this:[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)

```json
{
   "node1": 1.0,
   "node2": 0.1,
   "node3": 1.0,
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)Second, we iterate over the list of `nodes` that are passed into the method and build our map of `nodeScores`. Notice that our method of scoring is not that sophisticated. We check whether the index is equal to the `newWorker` variable, and if it is, we assign the node a score of `0.1`. If the index is not equal to the `newWorker`, we give it a score of `1.0`. Once we have built our map of `nodeScores`, we return it. Thus, the `Score` method adapts the original code from the manager’s `SelectWorker` method to the `Score` method of the `Scheduler` interface. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)

##### Listing 10.4 The `Score` method

```
func (r *RoundRobin) Score(t task.Task, nodes []*node.Node)
 map[string]float64 {
    nodeScores := make(map[string]float64)     #1
    var newWorker int                          #2
    if r.LastWorker+1 < len(nodes) {
        newWorker = r.LastWorker + 1
        r.LastWorker++
    } else {
        newWorker = 0
        r.LastWorker = 0
    }
 
    for idx, node := range nodes {             #3
        if idx == newWorker {
            nodeScores[node.Name] = 0.1
        } else {
            nodeScores[node.Name] = 1.0
        }
    }
 
    return nodeScores                          #4
}
#1 Defines the nodeScores map that will hold the scores for each node
#2 Defines the newWorker variable, an integer that represents the worker that should be selected to run a task
#3 Iterates over the list of nodes and assigns a score to each
#4 Returns the nodeScores map
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)With the `SelectCandidateNodes` and `Score` methods implemented, let’s turn our attention to the final method of the `Scheduler` interface, the `Pick` method. As its name suggests, this method picks the best node to run a task. It accepts a `map[string]float64`, which will be the scores returned from the `Score` method. It also accepts a list of candidate nodes. It returns a single type of a pointer to a `node.Node`. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)For the purposes of the round-robin implementation, the best score is the lowest score. So if we had a list of three nodes with scores of 0.1, 1.0, and 1.0, the node with the 0.1 score would be selected.

##### Listing 10.5 The round-robin scheduler’s `Pick` method

```
func (r *RoundRobin) Pick(scores map[string]float64,
     candidates []*node.Node) *node.Node {
    var bestNode *node.Node
    var lowestScore float64
    for idx, node := range candidates {         #1
        if idx == 0 {                           #2
            bestNode = node
            lowestScore = scores[node.Name]
            continue
        }
 
        if scores[node.Name] < lowestScore {    #3
            bestNode = node
            lowestScore = scores[node.Name]
        }
    }
 
    return bestNode                             #4
}
#1 Iterates over the slice of candidate nodes
#2 Handles the special case of the first node in the slice
#3 Checks whether the node’s score is lower than the current lowestScore
#4 Returns the bestNode, which in this case is the node with the lowest score
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)With the implementation of the `Pick` method, we have completed adapting the round-robin scheduler to the `Scheduler` interface. Now let’s see how we can use it. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)

## [](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)10.5 Using the new scheduler interface

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)To use the new `Scheduler` interface, there are a few changes we need to make to the manager. There are three types of changes:[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)

-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)Adding new fields to the `Manager` struct
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)Modifying the `New` helper function in the `manager` package
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)Modifying several of the manager’s methods to use the scheduler

### [](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)10.5.1 Adding new fields to the Manager struct

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)The first set of changes to make is to add two new fields to our `Manager` struct. As you can see in listing 10.6, the first is a field named `WorkerNodes`. This field is a slice of pointers of `node.Node`. It will hold instances of each worker node. The second field we need to add is `Scheduler`, which is our new interface type `scheduler.Scheduler`. As you will see later, defining the `Scheduler` field type as the `Scheduler` interface allows the manager to use any scheduler that implements the interface. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)

##### Listing 10.6 Adding the `WorkerNodes` and `Scheduler` fields to the `Manager` struct

```
type Manager struct {
   // previous code not shown

   WorkerNodes   []*node.Node
   Scheduler     scheduler.Scheduler
}
```

### [](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)10.5.2 Modifying the New helper function

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)The second set of changes involves modifying the `New` function in the `manager` package. We need to add the `schedulerType` parameter to the function signature. This parameter will allow us to create a manager with one of the concrete scheduler types, starting with the `RoundRobin` type. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)

##### Listing 10.7 The `New` helper function, modified to take a new argument, `schedulerType`

```
func New(workers []string, schedulerType string) *Manager {
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)The next change to the function happens in the body. We define the variable `nodes` to hold a slice of pointers to the `node.Node` type. We’re going to perform this work inside the existing loop over the `workers` slice. Inside this loop, we create a node by calling the `node.NewNode` function, passing it the name of the worker, the address for the worker’s API (e.g., [http://192.168.33.17:5556](http://192.168.33.17:5556)), and the node’s role. All three values passed in to the `NewNode` function are strings. Once we have created the node, we add it to the slice of `nodes` by calling the built-in `append` function. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)After creating the list of `nodes`, we can move on to the next-to-last change in the function body. Depending on the `schedulerType` passed in, we need to create a scheduler of the appropriate type. To do this, we create the variable `s` to hold the scheduler. Then we use a `switch` statement to initialize the appropriate scheduler. We start out with only a single case to support the `"roundrobin"` scheduler. If `schedulerType` is not `"roundrobin"` or is the empty string `""`, then we hit the `default` case and set a reasonable default. Since we only have a single scheduler right now, we’ll just use it. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)The final changes to the function are simple. We need to add our list of `nodes` and our scheduler `s` to the `Manager` that we’re returning at the end of the function. We do this by adding the slice of `nodes` to the `WorkerNodes` field and the scheduler `s` to the `Scheduler` field. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)

##### Listing 10.8 Changing the `New` helper function to use the new `Scheduler` interface

```
func New(workers []string, schedulerType string) *Manager {
   // previous code not shown

   var nodes []*node.Node
   for worker := range workers {
       workerTaskMap[workers[worker]] = []uuid.UUID{}

       nAPI := fmt.Sprintf("http://%v", workers[worker])
       n := node.NewNode(workers[worker], nAPI, "worker")
       nodes = append(nodes, n)
   }

   var s scheduler.Scheduler
   switch schedulerType {
   case "roundrobin":
       s = &scheduler.RoundRobin{Name: "roundrobin"}
   default:
       s = &scheduler.RoundRobin{Name: "roundrobin"}
   }

   return &Manager{
       Pending:       *queue.New(),
       Workers:       workers,
       TaskDb:        taskDb,
       EventDb:       eventDb,
       WorkerTaskMap: workerTaskMap,
       TaskWorkerMap: taskWorkerMap,
       WorkerNodes:   nodes,
       Scheduler:     s,
   }
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)With these changes to the `New` function, we can now create our manager with different types of schedulers. But we still have more work to do on our manager before it can actually use the scheduler.

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)The next piece of the `Manager` type we need to change is the `SelectWorker` method. We’re going to scrap the previous implementation of this method and replace it. Why? Because the previous implementation was specifically geared toward the round-robin scheduling algorithm. With the creation of the `Scheduler` interface and the `RoundRobin` implementation of that interface, we need to refactor the `SelectWorker` method to operate on the scheduler interface. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)As you can see in listing 10.9, the `SelectWorker` method becomes more straightforward. It does the following:

-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)Calls the manager’s `Scheduler.SelectCandidateNodes` method, passing it the task `t` and the slice of nodes in the manager’s `WorkerNodes` field. If the call to `SelectCandidateNodes` results in the `candidates` variable being `nil`, we return an error. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)Calls the manager’s `Scheduler.Score` method, passing it the task `t` and slice of `candidates`. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)Calls the manager’s `Scheduler.Pick` method, passing it the `scores` from the previous step and the slice of `candidates`. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)Returns the `selectedNode`[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/).

##### Listing 10.9 The `SelectWorker` method using the `Scheduler` interface

```
func (m *Manager) SelectWorker(t task.Task) (*node.Node, error) {
    candidates := m.Scheduler.SelectCandidateNodes(t, m.WorkerNodes)
    if candidates == nil {
        msg := fmt.Sprintf("No available candidates match resource request
     for task %v", t.ID)
        err := errors.New(msg)
        return nil, err
    }
    scores := m.Scheduler.Score(t, candidates)
    selectedNode := m.Scheduler.Pick(scores, candidates)
 
    return selectedNode, nil
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)Now let’s move on to the `SendWork` method of the manager. In the original version, the beginning of the method looked like that shown in listing 10.10. Notice that we called the `SelectWorker` method first, and we didn’t pass it a task. We need to rework the beginning of this method to account for the previous changes we made to the `SelectWorker` method. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)

##### Listing 10.10 The original `SendWork` method

```
func (m *Manager) SendWork() {
   if m.Pending.Len() > 0 {
       w := m.SelectWorker()

       e := m.Pending.Dequeue()
       te := e.(task.TaskEvent)
       t := te.Task
       log.Printf("Pulled %v off pending queue\n", t)

       m.EventDb[te.ID] = &te
       m.WorkerTaskMap[w] = append(m.WorkerTaskMap[w], te.Task.ID)
       m.TaskWorkerMap[t.ID] = w
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)Instead of calling the `SelectWorker` method first, we now want to pop a task off the manager’s pending queue as the first step. Then we do some accounting work, notably adding the `task.TaskEvent` `te` to the manager’s `EventDb` map. It’s only after pulling a task off the queue and doing the necessary accounting work that we then call the new version of `SelectWorker`. Moreover, we pass the task `t` to the new `SelectWorker` method. Thus, the new `SendWork` method re-orders the steps in the process of sending a task to a worker. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)

##### Listing 10.11 The new `SendWork` method

```
func (m *Manager) SendWork() {
   if m.Pending.Len() > 0 {
       e := m.Pending.Dequeue()
       te := e.(task.TaskEvent)
       m.EventDb[te.ID] = &te
       log.Printf("Pulled %v off pending queue", te)

       t := te.Task
       w, err := m.SelectWorker(t)
       if err != nil {
           log.Printf("error selecting worker for task %s: %v\n", t.ID, err)
       }
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)One important thing to note about the previous changes: the type returned from the new implementation of `SelectWorker` is no longer a string. `SelectWorker` now returns a type of `node.Node`. To make this more concrete, the old version of `SelectWorker` returned a string that looked like `192.168.13.13:1234`. So we need to make a few minor adjustments throughout the remainder of the `SendWork` method to replace any usage of the old string value held in the variable `w` with the value of the node’s `Name` field. The following listing shows that the `w` variable has changed from a string to a `node.Node` type, so we need to use the `w.Name` field. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)

##### Listing 10.12 Using the `w.Name` field

```
m.WorkerTaskMap[w.Name] = append(m.WorkerTaskMap[w.Name], te.Task.ID)
m.TaskWorkerMap[t.ID] = w.Name

url := fmt.Sprintf("http://%s/tasks", w.Name)
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)With that, we’ve completed all the necessary changes to our manager. Well, sort of. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)

## [](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)10.6 Did you notice the bug?

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)Up until this chapter, we’ve been working with a single instance of the worker. This choice made it easier for us to focus on the bigger picture. In the next section, however, we’re going to modify our `main.go` program to start three workers. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)There is a problem lurking in the manager’s `SendWork` method. Notice that it’s popping a task off its queue and then selecting a worker where it will send that task. What happens, however, when the task popped off the queue is for an already existing task? The most obvious case for this behavior is stopping a running task. In such a case, the manager already knows about the running task and the associated task event, so we shouldn’t create new ones. Instead, we need to check for an existing task and update it as necessary. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)Our code in the previous chapters was working by chance. Since we were running a single worker, the `SelectWorker` method only had one choice when it encountered a task intended to stop a running task. Since we’re now running three workers, there is a 67% chance that the existing code will select a worker where the existing task to be stopped is *not* running. Let’s fix this problem![](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)To start, let’s introduce a new method to our manager, called `stopTask`. This method takes two arguments: a `worker` of type `string` and a `taskID` also of type `string`. From the name of the method and the names of the parameters, it’s obvious what the method will do. It uses the `worker` and `taskID` arguments to build a URL to the worker’s `/tasks/{taskID}` endpoint. Then it creates a request by calling the `NewRequest` function in the `http` package. Next, it executes the request.[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)

##### Listing 10.13 The new `stopTask` method

```
func (m *Manager) stopTask(worker string, taskID string) {
   client := &http.Client{}
   url := fmt.Sprintf("http://%s/tasks/%s", worker, taskID)
   req, err := http.NewRequest("DELETE", url, nil)
   if err != nil {
       log.Printf("error creating request to delete task %s: %v\n", taskID, err)
       return
   }

   resp, err := client.Do(req)
   if err != nil {
       log.Printf("error connecting to worker at %s: %v\n", url, err)
       return
   }

   if resp.StatusCode != 204 {
       log.Printf("Error sending request: %v\n", err)
       return
   }

   log.Printf("task %s has been scheduled to be stopped", taskID)
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)Now let’s use the `stopTask` method by calling it from the `SendWork` method. We’re going to add new code near the beginning of the first `if` statement, which checks the length of the manager’s `Pending` queue. Just after the log statement that prints `"Pulled %v off pending queue"`, add a new line, and enter the code after the `// new code` comment, as seen in the following listing. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)

##### Listing 10.14 Checking for existing tasks and calling the new `stopTask` method

```
// existing code
if m.Pending.Len() > 0 {
    e := m.Pending.Dequeue()
    te := e.(task.TaskEvent)
    m.EventDb[te.ID] = &te
    log.Printf("Pulled %v off pending queue\n", te)
 
    // new code
    taskWorker, ok := m.TaskWorkerMap[te.Task.ID]                       #1
    if ok {
        persistedTask := m.TaskDb[te.Task.ID]                           #2
        if te.State == task.Completed &&
         task.ValidStateTransition(persistedTask.State, te.State) {   #3
            m.stopTask(taskWorker, te.Task.ID.String())
            return
        }
 
        log.Printf("invalid request: existing task %s is in state %v and
     cannot transition to the completed state\n",
     persistedTask.ID.String(), persistedTask.State)
        return
    }
#1 Uses the “comma ok” idiom to check for an existing task in the manager’s TaskDb
#2 Assigns the existing task to the persistedTask variable
#3 If the state of the task from the Pending queue is task.Completed and the running task can be transitioned from its current state to the completed state, calls the new stopTask method
```

## [](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)10.7 Putting it all together

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)Now that we’ve made the changes to the manager so it can make use of the new scheduler interface, we’re ready to make several changes to our `main.go` program. As I mentioned, in previous chapters, we used a single worker. That choice was mostly one of convenience. However, given that we’ve implemented a more sophisticated `Scheduler` interface, it’ll be more interesting to start up several workers. This will better illustrate how our scheduler works. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)The first change in our main program is to create three workers. To do this, we take the same approach as in previous chapters but repeat it three times to create workers `w1`, `w2`, and `w3`, as seen in listing 10.15. After creating each worker, we then create an API for it. Notice that for the first worker, we use the existing `wport` variable for the `Port` field of the `API`. Then, to start multiple APIs, we increment the value of the `wport` variable so each API has a unique port to run on. This saves us from having to specify three different variables when we run the program from the command line. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)

##### Listing 10.15 Creating three workers and their APIs

```
w1 := worker.Worker{
       Queue: *queue.New(),
       Db:    make(map[uuid.UUID]*task.Task),
   }
   wapi1 := worker.Api{Address: whost, Port: wport, Worker: &w1}

   w2 := worker.Worker{
       Queue: *queue.New(),
       Db:    make(map[uuid.UUID]*task.Task),
   }
   wapi2 := worker.Api{Address: whost, Port: wport + 1, Worker: &w2}

   w3 := worker.Worker{
       Queue: *queue.New(),
       Db:    make(map[uuid.UUID]*task.Task),
   }
   wapi3 := worker.Api{Address: whost, Port: wport + 2, Worker: &w3}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)Now that we have our three workers and their APIs, let’s start everything up. The process is the same as in past chapters, just doing it once for each worker/API combo.

##### Listing 10.16 Starting up each worker in the same way as we did for a single worker

```
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

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)The next change is to build a slice that contains all three of our workers:

```
workers := []string{
   fmt.Sprintf("%s:%d", whost, wport),
   fmt.Sprintf("%s:%d", whost, wport+1),
   fmt.Sprintf("%s:%d", whost, wport+2),
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)Now we need to update the existing call to the manager package’s `New` function to specify the type of scheduler we want the manager to use. As you can see, we’re going to start by using the `"roundrobin"` scheduler:[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)

```
func main() {
   m := manager.New(workers, "roundrobin")
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)With these changes, we can now start up our `main` program. Notice that we start up in the same way, by passing in the necessary environment variables for the worker and manager and then using the command `go run main.go`. Also notice that the output we see looks the same as it has. We see that the program starts up the worker, then it starts up the manager, and then it starts cycling through, checking for new tasks, collecting stats, checking the status of tasks, and attempting to update any existing tasks:

```bash
$ CUBE_WORKER_HOST=localhost CUBE_WORKER_PORT=5556
 CUBE_MANAGER_HOST=localhost CUBE_MANAGER_PORT=5555 go run main.go
Starting Cube worker
Starting Cube manager
2022/11/12 11:28:48 No tasks to process currently.
2022/11/12 11:28:48 Sleeping for 10 seconds.
2022/11/12 11:28:48 Collecting stats
2022/11/12 11:28:48 Checking status of tasks
2022/11/12 11:28:48 Task updates completed
2022/11/12 11:28:48 Sleeping for 15 seconds
2022/11/12 11:28:48 Processing any tasks in the queue
2022/11/12 11:28:48 No work in the queue
2022/11/12 11:28:48 Sleeping for 10 seconds
2022/11/12 11:28:48 Checking for task updates from workers
2022/11/12 11:28:48 Checking worker localhost:5556 for task updates
2022/11/12 11:28:48 Checking worker localhost:5557 for task updates
2022/11/12 11:28:48 Checking worker localhost:5558 for task updates
2022/11/12 11:28:48 Performing task health check
2022/11/12 11:28:48 Task health checks completed
2022/11/12 11:28:48 Sleeping for 60 seconds
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)Next, let’s send a task to our manager. We’ll use the same command that we have in past chapters to start up an instance of the echo server. The output from the `curl` command looks like what we’re used to seeing from previous chapters:

```bash
$ curl -X POST localhost:5555/tasks -d @task1.json
{
   "ID":"bb1d59ef-9fc1-4e4b-a44d-db571eeed203",
   "ContainerID":"",
   "Name":"test-chapter-9.1",
   "State":1,
   "Image":"timboring/echo-server:latest",
   "Cpu":0,
   "Memory":0,
   "Disk":0,
   "ExposedPorts": {
       "7777/tcp": {}
   },
   "HostPorts":null,
   "PortBindings": {
       "7777/tcp":"7777"
   },
   "RestartPolicy":"",
   "StartTime":"0001-01-01T00:00:00Z",
   "FinishTime":"0001-01-01T00:00:00Z",
   "HealthCheck":"/health",
   "RestartCount":0
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)After sending the task to the manager, we should see something like the following in the output of our main program. This should look familiar. The manager is checking its pending queue for tasks, and it finds the task we sent it:

```
2022/11/12 11:40:18 Processing any tasks in the queue
2022/11/12 11:40:18 Pulled {a7aa1d44-08f6-443e-9378-f5884311019e 2
 0001-01-01 00:00:00 +0000 UTC {bb1d59ef-9fc1-4e4b-a44d-db571eeed203
 test-chapter-9.1 1 timboring/echo-server:latest 0 0 0 map[7777/tcp:{}]
 map[] map[7777/tcp:7777]  0001-01-01 00:00:00 +0000 UTC 0001-01-01
 00:00:00 +0000 UTC /health 0}} off pending queue
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)The following output is from the worker. It shows that the manager selected it when it called its `SelectWorker` method, which calls the `SelectCandidateNodes`, `Score`, and `Pick` methods on the scheduler:[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)

```
Found task in queue: {bb1d59ef-9fc1-4e4b-a44d-db571eeed203  test-chapter-9.1
 1 timboring/echo-server:latest 0 0 0 map[7777/tcp:{}] map[]
 map[7777/tcp:7777]  0001-01-01 00:00:00 +0000 UTC 0001-01-01 00:00:00
 +0000 UTC /health 0}: 2022/11/12 11:40:28 attempting to transition
 from 1 to 1
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)Once the task is running, we can see the manager check it for any updates:

```
2022/11/12 11:40:33 Checking for task updates from workers
2022/11/12 11:40:33 Checking worker localhost:5556 for task updates
2022/11/12 11:40:33 [manager] Attempting to update task
 bb1d59ef-9fc1-4e4b-a44d-db571eeed203
2022/11/12 11:40:33 Task updates completed
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)At this point, we can start the other two tasks we’ve been using in past chapters. Using the `RoundRobin` scheduler, you should notice the manager selecting each of the other two workers in succession. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)We can see that the round-robin scheduler works. Now let’s implement a second scheduler. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)

## [](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)10.8 The E-PVM scheduler

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)The next type of scheduler we’re going to implement is more sophisticated than our round-robin scheduler. For our new scheduler, our goal is to spread the tasks across our cluster of worker machines so we minimize the CPU load of each node. In other words, we would rather each node in our cluster do some work and have overhead for any bursts of work. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)

### [](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)10.8.1 The theory

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)To accomplish our goal of spreading the load across our cluster, we’re going to use an opportunity cost approach to scoring our tasks. It is one of the approaches that Google used for its Borg orchestrator in its early days and is based on the work presented in the paper “An Opportunity Cost Approach for Job Assignment in a Scalable Computing Cluster” ([https://mosix.cs.huji.ac.il/pub/ocja.pdf](https://mosix.cs.huji.ac.il/pub/ocja.pdf)). According to the paper, “the key idea . . . is to convert the total usage of several heterogeneous resources . . . into a single homogeneous “cost.” Jobs are then assigned to the machine where they have the lowest cost.” The heterogenous resources are CPU and memory. The authors call this method *Enhanced PVM* (where *PVM* stands for *Parallel Virtual Machine* ). [](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)The main idea here is that when a new task enters the system and needs to be scheduled, this algorithm will calculate a `marginal_cost` for each machine in our cluster. What does *marginal cost* mean? If each machine has a homogeneous cost that represents the total usage of all its resources, then the marginal cost is the amount by which that homogeneous cost will increase if we add a new task to its workload. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)The paper provides us with the pseudocode for this algorithm, as seen in listing 10.17. If the `marginal_cost` of assigning the job to a machine is less than the `MAX_COST`, we assign the machine to `machine_pick`. Once we’ve iterated through our list of machines, `machine_pick` will contain the machine with the lowest marginal cost. We will slightly modify our implementation of this pseudocode to fit our own purposes. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)

##### Listing 10.17 Pseudocode describing the algorithm used in the E-PVM scheduling method

```
max_jobs = 1;
 
while () {
    machine_pick = 1; cost = MAX_COST
    repeat {} until (new job j arrives)
    for (each machine m) {
        marginal_cost = power(n, percentage memory utilization on
         m if j was added) +
        power(n, (jobs on m + 1/max_jobs) - power(n, memory use on m)
         - power(n, jobs on m/max_jobs));
 
        if (marginal_cost < cost) { machine_pick = m; }
    }
 
    assign job to machine_pick;
    if (jobs on machine_pick > max_jobs) max_jobs = max_jobs * 2;
}
```

### [](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)10.8.2 In practice

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)Implementing our new scheduler, which we’ll call the E-PVM scheduler, will follow a path similar to the one we used to adapt the round-robin algorithm to our scheduler interface. We start by defining the `Epvm` struct. Notice that we’re only defining a single field, `Name`, because we don’t need to keep track of the last selected node as we did for the round-robin scheduler:[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)

```
type Epvm struct {
   Name string
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)Next, we implement the `SelectCandidateNodes` method of the E-PVM scheduler. Unlike the round-robin scheduler, in this version of `SelectCandidateNodes`, we attempt to narrow the list of potential candidates. We do this by checking that the resources the task is requesting are less than the resources the node has available. For our purposes, we’re only checking disk because we want to ensure the selected node has the available disk space to download the task’s Docker image. The `Epvm` scheduler’s `SelectCandidateNodes` method filters out any nodes that can’t meet the task’s disk requirements. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)

##### Listing 10.18 The `Epvm` scheduler’s `SelectCandidateNodes` method

```
func (e *Epvm) SelectCandidateNodes(t task.Task, nodes []*node.Node)
     []*node.Node {
    var candidates []*node.Node
    for node := range nodes {
        if checkDisk(t, nodes[node].Disk-nodes[node].DiskAllocated) {
            candidates = append(candidates, nodes[node])
        }
    }
 
    return candidates
}
 
func checkDisk(t task.Task, diskAvailable int64) bool {
    return t.Disk <= diskAvailable
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)Now let’s dive into the meat of the E-PVM scheduler. It’s time to implement the `Score` method based on the E-PVM pseudocode. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)We start by defining a couple of variables that we’ll use later in the method. The first variable we define is `nodeScores`, which is a type of `map[string]float64` and will hold the scores of each node. Next we define the `maxJobs` variable. We are randomly setting it to the value of `4.0`, meaning each node can handle four tasks at most. I chose this value because I initially developed the code for this book using a cluster of several Raspberry Pis, and it seemed like a reasonable guess as to how many tasks each Pi could handle. In a production system, we would tune this value based on an analysis of observed metrics from our running production system. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)The next step is to iterate over each of our `nodes` passed into the method and calculate the marginal cost of assigning the task to the node. This process involves eight steps.

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)To calculate the node’s current CPU usage, we use the `calculateCpuUsage` helper function defined later. Then we call the `calculateLoad` helper function. This function takes two parameters, `usage` and `capacity`. The `usage` value we get from the previous call to `calculateCpuUsage`, and for the capacity, we use a fraction of what we think our max load will be. This definition of usage comes from the E-PVM paper, which assumes that the maximum possible load is “the smallest integer power of two greater than the largest load we have seen at any given time.” Again, given that I originally developed this code using Raspberry Pis, and only three of them at that, I guessed that the highest load seen on any of the nodes was 80%. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)The E-PVM scheduler’s `Score` has the same signature as the one in the `RoundRobin` scheduler, but it calculates scores in a more complicated way.

##### Listing 10.19 Signature of the E-PVM scheduler’s `Score`

```
const (
    // LIEB square ice constant
    // https://en.wikipedia.org/wiki/Lieb%27s_square_ice_constant
    LIEB = 1.53960071783900203869
)
 
func (e *Epvm) Score(t task.Task, nodes []*node.Node) map[string]float64 {
    nodeScores := make(map[string]float64)
    maxJobs := 4.0
 
    for _, node := range nodes {
        cpuUsage := calculateCpuUsage(node)
        cpuLoad := calculateLoad(cpuUsage, math.Pow(2, 0.8))
 
        memoryAllocated := float64(node.Stats.MemUsedKb()) +
         float64(node.MemoryAllocated)
        memoryPercentAllocated := memoryAllocated / float64(node.Memory)
 
        newMemPercent := (calculateLoad(memoryAllocated +
         float64(t.Memory/1000), float64(node.Memory)))
 
        memCost := math.Pow(LIEB, newMemPercent) + math.Pow(LIEB,
         (float64(node.TaskCount+1))/maxJobs) -
         math.Pow(LIEB, memoryPercentAllocated) -
         math.Pow(LIEB, float64(node.TaskCount)/float64(maxJobs))
        cpuCost := math.Pow(LIEB, cpuLoad) +
         math.Pow(LIEB, (float64(node.TaskCount+1))/maxJobs) -
         math.Pow(LIEB, cpuLoad) -
         math.Pow(LIEB, float64(node.TaskCount)/float64(maxJobs))
 
        nodeScores[node.Name] = memCost + cpuCost
            nodeScores[node.Name] = marginalCost
        }
    }
    return nodeScores
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)Our score method uses two helper functions to calculate CPU usage and load. The first of these helpers, `calculateCpuUsage`, is itself a multistep process. The code for this function is based on the algorithm presented in the Stack Overflow post at [https://stackoverflow.com/a/23376195](https://stackoverflow.com/a/23376195). I won’t go into more details about this algorithm because the post does a good job of covering the topic. I’d urge you to read it if you are interested. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)

##### Listing 10.20 The `calculateCpuUsage` helper function

```
func calculateCpuUsage(node *node.Node) *float64 {
    stat1 := getNodeStats(node)
    time.Sleep(3 * time.Second)
    stat2 := getNodeStats(node)
 
    stat1Idle := stat1.CpuStats.Idle + stat1.CpuStats.IOWait
    stat2Idle := stat2.CpuStats.Idle + stat2.CpuStats.IOWait
 
    stat1NonIdle := stat1.CpuStats.User + stat1.CpuStats.Nice +
     stat1.CpuStats.System + stat1.CpuStats.IRQ +
     stat1.CpuStats.SoftIRQ + stat1.CpuStats.Steal
 
    stat2NonIdle := stat2.CpuStats.User + stat2.CpuStats.Nice +
     stat2.CpuStats.System + stat2.CpuStats.IRQ +
     stat2.CpuStats.SoftIRQ + stat2.CpuStats.Steal
 
    stat1Total := stat1Idle + stat1NonIdle
    stat2Total := stat2Idle + stat2NonIdle
 
    total := stat2Total - stat1Total
    idle := stat2Idle - stat1Idle
 
    var cpuPercentUsage float64
    if total == 0 && idle == 0 {
        cpuPercentUsage = 0.00
    } else {
        cpuPercentUsage = (float64(total) - float64(idle)) / float64(total)
    }
    return &cpuPercentUsage
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)Note that this function uses a second helper function, `getNodeStats`. This function, seen in the following listing, is calling the `/stats` endpoint on the worker node and retrieving the worker’s stats at that point in time. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)

##### Listing 10.21 The `getNodeStats` helper function returning the stats for a given node

```
func getNodeStats(node *node.Node) *stats.Stats {
   url := fmt.Sprintf("%s/stats", node.Api)
   resp, err := http.Get(url)
   if err != nil {
       log.Printf("Error connecting to %v: %v", node.Api, err)
   }

   if resp.StatusCode != 200 {
       log.Printf("Error retrieving stats from %v: %v", node.Api, err)
   }

   defer resp.Body.Close()
   body, _ := ioutil.ReadAll(resp.Body)
   var stats stats.Stats
   json.Unmarshal(body, &stats)
   return &stats
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)The third helper function used by our `Score` method is the `calculateLoad` function. This function is much simpler than the `calculateCpuUsage` function. It takes two parameters: `usage`, which is of type `float64`, and `capacity`, also a `float64` type. Then it simply divides `usage` by `capacity` and returns the result:[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)

```
func calculateLoad(usage float64, capacity float64) float64 {
   return usage / capacity
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)The final method of our E-PVM scheduler to implement is the `Pick` method. This method is similar to the same method in the round-robin scheduler. It differs only in changing the name of the `lowestScore` variable to `minCost` to reflect the shift to the E-PVM scheduler’s focus on marginal cost. Otherwise, the method performs the same basic purpose: to select the node with the minimum, or lowest, cost. The E-PVM scheduler’s `Pick` method, as shown in the following listing, is almost identical to the one in the `RoundRobin` scheduler. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)

##### Listing 10.22 The E-PVM scheduler’s `Pick` method

```
func (e *Epvm) Pick(scores map[string]float64, candidates []*node.Node) *node.Node {
   minCost := 0.00
   var bestNode *node.Node
   for idx, node := range candidates {
       if idx == 0 {
           minCost = scores[node.Name]
           bestNode = node
           continue
       }

       if scores[node.Name] < minCost {
           minCost = scores[node.Name]
           bestNode = node
       }
   }
   return bestNode
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)With the implementation of the `Pick` method, we have completed the implementation of our second scheduler. This scheduler, like the round-robin scheduler, implements the `Scheduler` interface. As a result, we can use either scheduler in our manager. Before we change our `main.go` program to use this new scheduler, however, let’s take a minor detour and take care of some unfinished business. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)

## [](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)10.9 Completing the Node implementation

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)Earlier, we implemented a helper function named `getNodeStats`. This function takes a variable `node`, which is a pointer to a `node.Node` type. As the name of the function suggests, it communicates with the node by making a `GET` call to the node’s `/stats` endpoint. It then returns the resulting stats from the node as a pointer to a `stats.Stats` type. This function is part of the scheduler, so it’s awkward to have it handle the lower-level details of calling the node’s `/stats` endpoint, checking the response, and decoding the response from JSON. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)Let’s factor this code out of the scheduler and put it where it really belongs—in the `Node` type. We implemented the `Node` type back in chapter 2, so let’s review what it looks like since it has been a while since we’ve seen it. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)The `Node` type is pretty straightforward, as we can see in the next listing. Its fields hold the values that represent various attributes of our physical or virtual machine that’s performing the role of the worker.

##### Listing 10.23 The `Node` type defined in chapter 2

```
type Node struct {
   Name            string
   Ip              string
   Cores           int64
   Memory          int64
   MemoryAllocated int64
   Disk            int64
   DiskAllocated   int64
   Stats           stats.Stats
   Role            string
   TaskCount       int
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)Before we actually move the `getNodesStats` function, let’s implement another helper function. We’ll name this helper function `HTTPWithRetry`, and we’re going to use it from the `getNodesStats` function. `HTTPWithRetry` will ensure we can (eventually) get the stats from a worker even in the case where a worker experiences transient problems—say, for example, the node rebooted or there is a temporary network problem. So rather than simply failing after a single attempt to call the `/stats` endpoint, we make several attempts before giving up. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)`HTTPWithRetry` will take a function `f(string)` and a string `url` as arguments. The `f(string)` argument will be an HTTP method from the `net/http` package (e.g., `http.Get`). The function returns a pointer to the HTTP response and potentially an error. When we call `HTTPWithRetry`, it will look like this:

```
result, err := utils.HTTPWithRetry(http.Get, "http://localhost:5556/stats")
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)In the body of the function, we initialize a counter, `count`, to 10. Then we use the counter in a `for` loop, where we call the function `f(string)` and check the response. If the function returns an error, we sleep for 5 seconds and then try again. If the function is successful, we break out of the loop. Finally, we return the HTTP response and an error. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)We’re going to place the `HTTPWithRetry` function in its own package. Create a new directory in your project called `utils`, and inside that directory, create a file named `retry.go`. Inside this file, let’s add the code from the following listing. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)

##### Listing 10.24 The `HTTPWithRetry` helper function in the new `utils` package

```
package utils

import (
   "fmt"
   "net/http"
   "time"
)

func HTTPWithRetry(f func(string) (*http.Response, error), url string) (*http.Response, error) {
   count := 10
   var resp *http.Response
   var err error
   for i := 0; i < count; i++ {
       resp, err = f(url)
       if err != nil {
           fmt.Printf("Error calling url %v\n", url)
           time.Sleep(5 * time.Second)
       } else {
           break
       }
   }
   return resp, err
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)With the `HTTPWithRetry` helper defined, let’s return to the `getNodesStats` function. Remove it from our `scheduler.go` file, and add it to the `node.go` file in the `node/` package directory. As part of this moving process, let’s also change the name to `GetStats` and make it a method of the `node.Node` type. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)

##### Listing 10.25 Renaming the `getNodeStats` helper function

```
func (n *Node) GetStats() (*stats.Stats, error) {
    var resp *http.Response
    var err error
 
    url := fmt.Sprintf("%s/stats", n.Api)
    resp, err = utils.HTTPWithRetry(http.Get, url)
    if err != nil {
        msg := fmt.Sprintf("Unable to connect to %v. Permanent failure.\n",
         n.Api)
        log.Println(msg)
        return nil, errors.New(msg)
    }
 
    if resp.StatusCode != 200 {
        msg := fmt.Sprintf("Error retrieving stats from %v: %v", n.Api, err)
        log.Println(msg)
        return nil, errors.New(msg)
    }
 
    defer resp.Body.Close()
    body, _ := ioutil.ReadAll(resp.Body)
    var stats stats.Stats
    err = json.Unmarshal(body, &stats)
    if err != nil {
        msg := fmt.Sprintf("error decoding message while getting stats for
         node %s", n.Name)
        log.Println(msg)
        return nil, errors.New(msg)
    }
 
    n.Memory = int64(stats.MemTotalKb())
    n.Disk = int64(stats.DiskTotal())
 
    n.Stats = stats
 
    return &n.Stats, nil
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)With the `GetStats` method now implemented on the `Node` type, we can remove the old `getNodeStats` helper function from `scheduler.go`. And finally, we can update the `calculateCpuUsage` helper function to use the `node.GetStats` method. In addition to using the `node.GetStats` method, let’s also change the function signature to return a pointer to a `float64` and an `error`. The changed function looks like this:[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)

```
func calculateCpuUsage(node *node.Node) (*float64, error) {
   //stat1 := getNodeStats(node)
   stat1, err := node.GetStats()
   if err != nil {
       return nil, err
   }
   time.Sleep(3 * time.Second)
   //stat2 := getNodeStats(node)
   stat2, err := node.GetStats()
   if err != nil {
       return nil, err
   }

   // unchanged code

   return &cpuPercentUsage, nil
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)The `GetStats` helper calls a node’s worker API, so we need to expose the `/stats` endpoint on the worker `Api` type. This change is simple:[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)

```
func (a *Api) initRouter() {
   // previous code unchanged

   a.Router.Route("/stats", func(r chi.Router) {
       r.Get("/", a.GetStatsHandler)
   })
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)With these changes, we have completed our detour. Now let’s return to our fancy new `E-PVM` scheduler and take it for a spin![](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)

## [](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)10.10 Using the E-PVM scheduler

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)At this point, we have all the work completed on our shiny new scheduler interface. We have two types of schedulers we can use in our manager: the round-robin scheduler and the E-PVM scheduler. We have already made most of the necessary changes to use the scheduler interface, but we have a few minor tweaks to make that will allow us to easily switch between the `RoundRobin` and `Epvm` scheduler types implemented previously. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)The first change to make involves adding a new `case` to the `switch` statement in the manager’s `New` function. The new case adds support for the `Epvm` scheduler. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)

##### Listing 10.26 Adding a new `"epvm"` case to the `switch` statement

```
switch schedulerType {
case "roundrobin":                                  #1
    s = &scheduler.RoundRobin{Name: "roundrobin"}
case "epvm"                                         #2
    s = &scheduler.Epvm{Name: "epvm"}
default:
    s = &scheduler.RoundRobin{Name: "roundrobin"}   #3
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)The second and final change happens in our `main.go` program. If you recall, we previously created a new instance of the manager with the `"roundrobin"` scheduler using the `New` function:

```
func main() {
   m := manager.New(workers, "roundrobin")
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)Now, however, we want to create an instance of the manager that will use the `Epvm` scheduler. To do this, we can simply change the string in the call to `New` from `roundrobin` to `epvm`:

```
func main() {
   m := manager.New(workers, "epvm")
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)That’s it! We can now run our main program, and it will use the `Epvm` scheduler instead of the `RoundRobin` scheduler. Give it a try![](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)

## [](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)Summary

-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)The scheduling problem exists all around us, from home chores to seating customers in a restaurant.
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)Scheduling does not have a one-size-fits-all solution. There are multiple solutions, and each one makes tradeoffs based on what we are trying to achieve. It can be as simple as using a round-robin algorithm to select each node in turn. Or it can be as complex as devising a method to calculate a score for each node based on some set of data—for example, the current CPU load and memory usage of each node.
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)For the purposes of scheduling tasks in an orchestration system, we can generalize the process to three functions: selecting candidate nodes, which involves reducing the number of possible nodes based on some selection criteria (e.g., does the node have enough disk space to pull the task’s container image?); scoring the set of candidate nodes; and finally, picking the best candidate node.
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)We can use these three functions to create a general framework to allow us to implement multiple schedulers. In Go, the `interface` is what allows us to create this framework.
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)In this chapter, we started three workers, in contrast to a single one in past chapters. Using three workers allowed us to see a more realistic example of how the scheduling process works. However, it’s not the same as a more real-world scenario of using multiple physical or virtual machines. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-10/)

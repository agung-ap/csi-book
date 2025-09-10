# CHAPTER *7*

# Deadlocks

In a multiprogramming environment, several processes may compete for a finite number of resources. A process requests resources; if the resources are not available at that time, the process enters a waiting state. Sometimes, a waiting process is never again able to change state, because the resources it has requested are held by other waiting processes. This situation is called a **deadlock**. We discussed this issue briefly in [Chapter 5](https://learning.oreilly.com/library/view/operating-system-concepts/9781118063330/12_chapter05.html#chap5) in connection with semaphores.

Perhaps the best illustration of a deadlock can be drawn from a law passed by the Kansas legislature early in the 20th century. It said, in part: “When two trains approach each other at a crossing, both shall come to a full stop and neither shall start up again until the other has gone.”

In this chapter, we describe methods that an operating system can use to prevent or deal with deadlocks. Although some applications can identify programs that may deadlock, operating systems typically do not provide deadlock-prevention facilities, and it remains the responsibility of programmers to ensure that they design deadlock-free programs. Deadlock problems can only become more common, given current trends, including larger numbers of processes, multithreaded programs, many more resources within a system, and an emphasis on long-lived file and database servers rather than batch systems.

CHAPTER OBJECTIVES

- To develop a description of deadlocks, which prevent sets of concurrent processes from completing their tasks.
- To present a number of different methods for preventing or avoiding deadlocks in a computer system.

## 7.1 System Model

A system consists of a finite number of resources to be distributed among a number of competing processes. The resources may be partitioned into several types (or classes), each consisting of some number of identical instances. CPU cycles, files, and I/O devices (such as printers and DVD drives) are examples of resource types. If a system has two CPUs, then the resource type *CPU* has two instances. Similarly, the resource type *printer* may have five instances.

If a process requests an instance of a resource type, the allocation of ***any*** instance of the type should satisfy the request. If it does not, then the instances are not identical, and the resource type classes have not been defined properly. For example, a system may have two printers. These two printers may be defined to be in the same resource class if no one cares which printer prints which output. However, if one printer is on the ninth floor and the other is in the basement, then people on the ninth floor may not see both printers as equivalent, and separate resource classes may need to be defined for each printer.

[Chapter 5](https://learning.oreilly.com/library/view/operating-system-concepts/9781118063330/12_chapter05.html#chap5) discussed various synchronization tools, such as mutex locks and semaphores. These tools are also considered system resources, and they are a common source of deadlock. However, a lock is typically associated with protecting a specific data structure—that is, one lock may be used to protect access to a queue, another to protect access to a linked list, and so forth. For that reason, each lock is typically assigned its own resource class, and definition is not a problem.

A process must request a resource before using it and must release the resource after using it. A process may request as many resources as it requires to carry out its designated task. Obviously, the number of resources requested may not exceed the total number of resources available in the system. In other words, a process cannot request three printers if the system has only two.

Under the normal mode of operation, a process may utilize a resource in only the following sequence:

1. **Request**. The process requests the resource. If the request cannot be granted immediately (for example, if the resource is being used by another process), then the requesting process must wait until it can acquire the resource.
1. **Use**. The process can operate on the resource (for example, if the resource is a printer, the process can print on the printer).
1. **Release**. The process releases the resource.

The request and release of resources may be system calls, as explained in [Chapter 2](https://learning.oreilly.com/library/view/operating-system-concepts/9781118063330/08_chapter02.html#chap2). Examples are the request() and release() device, open() and close() file, and allocate() and free() memory system calls. Similarly, as we saw in [Chapter 5](https://learning.oreilly.com/library/view/operating-system-concepts/9781118063330/12_chapter05.html#chap5), the request and release of semaphores can be accomplished through the wait() and signal() operations on semaphores or through acquire() and release() of a mutex lock. For each use of a kernel-managed resource by a process or thread, the operating system checks to make sure that the process has requested and has been allocated the resource. A system table records whether each resource is free or allocated. For each resource that is allocated, the table also records the process to which it is allocated. If a process requests a resource that is currently allocated to another process, it can be added to a queue of processes waiting for this resource.

A set of processes is in a deadlocked state when every process in the set is waiting for an event that can be caused only by another process in the set. The events with which we are mainly concerned here are resource acquisition and release. The resources may be either physical resources (for example, printers, tape drives, memory space, and CPU cycles) or logical resources (for example, semaphores, mutex locks, and files). However, other types of events may result in deadlocks (for example, the IPC facilities discussed in [Chapter 3](https://learning.oreilly.com/library/view/operating-system-concepts/9781118063330/10_chapter03.html#chap3)).

To illustrate a deadlocked state, consider a system with three CD RW drives. Suppose each of three processes holds one of these CD RW drives. If each process now requests another drive, the three processes will be in a deadlocked state. Each is waiting for the event “CD RW is released,” which can be caused only by one of the other waiting processes. This example illustrates a deadlock involving the same resource type.

Deadlocks may also involve different resource types. For example, consider a system with one printer and one DVD drive. Suppose that process *Pi* is holding the DVD and process *Pj* is holding the printer. If *Pi* requests the printer and *Pj* requests the DVD drive, a deadlock occurs.

Developers of multithreaded applications must remain aware of the possibility of deadlocks. The locking tools presented in [Chapter 5](https://learning.oreilly.com/library/view/operating-system-concepts/9781118063330/12_chapter05.html#chap5) are designed to avoid race conditions. However, in using these tools, developers must pay careful attention to how locks are acquired and released. Otherwise, deadlock can occur, as illustrated in the dining-philosophers problem in [Section 5.7.3](https://learning.oreilly.com/library/view/operating-system-concepts/9781118063330/12_chapter05.html#sec5.7.3).

## 7.2 Deadlock Characterization

In a deadlock, processes never finish executing, and system resources are tied up, preventing other jobs from starting. Before we discuss the various methods for dealing with the deadlock problem, we look more closely at features that characterize deadlocks.

DEADLOCK WITH MUTEX LOCKS

Let's see how deadlock can occur in a multithreaded Pthread program using mutex locks. The pthread_mutex_init() function initializes an unlocked mutex. Mutex locks are acquired and released using pthread_mutex_lock() and pthread_mutex_unlock(), respectively. If a thread attempts to acquire a locked mutex, the call to pthread_mutex_lock() blocks the thread until the owner of the mutex lock invokes pthread_mutex_unlock().

Two mutex locks are created in the following code example:

```
/* Create and initialize the mutex locks */
pthread_mutex_t first_mutex;
pthread_mutex_t second_mutex;

pthread_mutex_init(&first_mutex, NULL);
pthread_mutex_init(&second_mutex, NULL);
```

Next, two threads—thread_one and thread_two—are created, and both these threads have access to both mutex locks. thread_one and thread_two run in the functions do_work_one() and do_work_two(), respectively, as shown below:

```
/* thread_one runs in this function */
void *do_work_one(void *param)
{
   pthread_mutex_lock(&first_mutex);
   pthread_mutex_lock(&second_mutex);
   /**
    * Do some work
    */
   pthread_mutex_unlock(&second_mutex);
   pthread_mutex_unlock(&first_mutex);

   pthread_exit(0);
}

/* thread_two runs in this function */
void *do_work_two(void *param)
{
   pthread_mutex_lock(&second_mutex);
   pthread_mutex_lock(&first_mutex);
   /**
    * Do some work
    */
   pthread_mutex_unlock(&first_mutex);
   pthread_mutex_unlock(&second_mutex);

   pthread_exit(0);
}
```

In this example, thread_one attempts to acquire the mutex locks in the order (1) first_mutex, (2) second_mutex, while thread_two attempts to acquire the mutex locks in the order (1) second_mutex, (2) first_mutex. Deadlock is possible if thread_one acquires first_mutex while thread_two acquires second_mutex.

Note that, even though deadlock is possible, it will not occur if thread_one can acquire and release the mutex locks for first_mutex and second_mutex before thread_two attempts to acquire the locks. And, of course, the order in which the threads run depends on how they are scheduled by the CPU scheduler. This example illustrates a problem with handling deadlocks: it is difficult to identify and test for deadlocks that may occur only under certain scheduling circumstances.

### 7.2.1 Necessary Conditions

A deadlock situation can arise if the following four conditions hold simultaneously in a system:

1. **Mutual exclusion**. At least one resource must be held in a nonsharable mode; that is, only one process at a time can use the resource. If another process requests that resource, the requesting process must be delayed until the resource has been released.
1. **Hold and wait**. A process must be holding at least one resource and waiting to acquire additional resources that are currently being held by other processes.
1. **No preemption**. Resources cannot be preempted; that is, a resource can be released only voluntarily by the process holding it, after that process has completed its task.
1. **Circular wait**. A set {*P*0, *P*1, …, *Pn*} of waiting processes must exist such that *P*0 is waiting for a resource held by *P*1, *P*1 is waiting for a resource held by *P*2, …, *P**n*−1 is waiting for a resource held by *Pn*, and *Pn* is waiting for a resource held by *P*0.

We emphasize that all four conditions must hold for a deadlock to occur. The circular-wait condition implies the hold-and-wait condition, so the four conditions are not completely independent. We shall see in [Section 7.4](https://learning.oreilly.com/library/view/operating-system-concepts/9781118063330/14_chapter07.html#sec7.4), however, that it is useful to consider each condition separately.

### 7.2.2 Resource-Allocation Graph

Deadlocks can be described more precisely in terms of a directed graph called a **system resource-allocation graph**. This graph consists of a set of vertices *V* and a set of edges *E*. The set of vertices *V* is partitioned into two different types of nodes: *P* = {*P*1, *P*2, …, *Pn*}, the set consisting of all the active processes in the system, and *R* = {*R*1, *R*2, …, *Rm*}, the set consisting of all resource types in the system.

A directed edge from process *Pi* to resource type *Rj* is denoted by *Pi* → *Rj*; it signifies that process *Pi* has requested an instance of resource type *Rj* and is currently waiting for that resource. A directed edge from resource type *Rj* to process *Pi* is denoted by *Rj* → *Pi*; it signifies that an instance of resource type *Rj* has been allocated to process *Pi*. A directed edge *Pi* → *Rj* is called a **request edge**; a directed edge *Rj* → *Pi* is called an **assignment edge**.

Pictorially, we represent each process *Pi* as a circle and each resource type *Rj* as a rectangle. Since resource type *Rj* may have more than one instance, we represent each such instance as a dot within the rectangle. Note that a request edge points to only the rectangle *Rj*, whereas an assignment edge must also designate one of the dots in the rectangle.

When process *Pi* requests an instance of resource type *Rj*, a request edge is inserted in the resource-allocation graph. When this request can be fulfilled, the request edge is ***instantaneously*** transformed to an assignment edge. When the process no longer needs access to the resource, it releases the resource. As a result, the assignment edge is deleted.

The resource-allocation graph shown in [Figure 7.1](https://learning.oreilly.com/library/view/operating-system-concepts/9781118063330/14_chapter07.html#fig7.1) depicts the following situation.

- The sets *P, R*, and *E*:

- *P* = {*P*1, *P*2, *P*3}

![image](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781118063330/files/images/ch007-f001.jpg)

**Figure 7.1** Resource-allocation graph.

- *R* = {*R*1, *R*2, *R*3, *R*4}
- *E* = {*P*1 → *R*1, *P*2 → *R*3, *R*1 → *P*2, *R*2 → *P*2, *R*2 → *P*1, *R*3 → *P*3}

- Resource instances:

- One instance of resource type *R*1
- Two instances of resource type *R*2
- One instance of resource type *R*3
- Three instances of resource type *R*4

- Process states:

- Process *P*1 is holding an instance of resource type *R*2 and is waiting for an instance of resource type *R*1.
- Process *P*2 is holding an instance of *R*1 and an instance of *R*2 and is waiting for an instance of *R*3.
- Process *P*3 is holding an instance of *R*3.

Given the definition of a resource-allocation graph, it can be shown that, if the graph contains no cycles, then no process in the system is deadlocked. If the graph does contain a cycle, then a deadlock may exist.

If each resource type has exactly one instance, then a cycle implies that a deadlock has occurred. If the cycle involves only a set of resource types, each of which has only a single instance, then a deadlock has occurred. Each process involved in the cycle is deadlocked. In this case, a cycle in the graph is both a necessary and a sufficient condition for the existence of deadlock.

If each resource type has several instances, then a cycle does not necessarily imply that a deadlock has occurred. In this case, a cycle in the graph is a necessary but not a sufficient condition for the existence of deadlock.

To illustrate this concept, we return to the resource-allocation graph depicted in [Figure 7.1](https://learning.oreilly.com/library/view/operating-system-concepts/9781118063330/14_chapter07.html#fig7.1). Suppose that process *P*3 requests an instance of resource type *R*2. Since no resource instance is currently available, we add a request edge *P*3 → *R*2 to the graph ([Figure 7.2](https://learning.oreilly.com/library/view/operating-system-concepts/9781118063330/14_chapter07.html#fig7.2)). At this point, two minimal cycles exist in the system:

![image](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781118063330/files/images/ch007-f002.jpg)

**Figure 7.2** Resource-allocation graph with a deadlock.

*P*1 → *R*1 → *P*2 → *R*3 → *P*3 → *R*2 → *P*1
*P*2 → *R*3 → *P*3 → *R*2 → *P*2

Processes *P*1, *P*2, and *P*3 are deadlocked. Process *P*2 is waiting for the resource *R*3, which is held by process *P*3. Process *P*3 is waiting for either process *P*1 or process *P*2 to release resource *R*2. In addition, process *P*1 is waiting for process *P*2 to release resource *R*1.

Now consider the resource-allocation graph in [Figure 7.3](https://learning.oreilly.com/library/view/operating-system-concepts/9781118063330/14_chapter07.html#fig7.3). In this example, we also have a cycle:

*P*1 → *R*1 → *P*3 → *R*2 → *P*1

![image](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781118063330/files/images/ch007-f003.jpg)

**Figure 7.3** Resource-allocation graph with a cycle but no deadlock.

However, there is no deadlock. Observe that process *P*4 may release its instance of resource type *R*2. That resource can then be allocated to *P*3, breaking the cycle.

In summary, if a resource-allocation graph does not have a cycle, then the system is ***not*** in a deadlocked state. If there is a cycle, then the system may or may not be in a deadlocked state. This observation is important when we deal with the deadlock problem.

## 7.3 Methods for Handling Deadlocks

Generally speaking, we can deal with the deadlock problem in one of three ways:

- We can use a protocol to prevent or avoid deadlocks, ensuring that the system will ***never*** enter a deadlocked state.
- We can allow the system to enter a deadlocked state, detect it, and recover.
- We can ignore the problem altogether and pretend that deadlocks never occur in the system.

The third solution is the one used by most operating systems, including Linux and Windows. It is then up to the application developer to write programs that handle deadlocks.

Next, we elaborate briefly on each of the three methods for handling deadlocks. Then, in [Sections 7.4](https://learning.oreilly.com/library/view/operating-system-concepts/9781118063330/14_chapter07.html#sec7.4) through [7.7](https://learning.oreilly.com/library/view/operating-system-concepts/9781118063330/14_chapter07.html#sec7.7), we present detailed algorithms. Before proceeding, we should mention that some researchers have argued that none of the basic approaches alone is appropriate for the entire spectrum of resource-allocation problems in operating systems. The basic approaches can be combined, however, allowing us to select an optimal approach for each class of resources in a system.

To ensure that deadlocks never occur, the system can use either a deadlock-prevention or a deadlock-avoidance scheme. **Deadlock prevention** provides a set of methods to ensure that at least one of the necessary conditions ([Section 7.2.1](https://learning.oreilly.com/library/view/operating-system-concepts/9781118063330/14_chapter07.html#sec7.2.1)) cannot hold. These methods prevent deadlocks by constraining how requests for resources can be made. We discuss these methods in [Section 7.4](https://learning.oreilly.com/library/view/operating-system-concepts/9781118063330/14_chapter07.html#sec7.4).

**Deadlock avoidance** requires that the operating system be given additional information in advance concerning which resources a process will request and use during its lifetime. With this additional knowledge, the operating system can decide for each request whether or not the process should wait. To decide whether the current request can be satisfied or must be delayed, the system must consider the resources currently available, the resources currently allocated to each process, and the future requests and releases of each process. We discuss these schemes in [Section 7.5](https://learning.oreilly.com/library/view/operating-system-concepts/9781118063330/14_chapter07.html#sec7.5).

If a system does not employ either a deadlock-prevention or a deadlock-avoidance algorithm, then a deadlock situation may arise. In this environment, the system can provide an algorithm that examines the state of the system to determine whether a deadlock has occurred and an algorithm to recover from the deadlock (if a deadlock has indeed occurred). We discuss these issues in [Section 7.6](https://learning.oreilly.com/library/view/operating-system-concepts/9781118063330/14_chapter07.html#sec7.6) and [Section 7.7](https://learning.oreilly.com/library/view/operating-system-concepts/9781118063330/14_chapter07.html#sec7.7).

In the absence of algorithms to detect and recover from deadlocks, we may arrive at a situation in which the system is in a deadlocked state yet has no way of recognizing what has happened. In this case, the undetected deadlock will cause the system's performance to deteriorate, because resources are being held by processes that cannot run and because more and more processes, as they make requests for resources, will enter a deadlocked state. Eventually, the system will stop functioning and will need to be restarted manually.

Although this method may not seem to be a viable approach to the deadlock problem, it is nevertheless used in most operating systems, as mentioned earlier. Expense is one important consideration. Ignoring the possibility of deadlocks is cheaper than the other approaches. Since in many systems, deadlocks occur infrequently (say, once per year), the extra expense of the other methods may not seem worthwhile. In addition, methods used to recover from other conditions may be put to use to recover from deadlock. In some circumstances, a system is in a frozen state but not in a deadlocked state. We see this situation, for example, with a real-time process running at the highest priority (or any process running on a nonpreemptive scheduler) and never returning control to the operating system. The system must have manual recovery methods for such conditions and may simply use those techniques for deadlock recovery.

## 7.4 Deadlock Prevention

As we noted in [Section 7.2.1](https://learning.oreilly.com/library/view/operating-system-concepts/9781118063330/14_chapter07.html#sec7.2.1), for a deadlock to occur, each of the four necessary conditions must hold. By ensuring that at least one of these conditions cannot hold, we can ***prevent*** the occurrence of a deadlock. We elaborate on this approach by examining each of the four necessary conditions separately.

### 7.4.1 Mutual Exclusion

The mutual exclusion condition must hold. That is, at least one resource must be nonsharable. Sharable resources, in contrast, do not require mutually exclusive access and thus cannot be involved in a deadlock. Read-only files are a good example of a sharable resource. If several processes attempt to open a read-only file at the same time, they can be granted simultaneous access to the file. A process never needs to wait for a sharable resource. In general, however, we cannot prevent deadlocks by denying the mutual-exclusion condition, because some resources are intrinsically nonsharable. For example, a mutex lock cannot be simultaneously shared by several processes.

### 7.4.2 Hold and Wait

To ensure that the hold-and-wait condition never occurs in the system, we must guarantee that, whenever a process requests a resource, it does not hold any other resources. One protocol that we can use requires each process to request and be allocated all its resources before it begins execution. We can implement this provision by requiring that system calls requesting resources for a process precede all other system calls.

An alternative protocol allows a process to request resources only when it has none. A process may request some resources and use them. Before it can request any additional resources, it must release all the resources that it is currently allocated.

To illustrate the difference between these two protocols, we consider a process that copies data from a DVD drive to a file on disk, sorts the file, and then prints the results to a printer. If all resources must be requested at the beginning of the process, then the process must initially request the DVD drive, disk file, and printer. It will hold the printer for its entire execution, even though it needs the printer only at the end.

The second method allows the process to request initially only the DVD drive and disk file. It copies from the DVD drive to the disk and then releases both the DVD drive and the disk file. The process must then request the disk file and the printer. After copying the disk file to the printer, it releases these two resources and terminates.

Both these protocols have two main disadvantages. First, resource utilization may be low, since resources may be allocated but unused for a long period. In the example given, for instance, we can release the DVD drive and disk file, and then request the disk file and printer, only if we can be sure that our data will remain on the disk file. Otherwise, we must request all resources at the beginning for both protocols.

Second, starvation is possible. A process that needs several popular resources may have to wait indefinitely, because at least one of the resources that it needs is always allocated to some other process.

### 7.4.3 No Preemption

The third necessary condition for deadlocks is that there be no preemption of resources that have already been allocated. To ensure that this condition does not hold, we can use the following protocol. If a process is holding some resources and requests another resource that cannot be immediately allocated to it (that is, the process must wait), then all resources the process is currently holding are preempted. In other words, these resources are implicitly released. The preempted resources are added to the list of resources for which the process is waiting. The process will be restarted only when it can regain its old resources, as well as the new ones that it is requesting.

Alternatively, if a process requests some resources, we first check whether they are available. If they are, we allocate them. If they are not, we check whether they are allocated to some other process that is waiting for additional resources. If so, we preempt the desired resources from the waiting process and allocate them to the requesting process. If the resources are neither available nor held by a waiting process, the requesting process must wait. While it is waiting, some of its resources may be preempted, but only if another process requests them. A process can be restarted only when it is allocated the new resources it is requesting and recovers any resources that were preempted while it was waiting.

This protocol is often applied to resources whose state can be easily saved and restored later, such as CPU registers and memory space. It cannot generally be applied to such resources as mutex locks and semaphores.

### 7.4.4 Circular Wait

The fourth and final condition for deadlocks is the circular-wait condition. One way to ensure that this condition never holds is to impose a total ordering of all resource types and to require that each process requests resources in an increasing order of enumeration.

To illustrate, we let *R* = {*R*1, *R*2,…, *Rm*} be the set of resource types. We assign to each resource type a unique integer number, which allows us to compare two resources and to determine whether one precedes another in our ordering. Formally, we define a one-to-one function *F*: *R* → *N*, where *N* is the set of natural numbers. For example, if the set of resource types *R* includes tape drives, disk drives, and printers, then the function *F* might be defined as follows:

*F*(tape drive) = 1
*F*(disk drive) = 5
*F*(printer) = 12

We can now consider the following protocol to prevent deadlocks: Each process can request resources only in an increasing order of enumeration. That is, a process can initially request any number of instances of a resource type—say, *Ri*. After that, the process can request instances of resource type *Rj* if and only if *F*(*Rj*) > *F*(*Ri*). For example, using the function defined previously, a process that wants to use the tape drive and printer at the same time must first request the tape drive and then request the printer. Alternatively, we can require that a process requesting an instance of resource type *Rj* must have released any resources *Ri* such that *F*(*Ri*) ≥ *F*(*Rj*). Note also that if several instances of the same resource type are needed, a ***single*** request for all of them must be issued.

If these two protocols are used, then the circular-wait condition cannot hold. We can demonstrate this fact by assuming that a circular wait exists (proof by contradiction). Let the set of processes involved in the circular wait be {*P*0, *P*1,…, *Pn*}, where *Pi* is waiting for a resource *Ri*, which is held by process *P**i*+1. (Modulo arithmetic is used on the indexes, so that *Pn* is waiting for a resource *Rn* held by *P*0.) Then, since process *P**i*+1 is holding resource *Ri* while requesting resource *R**i*+1, we must have *F*(*Ri*) < *F*(*R**i*+1) for all *i.* But this condition means that *F*(*R*0) < *F*(*R*1) < … < *F*(*Rn*) < *F*(*R*0). By transitivity, *F*(*R*0) < *F*(*R*0), which is impossible. Therefore, there can be no circular wait.

We can accomplish this scheme in an application program by developing an ordering among all synchronization objects in the system. All requests for synchronization objects must be made in increasing order. For example, if the lock ordering in the Pthread program shown in [Figure 7.4](https://learning.oreilly.com/library/view/operating-system-concepts/9781118063330/14_chapter07.html#fig7.4) was

*F*(first_mutex) = 1
*F*(second_mutex) = 5

then thread_two could not request the locks out of order.

Keep in mind that developing an ordering, or hierarchy, does not in itself prevent deadlock. It is up to application developers to write programs that follow the ordering. Also note that the function *F* should be defined according to the normal order of usage of the resources in a system. For example, because the tape drive is usually needed before the printer, it would be reasonable to define *F*(tape drive) < *F*(printer).

![image](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781118063330/files/images/ch007-f004.jpg)

**Figure 7.4** Deadlock example.

Although ensuring that resources are acquired in the proper order is the responsibility of application developers, certain software can be used to verify that locks are acquired in the proper order and to give appropriate warnings when locks are acquired out of order and deadlock is possible. One lock-order verifier, which works on BSD versions of UNIX such as FreeBSD, is known as **witness**. Witness uses mutual-exclusion locks to protect critical sections, as described in [Chapter 5](https://learning.oreilly.com/library/view/operating-system-concepts/9781118063330/12_chapter05.html#chap5). It works by dynamically maintaining the relationship of lock orders in a system. Let's use the program shown in [Figure 7.4](https://learning.oreilly.com/library/view/operating-system-concepts/9781118063330/14_chapter07.html#fig7.4) as an example. Assume that thread_one is the first to acquire the locks and does so in the order (1) first_mutex, (2) second_mutex. Witness records the relationship that first_mutex must be acquired before second_mutex. If thread_two later acquires the locks out of order, witness generates a warning message on the system console.

It is also important to note that imposing a lock ordering does not guarantee deadlock prevention if locks can be acquired dynamically. For example, assume we have a function that transfers funds between two accounts. To prevent a race condition, each account has an associated mutex lock that is obtained from a get_lock() function such as shown in [Figure 7.5](https://learning.oreilly.com/library/view/operating-system-concepts/9781118063330/14_chapter07.html#fig7.5):

![image](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781118063330/files/images/ch007-f005.jpg)

**Figure 7.5** Deadlock example with lock ordering.

Deadlock is possible if two threads simultaneously invoke the transaction() function, transposing different accounts. That is, one thread might invoke

```
transaction(checking_account, savings_account, 25);
```

and another might invoke

```
transaction(savings_account, checking_account, 50);
```

We leave it as an exercise for students to fix this situation.

## 7.5 Deadlock Avoidance

Deadlock-prevention algorithms, as discussed in [Section 7.4](https://learning.oreilly.com/library/view/operating-system-concepts/9781118063330/14_chapter07.html#sec7.4), prevent deadlocks by limiting how requests can be made. The limits ensure that at least one of the necessary conditions for deadlock cannot occur. Possible side effects of preventing deadlocks by this method, however, are low device utilization and reduced system throughput.

An alternative method for avoiding deadlocks is to require additional information about how resources are to be requested. For example, in a system with one tape drive and one printer, the system might need to know that process *P* will request first the tape drive and then the printer before releasing both resources, whereas process *Q* will request first the printer and then the tape drive. With this knowledge of the complete sequence of requests and releases for each process, the system can decide for each request whether or not the process should wait in order to avoid a possible future deadlock. Each request requires that in making this decision the system consider the resources currently available, the resources currently allocated to each process, and the future requests and releases of each process.

The various algorithms that use this approach differ in the amount and type of information required. The simplest and most useful model requires that each process declare the ***maximum number*** of resources of each type that it may need. Given this a priori information, it is possible to construct an algorithm that ensures that the system will never enter a deadlocked state. A deadlock-avoidance algorithm dynamically examines the resource-allocation state to ensure that a circular-wait condition can never exist. The resource-allocation ***state*** is defined by the number of available and allocated resources and the maximum demands of the processes. In the following sections, we explore two deadlock-avoidance algorithms.

### 7.5.1 Safe State

A state is *safe* if the system can allocate resources to each process (up to its maximum) in some order and still avoid a deadlock. More formally, a system is in a safe state only if there exists a **safe sequence**. A sequence of processes <*P*1, *P*2,…, *Pn*> is a safe sequence for the current allocation state if, for each *Pi*, the resource requests that *Pi* can still make can be satisfied by the currently available resources plus the resources held by all *Pj*, with *j* < *i*. In this situation, if the resources that *Pi* needs are not immediately available, then *Pi* can wait until all *Pj* have finished. When they have finished, *Pi* can obtain all of its needed resources, complete its designated task, return its allocated resources, and terminate. When *Pi* terminates, *P**i*+1 can obtain its needed resources, and so on. If no such sequence exists, then the system state is said to be *unsafe.*

A safe state is not a deadlocked state. Conversely, a deadlocked state is an unsafe state. Not all unsafe states are deadlocks, however ([Figure 7.6](https://learning.oreilly.com/library/view/operating-system-concepts/9781118063330/14_chapter07.html#fig7.6)). An unsafe state ***may*** lead to a deadlock. As long as the state is safe, the operating system can avoid unsafe (and deadlocked) states. In an unsafe state, the operating system cannot prevent processes from requesting resources in such a way that a deadlock occurs. The behavior of the processes controls unsafe states.

To illustrate, we consider a system with twelve magnetic tape drives and three processes: *P*0, *P*1, and *P*2. Process *P*0 requires ten tape drives, process *P*1 may need as many as four tape drives, and process *P*2 may need up to nine tape drives. Suppose that, at time *t*0, process *P*0 is holding five tape drives, process *P*1 is holding two tape drives, and process *P*2 is holding two tape drives. (Thus, there are three free tape drives.)

![image](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781118063330/files/images/ch007-f006.jpg)

**Figure 7.6** Safe, unsafe, and deadlocked state spaces.

![image](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781118063330/files/images/p329-001.jpg)

At time *t*0, the system is in a safe state. The sequence <*P*1, *P*0, *P*2> satisfies the safety condition. Process *P*1 can immediately be allocated all its tape drives and then return them (the system will then have five available tape drives); then process *P*0 can get all its tape drives and return them (the system will then have ten available tape drives); and finally process *P*2 can get all its tape drives and return them (the system will then have all twelve tape drives available).

A system can go from a safe state to an unsafe state. Suppose that, at time *t*1, process *P*2 requests and is allocated one more tape drive. The system is no longer in a safe state. At this point, only process *P*1 can be allocated all its tape drives. When it returns them, the system will have only four available tape drives. Since process *P*0 is allocated five tape drives but has a maximum of ten, it may request five more tape drives. If it does so, it will have to wait, because they are unavailable. Similarly, process *P*2 may request six additional tape drives and have to wait, resulting in a deadlock. Our mistake was in granting the request from process *P*2 for one more tape drive. If we had made *P*2 wait until either of the other processes had finished and released its resources, then we could have avoided the deadlock.

Given the concept of a safe state, we can define avoidance algorithms that ensure that the system will never deadlock. The idea is simply to ensure that the system will always remain in a safe state. Initially, the system is in a safe state. Whenever a process requests a resource that is currently available, the system must decide whether the resource can be allocated immediately or whether the process must wait. The request is granted only if the allocation leaves the system in a safe state.

In this scheme, if a process requests a resource that is currently available, it may still have to wait. Thus, resource utilization may be lower than it would otherwise be.

### 7.5.2 Resource-Allocation-Graph Algorithm

If we have a resource-allocation system with only one instance of each resource type, we can use a variant of the resource-allocation graph defined in [Section 7.2.2](https://learning.oreilly.com/library/view/operating-system-concepts/9781118063330/14_chapter07.html#sec7.2.2) for deadlock avoidance. In addition to the request and assignment edges already described, we introduce a new type of edge, called a **claim edge**. A claim edge *Pi* → *Rj* indicates that process *Pi* may request resource *Rj* at some time in the future. This edge resembles a request edge in direction but is represented in the graph by a dashed line. When process *Pi* requests resource *Rj*, the claim edge *Pi* → *Rj* is converted to a request edge. Similarly, when a resource *Rj* is released by *Pi*, the assignment edge *Rj* → *Pi* is reconverted to a claim edge *Pi* → *Rj*.

Note that the resources must be claimed a priori in the system. That is, before process *Pi* starts executing, all its claim edges must already appear in the resource-allocation graph. We can relax this condition by allowing a claim edge *Pi* → *Rj* to be added to the graph only if all the edges associated with process *Pi* are claim edges.

![image](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781118063330/files/images/ch007-f007.jpg)

**Figure 7.7** Resource-allocation graph for deadlock avoidance.

Now suppose that process *Pi* requests resource *Rj*. The request can be granted only if converting the request edge *Pi* → *Rj* to an assignment edge *Rj* → *Pi* does not result in the formation of a cycle in the resource-allocation graph. We check for safety by using a cycle-detection algorithm. An algorithm for detecting a cycle in this graph requires an order of *n*2 operations, where *n* is the number of processes in the system.

If no cycle exists, then the allocation of the resource will leave the system in a safe state. If a cycle is found, then the allocation will put the system in an unsafe state. In that case, process *Pi* will have to wait for its requests to be satisfied.

To illustrate this algorithm, we consider the resource-allocation graph of [Figure 7.7](https://learning.oreilly.com/library/view/operating-system-concepts/9781118063330/14_chapter07.html#fig7.7). Suppose that *P*2 requests *R*2. Although *R*2 is currently free, we cannot allocate it to *P*2, since this action will create a cycle in the graph ([Figure 7.8](https://learning.oreilly.com/library/view/operating-system-concepts/9781118063330/14_chapter07.html#fig7.8)). A cycle, as mentioned, indicates that the system is in an unsafe state. If *P*1 requests *R*2, and *P*2 requests *R*1, then a deadlock will occur.

### 7.5.3 Banker's Algorithm

The resource-allocation-graph algorithm is not applicable to a resource-allocation system with multiple instances of each resource type. The deadlock-avoidance algorithm that we describe next is applicable to such a system but is less efficient than the resource-allocation graph scheme. This algorithm is commonly known as the **banker's algorithm.** The name was chosen because the algorithm could be used in a banking system to ensure that the bank never allocated its available cash in such a way that it could no longer satisfy the needs of all its customers.

![image](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781118063330/files/images/ch007-f008.jpg)

**Figure 7.8** An unsafe state in a resource-allocation graph.

When a new process enters the system, it must declare the maximum number of instances of each resource type that it may need. This number may not exceed the total number of resources in the system. When a user requests a set of resources, the system must determine whether the allocation of these resources will leave the system in a safe state. If it will, the resources are allocated; otherwise, the process must wait until some other process releases enough resources.

Several data structures must be maintained to implement the banker's algorithm. These data structures encode the state of the resource-allocation system. We need the following data structures, where *n* is the number of processes in the system and *m* is the number of resource types:

- **Available**. A vector of length *m* indicates the number of available resources of each type. If ***Available***[*j*] equals *k*, then *k* instances of resource type *Rj* are available.
- **Max**. An *n* × *m* matrix defines the maximum demand of each process. If ***Max***[*i*][*j*] equals *k*, then process *Pi* may request at most *k* instances of resource type *Rj*.
- **Allocation**. An *n* × *m* matrix defines the number of resources of each type currently allocated to each process. If ***Allocation***[*i*][*j*] equals *k*, then process *Pi* is currently allocated *k* instances of resource type *Rj*.
- **Need**. An *n* × *m* matrix indicates the remaining resource need of each process. If ***Need***[*i*][*j*] equals *k*, then process *Pi* may need *k* more instances of resource type *Rj* to complete its task. Note that ***Need***[*i*][*j*] equals ***Max***[*i*][*j*] – ***Allocation***[*i*][*j*].

These data structures vary over time in both size and value.

To simplify the presentation of the banker's algorithm, we next establish some notation. Let *X* and *Y* be vectors of length *n.* We say that *X* ≤ *Y* if and only if *X*[*i*] ≤ *Y*[*i*] for all *i* = 1, 2,…, *n.* For example, if *X* = (1,7,3,2) and *Y* = (0,3,2,1), then *Y* ≤ *X.* In addition, *Y* < *X* if *Y* ≤ *X* and *Y* ≠ *X.*

We can treat each row in the matrices ***Allocation*** and ***Need*** as vectors and refer to them as ***Allocation****i* and ***Need****i****.*** The vector ***Allocation****i* specifies the resources currently allocated to process *Pi*; the vector ***Need****i* specifies the additional resources that process *Pi* may still request to complete its task.

#### 7.5.3.1 Safety Algorithm

We can now present the algorithm for finding out whether or not a system is in a safe state. This algorithm can be described as follows:

1. Let ***Work*** and ***Finish*** be vectors of length *m* and *n*, respectively. Initialize ***Work*** = ***Available*** and ***Finish***[*i*] = ***false*** for *i* = 0, 1,…, *n* − 1.
1. Find an index *i* such that both

1. ***Finish***[*i*] == ***false***
1. ***Need****i* ≤ ***Work***

If no such *i* exists, go to step 4.

1. ***Work*** = ***Work*** + ***Allocation****i*

***Finish***[*i*] = ***true***

Go to step 2.

1. If ***Finish***[*i*] == ***true*** for all *i*, then the system is in a safe state.

This algorithm may require an order of *m* × *n*2 operations to determine whether a state is safe.

#### 7.5.3.2 Resource-Request Algorithm

Next, we describe the algorithm for determining whether requests can be safely granted.

Let ***Request****i* be the request vector for process *Pi*. If ***Request****i* [*j*] == *k*, then process *Pi* wants *k* instances of resource type *Rj*. When a request for resources is made by process *Pi*, the following actions are taken:

1. If ***Request****i* ≤ ***Need****i*, go to step 2. Otherwise, raise an error condition, since the process has exceeded its maximum claim.
1. If ***Request****i* ≤ ***Available*,** go to step 3. Otherwise, *Pi* must wait, since the resources are not available.
1. Have the system pretend to have allocated the requested resources to process *Pi* by modifying the state as follows:

***Available*** = ***Available***−***Request****i*;
***Allocation****i* = ***Allocation****i* + ***Request****i*;
***Need****i* = ***Need****i*−***Request****i*;

If the resulting resource-allocation state is safe, the transaction is completed, and process *Pi* is allocated its resources. However, if the new state is unsafe, then *Pi* must wait for ***Request****i*, and the old resource-allocation state is restored.

#### 7.5.3.3 An Illustrative Example

To illustrate the use of the banker's algorithm, consider a system with five processes *P*0 through *P*4 and three resource types *A, B*, and *C.* Resource type *A* has ten instances, resource type *B* has five instances, and resource type *C* has seven instances. Suppose that, at time *T*0, the following snapshot of the system has been taken:

![image](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781118063330/files/images/p332-001.jpg)

The content of the matrix ***Need*** is defined to be ***Max*** − ***Allocation*** and is as follows:

![image](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781118063330/files/images/p333-001a.jpg)

We claim that the system is currently in a safe state. Indeed, the sequence <*P*1, *P*3, *P*4, *P*2, *P*0> satisfies the safety criteria. Suppose now that process *P*1 requests one additional instance of resource type *A* and two instances of resource type *C*, so *Request*1 = (1,0,2). To decide whether this request can be immediately granted, we first check that *Request*1 ≤ ***Available***—that is, that (1,0,2) ≤ (3,3,2), which is true. We then pretend that this request has been fulfilled, and we arrive at the following new state:

![image](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781118063330/files/images/p333-001.jpg)

We must determine whether this new system state is safe. To do so, we execute our safety algorithm and find that the sequence <*P*1, *P*3, *P*4, *P*0, *P*2> satisfies the safety requirement. Hence, we can immediately grant the request of process *P*1.

You should be able to see, however, that when the system is in this state, a request for (3,3,0) by *P*4 cannot be granted, since the resources are not available. Furthermore, a request for (0,2,0) by *P*0 cannot be granted, even though the resources are available, since the resulting state is unsafe.

We leave it as a programming exercise for students to implement the banker's algorithm.

## 7.6 Deadlock Detection

If a system does not employ either a deadlock-prevention or a deadlock-avoidance algorithm, then a deadlock situation may occur. In this environment, the system may provide:

- An algorithm that examines the state of the system to determine whether a deadlock has occurred
- An algorithm to recover from the deadlock

![image](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781118063330/files/images/ch007-f009.jpg)

**Figure 7.9** (a) Resource-allocation graph. (b) Corresponding wait-for graph.

In the following discussion, we elaborate on these two requirements as they pertain to systems with only a single instance of each resource type, as well as to systems with several instances of each resource type. At this point, however, we note that a detection-and-recovery scheme requires overhead that includes not only the run-time costs of maintaining the necessary information and executing the detection algorithm but also the potential losses inherent in recovering from a deadlock.

### 7.6.1 Single Instance of Each Resource Type

If all resources have only a single instance, then we can define a deadlock-detection algorithm that uses a variant of the resource-allocation graph, called a **wait-for** graph. We obtain this graph from the resource-allocation graph by removing the resource nodes and collapsing the appropriate edges.

More precisely, an edge from *Pi* to *Pj* in a wait-for graph implies that process *Pi* is waiting for process *Pj* to release a resource that *Pi* needs. An edge *Pi* → *Pj* exists in a wait-for graph if and only if the corresponding resource-allocation graph contains two edges *Pi* → *Rq* and *Rq* → *Pj* for some resource *Rq*. In [Figure 7.9](https://learning.oreilly.com/library/view/operating-system-concepts/9781118063330/14_chapter07.html#fig7.9), we present a resource-allocation graph and the corresponding wait-for graph.

As before, a deadlock exists in the system if and only if the wait-for graph contains a cycle. To detect deadlocks, the system needs to ***maintain*** the wait-for graph and periodically ***invoke an algorithm*** that searches for a cycle in the graph. An algorithm to detect a cycle in a graph requires an order of *n*2 operations, where *n* is the number of vertices in the graph.

### 7.6.2 Several Instances of a Resource Type

The wait-for graph scheme is not applicable to a resource-allocation system with multiple instances of each resource type. We turn now to a deadlock-detection algorithm that is applicable to such a system. The algorithm employs several time-varying data structures that are similar to those used in the banker's algorithm ([Section 7.5.3](https://learning.oreilly.com/library/view/operating-system-concepts/9781118063330/14_chapter07.html#sec7.5.3)):

- **Available**. A vector of length *m* indicates the number of available resources of each type.
- **Allocation**. An *n* × *m* matrix defines the number of resources of each type currently allocated to each process.
- **Request**. An *n* × *m* matrix indicates the current request of each process. If ***Request***[*i*][*j*] equals *k*, then process *Pi* is requesting *k* more instances of resource type *Rj*.

The ≤ relation between two vectors is defined as in [Section 7.5.3](https://learning.oreilly.com/library/view/operating-system-concepts/9781118063330/14_chapter07.html#sec7.5.3). To simplify notation, we again treat the rows in the matrices ***Allocation*** and ***Request*** as vectors; we refer to them as ***Allocation****i* and ***Request****i****.*** The detection algorithm described here simply investigates every possible allocation sequence for the processes that remain to be completed. Compare this algorithm with the banker's algorithm of [Section 7.5.3](https://learning.oreilly.com/library/view/operating-system-concepts/9781118063330/14_chapter07.html#sec7.5.3).

1. Let ***Work*** and ***Finish*** be vectors of length *m* and *n*, respectively. Initialize ***Work*** = ***Available.*** For *i* = 0, 1,…, *n−1*, if ***Allocation****i* ≠ 0, then ***Finish***[*i*] = ***false.*** Otherwise, ***Finish***[*i*] = ***true.***
1. Find an index *i* such that both

1. ***Finish***[*i*] == ***false***
1. ***Request****i* ≤ ***Work***

If no such *i* exists, go to step 4.

1. ***Work*** = ***Work*** + ***Allocation****i*
***Finish***[*i*] = ***true***
Go to step 2.

1. If ***Finish***[*i*] == ***false*** for some *i*, 0 ≤ *i* < *n*, then the system is in a deadlocked state. Moreover, if ***Finish***[*i*] == ***false*,** then process *Pi* is deadlocked.

This algorithm requires an order of *m* × *n*2 operations to detect whether the system is in a deadlocked state.

You may wonder why we reclaim the resources of process *Pi* (in step 3) as soon as we determine that ***Request****i* ≤ ***Work*** (in step 2b). We know that *Pi* is currently ***not*** involved in a deadlock (since ***Request****i* ≤ ***Work***). Thus, we take an optimistic attitude and assume that *Pi* will require no more resources to complete its task; it will thus soon return all currently allocated resources to the system. If our assumption is incorrect, a deadlock may occur later. That deadlock will be detected the next time the deadlock-detection algorithm is invoked.

To illustrate this algorithm, we consider a system with five processes *P*0 through *P*4 and three resource types *A, B*, and *C.* Resource type *A* has seven instances, resource type *B* has two instances, and resource type *C* has six instances. Suppose that, at time *T*0, we have the following resource-allocation state:

![image](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781118063330/files/images/p336-001.jpg)

We claim that the system is not in a deadlocked state. Indeed, if we execute our algorithm, we will find that the sequence <*P*0, *P*2, *P*3, *P*1, *P*4> results in ***Finish***[*i*] == *true* for all *i.*

Suppose now that process *P*2 makes one additional request for an instance of type *C.* The ***Request*** matrix is modified as follows:

![image](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781118063330/files/images/p336-001a.jpg)

We claim that the system is now deadlocked. Although we can reclaim the resources held by process *P*0, the number of available resources is not sufficient to fulfill the requests of the other processes. Thus, a deadlock exists, consisting of processes *P*1, *P*2, *P*3, and *P*4.

### 7.6.3 Detection-Algorithm Usage

When should we invoke the detection algorithm? The answer depends on two factors:

1. How ***often*** is a deadlock likely to occur?
1. How ***many*** processes will be affected by deadlock when it happens?

If deadlocks occur frequently, then the detection algorithm should be invoked frequently. Resources allocated to deadlocked processes will be idle until the deadlock can be broken. In addition, the number of processes involved in the deadlock cycle may grow.

Deadlocks occur only when some process makes a request that cannot be granted immediately. This request may be the final request that completes a chain of waiting processes. In the extreme, then, we can invoke the deadlock-detection algorithm every time a request for allocation cannot be granted immediately. In this case, we can identify not only the deadlocked set of processes but also the specific process that “caused” the deadlock. (In reality, each of the deadlocked processes is a link in the cycle in the resource graph, so all of them, jointly, caused the deadlock.) If there are many different resource types, one request may create many cycles in the resource graph, each cycle completed by the most recent request and “caused” by the one identifiable process.

Of course, invoking the deadlock-detection algorithm for every resource request will incur considerable overhead in computation time. A less expensive alternative is simply to invoke the algorithm at defined intervals—for example, once per hour or whenever CPU utilization drops below 40 percent. (A deadlock eventually cripples system throughput and causes CPU utilization to drop.) If the detection algorithm is invoked at arbitrary points in time, the resource graph may contain many cycles. In this case, we generally cannot tell which of the many deadlocked processes “caused” the deadlock.

## 7.7 Recovery from Deadlock

When a detection algorithm determines that a deadlock exists, several alternatives are available. One possibility is to inform the operator that a deadlock has occurred and to let the operator deal with the deadlock manually. Another possibility is to let the system **recover** from the deadlock automatically. There are two options for breaking a deadlock. One is simply to abort one or more processes to break the circular wait. The other is to preempt some resources from one or more of the deadlocked processes.

### 7.7.1 Process Termination

To eliminate deadlocks by aborting a process, we use one of two methods. In both methods, the system reclaims all resources allocated to the terminated processes.

- **Abort all deadlocked processes**. This method clearly will break the deadlock cycle, but at great expense. The deadlocked processes may have computed for a long time, and the results of these partial computations must be discarded and probably will have to be recomputed later.
- **Abort one process at a time until the deadlock cycle is eliminated**. This method incurs considerable overhead, since after each process is aborted, a deadlock-detection algorithm must be invoked to determine whether any processes are still deadlocked.

Aborting a process may not be easy. If the process was in the midst of updating a file, terminating it will leave that file in an incorrect state. Similarly, if the process was in the midst of printing data on a printer, the system must reset the printer to a correct state before printing the next job.

If the partial termination method is used, then we must determine which deadlocked process (or processes) should be terminated. This determination is a policy decision, similar to CPU-scheduling decisions. The question is basically an economic one; we should abort those processes whose termination will incur the minimum cost. Unfortunately, the term ***minimum cost*** is not a precise one. Many factors may affect which process is chosen, including:

1. What the priority of the process is
1. How long the process has computed and how much longer the process will compute before completing its designated task
1. How many and what types of resources the process has used (for example, whether the resources are simple to preempt)
1. How many more resources the process needs in order to complete
1. How many processes will need to be terminated
1. Whether the process is interactive or batch

### 7.7.2 Resource Preemption

To eliminate deadlocks using resource preemption, we successively preempt some resources from processes and give these resources to other processes until the deadlock cycle is broken.

If preemption is required to deal with deadlocks, then three issues need to be addressed:

1. **Selecting a victim**. Which resources and which processes are to be preempted? As in process termination, we must determine the order of preemption to minimize cost. Cost factors may include such parameters as the number of resources a deadlocked process is holding and the amount of time the process has thus far consumed.
1. **Rollback**. If we preempt a resource from a process, what should be done with that process? Clearly, it cannot continue with its normal execution; it is missing some needed resource. We must roll back the process to some safe state and restart it from that state.

Since, in general, it is difficult to determine what a safe state is, the simplest solution is a total rollback: abort the process and then restart it. Although it is more effective to roll back the process only as far as necessary to break the deadlock, this method requires the system to keep more information about the state of all running processes.

1. **Starvation**. How do we ensure that starvation will not occur? That is, how can we guarantee that resources will not always be preempted from the same process?

In a system where victim selection is based primarily on cost factors, it may happen that the same process is always picked as a victim. As a result, this process never completes its designated task, a starvation situation any practical system must address. Clearly, we must ensure that a process can be picked as a victim only a (small) finite number of times. The most common solution is to include the number of rollbacks in the cost factor.

## 7.8 Summary

A deadlocked state occurs when two or more processes are waiting indefinitely for an event that can be caused only by one of the waiting processes. There are three principal methods for dealing with deadlocks:

- Use some protocol to prevent or avoid deadlocks, ensuring that the system will never enter a deadlocked state.
- Allow the system to enter a deadlocked state, detect it, and then recover.
- Ignore the problem altogether and pretend that deadlocks never occur in the system.

The third solution is the one used by most operating systems, including Linux and Windows.

A deadlock can occur only if four necessary conditions hold simultaneously in the system: mutual exclusion, hold and wait, no preemption, and circular wait. To prevent deadlocks, we can ensure that at least one of the necessary conditions never holds.

A method for avoiding deadlocks, rather than preventing them, requires that the operating system have a priori information about how each process will utilize system resources. The banker's algorithm, for example, requires a priori information about the maximum number of each resource class that each process may request. Using this information, we can define a deadlock-avoidance algorithm.

If a system does not employ a protocol to ensure that deadlocks will never occur, then a detection-and-recovery scheme may be employed. A deadlock-detection algorithm must be invoked to determine whether a deadlock has occurred. If a deadlock is detected, the system must recover either by terminating some of the deadlocked processes or by preempting resources from some of the deadlocked processes.

Where preemption is used to deal with deadlocks, three issues must be addressed: selecting a victim, rollback, and starvation. In a system that selects victims for rollback primarily on the basis of cost factors, starvation may occur, and the selected process can never complete its designated task.

Researchers have argued that none of the basic approaches alone is appropriate for the entire spectrum of resource-allocation problems in operating systems. The basic approaches can be combined, however, allowing us to select an optimal approach for each class of resources in a system.

## Practice Exercises

**7.1**   List three examples of deadlocks that are not related to a computer-system environment.

**7.2**   Suppose that a system is in an unsafe state. Show that it is possible for the processes to complete their execution without entering a deadlocked state.

**7.3**   Consider the following snapshot of a system:

![image](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781118063330/files/images/p340-001.jpg)

Answer the following questions using the banker's algorithm:

1. What is the content of the matrix ***Need***?
1. Is the system in a safe state?
1. If a request from process *P*1 arrives for (0,4,2,0), can the request be granted immediately?

**7.4**   A possible method for preventing deadlocks is to have a single, higher-order resource that must be requested before any other resource. For example, if multiple threads attempt to access the synchronization objects *A* · · · *E*, deadlock is possible. (Such synchronization objects may include mutexes, semaphores, condition variables, and the like.) We can prevent the deadlock by adding a sixth object *F*. Whenever a thread wants to acquire the synchronization lock for any object *A* · · · *E*, it must first acquire the lock for object *F*. This solution is known as **containment**: the locks for objects *A* · · · *E* are contained within the lock for object *F*. Compare this scheme with the circular-wait scheme of [Section 7.4.4](https://learning.oreilly.com/library/view/operating-system-concepts/9781118063330/14_chapter07.html#sec7.4.4).

**7.5**   Prove that the safety algorithm presented in [Section 7.5.3](https://learning.oreilly.com/library/view/operating-system-concepts/9781118063330/14_chapter07.html#sec7.5.3) requires an order of *m* × *n*2 operations.

**7.6**   Consider a computer system that runs 5,000 jobs per month and has no deadlock-prevention or deadlock-avoidance scheme. Deadlocks occur about twice per month, and the operator must terminate and rerun about ten jobs per deadlock. Each job is worth about two dollars (in CPU time), and the jobs terminated tend to be about half done when they are aborted.

A systems programmer has estimated that a deadlock-avoidance algorithm (like the banker's algorithm) could be installed in the system with an increase of about 10 percent in the average execution time per job. Since the machine currently has 30 percent idle time, all 5,000 jobs per month could still be run, although turnaround time would increase by about 20 percent on average.

1. What are the arguments for installing the deadlock-avoidance algorithm?
1. What are the arguments against installing the deadlock-avoidance algorithm?

**7.7**   Can a system detect that some of its processes are starving? If you answer “yes,” explain how it can. If you answer “no,” explain how the system can deal with the starvation problem.

**7.8**   Consider the following resource-allocation policy. Requests for and releases of resources are allowed at any time. If a request for resources cannot be satisfied because the resources are not available, then we check any processes that are blocked waiting for resources. If a blocked process has the desired resources, then these resources are taken away from it and are given to the requesting process. The vector of resources for which the blocked process is waiting is increased to include the resources that were taken away.

For example, a system has three resource types, and the vector ***Available*** is initialized to (4,2,2). If process *P*0 asks for (2,2,1), it gets them. If *P*1 asks for (1,0,1), it gets them. Then, if *P*0 asks for (0,0,1), it is blocked (resource not available). If *P*2 now asks for (2,0,0), it gets the available one (1,0,0), as well as one that was allocated to *P*0 (since *P*0 is blocked). *P*0's ***Allocation*** vector goes down to (1,2,1), and its ***Need*** vector goes up to (1,0,1).

1. Can deadlock occur? If you answer “yes,” give an example. If you answer “no,” specify which necessary condition cannot occur.
1. Can indefinite blocking occur? Explain your answer.

**7.9**   Suppose that you have coded the deadlock-avoidance safety algorithm and now have been asked to implement the deadlock-detection algorithm. Can you do so by simply using the safety algorithm code and redefining ***Max****i* = ***Waiting****i* + ***Allocation****i*, where ***Waiting****i* is a vector specifying the resources for which process *i* is waiting and ***Allocation****i* is as defined in [Section 7.5](https://learning.oreilly.com/library/view/operating-system-concepts/9781118063330/14_chapter07.html#sec7.5)? Explain your answer.

**7.10** Is it possible to have a deadlock involving only one single-threaded process? Explain your answer.

### Exercises

**7.11** Consider the traffic deadlock depicted in [Figure 7.10](https://learning.oreilly.com/library/view/operating-system-concepts/9781118063330/14_chapter07.html#fig7.10).

1. Show that the four necessary conditions for deadlock hold in this example.
1. State a simple rule for avoiding deadlocks in this system.

**7.12** Assume a multithreaded application uses only reader–writer locks for synchronization. Applying the four necessary conditions for deadlock, is deadlock still possible if multiple reader–writer locks are used?

**7.13** The program example shown in [Figure 7.4](https://learning.oreilly.com/library/view/operating-system-concepts/9781118063330/14_chapter07.html#fig7.4) doesn't always lead to deadlock. Describe what role the CPU scheduler plays and how it can contribute to deadlock in this program.

![image](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781118063330/files/images/ch007-f010.jpg)

**Figure 7.10** Traffic deadlock for Exercise 7.11.

**7.14** In [Section 7.4.4](https://learning.oreilly.com/library/view/operating-system-concepts/9781118063330/14_chapter07.html#sec7.4.4), we describe a situation in which we prevent deadlock by ensuring that all locks are acquired in a certain order. However, we also point out that deadlock is possible in this situation if two threads simultaneously invoke the transaction() function. Fix the transaction() function to prevent deadlocks.

**7.15** Compare the circular-wait scheme with the various deadlock-avoidance schemes (like the banker's algorithm) with respect to the following issues:

1. Runtime overheads
1. System throughput

**7.16** In a real computer system, neither the resources available nor the demands of processes for resources are consistent over long periods (months). Resources break or are replaced, new processes come and go, and new resources are bought and added to the system. If deadlock is controlled by the banker's algorithm, which of the following changes can be made safely (without introducing the possibility of deadlock), and under what circumstances?

1. Increase ***Available*** (new resources added).
1. Decrease ***Available*** (resource permanently removed from system).
1. Increase ***Max*** for one process (the process needs or wants more resources than allowed).
1. Decrease ***Max*** for one process (the process decides it does not need that many resources).
1. Increase the number of processes.
1. Decrease the number of processes.

**7.17** Consider a system consisting of four resources of the same type that are shared by three processes, each of which needs at most two resources. Show that the system is deadlock free.

**7.18** Consider a system consisting of *m* resources of the same type being shared by *n* processes. A process can request or release only one resource at a time. Show that the system is deadlock free if the following two conditions hold:

1. The maximum need of each process is between one resource and *m* resources.
1. The sum of all maximum needs is less than *m* + *n.*

**7.19** Consider the version of the dining-philosophers problem in which the chopsticks are placed at the center of the table and any two of them can be used by a philosopher. Assume that requests for chopsticks are made one at a time. Describe a simple rule for determining whether a particular request can be satisfied without causing deadlock given the current allocation of chopsticks to philosophers.

**7.20** Consider again the setting in the preceding question. Assume now that each philosopher requires three chopsticks to eat. Resource requests are still issued one at a time. Describe some simple rules for determining whether a particular request can be satisfied without causing deadlock given the current allocation of chopsticks to philosophers.

**7.21** We can obtain the banker's algorithm for a single resource type from the general banker's algorithm simply by reducing the dimensionality of the various arrays by 1. Show through an example that we cannot implement the multiple-resource-type banker's scheme by applying the single-resource-type scheme to each resource type individually.

**7.22** Consider the following snapshot of a system:

![image](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781118063330/files/images/p343-001.jpg)

Using the banker's algorithm, determine whether or not each of the following states is unsafe. If the state is safe, illustrate the order in which the processes may complete. Otherwise, illustrate why the state is unsafe.

1. ***Available*** = (0, 3, 0, 1)
1. ***Available*** = (1, 0, 0, 2)

**7.23** Consider the following snapshot of a system:

![image](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781118063330/files/images/p344-001.jpg)

Answer the following questions using the banker's algorithm:

1. Illustrate that the system is in a safe state by demonstrating an order in which the processes may complete.
1. If a request from process *P*1 arrives for (1, 1, 0, 0), can the request be granted immediately?
1. If a request from process *P*4 arrives for (0, 0, 2, 0), can the request be granted immediately?

**7.24** What is the optimistic assumption made in the deadlock-detection algorithm? How can this assumption be violated?

**7.25** A single-lane bridge connects the two Vermont villages of North Tunbridge and South Tunbridge. Farmers in the two villages use this bridge to deliver their produce to the neighboring town. The bridge can become deadlocked if a northbound and a southbound farmer get on the bridge at the same time. (Vermont farmers are stubborn and are unable to back up.) Using semaphores and/or mutex locks, design an algorithm in pseudocode that prevents deadlock. Initially, do not be concerned about starvation (the situation in which northbound farmers prevent southbound farmers from using the bridge, or vice versa).

**7.26** Modify your solution to Exercise 7.25 so that it is starvation-free.

## Programming Problems

**7.27** Implement your solution to Exercise 7.25 using POSIX synchronization. In particular, represent northbound and southbound farmers as separate threads. Once a farmer is on the bridge, the associated thread will sleep for a random period of time, representing traveling across the bridge. Design your program so that you can create several threads representing the northbound and southbound farmers.

## Programming Projects

Banker's Algorithm

For this project, you will write a multithreaded program that implements the banker's algorithm discussed in [Section 7.5.3](https://learning.oreilly.com/library/view/operating-system-concepts/9781118063330/14_chapter07.html#sec7.5.3). Several customers request and release resources from the bank. The banker will grant a request only if it leaves the system in a safe state. A request that leaves the system in an unsafe state will be denied. This programming assignment combines three separate topics: (1) multithreading, (2) preventing race conditions, and (3) deadlock avoidance.

The Banker

The banker will consider requests from *n* customers for *m* resources types. as outlined in [Section 7.5.3](https://learning.oreilly.com/library/view/operating-system-concepts/9781118063330/14_chapter07.html#sec7.5.3). The banker will keep track of the resources using the following data structures:

```
/* these may be any values >= 0 */
#define NUMBER_OF_CUSTOMERS 5
#define NUMBER_OF_RESOURCES 3

/* the available amount of each resource */
int available[NUMBER_OF_RESOURCES];

/*the maximum demand of each customer */
int maximum[NUMBER_OF_CUSTOMERS][NUMBER_OF_RESOURCES];

/* the amount currently allocated to each customer */
int allocation[NUMBER_OF_CUSTOMERS][NUMBER_OF_RESOURCES];

/* the remaining need of each customer */
int need[NUMBER_OF_CUSTOMERS][NUMBER_OF_RESOURCES];
```

The Customers

Create *n* customer threads that request and release resources from the bank. The customers will continually loop, requesting and then releasing random numbers of resources. The customers' requests for resources will be bounded by their respective values in the need array. The banker will grant a request if it satisfies the safety algorithm outlined in [Section 7.5.3.1](https://learning.oreilly.com/library/view/operating-system-concepts/9781118063330/14_chapter07.html#sec7.5.3.1). If a request does not leave the system in a safe state, the banker will deny it. Function prototypes for requesting and releasing resources are as follows:

```
int request_resources(int customer_num, int request[]);

int release_resources(int customer_num, int release[]);
```

These two functions should return 0 if successful (the request has been granted) and −1 if unsuccessful. Multiple threads (customers)will concurrently access shared data through these two functions. Therefore, access must be controlled through mutex locks to prevent race conditions. Both the Pthreads and Windows APIs provide mutex locks. The use of Pthreads mutex locks is covered in [Section 5.9.4](https://learning.oreilly.com/library/view/operating-system-concepts/9781118063330/12_chapter05.html#sec5.9.4); mutex locks for Windows systems are described in the project entitled “Producer–Consumer Problem” at the end of [Chapter 5](https://learning.oreilly.com/library/view/operating-system-concepts/9781118063330/12_chapter05.html#chap5).

Implementation

You should invoke your program by passing the number of resources of each type on the command line. For example, if there were three resource types, with ten instances of the first type, five of the second type, and seven of the third type, you would invoke your program follows:

```
./a.out 10 5 7
```

The available array would be initialized to these values. You may initialize the maximum array (which holds the maximum demand of each customer) using any method you find convenient.

### Bibliographical Notes

Most research involving deadlock was conducted many years ago. [Dijkstra (1965)] was one of the first and most influential contributors in the deadlock area. [Holt (1972)] was the first person to formalize the notion of deadlocks in terms of an allocation-graph model similar to the one presented in this chapter. Starvation was also covered by [Holt (1972)]. [Hyman (1985)] provided the deadlock example from the Kansas legislature. A study of deadlock handling is provided in [Levine (2003)].

The various prevention algorithms were suggested by [Havender (1968)], who devised the resource-ordering scheme for the IBM OS/360 system. The banker's algorithm for avoiding deadlocks was developed for a single resource type by [Dijkstra (1965)] and was extended to multiple resource types by [Habermann (1969)].

The deadlock-detection algorithm for multiple instances of a resource type, which is described in [Section 7.6.2](https://learning.oreilly.com/library/view/operating-system-concepts/9781118063330/14_chapter07.html#sec7.6.2), was presented by [Coffman et al. (1971)].

[Bach (1987)] describes how many of the algorithms in the traditional UNIX kernel handle deadlock. Solutions to deadlock problems in networks are discussed in works such as [Culler et al. (1998)] and [Rodeheffer and Schroeder (1991)].

The witness lock-order verifier is presented in [Baldwin (2002)].

## Bibliography

**[Bach (1987)]** M. J. Bach, *The Design of the UNIX Operating System*, Prentice Hall (1987).

**[Baldwin (2002)]** J. Baldwin, “Locking in the Multithreaded FreeBSD Kernel”, *USENIX BSD* (2002).

**[Coffman et al. (1971)]** E. G. Coffman, M. J. Elphick, and A. Shoshani, “System Deadlocks”, *Computing Surveys*, Volume 3, Number 2 (1971), pages 67–78.

**[Culler et al. (1998)]** D. E. Culler, J. P. Singh, and A. Gupta, *Parallel Computer Architecture: A Hardware/Software Approach*, Morgan Kaufmann Publishers Inc. (1998).

**[Dijkstra (1965)]** E. W. Dijkstra, “Cooperating Sequential Processes”, Technical report, Technological University, Eindhoven, the Netherlands (1965).

**[Habermann (1969)]** A. N. Habermann, “Prevention of System Deadlocks”, *Communications of the ACM*, Volume 12, Number 7 (1969), pages 373–377, 385.

**[Havender (1968)]** J. W. Havender, “Avoiding Deadlock in Multitasking Systems”, *IBM Systems Journal*, Volume 7, Number 2 (1968), pages 74–84.

**[Holt (1972)]** R. C. Holt, “Some Deadlock Properties of Computer Systems”, *Computing Surveys*, Volume 4, Number 3 (1972), pages 179–196.

**[Hyman (1985)]** D. Hyman, *The Columbus Chicken Statute and More Bonehead Legislation*, S. Greene Press (1985).

**[Levine (2003)]** G. Levine, “Defining Deadlock”, *Operating Systems Review*, Volume 37, Number 1 (2003).

**[Rodeheffer and Schroeder (1991)]** T. L. Rodeheffer and M. D. Schroeder, “Automatic Reconfiguration in Autonet”, *Proceedings of the ACM Symposium on Operating Systems Principles* (1991), pages 183–97.

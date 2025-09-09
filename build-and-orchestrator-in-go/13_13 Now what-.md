# [](/book/build-an-orchestrator-in-go-from-scratch/chapter-13/)13 Now what?

### This chapter covers

- Reviewing what we’ve accomplished
- Where to go next

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-13/)Chapter 12 concluded our work to build the Cube orchestrator. Let’s review what we’ve accomplished:

1.  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-13/)We designed and implemented the worker component.
1.  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-13/)We designed and implemented the manager component.
1.  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-13/)We created a `Storage` interface that allowed us to implement in-memory and persistent data stores for storing tasks and events. This interface is then used by both the worker and manager components. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-13/)
1.  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-13/)We built a `Scheduler` interface and then refactored our original round-robin implementation to adhere to this interface. We also wrote a more sophisticated scheduler, called E-PVM. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-13/)
1.  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-13/)Finally, we replaced our crude `main.go` program with a proper command-line interface (CLI). This CLI allowed us to run the worker and manager components independently, even on different machines. The CLI also provides us with the ability to perform management operations: we can start and stop tasks, query the state of tasks, and get an overview of the state of each node in the orchestration system. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-13/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-13/)While this is all “neat,” so what? What can we do with the knowledge that we’ve gained? Well, a theoretical answer to these questions would be that we can write a new production-quality orchestrator, something to compete with or replace the likes of Kubernetes or Nomad. Personally, I find this answer unrealistic. Kubernetes has a strong foothold in the industry, and Nomad is a reasonable alternative if, for some reason, you or your company doesn’t want to use Kubernetes. There are, however, more practical answers.

## [](/book/build-an-orchestrator-in-go-from-scratch/chapter-13/)13.1 Working on Kubernetes and related tooling

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-13/)While you may not write your own general-purpose orchestrator, you could contribute to Kubernetes. Remember, the Kubernetes project is open source, and it’s also written in Go. As of this writing, there have been more than 3,500 contributors to its codebase. Similarly, maybe you’re interested in contributing to the K3s project. Packaged as a single binary, K3s advertises itself as a lightweight version of Kubernetes targeted to edge, IoT, development, and other smaller types of deployments (i.e., those that are not “web scale”). K3s is also written in Go.

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-13/)Or maybe you want to work on tools for Kubernetes or Nomad. With your knowledge of how orchestration systems work, you could contribute to projects like K9s ([https://github.com/derailed/k9s](https://github.com/derailed/k9s)) or Wander ([https://github.com/robinovitch61/wander](https://github.com/robinovitch61/wander)). Both K9s and Wander provide terminal UIs (or TUIs) for managing and working with Kubernetes (K9s) and Nomad (Wander) clusters.

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-13/)Why would you want to contribute to any of these projects? What would you get out of it? Perhaps you have a need that these projects don’t currently meet. By contributing to the project, you can have your individual need satisfied as well as help others who might also find your contribution useful. Or perhaps you simply want to contribute to an open source project. There is satisfaction in seeing your name listed as one of the contributors on a project’s repo.

## [](/book/build-an-orchestrator-in-go-from-scratch/chapter-13/)13.2 Manager-worker pattern and workflow systems

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-13/)Kubernetes and Nomad are examples of general-purpose orchestration systems, and they make use of what is sometimes called the manager-worker pattern. As we saw in our implementation of the Cube orchestrator, the manager-worker pattern has a `manager` component that manages a pool of `workers` for the purpose of running `tasks`. In the case of Cube (and Kubernetes and Nomad), those tasks just happen to be applications that can be used to build complex distributed systems. There are, however, other types of systems that also use this manager-worker pattern. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-13/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-13/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-13/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-13/)One of these other types of systems is the workflow system. A workflow system provides a programmatic way for users to define and run a sequence of tasks. While this sounds similar to an orchestration system, workflow systems are more specialized, focusing on automating the steps in a well-defined process. One popular workflow system is Apache Airflow ([https://github.com/apache/airflow](https://github.com/apache/airflow)).

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-13/)If you work on a DevOps or site reliability engineering (SRE) team, you are likely already using one or more workflow systems. Your team may be responsible for managing many services that provide the infrastructure to your development teams, who are writing code for user-facing products. The infrastructure services may be things like databases, virtual machines, Kubernetes or Nomad clusters, build tools, and more. All of these services have processes for managing them. And those processes almost certainly are broken down into discrete steps that can be automated. So one option to help you automate the management of these services could be to write your own special-purpose workflow system. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-13/)

## [](/book/build-an-orchestrator-in-go-from-scratch/chapter-13/)13.3 Manager-worker pattern and integration systems

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-13/)There are other places where knowledge of the manager-worker pattern can be used. For example, on my current team, we realized that the original version of our integration service was brittle and difficult to extend to meet the company’s needs as we looked into the near future. This integration service is pretty straightforward: it needs to ingest data from IoT devices, apply some transformations to that data, and then forward the data on to other destinations (databases, monitoring systems, financial systems, etc.). Our original implementation supported only a few hard-coded transformations. Moreover, we built it into our monolithic backend system and did not provide any reasonable means for scaling it over time. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-13/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-13/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-13/)Thus, we started down the path of designing a new integration service. While working on the design for this new service, I realized that what I was describing was, in fact, a service that could use the manager-worker pattern. Instead of tasks, as in a general-purpose orchestration system, the subject of our integration system was workflows. We have a worker component that is responsible for performing the individual steps of each workflow. And we have a manager component that is responsible for administrative tasks, like creating, updating, and deleting workflows in the system, as well as dispatching incoming requests from devices to individual workers.

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-13/)With this new design, we have much more flexibility in how we operate our integration system. We can run it inside our existing monolith, choosing to rip out the original integration service and replace it with this new one. We can run it as a separate microservice with all of the components running in a single process on a single machine (great for development purposes). Or we can run individual components of the system as separate processes, either on a single or separate machines. This is great for production and allows us to scale as necessary. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-13/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-13/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-13/)

## [](/book/build-an-orchestrator-in-go-from-scratch/chapter-13/)13.4 In closing

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-13/)The previous examples are just a few ways in which you can take the knowledge you’ve gained from this book and apply it in real-world situations. Thus, the time you spent writing the Cube orchestrator was not simply an academic exercise.

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-13/)At the end of the day, I hope you also had fun!

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-13/)Here is a review of what we have covered:

-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-13/)To organize code into Go types based on a mental model, see chapter 2.
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-13/)To use the Docker API to start and stop containers, see chapter 3.
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-13/)To manage the state of tasks over the course of their lifetime, see chapter 4.
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-13/)To write an HTTP API using the `chi` router, see chapters 5 and 8.
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-13/)To schedule tasks onto a pool of workers, see chapters 7 and 10.
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-13/)To store tasks in a key-value datastore using the BoltDB library, see chapter 11.
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-13/)To write a command-line application using the Cobra library, see chapter 12. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-13/)

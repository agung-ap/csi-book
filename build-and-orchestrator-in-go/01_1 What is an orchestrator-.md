# [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)1 What is an orchestrator?

### This chapter covers

- The evolution of application deployments
- Classifying the components of an orchestration system
- Introducing the mental model for the orchestrator
- Defining requirements for our orchestrator
- Identifying the scope of our work

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)*Kubernetes*. *Kubernetes*. *Kubernetes*. If you’ve worked in or near the tech industry in the last five years, you’ve at least heard the name. Perhaps you’ve used it in your day job. Or perhaps you’ve used other systems such as Apache Mesos or HashiCorp’s Nomad.

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)In this book, we’re going to build our own Kubernetes, writing the code ourselves to gain a better understanding of just what Kubernetes is. And what Kubernetes is—like Mesos and Nomad—is an orchestrator.

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)When you’ve finished the book, you will have learned the following:

-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)What components form the foundation of any orchestration system
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)How those components interact
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)How each component maintains its own state and why
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)What tradeoffs are made in designing and implementing an orchestration system

## [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)1.1 Why implement an orchestrator from scratch?

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)Why bother writing an orchestrator from scratch? No, the answer is not to write a system that will replace Kubernetes, Mesos, or Nomad. The answer is more practical than that. If you’re like me, you learn by doing. Learning by doing is easy when we’re dealing with small things. How do I write a `for` loop in this new programming language I’m learning? How do I use the `curl` command to make a request to this new API I want to use? These things are easy to learn by doing them because they are small in scope and don’t require too much effort. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)When we want to learn larger systems, however, learning by doing becomes challenging. The obvious way to tackle this situation is to read the source code. The code for Kubernetes, Mesos, and Nomad is available on GitHub. So if the source code is available, why write an orchestrator from scratch? Couldn’t we just look at the source code for them and get the same benefit?

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)Perhaps. Keep in mind, though, that these are large software projects. Kubernetes contains more than 2 million lines of source code. Mesos and Nomad clock in at just over 700,000 lines of code. While not impossible, learning a system by slogging around in codebases of this size may not be the best way.

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)Instead, we’re going to roll up our sleeves and get our hands dirty. We’ll implement our orchestrator in less than 3,000 lines of code.

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)To ensure we focus on the core bits of an orchestrator and don’t get sidetracked, we are going to narrow the scope of our implementation. The orchestrator you write in the course of this project will be fully functional. You will be able to start and stop tasks and interact with those tasks.

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)It will not, however, be production ready. After all, our purpose is not to implement a system that will replace Kubernetes, Nomad, or Mesos. Instead, our purpose is to implement a minimal system that gives us deeper insight into how production-grade systems like Kubernetes and Nomad work.

## [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)1.2 The (not so) good ol’ days

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)Let’s take a journey back to 2002 and meet Michelle. Michelle is a system administrator for her company, and she is responsible for keeping her company’s applications up and running around the clock. How does she accomplish this?[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)Like many other sysadmins, Michelle employs the common strategy of deploying applications on bare metal servers. A simplistic sketch of Michelle’s world can be seen in figure 1.1. Each application typically runs on its own physical hardware. To make matters more complicated, each application has its own hardware requirements, so Michelle has to buy and then manage a server fleet that is unique to each application. Moreover, each application has its own unique deployment process and tooling. The database team gets new versions and updates in the mail via compact disk, so its process involves a database administrator (DBA) copying files from the CD to a central server and then using a set of custom shell scripts to push the files to the database servers, where another set of shell scripts handles installation and updates. Michelle handles the installation and updates of the company’s financial system herself. This process involves downloading the software from the internet, at least saving her the hassle of dealing with CDs. But the financial software comes with its own set of tools for installing and managing updates. Several other teams are building the company’s software product, and the applications these teams build have a completely different set of tools and procedures. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)

![Figure 1.1 This diagram represents Michelle’s world in 2002. The outer box represents physical machines and the operating systems running on them. The inner box represents the applications running on the machines and demonstrates how applications used to be more directly tied to both operating systems and machines.](https://drek4537l1klr.cloudfront.net/boring/Figures/01-01.png)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)If you weren’t working in the industry during this time and didn’t experience anything like Michelle’s world, consider yourself lucky. Not only was that world chaotic and difficult to manage, it was also extremely wasteful. Virtualization came along next in the early to mid-2000s. These tools allowed sysadmins like Michelle to carve up their physical fleets so that each physical machine hosted several smaller yet independent virtual machines (VMs). Instead of each application running on its own dedicated physical machine, it now ran on a VM. And multiple VMs could be packed onto a single physical one. While virtualization made life for folks like Michelle better, it wasn’t a silver bullet. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)This was the way of things until the mid-2010s when two new technologies appeared on the horizon. The first was Docker, which introduced *containers* to the wider world. The concept of containers was not new. It had been around since 1979 (see Ell Marquez’s “The History of Container Technology” at [http://mng.bz/oro2](http://mng.bz/oro2)). Before Docker, containers were mostly confined to large companies, like Sun Microsystems and Google, and hosting providers looking for ways to efficiently and securely provide virtualized environments for their customers. The second new technology to appear at this time was Kubernetes, a container *orchestrator* focused on automating the deployment and management of containers. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)

## [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)1.3 What is a container, and how is it different from a virtual machine?

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)As mentioned earlier, the first step in moving from Michelle’s early world of physical machines and operating systems was the introduction of *virtual machines*. Virtual machines, or VMs, abstracted a computer’s physical components (CPU, memory, disk, network, CD-Rom, etc.) so administrators could run multiple operating systems on a single physical machine. Each operating system running on the physical machine was distinct. Each had its own kernel, its own networking stack, and its own resources (e.g., CPU, memory, disk). [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)The VM world was a vast improvement in terms of cost and efficiency. The cost and efficiency gains, however, only applied to the machine and operating system layers. At the application layer, not much had changed. As you can see in figure 1.2, applications were still tightly coupled to an operating system. If you wanted to run two or more instances of your application, you needed two or more VMs.

![Figure 1.2 Applications running on VMs](https://drek4537l1klr.cloudfront.net/boring/Figures/01-02.png)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)Unlike VMs, a container does not have a kernel. It does not have its own networking stack. It does not control resources like CPU, memory, and disk. In fact, the term *container* is just a concept; it is not a concrete technical reality like a VM.

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)The term *container* is really just shorthand for process and resource isolation in the Linux kernel. So when we talk about containers, what we really are talking about are *namespaces* and *control groups* (*cgroups*), both of which are features of the Linux kernel. *Namespaces* are a mechanism to isolate processes and their resources from each other. *Cgroups* provide limits and accounting for a collection of processes. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)But let’s not get too bogged down with these lower-level details. You don’t need to know about namespaces and cgroups to work through the rest of this book. If you are interested, however, I encourage you to watch Liz Rice’s talk “Containers from Scratch” ([https://www.youtube.com/watch?v=8fi7uSYlOdc](https://www.youtube.com/watch?v=8fi7uSYlOdc)).

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)With the introduction of containers, an application can be decoupled from the operating system layer, as seen in figure 1.3. With containers, if I have an app that starts up a server process that listens on port 80, I can now run multiple instances of that app on a single physical host. Or let’s say that I have six different applications, each with their own server processes listening on port 80. Again, with containers, I can run those six applications on the same host without having to give each one a different port at the application layer.

![Figure 1.3 Applications running in containers](https://drek4537l1klr.cloudfront.net/boring/Figures/01-03.png)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)The real benefit of containers is that they give the application the impression that it is the sole application running on the operating system and thus has access to all of the operating system’s resources. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)

## [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)1.4 What is an orchestrator?

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)The most recent step in the evolution of Michelle’s world is using an *orchestrator* to deploy and manage her applications. An orchestrator is a system that provides automation for deploying, scaling, and otherwise managing containers. In many ways, an orchestrator is similar to a CPU scheduler. The difference is that the target objects of an orchestration system are containers instead of OS-level processes. (While containers are typically the primary focus of an orchestrator, some systems also provide for the orchestration of other types of workloads. HashiCorp’s Nomad, for example, supports Java, command, and the QEMU VM runner workload types in addition to Docker.)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)With containers and an orchestrator, Michelle’s world changes drastically. In the past, the physical hardware and operating systems she deployed and managed were mostly dictated by requirements from application vendors. Her company’s financial system, for example, had to run on AIX (a proprietary Unix OS owned by IBM), which meant the physical servers had to be RISC-based ([https://riscv.org/](https://riscv.org/)) IBM machines. Why? Because the vendor that developed and sold the financial system certified that the system could run on AIX. If Michelle tried to run the financial system on, say, Debian Linux, the vendor would not provide support because it was not a certified OS. And this was just one of the many applications that Michelle operated for her company. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)Now Michelle can deploy a standardized fleet of machines that all run the same OS. She no longer has to deal with multiple hardware vendors who deal in specialized servers. She no longer has to deal with administrative tools that are unique to each operating system. And, most importantly, she no longer needs the hodgepodge of deployment tools provided by application vendors. Instead, she can use the same tooling to deploy, scale, and manage all of her company’s applications (table 1.1).

##### [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)Table 1.1 Michelle’s old and new worlds[(view table figure)](https://drek4537l1klr.cloudfront.net/boring/HighResolutionFigures/table_1-1.png)

| [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)Michelle’s old world | [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)Michelle’s new world |
| --- | --- |
| [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)Multiple hardware vendors | [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)Single hardware vendor (or cloud provider) |
| [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)Multiple operating systems | [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)Single operating system |
| [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)Runtime requirements dictated by application vendors | [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)Application vendors build to standards (containers and orchestration) |

## [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)1.5 The components of an orchestration system

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)So an orchestrator automates deploying, scaling, and managing containers. Next, let’s identify the generic components and their requirements that make those features possible. They are as follows:[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)

-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)The task
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)The job
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)The scheduler
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)The manager
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)The worker
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)The cluster
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)The command-line interface (CLI)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)Some of these components can be seen in figure 1.4.

![Figure 1.4 The basic components of an orchestration system. Regardless of what terms different orchestrators use, each has a scheduler, a manager, and a worker, and they all operate on tasks.](https://drek4537l1klr.cloudfront.net/boring/Figures/01-04.png)

### [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)1.5.1 The task

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)The *task* is the smallest unit of work in an orchestration system and typically runs in a container. You can think of it like a process that runs on a single machine. A single task could run an instance of a reverse proxy like NGINX, or it could run an instance of an application like a RESTful API server; it could be a simple program that runs in an endless loop and does something silly, like ping a website and write the result to a database. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)A task should specify the following:

1.  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)The amount of memory, CPU, and disk it needs to run effectively
1.  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)What the orchestrator should do in case of failures, typically called a *restart policy*[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)
1.  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)The name of the container image used to run the task

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)Task definitions may specify additional details, but these are the core requirements. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)

### [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)1.5.2 The job

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)The *job* is an aggregation of tasks. It has one or more tasks that typically form a larger logical grouping of tasks to perform a set of functions. For example, a job could be comprised of a RESTful API server and a reverse proxy. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)

##### [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)Kubernetes and the concept of a job

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)If you’re only familiar with Kubernetes[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/), this definition of *job* may be confusing at first. In Kubernetesland, a job is a specific type of workload that has historically been referred to as a *batch job*—that is, a job that starts and then runs to completion. Kubernetes has multiple resource types that are Kubernetes-specific implementations of the *job* concept:

-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)Deployment
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)ReplicaSet
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)StatefulSet
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)DaemonSet
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)Job

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)In the context of this book, we’ll use *job* in its more generic definition.

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)A job should specify details at a high level and will apply to all tasks it defines:

1.  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)Each task that makes up the job
1.  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)Which data centers the job should run in
1.  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)How many instances of each task should run
1.  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)The type of the job (should it run continuously or run to completion and stop?)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)We won’t be dealing with jobs in our implementation for the sake of simplicity. Instead, we’ll work exclusively at the level of individual tasks. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)

### [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)1.5.3 The scheduler

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)The *scheduler* decides what machine can best host the tasks defined in the job. The decision-making process can be as simple as selecting a node from a set of machines in a round-robin fashion or as complex as the Enhanced Parallel Virtual Machine (E-PVM) scheduler (used as part of Google’s Borg scheduler), which calculates a score based on a number of variables and then selects a node with the best score. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)The scheduler should perform these functions:

1.  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)Determine a set of candidate machines on which a task could run
1.  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)Score the candidate machines from best to worst
1.  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)Pick the machine with the best score

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)We’ll implement both the round-robin and E-PVM schedulers later in the book. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)

### [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)1.5.4 The manager

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)The *manager* is the brain of an orchestrator and the main entry point for users. To run jobs in the orchestration system, users submit their jobs to the manager. The manager, using the scheduler, then finds a machine where the job’s tasks can run. The manager also periodically collects metrics from each of its workers, which are used in the scheduling process. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)The manager should do the following:

1.  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)Accept requests from users to start and stop tasks.
1.  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)Schedule tasks onto worker machines.
1.  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)Keep track of tasks, their states, and the machine on which they run. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)

### [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)1.5.5 The worker

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)The *worker*[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/) provides the muscles of an orchestrator. It is responsible for running the tasks assigned to it by the manager. If a task fails for any reason, it must attempt to restart the task. The worker also makes metrics about its tasks and overall machine health available for the manager to poll. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)The worker is responsible for the following:

1.  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)Running tasks as Docker containers
1.  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)Accepting tasks to run from a manager
1.  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)Providing relevant statistics to the manager for the purpose of scheduling tasks [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)
1.  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)Keeping track of its tasks and their states

### [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)1.5.6 The cluster

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)The *cluster* is the logical grouping of all the previous components. An orchestration cluster could be run from a single physical or virtual machine. More commonly, however, a cluster is built from multiple machines, from as few as five to as many as thousands or more. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)The cluster is the level at which topics like *high availability* (HA) and *scalability* come into play. When you start using an orchestrator to run production jobs, these topics become critical. For our purposes, we won’t be discussing HA or scalability in any detail as they relate to the orchestrator we’re going to build. Keep in mind, however, that the design and implementation choices we make will impact the ability to deploy our orchestrator in a way that would meet the HA and scalability needs of a production environment. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)

### [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)1.5.7 Command-line interface

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)Finally, our CLI, the main user interface, should allow a user to [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)

1.  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)Start and stop tasks
1.  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)Get the status of tasks
1.  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)See the state of machines (i.e., the workers)
1.  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)Start the manager
1.  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)Start the worker

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)All orchestration systems share these same basic components. Google’s Borg, seen in figure 1.5, calls the manager the *BorgMaster* and the worker a *Borglet* but otherwise uses the same terms as previously defined. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)

![Figure 1.5 Google’s Borg. At the bottom are a number of Borglets, or workers, which run individual tasks in containers. In the middle is the BorgMaster, or the manager, which uses the scheduler to place tasks on workers.](https://drek4537l1klr.cloudfront.net/boring/Figures/01-05.png)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)Apache Mesos, seen in figure 1.6, was presented at the Usenix HotCloud workshop in 2009 and was used by Twitter starting in 2010. Mesos calls the manager simply the *master* and the worker an *agent*. It differs slightly, however, from the Borg model in how it schedules tasks. It has a concept of a *framework*, which has two components: a *scheduler* that registers with the master to be offered resources, and an executor process that is launched on agent nodes to run the framework’s tasks ([http://mesos.apache.org/documentation/latest/architecture/](http://mesos.apache.org/documentation/latest/architecture/)). [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)

![Figure 1.6 Apache Mesos](https://drek4537l1klr.cloudfront.net/boring/Figures/01-06.png)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)Kubernetes, which was created at Google and influenced by Borg, calls the manager the *control plane* and the worker a *kubelet*. It rolls up the concepts of job and task into *Kubernetes objects*[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/). Finally, Kubernetes maintains the usage of the terms *scheduler* and *cluster*. These components can be seen in the Kubernetes architecture diagram in figure 1.7. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)

![Figure 1.7 The Kubernetes architecture. The control plane, seen on the left, is equivalent to the manager function or to Borg’s BorgMaster.](https://drek4537l1klr.cloudfront.net/boring/Figures/01-07.png)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)HashiCorp’s Nomad, released a year after Kubernetes, uses more basic terms. The manager is the *server*, and the worker is the *client*. While not shown in figure 1.8, Nomad uses the terms *scheduler*, *job*, *task*, and *cluster* as we’ve defined here. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)

![Figure 1.8 Nomad’s architecture. While it appears more sparse, it still functions similarly to the other orchestrators.](https://drek4537l1klr.cloudfront.net/boring/Figures/01-08.png)

## [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)1.6 Meet Cube

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)We’re going to call our implementation *Cube*. If you’re up on your *Star Trek: Next Generation* references, you’ll recall that the Borg traveled in a cube-shaped spaceship. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)Cube will have a much simpler design than Google’s Borg, Kubernetes, or Nomad. And it won’t be anywhere nearly as resilient as the Borg’s ship. It will, however, contain all the same components as those systems.

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)The mental model in figure 1.9 expands on the architecture outlined in figure 1.4. In addition to the higher-level components, it dives a little deeper into the three main components: the manager, the worker, and the scheduler.

![Figure 1.9 Mental model for Cube. It has a manager, a worker, and a scheduler, and users (i.e., you) will interact with it via a command line.](https://drek4537l1klr.cloudfront.net/boring/Figures/01-09.png)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)Starting with the scheduler in the lower left of the diagram, we see it contains three boxes: *feasibility*, *scoring*, and *picking*. These boxes represent the scheduler’s generic phases, and they are arranged in the order in which the scheduler moves through the process of scheduling tasks onto workers:

-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)*Feasibility*—This phase assesses whether it’s even possible to schedule a task onto a worker. There will be cases where a task cannot be scheduled onto any worker; there will also be cases where a task can be scheduled but only onto a subset of workers. We can think of this phase as similar to choosing which car to buy. My budget is $10,000, but depending on which car lot I go to, all the cars on the lot could cost more than $10,000, or only a subset of cars may fit into my price range.
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)*Scoring*—This phase takes the workers identified by the feasibility phase and gives each one a score. This stage is the most important and can be accomplished in any number of ways. For example, to continue our car purchase analogy, I might give a score for each of three cars that fit within my budget based on variables like fuel efficiency, color, and safety rating.
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)*Picking*—This phase is the simplest. From the list of scores, the scheduler picks the best one. This will be either the highest or lowest score.

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)Moving up the diagram, we come to the manager. The first box inside the manager component shows that the manager uses the scheduler we described previously. Next, there is the *API* box. The API is the primary mechanism for interacting with Cube. Users submit jobs and request jobs be stopped via the API. A user can also query the API to get information about job and worker status. Next, there is the *Task* *Storage* box. The manager must keep track of all the jobs in the system to make good scheduling decisions, as well as to provide answers to user queries about job and worker statuses. Finally, the manager also keeps track of worker metrics, such as the number of jobs a worker is currently running, how much memory it has available, how much load the CPU is under, and how much disk space is free. This data, like the data in the job storage layer, is used for scheduling. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)The final component in our diagram is the worker. Like the manager, it too has an API, although it serves a different purpose. The primary user of this API is the manager. The API provides the means for the manager to send tasks to the worker, to tell the worker to stop tasks, and to retrieve metrics about the worker’s state. Next, the worker has a *task runtime*, which in our case will be Docker. Like the manager, the worker also keeps track of the work it is responsible for, which is done in the *Task Storage* layer. Finally, the worker provides metrics about its own state, which it makes available via its API. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)

## [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)1.7 What tools will we use?

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)To focus on our main goal, we’re going to limit the number of tools and libraries we use. Here’s the list of tools and libraries we’re going to use:[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)

-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)Go
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)chi
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)Docker SDK
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)BoltDB
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)goprocinfo
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)Linux

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)As the title of this book says, we’re going to write our code in the Go programming language. Both Kubernetes and Nomad are written in Go, so it is obviously a reasonable choice for large-scale systems. Go is also relatively lightweight, making it easy to learn quickly. If you haven’t used Go before but have written non-trivial software in languages such as C/C++, Java, Rust, Python, or Ruby, then you should be fine. If you want more in-depth material about the Go language, either *The Go Programming Language* ([www.gopl.io/](http://www.gopl.io/)) or *Get Programming with Go* ([www.manning.com/books/get-programming-with-go](http://www.manning.com/books/get-programming-with-go)) are good resources. That said, all the code presented will compile and run, so simply following along should also work. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)There is no particular requirement for an IDE to write the code. Any text editor will do. Use whatever you’re most comfortable with and makes you happy.

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)We’ll focus our system on supporting Docker containers. This is a design choice. We could broaden our scope so our orchestrator could run a variety of jobs: containers, standalone executables, or Java JARs. Remember, however, our goal is not to build something that will rival existing orchestrators. This is a learning exercise. Narrowing our scope to focus solely on Docker containers will help us reach our learning goals more easily. That said, we will be using Docker’s Go SDK ([https://pkg.go.dev/github.com/docker/docker/client](https://pkg.go.dev/github.com/docker/docker/client)).

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)Our manager and worker are going to need a datastore. For this purpose, we’re going to use BoltDB ([https://github.com/boltdb/bolt](https://github.com/boltdb/bolt)), an embedded key/value store. There are two main benefits to using Bolt. First, by being embedded within our code, we don’t have to run a database server. This feature means neither our manager nor our workers will need to talk across a network to read or write its data. Second, using a key/value store provides fast, simple access to our data. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)The manager and worker will each provide an API to expose their functionality. The manager’s API will be primarily user-facing, allowing users of the system to start and stop jobs, review job status, and get an overview of the nodes in the cluster. The worker’s API is internal-facing and will provide the mechanism by which the manager sends jobs to workers and retrieves metrics from them. In many other languages, we might use a web framework to implement such an API. For example, if we were using Java, we might use Spring. Or if we were using Python, we might choose Django. While there are such frameworks available for Go, they aren’t always necessary. In our case, we don’t need a full web framework like Spring or Django. Instead, we’re going to use a lightweight router called chi ([https://github.com/go-chi/chi](https://github.com/go-chi/chi)). We’ll write handlers in plain Go and assign those handlers to routes. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)To simplify the collection of worker metrics, we’re going to use the `goprocinfo` library ([https://github.com/c9s/goprocinfo](https://github.com/c9s/goprocinfo)). This library will abstract away some details related to getting metrics from the proc filesystem. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)Finally, while you can write the code in this book on any operating system, it will need to be compiled and run on Linux. Any recent distribution should be sufficient.

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)For everything else, we’ll rely on Go and its standard tools that are installed by default with every version of Go. Since we’ll be using Go modules, you should use Go v1.14 or later. I’ve developed the code in this book using versions 1.20, 1.19, and 1.16. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)

## [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)1.8 A word about hardware

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)You won’t need a bunch of hardware to complete this book. You can do everything on a single machine, whether that’s a laptop, a desktop, or even a Raspberry Pi. The only requirements are that the machine is running Linux and it has enough memory and disk to hold the source code and compile it. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)If you are going to do everything on a single machine, there are a couple more things to consider. You can run a single instance of the worker. This means when you submit a job to the manager, it will assign that job to the single worker. For that matter, any job will be assigned to that worker. For a better experience, and one that better exercises the scheduler and showcases the work you’re going to do, you can run multiple instances of the worker. One way to do this is to simply open multiple terminals and run an instance of the worker in each. Alternatively, you can use something like tmux ([https://github.com/tmux/tmux](https://github.com/tmux/tmux)), seen in figure 1.10, which achieves a similar outcome but allows you to detach from the terminal and leave everything running. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)

![Figure 1.10 A tmux session showing three Raspberry Pis running the Cube worker](https://drek4537l1klr.cloudfront.net/boring/Figures/01-10.png)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)If you have extra hardware lying around (e.g., an old laptop or desktop or a couple of Raspberry Pis), you can use those as your worker nodes. Again, the only requirement is that they are running Linux. For example, in developing the code in preparation for writing this book, I used eight Raspberry Pis as workers. I used my laptop as the manager.

## [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)1.9 What we won’t be implementing or discussing

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)So, to reiterate, our purpose here is not to build something that can be used to replace a production-grade system like Kubernetes. Engineering is about weighing tradeoffs against your requirements. This is a learning exercise to gain a better understanding of how orchestrators, in general, work. To that end, we won’t be dealing with or discussing any of the following that might accompany discussions of production-grade systems:[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)

-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)Distributed computing
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)Service discovery
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)High availability
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)Load balancing
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)Security

### [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)1.9.1 Distributed computing

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)*Distributed computing*[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/) is an architectural style where a system’s components run on different computers, communicate across a network, and have to coordinate actions and states. The main benefits of this style are scalability and resiliency to failure. An orchestrator is a distributed system. It allows engineers to scale systems beyond the resources of a single computer, thus enabling those systems to handle larger and larger workloads. An orchestrator also provides resiliency to failure by making it relatively easy for engineers to run multiple instances of their services and for those instances to be managed in an automated way.

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)That said, we won’t be going into the theory of distributed computing. If you’re interested in that topic specifically, there are many resources that cover the subject in detail. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)Resources on distributed computing include [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)

-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)*Designing Data-Intensive Applications* ([http://mng.bz/6nqZ](http://mng.bz/6nqZ))
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)*Designing Distributed Systems* ([http://mng.bz/5oqZ](http://mng.bz/5oqZ))

### [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)1.9.2 Service discovery

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)*Service discovery*[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/) provides a mechanism for users, either human or other machines, to discover service locations. Like all orchestration systems, Cube will allow us to run one or more instances of a task. When we ask Cube to run a task for us, we cannot know in advance where Cube will place the task (i.e., on which worker the task will run). If we have a cluster with three worker nodes, a task can potentially be scheduled onto any one of those three nodes.

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)To help find tasks once they are scheduled and running, we can use a service discovery system (e.g., Consul; [www.consul.io](http://www.consul.io)) to answer queries about how to reach a service. While service discovery is indispensable in larger orchestration systems, it won’t be necessary for our purposes. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)Resources on service discovery include [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)

-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)*Service Discovery in a Microservices Architecture* ([http://mng.bz/0lpz/](http://mng.bz/0lpz))
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)*Service Discovery in Nomad* ([http://mng.bz/W1yX](http://mng.bz/W1yX))
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)*Service Discovery in Kubernetes* ([http://mng.bz/84Pg](http://mng.bz/84Pg))

### [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)1.9.3 High availability

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)The term *availability* refers to the amount of time a system is available for usage by its intended user base. Often you’ll hear the term *hgh availability* (HA) used, which refers to strategies to maximize the time a system is available for its users. Several examples of HA strategies are [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)

-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)Elimination of single points of failure via redundancy
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)Automated detection of and recovery from failures
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)Isolation of failures to prevent total system outages

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)An orchestration system, by design, is a tool that enables engineers to implement these strategies. By running more than one instance of, say, a mission-critical web API, I can ensure the API won’t become completely unavailable for my users if a single instance of it goes down for some reason. By running more than one instance of my web API on an orchestrator, I ensure that if one of the instances does fail for some reason, the orchestrator will detect it and attempt to recover from the failure. If any one instance of my web API fails, that failure will not affect the other instances (with some exceptions; see the following discussion).

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)At the same time, it is common to use these strategies to deploy the orchestration system itself. Production orchestration systems typically use multiple worker nodes. For example, worker nodes in a Borg cluster number in the tens of thousands. By running multiple worker nodes, the system permits users like me to run multiple instances of my mission-critical web API across a number of different machines. If one of those machines running my web API experiences a catastrophic failure (maybe a mouse took up residence in the machine’s rack and accidentally unseated the machine’s power cord), my application can still serve its users.

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)For our purposes in this book, we will implement our orchestrator so multiple instances of the worker can be easily run in a manner similar to Google’s Borg. For the manager, however, we will only run a single instance. So while our workers can be run in an HA way, our manager cannot. Why?

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)The manager and worker components of our orchestration system—of any orchestration system—have different scopes. The worker’s scope is narrow, concerned only with the tasks that it is responsible for running. If worker 2 fails for some reason, worker 1 doesn’t care. Not only does it not care, but it doesn’t even know worker 2 exists.

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)The manager’s scope, however, encompasses the entire orchestration cluster. It maintains state for the cluster: how many worker nodes there are, the state of each worker (CPU, memory, and disk capacity, as well as how much of that capacity is already being used), and the state of each task submitted by users. To run multiple instances of the manager, there are many more questions to ask:

-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)Among the manager instances, will there be a *leader* that will handle all of the management responsibilities, or can any manager instance handle those responsibilities?[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)How are state updates replicated to each instance of the manager?
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)If state data gets out of sync, how do the managers decide which data to use?

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)These questions ultimately lead to the topic of *consensus*, which is a fundamental problem in distributed systems. While this topic is interesting, it isn’t critical to our learning about and understanding how an orchestration system works. If our manager goes down, it won’t affect our workers. They will continue to run the tasks already assigned to them. It does mean our cluster won’t be able to accept new tasks, but for our purposes, we’re going to decide that this is acceptable for the exercise at hand. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)Resources on HA include [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)

-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)“An Introduction to High Availability Computing: Concepts and Theory” ([http://mng.bz/mj5y](http://mng.bz/mj5y))
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)*Learn Amazon Web Services in a Month of Lunches* ([http://mng.bz/7vqV](http://mng.bz/7vqV))

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)Resources on consensus include [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)

-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)“Consensus: Reaching Agreement” ([http://mng.bz/qjvN](http://mng.bz/qjvN))
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)*Paxos Made Simple* ([http://mng.bz/K9Qn](http://mng.bz/K9Qn))
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)*The Raft Consensus Algorithm* ([https://raft.github.io/](https://raft.github.io/))

### [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)1.9.4 Load balancing

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)*Load balancing*[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/) is a strategy for building highly available, reliable, and responsive applications. Common load balancers (LBs) include NGINX, HAProxy, and AWS’s assortment of load balancers (classic elastic LBs, network LBs, and the newer application LBs). While they are used in conjunction with orchestrators, they can become complex quickly because they are typically employed in multiple ways.

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)For example, it’s common to have a public-facing LB that serves as an entry point to a system. This LB might know about each node in an orchestration system, and it will pick one of the nodes to which it forwards the request. The node receiving this request is itself running an LB that is integrated with a service discovery system and can thus forward the request to a node in the cluster running a task that can handle the request.

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)Load balancing as a topic is also complex. It can be as simple as using a round-robin algorithm, in which the LB maintains a list of nodes in the cluster and a pointer to the last node selected. When a request comes in, the LB selects the next node in the list. Or it can be as complex as choosing a node that is best able to meet some criteria, such as the resources available or the lowest number of connections. While load balancing is an important tool in building highly available production systems, it is not a fundamental component of an orchestration system. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)Resources on load balancing include [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)

-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)“Quick Introduction to Load Balancing and Load Balancers” ([http://mng.bz/ 9QW8](http://mng.bz/9QW8))
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)“Types of Load Balancing Algorithms” ([http://mng.bz/wjaB](http://mng.bz/wjaB))

### [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)1.9.5 Security

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)Security is like an onion. It has many layers, many more than we can reasonably cover in this book. If we were going to run our orchestrator in production, we would need to answer questions like[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)

-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)How do we secure the manager so only authenticated users can submit tasks or perform other management operations?
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)Should we use authorization to segment users and the operations they can perform?
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)How do we secure the workers so they only accept requests from a manager?
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)Should network traffic between the manager and worker be encrypted?
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)How should the system log events to audit who did what and when?

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)Resources on security include [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)

-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)*API Security in Action* ([https://www.manning.com/books/api-security-in-action](https://www.manning.com/books/api-security-in-action))
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)*Security by Design* ([https://www.manning.com/books/secure-by-design](https://www.manning.com/books/secure-by-design))
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)*Web Application Security* ([http://mng.bz/Jdqz](http://mng.bz/Jdqz))

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)In the next chapter, we’re going to start coding by translating our mental model into skeleton code. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)

## [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)Summary

-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)Orchestrators abstract machines and operating systems away from developers, thus leaving them to focus on their application.
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)An orchestrator is a system comprised of a manager, worker, and scheduler. The primary objects of an orchestration system are tasks and jobs.
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)Orchestrators are operated as a cluster of machines, with machines filling the roles of manager and worker.
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)In orchestration systems, applications typically run in containers.
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)Orchestrators allow for a level of standardization and automation that was difficult to achieve previously. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-1/)

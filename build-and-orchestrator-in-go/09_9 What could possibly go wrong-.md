# [](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)9 What could possibly go wrong?

### This chapter covers

- Enumerating potential failures
- Exploring options for recovering from failures
- Implementing task health checks to recover from task crashes

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)At the beginning of chapter 4, in which we started the process of implementing our worker, we talked about the scenario of running a web server that serves static pages. In that scenario, we considered how to deal with the problem of our site growing in popularity and thus needing to be resilient to failures to ensure we could serve our growing user base. The solution, we said, was to run multiple instances of our web server. In other words, we decided to scale horizontally, a common pattern for scaling. By scaling the number of web servers, we can ensure that a failure in any given instance of the web server does not bring our site completely down and, thus, unavailable to our users.

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)In this chapter, we’re going to modify this scenario slightly. Instead of serving static web pages, we’re going to serve an API. This API is very simple: it takes a `POST` request with a body, and it returns a response with the same body. In other words, it simply echoes the request in the response.

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)With that minor change to our scenario, this chapter will reflect on what we’ve built thus far and discuss a number of failure scenarios, both with our orchestrator and with the tasks running on it. Then we will implement several mechanisms for handling a subset of failure scenarios.

## [](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)9.1 Overview of our new scenario

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)Our new scenario involves an API that takes the body of a request and simply returns that body in the response to the user. The format of the body is JSON, and our API defines this format in the `Message` struct:[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)

```
type Message struct {
   Msg string
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)Thus, making a `curl` request to this API looks like this:

```bash
$ curl -X POST localhost:7777/ -d '{"Msg":"Hello, world!"}'
{"Msg":"Hello, world!"}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)And, as you can see in the response, we get back the same body that we sent. To make this scenario simpler to use, I’ve gone ahead and built a Docker image that we can reuse throughout the rest of the chapter. So to run that API locally, all you have to do is this:

```bash
$ docker run -it --rm --name echo timboring/echo-server:latest
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)(If you’re interested in the source code for this API, you can find it in the `echo` directory in the downloadable source code for this chapter.)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)Now let’s move on to talk about the number of ways this API can fail if we run it as a task in our orchestration system. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)

## [](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)9.2 Failure scenarios

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)Failures happen all the time! As engineers, we should expect this. Failures are the norm, not the exception. More importantly, failures happen at multiple levels:[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)

-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)Failures at the level of the application
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)Failures at the level of individual tasks
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)Failures at the level of the orchestration system

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)Let’s walk through what failures at each of these levels might look like.

### [](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)9.2.1 Application startup failure

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)A task can fail to start because the task’s application has a bug in its startup routine. For example, we might decide to store each request our echo service receives, and to do that, we add a database as a dependency. Now, when an instance of our echo service starts up, it attempts to make a connection to the database. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)What happens, however, if we can’t connect to the database? Maybe it’s down due to some networking problem. Or, if we’re using a managed service, perhaps the administrators decided they needed to do some maintenance, and as a result, the database service is unavailable for some period of time. Or maybe the database is upset with its human overlords and has decided to go on strike.

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)It doesn’t really matter why the database is unavailable. The fact is that our application depends on the database, and it needs to do something when it is unavailable. There are generally two options for how our application can respond:

-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)It can simply crash.
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)It can attempt to retry connecting to the database.

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)In my experience, I’ve seen the former option used frequently. It’s the default. As an engineer, I have an application that needs a database, and I attempt to connect to the database when my application starts. Maybe I check for errors, log them, and then exit gracefully.

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)The latter option might be the better choice, but it adds some complexity. Today, most languages have at least one third-party library that provides the framework to perform retries using exponential backoff. Using this option, I could have my application attempt to connect to the database in a separate goroutine, and until it can connect, maybe my application serves a `503` response with a helpful message explaining that the application is in the process of starting up. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)

### [](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)9.2.2 Application bugs

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)A task can also fail after having successfully started up. For example, our echo service can start up and operate successfully for a while. But we’ve recently added a new feature, and we haven’t tested it thoroughly because we decided it was an important feature and getting it into production would allow us to post about it on Hacker News. A user queries our service in a way that triggers our new code in an unexpected way and crashes the API. Oops![](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)

### [](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)9.2.3 Task startup failures due to resource problems

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)A task can fail to start because the worker machine doesn’t have enough resources (i.e., memory, CPU, or disk). In theory, this shouldn’t happen. Orchestration systems like Kubernetes and Nomad implement sophisticated schedulers that take memory and CPU requirements into account when scheduling tasks onto worker nodes. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)The story for disk, however, is a little more nuanced. Container images consume disk space. Run the `docker` `images` command on your machine and notice the `SIZE` column in the output. On my machine, the `timboring/echo-server` we’re using in this chapter is 12.3 MB in size. If I pull down the `postgres:14` image, I can see that its size is 376 MB:

```bash
$ docker images
REPOSITORY              TAG           IMAGE ID       CREATED        SIZE
timboring/echo-server   latest        fe039d2a9875   4 months ago   12.3MB
postgres                14            dd21862d2f49   4 days ago     376MB
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)While there are strategies to minimize size, images still reside on disk and thus consume space. In addition to container images, the other processes running on worker nodes also use disk space—for example, they may store their logs on disk. Also, other containers running on a node may be using disk space for their own data. So it is possible that an orchestrator could schedule a task onto a worker node, and then when that worker starts up the task, the task fails because there isn’t enough disk space to download the container image. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)

### [](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)9.2.4 Task failures due to Docker daemon crashes and restarts

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)Running tasks can also be affected by problems with the Docker daemon. For example, if the Docker daemon crashes, then our task will be terminated. Similarly, if we stop or restart the Docker daemon, then the daemon will also stop our task. This behavior is the default for the Docker daemon. Containers can be kept alive while the daemon is down using a feature called live restore, but the usage of that feature is beyond the scope of this book. For our purposes, we will work with the default behavior. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)

### [](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)9.2.5 Task failures due to machine crashes and restarts

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)The most extreme failure scenario is a worker machine crashing. In the case of an orchestration system, if a worker machine crashes, then the Docker daemon will obviously stop running, along with any tasks running on the machine. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)Less extreme is the situation where a machine is restarted. Perhaps an administrator restarts it after updating some software, in which case the Docker daemon will be stopped and started back up after the machine reboots. In the process, however, any tasks will be terminated and will need to be restarted. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)

### [](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)9.2.6 Worker failures

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)In addition to application and task failures, when we run the echo service on our orchestration system, the worker where the task runs can also fail. But there is a little more involved at this level. When we say *worker*, we need to clarify what exactly we’re talking about. First, there is the worker component that we’ve written. Second, there is the machine where our worker component runs. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)So when we talk about worker failures, we have two discrete types of failures at this layer of our orchestration system. Our worker component that we’ve written can crash due to bugs in our code. It can also crash because the machine it’s running on crashes or becomes otherwise unavailable.

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)We already touched on machine failure, but let’s talk briefly about failures with the worker component. If it fails for some reason, what happens to the running tasks? Unlike the Docker daemon, our worker going down or restarting does not terminate running containers. It does mean that the manager cannot send *new* tasks to the worker, and it means that the manager cannot query the worker to get the current state of running tasks.

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)So while a failure in our worker is inconvenient, it doesn’t have an immediate effect on running tasks. (It could be more than inconvenient if, say, a number of workers crashed, which resulted in your team being unable to deploy a mission-critical bug fix. But that’s a topic for another book.) [](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)

### [](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)9.2.7 Manager failures

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)The final failure scenario to consider involves the manager component. Remember, we said the manager serves an administrative function. It receives requests from users to run their tasks, and it schedules those tasks onto workers. Unless the manager and worker components are running on the same machine (and we wouldn’t do that in a production environment, would we?), any problems with the manager will only affect those administrative functions. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)So if the manager component or the machine on which it is running crashes, the effect would likely be minimal. Running tasks would continue to run. Users would not, however, be able to submit new tasks to the system because the manager would not be available to receive and take action on those requests. Again, it would be inconvenient but not necessarily the end of the world. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)

## [](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)9.3 Recovery options

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)As failures in an orchestration system can occur at multiple levels and have various degrees of effect, so too do the recovery options. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)

### [](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)9.3.1 Recovery from application failures

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)As we previously discussed, applications can fail at startup due to external dependencies being unavailable. The only real automated recovery option here is to perform retries with exponential backoff or some other mechanism. An orchestration system cannot wave a magic wand and fix problems with external dependencies (unless, of course, that external dependency is also running on the orchestration system). An orchestrator provides us with some tools for automated recovery from these kinds of situations, but if a database is down, continually restarting the application isn’t going to change the situation. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)Similarly, an orchestration system can’t help us with the bugs we introduce into our applications. The real solution is tools like automated testing, which can help identify bugs before they are deployed into production. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)

### [](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)9.3.2 Recovering from environmental failures

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)An orchestration system provides a number of tools for dealing with non-application-specific failures. We can group the remaining failure scenarios together and call them *environmental* failures:[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)

-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)Failures with Docker
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)Failures with machines
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)Failures with an orchestrator’s worker
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)Failures with an orchestrator’s manager

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)Let’s cover some ways in which an orchestration system can help recover from these types of failures.

### [](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)9.3.3 Recovering from task-level failures

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)Docker has a built-in mechanism for restarting containers when they exit. This mechanism is called *restart policies* and can be specified on the command line using the `--restart` flag. In the following example command line, we run a container using the `timboring/echo-server` image and tell Docker we want it to restart the container once if it exits because of a failure:[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)

```bash
$ docker run \
   --restart=on-failure:1 \
   --name echo \
   -p 7777:7777 \
   -it \
   timboring/echo-server:bad-exit
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)Docker supports four restart policies:

-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)`no`—Do nothing when a container exits (this is the default).
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)`on-failure`—Restart the container if it exits with a nonzero status code.
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)`always`—Always restart the container, regardless of the exit code.
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)`unless-stopped`—Always restart the container, except if the container was stopped.

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)You can read more about Docker’s restart policies in the docs at [http://mng.bz/VRWN](http://mng.bz/VRWN).

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)The restart policy works well when dealing with individual containers being run outside of an orchestration system. In most production situations, we run Docker itself as a systemd unit. systemd, as the initialization system for most Linux distributions, can ensure that applications that are supposed to be running are, in fact, running, especially after a reboot.

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)For containers running as part of an orchestration system, however, using Docker’s restart policies can pose problems. The main problem is that they muddy the waters around who is responsible for dealing with failures. Is the Docker daemon ultimately responsible? Or is the orchestration system? Moreover, if the Docker daemon is involved in handling failures, this adds complexity to the orchestrator because it will need to check with the Docker daemon to see if it’s in the process of restarting a container.

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)For Cube, we will handle task failures ourselves instead of relying on Docker’s restart policy. This decision, however, does raise another question: Should the manager or worker be responsible for handling failures?

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)The worker is closest to the task, so it seems natural to have the worker deal with failures. But the worker is only aware of its own singular existence. Thus, it can only attempt to deal with failures in its own context. If it’s overloaded, it can’t make the decision to send the task to another worker because it doesn’t know about any other workers.

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)The manager, though farther away from the actual mechanisms that control task execution, has a broader view of the whole system. It knows about all the workers in the cluster, and it knows about the individual tasks running on each of those workers. Thus, the manager has more options for recovering from failures than does an individual worker. It can ask the worker running the failed task to try to restart it. Or, if that worker is overloaded or unavailable (maybe it crashed), it can find another worker that has capacity to run the task. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)

### [](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)9.3.4 Recovering from worker failures

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)As I previously mentioned when discussing the types of worker failures, there are two distinct types of failures when it comes to the worker. There are failures in the worker component itself and failures with the machine where the worker is running. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)In the first case, when our worker component fails, we have the most flexibility. The worker itself isn’t critical to existing tasks. Once a task is up and running, the worker is not involved in the task’s ongoing operation. So if the worker fails, there isn’t much consequence to running tasks. In such a state, however, the worker is in a degraded state. The manager won’t be able to communicate with the worker, which means it won’t be able to collect the task state, and it won’t be able to place new tasks on the worker. It also won’t be able to stop running tasks.

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)In this situation, we could have the manager attempt to fix the worker component. How? The obvious thing that comes to mind is for the manager to consider the worker dead and move all the tasks to another worker. This is a rather blunt force tactic, however, and could wreak more havoc. If the manager simply considers those tasks dead and attempts to restart them on another worker machine, what happens if the tasks are still running on the machine where the worker crashed? By blindly considering the worker and all of its tasks dead, the manager could be putting applications into an unexpected state. This is particularly true when there is only a single instance of a task.

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)The second case, where a worker machine has crashed, is also tricky. How are we defining “crashed”? Does it mean the manager cannot communicate with the worker via its API? Does it mean the manager performs some other operation to verify a worker is up—for example, by attempting an ICMP ping? Moreover, can the manager be certain that a worker machine was actually down even if it did attempt an ICMP ping and did not receive a response? What if the problem was that the worker machine’s network card died, but the machine was otherwise up and operating normally? Similarly, what if the manager and worker machine were on different network segments, and a router, switch, or other piece of network equipment died, thus segmenting the two networks so the manager could not talk to the worker machine?

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)As we can see, trying to make our orchestration system resilient to failures in the worker component is more complex than it may initially seem. It’s difficult to determine whether a machine is down—meaning it has crashed or been powered off and is otherwise not running any tasks—in which case the Docker daemon is not running, nor are any of the tasks under its control. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)

### [](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)9.3.5 Recovering from manager failures

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)Finally, let’s consider our options for failures in the manager component. Like the worker, there are two failure scenarios. The manager component itself could fail, and the machine on which the manager component is running could fail. While these scenarios are the same as in the worker, their effects and how we deal with them are slightly different. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)First, if the manager dies, regardless of whether it’s the manager component itself or the machine where it’s running, there is no effect on running tasks. The tasks and the worker operate independently of the manager. In our orchestration system, if the manager dies, the worker and its tasks continue operating normally. The only difference is that the worker won’t receive any new tasks.

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)Second, recovering from manager failures in our orchestration system will likely be less complex than recovering from failures at the worker layer. Remember, for the sake of simplicity, we have said that we will run only a single manager. So if it fails, we only need to try to recover a single instance. If the manager component crashes, we can restart it. (Ideally, we’d run it using an init system like Systemd or supervisord.) If its datastore gets corrupted, we can restore it from a backup.

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)While not ideal, a manager failure doesn’t bring our whole system down. It does cause some pain for developers because while the manager is down, they won’t be able to start new tasks or stop existing ones. So deployments of new features or bug fixes will be delayed until the manager is back online.

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)Obviously, the ideal state in regard to the manager would be to run multiple instances of the manager. This is what orchestrators like Borg, Kubernetes, and Nomad do. Like running multiple workers, running multiple instances of the manager adds resiliency to the system as a whole. There is, however, added complexity.

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)When running multiple managers, we have to think about synchronizing state across all the instances. There might be a primary instance that is responsible for handling user requests and acting on them. This instance will also be responsible for distributing the state of all the system’s tasks across the other managers. If the primary instance fails, then another can take over its role. At this point, we start getting into the realm of consensus and the idea of how systems agree on the state of the world. This is where things like the Raft protocol come into play, but going farther down this road is beyond the scope of this book. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)

## [](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)9.4 Implementing health checks

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)With this complexity in mind, we are going to implement a simple solution for illustration purposes. We are going to implement health checks at the task level. The basic idea here is twofold:[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)

-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)An application implements a health check and exposes it on its API as `/health`. (The name of the endpoint could be anything, as long as it’s well defined and doesn’t change.)
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)When a user submits a task, they define the health check endpoint as part of the task configuration.
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)The manager calls a task’s health check periodically and will attempt to start a new task for any non-`200` response.

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)With this solution, we don’t have to worry about whether the worker machine is reachable. We also don’t have to figure out whether a worker component is working. We just call the health check for a task, and if it responds that it’s operating as expected, we know the manager can continue about its business.

##### Note

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/) Operationally, we still care about whether the worker component is functioning as expected. But we can treat that problem separately from task health and how and when we need to attempt to restart tasks.

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)There are two components to health checks. First, the worker has to periodically check the state of its tasks and update them accordingly. To do this, it can call the `ContainerInspect()` method on the Docker API. If the task is in any state other than `running`, then the worker updates the task’s state to `Failed`. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)Second, the manager must periodically call a task’s health check. If the check doesn’t pass (i.e., it returns anything other than a `200` response code), it then sends a task event to the appropriate worker to restart the task.

### [](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)9.4.1 Inspecting a task on the worker

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)Let’s start with refactoring our worker so it can inspect the state of a task’s Docker container. If we think back to chapter 3, we implemented the following `Docker` struct. The purpose of this struct is to hold a reference to an instance of the Docker client, which is what allows us to call the Docker API and perform various container operations. It also holds the `Config` for a task:[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)

```bash
type Docker struct {
   Client *client.Client
   Config Config
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)To handle responses from the `ContainerInspect` API call, let’s create a new struct called `DockerInspectResponse` in the `task/task.go` file. As we can see in listing 9.1, this struct will contain two fields. The `Error` field will hold an error if we encounter one when calling `ContainerInspect`. The `Container` field is a pointer to a `types` `.ContainerJSON` struct. This struct is defined in Docker’s Go SDK ([http://mng.bz/ orjD](http://mng.bz/orjD)). It contains all kinds of detailed information about a container, but most importantly for our purposes, it contains the field `State`. This is the current state of the container as Docker sees it. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)

##### Listing 9.1 The new `DockerInspectResponse` struct

```
type DockerInspectResponse struct {
   Error     error
   Container *types.ContainerJSON
}
```

##### [](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)A note about the Docker container state

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)The concept of Docker container state can be confusing. For example, the doc ([http:// mng.bz/n19d](http://mng.bz/n19d)) for the `docker` `ps` command mentions filtering by container status, where the status is one of `created`, `restarting`, `running`, `removing`, `paused`, `exited`, or `dead`. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)If you look at the Docker source code, however, you’ll find there is a `State` struct defined in `container/state.go` ([http://mng.bz/46xQ](http://mng.bz/46xQ)), which looks like this:[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)

```
type State struct {
   Running           bool
   Paused            bool
   Restarting        bool
   OOMKilled         bool
   RemovalInProgress bool
   Dead              bool
   // other fields omitted
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)As we can see, technically, there is not a state called `created`, nor is there an `exited` state. So what is going on here? It turns out there is a method on the `State` struct named `StateString` ([http://mng.bz/QRj4](http://mng.bz/QRj4)), and this is performing some logic that results in the statuses we see in the documentation for the `docker` `ps` command. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)In addition to adding the `DockerInspectResponse` struct, we’re also going to add a new method to our existing `Docker` struct. Let’s call this method `Inspect`. It should take a string that represents the container ID we want it to inspect. Then it should return a `DockerInspectResponse`. The body of the method is straightforward. It creates an instance of a Docker client called `dc`. Then we call the client’s `ContainerInspect` method, passing in a context `ctx` and a `containerID`. We check for an error and return it if we find one. Otherwise, we return a `DockerInspectResponse`. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)

##### Listing 9.2 The `Inspect` method calling the Docker API

```
func (d *Docker) Inspect(containerID string) DockerInspectResponse {
   dc, _ := client.NewClientWithOpts(client.FromEnv)
   ctx := context.Background()
   resp, err := dc.ContainerInspect(ctx, containerID)
   if err != nil {
       log.Printf("Error inspecting container: %s\n", err)
       return DockerInspectResponse{Error: err}
   }

   return DockerInspectResponse{Container: &resp}
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)Now that we’ve implemented the means to inspect a task, let’s move on and use it in our worker. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)

### [](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)9.4.2 Implementing task updates on the worker

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)For the worker to update the state of its tasks, we’ll need to refactor it to use the new `Inspect` method we created on the `Docker` struct. To start, let’s open the `worker/ worker.go` file and add the `InspectTask` method as shown in listing 9.3. This method takes a single argument `t` of type `task.Task`. It creates a task config `config` and then sets up an instance of the `Docker` type that will allow us to interact with the Docker daemon running on the worker. Finally, it calls the `Inspect` method, passing in the `ContainerID`. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)

##### Listing 9.3 The `InspectTask` method

```
func (w *Worker) InspectTask(t task.Task) task.DockerInspectResponse {
   config := task.NewConfig(&t)
   d := task.NewDocker(config)
   return d.Inspect(t.ContainerID)
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)Next, the worker will need to call its new `InspectTask` method. To do this, let’s use the same pattern we’ve used in the past. We’ll create a public method called `UpdateTasks`, which will allow us to run it in a separate goroutine. This method is nothing more than a wrapper that runs a continuous loop and calls the private `updateTasks` method, which does all the heavy lifting. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)

##### Listing 9.4 The worker’s new `UpdateTasks` method

```
func (w *Worker) UpdateTasks() {
   for {
       log.Println("Checking status of tasks")
       w.updateTasks()
       log.Println("Task updates completed")
       log.Println("Sleeping for 15 seconds")
       time.Sleep(15 * time.Second)
   }
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)The `updateTasks` method performs a very simple algorithm. For each task in the worker’s datastore, it does the following:[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)

-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)Calls the `InspectTask` method to get the task’s state from the Docker daemon
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)Verifies the task is in the `running` state
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)If it’s not in the `running` state, or not running at all, sets the tasks’ state to `failed`

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)The `updateTasks` method also performs one other operation. It sets the `HostPorts` field on the task. This allows us to see what ports the Docker daemon has allocated to the task’s running container. Thus, the worker’s new `updateTasks` method handles calling the new `InspectTask` method, which results in updating the task’s state based on the state of its Docker container. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)

##### Listing 9.5 The worker’s new `updateTasks` method

```
func (w *Worker) updateTasks() {
    for id, t := range w.Db {
        if t.State == task.Running {
            resp := w.InspectTask(*t)
            if resp.Error != nil {
                fmt.Printf("ERROR: %v\n", resp.Error)
            }
 
            if resp.Container == nil {
                log.Printf("No container for running task %s\n", id)
                w.Db[id].State = task.Failed
            }
 
            if resp.Container.State.Status == "exited" {
                log.Printf("Container for task %s in non-running state %s",
                 id, resp.Container.State.Status)
                w.Db[id].State = task.Failed
            }
 
            w.Db[id].HostPorts =
             resp.Container.NetworkSettings.NetworkSettingsBase.Ports
        }
    }
}
```

### [](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)9.4.3 Healthchecks and restarts

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)We’ve said we will have the manager perform health checks for the tasks running in our orchestration system. But how do we identify these health checks so the manager can call them? One simple way to accomplish this is to add a field called `HealthCheck` to the `Task` struct, and by convention, we can use this new field to include a URL that the manager can call to perform a health check. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)In addition to the `HealthCheck` field, let’s also add a field called `RestartCount` to the `Tasks` struct. This field will be incremented each time the task is restarted, as we will see later in this chapter. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)

##### Listing 9.6 Adding the `HealthCheck` and `RestartCount` fields

```
type Task struct {
   // existing fields omitted
   HealthCheck   string
   RestartCount  int
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)The benefit of this approach to health checks is that it makes it the responsibility of the task to define what it means to be healthy. Indeed, the definition of *healthy* can vary wildly from task to task. Thus, by having the task define its health check as a URL that can be called by the manager, all the manager has to do then is to call that URL. The result of calling the task’s health check URL then determines a task’s health: if the call returns a `200` status, the task is healthy; otherwise, it is not.

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)Now that we’ve implemented the necessary bits to enable our health check strategy, let’s write the code necessary for the manager to make use of that work. Let’s start with the lowest-level code first. Open the `manager/manager.go` file in your editor, and add the `checkTaskHealth` method as shown in listing 9.7. This method implements the necessary steps that allow the manager to check the health of an individual task. It takes a single argument `t` of type `task.Task`, and it returns an error if the health check is not successful. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)There are a couple of things to note about this method. First, recall that when the manager schedules a task onto a worker, it adds an entry in its `TaskWorkerMap` field that maps the task’s ID to the worker where it has been scheduled. That entry is a string and will be the IP address and port of the worker (e.g., `192.168.1.100:5555`). Thus, it’s the address of the worker’s API. The task will, of course, be listening on a different port from the worker API. Thus, it’s necessary to get the task’s port that the Docker daemon assigned to it when the task started, and we accomplish this by calling the `getHostPort` helper method. Then, using the worker’s IP address, the port on which the task is listening, and the health check defined in the task’s definition, the manager can build a URL like `http://192.168.1.100:49847/health`. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)

##### Listing 9.7 The manager’s new `checkTaskHealth` method

```
func (m *Manager) checkTaskHealth(t task.Task) error {
    log.Printf("Calling health check for task %s: %s\n",
     t.ID, t.HealthCheck)
 
    w := m.TaskWorkerMap[t.ID]                                          #1
    hostPort := getHostPort(t.HostPorts)                                #2
    worker := strings.Split(w, ":")                                     #3
    url := fmt.Sprintf("http://%s:%s%s",
     worker[0], *hostPort, t.HealthCheck)                             #4
    log.Printf("Calling health check for task %s: %s\n", t.ID, url)
    resp, err := http.Get(url)                                          #5
    if err != nil {
        msg := fmt.Sprintf("Error connecting to health check %s", url)
        log.Println(msg)
        return errors.New(msg)                                          #6
    }
 
    if resp.StatusCode != http.StatusOK {                               #7
        msg := fmt.Sprintf("Error health check for task %s did not
         return 200\n", t.ID)
        log.Println(msg)
        return errors.New(msg)
    }
 
    log.Printf("Task %s health check response: %v\n", t.ID, resp.StatusCode)
 
    return nil
}
#1 Gets the worker where the task is running from the manager’s TaskWorkerMap
#2 Retrieves the port on which the task is listening
#3 Extracts the IP address from the string representation of the worker stored in the TaskWorkerMap
#4 Builds a URL to the health check using the worker’s IP address, the port on which the task is listening, and the health check endpoint defined in the task definition
#5 Calls the health check
#6 Handles connection errors
#7 Handles non-200 responses
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)The `getHostPort` method is a helper that returns the host port where the task is listening. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)

##### Listing 9.8 The `getHostPort` method

```
func getHostPort(ports nat.PortMap) *string {
   for k, _ := range ports {
       return &ports[k][0].HostPort
   }
   return nil
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)Now that our manager knows how to call individual task health checks, let’s create a new method that will use that knowledge to operate on all the tasks in our system. It’s important to note that we want the manager to check the health of tasks only in `Running` or `Failed` states. Tasks in `Pending` or `Scheduled` states are in the process of being started, so we don’t want to attempt calling their health checks at this point. And the `Completed` state is terminal, meaning the task has stopped normally and is in the expected state. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)The process we’ll use to check the health of individual tasks will involve iterating over the tasks in the manager’s `TaskDb`. If a task is in the `Running` state, it will call the task’s health check endpoint and attempt to restart the task if the health check fails. If a task is in the `Failed` state, there is no reason to call its health check, so we move on and attempt to restart the task. We can summarize this process like this:[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)

-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)If the task is in the `Running` state, call the manager’s `checkTaskHealth` method, which, in turn, will call the task’s health check endpoint.
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)If the task’s health check fails, attempt to restart the task.
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)If the task is in the `Failed` state, attempt to restart the task.

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)This process is coded as you see in the `doHealthChecks` method in listing 9.9. Notice that we are only attempting to restart failed tasks if their `RestartCount` field is less than `3`. We are arbitrarily choosing to only attempt to restart failed tasks three times. If we were writing a production-quality system, we would likely do something smarter and much more sophisticated. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)

##### Listing 9.9 The manager’s `doHealthChecks` method

```
func (m *Manager) doHealthChecks() {
   for _, t := range m.GetTasks() {
       if t.State == task.Running && t.RestartCount < 3 {
           err := m.checkTaskHealth(*t)
           if err != nil {
               if t.RestartCount < 3 {
                   m.restartTask(t)
               }
           }
       } else if t.State == task.Failed && t.RestartCount < 3 {
           m.restartTask(t)
       }
   }
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)The `doHealthChecks` method calls the `restartTask` method, which is responsible for restarting tasks that have failed, as shown in listing 9.10. Despite the number of lines involved, this code is fairly straightforward[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/). Because our manager is naively attempting to restart the task on the same worker where the task was originally scheduled, it looks up that worker in its `TaskWorkerMap` using the task’s `task.ID` field. Next, it changes the task’s state to `Scheduled` and increments the task’s `RestartCount`. Then it overwrites the existing task in the `TaskDb` datastore to ensure the manager has the correct state of the task. At this point, the rest of the code should look familiar. It creates a `task.TaskEvent`, adds the `task` to it, and then marshals the `TaskEvent` into JSON. Using the JSON-encoded `TaskEvent`, it sends a `POST` request to the worker’s API to restart the task. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)

##### Listing 9.10 The manager’s new `restartTask` method

```
func (m *Manager) restartTask(t *task.Task) {
    w := m.TaskWorkerMap[t.ID]                 #1
    t.State = task.Scheduled
    t.RestartCount++
    m.TaskDb[t.ID] = t                         #2
 
    te := task.TaskEvent{
        ID:        uuid.New(),
        State:     task.Running,
        Timestamp: time.Now(),
        Task:      *t,
    }
    data, err := json.Marshal(te)
    if err != nil {
        log.Printf("Unable to marshal task object: %v.", t)
        return
    }
 
    url := fmt.Sprintf("http://%s/tasks", w)
    resp, err := http.Post(url, "application/json", bytes.NewBuffer(data))
    if err != nil {
        log.Printf("Error connecting to %v: %v", w, err)
        m.Pending.Enqueue(t)
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
 
    newTask := task.Task{}
    err = d.Decode(&newTask)
    if err != nil {
        fmt.Printf("Error decoding response: %s\n", err.Error())
        return
    }
    log.Printf("%#v\n", t)
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)With the low-level details implemented, we can wrap the necessary coding for the manager by writing the `DoHealthChecks` method, as in the following listing. This method will be used to run the manager’s health checking functionality in a separate goroutine. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)

##### Listing 9.11 The `DoHealthChecks` method wrapping the `doHealthChecks` method

```
func (m *Manager) DoHealthChecks() {
   for {
       log.Println("Performing task health check")
       m.doHealthChecks()
       log.Println("Task health checks completed")
       log.Println("Sleeping for 60 seconds")
       time.Sleep(60 * time.Second)
   }
}
```

## [](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)9.5 Putting it all together

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)To test our code and see it work, we’ll need a task that implements a health check. Also, we’ll want a way to trigger it to fail so our manager will attempt to restart it. We can use the echo service mentioned at the beginning of the chapter for this purpose. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)To run it, use this command:

```bash
$ docker run -p 7777:7777 --name echo timboring/echo-server:latest
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)The echo service implements three endpoints. Calling the root endpoint `/` with a `POST` and a JSON-encoded request body will simply echo a JSON request body back in a response body:

```bash
$ curl -X POST http://localhost:7777/ -d '{"Msg": "hello world"}'
{"Msg":"hello world"}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)Calling the `/health` endpoint with a `GET` will return an empty body with a `200` `OK` response:[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)

```bash
$ curl -v http://localhost:7777/health
*   Trying 127.0.0.1:7777...
* Connected to localhost (127.0.0.1) port 7777 (#0)
> GET /health HTTP/1.1
> Host: localhost:7777
> User-Agent: curl/7.83.1
> Accept: */*
>
* Mark bundle as not supporting multiuse
< HTTP/1.1 200 OK
< Date: Sun, 12 Jun 2022 16:17:02 GMT
< Content-Length: 2
< Content-Type: text/plain; charset=utf-8
<
* Connection #0 to host localhost left intact
OK
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)Finally, calling the `/healthfail` endpoint with a `GET` will return an empty body with a `500` `Internal` `Server` `Error` response:[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)

```bash
$ curl -v http://localhost:7777/healthfail
*   Trying 127.0.0.1:7777...
* Connected to localhost (127.0.0.1) port 7777 (#0)
> GET /healthfail HTTP/1.1
> Host: localhost:7777
> User-Agent: curl/7.83.1
> Accept: */*
>
* Mark bundle as not supporting multiuse
< HTTP/1.1 500 Internal Server Error
< Date: Sun, 12 Jun 2022 16:17:45 GMT
< Content-Length: 21
< Content-Type: text/plain; charset=utf-8
<
* Connection #0 to host localhost left intact
Internal server error
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)At this point, we can start up our worker and manager locally. We only need to make two tweaks to the code in the `main.go` file from chapter 8. The first is to call the new `UpdateTasks` method on our worker. The second is to call the new `DoHealthChecks` method on our manager. The rest of the code remains the same and results in the worker and manager starting up. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)

##### Listing 9.12 Adding `UpdateTasks` and `DoHealthChecks` methods to `main.go`

```
func main() {
   w := worker.Worker{
       Queue: *queue.New(),
       Db:    make(map[uuid.UUID]*task.Task),
   }
   wapi := worker.Api{Address: whost, Port: wport, Worker: &w}

   go w.RunTasks()
   go w.CollectStats()
   go w.UpdateTasks()
   go wapi.Start()

   m := manager.New(workers)
   mapi := manager.Api{Address: mhost, Port: mport, Manager: m}

   go m.ProcessTasks()
   go m.UpdateTasks()
   go m.DoHealthChecks()

   mapi.Start()

}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)When we start up the worker and manager, we should see familiar output like this:

```
2022/06/12 12:25:52 Sleeping for 15 seconds
2022/06/12 12:25:52 Collecting stats
2022/06/12 12:25:52 Checking for task updates from workers
2022/06/12 12:25:52 Checking worker localhost:5555 for task updates
2022/06/12 12:25:52 No tasks to process currently.
2022/06/12 12:25:52 Sleeping for 10 seconds.
2022/06/12 12:25:52 Processing any tasks in the queue
2022/06/12 12:25:52 No work in the queue
2022/06/12 12:25:52 Sleeping for 10 seconds
2022/06/12 12:25:52 Performing task health check
2022/06/12 12:25:52 Task health checks completed
2022/06/12 12:25:52 Sleeping for 60 seconds
2022/06/12 12:25:52 Task updates completed
2022/06/12 12:25:52 Sleeping for 15 seconds
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)We can verify that the worker and manager are indeed working as expected by sending requests to their APIs:

```bash
# querying the worker API
$ curl localhost:5555/tasks
[]

# querying the manager API
$ curl localhost:5556/tasks
[]
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)As we’d expect, both the worker and manager return empty lists for their respective `/tasks` endpoints. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)Let’s create a task so the manager can start it up. To simplify the process, create a file called `task1.json`, and add the JSON in the following listing. We can store a task in JSON format in a file and pass the file to the `curl` command, thus saving us time and confusion. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)

##### Listing 9.13 Storing a task in a file

```json
{
   "ID": "a7aa1d44-08f6-443e-9378-f5884311019e",
   "State": 2,
   "Task": {
       "State": 1,
       "ID": "bb1d59ef-9fc1-4e4b-a44d-db571eeed203",
       "Name": "test-chapter-9.1",
       "Image": "timboring/echo-server:latest",
       "ExposedPorts": {
           "7777/tcp": {}
       },
       "PortBindings": {
           "7777/tcp": "7777"
       },
       "HealthCheck": "/health"
   }
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)Next, let’s make a `POST` request to the manager using this JSON as a request body:

```bash
$ curl -v -X POST localhost:5556/tasks -d @task1.json
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)When we submit the task to the manager, we should see the manager and worker going through their normal paces to create the task. Ultimately, we should see the task in a running state if we query the manager:

```bash
$ curl http://localhost:5556/tasks|jq
[
  {
    "ID": "bb1d59ef-9fc1-4e4b-a44d-db571eeed203",
    "ContainerID":
     "fbdcb43461134fc20cafdfcdadc4cc905571c386908b15428d2cba4fa09be270",
    "Name": "test-chapter-9.1",
    "State": 2,
    "Image": "timboring/echo-server:latest",
    "Cpu": 0,
    "Memory": 0,
    "Disk": 0,
    "ExposedPorts": {
      "7777/tcp": {}
    },
    "HostPorts": {
      "7777/tcp": [
        {
          "HostIp": "0.0.0.0",
          "HostPort": "49155"
        },
        {
          "HostIp": "::",
          "HostPort": "49154"
        }
      ]
    },
    "PortBindings": {
      "7777/tcp": "7777"
    },
    "RestartPolicy": "",
    "StartTime": "0001-01-01T00:00:00Z",
    "FinishTime": "0001-01-01T00:00:00Z",
    "HealthCheck": "/health",
    "RestartCount": 0
  }
]
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)And we should eventually see output from the manager showing it calling the task’s health check:

```
2022/06/12 13:17:13 Performing task health check
2022/06/12 13:17:13 Calling health check for task
 bb1d59ef-9fc1-4e4b-a44d-db571eeed203: /health
2022/06/12 13:17:13 Calling health check for task
 bb1d59ef-9fc1-4e4b-a44d-db571eeed203: http://localhost:49155/health
2022/06/12 13:17:13 Task bb1d59ef-9fc1-4e4b-a44d-db571eeed203
 health check response: 200
2022/06/12 13:17:13 Task health checks completed
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)This is good news. We can see that our health-checking strategy is working. Well, at least in the case of a healthy task! What happens in the case of an unhealthy one?

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)To see what happens if a task’s health check fails, let’s submit another task to the manager. This time, we’re going to set the task’s health check endpoint to `/healthfail`. The JSON definition for our second task includes a health check that will result in a non-`200` response.

##### Listing 9.14 The JSON definition for our second task

```json
{
   "ID": "6be4cb6b-61d1-40cb-bc7b-9cacefefa60c",
   "State": 2,
   "Task": {
       "State": 1,
       "ID": "21b23589-5d2d-4731-b5c9-a97e9832d021",
       "Name": "test-chapter-9.2",
       "Image": "timboring/echo-server:latest",
       "ExposedPorts": {
           "7777/tcp": {}
       },
       "PortBindings": {
           "7777/tcp": "7777"
       },
       "HealthCheck": "/healthfail"
   }
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)If we watch the output in the terminal where our worker and manager are running, we should eventually see the call to this task’s `/healthfail` endpoint return a non-`200` response:

```
2022/06/12 13:37:30 Calling health check for task
 21b23589-5d2d-4731-b5c9-a97e9832d021: /healthfail
2022/06/12 13:37:30 Calling health check for task
 21b23589-5d2d-4731-b5c9-a97e9832d021: http://localhost:49160/healthfail
2022/06/12 13:37:30 Error health check for task
 21b23589-5d2d-4731-b5c9-a97e9832d021 did not return 200
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)As a result of this health check failure, we should see the manager attempt to restart the task:

```
2022/06/12 13:37:30 Added task 21b23589-5d2d-4731-b5c9-a97e9832d021
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)This process should continue until the task has been restarted three times, after which the manager will stop trying to restart the task, thus leaving it in the `Running` state. We can see this by querying the manager’s API and looking at the task’s `State` and `RetryCount` fields:[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)

```json
{
    "ID": "21b23589-5d2d-4731-b5c9-a97e9832d021",
    "ContainerID":
     "acb37c0c2577461cae93c50b894eccfdbc363a6c51ea2255c8314cc35c91e702",
    "Name": "test-chapter-9.2",
    "State": 2,
    "Image": "timboring/echo-server:latest",
    // other fields omitted
    "RestartCount": 3
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)In addition to restarting tasks when their health check fails, this strategy also works in the case where a task dies. For example, we can simulate the situation of a task dying by stopping the task’s container manually using the `docker` `stop` command. Let’s do this for the first task we created, which should still be running:[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)

```
2022/06/12 14:14:08 Performing task health check
2022/06/12 14:14:08 Calling health check for task
 bb1d59ef-9fc1-4e4b-a44d-db571eeed203: /health
2022/06/12 14:14:08 Calling health check for task
 bb1d59ef-9fc1-4e4b-a44d-db571eeed203: http://localhost:49169/health
2022/06/12 14:14:08 Error connecting to health check
 http://localhost:49169/health
2022/06/12 14:14:08 Added task bb1d59ef-9fc1-4e4b-a44d-db571eeed203
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)We should then see the container running again:

```bash
$ docker ps
CONTAINER ID   IMAGE                          CREATED          STATUS
1d75e69fa804   timboring/echo-server:latest   36 seconds ago   Up 36 seconds
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)And if we query the manager’s API, we should see that the task has a `RestartCount` of `1`:[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)

```bash
$ curl http://localhost:5556/tasks|jq
[
  {
    "ID": "bb1d59ef-9fc1-4e4b-a44d-db571eeed203",
    "ContainerID":
     "1d75e69fa80431b39980ba605bccdb2e049d39d44afa32cd3471d3d987209bf3",
    "Name": "test-chapter-9.1",
    "State": 2,
    "Image": "timboring/echo-server:latest",
    // other fields omitted
    "RestartCount": 1
  }
]
```

## [](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)Summary

-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)Failures happen all the time, and the causes can be numerous.
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)Handling failures in an orchestration system is complex. We can implement task-level health checking as a strategy to handle a small number of failure scenarios.
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-9/)An orchestration system can automate the process of recovering from task failures up to a certain point. Past a certain point, however, the best it can do is provide useful debugging information that helps administrators and application owners troubleshoot the problem further. (Note that we did not do this for our orchestration system. If you’re curious, you can try to implement something like task logging.)

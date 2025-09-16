# Chapter 1. Introduction to Async

For years, software engineers have been spoiled by the relentless increase in hardware performance. Phrases like “just chuck more computing power at it” or “write time is more expensive than read time” have become popular one-liners when justifying using a slow algorithm, rushed approach, or slow programming language. However, at the time of this writing, multiple microprocessor manufacturers have reported that the semiconductor advancement has slowed since 2010, leading to the controversial statement from NVIDIA CEO Jensen Huang in 2022 that “Moore’s law is dead.” With the increased demand on software and increasing number of I/O network calls in systems such as microservices, we need to be more efficient with our resources.

This is where *async programming* comes in. With async programming, we do not need to add another core to the CPU to get performance gains. Instead, with async, we can effectively juggle multiple tasks on a single thread if there is some dead time in those tasks, such as waiting for a response from a server.

We live our lives in an async way. For instance, when we put the laundry into the washing machine, we do not sit still, doing nothing, until the machine has finished. Instead, we do other things. If we want our computer and programs to live an efficient life, we need to embrace async programming.

However, before we roll up our sleeves and dive into the weeds of async programming, we need to understand where this topic sits in the context of our computers. This chapter provides an overview of how threads and processes work, demonstrating the effectiveness of async programming in I/O operations.

After reading this chapter, you should understand what async programming is at a high level, without knowing the intricate details of an async program. You will also understand some basic concepts around threads and Rust; these concepts pop up in async programming due to async runtimes using threads to execute async tasks. You should be ready to explore the details of how async programs work in the following chapter, which focuses on more concrete examples of async programming. If you are familiar with processes, threads, and sharing data between them, feel free to skip this chapter. In [Chapter 2](https://learning.oreilly.com/library/view/async-rust/9781098149086/ch02.html#ch02), we cover async-specific concepts like futures, tasks, and how an async runtime executes tasks.

# What Is Async?

When we use a computer, we expect it to perform multiple tasks at the same time. Our experience would be pretty bad otherwise. However, think about all the tasks that a computer does at one time. As we write this book, we’ve clicked onto the activity monitor of our Apple M1 MacBook with eight cores. The laptop at one point was running 3,118 threads and 453 processes while only using 7% of the CPU.

Why are there so many processes and threads? The reason is that there are multiple running applications, open browser tabs, and other background processes. So how does the laptop keep all these threads and processes running at the same time? Here’s the thing: the computer is not running all 3,118 threads and 453 processes at the same time. The computer needs to schedule resources.

To demonstrate the need for scheduling resources, we can run some computationally expensive code to see how the activity monitor changes. To stress our CPU, we employ a recursion calculation like this Fibonacci number calculation:

```
fn fibonacci(n: u64) -> u64 {
    if n == 0 || n == 1 {
        return n;
    }
    fibonacci(n-1) + fibonacci(n-2)
}
```

We can then spawn eight threads and calculate the 4,000th number with the following code:

```
use std::thread;


fn main() {
    let mut threads = Vec::new();


    for i in 0..8 {
        let handle = thread::spawn(move || {
            let result = fibonacci(4000);
            println!("Thread {} result: {}", i, result);
        });
        threads.push(handle);
    }
    for handle in threads {
        handle.join().unwrap();
    }
}
```

If we then run this code, our CPU usage jumps to 99.95%, but our processes and threads do not change much. From this, we can deduce that most of these processes and threads are not using CPU resources all the time.

Modern CPU design is very nuanced. What we need to know is that a portion of CPU time is allocated when a thread or process is created. Our task in the created thread or process is then scheduled to run on one of the CPU cores. The process or thread runs until it is interrupted or yielded by the CPU voluntarily. Once the interruption has occurred, the CPU saves the state of the process or thread, and then the CPU switches to another process or thread.

Now that you understand at a high level how the CPU interacts with processes and threads, let’s see basic asynchronous code in action. The specifics of the asynchronous code are covered in the following chapter, so right now it’s not important to understand exactly how every line of code works but instead to appreciate how asynchronous code is utilizing CPU resources. First, we need the following dependencies:

```
[dependencies]
reqwest = "0.11.14"
tokio = { version = "1.26.0", features = ["full"] }
```

The Rust library *Tokio* is giving us a high-level abstraction of an async runtime, and *reqwest* enables us to make async HTTP requests. HTTP requests are a good, simple real-world example of using async because of the latency through the network when making a request to a server. The CPU doesn’t need to do anything when waiting on a network response. We can time how long it takes to make a simple HTTP request when using *Tokio* as the async runtime with this code:

```
use std::time::Instant;
use reqwest::Error;


#[tokio::main]
async fn main() -> Result<(), Error> {
    let url = "https://jsonplaceholder.typicode.com/posts/1";
    let start_time = Instant::now();

    let _ = reqwest::get(url).await?;

    let elapsed_time = start_time.elapsed();
    println!("Request took {} ms", elapsed_time.as_millis());

    Ok(())
}
```

Your time may vary, but at the time of this writing, it took roughly 140 ms to make the request. We can increase the number of requests by merely copying and pasting the request another three times, like so:

```
let first = reqwest::get(url);
let second = reqwest::get(url);
let third = reqwest::get(url);
let fourth = reqwest::get(url);

let first = first.await?;
let second = second.await?;
let third = third.await?;
let fourth = fourth.await?;
```

Running our program again gave us 656 ms. This makes sense, since we have increased the number of requests by four. If our time was less than 140 × 4, the result would not make sense, because the increase in total time would not be proportional to increasing the number of requests by four.

Note that although we are using async syntax, we have essentially just written synchronous code. This means we are executing each request after the previous one has finished. To make our code truly asynchronous, we can join the tasks together and have them running at the same time with the following code:

```
let (_, _, _, _) = tokio::join!(
    reqwest::get(url),
    reqwest::get(url),
    reqwest::get(url),
    reqwest::get(url),
);
```

Here we are using `tokio::join!`, a macro provided by *Tokio*. This macro enables multiple tasks to run concurrently. Unlike the previous example, where requests were awaited one after another, this approach allows them to progress simultaneously. As expected, running this code gives us a duration time of 137 ms. That’s a 4.7 times increase in the speed of our program without increasing the number of threads! This is essentially async programming. Using async programming, we can free up CPU resources by not blocking the CPU with tasks that can wait. See [Figure 1-1](https://learning.oreilly.com/library/view/async-rust/9781098149086/ch01.html#fig0101).

To help you understand the context around async programming, we need to briefly explore how processes and threads work. While we will not be using processes in asynchronous programming, it is important to understand how they work and communicate with each other in order to give us context for threads and asynchronous programming.

![A blocking synchronous timeline compared to an asynchronous timeline](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781098149086/files/assets/asru_0101.png)

###### Figure 1-1. Blocking synchronous timeline compared to asynchronous timeline

# Introduction to Processes

Standard async programming in Rust does not use multiprocessing; however, we can achieve async behavior by using multiprocessing. For this to work, our async systems must sit within a *process*.

Let’s think about the database PostgreSQL. It spawns a process for every connection made. These processes are single-threaded. If you have ever looked at Rust web frameworks, you might have noticed that the functions defining the endpoints of the Rust web servers are async functions, which means that processes are not spawned per connection for Rust servers. Instead, the Rust web server usually has a thread pool, and incoming HTTP requests are async tasks that are run on this thread pool. We cover how async tasks interact with a thread pool in [Chapter 3](https://learning.oreilly.com/library/view/async-rust/9781098149086/ch03.html#ch03). For now, let’s focus on where processes fit within async programming.

A *process* is an abstraction provided by an operating system that is executed by the CPU. Processes can be run by a program or application. The instructions of the program are loaded into memory, and the CPU executes these instructions in a sequence to perform a task or set of tasks. Processes are like threads for external inputs (like those from a user via a keyboard or data from other processes) and can generate output, as seen in [Figure 1-2](https://learning.oreilly.com/library/view/async-rust/9781098149086/ch01.html#fig0102).

![asru 0102](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781098149086/files/assets/asru_0102.png)

###### Figure 1-2. How processes relate to a program

Processes differ from threads in that each process consists of its own memory space, and this is an essential part of how the CPU is managed because it prevents data from being corrupted or bleeding over into other processes.

A process has its own ID called a *process ID* (PID), which can be monitored and controlled by the computer’s operating system. Many programmers have used PIDs to kill stalled or faulty programs by using the command `kill PID` without realizing exactly what this PID represents. A PID is a unique identifier that the OS assigns to a process. It allows the OS to keep track of all the resources associated with the process, such as memory usage and CPU time.

Going back to PostgreSQL, while we must acknowledge that historical reasons do play a role in spawning a process per connection, this approach has some advantages. If a process is spawned per connection, then we have true fault isolation and memory protection per connection. This means that a connection has zero chance of accessing or corrupting the memory of another connection. Spawning a process per connection also has no shared state and is a simpler concurrency model. However, shared state can lead to complications. For instance, if two async tasks representing individual connections each rely on data from shared memory, we must introduce synchronization primitives such as locks. These synchronization primitives are at risk of adding complications such as deadlocks, which can end up grinding all connections that are relying on that lock to a halt. These problems can be hard to debug, and we cover concepts such as testing for deadlocks in [Chapter 11](https://learning.oreilly.com/library/view/async-rust/9781098149086/ch11.html#ch11). The simpler concurrency model of processes reduces the risk of sync complications, but the risk is not completely eliminated; acquiring external locks such as file locks can still cause complications regardless of state isolation. The state isolation of processes can also protect against memory bugs. For instance, in a language like C or C++, we could have code that does not deallocate the memory afterwards, resulting in an ever-growing consumption of memory until the computer runs out of it. (We cover memory leaks in [Chapter 6](https://learning.oreilly.com/library/view/async-rust/9781098149086/ch06.html#ch06).) If certain functions that connections run have memory leaks, the memory can run out for the entire program. However, we can run processes with memory limits, isolating the worst offenders.

To illustrate how processes fit in relation to async programming in Rust, we can recreate the async nature of our four HTTP requests with the following layout:

```
├── connection
│   ├── Cargo.toml
│   ├── connection
│   └── src
│       └── main.rs
├── scripts
│   ├── prep.sh
│   └── run.sh
└── server
    ├── Cargo.toml
    ├── server
    └── src
        └── main.rs
```

Here, we call our server package *server_bin* and the connection package *connection_bin*. Our connection binary has the same *Tokio* and *reqwest* dependencies as in the previous section. In our connection *main.rs* file, we merely make a request and print out the result with the following code:

```
use reqwest::Error;

#[tokio::main]
async fn main() -> Result<(), Error> {
    let url = "https://jsonplaceholder.typicode.com/posts/1";
    let response = reqwest::get(url).await?;

    if response.status().is_success() {
        let body = response.text().await?;
        println!("{}", body);
    } else {
        println!(
            "Failed to get a valid response. Status: {}",
            response.status()
        );
    }
    Ok(())
}
```

For the server, we create a process that makes the HTTP request every time we run the binary with the following *server/main.rs* file:

```
use std::process::{Command, Output};

fn main() {
    let output: Output = Command::new("./connection_bin")
        .output()
        .expect("Failed to execute command");
    if output.status.success() {
        let stdout = String::from_utf8_lossy(&output.stdout);
        println!("Output: {}", stdout);
    } else {
        let stderr = String::from_utf8_lossy(&output.stderr);
        eprintln!("Error: {}", stderr);
    }
}
```

Here, we can see that our command is running the binary of the connection. We can also see that we can handle the output of a process. If the process exits with a `0`, then the process exited without any errors. If the process exits with `1`, then the process did error. Whatever the outcome, we serialize the output and print it. We now have to build out our *scripts/prep.sh* file, which has the following code:

```
#!/usr/bin/env bash

SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"
cd $SCRIPTPATH
cd ..
cd connection && cargo build --release && cd ..
cd server && cargo build --release && cd ..
cp connection/target/release/connection_bin ./
cp server/target/release/server_bin ./
```

Here, we are compiling the binaries and moving them into the root directory. We now need to code our *scripts/run.sh* to run four connections at the same time. First, we navigate to the root directory as follows:

```
#!/usr/bin/env bash

SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"
cd $SCRIPTPATH
cd ..
```

We then run all four processes in the background, getting the PIDs of each one:

```
./server_bin &
pid1=$!
./server_bin &
pid2=$!
./server_bin &
pid3=$!
./server_bin &
pid4=$!
```

We then wait for the results and print out the exit codes:

```
wait $pid1
exit_code1=$?
wait $pid2
exit_code2=$?
wait $pid3
exit_code3=$?
wait $pid4
exit_code4=$?
echo "Task 1 (PID $pid1) exited with code $exit_code1"
echo "Task 2 (PID $pid2) exited with code $exit_code2"
echo "Task 3 (PID $pid3) exited with code $exit_code3"
echo "Task 4 (PID $pid4) exited with code $exit_code4"
```

After running the prep script and timing the run script using the `time sh scripts/run.sh` command, we found that our time was 123 ms, which is just slightly quicker than our async example. This shows that we can achieve async behavior by waiting on processes. However, this is not a demonstration that processes are better. We will be using more resources because processes are more resource heavy. Our standard async program is one process with multiple threads. This could lead to some contention on scheduling async tasks by the CPU due to shared memory. However, processes are simple to schedule by the CPU because they are isolated.

Before we run off spawning processes for everything, we need to consider some drawbacks. There can be limits to the number of threads we can spawn in an OS, and spawning processes is more expensive and will not scale as well. Once we start using all our cores, the extra spawned processes will start to get blocked. We also must appreciate the number of moving parts; interprocess communication can be expensive because of the need for serialization. What is interesting is that we also had async code in our process, and this is a nice demonstration of where processes sit. In PostgreSQL, a connection is a process, but that process contains async code that runs the command and accesses data storage.

To reduce the number of moving parts, we could use *Tokio*’s async tasks to point to processes that we spin up:

```
let mut handles = vec![];
for _ in 0..4 {
    let handle = tokio::spawn(async {
        let output = Command::new("./connection_bin")
            .output()
            .await;
        match output {
            Ok(output) => {
                println!(
                    "Process completed with output: {}",
                    String::from_utf8_lossy(&output.stdout)
                );
                Ok(output.status.code().unwrap_or(-1))
            }
            Err(e) => {
                eprintln!("Failed to run process: {}", e);
                Err(e)
            }
        }
    });
    handles.push(handle);
}
```

We then handle the process outcomes:

```
let mut results = Vec::with_capacity(handles.len());
for handle in handles {
    results.push(handle.await.unwrap());
}
for (i, result) in results.into_iter().enumerate() {
    match result {
        Ok(exit_code) => println!(
            "Process {} exited with code {}",
            i + 1, exit_code
        ),
        Err(e) => eprintln!(
            "Process {} failed: {}",
            i + 1, e
        ),
    }
}
```

While this reduces the number of moving parts, we still have the scaling issues of processes combined with the overhead of having to serialize data between the process and our main program. Because Rust is memory safe and we can handle errors as values, the isolation benefits behind processes are not as strong. For instance, unless we are actively producing unsafe Rust code, we are not going to get a memory leak in one of our threads.

Remember what we want to do with asynchronous programming: We want to spin off lightweight, nonblocking tasks and wait for them to finish. In a lot of cases, we will want to get the data from those tasks and use them. We also want the option of sending the task to the async runtime with data. Threads seem like a much better choice over processes for asynchronous programming due to the ease of sharing data between threads. We will cover threads next.

# What Are Threads?

A *thread* of execution is the smallest sequence of programmed instructions that can be executed by the CPU. A thread can be independently managed by a scheduler. Inside a process, we can share memory across multiple threads ([Figure 1-3](https://learning.oreilly.com/library/view/async-rust/9781098149086/ch01.html#fig0103)).

![asru 0103](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781098149086/files/assets/asru_0103.png)

###### Figure 1-3. How threads relate to a process

While both threads and async tasks are managed by a scheduler, they are different. Threads can run at the same time on different CPU cores, while async tasks usually wait their turn to use the CPU. We will cover async tasks in much more detail in [Chapter 2](https://learning.oreilly.com/library/view/async-rust/9781098149086/ch02.html#ch02).

To spin up threads, we can revisit our Fibonacci number recursive function and spread the calculations of Fibonacci numbers over four threads. First, we need to import the following:

```
use std::time::Instant;
use std::thread;
```

We can then time how long it takes to calculate the 50th Fibonacci number in the `main` function:

```
let start = Instant::now();
let _ = fibonacci(50);
let duration = start.elapsed();
println!("fibonacci(50) in {:?}", duration);
```

Next, we can reset the timer and calculate the time taken to calculate four 50th Fibonacci numbers over four threads. We achieve the multithreading by iterating four times to spawn four threads and attach each `JoinHandle` into a vector:

```
let start = Instant::now();
let mut handles = vec![];
for _ in 0..4 {
    let handle = thread::spawn(|| {
        fibonacci(50)
    });
    handles.push(handle);
}
```

A `JoinHandle` allows you to wait for a thread to finish, pausing the program until that thread completes. Joining the thread means blocking the program until the thread is terminated. A `JoinHandle` implements the `Send` and `Sync` traits, which means that it can be sent between threads. However, a `JoinHandle` does not implement the `Clone` trait. This is because we need a unique `JoinHandle` for each thread. If there are multiple +JoinHandle+s for one thread, you can run the risk of multiple threads trying to join the running thread, leading to data races.

###### Note

If you have used other programming languages, you may have come across *green threads*. These threads are scheduled by something other than the operating system (for example, a runtime or a virtual machine). Rust originally implemented green threads before pulling them prior to version 1.  The main reason for removing them and moving to a native thread, with green threads in libraries, is that in Rust, threads and I/O operations are coupled, which forced native threads and green threads to have and maintain the same API. This resulted in various problems in using I/O operations and designating allocation. See the Rust [documentation on green threads](https://oreil.ly/ghxQr) for more information.
Note that while Rust itself does not implement green threads, runtimes like *Tokio* do.

Now that we have our vector of `JoinHandle`, we can wait for them to execute and then print the time taken:

```
for handle in handles {
    let _ = handle.join();
}
let duration = start.elapsed();
println!("4 threads fibonacci(50) took {:?}", duration);
```

Running our program gives the following output:

```
fibonacci(50) in 39.665599542s
4 threads fibonacci(50) took 42.601305333s
```

We can see that when using threads in Rust, multiple CPU-intensive tasks can be handled at the same time. Therefore, we can deduce that multiple threads can also handle waiting concurrently. Even though we do not use the results of the Fibonacci calculations, we could use the results of the threads in our main program if we wanted to. When we are calling a join on a `JoinHandle` in this example, we are returning a `Result<u64, Box<dyn Any + Send>>`. The `u64` is the result of the calculated Fibonacci number from the thread. The `Box<dyn Any + Send>>` is a dynamic trait object that provides flexibility in handling various types of errors. These error types need to be sent over, but there could be a whole host of reasons why a thread errors. However, this approach has some overhead too because we need dynamic downcasting and boxing, as we do not know the size at compile time.

Threads can also directly interact with each other over memory within the program. The last example of this chapter uses channels, but for now we can make do with an `Arc`, `Mutex`, and a `Condvar` to create the system depicted in [Figure 1-4](https://learning.oreilly.com/library/view/async-rust/9781098149086/ch01.html#fig0104).

![asru 0104](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781098149086/files/assets/asru_0104.png)

###### Figure 1-4. A `Condvar` alerting another thread of a change

Here, we’ll have two threads. One thread is going to update the `Condvar`, and the other thread is going to listen to the `Condvar` for updates and print out that there was an update to the file the moment the update occurred. Before we write any code, however, we need to establish the following structs:

ArcThis stands for *atomic reference counting*, meaning that `Arc` keeps count of the references to the variable that is wrapped in an `Arc`. So, if we were to define an `Arc<i32>` and then reference it over four threads, the reference count would increase to four. The `Arc<i32>` would only be dropped when all four threads had finished referencing it, resulting in the reference count being zero.

MutexRemember that Rust only allows us to have one mutable reference to a variable at any given time. A `Mutex` (*mutual exclusion*) is a smart pointer type that provides *interior mutability* by having the value inside the `Mutex`. This means that we can provide mutable access to a single variable over multiple threads. This is achieved by a thread acquiring the lock. When we acquire the lock, we get the single mutable reference to the value inside the `Mutex`. We perform a transaction and then give up the lock to allow other threads to perform a transaction. The lock ensures that only one thread will have access to the mutable reference at a time, ensuring that Rust’s rule of only one mutable reference at a time is not violated. Acquiring the lock requires some overhead, as we might have to wait until it is released.

CondvarShort for *conditional variable*, this allows our threads to sleep and be woken when a notification is sent through the `Condvar`. We cannot send variables through the `Condvar`, but multiple threads can subscribe to a single `Condvar`.

Now that we have covered what we are using, we can build our system by initially importing the following:

```
use std::sync::{Arc, Condvar, Mutex};
use std::thread;
use std::time::Duration;
use std::sync::atomic::AtomicBool;
use std::sync::atomic::Ordering::Relaxed;
```

Inside our `main` function, we can then define the data that we are going to share across our two threads:

```
let shared_data = Arc::new((Mutex::new(false), Condvar::new()));
let shared_data_clone = Arc::clone(&shared_data);
let STOP = Arc::new(AtomicBool::new(false));
let STOP_CLONE = Arc::clone(&STOP);
```

Here we have a tuple that is wrapped in `Arc`. Our boolean variable that is going to be updated is wrapped in a `Mutex`. We then clone our data package so both threads have access to the shared data. The `shared_data_clone` thread is passed to `background_thread`, while the original `shared_data` remains with the main thread, which later uses it in `updater_thread`. Without cloning, the ownership of `shared_data` would be moved to the first thread it’s passed to, and the main thread would lose access to it.

Now that our data is available, we can define our first thread:

```
let background_thread = thread::spawn(move || {
    let (lock, cvar) = &*shared_data_clone;
    let mut received_value = lock.lock().unwrap();
    while !STOP.load(Relaxed) {
        received_value = cvar.wait(received_value).unwrap();
        println!("Received value: {}", *received_value);
    }
});
```

Here we can see that we wait on the `Condvar` notification. At the point of waiting, the thread is said to be *parked*. This means that the thread is blocked and not executing. Once the notification comes in from the `Condvar`, the thread accesses the variable in the `Mutex` after being woken by the `Condvar`. We then print out the variable, and the thread goes back to sleep. We are relying on the `AtomicBool` being `false` for the loop to continue indefinitely. This enables us to stop the thread if needed.

###### Note

We are using `unwrap` a lot in the code. This keeps the code concise so we can focus on the main concepts around async, but remember that production code should have error handling. The only time using `unwrap()` might be acceptable is when locking a mutex because the only reason it would panic is if a thread previously panicked while holding the lock, which is called `lock poisoning`.

In the next thread, we only execute four iterations before completing the thread:

```
let updater_thread = thread::spawn(move || {
    let (lock, cvar) = &*shared_data;
    let values = [false, true, false, true];

    for i in 0..4 {
        let update_value = values[i as usize];
        println!("Updating value to {}...", update_value);
        *lock.lock().unwrap() = update_value;
        cvar.notify_one();
        thread::sleep(Duration::from_secs(4));
    }
    STOP_CLONE.store(true, Relaxed);
    println!("STOP has been updated");
    cvar.notify_one();
});
updater_thread.join().unwrap();
```

We update the value and then notify the other thread that the value has changed. We then block the main program until `updater_thread` has finished.

Notice that we have used the `Relaxed` term. It is critical to ensure that operations occur in a specific order to avoid data races and strange inconsistencies. This is where memory ordering comes into play. The `Relaxed` ordering, used with [AtomicBool](https://oreil.ly/yQIeb), ensures that the operations on the atomic variable are visible to all threads but does not enforce any particular order on the surrounding operations. This is sufficient for our example because we only need to check the value of `STOP` and don’t care about strict ordering of other operations.

Running the program gives us the following output:

```
Updating value to false...
Received value: false
Updating value to true...
Received value: true
Updating value to false...
Received value: false
Updating value to true...
Received value: true
```

Our updater thread is updating the value of the shared data and notifying our first thread which accesses it.

The values are consistent, which is what we want, although admittedly it’s a crude implementation of what we could describe as async behavior. The thread is stopping and waiting for updates. Adding multiple `Condvars` for `updater_thread` to cycle through and check would result in one thread keeping track of multiple tasks and acting on them when changed. While this will certainly spark a debate online on whether this is truly async behavior or not, we can certainly say that this is not an optimum or standard way of implementing async programming. However, we can see that threads are a key building block for async programming.
Async runtimes handle tasks in a way that allows multiple asynchronous operations to run concurrently within a single thread. This thread is usually separate from the main thread. Runtimes can also have multiple threads executing tasks. In the next section, we will use standard implementations of async code.

# Where Can We Utilize Async?

We have introduced you to asynchronous programming and demonstrated some of its benefits in the examples (such as multiple HTTP requests). These have been toy examples designed to show you the power of async. This section presents real-life uses of async and why you might want to include them in your next project.

Let’s first think about what we can use async for. Unsurprisingly, the main use cases involve operations that have a delay or potential delay in doing something or receiving something—for example, I/O calls to the filesystem or network requests. Async allows the program that calls these operations to continue without blocking, which could cause the program to hang and become less responsive.

I/O operations like writing files are considered slow compared to in-memory operations because they usually rely on external devices such as hard drives. Most hard drives still rely on mechanical parts that need to physically move, so they are slower than electronic operations in RAM or the CPU. In addition, the speed at which data can be transferred from the CPU to the device may be limited—for example, by a USB connection.

To put this into perspective, let’s compare the time scales involved:

Nanoseconds (ns)This is a billionth of a second (1/1,000,000,000 of a second). Operations within the CPU and memory typically happen in nanoseconds. For example, accessing data in RAM might take around 100 ns.

Milliseconds (ms)This is a thousandth of a second (1/1,000 of a second). I/O operations, like writing to a hard drive or sending data over a network, usually occur in milliseconds. For example, writing data to a traditional hard drive might take several milliseconds.

These differences might seem trivial, but in the world of computing, they are huge. A CPU can perform millions of operations in the time it takes for a single file to be opened. This is why I/O operations are often the bottleneck in a program’s performance.

At the time of this writing, async file reads are not actually sped up by async. This is because file I/O operations are still bound by disk performance, so the bottleneck is in the disk write and read speed rather than CPU. What async can do, however, is make sure that while your file I/O is occurring, your program can continue and is not blocked by these operations.

We will now work through an example using async for a file I/O program. Imagine that we need to keep track of changes to a file and perform an action when a change in the file has been detected.

## Using Async for File I/O

To track file changes, we need to have a loop in a thread that checks the metadata of the file and then feeds back to the main loop in the main thread when the file metadata changes, as depicted in [Figure 1-5](https://learning.oreilly.com/library/view/async-rust/9781098149086/ch01.html#fig0105).

![asru 0105](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781098149086/files/assets/asru_0105.png)

###### Figure 1-5. A system keeping track of changes in a file

We can do all manner of things after the change is detected, but for the purpose of this exercise, we will print the contents to the console. Before we start tackling the components in [Figure 1-5](https://learning.oreilly.com/library/view/async-rust/9781098149086/ch01.html#fig0105), we need to import the following structs and traits:

```
use std::path::PathBuf;
use tokio::fs::File as AsyncFile;
use tokio::io::AsyncReadExt;
use tokio::sync::watch;
use tokio::time::{sleep, Duration};
```

We will cover how these structs and traits are used as we go along. Referring back to [Figure 1-5](https://learning.oreilly.com/library/view/async-rust/9781098149086/ch01.html#fig0105), it makes sense to tackle the file operations first and the main loop later. Our simplest operation is reading the file with a function:

```
async fn read_file(filename: &str) -> Result<String, std::io::Error> {
    let mut file = AsyncFile::open(filename).await?;
    let mut contents = String::new();
    file.read_to_string(&mut contents).await?;
    Ok(contents)
}
```

We open the file and read the contents to a string, returning that string. However, note that at the time of this writing, the standard implementation of async file reading is not async. Instead, it is blocking, so the file open operation is not truly async. The inconsistency of async file reading comes down to the file API that the OS supports. For instance, if you have Linux with a kernel version of 5.10 or higher, you can use the *Tokio-uring* crate that will enable true asynchronous I/O calls to the file API. However, for now, our function does the job we need.

We can now move on to our loop that periodically checks the metadata of our file:

```
async fn watch_file_changes(tx: watch::Sender<bool>) {
    let path = PathBuf::from("data.txt"); 

    let mut last_modified = None; 
    loop { 
        if let Ok(metadata) = path.metadata() {
            let modified = metadata.modified().unwrap(); 

            if last_modified != Some(modified) { 
                last_modified = Some(modified);
                let _ = tx.send(());
            }
        }
        sleep(Duration::from_millis(100)).await; 
    }
}
```

We can see that our function is an async function that carries out the following steps:

![1](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781098149086/files/assets/1.png)

We get the path to the file that we are checking.

![2](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781098149086/files/assets/2.png)

We set the last modified time to none, as we have not checked the file yet.

![3](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781098149086/files/assets/3.png)

We then have an infinite loop.

![4](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781098149086/files/assets/4.png)

In that loop, we extract the time that the file was last modified.

![5](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781098149086/files/assets/5.png)

If the extracted timestamp is not the same as our cached timestamp, we then update our cached timestamp and send a message through a channel using the sender that we passed into our function. This message then alerts our main loop that the file has been updated.

We ignore the result of `tx.send(())` because the only error  that could occur is if the receiver is no longer listening. In this case, there’s nothing more our function needs to do, so it’s safe to ignore the result.

![6](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781098149086/files/assets/6.png)

For each iteration, we sleep a short time just so that we are not constantly hitting the file that we are checking on.

###### Note

If we use a *Tokio* thread to run this function, the *Tokio* runtime will be able to switch context and execute another thread in the same process. If we use the standard library’s `sleep` function, the thread will block. This is because the standard library’s `sleep` will not send the task to the *Tokio* executor. We will go over executors in [Chapter 3](https://learning.oreilly.com/library/view/async-rust/9781098149086/ch03.html#ch03).

Now that our first loop is defined, we can move on to the loop that is run in `main`. At this point, if you know how to spin up *Tokio* threads and channels, you could try to write the `main` function yourself.

If you did attempt to write your own `main` function, hopefully it looks similar to the following:

```
#[tokio::main]
async fn main() {
    let (tx, mut rx) = watch::channel(false); 

    tokio::spawn(watch_file_changes(tx)); 

    loop { 
        // Wait for a change in the file
        let _ = rx.changed().await; 

        // Read the file and print its contents to the console
        if let Ok(contents) = read_file("data.txt").await { 
            println!("{}", contents);
        }
    }
}
```

Our `main` function carries out the following steps:

![1](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781098149086/files/assets/1.png)

We create a channel that is a single-producer, multi-consumer channel that only retains the last set value.
This channel allows one producer to send messages to multiple consumers, enabling concurrent data distribution.

![2](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781098149086/files/assets/2.png)

We pass the transmitter of that channel into our file-watching function, which is being run in a *Tokio* thread that we spin off.

![3](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781098149086/files/assets/3.png)

Now that our file-watching loop is running, we move onto our loop that holds until the value of the channel is changed.

![4](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781098149086/files/assets/4.png)

Because we do not care about the value coming from the channel, we denote the variable assignment as an underscore. Our main loop will stay there until a change occurs in the value inside the channel.

![5](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781098149086/files/assets/5.png)

Once the value inside the channel changes due to the metadata of the file changing, the rest of the loop interaction executes, reading the file and printing out the contents.

Before we run this, we need a *data.txt* file in the root of our project, next to our *Cargo.toml*. We can then run the system, open the *data.txt* file in an IDE, and type something into the file. Once you save the file, you will get its contents printed out in the console!

Now that we have used async programming locally, we can go back to implementing async programming with networks.

## Improving HTTP Request Performance with Async

I/O operations concern not just reading and writing files but also getting information from an API, executing operations on a database, or receiving information from a mouse or keyboard. What ties them together is that these operations are slower than the in-memory operations that can be performed in RAM. Async allows the program to continue without being blocked by the ongoing operation. Other tasks can be executed while we await the async operation.

In the following example, let’s imagine a user has logged into a website, and we want to display some data along with the time since that user’s login. To fetch the data, we’ll be using an external API that provides a specific delay. We need to process this data once it’s received, so we’ll define a `Response` struct and annotate it with the `Deserialize` trait to enable deserialization of the API data into a usable object.

To make the API calls, we’ll use the *reqwest* package. Since we’ll be working with JSON data, we’ll enable the JSON feature of *reqwest* by specifying `features=["json"]` in the dependency configuration. This allows us to conveniently handle JSON data when making API requests and processing the responses.

We need to add these dependencies to our *Cargo.toml*:

```
[dependencies]
tokio = { version = "1", features = ["full"] }
reqwest = { version = "0.11", features = ["json"] }
serde = { version = "1.0", features = ["derive"] }
serde_json = "1.0"
```

Next we import the libraries we need and define the `Response` struct:

```
use reqwest::Error;
use serde::Deserialize;
use tokio::time::sleep;
use std::time::Duration;
use std::time::Instant;
use serde_json;

#[derive(Deserialize, Debug)]
struct Response {
    url: String,
    args: serde_json::Value,
}
```

We now implement the `fetch_data` function. When called, it sends a GET request to *[https://httpbin.org/delay/](https://httpbin.org/delay/)*, which will return a response after a specified number of seconds. In our example, we set the delay to 5 seconds to emphasize the importance of designing a program capable of handling delays effectively in real-world scenarios:

```
async fn fetch_data(seconds: u64) -> Result<Response, Error> {
    let request_url = format!("https://httpbin.org/delay/{}", seconds);
    let response = reqwest::get(&request_url).await?;
    let delayed_response: Response = response.json().await?;
    Ok(delayed_response)
}
```

While the data is being fetched, we create a function that calculates the time since the user logged in. This would usually require a database check, but we will simulate the time it takes to check this by setting a sleep for 1 second. This simplifies the example so we do not need to get into database setups:

```
async fn calculate_last_login() {
    sleep(Duration::from_secs(1)).await;
    println!("Logged in 2 days ago");
}
```

Now we put the code together:

```
#[tokio::main]
async fn main() -> Result<(), Error> {
    let start_time = Instant::now();
    let data = fetch_data(5);
    let time_since = calculate_last_login();
    let (posts, _) = tokio::join!(
        data, time_since
    );
    let duration = start_time.elapsed();
    println!("Fetched {:?}", posts);
    println!("Time taken: {:?}", duration);
    Ok(())
}
```

Let’s examine the output:

```
Fetched Ok(Response { url: "https://httpbin.org/delay/5", args: Object {} })
Time taken: 5.494735083s
```

In the `main` function, we initiate the API call by using the `fetch_data` function before calling the `calculate_last_login` function. The API request is designed to take 5 seconds to return a response. Since `fetch_data` is an asynchronous function, it is executed in a nonblocking manner, allowing the program to continue its execution. As a result, a `calculate_last_login` is executed, and its output is printed to the terminal first. After the 5-second delay, `fetch_data` completes, and its result is returned and printed.

Unlike our initial HTTP request example, this demonstrates how asynchronous programming allows concurrent execution of tasks without blocking the program’s flow, resulting in network requests completing out of order. Therefore, we can use async for multiple network requests, as long as we `await` each request in the order that we need the data.

# Summary

In this chapter we introduced async programming and how it relates to the computer system in terms of threads and processes. We then covered basic high-level interactions with threads and processes to demonstrate that threads can be useful in async programming. We then explored basic high-level async programming, improving the performance of multiple HTTP calls by sending more requests while waiting for other requests to respond. We also used async principles to keep track of file changes.

We hope that this chapter has demonstrated that async is a powerful tool for juggling multiple tasks simultaneously that do not need constant CPU time. Therefore, async enables us to have one thread handling multiple tasks at the same time. Now that you understand where async programming sits in the context of a computer system, we will explore basic async programming concepts in [Chapter 2](https://learning.oreilly.com/library/view/async-rust/9781098149086/ch02.html#ch02).

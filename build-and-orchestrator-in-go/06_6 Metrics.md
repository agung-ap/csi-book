# [](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)6 Metrics

### This chapter covers

- Explaining why the worker needs to collect metrics
- Defining the metrics
- Creating a process to collect metrics
- Implementing a handler on the existing API

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)Imagine you’re the host at a busy restaurant on a Friday night. You have six servers waiting on customers sitting at tables spread across the room. Each customer at each of those tables has different requirements. One customer might be there to have drinks and appetizers with a group of friends they haven’t seen in a while. Another customer might be there for a full dinner, complete with an appetizer and dessert. Yet another customer might have strict dietary requirements and only eat plant-based food.

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)Now a new customer walks in. It’s a family of four: two adults and two teenage children. Where do you seat them? Do you place them at the table in the section being served by John, who already has three tables with four customers each? Do you place them at the table in Jill’s section, which has six tables with a single customer each? Or do you place them in Willie’s section, which has a single table with three customers?

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)This scenario is exactly what the manager in an orchestration system deals with. Instead of six servers waiting on tables, you have six machines. Instead of customers, you have tasks, and instead of being hungry and wanting food and drinks, the tasks want computing resources like CPU, memory, and disk. The manager’s job in an orchestration system, like the host in the restaurant, is to place incoming tasks on the best worker machine that can meet the task’s resource needs.

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)For the manager to do its job, however, it needs metrics that reflect how much work a worker is already doing. Those metrics are provided by the worker.

## [](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)6.1 What metrics should we collect?

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)Before we dive deeper into metrics, it’s good to refresh our memory about the worker and its components at a higher level. As you can see in figure 6.1, the two components that we’ll be dealing with are the `API` and `Metrics`. In previous chapters, we covered the `Task` `DB`, `Task` `Queue`, and `Runtime` components. In the last chapter, we covered the API, which resulted in building an API server that wraps the worker’s lower-level operations for starting and stopping tasks. Now we want to dig deeper into the `Metrics` component, which will expose metrics on the same API. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)

![Figure 6.1 Remembering the big picture of the worker’s components](https://drek4537l1klr.cloudfront.net/boring/Figures/06-01.png)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)For a worker to tell a manager how much work it’s currently doing, what metrics will paint a reasonably accurate picture? Remember, we’re not building a production-ready orchestrator. Systems like Borg, Kubernetes, and Nomad will have better metrics, both in quantity and quality, than will our system. That’s okay. We’re trying to understand how an orchestration system works at a fundamental level, not replace existing systems.

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)In thinking about these metrics, let’s look back at listing 3.6, in which we defined the `Task` struct. Three fields in that struct are relevant to this discussion: `CPU`, `Memory`, and `Disk`. These fields represent how much CPU, memory, and disk space a task needs to perform its work. The values will be specified by humans like you and me when we submit our tasks to the system. If our task will be doing a lot of heavy computation, maybe it will need lots of CPU and memory. If our task uses a Docker image that is particularly large for some reason, we may want to specify an amount that provides a little overhead so there is room for the worker to download the image when it starts the task:[](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)

```
type Task struct {
   // prior fields not listed

   Cpu           float64
   Memory        int64
   Disk          int64

   // following fields not listed
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)If these are the resources that a user will specify when it submits a task to the system, then it makes sense that we should collect metrics about these resources from each of the workers. In particular, we’re interested in metrics about the following:

-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)CPU usage (as a percentage)
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)Total memory
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)Available memory
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)Total disk space
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)Available disk space [](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)

## [](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)6.2 Metrics available from the /proc filesystem

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)Now that we’ve identified the metrics we want to collect, let’s talk about how we’re going to collect them. On Linux systems, there is a pseudo-filesystem named `/proc`, which contains a range of information about the state of the system. A deep discussion about the `/proc` filesystem is beyond the scope of this book; if you’re interested in more details, there are good sources that cover the topic. For our purposes, it’s enough to understand that `/proc` is a special filesystem that is part of the Linux operating system and holds a wealth of information, including information about the state of the system’s CPU, memory, and disk resources.

##### [](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)More info about /proc

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)If you’re interested in more information about the `/proc` filesystem, there are many resources available on the web. Here are a couple to get started:

-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)[https://tldp.org/LDP/sag/html/proc-fs.html](https://tldp.org/LDP/sag/html/proc-fs.html)
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)[http://mng.bz/27do](http://mng.bz/27do)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)The nice thing about `/proc` is that it appears like any other filesystem, which means users can interact with it the same way they interact with other normal filesystems. Items in `/proc` appear as files, which means standard tools like `ls` and `cat` can be used on them.

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)The files in the `/proc` filesystem that we’re going to work with are as follows:

-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)`/proc/stat`—Contains information about processes running on the system
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)`/proc/meminfo`—Contains information about memory usage
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)`/proc/loadavg`—Contains information about the system’s load average

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)These files are the source of data that you see in many Linux commands like `ps`, `stat`, and `top`.

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)To get a sense of the data contained in these files, use the `cat` command to poke around in them. For example, running the command `cat/proc/stat` on my laptop (which is running Manjaro Linux), I see a bunch of data about each of my CPUs. According to the `proc` man page (see `man` `5` `proc`), each line contains 10 values, which represent the amount of time spent in various states. Those states are

-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)`user`—Time spent in user mode
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)`nice`—Time spent in user mode with low priority (nice)
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)`system`—Time spent in system mode
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)`idle`—Time spent in the idle task
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)`iowait`—Time waiting for I/O to complete
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)`irq`—Time servicing interrupts
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)`softirq`—Time servicing softirqs
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)`steal`—Stolen time, which is the time spent in other operating systems when running in a virtualized environment
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)`guest`—Time spent running a virtual CPU for guest operating systems under the control of the Linux kernel
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)`guest_nice`—Time spent running a niced guest

##### Listing 6.1 Using `cat` to look at the `/proc/stat` file

```bash
$ cat /proc/stat
cpu  724661 181 374910 105390121 4468 59434 23083 0 0 0   #1
cpu0 59580 33 29642 8786508 191 3560 2244 0 0 0           #2
cpu1 60502 3 31300 8779359 150 9016 2729 0 0 0
cpu2 58574 7 32002 8785331 139 3688 3159 0 0 0
cpu3 59564 9 30935 8787000 137 3259 2017 0 0 0
cpu4 59555 6 29208 8786670 369 3312 1950 0 0 0
cpu5 63148 16 37486 8755311 430 16914 2993 0 0 0
cpu6 60653 76 31349 8780196 483 4168 2040 0 0 0
cpu7 62622 2 33386 8781129 533 3402 1325 0 0 0
cpu8 60286 1 31729 8783928 542 3175 1219 0 0 0
cpu9 59229 2 29664 8787395 571 3038 1118 0 0 0
cpu10 59550 1 28925 8789436 468 2945 1100 0 0 0
cpu11 61392 18 29278 8787854 449 2952 1184 0 0 0
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)Running the command `cat/proc/meminfo` shows data about the memory being used by my system. This data is used by commands like `free`. For our purposes, we will focus on two values provided by `/proc/meminfo` (see `/proc/meminfo` in `man` `5` `proc` for more details):

-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)`MemTotal`—Total usable RAM (i.e., physical RAM minus a few reserved bits and the kernel binary code)
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)`MemAvailable`—An estimate of how much memory is available for starting new applications without swapping

##### Listing 6.2 Using `cat` to look at the `/proc/meminfo` file

```bash
$ cat /proc/meminfo
MemTotal:       32488372 kB
MemFree:        21697264 kB
MemAvailable:   25975132 kB
Buffers:          512724 kB
Cached:          5829084 kB
SwapCached:            0 kB
Active:          1978056 kB
Inactive:        6165696 kB
Active(anon):      18368 kB
Inactive(anon):  3766080 kB
Active(file):    1959688 kB
Inactive(file):  2399616 kB
Unevictable:     1836208 kB
Mlocked:              32 kB
SwapTotal:             0 kB
SwapFree:              0 kB
Dirty:                 0 kB
[additional data truncated]
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)Running the command `cat/proc/loadavg` shows data about the system’s load average (see listing 6.3). The first three fields in the output should look familiar, as they are the same as what you see when you run the `uptime` command. These numbers represent the number of jobs in the run queue (state `R`) or waiting for disk I/O averaged over 1, 5, and 15 minutes. The fourth field contains two values separated by a slash (i.e., this is not a fraction): the first value is the number of currently runnable kernel processes or threads, and the second value is the number of kernel processes and threads that currently exist on the system (see `/proc/loadavg` in `man` `5` `proc`).

##### Listing 6.3 Using `cat` to look at the `/proc/loadavg` file

```bash
$ cat /proc/loadavg
0.14 0.16 0.18 1/1787 176550
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)While we will use the `/proc` filesystem for CPU and memory metrics, we won’t use it to gather disk metrics. We could use it, for there is the `/proc/diskstats` file. But we’re going to collect disk metrics a different way, which we’ll talk more about in a minute.

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)Since the metrics we’re interested in are available from the `/proc` filesystem, we could write our own code to interact with `/proc` and pull out the data we need. We’re not, however, going to take that route. Instead, we’re going to use a third-party library called `goprocinfo`.

## [](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)6.3 Collecting metrics with goprocinfo

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)The `goprocinfo` library ([https://github.com/c9s/goprocinfo](https://github.com/c9s/goprocinfo)) provides a range of types that allow us to interact with the `/proc` filesystem. For our purposes, we will focus on four types that will greatly simplify our work. They are as follows:[](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)

-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)`LoadAvg` ([http://mng.bz/Rm0R](http://mng.bz/Rm0R)), which provides the `ReadLoadAvg()` method and makes available the data from `/proc/loadavg`
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)`CpuStat` ([http://mng.bz/ZRDN](http://mng.bz/ZRDN)), which provides the `ReadStat()` method and makes available the data from `/proc/stat`
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)`MemInfo` ([http://mng.bz/A8me](http://mng.bz/A8me)), which provides the `ReadMemInfo()` method and makes available the data from `/proc/meminfo`
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)`Disk` ([http://mng.bz/PRD8](http://mng.bz/PRD8)), which provides the `ReadDisk()` method and makes available disk-related data using the `syscall` package from Go’s standard library

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)We won’t use every piece of data contained in each of these types, as we will see shortly.

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)To make it easy to use these metrics, let’s create a wrapper around them. We’ll start by adding the `Stats` struct you see in listing 6.4 into the `stats.go` `file` under the worker. This wrapper type contains five fields that will provide us with everything we need. The `MemStats` field will hold all the memory-related data we need and will be a pointer to the `MemInfo` type from `goprocinfo`. The `DiskStats` field will hold all the necessary disk-related data and will be a pointer to `goprocinfo`’s `Disk` type. The `CpuStats` field will contain all the CPU-related data and will be a pointer to `goprocinfo`’s `CPUStat` type. Finally, the `LoadStats` field will hold the relevant load-related data and will be a pointer to `goprocinfo`’s `LoadAvg` type. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)

##### Listing 6.4 The `Stats` type we’ll use to hold all the worker’s metrics

```
type Stats struct {
   MemStats  *linux.MemInfo
   DiskStats *linux.Disk
   CpuStats  *linux.CPUStat
   LoadStats *linux.LoadAvg
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)Now that we have defined our `Stats` type, let’s take a step back and think about the kinds of metrics that might be useful. Starting with memory, what might we be interested in? It’d be good to know how much total memory the worker has. Knowing how much memory is available for new programs would also probably be useful. It’d also be good to know how much memory is being used. Similarly, it’d be useful to know how much memory is being used as a percentage of total memory. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)With these memory metrics identified, let’s add some helper methods to the `Stats` type that will make it quick and easy to get this data. We’ll start with a method named `MemTotalKb`, seen in the next listing. This method simply returns the value of the `MemStats.MemTotal` field. We add the suffix `Kb` to the method name as a quick reminder of the units being used. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)

##### Listing 6.5 The `MemTotalKb()` helper method

```
func (s *Stats) MemTotalKb() uint64 {
   return s.MemStats.MemTotal
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)Next, let’s add the `MemAvailableKb` method, as seen in the next listing. Like `MemTotalKb`, it simply returns the value from a field in the `MemStats` field—in this case, `MemAvailable`. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)

##### Listing 6.6 The `MemAvailableKb()` helper method

```
func (s *Stats) MemAvailableKb() uint64 {
   return s.MemStats.MemAvailable
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)The `MemTotalKb` and `MemAvailable` methods let us figure out the last two memory-related metrics we identified: how much memory is being used as an absolute value and as a percentage of total memory. These metrics are provided by the `MemUsedKb` and `MemUsedPercent` methods in the following listing. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)

##### Listing 6.7 The `MemUsedKb()` and `MemUsedPercent()` helper methods

```
func (s *Stats) MemUsedKb() uint64 {
   return s.MemStats.MemTotal - s.MemStats.MemAvailable
}

func (s *Stats) MemUsedPercent() uint64 {
   return s.MemStats.MemAvailable / s.MemStats.MemTotal
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)Now let’s turn our attention to disk-related metrics. Similar to our memory metrics, it’d be good to know how much total disk is available on a worker machine, how much is free, and how much is being used. Unlike the memory-related methods, our disk-related methods won’t need to perform any calculations. The data is provided to us directly from `goprocinfo`’s `Disk` type[](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/). So let’s create the `DiskTotal`[](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/), `DiskFree`[](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/), and `DiskUsed`[](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/) methods, as shown in the following listing.

##### Listing 6.8 Helper methods for disk-related metrics

```
func (s *Stats) DiskTotal() uint64 {
   return s.DiskStats.All
}
func (s *Stats) DiskFree() uint64 {
   return s.DiskStats.Free
}

func (s *Stats) DiskUsed() uint64 {
   return s.DiskStats.Used
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)Finally, let’s talk about CPU-related metrics. The two most commonly used metrics are *load average* and *usage*. As we mentioned earlier, load average can be seen in the output of the `uptime` command, which comes from `/proc/loadavg`:[](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)

```bash
$ uptime
14:38:18 up 6 days, 22:39,  2 users,  load average: 0.43, 0.32, 0.33

$ cat /proc/loadavg
0.43 0.32 0.33 1/2462 865995
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)For CPU usage, however, the story is slightly more complicated. When discussing CPU usage, we typically talk in terms of percentages. For example, on my laptop, the CPU usage is currently 2%. But what does that mean?

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)As we discussed previously, on a Linux operating system, a CPU spends its time in various states. Moreover, we can see how much time our CPU(s) are spending in each of the states (`user`, `nice`, `system`, `idle`, etc.) by looking at `/proc/stat`. Knowing how much time our CPUs are spending in these individual states is nice, but it doesn’t translate into that single percentage we use when we say, “The CPU percentage is 2%.”

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)Unfortunately, the `CPUStat` type provided by the `goprocinfo` library doesn’t provide us with any useful helper methods to calculate the CPU usage; it simply provides us with the `CPUStat` type:[](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)

```
type CPUStat struct {
   Id        string `json:"id"`
   User      uint64 `json:"user"`
   Nice      uint64 `json:"nice"`
   System    uint64 `json:"system"`
   Idle      uint64 `json:"idle"`
   IOWait    uint64 `json:"iowait"`
   IRQ       uint64 `json:"irq"`
   SoftIRQ   uint64 `json:"softirq"`
   Steal     uint64 `json:"steal"`
   Guest     uint64 `json:"guest"`
   GuestNice uint64 `json:"guest_nice"`
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)So it is up to us to calculate this percentage ourselves. Luckily, we don’t have to do too much work because this problem has been discussed in a StackOverflow post titled “Accurate Calculation of CPU Usage Given in Percentage in Linux” ([http://mng.bz/ xj17](http://mng.bz/xj17)). According to this post, the general algorithm for performing this calculation is

1.  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)Sum the values for the idle states.
1.  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)Sum the values for the non-idle states.
1.  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)Sum the total of idle and non-idle states.
1.  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)Subtract the idle from the total and divide the result by the total.

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)Thus, we can code this algorithm as in the following listing.

##### Listing 6.9 Using the `CpuUsage()` method to get CPU usage as a percentage

```
func (s *Stats) CpuUsage() float64 {
   idle := s.CpuStats.Idle + s.CpuStats.IOWait
   nonIdle := s.CpuStats.User + s.CpuStats.Nice + s.CpuStats.System +
       s.CpuStats.IRQ + s.CpuStats.SoftIRQ + s.CpuStats.Steal
   total := idle + nonIdle


   if total == 0 {
       return 0.00
   }

   return (float64(total) - float64(idle)) / float64(total)
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)At this point, we have laid the foundation for gathering metrics that reflect the amount of work an individual worker is performing. All that is left now is to wrap up our work into a few functions that will return a fully populated `Stats` type that we can use in the worker’s API. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)The first of these functions is the `GetStats()` function seen in listing 6.10. This function sets the fields `MemStats`, `DiskStats`, `CpuStats`, and `LoadStats` in the `Stats` struct by calling the appropriate helper functions. Thus, it populates an instance of the `Stats` type and returns a pointer to the caller. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)

##### Listing 6.10 The `GetStats()` function

```
func GetStats() *Stats {
   return &Stats{
       MemStats:  GetMemoryInfo(),
       DiskStats: GetDiskInfo(),
       CpuStats:  GetCpuStats(),
       LoadStats: GetLoadAvg(),
   }
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)Each of the helper functions used in the `GetStats` function takes a similar format. It starts by calling the relevant function from the `goprocinfo` library. It then checks whether any errors were returned from the function call. And finally, it returns the data in the relevant struct. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)It’s worth noting that if there is an error in calling the relevant `goprocinfo` function, we simply print an error message and return a pointer to the appropriate type (e.g., `&linux.MemInfo{}`), as in listing 6.11. The returned type will be populated with the appropriate zero value (i.e., the empty string `""` for strings and `0` for numbers). Helper functions return metrics from the `/proc` filesystem, with the exception of the `GetDiskInfo()` function. Under the hood, it uses the `syscall` package from Go’s standard library. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)

##### Listing 6.11 Helper functions used by `GetStats()`

```
func GetMemoryInfo() *linux.MemInfo {
   memstats, err := linux.ReadMemInfo("/proc/meminfo")
   if err != nil {
       log.Printf("Error reading from /proc/meminfo")
       return &linux.MemInfo{}
   }

   return memstats
}

// GetDiskInfo See https://godoc.org/github.com/c9s/goprocinfo/linux#Disk
func GetDiskInfo() *linux.Disk {
   diskstats, err := linux.ReadDisk("/")
   if err != nil {
       log.Printf("Error reading from /")
       return &linux.Disk{}
   }

   return diskstats
}

// GetCpuInfo See https://godoc.org/github.com/c9s/goprocinfo/linux#CPUStat
func GetCpuStats() *linux.CPUStat {
   stats, err := linux.ReadStat("/proc/stat")
   if err != nil {
       log.Printf("Error reading from /proc/stat")
       return &linux.CPUStat{}
   }

   return &stats.CPUStatAll
}

// GetLoadAvg See https://godoc.org/github.com/c9s/goprocinfo/linux#LoadAvg
func GetLoadAvg() *linux.LoadAvg {
   loadavg, err := linux.ReadLoadAvg("/proc/loadavg")
   if err != nil {
       log.Printf("Error reading from /proc/loadavg")
       return &linux.LoadAvg{}
   }

   return loadavg
}
```

## [](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)6.4 Exposing the metrics on the API

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)Now that we’ve done all the hard work, there are only three things left to do to expose the worker’s metrics on its API:[](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)

-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)Add a method to the worker to regularly collect metrics
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)Add a handler method to the API
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)Add a `/stats` route to the API

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)To regularly collect our metrics, let’s add a method called `CollectStats` to our worker in the `worker.go` file. This method, seen in listing 6.12, uses an infinite loop, inside of which we call the `GetStats()` function we created earlier. Note that we also set the worker’s `TaskCount` field. Finally, we sleep for 15 seconds. Why sleep for fifteen seconds? This is an arbitrary decision that is mainly intended to slow down how frequently our system is performing actions so that we humans can observe what is going on. In a real production system, where users might be submitting tens, hundreds, or even thousands of tasks per minute, we’d want to collect metrics in a more real-time fashion. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)

##### Listing 6.12 The worker’s new `CollectStats()` method

```
func (w *Worker) CollectStats() {
   for {
       log.Println("Collecting stats")
       w.Stats = GetStats()
       w.Stats.TaskCount = w.TaskCount
       time.Sleep(15 * time.Second)
   }
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)Next, let’s add the new handler method, called `GetStatsHandler`, to the API in the `handlers.go` file. Like the other handlers we created in chapter 5, this one takes two arguments: an `http.ResponseWriter` named `w` and a pointer to an `http.Request` named `r`. The body of the method is pretty simple. It sets the `Content-Type` header to `application/json` to let the caller know the response contains JSON-encoded content. It then sets the response code to `200`. Finally, it encodes the worker’s `Stats` field. Thus, `GetStatsHandler` is simply encoding and returning the metrics in the worker’s `Stats` field, which gets refreshed every 15 seconds by the `CollectStats` method. The API’s new `GetStatsHandler()` method will be used for requests to the new `/stats` route created in the following listing. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)

##### Listing 6.13 The API’s new `GetStatsHandler()` method

```
func (a *Api) GetStatsHandler(w http.ResponseWriter, r *http.Request) {
   w.Header().Set("Content-Type", "application/json")
   w.WriteHeader(200)
   json.NewEncoder(w).Encode(a.Worker.Stats)
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)The last thing to do is to update the API’s routes in the `api.go` file. Here, we will create a new route, `/stats`. That route will only support `GET` requests and will call the `GetStatsHandler` we created previously. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)

##### Listing 6.14 Adding the new `/stats` route to the `api.go` file

```
a.Router.Route("/stats", func(r chi.Router) {
   r.Get("/", a.GetStatsHandler)
})
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)Since we’ve added this new route to our API, let’s update the route table from chapter 5 to provide a complete picture of what it now looks like in table 6.1. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)[](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)

##### [](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)Table 6.1 Our updated route table for the worker API[(view table figure)](https://drek4537l1klr.cloudfront.net/boring/HighResolutionFigures/table_6-1.png)

| [](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)Method | [](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)Route | [](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)Description | [](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)Request body | [](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)Response body | [](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)Status code |
| --- | --- | --- | --- | --- | --- |
| [](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)`GET` | [](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)`/tasks` | [](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)Gets a list of all tasks | [](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)None | [](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)List of tasks | [](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)`200` |
| [](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)`POST` | [](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)`/tasks` | [](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)Creates a task | [](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)JSON-encoded `task.TaskEvent` | [](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)None | [](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)`201` |
| [](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)`DELETE` | [](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)`/tasks/{taskID}` | [](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)Stops the task identified by `taskID` | [](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)None | [](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)None | [](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)`204` |
| [](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)`GET` | [](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)`/stats` | [](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)Gets metrics about the worker | [](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)None | [](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)JSON-encoded `stats.Stats` | [](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)`200` |

## [](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)6.5 Putting it all together

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)Before we put this all together and take it for a test run, let’s quickly review what we’ve done:[](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)

-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)We created a new file, `stats.go`.
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)In `stats.go` we created a new `Stats` type to hold the worker’s metrics.
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)Also in `stats.go`, we created a `GetStats()` function that uses the `goprocinfo` library to collect metrics and populate the `Stats` type with data.
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)We added the `CollectStats` method to the worker, which will call the `GetStats()` function in an infinite loop.
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)We added the `GetStatsHandler` method to the worker’s handlers in `handlers.go`.
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)We added a new route, `/stats`, to the worker’s API.

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)At a conceptual level, this work looks like that in figure 6.2.

![Figure 6.2 The worker runs on a Linux machine and serves an API that includes the /stats endpoint. The metrics served on the /stats endpoint are collected using the goprocinfo library, which interacts directly with the Linux /proc filesystem.](https://drek4537l1klr.cloudfront.net/boring/Figures/06-02.png)

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)Now, to see our work in action, we need to write a program, as we’ve done in past chapters, that will glue all of our work together. In this case, we can reuse the program we wrote in chapter 5. We only need to make one minor change.

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)Open up the `main.go` program we used in chapter 5. In the `main()` function, after the call to `runTasks`, add a call to the worker’s new `CollectStats` method. And, like the `runTasks` method, execute that call to `CollectStats` in a separate goroutine. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)

##### Listing 6.15 Updating the `main()` function from our `main.go` file

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
   api.Start()
}
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)After updating the `main.go` file, start up the API the same way you did in chapter 5. You’ll notice that the API’s log output shows that it’s collecting stats every 15 seconds:

```bash
$ CUBE_HOST=localhost CUBE_PORT=5555 go run main.go
Starting Cube worker
2021/12/28 14:03:35 No tasks to process currently.
2021/12/28 14:03:35 Sleeping for 10 seconds.
2021/12/28 14:03:35 Collecting stats
2021/12/28 14:03:45 No tasks to process currently.
2021/12/28 14:03:45 Sleeping for 10 seconds.
2021/12/28 14:03:50 Collecting stats
```

[](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)Now that the API is running, query the new `/stats` endpoint from a different terminal. You should see output about memory, disk, and CPU usage: [](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)

```bash
$ curl localhost:5555/stats|jq .
{
 "MemStats": {
   "mem_total": 32488372,
   "mem_free": 14399056,
   "mem_available": 23306576,
   [....]
 },
 "DiskStats": {
   "all": 1006660349952,
   "used": 39346565120,
   "free": 967313784832,
   "freeInodes": 61645909
 },
 "CpuStats": {
   "id": "cpu",
   "user": 4819423,
   "nice": 701,
   "system": 2140212,
   "idle": 502094668,
   "iowait": 14448,
   "irq": 561115,
   "softirq": 178454,
   "steal": 0,
   "guest": 0,
   "guest_nice": 0
 },
 "LoadStats": {
   "last1min": 0.78,
   "last5min": 0.55,
   "last15min": 0.43,
   "process_running": 2,
   "process_total": 2336,
   "last_pid": 581117
 },
 "TaskCount": 0
}
```

## [](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)Summary

-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)The worker exposes metrics about the state of the machine where it is running. The metrics—about CPU, memory, and disk usage—will be used by the manager to make scheduling decisions.
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)To make gathering metrics easier, we use a third-party library called `goprocinfo`. This library handles most of the low-level work necessary to get metrics from the `/proc` filesystem.
-  [](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)The metrics are made available on the same API that we built in chapter 5. Thus, the manager will have a uniform way to interact with workers: making HTTP calls to `/tasks` to perform task operations and making calls to `/stats` to gather metrics about a worker’s current state. [](/book/build-an-orchestrator-in-go-from-scratch/chapter-6/)

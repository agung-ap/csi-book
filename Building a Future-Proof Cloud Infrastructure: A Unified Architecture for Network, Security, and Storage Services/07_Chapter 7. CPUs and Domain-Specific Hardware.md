## Chapter 7. CPUs and Domain-Specific Hardware

In [Chapter 1](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch01.xhtml#ch01), “[Introduction to Distributed Platforms](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch01.xhtml#ch01),” you saw that a distributed services platform requires distributed services nodes (DSNs) to be present as close as possible to the user applications. The services provided by these DSNs may require substantial processing capabilities, especially when features such as encryption and compression are required.

DSNs can be implemented with domain-specific hardware or general-purpose CPUs. It is essential to have a historical perspective on this topic because the pendulum has swung in both directions a couple of times.[1](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch07.xhtml#ch07foot1) Back in the 1970s–1980s, at the time of mainframes, the central CPUs were not fast enough to do both computing and I/O. Coprocessors and I/O offloads were the norm [[1](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch07.xhtml#ch07ref1)]. The period of the 1990s and 2000s were dominated by the rapid growth of processor performance associated with significant innovation in the processor microarchitecture. For example, from an Intel x86 perspective, the Intel 386 was the first processor with an integrated cache, the 486 was the first pipelined processor, the Pentium was the first superscalar processor, the Pentium Pro/II was the first with speculative execution and integrated L2 cache, and the Pentium 4 was the first SMT x86 processor with virtualization extensions for speeding up hypervisors. Integrated caches played a big part in this performance boost as well, because processor speeds grew super-linearly as compared to DRAM speeds.

[1](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch07.xhtml#rch07foot1). The author would like to thank Francis Matus for his significant contribution to this chapter.

All this evolution happened thanks to the capability to shrink the transistor size. In the 2000s, with transistor channel-length becoming sub-micron, it became challenging to continue to increase the frequency because wires were becoming the dominant delay element. The only effective way to utilize the growing number of transistors was with a multicore architecture; that is, putting multiple CPUs on the same chip. In a multicore architecture, the speed-up is achieved by task-level parallelism, but this requires numerous software tasks that can run independently of each other. These architectures were based on the seminal paper on the Raw Architecture Workstation (RAW) multicore architecture written by Agarwal at MIT in the late ’90s [[2](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch07.xhtml#ch07ref2)].

Multicore architectures provided sufficient numbers of cores such that coprocessors were no longer required. Even as the processor technology continued to advance, in 2010 the pendulum started to swing back.

Multicore started to be coupled with virtualization technology, allowing a CPU with multiple cores to be shared across many virtual machines.

Then the “cloud” arrived, and cloud providers began to realize that the amount of I/O traffic was growing extremely fast due to the explosion of East-West traffic, storage networking, and applications that are I/O intensive. Implementing network, storage, and security services in the server CPU was consuming too many CPU cycles. These precious CPU cycles needed to be used and billed to users, not to services.

The historical period that was dominated by the mindset: “*... we don’t need specialized hardware since CPU speeds continue increasing, CPUs are general purpose, the software is easy to write* …” came to an end with a renewed interest in domain-specific hardware.

Another relevant question is, “What does *general-purpose CPU* mean in the era of Internet and cloud characterized by high volumes of data I/O and relatively low compute requirements?” Desktop CPUs are only “general purpose” in the realm of single-user applications. All the CPU resources, the cache hierarchy, out-of-order issue, branch prediction, and so on, are designed to accelerate a single thread of execution. A lot of computation is wasted, and some of the resources are expensive in terms of power and area. If you’re more concerned with average throughput over multiple tasks at the lowest cost and power, a pure CPU-based solution may not be the best answer.

Starting in 2018, single-thread CPU speed has only grown approximately 4 percent per year, mainly due to the slowdown in Moore’s law, the end of Dennard scaling, and other technical issues related to the difficulty of further reducing the size of the transistors.

The slowing rate of CPU performance growth opens the door to domain-specific hardware for DSNs because user applications require these precious CPU cycles that should not be used by taxing network services. Using domain-specific devices also has a significant benefit in terms of network latency and jitter.

But before we get ahead of ourselves, let’s start analyzing the causes mentioned earlier.

### 7.1 42 Years of Microprocessor Trend Data

The analysis of objective data is essential to understand microprocessor evolution. M. Horowitz, F. Labonte, O. Shacham, K. Olukotun, L. Hammond, and C. Batten did one of the first significant data collections [[3](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch07.xhtml#ch07ref3)], but it lacks more recent data. Karl Rupp [[4](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch07.xhtml#ch07ref4)], [[5](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch07.xhtml#ch07ref5)] added the data of the more recent years and published it on GitHub with a Gnu plotting script. The result of this work is shown in [Figure 7-1](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch07.xhtml#ch07fig1).

![A scatter plot presents the trend data of 42 years of a microprocessor.](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9780136624226/files/graphics/07fig01.jpg)

**FIGURE 7-1** 42 Years of Microprocessor Trend Data

A scatter plot is shown in which the Microprocessor trend data is depicted. The plots for transistors (in thousands), single-thread performance (SpecINT times 10 cubed), frequency (Megahertz), typical power (in Watts), and the number of logical cores are shown. The vertical axis ranges from 10 powered 0 to 10 powered 7. The horizontal axis representing the year ranges from 1970 to 2020 in increments of 10. The plots are increasing, starting from 10 powered 0 in 1970 and reaches a maximum value in 2020. In 2020, the plots are at 10 powered 7 for transistors, 10 powered 5 for single-thread performance, 10 powered 3 for frequency, 10 powered 2 for typical power, and 10 powered 2 for the number of logical cores. The concentration of the plots is higher between 1995 and 2015. Note: The values are approximate.

This figure contains five curves:

- The transistor count curve is usually known as Moore’s law and is described in more detail in the next section.

- The single-thread performance curve shows the combined effect of all the factors described in this chapter and is discussed in detail in [section 7.6](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch07.xhtml#ch07lev1sec6). At first glance, it is evident that this curve is flattening out; that is, single-thread performance is not growing linearly any longer.

- Frequency is another curve that has flattened out mainly due to technological factors such as Dennard scaling, described in [sections 7.3](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch07.xhtml#ch07lev1sec3) and [7.5](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch07.xhtml#ch07lev1sec5).

- The typical power curve shows a trend similar to the frequency curve.

- Finally, the curve “number of logical cores” shows the role of the multicore architecture introduced around 2005 and presents significant implications when coupled with Amdahl’s law described in [section 7.4](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch07.xhtml#ch07lev1sec4).

### 7.2 Moore’s Law

One of the typical statements used to justify the adoption of domain-specific hardware is, “Moore’s Law is dead.” Is this sentence correct?

Gordon Moore, the co-founder of Fairchild Semiconductor and longtime CEO and Chairman of Intel, formulated the original Moore’s Law in 1965. There are different formulations, but the one commonly accepted is the 1975 formulation that states that “transistor count doubles approximately every two years.” This is not really a law; it is more an “ambition.”

[Figure 7-2](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch07.xhtml#ch07fig2) contains a plot of the transistor count on integrated circuit chips courtesy of Our World in Data [[6](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch07.xhtml#ch07ref6)].

![A graph presents the number of transistors on integrated circuit chips using Moore's Law.](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9780136624226/files/graphics/07fig02.jpg)

**FIGURE 7-2** Transistor Count as a Function of Years

A scatter plot depicts the transistor count as a function of years by Moore's law. The horizontal axis representing years ranges from 1970 to 2016 in increments of 2 years. The vertical axis representing the transistor count ranges from 0 to 20 billion. It is observed that the transistor count keeps increasing with years, and the concentration of plots is higher between the years 2000 and 2016, where the transistor count is between one hundred million and twenty billion. Transistors such as Intel 4004, Motorola 68000, ARM 3, and WDC 65C02 are plotted in the range of 0 to 1 million in the period between 1970 to 1984. Transistors such as Pentium Pro, SA-100, AMD K7, SA-110, and Atom are present in the range of 1 million to 100 million in the period from 1984 to 2002. Transistors such as SPARC M7, dual-core Itanium 2, and 8-core Core i7 Hasewell-E are present in the range of 100 million and 10 billion in the years 2002 to 2016. Note: All the values are approximate.

At first glance, [Figure 7-2](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch07.xhtml#ch07fig2) seems to confirm that Moore’s Law is still on track. It also correlates well with the transistor count curve of [Figure 7-1](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch07.xhtml#ch07fig1). A more specific analysis of Intel processors, which are the dominant processors in large data centers and the cloud, is shown in [Figure 7-3](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch07.xhtml#ch07fig3) and presents a different reality. In 2015 Intel itself acknowledged a slowdown of Moore’s Law from 2 to 2.5 years [[7](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch07.xhtml#ch07ref7)], [[8](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch07.xhtml#ch07ref8)].

![A trend graph depicts the data of Moore's law and the Intel processors.](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9780136624226/files/graphics/07fig03.jpg)

**FIGURE 7-3** Intel Processor Transistor Count

A trend graph presenting the intel processor and Moore's Law transistor count is shown. The horizontal axis representing years ranges from 1971 to 2017. The vertical axis representing transistor count ranges from 2.00E plus 03 to 3.36E plus 10. Two trendlines, representing 1975 Moore's law and intel processors are shown. Both the trendlines begin at 2.00E plus 03 in 1971 and increases. The path traced by the trend line representing 1975 Moore's law is an increasing straight line, that extends up to 3.36E plus 10 by 2017. The path traced by the line representing intel processors has minor inflections and extends up to 8.39E plus 09. The transistor count of Intel processors is in and around the corresponding transistor count by Moore's law.

Gordon Moore recently estimated that his law would reach the end of applicability by 2025 because transistors would ultimately reach the limits of miniaturization at the atomic level.

To show the slowdown of CPUs in terms of the SPEC Integer benchmark (used for comparing the performance of a computer when dealing with a single task, such as the time to complete a single task), you need to add other factors from the Hennessy and Patterson Turing Award lecture [[9](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch07.xhtml#ch07ref9)], [[10](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch07.xhtml#ch07ref10)]:

- The end of Dennard scaling

- The restricted power budgets for microprocessors

- The replacement of the single power-hungry processor with several energy-efficient processors

- The limits to multiprocessing due to Amdahl’s Law

### 7.3 Dennard Scaling

In 1974, Robert Dennard observed that power density remained constant for a given area of silicon (nanometers square) when the dimension of the transistor shrank, thanks to technology improvements [[11](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch07.xhtml#ch07ref11)].

He observed that voltage and current should be proportional to the linear dimensions of a transistor; thus, as transistors shrank, so did voltage and current. Because power is the product of voltage and current, power dropped with the square. On the other hand, the area of the transistors dropped with the square, and the transistor count increased with the square. The two phenomena compensated each other.

Dennard scaling ended around 2004 because current and voltage couldn’t keep dropping while still maintaining the dependability of integrated circuits.

Moreover, Dennard scaling ignored the leakage current and threshold voltage, which establish a baseline of power per transistor. With the end of Dennard scaling, with each new transistor generation, power density increased. [Figure 7-4](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch07.xhtml#ch07fig4) shows the transistor size and the power increase as a function of the years.

![A graph presents channel length and power increase using Dennard scaling.](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9780136624226/files/graphics/07fig04.jpg)

**FIGURE 7-4** Dennard Scaling

The channel length and power increase are shown using Dennard scaling. The left vertical axis, representing channel length (in nanometer) ranges from 0 to 600 in increments of 100. The right vertical axis, representing power per square nanometer compared to the 45-nanometer channel length, ranges from 0.00 to 4.50 in increments of 0.50. The horizontal axis representing years ranges from 1992 to 2019. The trendline representing channel size is decreasing and passes through the following values: 500 in 1992, 350 in 1995, 250 in 1998, 180 in 2001, 130 in 2003, 90 in 2006, 65 in 2008, 45 in 2010, 28 in 2012, 16 in 2015, 14 in 2017, and 7 in 2019. The trendline representing power per square nanometer compared to channel length is increasing and passes through the following points: 1.0 in 2010, 1.6 in 2012, 3.0 in 2015, 3.4 in 2017, and 4.1 in 2019. Note: All the values are approximate.

The power data is estimated using the International Technology Roadmap for Semiconductors (ITRS) data from Hadi Esmaeilzadeh, et al. [[12](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch07.xhtml#ch07ref12)]. All these data are approximated and should be used only to obtain a qualitative idea of the phenomena.

The increase in power density also started to pose a limitation to the increase in clock frequencies and, as a consequence, to the performance increase of a single CPU core.

Dennard scaling is the dominant factor in the slowdown of the growth of a single CPU core.

Starting in 2005, CPU manufacturers focused on multicore architecture as a way to continue to increase performance, and here is where Amdahl’s law comes into play.

### 7.4 Amdahl’s Law

In 1967, computer scientist Gene Amdahl formulated his law that is used to predict the theoretical speedup when using multiple processors [[13](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch07.xhtml#ch07ref13)]. It has three parameters:

- “Speedup” is the theoretical speedup of the execution of the whole task.

- “N” is the number of cores.

- “p” is the proportion of the program that can be parallelized; if N approaches infinity then Speedup = 1 / (1 – p).

For example, if 10% of the task is serial (p = 0.9), then the maximum performance benefit from using multiple cores is 10.

[Figure 7-5](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch07.xhtml#ch07fig5) shows possible speedups when the parallel portion of the code is 50%, 75%, 90%, and 95%. At 95% the maximum achievable speedup is 20 with 4096 cores, but the difference between 256 cores and 4096 is minimal. Continuing to increase the number of cores produces a diminished return.

![A graph depicts the speedups of 50 percent, 75 percent, 90 percent, and 95 percent parallel portion of the code.](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9780136624226/files/graphics/07fig05.jpg)

**FIGURE 7-5** Amdahl’s Law

The graph, presenting an example of Amdahl's law is shown. The horizontal axis representing the number of processors ranges from 1 to 65536 (every consecutive number in this scale doubles). The vertical axis representing speedup ranges from 0 to 20 in increments of 2. There are four trend lines drawn representing 50 percent, 75 percent, 90 percent, and 95 percent parallel portion of the code. The lines originate from a point, where its speedup and number of processors are at 1. The speedup for 95 percent parallel portion increases from 1 to 20 corresponding to the processors from 1 to 2048, after which the line remains constant. For a 90 percent parallel portion, the speedup increases from 1 to 10 corresponding to the processors from 1 to 256, after which the path traced by the line remains constant. For a 75 percent parallel portion, the speedup increases from 1 to 4 corresponding to the processors from 1 to 128, after which the path traced by the line remains constant. For a 50 percent parallel portion, the speedup increases from 1 to 2 corresponding to the processor from 1 to 16, after which the path traced by the line remains constant.

### 7.5 Other Technical Factors

All modern processors are built using MOSFETs (metal-oxide-semiconductor field-effect transistors). Shrinking the size of these transistors is very desirable because it allows us to pack more functions on a single chip and reduces the cost and power per feature. We have already discussed a few reasons why shrinking the size of MOSFET is difficult, but here are a few others:

- Shrinking the size of the transistor also implies shrinking the size of the metal traces that interconnect them, and this results in an increased electrical resistance, which, in turn, limits the frequency of operations.

- Reducing the voltage at which circuits operate can be done up to a point. However, there are minimum threshold voltages; for example, for memory circuits, which cannot be exceeded. Reducing voltage below a certain level also causes transistors not to switch on and off completely and, therefore, consume power due to subthreshold conduction.

- There is an intrinsic power dissipation related to distributing the clock along the clock tree.

- Other leakages become important when reducing channel length; for example, gate-oxide leakage and reverse-biased junction leakage. These were ignored in the past but now can account for more than half of the total power consumption of an application specific integrated circuits (ASIC).

- Associated with power consumption are heat production and heat dissipation. Maintaining the transistor below a specific temperature is mandatory for device reliability.

- Process variations also become more critical. It is more difficult to precisely align the fabrication masks and control the dopant numbers and placement.

All these factors, plus Amdahl’s Law and Dennard Scaling discussed in the previous sections, explain why in [Figure 7-1](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch07.xhtml#ch07fig1) the frequency and power curves have flattened out in recent years. Economic factors are also important; for example, the adoption of esoteric, expensive technology to cool a chip is not practical.

### 7.6 Putting It All Together

As of today, the transistor count still follows the exponential growth line predicted by Gordon Moore. The AMD Epyc processor and the NVIDIA CP100 GPU are two recent devices that track Moore’s law.

Single-thread performance growth is now only increasing slightly year over year, mainly thanks to further improvements in instructions per clock cycle.

The availability of additional transistors translates into an increase in the number of cores.

Combining the effects described in the three preceding sections produces the result shown in [Figure 7-6](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch07.xhtml#ch07fig6).

![A graph presents the combined effect on single-thread performance.](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9780136624226/files/graphics/07fig06.jpg)

**FIGURE 7-6** Combined effect on single-thread performance

A graph depicts the performance after combining all the effects. The horizontal axis representing the years ranges from 1986 to 2019. The vertical axis represents the performance increase (spec integer benchmark). A trendline is drawn to mark performance through the years. The data inferred from the graph are as follows: there is approximately a 50 percent yearly increase between 1986 and 2003, there is approximately a 25 percent yearly increase between 2003 and 2011, there is approximately 10 percent yearly increase between 2011 to 2015, and 4 percent yearly increase after 2015.

The vertical axis is the performance of a processor according to the SPEC Integer benchmark, a standard benchmarking technique from spec.org; the horizontal axis is a timeline. Data is qualitative and obtained by linearizing the “single-thread performance points” of [Figure 7-1](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch07.xhtml#ch07fig1).

The important datum the graph shows is that since 2015, the SPEC Integer speed of the processors has only grown 4 percent per year. If this trend continues, it will take 20 years for the single-thread performance to double!

### 7.7 Is Moore’s Law Dead or Not?

Moore’s law, in its 1975 formulation, says that “transistor count doubles approximately every two years.” We have seen that this still holds in general, even if the steadily reducing transistor channel-length is approaching the size of atoms; this is a primary barrier. Gordon Moore and other analysts expect Moore’s law to end around 2025.

We have also seen that Intel processors, today the most deployed in data centers and clouds, have had difficulty tracking Moore’s law since 2015.

The most important conclusion is the fact that single-thread performance will take 20 years to double if it continues to grow at the current pace.

This last factor is what makes most analysts claim that Moore’s law is dead [[14](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch07.xhtml#ch07ref14)].

### 7.8 Domain-specific Hardware

Domain-specific hardware is optimized for certain types of data processing tasks, allowing it to perform those tasks way faster and more efficiently than general-purpose CPUs.

For example, graphics processing units (GPUs) were created to support advanced graphics interfaces, but today they are also extensively used for artificial intelligence and machine learning. The key to GPUs’ success is the highly parallel structure that makes them more efficient than CPUs for algorithms that process large blocks of data in parallel and rely on extensive floating-point math computations. This is an example in which the sea of processor architecture cannot compete. For example, Intel’s Larrabee project was an attempt to contrast GPUs with a sea of processor cores, but it was cancelled due to delays and disappointing early performance figures [[15](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch07.xhtml#ch07ref15)], mainly because the sea of core structure was not a good match for the graphic problem.

In the enforcement of network services, some operations are not well suited for CPUs, but they can take advantage of domain-specific hardware. Let’s consider the longest prefix match and access control lists. Both can be implemented effectively in ternary content addressable memory (TCAM), but are not supported natively by CPUs and, therefore, must be implemented in software using tree-like data structures. The same is partially correct for encryption. Modern CPUs have added support for symmetric encryption algorithms, but they typically lack significant optimizations for asymmetric encryption algorithms (for example, RSA, Diffie-Hellman) that are used when new secure connections need to be set up. Also, lossless data compression and data deduplication are standard in storage applications, and CPUs don’t have native instructions for these functions.

Another critical point is that CPUs are not designed to process packets with low delay and minimal jitter, whereas network devices are generally designed with these specific attributes. CPUs typically run an operating system with a scheduler in charge of sharing the CPU across different processes. This scheduler is not designed to minimize jitter and latency, but rather to optimize overall CPU utilization. Jitter and delay are two fundamental parameters when processing network packets. Therefore, there is a mismatch between network services and CPUs that is not present between network services and domain-specific hardware.

### 7.9 Economics of the Server

The fundamental question that we need to ask ourselves is, “Where do we put our dollars to obtain maximum system performance—in other words, is there a business case for domain-specific hardware in distributed services platforms?”

Let’s start by analyzing what makes a server: CPU, RAM, peripherals, and motherboard. The motherboard is a commodity component in which there is minimal differentiation. Intel mainly controls the CPU market. The RAM market has a few vendors with little price differentiation. Among the different peripherals, an important one for distributed services is the network interface card (NIC).

We have seen that the current trend is to load the CPU with tasks such as security, management, storage, and control functions. Reversing this trend and pushing these auxiliary functions to domain-specific hardware in network devices frees up CPU cycles for real applications. For example, security and network functions are computation-intensive and better implemented in domain-specific, power-efficient hardware.

Also, the refreshment period of domain-specific hardware tends to be faster than the one of CPUs (typically two years, compared to four years for a new CPU complex), allowing the distributed services improvements to happen at a quicker pace.

All these points indicate that there is a business case for domain-specific hardware for distributed services platforms and that we will see a growing number of such platforms in the next few years.

### 7.10 Summary

In this chapter, we have shown that the availability of domain-specific hardware is key to an efficient implementation of a distributed services platform.

The next chapter presents the evolution of NICs and discusses whether they can be used to host the hardware required by the DSN, or if a better placement of this hardware is in other network devices.

### 7.11 Bibliography

**[[1](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch07.xhtml#rch07ref1)]** Wikipedia, “Coprocessors,” [https://en.wikipedia.org/wiki/Coprocessor](https://en.wikipedia.org/wiki/Coprocessor)

**[[2](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch07.xhtml#rch07ref2)]** Anant Agarwal, “Raw Computation,” *Scientific American*, vol. 281, no. 2, 1999, pp. 60–63. JSTOR, [www.jstor.org/stable/26058367](http://www.jstor.org/stable/26058367)

**[[3](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch07.xhtml#rch07ref3)]** W. Harrod, “A Journey to Exascale Computing,” slide 12, [https://science.energy.gov/~/media/ascr/ascac/pdf/reports/2013/SC12_Harrod.pdf](https://science.energy.gov/~/media/ascr/ascac/pdf/reports/2013/SC12_Harrod.pdf)

**[[4](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch07.xhtml#rch07ref4)]** Karl Rupp, “42 Years of Microprocessor Trend Data,” [https://www.karl-rupp.net/2018/02/42-years-of-microprocessor-trend-data](https://www.karl-rupp.net/2018/02/42-years-of-microprocessor-trend-data)

**[[5](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch07.xhtml#rch07ref5)]** Karl Rupp, “Microprocessor Trend Data,” [https://github.com/karlrupp/microprocessor-trend-data](https://github.com/karlrupp/microprocessor-trend-data)

**[[6](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch07.xhtml#rch07ref6)]** Our World in Data, “Moore’s Law - The number of transistors on integrated circuit chips (1971–2016),” [https://ourworldindata.org](https://ourworldindata.org/)

**[[7](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch07.xhtml#rch07ref7)]** [https://www.technologyreview.com/s/601102/intel-puts-the-brakes-on-moores-law](https://www.technologyreview.com/s/601102/intel-puts-the-brakes-on-moores-law)

**[[8](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch07.xhtml#rch07ref8)]** [https://www.businessinsider.com/intel-acknowledges-slowdown-to-moores-law-2016-3](https://www.businessinsider.com/intel-acknowledges-slowdown-to-moores-law-2016-3)

**[[9](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch07.xhtml#rch07ref9)]** John L. Hennessy and David A. Patterson, 2019. A new golden age for computer architecture. Commun. ACM 62, 2 (January 2019), 48–60. DOI: [https://doi.org/10.1145/3282307](https://doi.org/10.1145/3282307)

**[[10](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch07.xhtml#rch07ref10)]** John Hennessy, “The End of Moore’s Law & Faster General Purpose Computing, and a Road Forward,” Stanford University, March 2019, [https://p4.org/assets/P4WS_2019/Speaker_Slides/9_2.05pm_John_Hennessey.pdf](https://p4.org/assets/P4WS_2019/Speaker_Slides/9_2.05pm_John_Hennessey.pdf)

**[[11](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch07.xhtml#rch07ref11)]** R. H. Dennard, F. H. Gaensslen, V. L. Rideout, E. Bassous, and A. R. LeBlanc, “Design of ion-implanted MOSFETs with very small physical dimensions,” in IEEE *Journal of Solid-State Circuits*, vol. 9, no. 5, pp. 256–268, Oct. 1974.

**[[12](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch07.xhtml#rch07ref12)]** Hadi Esmaeilzadeh, et al. “Dark silicon and the end of multicore scaling.” 2011 38th Annual International Symposium on Computer Architecture (ISCA) (2011): 365–376.

**[[13](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch07.xhtml#rch07ref13)]** Gene M. Amdahl, 1967. Validity of the single processor approach to achieving large scale computing capabilities. In Proceedings of the April 18–20, 1967, Spring Joint Computer Conference (AFIPS ’67 (Spring)). ACM, New York, NY, USA, 483–485.

**[[14](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch07.xhtml#rch07ref14)]** Tekla S. Perry, “David Patterson Says It’s Time for New Computer Architectures and Software Languages,” IEEE Spectrum, 17 Sep 2018, [https://spectrum.ieee.org/view-from-the-valley/computing/hardware/david-patterson-says-its-time-for-new-computer-architectures-and-software-langauges](https://spectrum.ieee.org/view-from-the-valley/computing/hardware/david-patterson-says-its-time-for-new-computer-architectures-and-software-langauges)

**[[15](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch07.xhtml#rch07ref15)]** Wikipedia, “Larrabee (microarchitecture),” [https://en.wikipedia.org/wiki/Larrabee_(microarchitecture)](https://en.wikipedia.org/wiki/Larrabee_(microarchitecture))

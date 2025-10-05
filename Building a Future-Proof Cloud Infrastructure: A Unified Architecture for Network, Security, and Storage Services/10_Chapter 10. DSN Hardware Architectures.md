## Chapter 10. DSN Hardware Architectures

In this chapter, we analyze a few competing hardware structures that can be suitable for DSNs, according to the goals and constraints set in the previous chapter. We try to answer the question, “What is the best hardware architecture for a DSN?” reminding ourselves that the ideal DSN is a fully contained unit, with zero footprint on the servers, is programmable in three dimensions (data plane, control plane, and management plane), and performs at wire speed with low latency and low jitter.

The control and management planes’ programmability don’t really factor in, because they are not data intensive. All the DSNs include a few CPU cores, typically in the form of ARM cores, to execute control protocols and management interfaces.

Today, data plane programmability at speeds of 100 Gbps or more is still very rare, because it is difficult to implement in hardware. The P4 architecture, described in [Chapter 11](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch11.xhtml#ch11), “[The P4 Domain-Specific Language](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch11.xhtml#ch11),” addresses this issue.

### 10.1 The Main Building Blocks of a DSN

Let’s start with the description of some of the potential building blocks that might be needed to build a DSN, in no particular order:

- **2 × 100 growing to 2 × 200 and 2 × 400 Gbps Ethernet ports:** Two ports are the minimum to support the bump-in-the-wire configuration or to dual-attach a server to two ToR switches or two separate networks, and so on. It is desirable that they support the Pulse-Amplitude Modulation 4-Level (PAM-4) standard [[1](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch10.xhtml#ch10ref1)] to easily partition them in multiple 25 and 50 Gbps ports.

- **1 × 1 Gbps Ethernet management port:** We saw in the preceding chapter that the “network mode” is the preferred and most secure management mode, and some users want to run the management plane out-of-band as a separate network. A dedicated management port allows them to achieve this goal.

- **PCIe Gen 3 and Gen 4:** In [section 8.1](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch08.xhtml#ch08lev1sec1) we discussed how four Gen 3 lanes support a 25 Gb/s Ethernet connection, eight lanes support 50 Gb/s Ethernet, and sixteen support 100 Gb/s Ethernet. These bandwidth numbers double for Gen 4. If PCIe is limited to configuration and management, two lanes are enough; if it passes user data to and from the Ethernet ports, then an appropriate number of lanes is required, typically 16 or 32.

- **Internal switch:** An internal layer 2 switch capable of implementing SR-IOV is the minimum requirement. The internal switch is the central point of the DSN, and typically it is much more sophisticated, including layer 3, ACLs, firewall, NAT, load balancing, and so on. The final goal is to have a switch that is fully programmable in the data plane, allowing users to add proprietary functions or encapsulations.

- **SR-IOV logical ports (see [section 8.4](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch08.xhtml#ch08lev1sec4)):** A sufficient number of physical functions (PFs) and virtual functions (VFs) need to be supported; a reasonable implementation may support, for example, 4 PFs and 256 VFs/PFs for a total of 1024 VFs. Each VF and PF is a separate logical port on the internal switch.

- **Memory:** A DSN requires memory to store state, data, and programs. For example, the state is stored in tables, the largest one being the flow table. A flow table entry contains multiple fields derived from the packet fields and various counters and timers associated with telemetry and other auxiliary functions. Assuming that one flow table entry is 128 bytes, 2 GB of memory is required to store 16 million flows. Considering all data and program storage requirements, a memory size between 4 GB and 16 GB looks reasonable.

- **Cache:** Some form of write-back cache is required to compensate between the high speed of the internal circuitry and the lower speed of the memory. Sizing a cache from a theoretical perspective is impossible; the larger the better, typically a few MB.

- **Network on chip (NOC):** All the components listed here need to communicate and share memories, and this is the primary purpose of the NOC that can optionally also guarantee cache coherency among the different memories on the chip.

- **Dedicated hardware for special functions:** Even with the best programmability in the data plane, some functions are best executed in specialized hardware structures, among them encryption and compression.

- **RDMA and storage support:** In [Chapter 6](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch06.xhtml#ch06), “[Distributed Storage and RDMA Services](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch06.xhtml#ch06),” we discussed how RDMA and storage take advantage of particular hardware infrastructure to move data at very high speed without loading the main server CPU. If these services are required, a DSN needs to implement them in hardware.

- **Various auxiliary interfaces:** These are low-speed interfaces used for initialization and troubleshooting, such as serial, USB, and I2C.

- **NVRAM interface:** This is needed to connect an NVRAM for storing DSN software images and other static data.

- **Embedded CPU cores:** These are required to run control and management planes.

### 10.2 Identifying the Silicon Sweet Spot

One of the challenges in designing a DSN is the identification of the “silicon sweet-spot”: that is, of an area of silicon that has a reasonable cost, can provide exceptional services at high speed, and has a power dissipation that is compatible with the embodiments considered. How big this area is and how many logical functions can fit into it depends on the silicon process technology used in the fabrication.

Choosing the right technology is essential because it creates interdependencies among the silicon area, the number of gates, the clock frequency, the power consumption, and, ultimately, the cost. [Figure 10-1](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch10.xhtml#ch10fig1) shows the significant interdependencies and also clarifies that the final performance of domain-specific hardware depends not only on the gate count but also on the chosen hardware architecture, which is the main topic of this chapter, starting from [section 10.3](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch10.xhtml#ch10lev1sec3).

![A figure depicts the major considerations in silicon design.](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9780136624226/files/graphics/10fig01.jpg)

**FIGURE 10-1** Major Considerations in Silicon Design

A figure depicts the interdependencies of various factors in silicon design. Gate count and cost depends on the silicon area and process. Power consumption depends on the silicon area, process, and frequency. Performance depends on gate count, frequency, and architecture.

Usually, process technologies are classified according to the transistor channel length. [Table 10-1](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch10.xhtml#ch10tab1) summarizes the integrated circuit (IC) manufacturing processes according to the year of introduction [[2](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch10.xhtml#ch10ref2)].

**TABLE 10-1** Integrated Circuit Manufacturing Processes

| 2001 | 2004 | 2006 | 2007 | 2010 | 2012 | 2014[1](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch10.xhtml#ch10tabf1) | 2017 | 2018 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 130 nm | 90 nm | 65 nm | 45 nm | 32 nm | 22 nm | 16/14 nm | 10 nm | 7 nm |

[1](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch10.xhtml#rch10tabf1) The 14 nm and 16 nm are essentially the same process and are referred to as 16 nm in this chapter.

At the time of writing, the two technologies used to build most of the ASICs are 16 nm (nanometer) and 7 nm.

When you are evaluating a new process, several components must be considered carefully. Among them:

- **The Serializer/Deserializer (SerDes):** These are incredibly critical components used to input/output data from the chip at high speed. For example, they are the components at the base of the Ethernet MACs and PCIe lanes. In the case of Ethernet, two very desirable emerging standards are PAM-4 56G and PAM-4 112G [[1](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch10.xhtml#ch10ref1)]. PCIe Gen 3 and Gen 4 need to be supported, and, with respect to market trends, very soon Gen 5 will be required.

- **The memory interfaces:** These are also high-speed connections toward external memories. The desirable standards to be supported are DDR4, DDR5, and HBM.

- **CPUs:** All new ASICs include some form of general-purpose processors, and the ARM family of processors is often used for these applications. Frequency, architecture, cache size, and other parameters depend on the manufacturing processes.

- **Other logic infrastructures:** These include, for example, the availability of TCAMs, which are used for the longest prefix match or five-tuple ACL rules.

- **Availability of third-party intellectual property (IP):** These include, for example, libraries containing encryption and compression modules.

One significant consideration is always power dissipation. To keep the power budget around 25 Watts (which we have seen is a requirement for PCIe slots), the silicon area sweet spot is around 200 square millimeters, both at 16 nm and 7 nm.

How much logic and memory can be packed into that area depends first and foremost on the channel length, but also on which design path is chosen; a customer-owned tooling (COT), in general, produces smaller silicon areas, but not necessarily a lower power.

#### 10.2.1 The 16 nm Process

The 16 nm process is the evolution of the 22 nm, and the first devices appeared in volume in products in 2015. For example, in 2015 the MacBook started to use the i7-5557U Intel processor, the Galaxy S6 began using a System on a Chip (SoC), and the iPhone 6S began using the A9 chips, all fabricated with this technology [[2](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch10.xhtml#ch10ref2)].

Ethernet interfaces up to 100 Gbps have been used in conjunction with PCI Gen 3 and Gen 4. Memory interfaces are typically DDR3, DDR4, and HBM. The availability of libraries with many modules is exceptionally mature, and ARM processors of the A72 architecture can be easily integrated with a clock frequency between 1.6 to 2.2 Ghz.

The 16 nm technology allows a transistor density of approximately 35 million transistors per square millimeter [[3](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch10.xhtml#ch10ref3)], a 2.5 times improvement compared to the previous 22 nm technology. When you consider that:

- At least four transistors are required to build a NAND gate

- Not all transistors can be used due to placement, routing, and other technological considerations

- Gates need to be accompanied by some amount of memory to produce a useful circuit

the net result is that—for example, with the 16 nm process—in one square millimeter it is possible to pack two to four million gates or 4 Mbit to 8 Mbit of RAM, or a combination of the two.

#### 10.2.2 The 7 nm Process

The biggest challenges related to evolving the 16 nm process into the 7 nm process are in the area of lithography and, in particular, in the second part of the fabrication process called the back end of line (BEOL), where transistors get interconnected through the metallization layers.

The first devices in 7 nm were introduced in 2018 and are the Apple A12 Bionic [[4](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch10.xhtml#ch10ref4)] and the Huawei Kirin 980 [[5](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch10.xhtml#ch10ref5)]. They both have a transistor density of approximately 83 million transistors per square millimeter, and density up to 100 million transistors per square millimeter have been reported by Intel [[3](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch10.xhtml#ch10ref3)]. As a result, the 7 nm process can pack two to three times as many gates or memory bits as the 16 nm process.

Ethernet interfaces are typically 100/200/400 Gbps implemented using PAM-4 56G and PAM-4 112G. DDR5 and HBM2 memory interfaces are available in addition to the previous ones, and so is PCIe Gen 5. At the time of writing, the availability of libraries is maturing quickly and an ARM processor of the A72 architecture can be easily integrated with a clock frequency up to 3.0 GHz.

In a nutshell, at 7 nm it is possible to design devices that consume half the power with the same performance as 16 nm or with the same power and provide two to three times the performance.

### 10.3 Choosing an Architecture

[Figure 10-1](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch10.xhtml#ch10fig1) showed how the final performance of domain-specific hardware is a combination of the gate count and of the architecture built using these gates. In the preceding sections, we explained the gate count and the availability of building blocks. In the following, we discuss which architecture is the best for distributed-service, domain-specific hardware.

[Figure 10-2](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch10.xhtml#ch10fig2) illustrates the three major architecture possibilities: sea of CPU cores, field-programmable gate arrays (FPGAs), and ASICs. It also shows the presence of another interesting technology called P4 that adds data plane programmability to the ASIC architecture. [Chapter 11](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch11.xhtml#ch11), “[The P4 Domain-Specific Language](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch11.xhtml#ch11),” presents the P4 architecture and the associated language.

![A figure presents the possible architectures for DSNs. They are sea of cores, FPGAs, ASICs, and P4 architecture.](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9780136624226/files/graphics/10fig02.jpg)

**FIGURE 10-2** Possible Architectures for DSNs

### 10.4 Having a Sea of CPU Cores

The idea of having a limited number of CPU cores inside a DSN to implement control and management protocols and other auxiliary functions is widely accepted and deployed. This section does not discuss that; it analyzes the use of CPU cores in the data plane; that is, to parse, modify, drop, or forward every single packet that enters a DSN. The basic idea is to use all the silicon area for as many processors as possible combined with a hardwired, nonprogrammable NIC. Common processor choices are ARM [[6](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch10.xhtml#ch10ref6)] or MIPS [[7](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch10.xhtml#ch10ref7)] cores with associated caches.

The clear advantage of the sea of CPU cores architecture is easy programmability; for example, these processors can run a standard Linux distribution and can be programmed in any possible language. All the tools used to write and troubleshoot software on general-purpose CPUs are readily available and known to a large number of programmers. This option is very appealing for developers coming from the software world, but it has substantial performance drawbacks.

In this chapter, we base our discussion on the ARM A72 core [[8](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch10.xhtml#ch10ref8)], which is a widely used processor. The performance measurements refer to a complex of four ARM A72 cores and the associated cache memory. The size of this complex is approximately 17 million gates and 20 Mbits of RAM.

Using the sweet spot presented in the previous sections, it is probably possible to fit eight such complexes on a 16 nm, 200 square millimeters die, for a total of 32 processors at 2.2 GHz.

[Figure 10-3](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch10.xhtml#ch10fig3) indicates that for a reasonable feature set with an average packet size of 256 bytes, an ARM A72 normalized at 1 GHz will process approximately a half Gbps of bandwidth [[9](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch10.xhtml#ch10ref9)]. Multiply that by 32 cores and 2.2 GHz, and the total bandwidth is 35 Gbps, clearly far from the processing capability required for a single 100 Gbps Ethernet link.

![A graph presents the ARM performance as a packet processor.](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9780136624226/files/graphics/10fig03.jpg)

**FIGURE 10-3** ARM Performance as a Packet Processor

A graph of bandwidth (vertical axis) versus packet size (horizontal axis) is shown. The bandwidth ranges from 0 Gbps to 2 Gbps in increments of 0.5 and the packet size ranges from 64 bytes to 8192 bytes. Five trend lines representing the following are drawn: Base-App, Base-App plus Parser, Base-App plus Parser plus VLAN rewrite, Base-App plus Parser plus VLAN rewrite plus Policer, Base-App plus Parser plus VLAN rewrite plus Policer plus NACL. At the packet size 64 bytes, the bandwidth of Base-App is 0.25, Base-App plus Parser is 0.1, Base-App plus Parser plus VLAN rewrite is 0.1, Base-App plus Parser plus VLAN rewrite plus Policer is 0, Base-App plus Parser plus VLAN rewrite plus Policer plus NACL is 0. At the packet size 128 bytes, the bandwidth of Base-App is 0.35, Base-App plus Parser is 0.25, Base-App plus Parser plus VLAN rewrite is 0.25, Base-App plus Parser plus VLAN rewrite plus Policer is 0.1, Base-App plus Parser plus VLAN rewrite plus Policer plus NACL is 0.1. At the packet size 256 bytes, the bandwidth of Base-App is 0.65, Base-App plus Parser is 0.35, Base-App plus Parser plus VLAN rewrite is 0.35, Base-App plus Parser plus VLAN rewrite plus Policer is 0.2, Base-App plus Parser plus VLAN rewrite plus Policer plus NACL is 0.2. At the packet size 512 bytes, the bandwidth of Base-App is 1.2, Base-App plus Parser is 0.75, Base-App plus Parser plus VLAN rewrite is 0.75, Base-App plus Parser plus VLAN rewrite plus Policer is 0.2, Base-App plus Parser plus VLAN rewrite plus Policer plus NACL is 0.2. At the packet size 1024 bytes, the bandwidth of Base-App is 1.75, Base-App plus Parser is 1.5, Base-App plus Parser plus VLAN rewrite is 1.3, Base-App plus Parser plus VLAN rewrite plus Policer is 0.4, Base-App plus Parser plus VLAN rewrite plus Policer plus NACL is 0.4. At the packet size 2048 bytes, the bandwidth of Base-App is 1.1, Base-App plus Parser is 1.1, Base-App plus Parser plus VLAN rewrite is 0.95, Base-App plus Parser plus VLAN rewrite plus Policer is 0.45, Base-App plus Parser plus VLAN rewrite plus Policer plus NACL is 0.45. At the packet size 8.92 bytes, the bandwidth of Base-App is 1.8, Base-App plus Parser is 1.8, Base-App plus Parser plus VLAN rewrite is 1.75, Base-App plus Parser plus VLAN rewrite plus Policer is 0.5, Base-App plus Parser plus VLAN rewrite plus Policer plus NACL is 0.5.

Moving to 7 nm it is probably possible to pack 96 ARM cores at 3 GHz, and this should be enough to process one 100 Gbps link, but for sure not multiple 200/400 Gbps links.

Another way to think about these numbers is that one ARM core at 1 GHz is capable of executing one instruction every 1.5 clock cycles at best; that is, 666M instructions per second. With an average packet length of 256 bytes at 100 Gbps, it is possible to transmit 45 Mpps, equivalent to a budget of 14.8 instructions per packet per core. Assuming 32 cores at 3 GHz, the budget is 1420 instructions per packet, which is insufficient to program the data plane that parses, de-parses, forwards, and applies services. This analysis is optimistic because it completely ignores memory bandwidth and focuses just on the CPU.

Two other factors are even more critical: latency and jitter. We have previously discussed a goal of a few microseconds as the maximum latency introduced by a DSN with a jitter of less than a microsecond and as close as possible to zero.

General-purpose processors, when used as packet processors, are not good at minimizing latency and jitter. They run a standard OS, with a standard scheduler whose goal is to maximize throughput. They try to limit context swapping with techniques such as interrupt moderation that by definition increases jitter.

All the problems discussed in [section 4.2.4](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch04.xhtml#ch04lev2sec2_4) about using or bypassing the kernel are present, but now they are embedded inside a domain-specific hardware device, instead of being present on the main server CPU.

It is not uncommon to have jitter and latencies in milliseconds, three orders of magnitude worse than our goal. Just open a terminal window and type **ping [google.com](http://google.com/)**. On my consumer home connection, I am getting an average latency of 15 ms, with a jitter of 2 ms; a DSN with latency and jitter of milliseconds is unusable.

To minimize jitter and latency, the OS can be removed from the processors and replaced by a technique familiarly called BLT (Big Loop Technology) in which a single code loop fetches the packets from the interfaces and process them. BLT reduces delay and jitter but negates some of the advantages of using general-purpose processors; the familiar toolchains, debugging, and troubleshooting tools don’t work anymore. All the OS libraries are no longer available. What is still safe is the possibility of programming in high-level languages like C.

It should also be mentioned that ARM has cores that are more suitable for the BLT [[10](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch10.xhtml#ch10ref10)]. They don’t support more advanced features such as virtualization (not required for BLT), but they have approximately the same packet processing power and are smaller, approximately half the size of an A72 core; therefore, it is possible to fit two of them in place of an A72, doubling the packet processing rate.

The sea of cores solution is not adequate for speeds of 100 Gbps or higher; It does not make the best use of the silicon area, and it provides inferior results in terms of throughput, latency, and jitter.

### 10.5 Understanding Field-Programmable Gate Arrays

Field-programmable gate arrays (FPGAs) [[11](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch10.xhtml#ch10ref11)] are integrated circuits that can be programmed to perform a particular function after they are manufactured. They have been around for many years and in their initial design were just an array of gates with a programmable interconnection. Using a CAD tool, system designers can develop a programming file that defines the interconnections between the gates, which can be downloaded into FPGA so it can perform the desired functions.

FPGAs carry the promise of perfect programmability because they can be entirely reprogrammed by downloading a new configuration file. Unfortunately, this programmability comes at a cost: FPGAs are less dense and more power hungry than ASICs. But more on this later.

Conventional FPGAs are not optimized for building a DSN; they have building blocks like digital signal processors that have no applicability in a DSN, and they lack standard blocks like Ethernet MAC and PCIe. This creates difficulties in obtaining a stable device at high speeds.

FPGAs have recently grown in size and complexity and are now available in a system on chip (SoC) version. These are combinations of hard and soft functions.

Examples of hard functions are an ARM core complex, PCIe interfaces, PAM-4 Ethernet interfaces, and DDR4 memory interfaces [[12](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch10.xhtml#ch10ref12)].

The soft part is the programmable one, which is generally expressed in terms of the number of logical elements (LEs) and adaptive logic modules (ALMs).

An LE, also known as a logical cell, is a four-input logical block that contains a programmable look up table (LUT), basically a four-input truth table, and a flip-flop (a memory bit).

An ALM is a more complex element that supports up to eight inputs, eight outputs, two combinational logic cells, two or four registers, two full adders, a carry chain, a register chain, and LUT mask. An ALM can implement substantially more complicated logical functions than an LE.

For example, the Intel Agilex AGF 008 [[13](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch10.xhtml#ch10ref13)] is an SoC that contains 764,640 LEs, 259,200 ALMs, DDR4 interfaces, 24x PAM-4, a quad-core 64-bit ARM Cortex-A53, and so on.

These features are desirable, but as we already mentioned, the most obvious drawbacks are high power consumption and high cost.

A dated study (2007) on the power consumption of FPGAs/ASICs [[14](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch10.xhtml#ch10ref14)] showed a ratio between 7.1 and 14; that is, approximately one order of magnitude. FPGAs have improved, but so have ASICs, and FPGA power consumption upto 100 Watts is typical, while some cards can use up to 215 Watts [[15](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch10.xhtml#ch10ref15)], very far from our target of 25 Watts for a DSN.

Cost is not relevant for small production, but it becomes crucial for high volumes. Here is where ASICs excel.

But there is another issue with FPGAs that is less understood and fundamental: programmability.

The term *programmability* is typically associated with processors that execute instructions sequentially. These instructions are the components of software programs that are written in a high-level programming language like C.

FPGAs are programmable, but not in the traditional way processors are. FPGAs are programmed using a hardware description language (HDL). The two most common HDLs are VHDL and Verilog. They describe hardware structures, not software programs. They may have a friendly C-like syntax that may induce you to think that you are writing C programs, but nothing can be farther from the truth. Software programs consist of a sequence of operations, whereas HDL code describes an interconnection of logic blocks and the functions performed by each block. HDL codes hardware structures, not software programs.

Suppose you write two software functions in C and want to use them in the main program; very easy: call them from the main. Now consider the case in which you have coded two hardware structures in Verilog, successfully tested them separately on an FPGA, and want to merge them in the same FPGA. It is not easy. You will need to redesign a manually combined structure. HDLs do not have a composable semantic!

Let’s look at a more concrete example: two hardware structures to parse two network protocols. Each hardware structure has its packet parser, but in the merged structure, the FPGA needs to parse the frame only once, so you need to merge the two parsers manually.

FPGAs require a deep understanding of how hardware circuits and digital logic work. Merely asking a software engineer to write Verilog programs and hoping to get fantastic performance, high utilization, and low power consumption is unrealistic.

FPGAs are great devices for many applications, but in the author’s opinion, they are not a suitable implementation for a DSN.

### 10.6 Using Application-Specific Integrated Circuits

An application-specific integrated circuit (ASIC) is an integrated circuit designed for a specific purpose and not intended to be a general-purpose device. Computer-aided design (CAD) tools are used to create and simulate the desired features and to produce a full set of photolithographic masks required to fabricate the IC. For DSN implementation, we only consider full-custom design ASICs, even if cheaper solutions exist for simpler applications [[16](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch10.xhtml#ch10ref16)]. The full-custom process requires a capable team of hardware and ASIC engineers and a non-recurring engineering (NRE) investment that for 16 nm and 7 nm technologies reaches several millions of dollars.

Additional advantages are the ability to integrate fully verified components from libraries; for example, analog components, microprocessor cores, encryption modules, and state-of-the-art SerDes.

Evidence that ASICs are the best solution for high-performance network, storage, and security devices is everywhere. All routers, switches, and NIC cards are built using ASICs; not a single successful network switch uses a sea of cores or an FPGA in the data plane.

ASICs have been criticized for being rigid and not as flexible as FPGAs. The introduction of a new feature requires a new generation of ASICs, and turnaround time may be an issue. The turnaround time is mostly dependent on the quality and determination of the ASIC team: I have seen ASIC solutions evolving faster than FPGA ones, but I have also seen designs stagnating forever.

In the specific case of ASICs used to implement a DSN, we have already seen that the ASIC is an SoC that includes processors. Therefore, it is the software that implements features in the management and control planes, providing all the desirable flexibility.

The data plane also requires flexibility to have an ASIC architecture that allows the addition of new features or the modification of existing ones without having to respin the ASIC. Here is where the P4 architecture, discussed in the next chapter, plays a vital role because P4 provides a programmable data plane.

ASICs are the best solution for proper silicon utilization; that is, to produce a DSN that has:

- Reduced area, with high transistor density, and high transistor utilization

- A lower cost per chip when mass-produced, and the NRE is amortized

- The best possible performance in terms of packets per seconds

- A packet latency that is known and limited to a low number

- The minimum packet jitter

- The minimum power consumption

### 10.7 Determining DSN Power Consumption

One criterion that has been proposed to compare all these approaches is to measure how much power is required by a DSN to process a packet in nanojoule.

The joule is a derived unit of energy in the International System of Units [[19](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch10.xhtml#ch10ref19)]. It is equal to the energy dissipated as heat when an electric current of 1 ampere passes through a resistance of 1 ohm for 1 second.

According to this definition, we can classify DSNs according to nanojoule per packet or nanowatt per packet per second. Because network device performance is expressed in pps (packets per second), this book uses nanowatt/pps, which is identical to nanojoule per packet.

In [section 10.4](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch10.xhtml#ch10lev1sec4) we saw that “an ARM A72 normalized at 1 GHz will process approximately a half Gbps of bandwidth.” In 16 nm, a complex of four ARM cores at 2.2 GHz consume approximately 2.9 Watts and process 0.5 Gbps × 4 × 2.2 = 4.4 Gbps. With an average packet length of 256 bytes (plus 24 bytes of Ethernet interpacket gap, preamble, and CRC) or 2,240 bits, this is equal to 1.96 Mpps, thus resulting in average power consumption of 1,480 nanowatt/pps. At 7 nm, four quad-cores at 3 GHz consume approximately 12.4 Watts and process 0.5 Gbps × 16 × 3 = 24 Gbps, equal to 10.7 Mpps, equal to 1,159 nanowatt/pps.

In [section 10.6](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch10.xhtml#ch10lev1sec6) we didn’t discuss the power consumption of DSN ASIC, but in [Chapter 8](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch08.xhtml#ch08), “[NIC Evolution](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch08.xhtml#ch08),” we presented several modern NIC and SmartNIC cards that have a power consumption between 25 Watts and 35 Watts and implement some form of DSN in ASIC at 100 Gbps. It equates to 45 Mpps (100 Gbps / 2240 bit/packet) and power consumption of 560 to 780 nanowatt/pps. This also depends on the technology. In 16 nm, power consumption around 780 nanowatt/pps should be common; in 7 nm, the power consumption should be half of that, targeting 390 nanowatt/pps, but probably more realistically 500 nanowatt/pps.

In [section 10.5](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch10.xhtml#ch10lev1sec5) we discussed the fact that FPGAs consume on average four times the power of ASICs, placing them at approximately 2,000 nanowatt/pps. This seems to be confirmed by a 100 Gbps/ 45 Mpps implementation in FPGA that consumes 100 Watts; that is 2,222 nanowatt/pps. [Table 10-2](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch10.xhtml#ch10tab2) tries to summarize the results, that are qualitative in nature and have significant variations among different implementations.

**TABLE 10-2** DSN Power Consumptions

| DSN at 100 Gbps Technology | Power Consumption nanowatt/pps or nanojoule per packet[2](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch10.xhtml#ch10tabf2) |
| --- | --- |
| ARM A72 at 2.2 GHz — 16 nm | 1,480 |
| ARM A72 at 3.0 GHz — 7 nm | 1,159 |
| ASIC 16 nm | 780 |
| ASIC 7 nm | 500 |
| FPGA | 2000 |

[2](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch10.xhtml#rch10tabf2) 256 bytes per packet

### 10.8 Determining Memory Needs

Independently of the solution adopted, DSNs require large memories, including to buffer packets; to store flow tables used by firewalls, load balancers, NAT, and telemetry; and to store code for control and management planes. A DSN may need several gigabytes of memory, and these large amounts come only in the form of Dynamic RAM (DRAM).

DRAM speed is also critical, and it is typically expressed in Mega Transactions per second (MT/s) or GigaBytes per second (GB/s). For example, a DDR4-1600 does 1600 MT/s with a parallelism of 64 bits, equivalent to 12.8 GB/s. These numbers are the transfer rate, also known as the burst rate, but due to how the information is stored inside the DRAM, only a fraction of that bandwidth is usable in a sustainable way. According to applications and read versus write usage, utilization between 65 percent and 85 percent have been reported.

In critical cases, utilization can go down to 30 percent for random 64-byte reads and writes, which is a pattern observed behind an L3 cache running typical workloads on one CPU core.

DRAMs can have several form factors, as described in the next sections.

#### 10.8.1 Host Memory

The host memory is an economical solution used by some NICs. The advantage is that host memory is abundant and relatively inexpensive; the main disadvantages are as follows:

- High access time and therefore low performance, because accessing host memory requires traversing the PCIe complex.

- The footprint on the host, because the memory used by the DSN is not available to the main server CPU, and it also requires a particular driver in the OS or hypervisor.

- Security, because the memory can be exposed to a compromised host. For this reason, in my opinion, this is not a viable solution for DSNs.

#### 10.8.2 External DRAM

DSNs may integrate memory controllers to use external DRAMs in the form of DDR4, DDR5, and GDDR6 devices. This solution provides higher bandwidth than the host memory solution, and it is probably slightly more expensive, but it can host huge forwarding tables and RDMA context at very high performance.

Double Data Rate 4 Synchronous Dynamic Random-Access Memory (DDR4) is available with a parallelism of 64 bits from DDR-4-1600 (1600 MT/s, 12.8 GB/s burst rate) to DDR-4-3200 (3200 MT/s, 25.6 GB/s burst rate) [[17](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch10.xhtml#ch10ref17)].

Double Data Rate 5 Synchronous Dynamic Random-Access Memory (DDR5) has the same 64-bit parallelism, and it supports DDR-5-4400 (4400 MT/s, 35.2 GB/s burst rate). In November 2018, SK Hynix announced the completion of DDR5-5200 (5200 MT/s, 41.6 GB/s burst rate) [[18](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch10.xhtml#ch10ref18)]. DDR5 is still under development at the time of writing.

Graphics Double Data Rate type 6 synchronous dynamic random-access memory (GDDR6), initially designed for graphics cards, can be used by a DSN. It has a per-pin bandwidth of up to 16 Gbps and a parallelism of 2 × 16 bits, for a total bandwidth up to 64 GB/s. GDDR6 is still under development at the time of writing.

Of course, with external DRAM, it is possible to deploy two or more controllers, further increasing the bandwidth available.

#### 10.8.3 On-chip DRAM

An ASIC cannot integrate all the DRAM required by a DSN. A solution used when an ASIC requires lots of DRAM with high bandwidth is to use a silicon interposer and insert into the same package a memory chip called high-bandwidth memory (HBM). [Figure 10-4](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch10.xhtml#ch10fig4) shows this configuration [[20](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch10.xhtml#ch10ref20)].

![The high-bandwidth memory configuration is shown. HBM and DSN chip are present at the top layer, silicon interposer is present in the middle layer, and the package substrate is present at the bottom layer.](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9780136624226/files/graphics/10fig04.jpg)

**FIGURE 10-4** High-Bandwidth Memory (HBM)

Today, HBM exists in two versions: HBM-1 with a maximum bandwidth of 128 GB/s, and HBM-2 with a maximum bandwidth of 307 GB/s.

#### 10.8.4 Memory Bandwidth Requirements

How much memory bandwidth is required is debatable.

All the previous solutions need to be complemented by on-chip caches to lower the average latency by exploiting temporal locality in packet flows.

For a cut-through solution that does not use the DRAM as a packet buffer, the memory bandwidth requirement is not huge. For example, 25 Mpps with ten table lookups per packet at 64 bytes equal 25 × 10 × 64 million = 16 GB/s, and all external DRAM solutions are adequate.

If packets need to be stored in DRAM for manipulation at 100 Gbps, this implies 100 Gbps of writing and 100 Gbps of reading, equivalent to 25 GB/s, plus the table lookup bandwidth, for a total of 40 GB/s–50 GB/s. Two channels of DDR5 or HBM-2 may be required for these solutions.

### 10.9 Summary

In this chapter, we discussed that a DSN is an SoC that uses CPU cores (usually ARM cores) for implementing the control and management planes in software.

The data plane implementation differs. In the sea of CPU cores approach, more CPU cores are used to implement the data plane in software. In the ASIC approach, hardware structures implement the data plane for maximum efficiency and performance. In the FPGA approach, the same ASIC circuitry is implemented in a programmable structure that is inherently less efficient than the ASIC one.

For a DSN, the data plane is the most critical component, and the only acceptable implementation is an ASIC. The next chapter reviews the P4 architecture that adds runtime programmability to the ASIC data plane.

### 10.10 Bibliography

**[[1](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch10.xhtml#rch10ref1)]** Intel, “AN 835: PAM4 Signaling Fundamentals,” 2019.03.12, [https://www.intel.com/content/dam/www/programmable/us/en/pdfs/literature/an/an835.pdf](https://www.intel.com/content/dam/www/programmable/us/en/pdfs/literature/an/an835.pdf)

**[[2](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch10.xhtml#rch10ref2)]** Wikipedia, “14 nanometers,” [https://en.wikipedia.org/wiki/14_nanometer](https://en.wikipedia.org/wiki/14_nanometer)

**[[3](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch10.xhtml#rch10ref3)]** Rachel Courtland, “Intel Now Packs 100 Million Transistors in Each Square Millimeter,” IEEE Spectrum, 30 Mar 2017. [https://spectrum.ieee.org/nano-clast/semiconductors/processors/intel-now-packs-100-million-transistors-in-each-square-millimeter](https://spectrum.ieee.org/nano-clast/semiconductors/processors/intel-now-packs-100-million-transistors-in-each-square-millimeter)

**[[4](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch10.xhtml#rch10ref4)]** Apple A12 Bionic - HiSilicon, WikiChip.org, [https://en.wikichip.org/wiki/apple/ax/a12](https://en.wikichip.org/wiki/apple/ax/a12)

**[[5](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch10.xhtml#rch10ref5)]** Kirin 980 - HiSilicon, WikiChip.org, [https://en.wikichip.org/wiki/hisilicon/kirin/980](https://en.wikichip.org/wiki/hisilicon/kirin/980)

**[[6](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch10.xhtml#rch10ref6)]** ARM Ltd., [https://www.arm.com](https://www.arm.com/)

**[[7](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch10.xhtml#rch10ref7)]** MIPS, [https://www.mips.com](https://www.mips.com/)

**[[8](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch10.xhtml#rch10ref8)]** Wikipedia, “ARM Cortex-A72,” [https://en.wikipedia.org/wiki/ARM_Cortex-A72](https://en.wikipedia.org/wiki/ARM_Cortex-A72)

**[[9](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch10.xhtml#rch10ref9)]** Pensando, Private communication.

**[[10](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch10.xhtml#rch10ref10)]** ARM developers, “Arm Cortex-R Series Processors,” [https://developer.arm.com/ip-products/processors/cortex-r](https://developer.arm.com/ip-products/processors/cortex-r)

**[[11](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch10.xhtml#rch10ref11)]** Wikipedia, “Field-programmable gate array,” [https://en.wikipedia.org/wiki/Field-programmable_gate](https://en.wikipedia.org/wiki/Field-programmable_gate)

**[[12](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch10.xhtml#rch10ref12)]** Intel AGILEX FPGAs and SOCs, [https://www.intel.com/content/www/us/en/products/programmable/fpga/agilex.html](https://www.intel.com/content/www/us/en/products/programmable/fpga/agilex.html)

**[[13](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch10.xhtml#rch10ref13)]** [https://www.intel.com/content/dam/www/programmable/us/en/pdfs/literature/pt/intel-agilex-f-series-product-table.pdf](https://www.intel.com/content/dam/www/programmable/us/en/pdfs/literature/pt/intel-agilex-f-series-product-table.pdf)

**[[14](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch10.xhtml#rch10ref14)]** I. Kuon and J. Rose, “Measuring the gap between FPGAs and ASICs,” in IEEE Transactions on Computer-Aided Design of Integrated Circuits and Systems (TCAD), 2007.

**[[15](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch10.xhtml#rch10ref15)]** Intel FPGA Programmable Acceleration Card (PAC) D5005, Product Brief, [https://www.intel.com/content/www/us/en/programmable/documentation/cvl1520030638800.html](https://www.intel.com/content/www/us/en/programmable/documentation/cvl1520030638800.html)

**[[16](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch10.xhtml#rch10ref16)]** Wikipedia, “Application-specific integrated circuit,” [https://en.wikipedia.org/wiki/Application-specific_integrated_circuit](https://en.wikipedia.org/wiki/Application-specific_integrated_circuit)

**[[17](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch10.xhtml#rch10ref17)]** Wikipedia, “DDR4 SDRAM,” [https://en.wikipedia.org/wiki/DDR4_SDRAM](https://en.wikipedia.org/wiki/DDR4_SDRAM)

**[[18](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch10.xhtml#rch10ref18)]** TechQuila, “SK Hynix Develops First 16 Gb DDR5-5200 Memory Chip,” [https://www.techquila.co.in/sk-hynix-develops-first-16-gb-ddr5-5200-memory-chip](https://www.techquila.co.in/sk-hynix-develops-first-16-gb-ddr5-5200-memory-chip)

**[[19](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch10.xhtml#rch10ref19)]** Wikipedia, “Joule,” [https://en.wikipedia.org/wiki/Joule](https://en.wikipedia.org/wiki/Joule)

**[[20](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch10.xhtml#rch10ref20)]** Wikipedia, “High-Bandwidth Memory,” [https://en.wikipedia.org/wiki/High_Bandwidth_Memory](https://en.wikipedia.org/wiki/High_Bandwidth_Memory)

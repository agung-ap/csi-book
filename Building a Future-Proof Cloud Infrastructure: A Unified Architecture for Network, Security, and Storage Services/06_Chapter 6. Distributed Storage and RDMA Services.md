## Chapter 6. Distributed Storage and RDMA Services

In previous chapters, we have discussed distributed application services that can be placed almost anywhere on the network. In this chapter, we focus on infrastructure services that require access to server memory, typically through a PCIe interface.

In the not-so-distant past, the typical server included up to three types of communication interfaces, each connected to a dedicated infrastructure network (see [Figure 6-1](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch06.xhtml#ch06fig1)):

- A network interface card (NIC) connecting the server to the LAN and the outside world

- A storage interface that could attach to local disks or a dedicated storage area network (SAN)

- A clustering interface for high-performance communication across servers in distributed application environments

![A figure depicts the connection of a host to the dedicated networks. A server is connected to three different interfaces: Infiniband Fabric (in turn to the RDMA cluster), Fibre Channel SAN (in turn to remote storage), and Ethernet network (that is IP network).](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9780136624226/files/graphics/06fig01.jpg)

**FIGURE 6-1** Host Connected to Dedicated Networks

Over the past two decades, the communication substrate for these infrastructure services has been mostly unified. The opportunity to significantly reduce costs has driven this convergence. Cloud deployments with their massive scales have dramatically accelerated this trend. Today, networking, distributed storage, and RDMA clustering all ride the ubiquitous Ethernet; see [Figure 6-2](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch06.xhtml#ch06fig2).

![A figure depicts the connection of hosts with unified networks. The typical server is connected to the unified Ethernet network that is in turn connected to RDMA Cluster, Remote storage, and interconnected IP network.](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9780136624226/files/graphics/06fig02.jpg)

**FIGURE 6-2** Hosts with Unified Networks

In spite of the physical network consolidation, the three discussed infrastructure services remain individually exposed to the host operating systems through distinct software interfaces; see [Figure 6-3](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch06.xhtml#ch06fig3). In all cases, these interfaces rely on direct memory access (DMA) to and from memory by the I/O adapter, most typically through PCIe.

![An architecture of a unified network software stack is depicted.](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9780136624226/files/graphics/06fig03.jpg)

**FIGURE 6-3** Unified Network Software Stack

In the figure, the layers of the unified network software stack are presented. The bottom-most is the converged Ethernet NIC. The top-most layer is comprised of: RDMA verbs, block storage interface, and sockets API. The middle layer contains the following: RDMA/RoCE stack, FCoE stack, TCP/UDP IP stack, NVMEoF, iSCSi, and block storage.

### 6.1 RDMA and RoCE

Computer clusters have been around for many decades with successful commercial products since the 1980s by Digital Equipment Corporation [[1](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch06.xhtml#ch06ref1)], Tandem Computers [[2](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch06.xhtml#ch06ref2)], Compaq, Sun, HP, and IBM.

In a world where individual CPUs could no longer evolve at the pace of Moore’s law, scaling out became the most viable way to satisfy the growing demand for compute-intensive applications. Over time, the move toward cloud services motivated the deployment of racks of standard servers at very large scale. Clusters of commodity servers have become the standard for the modern datacenter ranging from on-premise enterprise deployments all the way to public clouds.

In contrast to CPUs, communication technology continued to evolve at a steady pace and allowed bigger and better clusters. With faster networks came the demand for a more efficient I/O software interface that would address the communication bottleneck for high-performance distributed applications. In this context, the industry defined the Virtual Interface Architecture (VIA), intending to increase communication performance by eliminating host processing software overheads [[3](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch06.xhtml#ch06ref3)]. The objective: high bandwidth, low latency, and low CPU utilization.

These ideas were picked up in 1999 by two initially competing industry groups: NGIO and FutureIO. In the NGIO camp were Intel and Sun Microsystems, while IBM, HP, and Compaq led FutureIO. The head-to-head race to specify the new I/O standard was settled as both groups joined forces and created the InfiniBand Trade Association (IBTA), which in 2000 produced the first (InfiniBand) RDMA Specification [[4](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch06.xhtml#ch06ref4)], [[5](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch06.xhtml#ch06ref5)].

InfiniBand RDMA (Remote Direct Memory Access) was originally conceived as a vertically integrated protocol stack (see [Figure 6-4](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch06.xhtml#ch06fig4)) covering switches, routers, and network adapters and including from a physical layer up to software and management interfaces.

![A diagram illustrates the Infiniband protocol stack and fabric.](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9780136624226/files/graphics/06fig04.jpg)

**FIGURE 6-4** InfiniBand Protocol Stack and Fabric Diagram

The vertically integrated protocol stack consists of five layers from top to bottom labeled Upper-level protocols, Transport layer, Network layer, Link layer, and Physical layer. Two end nodes communicate to one another through these five layers. The upper level protocols layer involves client-level transactions. In the transport layer, the IBA operations of each node exchange messages. In the network layer, routing between the two nodes (IPv6) takes place. In the link layer, the end nodes connection is established using a switch and a router. The switch has links equipped by L2 bridge. The router uses the IPv6 router and links.

The value proposition of RDMA is mainly derived from the following four characteristics:

- **Kernel bypass:** A mechanism that allows secure and direct access to I/O services from userspace processes without having to go through the OS kernel; see [Figure 6-5](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch06.xhtml#ch06fig5). It eliminates a significant latency component and reduces CPU utilization.

- **Zero-copy:** The ability for the I/O device to directly read from and write to userspace memory buffers, thereby eliminating multiple copies of I/O data that is common with the OS-based software stack of traditional network protocols; see [Figure 6-6](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch06.xhtml#ch06fig6).

- **Protocol offload:** Message segmentation and reassembly, delivery guarantees, access checks, and all aspects of a reliable transport are offloaded to the NIC, eliminating the consumption of CPU resources for network protocol processing; see [Figure 6-7](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch06.xhtml#ch06fig7).

- **One-sided operations:** RDMA Read, Write and Atomic operations are executed without any intervention of the target-side CPU, with the obvious benefit of not spending valuable compute cycles on the target system; see [Figure 6-8](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch06.xhtml#ch06fig8). This asynchronous processing approach results in a significant increase in message rates and a drastic reduction in message completion jitter, as the processing completely decouples I/O execution from the scheduling of the receiver’s I/O stack software.

![A figure depicts the comparison of the Kernel network stack versus bypass mechanism.](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9780136624226/files/graphics/06fig05.jpg)

**FIGURE 6-5** Cost of I/O, Kernel Network Stack versus Bypass

In the figure, the mechanisms of zero copy and kernel buffer are compared. In the case of zero copy, the data is transferred from the application to the RDMA library to the RDMA NIC with Kernel bypass. No operation occurs in the OS kernel level. In the case of kernel buffer, data from application in the user level software level is transferred to the Ethernet NIC through Host IP stack and Ethernet driver in the OS kernel level.

![A figure depicts the comparison of the Kernel buffer versus the Zero-copy mechanism.](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9780136624226/files/graphics/06fig06.jpg)

**FIGURE 6-6** Kernel Buffer versus Zero-Copy

The Zero copy and the Kernel buffer consist of CPU (top), Memory controller or PCI root complex (center), and NIC card (bottom). Besides the Memory controller, the stack of host memory is present, which contains User app buffer and IP stack buffer. In the Zero-copy, the information from the User app buffer is sent to the NIC card, simply through memory controller. In the Kernel buffer, the information from the User app buffer is sent to the memory controller as step 1 followed by transmission to the IP stack buffer. The information from the IP stack buffer is sent to the NIC card as step 2.

![A figure shows the comparison of software stack versus protocol offload mechanism.](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9780136624226/files/graphics/06fig07.jpg)

**FIGURE 6-7** Software Stack versus Protocol Offload

The protocol offload and software stack consists of two sections, Software running on host CPU and Hardware. In the protocol offload, the software section includes two layers in between the RDMA verbs such as application and RDMA library at the top and RDMA control plane at the bottom. The hardware section includes RDMA NIC that is, RDMA transport segmentation and reassembly reliable delivery. The information from the application is directly fed to the RDMA NIC. In the software stack, the software section includes two layers in between the sockets API such as application at the top and TCP or UDP IP stack segmentation and reassembly reliable delivery (packet per packet) and Ethernet driver at the bottom. The hardware section includes Ethernet NIC. The information is processed each stage from the application to the Ethernet NIC.

![A diagram illustrates the one-sided operations ladder.](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9780136624226/files/graphics/06fig08.jpg)

**FIGURE 6-8** One-sided Operations Ladder Diagram

The input/output request and the response of RDMA are processed in a ladder manner. Three vertical lines are shown on the left labeled Source side software running on host CPU, Source side memory, and Source side RDMA NIC. Three vertical lines are shown on the right labeled Target side RDMA NIC, Target side memory, and Target side software running on the host CPU. The operations are carried out in six steps as follows, Step 1: The RDMA IO request is sent from the source side software running on host CPU to the source side RDMA NIC. Step 2: The memory access is loop backed from the source side RDMA NIC via the source side memory. Step 3: The request from the RDMA NIC is processed and sent to the target. Step 4: The target NIC is processed without target CPU intervention and sends a response back to the source. This response is sent to the source through target side memory access. Step 5: From the target side RDMA NIC, the response is received and the status is sent back to requester application. Step 6: The complete response of RDMA IO is sent from the source side RDMA NIC to the source side software running on the host CPU.

#### 6.1.1 RDMA Architecture Overview

The term *RDMA*, denoting this infrastructure service, is a little bit of a misnomer. The so-called RDMA service includes actual RDMA (Remote Direct Memory Access) operations alongside traditional SEND/RECEIVE message semantics. Most fundamentally, the RDMA service implements a quite different I/O model than that of traditional networks.

Central to the RDMA model is the notion of Queue Pairs (QPs). These are the interface objects through which consumer applications submit I/O requests. A Queue Pair comprises a Send Queue (SQ) and a Receive Queue (RQ) and operates in a way that is somewhat similar to how Send and Receive Rings work on traditional Ethernet interfaces. The fundamental difference is that each RDMA flow operates on top of its own dedicated QP, and these QPs are directly accessed from their respective consumer processes without any kernel driver intervention in the data path.

RDMA operations, normally referred to as work requests (WRs), are posted into SQs and RQs and asynchronously serviced by the RDMA provider (that is, the RDMA NIC). Once executed and completed, the provider notifies the consumer process through Completion Queues (CQs); see [Figure 6-9](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch06.xhtml#ch06fig9). Consumer processes may have one or more CQs that can be flexibly associated with their QPs.

![An architecture of RMDA with the process of Queue pairs (QPs), Work request (WRs), Completion queues (CQs), and Scheduler or Quality of service (QoS).](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9780136624226/files/graphics/06fig09.jpg)

**FIGURE 6-9** QPs, WRs, CQs, and Scheduler/QoS Arbiter

Two userspace RDMA consumers and one kernel RDMA consumer are shown. The first userspace RDMA consumer has two send queue (SQ), two receive queue (RQ), and a completion queue (CQ). The work request (WR) in the SQ and RQ are sent to the QP and further pending works are sent to the QoS arbiter. The Queue pairs send the CQE job to the Completion queues. The second userspace RDMA consumers and kernel RDMA consumer have one SQ and RQ, and two CQ each. The same process as the first userspace RDMA consumer is carried out in the second userspace RDMA consumer. The information from the QoS arbiter is the resulted output. The QPs and the RDMA NIC are collectively part of hardware. The entire Kernal RDMA consumer is labeled software running on the host CPU.

The RDMA provider guarantees QP access protection across multiple consumers via a combination of regular host virtual memory and the mapping of I/O space into each process’s own space. In this manner, user processes can exclusively access their respective RDMA resources. Typically, each process is assigned a dedicated page in the I/O address space of the RDMA NIC that is mapped to the process’s virtual memory. The process can then directly interact with the RDMA NIC using regular userspace memory access to these mapped addresses. The NIC, in turn, can validate legitimate use of the corresponding RDMA resources and act upon the I/O requests without the intervention of the OS kernel.

As a corollary to the direct access model and the individual flow interfaces (that is, QPs) being visible to the NIC, fine-grained QoS is a natural characteristic of RDMA. Most typically, RDMA NICs implement a scheduler that picks pending jobs from QPs with outstanding WRs following sophisticated programmable policies.

To allow direct I/O access to/from user-level process buffers, the RDMA model includes a mechanism called *memory registration*. This facility is used to pin into physical memory the user memory ranges that are meant to be used as the source or target of RDMA operations. In addition to pinning, during memory registration, the RDMA provider updates its memory mapping table with the physical addresses of the registered buffers and returns a memory key to the RDMA consumer process. Once registered, consumer processes can then refer to these memory regions in their submitted work requests, and the RDMA NIC can directly access these buffers during execution (that is, zero-copy).

#### 6.1.2 RDMA Transport Services

The RDMA protocol standard originally defined two connection-oriented transport services: Reliable Connected (RC), Unreliable Connected (UC); and two datagram services: Reliable Datagram (RD) and Unreliable Datagram (UD); see [Figure 6-10](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch06.xhtml#ch06fig10). The most commonly used ones are RC and UD. UC is rarely used and RD was never implemented.

![Transport service of RDMA is depicted.](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9780136624226/files/graphics/06fig10.jpg)

**FIGURE 6-10** RDMA Transport Services

The RDMA transport and datagram services are given in the form of a two-cross-two grid. The connected services include two implementations known as reliable connected (RC) and unreliable connected (UC). The datagram services include two implementations known as reliable datagram (RD) and unreliable datagram (UD). Reliable connected and unreliable datagram are the most commonly used services.

As far as reliability and connection characteristics are concerned, RC could be seen as the logical equivalent of the well-known TCP. A lot of the RDMA value proposition requires this transport service, and hence most RDMA consumer applications use it. Meanwhile, the UD transport service resembles UDP, and RDMA consumers use it mostly for management and control operations.

Over time, a new XRC transport service was added to the specification. It is a variation on RC that is mostly relevant for reducing the number of connections in scenarios with lots of processes per node.

#### 6.1.3 RDMA Operations

The RDMA protocol includes Send/Receive semantics, RDMA Read/Writes, and Atomics.

Even though Send/Receives are semantically similar to their traditional network counterparts, the RDMA version leverages the kernel-bypass, the zero copy, and the reliable transport protocol offload of RDMA. In this way, consumer applications can attain low latency, high bandwidth, and low CPU utilization without significant changes to their communication model.

The Remote Direct Memory Access (RDMA) operations, RDMA Read and RDMA Write, give their name to the protocol. The main difference between these and Send/Receive is the one-sided nature of the execution. RDMA accesses complete with no intervention of the target-side CPU. Consumer applications can asynchronously read and write from and to remote node memory locations, subject to strict access right checks. Applications that have been coded for the explicit use of RDMA services typically exploit the full value proposition via RDMA Reads and Writes.

RDMA Atomic operations allow one-sided atomic remote memory accesses. The InfiniBand RDMA standard defines 64-bit CompareAndSwap and FetchAndAdd operations, but over time vendors have extended the support to longer data fields and other variants such as the support for masked versions of the operations. Among others, RDMA Atomics are widely used by distributed lock applications and clustered database systems.

#### 6.1.4 RDMA Scalability

The InfiniBand RDMA architecture follows very strict protocol layering and was designed with a hardware implementation in mind. However, not all RDMA implementations are created equal. One challenge is that of delivering RDMA services at scale. The offloaded nature of the RDMA model mandates per-flow context structures of considerable size. Reasonably, the more RDMA flows, the more state the RDMA NIC needs to maintain. It’s not rare for consumer applications to demand tens and hundreds of thousands of RDMA flows with some even reaching the millions. One possible approach is that of caching context structures on the RDMA device itself while maintaining the complete state tables in host memory. When there is significant locality in RDMA flow usage, this type of solution can deliver adequate performance. However, for several deployment scenarios, context cache replacement may introduce significant performance jitter. With these use cases in mind, high-scale RDMA NICs have been designed with onboard dedicated context memory that can fit the entire RDMA protocol state.

#### 6.1.5 RoCE

In addition to the software interface advantages of the RDMA model, InfiniBand dominated the high-performance clustering space, thanks to the performance advantage of its dedicated L1 and L2 that was at that time faster than that of the much more established Ethernet. A few years later, as 10Gig and 40Gig Ethernet turned out to be more common, it became apparent that the same benefits of RDMA could be obtained over the ubiquitous Ethernet network. Two standards emerged to address this approach, iWARP and RoCE. iWARP defined RDMA semantics on top of TCP as the underlying transport protocol [[6](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch06.xhtml#ch06ref6)]. Meanwhile, the IBTA defined RoCE by merely replacing the lower two layers of its vertical protocol stack with those of Ethernet [[7](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch06.xhtml#ch06ref7)].

The first version of RoCE did not have an IP layer and hence wasn’t routable. This happened at pretty much the same time as FCoE was being defined under the similar vision of flat L2-based networks. Eventually, it became clear that Routable RoCE was required, and the spec further evolved to become RoCEv2, defining the encapsulation of RDMA on top of UDP/IP [[8](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch06.xhtml#ch06ref8)]. In addition to making RoCE routable, RoCEv2 leverages all the advantages of the IP protocol, including QoS marking (DSCP) and congestion management signaling (ECN).

The resulting architecture is depicted in [Figure 6-11](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch06.xhtml#ch06fig11). The first column from the left represents the classical implementation of InfiniBand RDMA. The middle column is ROCEv1 (no IP header, directly over Ethernet), and the third column is RoCEv2 in which the InfiniBand transport layer is encapsulated in IP/UDP.

![An illustration of RDMA over Ethernet protocol stack evolution is depicted.](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9780136624226/files/graphics/06fig11.jpg)

**FIGURE 6-11** RDMA over Ethernet Protocol Stack Evolution

The architecture consists of five layers. The first two layers: RDMA application or ULP and RDMA stack that includes RDMA verbs are in the software level. The remaining three layers are in the hardware level. The three layers are defined in three communication interfaces known as InfiniBand, RoCE, and RoCE v2. The InfiniBand includes IB transport protocol, IB network layer, and InfiniBand link layer. The RoCE includes IB transport protocol, IB network layer, and Ethernet link layer. The RoCE v2 includes IB transport protocol, UDP, IP, and Ethernet link layer.

#### 6.1.6 RoCE vs iWARP

iWARP and RoCE are functionally similar but not identical in terms of the RDMA services that they offer. There are some semantic differences between the two protocols and a few functional aspects of RoCE that were not covered by the iWARP specification. In practice, iWARP didn’t attain a wide adoption in the market, due in part to the fact that the RoCE specification is much more suitable for efficient hardware implementations. [Figure 6-12](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch06.xhtml#ch06fig12) illustrates the protocol stack differences between the two.

![A figure depicts the differences between iWARP and RoCE protocols.](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9780136624226/files/graphics/06fig12.jpg)

**FIGURE 6-12** RoCE versus iWARP

The iWARP protocol consists of six layers from top to bottom labeled RDMAP, DDP, MPA, TCP, IP, and Ethernet. The RoCE protocol consists of four layers. In RoCE protocol, the first four layers of the iWARP are combined as IBTA transport protocol. The remaining three layers are labeled UDP, IP, and Ethernet.

#### 6.1.7 RDMA Deployments

RDMA was initially deployed in high-performance computing (HPC) where ultra-low latency and high bandwidth dominate the requirements. The cost/performance advantages were so drastic that in a few years InfiniBand debunked well-established proprietary networks and became the de facto standard for top-end HPC clusters; see [Figure 6-13](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch06.xhtml#ch06fig13). This broad adoption in the HPC space fueled the development of high-end RDMA and made it a more mature technology [[9](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch06.xhtml#ch06ref9)].

![An area chart shows the share percentage of InfiniBand and Ethernet.](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9780136624226/files/graphics/06fig13.jpg)

**FIGURE 6-13** InfiniBand and Ethernet Shares (Data courtesy of top500.org)

The InfiniBand and Ethernet shares are shown in an area chart. The horizontal axis ranges from December 2005 to December 2012 in increments of 3 months. The vertical axis representing percentage, ranges from 0 to 100, in increments of 10. The range of Ethernet shares is between 0 to 50 percent in December 2005 and is between 0 to 40 percent in December 2012. The share is fluctuating in and around this range for the given period. The peak value of 55 percent is noted in March 2008 and a minimum of 40 percent is noted in June 2007. The range of Infiniband is between 50 to 55 percent in December 2005 and is between 40 to 85 percent in December 2012. The peak value of 90 percent is noted in June 2009 and a minimum of 55 percent is noted in December 2005. The range of other shares is between 55 to 100 percent in December 2005 and 85 to 100 percent in December 2012. Note that the mentioned values are approximate.

Embedded platforms were also among the early adopters of RDMA technology. Examples included data replication in storage appliances, media distribution, and others. The unrivaled performance of RDMA and the fact that it was an open standard with a visible roadmap into the future made the solution very attractive to this market that traditionally aims for long-term investments in technology.

One other major milestone in the growth of RDMA was the adoption of the technology at the core of Oracle’s flagship clustered database [[10](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch06.xhtml#ch06ref10)]. This use case was instrumental in bringing RDMA into the enterprise network.

Another wave of early adoption came when the financial market identified a significant edge for market data delivery systems in the ultra-low latency of InfiniBand.

Currently, RoCEv2 offers the RDMA value proposition on Ethernet networks with applications covering remote storage protocols, database clustering, nonvolatile memory, artificial intelligence, scientific computing, and others.

Mellanox Technologies has been one of the most significant contributors to the InfiniBand technology; [Figure 9-6](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch09.xhtml#ch09fig6) shows a Mellanox ConnectX-5 Dual-Port Adapter Supporting RoCEv2 over two 100Gb/s Ethernet ports.

#### 6.1.8 RoCEv2 and Lossy Networks

Due to the simplicity of its transport protocol, RDMA performance is quite sensitive to packet losses. Very much like FCoE, the RDMA protocol was designed with the assumption of an underlying lossless network. The network was indeed lossless when RDMA was running on InfiniBand Fabrics and, when RoCE was defined, the IEEE 802.1 was in the process of standardizing a set of Ethernet specs usually referred to as Data Center Bridging (DCB), which, among other things, offered non-drop (also known as “lossless”) priorities through Per-Priority Flow Control (PFC). RoCE and FCoE were both originally defined to leverage PFC to satisfy the lossless requirement [[11](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch06.xhtml#ch06ref11)].

With PFC, each of the eight priorities (from 0 to 7) can be configured as lossless or lossy. Network devices treat the lossy priorities as in classical Ethernet and use a per-priority pause mechanism to guarantee that no frames are lost on the lossless priorities.

[Figure 6-14](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch06.xhtml#ch06fig14) illustrates this technique: Priority 2 is stopped by a pause frame to avoid overflowing the queue on the switch side and thus losing packets.

![An illustration shows the priority flow control via Ethernet links.](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9780136624226/files/graphics/06fig14.jpg)

**FIGURE 6-14** Priority Flow Control

The priority flow control is shown. There are seven sets of priorities (labeled from zero to seven) in transmit queues (NIC) and receive queues (switch). The transmit queue and receive queue are present on either side and the Ethernet links are present in between, mapping the transmit queues to their respective receive queues. Priority two in the transmit queue is stopped by a pause frame from priority two in the receive queue.

Alongside PFC, IEEE has standardized DCBX (Data Center Bridging eXchange) in an attempt to make I/O consolidation deployable on a larger scale. DCBX is a discovery and configuration protocol that guarantees that both ends of an Ethernet link are configured consistently. DCBX works to configure switch-to-switch links and switch-to-host links correctly to avoid configuration errors, which can be very difficult to troubleshoot. DCBX discovers the capabilities of the two peers at each end of a link: It can check for consistency, notify the device manager in the case of configuration mismatches, and provide a basic configuration in case one of the two peers is not configured. DCBX can be configured to send conflict alarms to the appropriate management stations.

While these DCB techniques can be appropriately deployed and do not present any conceptual flaws, there has consistently been significant concerns from the IT community that prevented their mainstream deployment. Criticism has been fueled by some unfortunate experiences, lack of tools for consistency checks and troubleshooting, and distance limitation both in terms of miles and hops.

In light of the preceding, it became quite clear that PFC was not poised to become widespread and hence FCoE and RoCEv2 would need an alternative solution. In other words, to gain wide adoption, RDMA and Remote Storage over Ethernet need to be adapted to tolerate a non-lossless network. For storage, the real solution comes from NVMe and NVMe over Fabrics (NVMe-oF), which runs on top of RDMA or TCP and leverages their respective transport protocol characteristics as described in [section 6.2.2](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch06.xhtml#ch06lev2sec2_2). For RoCEv2, modifications to the protocol have been implemented as described in the following section.

To properly understand the scope of the problem, it’s crucial to establish what defines a *lossy network*. In a nutshell, in modern Ethernet networks, there are two leading causes for packet losses.

The first type of packet drops is literally produced by the forces of nature (for example, alpha particles) that every once in a while cause a bit flip on a packet while it’s being transmitted or stored in a network device. This data corruption will be detected by CRCs and will result in the packet’s being dropped. In modern data centers and enterprise networks, the probability for these events is very low. This kind of packet loss does occur on the so-called lossless networks; but given the low occurrence rate and the fact that it typically affects a single packet, simple retransmission schemes can effectively overcome it.

The second type of loss comes as a result of congestion. When there is contention on the output port of a network device and this contention lasts until its buffers fill up, the device will have no choice but to start dropping packets. This congestion-induced loss is much more severe and is the actual cause for significant reductions in performance. As described earlier, in a “lossless” network, this problem is addressed with link layer flow control that effectively prevents packets from arriving at a device unless there is enough buffer space to store them.

The strategy to solve the second problem, without using any link-layer flow control, centers around two complementary approaches. First, reduce contention by applying congestion management. With this technique, upon buffer buildup, a closed loop scheme controls injection at the source, thereby reducing the contention and minimizing the cases of packet drop. With congestion reduced to a minimum, the second technique focuses on the efficient retransmission of the few remaining dropped packets. These packet losses are inevitable, but fewer, thanks to congestion management.

Specifically, with RoCEv2, Data Center Quantized Congestion Notification (DCQCN) [[12](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch06.xhtml#ch06ref12)] congestion management has been deployed to minimize drops and was shown to greatly improve overall network performance. The components of DCQCN are depicted in [Figure 6-15](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch06.xhtml#ch06fig15). DCQCN relies on explicit congestion marking by switches using the ECN bits in the IP header [[13](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch06.xhtml#ch06ref13)]. Switches detect congestion through monitoring of their queue sizes. When a queue size crosses a programmable threshold, switches start to probabilistically mark packets indicating that these are crossing a congestion point. Upon receiving such marked packets, the destination node reflects this information to the source by using an explicit congestion notification packet (CNP). The reception of the CNP results in a reduction in the injection rate of the corresponding flow using a specified algorithm with configurable parameters. It has proven to be somewhat challenging to tune the DCQCN thresholds and parameters to obtain good congestion management performance under a wide variety of flows.

![A figure presents the components of the Data Center Quantized Congestion Notification.](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9780136624226/files/graphics/06fig15.jpg)

**FIGURE 6-15** DCQCN

A figure shows the DCQCN components. The sender Network Interface Controller, a switch, and a receiver Network Interface Controller are present. Congested traffic is sent from the sender NIC to the switch (congestion point), and a congestion marking is marked from the switch to the receiver NIC. A congestion notification (high priority) is sent from receiver NIC to sender NIC.

A newer approach under development utilizes a different congestion signaling scheme that is based on measuring latencies at the end nodes and reacts to queue buildup by detecting a latency change or spike; see [Figure 6-16](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch06.xhtml#ch06fig16). This new scheme has faster response times than DCQCN and offers the additional benefit of not requiring the tuning of queue thresholds in the switches or other parameters. This mechanism is completely implemented at the end nodes without any reliance on switches.

![A figure illustrates one-way latencies.](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9780136624226/files/graphics/06fig16.jpg)

**FIGURE 6-16** One-way Latencies

The process of a one-way latency is shown in the figure. The sender and receiver are present. Two packets 1 and 2 (sender timestamps) are sent from the sender to the receiver. The distance between the two packets in the sender represents the delta of the sender and the distance between the packets in the receiver represents the delta of the receiver. The delta of the sender is lesser than the delta of the receiver and hence there is an increase in congestion.

Congestion management will significantly improve the performance of RDMA in lossy networks by minimizing congestion-induced packet loss. However, in practice it’s impossible (actually, extremely inefficient) to guarantee absolutely no drops under all possible conditions, no matter how good the congestion management scheme is. The reaction time for congestion management extends from the moment congestion is detected, through the point where the source reduces the injection rate, and until the reduced rate arrives back at the congested point. During this period, packets continue to accumulate at the higher rate, and it could so happen that buffers overflow and packets are dropped. This delayed reaction characteristic is typical of closed-loop control systems. The congestion management algorithm could be tuned for more aggressive injection rate changes, thereby inducing a quicker reaction, to mitigate the impact of control loop delay. However, an over-aggressive scheme would generally create a prolonged underutilization of the available bandwidth. In essence, there is a tradeoff between the possibility of some packet drops versus utilization of all available bandwidth, and in general it’s best to tune for minimal (but non-zero) drops.

Even with very effective and adequately tuned congestion management, some packets may be dropped. At that point, it’s the job of the communication protocol to deal with recovery. The transport layer of the RDMA protocol, as currently defined in the RoCEv2 standard, utilizes a very simplistic approach for this task. Upon detection of a missing packet, the receiver sends a NAK code back to the sender indicating the sequence number of the missed packet. The sender rolls back its state and resends everything from that point on. This “Go Back N” approach was conceived with the assumption of an underlying lossless fabric, and it’s not ideal in the presence of congestion-induced drops.

To address this limitation, modern RoCEv2 implementations introduced a selective retransmission scheme that is much better at recovering from losses; see [Figure 6-17](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch06.xhtml#ch06fig17). The main goal is to recover faster and conserve network bandwidth by resending only the lost packets.

![Two figures show how Go Back N and selective retransmissions are implemented.](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9780136624226/files/graphics/06fig17.jpg)

**FIGURE 6-17** Go Back N versus Selective Retransmission

The Go Back N and selective retransmission implementations are shown. In the Go back N approach, several packets such as PSN 1, PSN 2, etcetera are sent to the receiver. Packets 3, 4, 5, and 8 are lost at the sender's end and packets 6, 7, and 9 are lost at the receiver's end. A negative acknowledgment "NAK 2" is sent after the loss of the seventh packet, which reaches the sender after the loss of packet 9. The packets 3 to 8 are resent, in which packet 7 is lost in the sender's end. A negative acknowledgment "NAK 6" is sent after packet 8. Packets 7 and 8 are resent to the receiver. In the Selective retransmission approach, the negative acknowledgment "NAK 2 is sent after the loss of packet 7 and lost packets 3, 4, and 5, are resent, after which packets 10 and 11 are sent. A negative acknowledgment "NAK 7 [8,8]" is sent after packet 10, indicating the loss of packet 8. Packet 8 is sent to the receiver and the next packet to be sent is packet 12.

Selective retransmission has been implemented in TCP for quite some time. The resending of individual packets from the source is quite straightforward. The challenge in RDMA networks is mainly at the receiver and has to do with the protocol requirement for in-order processing of inbound packets. For example, a multipacket RDMA Write message only carries the destination address in its first packet. If that packet is lost, subsequent ones can’t be placed into their intended memory destinations. Attempts have been discussed to modify the message semantics to allow for out-of-order processing of inbound packets. However, such an approach would have a significant impact on existing RDMA protocol semantics that would be visible to consumer applications. A much more friendly approach (see [Figure 6-18](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch06.xhtml#ch06fig18)) completely preserves existing semantics and is implemented with the help of a staging buffer that is used to temporarily store subsequent packets until the lost ones arrive after being resent. RDMA NIC architectures that support efficient on-NIC memory are particularly suitable for this type of solution.

![A figure is shown for the staging buffer cost of selective retransmission.](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9780136624226/files/graphics/06fig18.jpg)

**FIGURE 6-18** Staging Buffer Cost of Selective Retransmission

The staging buffer cost of selective retransmission is shown. From the sender's end, several packets, such as PSN 1, PSN 2, etcetera are sent to the receiver. The packets 3, 4, 5, and 8 are lost in the sender's end and packets 6, 7, and 9 are lost in the receiver's end. A negative acknowledgment "NAK 2 [3, 5]" is sent from the receiver's end after the loss of the seventh packet, indicating the loss of packets 3 to 5, which reaches the sender after the failure of packet 9. The lost packets are resent to the receiver, after which packets 10 and 11 are sent to the receiver. A negative acknowledgment "NAK 7 [8, 8]" is sent after packet 10, indicating the loss of the packet 8, which is resent to the receiver. After this, packet 12 is sent and a negative acknowledgment NAK 11 is received from the receiver's end. To the right of the receiver's end, is their respective receiver window number, starting from 50 and extending till 62. The staging buffer occupancy window is present to the right. The lost packets on the receiver's end (6, 7, and 9) are stored in the staging buffer near the receiver window 52. Packets 9, 10, and 11 are stored in the staging buffer near window 57.

As described earlier, the RDMA transport protocol detects missing packets at the target and utilizes explicit NAKs to trigger immediate resends. With selective retransmission, this scheme is efficient except for the case when the lost packets are the last in the message (also known as tail drops), as there are no subsequent packets to detect the loss and trigger the NAK. For this case, the transport protocol relies on a timeout at the sender that kicks in when there are outstanding unacknowledged packets for much longer than expected. However, to prevent unnecessary retransmissions due to latency variations, this timeout is intended to be set to a value that is much higher than the typical network round trip. The effect is that, in case of a tail drop, the completion time of the message is severely impacted. Some RDMA implementations send an unsolicited ACK from the target back to the source, when no further packets are being received on an active flow, to improve the recovery time in the presence of a tail drop; see [Figure 6-19](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch06.xhtml#ch06fig19). The receiver is in a much better position to eagerly detect the potential loss of a tail in a way that is entirely independent of the fabric round trip latency.

![A figure illustrates the Tail drop recovery.](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9780136624226/files/graphics/06fig19.jpg)

**FIGURE 6-19** Tail Drop Recovery

Two cases of tail drop recovery are shown. In the first case, three packets are sent from the requester to the responder, where the last packet is dropped. An acknowledgment is sent in return. After a while, the last packet is resent to the responder and an acknowledgment that the message is complete is received by the requester. In the requester's end, the time taken between the first acknowledgment and the resend of the last packet is marked as transport timeout. In the second case, three packets are sent in which the last packet is dropped. An acknowledgment and an unsolicited acknowledgment are received from the responder. The last packet is resent to the responder and an acknowledgment that the message is complete is received from the responder. In the responder's end, the time taken between the second packet and the acknowledgment is marked as tail loss timeout.

#### 6.1.9 Continued Evolution of RDMA

As it usually happens with technology, RDMA deployment experiences prompted further evolution of the protocol. In this context, the vendor’s innovation sets the pace. When adopted by the market, some of the new extensions become candidates for standardization at the IBTA, which has remained active for more than 20 years. Recent areas of activities are discussed next.

### Control Plane Acceleration

We have described the mainstream data plane of the RDMA protocol that has been heavily optimized and tuned for maximum performance. Meanwhile, the control plane has been pointed out as a limiting factor for some real-life applications. In particular, with the one-connection-per-flow model that is common with RDMA, the cost of connection setup can become a burden. It is especially true for large deployments or those with very dynamic connection characteristics. Another aspect of RoCE that has been a consistent complaint is the cost of memory registration. This operation involves a mandatory interaction with the OS and typically requires careful synchronization of RDMA NIC state. Some new RDMA implementations optimize these operations, and near-data-plane-performance versions of memory registration and connection setup have become available.

##### Support for Remote Nonvolatile Memory Accesses

The recent proliferation of new nonvolatile memory technologies has opened up opportunities for a new range of applications and changed the paradigm for many others. NVDIMMs with Load/Store access semantics are adopting the form of a new storage tier. The SNIA has been working to define programming models for these new technologies [[14](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch06.xhtml#ch06ref14)], and the IBTA is extending the RDMA protocol with explicit support for the unique characteristics of explicit nonvolatile memory accesses across the network. Specifically, new RDMA operations will allow remote NVM commits that, once completed at the source, will virtually guarantee that data has been safely delivered to the persistence domain on the target side while maintaining the one-sided execution that is crucial to the RDMA model.

##### Data Security

Concerning data security, the RDMA protocol covers all aspects of interprocess protection and memory access checks at the end nodes. However, as far as data in transit is concerned, the standard doesn’t define data encryption or cryptographic authentication schemes. Still, by being a layered protocol that runs on UDP/IP, there are several ways to implement encrypted RDMA, such as IPSec or DTLS. Modern RDMA implementations using domain-specific hardware are particularly efficient at this kind of task and can achieve wire rate encryption/decryption for 100GE links.

### 6.2 Storage

Introduced in 1986, SCSI (Small Computer System Interface) became the dominant storage protocol for servers. SCSI offered a variety of physical layers, from parallel to serial, mostly limited to very short distances.

The demand for longer reach, as well as the opportunity to disaggregate storage, motivated the creation of Fibre Channel [[15](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch06.xhtml#ch06ref15)], a dedicated storage network designed to carry SCSI across a switched fabric and connect to dedicated appliances providing storage services to many clients.

Over time, the network consolidation trend prompted the definition of further remote storage solutions for carrying SCSI across nondedicated networks. iSCSI [[16](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch06.xhtml#ch06ref16)] and FCoE [[17](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch06.xhtml#ch06ref17)] are attempts to converge storage and networking over Ethernet, whereas SRP [[18](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch06.xhtml#ch06ref18)] and iSER [[19](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch06.xhtml#ch06ref19)] are designed to carry SCSI over RDMA; see [Figure 6-20](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch06.xhtml#ch06fig20). In all cases, the goal is to eliminate the requirement for a dedicated storage network (for example, Fibre Channel). Additionally, storage consolidation has further redefined and disrupted the storage landscape through “hyper-converged infrastructure” (HCI) and “hyper-converged storage” offerings. These are typically proprietary solutions defined and implemented by the top-tier cloud providers [[20](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch06.xhtml#ch06ref20)].

![A figure shows the remote SCSI storage protocols.](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9780136624226/files/graphics/06fig20.jpg)

**FIGURE 6-20** Remote SCSI Storage Protocols

The SCSI storage protocols are classified based on their convergence over Ethernet and Ethernet or Infiniband. The SCSI block storage converges over Ethernet and RDMA. FCoE, TCP/UDP IP stack, and half of iSCSi converge over Ethernet. iSER, SRP, and half of iSCSi converge over RDMA.

#### 6.2.1 The Advent of SSDs

Since 2010, solid state drives (SSDs) started to become economically viable. They provide superior performance compared to rotating media hard disks. To fully exploit SSD capabilities, a new standard called Non-Volatile Memory express (NVMe) has been created as a more modern alternative to SCSI.

NVMe [[21](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch06.xhtml#ch06ref21)] is an open logical device interface specification for accessing nonvolatile storage media attached via a PCIe. NVMe has been designed to take advantage of the low latency and high internal parallelism of flash-based storage devices. As a result, NVMe reduces I/O overhead and brings various performance improvements relative to previous logical-device interfaces, including multiple, long command queues and reduced latency. NVMe can be used for SSD, but also for new technologies such as 3D Xpoint [[22](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch06.xhtml#ch06ref22)] and NVDIMMs [[23](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch06.xhtml#ch06ref23)].

#### 6.2.2 NVMe over Fabrics

As was the case with SCSI, a remote storage flavor of NVMe was also defined [[24](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch06.xhtml#ch06ref24)]. NVMe over Fabrics (NVMe-oF) defines extensions to NVMe that allow remote storage access over RDMA and Fibre Channel. Most recently, NVMe/ TCP was also included in the standard (see [Figure 6-21](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch06.xhtml#ch06fig21)).

![A figure shows the standard NVMe over Fabrics.](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9780136624226/files/graphics/06fig21.jpg)

**FIGURE 6-21** NVMe-oF

In the figure, NVME is present over fabric transport and local bus transport (PCIe). The fabric transport is present over Fibre channel, RDMA, and TCP or IP or Ethernet. The NVMe disk, FC adapter, IB or Ethernet, and Ethernet are present below local bus transport, FC, RDMA, and TCP or IP or Ethernet, respectively.

It seems that the Fibre Channel flavor of NVMe-oF will not be particularly relevant, because it requires maintaining a separate FC network or running over FCoE. Given the benefits already explored in previous sections, the highest performant solution appears to be NVMe over RDMA. The NVMe/TCP approach will likely gain wide acceptance, given the ubiquity of TCP and the opportunity to leverage most of the value proposition of NVMeoF with minimal impact to the datacenter network.

#### 6.2.3 Data Plane Model of Storage Protocols

Remote storage has been in place for a couple of decades. As one looks in more detail, there is a common pattern in the data plane of most remote storage protocols. I/O operations start with a request from the storage client, which is typically delivered to the remote storage server in the payload of a network message. The storage server usually manages the outstanding I/O requests in a queue from which it schedules for execution. Execution entails the actual data transfer between the client and the server and the actual access to the storage media. For I/O reads (that is, read from storage), the server will read from the storage media and then deliver the data through the network into buffers on the client side that were set aside for that purpose when the I/O operation was requested. For I/O writes, the server will access the client buffers to retrieve the data across the network and store it in the storage media when it arrives (a pull model); see [Figure 6-22](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch06.xhtml#ch06fig22). After the I/O has been completed, the server will typically deliver a completion status to the client in the payload of a message through the network.

![The storage write between a storage client and a storage server is shown. A disk write request command is sent to the server by the client and the data is fetched from the server to the storage client. Data is then delivered to the server and a disk write completed report is received by the storage client.](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9780136624226/files/graphics/06fig22.jpg)

**FIGURE 6-22** Example of Storage Write

Some remote storage protocols also include a flavor of I/O writes where data is pushed into the server directly with the I/O request; see [Figure 6-23](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch06.xhtml#ch06fig23). The benefit of this optimization is the saving of the data delivery roundtrip. However, this scheme poses a challenge to the storage server as it needs to provision queues for the actual incoming data and, hence, when available, this push model is only permitted for short I/O writes.

![A push model is illustrated. This model has a storage client and a storage server. Disk write request command (with data) is sent from the client to the server, and in return, the disk write completed report is received from the server.](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9780136624226/files/graphics/06fig23.jpg)

**FIGURE 6-23** Push Model

RDMA operations present clear benefits when applied towards data access and I/O requests. With RDMA, the client-side CPU need not be involved in the actual delivery of data. The server asynchronously executes storage requests, and the status is reported back to the client, after the requests are completed. This natural alignment prompted the development of RDMA-based remote storage protocols that would work over SCSI. Initially, the SCSI RDMA Protocol (SRP) [[18](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch06.xhtml#ch06ref18)] was defined, followed sometime later by the IETF standardized iSCSI Extensions for RDMA (iSER) [[19](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch06.xhtml#ch06ref19)], which preserves the iSCSI model by replacing the underlying TCP with RDMA. Finally, NVMe-oF was defined to leverage the NVMe model on RDMA fabrics, given the current momentum and the maturity of RDMA technologies. NVMe-oF seems poised to gain a much broader adoption than either SRP or iSER.

#### 6.2.4 Remote Storage Meets Virtualization

Economies of scale motivated large compute cluster operators to look at server disaggregation. Among server components, storage is possibly the most natural candidate for disaggregation, mainly because the average latency of storage media access could tolerate a network traversal. Even though the new prevalent SSD media drastically reduces these latencies, network performance evolution accompanies that improvement. As a result, the trend for storage disaggregation that started with the inception of Fibre Channel was sharply accelerated by the increased popularity of high-volume clouds, as this created an ideal opportunity for consolidation and cost reduction.

Remote storage is sometimes explicitly presented as such to the client; see [Figure 6-24](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch06.xhtml#ch06fig24). This mandates the deployment of new storage management practices that affect the way storage services are offered to the host, because host management infrastructure needs to deal with the remote aspects of storage (remote access permissions, mounting of a specific remote volume, and so on).

![An explicit remote storage system is shown.](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9780136624226/files/graphics/06fig24.jpg)

**FIGURE 6-24** Explicit Remote Storage

The explicit remote storage is illustrated in the figure. The host is present on the left, which includes the VM, hypervisor, RDMA NIC, Ethernet NIC, and a data storage stack. The operating system consists of the following: remote storage management, RDMA driver, TCP/IP stack, and NVME-oF initiator. Next to the Ethernet NIC is a data storage stack. This stack is connected to a system of four multilayered switches, out of which one switch is connected to two more data storage stacks. The data storage stack in the host is connected to an NVME-oF target through these multilayered switches.

In some cases, exposing the remote nature of storage to the client could present some challenges, notably in virtualized environments where the tenant manages the guest OS, which assumes the presence of local disks. One standard solution to this problem is for the hypervisor to virtualize the remote storage and emulate a local disk toward the virtual machine; see [Figure 6-25](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch06.xhtml#ch06fig25). This emulation abstracts the paradigm change from the perspective of the guest OS.

![A figure shows a remote storage model, with a emulated local storage in the hypervisor.](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9780136624226/files/graphics/06fig25.jpg)

**FIGURE 6-25** Hypervisor Emulates Local Disk Towards Guest OS

A remote storage model is shown in the figure. The host is present on the left, which includes the virtual machine, hypervisor, RDMA NIC, Ethernet NIC, and a data storage stack. The VM consists of an NVME initiator. The hypervisor contains the following; remote storage management, RDMA driver, TCP/IP stack, and NVME emulation. The NVME emulation has an emulated local storage and NVME-oF initiator. The NVME initiator from the host is connected to the emulated local storage in NVME emulation. Next to the Ethernet NIC is a data storage stack. This stack is connected to a system of four multilayered switches out of which one switch is connected to two more data storage stacks. The data storage stack in the host is connected to an NVME-oF target through these multilayered switches.

However, hypervisor-based storage virtualization is not a suitable solution in all cases. For example, in bare-metal environments, tenant-controlled OS images run on the actual physical machines with no hypervisor to create the emulation. For such cases, a hardware emulation model is becoming more common; see [Figure 6-26](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch06.xhtml#ch06fig26). This approach presents to the physical server the illusion of a local hard disk. The emulation system then virtualizes access across the network using standard or proprietary remote storage protocols. One typical approach is to emulate a local NVMe disk and use NVMe-oF to access the remote storage.

![A NIC-based emulation is shown in a remote storage model.](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9780136624226/files/graphics/06fig26.jpg)

**FIGURE 6-26** NIC-Based NVMe Emulation

The NIC-based NVMe emulation is shown in the figure. The host is present on the left, which includes the OS or hypervisor and the NVME emulation adapter and NIC. The OS or hypervisor has an NVME initiator. The NVME emulation adapter and NIC has two sections: remote storage management and NVME emulation. The NVME emulation has an emulated local storage and NVME-oF initiator. The NVME initiator from the OS or Hypervisor is connected to the emulated local storage in NVME emulation. Next to it is a system of four multilayered switches connected with two data storage stacks. The NVME-oF initiator from the host is connected to the NVME-oF target system through these multilayered switches.

One proposed way to implement the data plane for disk emulation is by using so-called “Smart NICs”; see [section 8.6](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch08.xhtml#ch08lev1sec6). These devices typically include multiple programmable cores combined with a NIC data plane. For example, Mellanox BlueField and Broadcom Stingray products fall into this category.

However, as the I/O demand increases, this kind of platform may struggle to deliver the required performance and latency, and the scalability of the solution, especially in terms of heat and power, may become a challenge. An alternative approach favors the use of domain-specific hardware instead of off-the-shelf programmable cores. We discuss this further in the context of distributed storage services.

#### 6.2.5 Distributed Storages Services

It has been quite a while since storage was merely about reading and writing from persistent media. Modern storage solutions offer multiple additional associated services. [Table 6-1](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch06.xhtml#ch06tab1) summarizes the more prevalent ones. We discuss some of them in the following sections.

**TABLE 6-1** Storage Services by Type

| Security and Integrity | Efficiency | Reliability & Availability |
| --- | --- | --- |
| <br>
<br>Encryption and Decryption
<br>
<br> | <br>
<br>Compression and Decompression
<br>
<br> | <br>
<br>Replication
<br>
<br> |
| <br>
<br>Key Management
<br>
<br> | <br>
<br>Deduplication
<br>
<br> | <br>
<br>Mirroring
<br>
<br> |
| <br>
<br>Checksum
<br>
<br> |  | <br>
<br>Erasure Coding
<br>
<br> |
|  |  | <br>
<br>Striping
<br>
<br> |
|  |  | <br>
<br>Snapshotting
<br>
<br> |

#### 6.2.6 Storage Security

In today’s world, encryption of data is of primary importance. Multiple encryption schemes have been devised over the years for the encryption of data at rest. The recently approved IEEE standard 1619-2018 defines Cryptographic Protection on Block Storage Devices. The algorithm specified is a variant of the Advanced Encryption Standard, AES-XTS (XOR–Encrypt–XOR, tweaked-codebook mode with ciphertext stealing). The AES-XTS block size is 16 bytes, but with ciphertext stealing, any length, not necessarily a multiple of 16 bytes, is supported. AES-XTS considers each storage data block as the data unit. Popular storage block sizes are 512B, 4KB, and 8KB. Each block can also include metadata/Protection Info (PI) and thus be larger than the aforementioned sizes by anywhere from 8 to 32 bytes.

#### 6.2.7 Storage Efficiency

A crucial service of modern storage technology that directly ties to IT costs is data compression. Every day, vast amounts of data are generated and stored—logs, web history, transactions, and so on. Most of this data is in a human-consumable form and is significantly compressible; therefore, doing so allows for better utilization of storage resources. With the advent of SSDs, which offer tremendous performance but have a higher cost per GB than HDDs, data compression becomes even more compelling.

Most of the data compression techniques used in practice today are variants of the Lempel-Ziv (LZ) compression scheme with or without Huffman Coding. These techniques inevitably trade off compression ratio for compression and decompression speed and complexity. For example, deflate compression, the most popular and open source compression in use, implements nine levels, progressively going from speed-optimized (level 1) to ratio-optimized (level 9).

Compression speed, compression ratio, and decompression speed of various algorithms are compared in [[25](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch06.xhtml#ch06ref25)]:

- Fast compression techniques such as LZ4 and Snappy focus on speed optimization by eliminating Huffman Coding.

- The fastest software-based compression algorithm (LZ4) offers a compression ratio of 2 on Silesia benchmark.

- The highest compression ratio of 3 comes from deflate (level 6).

Data deduplication is another data-reduction technique that has become popular in storage platforms. The benefit stems from the reality that it’s extremely common for multiple copies of the same data to be stored in the same system. Consider, for example, the OS images for instances of multiple VMs; a large presentation emailed to a work team or multimedia files delivered to social media groups. The explicit goal is to store a single copy of the common data and avoid the waste of storage space on copies.

Data deduplication involves comparing a new data block against all previously stored ones in an attempt to discover a potential copy. Byte-by-byte comparison is not an efficient solution. The most common technique relies on calculating a short digest of the data block and comparing it against the other block’s digests. Cryptographic hashes are used as digests thanks to their very low collision probability. For example, a Secure Hash Algorithm 2 (SHA2) 512-bit digest of a 4KB data block is just 64B long but has a collision probability of 2.2×10-132! Different storage systems have chosen different cryptographic hashes, but the most common is the NIST-approved SHA family: SHA1, SHA2, SHA3. SHA2 and SHA3 offer digest sizes of 256, 384, or 512 bits.

#### 6.2.8 Storage Reliability

Resiliency to media failure is among the essential features of a storage system. In its simplest form, this can be achieved by storing two copies of each block on two different disks, and consequently duplicating the cost of the media. By calculating a parity block over N data blocks and then storing the N data blocks and the one parity block on N+1 different drives, the cost can be reduced while tolerating a single drive failure (including a failure to the parity drive). The Redundant Array of Independent Disks standard 5 (RAID5) implements this scheme, but it is less popular these days due to vulnerabilities during rebuild times and the increased size of the individual disks. Similarly, RAID-6 calculates two different parity blocks and can tolerate two drive failures. This approach, known as erasure coding, can be generalized. A scheme to tolerate K drive failures requires calculating K parity blocks over N data blocks and storing N+K blocks on N+K drives. Reed-Solomon [[25](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch06.xhtml#ch06ref25)] is a widespread erasure coding scheme used by many storage systems.

#### 6.2.9 Offloading and Distributing Storage Services

Traditionally, most storage services, like the ones described previously, were provided by the monolithic storage platform. The disaggregation of storage using local disk emulation presents an opportunity for further innovations. Storage services can now be implemented in three different components of the platform: the disk emulation adapter at the host, the front-end controller of the storage server, or the storage backend; see [Figure 6-27](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch06.xhtml#ch06fig27).

![A figure shows a system of distributed storage services.](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9780136624226/files/graphics/06fig27.jpg)

**FIGURE 6-27** Distributed Storage Services

The distributed storage services are shown in the figure. The host is present on the left, which includes the OS or hypervisor and the NVME emulation adapter and NIC. The OS or hypervisor has an NVME initiator. The NVME emulation adapter and NIC has two sections: remote storage management and NVME emulation. The NVME emulation has an emulated local storage and NVME-oF initiator. The NVME initiator from the host is connected to the emulated local storage in NVME emulation. Next to the host, is a system of four connected multilayered switches. Two data storage stacks are connected to these switches. Next to this system is a storage system, which consists of a storage frontend connected to four multilayered switches, and then to the storage backend. The NVME-oF initiator from the host is connected to the storage backend through the four multilayered switches and the storage frontend, and storage services are indicated in these connections.

Deployment of storage services using domain-specific hardware within the host platform aligns well with the benefits of other distributed services discussed in previous chapters. Storage compression, for example, appears to be an excellent candidate for this approach. Implementation at the end node versus an appliance offers the benefit of scalability, and, in addition, the advantage of reduced network bandwidth as the storage data is delivered in compressed form.

However, not all services are equally suitable for this approach. In particular, client-side offloads are more efficient when context information is unchanging per flow, which is often the case for compression. In contrast, reliability services that involve persistent metadata schemes are a better fit for the storage server side. Some services could benefit from mixed approaches. For example, deduplication would be naturally implemented by the storage system because it requires the digest of all stored blocks. However, digest calculation, which is a compute-intensive task, could be very well offloaded to the host adapter, attaining a benefit in scalability.

With regard to security, distributed storage presents the additional need to protect data in transit. For this purpose, there is no choice but to involve the end node. In cases where the remote storage server implements encryption of data at rest, data in transit can be secured using traditional network packet encryption schemes (for example, IPSec, DTLS). Alternatively, AES-XTS encryption for data-at-rest could be implemented directly at the host adapter, thereby covering the protection of data in transit and relieving the storage platform from the work of encryption/decryption. The AES-XTS scheme is hardware-friendly and particularly suitable for offload to the disk emulation controller on the host side. Encryption of data at rest performed by the end node offers the additional benefit of total data protection under the complete control of the data owner. With encryption performed at the source, services such as compression that require visibility of the data must also be implemented at the endnode.

#### 6.2.10 Persistent Memory as a New Storage Tier

The emergence of nonvolatile memory devices also created the notion of a new storage tier. These new devices, some of which are packaged in DIMM form factors, have performance characteristics that are closer to that of DRAM with capacities and persistency that is more typical of storage. This trend promoted the development of new APIs for efficient utilization of these devices. The Storage Networking Industry Association (SNIA) developed a programming model [[26](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch06.xhtml#ch06ref26)] that covers local access and is now being extended to support remote NVM devices in line with the RDMA protocol extensions discussed in [section 6.1.9](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch06.xhtml#ch06lev2sec1_9).

### 6.3 Summary

As with application services, the demand for cost-efficient scalability and flexibility requires a paradigm change in the deployment of infrastructure services in enterprise networks and clouds. Domain-specific hardware for distributed services processing deployed at the end nodes or close by seems to offer a promising, scalable solution that strikes a good balance of flexibility and cost.

### 6.4 Bibliography

**[[1](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch06.xhtml#rch06ref1)]** Kronenberg, Nancy P. et al. “VAXclusters: A Closely-Coupled Distributed System (Abstract).” SOSP (1985), [http://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.74.727&rep=rep1&type=pdf](http://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.74.727&rep=rep1&type=pdf)

**[[2](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch06.xhtml#rch06ref2)]** Horst and Diego José Díaz García. “1.0 Introduction, 2.0 ServerNet Overview, 2.1 ServerNet I, ServerNet SAN I/O Architecture.” [https://pdfs.semanticscholar.org/e00f/9c7dfa6e2345b9a58a082a2a2c13ef27d4a9.pdf](https://pdfs.semanticscholar.org/e00f/9c7dfa6e2345b9a58a082a2a2c13ef27d4a9.pdf)

**[[3](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch06.xhtml#rch06ref3)]** Compaq, Intel, Microsoft, “Virtual Interface Architecture Specification, Version 1.0,” December 1997, [http://www.cs.uml.edu/~bill/cs560/VI_spec.pdf](http://www.cs.uml.edu/~bill/cs560/VI_spec.pdf)

**[[4](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch06.xhtml#rch06ref4)]** InfiniBand Trade Association, [http://www.infinibandta.org](http://www.infinibandta.org/)

**[[5](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch06.xhtml#rch06ref5)]** InfiniBand Architecture Specification, Volume 1, Release 1.3, [https://cw.infinibandta.org/document/dl/7859](https://cw.infinibandta.org/document/dl/7859)

**[[6](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch06.xhtml#rch06ref6)]** RDMA Consortium, [http://rdmaconsortium.org](http://rdmaconsortium.org/)

**[[7](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch06.xhtml#rch06ref7)]** Supplement to InfiniBand Architecture Specification, Volume 1, Release 1.2.1, Annex A16, RDMA over Converged Ethernet (RoCE) [https://cw.infinibandta.org/document/dl/7148](https://cw.infinibandta.org/document/dl/7148)

**[[8](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch06.xhtml#rch06ref8)]** Supplement to InfiniBand Architecture Specification, Volume 1, Release 1.2.1, Annex A17, RoCEv2 [https://cw.infinibandta.org/document/dl/7781](https://cw.infinibandta.org/document/dl/7781)

**[[9](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch06.xhtml#rch06ref9)]** Top 500, Development over time, [https://www.top500.org/statistics/overtime](https://www.top500.org/statistics/overtime)

**[[10](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch06.xhtml#rch06ref10)]** Paul Tsien, “Update: InfiniBand for Oracle RAC Clusters,” Oracle, [https://downloads.openfabrics.org/Media/IB_LowLatencyForum_2007/IB_2007_04_Oracle.pdf](https://downloads.openfabrics.org/Media/IB_LowLatencyForum_2007/IB_2007_04_Oracle.pdf)

**[[11](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch06.xhtml#rch06ref11)]** IEEE 802.1 Data Center Bridging, [https://1.ieee802.org/dcb](https://1.ieee802.org/dcb)

**[[12](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch06.xhtml#rch06ref12)]** Yibo Zhu, Haggai Eran, Daniel Firestone, Chuanxiong Guo, Marina Lipshteyn, Yehonatan Liron, Jitendra Padhye, Shachar Raindel, Mohamad Haj Yahia, and Ming Zhang. 2015. Congestion Control for Large-Scale RDMA Deployments. SIGCOMM Comput. Commun. Rev. 45, 4 (August 2015), 523–536. DOI: [https://doi.org/10.1145/2829988.2787484](https://doi.org/10.1145/2829988.2787484), [https://conferences.sigcomm.org/sigcomm/2015/pdf/papers/p523.pdf](https://conferences.sigcomm.org/sigcomm/2015/pdf/papers/p523.pdf)

**[[13](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch06.xhtml#rch06ref13)]** Ramakrishnan, K., Floyd, S., and D. Black, “The Addition of Explicit Congestion Notification (ECN) to IP,” RFC 3168, DOI 10.17487/RFC3168, September 2001, [https://www.rfc-editor.org/info/rfc3168](https://www.rfc-editor.org/info/rfc3168)

**[[14](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch06.xhtml#rch06ref14)]** SNIA, “NVM Programming Model (NPM),” [https://www.snia.org/tech_activities/standards/curr_standards/npm](https://www.snia.org/tech_activities/standards/curr_standards/npm)

**[[15](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch06.xhtml#rch06ref15)]** FCIA, Fibre Channel Industry Association, [https://fibrechannel.org](https://fibrechannel.org/)

**[[16](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch06.xhtml#rch06ref16)]** Chadalapaka, M., Satran, J., Meth, K., and D. Black, “Internet Small Computer System Interface (iSCSI) Protocol (Consolidated),” RFC 7143, DOI 10.17487/RFC7143, April 2014, [https://www.rfc-editor.org/info/rfc7143](https://www.rfc-editor.org/info/rfc7143)

**[[17](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch06.xhtml#rch06ref17)]** Incits, “T11 - Fibre Channel Interfaces,” [http://www.t11.org](http://www.t11.org/)

**[[18](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch06.xhtml#rch06ref18)]** Incits “T10, SCSI RDMA Protocol (SRP),” [http://www.t10.org/cgi-bin/ac.pl?t=f&f=srp-r16a.pdf](http://www.t10.org/cgi-bin/ac.pl?t=f&f=srp-r16a.pdf)

**[[19](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch06.xhtml#rch06ref19)]** Ko, M. and A. Nezhinsky, “Internet Small Computer System Interface (iSCSI) Extensions for the Remote Direct Memory Access (RDMA) Specification,” RFC 7145, DOI 10.17487/RFC7145, April 2014, [https://www.rfc-editor.org/info/rfc7145](https://www.rfc-editor.org/info/rfc7145)

**[[20](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch06.xhtml#rch06ref20)]** Google, “Colossus,” [http://www.pdsw.org/pdsw-discs17/slides/PDSW-DISCS-Google-Keynote.pdf](http://www.pdsw.org/pdsw-discs17/slides/PDSW-DISCS-Google-Keynote.pdf)

**[[21](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch06.xhtml#rch06ref21)]** NVM Express, [http://nvmexpress.org](http://nvmexpress.org/)

**[[22](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch06.xhtml#rch06ref22)]** Rick Coulson, “3D XPoint Technology Drives System Architecture,” [https://www.snia.org/sites/default/files/NVM/2016/presentations/RickCoulson_All_the_Ways_3D_XPoint_Impacts.pdf](https://www.snia.org/sites/default/files/NVM/2016/presentations/RickCoulson_All_the_Ways_3D_XPoint_Impacts.pdf)

**[[23](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch06.xhtml#rch06ref23)]** Jeff Chang, “NVDIMM-N Cookbook: A Soup-to-Nuts Primer on Using NVDIMM-Ns to Improve Your Storage Performance,” [http://www.snia.org/sites/default/files/SDC15_presentations/persistant_mem/JeffChang-ArthurSainio_NVDIMM_Cookbook.pdf](http://www.snia.org/sites/default/files/SDC15_presentations/persistant_mem/JeffChang-ArthurSainio_NVDIMM_Cookbook.pdf), Sep. 2015

**[[24](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch06.xhtml#rch06ref24)]** NVM Express, “NVMExpress over Fabrics,” Revision 1.0, June 5, 2016, [https://nvmexpress.org/wp-content/uploads/NVMe_over_Fabrics_1_0_Gold_20160605-1.pdf](https://nvmexpress.org/wp-content/uploads/NVMe_over_Fabrics_1_0_Gold_20160605-1.pdf)

**[[25](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch06.xhtml#rch06ref25)]** GitHib, “Extremely Fast Compression algorithm,” [https://github.com/lz4/lz4](https://github.com/lz4/lz4)

**[[26](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch06.xhtml#rch06ref26)]** SNIA, “NVM Programming Model (NPM),” Version 1.2, [https://www.snia.org/sites/default/files/technical_work/final/NVMProgrammingModel_v1.2.pdf](https://www.snia.org/sites/default/files/technical_work/final/NVMProgrammingModel_v1.2.pdf)

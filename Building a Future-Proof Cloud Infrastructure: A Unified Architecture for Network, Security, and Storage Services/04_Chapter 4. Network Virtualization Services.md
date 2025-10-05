## Chapter 4. Network Virtualization Services

Three main types of services are required to successfully implement a cloud infrastructure: networking, security, and storage services. These services are essential services to implement any multitenant architecture, be it private or public.

This chapter explains the networking services with particular emphasis on network virtualization. [Chapter 5](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch05.xhtml#ch05), “[Security Services](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch05.xhtml#ch05),” describes the security services.

In a distributed services platform, these two services can be located in different places, because they are not strictly related to the I/O and memory architecture of the server. [Chapter 6](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch06.xhtml#ch06), “[Distributed Storage and RDMA Services](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch06.xhtml#ch06),” describes two other services, RDMA and storage, which are best hosted in the server because they are more tightly coupled with the I/O and memory of the server.

### 4.1 Introduction to Networking Services

Adding networking services to a cloud or data center network is associated with several challenges. Among them:

- **Where to locate the services:** They can be implemented in the server software, in the server hardware, or in a network device external to the server.

- **Complexity:** Traditional mechanisms of inserting service appliances are met with operational complexity, needing complicated automation, and imposing limitations associated with a single or dual point of failure.

- **Lack of management:** Integration with existing management tools and orchestration systems like VMware and Kubernetes can provide ease of deployment and simplification to the end user.

- **Lack of visibility:** Deploying telemetry in the infrastructure is also a big part of securing it. Knowing the application-level insights can be beneficial to the architects, as well as application developers to plan capacity, and to understand security postures.

- **Lack of troubleshooting tools:** Today’s tools are still very cumbersome to use, involving multiple touch points and having to be turned on when required, making it a tedious process; hence the need for always-on telemetry and troubleshooting.

- **Limited performance:** Implementing network, security, telemetry and other services in software running on the server CPU steals precious cycles from user applications. A perfect server should use 100 percent of its CPU cycles to run user applications! The availability of domain-specific hardware that implements a correct standard networking model will remove these loads from the server CPU.

Because some of the recent technology trends in networking have been particularly chaotic, especially concerning server networking, we will try to clarify the historical reasoning behind them and their future directions.

The final part of the chapter describes some new trends in telemetry and troubleshooting. Even the best service implementation will fall short if not accompanied by state-of-the-art troubleshooting and telemetry features.

### 4.2 Software-Defined Networking

At the end of the previous century, all the crucial problems in networking were solved. On my bookshelf I still have a copy of *Interconnections: Bridges and Routers* by Radia Perlman [[1](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch04.xhtml#ch04ref1)] dated 1993. In her book, Perlman presents the spanning tree protocol for bridged networks, distance vector routing, and link state routing: all the essential tools that we use today to build a network. During the following two decades there have been improvements, but they were minor, incremental. The most significant change has been the dramatic increase in link speed. Even Clos networks, the basis of the modern data center leaf-spine architecture, have been known for decades (since 1952).

In 2008, Professor Nick McKeown and others published their milestone paper on OpenFlow [[2](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch04.xhtml#ch04ref2)]. Everybody got excited and thought that with software-defined networking (SDN), networks were going to change forever. They did, but it was a transient change; a lot of people tried OpenFlow, but few adopted it. Five years later, most of the bridges and routers were still working as described by Perlman in her book.

But two revolutions had started:

- A distributed control plane with open API

- A programmable data plane

The second one was not successful because it was too simple and didn’t map well to hardware. However, it created the condition for the development of P4 to address those issues (see [Chapter 11](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch11.xhtml#ch11), “[The P4 Domain-Specific Language](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch11.xhtml#ch11)”).

OpenFlow impacted even more host networking, where the SDN concept is used in a plethora of solutions. It also had some traction in specific solutions such as SD-WAN.

The remainder of this chapter discusses these topics in detail.

#### 4.2.1 OpenFlow

OpenFlow is a switching and routing paradigm that was originally proposed by Professor Nick McKeown and others [[2](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch04.xhtml#ch04ref2)]. The project is now managed by the Open Networking Foundation (ONF) [[3](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch04.xhtml#ch04ref3)], a nonprofit operator-led consortium that maintains and develops the OpenFlow specification.

The genesis of OpenFlow is rooted in two separate factors. The first was a profound dissatisfaction of the network managers about how closed and proprietary routers and switches were. The issue was not related to the routing protocols that were standard and interoperable; it was the management experience that was a nightmare. Each different vendor had a different command line interface (CLI), which sometimes also had variations among different models from the same vendor. The only programmatic interface was Simple Network Management Protocol (SNMP) that was only used to collect information, not to configure the boxes. A correct REST API was missing or, when present, it was just a wrap-around of the CLI, returning unstructured data that needed custom text parsing instead of standard format like XML or JSON. Network managers wanted a programmatic interface to configure and provision switches and routers.

The second factor was related to the research community and academia. They also were concerned about how closed and proprietary the routers and switches were, but for a different reason: It was impossible for them to develop and test new routing protocols and forwarding schemes. The abstract of the original OpenFlow paper [[2](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch04.xhtml#ch04ref2)] states: “*We believe that OpenFlow is a pragmatic compromise: on one hand, it allows researchers to run experiments on heterogeneous switches in a uniform way at line-rate and with high port-density; while on the other hand, vendors do not need to expose the internal workings of their switches*.”

OpenFlow gained some popularity among the folks that challenged the conventional wisdom of shortest path first (SPF), the most common style of routing, as they needed to provide custom forwarding and traffic engineering between data centers, based on custom business logic; for example, routing based on time of day.

A lot of people in the networking community thought that OpenFlow could kill two birds with one stone and solve both problems at the same time. But let’s not get ahead of ourselves, and let’s first understand what OpenFlow is. OpenFlow is an architecture that separates the network control plane (where the routing protocols run) from the data plane (where packets are forwarded). The control plane runs on servers called controller, while the data plane runs on routers and switches that can be either hardware devices or software entities (see [Figure 4-1](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch04.xhtml#ch04fig1)).

![The main components of the OpenFlow Switch are illustrated.](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9780136624226/files/graphics/04fig01.jpg)

**FIGURE 4-1** Main Components of an OpenFlow Switch

Two controllers are present above the OpenFlow switch that are interconnected with the OpenFlow switch (open flow protocol). The OpenFlow switch has the following components: Two OpenFlow channels inside the control channel on the top left. To the top right, a group table and a meter table belonging to the datapath are present. There are two ports on either side of the OpenFlow Switch borders. The flow tables from left to right are shown along the pipeline.

The OpenFlow specification [[4](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch04.xhtml#ch04ref4)] defines two types of OpenFlow switches: OpenFlow-only and OpenFlow-hybrid (in this chapter the word *switch* means a combination of a layer 2 switch and a layer 3 router, which is commonly used in SDN/OpenFlow). OpenFlow-only switches forward packets according to the OpenFlow model only. OpenFlow-hybrid switches have a classification mechanism, outside the specification of OpenFlow, that decides whether the packets must be forwarded according to classical layer 2 and layer 3 models, or according to OpenFlow. In the rest of this section, we focus on OpenFlow-only switches and their four basic concepts: ports, flow tables, channels, and the OpenFlow protocol.

The OpenFlow ports are the switch ports passing traffic to and from the network. OpenFlow packets are received on an ingress port and processed by the OpenFlow pipeline, which may forward them to an output port. They can be physical ports, as in the case of the switch front panel ports, or they can be logical ports; for example, a linux netdev interface, which can be a virtual ethernet (vEth) port.

Reserved ports are also available; for example, for forwarding traffic to the controller.

The OpenFlow flow tables are the key components of the OpenFlow pipeline, which is an abstraction of the actual hardware of the switch. The pipeline and the tables are divided into two parts: ingress and egress. Ingress processing is always present, whereas egress processing is optional. A flow table is composed of flow entries, and each packet is matched against the flow entries of one or more tables. Each flow entry has match fields that are compared against packet headers, a priority, a set of counters, and a set of actions to be taken if the entry is matched. This is a simplified view; for full details, see the OpenFlow Switch Specification [[4](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch04.xhtml#ch04ref4)].

The OpenFlow channel is the control channel between the OpenFlow controller and the OpenFlow switch. The OpenFlow controller uses this channel to configure and manage the switch, to receive events and packets, and to send out packets.

The OpenFlow protocol is the protocol spoken over the OpenFlow channel.

OpenFlow has remarkable similarities with what used to be called “centralized routing” [[5](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch04.xhtml#ch04ref5)]. It also has the same disadvantages of centralized routing, mainly the controller being a single point of failure and not capable of scaling. Centralized routing was replaced in the 1990s by distributed routing such as distance vector routing and link state routing.

Although the centralized routing approach does not scale at the Internet level, it has some merit in limited and controlled environments.

OpenFlow has lost its momentum in recent years as the network manager requirements of provisioning and programming network boxes are now satisfied by approaches such as REST API, NETCONF/YANG, gRPC, and so on, whereas the routing issue continues to be well-addressed by distance vector routing and link state routing.

The only known massive deployment of OpenFlow is at Google [[6](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch04.xhtml#ch04ref6)], [[7](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch04.xhtml#ch04ref7)]. Professor Amin Vahdat explained part of Google’s strategy in an interview with NetworkWorld [[8](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch04.xhtml#ch04ref8)]. What emerges is that Google has a substantial investment in wide-area networks, the links are costly, and there is a desire to run them more efficiently, as closely as possible to 100 percent utilization. Google uses OpenFlow for traffic engineering and prioritization, an approach also called SD-WAN and discussed in the next section.

Recently, Google has also started to push for another approach called gRIBI, described in [section 4.2.3](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch04.xhtml#ch04lev2sec2_3).

OVS, described in [section 4.3.1](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch04.xhtml#ch04lev2sec3_1), also uses OpenFlow as the datapath, and OVS is used by VMware NSX, OpenStack and a few others.

Finally, Professors Nick McKeown and Amin Vahdat are now on the board of the P4 Language Consortium [[9](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch04.xhtml#ch04ref9)]. P4 is a language designed for programming of packet forwarding planes. P4 addresses some shortcomings of OpenFlow by allowing flexible packet header parsing, coupled with the match-action pipeline of OpenFlow. We discuss the P4 approach in [Chapter 11](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch11.xhtml#ch11).

#### 4.2.2 SD-WAN

Software-defined wide-area network (SD-WAN) is the combination of the SDN and VPN technologies designed to support WAN connectivity to connect enterprise networks, branch offices, data centers, and clouds over vast geographic distances [[10](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch04.xhtml#ch04ref10)]. It is a packaging of many existing technologies in a new creative way. The promises of SD-WAN are many, including its ability to manage multiple types of connections, from MPLS to broadband and LTE; simplified cloud-based management; the capability of provisioning bandwidth on demand; of using different links according to cost or time of day; and so on.

Another attraction of SD-WANs is their ability to consistently manage all policies across all the sites from a common place. Policy management was one of the biggest challenges before SD-WAN, creating security lapses and forcing manual reconciliation of policies.

In a nutshell, it is a lower-cost option, more flexible, and easier to manage than a classical router-based WAN. One practical advantage is the possibility of using lower-cost Internet access from different providers, instead of more expensive MPLS circuits. Another appeal derives from replacing branch routers with virtualized appliances that can implement additional functions, such as application optimization, network overlays, VPNs, encryption, firewall, and so on.

#### 4.2.3 gRIBI

The OpenFlow section presented one possible implementation of SDN through directly programming forwarding plane entries using OpenFlow, or P4Runtime (see [section 11.5](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch11.xhtml#ch11lev1sec5)). These are extreme approaches because they take complete control of the switches and give up all the features provided by standard protocols. Often this is not what is desired.

An alternative approach is to use protocols such as BGP or IS-IS to bring up the network and establish standard functionalities and then inject a few route optimizations using separate means. For example, this may work well for SD-WAN where by default packets follow the shortest path, but an SDN controller could enable other routes.

gRPC Routing Information Base Interface (gRIBI) [[11](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch04.xhtml#ch04ref11)] follows this second model, and the way it plugs into a switch software is shown in [Figure 4-2](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch04.xhtml#ch04fig2).

![A figure depicts the gRPC Routing Information Base Interface model.](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9780136624226/files/graphics/04fig02.jpg)

**FIGURE 4-2** gRIBI

A figure outlines the architecture of gRIBI. Static receives data from Config. gRIBI receives data from an external entity through gRPC. Static, BGP, ISIS, and gRIBI (daemon) send data to the Routing Table Manager, which is associated with RIB(s). The output from the routing table manager is separated to LFIB and FIB.

gRIBI has a daemon inside the switch software that acts as a routing protocol, but instead of exchanging routing control packets to compute routes, it receives routes from a programming entity via gRPC (see [section 3.4.2](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch03.xhtml#ch03lev2sec4_2)).

The support of multiple simultaneous routing protocols on a switch is a standard feature. Routing protocols populate a software data structure called routing information base ( RIB), and so does gRIBI. The switch software uses the RIB as the input to program the forwarding information base (FIB) that is the structure used by the switch hardware to forward the data packets in the data plane.

Two other advantages of this architecture are that gRIBI is part of the control plane of the switch, and entries are created as they were learned via a dynamic routing protocol, not treated as device configuration. gRIBI has a transactional semantic that allows the programming entity to learn about the success or failure of the programming operation.

#### 4.2.4 Data Plane Development Kit (DPDK)

DPDK is a technique to bypass the kernel and to process packets in userspace.

DPDK is a set of userspace software libraries and drivers that can be used to accelerate packet processing. DPDK creates a low-latency, high-throughput network data path from the NIC to the user space, bypassing the network stack in the kernel; see [Figure 4-3](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch04.xhtml#ch04fig3).

![A figure illustrates the process involving DPDK.](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9780136624226/files/graphics/04fig03.jpg)

**FIGURE 4-3** DPDK

The packets are processed in two ways, without DPDK and with DPDK. The packets processing involves three sections labeled user space that include applications, kernel space that includes network driver, and network adapter that enables accelerated networking. Without DPDK, the packets are transmitted and received, from the user space, through the kernel space, to the network adapter. With DPDK, the packets are transmitted and received between user space and network adapter section skipping the kernel space.

DPDK is processor agnostic and currently supported on Intel x86, IBM POWER, and ARM. It is used mainly on Linux and FreeBSD. It utilizes a multicore framework, huge page memory, ring buffers, and poll-mode drivers for networking, crypto, and events.

The kernel still needs to provide access to the memory space of the NIC, and also provide interrupt handling, even though DPDK was designed to use poll-mode drivers. The interrupt handling is usually limited to link up and down events. These tasks are performed using a kernel module known as UIO (user space I/O). The Linux kernel includes a basic UIO module, based on the device file /dev/uioX, which is used to access the address space of the card and handle interrupts. Note: This module does not provide IOMMU protection, which is supported by a similar and more secure module known as VFIO.

When using DPDK, applications need to be rewritten. For example, to run an application that uses TCP, a userspace TCP implementation must be provided, because DPDK bypasses the network portion of the kernel, including TCP.

DPDK has a growing and active user community that appreciates the network performance improvements obtainable through DPDK. Reducing context switching, networking layer processing, interrupts, and so on is particularly relevant for processing Ethernet at speeds of 10Gbps or higher.

A portion of the Linux community does not like DPDK and userspace virtual switches in general, because they remove control of networking from the Linux kernel. This group prefers approaches such as eBPF (see [section 4.3.5](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch04.xhtml#ch04lev2sec3_5)) and XDP (see [section 4.3.6](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch04.xhtml#ch04lev2sec3_6)), which are part of the kernel.

### 4.3 Virtual Switches

We introduced virtual switches (vSwitches) in [section 3.2](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch03.xhtml#ch03lev1sec2). We described them as software entities, typically present inside the hypervisors, to switch packets among virtual machines and through the NICs (network interface cards) to the outside world. Hypervisors are not the only users of vSwitches; containers use them, too.

In this section and the following ones, we describe a few vSwitch implementations, and we try to classify them according to criteria such as the following:

- Where the switching is done—in the hardware, the kernel, or the userspace

- Whether all the packets are treated equally or whether the concept of a “first packet” exists

- Whether vSwitches are individual entities or whether a higher level of coordination exists; that is, can a management software manage multiples of them as a single entity?

#### 4.3.1 Open vSwitch (OVS)

Open vSwitch (OVS) is an example of an open-source implementation of a distributed virtual multilayer switch [[12](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch04.xhtml#ch04ref12)]. It was created by Nicira (now part of VMware). According to the official documentation, it is “… a production quality, multilayer virtual switch licensed under the open source Apache 2.0 license. It is designed to enable massive network automation through programmatic extension, while still supporting standard management interfaces and protocols (e.g., NetFlow, sFlow, IPFIX, RSPAN, CLI, LACP, 802.1ag). In addition, it is designed to support distribution across multiple physical servers similar to VMware’s vNetwork distributed vSwitch or Cisco’s Nexus 1000V… .”

[Figure 4-4](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch04.xhtml#ch04fig4) depicts an OVS switch according to the official website [[13](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch04.xhtml#ch04ref13)]. There are different ways of using an OVS switch. By default, an OVS switch is a standard-compliant layer 2 bridge acting alone and doing MAC address learning. OVS is also an implementation of OpenFlow and, in this embodiment, multiple OVS switches can be managed and programmed by a single controller and act as a distributed switch, as shown in [Figure 4-5](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch04.xhtml#ch04fig5).

![A figure illustrates the function of the OVS (Open Virtual Switch).](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9780136624226/files/graphics/04fig04.jpg)

**FIGURE 4-4** OVS (Open Virtual Switch)

A virtualization environment is given with three virtual machines and a NIC connected to an open virtual switch. The open virtual switch deals with the four main functions such as Security for VLAN isolation and traffic filtering; Monitoring the Netflow, sFlow, SPAN, and RSPAN; QoS for traffic queuing and traffic shaping; and Automated control in OpenFlow, OVSDB, and management protocol.

![The architecture of a distributed open virtual switch (OVS) is depicted.](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9780136624226/files/graphics/04fig05.jpg)

**FIGURE 4-5** A Distributed OVS

A virtualization environment is shown, where 2 web servers, 1 application server, and 1 database server (all linux-based) are connected to two sets of hypervisor and server. This connection is established through a single "distributed virtual switch (open vSwitch)."

[Figure 4-6](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch04.xhtml#ch04fig6) shows the OVS architecture, outlining the kernel component, the user space datapath, the management utilities, and the optional connection to a remote controller.

![The OVS architecture is depicted.](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9780136624226/files/graphics/04fig06.jpg)

**FIGURE 4-6** The OVS Architecture

The OVS architecture consists of four layers from bottom to top labeled Kernel-space, User-space, Management, and Off-box. The Kernel-space layer includes kmod-open vswitch (fast datapath module) block in which the data in the hash lookup is transferred to the flow table. The User-space layer includes ovs-vswitchd block in which the data in the classifier is transferred to the stack of flow tables. The ovs-vswitchd block is interconnected to the ovsdb-server block that in turn is interconnected the ovsdb block. The management layer consists of five blocks, ovs-dpctl, ovs-ofctl, ovs-appctl, ovs-vsctl, and ovs-dbtool. The ovs-vswitchd block is interconnected to the ovs-ofctl and ovs-appctl in the management layer. The ovs-dpctl block is interconnected to the kmod-openvswitch in the kernel-space layer. The Off-box layer consists of SDN controller. The SDN controller is interconnected to the open-vswitchd and ovsdb-server blocks in the user-space layer through openflow protocol and OV SB B Management (RFC7047), respectively. The packets are transferred in and out via the physical NIC. The Netlink is transmitted and received between the ovs-vswitchd and kmod-openvswitch block.

Let’s start our description from the Open vSwitch kernel module (“kmod-openvswitch”) that implements multiple datapaths in the kernel. Each datapath can have multiple “vports” (analogous to ports within a bridge), and it has a “flow table.” It should be noticed that the OVS datapath in the kernel is a replacement of the standard Linux kernel network datapath. The interfaces associated with OVS use the OVS datapath instead of the Linux datapath.

A flow key is computed each time a packet is received on a vport, and the flowkey is searched in the flow table. If found, the associated action is performed on the packet; otherwise, the flow key and the packet is passed to “ovs-vswitchd,” which is the userspace daemon.

The userspace daemon can do a very sophisticated analysis of the packet, consulting multiple OpenFlow-style tables. As part of the processing, the daemon customarily sets up the flow key in the kernel module to handle further packets of the same flow directly in the kernel. This behavior is similar to the one explained in [section 2.8](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch02.xhtml#ch02lev1sec8) about Cache-based forwarding.

The OVS configuration is permanent across reboots. The “ovs-vswitchd” connects to an “ovsdb-server” and it retrieves its configuration from the database at startup. OVSDB (Open vSwitch Database) is a management protocol to configure OVS [[14](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch04.xhtml#ch04ref14)].

In [Figure 4-6](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch04.xhtml#ch04fig6) there are a few blocks whose names end in “ctl” (pronounced “cutle”). These blocks are the CLIs used to program the different features.

What has been described up to now is the standard implementation of OVS, mostly done in user space but with a kernel component. OVS can also operate entirely in user space by using DPDK to pass all the packets to the user space. In both cases, OVS is putting a load on the server CPU that can be very relevant.

OVS can also be hardware accelerated; for example, by replacing the kernel module table with a hardware table on a NIC. [Figure 4-7](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch04.xhtml#ch04fig7) shows a possible implementation of OVS in conjunction with a NIC that has an OVS-compliant hardware flow table and one or more processors onboard to run the OVS daemon and OVSDB. This concept is similar to the one outlined in section 2.8.1 when describing Microsoft GFT and the Azure SmartNIC.

![A figure shows the implementation of OVS in a NIC card.](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9780136624226/files/graphics/04fig07.jpg)

**FIGURE 4-7** OVS in a NIC

The NIC (Network Interface Card) consists of vSwitch and multiple VF ports. The vSwitch in NIC is connected to the OVS control section that includes Ovsdb server and OVS vswitchd. Each VF port in the NIC is connected with the vNIC of the virtual machines. The OVS control section is interconnected to the SDN controller OVN that in turn is interconnected to the Neutron in the Open stack.

Please notice that the previous solution is feasible because it is totally included in the NIC and therefore transparent to the kernel. The Linux kernel community has refused to *upstream* (a term that means to include in the standard kernel) any OVS hardware offload. To bypass this limitation, some companies have developed the solution described in the next section.

[Figure 4-7](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch04.xhtml#ch04fig7) also shows a possible integration with OpenStack (see [section 3.5](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch03.xhtml#ch03lev1sec5)). In OpenStack, both the Neutron node and the compute node (Nova) are running OVS to provide virtualized network services.

OVS is also the default virtual switch for XEN environments (see [section 3.2.5](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch03.xhtml#ch03lev2sec2_5)).

#### 4.3.2 tc-flower

“tc-flower” is an extension of “tc,” the traffic classification subsystem of the Linux kernel. tc-flower allows construction of a match-action datapath.

The match part is used to classify packets on a variety of fields in the L2, L3, and L4 headers, and metadata fields. It uses a subsystem in the kernel called *flow dissector*. tc-flower actions include output, drop, edit packet, and VLAN actions such as push and pop VLAN tags.

tc-flower match-action logic is stateless; that is, each packet is processed independently of the others. There is no possibility to base the decision on the status of a connection usually kept in conntrack.

Also, tc-flower has not been widely adopted due to its relative complexity, which is inherited from tc.

So, why do some companies plan to use tc-flower in conjunction with OVS?

Because from Linux kernel v4.14-rc4, it is possible to offload tc-flower in hardware through a utility called “ndo-setup-tc” [[15](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch04.xhtml#ch04ref15)]. The same service is also used to offload Berkeley Packet Filter (BPF), described in the next section. [Figure 4-8](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch04.xhtml#ch04fig8) shows this arrangement.

![A figure depicts the arrangement of OVS offload with the tc-flower.](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9780136624226/files/graphics/04fig08.jpg)

**FIGURE 4-8** OVS Offload with tc-flower

The OVS model consists of three sections from bottom to top labeled Hardware, Kernel, and Userspace. The hardware section consists of a NIC (Network Interface Card) that includes vSwitch and multiple VF ports. The kernel section consists of a Driver, tc-flower, and kmod-openvswitch block. The Userspace section consists of a ovs-vswitchd block. The vSwitch in the NIC card is interconnected to the Driver of the kernel section. The tc-flower and ovs-vswitchd block are connected to establish flows and stats. The kmod-openvswitch and ovs-vswitchd block are connected to establish flows, stats, and missed. The missed ones are transmitted to the tc-flower from kmod-openvswitch.

The basic idea is to piggyback OVS offload through tc-flower. The NIC maintains the OVS flow table in hardware and, when a packet misses the flow table, it is passed to tc-flower—that is almost an empty shell—by merely redirecting the miss to the OVS kernel module. The kernel module may have a larger flow table compared to the hardware, including flows that are making a limited amount of traffic, also called “mice flows” in contrast to high byte-count “elephant flows.” If the miss matches in the OVS kernel module flow table, a reply is returned to tc-flower; otherwise, the userspace module of OVS is activated, as in the normal OVS processing. OVS supports tc-flower integration since OVS 2.8.

As already mentioned, the most significant limitation of this approach is that tc-flower match is stateless; to make it stateful, it requires a combination with conntrack and potentially two passes in tc-flower, one before and one after conntrack. “Stateful security groups” is another name for this missing feature.

#### 4.3.3 DPDK RTE Flow Filtering

The DPDK Generic Flow API [[16](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch04.xhtml#ch04ref16)] provides a way to configure hardware (typically a NIC) to match specific packets, decide their fate, and query related counters. It is yet another match-action API that, being based on DPDK, has no kernel components and therefore requires no kernel upstreaming or nonstandard kernel patches.

DPDK RTE Flow Filtering is another name for the same API since all the calls start with “rte_.” (RTE stands for run time environment.)

This approach suffers from the same limitation of the tc-flower approach; it only supports stateless rules, no stateful security groups.

#### 4.3.4 VPP (Vector Packet Processing)

The last of the kernel-bypass approaches covered in this book is Vector Packet Processing (VPP) [[17](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch04.xhtml#ch04ref17)], which was donated by Cisco to the Linux Foundation Project and is now part of FD.io (Fast Data - Input/Output). According to the official documentation: “*The VPP platform is an extensible framework that provides out-of-the-box production quality switch/router functionality.*”

VPP uses DPDK to bypass the network stack in the kernel and move packet processing to userspace, but it also implements additional optimization techniques such as batch packet processing, NUMA awareness, CPU isolation, and so on to improve performance.

The packet processing model of VPP is a “packet processing graph,” as shown in [Figure 4-9](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch04.xhtml#ch04fig9).

![A figure explains the process of VPP.](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9780136624226/files/graphics/04fig09.jpg)

**FIGURE 4-9** VPP

The n number of packets in the packet vector is processed in batches to the dpdk-input. The dpdk-input transfers the packet to the ethernet-input. From the ethernet-input, the packets are transmitted to mpls-ethernet-input, ip6-input, ip4-input, arp-input, and llc-input. Further, the data from the ip6-input is transferred to the ip6-lookup.

Packets are processed in batches. At any given time, VPP collects all the packets waiting for processing, batches them together, and applies the graph to the packets. The advantage of this approach is that all packets are processed at the same time by the same code so that the hit ratio in the CPU instruction cache is increased significantly. Another way of thinking about this is that the first packet of the batch warms up the instruction cache for the remaining packets. Because packets are collected through DPDK, there are no interrupts; that is, no context switching. This minimizes overhead and increases performance.

VPP also supports “graph plugins” that can add/remove graph nodes and rearrange the packet graph. Plugins are a very convenient way to upgrade or add new features.

#### 4.3.5 BPF and eBPF

All the virtual switch approaches discussed up to now try to avoid the Linux kernel as much as possible and therefore move a significant part of the work to userspace. This section and the next one describe approaches that leverage the Linux kernel to its full extent and are thus supported by the Linux kernel community.

Let’s start with the original effort. In 1992, Van Jacobson and Steven McCanne proposed a solution for minimizing unwanted network packet copies to userspace by implementing in Unix an in-kernel packet filter known as Berkeley Packet Filter (BPF) [[18](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch04.xhtml#ch04ref18)].

BPF defined an abstract register-based “filter machine” similar to RISC CPUs.

The BPF machine consists of an accumulator, an index register, a scratch memory, and an implicit program counter. Filters are programs for the BPF machine. When BPF is active, the device driver, on receiving a packet, delivers the packet to BPF for filtering. The resulting action may be to accept or reject the packet.

In 2014, Alexei Starovoitov introduced eBPF (extended BPF) that more closely resembles contemporary processors, broadens the number of registers from two to ten, moves to 64-bit registers, and adds more instructions, making an eBPF machine C-programmable using the LLVM compiler infrastructure [[19](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch04.xhtml#ch04ref19)], [[20](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch04.xhtml#ch04ref20)]. eBPF also provides improved performance compared to BPF.

A reasonable question to ask is, “Why is eBPF relevant in the discussion about virtual switches?” There are four reasons:

- It is possible to code in an eBPF program, not only a basic virtual switch but also other network services such as a firewall, so for some applications, it may be an alternative to OVS.

- When eBPF is used in conjunction with XDP, a kernel technique described in the next section, the performance dramatically improves.

- eBPF can be offloaded to domain-specific hardware; for example, on a NIC, using “ndo-setup-tc,” the same utility that is used to offload tc-flower.

- eBPF can perform operations at various layers in a Linux networking stack; for example, before routing, post routing, at socket layer, and so on, giving flexible insertion points.

#### 4.3.6 XDP

eXpress Data Path (XDP) provides a high-performance, programmable network data path in the Linux kernel [[20](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch04.xhtml#ch04ref20)], [[21](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch04.xhtml#ch04ref21)]. The Linux kernel community developed XDP as an alternative to DPDK. David Miller, the primary maintainer of the Linux networking subsystem, says that “*DPDK is not Linux.*” He reasons that DPDK bypasses the Linux networking stack, and it lives outside the Linux realm.

XDP is the mechanism in the Linux kernel to run eBPF programs with the lowest possible overhead; see [Figure 4-10](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch04.xhtml#ch04fig10) [[22](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch04.xhtml#ch04ref22)].

![The process of eXpress Data Path (XDP) is depicted.](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9780136624226/files/graphics/04fig10.jpg)

**FIGURE 4-10** XDP

Applications run in the RX CPU and other CPUs. The XDP packet processor is at the center of the architecture with functions packet steering and parsing or processing BPF program. Control Application (load or configure BPF) is connected to the parsing or processing PBF program. Packet steering is connected to the TCP/IP stack of the applications. The parsing or processing program performs three actions: drop, received local (with and without GRO), and forward. The applications are connected to the device/driver through the TCP/IP stack, which is in turn connected to the parsing or processing BPF program.

XDP executes in the receiving side of the driver as soon as the packet is pulled out of the ring. It is the theoretical first opportunity to process a packet. XDP is invoked before the socket buffer (SKB) is attached to the packet. SKB is a large data structure used by the network stack, and there is a significant performance advantage to processing the packet before the SKB is attached. XDP works on a linear buffer that must fit on a single memory page, and the only two pieces of metadata it has are the pointers to the beginning and end of the packet. The buffer is not read-only, and eBPF can modify the packet to implement, for example, routing. One of these four actions results from the eBPF packet processing: drop the packet, abort due to an internal error in eBPF, pass the packet to the Linux networking stack, or transmit the packet on the same interface it was received. In all cases, eBPF may have modified the packet.

In addition to bridging and routing, other use cases for XDP/eBPF are Denial of Service detection [[23](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch04.xhtml#ch04ref23)], load balancing, traffic sampling, and monitoring.

Following the introduction of XDP in the Linux kernel, proposals have been presented to use eBPF/XDP in conjunction with OVS [[24](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch04.xhtml#ch04ref24)]. Two different approaches are possible:

- Rewrite the OVS kernel module (kmod-openvswitch) using eBPF

- use the AF_XDP socket and move flow processing into userspace.

#### 4.3.7 Summary on Virtual Switches

The previous sections have described several different ways of implementing virtual switches. [Figure 4-11](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch04.xhtml#ch04fig11) is my attempt at summarizing all of them into a single picture.

![A figure presents the different ways of implementing virtual switches.](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9780136624226/files/graphics/04fig11.jpg)

**FIGURE 4-11** All Solutions in One Picture

The three main expected solutions from the implementations of virtual switches are userspace only solutions, hardware acceleration, and kernel only solution. The addition of VPP and DPDK results in userspace only solutions. The OVS kernel and userspace along with DPDK results in userspace only solutions. The combination of OVS kernel and userspace with tc-flower and ndo-setup-tc results in hardware acceleration. The addition of OVS kernel and userspace with ndo-setup-tc results in hardware acceleration. The RTE flow combined with DPDK forms hardware acceleration. The combination of eBPF and ndo-setup-tc results in hardware acceleration. Also, the combination of eBPF, ndo-setup-tc, and OVS kernel plus userspace leads to hardware acceleration. The eBPF along with the XDP results as kernel only solution.

They differ for the following three main reasons:

- They use a native Linux model or bypass the Linux network stack.

- They run in the kernel or userspace, or a combination of the two.

- They use hardware acceleration.

All the software solutions have real performance issues at 10 Gbps and above, thus consuming many cores on the primary server CPUs.

Hardware acceleration is a necessity at 10 Gbps and above, but many of the current solutions are just additions to the existing NICs with many limitations.

The real solution will come from domain-specific hardware capable of implementing the classical bridging and routing models, in addition to the principal distributed network services, such as NAT, firewall, load balancing, and so on.

The next sections explain these distributed network services that complement routing and bridging.

### 4.4 Stateful NAT

IP address management remains a sore point, with the never ending transition to IPv6 still in the future. The use of private IPv4 addresses according to RFC 1918 is a common practice, which leads to address duplication in the case of hybrid cloud infrastructure, company merger, and acquisition. In this environment, good support for stateful NAT is a must.

The acronym *NAT* properly means network address translation, and it refers to changing only the IP addresses in an IP packet. In common parlance, NAT is also mixed/confused with PAT (port address translation) that refers to the capability of dynamic mapping/changing TCP/UDP port numbers. For a complete discussion of NAT versus PAT, see RFC 2663 [[25](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch04.xhtml#ch04ref25)].

The NAT also needs to be “stateful” any time it works in a modality, called *IP masquerading*, in which a group of private IP addresses is mapped to a single public IP address by using PAT, a typical case being a home gateway that connects multiple PCs, tablets, and phones to the Internet using a single public IP address. For example, in this case, the first packet generated by a tablet for a particular connection creates the mapping that is needed by the packets traveling in the opposite direction for the same session; hence the name, “stateful NAT.”

Fortunately, the number of application protocols that need to cross the NAT has dramatically decreased with most of them being NAT-friendly, such as SSH, HTTP, and HTTPS. Some old protocols require NAT ALGs (application layer gateways) because they carry IP addresses or port numbers inside the payload—one notable example being FTP, which is still widely used even if excellent secure alternatives exist that don’t have NAT issues.

### 4.5 Load Balancing

Another layer 4 service that is becoming ubiquitous is load balancing.

Its main application is to load balance web traffic by distributing HTTP/HTTPS requests to a pool of web servers to increase the number of web pages that can be served in a unit of time [[26](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch04.xhtml#ch04ref26)] (see [Figure 4-12](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch04.xhtml#ch04fig12)).

![The architecture of web load balancing is depicted.](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9780136624226/files/graphics/04fig12.jpg)

**FIGURE 4-12** Web Load Balancing

The user computer connected to the internet is equipped with an external firewall. The firewall is connected to the hardware of the load balancing cluster. The load balancing cluster consists of the hardware load balancer that is connected to three web servers labeled A, B, and C.

Load balancers act as proxies as they query the back-end web servers in place of the clients; this helps to secure the back-end servers from attack in conjunction with firewalls and microsegmentation (see [sections 5.1](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch05.xhtml#ch05lev1sec1) and [5.2](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch05.xhtml#ch05lev1sec2)).

Requests are received and distributed to a particular server based on a configured algorithm; for example, weighted round robin or least response time. This requires the load balancer to be stateful and keep track of the status of the back-end servers, their load, and, under normal operation, direct all the requests from a particular client to the same back-end server.

A load balancer can also perform caching of static content, compression, SSL/TLS encryption and decryption, and single point of authentication.

Historically implemented as discrete appliances, load balancers are now shifting from the centralized model to the distributed-service model, which also guarantees higher performance. Firewalls are undergoing a similar shift toward distributed firewalls: a distributed-service node can implement and integrate both functionalities.

### 4.6 Troubleshooting and Telemetry

Many of the techniques explained up to this point are essential for building data-center and cloud infrastructures. They also introduce significant complexity and functions that may become bottlenecks and cause slowdowns. Let’s consider, for example, I/O consolidation that brings the considerable promise of running everything over a single network for significant cost savings. It also removes a separate storage network that storage managers used to monitor for performance. When an application is slow, this can trigger considerable finger pointing: “Why is my application slow? Is it the network’s fault? No, it is the fault of the OS; No, it is the application that is poorly written; No, it is the storage back-end that is slow; No, there is packet loss; No ….” Pick your favorite cause. The only way to understand what is going on is by using telemetry, a word composed of the two Greek words *tele* (remote) and *metron* (measure). We need to measure as much as possible and report the measurements to a remote management station. The reality is that without objective measurement it is impossible to understand what is happening. Here is where telemetry comes into play.

Telemetry is the real-time measurement of a large number of parameters. In itself this is not new; switches and routers have multiple hardware counters that are typically read through Simple Network Management Protocol (SNMP) [[27](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch04.xhtml#ch04ref27)].

SNMP is a “pull” model (often also called a “poll” model) in which a management station periodically pulls data from the network devices. A pull interval of 5 minutes is typical, and SNMP on network devices is known to be inefficient and to use a lot of CPU cycles: sending too many SNMP requests may saturate, for example, a router CPU.

An alternative to pull models are push models in which the network devices periodically push out data, for example, to export flow statistics through NetFlow [[28](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch04.xhtml#ch04ref28)] to a NetFlow collector, and to log events to a remote server through Syslog [[29](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch04.xhtml#ch04ref29)].

Telemetry builds on these existing ideas, but it also adds a few new concepts:

- Usually, the data is modeled through a formal language such as Yang so that applications can consume data easily. Then it is encoded in a structured format such as XML, JSON, or Google’s protocol buffer (see [section 3.4.2](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch03.xhtml#ch03lev2sec4_2)). Another important consideration is a compact encoding scheme, because the volume of data to be streamed is high.

- The protocols used to do the pushing are more modern and derived from the computing world, not from the network world. Google’s protocol buffer message format is often used to stream the data.

- Pre-filtering is often used to reduce the enormous amount of data that needs streaming to a data collector. For example, data that shows normal behavior can be streamed less frequently than data associated with abnormal behavior.

- The push can be “cadence-based” or “policy-based”; that is, it can be done periodically, or when a particular policy is triggered; for example, a threshold is exceeded. The policies can also be refined in real time to make the data collection more useful.

Accurate telemetry is an essential tool to perform root cause analysis. In many cases the failures are difficult to locate, especially when intermittent; to identify the primary cause of an application slowdown a sequence of events needs to be analyzed, which is impossible without good telemetry.

In a distributed-service platform telemetry should cover all the different services in order to be effective. In particular, when multiple services are chained together, telemetry should help to identify which service in the chain is causing the problem.

### 4.7 Summary

In this chapter, we have presented networking distributed services that are extremely valuable in cloud and enterprise networks. Domain-specific hardware can make their implementation extremely performant and scalable. These services can be deployed in different parts of the network and implementing them in devices such as appliances or switches offers additional advantages of also supporting bare-metal servers and the possibility to share the domain-specific hardware across multiple servers, thus reducing the cost of ownership.

### 4.8 Bibliography

**[[1](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch04.xhtml#rch04ref1)]** Radia Perlman. 1999. *Interconnections* (2nd Ed.): *Bridges, Routers, Switches, and Internetworking Protocols.* Addison-Wesley Longman Publishing Co., Inc., Boston, MA, USA.

**[[2](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch04.xhtml#rch04ref2)]** Nick McKeown, Tom Anderson, Hari Balakrishnan, Guru Parulkar, Larry Peterson, Jennifer Rexford, Scott Shenker, and Jonathan Turner. 2008. “OpenFlow: enabling innovation in campus networks.” SIGCOMM Comput. Commun. Rev. 38, 2 (March 2008), 69–74. DOI=[http://dx.doi.org/10.1145/1355734.1355746](http://dx.doi.org/10.1145/1355734.1355746)

**[[3](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch04.xhtml#rch04ref3)]** The Open Networking Foundation (ONF), [https://www.opennetworking.org](https://www.opennetworking.org/)

**[[4](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch04.xhtml#rch04ref4)]** The Open Networking Foundation (ONF), “OpenFlow Switch Specification Version 1.5.1 (Protocol version 0x06 ),” March 26, 2015, ONF TS-025.

**[[5](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch04.xhtml#rch04ref5)]** [https://en.wikibooks.org/wiki/Routing_protocols_and_architectures/Routing_algorithms](https://en.wikibooks.org/wiki/Routing_protocols_and_architectures/Routing_algorithms)

**[[6](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch04.xhtml#rch04ref6)]** NetworkWorld, “Google Showcases OpenFlow network,” [https://www.networkworld.com/article/2222173/google-showcases-openflow-network.html](https://www.networkworld.com/article/2222173/google-showcases-openflow-network.html)

**[[7](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch04.xhtml#rch04ref7)]** Google, “OpenFlow @ Google,” [http://www.segment-routing.net/images/hoelzle-tue-openflow.pdf](http://www.segment-routing.net/images/hoelzle-tue-openflow.pdf)

**[[8](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch04.xhtml#rch04ref8)]** NetworkWorld, “Google’s software-defined/OpenFlow backbone drives WAN links to 100% utilization,” [https://www.networkworld.com/article/2189197/google-s-software-defined-openflow-backbone-drives-wan-links-to-100--utilization.html](https://www.networkworld.com/article/2189197/google-s-software-defined-openflow-backbone-drives-wan-links-to-100--utilization.html)

**[[9](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch04.xhtml#rch04ref9)]** P4 Language Consortium, [https://p4.org](https://p4.org/)

**[[10](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch04.xhtml#rch04ref10)]** NetworkWorld, “SD-WAN: What it is and why you’ll use it one day,” 2016-02-10, [https://www.networkworld.com/article/3031279/sd-wan-what-it-is-and-why-you-ll-use-it-one-day.html](https://www.networkworld.com/article/3031279/sd-wan-what-it-is-and-why-you-ll-use-it-one-day.html)

**[[11](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch04.xhtml#rch04ref11)]** gRIBI, [https://github.com/openconfig/gribi](https://github.com/openconfig/gribi)

**[[12](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch04.xhtml#rch04ref12)]** T. Koponen, K. Amidon, P. Balland, M. Casado, A. Chanda, B. Fulton, I. Ganichev, J. Gross, N. Gude, P. Ingram, E. Jackson, A. Lambeth, R. Lenglet, S.-H. Li, A. Padmanabhan, J. Pettit, B. Pfaff, R. Ramanathan, S. Shenker, A. Shieh, J. Stribling, P. Thakkar. Network virtualization in multi-tenant data centers, USENIX NSDI, 2014.

**[[13](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch04.xhtml#rch04ref13)]** Linux Foundation Collaborative Projects, “OVS: Open vSwitch,” [http://www.openvswitch.org](http://www.openvswitch.org/)

**[[14](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch04.xhtml#rch04ref14)]** Pfaff, B. and B. Davie, Ed., “The Open vSwitch Database Management Protocol,” RFC 7047, DOI 10.17487/RFC7047, December 2013.

**[[15](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch04.xhtml#rch04ref15)]** Simon Horman, “TC Flower Offload,” Netdev 2.2, The Technical Conference on Linux Networking, November 2017.

**[[16](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch04.xhtml#rch04ref16)]** DPDK, “Generic Flow API,” [https://doc.dpdk.org/guides/prog_guide/rte_flow.html](https://doc.dpdk.org/guides/prog_guide/rte_flow.html)

**[[17](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch04.xhtml#rch04ref17)]** The Linux Foundation Projects, “Vector Packet Processing (VPP),” [https://fd.io/technology](https://fd.io/technology)

**[[18](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch04.xhtml#rch04ref18)]** Steven McCanne, Van Jacobson, “The BSD Packet Filter: A New Architecture for User-level Packet Capture,” USENIX Winter 1993: 259–270.

**[[19](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch04.xhtml#rch04ref19)]** Gianluca Borello, “The art of writing eBPF programs: a primer,” February 2019, [https://sysdig.com/blog/the-art-of-writing-ebpf-programs-a-primer](https://sysdig.com/blog/the-art-of-writing-ebpf-programs-a-primer)

**[[20](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch04.xhtml#rch04ref20)]** Diego Pino García, “A brief introduction to XDP and eBPF,” January 2019, [https://blogs.igalia.com/dpino/2019/01/07/introduction-to-xdp-and-ebpf](https://blogs.igalia.com/dpino/2019/01/07/introduction-to-xdp-and-ebpf)

**[[21](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch04.xhtml#rch04ref21)]** Fulvio Risso, “Toward Flexible and Efficient In-Kernel Network Function Chaining with IO Visor,” HPSR 2018, Bucharest, June 2018, [http://fulvio.frisso.net/files/18HPSR%20-%20eBPF.pdf](http://fulvio.frisso.net/files/18HPSR%20-%20eBPF.pdf)

**[[22](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch04.xhtml#rch04ref22)]** The Linux Foundation Projects, “IO Visor Project: XDP eXpress Data Path,” [https://www.iovisor.org/technology/xdp](https://www.iovisor.org/technology/xdp)

**[[23](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch04.xhtml#rch04ref23)]** Gilberto Bertin, “XDP in practice: integrating XDP in our DDoS mitigation pipeline,” 2017, InNetDev 2.1—The Technical Conference on Linux Networking. [https://netdevconf.org/2.1/session.html?bertin](https://netdevconf.org/2.1/session.html?bertin)

**[[24](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch04.xhtml#rch04ref24)]** William Tu, Joe Stringer, Yifeng Sun, and Yi-HungWei, “Bringing The Power of eBPF to Open vSwitch,” In Linux Plumbers Conference 2018 Networking Track.

**[[25](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch04.xhtml#rch04ref25)]** Srisuresh, P. and M. Holdrege, “IP Network Address Translator (NAT) Terminology and Considerations,” RFC 2663, DOI 10.17487/RFC2663, August 1999.

**[[26](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch04.xhtml#rch04ref26)]** Nginx, “What is load balancing,” [https://www.nginx.com/resources/glossary/load-balancing](https://www.nginx.com/resources/glossary/load-balancing)

**[[27](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch04.xhtml#rch04ref27)]** Harrington, D., Presuhn, R., and B. Wijnen, “An Architecture for Describing Simple Network Management Protocol (SNMP) Management Frameworks,” STD 62, RFC 3411, DOI 10.17487/RFC3411, December 2002.

**[[28](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch04.xhtml#rch04ref28)]** Claise, B., Ed., “Cisco Systems NetFlow Services Export Version 9,” RFC 3954, DOI 10.17487/RFC3954, October 2004.

**[[29](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch04.xhtml#rch04ref29)]** Gerhards, R., “The Syslog Protocol,” RFC 5424, DOI 10.17487/RFC5424, March 2009.

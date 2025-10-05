## Chapter 2. Network Design

Why a chapter on network design in a book about distributed network services? The reality is that network design has evolved a lot in the recent years to accommodate the new scale and bandwidth requirements introduced initially in cloud networks but that are now also present in enterprise data center networks.

For many years the classical way to structure a network was with an Access-Aggregation-Core model, using a mixture of bridging, routing, and VLANs. It was primarily a layer 2–based design, with the layer 2/3 boundary at the core of the network. These layer 2, spanning tree–based, loop-free designs inherently limited the ability of the network to horizontally scale to address the increasing East-West bandwidth demand. Applications have evolved with each new generation requiring more bandwidth and lower latency than the previous one. New applications are more “media-rich” (think of the evolution from pure text to images, to videos, to high-definition, image rendering, and so on) but there is also a new way of structuring applications as microservices (see [Chapter 3](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch03.xhtml#ch03), “[Virtualization](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch03.xhtml#ch03)”), increasing the data exchanged between the different parts of an application.

In enterprise data center networks, servers have evolved from 1 Gbps connectivity to 10 Gbps and are now in the process of upgrading to 25 Gbps. In a cloud infrastructure, the number of supported customers far exceeds that of data centers, with servers connected at 40/50 Gbps and moving to 100 Gbps soon, posing significant requirements on data center and cloud networks. As a result, 200 and 400 Gbps interswitch links are now becoming common.

Speed is not the only thing that has changed. Applications have evolved from monoliths to multi-tiered (web server, application, database) scale-out applications, using distributed databases, stateless distributed microservices, creating a lot more demand for East-West network capacity and, more importantly, network services. Typically, the East-West traffic is 70 percent of overall traffic and is forecast to reach 85 percent by 2021 [[1](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch02.xhtml#ch02ref1)].

With this increase in scale and bandwidth and the change in application architecture, the access-aggregation networks have been discontinued in favor of Clos networks that have many advantages, as explained later in this chapter, but they are layer 3 routed networks and therefore they strictly limit the role of layer 2 bridging. To continue to support legacy applications that have layer 2 adjacency requirements, various tunneling technologies have been introduced, with VXLAN becoming the most prevalent and widely deployed industry standard (see [section 2.3.4](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch02.xhtml#ch02lev2sec3_4) for details).

This chapter drills down on these topics, and in particular it describes:

- The difference between bridging and routing

- Routing implementation techniques, such as LPM and caches

- Clos networks that enable most public cloud architectures and large enterprise data centers

- The importance of tunneling techniques and how to secure them

- Segment routing and traffic engineering techniques

- The role of discrete appliances and the traffic trombone

After you read this chapter, it should be evident that proper network design and implementation of routing and tunneling in hardware can significantly reduce the load on server CPU cores. The availability of flexible hardware will allow the encapsulations to evolve further as new abstractions are created, ensuring less hardcoding and yet providing the performance, low latency, and low jitter for various networking and distributed services.

Understanding network design is also crucial to understanding the limitations of the appliance model and where to best place the distributed service nodes.

### 2.1 Bridging and Routing

The debate between bridging and routing supporters has been very active for the last 25 years. With Ethernet being the only surviving technology at layer 2, the term *bridging* is today a synonym of Ethernet bridging, with its behavior defined by the Institute of Electrical and Electronics Engineers (IEEE) in IEEE 802.1 [[2](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch02.xhtml#ch02ref2)] and implemented by *bridges*. On the other hand, IP is the only surviving technology at layer 3, and *routing* is the synonym of IP routing with its behavior defined by IETF [[3](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch02.xhtml#ch02ref3)] (Internet Engineering Task Force) RFC (Request For Comment) standards and implemented by *routers*.

*Switch* and *switching* are terms that do not exist in standards; they were generally introduced to indicate a multiport layer 2 bridge. Over the years, their use has expanded to layer 3 switching (which we should correctly call *routing*) and also to stateful layer 4 forwarding as used by firewalls, load balancers, and other layer 4 functions.

Independent of naming, understanding the difference between layer 2 (L2) forwarding and layer 3 (L3) forwarding is essential.

#### 2.1.1 L2 Forwarding

Ethernet packets (properly called *frames*) have a straightforward structure that contains six fields: destination MAC address, source MAC address, 802.1Q tag, Ethertype (protocol inside the data field), data, and frame check sequence (FCS). The 802.1Q tag contains the VLAN identifier (VID) and the priority.

Of these fields, the only ones used in L2 forwarding are the VID and the destination MAC address that are concatenated and used as a key to search a MAC address table with an exact match technique. If the key is found, the table entry indicates where to forward the frame. If the key is missing, the frame is flooded to all the ports (except the one where it came in) in an attempt to make the maximum effort to deliver the frame to its final destination.

Usually, this exact match is implemented by using a hashing technique that has the capability of dealing with collisions; for example, through rehashing. Efficient hardware implementations exist for these hashing schemes.

This L2 forwarding requires a forwarding topology structured as a tree to avoid loops and packet storms. L2 forwarding uses the spanning tree protocol to prune the network topology and obtain a tree. One of the disadvantages of spanning tree is that it dramatically reduces the number of links usable in the network, blocking any connection that can cause a loop, thus substantially reducing the network bandwidth. For this reason, in modern network design, the role of bridging is strictly confined to the periphery of the network, whereas the network core uses L3 routing. We continue this discussion later in this chapter when speaking of Clos networks and VXLAN.

#### 2.1.2 L3 Forwarding

Layer 3 forwarding is different from L2 forwarding: if the packet needs to be sent across subnets, the destination IP address is searched in an IP routing table using a longest prefix match (LPM) technique. The routing table does not include all the possible IP addresses, but it contains prefixes. For example, in IPv4, the routing table may contain:

```
10.1.0.0/16 – port 1
10.2.0.0/16 – port 2
10.1.1.0/24 – port 3
```

The /*n* indicates that only the first *n* bits from the left are significant in any matching. Now let’s suppose that a packet has a destination IP of 10.1.1.2. The first entry has a 16-bit match, and the third entry has a 24-bit match, but it is mandatory to select the longest one (the one that is more specific)— that is, the third one—and therefore forward the packet on port 3.

If the LPM does not find a match in the forwarding table for the IP destination address, the packet is dropped. Not forwarding packets for which there is not a routing table entry is a significant difference compared to L2 forwarding, and it removes the requirement for a tree topology. In L3 forwarding the active network topology can be arbitrarily meshed. Temporary loops are acceptable and packets are discarded when they exceed their time to live (TTL).

LPM can be done in software using a variety of data structures and algorithms [[4](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch02.xhtml#ch02ref4)]. Linux uses a level-compressed trie (or LPC-trie) for IPv4, providing good performance with low memory usage. For IPv6, Linux uses a more traditional Patricia trie [[5](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch02.xhtml#ch02ref5)].

#### 2.1.3 LPM Forwarding in Hardware

LPM forwarding in HW is the most common implementation of layer 3 forwarding. It is used by almost all modern routers (including layer 3 switches) [[6](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch02.xhtml#ch02ref6)], [[7](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch02.xhtml#ch02ref7)].

[Figure 2-1](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch02.xhtml#ch02fig1) shows the simplicity of this approach. Each packet is processed independently of all the other packets; a full forwarding decision occurs in constant time. The packet per second (PPS) is very predictable, consistent, and independent of the type of traffic.

![A figure shows all packets entering as a single stream into an LPM forwarding and policies in the hardware block. The output is also a single stream.](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9780136624226/files/graphics/02fig01.jpg)

**FIGURE 2-1** LPM Forwarding

There are a few different ways to accomplish LPM in hardware. All of them require performing a “ternary match”; that is, a match where some of the bits are “don’t care” (represented by the letter “X”).

For example, the route 10.1.1.0/24 is encoded as

```
00001010 00000001 00000001 XXXXXXX
```

which means that the last 8 bits are “don’t care” (ignored) in the matching process.

Ternary matches are more challenging to implement in hardware compared to the binary matches used in L2 forwarding. For example, some commercial routers use a microcode implementation of Patricia trie. Others use a hardware structure called ternary content-addressable memory (TCAM) [[7](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch02.xhtml#ch02ref7)] that supports ternary matches. The TCAM also contains a priority encoder not just to return any matching entry, but to return the longest one to comply with LPM. Unfortunately, TCAMs take up significant silicon space and have high power consumption.

Pure IPv4 destination routing requires a 32-bits-wide forwarding table called a forwarding information base (FIB) to host all the routes, mostly the internal ones because the routes associated with the outside world are summarized in a few entries pointing to a few default gateways.

The FIB width can grow due to several factors:

- The presence of multiple routing tables (see [section 2.1.4](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch02.xhtml#ch02lev2sec1_4) for a discussion of virtual routing and forwarding [VRF])

- Using IPv6 in addition to IPv4; that is, 128-bit addresses instead of 32-bit addresses

- Supporting multicast routing

One additional advantage of this approach is that it is straightforward to upgrade the FIB as a result of a route change. If a routing protocol (for example, Border Gateway Protocol, or BGP [[8](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch02.xhtml#ch02ref8)]) changes a few routes, the associated entries in the FIB are updated without creating any traffic disruption.

#### 2.1.4 VRF

Virtual routing and forwarding (VRF) is a layer 3 network virtualization technology that permits multiple instances of a routing table to exist in a router and work simultaneously. This allows different kinds of traffic to be forwarded according to different routing tables. Each routing instance is independent of the others, thus supporting overlapping IP addresses without creating conflicts.

In VRF, each router participates in the virtual routing environment in a peer-based fashion; that is, each router selects the routing table according to some local criteria, the most common being the incoming interface (either physical or logical).

In the full implementation, VRF selects the routing table according to a “tag” inside the packet. Common tags are the VLAN ID or an MPLS label.

VRF requires the use of a routing protocol that is “VRF aware,” such as BGP.

### 2.2 Clos Topology

A Clos network is a multistage network that was first formalized by Charles Clos in 1952 [[9](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch02.xhtml#ch02ref9)]. In its simplest embodiment, it is a two-stage network like the one shown in [Figure 2-2](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch02.xhtml#ch02fig2). It can be scaled to an arbitrary number of stages, as explained later.

![The Clos network architecture is shown.](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9780136624226/files/graphics/02fig02.jpg)

**FIGURE 2-2** A Clos Network

A network diagram shows the two-stage Clos network. The first stage is denoted as "spines" and has four network appliances. The next stage is denoted as "leaves" and has four network appliances. The appliances in the spines and the leaves are interconnected. The first appliance in the leaves is connected to the servers A and B, the second appliance is connected to the servers C and D, the third appliance is connected to the servers E and F, and the fourth appliance is connected to the servers G and H.

In their current usage and parlance, two-stage Clos networks have leaves and spines. The spines interconnect the leaves, and the leaves connect the network users. The network users are mostly, but not only, the servers. In fact, any network user needs to be attached to the leaves and not to the spines, including network appliances, wide-area routers, gateways, and so on. The network users are typically stored in racks. Each rack in its top unit usually contains a leaf, and therefore a leaf is often called a top of rack (ToR) switch.

The Clos topology is widely accepted in data center and cloud networks because it scales horizontally and it supports East-West traffic well. There are multiple equal-cost paths between any two servers, and routing protocols can load balance the traffic among them with a technique called equal cost multi-path (ECMP). Adding additional spines increases the available bandwidth.

Clos networks are not suited for layer 2 forwarding, because the spanning tree protocol will prune them heavily, thus defeating their design principle. For this reason, the spanning tree protocol is not used between the spines and the leaves, but it is confined at the leaf periphery (southbound, toward the network users).

Each leaf owns one or more IP subnets, and it acts as the default gateway for these subnets. The subnets can be in the same or different VRFs.

Layer 3 routing protocols that support ECMP are used between the leaves and the spines, mainly BGP, with some deployment of Open Shortest Path First (OSPF) [[10](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch02.xhtml#ch02ref10)] and Intermediate-System to Intermediate-System (IS-IS) [[11](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch02.xhtml#ch02ref11)].

VXLAN encapsulation (see [section 2.3.4](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch02.xhtml#ch02lev2sec3_4)) provides layer 2 connectivity across a Clos network if required.

When using ECMP to distribute the load, it is essential not to create out-of-order packet delivery that can severely impact, for example, the performance of TCP-based applications. The flow hashing technique eliminates packet reordering. The five-tuple containing source and destination IP addresses, protocol type and source, and destination ports is hashed to select a path. Different implementations may use all or a subset of the five fields.

To further scale a Clos network both in terms of users and bandwidth, it is possible to add another tier of spines, thus creating a three-tier Clos network. Functionally, these new spines are equivalent to the other spines, but they are usually called super-spines. Three-tier Clos networks can be virtual chassis-based or pod-based, but they are outside the scope of this book. A book [[12](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch02.xhtml#ch02ref12)] from my dear friend Dinesh Dutt contains a detailed discussion of all topics related to Clos networks.

From a hardware perspective, super-spines, spines, and leaves can be the same type of box, resulting in a considerable simplification, because this reduces the number of spare parts that are needed and it simplifies the management and provisioning.

Clos networks are very redundant, and servers can be connected to two leaves if desired. Losing one switch in a Clos network is often a non-event, and, for this reason, each box does not need to have high availability or support inline software upgrade capability. Each switch can be upgraded independently from the others and replaced if required, without significantly disrupting network traffic.

### 2.3 Overlays

Encapsulation has proven very useful in providing abstractions in the networking industry over many years; for example, MPLS, GRE, IP in IP, L2TP, and VXLAN. The abstraction offered by layering allows for the creation of another logical networking layer on top of a substrate networking layer. It provides for decoupling, scale, and most importantly, newer network consumption models.

Network virtualization technologies require supporting multiple virtual networks on a single physical network. This section discusses overlay networks that are a common way to satisfy the previous requirements.

An *overlay network* is a virtual network built on top of an *underlay network*; that is, a physical infrastructure. The underlay network’s primary responsibility is forwarding the overlay encapsulated packets (for example, VXLAN) across the underlay network in an efficient way using ECMP when available. The underlay provides a service to the overlay. In modern network designs, the underlay network is always an IP network (either IPv4 or IPv6), because we are interested in running over a Clos fabric that requires IP routing.

In overlays, it is possible to decouple the IP addresses used by the applications (overlay) from the IP addresses used by the infrastructure (underlay). The VMs that run a user application may use a few addresses from a customer IP subnet (overlay), whereas the servers that host the VMs use IP addresses that belong to the cloud provider infrastructure (underlay).

An arrangement like the one described is shown in [Figure 2-3](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch02.xhtml#ch02fig3) where the VMs use addresses belonging to the 192.168.7.0/24 subnet and the servers use addresses belonging to the 10.0.0.0/8 subnet.

![Customers and infrastructure IP addresses are illustrated.](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9780136624226/files/graphics/02fig03.jpg)

**FIGURE 2-3** Customers and Infrastructure IP Addresses

A network diagram shows three servers namely server 1, server 2, and server 3. Server 1 has the virtual machine 1 of IP 192.168.7.1, Server 2 has the virtual machine 2 of IP 192.168.7.2, and Server 3 has the virtual machine 3 of IP 192.168.7.3. Server 1, Server 2, and Server 3 are connected to the internet via the IP addresses 10.1.7.251, 10.19.8.250, and 10.180.7.2 respectively.

Overlay networks are an attempt to address the scalability problem and to provide ease of orchestration fitting an agile model for network consumption, both critical for large cloud computing deployments. In the previous example, the packets exchanged between the virtual machines with source and destination addresses belonging to the subnet 192.168.7.0/24 are encapsulated into packets exchanged between the servers with source and destination addresses belonging to the subnet 10.0.0.0/8. The packets are said to be *tunneled*. The encapsulation is also referred to as *tunneling*, and the term *tunnel endpoints* (the points where the encapsulation is added or removed) is used.

In any overlay scheme there are two primary considerations:

- The first one is a data plane consideration: the structure of the encapsulated frame and the operations required to put a packet in the tunnel (encapsulate) and to remove a packet from the tunnel (decapsulate). Data plane considerations are of primary importance from a performance perspective. Forwarding decisions control tunneling operations, and this implies that they need to be integrated with LPM and flow tables; thus encapsulation and decapsulation should be incorporated into the forwarding hardware to achieve high performance.

- The second consideration is a control and management plane: tunnel creation and maintenance, address mapping, troubleshooting tools, and so on.

In this section, we focus on the data plane, and you will see that all the encapsulation schemes considered have the general structure shown in [Figure 2-4](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch02.xhtml#ch02fig4), where the concepts of underlay and overlay are apparent.

![A figure shows the generic encapsulation structure.](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9780136624226/files/graphics/02fig04.jpg)

**FIGURE 2-4** Generic Encapsulation

The generic encapsulation structure resembles a tunnel with an outer IP header, optional header in the middle, and innermost encapsulated packet. The outer IP header represents the underlay and its bottom-left corner denotes the tunnel endpoints. The encapsulated packet represents the overlay and its end attached with the optional header denotes the original endpoints.

Let’s consider the example of [Figure 2-3](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch02.xhtml#ch02fig3), and let’s assume that VM #2 wants to send a packet to VM #3. The original IP header contains Source Address (SA) = 192.168.7.2 and Destination Address (DA) = 192.168.7.3; the outer IP header contains SA = 10.19.8.250 and DA = 10.180.7.2. The content of the “other optional headers” depends on the encapsulation scheme.

In the continuation of this chapter, we will consider three encapsulation schemes: IP in IP, GRE, and VXLAN.

#### 2.3.1 IP in IP

One of the first standards that deals with encapsulation of IPv4 in IPv4 is RFC 1853 [[13](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch02.xhtml#ch02ref13)], which is dated October 1995, pretty ancient history in Internet years—an essential fact to consider when examining the choices made in that standard.

In 1995 the speed of the lines was still pretty slow, the topology was sparsely connected and typically lacking parallel links, and optimizing the usage of each byte in the packet was a primary concern. Software or microcode was used to implement routers, so when designing a protocol, being “hardware friendly” was not a consideration.

IPv4 in IPv4 was the first encapsulation defined, and it did not have any optional header. In the outer IP header, the field Protocol was set to 4 to indicate that another IPv4 header was next. Normally the field Protocol is set either to 6 to indicate a TCP payload or to 17 to indicate a UDP payload. The value 4 also gave the name “Protocol 4 encapsulation” to this scheme (see [Figure 2-5](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch02.xhtml#ch02fig5)).

![A figure shows the IPv4 in IPv4 encapsulation structure. The structure resembles a tunnel with an outer IPv4 header and inner IPv4 packet. The protocol of the IPv4 header is set to 4.](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9780136624226/files/graphics/02fig05.jpg)

**FIGURE 2-5** IPv4 in IPv4 Encapsulation

The same protocol 4 encapsulation is also usable for IPv4 inside IPv6. Merely set the field Next Header of the IPv6 header to 4 to indicate that the next header is an IPv4 header.

Another encapsulation is called *Protocol 41 encapsulation*. It is very similar to the previous one; the only difference is that the inner IP header this time is an IPv6 header. To encapsulate IPv6 in IPv4, set the Protocol of the outer IPv4 header to 41; to encapsulate IPv6 in IPv6, set the next header of the outer IPv6 header to 41 (see RFC 2473 [[14](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch02.xhtml#ch02ref14)]).

There are much more popular IPv6 in IPv4 encapsulations that are not covered in this book.

#### 2.3.2 GRE

In 1994 Cisco Systems introduced Generic Routing Encapsulation (GRE) and published it as informational RFC 1701 [[15](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch02.xhtml#ch02ref15)], [[16](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch02.xhtml#ch02ref16)]. The goal was to be able to encapsulate a wide variety of network layer protocols inside virtual point-to-point links over an IP network. When GRE was designed, this was an important feature due to the relevant number of layer 3 protocols that were present on LANs (for example, AppleTalk, Banyan Vines, IP, IPX, DECnet, and so on). Although nowadays this feature is less relevant because the only surviving protocols are IPv4 and IPv6, it is still important, because with virtualization there is a need to carry layer 2 traffic inside a tunnel. Efforts such as Network Virtualization using Generic Routing Encapsulation (NVGRE) [[17](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch02.xhtml#ch02ref17)] and L2 GRE try to satisfy this virtualization requirement.

In a nutshell, GRE adds an extra header between the outer IP header and the original IP header, as shown in [Figure 2-6](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch02.xhtml#ch02fig6).

![A figure shows the GRE encapsulation structure. The structure consists of the outer IPv4 header, GRE header in the middle, and any protocol at the innermost layer.](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9780136624226/files/graphics/02fig06.jpg)

**FIGURE 2-6** GRE Encapsulation

#### 2.3.3 Modern Encapsulations

Encapsulation requirements have evolved. Minimizing overhead is no longer critical. Although it remains essential to be hardware friendly and to support richly connected networks in which multipathing is used to achieve high throughput, the network should not reorder packet arrivals, as was discussed in [section 2.2](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch02.xhtml#ch02lev1sec2).

Routers achieve ECMP and avoid packet reordering by using a hash over the five-tuple, but the five-tuple is well defined only for TCP, UDP, and SCTP. SCTP is not very common; therefore, modern encapsulation must be based either on TCP or UDP.

TCP is not a choice because it is complicated to terminate and carrying a TCP session inside a TCP tunnel has been shown to perform very poorly due to the interaction between the inner and outer TCP congestion control algorithms [[18](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch02.xhtml#ch02ref18)], [[19](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch02.xhtml#ch02ref19)]. Research has shown that using a TCP tunnel degrades the end-to-end TCP throughput, creating, under some circumstances, what is called a TCP meltdown [[20](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch02.xhtml#ch02ref20)].

UDP has become the de facto standard for modern encapsulation schemes. For example, VXLAN (described in the next section) and RoCEv2 (described in [Chapter 6](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch06.xhtml#ch06), “[Distributed Storage and RDMA Services](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch06.xhtml#ch06)”) use UDP. In these applications, the UDP checksum is not used.

#### 2.3.4 VXLAN

Before entering into the details, let’s have a 10,000-feet view of why VXLAN is essential. As we mentioned in the introduction, access-aggregation networks allowed layer 2 domains (that is, layer 2 broadcast domains) to span multiple switches. The VID (VLAN identifier) was the standard way to segregate the traffic from different users and applications. Each VLAN carried one or more IP subnets that were spanning multiple switches.

Clos network changed this by mandating routing between the leaves and the spines and limiting the layer 2 domains to the southern part of the leaves toward the hosts. The same is true for the IP subnets where the hosts are connected. To solve the problem of using a Clos network, while at the same time propagating a layer 2 domain over it, VXLAN was introduced. In a nutshell, VXLAN carries a VLAN across a routed network.

In essence, VXLAN enables seamless connectivity of servers by allowing them to continue to share the same layer 2 broadcast domain. Although VLANs have historically been associated with the spanning tree protocol, which provides a single path across a network, VXLAN can use the equal cost multi-path (ECMP) of the underlying network to offer more bandwidth.

It was designed primarily to satisfy the scalability requirements associated with large cloud computing deployments. The VXLAN standard is defined in RFC 7348 [[21](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch02.xhtml#ch02ref21)] and the authors’ list, showing that it is a concerted effort among router, NIC, and virtualization companies, indicating the strategic importance of this overlay. [Figure 2-7](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch02.xhtml#ch02fig7) shows VXLAN encapsulation.

![A figure shows the VXLAN encapsulation structure. The structure resembles a tunnel with four layers: The first layer is the outer IPv4 header, the next layer is the UDP header, the third layer is the VXLAN header, and the innermost layer is original L2 frame.](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9780136624226/files/graphics/02fig07.jpg)

**FIGURE 2-7** VXLAN Encapsulation

VXLAN uses UDP encapsulation, and the destination UDP port is set to the well-known value of 4789.

The source UDP port should be randomly set, creating entropy that can be used by routers to load balance the traffic among multiple parallel links.

In a first example, the encapsulation endpoint can set the source UDP port to be equal to a hash of the original source IP address (the one in the inner IP header, typically belonging to a VM). In this way, all the packets belonging to a VM will follow one link, but other VMs may use different links. This choice implements load balancing at the VM level.

In a second example, the encapsulating endpoint may set the UDP source port to a hash of the five-tuple of the inner IP header. In this way, all the packets belonging to a single flow will follow the same path, preventing out-of-order packets, but different flows may follow different paths.

VXLAN is also used as a technology for encapsulating layer 3 unicast communication between application layers; this is evident in the newer revision of the VXLAN specification that allows for IP encapsulation within VXLAN natively.

Finally, VXLAN encapsulation adds a Virtual Network ID (VNID) to the original L2 frame, a concept similar to a VLAN-ID, but with a much broader range of values, because the VNID field is 24 bits, compared to the VLAN-ID field that is only 12 bits (see [Figure 2-8](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch02.xhtml#ch02fig8)).

![A detailed illustration of the VXLAN encapsulation.](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9780136624226/files/graphics/02fig08.jpg)

**FIGURE 2-8** VXLAN Encapsulation Details

The VXLAN encapsulation has the following fields: Outer MAC header, the outer IP header, User datagram Protocol (UDP) header, Virtual extensible local area network (VXLAN) header, and original L2 frame. The latter two are encapsulated in the UDP header which in turn is inside the outer IP header. The final layer is the frame check sequence (FCS). The outer MAC header has 14 bytes with optional 4 bytes. Destination MAC address (48 bits), Source MAC address (48 bits), VLAN type 0x8100 (16 bits), VLAN ID Tag (16 bits), and ether type 0x0800 (16 bits) are included in the outer MAC header. The outer IP header has 20 bytes allocated to IP header Miscellaneous data (72 bits), Protocol 0x11 (8 bits), header checksum (16 bits), outer source IP (32 bits), and Outer Destination IP (32 bits). The UDP header has 8 bytes allocated to UDP Source port, VXLAN Port, UDP length, and Checksum 0x0000, each 16 bits. The VXLAN header has 8 bytes allocated for VXLAN flags (8 bits), reserved (24 bits), VNID (24 bits), and reserved (8 bits).

The VXLAN encapsulation adds 50 bytes to the original layer 2 Ethernet frame, which needs to be considered in the context of the network underlay; see [section 2.3.5](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch02.xhtml#ch02lev2sec3_5) on MTU.

VNID can be used to put the packets from multiple tenants into the same VXLAN tunnel and to separate them easily at the tunnel egress point. [Figure 2-9](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch02.xhtml#ch02fig9) shows a VXLAN tunnel endpoint, or VTEP, in the leaf switches and the VXLAN tunnel overlaid on the underlying Clos network.

![An illustration of the virtual tunnel endpoints (VTEPs) in VXLAN.](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9780136624226/files/graphics/02fig09.jpg)

**FIGURE 2-9** VTEPs

The VXLAN tunnels have two functions: the routing and the bridging. The network setup has two spines that connect to the leaves. The VXLAN tunnel is overlaid between these two layers. Two spines are interconnected to three leaves (VTEP VNI 7) and routing takes place here. The three leaves are connected to the three hosts (host 1, host 2, and host 3), respectively, corresponding to bridging. The spines and the leaves are interconnected with more than one connection. One leaf is connected to one host.

VTEPs are configured by creating a mapping between the VLAN VID and the VXLAN VNID ([Figure 2-9](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch02.xhtml#ch02fig9) shows using the same number for VID and VNID, but this is not necessary). For traffic to flow, the VTEPs need to create forwarding table entries. They can do this in three ways:

- **“Flood and learn”:** This is the classical layer 2 approach discussed in [section 2.1.1](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch02.xhtml#ch02lev2sec1_1)

- **Through a distributed protocol that announces address reachability:** This is the approach taken in EVPN (Ethernet VPN) where BGP is used to advertise address reachability

- **Through an SDN (Software Defined Networking) approach:** A controller can configure the VTEPs; for example, through OVSDB (see [section 4.3.1](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch04.xhtml#ch04lev2sec3_1))

#### 2.3.5 MTU Considerations

Maximum transmission unit (MTU) is a term that indicates the maximum packet size at layer 3 that can be transmitted on a given link. The MTU depends on two factors:

- The size of the data field at the data link layer. In the case of an original Ethernet frame, this size was 1500 bytes, but “jumbo frames,” now universally supported, extended it to 9216 bytes.

- The presence of tunneling, since each time a new header is added to the packet, the payload is reduced by the size of the additional header.

Historically, the IPv4 protocol had the capability of fragmenting the packet under this circumstance, but modern IPv4 routers typically don’t fragment IP packets—they drop them if they exceed the link MTU, increasing the difficulty to troubleshoot malfunctioning. In IPv6 fragmentation is not supported.

Path MTU discovery (PMTUD) is a standardized technique for determining the MTU on the path between IP hosts. It is standardized in RFC 1191 [[22](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch02.xhtml#ch02ref22)], in RFC 1981 [[23](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch02.xhtml#ch02ref23)], and in RFC 4821 [[24](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch02.xhtml#ch02ref24)]. It can help in avoiding MTU issues in overlay networks. It requires ICMP to discover the actual usable MTU on a network from an end host to an end host. Unfortunately, some network administrators disabled ICMP, and some implementations were affected by bugs, so path MTU discovery got a bad reputation. Many network managers prefer to manually configure the MTU to a lower value so that there are no issues in the presence of tunneling. Normally they reserve 100 bytes to account for packet size growth due to encapsulation.

### 2.4 Secure Tunnels

The tunneling and encapsulation techniques described up to this point solve a variety of problems, including address issues, layer 2 domain propagation, multicast and broadcast propagation, multiprotocol support, and so on, but do not deal with the privacy of the data. In fact, even when the data undergoes encapsulation, it is still in the clear and can be read by an eavesdropper. This lack of security may be acceptable inside the data center, but it is not tolerable when the transmission happens on a public network, in particular on the Internet.

The conventional way to secure tunnels is with the addition of encryption. [Section 5.11](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch05.xhtml#ch05lev1sec11) describes the encryption algorithms used by secure tunnels.

### 2.5 Where to Terminate the Encapsulation

Hosts, switches, and appliances terminate different kinds of tunnels.

Software running on the host may terminate encapsulations, and this is common in virtualized environments that do not require high performance. The network interface card in the server may provide some degree of hardware support to terminate tunnels. Appliances are commonly used to terminate all sorts of encapsulations. Initially, appliances were stand-alone boxes with physical interfaces, but recently they are also sold as “virtual appliances”; for example, as virtual machines to run in a virtualized environment. Top of Rack (ToR) switches can also terminate all kinds of encapsulation; for example, they support VLAN to VXLAN mapping to allow layer 2 traffic to propagate over a layer 3 Clos network, as explained in [section 2.3.4](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch02.xhtml#ch02lev2sec3_4).

Terminating simple encapsulations is relatively easy, even if not all the hardware solutions recognize all the encapsulation schemes. Complexity arises because, after terminating the encapsulation, other actions need to happen, like bridging or routing and potentially adding another encapsulation. When authentication and encryption are present, the requirement for dedicated hardware to achieve high performance is real. The need for specialized hardware becomes even more evident if the tunneling scheme requires terminating TCP, as in the case of TLS.

### 2.6 Segment Routing

Source routing is a technology known for decades in which the sender of the packet decides the path the packet should take to its destination. Segment routing (SR) [[25](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch02.xhtml#ch02ref25)] is a form of source routing where the source node defines the forwarding path as an ordered list of “segments.” There are two kinds of Segment Routing:

- SR-MPLS, which is based on Multiprotocol Label Switching (MPLS)

- SRv6, which is based on IPv6

The underlying technology used by SR-MPLS is Multiprotocol Label Switching (MPLS), a routing technique that directs data from one node to the next based on “labels” rather than network addresses. Alternatively, SR can use an IPv6 data plane, as is the case in SRv6.

Segment routing divides the network into “segments” where each node and link could be assigned a segment identifier, or a SID, which is advertised by each node using extensions to standard routing protocols like IS-IS, OSPF and BGP, eliminating the need to run additional label distribution protocols such as MPLS LDP.

SR imposes no changes to the MPLS data plane. In SR the ordered list of segments is encoded as a stack of labels. The first segment to process is on the top of the stack. Upon completion of a segment processing, the segment is removed from the stack.

For example, in the absence of SR the routing between the Source and the Destination in [Figure 2-10](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch02.xhtml#ch02fig10) is composed of two ECMPs: A - D - F - G and A - D - E - G (assuming all links have the same cost). In the presence of SR it is possible to forward the packet across other links. For example, if the source specifies a stack E/C/A, where A is the top of the stack, the packet is forwarded to A that pops its label, resulting in a stack containing E/C. Then A sends the packet to C, C will pop its label and forward the packet to E, which delivers it to its destination.

![An illustration of the segment routing with two equal-cost multi-path routing.](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9780136624226/files/graphics/02fig10.jpg)

**FIGURE 2-10** Segment Routing Example

The segment routing from the source to the destination is shown. Between the source and the destination, there are seven segments. The connection through which the packets are forwarded from source to destination is as follows: Source is connected to 'A,' 'A' connects to B and D respectively. B connects to C. C and D connect to E. D also connects to F. F and E respectively connect to G. G connects to the destination.

Using SR, it is possible to implement traffic engineering to allow the optimal usage of network resources by including links that are not part of the ECMP paths provided by IP routing.

Segment routing offers the following benefits:

- Network slicing, a type of virtual networking architecture with the ability to express a forwarding policy to meet a specific application SLA (for example, latency, bandwidth)

- Traffic engineering

- Capability to define separate paths for disjoint services

- Better utilization of the installed infrastructure

- Stateless service chaining

- End-to-end policies

- Compatibility with IP and SDN

### 2.7 Using Discrete Appliance for Services

This section contains an example of a communication between two servers that goes through a firewall and a load balancer, an operation customarily called *service chaining*.

[Figure 2-11](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch02.xhtml#ch02fig11) shows a Server C that needs to communicate with Server E through a load balancer (Virtual Server Z). For security, the communication between Server C and Virtual Server Z also needs to go through a firewall. This can be achieved with a layer 2 or with a layer 3 approach.

![A network diagram of the layer 2 approach for the communication between two servers.](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9780136624226/files/graphics/02fig11.jpg)

**FIGURE 2-11** Example of Trombone at Layer 2

The illustration shows four spine switches in the first layer, 4 leaves in the second layer, and 8 servers in the third layer. The spines S1, S2, S3, and S4 are in the first layer. The spines have multiple connections (normal and virtual) to the leaves L1, L2, L3, and L4. The leaves are connected to respective servers. The leaf L1 is connected to servers 'A' and B, the leaf L2 is connected to server C (source) and server D. A virtual connection exists between L2 and server C. The leaf L3 has virtual and normal connections with server E (destination) and server F, respectively. The leaf L4 has a normal connection with the servers G and H. The spine S2 is virtually connected to leaf L1, which is in turn connected to the firewall. The spine S3 is virtually connected to leaf L4, which is then connected to the load balancer virtual server Z.

#### 2.7.1 Tromboning with VXLAN

The first example is based on a layer 2 approach where the firewall is deployed in transparent mode, acting as the default router for the server C subnet. Please note that a host and its default router need to be in the same subnet. This is impossible without some encapsulation, because in a Clos network each leaf has native IP addresses in its own subnet. The network manager maps each subnet to a VLAN and enables VLAN trunking toward the firewall, so that the firewall may act as the default gateway for hosts in different subnets. In our case, the network manager uses a VLAN with VLAN-ID = 7 from server C to the leaf switch L2. The leaf switch L2 maps VLAN 7 to a VXLAN segment with VNID = 7 (to keep the example simple). The encapsulated frame goes through S2 to L1, L1 removes the VXLAN encapsulation and passes the packet on VLAN 7 to the firewall that receives it and applies the appropriate policies. If the packet complies with the policies, the firewall forwards it to the virtual server Z; that is, the load balancer using the same process. Again, L1 encapsulates the packet in VXLAN, L1 forwards to S4, S4 forwards to L4, L4 decapsulates and gives the packet to the load balancer that decides to send it to server E, where the same encapsulation/ decapsulation process happens again.

This process has two major deficiencies:

- For server C to communicate with server E, the packet has to cross the network three times instead of one. We have spent 30 years in trying to optimize packet routing at layer 3, and now we throw it out of the window because we need to support discrete appliances.

- The firewall acts as an inter-VLAN router between L2 domains, and a significant amount of traffic is funneled through the firewall in a technique colorfully described as traffic trombone or traffic tromboning [[26](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch02.xhtml#ch02ref26)], [[27](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch02.xhtml#ch02ref27)]. In doing so, it also creates a bottleneck. Given the complexity of today’s network architectures, an appliance-based security tromboning approach is an unrealistic option.

The solution to both these issues is to distribute the service functionality as close to the servers as possible. [Chapter 9](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch09.xhtml#ch09), “[Implementing a DS Platform](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch09.xhtml#ch09),” introduces a distributed service network architecture that provides services in the NICs or rack appliance or the ToR switches to solve both these problems in a scalable way.

#### 2.7.2 Tromboning with VRF

This second example is based on a layer 3 approach where the firewall is deployed in routed mode, which uses the VRF configuration described in [section 2.1.4](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch02.xhtml#ch02lev2sec1_4).

We start with the more straightforward case of using the firewall in [Figure 2-12](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch02.xhtml#ch02fig12) only for the North-South security policy enforcement case.

![A network setup illustrates the layer 3 approach in the tromboning with VRF.](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9780136624226/files/graphics/02fig12.jpg)

**FIGURE 2-12** Example of Trombone at Layer 3

The node S1 in the Spine is connected to the node L1 and L2 of the leaves. The connectivity between the spine and the leaf uses blue VRF. The node L1 connected is to the servers 'A' and B. The node L2 is connected to the internet on one side and the centralized firewall on the other side. The node L2 and the internet are connected via the red VRF. The nodes L2 and the centralized firewall are connected via the blue and red VRF. The routes from the internet to the node L2, and then to the centralized firewall and the route from the centralized firewall to the node L2, and then the spine S1 denote the default routes.

We define two VRFs: the Red VRF associated with the Internet (external) traffic and the Blue VRF associated with the data center internal traffic. All the switches in our network participate in the Blue VRF, while the leaf L2 is also a part of the Red VRF. L2 distinguishes between the Blue and the Red VRFs based on the physical ports. More sophisticated association schemes are possible, but not required for this example. The firewall has interfaces on both the Blue VRF (internal network) and the Red VRF (external network), so it is the only point of contact between the two VRFs, and thus all the traffic to/from the Internet must transit through the firewall.

The Internet-facing edge router injects the default route. The firewall receives it on the Red link and then pushes into the Blue link. The firewall has no notion of VRFs; it just maintains two BGP sessions: one on the Red link and the other on the Blue link.

Only Leaf 2 runs BGP in the Internet-facing Red VRF, with two sessions: one peering with the Internet-facing router and the other peering with the firewall on the Red link. All other routers run BGP in the Blue VRF. For example, Leaf 2 runs BGP in the Blue VRF with peering sessions to the firewall on the Blue link and Spine 1.

This default route causes all the external traffic from the Blue VRF to go through the firewall. The firewall applies its security policy and forwards the traffic through the Red VRF to the Internet. Similarly, in the opposite direction, the traffic coming from the Internet reaches the firewall on the Red VRF, and the firewall applies its security policy and forwards the traffic through the Blue VRF to its internal destination.

It is possible to use the same principle also for the East-West security policy enforcement case. In this case we need to define more VRFs. Let’s suppose that we have four groups of servers that we want to keep separate on the East-West direction—we define four VRFs on all the switches of the Clos network, plus one external VRF on the leaf L2. The firewall will have five layer 3 interfaces defined, one per VRF. These interfaces don’t need to be physical ports; they can be different VLANs in different subinterfaces on the same physical port.

Compared to the previous case, we have not used any VXLAN encapsulation, and the firewall is not the default gateway of the server. The firewall injects the default route, whereas the default gateway for the server remains its leaf switch (in [Figure 2-12](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch02.xhtml#ch02fig12) Server A has leaf L1 as the default gateway).

#### 2.7.3 Hybrid Tromboning

The two previous approaches can be combined into a hybrid approach. VXLAN can be used as described in [section 2.7.1](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch02.xhtml#ch02lev2sec7_1), but the firewall does not need to be the default gateway. The firewall injects the default routes as described in [section 2.7.2](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch02.xhtml#ch02lev2sec7_2).

### 2.8 Cache-Based Forwarding

The technique discussed in this section is not used in routers, but it has some implementation on the hosts, often in conjunction with a NIC.

Cloud providers have a large number of tenants and, even if routing and access control lists (ACLs) requirements for each tenant are moderate, when multiplied by the number of tenants there is an explosion in the number of routes and ACLs, which can be difficult to accommodate on the host with traditional table lookups.

Some cloud providers decided to implement a cache-based forwarding scheme in the server NIC hardware instead of maintaining an entire forwarding database.

A flow cache is a binary data structure capable of exactly matching packets belonging to a particular flow. The word “exactly” implies a binary match easier to implement both in hardware or software, unlike a ternary match such as LPM.

A flow cache contains an entry for each known packet flow. The flow can be defined with an arbitrary number of fields, thus supporting IPv6 addresses, different encapsulations, policy routing, and firewalling. New cache entries may be created by a separate process if a packet does not match any flow in the flow cache (this is called “a miss”).

[Figure 2-13](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch02.xhtml#ch02fig13) shows the organization of this solution. Any packet that causes a miss in the flow cache is redirected to a software process that applies a full decision process and forwards or drops the packet accordingly. This software process also adds an entry in the flow cache (dashed line) so that subsequent packets can be forwarded or dropped as the previous packets of the same flow.

![An illustration of the cache-based forwarding in hardware.](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9780136624226/files/graphics/02fig13.jpg)

**FIGURE 2-13** Cache-based Forwarding in HW

Cache-based forwarding involves the following processes. All the data packets are forwarded through the flow cache. The packets that are missed in the flow cache are directed to the SW LPM forwarding and policies. This data is fed into the flow cache through programming. These packets are then forwarded out of this hardware.

Let’s suppose that an average flow is composed of 500 packets: one will hit the software process, and the remaining 499 will be processed directly in hardware with a speed-up factor of 500 compared to a pure software solution. Of course, this solution should guarantee that packets that are processed in software and in hardware don’t get reordered.

In this case, the packet per second (PPS) is not predictable and constant, because it depends on the type of traffic. Recent advances such as persistent connections in the HTTP/HTTPS protocols (that account for the majority of the traffic) tend to make the flows longer and, therefore, can play in favor of this solution.

Another consideration is that multiple protocols exchange only a couple of packets per flow. These are auxiliary protocols like Domain Name Server (DNS), Time Server, and so on. For these protocols, it is not meaningful to create a cache entry, because it only consumes cache resources without generating a significant increase in performance.

The width of the cache may be significant, due to these factors:

- Doing source routing in addition to destination routing: two addresses instead of one

- Using IPv6 in addition to IPv4: 128-bit addresses instead of 32-bit addresses

- Using overlay techniques (see [section 2.3](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch02.xhtml#ch02lev1sec3)) like IP in IP or VXLAN: more headers to parse

- Doing policy routing on layer 4 headers: the need to parse protocol types and source and destination ports

- Implementing firewalls and load balancers

In an extreme case, the cache width was 1700 bits, making the hardware extremely complicated; that is, more square millimeters of silicon, higher cost, and more power.

An attractive property of this solution is ease of merging multiple services into a single cache entry; for example, it is possible to remove an encapsulation, route the packet, apply firewall rules, and collect statistics with a single cache entry.

Of course, as with all cache solutions, there is the issue of cache maintenance; for example, aging old entries. A bigger problem happens when a route changes. In fact, there is no easy way to know which cache entries are affected and therefore the conventional approach is to invalidate the whole cache. Immediately after clearing the cache, there is a drop-in performance that, even if transient, is significant. For this reason, cache-based forwarding is not used in backbone routers that are subject to frequent route changes. In the case of a peripheral network service point, one can argue route changes are a rare event, and therefore cache invalidation is acceptable. [Chapter 3](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch03.xhtml#ch03), “[Virtualization](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch03.xhtml#ch03),” describes a few implementations of software switches that use this technique. In some cases, the first packet is processed on the server CPU core; in other instances it is processed in cores embedded in a NIC, providing different grades of offload.

### 2.9 Generic Forwarding Table

Generic forwarding table (GFT) is an approach used in Microsoft Azure [[28](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch02.xhtml#ch02ref28)], [[29](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch02.xhtml#ch02ref29)] that follows the model described in the previous section. Azure has a virtual machine offering based on Hyper-V, the Microsoft Hypervisor (see [section 3.2.2](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch03.xhtml#ch03lev2sec2_2)). Hyper-V includes a software switch to forward packets between the virtual machines and the network. To implement GFT, Microsoft built VFP (Virtual Filtering Platform) to operate on top of Hyper-V software switch. VFP has the concept of unified flows, matching a unique source and destination L2/L3/L4 tuple, potentially across multiple layers of encapsulation, along with the capability of adding, removing, or modifying headers.

A custom Azure SmartNIC includes a field programmable gate array (FPGA) to accelerate the forwarding operations by implementing the flow cache in hardware [[30](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch02.xhtml#ch02ref30)].

The cache redirects any packet that has a miss to VFP, which in turn forwards the packet in software and programs the cache.

Currently, VFP runs on the primary server CPU, but there is no technical reason why the SmartNIC itself cannot have a CPU to host VFP, thus freeing server CPU cycles.

### 2.10 Summary

In this chapter, we discussed the network design concepts that are at the basis of designing a distributed network service architecture. We discussed L2 versus L3 forwarding, two different implementations of L3 forwarding, the impact of Clos networks, and the requirements for routing in the network core. This requires the introduction of overlay networks and a way of securing them. We have also analyzed how the presence of appliances creates the tromboning issue and how a distributed services architecture solves that. Finally, we have discussed segment routing as a way to increase network utilization and predictability.

In the next chapter, we discuss in a similar and parallel way the impact of virtualization on a distributed network service architecture.

### 2.11 Bibliography

**[[1](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch02.xhtml#rch02ref1)]** Cisco Global Cloud Index: Forecast and Methodology, 2016–2021, [https://www.cisco.com/c/en/us/solutions/collateral/service-provider/global-cloud-index-gci/white-paper-c11-738085.pdf](https://www.cisco.com/c/en/us/solutions/collateral/service-provider/global-cloud-index-gci/white-paper-c11-738085.pdf)

**[[2](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch02.xhtml#rch02ref2)]** [https://1.ieee802.org](https://1.ieee802.org/)

**[[3](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch02.xhtml#rch02ref3)]** RFC Editor, “Internet Official Protocol Standards,” RFC5000, May 2008.

**[[4](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch02.xhtml#rch02ref4)]** W. Eatherton, Z. Dittia, and G. Varghese. Tree Bitmap: Hardware/Software IP Lookups with Incremental Updates. ACM SIGCOMM Computer Communications Review, 34(2):97–122, 2004. Online at [http://cseweb.ucsd.edu/~varghese/PAPERS/ccr2004.pdf](http://cseweb.ucsd.edu/~varghese/PAPERS/ccr2004.pdf)

**[[5](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch02.xhtml#rch02ref5)]** Park, Hyuntae, et al. “An efficient IP address lookup algorithm based on a small balanced tree using entry reduction.” Computer Networks 56 (2012): 231–243.

**[[6](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch02.xhtml#rch02ref6)]** Waldvogel, M., Varghese, G., Turner, J.S., & Plattner, B. (1997). Scalable High Speed IP Routing Lookups. SIGCOMM.

**[[7](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch02.xhtml#rch02ref7)]** Pagiamtis, K.; Sheikholeslami, A. (2006). “Content-Addressable Memory (CAM) Circuits and Architectures: A Tutorial and Survey.” IEEE Journal of Solid-State Circuits. 41 (3): 712–727. Online at [https://www.pagiamtzis.com/pubs/pagiamtzis-jssc2006.pdf](https://www.pagiamtzis.com/pubs/pagiamtzis-jssc2006.pdf)

**[[8](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch02.xhtml#rch02ref8)]** Lougheed, K. and Y. Rekhter, “Border Gateway Protocol 3 (BGP-3)”, RFC 1267, DOI 10.17487/RFC1267.

**[[9](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch02.xhtml#rch02ref9)]** Clos, Charles. “A study of non-blocking switching networks”. Bell System Technical Journal. 32 (2): 406–424. doi:10.1002/j.1538-7305.1953. tb01433.x. ISSN 0005-8580. Mar 1953, Retrieved 22 March 2011.

**[[10](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch02.xhtml#rch02ref10)]** Moy, J., “OSPF Version 2”, STD 54, RFC 2328, DOI 10.17487/RFC2328, April 1998.

**[[11](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch02.xhtml#rch02ref11)]** Zinin, A., “Cooperative Agreement Between the ISOC/IETF and ISO/IEC Joint Technical Committee 1/Sub Committee 6 (JTC1/SC6) on IS-IS Routing Protocol Development”, RFC 3563, DOI 10.17487/RFC3563.

**[[12](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch02.xhtml#rch02ref12)]** Dutt, Dinesh. “Cloud-Native Data Center Networking Architecture: Protocols, and Tools.” O’Reilly, 2019.

**[[13](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch02.xhtml#rch02ref13)]** Simpson, W., “IP in IP Tunneling,” RFC 1853, DOI 10.17487/RFC1853, October 1995.

**[[14](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch02.xhtml#rch02ref14)]** Conta, A. and S. Deering, “Generic Packet Tunneling in IPv6 Specification,” RFC 2473, DOI 10.17487/RFC2473, December 1998.

**[[15](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch02.xhtml#rch02ref15)]** Hanks, S., Li, T., Farinacci, D., and P. Traina, “Generic Routing Encapsulation (GRE),” RFC 1701, DOI 10.17487/RFC1701, October 1994.

**[[16](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch02.xhtml#rch02ref16)]** Farinacci, D., Li, T., Hanks, S., Meyer, D., and P. Traina, “Generic Routing Encapsulation (GRE),” RFC 2784, DOI 10.17487/RFC2784, March 2000.

**[[17](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch02.xhtml#rch02ref17)]** Garg, P., Ed., and Y. Wang, Ed., “NVGRE: Network Virtualization Using Generic Routing Encapsulation,” RFC 7637, DOI 10.17487/RFC7637, September 2015.

**[[18](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch02.xhtml#rch02ref18)]** O. Titz, “Why TCP over TCP is a bad idea.” [http://sites.inka.de/sites/bi-gred/devel/tcp-tcp.html](http://sites.inka.de/sites/bi-gred/devel/tcp-tcp.html)

**[[19](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch02.xhtml#rch02ref19)]** Honda, Osamu & Ohsaki, Hiroyuki & Imase, Makoto & Ishizuka, Mika & Murayama, Junichi. (2005). Understanding TCP over TCP: effects of TCP tunneling on end-to-end throughput and latency. Proc SPIE. 104.10.1117/12.630496.

**[[20](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch02.xhtml#rch02ref20)]** OpenVPN, “What is TCP Meltdown?,” [https://openvpn.net/faq/what-is-tcp-meltdown](https://openvpn.net/faq/what-is-tcp-meltdown)

**[[21](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch02.xhtml#rch02ref21)]** Mahalingam, M., Dutt, D., Duda, K., Agarwal, P., Kreeger, L., Sridhar, T., Bursell, M., and C. Wright, “Virtual eXtensible Local Area Network (VXLAN): A Framework for Overlaying Virtualized Layer 2 Networks over Layer 3 Networks,” RFC 7348, DOI 10.17487/RFC7348, August 2014.

**[[22](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch02.xhtml#rch02ref22)]** Mogul, J. and S. Deering, “Path MTU discovery,” RFC 1191, DOI 10.17487/RFC1191, November 1990.

**[[23](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch02.xhtml#rch02ref23)]** Lottor, M., “Internet Growth (1981–1991),” RFC 1296, DOI 10.17487/RFC1296, January 1992.

**[[24](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch02.xhtml#rch02ref24)]** Mathis, M. and J. Heffner, “Packetization Layer Path MTU Discovery,” RFC 4821, DOI 10.17487/RFC4821, March 2007.

**[[25](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch02.xhtml#rch02ref25)]** Filsfils, C., Ed., Previdi, S., Ed., Ginsberg, L., Decraene, B., Litkowski, S., and R. Shakir, “Segment Routing Architecture,” RFC 8402, DOI 10.17487/RFC8402, July 2018.

**[[26](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch02.xhtml#rch02ref26)]** Ivan Pepelnjak, “Traffic Trombone (what it is and how you get them),” [ip-space.net](http://ip-space.net/), February 2011. [https://blog.ipspace.net/2011/02/traffic-trombone-what-it-is-and-how-you.html](https://blog.ipspace.net/2011/02/traffic-trombone-what-it-is-and-how-you.html)

**[[27](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch02.xhtml#rch02ref27)]** Greg Ferro, “VMware ‘vFabric’ and the Potential Impact on Data Centre Network Design—The Network Trombone” [etherealmind.com](http://etherealmind.com/), August 2010, [https://etherealmind.com/vm-ware-vfabric-data-centre-network-design](https://etherealmind.com/vm-ware-vfabric-data-centre-network-design)

**[[28](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch02.xhtml#rch02ref28)]** Greenberg, Albert. SDN for the Cloud, acm sigcomm, 2015.

**[[29](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch02.xhtml#rch02ref29)]** Firestone, Daniel et al. “Azure Accelerated Networking: SmartNICs in the Public Cloud.” NSDI (2018), pages 51–66.

**[[30](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch02.xhtml#rch02ref30)]** Daniel Firestone. “VFP: A virtual switch platform for host SDN in the public cloud.” In 14th USENIX Symposium on Networked Systems Design and Implementation (NSDI 17), pages 315–328, Boston, MA, 2017. USENIX Association.

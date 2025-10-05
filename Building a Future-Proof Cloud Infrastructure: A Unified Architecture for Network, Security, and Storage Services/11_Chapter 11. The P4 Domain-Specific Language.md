## Chapter 11. The P4 Domain-Specific Language

In the previous chapter, we explained that the application-specific integrated circuit (ASIC) architecture is best suited to implement a DSN, but we want to add data plane programmability, which is extremely data intensive and is still rare.

The P4 architecture will help us achieve this goal.

The Programming Protocol-independent Packet Processors (P4) architecture formally defines the data plane behavior of a network device, and it supports both programmable and fixed-function network devices. The idea derived from the SDN and OpenFlow movement (see [section 4.2.1](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch04.xhtml#ch04lev2sec2_1)) and was first published in 2013 [[1](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch11.xhtml#ch11ref1)], [[2](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch11.xhtml#ch11ref2)].

In March 2015, the P4 language consortium was created [[3](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch11.xhtml#ch11ref3)], version 1.0.2 of “The P4 Language Specification” was posted, and in June 2015, Professor Nick McKeown hosted the first P4 workshop at Stanford University.

A lot has happened since then, and now the P4 project is hosted by the Open Networking Foundation [[4](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch11.xhtml#ch11ref4)], and the P4 specifications and any contributed code are primarily licensed under the Apache 2.0 License.

P4 adds to the ASIC architecture the missing data plane programmability aspect. Some of the benefits include the following:

- Adding support for new protocols is easy.

- It is possible to remove unused features and free up associated resources, thus reducing complexity and enabling the reallocation of resources for used features.

- It provides agility in rolling out updates on existing hardware.

- It offers greater visibility into the network.

- It allows the implementation of proprietary features, thus protecting intellectual property. This point is crucial for large users such as public cloud providers.

P4 programs can specify how the switch inside the DSN processes packets. It is possible to implement most of the services described in this book, except for those that require dedicated hardware structures; for example, encryption.

The first version of the P4 specification was called version 14 and had some significant limitations. It targeted a network device with an architecture like the one shown in [Figure 11-1](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch11.xhtml#ch11fig1).

![A figure shows an example of P4 version 14 network device.](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9780136624226/files/graphics/11fig01.jpg)

**FIGURE 11-1** Example of P4 Version 14 Network Device

In P4 version 14 network device architecture, the input packets enter the programmable parser (Programmer declares the headers that should be recognized and their order in the packet). From the programmable parser, the packets are sent through the programmable match-action pipeline (Programmer defines the tables and the exact processing algorithm). Then the packets enter the programmable deparser (Programmer declares how the output packet will look on the wire) and finally output packets are received.

This device has three main components:

- **Programmable parser:** This is important because P4 does not have any predefined packet formats. It is composed of a state machine that specifies which packet format the switch recognizes and that generally has one state for each protocol. In each state, the parser extracts some protocol-specific information used in the rest of the pipeline. A classic example is the parsing of an Ethernet frame and then, as a function of the EtherType, parsing either an IPv4 header or an IPv6 header to extract the source and destination IP addresses. The programmable parser may extract and feed more than one header in the pipeline.

- **Programmable match-action pipeline:** The previously extracted headers are the inputs of a series of match-action tables that can modify them. While the headers go through the pipeline, they can carry with them metadata information generated in the previous pipeline stages. This match-action pipeline may also add new headers to the packet.

- **Programmable deparser:** It takes all the headers and constructs the output packet with the valid ones followed by the payload, and it serializes it to the destination port.

While the headers traverse the pipeline, metadata accompanies them. There are two kinds of metadata: standard and user defined. The standard metadata contains fields like input port, packet length, and timestamp. The user-defined metadata can include, for example, the virtual routing and forwarding (VRF) value associated with the packets and derived from a table lookup in a previous stage of the pipeline.

The most common case is that a packet enters the P4 pipeline, goes through it, and a modified packet exits it. Of course, the packet can also be dropped; for example, due to an ACL. Other special operations are “cloning” a packet to send it to a switched port analyzer (SPAN) port, multicast replication, and “recirculating” a packet. This last operation is useful when, due to the complexity of the processing, the packet cannot be processed entirely in one pass, and consequently, it is reinjected at the input for further processing. Recirculation reduces performance.

### 11.1 P4 Version 16

In May 2017 P4 version 16 was posted, containing significant improvements to the previous version. P4 was extended to target multiple programmable devices with different architectures. [Figure 11-2](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch11.xhtml#ch11fig2) shows that there are two groups of constructs: above the dashed line are general concepts that are common to all P4 implementations. Below the dashed line are architecture-specific definitions and components.

![The different P4 language components are described in the figure.](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9780136624226/files/graphics/11fig02.jpg)

**FIGURE 11-2** P4 Language Components

The different constructs used for P4 implementations are listed as follows: parsers (state machine bit field extraction), controls (tables, actions, control flow statements), expressions (basic operations and operators), data types (bistrings, headers, structures, arrays), architecture description (programmable blocks and their interfaces), and extern libraries (support for specialized components). A horizontal dashed line separates the constructs into two groups: parsers, controls, expressions, and data types come under one group and architecture description and extern libraries come under other group. A P4 architecture is shown on the right, where the packets pass through a parser, a programmable match-action pipeline, then followed by a parser and deparser. The control components are processed in the match-action pipeline and deparser.

P4 version 16 introduces the following concepts[[5](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch11.xhtml#ch11ref5)]:

- **Architecture:** “A set of P4-programmable components and the data plane interfaces between them.” The architecture is an abstraction of the underlying device, the way P4 programmers think about the device data plane.

- **Target:** “A packet-processing system capable of executing a P4 program.” In general, it is a hardware device, but P4 16 also supports software switches such as OVS.

P4 16 main components are:

- **The P4 programming language:** P4 programs specify how the various programmable blocks of the data plane of a network device are programmed and connected. P4 does not have any preconceived packet format or protocol knowledge. A P4 program expresses how packets are processed by the data plane of a programmable network-forwarding element.

- **The Portable Switch Architecture (PSA):** A description of standard capabilities of network devices that process and forward packets across multiple interface ports.

- **The P4Runtime API:** A control plane specification for controlling the data plane elements of a device defined or described by a P4 program.

- **In-band Network Telemetry (INT):** A draft specification on how to collect telemetry data as a packet traverses the network.

### 11.2 Using the P4 Language

The P4 language [[5](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch11.xhtml#ch11ref5)] is a domain-specific language (DSL) targeted toward a high-performance hardware implementation. A modern network device processes billions of packets per second. This is achievable with a programmable infrastructure only if there is a functional coupling between the DSL and the domain-specific hardware. The P4 language has concepts like table lookups that match a hardware table lookup but, for example, even a table lookup cannot be invoked more than once to maintain the performance predictably. To improve hardware performance, P4 generally uses data structures of fixed size.

The core elements in the P4 language are shown in [Figure 11-2](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch11.xhtml#ch11fig2) and are:

- **Parsers:** State machines to define the packet formats accepted by a P4 program. The parser is one place where the P4 language allows loops, because many headers may need to be extracted or reassembled.

- **Controls:** It defines a directed acyclic graph (DAG) of match-action tables. The term *DAG* indicates an if-then-else program structure that forbids loops.

- **Expression:** Parsers and controls are written using expressions. Expressions include standard expressions on boolean, bit-field operators; comparison, simple arithmetic on integer, conditional operators; operations on sets; operations on headers; and so on.

- **Data types:** P4 is a statically typed language. Supported data types are void, error, boolean, bit-strings of fixed width, signed integers, the match_ kind used for describing the implementation of table lookups, and so on. Constructors can be applied to these basic data types to derive more complex ones. Examples of constructors are header, struct, tuple, extern, and parser.

- **Architecture descriptions:** This is the description of the network device architecture. It identifies the P4-programmable blocks; for example, how many parsers, deparsers, match-action pipelines, and their relationship. It is used to accommodate differences; for instance, between a NIC and a data center switch. The P4 language is agnostic of the architecture; the hardware vendor defines the architecture.

- **Extern:** Objects and functions provided by the architecture. P4 programs can invoke services implemented by extern objects and functions. The extern construct describes the interfaces that an object exposes to the data plane. Examples of externs are CRC functions, random selector for ECMP, timestamp, and timers.

The hardware vendor provides the P4 compiler that produces configuration binaries for the P4 hardware. The binaries allocate and partition the resources of the P4 devices. These resources can be manipulated at runtime by the P4Runtime API. This API allows, for example, to add and remove table entries, read counters, program meters, inject and receive control packets, and so on.

### 11.3 Getting to Know the Portable Switch Architecture

Several P4 architectures have been developed and put in the public domain. The P4 Language consortium developed the Portable Switch Architecture (PSA) [[6](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch11.xhtml#ch11ref6)], a vendor-independent design that defines standard capabilities of network switches that process and forward packets across multiple interfaces. It establishes a library of types; externs for constructs such as counters, meters, and registers; and a set of “packet paths” that enable a P4 programmer to write P4 programs for network switches.

The PSA is composed of six programmable P4 blocks and two fixed-function blocks, as shown in [Figure 11-3](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch11.xhtml#ch11fig3).

![The portable switch architecture is shown.](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9780136624226/files/graphics/11fig03.jpg)

**FIGURE 11-3** The PSA

In PSA, the input packets pass through the following components: parser to Ingress, ingress to deparser, deparser to packet buffer and replication, packet buffer and replication to parser, parser to egress, egress to deparser, and deparser to buffer queuing engine.

From left to right, the first three blocks are the “ingress pipeline,” followed by a packet buffer and replication fixed-function box, followed by the egress pipeline, followed by the buffer-queueing engine fixed-function box.

The ingress and egress pipeline parse and validate the packet, pass it to a match action pipeline, and then pass it to the deparser.

After the ingress pipeline, the packet may optionally be replicated (for example, for multicast) and stored in the packet buffer.

After the egress pipeline, the packet is queued to leave the pipeline.

This architecture comes with APIs, templates, headers, metadata, and guidelines designed to maximize P4 code portability.

### 11.4 Looking at a P4 Example

The best way to learn P4 is to use the GitHub P4 Tutorial repository [[7](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch11.xhtml#ch11ref7)]. There you will find a set of exercises to help you get started with P4 programming, an emulation environment based on VirtualBox, and Vagrant where you will be able to run your code.

This section contains a brief description of the “Basic Forwarding” exercise, which uses a simple P4 architecture, known as the V1 model architecture, shown in [Figure 11-4](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch11.xhtml#ch11fig4).

![The V1 model architecture is shown. It is composed of the following components: parser, checksum verification or ingress match-action, traffic manager, checksum update or egress match-action, and a deParser.](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9780136624226/files/graphics/11fig04.jpg)

**FIGURE 11-4** The V1 Model Architecture

[Listing 11-1](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch11.xhtml#list11-1) spans a few pages and contains the necessary forwarding code of a switch based on the V1 model architecture. It starts by defining two headers: the Ethernet header and the IPv4 header. Then, following the V1 model architecture from left to right, it defines the parser that extracts the Ethernet `(ethernet_t)` and IPv4 `(ipv4_t)` headers.

**LISTING 11-1** P4 Example

[Click here to view code image](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch11_images.xhtml#list11_1)

```
/* -*- P4_16 -*- */
#include <core.p4>
#include <v1model.p4>

const bit<16> TYPE_IPV4 = 0x800;
/****************** HEADERS *************************/
typedef bit<9>  egressSpec_t;
typedef bit<48> macAddr_t;
typedef  bit<32> ip4Addr_t;

header ethernet_t {
    macAddr_t dstAddr;
    macAddr_t srcAddr;
    bit<16>
    etherType;
}

header ipv4_t {
    bit<4>    version;
    bit<4>    ihl;
    bit<8>    diffserv;
    bit<16>   totalLen;
    bit<16>   identification;
    bit<3>    flags;
    bit<13>   fragOffset;
    bit<8>    ttl;
    bit<8>    protocol;
    bit<16>   hdrChecksum;
    ip4Addr_t srcAddr;
    ip4Addr_t dstAddr;
}

struct metadata {
    /* empty */
}

struct headers {
    ethernet_t  ethernet;
    ipv4_t      ipv4;
}

/****************** PARSER *************************/

parser MyParser(packet_in packet,
                out headers hdr,
                inout metadata meta,
                inout standard_metadata_t standard_metadata) {

    state start {
        transition parse_ethernet;
    }

    state parse_ethernet {
        packet.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType)
            { TYPE_IPV4: parse_ipv4;
            default: accept;
        }
    }

    state parse_ipv4 {
        packet.extract(hdr.ipv4);
        transition accept;
    }

}

/******** CHECKSUM VERIFICATION *********/

control MyVerifyChecksum(inout headers hdr, inout metadata meta) {
    apply { }
}

/*********** INGRESS PROCESSING **************/
control MyIngress(inout headers hdr,
                  inout metadata meta,
                  inout standard_metadata_t standard_metadata) {
    action drop() {
        mark_to_drop(standard_metadata);
    }

    action ipv4_forward(macAddr_t dstAddr, egressSpec_t port) {
        standard_metadata.egress_spec = port;
        hdr.ethernet.srcAddr = hdr.ethernet.dstAddr;
        hdr.ethernet.dstAddr = dstAddr;
        hdr.ipv4.ttl = hdr.ipv4.ttl - 1;
    }

    table ipv4_lpm {
    key = {
        hdr.ipv4.dstAddr: lpm;
    }
    actions = {
        ipv4_forward;
        drop;
        NoAction;
    }
        size = 1024;
        default_action = drop();
    }

    apply {
        if (hdr.ipv4.isValid()) {
            ipv4_lpm.apply();
        }
    }
}

/*********** EGRESS PROCESSING **************/

control MyEgress(inout headers hdr,
                 inout metadata meta,
                 inout standard_metadata_t standard_metadata) {
    apply { }
}

/********* CHECKSUM COMPUTATION **********/

control MyComputeChecksum(inout headers hdr, inout metadata meta) {
    apply {
    update_checksum(
        hdr.ipv4.isValid(),
          { hdr.ipv4.version,
          hdr.ipv4.ihl,
            hdr.ipv4.diffserv,
            hdr.ipv4.totalLen,
            hdr.ipv4.identification,
              hdr.ipv4.flags,
              hdr.ipv4.fragOffset,
              hdr.ipv4.ttl,
              hdr.ipv4.protocol,
              hdr.ipv4.srcAddr,
              hdr.ipv4.dstAddr },
            hdr.ipv4.hdrChecksum,
            HashAlgorithm.csum16);
    }
}

/****************** DEPARSER **********************/

control MyDeparser(packet_out packet, in headers hdr) {
    apply {
        packet.emit(hdr.ethernet);
        packet.emit(hdr.ipv4);
    }
}

/****************** SWITCH *************************/

V1Switch(
MyParser(),
MyVerifyChecksum(),
MyIngress(),
MyEgress(),
MyComputeChecksum(),
MyDeparser()
) main;
```

The next block is the checksum verifier followed by the ingress processing. This example does not specify a traffic manager. The following two blocks are egress processing and checksum computation. Finally, the deparser terminates the processing.

The definition of the V1 architecture is in the `v1model.p4` [[8](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch11.xhtml#ch11ref8)] included at the beginning of the example. The V1 architecture contains a construct package `V1Switch<H, M>` that lists the blocks of the V1 architecture. The `V1Switch()` at the end of the listing binds the P4 statements to the six blocks defined in the architecture.

From this example, it is evident that each P4 program must follow precisely the architecture for which it is written and that the compiler translates each section of the P4 program in code and configuration for the corresponding block on the architecture.

### 11.5 Implementing the P4Runtime API

The P4Runtime API [[9](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch11.xhtml#ch11ref9)] is “a control plane specification for controlling the data plane elements of a device defined or described by a P4 program.” It is designed to be implemented in conjunction with the P4 16 language.

The significant P4Runtime features are:

- Runtime control of P4 objects (tables and value sets).

- Runtime control of PSA externs; for example, counters, meters, and action profiles.

- Runtime control of architecture-specific (non-PSA) externs, through an extension mechanism.

- I/O of control packets from the control plane.

The syntax follows the Protobuff format [[10](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch11.xhtml#ch11ref10)]. The client and the server communicate using gRPC [[11](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch11.xhtml#ch11ref11)], which is a perfect match for Protobuff (see [section 3.4.2](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch03.xhtml#ch03lev2sec4_2)).

[Figure 11-5](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch11.xhtml#ch11fig5) shows a complex solution in which three different servers manage the P4 pipeline: two remote and one embedded. For the target P4 pipeline, there is no difference between a P4Runtime client embedded or remote.

![A figure demonstrates about P4Runtime.](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9780136624226/files/graphics/11fig05.jpg)

**FIGURE 11-5** P4Runtime

A P4 target network device is shown. It consists of a P4 pipeline and a P4 embedded controller (gRPC client). The P4 pipeline consists of gRPC server, instrumentation, and platform drivers. Two P4 remote controllers (gRPC clients) are also shown. The three controllers and the P4 pipeline are interconnected (representing P4Runtime). The entities from the remote controllers and the entities and configuration from the embedded controller are stacked in the P4 pipeline.

Both communications happen on gRPC and therefore on a TCP socket. Thus, there is no assumption that the control plane is collocated or separated from the data plane.

### 11.6 Understanding the P4 INT

In P4 INT [[12](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch11.xhtml#ch11ref12)], a P4 device is instructed to add metadata information to each packet that it processes; for example, timestamp, device ID, and queue ID. The metadata is carried in the P4 INT header. This header can be hop-by-hop or end-to-end. P4 INT does not specify where to put the INT header in the packet.

The information inside the INT header helps answer questions such as:

- Which path did my packet take?

- How long was it queued on each device?

- Which other flows shared the queue with my packet?

There is no doubt that P4 INT allows an excellent understanding of packet propagation without requiring precise clock synchronization among network devices. The downside is the additional header that, depending on the placement on the packet, needs to be understood by different entities in the network and can potentially break implementations that are not P4 INT aware.

### 11.7 Extending P4

Although P4 is a good start, it could take advantage of some extensions to be better suited for implementing a DSN.

#### 11.7.1 Portable NIC Architecture

Portable NIC Architecture (PNA) is the equivalent of a PSA for a NIC architecture. The P4 Architecture Working Group has discussed it, but at the time of writing there is not yet a final proposal.

To be able to model a NIC, one significant addition is a DMA engine capable of moving data to and from the host memory through the PCIe bus. The DMA engine should have the flexibility to assemble packets from data in memory through scatter and gather lists. A doorbell mechanism to interface the driver on the host should also exist.

A DMA engine is also crucial if a NIC needs to support RDMA and storage.

The availability of a PNA is essential to support a DSN implementation as a NIC.

#### 11.7.2 Language Composability

*Language composability* is probably an overused term. In general, it refers to a design principle in which components can be easily selected and assembled in various combinations without any modifications to implement a specific set of features.

In this sense, P4 is not a composable language. It is similar to Verilog, strictly related to the hardware architecture; merging two P4 functions is a manual process that may involve a lot of rewriting.

Some preliminary attempts exist in this direction. For example, Mario Baldi’s work at Cisco Systems [[13](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch11.xhtml#ch11ref13)] is a specific case of composability, as it allows a programmer to add features to an existing P4-coded data plane without having to have access to the existing source code, but the new feature must be written to fit the existing program.

In the most general case, composing functions that are written independently of each other would be desirable. A programmer should be able to add or remove features without having to rewrite the existing P4 code.

The P4 Language Design Working Group has discussed this issue in the past, but no solution has been adopted.

#### 11.7.3 Better Programming and Development Tools

To make P4 successful, a large number of programmers need to have the means to design, write, compile, debug and profile P4 programs.

The P4 community provides an “alpha-quality reference compiler” that supports four standard backends. Each hardware vendor is in charge of adding its backend for its architecture. Unfortunately, we have already seen that the hardware architecture shapes how the P4 programs are written and limit their portability. If we want to address the aspect of “language composability,” the backend needs to become much more sophisticated and be able to merge multiple programs and reallocate functions and resources in the pipeline.

These requirements seem to point in the direction of a P4 linker/loader that will also allow some programs not to be divulged in source form to protect intellectual property.

After a P4 program is compiled, understanding its behavior on real hardware may be tricky; for this reason, debugging and profiling tools are mandatory.

### 11.8 Summary

In this chapter, we reviewed the P4 architecture that brings runtime data plane programmability to ASIC. P4 is a domain-specific architecture targeted at network devices.

At the time of writing (2019), commercial P4 products are starting to be available; some of them are based on the Barefoot Networks Tofino switch [[14](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch11.xhtml#ch11ref14)] recently acquired by Intel [[15](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch11.xhtml#ch11ref15)].

The P4 language is a valuable way to specify the functionality of the data plane with a program for a manufacturer of network equipment or a large corporation, like a cloud provider. We have also discussed the fact that P4 is not a composable language, and unless this barrier is removed, it may be difficult for a small company or an individual programmer to add or remove features to a P4 network device.

### 11.9 Bibliography

**[[1](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch11.xhtml#rch11ref1)]** P. Bosshart, G. Gibb, H.-S. Kim, G. Varghese, N. McKeown, M. Izzard, F. Mujica, and M. Horowitz, “Forwarding metamorphosis: Fast programmable match-action processing in hardware for SDN,” in ACM SIGCOMM, 2013.

**[[2](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch11.xhtml#rch11ref2)]** Pat Bosshart, Dan Daly, Glen Gibb, Martin Izzard, Nick McKeown, Jennifer Rexford, Cole Schlesinger, Dan Talayco, Amin Vahdat, George Varghese, and David Walker. 2014. P4: programming protocol-independent packet processors. SIGCOMM Comput. Commun. Rev. 44, 3 (July 2014), 87–95.

**[[3](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch11.xhtml#rch11ref3)]** P4 Language Consortium, [https://p4.org](https://p4.org/)

**[[4](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch11.xhtml#rch11ref4)]** The Open Networking Foundation (ONF), “P4,” [https://www.opennetworking.org/p4](https://www.opennetworking.org/p4)

**[[5](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch11.xhtml#rch11ref5)]** P4 16 Language Specification version 1.1.0, The P4 Language Consortium, 2018-11-30, [https://p4.org/p4-spec/docs/P4-16-v1.1.0-spec.pdf](https://p4.org/p4-spec/docs/P4-16-v1.1.0-spec.pdf)

**[[6](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch11.xhtml#rch11ref6)]** P4 16 Portable Switch Architecture (PSA) Version 1.1, The P4.org Architecture Working Group, November 22, 2018, [https://p4.org/p4-spec/docs/PSA-v1.1.0.pdf](https://p4.org/p4-spec/docs/PSA-v1.1.0.pdf)

**[[7](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch11.xhtml#rch11ref7)]** P4 Tutorial, [https://github.com/p4lang/tutorials](https://github.com/p4lang/tutorials)

**[[8](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch11.xhtml#rch11ref8)]** Barefoot Networks, Inc., “P4 v1.0 switch model,” [https://github.com/p4lang/p4c/blob/master/p4include/v1model.p4](https://github.com/p4lang/p4c/blob/master/p4include/v1model.p4)

**[[9](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch11.xhtml#rch11ref9)]** P4Runtime Specification, version 1.0.0, The P4.org API Working Group, 2019-01-29, [https://s3-us-west-2.amazonaws.com/p4runtime/docs/v1.0.0/P4Runtime-Spec.pdf](https://s3-us-west-2.amazonaws.com/p4runtime/docs/v1.0.0/P4Runtime-Spec.pdf)

**[[10](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch11.xhtml#rch11ref10)]** Protocol Buffers, [https://developers.google.com/protocol-buffers](https://developers.google.com/protocol-buffers)

**[[11](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch11.xhtml#rch11ref11)]** gRPC, [https://grpc.io](https://grpc.io/)

**[[12](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch11.xhtml#rch11ref12)]** Inband Network Telemetry (INT) Dataplane Specification, working draft, The P4.org Application Working Group, 2018-08-17, [https://github.com/p4lang/p4-applications/blob/master/docs/INT.pdf](https://github.com/p4lang/p4-applications/blob/master/docs/INT.pdf)

**[[13](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch11.xhtml#rch11ref13)]** Mario Baldi, “Demo at the P4 workshop 2019,” May 2019, Stanford University.

**[[14](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch11.xhtml#rch11ref14)]** Barefoot Networks, “Tofino: World’s fastest P4-programmable Ethernet switch ASICs,” [https://barefootnetworks.com/products/brief-tofino](https://barefootnetworks.com/products/brief-tofino)

**[[15](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch11.xhtml#rch11ref15)]** [https://newsroom.intel.com/editorials/intel-acquire-barefoot-networks](https://newsroom.intel.com/editorials/intel-acquire-barefoot-networks)

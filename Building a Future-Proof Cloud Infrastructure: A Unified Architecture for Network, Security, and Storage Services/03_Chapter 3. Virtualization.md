## Chapter 3. Virtualization

The previous chapter discussed how network design has an impact on a distributed network service architecture, but it is nothing compared to the effect of virtualization techniques like virtual machines (VMs) and containers, which are crucial components of cloud infrastructures and modern data centers. VMs and containers are not synonymous, and they don’t have the same scope:

- VMs provide machine virtualization and packaging that helps instantiate a machine on demand, with specified CPU, memory, disk, and network.

- Containers provide application packaging and application runtime within a server.

In general, virtualization techniques allow for higher workload density, and when using microservices, to partition monolith functions into smaller units, to replicate them effectively, and to move them around as needed. These workloads are also dynamic; that is, they are created and terminated often, and this creates a need for automating the network services. This causes an explosion in the number of IP addressable entities and the need to offer granular network services to these entities; for example, firewalling and load balancing. At this point, the reader may deduce that a solution that addresses virtualized loads solves all problems. Unfortunately, this is far from the truth. In enterprise data centers, a large number of the servers are “bare metal”; that is, without any virtualization software. Even public clouds, where initially the load was 100 percent virtualized, are now moving to offer bare-metal servers that remain important for specific applications, like databases, or allow bring-your-own-hypervisor; for example, VMware. Almost all cloud providers offer bare-metal servers in addition to VMs. Therefore, any distributed network service architecture must support equally well all bare-metal server, virtual machine, and container environments.

The remainder of this chapter describes these environments. The discussion is organized into sections on virtualization and clouds, virtual machines and hypervisors, containers, and the microservice architecture.

At the end of this chapter, it should be apparent that most networks use a combination of techniques with some applications running on bare metal and others on virtual machines, and some rewritten following the microservice architecture and thus are suitable for containers. This chapter also outlines an example of a management and provisioning system (OpenStack) and an instance on a virtualized application in the Telco space (NFV).

### 3.1 Virtualization and Clouds

In the old days, some computers were running multiple concurrent applications to increase computer utilization. Unfortunately, this proved impractical because different applications require different libraries, OSes, kernels, and so on and running various applications on the same computer provided almost no separation from a security, management, and performance perspective. Many computers became dedicated to a single application, which resulted in very low CPU and memory utilization. Server virtualization was invented to solve these and other issues.

Server virtualization addresses several needs:

- Multiple OS environments can exist simultaneously on the same machine, isolated from each other.

- A physical server can run various logical servers (usually called virtual machines or VMs). Running a VM per CPU core is a standard practice.

- It reduces the number of physical servers by increasing server utilization, thus reducing the cost associated both to server CAPEX and OPEX; for example, space and electrical power.

- Applications can take advantage of multiple cores without the need to rewrite them in a multithreaded and parallel way. Server virtualization allows users to run multiple copies of the same application on different VMs.

- Virtualization enables testing and staging environments to be run in parallel with production, and this is a considerable simplification.

- Machine provisioning, snapshots, backup, restore, and mobility become much more straightforward.

- Virtualization software offers centralized management and provisioning.

- Because each virtual machine is a complete server, including the OS and the kernel, there is better application isolation and security than in shared environments.

- Hardware independence is obtained by presenting a “standardized hardware” to all the virtual machines.

Of course, there are also drawbacks, mainly in the area of high RAM usage and application performance predictability, but these must be minor because server virtualization has become a de facto reality on which many corporations rely for their day-to-day operations.

Virtualization allows for greater sharing of resources; for example, all the VMs may share a single 100G NIC. However, whenever there is sharing, there is the potential for abuse. In a multitenant cloud, a so-called “noisy neighbor” may consume most of the available resources (PCI bandwidth, for example) and impact other tenants on the server. This is a problem even if the “noise” is transient.

VMware was the first commercially successful company to virtualize the x86 architecture [[1](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch03.xhtml#ch03ref1)], and nowadays its presence in the data center is relevant. KVM (Kernel-based Virtual Machine) is one of the few public domain hypervisors, and it is used as a starting point for many offerings in the cloud space.

Public clouds are now a very mature offering, with players such as Amazon Web Services (AWS)—a subsidiary of [Amazon.com](http://amazon.com/), Azure—a cloud computing service created by Microsoft, Oracle Cloud Infrastructure, IBM Cloud, Google Cloud Platform, Alibaba Cloud, OVH, and others.

Private clouds are the new way of organizing an enterprise data center so that virtual servers, in the form of virtual machines, can be easily and quickly provisioned. Clouds provide more agility and cost savings. The sentence “cloud-native data center infrastructure” is used to describe these realities.

Hybrid clouds, shown in [Figure 3-1](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch03.xhtml#ch03fig1), are the current frontier.

![The functioning of the hybrid cloud is illustrated.](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9780136624226/files/graphics/03fig01.jpg)

**FIGURE 3-1** A Hybrid Cloud

A public cloud and a private cloud are present in the hybrid cloud. Both clouds have virtual machines. The virtual machines in the public cloud are VM number 1, number 2, and number 7. The virtual machines here are not properly connected but have a randomly established connection. The virtual machines in the private cloud are VM number 3, number 4, and number 11. Here the virtual machine number 11 is connected to the virtual machine number 3 and 4.

Hybrid clouds are a combination of private and public clouds to achieve load balancing, fault tolerance, computing peak absorption, data partitioning, and so on. In a perfect hybrid cloud architecture, a virtual machine can be located in the private part or the public part and can be moved from one place to another without having to rewrite code, change addresses or policies, or being concerned about security issues. In advanced cases, this move can happen while the virtual machine is running.

Hybrid clouds pose incredible challenges that are only partially addressed by current solutions.

Clouds have also made multitenancy a de facto reality. Cloud providers must protect users from each other because applications of different users can run on the same physical server and use shared storage resources and shared network services. Different users may use the same private IP addresses that, if not appropriately dealt with, may create conflicts on the network. Finally, in a cloud environment, the provider must take care of securing access to the user applications, both in terms of firewalling and encryption and to offer other value-added services such as load balancing.

Multi-tenancy is a reality not only in the public cloud but also inside large enterprises to separate and protect different activities from each other; for example, for legal compliance.

Multi-tenancy requires an on-demand virtual infrastructure instantiation per tenant, including network, storage, compute, security, and other services.

These new requirements have created a need to layer this new virtual infrastructure as closely as possible to the workload. A distributed services platform is the best solution for these needs.

### 3.2 Virtual Machines and Hypervisors

Today two major virtualization solutions are available:

- Virtual machines and hypervisors (described in this section)

- Containers (described in [section 3.3](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch03.xhtml#ch03lev1sec3))

At first glance, these may look like two simple variations of the same solution, but when you dig deeper, they are substantially different.

The idea behind virtual machines is to take a physical server, including OS, kernel, userspace, libraries, and applications and transform it into a virtual server that runs inside a virtual machine. No assumption is made on what the physical server does or on how the application or applications are structured inside the server. With the advent of packaging, portability, and tooling around it, virtualizing applications has become easier. Multiple tools are available to migrate a physical server into a virtual machine without changing anything.

The idea behind containers is different. Containers can be used to repackage an application or to convert it into a microservice architecture. When it is being repackaged, the application and its runtime environment are encapsulated in a container without requiring any rewriting; for example, a Python application that requires Python 2.6 can be packaged in a container, run alongside another application requiring Python 4.5 wrapped in a different container. Containers also offer the possibility to convert an application to microservices, but this means reorganizing the application often with substantial rewriting, to follow the new microservice architecture described in [section 3.4](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch03.xhtml#ch03lev1sec4). In a nutshell, the application is divided into multiple independent modules that communicate with each other using standardized APIs. A container instantiates each module.

If an application is built as a microservice, it can be horizontally scaled out by instantiating multiple copies, each being a stateless service.

If a module is a performance bottleneck, the same module may be instantiated in multiple containers.

Although it is partially possible to use virtual machines as containers and vice versa, the full potential of the solution is achieved when each technique is used for its proper purpose.

In the remainder of this section, we drill down on these two concepts:

- The hypervisor, which creates an environment where the virtual machine runs

- The virtual machine, which encapsulates a physical server including the operating system (kernel and userspace), the libraries, and the applications

[Figure 3-2](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch03.xhtml#ch03fig2) shows two types of hypervisors: bare metal and hosted.

![Two types of Hypervisors, bare metal (type 1) and the hosted (type 2) are shown.](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9780136624226/files/graphics/03fig02.jpg)

**FIGURE 3-2** Different Types of Hypervisors

The bare-metal hypervisor (type 1) has hardware at the base, hypervisor above it and two guest operating systems at the top. The hosted hypervisor (type 2) has the hardware at the bottom and a host operating system above it, followed by a hypervisor. The four guest operating systems are at the top.

A bare-metal hypervisor [[2](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch03.xhtml#ch03ref2)] is a native operating system that runs directly on the hardware, with direct access to the hardware resources, thus providing scalability, robustness, and performance. The disadvantage of this approach is that the hypervisor must have all the drivers required to support the hardware over which it is running.

In contrast, a hosted hypervisor is an extension to an existing operating system, with the advantage of supporting the broadest range of hardware configurations.

Another way to classify hypervisors is by looking at the kind of virtualization they offer: full virtualization or paravirtualization.

Full virtualization provides a total abstraction of the underlying physical server and requires no modification in the guest OS or application; that is, in the virtual machine. Full virtualization is advantageous when migrating a physical server to a virtual machine because it provides complete decoupling of the software from the hardware but, in some cases, it can incur a performance penalty.

Paravirtualization requires modifications to the guest operating systems that are running in the virtual machines, making them “aware” that they are running on virtualized hardware. Performance may improve, but it is not as generic as full virtualization.

Hypervisors contain one or more virtual switches, also known as vSwitches, that are software entities in charge of switching packets among virtual machines and through the network interface cards (NICs) to the outside world (see [Figure 3-3](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch03.xhtml#ch03fig3)).

![An illustration of the virtual switch is shown. The server has two layers. The top layer has three virtual machines numbered 1, 2, and 3. Each of the virtual machines is interconnected with the hypervisor switch or bridge in the next layer. The connection further extends outside the server from this switch.](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9780136624226/files/graphics/03fig03.jpg)

**FIGURE 3-3** A Virtual Switch

A vSwitch usually acts as a layer 2 bridge, offers virtual Ethernet interfaces to the VMs, and connects to one or more NIC. The external connectivity, in the presence of multiple NICs, can be configured in two primary modes of NIC teaming: active-standby and active-active. Active-standby is self- explanatory. Active-active on hypervisors has the following flavors:

- **vEth-based forwarding:** Traffic arriving on a virtual Ethernet (vEth) port is always sent to a given uplink unless a failure is observed.

- **Hash-based forwarding:** This can be MAC address, IP address, or flow based.

The active-active mode can implement static bonding or dynamic (LACP)-based bonding.

vSwitches are essential in the context of a distributed services platform because they represent a place where it is possible to implement a distributed network service architecture. Their functionality can also be moved into hardware to increase performance. We describe various virtual switch approaches and standards in [section 4.3](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch04.xhtml#ch04lev1sec3) in [Chapter 4](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch04.xhtml#ch04), “[Network Virtualization Services](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch04.xhtml#ch04).”

Although the hypervisor is the real enabler of VMs, commercial companies monetize their investments on the management and service offerings. Often services are offered as virtual appliances; that is, as VMs that implement a particular function, such as firewall, VPN termination, and load balancer. These virtual appliances are very flexible, but they often lack the deterministic performance and latency of physical appliances that use dedicated hardware.

In the next sections, we consider two commercial and two open source virtualization systems.

#### 3.2.1 VMware ESXi

Founded in 1998, VMware was one of the first commercially successful companies to virtualize the x86 architecture [[3](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch03.xhtml#ch03ref3)]. VMware ESXi is the hypervisor of VMware. It is a bare-metal hypervisor that supports full virtualization. [Figure 3-4](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch03.xhtml#ch03fig4) shows an ESXi server with two VMs. The ESXi presents a hardware abstraction to each VM.

![An illustration of the Vmware ESXi architecture.](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9780136624226/files/graphics/03fig04.jpg)

**FIGURE 3-4** VMware ESXi

The VMware ESXi server has three layers, the hardware, ESXi hypervisor, and two virtual machines. The bottom layer is the hardware that includes CPU, memory, NIC, and disk. This is followed by an ESXi hypervisor. Above the hypervisor, two virtual machines are shown. Each virtual machine consists of an operating system with applications.

Each VM has its OS, including the kernel, and it has the perception of running on the real hardware.

Not having a host OS, ESXi needs drivers for all the server hardware components, and this may limit its deployability in the presence of uncommon HW. VMware offers certified compatibility guides that list system, I/O, storage/SAN, and backup compatibility.

The basic version of ESXi has a free license, and VMware offers many additional features under a paid license. These include

- **VMware vCenter:** A centralized management application to manage virtual machines and ESXi hosts centrally as well as features typically needed to enable business continuity, such as vMotion; that is, the capability to do live migration of VM from one ESXi host to another.

- **VMware vSAN:** A storage aggregation layer to create a single storage pool shared across all hosts in the vSAN cluster.

- **VMware NSX:** A distributed network virtualization that includes switching, routing, firewalling, and other network and security services.

VMware is a software company. At the time of writing it implements all its solutions in software, and this has worked well so far because the speed of the Intel processors has continually increased. Unfortunately, this trend is slowing down, as shown in [Chapter 7](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch07.xhtml#ch07), “[CPUs and Domain-Specific Hardware](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch07.xhtml#ch07),” and time will tell whether VMware will have to move some of its functionality to domain-specific hardware.

Finally, a significant evolution is the native support of VMware in the cloud. For example, VMware Cloud on AWS is an integrated cloud offering, jointly developed by AWS and VMware, in which the customer can provision, on the AWS cloud, servers that run the VMware software. This offering has the capability of supporting a hybrid cloud and moving VMs from the private part to the public portion and vice versa. Tools also exist to migrate applications to and from the cloud. Similar announcements are expected with other cloud providers.

#### 3.2.2 Hyper-V

Microsoft Hyper-V [[4](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch03.xhtml#ch03ref4)] is a bare-metal hypervisor that can create virtual machines on x86 64-bit systems. It was first released alongside Windows Server 2008 and has been available without additional charge since Windows Server 2012 and Windows 8. Microsoft also released a standalone version, called Hyper-V Server 2008, that is available as a free download, but with the command line interface only. [Figure 3-5](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch03.xhtml#ch03fig5) shows the Hyper-V architecture.

![The Hyper-V architecture is shown in the figure.](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9780136624226/files/graphics/03fig05.jpg)

**FIGURE 3-5** The Hyper-V Architecture

The Hyper-V architecture consists of the hardware followed by the hypervisor (hypervisor is in "Ring 1"). Above this layer, there are two partitions: parent partition and the child partition. The parent partition has the following two layers: The first layer consists of VM bus, windows kernel and the virtualization service provider (VSP) connected by the device drivers. The next layer is the VM worker processes that include the virtual machine management service and a VMI provider. The child partition has two layers the kernel-mode "Ring 0" and the user-mode "Ring 3." The kernel-mode has a VMBus, virtualization service consumer (VSC), and the Windows kernel. The user mode has the applications.

Hyper-V implements isolation of virtual machines in terms of a partition. Each VM runs in a separate child partition. A root or parent partition contains the Windows OS, which is responsible for the management of the server, including the creation of the child partitions; that is, of the VMs.

The virtualization software runs in the parent partition and has direct access to the hardware devices. The parent partition has several roles:

- Controls the physical processors, including memory management and interrupts

- Manages the memory for the child partitions

- Handles the devices connected to the hypervisor such as the keyboard, mouse, and printers

- Presents the device to the child partitions as virtual devices

When a child partition accesses a virtual device, the virtual device forwards the request via the VMBus to the devices in the parent partition, which will manage it. The VMBus is a logical channel that enables interpartition communication. The response also travels back via the VMBus. Hyper-V also offers “Enlightened I/O,” a mechanism that allows the VMBus to interact with the hardware directly for high speed I/O operations.

Even though not shown in the picture, Hyper-V has the capability of creating virtual switches that provide virtual network adapters to its virtual machines and teamed physical network adapters to serve as uplinks toward the network switches.

By default, Hyper-V also provides virtualization support for Linux guests and Microsoft has submitted Hyper-V drivers to the Linux kernel. Hyper-V Linux support can be extended by installing the Linux Integration Components.

Hyper-V is also the hypervisor at the base of Microsoft’s Azure offering. In [section 2.9](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch02.xhtml#ch02lev1sec9) we discussed the relationship between the Hyper-V virtual switch and the Azure SmartNIC.

#### 3.2.3 QEMU

QEMU (Quick EMUlator) [[5](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch03.xhtml#ch03ref5)] [[6](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch03.xhtml#ch03ref6)] is a complete, standalone open-source software capable of operating as a machine emulator, or virtualizer.

When operating as a machine emulator, QEMU transforms binary code written for a given processor into another one (for example, it can run x86 code on an ARM processor). QEMU emulates a processor through dynamic binary translation and provides a set of different hardware and device models to run a variety of guest operating systems. QEMU includes a long list of peripheral emulators: network, display adapters, disks, USB/serial/parallel ports, and so on.

When used as a virtualizer, QEMU runs code on the native architecture; for example, x86 code over an x86 platform. In this configuration, it is typically paired with KVM (see the next section) to implement a hypervisor.

QEMU used as an emulator is slower than QEMU used as a virtualizer because it involves translating binary code. QEMU virtualizer runs virtual machines at near-native speed by taking advantage of CPU virtualization features such as Intel VT or AMD-V.

#### 3.2.4 KVM

KVM (for Kernel-based Virtual Machine) [[7](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch03.xhtml#ch03ref7)], [[8](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch03.xhtml#ch03ref8)] is an open-source hosted hypervisor, full virtualization solution that can host multiple virtual machines running unmodified Linux or Windows images. [Figure 3-6](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch03.xhtml#ch03fig6) shows the KVM architecture.

![The kernel-based virtual machine architecture is illustrated.](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9780136624226/files/graphics/03fig06.jpg)

**FIGURE 3-6** The KVM Architecture

The KVM architecture has the following layers: the bottom layer has the server with virtualization support (Intel-VT/AMD-V) and the layer above is the Linux kernel that has a kernel-based virtual machine. The LINUX Kernel is connected to a virtual machine containing a QEMU in the base and the windows OS above. The LINUX Kernel is also connected to a virtual machine containing a QEMU in the base and the LINUX OS above. The ordinary Linux processes are also linked with the LINUX Kernel.

A Linux host OS is booted on the bare-metal hardware. The kernel component of KVM is included in mainline Linux as of 2.6.20. KVM uses either Intel VT or AMD-V virtualization extensions. KVM consists of a loadable kernel module, kvm.ko, that provides the core virtualization infrastructure and a processor-specific module, kvm-intel.ko or kvm-amd.ko. This code is responsible for converting the Linux kernel into a hypervisor. KVM also supports PPC, S/390, ARM, and MIPS processors.

In conventional Linux-style, KVM does one thing, and it does it right. It leaves process scheduling, memory management, and so on to the Linux kernel. Any improvements done by the Linux community to these features immediately benefit the hypervisor as well.

KVM does not provide virtualized hardware; it leverages QEMU. The userspace component of KVM is included in QEMU (see the previous section). Each virtual machine created on a host has its own QEMU instance. The guest runs as part of the QEMU process.

KVM exposes its API to userspace via ioctls, and QEMU is one of the users of this API.

QEMU is also integrated with Virtio, as shown in [Figure 3-7](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch03.xhtml#ch03fig7).

![An illustration of the virtio is shown. The virtio-blk, virtio-net, virtio-pcl, virtio-balloon, and virtio console are included in the virtio. Transportation occurs between the virtio and the virtio back-end drivers.](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9780136624226/files/graphics/03fig07.jpg)

**FIGURE 3-7** Virtio

Virtio [[9](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch03.xhtml#ch03ref9)], [[10](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch03.xhtml#ch03ref10)] is a set of paravirtualized drivers, where the guest’s device driver is aware that it is running in a virtual environment and cooperates with the hypervisor to obtain high-performance; for example, in network and disk operations. Virtio is tightly integrated with both QEMU and KVM, as shown in [Figure 3-8](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch03.xhtml#ch03fig8).

![A network setup with KVM, QEMU, and virtio is shown.](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9780136624226/files/graphics/03fig08.jpg)

**FIGURE 3-8** KVM, QEMU, Virtio

Network topology with a host and a guest is shown. The host has the following connections: the kernel space consists of a tap device, interconnected with vhost, that is then connected to KVM via the irqfd and ioeventfd. The guest has the QEMU, that in turn has the operating system and a virtio driver. The Virtio driver is interconnected with vhost (via RX and TX queue). The virtio driver is also interconnected with KVM.

In particular, the vhost driver in the Linux kernel implements a fast, kernel-based Virtio device emulation. Usually, the QEMU userspace process emulates I/O accesses from the guest. Vhost puts Virtio emulation code into the kernel, reducing the number of buffer-copy operations and thus improving performance. [Section 8.5](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch08.xhtml#ch08lev1sec5) further discusses Virtio-net because it has applicability also outside KVM/QEMU.

QEMU and KVM support both the classical virtual switch model and SR-IOV, a standard described in [section 8.4](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch08.xhtml#ch08lev1sec4), to move the virtual switch into the NIC for high networking performance. [Figure 3-9](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch03.xhtml#ch03fig9) shows the two cases. The TAP device shown in [Figures 3.8](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch03.xhtml#ch03fig8) and [3.9](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch03.xhtml#ch03fig9) is a virtual ethernet interface that works at layer 2 and is associated with a specific guest/VM.

![A vSwitch with SR-IOV is shown.](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9780136624226/files/graphics/03fig09.jpg)

**FIGURE 3-9** vSwitch with SR-IOV

The vswitch is on the left and the SR-IOV is on the right. The components in the vSwitch are as follows: virtual machine, QEMU, and kernel. The kernel has the bridge, TAP, and a vhost. The virtual machine and the vhost are connected by TX and RX. The bridge in the kernel is connected to the physical NIC. The SR-IOV has the following components: virtual machine, QEMU, kernel, virtual NIC, and a physical NIC. The virtual machine is connected to the virtual NIC by the TX and RX. The kernel has two virtual NICs that are connected to the physical NIC outside the kernel. The physical NIC is further connected to the virtual NIC.

Finally, from a management perspective, libvirt [[11](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch03.xhtml#ch03ref11)] provides a hypervisor-neutral API to manage virtual machines, including storage and network configurations.

Public cloud companies such as AWS and Google use KVM in production.

#### 3.2.5 XEN

XEN is a bare-metal hypervisor developed by the University of Cambridge Computer Laboratory [[12](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch03.xhtml#ch03ref12)], [[13](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch03.xhtml#ch03ref13)]. In the open-source community, the XEN Project develops and maintains Xen. Xen is currently available for Intel 32- and 64-bit and ARM processors. [Figure 3-10](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch03.xhtml#ch03fig10) shows its architecture.

![The XEN architecture is illustrated.](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9780136624226/files/graphics/03fig10.jpg)

**FIGURE 3-10** The XEN Architecture

XEN architecture has three layers. The base layer has the host, followed by the XEN layer then the virtual machines. The base layer is the host with the following components: input/ output, memory, and the central processing units. The Xen layer has the following components: scheduler, MMU, timers, and interrupts. The top layers are the virtual machines VM 0 (or Domain U 0), VM 1 (or domain U 1), VM 2 (or domain U 2), up to VM n or (domain U n). VM 0 consists of system services (TS, DE, and XS) and the domain 0 kernel with the native driver. The input/ output is connected to the native driver in VM 0. The other virtual machines consist of applications and guest OS.

The XEN hypervisor is responsible for memory management and CPU scheduling of virtual machines, also known as “domains” in XEN parlance. XEN reserves to itself domain 0 (“dom0”), the only virtual machine that has direct access to hardware. dom0 is used to manage the hypervisor and the other domains; that is, the other virtual machines. Usually, dom0 runs a version of Linux or BSD. For user domains, XEN supports both full virtualization and paravirtualization.

Around 2005, a few Cambridge alumni founded XenSource, Inc. to turn XEN into a competitive enterprise product. Citrix acquired XenSource in October 2007. In 2013 the Linux Foundation took charge of the Xen project and launched a new community website at xenproject.org. Current project members include AlibabaCloud, AMD, ARM, AWS, BitDefender, Citrix, Huawei, Intel, and Oracle.

Public cloud companies such as AWS and IBM Cloud have used XEN in production.

Citrix hypervisor [[14](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch03.xhtml#ch03ref14)], formerly known as XenServer, is a commercial product based on XEN.

### 3.3 Containers

Container-based virtualization, or *containers* for short [[15](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch03.xhtml#ch03ref15)], is a virtualization technique that matches well the microservice architecture described in the next section. It is a virtualization method that avoids launching an entire VM just to run an application.

In traditional virtualization, a VM not only contains the application, but it also includes the OS and the kernel. In container virtualization, all the applications running on the same host share the same kernel, but they may have a customized view of the OS and its distribution packaging; for example, libraries, files, and environment variables. Linux OS offers LXC (LinuX Containers), a set of capabilities of the Linux kernel that allow sandboxing processes from one another by using resource isolation, kernel namespaces, and kernel groups.

The most relevant kernel techniques used by containers are:

- **Namespaces:** pid namespace, network namespace, mount, ipc, user, and so on

- **Chroot:** Allows for a different root file system for an application instead of that of the base OS

- **Control groups:** Allows isolation of resources among various processes; for example, CPU, memory, disk, and network I/O

Containers also rely on a union-capable file system such as OverlayFS. Containers expand or replace LXC to achieve additional advantages.

[Figure 3-11](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch03.xhtml#ch03fig11) shows the difference between a hosted hypervisor and container virtualization.

![The difference between classical virtualization and container virtualization is shown.](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9780136624226/files/graphics/03fig11.jpg)

**FIGURE 3-11** Classical Virtualization versus Container Virtualization

The virtual machines have the following hierarchy from the base: host hardware, host operating systems, hypervisor, and virtual machines numbered 1, 2, and 3. Each virtual machine has a guest operating system and application. The containers have the following hierarchy from the base: host hardware, host operating systems, and applications 1 to n followed by a container engine.

Container efforts can be classified as runtime mechanisms to execute multiple containers on the same physical server and as management and provisioning efforts to simplify the deployment and monitoring of a large number of containers, also known as *orchestration*. Docker is a well-known solution for the first aspect, whereas Kubernetes addresses the second aspect.

#### 3.3.1 Docker and Friends

This section describes container runtimes; that is, software systems that allow multiple containers to run on the same server. Among them, Docker is probably the most well-known.

Docker [[16](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch03.xhtml#ch03ref16)] started in France as an internal project within dotCloud, a platform-as-a-service company. The software debuted to the public in 2013 and, at that time, it was released as open source.

Docker replaces LXC with runC (formerly known as libcontainer), uses a layered filesystem (AuFS), and manages networking. Compared to hypervisor virtualization, it offers less isolation, but it is much lighter to run, requiring fewer resources. The conventional wisdom is that you can run on a physical server up to ten times more containers compared to virtual machines. The comparison is partly unfair because a container typically runs just a microservice, not the entire application. Docker is not the only container runtime solution available. Other similar solutions are containerd (now part of the Cloud Native Computing Foundation) [[17](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch03.xhtml#ch03ref17)]; OCI (Open Container Initiative) [[18](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch03.xhtml#ch03ref18)]; Rocket, part of CoreOS [[19](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch03.xhtml#ch03ref19)] (a lightweight OS that can run containers efficiently, recently acquired by Red Hat); and Mesos [[20](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch03.xhtml#ch03ref20)] a container scheduler similar to Kubernetes.

#### 3.3.2 Kata Containers

In the previous sections, we have discussed how containers share the OS kernel and achieve isolation through kernel namespaces and groups. In some applications, having a common kernel shared by two or more containers is considered a security risk—a classic example being a financial application. The Kata Container project [[21](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch03.xhtml#ch03ref21)] tries to solve this issue and promises “*... the speed of containers, and the security of VMs ...*”

[Figure 3-12](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch03.xhtml#ch03fig12) compares the classical container approach with Kata Containers.

![The difference between the kata containers and the containers in the cloud today is illustrated in the figure.](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9780136624226/files/graphics/03fig12.jpg)

**FIGURE 3-12** Kata Containers

The containers in the cloud today are as follows: The Hypervisor is present at the base followed by a single virtual machine. In the virtual machine, a kernel is common to two separate containers with Namespace and application. The kata containers are as follows: The Hypervisor is present at the base followed by two virtual machines. Each virtual machine has a kernel at the bottom connected to a container with namespace and an application.

In Kata Containers, each container has its kernel, thus providing the same level of isolation as virtual machines. Of course, this also comes at the cost of a more substantial infrastructure.

Companies offering virtual machine solutions have done a significant amount of work to mitigate their disadvantages in comparison to containers. Today’s offerings range from virtual machines to Kata Containers, to standard containers with trade-offs present in each choice.

#### 3.3.3 Container Network Interface

Containers are more dynamic than virtual machines and much more dynamic than bare-metal servers. Containers are deployed in great numbers, and they are created and destroyed continuously. The lightweight nature of containers enables “elasticity,” where services are scaled on demand. Service scaling should be automatic, so, naturally, container connectivity should be automated through an API. The Container Network Interface (CNI) answers this need [[22](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch03.xhtml#ch03ref22)]. It is a simple interface between the container runtime and network implementation. It is a way for an orchestrator to connect a workload to the network. It was developed as part of Rocket at CoreOS. It is a generic plugin-based networking solution for application containers on Linux. The plugability allows for normalizing the user-visible semantics for various network providers; for example, users of the orchestrator can use the same interface regardless of whether it is running in a public cloud as a service or in an on-premise network.

Currently, it is composed of a simple set of four APIs:

- ADD network for a container

- DEL network for a container

- CHECK status of the network for a container

- VERSION, which provides the supported CNI versions by the driver

These APIs are blocking APIs; for example, container orchestrator would wait for the underlying network provider to finish the network plumbing, including assigning an IP address, to ensure that network is ready before an application can be started to use the network. This semantic makes it a perfect place to instantiate any security and other policies before the workload is brought up. Kubernetes and other orchestration systems selected CNI; it has become the industry standard.

A similar effort exists in the storage space; it is called Container Storage Interface (CSI) [[23](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch03.xhtml#ch03ref23)].

#### 3.3.4 Kubernetes

Kubernetes (commonly written K8s) [[24](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch03.xhtml#ch03ref24)], [[25](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch03.xhtml#ch03ref25)] is an important project that is shaping the future of containers. Kubernetes is container orchestration software for automating deployment, scaling, and management of containerized applications. Google designed it based on the experience of creating Borg [[26](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch03.xhtml#ch03ref26)], and currently, the Cloud Native Computing Foundation maintains it. Other container orchestration systems exist, such as Mesos, but Kubernetes is the most popular and the most promising one. It manages containerized applications across multiple hosts in a cluster. [Figure 3-13](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch03.xhtml#ch03fig13) shows the Kubernetes cluster components.

![A figure depicts the Kubernetes cluster components.](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9780136624226/files/graphics/03fig13.jpg)

**FIGURE 3-13** Kubernetes Cluster Components

The Kubernetes cluster has three nodes connected to a master node. The three nodes have the following components: a docker, a kubelet, and a kube-proxy. The components inside the master node are controllers, scheduler, API server, and an etcd database. The controllers and schedulers are connected to the API server. The API server is connected to the etcd database. All three nodes are connected to the API server in the master node.

[Figure 3-14](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch03.xhtml#ch03fig14) illustrates how microservices are deployed using Kubernetes.

![The microservices that are deployed using the Kubernetes are illustrated in the figure.](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9780136624226/files/graphics/03fig14.jpg)

**FIGURE 3-14** Microservices Deployed using Kubernetes

The service user requests web user interface, API and CLI are sent to the K8s (Kubernetes) ingress: external LB, which is in turn connected to the K8s- node. The K8s service nodes have the svc1 - inst1 (or svc 1 - inst2) and a docker, kubelet kubeproxy.

A Kubernetes cluster is composed of at least three nodes. Each node may be a VM or a bare-metal server. Each node contains the services necessary to run pods (see later) and is managed by the master node(s). Services on a node include the container runtime (typically Docker), kubelet (the primary node agent), and kube-proxy (the network proxy).

The master node(s) contains the cluster control plane. Multinode high-available masters are common in production. The API server is the front-end of the Kubernetes control plane. The master node(s) includes the API server, the front-end of the Kubernetes control plane; the “etcd” database, a highly available key-value store used for all cluster data; the scheduler; and various controllers.

Another critical concept in Kubernetes is the “pod.” A pod is an atomic unit of deployment that cannot be split. A pod encapsulates one or more containers that share the same resources and local network. A pod is highly available. If it dies, it gets rescheduled.

A pod is the unit of replication in Kubernetes. In production, it is common practice to have multiple copies of a pod running for load balancing and fault tolerance. When an application is overloaded, it is possible to increase the number of instances of a pod.

Kubernetes is a vast system with many components; a full explanation of Kubernetes is outside the scope of this book. Kubernetes maintains a nice documentation site [[27](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch03.xhtml#ch03ref27)].

### 3.4 The Microservice Architecture

In this section, we shift gears and look at how to apply virtualization techniques best when applications are written from scratch or substantially rewritten. The most recent paradigm is to write these applications as a collection of microservices [[28](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch03.xhtml#ch03ref28)] and to use microservices as the “LEGO blocks” to build complex and scalable software or newer services.

There is no official definition of what a microservice is but, for this book, we assume this: “*A microservice implements a small unit of a conceptual business function that can be accessed via a well-defined interface.*” [Figure 3-15](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch03.xhtml#ch03fig15) depicts a microservice architecture.

![The architecture of microservice is illustrated.](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9780136624226/files/graphics/03fig15.jpg)

**FIGURE 3-15** A Microservice Architecture

The Microservice architecture is as follows: The user requests, web user interface, API, CLI are connected to the microservice 1 via the external LB. The microserver 1 is connected to the microserver 3 via the local balancing (explicit or client-side). The microservice 3 is connected to the microservice 2 via the REST/g RPC APIs which in turn is connected to the microserver 4. Each microservice has the following components: instances 1 to n and the microservice distributed databases.

Commonly accepted attributes of a microservice architecture are:

- Services are fine-grained.

- Protocols are lightweight.

- Application decomposition in microservices improves modularity.

- Applications are easier to understand, develop, and test.

- Continuous application delivery and deployment is easily enabled.

- Because microservices communicate through a clean API, they can be coded using different programming languages, databases, and so on.

- They can be independently scaled as the load increases by creating multiple instances and load balancing among them.

- They are usually built as stateless, restartable services, each backed by a shared database.

- They create a small failure domain with a scale-out model.

- Microservices are fast and easy to spin up and tear down.

The API used by microservices is either a REST API (see [section 3.4.1](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch03.xhtml#ch03lev2sec4_1)) or gRPC (see [section 3.4.2](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch03.xhtml#ch03lev2sec4_2)). Sometimes microservices support both APIs. REST API and gRPC usually run on top of HTTP/HTTPS protocols. HTTPS enables the applications to provide authenticated access to a given microservice. These APIs are generally backward compatible, so components can be swapped out with newer revisions without impacting other parts.

Microservices are implemented as stateless instances; that is, they can be quickly terminated/started to scale up/down with the application load. This allows a load balancer to sit in front and route any incoming URLs/APIs to various back-end instances.

Microservices are popular with developers because they are faster to develop, test, rebuild, and replace, thanks to their independence from each other and clear APIs. Teams can be smaller and more focused and adopt new development technologies more efficiently.

Microservices are natively designed for the cloud; they can be run on-premise or in the cloud. They take advantage of the container architecture and modern tooling; see [section 3.3](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch03.xhtml#ch03lev1sec3).

Microservices use mature schedulers such as Kubernetes (see [section 3.3.4](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch03.xhtml#ch03lev2sec3_4)) and built-in telemetry, security, and observability. Microservices also have disadvantages. The main one is that they don’t work well for existing or “brownfield” applications; that is, they require applications to be rewritten.

Troubleshooting can also be challenging due to the need to track interservice dependencies. There are tools for helping this aspect but, of course, they consume resources and add overhead.

There is also additional latency because function calls inside a process are replaced with RPCs over the IP network, with all the associated overhead.

Highly optimized standardized tooling like protobuf/gRPC (see [section 3.4.2](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch03.xhtml#ch03lev2sec4_2)) can help to compensate for this overhead. Also, RPC load balancers add an extra hop before a service can be reached. Client-side load balancing (for example, finagle, gRPC-lb) can help alleviate this.

Another critical design consideration is that partitioning an application in microservices with improper abstractions can be worse than keeping it monolithic. Inappropriate partitioning results in increased RPC calls, which exposes internal functioning, and troubleshooting interservice dependencies becomes a nightmare, especially in the presence of circular dependencies. Any microservice architecture should account for time spent creating the correct business abstractions.

Microservices are also complicated to deploy and operationalize without proper tooling like Kubernetes (see [section 3.3.4](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch03.xhtml#ch03lev2sec3_4)).

#### 3.4.1 REST API

Roy Fielding first introduced REST (Representational State Transfer) in 2000 in his dissertation [[29](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch03.xhtml#ch03ref29)]. It is a software architecture that defines a set of constraints that must be satisfied to create RESTful web services. REST is a client-server architecture that separates the user interface from the application logic and storage. Each REST request is stateless; that is, it contains all the information necessary to process it, and it cannot refer to any state stored on the server. Session state is, therefore, kept entirely on the client. Each response must also indicate if the data is cacheable; that is, if the client can reuse it. Requests are sent from the client to the server, commonly using HTTP. The most common methods are GET, PUT, POST, and DELETE. Typically, the responses are formatted in HTML, XML, or JSON.

REST aims to achieve performance, reliability, and reusability by using a stateless protocol and standard operations. REST is not a synonym of HTTP: REST principles are stricter and can be applied independently of HTTP.

A common approach is to start from an object model and generate the REST APIs automatically. Swagger [[30](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch03.xhtml#ch03ref30)] has been both a tool to create the API and a modeling language that has now evolved into OpenAPI Specification (OAS) [[31](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch03.xhtml#ch03ref31)]. YANG [[32](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch03.xhtml#ch03ref32)] (Yet Another Next Generation) is another data modeling language that can be used for this purpose.

#### 3.4.2 gRPC

gRPC [[33](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch03.xhtml#ch03ref33)] is an open source remote procedure call (RPC) system developed initially at Google. gRPC is coupled with *protocol buffers* [[34](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch03.xhtml#ch03ref34)].

Protocol buffers are Google’s “language-neutral, platform-neutral, extensible mechanism for serializing structured data.” An interface description language (IDL) describes the structure of the data, and a program creates the source code for generating and parsing the byte stream. gRPC can use protocol buffers as both its IDL and as its underlying message interchange format.

gRPC uses HTTP/2 for transport and provides features such as authentication, bidirectional streaming, flow control, blocking or nonblocking bindings, cancellation, and timeouts.

REST API and gRPC are similar in functionality, and they can be generated simultaneously from the same IDL or modeling language, but they have differences, too:

- REST API encodes textual representation, making it easy to be human readable; for example, the “curl” utility can be used to execute a REST API and interact with a system.

- gRPC uses a binary representation, making it more compact and high performance, and it has built-in load balancing.

In general, gRPC is suitable for internal service-service communication, whereas REST is useful for external communication.

### 3.5 OpenStack

When a company wants to build a cloud, some of the significant problems to solve are the provisioning, management, and monitoring of the cloud infrastructure. Several commercial companies offer software for this purpose. OpenStack is an open-source project that attempts to address the problem in its globality.

OpenStack [[35](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch03.xhtml#ch03ref35)] is an open-source software platform for provisioning, deployment, and management of VMs, containers, and bare-metal servers. It is a modular architecture dedicated to builders and operators of cloud infrastructures.

The OpenStack Foundation manages the project under the principles of open source, design, development, and community.

It is one of the most significant open source projects, but it is difficult to grasp its actual penetration in production environments.

[Figure 3-16](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch03.xhtml#ch03fig16) shows the OpenStack architecture.

![The OpenStack architecture is illustrated in the figure.](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9780136624226/files/graphics/03fig16.jpg)

**FIGURE 3-16** The OpenStack Architecture

The OpenStack architecture has the following layers. Layer 1: shared services. Layer 2: networking, bare metal, and storage. Layer 3: compute. Layer 4: workload provisioning, application lifecycle, and orchestration. Layer 5: web frontend and API proxies. The subcomponents in the first layer are keystone, glance, barbican, searchlight, and karbor. The subcomponents in the second layer are as follows: Networking includes SDN (neutron), load balancing (Octavia), and DNS (designate); Bare metal includes servers (ironic) and GPUS (cyborg); and Storage includes object (swift), block (cinder), and file (Manila). The subcomponents in the third layer are virtual machine (Nova), containers (zun), and functions (qinling). The subcomponents in the fourth layer are as follows: workload provisioning has magnum, trove, and Sahara; the application lifecycle has Murano, freezer, solum, and masakari; and the orchestration has heat, mistral, aodh, senlin, zaqar, and blazar. The subcomponents in the fifth layer are as follows: web frontend has horizon, API proxies have EC2API.

Among the many modules that constitute OpenStack, the most relevant are:

- **Keystone (Identity Service):** A service for authenticating and managing users and roles in the OpenStack environment. It authenticates users and services by sending and validating authorization tokens.

- **Neutron (Networking):** A service for physical and virtual networking in an OpenStack cloud. It includes many standard networking concepts such as VLANs, VXLANs, IP addresses, IP subnets, ports, routers, load balancers, and so on.

- **Nova (Compute):** A service for physical and virtual computing resources, mainly instances (for example, virtual machines) and hosts (for example, hardware resources, mostly servers). Nova can also be used to snapshot an instance or to migrate it.

- **Glance (Image Service):** A service to register, discover, and retrieve virtual machine images.

- **Cinder (Block Storage):** A service to connect storage volumes to compute instances. Cinder supports different storage protocols, like iSCSI, to access the storage volumes.

- **Swift (Object Storage):** A service that implements object storage on commodity hardware. Swift is highly scalable and redundant.

- **Ironic (bare-metal):** A service for server bare-metal provision.

The book *OpenStack Cloud Computing* [[36](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch03.xhtml#ch03ref36)] provides a good overview of OpenStack and shows the role of Ansible [[37](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch03.xhtml#ch03ref37)] in OpenStack configuration and automation. [Figure 3-16](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch03.xhtml#ch03fig16) shows that many more modules are available in addition to the ones listed previously.

### 3.6 NFV

This section contains an example of application of virtualization, called Network Function Virtualization (NFV), mainly used in the telecommunications community.

The architecture of telephone networks has dramatically evolved with the introduction of cellular technology. Each new generation (2G, 3G, 4G, LTE, 5G) has added more features, deemphasizing classical phone calls in favor of Internet traffic, apps, and services. Initially, telecommunications companies have tried to implement these services using discrete appliances, like firewalls, NATs, load balancers, session border controllers, message routers, CDNs, WAN optimizers, and so on, but with the explosion of traffic and services, this approach has become impractical.

According to the ETSI (European Telecommunications Standards Institute) [[38](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch03.xhtml#ch03ref38)], new service creation often demands network reconfiguration and on-site installation of new dedicated equipment, which in turn requires additional floor space, power, and trained maintenance staff. The goal of NFV is to replace hardware appliances with virtualized network functions to allow networks to be agile and capable of responding to the needs of new services and traffic. In the extreme case, most of these functions can be moved to the cloud.

NFV is a network architecture that virtualizes entire classes of network node functions into building blocks that connect and are chained together to create communication services. It uses traditional server virtualization and virtual switches, as previously discussed, but it also adds virtualization of load balancers, firewalls, devices offering network address translation (NAT), intrusion detection and prevention, WAN acceleration, caching, Gateway GPRS Support Nodes (GGSN), Session Border Controllers, Domain Name Services (DNS), and other layer 4 services.

[Figure 3-17](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch03.xhtml#ch03fig17) shows an example of NFV. A different gray tone indicates distributed services for a diverse group of users.

![An illustration of Network Function Virtualization (NFV).](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9780136624226/files/graphics/03fig17.jpg)

**FIGURE 3-17** NFV example

In the network diagram, multiple servers are connected to the internal network which is in turn connected to the provider edge. The towers are placed near the provider edge. The servers have the following components: packet data gateway (PGW) virtual machine, service gateway (SGW) virtual machine (or PGW virtual machine), policy and charging rules function (PCRF) virtual machine, firewall (FW), load balancer (LB) (or firewall), and a device offering network address translation (NAT).

New standards like 5G, the latest generation of cellular mobile communications, exacerbate these needs by supporting many more applications and, therefore, many more user groups with different needs; for example, IoT (Internet of Things) and autonomous vehicles.

ETSI has been very active in trying to standardize NFV in one of its working groups, the ETSI ISG NFV [[39](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch03.xhtml#ch03ref39)]. Open Source Mano is also an ETSI-hosted initiative to develop an Open Source NFV Management and Orchestration (MANO) software stack aligned with ETSI NFV [[40](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch03.xhtml#ch03ref40)].

### 3.7 Summary

This chapter shows that any distributed network service architecture should support a mixture of bare-metal servers, virtual machines, and containers and be integrated with management and orchestration frameworks. Where to place the distributed services nodes depends on multiple factors, including virtualized versus bare-metal workload, the amount of bandwidth required, and the kind of services needed. The remainder of the book describes these topics in detail.

The next chapter focuses on network virtualization services.

### 3.8 Bibliography

**[[1](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch03.xhtml#rch03ref1)]** Bugnion, E., Devine, S., Rosenblum, M., Sugerman, J., and Wang, E. Y. 2012. Bringing virtualization to the x86 architecture with the original VMware Workstation. ACM Trans. Comput. Syst. 30, 4, Article 12 (November 2012), 51 pages.

**[[2](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch03.xhtml#rch03ref2)]** Alam N., Survey on hypervisors. Indiana University, Bloomington, School of Informatics and Computing, 2009.

**[[3](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch03.xhtml#rch03ref3)]** VMware ESXi: The Purpose-Built Bare Metal Hypervisor, [https://www.vmware.com/products/esxi-and-esx.html](https://www.vmware.com/products/esxi-and-esx.html)

**[[4](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch03.xhtml#rch03ref4)]** Anthony Velte and Toby Velte. 2009. *Microsoft Virtualization with Hyper-V* (1 ed.). McGraw-Hill, Inc., New York, NY, USA.

**[[5](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch03.xhtml#rch03ref5)]** Fabrice Bellard. 2005. QEMU, a fast and portable dynamic translator. In Proceedings of the annual conference on USENIX Annual Technical Conference (ATEC ’05). USENIX Association, Berkeley, CA, USA, 41–41.

**[[6](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch03.xhtml#rch03ref6)]** QEMU, [https://www.qemu.org](https://www.qemu.org/)

**[[7](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch03.xhtml#rch03ref7)]** Habib I., “Virtualization with KVM,” Linux Journal, 2008:8.

**[[8](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch03.xhtml#rch03ref8)]** Linux KVM. [https://www.linux-kvm.org](https://www.linux-kvm.org/)

**[[9](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch03.xhtml#rch03ref9)]** Virtio, [https://wiki.libvirt.org/page/Virtio](https://wiki.libvirt.org/page/Virtio)

**[[10](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch03.xhtml#rch03ref10)]** Using VirtIO NIC - KVM, [https://www.linux-kvm.org/page/Using_VirtIO_NIC](https://www.linux-kvm.org/page/Using_VirtIO_NIC)

**[[11](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch03.xhtml#rch03ref11)]** ibvirt. [https://libvirt.org](https://libvirt.org/)

**[[12](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch03.xhtml#rch03ref12)]** Paul Barham, Boris Dragovic, Keir Fraser, Steven Hand, Tim Harris, Alex Ho, Rolf Neugebauer, Ian Pratt, and Andrew Warfield. 2003. Xen and the art of virtualization. In Proceedings of the nineteenth ACM symposium on Operating systems principles (SOSP ’03). ACM, New York, NY, USA, 164–177. DOI: [https://doi.org/10.1145/945445.945462](https://doi.org/10.1145/945445.945462)

**[[13](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch03.xhtml#rch03ref13)]** XEN, [https://xenproject.org](https://xenproject.org/)

**[[14](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch03.xhtml#rch03ref14)]** Citrix hypervisor, [https://www.citrix.com/products/citrix-hypervisor](https://www.citrix.com/products/citrix-hypervisor)

**[[15](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch03.xhtml#rch03ref15)]** What is a Linux Container, RedHat, [https://www.redhat.com/en/topics/containers/whats-a-linux-container](https://www.redhat.com/en/topics/containers/whats-a-linux-container)

**[[16](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch03.xhtml#rch03ref16)]** Docker, [https://www.docker.com](https://www.docker.com/)

**[[17](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch03.xhtml#rch03ref17)]** Cloud Native Computing Foundation, containerd, [https://containerd.io](https://containerd.io/)

**[[18](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch03.xhtml#rch03ref18)]** The Linux Foundation Project, OCI: Open Container Initiative, [https://www.opencontainers.org](https://www.opencontainers.org/)

**[[19](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch03.xhtml#rch03ref19)]** CoreOS, [https://coreos.com](https://coreos.com/)

**[[20](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch03.xhtml#rch03ref20)]** Mesos, [http://mesos.apache.org](http://mesos.apache.org/)

**[[21](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch03.xhtml#rch03ref21)]** Kata Containers, [https://katacontainers.io](https://katacontainers.io/)

**[[22](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch03.xhtml#rch03ref22)]** GitHub, “Container Network Interface Specification,” [https://github.com/containernetworking/cni/blob/master/SPEC.md](https://github.com/containernetworking/cni/blob/master/SPEC.md)

**[[23](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch03.xhtml#rch03ref23)]** GitHub, Container Storage Interface (CSI) Specification, [https://github.com/container-storage-interface/spec](https://github.com/container-storage-interface/spec)

**[[24](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch03.xhtml#rch03ref24)]** kubernetes or K8s, [https://kubernetes.io](https://kubernetes.io/)

**[[25](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch03.xhtml#rch03ref25)]** Kelsey Hightower, Brendan Burns, and Joe Beda. 2017. *Kubernetes: Up and Running Dive into the Future of Infrastructure* (1st ed.). O’Reilly Media, Inc.

**[[26](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch03.xhtml#rch03ref26)]** Verma, A., Pedrosa, L., Korupolu, M., Oppenheimer, D., Tune, E., & Wilkes, J. (2015). Large-scale cluster management at Google with Borg. EuroSys. [https://pdos.csail.mit.edu/6.824/papers/borg.pdf](https://pdos.csail.mit.edu/6.824/papers/borg.pdf)

**[[27](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch03.xhtml#rch03ref27)]** Kubernetes documentation, kubernetes.io/docs/home

**[[28](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch03.xhtml#rch03ref28)]** Sam Newman. 2015. *Building Microservices* (1st ed.). O’Reilly Media, Inc.

**[[29](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch03.xhtml#rch03ref29)]** Fielding, Roy Thomas, “[Chapter 5: Representational State Transfer (REST)](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch05.xhtml#ch05).” Architectural Styles and the Design of Network-based Software Architectures (Ph.D.). University of California, Irvine, 2000.

**[[30](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch03.xhtml#rch03ref30)]** Swagger, [https://swagger.io](https://swagger.io/)

**[[31](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch03.xhtml#rch03ref31)]** Open API. [https://www.openapis.org](https://www.openapis.org/)

**[[32](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch03.xhtml#rch03ref32)]** Bjorklund, M., Ed., “YANG—A Data Modeling Language for the Network Configuration Protocol (NETCONF),” RFC 6020, DOI 10.17487/RFC6020, October 2010.

**[[33](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch03.xhtml#rch03ref33)]** gRPC, [https://grpc.io](https://grpc.io/)

**[[34](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch03.xhtml#rch03ref34)]** Protocol Buffers, [https://developers.google.com/protocol-buffers](https://developers.google.com/protocol-buffers)

**[[35](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch03.xhtml#rch03ref35)]** OpenStack Foundation. [https://www.openstack.org](https://www.openstack.org/)

**[[36](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch03.xhtml#rch03ref36)]** Kevin Jackson. 2012. *OpenStack Cloud Computing Cookbook*. Packt Publishing.

**[[37](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch03.xhtml#rch03ref37)]** Ansible, [https://www.ansible.com](https://www.ansible.com/)

**[[38](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch03.xhtml#rch03ref38)]** ETSI, [http://www.etsi.org](http://www.etsi.org/)

**[[39](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch03.xhtml#rch03ref39)]** NFV, [http://www.etsi.org/technologies-clusters/technologies/nfv](http://www.etsi.org/technologies-clusters/technologies/nfv)

**[[40](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch03.xhtml#rch03ref40)]** Mano, [http://www.etsi.org/technologies-clusters/technologies/nfv/open-source-mano](http://www.etsi.org/technologies-clusters/technologies/nfv/open-source-mano)

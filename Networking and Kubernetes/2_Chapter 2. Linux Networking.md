# Chapter 2. Linux Networking

To understand the implementation of networking in Kubernetes, we will need to understand the fundamentals
of networking in Linux. Ultimately, Kubernetes is a complex management tool for Linux (or Windows!) machines, and
this is hard to ignore while working with the Kubernetes network stack. This chapter will provide an overview of the
Linux networking stack, with a focus on areas of note in Kubernetes. If you are highly familiar with Linux networking
and network management, you may want to skim or skip this chapter.

###### Tip

This chapter introduces many Linux programs.
Manual, or *man*, pages, accessible with `man <program>`,
will provide more detail.

# Basics

Let’s revisit our Go web server,
which we used in [Chapter 1](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch01.html#networking_introduction).
This web server listens on port 8080
and returns “Hello” for HTTP requests to / (see [Example 2-1](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch02.html#EX1_Ch02)).

##### Example 2-1. Minimal web server in Go

```
package main

import (
	"fmt"
	"net/http"
)

func hello(w http.ResponseWriter, _ *http.Request) {
	fmt.Fprintf(w, "Hello")
}

func main() {
	http.HandleFunc("/", hello)
	http.ListenAndServe("0.0.0.0:8080", nil)
}
```

###### Warning

Ports 1–1023 (also known as *well-known ports*) require root permission to bind to.

Programs should always be given the least permissions necessary to function, which means that a typical web service should not be run as the root user. Because of this, many programs will listen on port 1024 or higher (in particular, port 8080 is a common choice for HTTP services). When possible, listen on a nonprivileged port,
and use infrastructure redirects (load balancer forwarding, Kubernetes services, etc.) to forward an externally visible privileged port to a program listening on a nonprivileged port.

This way, an attacker exploiting a possible vulnerability in your service will not have
overly broad permissions available to them.

Suppose this program is running on a Linux server machine
and an external client makes a request to `/`.
What happens on the server?
To start off,
our program needs to listen to an address and port.
Our program creates a socket for that address and port and binds to it.
The socket will receive requests addressed to both the specified address and port -
`8080` with any IP address in our case.

###### Note

`0.0.0.0` in IPv4 and `[::]` in IPv6 are wildcard addresses.
They match all addresses of their respective protocol
and, as such,
listen on all available IP addresses when used for a socket binding.

This is useful to expose a service,
without prior knowledge of what IP addresses the machines running it will have.
Most network-exposed services bind this way.

There are multiple ways to inspect sockets.
For example, `ls -lah /proc/<server proc>/fd` will list the sockets.
We will discuss some programs that can inspect sockets at the end of this chapter.

The kernel maps a given packet to a specific connection
and uses an internal state machine to manage the connection state.
Like sockets, connections can be inspected through various tools,
which we will discuss later in this chapter.
Linux represents each connection with a file.
Accepting a connection entails a notification from the kernel to our program,
which is then able to stream content to and from the file.

Going back to our Golang web server,
we can use `strace` to show what the server is doing:

```bash
$ strace ./main
execve("./main", ["./main"], 0x7ebf2700 /* 21 vars */) = 0
brk(NULL)                               = 0x78e000
uname({sysname="Linux", nodename="raspberrypi", ...}) = 0
mmap2(NULL, 8192, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_ANONYMOUS, -1, 0)
= 0x76f1d000
[Content cut]
```

Because `strace` captures all the system calls made by our server,
there is a *lot* of output.
Let’s reduce it somewhat to the relevant network syscalls.
Key points are highlighted, as the Go
HTTP server performs many syscalls during startup:

```
openat(AT_FDCWD, "/proc/sys/net/core/somaxconn",
O_RDONLY|O_LARGEFILE|O_CLOEXEC) = 3
epoll_create1(EPOLL_CLOEXEC)            = 4 
epoll_ctl(4, EPOLL_CTL_ADD, 3, {EPOLLIN|EPOLLOUT|EPOLLRDHUP|EPOLLET,
    {u32=1714573248, u64=1714573248}}) = 0
fcntl(3, F_GETFL)                       = 0x20000 (flags O_RDONLY|O_LARGEFILE)
fcntl(3, F_SETFL, O_RDONLY|O_NONBLOCK|O_LARGEFILE) = 0
read(3, "128\n", 65536)                 = 4
read(3, "", 65532)                      = 0
epoll_ctl(4, EPOLL_CTL_DEL, 3, 0x20245b0) = 0
close(3)                                = 0
socket(AF_INET, SOCK_STREAM|SOCK_CLOEXEC|SOCK_NONBLOCK, IPPROTO_TCP) = 3
close(3)                                = 0
socket(AF_INET6, SOCK_STREAM|SOCK_CLOEXEC|SOCK_NONBLOCK, IPPROTO_TCP) = 3 
setsockopt(3, SOL_IPV6, IPV6_V6ONLY, [1], 4) = 0 
bind(3, {sa_family=AF_INET6, sin6_port=htons(0),
inet_pton(AF_INET6, "::1", &sin6_addr),
    sin6_flowinfo=htonl(0), sin6_scope_id=0}, 28) = 0
socket(AF_INET6, SOCK_STREAM|SOCK_CLOEXEC|SOCK_NONBLOCK, IPPROTO_TCP) = 5
setsockopt(5, SOL_IPV6, IPV6_V6ONLY, [0], 4) = 0
bind(5, {sa_family=AF_INET6,
sin6_port=htons(0), inet_pton(AF_INET6,
    "::ffff:127.0.0.1", &sin6_addr), sin6_flowinfo=htonl(0),
sin6_scope_id=0}, 28) = 0
close(5)                                = 0
close(3)                                = 0
socket(AF_INET6, SOCK_STREAM|SOCK_CLOEXEC|SOCK_NONBLOCK, IPPROTO_IP) = 3
setsockopt(3, SOL_IPV6, IPV6_V6ONLY, [0], 4) = 0
setsockopt(3, SOL_SOCKET, SO_BROADCAST, [1], 4) = 0
setsockopt(3, SOL_SOCKET, SO_REUSEADDR, [1], 4) = 0
bind(3, {sa_family=AF_INET6, sin6_port=htons(8080),
inet_pton(AF_INET6, "::", &sin6_addr),
    sin6_flowinfo=htonl(0), sin6_scope_id=0}, 28) = 0 
listen(3, 128)                          = 0
epoll_ctl(4, EPOLL_CTL_ADD, 3,
{EPOLLIN|EPOLLOUT|EPOLLRDHUP|EPOLLET, {u32=1714573248,
    u64=1714573248}}) = 0
getsockname(3, {sa_family=AF_INET6, sin6_port=htons(8080),

inet_pton(AF_INET6, "::", &sin6_addr), sin6_flowinfo=htonl(0),
sin6_scope_id=0},
    [112->28]) = 0
accept4(3, 0x2032d70, [112], SOCK_CLOEXEC|SOCK_NONBLOCK) = -1 EAGAIN
    (Resource temporarily unavailable)
epoll_wait(4, [], 128, 0)               = 0
epoll_wait(4,
```

![1](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492081647/files/assets/1.png)

Open a file descriptor.

![2](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492081647/files/assets/2.png)

Create a TCP socket for IPv6 connections.

![3](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492081647/files/assets/3.png)

Disable `IPV6_V6ONLY` on the socket. Now, it can listen on IPv4 and IPv6.

![4](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492081647/files/assets/4.png)

Bind the IPv6 socket to listen on port 8080 (all addresses).

![5](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492081647/files/assets/5.png)

Wait for a request.

Once the server has started, we see the output from `strace` pause on `epoll_wait`.

At this point, the server is listening on its socket
and waiting for the kernel to notify it about packets.
When we make a request to our listening server, we see the “Hello” message:

```bash
$ curl <ip>:8080/
Hello
```

###### Tip

If you are trying to debug the fundamentals of a web server with `strace`,
you will probably not want to use a web browser.
Additional requests or metadata sent to the server may result in additional work for the server,
or the browser may not make expected requests.
For example, many browsers try to request a favicon file automatically.
They will also attempt to cache files, reuse connections, and do other things that make it harder to predict the exact network interaction.
When simple or minimal reproduction matters, try using a tool like `curl` or `telnet`.

In `strace`, we see the following from our server process:

```
[{EPOLLIN, {u32=1714573248, u64=1714573248}}], 128, -1) = 1
accept4(3, {sa_family=AF_INET6, sin6_port=htons(54202), inet_pton(AF_INET6,
    "::ffff:10.0.0.57", &sin6_addr), sin6_flowinfo=htonl(0), sin6_scope_id=0},
    [112->28], SOCK_CLOEXEC|SOCK_NONBLOCK) = 5
epoll_ctl(4, EPOLL_CTL_ADD, 5, {EPOLLIN|EPOLLOUT|EPOLLRDHUP|EPOLLET,
    {u32=1714573120, u64=1714573120}}) = 0
getsockname(5, {sa_family=AF_INET6, sin6_port=htons(8080),
    inet_pton(AF_INET6, "::ffff:10.0.0.30", &sin6_addr), sin6_flowinfo=htonl(0),
    sin6_scope_id=0}, [112->28]) = 0
setsockopt(5, SOL_TCP, TCP_NODELAY, [1], 4) = 0
setsockopt(5, SOL_SOCKET, SO_KEEPALIVE, [1], 4) = 0
setsockopt(5, SOL_TCP, TCP_KEEPINTVL, [180], 4) = 0
setsockopt(5, SOL_TCP, TCP_KEEPIDLE, [180], 4) = 0
accept4(3, 0x2032d70, [112], SOCK_CLOEXEC|SOCK_NONBLOCK) = -1 EAGAIN
    (Resource temporarily unavailable)
```

After inspecting the socket,
our server writes response data (“Hello” wrapped in the HTTP protocol) to the file descriptor.
From there, the Linux kernel (and some other userspace systems)
translates the request into packets
and transmits those packets back to our cURL client.

To summarize what the server is doing when it receives a request:

1.

Epoll returns and causes the program to resume.

1.

The server sees a connection from `::ffff:10.0.0.57`, the client IP address in this example.

1.

The server inspects the socket.

1.

The server changes `KEEPALIVE` options: it turns `KEEPALIVE` on, and sets a 180-second interval between `KEEPALIVE` probes.

This is a bird’s-eye view of networking in Linux,
from an application developer’s point of view.
There’s a lot more going on to make everything work.
We’ll look in more detail at parts of the networking stack that are particularly relevant
for Kubernetes users.

# The Network Interface

Computers use a *network interface* to communicate with the outside world.
Network interfaces can be physical (e.g., an Ethernet network controller) or virtual.
Virtual network interfaces do not correspond to physical hardware; they are abstract interfaces provided by the host or hypervisor.

IP addresses are assigned to network interfaces.
A typical interface may have one IPv4 address and one IPv6 address,
but multiple addresses can be assigned to the same interface.

Linux itself has a concept of a network interface,
which can be physical (such as an Ethernet card and port)
or virtual.
If you run `ifconfig`,
you will see a list of all network interfaces and their configurations
(including IP addresses).

The *loopback interface* is a special interface for same-host communication.
`127.0.0.1` is the standard IP address for the loopback interface.
Packets sent to the loopback interface will not leave the host, and processes listening on `127.0.0.1` will be
accessible only to other processes on the same host.
Note that making a process listen on `127.0.0.1` is not a security boundary.
CVE-2020-8558 was a past Kubernetes vulnerability, in which `kube-proxy` rules allowed some remote systems to reach `127.0.0.1`.
The loopback interface is commonly abbreviated as `lo`.

###### Tip

The `ip` command can also be used to inspect network interfaces.

Let’s look at a typical `ifconfig` output; see [Example 2-2](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch02.html#EX0202).

##### Example 2-2. Output from `ifconfig` on a machine with one pysical network interface (ens4), and the loopback interface

```bash
$ ifconfig
ens4: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1460
        inet 10.138.0.4  netmask 255.255.255.255  broadcast 0.0.0.0
        inet6 fe80::4001:aff:fe8a:4  prefixlen 64  scopeid 0x20<link>
        ether 42:01:0a:8a:00:04  txqueuelen 1000  (Ethernet)
        RX packets 5896679  bytes 504372582 (504.3 MB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 9962136  bytes 1850543741 (1.8 GB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

lo: flags=73<UP,LOOPBACK,RUNNING>  mtu 65536
        inet 127.0.0.1  netmask 255.0.0.0
        inet6 ::1  prefixlen 128  scopeid 0x10<host>
        loop  txqueuelen 1000  (Local Loopback)
        RX packets 352  bytes 33742 (33.7 KB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 352  bytes 33742 (33.7 KB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0
```

Container runtimes create a virtual network interface for each pod on a host,
so the list would be much longer on a typical Kubernetes node.
We’ll cover container networking in more detail in [Chapter 3](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch03.html#container_networking_basics).

# The Bridge Interface

The bridge interface (shown in [Figure 2-1](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch02.html#img-bridge)) allows system administrators to create multiple layer 2 networks on a single host.
In other words,
the bridge functions like a network switch between network interfaces on a host,
seamlessly connecting them.
Bridges allow pods,
with their individual network interfaces,
to interact with the broader network
via the node’s network interface.

![Bridge](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492081647/files/assets/neku_0201.png)

###### Figure 2-1. Bridge interface

###### Note

You can read more about Linux bridging in the [documentation](https://oreil.ly/4BRsA).

In [Example 2-3](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch02.html#Veth),
we demonstrate how to create a bridge device named `br0`
and attach a virtual Ethernet (veth) device, `veth`, and a physical
device, `eth0`, using `ip`.

##### Example 2-3. Creating bridge interface and connecting veth pair

```bash
# # Add a new bridge interface named br0.
# ip link add br0 type bridge
# # Attach eth0 to our bridge.
# ip link set eth0 master br0
# # Attach veth to our bridge.
# ip link set veth master br0
```

Bridges can also be managed and created using the `brctl` command.
[Example 2-4](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch02.html#Brctl) shows some options available with
`brctl`.

##### Example 2-4. `brctl` options

```bash
$ brctl
$ commands:
        addbr           <bridge>                add bridge
        delbr           <bridge>                delete bridge
        addif           <bridge> <device>       add interface to bridge
        delif           <bridge> <device>       delete interface from bridge
        setageing       <bridge> <time>         set ageing time
        setbridgeprio   <bridge> <prio>         set bridge priority
        setfd           <bridge> <time>         set bridge forward delay
        sethello        <bridge> <time>         set hello time
        setmaxage       <bridge> <time>         set max message age
        setpathcost     <bridge> <port> <cost>  set path cost
        setportprio     <bridge> <port> <prio>  set port priority
        show                                    show a list of bridges
        showmacs        <bridge>                show a list of mac addrs
        showstp         <bridge>                show bridge stp info
        stp             <bridge> <state>        turn stp on/off
```

The veth  device is a local Ethernet tunnel. Veth devices are created in pairs, as shown in [Figure 2-1](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch02.html#img-bridge),
where the pod sees an `eth0` interface from the veth.
Packets transmitted on one device in the pair are immediately received on the other device. When either device is
down, the link state of the pair is down. Adding a bridge to Linux can be done with using the `brctl` commands or
`ip`. Use a veth configuration when namespaces need to communicate to the main host namespace or between each other.

[Example 2-5](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch02.html#Veth-Create) shows how to set up a veth configuration.

##### Example 2-5. Veth creation

```bash
# ip netns add net1
# ip netns add net2
# ip link add veth1 netns net1 type veth peer name veth2 netns net2
```

In [Example 2-5](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch02.html#Veth-Create), we show the steps to create two network namespaces (not to be confused with Kubernetes namespaces), `net1` and `net2`, and a pair of veth devices, with `veth1` assigned
to namespace `net1` and `veth2` assigned to namespace `net2`. These two namespaces are connected with this veth pair. Assign a pair
of IP addresses, and you can ping and communicate between the two namespaces.

Kubernetes uses this in concert with the CNI project to manage container network namespaces, interfaces, and IP
addresses. We will cover more of this in [Chapter 3](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch03.html#container_networking_basics).

# Packet Handling in the Kernel

The Linux kernel is responsible for translating between packets,
and a coherent stream of data for programs.
In particular, we will look at how the kernel handles connections
because routing and firewalling, key things in Kubernetes,
rely heavily on Linux’s underlying packet management.

## Netfilter

Netfilter, included in Linux since 2.3,
is a critical component of packet handling.
Netfilter is a framework of kernel hooks,
which allow userspace programs to handle packets on behalf of the kernel.
In short,
a program registers to a specific Netfilter hook, and
the kernel calls that program on applicable packets.
That program could tell the kernel to do something with the packet (like drop it),
or it could send back a modified packet to the kernel.
With this, developers can build normal programs that run in userspace
and handle packets.
Netfilter was created jointly with `iptables`,
to separate kernel and userspace code.

###### Tip

[netfilter.org](https://netfilter.org/) contains some excellent documentation on the design and use of both Netfilter and `iptables`.

Netfilter has five hooks, shown in [Table 2-1](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch02.html#webfilter_hooks).

Netfilter triggers each hook under specific stages in a packet’s journey through the kernel.
Understanding Netfilter’s hooks is key to understanding `iptables` later in this chapter,
as `iptables` directly maps its concept of *chains* to Netfilter hooks.

| Netfilter hook | Iptables chain name | Description |
| --- | --- | --- |
| NF_IP_PRE_ROUTING | PREROUTING | Triggers when a packet arrives from an external system. |
| NF_IP_LOCAL_IN | INPUT | Triggers when a packet’s destination IP address matches this machine. |
| NF_IP_FORWARD | NAT | Triggers for packets where neither source nor destination<br>matches the machine’s IP addresses (in other words, packets that this machine is routing on behalf of other machines). |
| NF_IP_LOCAL_OUT | OUTPUT | Triggers when a packet, originating from the machine, is leaving the machine. |
| NF_IP_POST_ROUTING | POSTROUTING | Triggers when any packet (regardless of origin) is leaving the machine. |

Netfilter triggers each hook during a specific phase of packet handling, and
under specific conditions,
we can visualize Netfilter hooks with a flow diagram, as shown in [Figure 2-2](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch02.html#img-nftables-packet-flow).

![neku 0202](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492081647/files/assets/neku_0202.png)

###### Figure 2-2. The possible flows of a packet through Netfilter hooks

We can infer from our flow diagram that only certain permutations of Netfilter hook calls are possible for any given packet.
For example, a packet originating from a local process will always trigger
`NF_IP_LOCAL_OUT` hooks and then `NF_IP_POST_ROUTING` hooks.
In particular,
the flow of Netfilter hooks for a packet depends on two things:
if the packet source is the host
and if the packet destination is the host.
Note that if a process sends a packet destined for the same host,
it triggers the `NF_IP_LOCAL_OUT` and then the `NF_IP_POST_ROUTING` hooks
before “reentering” the system
and triggering the `NF_IP_PRE_ROUTING` and `NF_IP_LOCAL_IN` hooks.

In some systems,
it is possible to spoof such a packet
by writing a fake source address (i.e., spoofing that a packet has a source and destination address of `127.0.0.1`).
Linux will normally filter such a packet when it arrives at an external interface.
More broadly,
Linux filters packets when a packet arrives at an interface
and the packet’s source address does not exist on that network.
A packet with an “impossible” source IP address is called a *Martian packet*.
It is possible to disable filtering of Martian packets in Linux.
However, doing so poses substantial risk
if any services on the host assume that traffic from localhost is “more trustworthy” than external traffic.
This can be a common assumption, such as when exposing an API or database to the host without strong authentication.

###### Note

Kubernetes has had at least one CVE, CVE-2020-8558, in which packets from another host,
with the source IP address falsely set to `127.0.0.1`,
could access ports that should be accessible only locally.
Among other things, this means that if a node in the Kubernetes control plane ran `kube-proxy`,
other machines on the node’s network could use “trust authentication” to connect to the API server,
effectively owning the cluster.

This was not technically a case of Martian packets not being filtered,
as offending packets would come from the loopback device,
which *is* on the same network as `127.0.0.1`.
You can read the reported issue on [GitHub](https://oreil.ly/A5HtN).

[Table 2-2](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch02.html#table0202) shows the Netfilter hook order for various packet sources and destinations.

| Packet source | Packet destination | Hooks (in order) |
| --- | --- | --- |
| Local machine | Local machine | `NF_IP_LOCAL_OUT`, `NF_IP_LOCAL_IN` |
| Local machine | External machine | `NF_IP_LOCAL_OUT`, `NF_IP_POST_ROUTING` |
| External machine | Local machine | `NF_IP_PRE_ROUTING`, `NF_IP_LOCAL_IN` |
| External machine | External machine | `NF_IP_PRE_ROUTING`, `NF_IP_FORWARD`, `NF_IP_POST_ROUTING` |

Note that packets from the machine to itself
will trigger `NF_IP_LOCAL_OUT` and `NF_IP_POST_ROUTING` and then “leave” the network interface.
They will “reenter” and be treated like packets from any other source.

Network address translation (NAT) only impacts local routing decisions in the `NF_IP_PRE_ROUTING` and `NF_IP_LOCAL_OUT` hooks
(e.g., the kernel makes no routing decisions after a packet reaches the `NF_IP_LOCAL_IN` hook).
We see this reflected in the design of `iptables`,
where source and destination NAT can be performed only in specific hooks/chains.

Programs can register a hook by calling `NF_REGISTER_NET_HOOK`  (`NF_REGISTER_HOOK` prior to Linux 4.13)
with a handling function.
The hook will be called every time a packet matches.
This is how programs like `iptables` integrate with Netfilter,
though you will likely never need to do this yourself.

There are several actions that a Netfilter hook can trigger,
based on the return value:

AcceptContinue packet handling.

DropDrop the packet, without further processing.

QueuePass the packet to a userspace program.

StolenDoesn’t execute further hooks, and allows the userspace program to take ownership of the packet.

RepeatMake the packet “reenter” the hook and be reprocessed.

Hooks can also return mutated packets.
This allows programs to do things such as reroute or masquerade packets, adjust packet TTLs, etc.

## Conntrack

Conntrack is a component of Netfilter
used to track the state of connections to (and from) the machine.
Connection tracking directly associates packets with a particular connection.
Without connection tracking,
the flow of packets is much more opaque.
Conntrack can be a liability or a valuable tool, or both, depending on how it is used.
In general, Conntrack is important on systems that handle firewalling or NAT.

Connection tracking allows firewalls to distinguish between responses and arbitrary packets.
A firewall can be configured to allow inbound packets
that are part of an existing connection
but disallow inbound packets that are not part of a connection.
To give an example, a program could be allowed to make an outbound connection and perform an HTTP request,
without the remote server being otherwise able to send data or initiate connections inbound.

NAT relies on Conntrack to function.
`iptables` exposes NAT as two types: SNAT (source NAT, where `iptables` rewrites the source address) and DNAT (destination NAT, where `iptables` rewrites the destination address).
NAT is extremely common;
the odds are overwhelming that your home router uses SNAT and DNAT to fan traffic between your public IPv4 address
and the local address of each device on the network.
With connection tracking,
packets are automatically associated with their connection
and easily modified with the same SNAT/DNAT change.
This enables consistent routing decisions,
such as “pinning” a connection in a load balancer to a specific backend or machine.
The latter example is highly relevant in Kubernetes,
due to `kube-proxy`’s implementation of service load balancing via `iptables`.
Without connection tracking,
every packet would need to be *deterministically* remapped to the same destination,
which isn’t doable (suppose the list of possible destinations could change…).

Conntrack identifies connections by a tuple, composed of source address, source port, destination address, destination port, and L4 protocol.
These five pieces of information are the minimal identifiers needed to identify any given L4 connection.
All L4 connections have an address and port on each side of the connection;
after all, the internet uses addresses for routing, and computers use port numbers for application mapping.
The final piece, the L4 protocol, is present because a program will bind to a port in TCP *or* UDP mode
(and binding to one does not preclude binding to the other).
Conntrack refers to these connections as *flows*.
A flow contains metadata about the connection and its state.

Conntrack stores flows in a hash table, shown in [Figure 2-3](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch02.html#img-conntrack-hashtable),
using the connection tuple as a key.
The size of the keyspace is configurable.
A larger keyspace requires more memory to hold the underlying array
but will result in fewer flows hashing to the same key
and being chained in a linked list,
leading to faster flow lookup times.
The maximum number of flows is also configurable.
A severe issue that can happen is when Conntrack runs out of space for connection tracking, and
new connections cannot be made.
There are other configuration options too,
such as the timeout for a connection.
On a typical system, default settings will suffice.
However, a system that experiences a huge number of connections
will run out of space.
If your host runs directly exposed to the internet,
overwhelming Conntrack with short-lived or incomplete connections
is an easy way to cause a denial of service (DOS).

![Conntrack Hashtable](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492081647/files/assets/neku_0203.png)

###### Figure 2-3. The structure of Conntrack flows

Conntrack’s max size is normally set in `/proc/sys/net/nf_conntrack_max`,
and the hash table size is normally set in `/sys/module/nf_conntrack/parameters/hashsize`.

Conntrack entries contain a connection state, which is one of four states.
It is important to note that, as a layer 3 (Network layer) tool,
Conntrack states are distinct from layer 4 (Protocol layer) states.
[Table 2-3](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch02.html#conntrack_states) details the four states.

| State | Description | Example |
| --- | --- | --- |
| NEW | A valid packet is sent or received, with no response seen. | TCP SYN received. |
| ESTABLISHED | Packets observed in both directions. | TCP SYN received, and TCP SYN/ACK sent. |
| RELATED | An additional connection is opened, where metadata indicates that it is “related” to an original connection.<br>Related connection handling is complex. | An FTP program, with an ESTABLISHED connection, opens additional data connections. |
| INVALID | The packet itself is invalid, or does not properly match another Conntrack connection state. | TCP RST received, with no prior connection. |

Although Conntrack is built into the kernel,
it may not be active on your system.
Certain kernel modules must be loaded,
and you must have relevant `iptables` rules
(essentially, Conntrack is normally not active if nothing needs it to be).
Conntrack requires the kernel module `nf_conntrack_ipv4` to be active.
`lsmod | grep nf_conntrack` will show if the module is loaded,
and `sudo modprobe nf_conntrack` will load it.
You may also need to install the `conntrack` command-line interface (CLI) in order to view Conntrack’s state.

When Conntrack is active,
`conntrack -L` shows all current flows.
Additional Conntrack flags will filter which flows are shown.

Let’s look at the anatomy of a Conntrack flow, as displayed here:

```
tcp      6 431999 ESTABLISHED src=10.0.0.2 dst=10.0.0.1
sport=22 dport=49431 src=10.0.0.1 dst=10.0.0.2 sport=49431 dport=22 [ASSURED]
mark=0 use=1

<protocol> <protocol number> <flow TTL> [flow state>]
<source ip> <dest ip> <source port> <dest port> [] <expected return packet>
```

The expected return packet is of the form `<source ip> <dest ip> <source port> <dest port>`.
This is the identifier that we expect to see when the remote system sends a packet.
Note that in our example,
the source and destination values are in reverse for address and ports.
This is often, but not always, the case.
For example, if a machine is behind a router,
packets destined to that machine will be addressed to the router,
whereas packets from the machine will have the machine address,
not the router address, as the source.

In the previous example from machine `10.0.0.2`, `10.0.0.1` has established a TCP connection from port 49431 to port 22 on `10.0.0.2`.
You may recognize this as being an SSH connection,
although Conntrack is unable to show application-level behavior.

Tools like `grep` can be useful for examining Conntrack state and ad hoc statistics:

```
grep ESTABLISHED /proc/net/ip_conntrack | wc -l
```

## Routing

When handling any packet, the kernel must decide where to send that packet. In most cases, the destination machine
will not be within the same network. For example, suppose you are attempting to connect to `1.2.3.4` from your personal
computer. `1.2.3.4` is not on your network; the best your computer can do is pass it to another host that is closer to
being able to reach `1.2.3.4`. The route table serves this purpose by mapping known subnets to a gateway IP address
and interface. You can list known routes with `route` (or `route -n` to show raw IP addresses instead of hostnames).
A typical machine will have a route for the local network
and a route for `0.0.0.0/0`. Recall that subnets can be expressed as a CIDR (e.g., `10.0.0.0/24`) or an IP address and a
mask (e.g., `10.0.0.0` and `255.255.255.0`).

This is a typical routing table for a machine on a local network with access to the internet:

```bash
# route
Kernel IP routing table
Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
0.0.0.0         10.0.0.1        0.0.0.0         UG    303    0        0 eth0
10.0.0.0        0.0.0.0         255.255.255.0   U     303    0        0 eth0
```

In the previous example, a request to `1.2.3.4` would be sent to `10.0.0.1`, on the `eth0` interface,
because `1.2.3.4` is in the subnet described by the first rule (`0.0.0.0/0`) and not in the subnet described by the second rule (`10.0.0.0/24`).
Subnets are specified by the destination and `genmask` values.

Linux prefers to route packets by *specificity* (how “small” a matching subnet is) and then by weight (“metric” in `route` output).
Given our example, a packet addressed to `10.0.0.1` will always be sent to gateway `0.0.0.0`
because that route matches a smaller set of addresses.
If we had two routes with the same specificity, then the route with a lower metric wiould be preferred.

Some CNI plugins make heavy use of the route table.

Now that we’ve covered some key concepts in how the Linux kernel handles packets,
we can look at how higher-level packet and connection routing works.

# High-Level Routing

Linux has complex packet management abilities. Such tools allow Linux users to create firewalls, log traffic, route
packets, and even implement load balancing. Kubernetes makes use of some of these tools to handle node and pod
connectivity, as well as manage Kubernetes services. In this book, we will cover the three tools that are most
commonly seen in Kubernetes. All Kubernetes setups will make some use of `iptables`, but there are many ways that
services can be managed. We will also cover IPVS (which has built-in support in `kube-proxy`), and eBPF, which is used
by Cilium (a `kube-proxy` alternative).

We will reference this section in [Chapter 4](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch04.html#kubernetes_networking_introduction), when we cover services and `kube-proxy`.

## iptables

`iptables` is staple of Linux sysadmins and has been for many years. `iptables` can be used to create firewalls and
audit logs, mutate and reroute packets, and even implement crude connection fan-out. `iptables` uses Netfilter, which
allows `iptables` to intercept and mutate packets.

`iptables` rules can become extremely complex. There are many tools that provide a simpler interface for managing
`iptables` rules; for example, firewalls like `ufw` and `firewalld`. Kubernetes components (specifically, `kubelet`
and `kube-proxy`) generate `iptables` rules in this fashion. Understanding `iptables` is important to understand access and
routing for pods and nodes in most clusters.

###### Note

Most Linux distributions are replacing `iptables` with `nftables`, a similar but more performant tool built atop Netfilter.
Some distros already ship with a version of `iptables` that is powered by
`nftables`.

Kubernetes has many known issues with the `iptables`/`nftables` transition. We highly recommend not using a
`nftables`-backed version of `iptables` for the foreseeable future.

There are three key concepts in `iptables`: tables, chains, and rules. They are considered hierarchical in nature: a table
contains chains, and a chain contains rules.

Tables organize rules according to the type of effect they have. `iptables` has a broad range of functionality,
which tables group together. The three most commonly applicable tables are: Filter (for firewall-related rules),
NAT (for NAT-related rules), and Mangle (for non-NAT packet-mutating rules). `iptables` executes tables in a specific
order, which we’ll cover later.

Chains contain a list of rules.
When a packet executes a chain,
the rules in the chain are evaluated in order.
Chains exist within a table
and organize rules according to Netfilter hooks.
There are five built-in, top-level chains, each of which corresponds to a Netfilter hook
(recall that Netfilter was designed jointly with `iptables`).
Therefore, the choice of which chain to insert a rule dictates if/when the rule will be evaluated for a given packet.

Rules are a combination condition and action (referred to as a *target*).
For example, “if a packet is addressed to port 22, drop it.”
`iptables` evaluates individual packets,
although chains and tables dictate which packets a rule will be evaluated against.

The specifics of table → chain → target execution are complex,
and there is no end of fiendish diagrams available to describe the full state machine.
Next, we’ll examine each portion in more detail.

###### Tip

It may help to refer to earlier material
as you progress through this section.
The designs of tables, chains, and rules are tightly intertwined,
and it is hard to properly understand one without understanding the others.

### iptables tables

A table in `iptables` maps to a particular *capability set*,
where each table is “responsible” for a specific type of action.
In more concrete terms, a table can contain only specific target types,
and many target types can be used only in specific tables.
`iptables` has five tables,
which are listed in [Table 2-4](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch02.html#iptables_tables).

| Table | Purpose |
| --- | --- |
| Filter | The Filter table handles acceptance and rejection of packets. |
| NAT | The NAT table is used to modify the source or destination IP addresses. |
| Mangle | The Mangle table can perform general-purpose editing of packet headers, but it is not intended for NAT. It can also “mark” the packet with `iptables`-only metadata. |
| Raw | The Raw table allows for packet mutation before connection tracking and other tables are handled. Its most common use is to disable connection tracking for some packets. |
| Security | SELinux uses the Security table for packet handling. It is not applicable on a machine that is not using SELinux. |

We will not discuss the Security table in more detail in this book;
however, if you use SELinux,
you should be aware of its use.

`iptables` executes tables in a particular order: Raw, Mangle, NAT, Filter.
However, this order of execution is broken up by chains.
Linux users generally accept the mantra of “tables contains chains,”
but this may feel misleading.
The order of execution is chains, *then* tables.
So, for example,
a packet will trigger `Raw PREROUTING`, `Mangle PREROUTING`, `NAT PREROUTING`,
and then trigger the Mangle table in either the `INPUT` or `FORWARD` chain (depending on the packet).
We’ll cover this in more detail in the next section on chains,
as we put more pieces together.

### iptables chains

`iptables` chains are a list of rules.
When a packet triggers or passes through a chain,
each rule is sequentially evaluated, until the packet matches a “terminating target” (such as `DROP`),
or the packet reaches the end of the chain.

The built-in, “top-level” chains are `PREROUTING`, `INPUT`, `NAT`, `OUTPUT`, and `POSTROUTING`.
These are powered by Netfilter hooks.
Each chain corresponds to a hook.
[Table 2-5](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch02.html#iptables_chains_and_corresponding_netfilter_hooks) shows the chain and hook pairs.
There are also user-defined subchains that exist to help organize rules.

| iptables chain | Netfilter hook |
| --- | --- |
| `PREROUTIN` | `NF_IP_PRE_ROUTING` |
| `INPUT` | `NF_IP_LOCAL_IN` |
| `NAT` | `NF_IP_FORWARD` |
| `OUTPUT` | `NF_IP_LOCAL_OUT` |
| `POSTROUTING` | `NF_IP_POST_ROUTING` |

Returning to our diagram of Netfilter hook ordering,
we can infer the equivalent diagram of `iptables` chain execution and ordering
for a given packet (see [Figure 2-4](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch02.html#img-iptables-packet-flow)).

![neku 0204](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492081647/files/assets/neku_0204.png)

###### Figure 2-4. The possible flows of a packet through `iptables` chains

Again, like Netfilter,
there are only a handful of ways that a packet can traverse these chains
(assuming the packet is not rejected or dropped along the way).
Let’s use an example with three machines,
with IP addresses `10.0.0.1`, `10.0.0.2`, and `10.0.0.3`, respectively.
We will show some routing scenarios
from the perspective of machine 1 (with IP address `10.0.0.1`).
We examine them in [Table 2-6](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch02.html#table0206).

| Packet description | Packet source | Packet destination | Tables processed |
| --- | --- | --- | --- |
| An inbound packet, from another machine. | `10.0.0.2` | `10.0.0.1` | `PREROUTING`, `INPUT` |
| An inbound packet, not destined for this machine. | `10.0.0.2` | `10.0.0.3` | `PREROUTING`, `NAT`, `POSTROUTING` |
| An outbound packet, originating locally, destined for another machine. | `10.0.0.1` | `10.0.0.2` | `OUTPUT`, `POSTROUTING` |
| A packet from a local program, destined for the same machine. | `127.0.0.1` | `127.0.0.1` | `OUTPUT`, `POSTROUTING` (then `PREROUTING`, `INPUT` as the packet re-enters via the loopback interface) |

###### Tip

You can experiment with chain execution behavior on your own
using `LOG` rules.
For example:

```
iptables -A OUTPUT -p tcp --dport 22 -j LOG
--log-level info --log-prefix "ssh-output"
```

will log TCP packets to port 22 when they are processed by the `OUTPUT` chain,
with the log prefix "`ssh-output`“.
Be aware that log size can quickly become unwieldy.
Log on important hosts with care.

Recall that when a packet triggers a chain,
`iptables` executes tables within that chain (specifically, the rules within each table)
in the following order:

1.

Raw

1.

Mangle

1.

NAT

1.

Filter

Most chains do not contain all tables;
however, the relative execution order remains the same.
This is a design decision to reduce redundancy.
For example, the Raw table exists to manipulate packets “entering” `iptables`,
and therefore has only `PREROUTING` and `OUTPUT` chains, in accordance with Netfilter’s packet flow. The tables that contain each chain are laid out in [Table 2-7](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch02.html#table0207).

|   | Raw | Mangle | NAT | Filter |
| --- | --- | --- | --- | --- |
| `PREROUTING` | ✓ | ✓ | ✓ |  |
| `INPUT` |  | ✓ | ✓ | ✓ |
| `FORWARD` |  | ✓ |  | ✓ |
| `OUTPUT` | ✓ | ✓ | ✓ | ✓ |
| `POSTROUTING` |  | ✓ | ✓ |  |

You can list the chains that correspond to a table yourself, with `iptables -L -t <table>`:

```bash
$ iptables -L -t filter
Chain INPUT (policy ACCEPT)
target     prot opt source               destination

Chain FORWARD (policy ACCEPT)
target     prot opt source               destination

Chain OUTPUT (policy ACCEPT)
target     prot opt source               destination
```

There is a small caveat for the NAT table:
DNAT can be performed in `PREROUTING` or `OUTPUT``,
and SNAT can be performed in only `INPUT` or `POSTROUTING`.

To give an example, suppose we have an inbound packet destined for our host.
The order of execution would be:

1.

`PREROUTING`

1.

Raw

1.

Mangle

1.

NAT

1.

`INPUT`

1.

Mangle

1.

NAT

1.

Filter

Now that we’ve learned about Netfilter hooks, tables, and chains,
let’s take one last look at the flow of a packet through `iptables`,
shown in [Figure 2-5](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch02.html#img-iptables-flow).

![Iptables packet](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492081647/files/assets/neku_0205.png)

###### Figure 2-5. The flow of a packet through `iptables` tables and chains. A circle denotes a table/hook combination that exists in `iptables`.

All `iptables` rules belong to a table and chain,
the possible combinations of which are represented as dots in our flow chart.
`iptables` evaluates chains (and the rules in them, in order) based on the order
of Netfilter hooks that a packet triggers.
For the given chain, `iptables` evaluates that chain in each table that it is present in
(note that some chain/table combinations do not exist, such as Filter/`POSTROUTING`).
If we trace the flow of a packet originating from the local host,
we see the following table/chains pairs evaluated, in order:

1.

Raw/`OUTPUT`

1.

Mangle/`OUTPUT`

1.

NAT/`OUTPUT`

1.

Filter/`OUTPUT`

1.

Mangle/`POSTROUTING`

1.

NAT/`POSTROUTING`

### Subchains

The aforementioned chains are the top-level, or entry-point, chains.
However, users can define their own subchains
and execute them with the JUMP target.
`iptables` executes such a chain in the same manner,
target by target, until a terminating target matches.
This can be useful for logical separation
or reusing a series of targets that can be executed in more than one context
(i.e., a similar motivation to why we might organize code into a function).
Such organization of rules across chains can have a substantial impact on performance.
`iptables` is, effectively,
running tens or hundreds or thousands of `if` statements against every
single packet that goes in or out of your system.
That has measurable impact on packet latency, CPU use, and network throughput.
A well-organized set of chains reduces this overhead
by eliminating effectively redundant checks or actions.
However, `iptables`’s performance given a service with many pods is still a problem in Kubernetes,
which makes other solutions with less or no `iptables` use,
such as IPVS or eBPF,
more appealing.

Let’s look at creating new chains in [Example 2-6](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch02.html#SSH-IPtables).

##### Example 2-6. Sample `iptables` chain for SSH firewalling

```bash
# Create incoming-ssh chain.
$ iptables -N incoming-ssh

# Allow packets from specific IPs.
$ iptables -A incoming-ssh -s 10.0.0.1 -j ACCEPT
$ iptables -A incoming-ssh -s 10.0.0.2 -j ACCEPT

# Log the packet.
$ iptables -A incoming-ssh -j LOG --log-level info --log-prefix "ssh-failure"

# Drop packets from all other IPs.
$ iptables -A incoming-ssh -j DROP

# Evaluate the incoming-ssh chain,
# if the packet is an inbound TCP packet addressed to port 22.
$ iptables -A INPUT -p tcp --dport 22 -j incoming-ssh
```

This example creates a new chain, `incoming-ssh`,
which is evaluated for any TCP packets inbound on port 22.
The chain allows packets from two specific IP addresses,
and packets from other addresses are logged and dropped.

Filter chains end in a default action, such as dropping the packet if no prior target matched.
Chains will default to `ACCEPT` if no default is specified.
`iptables -P <chain> <target>` sets the default.

### iptables rules

Rules have two parts: a match condition and an action (called a *target*).
The match condition describes a packet attribute.
If the packet matches,
the action will be executed.
If the packet does not match,
`iptables` will move to check the next rule.

Match conditions check if a given packet meets some criteria,
for example, if the packet has a specific source address.
The order of operations from tables/chains is important to remember,
as prior operations can impact the packet
by mutating it, dropping it, or rejecting it.
[Table 2-8](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch02.html#some_common_iptables_match_types) shows some common match types.

| Match type | Flag(s) | Description |
| --- | --- | --- |
| Source | `-s`, `--src`, `--source` | Matches packets with the specified source address. |
| Destination | `-d`, `--dest`, `--destination` | Matches packets with the destination source address. |
| Protocol | `-p`, `--protocol` | Matches packets with the specified protocol. |
| In interface | `-i`, `--in-interface` | Matches packets that entered via the specified interface. |
| Out interface | `-o`, `--out-interface` | Matches packets that are leaving the specified interface. |
| State | `-m state --state <states>` | Matches packets from connections that are in one of the comma-separated states. This uses the Conntrack states (NEW, ESTABLISHED, RELATED, INVALID). |

###### Note

Using `-m` or `--match`,
`iptables` can use extensions for match criteria.
Extensions range from nice-to-haves, such as specifying multiple ports in a single rule (multiport),
to more complex features such as eBPF interactions.
`man iptables-extensions` contains more information.

There are two kinds of target actions: terminating and nonterminating.
A terminating target
will stop `iptables` from checking subsequent targets in the chain,
essentially acting as a final decision.
A nonterminating target
will allow `iptables` to continue checking subsequent targets in the chain.
`ACCEPT`, `DROP`, `REJECT`, and `RETURN` are all terminating targets.
Note that `ACCEPT` and `RETURN` are terminating only *within their chain*.
That is to say, if a packet hits an `ACCEPT` target in a subchain,
the parent chain will resume processing
and could potentially drop or reject the target.
[Example 2-7](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch02.html#IPTABLEs-REJECT) shows a set of rules that would reject packets to port 80,
despite matching an `ACCEPT` at one point.
Some command output has been removed for simplicity.

##### Example 2-7. Rule sequence which would reject some previously accepted packets

```
```
$ iptables -L --line-numbers
Chain INPUT (policy ACCEPT)
num  target     prot opt source               destination
1    accept-all  all  --  anywhere             anywhere
2    REJECT     tcp  --  anywhere             anywhere
tcp dpt:80 reject-with icmp-port-unreachable

Chain accept-all (1 references)
num  target     prot opt source               destination
1               all  --  anywhere             anywhere
```
```

[Table 2-9](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch02.html#common_iptables_target_types_and_behavior) summarizes common target types and their behavior.

| Target type | Applicable tables | Description |
| --- | --- | --- |
| `AUDIT` | All | Records data about accepted, dropped, or rejected packets. |
| `ACCEPT` | Filter | Allows the packet to continue unimpeded and without further modification. |
| `DNAT` | NAT | Modifies the destination address. |
| `DROPs` | Filter | Discards the packet. To an external observer, it will appear as though the packet was never received. |
| `JUMP` | All | Executes another chain. Once that chain finishes executing, execution of the parent chain will continue. |
| `LOG` | All | Logs the packet contents, via the kernel log. |
| `MARK` | All | Sets a special integer for the packet, used as an identifier by Netfilter. The integer can be used in other `iptables` decisions and is not written to the packet itself. |
| `MASQUERADE` | NAT | Modifies the source address of the packet, replacing it with the address of a specified network interface. This is similar to SNAT, but does not require the machine’s IP address to be known in advance. |
| `REJECT` | Filter | Discards the packet and sends a rejection reason. |
| `RETURN` | All | Stops processing the current chain (or subchain). Note that this is *not* a terminating target, and if there is a parent chain, that chain will continue to be processed. |
| `SNAT` | NAT | Modifies the source address of the packet, replacing it with a fixed address. See also: `MASQUERADE`. |

Each target type may have specific options, such as ports or log strings, that apply to the rule.
[Table 2-10](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch02.html#iptables_target_command_examples) shows some example commands and explanations.

| Command | Explanation |
| --- | --- |
| iptables -A INPUT -s 10.0.0.1 | Accepts an inbound packet if the source address is `10.0.0.1`. |
| iptables -A INPUT -p ICMP | Accepts all inbound ICMP packets. |
| iptables -A INPUT -p tcp --dport 443 | Accepts all inbound TCP packets to port 443. |
| iptables -A INPUT -p tcp --dport 22 -j DROP | Drops all inbound TCP ports to port 22. |

A target belongs to both a table and a chain,
which control when (if at all) `iptables` executes the aforementioned target for a given packet.
Next, we’ll put together what we’ve learned
and look at `iptables` commands in practice.

### Practical iptables

You can show `iptables` chains with `iptables -L`:

```bash
$ iptables -L
Chain INPUT (policy ACCEPT)
target     prot opt source               destination

Chain FORWARD (policy ACCEPT)
target     prot opt source               destination

Chain OUTPUT (policy ACCEPT)
target     prot opt source               destination
```

###### Warning

There is a distinct but nearly identical program, `ip6tables`, for managing IPv6 rules. `iptables` and `ip6tables`
rules are completely separate. For example, dropping all packets to TCP `0.0.0.0:22` with `iptables` will not prevent
connections to TCP `[::]:22`, and vice versa for `ip6tables`.

For simplicity, we will refer only to `iptables` and IPv4 addresses in this section.

`--line-numbers` shows numbers for each rule in a chain.
This can be helpful when inserting or deleting rules.
`-I <chain> <line>` inserts a rule at the specified line number,
before the previous rule at that line.

The typical format of a command to interact with `iptables` rules is:

```
iptables [-t table] {-A|-C|-D} chain rule-specification
```

where `-A` is for *append*, `-C` is for *check*, and `-D` is for *delete*.

###### Warning

`iptables` rules aren’t persisted across restarts. `iptables` provides `iptables-save` and `iptables-restore` tools,
which can be used manually or with simple automation to capture or reload rules. This is something that most firewall
tools paper over by automatically creating their own `iptables` rules every time the system starts.

`iptables` can masquerade connections,
making it appear as if the packets came from their own IP address.
This is useful to provide a simplified exterior to the outside world.
A common use case is to provide a known host for traffic,
as a security bastion, or to provide a predictable set of IP addresses to third parties.
In Kubernetes,
masquerading can make pods use their node’s IP address,
despite the fact that pods have unique IP addresses.
This is necessary to communicate outside the cluster
in many setups,
where pods have internal IP addresses that cannot communicate directly with the internet.
The `MASQUERADE` target is similar to SNAT;
however, it does not require a `--source-address` to be known and specified in advance.
Instead, it uses the address of a specified interface.
This is slightly less performant than SNAT in cases where the new source address is static,
as `iptables` must continuously fetch the address:

```
$iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
```

`iptables` can perform connection-level load balancing
or more accurately, connection fan-out.
This technique relies on DNAT rules
and random selection (to prevent every connection from being routed to the first DNAT target):

```bash
$ iptables -t nat -A OUTPUT -p tcp --dport 80 -d $FRONT_IP -m statistic \
--mode random --probability 0.5 -j DNAT --to-destination $BACKEND1_IP:80
$ iptables -t nat -A OUTPUT -p tcp --dport 80 -d $FRONT_IP \
-j DNAT --to-destination $BACKEND2_IP:80
```

In the previous example,
there is a 50% chance of routing to the first backend.
Otherwise, the packet proceeds to the next rule,
which is guaranteed to route the connection to the second backend.
The math gets a little tedious for adding more backends.
To have an equal chance of routing to any backend,
the nth backend must have a 1/n chance of being routed to.
If there were three backends, the probabilities would need to be 0.3 (repeating), 0.5, and 1:

```
Chain KUBE-SVC-I7EAKVFJLYM7WH25 (1 references)
target     prot opt source               destination
KUBE-SEP-LXP5RGXOX6SCIC6C  all  --  anywhere             anywhere
    statistic mode random probability 0.25000000000
KUBE-SEP-XRJTEP3YTXUYFBMK  all  --  anywhere             anywhere
    statistic mode random probability 0.33332999982
KUBE-SEP-OMZR4HWUSCJLN33U  all  --  anywhere             anywhere
    statistic mode random probability 0.50000000000
KUBE-SEP-EELL7LVIDZU4CPY6  all  --  anywhere             anywhere
```

When Kubernetes uses `iptables` load balancing for a service,
it creates a chain as shown previously.
If you look closely, you can see rounding errors in one of the probability numbers.

Using DNAT fan-out for load balancing has several caveats.
It has no feedback for the load of a given backend
and will always map application-level queries on the same connection
to the same backend.
Because the DNAT result lasts the lifetime of the connection,
if long-lived connections are common,
many downstream clients may stick to the same upstream backend
if that backend is longer lived than others.
To give a Kubernetes example,
suppose a gRPC service has only two replicas and
then additional replicas scale up.
gRPC reuses the same HTTP/2 connection,
so existing downstream clients (using the Kubernetes service and not gRPC load balancing)
will stay connected to the initial two replicas,
skewing the load profile among gRPC backends.
Because of this,
many developers use a smarter client (such as making use of gRPC’s client-side load balancing),
force periodic reconnects at the server and/or client,
or use service meshes to externalize the problem.
We’ll discuss load balancing in more detail in Chapters [4](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch04.html#kubernetes_networking_introduction) and [5](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch05.html#kubernetes_networking_abstractions).

Although `iptables` is widely used in Linux,
it can become slow in the presence of a huge number of rules
and offers limited load balancing functionality.
Next we’ll look at IPVS,
an alternative that is more purpose-built for load balancing.

## IPVS

IP Virtual Server (IPVS) is a Linux connection (L4) load balancer.
[Figure 2-6](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch02.html#img-ipvs) shows a simple diagram of IPVS’s role in routing packets.

![IPVS](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492081647/files/assets/neku_0206.png)

###### Figure 2-6. IPVS

`iptables` can do simple L4 load balancing by
randomly routing connections, with the randomness shaped by the weights on individual DNAT rules.
IPVS supports
multiple load balancing modes (in contrast with the `iptables` one), which are outlined in [Table 2-11](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch02.html#ipvs_modes_supported_in_kubernetes).
This allows IPVS to spread load more effectively than `iptables`, depending on IPVS configuration and traffic patterns.

| Name | Shortcode | Description |
| --- | --- | --- |
| Round-robin | `rr` | Sends subsequent connections to the “next” host in a cycle. This increases the time between subsequent connections sent to a given host, compared to random routing like `iptables` enables. |
| Least connection | `lc` | Sends connections to the host that currently has the least open connections. |
| Destination hashing | `dh` | Sends connections deterministically to a specific host, based on the connections’ destination addresses. |
| Source hashing | `sh` | Sends connections deterministically to a specific host, based on the connections’ source addresses. |
| Shortest expected delay | `sed` | Sends connections to the host with the lowest connections to weight ratio. |
| Never queue | `nq` | Sends connections to any host with no existing connections, otherwise uses “shortest expected delay” strategy. |

IPVS supports packet forwarding modes:

-

NAT rewrites source and destination addresses.

-

DR encapsulates IP datagrams within IP datagrams.

-

IP tunneling directly routes packets to the backend server by rewriting the MAC address of the data frame with the MAC
address of the selected backend server.

There are three aspects to look at when it comes to issues with `iptables` as a load balancer:

Number of nodes in the clusterEven though Kubernetes already supports 5,000 nodes in release v1.6, `kube-proxy` with `iptables` is a bottleneck to
scale the cluster to 5,000 nodes. One example is that with a NodePort service in a 5,000-node cluster, if we have 2,000
services and each service has 10 pods, this will cause at least 20,000 `iptables` records on each worker node, which
can make the kernel pretty busy.

TimeThe time spent to add one rule when there are 5,000 services (40,000 rules) is 11 minutes. For 20,000 services (160,000 rules), it’s 5 hours.

LatencyThere is latency to access a service (routing latency); each packet must traverse the `iptables` list until a match is made. There is latency to add/remove rules, inserting and removing from an extensive list is an intensive operation at
scale.

IPVS also supports session affinity, which is exposed as an option in services
(`Service.spec.sessionAffinity` and `Service.spec.sessionAffinityConfig`).
Repeated connections,
within the session affinity time window,
will route to the same host.
This can be useful for scenarios such as minimizing cache misses.
It can also make routing in any mode effectively stateful (by indefinitely routing connections from the same address to the same host),
but the routing stickiness is less absolute in Kubernetes,
where individual pods come and go.

To create a basic load balancer with two equally weighted destinations,
run `ipvsadm -A -t <address> -s <mode>`.
`-A`, `-E`, and `-D` are used to add, edit, and delete virtual services, respectively.
The lowercase counterparts, `-a`, `-e`, and `-d`,
are used to add, edit, and delete host backends, respectively:

```bash
# ipvsadm -A -t 1.1.1.1:80 -s lc
# ipvsadm -a -t 1.1.1.1:80 -r 2.2.2.2 -m -w 100
# ipvsadm -a -t 1.1.1.1:80 -r 3.3.3.3 -m -w 100
```

You can list the IPVS hosts with `-L`.
Each virtual server (a unique IP address and port combination)
is shown, with its backends:

```bash
# ipvsadm -L
IP Virtual Server version 1.2.1 (size=4096)
Prot LocalAddress:Port Scheduler Flags
  -> RemoteAddress:Port           Forward Weight ActiveConn InActConn
TCP  1.1.1.1.80:http lc
  -> 2.2.2.2:http             Masq    100    0          0
  -> 3.3.3.3:http             Masq    100    0          0
```

`-L` supports multiple options, such as `--stats`, to show additional connection
statistics.

## eBPF

eBPF is a programming system that allows special sandboxed programs to run in the kernel
without passing back and forth between kernel and user space,
like we saw with Netfilter and `iptables`.

Before eBPF, there was the Berkeley Packet Filter (BPF). BPF is a technology used in the kernel,
among other things, to analyze network traffic. BPF supports filtering packets, which allows a userspace process to
supply a filter that specifies which packets it wants to inspect. One of BPF’s use cases is `tcpdump`, shown in [Figure 2-7](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch02.html#img-epbf). When you specify
a filter on `tcpdump`, it compiles it as a BPF program and passes it to BPF. The techniques in BPF have been extended
to other processes and kernel operations.

![tcpdump-ebpf](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492081647/files/assets/neku_0207.png)

###### Figure 2-7. `tcpdump`

An eBPF program has direct access to syscalls.
eBPF programs can directly watch and block syscalls, without the usual approach of adding kernel hooks to a
userspace program. Because of its performance characteristics,  it is well suited for writing networking software.

###### Tip

You can learn more about eBPF on its [website](http://ebpf.io/).

In addition to socket filtering, other supported attach points in the kernel are as
follows:

KprobesDynamic kernel tracing of internal kernel components.

UprobesUser-space tracing.

TracepointsKernel static tracing. These are programed into the kernel by developers and are more stable as
compared to kprobes, which may change between kernel versions.

perf_eventsTimed sampling of data and events.

XDPSpecialized eBPF programs that can go lower than kernel space to access driver space to act directly on packets.

Let’s return to `tcpdump` as an example. [Figure 2-8](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch02.html#img-epbf-example) shows a simplified rendition of `tcpdump`’s interactions with eBPF.

![ebpf](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492081647/files/assets/neku_0208.png)

###### Figure 2-8. eBPF example

Suppose we run `tcpdump -i any`.

The string is compiled by `pcap_compile` into a BPF program. The kernel will then use this BPF program to filter all
packets that go through all the network devices we specified, any with the `-I` in our case.

It will make this data available to `tcpdump` via a map. Maps are a data structure consisting of key-value pairs used by
the BPF programs to exchange data.

There are many reasons to use eBPF with Kubernetes:

Performance (hashing table versusiptableslist)For every service added to Kubernetes, the list of `iptables` rules that have to be traversed grows exponentially.
Because of the lack of incremental updates, the entire list of rules has to be replaced each time a new rule is added.
This leads to a total duration of 5 hours to install the 160,000 `iptables` rules representing 20,000 Kubernetes services.

TracingUsing BPF, we can gather pod and container-level network statistics. The BPF socket filter is nothing new, but the BPF socket
filter per cgroup is. Introduced in Linux 4.10, `cgroup-bpf` allows  attaching eBPF programs to cgroups. Once attached,
the program is executed for all packets entering or exiting any process in the cgroup.

Auditingkubectl execwith eBPFWith eBPF, you can attach a program that will record any commands executed in the `kubectl exec` session and
pass those commands to a userspace program that logs those events.

SecuritySeccompSecured computing that restricts what syscalls are allowed. Seccomp filters can be written in eBPF.

FalcoOpen source container-native runtime security that uses eBPF.

The most common use of eBPF in Kubernetes is Cilium,
CNI and service implementation.
Cilium replaces `kube-proxy`, which writes `iptables` rules to map a service’s IP address
to its corresponding pods.

Through eBPF, Cilium can intercept and route all packets directly in the kernel,
which is faster and allows for application-level (layer 7) load balancing.
We will cover `kube-proxy` in [Chapter 4](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch04.html#kubernetes_networking_introduction).

# Network Troubleshooting Tools

Troubleshooting network-related issues with Linux is a complex topic
and could easily fill its own book.
In this section, we will introduce some key troubleshooting tools
and the basics of their use ([Table 2-12](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch02.html#cheatsheet_of_common_debugging_cases_and_tools) is provided as a simple cheat sheet of tools and applicable use cases).
Think of this section as a jumping-off point for common Kubernetes-related tool uses.
Man pages, `--help`, and the internet can guide you further.
There is substantial overlap in the tools that we describe,
so you may find learning about some tools (or tool features) redundant.
Some are better suited to a given task than others
(for example, multiple tools will catch TLS errors,
but OpenSSL provides the richest debugging information).
Exact tool use may come down to preference, familiarity, and availability.

| Case | Tools |
| --- | --- |
| Checking connectivity | `traceroute`, `ping`, `telnet`, `netcat` |
| Port scanning | `nmap` |
| Checking DNS records | `dig`, commands mentioned in “Checking Connectivity” |
| Checking HTTP/1 | cURL, `telnet`, `netcat` |
| Checking HTTPS | OpenSSL, cURL |
| Checking listening programs | `netstat` |

Some networking tools that we describe likely won’t be preinstalled in your distro of choice,
but all should be available through your distro’s package manager.
We will sometimes use `# Truncated` in command output where we have omitted text
to avoid examples becoming repetitive or overly long.

## Security Warning

Before we get into tooling details, we need to talk about security.
An attacker can utilize any tool listed here
in order to explore and access additional systems.
There are many strong opinions on this topic,
but we consider it best practice to leave the fewest possible networking tools installed on a given machine.

An attacker may still be able to download tools themselves (e.g., by downloading a binary from the internet)
or use the standard package manager (if they have sufficient permission).
In most cases,
you are simply introducing some additional friction
prior to exploring and exploiting.
However, in some cases you can reduce an attacker’s capabilities by not preinstalling networking tools.

Linux file permissions include something called the *setuid bit* that
is sometimes used by networking tools.
If a file has the setuid bit set,
executing said file causes the file to be executed *as the user who owns the file*,
rather than the current user.
You can observe this by looking for an `s` rather than an `x` in the permission readout of a file:

```bash
$ ls -la /etc/passwd
-rwsr-xr-x 1 root root 68208 May 28  2020 /usr/bin/passwd
```

This allows programs to expose limited, privileged capabilities (for example, `passwd` uses this ability to allow a
user to update their password, without allowing arbitrary writes to the password file). A number of networking tools
(`ping`, `nmap`, etc.) may use the setuid bit on some systems to send raw packets, sniff packets, etc. If an attacker downloads their own copy
of a tool and cannot gain root privileges, they will be able to do less with said tool than if it was installed by the system with the setuid bit set.

## ping

`ping` is a simple program that sends ICMP `ECHO_REQUEST` packets to networked devices.
It is a common, simple way to test network connectivity from one host to another.

ICMP is a layer 4 protocol, like TCP and UDP.
Kubernetes services support TCP and UDP, but not ICMP.
This means that pings to a Kubernetes service will always fail.
Instead, you will need to use `telnet` or a higher-level tool such as cURL to check connectivity to a service.
Individual pods may still be reachable by `ping`, depending on your network configuration.

###### Warning

Firewalls and routing software are aware of ICMP packets
and can be configured to filter or route specific ICMP packets.
It is common, but not guaranteed (or necessarily advisable), to have permissive rules for ICMP packets.
Some network administrators, network software, or cloud providers will allow ICMP packets by default.

The basic use of `ping` is simply `ping <address>`.
The address can be an IP address or a domain.
`ping` will send a packet, wait,
and report the status of that request when a response or timeout happens.

By default, `ping` will send packets forever,
and must be manually stopped (e.g., with Ctrl-C).
`-c <count>` will make `ping` perform a fixed number
before shutting down.
On shutdown, `ping` also prints a summary:

```bash
$ ping -c 2 k8s.io
PING k8s.io (34.107.204.206): 56 data bytes
bytes from 34.107.204.206: icmp_seq=0 ttl=117 time=12.665 ms
bytes from 34.107.204.206: icmp_seq=1 ttl=117 time=12.403 ms

--- k8s.io ping statistics ---
packets transmitted, 2 packets received, 0.0% packet loss
round-trip min/avg/max/stddev = 12.403/12.534/12.665/0.131 ms
```

[Table 2-13](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch02.html#useful_ping_options) shows common `ping` options.

| Option | Description |
| --- | --- |
| -c <count> | Sends the specified number of packets. Exits after the final packet is received or times out. |
| -i <seconds> | Sets the wait interval between sending packets. Defaults to 1 second. Extremely low values are not recommended, as `ping` can flood the network. |
| -o | Exit after receiving 1 packet. Equivalent to `-c 1`. |
| -S <source address> | Uses the specified source address for the packet. |
| -W <milliseconds> | Sets the wait interval to receive a packet. If `ping` receives the packet later than the wait time, it will still count toward the final summary. |

## traceroute

`traceroute` shows the network route taken from one host to another. This allows users to easily validate and debug the
route taken (or where routing fails) from one machine to another.

`traceroute` sends packets with specific IP time-to-live values.
Recall from [Chapter 1](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch01.html#networking_introduction) that each host that handles a packet decrements the time-to-live (TTL) value on packets by 1,
therefore limiting the number of hosts that a request can be handled by.
When a host receives a packet
and decrements the TTL to 0, it sends a `TIME_EXCEEDED` packet
and discards the original packet.
The `TIME_EXCEEDED` response packet contains the source address of the machine where the packet timed out.
By starting with a TTL of 1 and raising the TTL by 1 for each packet,
`traceroute` is able to get a response from each host along the route to the destination address.

`traceroute` displays hosts line by line,
starting with the first external machine.
Each line contains the hostname (if available), IP address, and response time:

```
$traceroute k8s.io
traceroute to k8s.io (34.107.204.206), 64 hops max, 52 byte packets
router (10.0.0.1)  8.061 ms  2.273 ms  1.576 ms
192.168.1.254 (192.168.1.254)  2.037 ms  1.856 ms  1.835 ms
adsl-71-145-208-1.dsl.austtx.sbcglobal.net (71.145.208.1)
4.675 ms  7.179 ms  9.930 ms
* * *
12.122.149.186 (12.122.149.186)  20.272 ms  8.142 ms  8.046 ms
sffca22crs.ip.att.net (12.122.3.70)  14.715 ms  8.257 ms  12.038 ms
12.122.163.61 (12.122.163.61)  5.057 ms  4.963 ms  5.004 ms
12.255.10.236 (12.255.10.236)  5.560 ms
    12.255.10.238 (12.255.10.238)  6.396 ms
    12.255.10.236 (12.255.10.236)  5.729 ms
* * *
206.204.107.34.bc.googleusercontent.com (34.107.204.206)
64.473 ms  10.008 ms  9.321 ms
```

If `traceroute` receives no response from a given hop before timing out,
it prints a ***.
Some hosts may refuse to send a `TIME_EXCEEDED` packet,
or a firewall along the way may prevent successful delivery.

[Table 2-14](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch02.html#useful_traceroute_options) shows common `traceroute` options.

| Option | Syntax | Description |
| --- | --- | --- |
| First TTL | `-f <TTL>`, `-M <TTL>` | Set the starting IP TTL (default value: 1). Setting the TTL to `n` will cause <br>`traceroute` to not report the first `n-1` hosts en route to the destination. |
| Max TTL | `-m <TTL>` | Set the maximum TTL, i.e., the maximum number of hosts that `traceroute` will attempt to route through. |
| Protocol | `-P <protocol>` | Send packets of the specified protocol (TCP, UDP, ICMP, and sometimes other options). UDP is default. |
| Source address | `-s <address>` | Specify the source IP address of outgoing packets. |
| Wait | `-w <seconds>` | Set the time to wait for a probe response. |

## dig

`dig` is a DNS lookup tool.
You can use it to make DNS queries from the command line
and display the results.

The general form of a `dig` command is `dig [options] <domain>`.
By default, `dig` will display the CNAME, A, and AAAA records:

```bash
$ dig kubernetes.io

; <<>> DiG 9.10.6 <<>> kubernetes.io
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 51818
;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 1452
;; QUESTION SECTION:
;kubernetes.io.			IN	A

;; ANSWER SECTION:
kubernetes.io.		960	IN	A	147.75.40.148

;; Query time: 12 msec
;; SERVER: 2600:1700:2800:7d4f:6238:e0ff:fe08:6a7b#53
(2600:1700:2800:7d4f:6238:e0ff:fe08:6a7b)
;; WHEN: Mon Jul 06 00:10:35 PDT 2020
;; MSG SIZE  rcvd: 71
```

To display a particular type of DNS record, run `dig <domain> <type>` (or `dig -t <type> <domain>`).
This is overwhelmingly the main use case for `dig`:

```bash
$ dig kubernetes.io TXT

; <<>> DiG 9.10.6 <<>> -t TXT kubernetes.io
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 16443
;; flags: qr rd ra; QUERY: 1, ANSWER: 2, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 512
;; QUESTION SECTION:
;kubernetes.io.			IN	TXT

;; ANSWER SECTION:
kubernetes.io.		3599	IN	TXT
"v=spf1 include:_spf.google.com ~all"
kubernetes.io.		3599	IN	TXT
"google-site-verification=oPORCoq9XU6CmaR7G_bV00CLmEz-wLGOL7SXpeEuTt8"

;; Query time: 49 msec
;; SERVER: 2600:1700:2800:7d4f:6238:e0ff:fe08:6a7b#53
(2600:1700:2800:7d4f:6238:e0ff:fe08:6a7b)
;; WHEN: Sat Aug 08 18:11:48 PDT 2020
;; MSG SIZE  rcvd: 171
```

[Table 2-15](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch02.html#useful_dig_options) shows common `dig` options.

| Option | Syntax | Description |
| --- | --- | --- |
| IPv4 | `-4` | Use IPv4 only. |
| IPv6 | `-6` | Use IPv6 only. |
| Address | `-b <address>[#<port>]` | Specify the address to make a DNS query to. Port can optionally be included, preceded by *#*. |
| Port | `-p <port>` | Specify the port to query, in case DNS is exposed on a nonstandard port. The default is 53, the DNS standard. |
| Domain | `-q <domain>` | The domain name to query. The domain name is usually specified as a positional argument. |
| Record Type | `-t <type>` | The DNS record type to query. The record type can alternatively be specified as a positional argument. |

## telnet

`telnet` is both a network protocol and a tool for using said protocol.
`telnet` was once used for remote login,
in a manner similar to SSH.
SSH has become dominant due to having better security,
but `telnet` is still extremely useful for debugging servers that use a text-based protocol.
For example, with `telnet`,
you can connect to an HTTP/1 server and manually make requests against it.

The basic syntax of `telnet` is `telnet <address> <port>`.
This establishes a connection and provides an interactive command-line interface.
Pressing Enter twice will send a command,
which easily allows multiline commands to be written.
Press Ctrl-J to exit the session:

```bash
$ telnet kubernetes.io
Trying 147.75.40.148...
Connected to kubernetes.io.
Escape character is '^]'.
> HEAD / HTTP/1.1
> Host: kubernetes.io
>
HTTP/1.1 301 Moved Permanently
Cache-Control: public, max-age=0, must-revalidate
Content-Length: 0
Content-Type: text/plain
Date: Thu, 30 Jul 2020 01:23:53 GMT
Location: https://kubernetes.io/
Age: 2
Connection: keep-alive
Server: Netlify
X-NF-Request-ID: a48579f7-a045-4f13-af1a-eeaa69a81b2f-23395499
```

To make full use of `telnet`, you will need to understand how the application protocol that you are using works. `telnet`
is a classic tool to debug servers running HTTP, HTTPS, POP3, IMAP, and so on.

## nmap

`nmap` is a port scanner,
which allows you to explore and examine services on your
network.

The general syntax of `nmap` is `nmap [options] <target>`,
where target is a domain, IP address, or IP CIDR.
`nmap`’s default options will give a fast and brief summary of open ports on a host:

```bash
$ nmap 1.2.3.4
Starting Nmap 7.80 ( https://nmap.org ) at 2020-07-29 20:14 PDT
Nmap scan report for my-host (1.2.3.4)
Host is up (0.011s latency).
Not shown: 997 closed ports
PORT     STATE SERVICE
22/tcp   open  ssh
3000/tcp open  ppp
5432/tcp open  postgresql

Nmap done: 1 IP address (1 host up) scanned in 0.45 seconds
```

In the previous example, `nmap` detects three open ports
and guesses which service is running on each port.

###### Tip

Because `nmap` can quickly show you which services are accessible from a remote machine,
it can be a quick and easy way to spot services that should *not* be exposed.
`nmap` is a favorite tool for attackers for this reason.

`nmap` has a dizzying number of options,
which change the scan behavior
and level of detail provided.
As with other commands,
we will summarize some key options,
but we *highly* recommend reading `nmap`’s help/man pages.

[Table 2-16](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch02.html#useful_nmap_options) shows common `nmap` options.

| Option | Syntax | Description |
| --- | --- | --- |
| Additional detection | `-A` | Enable OS detection, version detection, and more. |
| Decrease verbosity | `-d` | Decrease the command verbosity. Using multiple `d`’s (e.g., `-dd`) increases the effect. |
| Increase verbosity | `-v` | Increase the command verbosity. Using multiple `v`’s (e.g., `-vv`) increases the effect. |

## netstat

`netstat` can display a wide range of information about a machine’s network stack and connections:

```bash
$ netstat
Active internet connections (w/o servers)
Proto Recv-Q Send-Q Local Address           Foreign Address         State
tcp        0    164 my-host:ssh             laptop:50113            ESTABLISHED
tcp        0      0 my-host:50051           example-host:48760      ESTABLISHED
tcp6       0      0 2600:1700:2800:7d:54310 2600:1901:0:bae2::https TIME_WAIT
udp6       0      0 localhost:38125         localhost:38125         ESTABLISHED
Active UNIX domain sockets (w/o servers)
Proto RefCnt Flags   Type    State  I-Node  Path
unix  13     [ ]     DGRAM          8451    /run/systemd/journal/dev-log
unix  2      [ ]     DGRAM          8463    /run/systemd/journal/syslog
[Cut for brevity]
```

Invoking `netstat` with no additional arguments will display all *connected* sockets on the machine.
In our example, we see three TCP sockets,
one UDP socket, and a
multitude of UNIX sockets.
The output includes the address (IP address and port) on both sides of a connection.

We can use the `-a` flag to show all connections or `-l` to show only listening
connections:

```bash
$ netstat -a
Active internet connections (servers and established)
Proto Recv-Q Send-Q Local Address           Foreign Address      State
tcp        0      0 0.0.0.0:ssh             0.0.0.0:*            LISTEN
tcp        0      0 0.0.0.0:postgresql      0.0.0.0:*            LISTEN
tcp        0    172 my-host:ssh             laptop:50113         ESTABLISHED
[Content cut]
```

A common use of `netstat` is to check which process is listening on a specific port.
To do that, we run `sudo netstat -lp` -
`l` for “listening” and `p` for “program.”
`sudo` may be necessary for `netstat` to view all program information.
The output for `-l` shows which address a service is listening on (e.g., `0.0.0.0` or `127.0.0.1`).

We can use simple tools like `grep` to get a clear output from `netstat`
when we are looking for a specific result:

```bash
$ sudo netstat -lp | grep 3000
tcp6     0    0 [::]:3000       [::]:*       LISTEN     613/grafana-server
```

[Table 2-17](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch02.html#useful_netstat_commands) shows common `netstat` options.

| Option | Syntax | Description |
| --- | --- | --- |
| Show all sockets | `netstat -a` | Shows all sockets, not only open connections. |
| Show statistics | `netstat -s` | Shows networking statistics. By default, `netstat` shows stats from all protocols. |
| Show listening sockets | `netstat -l` | Shows sockets that are listening. This is an easy way to find running services. |
| TCP | `netstat -t` | The `-t` flag shows only TCP data. It can be used with other flags, e.g., `-lt` (show sockets listening with TCP). |
| UDP | `netstat -u` | The `-u` flag shows only UDP data. It can be used with other flags, e.g., `-lu` (show sockets listening with UDP). |

## netcat

`netcat` is a multipurpose tool for making connections, sending data, or listening on a socket.
It can be helpful as a way to “manually” run a server or client
to inspect what happens in greater detail.
`netcat` is arguably similar to `telnet` in this regard,
though `netcat` is capable of many more things.

###### Tip

`nc` is an alias for `netcat` on most systems.

`netcat` can connect to a server when invoked as `netcat <address> <port>`.
`netcat` has an interactive `stdin`, which allows you to
manually type data or pipe data to `netcat`.
It’s very `telnet`-esque so far:

```bash
$ echo -e "GET / HTTP/1.1\nHost: localhost\n" > cmd
$ nc localhost 80 < cmd
HTTP/1.1 302 Found
Cache-Control: no-cache
Content-Type: text/html; charset=utf-8
[Content cut]
```

## Openssl

The OpenSSL technology powers a substantial chunk of the world’s HTTPS connections.
Most heavy lifting with OpenSSL is done with language bindings,
but it also has a CLI for operational tasks and debugging.
`openssl` can do things such as creating keys and certificates,
signing certificates, and,
most relevant to us, testing TLS/SSL connections.
Many other tools,
including ones outlined in this chapter,
can test TLS/SSL connections.
However, `openssl` stands out for its feature-richness and level of detail.

Commands usually take the form `openssl [sub-command] [arguments] [options]`.
`openssl` has a vast number of subcommands (for example,
`openssl rand` allows you to generate pseudo random data).
The `list` subcommand allows you to list capabilities,
with some search options
(e.g., `openssl list --commands` for commands).
To learn more about individual sub commands,
you can check `openssl <subcommand> --help`
or its man page (`man openssl-<subcommand>` or just `man <subcommand>`).

`openssl s_client -connect` will connect to a server and display detailed information about the server’s certificate.
Here is the default invocation:

```
openssl s_client -connect k8s.io:443
CONNECTED(00000003)
depth=2 O = Digital Signature Trust Co., CN = DST Root CA X3
verify return:1
depth=1 C = US, O = Let's Encrypt, CN = Let's Encrypt Authority X3
verify return:1
depth=0 CN = k8s.io
verify return:1
---
Certificate chain
0 s:CN = k8s.io
i:C = US, O = Let's Encrypt, CN = Let's Encrypt Authority X3
1 s:C = US, O = Let's Encrypt, CN = Let's Encrypt Authority X3
i:O = Digital Signature Trust Co., CN = DST Root CA X3
---
Server certificate
-----BEGIN CERTIFICATE-----
[Content cut]
-----END CERTIFICATE-----
subject=CN = k8s.io

issuer=C = US, O = Let's Encrypt, CN = Let's Encrypt Authority X3

---
No client certificate CA names sent
Peer signing digest: SHA256
Peer signature type: RSA-PSS
Server Temp Key: X25519, 253 bits
---
SSL handshake has read 3915 bytes and written 378 bytes
Verification: OK
---
New, TLSv1.3, Cipher is TLS_AES_256_GCM_SHA384
Server public key is 2048 bit
Secure Renegotiation IS NOT supported
Compression: NONE
Expansion: NONE
No ALPN negotiated
Early data was not sent
Verify return code: 0 (ok)
---
```

If you are using a self-signed CA,
you can use `-CAfile <path>` to use that CA.
This will allow you to establish and verify connections against a self-signed certificate.

## cURL

cURL is a data transfer tool that supports multiple protocols,
notably HTTP and HTTPS.

###### Tip

`wget` is a similar tool to the command `curl`.
Some distros or administrators may install it instead of `curl`.

cURL commands are of the form `curl [options] <URL>`. cURL prints the URL’s contents and sometimes cURL-specific
messages to `stdout`. The default behavior is to make an HTTP GET request:

```bash
$ curl example.org
<!doctype html>
<html>
<head>
    <title>Example Domain</title>
# Truncated
```

By default, cURL does not follow redirects,
such as HTTP 301s or protocol upgrades.
The `-L` flag (or `--location`) will enable redirect following:

```bash
$ curl kubernetes.io
Redirecting to https://kubernetes.io

$ curl -L kubernetes.io
<!doctype html><html lang=en class=no-js><head>
# Truncated
```

Use the `-X` option to perform a specific HTTP verb;
e.g., use `curl -X DELETE foo/bar` to make a `DELETE` request.

You can supply data (for a POST, PUT, etc.) in a few ways:

-

URL encoded: `-d "key1=value1&key2=value2"`

-

JSON: `-d '{"key1":"value1", "key2":"value2"}'`

-

As a file in either format: `-d @data.txt`

The `-H` option adds an explicit header,
although basic headers such as `Content-Type` are added automatically:

`-H "Content-Type: application/x-www-form-urlencoded"`

Here are some examples:

```bash
$ curl -d "key1=value1" -X PUT localhost:8080

$ curl -H "X-App-Auth: xyz" -d "key1=value1&key2=value2"
-X POST https://localhost:8080/demo
```

###### Tip

cURL can be of some help when debugging TLS issues,
but more specialized tools such as `openssl` may be more helpful.

cURL can help diagnose TLS issues.
Just like a reputable browser,
cURL validates the certificate chain returned by HTTP sites
and checks against the host’s CA certs:

```bash
$ curl https://expired-tls-site
curl: (60) SSL certificate problem: certificate has expired
More details here: https://curl.haxx.se/docs/sslcerts.html

curl failed to verify the legitimacy of the server and therefore could not
establish a secure connection to it. To learn more about this situation and
how to fix it, please visit the web page mentioned above.
```

Like many programs, cURL has a verbose flag, `-v`,
which will print more information about the request and response.
This is extremely valuable when debugging a layer 7 protocol such as HTTP:

```bash
$ curl https://expired-tls-site -v
*   Trying 1.2.3.4...
* TCP_NODELAY set
* Connected to expired-tls-site (1.2.3.4) port 443 (#0)
* ALPN, offering h2
* ALPN, offering http/1.1
* successfully set certificate verify locations:
*   CAfile: /etc/ssl/cert.pem
  CApath: none
* TLSv1.2 (OUT), TLS handshake, Client hello (1):
* TLSv1.2 (IN), TLS handshake, Server hello (2):
* TLSv1.2 (IN), TLS handshake, Certificate (11):
* TLSv1.2 (OUT), TLS alert, certificate expired (557):
* SSL certificate problem: certificate has expired
* Closing connection 0
curl: (60) SSL certificate problem: certificate has expired
More details here: https://curl.haxx.se/docs/sslcerts.html

# Truncated
```

cURL has many additional features that we have not covered, such as the ability to use timeouts, custom CA certs,
custom DNS, and so on.

# Conclusion

This chapter has provided you with a whirlwind tour of networking in Linux. We focused primarily on concepts that are
required to understand Kubernetes’ implementation, cluster setup constraints, and debugging Kubernetes-related
networking problems (in workloads on Kubernetes, or Kubernetes itself). This chapter was by no means exhaustive, and
you may find it valuable to learn more.

Next, we will start to look at containers in Linux and how containers interact with the network.

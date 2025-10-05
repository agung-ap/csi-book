## Chapter 5. Security Services

This chapter describes important security services required in cloud and data center networks to combat the continuously evolving security threats and to comply with regulatory issues.

Security threats can be external (coming from the network) or internal (from compromised applications). Today’s solutions either assume that application/hypervisor/OS can’t be compromised, or network-based security models consider the network trusted and locate the enforcement points only at the periphery.

Both approaches need scrutiny; for example, in the wake of Spectre and Meltdown [[1](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch05.xhtml#ch05ref1)], we can’t trust a compromised host, OS or hypervisor. Similarly, it is crucial to limit the ability to move laterally (in East-West direction) to prevent damage in case of a compromise.

Initially, security architectures were based on the idea of a “perimeter” and of securing the “North-South” traffic entering and exiting the data center (see [Figure 5-1](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch05.xhtml#ch05fig1)). The East-West traffic inside the datacenter was trusted, considered secure, and immune from attacks. In other words, the “bad guys” were outside the perimeter, and the “good guys” were inside.

![An illustration depicts the security architectures of the north to south versus east to west traffic.](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9780136624226/files/graphics/05fig01.jpg)

**FIGURE 5-1** North-South versus East-West

In the figure, several servers (numbered 1 to n) are linearly arranged and connected to the internet through a centralized firewall. The traffic among the linearly arranged servers is labeled "east-west traffic." The network traffic between the centralized firewall and the servers is labeled "north-south" traffic.

Over time this model has shown its limitations because the perimeter has become much more fragmented with the necessity of having B2B (business to business) connections to support remote offices and remote and mobile workers.

The virtual private network (VPN) technology has helped tremendously (see [section 5.12](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch05.xhtml#ch05lev1sec12)), but the attacks have evolved, requiring increased attention to secure the East-West traffic inside the data center.

According to the 2017 Phishing Trends Report of Keepnet Labs [[2](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch05.xhtml#ch05ref2)] “Over 91% of system breaches have been caused by a phishing attack.” Phishing attacks are a type of attack in which someone inside the secure perimeter clicks on a bogus link received by email that, as a result, compromises a system inside the boundary.

A solution to this problem is composed of a combination of security services including firewall, microsegmentation, encryption, key management, and VPNs.

### 5.1 Distributed Firewalls

Distributed firewalls are becoming a necessity due to the multitenancy requirement and the change in the type of security attacks described earlier. When a system inside the firewall is compromised, traditional security measures based on encryption, while in general a good idea, may not help because the malware can spread through encrypted channels.

Containment of infected systems is the next line of defense, and it is achieved through firewalls. For considerations similar to the one discussed in the NAT section (see [section 4.4](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch04.xhtml#ch04lev1sec4)), firewalls also need to be stateful; for example, the traffic flowing in one direction may create a state to permit traffic in the opposite direction that would otherwise be dropped.

Created for perimeter protection, discrete firewalls can also be used to protect and separate the East-West traffic, typically in combination with VLANs. The technique is called trombone or tromboning (see [section 2.7.1](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch02.xhtml#ch02lev2sec7_1)), and it consists of sending the traffic that needs to go from one VLAN to another through a firewall. Of course, the centralized firewall becomes a performance bottleneck, and all the routing and forwarding of packets inside the datacenter/cloud becomes suboptimal.

A better solution is to distribute the firewall functionality as closely as possible to the final user in a distributed-service node; for example, by incorporating the firewall functionality in a ToR/leaf switch or in an SR-IOV capable NIC (see [section 8.4](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch08.xhtml#ch08lev1sec4)). Both solutions decouple routing and forwarding from firewalling, remove the performance bottlenecks, and offer lower latency and jitter.

### 5.2 Microsegmentation

Microsegmentation is a technique that is built on the concept of distributed firewalls by dividing the datacenter into security segments associated with workloads that, by default, cannot talk to each other. This restricts the ability of an attacker that has penetrated the North-South firewall to move in the East-West direction freely. These security segments are also called security zones, and they decrease the network attack surface by preventing attacker movement from one compromised application to another. [Figure 5-2](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch05.xhtml#ch05fig2) shows a pictorial representation of microsegmentation.

![A figure illustrates the concept of microsegmentation.](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9780136624226/files/graphics/05fig02.jpg)

**FIGURE 5-2** Microsegmentation

A network cloud is distributed with many microsegments. Each of the microsegment is connected to the segments of several distributed firewalls. The first microsegment is connected to the segment A1 of first and last distributed firewalls. The second microsegment is connected to the segment A2 of the first and second distributed firewall. The third microsegment is connected to segment A3 and A1 of the second and last distributed firewalls. The transport of data is bidirectional.

Microsegmentation associates fine-grained security policies to datacenter applications, which are enforced by distributed firewalls. These policies are not restricted to the IP addresses or VLAN tags of the underlying network, and they can act on the information contained in the overlay network packets, being specific to virtual machines or containers.

The concept of “zero-trust” is also a part of microsegmentation: “never trust, always verify.” This means that only the necessary connections are enabled, blocking anything else by default. For example, it is possible to create a segment that contains all the IoT (Internet of Things) devices of a particular laboratory and create a policy that allows them to talk to each other and a gateway. If an IoT device moves, its security policies follow it.

The term *zero-trust security* in this context implies that having network access doesn’t mean access to all applications in the network. It is an extension of the white list concept: don’t allow anything unless it’s asked for.

Low throughput and complex policy management are two significant operational barriers to microsegmentation. Low throughput is the result of tromboning into centralized firewalls. Even if these firewalls are upgraded (an operation that could be extremely expensive), they still create a performance bottleneck resulting in high latency, jitter, and potentially packet loss. The solution to this issue is a distributed firewall architecture, with firewalls located as closely as possible to the applications. Once again, these firewalls need to be stateful for the reasons explained in [Chapter 4](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch04.xhtml#ch04), “[Network Virtualization Services](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch04.xhtml#ch04)” (for example, NAT, IP masquerading). Any time there is state, there is a potential scaling problem: How fast can we update the flow database (connections per second)? How many entries can we support? A distributed solution naturally scales with the size of the problem. This also implies that firewalls for microsegmentation cannot be discrete appliances. However, distributing the firewalls very granularly also creates a policy management issue that brings us to the next point.

Policy management complexity increases exponentially with the number of workloads, the number of firewalls, and the need to support mobility in rapidly changing environments. Manually programming the firewalls for microsegmentation is, at best, impractical, and, at worst, impossible. Microsegmentation requires a capable policy manager where security policies are formulated independently of network topology or enforcement point location. This policy manager is in charge of communicating with all the distributed firewalls through a programmatic API such as a REST API or gRPC. This API is used to pass the appropriate subset of policies to each firewall and to modify them as users and applications move or change their policies.

For more information, we recommend the book *Micro-Segmentation For Dummies*, where author Matt De Vincentis analyzes in greater detail the advantages and limitations of microsegmentation [[3](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch05.xhtml#ch05ref3)].

### 5.3 TLS Everywhere

Transport Layer Security (TLS) is a modern security standard to secure communications inside and outside the datacenter. Initially developed to secure web traffic, TLS can be used to secure any traffic. [Sections 5.11.2](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch05.xhtml#ch05lev2sec11_2) and [5.11.3](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch05.xhtml#ch05lev2sec11_3) discuss the encapsulation aspect of TLS; here the focus is on its security aspects.

Before starting our discussion, let’s understand the differences between HTTP, HTTPS, SSL, and TLS.

- **HTTP** (Hypertext Transfer Protocol) is an application layer protocol used to communicate between two machines and mostly used for web traffic. HTTP in itself does not provide any security. Original HTTP suffered from some performance issues, but the latest HTTP/2 is very efficient. Usually, web servers bind HTTP on TCP port 80.

- **HTTPS** (HTTP Secure) is a secure version of HTTP. Security is added by running HTTP on top of SSL or TLS. For this reason, it is also referred to as HTTP over SSL or HTTP over TLS. Usually, web servers bind HTTPS to TCP port 443.

- **SSL** (Secure Sockets Layer) is a cryptographic protocol that provides authentication and data encryption. SSL 2.0 was introduced in 1995 and evolved into SSL 3.0. All SSL versions have been deprecated due to security flaws.

- **TLS** (Transport Layer Security) is a successor to SSL. TLS 1.1 was introduced in 2006 and is now deprecated. The current versions of TLS are 1.2 (launched in 2008) [[4](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch05.xhtml#ch05ref4)] and 1.3 (introduced in 2018) [[5](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch05.xhtml#ch05ref5)]. [Figure 5-3](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch05.xhtml#ch05fig3) shows the TLS protocol stack.

![Architecture of the TLS protocol stack is depicted.](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9780136624226/files/graphics/05fig03.jpg)

**FIGURE 5-3** TLS Protocol Stack

The TLS protocol stack consists of four layers. The first layer consists of four fields labeled SSL/TLS handshake, SSL/TLS change cipher spec, SSL/TLS alert, and HTTP. The second layer is labeled SSL/TLS record protocol. The third layer is labeled TCP. The fourth layer is labeled IP.

When TLS is implemented with perfect forward secrecy (PFS), it provides a good security solution. PFS generates a unique key for every user-initiated session to protect against future compromises of secret keys or passwords.

The simple reason that all major companies have moved the transport of their web pages from HTTP to HTTPS to improve security makes TLS a crucial protocol, but TLS can be used for other applications as well; for example, in a new type of virtual private network (VPN).

Proper implementations of TLS require many different pieces:

- Symmetric encryption used to protect user data

- Asymmetric encryption used during session creation

- Digital certificates

- Hashing algorithms

- Secure storage for keys, certificates, and so on

- A mechanism to generate a private key

- An appropriate implementation of TCP, because TLS runs over TCP

The following sections describe these aspects in more detail.

### 5.4 Symmetric Encryption

Symmetric encryption is a type of encryption that uses the same key for encrypting and decrypting the message. The symmetric algorithm universally used is Advanced Encryption Standard (AES) established by the National Institute of Standards and Technology (NIST) in 2001 [[6](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch05.xhtml#ch05ref6)].

AES is a block cipher and can be used with keys of different length, usually 128, 192, or 256 bits. It can also be used in different modes, the most common being GCM (Galois Counter Mode), a hardware-friendly implementation widely used for web traffic; and XTS (“Xor-encrypt-xor”-based, tweaked-codebook mode with ciphertext stealing), widely used to encrypt data-at-rest in storage applications.

Even if AES 128-bit GCM is probably the most commonly used symmetric encryption in TLS, TLS supports other encryption algorithms, including stream ciphers, such as ChaCha20-Poly1305 [[7](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch05.xhtml#ch05ref7)].

Today, symmetric encryption is widely supported in a variety of devices and processors. Moving it to domain-specific hardware still has performance and latency advantages over processors, but the performance gap is much wider in asymmetric encryption, discussed in the next section.

### 5.5 Asymmetric Encryption

Asymmetric encryption, also known as public key cryptography, is a form of encryption in which there are two separate keys, one to encrypt and one to decrypt the message, and it is computationally infeasible to derive one key from the other (the original idea is attributed to Whitfield Diffie and Martin Hellman [[8](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch05.xhtml#ch05ref8)]). The two keys are also referred to as the private and the public key. Anyone who wants to receive messages using asymmetric encryption will generate the two keys, publish the public key, and keep secret the private one. As an example, Linux provides the openssl utility for key generation. The sender will encrypt the message using the public key, and only the owner of the private key will be able to decode the message.

Asymmetric encryption is computationally much heavier than symmetric encryption, and, for this reason, TLS only uses it at the connection setup phase.

TLS 1.2 supported approximately 20 different schemes of key exchange, agreement, and authentication, but TLS 1.3 reduced them to three. They are based on a combination of the original idea from Diffie-Hellman, RSA (Rivest-Shamir-Adleman) [[9](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch05.xhtml#ch05ref9)], and Elliptic Curves [[10](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch05.xhtml#ch05ref10)], [[11](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch05.xhtml#ch05ref11)].

The concept behind RSA is the difficulty of the factorization of the product of two large prime numbers.

An elliptic curve is the set of points that satisfy a specific mathematical equation that looks like y2 = x3 + ax + b. Computing the private key from the public key in elliptic curve requires solving a logarithm problem over finite fields, a very difficult problem. Elliptic curves require a smaller key, compared to RSA, for the same level of security. For example, the NSA recommends using either a 3072-bit RSA key or 256-bit Elliptic Curves key [[12](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch05.xhtml#ch05ref12)] for a security level comparable to a 128-bit AES symmetric key.

Today, CPUs do not support asymmetric encryption adequately and, for this reason, domain-specific hardware provides a significant improvement in TLS connection setup per second.

### 5.6 Digital Certificates

Before encrypting a message with a public key, it is essential to be sure that the public key belongs to the organization we want to send the data to. Certification authorities guarantee ownership of public keys through digital certificates. Besides establishing ownership, a digital certificate also indicates expected usages of that key, expiration date, and other parameters.

### 5.7 Hashing

A cryptographically secure hash is a unidirectional function that is hard to invert and computes a short signature of a much larger number of bits. It is usually applied and appended to a message to verify that the message has not been altered. The hard-to-invert property of the hash function prevents attacks, because it is hard for an adversary to find an alternative message with the same hash. Famous hashing algorithms are MD5, which produces a 128-bit hash value, and SHA, a family of hashing algorithms. MD5 is not considered good enough for security applications, and even SHA-1 (160-bit hash value) is deprecated. The current state of the art is SHA-256 that not only extends the signature to 256-bits but is also a significant redesign compared to SHA-1. Any security solution needs to implement hashing algorithms in hardware for performance reasons.

### 5.8 Secure Key Storage

The security of any solution fundamentally depends on the capability to keep the private keys secret, but at the same time to not lose them.

The well-publicized Spectre, Meltdown, and Zombieload exploits, where data can leak from one CPU process to another, show that the server cannot guarantee security. Therefore, encryption keys need to be stored securely in a dedicated hardware structure named hardware security module (HSM). HSMs are typically certified to the FIPS 140 [[13](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch05.xhtml#ch05ref13)] standard to provide users with independent assurance that the design and implementation of the product and cryptographic algorithms are sound. HSMs can be separate appliances or hardware modules that are integrated into cards or ASICs. HSMs must also be protected against tampering, by either being tamper resistant, tamper evident, or tamper responsive (for example, by being capable of automatically erasing the keys in the case of a tamper attempt).

An HSM may also be capable of generating the keys onboard so that the private keys never leave the HSM.

### 5.9 PUF

The physical unclonable function (PUF) is a hardware structure that serves as a unique identity for a semiconductor device. PUF is used to generate a strong cryptographic key unique to each ASIC. PUF is based on natural variations that occur during semiconductor manufacturing. For example, PUF can create cryptographic keys that are unique to individual smartcards. A special characteristic of PUF is that it is repeatable across power-cycles: It always produces the same key, which therefore does not need to be saved on nonvolatile memory. Although various types of PUFs exist today, RAM-based PUFs are the most commonly used in large ASICs [[14](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch05.xhtml#ch05ref14)] [[15](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch05.xhtml#ch05ref15)], and they are based on the observation that RAM cells initialize to random but repeatable values at startup time. Previous solutions based on EEPROM or flash memory were much less secure.

### 5.10 TCP/TLS/HTTP Implementation

To provide pervasive encryption in the data center, excellent implementation of TCP, TLS and HTTP are required. The relation among these three protocols is more complex than may appear at first glance.

In HTTP/2 [[16](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch05.xhtml#ch05ref16)] a single TCP connection is shared by multiple HTTP requests and responses. Each request has a unique stream ID that is used to associate the response with the request. Responses and requests are divided into frames and marked with the stream ID. Frames are multiplexed over a single TCP connection. There is no relation between frames and IP packets: A frame may span multiple IP packets, and many frames may be contained in a single IP packet. Add TLS to all this, and you realize that the only way to process HTTPS properly is to terminate TCP, decrypt the TLS, pass the payload to HTTP/2, and let HTTP/2 delineate the frames and reconstruct the streams.

This complexity is not difficult to handle in software for a general-purpose processor, but it can be a challenge when implemented in domain-specific hardware. For example, in the past, there have been several attempts to implement TCP in the NIC with limited success, a practice called TCP offload. TCP in hardware has also been opposed by the software community, in particular by the Linux community.

For domain-specific hardware, implementing a generic TCP termination externally to the server to offload the termination of all TCP flows is not particularly attractive. On the other hand, an example of an interesting application is TCP termination used in conjunction with TLS termination to inspect encrypted traffic flows. It has applications in server load balancing, identification of traffic belonging to a particular user or application, routing different HTTP requests to different servers according to their URLs, and implementing sophisticated IDS (intrusion detection) features.

### 5.11 Secure Tunnels

In [Chapter 2](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch02.xhtml#ch02), “[Network Design](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch02.xhtml#ch02),” we presented multiple encapsulation and overlay schemes to solve addressing issues, layer 2 domain propagation, multicast and broadcast propagation, multiprotocol support, and so on. These schemes do not deal with the privacy of the data. In fact, even when the data undergoes encapsulation, it is still in the clear and can be read by an eavesdropper. This lack of security may be acceptable inside the datacenter, but it is not tolerable when the transmission happens on a public network, in particular on the Internet.

The conventional way to secure tunnels is with the addition of encryption.

#### 5.11.1 IPsec

IPsec is a widely used architecture that has been around since 1995 to secure IP communications [[17](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch05.xhtml#ch05ref17)]. [Figure 5-4](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch05.xhtml#ch05fig4) shows a simplified view of the two encapsulation schemes supported by IPsec: transport mode and tunnel mode.

![A figure shows the encapsulation of IPsec.](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9780136624226/files/graphics/05fig04.jpg)

**FIGURE 5-4** IPsec Encapsulations

The IPsec encapsulation is of two types, known as tunnel mode and transport mode. The tunnel mode has an outer jacket labeled New IP header, attached to the inner jacket labeled IPSEC header, which is attached to a middle coating labeled Original IP header. The original IP header is attached to the inner core labeled Data. The encrypted part is the original IP header and Data. The transport mode has an outer jacket labeled Original IP header connected to the middle coating labeled IPSEC header, which is attached to an inner core labeled Data. The encrypted portion is the data only.

The IPsec header may provide just data authentication (the data is still in the clear, but the sender cryptographically signs it) or authentication plus encryption (an eavesdropper cannot decode the information).

In transport mode, the original IP header is used to route the packet in the network, and the IPsec header protects only the data part of the packet. In tunnel mode, the whole packet (including the IP header) is protected by the IPsec header, and a new IP header is added to route the packet through the network.

In both cases, the presence of the IPsec header is identified by the value 51 (for encryption) or 50 (for authentication only) in the protocol type of the IP header; there is no TCP or UDP header after the IP header. For this reason, IPsec is not a modern encapsulation scheme (see [section 2.3.3](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch02.xhtml#ch02lev2sec3_3)) because routers cannot use the TCP/UDP header to load balance the IPsec traffic across multiple ECMP links. Sentences such as “lack of overlay entropy” or “lack of network entropy” are often used to describe this phenomenon, where the term entropy is used as a measure of the randomness of the information content.

The next two secure tunneling schemes (TLS and DTLS) are more modern and provide overlay entropy, although IPsec remains an active player in the VPN arena.

#### 5.11.2 TLS

Transport Layer Security (TLS) [[18](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch05.xhtml#ch05ref18)] is the evolution of Secure Sockets Layer (SSL), and it is a vital component of any modern security architecture. The broad adoption and large install base of SSL and TLS is attributed to the use of these protocols to secure the traffic on the Web. Used to protect the most sensitive data, TLS has been scrutinized in all of its details, an essential factor in hardening its implementations. TLS is also a standard with a high degree of interoperability among different implementations, and it supports all the latest symmetric and asymmetric encryption schemes.

Typically, TLS is implemented on top of TCP for HTTPS-based traffic with an encapsulation like the one shown in [Figure 5-5](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch05.xhtml#ch05fig5).

![A figure shows the encapsulation of TLS. The TLS encapsulation has an outer jacket labeled IP/TCP, which is connected to the middle coating labeled TLS. This is attached to an inner core labeled Application data. The encrypted part is application data.](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9780136624226/files/graphics/05fig05.jpg)

**FIGURE 5-5** TLS Encapsulation

Because the external encapsulation of TLS is IP/TCP, TLS provides network entropy, allowing load balancing of TLS traffic in the core of the network, based on classical 5-tuples, a feature that is missing in IPsec. The same applies to DTLS (see the next section) where an IP/UDP header replaces the IP/TCP header.

TLS traffic suffers from reduced performance if the data that is encapsulated is another TCP packet, as discussed in [section 2.3.3](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch02.xhtml#ch02lev2sec3_3).

To avoid this double TCP, it is theoretically possible to terminate the unencrypted TCP session, add the TLS header, and then regenerate a new TCP session and do the opposite in the reverse direction. This operation, also called “proxy,” requires terminating two TCP sessions, which is computationally expensive and may require a significant amount of buffering. Moreover, the processing cannot be done on a packet by packet basis because the TCP and TLS application data needs reconstruction before being re-encapsulated. Web traffic load balancers support the proxy feature by terminating the HTTPS sessions coming from the Internet (encrypted with TLS), decrypting them, and generating clear-text HTTP sessions toward the internal web servers. This scheme works well for web traffic, but it is not used for VPN because DTLS offers a better solution.

#### 5.11.3 DTLS

Datagram TLS (DTLS) [[19](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch05.xhtml#ch05ref19)], [[20](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch05.xhtml#ch05ref20)] is particularly desirable for tunneling schemes because it avoids running TCP over TCP, and there is no need for TCP terminations at tunnel endpoints. DTLS not only allows TCP to run end-to-end but, when combined with VXLAN, it also supports any L2 protocol inside VXLAN, while providing the same security as TLS. DTLS works packet by packet; it is fast, low latency, and low jitter. [Figure 5-6](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch05.xhtml#ch05fig6) shows the DTLS encapsulation.

![A figure shows the encapsulation of DTLS.](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9780136624226/files/graphics/05fig06.jpg)

**FIGURE 5-6** DTLS Encapsulation

The DTLS encapsulation has an outer jacket labeled IP/UDP is attached to the inner jacket labeled DTLS and that is attached to a middle coating labeled VXLAN. The VXLAN is attached to the inner core labeled Any protocol. The encrypted information is the VXLAN and Any protocol.

DTLS was invented because TLS cannot be used directly in a UDP environment because packets may be lost or reordered. TLS has no internal facilities to handle this kind of unreliability because it relies on TCP. DTLS makes only minimal changes to TLS to fix this problem. DTLS uses a simple retransmission timer to handle packet loss and a sequence number to handle packet reordering.

### 5.12 VPNs

The term *virtual private network* (VPN) is a very generic one, and it is a common umbrella for multiple technologies. In general, VPN network technologies can be classified according to three main parameters:

- Type of encapsulation used

- Presence or absence of encryption

- Control protocol used to create tunnels, if any

In [section 2.3](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch02.xhtml#ch02lev1sec3), we discussed overlay networks and covered several encapsulation schemes. In this section, we focus on the security aspect of VPNs and therefore on the kind of encryption used.

There are a few applications of VPNs that do not use encryption, two examples being EVPNs and MPLS VPNs.

EVPNs (described in [section 2.3.4](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch02.xhtml#ch02lev2sec3_4)) are usually confined inside a datacenter where eavesdropping is considered unlikely due to the need to physically access the datacenter and the difficulty of tapping fiber links.

MPLS VPNs were one of the first ways for Telcos to provide virtual circuits to connect different sites of the same company. The trust to guarantee the privacy of the transmission was placed on the Telco. MPLS VPNs have been declining in popularity, mostly due to their cost, and replaced by VPNs that use the Internet to create the virtual circuits (see [Figure 5-7](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch05.xhtml#ch05fig7)).

![Illustration of VPN is shown. Different network clouds: regional offices and remote or roaming users are connected to the head office's network cloud through the internet.](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9780136624226/files/graphics/05fig07.jpg)

**FIGURE 5-7** Example of a VPN

In this case, the use of encryption is mandatory, especially when Wi-Fi is present. With a significant part of the workforce either telecommuting, working from home, or merely using their cellular devices, encrypted VPNs have become mandatory. One can reasonably ask, “Why do we need encrypted VPNs if we have HTTPS?” The answer is, “To protect all the traffic, not just the web.” In the case of HTTPS, even if the pages are encrypted, the IP addresses of the sites are not. There is a lot that a hacker can learn about you and your business just by looking at your traffic by eavesdropping at a coffee shop Wi-Fi. If in doubt, read *The Art of Invisibility* [[21](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch05.xhtml#ch05ref21)] for some eye-opening information.

[Figure 5-7](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch05.xhtml#ch05fig7) shows both site-to-site or host-to-site VPNs.

Site-to-site VPNs are a convenient way to interconnect multiple offices by using the Internet, often in conjunction with a technology such as SD-WAN (described in [section 4.2.2](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch04.xhtml#ch04lev2sec2_2)). Historically, site-to-site VPNs used the IPsec protocol [[22](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch05.xhtml#ch05ref22)], but there is a trend to shift them toward TLS. These employ the same TLS security architecture used by HTTPS; in this case, to encrypt all your traffic. Usually, site- to-site VPNs are data intensive due to the need to transfer and back up data from one site to another, and therefore they often require hardware acceleration for encryption. For example, this is the case in a hybrid cloud where different parts of the cloud are interconnected using site-to-site VPNs, normally IPsec-based.

The host-to-site VPNs usually adopt a software client on the host (often a laptop, tablet, or phone in today’s world) and hardware-based termination on the network side, generally in the form of a VPN gateway. In this kind of VPN, OpenVPN [[23](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch05.xhtml#ch05ref23)] is becoming the dominant standard, replacing the two old approaches PPTP and L2TP/IPsec.

OpenVPN is an open-source project, published under the GPL license and offered as a product by several different commercial companies. OpenVPN employs TLS to create the session, which, once initialized and authenticated, is used to exchange random key material for the bidirectional cipher and HMAC (Hash-based Message Authentication Code) keys used to secure the actual tunnel.

OpenVPN is NAT and firewall friendly, an important characteristic to use it on public Wi-Fi. It can be configured to use both TCP and UDP and is often set to use TCP on port 443 so that its traffic is indistinguishable from HTTPS traffic, and therefore not deliberately blocked.

OpenVPN heavily reuses OpenSSL code and has a vast code footprint.

Wireguard [[24](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch05.xhtml#ch05ref24)] is emerging as an alternative to OpenVPN. It has the goal of having a tiny code base, being easily understandable, being much more performant than OpenVPN, and using state-of-the-art encryption algorithms, such as ChaCha20 and Poly1305, which are more efficient and thus mobile friendly. There is a high hope that Wireguard will become part of Linux Kernel 5.0. Linus Torvalds himself wrote [[25](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch05.xhtml#ch05ref25)]: “*... Can I just once again state my love for it and hope it gets merged soon? Maybe the code isn’t perfect, but I’ve skimmed it, and compared to the horrors that are OpenVPN and IPSec, it’s a work of art…*.”

Independent of the technology choice, the need to adopt encrypted VPNs is getting more critical every day. Even technologies such as EVPN that do not necessarily require encryption may benefit from encryption if they need to extend outside a protected environment such as a datacenter. EVPN in a hybrid cloud is an excellent example of a technology that may require the addition of encryption.

The bottom line is, *any distributed-services platform needs to support encryption.* Having to choose only two schemes, the preference would be for IPsec and TLS. Availability of hardware acceleration for both symmetric and asymmetric encryption is a must, complemented by the availability of modern stream ciphers such as ChaCha/Poly, in addition to the classical AES in GCM mode.

### 5.13 Secure Boot

We have seen that the DSN is responsible for implementing policies, but these policies can be trusted only as far as the DSN can be trusted. To trust the DSN device, whether it is in a NIC or a switch and so on, we must first be sure that is has not been compromised. The standard solution for this is known as *secure boot*, which ensures that the device is running authentic and trusted firmware. In addition, if the DSN is directly attached to the host (via PCIe, for example), we must ensure that access from the host is restricted to only certain allowed regions. This PCIe filtering (see [section 9.1.10](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch09.xhtml#ch09lev2sec1_10)) should also be configured by the secure boot process.

A secure boot system begins with two implicitly trusted items:

- A source of immutable, trusted boot code; for example a boot ROM

- An immutable root of trust public key (ROTPK), either in ROM or programmed at manufacturing into a one-time-programmable (OTP) memory

The CPU boot sequence begins execution in the trusted ROM. It loads new runtime software from untrusted media, such as a flash disk, into secure memory and then verifies that the software image has come from a trusted source. This verification is via a digital signature that accompanies the image. The signature for the image is verified using the ROTPK. If the check fails, then the image is rejected. If the check passes then the image is authentic and may be executed. The new image continues the boot process similarly, further loading new code and verifying its digital signature, until the device is fully operational.

In addition to loading code images, a secure boot sequence may also load public key certificates. These certificates hold subordinate public keys that can be used to authenticate further objects. The certificates themselves are authenticated by previously loaded certificates, or the ROTPK.

Each step along the secure boot path extends trust to the newly authenticated object, and similarly the authenticity of every loaded object can be traced back along a sequence of certificates back to the ROTPK.

### 5.14 Summary

In this chapter, we have presented distributed services that are important to increase the security in cloud and enterprise infrastructure. In particular, we have covered segregation services such as firewall and microsegmentation, privacy services such as encryption, and infrastructural services such as PUF, HSM, and secure boot. We have seen that encryption comes paired with encapsulation, and we’ve discussed IPsec, the first widely implemented encryption tunnel, and TLS/DTLS, a more modern, growing solution. Encryption is at the basis of VPN deployments, which are essential for today’s mobile workforce and geographically spread corporations.

The next chapter presents two network services that are best suited to be hosted directly on the server: Storage and RDMA.

### 5.15 Bibliography

**[[1](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch05.xhtml#rch05ref1)]** Wired, “The Elite Intel Team Still Fighting Meltdown and Spectre,” [https://www.wired.com/story/intel-meltdown-spectre-storm/](https://www.wired.com/story/intel-meltdown-spectre-storm/), 01/03/2019.

**[[2](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch05.xhtml#rch05ref2)]** Keepnet, “2017 Phishing Trends Report,” [https://www.keepnetlabs.com/phishing-trends-report](https://www.keepnetlabs.com/phishing-trends-report)

**[[3](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch05.xhtml#rch05ref3)]** Matt De Vincentis, *Micro-Segmentation For Dummies*, 2nd VMware special edition, John Wiley & Sons, Inc, 2017.

**[[4](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch05.xhtml#rch05ref4)]** Dierks, T. and E. Rescorla, “The Transport Layer Security (TLS) Protocol Version 1.2,” RFC 5246, August 2008.

**[[5](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch05.xhtml#rch05ref5)]** Rescorla, E., “The Transport Layer Security (TLS) Protocol Version 1.3,” RFC 8446, DOI 10.17487/RFC8446, August 2018.

**[[6](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch05.xhtml#rch05ref6)]** “Announcing the ADVANCED ENCRYPTION STANDARD (AES),” Federal Information Processing Standards Publication 197. United States National Institute of Standards and Technology (NIST). November 26, 2001.

**[[7](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch05.xhtml#rch05ref7)]** Langley, A., Chang, W., Mavrogiannopoulos, N., Strombergson, J., and S. Josefsson, “ChaCha20-Poly1305 Cipher Suites for Transport Layer Security (TLS),” RFC 7905, DOI 10.17487/RFC7905, June 2016.

**[[8](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch05.xhtml#rch05ref8)]** Whitfield Diffie; Martin Hellman (1976). “New directions in cryptography.” IEEE Transactions on Information Theory. 22 (6): 644.

**[[9](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch05.xhtml#rch05ref9)]** Rivest, R.; Shamir, A.; Adleman, L. (February 1978). “A Method for Obtaining Digital Signatures and Public-Key Cryptosystems” (PDF). Communications of the ACM. 21 (2): 120–126.

**[[10](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch05.xhtml#rch05ref10)]** Koblitz, N. “Elliptic curve cryptosystems.” Mathematics of Computation, 1987, 48 (177): 203–209.

**[[11](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch05.xhtml#rch05ref11)]** Miller, V. “Use of elliptic curves in cryptography. CRYPTO,” 1985, Lecture Notes in Computer Science. 85. pp. 417–426.

**[[12](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch05.xhtml#rch05ref12)]** “The Case for Elliptic Curve Cryptography.” NSA.

**[[13](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch05.xhtml#rch05ref13)]** “FIPS 140-3 PUB Development.” NIST. 2013-04-30.

**[[14](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch05.xhtml#rch05ref14)]** Tehranipoor, F., Karimian, N., Xiao, K., and J. Chandy , “DRAM based intrinsic physical unclonable functions for system-level security,” In Proceedings of the 25th edition on Great Lakes Symposium on VLSI, (pp. 15–20). ACM, 2015.

**[[15](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch05.xhtml#rch05ref15)]** 40 Intrinsic ID, “White paper: Flexible Key Provisioning with SRAM PUF,” 2017, [www.intrinsic-id.com](http://www.intrinsic-id.com/)

**[[16](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch05.xhtml#rch05ref16)]** Belshe, M., Peon, R., and M. Thomson, Ed., “Hypertext Transfer Protocol Version 2 (HTTP/2),” RFC 7540, DOI 10.17487/RFC7540, May 2015.

**[[17](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch05.xhtml#rch05ref17)]** Kent, S. and K. Seo, “Security Architecture for the Internet Protocol,” RFC 4301, December 2005.

**[[18](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch05.xhtml#rch05ref18)]** Rescorla, E., “The Transport Layer Security (TLS) Protocol Version 1.3,” RFC 8446, August 2018.

**[[19](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch05.xhtml#rch05ref19)]** Modadugu, Nagendra and Eric Rescorla. “The Design and Implementation of Datagram TLS.” NDSS (2004).

**[[20](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch05.xhtml#rch05ref20)]** Rescorla, E. and N. Modadugu, “Datagram Transport Layer Security Version 1.2,” RFC 6347, January 2012.

**[[21](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch05.xhtml#rch05ref21)]** Mitnick, Kevin and Mikko Hypponen, *The Art of Invisibility: The World’s Most Famous Hacker Teaches You How to Be Safe in the Age of Big Brother and Big Data,* Little, Brown, and Company.

**[[22](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch05.xhtml#rch05ref22)]** Kent, S. and K. Seo, “Security Architecture for the Internet Protocol,” RFC 4301, DOI 10.17487/RFC4301, December 2005.

**[[23](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch05.xhtml#rch05ref23)]** OpenVPN, [https://openvpn.net](https://openvpn.net/)

**[[24](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch05.xhtml#rch05ref24)]** Wireguard: Fast, Modern, Secure VPN Tunnel, [https://www.wireguard.com](https://www.wireguard.com/)

**[[25](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch05.xhtml#rch05ref25)]** Linus Torvalds, “Re: [GIT] Networking,” 2 Aug 2018, [https://lkml.org/lkml/2018/8/2/663](https://lkml.org/lkml/2018/8/2/663)

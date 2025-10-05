## 9
READING LIST AND BIBLIOGRAPHY

We have now finished our study of computer networks, but this is only the beginning. Many interesting topics have not been treated in as much detail as they deserve, and others have been omitted altogether for lack of space. In this chapter, we provide some suggestions for further reading and a bibliography, for the benefit of readers who wish to continue their study of computer networks.

### 9.1 SUGGESTIONS FOR FURTHER READING

There is an extensive literature on all aspects of computer networks. Two journals that publish papers in this area are *IEEE/ACM Transactions on Networking* and *IEEE Journal on Selected Areas in Communications*.

The periodicals of the ACM Special Interest Groups on Data Communications (SIGCOMM) and Mobility of Systems, Users, Data, and Computing (SIGMOBILE) publish many papers of interest, especially on emerging topics. They are *Computer Communication Review* and *Mobile Computing and Communications Review*.

IEEE also publishes three magazines—*IEEE Internet Computing, IEEE Network Magazine*, and *IEEE Communications Magazine*—that contain surveys, tutorials, and case studies on networking. The first two emphasize architecture, standards, and software, and the last tends toward communications technology (fiber optics, satellites, and so on).

There are a number of annual or biannual conferences that attract numerous papers on networks. In particular, look for the *SIGCOMM* conference, *NSDI* (Symposium on Networked Systems Design and Implementation), *MobiSys* (Conference on Mobile Systems, Applications, and Services), *SOSP* (Symposium on Operating Systems Principles) and *OSDI* (Symposium on Operating Systems Design and Implementation).

Below we list some suggestions for supplementary reading, keyed to the chapters of this book. Many of the suggestions are books of chapters in books, with some tutorials and surveys. Full references are in Sec. 9.2.

#### 9.1.1 Introduction and General Works

Comer, *The Internet Book*, 4th ed.

Anyone looking for an easygoing introduction to the Internet should look here. Comer describes the history, growth, technology, protocols, and services of the Internet in terms that novices can understand, but so much material is covered that the book is also of interest to more technical readers.

*Computer Communication Review*, 25th Anniversary Issue, Jan. 1995

For a firsthand look at how the Internet developed, this special issue collects important papers up to 1995. Included are papers that show the development of TCP, multicast, the DNS, Ethernet, and the overall architecture.

Crovella and Krishnamurthy, *Internet Measurement*

How do we know how well the Internet works anyway? This question is not trivial to answer because no one is in charge of the Internet. This book describes the techniques that have been developed to measure the operation of the Internet, from network infrastructure to applications.

*IEEE Internet Computing*, Jan.–Feb. 2000

The first issue of *IEEE Internet Computing* in the new millennium did exactly what you would expect: it asked the people who helped create the Internet in the previous millennium to speculate on where it is going in the next one. The experts are Paul Baran, Lawrence Roberts, Leonard Kleinrock, Stephen Crocker, Danny Cohen, Bob Metcalfe, Bill Gates, Bill Joy, and others. See how well their predictions have fared over a decade later.

Kipnis, “Beating the System: Abuses of the Standards Adoption Process”

Standards committees try to be fair and vendor neutral in their work, but unfortunately there are companies that try to abuse the system. For example, it has happened repeatedly that a company helps develop a standard and then after it is approved, announces that the standard is based on a patent it owns and which it will license to companies that it likes and not to companies that it does not like, at prices that it alone determines. For a look at the dark side of standardization, this article is an excellent start.

Hafner and Lyon, *Where Wizards Stay Up Late*

Naughton, *A Brief History of the Future*

Who invented the Internet, anyway? Many people have claimed credit. And rightly so, since many people had a hand in it, in different ways. There was Paul Baran, who wrote a report describing packet switching, there were the people at various universities who designed the ARPANET architecture, there were the people at BBN who programmed the first IMPs, there were Bob Kahn and Vint Cerf who invented TCP/IP, and so on. These books tell the story of the Internet, at least up to 2000, replete with many anecdotes.

#### 9.1.2 The Physical Layer

Bellamy, *Digital Telephony*, 3rd ed.

For a look back at that other important network, the telephone network, this authoritative book contains everything you ever wanted to know and more. Particularly interesting are the chapters on transmission and multiplexing, digital switching, fiber optics, mobile telephony, and DSL.

Hu and Li, “Satellite-Based Internet: A Tutorial”

Internet access via satellite is different from using terrestrial lines. Not only is there the issue of delay, but routing and switching are also different. In this paper, the authors examine the issues related to using satellites for Internet access.

Joel, “Telecommunications and the IEEE Communications Society”

For a compact but surprisingly comprehensive history of telecommunications, starting with the telegraph and ending with 802.11, this article is the place to look. It also covers radio, telephones, analog and digital switching, submarine cables, digital transmission, television broadcasting, satellites, cable TV, optical communications, mobile phones, packet switching, the ARPANET, and the Internet.

Palais, *Fiber Optic Communication*, 5th ed.

Books on fiber optic technology tend to be aimed at the specialist, but this one is more accessible than most. It covers waveguides, light sources, light detectors, couplers, modulation, noise, and many other topics.

Su, *The UMTS Air Interface in RF Engineering*

This book provides a detailed overview of one of the main 3G cellular systems. It is focused on the air interface, or wireless protocols that are used between mobiles and the network infrastructure.

Want, *RFID Explained*

Want’s book is an easy-to-read primer on how the unusual technology of the RFID physical layer works. It covers all aspects of RFID, including its potential applications. Some real-world examples of RFID deployments and the experience gained from them is also convered.

#### 9.1.3 The Data Link Layer

Kasim, *Delivering Carrier Ethernet*

Nowadays, Ethernet is not only a local-area technology. The new fashion is to use Ethernet as a long-distance link for carrier-grade Ethernet. This book brings together essays to cover the topic in depth.

Lin and Costello, *Error Control Coding*, 2nd ed.

Codes to detect and correct errors are central to reliable computer networks. This popular textbook explains some of the most important codes, from simple linear Hamming codes to more complex low-density parity check codes. It tries to do so with the minimum algebra necessary, but that is still a lot.

Stallings, *Data and Computer Communications*, 9th ed.

Part two covers digital data transmission and a variety of links, including error detection, error control with retransmissions, and flow control.

#### 9.1.4 The Medium Access Control Sublayer

Andrews et al., *Fundamentals of WiMAX*

This comprehensive book gives a definitive treatment of WiMAX technology, from the idea of broadband wireless, to the wireless techniques using OFDM and multiple antennas, through the multi-access system. Its tutorial style gives about the most accessible treatment you will find for this heavy material.

Gast, *802.11 Wireless Networks*, 2nd ed.

For a readable introduction to the technology and protocols of 802.11, this is a good place to start. It begins with the MAC sublayer, then introduces material on the different physical layers and also security. However, the second edition is not new enough to have much to say about 802.11n.

Perlman, *Interconnections*, 2nd ed.

For an authoritative but entertaining treatment of bridges, routers, and routing in general, Perlman’s book is the place to look. The author designed the algorithms used in the IEEE 802 spanning tree bridge and she is one of the world’s leading authorities on various aspects of networking.

#### 9.1.5 The Network Layer

Comer, *Internetworking with TCP/IP*, Vol. 1, 5th ed.

Comer has written the definitive work on the TCP/IP protocol suite, now in its fifth edition. Most of the first half deals with IP and related protocols in the network layer. The other chapters deal primarily with the higher layers and are also worth reading.

Grayson et al., *IP Design for Mobile Networks*

Traditional telephone networks and the Internet are on a collision course, with mobile phone networks being implemented with IP on the inside. This book tells how to design a network using the IP protocols that supports mobile telephone service.

Huitema, *Routing in the Internet*, 2nd ed.

If you want to gain a deep understanding of routing protocols, this is a very good book. Both pronounceable algorithms (e.g., RIP, and CIDR) and unpronounceable algorithms (e.g., OSPF, IGRP, and BGP) are treated in great detail. Newer developments are not covered since this is an older book, but what is covered is explained very well.

Koodli and Perkins, *Mobile Inter-networking with IPv6*

Two important network layer developments are presented in one volume: IPv6 and Mobile IP. Both topics are covered well, and Perkins was one of the driving forces behind Mobile IP.

Nucci and Papagiannaki, *Design, Measurement and Management of Large-Scale IP Networks*

We talked a great deal about how networks work, but not how you would design, deploy and manage one if you were an ISP. This book fills that gap, looking at modern methods for traffic engineering and how ISPs provide services using networks.

Perlman, *Interconnections*, 2nd ed.

In Chaps. 12 through 15, Perlman describes many of the issues involved in unicast and multicast routing algorithm design, both for wide area networks and networks of LANs. But by far, the best part of the book is Chap. 18, in which the author distills her many years of experience with network protocols into an informative and fun chapter. It is required reading for protocol designers.

Stevens, *TCP/IP Illustrated*, Vol. 1

Chapters 3–10 provide a comprehensive treatment of IP and related protocols (ARP, RARP, and ICMP), illustrated by examples.

Varghese, *Network Algorithmics*

We have spent much time talking about how routers and other network elements interact with each other. This book is different: it is about how routers are actually designed to forward packets at prodigious speeds. For the inside scoop on that and related questions, this is the book to read. The author is an authority on clever algorithms that are used in practice to implement high-speed network elements in software and hardware.

#### 9.1.6 The Transport Layer

Comer, *Internetworking with TCP/IP*, Vol. 1, 5th ed.

As mentioned above, Comer has written the definitive work on the TCP/IP protocol suite. The second half of the book is about UDP and TCP.

Farrell and Cahill, *Delay- and Disruption-Tolerant Networking*

This short book is the one to read for a deeper look at the architecture, protocols, and applications of “challenged networks” that must operate under harsh conditions of connectivity. The authors have participated in the development of DTNs in the IETF DTN Research Group.

Stevens, *TCP/IP Illustrated*, Vol. 1

Chapters 17–24 provide a comprehensive treatment of TCP illustrated by examples.

#### 9.1.7 The Application Layer

Berners-Lee et al., “The World Wide Web”

Take a trip back in time for a perspective on the Web and where it is going by the person who invented it and some of his colleagues at CERN. The article focuses on the Web architecture, URLs, HTTP, and HTML, as well as future directions, and compares it to other distributed information systems.

Held, *A Practical Guide to Content Delivery Networks*, 2nd ed.

This book gives a down-to-earth exposition of how CDNs work, emphasizing the practical considerations in designing and operating a CDN that performs well.

Hunter et al., *Beginning XML*, 4th ed.

There are many, many books on HTML, XML and Web services. This 1000-page book covers most of what you are likely to want to know. It explains not only how to write XML and XHTML, but also how to develop Web services that produce and manipulate XML using Ajax, SOAP, and other techniques that are commonly used in practice.

Krishnamurthy and Rexford, *Web Protocols and Practice*

It would be hard to find a more comprehensive book about all aspects of the Web than this one. It covers clients, servers, proxies, and caching, as you might expect. But there are also chapters on Web traffic and measurements as well as chapters on current research and improving the Web.

Simpson, *Video Over IP*, 2nd ed.

The author takes a broad look at how IP technology can be used to move video across networks, both on the Internet and in private networks designed to carry video. Interestingly, this book is oriented for the video professional learning about networking, rather than the other way around.

Wittenburg, *Understanding Voice Over IP Technology*

This book covers how voice over IP works, from carrying audio data with the IP protocols and quality-of-service issues, through to the SIP and H.323 suite of protocols. It is necessarily detailed given the material, but accessible and broken up into digestible units.

#### 9.1.8 Network Security

Anderson, *Security Engineering*, 2nd. ed.

This book presents a wonderful mix of security techniques couched in an understanding of how people use (and misuse) them. It is more technical than *Secrets and Lies*, but less technical than *Network Security* (see below). After an introduction to the basic security techniques, entire chapters are devoted to various applications, including banking, nuclear command and control, security printing, biometrics, physical security, electronic warfare, telecom security, e-commerce, and copyright protection.

Ferguson et al., *Cryptography Engineering*

Many books tell you how the popular cryptographic algorithms work. This book tells you how to use cryptography—why cryptographic protocols are designed the way they are and how to put them together into a system that will meet your security goals. It is a fairly compact book that is essential reading for anyone designing systems that depend on cryptography.

Fridrich, *Steganography in Digital Media*

Steganography goes back to ancient Greece, where the wax was melted off blank tablets so secret messages could be applied to the underlying wood before the wax was reapplied. Nowadays, videos, audio, and other content on the Internet provide different carriers for secret messages. Various modern techniques for hiding and finding information in images are discussed here.

Kaufman et al., *Network Security*, 2nd ed.

This authoritative and witty book is the first place to look for more technical information on network security algorithms and protocols. Secret and public key algorithms and protocols, message hashes, authentication, Kerberos, PKI, IPsec, SSL/TLS, and email security are all explained carefully and at considerable length, with many examples. Chapter 26, on security folklore, is a real gem. In security, the devil is in the details. Anyone planning to design a security system that will actually be used will learn a lot from the real-world advice in this chapter.

Schneier, *Secrets and Lies*

If you read *Cryptography Engineering* from cover to cover, you will know everything there is to know about cryptographic algorithms. If you then read *Secrets and Lies* cover to cover (which can be done in a lot less time), you will learn that cryptographic algorithms are not the whole story. Most security weaknesses are not due to faulty algorithms or even keys that are too short, but to flaws in the security environment. For a nontechnical and fascinating discussion of computer security in the broadest sense, this book is a very good read.

Skoudis and Liston, *Counter Hack Reloaded*, 2nd ed.

The best way to stop a hacker is to think like a hacker. This book shows how hackers see a network, and argues that security should be a function of the entire network’s design, not an afterthought based on one specific technology. It covers almost all common attacks, including the “social engineering” types that take advantage of users who are not always familiar with computer security measures.

### 9.2 ALPHABETICAL BIBLIOGRAPHY

**ABRAMSON, N.**: “Internet Access Using VSATs,” *IEEE Commun. Magazine*, vol. 38, pp. 60–68, July 2000.

**AHMADI, S.**: “An Overview of Next-Generation Mobile WiMAX Technology,” *IEEE Commun. Magazine*, vol. 47, pp. 84–88, June 2009.

**ALLMAN, M., and PAXSON, V.**: “On Estimating End-to-End Network Path Properties,” *Proc. SIGCOMM ‘99 Conf*., ACM, pp. 263–274, 1999.

**ANDERSON, C.**: *The Long Tail: Why the Future of Business is Selling Less of More*, rev. upd. ed., New York: Hyperion, 2008a.

**ANDERSON, R.J.**: *Security Engineering: A Guide to Building Dependable Distributed Systems*, 2nd ed., New York: John Wiley & Sons, 2008b.

**ANDERSON, R.J.**: “Free Speech Online and Offline,” *IEEE Computer*, vol. 25, pp. 28–30, June 2002.

**ANDERSON, R.J.**: “The Eternity Service,” *Proc. Pragocrypt Conf*., CTU Publishing House, pp. 242–252, 1996.

**ANDREWS, J., GHOSH, A., and MUHAMED, R.**: *Fundamentals of WiMAX: Understanding Broadband Wireless Networking*, Upper Saddle River, NJ: Pearson Education, 2007.

**ASTELY, D., DAHLMAN, E., FURUSKAR, A., JADING, Y., LINDSTROM, M., and PARKVALL, S.**: “LTE: The Evolution of Mobile Broadband,” *IEEE Commun. Magazine*, vol. 47, pp. 44–51, Apr. 2009.

**BALLARDIE, T., FRANCIS, P., and CROWCROFT, J.**: “Core Based Trees (CBT),” *Proc. SIGCOMM ‘93 Conf*., ACM, pp. 85–95, 1993.

**BARAN, P.**: “On Distributed Communications: I. Introduction to Distributed Communication Networks,” *Memorandum RM-420-PR*, Rand Corporation, Aug. 1964.

**BELLAMY, J.**: *Digital Telephony*, 3rd ed., New York: John Wiley & Sons, 2000.

**BELLMAN, R.E.**: *Dynamic Programming*, Princeton, NJ: Princeton University Press, 1957.

**BELLOVIN, S.**: “The Security Flag in the IPv4 Header,” RFC 3514, Apr. 2003.

**BELSNES, D.**: “Flow Control in the Packet Switching Networks,” *Communications Networks*, Uxbridge, England: Online, pp. 349–361, 1975.

**BENNET, C.H., and BRASSARD, G.**: “Quantum Cryptography: Public Key Distribution and Coin Tossing,” *Int’l Conf. on Computer Systems and Signal Processing*, pp. 175–179, 1984.

**BERESFORD, A., and STAJANO, F.**: “Location Privacy in Pervasive Computing,” *IEEE Pervasive Computing*, vol. 2, pp. 46–55, Jan. 2003.

**BERGHEL, H.L.**: “Cyber Privacy in the New Millennium,” *IEEE Computer*, vol. 34, pp. 132–134, Jan. 2001.

**BERNERS-LEE, T., CAILLIAU, A., LOUTONEN, A., NIELSEN, H.F., and SECRET, A.**: “The World Wide Web,” *Commun. of the ACM*, vol. 37, pp. 76–82, Aug. 1994.

**BERTSEKAS, D., and GALLAGER, R.**: *Data Networks*, 2nd ed., Englewood Cliffs, NJ: Prentice Hall, 1992.

**BHATTI, S.N., and CROWCROFT, J.**: “QoS Sensitive Flows: Issues in IP Packet Handling,” *IEEE Internet Computing*, vol. 4, pp. 48–57, July–Aug. 2000.

**BIHAM, E., and SHAMIR, A.**: “Differential Fault Analysis of Secret Key Cryptosystems,” *Proc. 17th Ann. Int’l Cryptology Conf*., Berlin: Springer-Verlag LNCS 1294, pp. 513–525, 1997.

**BIRD, R., GOPAL, I., HERZBERG, A., JANSON, P.A., KUTTEN, S., MOLVA, R., and YUNG, M.**: “Systematic Design of a Family of Attack-Resistant Authentication Protocols,” *IEEE J. on Selected Areas in Commun*., vol. 11, pp. 679–693, June 1993.

**BIRRELL, A.D., and NELSON, B.J.**: “Implementing Remote Procedure Calls,” *ACM Trans. on Computer Systems*, vol. 2, pp. 39–59, Feb. 1984.

**BIRYUKOV, A., SHAMIR, A., and WAGNER, D.**: “Real Time Cryptanalysis of A5/1 on a PC,” *Proc. Seventh Int’l Workshop on Fast Software Encryption*, Berlin: Springer-Verlag LNCS 1978, pp. 1–8, 2000.

**BLAZE, M., and BELLOVIN, S.**: “Tapping on My Network Door,” *Commun. of the ACM*, vol. 43, p. 136, Oct. 2000.

**BOGGS, D., MOGUL, J., and KENT, C.**: “Measured Capacity of an Ethernet: Myths and Reality,” *Proc. SIGCOMM ‘88 Conf*., ACM, pp. 222–234, 1988.

**BORISOV, N., GOLDBERG, I., and WAGNER, D.**: “Intercepting Mobile Communications: The Insecurity of 802.11,” *Seventh Int’l Conf. on Mobile Computing and Networking*, ACM, pp. 180–188, 2001.

**BRADEN, R.**: “Requirements for Internet Hosts—Communication Layers,” RFC 1122, Oct. 1989.

**BRADEN, R., BORMAN, D., and PARTRIDGE, C.**: “Computing the Internet Checksum,” RFC 1071, Sept. 1988.

**BRANDENBURG, K.**: “MP3 and AAC Explained,” *Proc. 17th Intl. Conf.: High-Quality Audio Coding*, Audio Engineering Society, pp. 99–110, Aug. 1999.

**BRAY, T., PAOLI, J., SPERBERG-MCQUEEN, C., MALER, E., YERGEAU, F., and COWAN, J.**: “Extensible Markup Language (XML) 1.1 (Second Edition),” W3C Recommendation, Sept. 2006.

**BRESLAU, L., CAO, P., FAN, L., PHILLIPS, G., and SHENKER, S.**: “Web Caching and Zipf-like Distributions: Evidence and Implications,” *Proc. INFOCOM Conf*., IEEE, pp. 126–134, 1999.

**BURLEIGH, S., HOOKE, A., TORGERSON, L., FALL, K., CERF, V., DURST, B., SCOTT, K., and WEISS, H.**: “Delay-Tolerant Networking: An Approach to Interplanetary Internet,” *IEEE Commun. Magazine*, vol. 41, pp. 128–136, June 2003.

**BURNETT, S., and PAINE, S.**: *RSA Security’s Official Guide to Cryptography*, Berkeley, CA: Osborne/McGraw-Hill, 2001.

**BUSH, V.**: “As We May Think,” *Atlantic Monthly*, vol. 176, pp. 101–108, July 1945.

**CAPETANAKIS, J.I.**: “Tree Algorithms for Packet Broadcast Channels,” *IEEE Trans. on Information Theory*, vol. IT-5, pp. 505–515, Sept. 1979.

**CASTAGNOLI, G., BRAUER, S., and HERRMANN, M.**: “Optimization of Cyclic Redundancy-Check Codes with 24 and 32 Parity Bits,” *IEEE Trans. on Commun*., vol. 41, pp. 883–892, June 1993.

**CERF, V., and KAHN, R.**: “A Protocol for Packet Network Interconnection,” *IEEE Trans*. *on Commun*., vol. COM-2, pp. 637–648, May 1974.

**CHANG, F., DEAN, J., GHEMAWAT, S., HSIEH, W., WALLACH, D., BURROWS, M., CHANDRA, T., FIKES, A., and GRUBER, R.**: “Bigtable: A Distributed Storage System for Structured Data,” *Proc. OSDI2006 Symp*., USENIX, pp. 15–29, 2006.

**CHASE, J.S., GALLATIN, A.J., and YOCUM, K.G.**: “End System Optimizations for High-Speed TCP,” *IEEE Commun. Magazine*, vol. 39, pp. 68–75, Apr. 2001.

**CHEN, S., and NAHRSTEDT, K.**: “An Overview of QoS Routing for Next-Generation Networks,” *IEEE Network Magazine*, vol. 12, pp. 64–69, Nov./Dec. 1998.

**CHIU, D., and JAIN, R.**: “Analysis of the Increase and Decrease Algorithms for Congestion Avoidance in Computer Networks,” *Comput. Netw. ISDN Syst*., vol. 17, pp. 1–4, June 1989.

**CISCO**: “Cisco Visual Networking Index: Forecast and Methodology, 2009–2014,” Cisco Systems Inc., June 2010.

**CLARK, D.D.**: “The Design Philosophy of the DARPA Internet Protocols,” *Proc. SIGCOMM ‘88 Conf*., ACM, pp. 106–114, 1988.

**CLARK, D.D.**: “Window and Acknowledgement Strategy in TCP,” RFC 813, July 1982.

**CLARK, D.D., JACOBSON, V., ROMKEY, J., and SALWEN, H.**: “An Analysis of TCP Processing Overhead,” *IEEE Commun. Magazine*, vol. 27, pp. 23–29, June 1989.

**CLARK, D.D., SHENKER, S., and ZHANG, L.**: “Supporting Real-Time Applications in an Integrated Services Packet Network,” *Proc. SIGCOMM ‘92 Conf*., ACM, pp. 14–26, 1992.

**CLARKE, A.C.**: “Extra-Terrestrial Relays,” *Wireless World*, 1945.

**CLARKE, I., MILLER, S.G., HONG, T.W., SANDBERG, O., and WILEY, B.**: “Protecting Free Expression Online with Freenet,” *IEEE Internet Computing*, vol. 6, pp. 40–49, Jan.-Feb. 2002.

**COHEN, B.**: “Incentives Build Robustness in BitTorrent,” *Proc. First Workshop on Economics of Peer-to-Peer Systems*, June 2003.

**COMER, D.E.**: *The Internet Book*, 4th ed., Englewood Cliffs, NJ: Prentice Hall, 2007.

**COMER, D.E.**: *Internetworking with TCP/IP*, vol. 1, 5th ed., Englewood Cliffs, NJ: Prentice Hall, 2005.

**CRAVER, S.A., WU, M., LIU, B., STUBBLEFIELD, A., SWARTZLANDER, B., WALLACH, D.W., DEAN, D., and FELTEN, E.W.**: “Reading Between the Lines: Lessons from the SDMI Challenge,” *Proc. 10th USENIX Security Symp*., USENIX, 2001.

**CROVELLA, M., and KRISHNAMURTHY, B.**: *Internet Measurement*, New York: John Wiley & Sons, 2006.

**DAEMEN, J., and RIJMEN, V.**: *The Design of Rijndael*, Berlin: Springer-Verlag, 2002.

**DALAL, Y., and METCLFE, R.**: “Reverse Path Forwarding of Broadcast Packets,” *Commun. of the ACM*, vol. 21, pp. 1040-1048, Dec. 1978.

**DAVIE, B., and FARREL, A.**: *MPLS: Next Steps*, San Francisco: Morgan Kaufmann, 2008.

**DAVIE, B., and REKHTER, Y.**: *MPLS Technology and Applications*, San Francisco: Morgan Kaufmann, 2000.

**DAVIES, J.**: *Understanding IPv6*, 2nd ed., Redmond, WA: Microsoft Press, 2008.

**DAY, J.D.**: “The (Un)Revised OSI Reference Model,” *Computer Commun. Rev*., vol. 25, pp. 39–55, Oct. 1995.

**DAY, J.D., and ZIMMERMANN, H.**: “The OSI Reference Model,” *Proc. of the IEEE*, vol. 71, pp. 1334–1340, Dec. 1983.

**DECANDIA, G., HASTORIN, D., JAMPANI, M., KAKULAPATI, G., LAKSHMAN, A., PIL-CHIN, A., SIVASUBRAMANIAN, S., VOSSHALL, P., and VOGELS, W.**: “Dynamo: Amazon’s Highly Available Key-value Store,” *Proc. 19th Symp. on Operating Systems Prin*., ACM, pp. 205–220, Dec. 2007.

**DEERING, S.E.**: “SIP: Simple Internet Protocol,” *IEEE Network Magazine*, vol. 7, pp. 16–28, May/June 1993.

**DEERING, S., and CHERITON, D.**: “Multicast Routing in Datagram Networks and Extended LANs,” *ACM Trans. on Computer Systems*, vol. 8, pp. 85–110, May 1990.

**DEMERS, A., KESHAV, S., and SHENKER, S.**: “Analysis and Simulation of a Fair Queueing Algorithm,” *Internetwork: Research and Experience*, vol. 1, pp. 3–26, Sept. 1990.

**DENNING, D.E., and SACCO, G.M.**: “Timestamps in Key Distribution Protocols,” *Commun. of the ACM*, vol. 24, pp. 533–536, Aug. 1981.

**DEVARAPALLI, V., WAKIKAWA, R., PETRESCU, A., and THUBERT, P.**: “Network Mobility (NEMO) Basic Support Protocol,” RFC 3963, Jan. 2005.

**DIFFIE, W., and HELLMAN, M.E.**: “Exhaustive Cryptanalysis of the NBS Data Encryption Standard,” *IEEE Computer*, vol. 10, pp. 74–84, June 1977.

**DIFFIE, W., and HELLMAN, M.E.**: “New Directions in Cryptography,” *IEEE Trans. on Information Theory*, vol. IT-2, pp. 644–654, Nov. 1976.

**DIJKSTRA, E.W.**: “A Note on Two Problems in Connexion with Graphs,” *Numer. Math*., vol. 1, pp. 269–271, Oct. 1959.

**DILLEY, J., MAGGS, B., PARIKH, J., PROKOP, H., SITARAMAN, R., and WHEIL, B.**: “Globally Distributed Content Delivery,” *IEEE Internet Computing*, vol. 6, pp. 50–58, 2002.

**DINGLEDINE, R., MATHEWSON, N., SYVERSON, P.**: “Tor: The Second-Generation Onion Router,” *Proc. 13th USENIX Security Symp*., USENIX, pp. 303–320, Aug. 2004.

**DONAHOO, M., and CALVERT, K.**: *TCP/IP Sockets in C*, 2nd ed., San Francisco: Morgan Kaufmann, 2009.

**DONAHOO, M., and CALVERT, K.**: *TCP/IP Sockets in Java*, 2nd ed., San Francisco: Morgan Kaufmann, 2008.

**DONALDSON, G., and JONES, D.**: “Cable Television Broadband Network Architectures,” *IEEE Commun. Magazine*, vol. 39, pp. 122–126, June 2001.

**DORFMAN, R.**: “Detection of Defective Members of a Large Population,” *Annals Math. Statistics*, vol. 14, pp. 436–440, 1943.

**DUTCHER, B.**: *The NAT Handbook*, New York: John Wiley & Sons, 2001.

**DUTTA-ROY, A.**: “An Overview of Cable Modem Technology and Market Perspectives,” *IEEE Commun. Magazine*, vol. 39, pp. 81–88, June 2001.

**EDELMAN, B., OSTROVSKY, M., and SCHWARZ, M.**: “Internet Advertising and the Generalized Second-Price Auction: Selling Billions of Dollars Worth of Keywords,” *American Economic Review*, vol. 97, pp. 242–259, Mar. 2007.

**EL GAMAL, T.**: “A Public-Key Cryptosystem and a Signature Scheme Based on Discrete Logarithms,” *IEEE Trans. on Information Theory*, vol. IT-1, pp. 469–472, July 1985.

**EPCGLOBAL**: *EPC Radio-Frequency Identity Protocols Class- Generation- UHF RFID Protocol for Communication at 860-MHz to 960-MHz Version 1.2.0*, Brussels: EPCglobal Inc., Oct. 2008.

**FALL, K.**: “A Delay-Tolerant Network Architecture for Challenged Internets,” *Proc. SIGCOMM 2003 Conf*., ACM, pp. 27–34, Aug. 2003.

**FALOUTSOS, M., FALOUTSOS, P., and FALOUTSOS, C.**: “On Power-Law Relationships of the Internet Topology,” *Proc. SIGCOMM ‘99 Conf*., ACM, pp. 251–262, 1999.

**FARRELL, S., and CAHILL, V.**: *Delay- and Disruption-Tolerant Networking*, London: Artech House, 2007.

**FELLOWS, D., and JONES, D.**: “DOCSIS Cable Modem Technology,” *IEEE Commun. Magazine*, vol. 39, pp. 202–209, Mar. 2001.

**FENNER, B., HANDLEY, M., HOLBROOK, H., and KOUVELAS, I.**: “Protocol Independent Multicast-Sparse Mode (PIM-SM),” RFC 4601, Aug. 2006.

**FERGUSON, N., SCHNEIER, B., and KOHNO, T.**: *Cryptography Engineering: Design Principles and Practical Applications*, New York: John Wiley & Sons, 2010.

**FLANAGAN, D.**: *JavaScript: The Definitive Guide*, 6th ed., Sebastopol, CA: O’Reilly, 2010.

**FLETCHER, J.**: “An Arithmetic Checksum for Serial Transmissions,” *IEEE Trans. on Commun*., vol. COM-0, pp. 247–252, Jan. 1982.

**FLOYD, S., HANDLEY, M., PADHYE, J., and WIDMER, J.**: “Equation-Based Congestion Control for Unicast Applications,” *Proc. SIGCOMM 2000 Conf*., ACM, pp. 43–56, Aug. 2000.

**FLOYD, S., and JACOBSON, V.**: “Random Early Detection for Congestion Avoidance,” *IEEE/ACM Trans. on Networking*, vol. 1, pp. 397–413, Aug. 1993.

**FLUHRER, S., MANTIN, I., and SHAMIR, A.**: “Weakness in the Key Scheduling Algorithm of RC4,” *Proc. Eighth Ann. Workshop on Selected Areas in Cryptography*, Berlin: Springer-Verlag LNCS 2259, pp. 1–24, 2001.

**FORD, B.**: “Structured Streams: A New Transport Abstraction,” *Proc. SIGCOMM 2007 Conf*., ACM, pp. 361–372, 2007.

**FORD, L.R., Jr., and FULKERSON, D.R.**: *Flows in Networks*, Princeton, NJ: Princeton University Press, 1962.

**FORD, W., and BAUM, M.S.**: *Secure Electronic Commerce*, Upper Saddle River, NJ: Prentice Hall, 2000.

**FORNEY, G.D.**: “The Viterbi Algorithm,” *Proc. of the IEEE*, vol. 61, pp. 268–278, Mar. 1973.

**FOULI, K., and MALER, M.**: “The Road to Carrier-Grade Ethernet,” *IEEE Commun. Magazine*, vol. 47, pp. S30–S38, Mar. 2009.

**FOX, A., GRIBBLE, S., BREWER, E., and AMIR, E.**: “Adapting to Network and Client Variability via On-Demand Dynamic Distillation,” *SIGOPS Oper. Syst. Rev*., vol. 30, pp. 160–170, Dec. 1996.

**FRANCIS, P.**: “A Near-Term Architecture for Deploying Pip,” *IEEE Network Magazine*, vol. 7, pp. 30–37, May/June 1993.

**FRASER, A.G.**: “Towards a Universal Data Transport System,” *IEEE J. on Selected Areas in Commun*., vol. 5, pp. 803–816, Nov. 1983.

**FRIDRICH, J.**: *Steganography in Digital Media: Principles, Algorithms, and Applications*, Cambridge: Cambridge University Press, 2009.

**FULLER, V., and LI, T.**: “Classless Inter-domain Routing (CIDR): The Internet Address Assignment and Aggregation Plan,” RFC 4632, Aug. 2006.

**GALLAGHER, R.G.**: “A Minimum Delay Routing Algorithm Using Distributed Computation,” *IEEE Trans. on Commun*., vol. COM-5, pp. 73–85, Jan. 1977.

**GALLAGHER, R.G.**: “Low-Density Parity Check Codes,” *IRE Trans. on Information Theory*, vol. 8, pp. 21–28, Jan. 1962.

**GARFINKEL, S., with SPAFFORD, G.**: *Web Security, Privacy, and Commerce*, Sebastopol, CA: O’Reilly, 2002.

**GAST, M.**: *802.11 Wireless Networks: The Definitive Guide*, 2nd ed., Sebastopol, CA: O’Reilly, 2005.

**GERSHENFELD, N., and KRIKORIAN, R., and COHEN, D.**: “The Internet of Things,” *Scientific American*, vol. 291, pp. 76–81, Oct. 2004.

**GILDER, G.**: “Metcalfe’s Law and Legacy,” *Forbes ASAP*, Sepy. 13, 1993.

**GOODE, B.**: “Voice over Internet Protocol,” *Proc. of the IEEE*, vol. 90, pp. 1495–1517, Sept. 2002.

**GORALSKI, W.J.**: *SONET*, 2nd ed., New York: McGraw-Hill, 2002.

**GRAYSON, M., SHATZKAMER, K., and WAINNER, S.**: *IP Design for Mobile Networks*, Indianapolis, IN: Cisco Press, 2009.

**GROBE, K., and ELBERS, J.**: “PON in Adolescence: From TDMA to WDM-PON,” *IEEE Commun. Magazine*, vol. 46, pp. 26–34, Jan. 2008.

**GROSS, G., KAYCEE, M., LIN, A., MALIS, A., and STEPHENS, J.**: “The PPP Over AAL5,” RFC 2364, July 1998.

**HA, S., RHEE, I., and LISONG, X.**: “CUBIC: A New TCP-Friendly High-Speed TCP Variant,” *SIGOPS Oper. Syst. Rev*., vol. 42, pp. 64–74, June 2008.

**HAFNER, K., and LYON, M.**: *Where Wizards Stay Up Late*, New York: Simon & Schuster, 1998.

**HALPERIN, D., HEYDT-BENJAMIN, T., RANSFORD, B., CLARK, S., DEFEND, B., MORGAN, W., FU, K., KOHNO, T., and MAISEL, W.**: “Pacemakers and Implantable Cardiac Defibrillators: Software Radio Attacks and Zero-Power Defenses,” *IEEE Symp. on Security and Privacy*, pp. 129–142, May 2008.

**HALPERIN, D., HU, W., SHETH, A., and WETHERALL, D.**: “802.11 with Multiple Antennas for Dummies,” *Computer Commun. Rev*., vol. 40, pp. 19–25, Jan. 2010.

**HAMMING, R.W.**: “Error Detecting and Error Correcting Codes,” *Bell System Tech. J*., vol. 29, pp. 147–160, Apr. 1950.

**HARTE, L., KELLOGG, S., DREHER, R., and SCHAFFNIT, T.**: *The Comprehensive Guide to Wireless Technology*, Fuquay-Varina, NC: APDG Publishing, 2000.

**HAWLEY, G.T.**: “Historical Perspectives on the U.S. Telephone Loop,” *IEEE Commun. Magazine*, vol. 29, pp. 24–28, Mar. 1991.

**HECHT, J.**: *Understanding Fiber Optics*, Upper Saddle River, NJ: Prentice Hall, 2005.

**HELD, G.**: *A Practical Guide to Content Delivery Networks*, 2nd ed., Boca Raton, FL: CRC Press, 2010.

**HEUSSE, M., ROUSSEAU, F., BERGER-SABBATEL, G., DUDA, A.**: “Performance Anomaly of 802.11b,” *Proc. INFOCOM Conf*., IEEE, pp. 836–843, 2003.

**HIERTZ, G., DENTENEER, D., STIBOR, L., ZANG, Y., COSTA, X., and WALKE, B.**: “The IEEE 802.11 Universe,” *IEEE Commun. Magazine*, vol. 48, pp. 62–70, Jan. 2010.

**HOE, J.**: “Improving the Start-up Behavior of a Congestion Control Scheme for TCP,” *Proc. SIGCOMM ‘96 Conf*., ACM, pp. 270–280, 1996.

**HU, Y., and LI, V.O.K**.:” Satellite-Based Internet: A Tutorial,” *IEEE Commun. Magazine*, vol. 30, pp. 154–162, Mar. 2001.

**HUITEMA, C.**: *Routing in the Internet*, 2nd ed., Englewood Cliffs, NJ: Prentice Hall, 1999.

**HULL, B., BYCHKOVSKY, V., CHEN, K., GORACZKO, M., MIU, A., SHIH, E., ZHANG, Y., BALAKRISHNAN, H., and MADDEN, S.**: “CarTel: A Distributed Mobile Sensor Computing System,” *Proc. Sensys 2006 Conf*., ACM, pp. 125–138, Nov. 2006.

**HUNTER, D., RAFTER, J., FAWCETT, J., VAN DER LIST, E., AYERS, D., DUCKETT, J., WATT, A., and MCKINNON, L.**: *Beginning XML*, 4th ed., New Jersey: Wrox, 2007.

**IRMER, T.**: “Shaping Future Telecommunications: The Challenge of Global Standardization,” *IEEE Commun. Magazine*, vol. 32, pp. 20–28, Jan. 1994.

**ITU (INTERNATIONAL TELECOMMUNICATION UNION)**: *ITU Internet Reports 2005: The Internet of Things*, Geneva: ITU, Nov. 2005.

**ITU (INTERNATIONAL TELECOMMUNICATION UNION)**: *Measuring the Information Society: The ICT Development Index*, Geneva: ITU, Mar. 2009.

**JACOBSON, V.**: “Compressing TCP/IP Headers for Low-Speed Serial Links,” RFC 1144, Feb. 1990.

**JACOBSON, V.**: “Congestion Avoidance and Control,” *Proc. SIGCOMM ‘88 Conf*., ACM, pp. 314–329, 1988.

**JAIN, R., and ROUTHIER, S.**: “Packet Trains—Measurements and a New Model for Computer Network Traffic,” *IEEE J. on Selected Areas in Commun*., vol. 6, pp. 986–995, Sept. 1986.

**JAKOBSSON, M., and WETZEL, S.**: “Security Weaknesses in Bluetooth,” *Topics in Cryptology: CT-RSA 2001*, Berlin: Springer-Verlag LNCS 2020, pp. 176–191, 2001.

**JOEL, A.**: “Telecommunications and the IEEE Communications Society,” *IEEE Commun. Magazine*, 50th Anniversary Issue, pp. 6–14 and 162–167, May 2002.

**JOHNSON, D., PERKINS, C., and ARKKO, J.**: “Mobility Support in IPv6,” RFC 3775, June 2004.

**JOHNSON, D.B., MALTZ, D., and BROCH, J.**: “DSR: The Dynamic Source Routing Protocol for Multi-Hop Wireless Ad Hoc Networks,” *Ad Hoc Networking*, Boston: Addison-Wesley, pp. 139–172, 2001.

**JUANG, P., OKI, H., WANG, Y., MARTONOSI, M., PEH, L., and RUBENSTEIN, D.**: “Energy-Efficient Computing for Wildlife Tracking: Design Tradeoffs and Early Experiences with ZebraNet,” *SIGOPS Oper. Syst. Rev*., vol. 36, pp. 96–107, Oct. 2002.

**KAHN, D.**: *The Codebreakers*, 2nd ed., New York: Macmillan, 1995.

**KAMOUN, F., and KLEINROCK, L.**: “Stochastic Performance Evaluation of Hierarchical Routing for Large Networks,” *Computer Networks*, vol. 3, pp. 337–353, Nov. 1979.

**KARN, P.**: “MACA—A New Channel Access Protocol for Packet Radio,” *ARRL/CRRL Amateur Radio Ninth Computer Networking Conf*., pp. 134–140, 1990.

**KARN, P., and PARTRIDGE, C.**: “Improving Round-Trip Estimates in Reliable Transport Protocols,” *Proc. SIGCOMM ‘87 Conf*., ACM, pp. 2–7, 1987.

**KARP, B., and KUNG, H.T.**: “GPSR: Greedy Perimeter Stateless Routing for Wireless Networks,” *Proc. MOBICOM 2000 Conf*., ACM, pp. 243–254, 2000.

**KASIM, A.**: *Delivering Carrier Ethernet*, New York: McGraw-Hill, 2007.

**KATABI, D., HANDLEY, M., and ROHRS, C.**: “Internet Congestion Control for Future High Bandwidth-Delay Product Environments,” *Proc. SIGCOMM 2002 Conf*., ACM, pp. 89–102, 2002.

**KATZ, D., and FORD, P.S.**: “TUBA: Replacing IP with CLNP,” *IEEE Network Magazine*, vol. 7, pp. 38–47, May/June 1993.

**KAUFMAN, C., PERLMAN, R., and SPECINER, M.**: *Network Security*, 2nd ed., Engle-wood Cliffs, NJ: Prentice Hall, 2002.

**KENT, C., and MOGUL, J.**: “Fragmentation Considered Harmful,” *Proc. SIGCOMM ‘87 Conf*., ACM, pp. 390–401, 1987.

**KERCKHOFF, A.**: “La Cryptographie Militaire,” *J. des Sciences Militaires*, vol. 9, pp. 5–38, Jan. 1883 and pp. 161–191, Feb. 1883.

**KHANNA, A., and ZINKY, J.**: “The Revised ARPANET Routing Metric,” *Proc. SIGCOMM ‘89 Conf*., ACM, pp. 45–56, 1989.

**KIPNIS, J.**: “Beating the System: Abuses of the Standards Adoption Process,” *IEEE Commun. Magazine*, vol. 38, pp. 102–105, July 2000.

**KLEINROCK, L.**: “Power and Other Deterministic Rules of Thumb for Probabilistic Problems in Computer Communications,” *Proc. Intl. Conf. on Commun*., pp. 43.1.1–43.1.10, June 1979.

**KLEINROCK, L., and TOBAGI, F.**: “Random Access Techniques for Data Transmission over Packet-Switched Radio Channels,” *Proc. Nat. Computer Conf*., pp. 187–201, 1975.

**KOHLER, E., HANDLEY, H., and FLOYD, S.**: “Designing DCCP: Congestion Control without Reliability,” *Proc. SIGCOMM 2006 Conf*., ACM, pp. 27–38, 2006.

**KOODLI, R., and PERKINS, C.E.**: *Mobile Inter-networking with IPv6*, New York: John Wiley & Sons, 2007.

**KOOPMAN, P.**: “32-Bit Cyclic Redundancy Codes for Internet Applications,” *Proc. Intl. Conf. on Dependable Systems and Networks*., IEEE, pp. 459–472, 2002.

**KRISHNAMURTHY, B., and REXFORD, J.**: *Web Protocols and Practice*, Boston: Addison-Wesley, 2001.

**KUMAR, S., PAAR, C., PELZL, J., PFEIFFER, G., and SCHIMMLER, M.**: “Breaking Ciphers with COPACOBANA: A Cost-Optimized Parallel Code Breaker,” *Proc. 8th Cryptographic Hardware and Embedded Systems Wksp*., IACR, pp. 101–118, Oct. 2006.

**LABOVITZ, C., AHUJA, A., BOSE, A., and JAHANIAN, F.**: “Delayed Internet Routing Convergence,” *IEEE/ACM Trans. on Networking*, vol. 9, pp. 293–306, June 2001.

**LAM, C.K.M., and TAN, B.C.Y.**: “The Internet Is Changing the Music Industry,” *Commun. of the ACM*, vol. 44, pp. 62–66, Aug. 2001.

**LAOUTARIS, N., SMARAGDAKIS, G., RODRIGUEZ, P., and SUNDARAM, R.**: “Delay Tolerant Bulk Data Transfers on the Internet,” *Proc. SIGMETRICS 2009 Conf*., ACM, pp. 229–238, June 2009.

**LARMO, A., LINDSTROM, M., MEYER, M., PELLETIER, G., TORSNER, J., and WIEMANN, H.**: “The LTE Link-Layer Design,” *IEEE Commun. Magazine*, vol. 47, pp. 52–59, Apr. 2009.

**LEE, J.S., and MILLER, L.E.**: *CDMA Systems Engineering Handbook*, London: Artech House, 1998.

**LELAND, W., TAQQU, M., WILLINGER, W., and WILSON, D.**: “On the Self-Similar Nature of Ethernet Traffic,” *IEEE/ACM Trans. on Networking*, vol. 2, pp. 1–15, Feb. 1994.

**LEMON, J.**: “Resisting SYN Flood DOS Attacks with a SYN Cache,” *Proc. BSDCon Conf*., USENIX, pp. 88–98, 2002.

**LEVY, S.**: “Crypto Rebels,” *Wired*, pp. 54–61, May/June 1993.

**LEWIS, M.**: *Comparing, Designing, and Deploying VPNs*, Indianapolis, IN: Cisco Press, 2006.

**LI, M., AGRAWAL, D., GANESAN, D., and VENKATARAMANI, A.**: “Block-Switched Networks: A New Paradigm for Wireless Transport,” *Proc. NSDI 2009 Conf*., USENIX, pp. 423–436, 2009.

**LIN, S., and COSTELLO, D.**: *Error Control Coding*, 2nd ed., Upper Saddle River, NJ: Pearson Education, 2004.

**LUBACZ, J., MAZURCZYK, W., and SZCZYPIORSKI, K.**: “Vice over IP,” *IEEE Spectrum*, pp. 42–47, Feb. 2010.

**MACEDONIA, M.R.**: “Distributed File Sharing,” *IEEE Computer*, vol. 33, pp. 99–101, 2000.

**MADHAVAN, J., KO, D., LOT, L., GANGPATHY, V., RASMUSSEN, A., and HALEVY, A.**: “Google’s Deep Web Crawl,” *Proc. VLDB 2008 Conf*., VLDB Endowment, pp. 1241–1252, 2008.

**MAHAJAN, R., RODRIG, M., WETHERALL, D., and ZAHORJAN, J.**: “Analyzing the MAC-Level Behavior of Wireless Networks in the Wild,” *Proc. SIGCOMM 2006 Conf*., ACM, pp. 75–86, 2006.

**MALIS, A., and SIMPSON, W.**: “PPP over SONET/SDH,” RFC 2615, June 1999.

**MASSEY, J.L.**: “Shift-Register Synthesis and BCH Decoding,” *IEEE Trans. on Information Theory*, vol. IT-5, pp. 122–127, Jan. 1969.

**MATSUI, M.**: “Linear Cryptanalysis Method for DES Cipher,” *Advances in Cryptology—Eurocrypt 1993 Proceedings*, Berlin: Springer-Verlag LNCS 765, pp. 386–397, 1994.

**MAUFER, T.A.**: *IP Fundamentals*, Upper Saddle River, NJ: Prentice Hall, 1999.

**MAYMOUNKOV, P., and MAZIERES, D.**: “Kademlia: A Peer-to-Peer Information System Based on the XOR Metric,” *Proc. First Intl. Wksp. on Peer-to-Peer Systems*, Berlin: Springer-Verlag LNCS 2429, pp. 53–65, 2002.

**MAZIERES, D., and KAASHOEK, M.F.**: “The Design, Implementation, and Operation of an Email Pseudonym Server,” *Proc. Fifth Conf. on Computer and Commun. Security*, ACM, pp. 27–36, 1998.

**MCAFEE LABS**: *McAfee Threat Reports: First Quarter 2010*, McAfee Inc., 2010.

**MENEZES, A.J., and VANSTONE, S.A.**: “Elliptic Curve Cryptosystems and Their Implementation,” *Journal of Cryptology*, vol. 6, pp. 209–224, 1993.

**MERKLE, R.C., and HELLMAN, M.**: “Hiding and Signatures in Trapdoor Knapsacks,” *IEEE Trans. on Information Theory*, vol. IT-4, pp. 525–530, Sept. 1978.

**METCALFE, R.M.**: “Computer/Network Interface Design: Lessons from Arpanet and Ethernet,” *IEEE J. on Selected Areas in Commun*., vol. 11, pp. 173–179, Feb. 1993.

**METCALFE, R.M., and BOGGS, D.R.**: “Ethernet: Distributed Packet Switching for Local Computer Networks,” *Commun. of the ACM*, vol. 19, pp. 395–404, July 1976.

**METZ, C**: “Interconnecting ISP Networks,” *IEEE Internet Computing*, vol. 5, pp. 74–80, Mar.-Apr. 2001.

**MISHRA, P.P., KANAKIA, H., and TRIPATHI, S.**: “On Hop by Hop Rate-Based Congestion Control,” *IEEE/ACM Trans. on Networking*, vol. 4, pp. 224–239, Apr. 1996.

**MOGUL, J.C.**: “IP Network Performance,” in *Internet System Handbook*, D.C. Lynch and M.Y. Rose (eds.), Boston: Addison-Wesley, pp. 575–575, 1993.

**MOGUL, J., and DEERING, S.**: “Path MTU Discovery,” RFC 1191, Nov. 1990.

**MOGUL, J., and MINSHALL, G.**: “Rethinking the Nagle Algorithm,” *Comput. Commun. Rev*., vol. 31, pp. 6–20, Jan. 2001.

**MOY, J.**: “Multicast Routing Extensions for OSPF,” *Commun. of the ACM*, vol. 37, pp. 61–66, Aug. 1994.

**MULLINS, J.**: “Making Unbreakable Code,” *IEEE Spectrum*, pp. 40–45, May 2002. **NAGLE, J.**: “On Packet Switches with Infinite Storage,” *IEEE Trans. on Commun*., vol. COM-5, pp. 435–438, Apr. 1987.

**NAGLE, J.**: “Congestion Control in TCP/IP Internetworks,” *Computer Commun. Rev*., vol. 14, pp. 11–17, Oct. 1984.

**NAUGHTON, J.**: *A Brief History of the Future*, Woodstock, NY: Overlook Press, 2000.

**NEEDHAM, R.M., and SCHROEDER, M.D.**: “Using Encryption for Authentication in Large Networks of Computers,” *Commun. ofthe ACM*, vol. 21, pp. 993–999, Dec. 1978.

**NEEDHAM, R.M., and SCHROEDER, M.D.**: “Authentication Revisited,” *Operating Systems Rev*., vol. 21, p. 7, Jan. 1987.

**NELAKUDITI, S., and ZHANG, Z.-L.**: “A Localized Adaptive Proportioning Approach to QoS Routing,” *IEEE Commun. Magazine* vol. 40, pp. 66–71, June 2002.

**NEUMAN, C., and TS’O, T.**: “Kerberos: An Authentication Service for Computer Networks,” *IEEE Commun. Mag*., vol. 32, pp. 33–38, Sept. 1994.

**NICHOLS, R.K., and LEKKAS, P.C.**: *Wireless Security*, New York: McGraw-Hill, 2002.

**NIST**: “Secure Hash Algorithm,” U.S. Government Federal Information Processing Standard 180, 1993.

**NONNENMACHER, J., BIERSACK, E., and TOWSLEY, D.**: “Parity-Based Loss Recovery for Reliable Multicast Transmission,” *Proc. SIGCOMM ‘97 Conf*., ACM, pp. 289–300, 1997.

**NUCCI, A., and PAPAGIANNAKI, D.**: *Design, Measurement and Management of Large-Scale IP Networks*, Cambridge: Cambridge University Press, 2008.

**NUGENT, R., MUNAKANA, R., CHIN, A., COELHO, R., and PUIG-SUARI, J.**: “The CubeSat: The PicoSatellite Standard for Research and Education,” *Proc. SPACE 2008 Conf*., AIAA, 2008.

**ORAN, D.**: “OSI IS-IS Intra-domain Routing Protocol,” RFC 1142, Feb. 1990.

**OTWAY, D., and REES, O.**: “Efficient and Timely Mutual Authentication,” *Operating Systems Rev*., pp. 8–10, Jan. 1987.

**PADHYE, J., FIROIU, V., TOWSLEY, D., and KUROSE, J.**: “Modeling TCP Throughput: A Simple Model and Its Empirical Validation,” *Proc. SIGCOMM ‘98 Conf*., ACM, pp. 303–314, 1998.

**PALAIS, J.C.**: *Fiber Optic Commun*., 5th ed., Englewood Cliffs, NJ: Prentice Hall, 2004.

**PARAMESWARAN, M., SUSARLA, A., and WHINSTON, A.B.**: “P2P Networking: An Information-Sharing Alternative,” *IEEE Computer*, vol. 34, pp. 31–38, July 2001.

**PAREKH, A., and GALLAGHER, R.**: “A Generalized Processor Sharing Approach to Flow Control in Integrated Services Networks: The Multiple-Node Case,” *IEEE/ACM Trans. on Networking*, vol. 2, pp. 137–150, Apr. 1994.

**PAREKH, A., and GALLAGHER, R.**: “A Generalized Processor Sharing Approach to Flow Control in Integrated Services Networks: The Single-Node Case,” *IEEE/ACM Trans. on Networking*, vol. 1, pp. 344–357, June 1993.

**PARTRIDGE, C., HUGHES, J., and STONE, J.**: “Performance of Checksums and CRCs over Real Data,” *Proc. SIGCOMM ‘95 Conf*., ACM, pp. 68–76, 1995.

**PARTRIDGE, C., MENDEZ, T., and MILLIKEN, W.**: “Host Anycasting Service,” RFC 1546, Nov. 1993.

**PAXSON, V., and FLOYD, S.**: “Wide-Area Traffic: The Failure of Poisson Modeling,” *IEEE/ACM Trans. on Networking*, vol. 3, pp. 226–244, June 1995.

**PERKINS, C.**: “IP Mobility Support for IPv4,” RFC 3344, Aug. 2002.

**PERKINS, C.E.**: *RTP: Audio and Video for the Internet*, Boston: Addison-Wesley, 2003.

**PERKINS, C.E. (ed.)**: *Ad Hoc Networking*, Boston: Addison-Wesley, 2001.

**PERKINS, C.E.**: *Mobile IP Design Principles and Practices*, Upper Saddle River, NJ: Prentice Hall, 1998.

**PERKINS, C.E., and ROYER, E.**: “The Ad Hoc On-Demand Distance-Vector Protocol,” in *Ad Hoc Networking*, edited by C. Perkins, Boston: Addison-Wesley, 2001.

**PERLMAN, R.**: *Interconnections*, 2nd ed., Boston: Addison-Wesley, 2000.

**PERLMAN, R.**: *Network Layer Protocols with Byzantine Robustness*, Ph.D. thesis, M.I.T., 1988.

**PERLMAN, R.**: “An Algorithm for the Distributed Computation of a Spanning Tree in an Extended LAN,” *Proc. SIGCOMM ‘85 Conf*., ACM, pp. 44–53, 1985.

**PERLMAN, R., and KAUFMAN, C.**: “Key Exchange in IPsec,” *IEEE Internet Computing*, vol. 4, pp. 50–56, Nov.-Dec. 2000.

**PETERSON, W.W., and BROWN, D.T.**: “Cyclic Codes for Error Detection,” *Proc. IRE*, vol. 49, pp. 228–235, Jan. 1961.

**PIATEK, M., KOHNO, T., and KRISHNAMURTHY, A.**: “Challenges and Directions for Monitoring P2P File Sharing Networks—or Why My Printer Received a DMCA Takedown Notice,” *3rd Workshop on Hot Topics in Security*, USENIX, July 2008.

**PIATEK, M., ISDAL, T., ANDERSON, T., KRISHNAMURTHY, A., and VENKA-TARAMANI, V.**: “Do Incentives Build Robustness in BitTorrent?,” *Proc. NSDI2007 Conf*., USENIX, pp. 1–14, 2007.

**PISCITELLO, D.M., and CHAPIN, A.L.**: *Open Systems Networking: TCP/IP and OSI*, Boston: Addison-Wesley, 1993.

**PIVA, A., BARTOLINI, F., and BARNI, M.**: “Managing Copyrights in Open Networks,” *IEEE Internet Computing*, vol. 6, pp. 18–26, May- 2002.

**POSTEL, J.**: “Internet Control Message Protocols,” RFC 792, Sept. 1981.

**RABIN, J., and McCATHIENEVILE, C.**: “Mobile Web Best Practices 1.0,” W3C Recommendation, July 2008.

**RAMAKRISHNAM, K.K., FLOYD, S., and BLACK, D.**: “The Addition of Explicit Congestion Notification (ECN) to IP,” RFC 3168, Sept. 2001.

**RAMAKRISHNAN, K.K., and JAIN, R.**: “A Binary Feedback Scheme for Congestion Avoidance in Computer Networks with a Connectionless Network Layer,” *Proc. SIGCOMM ‘88 Conf*., ACM, pp. 303–313, 1988.

**RAMASWAMI, R., KUMAR, S., and SASAKI, G.**: *Optical Networks: A Practical Perspective*, 3rd ed., San Francisco: Morgan Kaufmann, 2009.

**RATNASAMY, S., FRANCIS, P., HANDLEY, M., KARP, R., and SHENKER, S.**: “A Scalable Content-Addressable Network,” *Proc. SIGCOMM 2001 Conf*., ACM, pp. 161–172, 2001.

**RIEBACK, M., CRISPO, B., and TANENBAUM, A.**: “Is Your Cat Infected with a Computer Virus?,” *Proc. IEEE Percom*, pp. 169–179, Mar. 2006.

**RIVEST, R.L.**: “The MD5 Message-Digest Algorithm,” RFC 1320, Apr. 1992.

**RIVEST, R.L., SHAMIR, A., and ADLEMAN, L.**: “On a Method for Obtaining Digital Signatures and Public Key Cryptosystems,” *Commun. of the ACM*, vol. 21, pp. 120–126, Feb. 1978.

**ROBERTS, L.G.**: “Extensions of Packet Communication Technology to a Hand Held Personal Terminal,” *Proc. Spring Joint Computer Conf*., AFIPS, pp. 295–298, 1972.

**ROBERTS, L.G.**: “Multiple Computer Networks and Intercomputer Communication,” *Proc. First Symp. on Operating Systems Prin*., ACM, pp. 3.1–3.6, 1967.

**ROSE, M.T.**: *The Simple Book*, Englewood Cliffs, NJ: Prentice Hall, 1994.

**ROSE, M.T.**: *The Internet Message*, Englewood Cliffs, NJ: Prentice Hall, 1993.

**ROWSTRON, A., and DRUSCHEL, P.**: “Pastry: Scalable, Distributed Object Location and Routing for Large-Scale Peer-to-Peer Storage Utility,” *Proc. 18th Int’l Conf. on Distributed Systems Platforms*, London: Springer-Verlag LNCS 2218, pp. 329–350, 2001.

**RUIZ-SANCHEZ, M.A., BIERSACK, E.W., and DABBOUS, W.**: “Survey and Taxonomy of IP Address Lookup Algorithms,” *IEEE Network Magazine*, vol. 15, pp. 8–23, Mar.-Apr. 2001.

**SALTZER, J.H., REED, D.P., and CLARK, D.D.**: “End-to-End Arguments in System Design,” *ACM Trans. on Computer Systems*, vol. 2, pp. 277–288, Nov. 1984.

**SAMPLE, A., YEAGER, D., POWLEDGE, P., MAMISHEV, A., and SMITH, J.**: “Design of an RFID-Based Battery-Free Programmable Sensing Platform,” *IEEE Trans. on Instrumentation and Measurement*, vol. 57, pp. 2608–2615, Nov. 2008.

**SAROIU, S., GUMMADI, K., and GRIBBLE, S.**: “Measuring and Analyzing the Characteristics of Napster & Gnutella Hosts,” *Multim. Syst*., vol. 9,, pp. 170–184, Aug. 2003.

**SCHALLER, R.**: “Moore’s Law: Past, Present and Future,” *IEEE Spectrum*, vol. 34, pp. 52–59, June 1997.

**SCHNEIER, B.**: *Secrets and Lies*, New York: John Wiley & Sons, 2004.

**SCHNEIER, B.**: *E-Mail Security*, New York: John Wiley & Sons, 1995.

**SCHNORR, C.P.**: “Efficient Signature Generation for Smart Cards,” *Journal of Cryptology*, vol.4, pp. 161–174, 1991.

**SCHOLTZ, R.A.**: “The Origins of Spread-Spectrum Communications,” *IEEE Trans. on Commun*., vol. COM-0, pp. 822–854, May 1982.

**SCHWARTZ, M., and ABRAMSON, N.**: “The AlohaNet: Surfing for Wireless Data,” *IEEE Commun. Magazine*, vol. 47, pp. 21–25, Dec. 2009.

**SEIFERT, R., and EDWARDS, J.**: *The All-New Switch Book*, NY: John Wiley, 2008.

**SENN, J.A.**: “The Emergence of M-Commerce,” *IEEE Computer*, vol. 33, pp. 148–150, Dec. 2000.

**SERJANTOV, A.**: “Anonymizing Censorship Resistant Systems,” *Proc. First Int’l Workshop on Peer-to-Peer Systems*, London: Springer-Verlag LNCS 2429, pp. 111–120, 2002.

**SHACHAM, N., and MCKENNY, P.**: “Packet Recovery in High-Speed Networks Using Coding and Buffer Management,” *Proc. INFOCOM Conf*., IEEE, pp. 124–131, June 1990.

**SHAIKH, A., REXFORD, J., and SHIN, K.**: “Load-Sensitive Routing of Long-Lived IP Flows,” *Proc. SIGCOMM ‘99 Conf*., ACM, pp. 215–226, Sept. 1999.

**SHALUNOV, S., and CARLSON, R.**: “Detecting Duplex Mismatch on Ethernet,” *Passive and Active Network Measurement*, Berlin: Springer-Verlag LNCS 3431, pp. 3135–3148, 2005.

**SHANNON, C.**: “A Mathematical Theory of Communication,” *Bell System Tech. J*., vol. 27, pp. 379–423, July 1948; and pp. 623–656, Oct. 1948.

**SHEPARD, S.**: *SONET/SDH Demystified*, New York: McGraw-Hill, 2001.

**SHREEDHAR, M., and VARGHESE, G.**: “Efficient Fair Queueing Using Deficit Round Robin,” *Proc. SIGCOMM ‘95 Conf*., ACM, pp. 231–243, 1995.

**SIMPSON, W.**: *Video Over IP*, 2nd ed., Burlington, MA: Focal Press, 2008.

**SIMPSON, W.**: “PPP in HDLC-like Framing,” RFC 1662, July 1994b.

**SIMPSON, W.**: “The Point-to-Point Protocol (PPP),” RFC 1661, July 1994a.

**SIU, K., and JAIN, R.**: “A Brief Overview of ATM: Protocol Layers, LAN Emulation, and Traffic,” *ACM Computer Communications Review*, vol. 25, pp. 6–20, Apr. 1995.

**SKOUDIS, E., and LISTON, T.**: *Counter Hack Reloaded*, 2nd ed., Upper Saddle River, NJ: Prentice Hall, 2006.

**SMITH, D.K., and ALEXANDER, R.C.**: *Fumbling the Future*, New York: William Morrow, 1988.

**SNOEREN, A.C., and BALAKRISHNAN, H.**: “An End-to-End Approach to Host Mobility,” *Int’l Conf. on Mobile Computing and Networking*, ACM, pp. 155–166, 2000.

**SOBEL, D.L.**: “Will Carnivore Devour Online Privacy,” *IEEE Computer*, vol. 34, pp. 87–88, May 2001.

**SOTIROV, A., STEVENS, M., APPELBAUM, J., LENSTRA, A., MOLNAR, D., OSVIK, D., and DE WEGER, B.**: “MD5 Considered Harmful Today,” *Proc. 25th Chaos Communication Congress*, Verlag Art d’Ameublement, 2008.

**SOUTHEY, R.**: *The Doctors*, London: Longman, Brown, Green and Longmans, 1848.

**SPURGEON, C.E.**: *Ethernet: The Definitive Guide*, Sebastopol, CA: O’Reilly, 2000.

**STALLINGS, W.**: *Data and Computer Communications*, 9th ed., Upper Saddle River, NJ: Pearson Education, 2010.

**STARR, T., SORBARA, M., COIFFI, J., and SILVERMAN, P.**: “DSL Advances,” Upper Saddle River, NJ: Prentice Hall, 2003.

**STEVENS, W.R.**: *TCP/IP Illustrated: The Protocols*, Boston: Addison Wesley, 1994. **STINSON, D.R.**: *Cryptography Theory and Practice*, 2nd ed., Boca Raton, FL: CRC Press, 2002.

**STOICA, I., MORRIS, R., KARGER, D., KAASHOEK, M.F., and BALAKRISHNAN, H.**: “Chord: A Scalable Peer-to-Peer Lookup Service for Internet Applications,” *Proc. SIGCOMM 2001 Conf*., ACM, pp. 149–160, 2001.

**STUBBLEFIELD, A., IOANNIDIS, J., and RUBIN, A.D.**: “Using the Fluhrer, Mantin, and Shamir Attack to Break WEP,” *Proc. Network and Distributed Systems Security Symp*., ISOC, pp. 1–11, 2002.

**STUTTARD, D., and PINTO, M.**: *The Web Application Hacker’s Handbook*, New York: John Wiley & Sons, 2007.

**SU, S.**: *The UMTS Air Interface in RF Engineering*, New York: McGraw-Hill, 2007.

**SULLIVAN, G., and WIEGAND, T.**: “Tree Algorithms for Packet Broadcast Channels,” *Proc. of the IEEE*, vol. 93, pp. 18–31, Jan. 2005.

**SUNSHINE, C.A., and DALAL, Y.K.**: “Connection Management in Transport Protocols,” *Computer Networks*, vol. 2, pp. 454–473, 1978.

**TAN, K., SONG, J., ZHANG, Q., and SRIDHARN, M.**: “A Compound TCP Approach for High-Speed and Long Distance Networks,” *Proc. INFOCOM Conf*., IEEE, pp. 1–12, 2006.

**TANENBAUM, A.S.**: *Modern Operating Systems*, 3rd ed., Upper Saddle River, NJ: Prentice Hall, 2007.

**TANENBAUM, A.S., and VAN STEEN, M.**: *Distributed Systems: Principles and Paradigms*, Upper Saddle River, NJ: Prentice Hall, 2007.

**TOMLINSON, R.S.**: “Selecting Sequence Numbers,” *Proc. SIGCOMM/SIGOPS Interprocess Commun. Workshop*, ACM, pp. 11–23, 1975.

**TUCHMAN, W.**: “Hellman Presents No Shortcut Solutions to DES,” *IEEE Spectrum*, vol. 16, pp. 40–41, July 1979.

**TURNER, J.S.**: “New Directions in Communications (or Which Way to the Information Age),” *IEEECommun. Magazine*, vol. 24, pp. 8–15, Oct. 1986.

**UNGERBOECK, G.**: “Trellis-Coded Modulation with Redundant Signal Sets Part I: Introduction,” *IEEE Commun. Magazine*, vol. 25, pp. 5–11, Feb. 1987.

**VALADE, J.**: *PHP* & *MySQL for Dummies*, 5th ed., New York: John Wiley & Sons, 2009.

**VARGHESE, G.**: *Network Algorithmics*, San Francisco: Morgan Kaufmann, 2004.

**VARGHESE, G., and LAUCK, T.**: “Hashed and Hierarchical Timing Wheels: Data Structures for the Efficient Implementation of a Timer Facility,” *Proc. 11th Symp. on Operating Systems Prin*., ACM, pp. 25–38, 1987.

**VERIZON BUSINESS**: *2009 Data Breach Investigations Report*, Verizon, 2009.

**VITERBI, A.**: *CDMA: Principles of Spread Spectrum Communication*, Englewood Cliffs, NJ: Prentice Hall, 1995.

**VON AHN, L., BLUM, B., and LANGFORD, J.**: “Telling Humans and Computers Apart Automatically,” *Commun. of the ACM*, vol. 47, pp. 56–60, Feb. 2004.

**WAITZMAN, D., PARTRIDGE, C., and DEERING, S.**: “Distance Vector Multicast Routing Protocol,” RFC 1075, Nov. 1988.

**WALDMAN, M., RUBIN, A.D., and CRANOR, L.F.**: “Publius: A Robust, Tamper-Evident, Censorship-Resistant Web Publishing System,” *Proc. Ninth USENIX Security Symp*., USENIX, pp. 59–72, 2000.

**WANG, Z., and CROWCROFT, J.**: “SEAL Detects Cell Misordering,” *IEEE Network Magazine*, vol. 6, pp. 8–9, July 1992.

**WANT, R.**: *RFID Explained*, San Rafael, CA: Morgan Claypool, 2006.

**WARNEKE, B., LAST, M., LIEBOWITZ, B., and PISTER, K.S.J.**: “Smart Dust: Communicating with a Cubic Millimeter Computer,” *IEEE Computer*, vol. 34, pp. 44–51, Jan. 2001.

**WAYNER, P.**: *Disappearing Cryptography: Information Hiding, Steganography, and Watermarking*, 3rd ed., San Francisco: Morgan Kaufmann, 2008.

**WEI, D., CHENG, J., LOW, S., and HEGDE, S.**: “FAST TCP: Motivation, Architecture, Algorithms, Performance,” *IEEE/ACM Trans. on Networking*, vol. 14, pp. 1246–1259, Dec. 2006.

**WEISER, M.**: “The Computer for the Twenty-First Century,” *Scientific American*, vol. 265, pp. 94–104, Sept. 1991.

**WELBOURNE, E., BATTLE, L., COLE, G., GOULD, K., RECTOR, K., RAYMER, S., BALAZINSKA, M., and BORRIELLO, G.**: “Building the Internet of Things Using RFID,” *IEEE Internet Computing*, vol. 13, pp. 48–55, May 2009.

**WITTENBURG, N.**: *Understanding Voice Over IP Technology*, Clifton Park, NY: Delmar Cengage Learning, 2009.

**WOLMAN, A., VOELKER, G., SHARMA, N., CARDWELL, N., KARLIN, A., and LEVY, H.**: “On the Scale and Performance of Cooperative Web Proxy Caching,” *Proc. 17th Symp. on Operating Systems Prin*., ACM, pp. 16–31, 1999.

**WOOD, L., IVANCIC, W., EDDY, W., STEWART, D., NORTHAM, J., JACKSON, C., and DA SILVA CURIEL, A.**: “Use of the Delay-Tolerant Networking Bundle Protocol from Space,” *Proc. 59th Int’l Astronautical Congress*, Int’l Astronautical Federation, pp. 3123–3133, 2008.

**WU, T.**: “Network Neutrality, Broadband Discrimination,” *Journal on Telecom. and High-Tech. Law*, vol. 2, pp. 141–179, 2003.

**WYLIE, J., BIGRIGG, M.W., STRUNK, J.D., GANGER, G.R., KILICCOTE, H., and KHOSLA, P.K.**: “Survivable Information Storage Systems,” *IEEE Computer*, vol. 33, pp. 61–68, Aug. 2000.

**YU, T., HARTMAN, S., and RAEBURN, K.**: “The Perils of Unauthenticated Encryption: Kerberos Version 4,” *Proc. NDSS Symposium*, Internet Society, Feb. 2004.

**YUVAL, G.**: “How to Swindle Rabin,” *Cryptologia*, vol. 3, pp. 187–190, July 1979.

**ZACKS, M.**: “Antiterrorist Legislation Expands Electronic Snooping,” *IEEE Internet Computing*, vol. 5, pp. 8–9, Nov.-Dec. 2001.

**ZHANG, Y., BRESLAU, L., PAXSON, V., and SHENKER, S.**: “On the Characteristics and Origins of Internet Flow Rates,” *Proc. SIGCOMM 2002 Conf*., ACM, pp. 309–322, 2002.

**ZHAO, B., LING, H., STRIBLING, J., RHEA, S., JOSEPH, A., and KUBIATOWICZ, J.**: “Tapestry: A Resilient Global-Scale Overlay for Service Deployment,” *IEEE J. on Selected Areas in Commun*., vol. 22, pp. 41–53, Jan. 2004.

**ZIMMERMANN, P.R.**: *The Official PGP User’s Guide*, Cambridge, MA: M.I.T. Press, 1995a.

**ZIMMERMANN, P.R.**: *PGP: Source Code and Internals*, Cambridge, MA: M.I.T. Press, 1995b.

**ZIPF, G.K.**: *Human Behavior and the Principle of Least Effort: An Introduction to Human Ecology*, Boston: Addison-Wesley, 1949.

**ZIV, J., and LEMPEL, Z.**: “A Universal Algorithm for Sequential Data Compression,” *IEEE Trans. on Information Theory*, vol. IT–3, pp. 337–343, May 1977.

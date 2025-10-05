## Chapter 12. Management Architectures for DS Platforms

Distribution provides better resilience, scale benefits, and failure domain localization when compared to centralized systems. However, it poses a challenge of coherently managing a large number of DSNs. A well-architected management control plane not only provides management simplicity, but also offers a comprehensive view of the system and clusterwide insights. Simplification comes from providing intuitive abstractions of user concepts for configuring the system, showing relevant information for operationalizing the infrastructure, and extracting meaningful information from the vast amount of data collected over time. A comprehensive view of the system makes it easier to operate and aggregate information while hiding the unwanted details. A management control plane can provide insights from correlation and offer better visualization to operate infrastructure services efficiently.

[Figure 12-1](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch12.xhtml#ch12fig1) describes the components of a distributed management control plane. To ensure resiliency and scale, DSN management system should be implemented as a distributed application running on multiple “control nodes.”

![A figure depicts the communication between DSNs and the distributed services management control plane.](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9780136624226/files/graphics/12fig01.jpg)

**FIGURE 12-1** Distributed Services Management Control Plane

A network model is shown, where a network fabric cloud is present above the host DSNs. The host DSNs communicate with the distributed service management control plane. The distributed services management control plane consists of several control nodes.

As shown in [Figure 12-1](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch12.xhtml#ch12fig1), DSNs are network managed, where each DSN communicates with the management plane over an IP network. Managing DSNs from the network is similar to how infrastructure is managed in a public cloud, separating consumers of infrastructure from the infrastructure itself.

This chapter describes the architectural elements of a distributed management services control plane and concludes with a proposed architecture, combining various concepts for a distributed management control plane.

### 12.1 Architectural Traits of a Management Control Plane

If a management control plane were built like a modern multi-tier scale-out distributed application, then it would inherit all the benefits of such applications. Although the benefits, such as scale, composability, high availability, and so on are enticing, the challenges of debuggability, distribution, synchronization, and so on can be complex and time consuming. Simplification requires shielding the underlying complexity, especially for clusterwide services that require managing and coordinating multiple DSNs.

An architectural approach to address these challenges would offer a solution that can easily withstand the complexities that arise from scale, distribution, network partitioning, and operationalization. The elements of such a system would allow users to specify the intent declaratively and be built using a set of microservices. Consequently, they would provide a malleable cloud native application that could be deployed not only on-premise but also on any public cloud microservices platform. Microservices architecture can offer many benefits, such as decentralization, scale, upgradeability, resilience, and independence, assuming common pitfalls of application design are avoided. Generally speaking, if a microservice is built to serve a business function, it should offer a clean set of APIs that serves a user-visible feature and is likely to provide a simpler implementation. Therefore, a top-down approach, where business functions drive the APIs and functional abstraction, is preferred over a bottom-up approach of exposing engineering design to become a business function.

Although the term *service* can be confusing in the context of distributed services platform, this chapter uses the term *business function* to mean what really is offered as an infrastructure service by distributed services platform, and the term *service* may be referred to as a microservice that implements a business function.

### 12.2 Declarative Configuration

A declarative configuration model allows users to specify the desired intent while the system works toward achieving the desired intent. This abstraction offers a simpler configuration model to the user as the system constantly works toward reconciling the desired intent with the reality. In contrast, an imperative configuration model takes an immediate action before returning a success or a failure to the user. Imperative configuration models cannot be accurately implemented when a system grows to thousands of DSNs, some dynamically joining and leaving the system. The advantages of declarative configuration are as follows:

- System automates resource tracking instead of user polling for resource availability to instantiate the policy

- System can be optimized for policy distribution to the available DSNs

- Omission of tracking external dependencies; for example, workloads coming up and going away, integration with ecosystem partners, and so on

- Automation of failure handling, such as network disconnection, partitioning, reconciliation upon such events, and moving toward zero touch configuration management

- Scheduling future work; for example, upgrades and monitoring based on events

These advantages make it easier for the user to operationalize the system. In turn, the system offers full visibility about the status of the instantiated behavior for the specified intent. [Figure 12-2](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch12.xhtml#ch12fig2) describes the mechanics of event watchers, a key concept in implementing a reconciliation loop.

![A figure shows the implementation of declarative configuration.](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9780136624226/files/graphics/12fig02.jpg)

**FIGURE 12-2** Implementation of Declarative Configuration

In a network model, various DSNs (that watch for DSN specific configuration) are connected to the distributed services management control plane (that is the management control plane serves the service-specific watchers). The distributed services management control plane consists of services A, B, C, API service, and a configuration store. The services A, B, and C are interconnected to the API service. The API service is interconnected to the configuration store and also to the User configuration intent.

The declarative configuration model is better suited for systems that offer generic resources at scale; for example, software-like scalable resources on DSNs. Not having rigid limits or specialized resources allows the control plane to accept the intent with a reasonable guarantee that the admitted policy will be instantiated, as long as there are no connectivity issues. Even upon disconnection and subsequent reconnection, the system could successfully reconcile the desired intent. The architecture to achieve declarative configuration requires upfront validation of any acceptable configuration, including syntax, semantics, authentication, authorization, and relational validations. The expectation from the system is that once the intent is admitted into the system, it can’t be given back to the user for amendments. After this time, it becomes the system’s responsibility to save and act upon the configuration. System services watch for user configuration changes and run reconciliation loops to instantiate the latest intent.

Declarative configuration is easy to back up and restore because the intent is inherently independent of the order in which the configuration was done. This presents a user with a simpler way to describe, copy, back up, and make changes to the configuration. Implementing transactional semantics in a declarative configuration also ensures that validation can be done across multiple objects together instead of having individual API objects configured into the system.

### 12.3 Building a Distributed Control Plane as a Cloud-Native Application

Cloud-native applications are portable, modular, exposed via APIs, scalable, and are policy driven. The most important aspect is their portability, making it easy to migrate between private and public clouds. The Cloud Native Computing Foundation (CNCF) [[1](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch12.xhtml#ch12ref1)] is a governing body under the Linux Foundation for many open source projects, which helps developers build cloud-native applications. Cloud-native applications are portable because they are implemented using normalized assumptions about the infrastructure resources they need to run on. They are built as stateless applications and, therefore, are easy to autoscale. They are built using functional component boundaries that interact with each other using backward compatible APIs, making them easy to grow independently. The cloud-native ecosystem provides a plethora of frameworks and tools to build, operate, and run such applications. Also, the vibrant open source community and the prevalent use in so many products makes it more practical to build the management system as a cloud-native application. The remainder of this section discusses the applicability of cloud-native concepts as it relates to a distributed services management control plane.

Cloud-native applications are always built as containerized applications to allow for decoupling application packaging from the underlying OS distribution. Containerization allows building applications in the developer’s language of choice, be it Golang, Rust, C++, Python, or a new language that is yet to be developed. Containerized applications can be run on a microservices orchestration platform, such as Kubernetes [[2](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch12.xhtml#ch12ref2)], to manage the life cycle of the application. The benefits of containerization, such as use of Docker [[3](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch12.xhtml#ch12ref3)], and microservice platforms, such as Kubernetes or Mesos [[4](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch12.xhtml#ch12ref4)], are well known (see [Chapter 3](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch03.xhtml#ch03), “[Virtualization](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch03.xhtml#ch03)”). One obvious benefit for building an application as a set of containerized microservices is to speed up the feature delivery, while leveraging mature open source software to run, upgrade, and scale.

Cloud-native applications use REST API or an RPC framework to communicate with each other (see [sections 3.4.1](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch03.xhtml#ch03lev2sec4_1) and [3.4.2](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch03.xhtml#ch03lev2sec4_2)). gRPC [[5](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch12.xhtml#ch12ref5)] is an RPC framework, often built alongside Google protocol buffers (protobuf) [[6](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch12.xhtml#ch12ref6)], to define the RPC messages and marshalling and demarshalling of the messages between applications. Using protobufs can also allow using various tools to generate client API bindings, documentation, and other code for tools to help manage the services. Although JSON over REST is a generic user-friendly API, gRPC with protobuf employs binary encoding to offer efficiency and performance.

Cloud-native applications are built as scale-out applications, which share the load across multiple instances. To share the load of incoming API requests, microservices are often accessed via a network or an application load balancer. A load balancer function can be implemented as a proxy software, such as Envoy [[7](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch12.xhtml#ch12ref7)] or Nginx [[8](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch12.xhtml#ch12ref8)], intercepting the messages between two applications using service discovery mechanisms. Alternatively, a load balancer can also be a logical function that is packaged as a library within the application itself, often referred to as client-side load balancing. Client-side load balancing is implemented as part of the RPC layer; for example using Finagle [[9](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch12.xhtml#ch12ref9)] or gRPC. Client-side load balancing offers lower latency and efficiency than an external Network Load Balancer (NLB) because it avoids one extra hop, but it requires application architecture to use the prescribed RPC mechanism. In contrast, independently running load balancers can be inserted in an application topology without the need to change the applications.

Cloud-native applications need sophisticated troubleshooting tooling because of their distributed nature. To trace the path traversed by messages between microservices, the tooling must carry the message context across the RPC messages. Then it can correlate message context information with observed failures and help the developer diagnose problems. Tools such as OpenZipkin [[10](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch12.xhtml#ch12ref10)] utilize the OpenTracing [[11](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch12.xhtml#ch12ref11)] protocol and methods to offer integration with gRPC and/or HTTP layers to allow message tracing across services and improved troubleshooting capabilities.

To summarize, building a management control plane as a cloud-native application is not only beneficial for the features it offers, but also speeds development given the mature, open source tooling available.

### 12.4 Monitoring and Troubleshooting

Observability and troubleshooting capabilities are essential in the management control plane as well as the architectural aspects required to build these capabilities natively in the control plane.

DSNs can be expected to provide highly scalable data paths; for example, hundreds of thousands of network sessions, a large number of RDMA sessions, and storage service functions. The amount of data gathered on just one DSN can be inundating. Therefore, the amount of data collected within the entire cluster, consisting of thousands of DSNs, would need sophisticated data collection, query, and presentation techniques. Use of a distributed database as a part of a management control plane helps with increased scale and redundancy. In addition, using multiple kinds of databases may be needed, such as a:

- **Time series database:** To help observe usage and trends over time

- **Search database:** To help with arbitrary text search of events, logs, and configuration

- **SQL database:** To help manage system inventory

- **Graph database:** To help track data relationships

Most of these databases offer a query language and mathematical functions to help perform aggregate functions to get meaningful insights.

The mechanisms discussed here can be useful for both monitoring applications on the system and for troubleshooting the system itself. For example, trends on resource usage or failures can proactively provide hints about the potential problems. The data collected about applications can provide insights such as top users of the resources, workloads with highest security violations, and network or storage latency between applications. Given that the management control plane has full view of all workloads and their locality, it can offer automation tools to troubleshoot the network-wide issues by examining the collected data or sending stimulus data and measuring the behavior within the network. This can help troubleshoot network issues, storage performance measurements, or provide data that can lead to identifying and addressing anomalies.

Architecturally, the system should be designed to proactively notify the user when the first signs of the problem are detected. Traditional “reactive troubleshooting” takes place only after a problem (soft failure or a hard failure) has surfaced and requires domain expertise to properly diagnose. The availability of historical data can play a significant role here in helping determine anomalies, thus leading to a proactive nature of system diagnostics and troubleshooting application connectivity, performance, or latency. The notion of normalcy and definition of exception path is very relative to deployment and user. Therefore, providing a way for the user to define or help learn the anomaly could train the system, possibly by leveraging self-learning mechanisms to take out any false positives.

To promote easy consumption of data, the metrics should be associated with a configured object. This makes metrics a first-class concept available for every configured object, even though metrics can be internally managed differently from the status of an object.

### 12.5 Securing the Management Control Plane

The management control plane communicates highly sensitive information to the DSNs over an IP network. If this information is tampered with, blocked by, or even read by unauthorized actor, it can lead to a severe security lapse and implications that can have long-lasting consequences. Although the typical recommendation is to keep the management network isolated from the rest of the infrastructure, it breaks the security model if the management network is compromised. Instead, a security framework for the management control plane should be responsible for ensuring the identity management, authentication, authorization, and encryption of the traffic independent of the underlying network connectivity and assumptions.

Identity establishment and identity verification is the most important first step in ensuring the security posture of the system. Distributed entities like DSNs and control plane software components would need to be given cryptographic identities. Then, a mechanism should be in place to have these entities prove their identity to each other before they start to exchange information. First, DSNs should be able to prove their cryptographic identity, using an X.509 certificate, for example, that the management control plane can trust. DSNs can use hardware security modules such as the Trusted Platform Module (TPM) [[12](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch12.xhtml#ch12ref12)] or latch on to the trust chain of underlying booted root of trust to assert their identity. Second, microservice applications running within the control plane across a set of compute nodes need to provide their identity to each other to establish trust. Secure Production Identity Framework for Everyone (SPIFFE) [[13](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch12.xhtml#ch12ref13)] is an open effort that attempts to standardize the application identity and mechanisms to perform mutual authentication among those entities using a common root of trust before they communicate over an untrusted network.

Using mutual Transport Layer Security (TLS) for all communication between control plane services and DSNs should be an integral component of the security architecture. RPC frameworks, such as gRPC, support TLS natively, paving a way to secure the communication. The management control plane must become the certificate authority (CA) for all the components and is also responsible for providing mechanisms to sign the certificates; the system should ensure that this can be done without ever having to share the private keys. TLS is proven to provide security across the Internet; it ensures all user data is encrypted and can never be eavesdropped on by a middle man. It also provides non-repudiation for auditing and traceability. [Figure 12-3](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch12.xhtml#ch12fig3) shows the key management and TLS between various entities within the cluster.

![A figure shows a security model of management control plane.](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9780136624226/files/graphics/12fig03.jpg)

**FIGURE 12-3** Security Model of Management Control Plane

In the network model, various DSNs (stored with secure private keys) are interconnected to the distributed services management control plane via TLS. The distributed services management control plane consists of three services A, B, C (each provided with secure private key), an API service, and a configuration store. Each DSN is interconnected to the services A, B, and C via TLS. The services A, B, and C are interconnected to the API service via TLS. The API service is interconnected to the configuration store and also to REST APIs over TLS (with RBAC).

In addition to authentication, an authorization layer is needed to help ensure proper permissions for communication; for example, a list of permissible connections and API operations. Typically, one doesn’t need a very elaborate authorization policy between the components of a microservices platform, but a basic authorization would define which communication is permitted, respecting the application layering of the infrastructure.

The Role-Based Access Control (RBAC) layer defines what an external user of the management control plane can or cannot do. An external user can be a human making modifications to the control plane via GUI or CLI, or it can be an automation script or software component interacting with the system using a REST or gRPC API. The control plane must define the notion of users, roles, permissions and allow assigning permissions to the roles and eventually users having access to those roles. The users may need to be obtained from the organization’s database, using integration with Lightweight Directory Access Protocol (LDAP) servers. Furthermore, the granularity of these roles needs to be sufficient to permit a variety of operations on individual objects or object categories. Naturally, keeping an audit log of all API calls into the system also becomes an important aspect of authorization.

### 12.6 Ease of Deployment

A management control plane has multiple independent services, making it complex to deploy and operate. However, a well-designed system will be easy to install, configure, and operationalize, while hiding the underlying complexity. Unwanted details are often forced upon users, possibly exposing them to architectural deficiencies. Designing for simplicity does not necessarily require trade-offs around security, functionality, scalability, and performance. This section discusses the architectural elements of the management control plane that can make it simple to use, yet not compromise on other attributes such as security, scale, and so on.

To make it easy to deploy the control plane software, the packaging should include all components with minimal configuration to bootstrap the control plane. This can be done if the software is bundled to bootstrap easily on a physical or virtual machine. After the control plane is started, it then can kickstart all the required services and provide a startup wizard to perform day-0 setup. In situations when a user has brought up a microservices deployment platform such as Kubernetes, the management control plane can be deployed using tools like Helm [[14](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch12.xhtml#ch12ref14)]. Deploying on Kubernetes can be easier in a public cloud as most of the public clouds provide a managed Kubernetes service.

DSNs are expected to be added or removed dynamically from the cluster, presenting another day-0 operation requiring simplification to accommodate detection, discovery, and admission of DSNs into the management control plane. When a DSN is brought up, it must discover the management control domain-name address to be able to communicate with it. This discovery can be automated by having a network service that is expected to be always up, either in a public cloud or on-premise responding to the beacons sent by DSNs. Other network-based discovery mechanisms, such as DHCP service, may also be employed for DSN to discover the control plane.

Simplification of day-1 and day-2 operations, such as configuring, troubleshooting, upgrading, and so on, require many architectural considerations. Specifically, the system must provide an object model that accurately captures business functions, offers visibility into the system, and allows ease of migrating to new features in a backward-compatible way. The system should also build ample API integration points and client libraries ensuring smoother integration into existing software tools. Most of the software and systems, both commercial and open source software used in deployment and operations, provide APIs and infrastructure to add plugins; for example, pre-baked recipes to be used with configuration management tools such as Ansible, Chef, or Puppet. Integration with syslog importers can help users unify their logging analysis tools. Creating recipes for application deployment and for upgrade operations, using tools such as Helm or charts for Kubernetes, can help users to use validated packaging. Many users bring their own metrics analysis tools. Therefore, design goals should focus on easy integration of metrics and schema with visualization tools such as Grafana, or Kibana. Providing plugins for integrated stacks, such as ELK [[15](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch12.xhtml#ch12ref15)] or TICK [[16](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch12.xhtml#ch12ref16)], could help, if applicable.

To simplify operations, troubleshooting and diagnosis tools offered by the management control plane must provide an end-to-end perspective and stay operational even in the case of partial failures within the system itself. To achieve the highest resilience, the diagnostic software and tools require operating within a context of “reserved” resource allocation and isolation, so that diagnostic tools can operate even when the system is under unusual stress, failure, or resource exhaustion. Ensuring stability and reliability of diagnostic tools is paramount for troubleshooting the broader infrastructure via the management control plane. Conversely, the diagnostic tools should not cause any instability. [Section 12.4](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch12.xhtml#ch12lev1sec4) discusses some of the tools that can be used to troubleshoot infrastructure problems.

### 12.7 Performance and Scale

Scaling a distributed system is a topic of heavy research and exploration [[17](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch12.xhtml#ch12ref17)] with a focus on achieving consensus, replication, high availability, transactions, concurrency, performance, and scalability. The techniques include distributed consensus building, lock-free synchronization, workload distribution sharding, caching and cache invalidation, division of a work with parallelism, data replication consistency, and so on. A discussion on these techniques is outside the scope of this book; readers are encouraged to look at the references. These techniques have been successfully used in consistent key-value store implementations such as Zookeeper [[18](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch12.xhtml#ch12ref18)] or Etcd [[19](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch12.xhtml#ch12ref19)], distributed time series databases such as Prometheus [[20](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch12.xhtml#ch12ref20)] or InfluxDB [[21](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch12.xhtml#ch12ref21)], distributed NoSQL databases such as Cassandra [[22](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch12.xhtml#ch12ref22)], MongoDB [[23](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch12.xhtml#ch12ref23)] or Redis [[24](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch12.xhtml#ch12ref24)], distributed SQL databases such as CockroachDB [[25](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch12.xhtml#ch12ref25)], distributed object stores such as Minio [[26](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch12.xhtml#ch12ref26)], distributed search DBs such as ElasticDB [[27](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch12.xhtml#ch12ref27)], and distributed message buses, such as Kafka [[28](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch12.xhtml#ch12ref28)] or NATS [[29](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch12.xhtml#ch12ref29)]. The plethora of the tooling is somewhat inundating, but as we get deeper into the use cases and their architectures, one thing becomes clear: Different solutions exist to solve different business problems. Therefore, choosing the right database, key-value store, or message bus should be based on the nature of data produced by the DSNs and within the management control plane. In fact, microservices architecture calls for using these elements for individual business functions instead of combining all the requirements into a single back-end database. Splitting these functional aspects not only allows the independent scaling of each business function, but also facilitates horizontal scaling of each entity, improving control plane performance. Furthermore, architecturally it allows the control plane to solve scalability by merely adding more general-purpose compute resources, without creating a single point of failure or performance bottleneck.

The scale of a distributed platform is defined by the following factors:

- **Number of DSNs:** This measures the control plane’s ability to serve a large set of DSNs. Each DSN is a managed entity in itself and, therefore, requires additional work to manage their life cycle, such as discovery, monitoring, upgrading, and so on. Every DSN within the cluster increases the management plane’s burden to handle more events, generate more metrics, and distribute policies to a larger set of entities. On the other hand, this scale parameter should be as high as possible to avoid splitting the cluster, which is a burden for the operator. However, note that multiple management domains or clusters may be applicable where there are limits based on connectivity regions or the maximum size of the failure domain.

- **Number of objects:** Configuration is typically managed using Create, Read, Update, and Delete (CRUD) operations on published REST APIs. Each configured object represents a conceptual instance of the desired function. Therefore, increases in cluster size or workload density result in more objects being instantiated within the system. More objects result in more data to be saved, increased number of metrics, and, most importantly, an increase in the quantity of objects to be distributed to the applicable recipients.

- **API performance:** This is the control plane’s ability to serve a large number of user requests per second. More is always better; however, care should be taken to determine the nature of requests on various objects. To serve an API request successfully, the management plane would need to authenticate, authorize, and perform validation checks on the API call. Thus, scaling the rate of APIs may require running multiple entry points into the cluster, and/or improving the caching to serve the read operations much faster.

- **Metrics scale:** This is the control plane’s ability to ingest the millions of metrics produced every second by the system either on DSNs or within the control plane and requires selecting an appropriate metrics database with enough redundancy and horizontal scale built with sharding methodologies. Time series databases (TSDBs) are a good choice to manage metrics and perform queries on the data, perform aggregation functions, and so on.

- **Events scale:** This is the control plane’s ability to handle the vast number of events generated by various distributed entities in the cluster. The aspects of handling the scale of events in a distributed system include dealing with the sheer volume of the events generated by various entities in the system, and the control plane’s ability to find user-actionable tasks from those events. In addition, all events and logs may need to be exported to an external collector. When events are produced at very large scale, the greatest challenge becomes finding ways to take meaningful action and ways to create correlation between certain events, system state, metrics, and user actions. This correlation and analysis is best done using sophisticated tooling, described earlier in this section.

- **Data plane scale:** This is the management control plane’s ability to handle the data generated by the data path; for example, metrics, logs, searchable records of data path activity, and so on. Ultimately, the purpose of the distributed services platform is to provide services in the data path for the workloads; therefore, the ability to deal with a scalable data path is critical.

Later in the chapter, we discuss how to test the scale of such a system.

### 12.8 Failure Handling

A system is incomplete without its ability to handle various internal or external failures. Therefore, architecting a system with the assumption that failures will occur is the most natural way of dealing with the problem. Although failure handling complicates the system architecture, it is required to ensure reliable operation.

The mechanisms to handle failures vary depending on the problem, but the balance between providing redundancy, efficiency, and performance is important. These mechanisms include:

- **Data replication:** Data replication can avoid loss of data due to a single failure. Of course, n-way replication may result in better resiliency, but at the cost of reduced performance. Most of the distributed databases that we discuss in this chapter are capable of replicating the data and continue to be fully operational in case of failure(s).

- **Network redundancy:** Redundant network connectivity can easily handle link failure, network element failure, or a DSN failure and will ensure the infrastructure can converge using alternative connectivity with minimal disruption.

- **Resource acquisition on demand:** Providing the system with extra processing capacity ensures that system can overflow into spare available resources that can be acquired on demand. Implementing the control plane as a cloud-native application, such as via Kubernetes, helps with resource acquisition and scheduling on demand by the infrastructure software.

- **Reconciliation:** Network failures can result in distributed entities going out of sync. After the network connectivity is restored, distributed entities must reconcile with the latest user intent. As discussed earlier, a declarative model helps distributed entities reconcile the system to the latest intent.

- **In-service upgrade:** Rollout of newer versions of the management control plane can be done leveraging the underlying features of the cloud-native infrastructure capabilities, such as via Kubernetes, to upgrade the microservices components one at a time to allow for the older version to be phased out without requiring any disruption to the applications. Doing this upgrade requires building backward-compatible APIs so that applications don’t need to be upgraded together. We discuss more about API architecture in the subsequent section.

The minimum expectation from a management system is to handle any single point of failure without disruption and be able to recover the system from multiple simultaneous failures with minimal or no impact to the users. There are nonrecoverable failures and recoverable failures. Recoverable failures generally happen due to software malfunction such as a process crash; a correctable human error such as a configuration error; or connectivity issues such as network miscabling. Nonrecoverable failures happen due to hardware failures, such as memory errors, disk failures, transmission device failures, or power supply failures. Nonrecoverable failures can be hard failures or soft failures. A hard failure is abrupt and typically unpredictable; for example, system halt. Therefore, failure handling must take into consideration that it may never get a chance to predict the failure. Failures that start slow and grow over time are referred to as soft failures (not to be confused with soft*ware* failures). Examples include deterioration in a disk’s life, bit errors increasing in the I/O hardware, or a software memory leak slowly degrading the usability of the system. Ideally, soft failures can be detected based on trends of relevant metrics going in a specific direction (either non-increasing or non-decreasing, depending on the metric).

Placing all control nodes behind a load balancer with a discoverable IP address ensures the best possible serviceability of the management control plane. Doing so allows the serving of the external users without any disruption and can also improve the overall performance by sharing the incoming API requests among multiple instances of the service.

### 12.9 API Architecture

APIs are the user-facing programmable interface into the management control plane. Graphical user interface (GUI) and command line interface (CLI) use the APIs to provide other mechanisms to manage the system. APIs ought to be simple to use, intuitive to understand, be highly performant, and ensure security with authenticated and authorized access into the system. The APIs must also be backward compatible, self-documenting, and scalable. [Figure 12-4](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch12.xhtml#ch12fig4) describes a sample set of components comprising the API layer of the management control plane.

![A figure depicts the functionality and architecture of API services.](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9780136624226/files/graphics/12fig04.jpg)

**FIGURE 12-4** Functionality and Architecture of API Service

A distributed services management control plane is shown. 'N' number of services are interconnected to the distributed configuration store. The distributed configuration store is in turn interconnected to 'n' number of API services. Each API service is in turn interconnected to a load balance. The load balancer is interconnected to the user configuration intent. The API services are listed as follows: authentication, authorization, validation, caching, services internal users, and serves external users.

Now, we discuss the design choices to achieve these desired attributes:

- **Simple to use:** System APIs should be easy to learn; for example, REST/JSON APIs may be a familiar interface to many users. Another important aspect of making the APIs simpler is if the documentation itself is available as part of the API, which describes the objects and their fields. Although not always possible, if the structure of the API objects uses a familiar semantic structure, it could simplify understanding the APIs. Providing client bindings in popular languages to access the APIs can ease the integration challenges. The importance of APIs returning meaningful error messages can be very helpful in improving the API usability. Using automation tools to generate the client bindings or documentation can also avoid the human errors in translating the repeatable part of things. A simplified URL path for various objects in the REST APIs can provide an easy way for the user to interact with the system using commonly available tools to manage REST APIs.

- **API security:** The API being the entry point into the system exposes an attack surface. It is important to tie every single object/API access to the users and their roles. Further, the granularity of various actions, including create, update, get, delete, and so on, should also be tied to the RBAC model. The API should only be accessible over an encrypted transport such as HTTPS/TLS. The mechanism must employ short-lived certificates or time-limited JSON Web Tokens (JWT) [[30](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch12.xhtml#ch12ref30)] given to specific users for a configurable time period. This ensures that even when credentials are compromised, the impact of the compromise is limited. Only very specific user roles must be able to alter the credentials of the user; that is, modify the RBAC objects. And in case of a compromise, users should be able to revoke the credentials right away. The control plane can also be subjected to DoS attack, where a huge number of API requests can prevent authorized users from accessing the system; therefore, it can help to employ rate limiting to restrict the number of API calls per object(s) per user. Finally, simple proven measures like accepting all incoming requests on one TCP port can help reduce the attach surface, and, of course, not leaving any backdoors open to unauthorized access. Note, however, that RBAC not only controls the rights to perform CRUD operations, but also what data is returned based on the user role.

- **API auditing:** It is an important security aspect of the system to be able to audit all API calls into the system; therefore, preserving the audit logs for the longest possible period with all required details can offer the user a glimpse of answers to who accessed the API, when it was accessed, why it was permitted, what operation was performed, and from where it was done. A searchable audit log goes a long way in improving the security posture of the management control plane.

- **Performance and scale:** API performance comes from a reduction in the amount of back-end processing to perform the functions such as authentication, authorization, object syntax validation, semantic validation, auditing, and so on. Therefore, employing caching can improve the performance. Doing multiple validations and other error checks in parallel threads can result in quicker response. In addition to improving the overall API processing times, serving the APIs in all scale-out instances in the control plane nodes can also allow for horizontal scale.

- **Backward compatibility:** API compatibility becomes relevant as the adoption and ecosystem around the APIs start to build. As a general rule, the API should have a very good reason to break the compatibility, and when this is needed it should be versioned; that is, a new version should support the new API while the control plane continues to support the older version of the API to ensure older users can use the system without any impact, yet providing them a chance to move to the newer version if they want to move to newer functionality. Using the REST/JSON structure can allow adding incremental fields to existing objects easily without breaking backward compatibility. However, a semantic change in the object relationship or a change in the meaning of the field would need a version update.

- **Debuggability:** Dry-runs on API calls without impacting the system behavior gives users a way to play with the APIs and ensures that the understanding of various fields and parameters is correct. Furthermore, precise error codes and crisp error messages can improve API debuggability significantly.

- **Transactional semantics:** Often, the user may want to commit creation or modification of multiple objects atomically. The API backend would need to support transactional semantics to allow the user to create these objects together, validate them as a single unit, and then commit them all at once.

### 12.10 Federation

This section explains the concept of federation of multiple software defined services platforms (SDSPs). We cover some common reasons for adopting a federated policy-driven management architecture.

Before talking about federation of management, it’s worth reviewing common nonfederated service management. Perhaps the most common architecture is “centralized management,” because it works well in small to midsize environments in a single location. In a centralized management system architecture there is typically one SDSP (which itself could consist of multiple distributed control nodes) located in a single location or data center.

One of the core responsibilities of the SDSP is to perform full life-cycle management of DSNs, which includes the following:

- Admission, or allow a DSN to join the SDSP management domain

- Inventory

- Monitoring

- Upgrades and downgrades

- Policy distribution; services, rules and behaviors, and so on

- Decommission, or remove a DSN from the SDSP

The SDSP typically also provides other crucial functions such as:

- RBAC

- Multi-tenancy

- Systemwide monitoring and alerting

- Systemwide telemetry correlation and reporting

- Auditing

- Log collection of distributed services (such as firewall, workloads and load-balancers, and so on)

- Tools for diagnostics and troubleshooting

- Systemwide software and image management

In this architecture, the SDSP is considered to be the “single source of truth” for all the policies and configurations in the domain. That said, it is common that the actual source of truth for rules and desired behaviors and so on comes from an external system, such as a custom configuration management database (CMDB). Rules and configurations are often pushed to the SDSP via a REST-based API or gRPC from an orchestration engine or similar.

#### 12.10.1 Scaling a Single SDSP

A SDSP can become resource constrained in aspects such as capacity (space for logs, events, audits, policies, stats, and so on) or performance (processing of policies, events, telemetry, and other system services) due to factors such as an increased number of managed DSNs in the domain and/or an increased number of workloads or services enabled such as firewalls, load balancers, and so on. Typically, a SDSP can be scaled in a scale-out or scale-up fashion. But in practice, single SDSP scales only to a certain point, for reasons we will discuss later.

Scale-up is often the simplest solution, where each distributed node gets upgraded (or moved to a different compute system) with more resources such as CPU cores, memory, and storage. However, this often becomes an expensive solution compared to scale-out, and it is typically neither practical nor possible to scale up nodes indefinitely.

Scale-out is often a better solution, where additional controller nodes are added to the SDSP, allowing for redistribution of microservices as well as increasing the number of microservices, therefore reducing the average load on each controller node. However, adding too many nodes to a SDSP may cause challenges, as well, especially when data needs to be persistent and consistent across all the nodes. Such systems are built to scale linearly, but at some point, adding too many nodes can result in increased latency or reduced performance benefit for each added node (that is, non-linear scaling), often caused by system updates such as events, statistics, states, and config changes, as more nodes participate in the update. Building a large scale-out distributed system that maintains low latency as it scales is a lot more challenging than building one targeted for delivering high throughput; see [Figure 12-5](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch12.xhtml#ch12fig5).

![A single DS manager is composed of a distributed services platform that contains 'N' number of nodes and policies. The distributed services platform manages multiple DSNs.](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9780136624226/files/graphics/12fig05.jpg)

**FIGURE 12-5** A Single DS Manager

There are other reasons why having a single SDSP may not be practical. A single SDSP domain does provide resiliency against failures (for individual or multinode failures), but a single SDSP can be considered a failure domain in itself. Even the most sophisticated and stable systems are not guaranteed to be protected against bugs and infrastructure failures. For many customers, the SDSP size is limited by an acceptable security zone size to reduce the attack surface. Also, in consideration of managing DSNs across multiple data centers with disaster recovery (DR) in mind, a single SDSP may not be practical.

To address these challenges, we propose using multiple SDSPs as the preferred approach. A multiple SDSP approach can be architected by using a distributed SDSP architecture or by a federated SDSP architecture. Both options are discussed in the following sections.

#### 12.10.2 Distributed Multiple SDSPs

One approach to reduce a domain size is to create multiple distributed SDSPs. Such an approach can be done within a single data center or across data centers. In this architecture, each SDSP acts as an independent system, and the SDSPs coexist as peers. In this approach, global policies are distributed and applied across these independent systems. This is a common architectural approach for such systems, because there are typically few modifications needed with respect to the centralized single domain model. However, this approach does introduce certain complexity: As the architecture scales out to larger numbers, it increases the risks for consequential configuration drifts and potential policy consistency issues across the SDSPs due to synchronizations or human configuration drifts. Visibility and troubleshooting can be challenging, because each SDSP has its own view of the world and works independently of others. Troubleshooting and correlation of events between these systems can sometimes be challenging; see [Figure 12-6](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch12.xhtml#ch12fig6).

![A figure demonstrates the distribution of multiple DS managers.](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9780136624226/files/graphics/12fig06.jpg)

**FIGURE 12-6** Distribution of Multiple DS Managers

In the network model, the policy to be synced is distributed among three different distributed services platform via the network cloud. Each distributed service platform consists of 'n' number of nodes and policies and manages multiple DSNs.

#### 12.10.3 Federation of Multiple SDSPs

Federation is a different concept where the architecture is a hierarchical treelike structure rather than a peer architecture, operating more as a single system across multiple domains; see [Figure 12-7](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch12.xhtml#ch12fig7).

![A figure demonstrates about the federation of multiple DS managers.](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9780136624226/files/graphics/12fig07.jpg)

**FIGURE 12-7** Federation of Multiple DS Managers

In the figure, a federated service manager and three distributed services platforms are connected via the network cloud. The federated service manager constitutes 'N' nodes with high-level systemwide policies while the distributed services platforms constitute 'N' nodes with domain-specific policies. Each distributed service platform manages multiple DSNs.

The Federated Service Manager (FSM) would typically provide centralized systemwide services and manage high-level policy definitions, rather than individual domain-specific data such as local IP addresses, networks, and so on. These polices use high-level descriptors like names or labels to describe the intent. A high-level policy terminates on a named reference, rather than an actual attribute value. These names or labels are later resolved into something meaningful and specific with respect to the SDSP domain itself (domain-specific data). Examples of high-level policies can be:

- Authorization policies (for example, no local user authentication allowed, only external authentication via RADIUS or LDAP)

- Network services, such as security policies

- Backup schedule definitions

- Optional versus mandatory network services (for example, load balancer is optional; firewall is mandatory)

Each SDSP contains domain-specific policies and configurations relevant to its own management domain and resources. Individual SDSPs also have their own understanding of how to resolve a named reference in a high-level policy definition (the attribute value or data). In this way, the system can work in harmony and reduce the risk of drifts and policy inconsistency.

For example, if each SDSP has two networks labeled Database and AppX, and each SDSP domain uses different subnets and VLAN IDs for these networks. And let’s say there is a high-level FSM policy describing firewall rules for the two networks, Database and AppX. Each SDSP receives the high-level FSM policy and will then individually resolve these labels based on its own definition of subnet and VLAN IDs; the SDSP then applies the rules based on its knowledge of the definition. From an FSM level the rules are the same, but on the SDSP level the definitions are different.

This architecture brings systemwide benefits, including:

- Global policy definition and enforcement

- Visibility

- Event correlations

- Troubleshooting

- Reporting

- A centralized software and image repository

The architecture enforces system policies top down and policies are inherited if they could not be provided locally within SDSP. Global policies also serve as “guidelines” where the system resolves the policy in a hierarchical way from the local domain and up into the scope of the parent.

The policy would first attempt to be resolved at individual SDSP level (in a hierarchical way) if it exists. If it cannot be resolved at the SDSP level, it would be resolved from the policy in the FSM instead (also hierarchical).

The FSM and the SDSPs are typically loosely coupled. Each SDSP is responsible for resolving its own policies and each domain can act individually during exceptions. Examples would include a disconnection from the federated system (scheduled or unscheduled). There are always exceptions that could happen, where a SDSP must be able to operate as an individual management system outside the federation for a period of time and later rejoin the federation. Once the SDSP has rejoined the federation, any new policies added or updated in the federated system (that is applicable to the domain) will flow down to the SDSP.

Policy relevance can be managed through a subscription model and pull mechanism by the SDSP, rather than by push from the Federated Service Manager. Each SDSP would be responsible for requesting policies from the federated system. However, if the SDSP has made local changes to any existing policy (during a disconnected state) that conflicts with the high-level policy in the Federation Service Manager, the system needs to detect and identify any conflicts that require a resolution. The action to resolve the conflict is typically taken from the SDSP rather than the FSM. The system should provide insight into what the conflict looks like, provide impact analysis, and propose various resolutions.

One caveat or anti-pattern is to refrain from having domain policy definitions synced up to the federation level, because this could conflict with other SDSPs in the same federation. Similar challenges would also exist for the distributed SDSP model, discussed previously.

Explicitly overriding inherited policies may not be recommended either, but may be necessary in certain circumstances, such as if a change was made that violates some fundamental security setting; for example, a local authentication exception.

There are numerous ways to resolve global versus local policy conflicts. In some instances, conflicts can be automatically resolved. But there are no single “silver bullets” or axioms to apply automatically for resolving policy conflicts. In general, resolution will come down to human intervention and common sense from the administrators involved. Time is also an important factor in policy conflict resolution. Sometimes resolution can be delayed; sometimes resolution needs to be immediate, depending on the conflict.

A federated system monitors the health of the individual SDSPs and related components in the system. The FSM can also often provide centralized services such as a repository of secure and verified software images for the SDSP to consume. The FSM typically has some kind of dashboard, which provides a single systemwide, correlated view of all the individual domains as well as troubleshooting tools. The common pillar is seamless management of individual domains, tenants, and users.

Please note: *A Federation Service Manager typically does not bring up all the data such as logs, telemetry, events, and statistics from all the individual SDSPs. Doing so would not be efficient because the amount of data could be very large depending on number of domains, number of DSNs, network services, and so on. Instead, the FSM would contain a subset of the data and query individual SDSPs for specific data in real time, processing the received data before presentation to provide the impression that the data is stored centrally.*

In summary, federation is a way to span multiple SDSP systems across multiple data centers or to reduce the failure domain/security zone within a single data center. Federation provides high-level policies (non-SDSP specific attributes) and systemwide services. An FSM provides global services (for example, a software image repository) across all SDSPs participating in the federation. The federation provides cross-SDSP management and is able to correlate information such as events, alerts, and logs.

In addition to federation, other distributed system architectures are common and provide similar capabilities but can sometimes be challenging to manage as their distribution scale increases.

### 12.11 Scale and Performance Testing

A SDSP system should be designed to handle a large number of endpoints or DSNs. Therefore, all of the functions and components of a SDSP system need to be thoroughly tested for realistic scale, performance, and resiliency during its development cycle.

The testing should confirm that the architecture is valid and that it can provide the scale, performance, and robustness as expected. The testing should aim to find weaknesses and critical bottlenecks. Studies show that failures in these systems tend to be caused by their inability to scale to meet user demand, as opposed to feature bugs. Therefore, load testing at scale is required in addition to conventional functional testing.

Scale and performance testing are critical aspects during the development of a SDSP. This is an ongoing process, starting as early as possible in the development phase. Simulating individual components is needed for development and integration testing. Simulation also helps with testing scale and architectural validation.

Scale testing can be thought of in three phases:

1. Scale test design (defines what a realistic load looks like)

1. Scale test execution (defines how the tests will be run)

1. Analysis of the test results

All the components in an SDSP are expected to work in harmony, especially at full scale. Buffers, caches, processes and services, and so on should be balanced relative to each other, so the system behaves accurately under heavy load. With proper design, systems can handle burstiness and provide predictability. Realistic full-scale testing is a common way to make sure the system operates in an optimal way at full scale.

A SDSP system should be easy to scale for performance and/or capacity, easy to troubleshoot, and easy to manage at scale. An effective design hides the internal complexity and makes the management of one SDSP almost as easy as multiple thousands of SDSPs. The end user should not experience increases in complexity and slower performance as the scale of the system increases. Intent-based, policy-driven management has proven itself to be an excellent choice. A good example is Cisco UCS Manager for solving management at scale.

A SDSP architecture consists of many different “moving parts,” and there are many aspects to consider during the design of the architecture, such as how the different components interact with each other, how they scale internally, and how to make them efficient and resource effective. For example, here are some components that should be considered:

- Control plane

- Data plane

- Management plane

- Security (interaction between the various components)

- Microservices with their different functions

- Intercommunication and synchronization between services and between nodes

- Load distribution of service requests, both internally and externally

- Transactional data (user intents, policy mutations, and other state changes)

- Non-transactional data that needs to be processed or analyzed (logs, events, and so on)

- User interfaces such as API, GUI, and CLI with respect to usability, scale, and responsiveness

- Failure detection and handling

- Number and size of internal objects

- Size of logs and other forms of internal data

All system aspects and components need to be tested at full scale. However, most test environments do not have the luxury of full-scale test beds with real physical compute nodes or DSNs. Performing realistic testing of SDSP systems at scale requires other means to be used, like simulators utilizing various virtualization techniques, such as VMs or Containers.

When architecting a full-scale test bed, it is important to understand what a full-scale customer implementation would look like in terms of the capability and functionality of the SDSP, supported network services, and so on.

There are many different data points in a SDSP system. All data points should be considered both from MAX/Burst and Average values. [Table 12-1](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch12.xhtml#ch12tab1) describes a few common data points. At a very high level it can be divided into three simple areas: scale, workload, and management/monitoring characteristics.

**TABLE 12-1** Scaling

| Area | Description |
| --- | --- |
| **Scale:** Number of DSNs per SDSP | This helps determine the scale of the test bed needed, number of simulators, and so on |
| **Workload Characteristics:** Number of connections per second Number of active flows Number of endpoints | This is defined per DSN, and it indicates the amount of data that will be generated by telemetry and stats collections per second. This data is typically rolled up into a systemwide workload map. |
| **Management/Monitoring:** Number, types, and sizes of policies Number of updates per second Number of calls per second | This helps to estimate the size and the required number of updates for the policy database, as well as the policy distribution and enforcement for the different DSNs. It will also indicate the number of expected API calls per second expected to be handled by the API gateways. |

To give headroom for future feature enhancements of the system, it is important that the architecture is designed for scalability well beyond what the initial requirements are.

Based on the data points described previously, certain test data parameters can be sized for aspects such as events, amount of telemetry data to process, state changes, flows, log entries and sizes, user requests, and so on. This sizing provides useful information on what the target test topology should look like and how the tests should be run.

A test topology consisting of real and simulated components provides many benefits. Simulators are economical, easy to scale, and easy to control. Another important aspect is the ability to perform various forms of fault injection. Simulators can report simulated hardware failures, states, temperatures, misbehaviors, and so on, which are often hard to accomplish with physical hardware.

During testing, both physical and simulated DSNs pass real traffic and test the actual required network, storage, and RDMA traffic per DSN. Containers and other virtualization technologies are excellent for running simulators. The number of simulators that can run on a single physical host varies depending on the physical host resources as well as the simulator’s resource consumption profile. Typically, multiple hundreds of simulators can be run per physical server.

To generate an effective simulation test topology at scale, configuration generation and traffic generation for a given configuration is essential. This can be thought of as a description of an “infrastructure and traffic pattern map” with the validation capability for verifying expected behaviors. This enables creating realistic test scenarios at scale, testing individual or aggregated workloads, and testing for specific use cases.

The testing infrastructure itself should be dynamic and be designed to easily scale for larger testing purpose, to easily inject new tests, and to be fully automated. The following are some common guidelines that can be used in large-scale test design:

- Run multiple scenarios; for example, starting with a small-scale test and increasing the scale and/or load test up toward the full-scale testing. Upon completion, the results should be compared to obtain better insight into the system behavior, as scale and load increases.

- Run tests for extended periods of time to ensure the target system will not degrade in performance and functionality over time with massive load at scale.

- Use multiple parallel test beds for parallel testing of different scenarios.

- Take advantage of AI/ML and other forms of analytics to help produce test result reports and to analyze both individual DSN’s behaviors as well as clusterwide behavior (SDSP).

- Run tests at larger scale than are required to find limitations, including larger log data than expected. During the tests run user-realistic operations of the data, such as various reporting, trending analysis, and various searches to verify an acceptable responsiveness.

The tests are often broken into three different categories: performance testing, stress testing, and load testing. Tests should be run individually as well as in combination of these types of tests:

- Load testing aims to verify the functional correctness of the system under load.

- Performance testing aims to verify the performance of the architecture—services, algorithms, and so on—during normal conditions.

- Stress testing aims to test abnormal conditions such as higher latency and lower bandwidth than expected.

All components of the system need to be considered, and the test results should be analyzed for individual components (DSNs, algorithms, services, and so on) as well as systemwide behavior.

### 12.12 Summary

In this chapter, we presented a management control plane architecture, built using containerized microservices, that is secure, scalable, high performance, debuggable, resilient, and extensible. It is a system built to run on a container orchestration system such as Kubernetes, running microservices that interact with each other using backward-compatible APIs presenting a scalable, resilient, and upgradable deployment model. We presented the design choices for an implementation that can allow business functions to be created and evolved independently. We presented how using mutual TLS between all the components of the system present a highly secure architecture. We also presented mechanisms to federate the policies consistently and allow debugging in a multisite deployment. Finally, we discussed the challenges of building the management system as a cloud-native application and discussed techniques to mitigate those challenges.

### 12.13 Bibliography

**[[1](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch12.xhtml#rch12ref1)]** Cloud Native Computing Foundation, “Sustaining and Integrating Open Source Technologies,” [https://www.cncf.io](https://www.cncf.io/)

**[[2](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch12.xhtml#rch12ref2)]** Kubernetes.io, “Production-Grade Container Orchestration,” [https://kubernetes.io](https://kubernetes.io/)

**[[3](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch12.xhtml#rch12ref3)]** Docker, “Docker: The Modern Platform for High-Velocity Innovation,” [https://www.docker.com/why-docker](https://www.docker.com/why-docker)

**[[4](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch12.xhtml#rch12ref4)]** Apache Software Foundation, “Program against your datacenter like it’s a single pool of resources,” [http://mesos.apache.org](http://mesos.apache.org/)

**[[5](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch12.xhtml#rch12ref5)]** Cloud Native Computing Foundation, “A high performance, open-source universal RPC framework,” [https://grpc.io](https://grpc.io/)

**[[6](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch12.xhtml#rch12ref6)]** GitHub, “Protocol Buffers,” [https://developers.google.com/protocol-buffers](https://developers.google.com/protocol-buffers)

**[[7](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch12.xhtml#rch12ref7)]** Cloud Native Computing Foundation, “Envoy Proxy Architecture Overview” [https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/arch_overview](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/arch_overview)

**[[8](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch12.xhtml#rch12ref8)]** Nginx, “nginx documentation,” [https://nginx.org/en/docs](https://nginx.org/en/docs)

**[[9](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch12.xhtml#rch12ref9)]** GitHub, “finagle: A fault tolerant, protocol-agnostic RPC system,” [https://github.com/twitter/finagle](https://github.com/twitter/finagle)

**[[10](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch12.xhtml#rch12ref10)]** OpenZipkin, “Architecture Overview,” [https://zipkin.io/pages/architecture.html](https://zipkin.io/pages/architecture.html)

**[[11](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch12.xhtml#rch12ref11)]** Cloud Native Computing Foundation, “Vendor-neutral APIs and instrumentation for distributed tracing,” [https://opentracing.io](https://opentracing.io/)

**[[12](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch12.xhtml#rch12ref12)]** Wikipedia, “Trusted Platform Module,” [https://en.wikipedia.org/wiki/Trusted_Platform_Module](https://en.wikipedia.org/wiki/Trusted_Platform_Module)

**[[13](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch12.xhtml#rch12ref13)]** Cloud Native Computing Foundation, “Secure Production Identity Framework for Everyone,” [https://spiffe.io](https://spiffe.io/)

**[[14](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch12.xhtml#rch12ref14)]** Helm, “The Packet manager for Kubernetes,” [https://helm.sh](https://helm.sh/)

**[[15](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch12.xhtml#rch12ref15)]** Elastic, “What is the ELK Stack? Why, it’s the Elastic Stack,” [https://www.elastic.co/elk-stack](https://www.elastic.co/elk-stack)

**[[16](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch12.xhtml#rch12ref16)]** InfluxData, “Introduction to InfluxData’s InfluxDB and TICK Stack,” [https://www.influxdata.com/blog/introduction-to-influxdatas-influxdb-and-tick-stack](https://www.influxdata.com/blog/introduction-to-influxdatas-influxdb-and-tick-stack)

**[[17](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch12.xhtml#rch12ref17)]** Distributed Systems Reading Group, “Papers on Consensus,” [http://dsrg.pdos.csail.mit.edu/papers](http://dsrg.pdos.csail.mit.edu/papers)

**[[18](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch12.xhtml#rch12ref18)]** Apache Software Foundation, “Zookeeper,” [https://zookeeper.apache.org](https://zookeeper.apache.org/)

**[[19](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch12.xhtml#rch12ref19)]** Cloud Native Computing Foundation, “etcd: A distributed, reliable key-value store for the most critical data of a distributed system,” [https://coreos.com/etcd](https://coreos.com/etcd)

**[[20](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch12.xhtml#rch12ref20)]** Prometheus, “From metrics to insight,” [https://prometheus.io](https://prometheus.io/)

**[[21](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch12.xhtml#rch12ref21)]** Universite libre de Bruxelles, “Time Series Databases and InfluxDB,” [https://cs.ulb.ac.be/public/_media/teaching/influxdb_2017.pdf](https://cs.ulb.ac.be/public/_media/teaching/influxdb_2017.pdf)

**[[22](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch12.xhtml#rch12ref22)]** Apache Software Foundation, “Cassandra,” [http://cassandra.apache.org](http://cassandra.apache.org/)

**[[23](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch12.xhtml#rch12ref23)]** MongoDB, “What is MongoDB,” [https://www.mongodb.com/what-is-mongodb](https://www.mongodb.com/what-is-mongodb)

**[[24](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch12.xhtml#rch12ref24)]** Wikipedia, “Redis,” [https://en.wikipedia.org/wiki/Redis](https://en.wikipedia.org/wiki/Redis)

**[[25](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch12.xhtml#rch12ref25)]** GitHub, “CockroachDB - the open source, cloud-native SQL database,” [https://github.com/cockroachdb/cockroach](https://github.com/cockroachdb/cockroach)

**[[26](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch12.xhtml#rch12ref26)]** GitHub, “MinIO is a high performance object storage server compatible with Amazon S3 APIs,” [https://github.com/minio/minio](https://github.com/minio/minio)

**[[27](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch12.xhtml#rch12ref27)]** Wikipedia, ElasticSearch, [https://en.wikipedia.org/wiki/Elasticsearch](https://en.wikipedia.org/wiki/Elasticsearch)

**[[28](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch12.xhtml#rch12ref28)]** Apache Software Foundation, “Kafka: A distributed streaming platform,” [https://kafka.apache.org](https://kafka.apache.org/)

**[[29](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch12.xhtml#rch12ref29)]** Github, “NATS,” [https://nats-io.github.io/docs](https://nats-io.github.io/docs)

**[[30](https://learning.oreilly.com/library/view/building-a-future-proof/9780136624226/ch12.xhtml#rch12ref30)]** JSON Web Tokens, “JWT,” [https://jwt.io/introduction](https://jwt.io/introduction)

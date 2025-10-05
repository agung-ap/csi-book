# Chapter 6. Kubernetes and Cloud Networking

The use of the cloud and its service offerings has grown tremendously: 77% of enterprises are using the public cloud
in some capacity, and 81% can innovate more quickly with the public cloud than on-premise. With the popularity and
innovation available in the cloud, it follows that running Kubernetes in the cloud is a logical step. Each major cloud
provider has its own managed service offering for Kubernetes using its cloud network services.

In this chapter, we’ll explore the network services offered by the major cloud providers AWS, Azure, and GCP with a
focus on how they affect the networking needed to run a Kubernetes cluster inside that specific cloud. All the providers also have a CNI project that makes running a Kubernetes cluster smoother from an integration perspective with their cloud network APIs, so an exploration of the CNIs is warranted. After reading this chapter, administrators will  understand how cloud providers implement their managed Kubernetes on top of their cloud network
services.

# Amazon Web Services

Amazon Web Services (AWS) has grown its cloud service offerings from Simple Queue Service (SQS) and Simple Storage
Service (S3) to well over 200 services.  Gartner Research positions AWS in the Leaders quadrant of its 2020 Magic
Quadrant for Cloud Infrastructure & Platform Services. Many services are built atop of other foundational services.
For example, Lambda uses S3 for code storage and DynamoDB for metadata. AWS CodeCommit uses S3 for code storage.
EC2, S3, and CloudWatch are integrated into the Amazon Elastic MapReduce service, creating a managed data platform.
The AWS networking services are no different. Advanced services such as peering and endpoints use building blocks from
core networking fundamentals. Understanding those fundamentals, which enable AWS to build a
comprehensive Kubernetes service, is needed for administrators and developers.

## AWS Network Services

AWS has many services that allow users to extend and secure their cloud networks. Amazon Elastic Kubernetes Service
(EKS) makes extensive use of those network components available in the AWS cloud. We will discuss the basics of
AWS networking components and how they are related to deploying an EKS cluster network. This section will also discuss
several other open source tools that make managing a cluster and application deployments simple. The first is `eksctl`,
a CLI tool that deploys and manages EKS clusters. As we have seen from previous chapters, there are many components
needed to run a cluster, and that is also true on the AWS network. `eksctl` will deploy all the components in AWS for
cluster and network administrators. Then, we will discuss the AWS VPC CNI, which allows the cluster to use native AWS
services to scale pods and manage their IP address space. Finally, we will examine the AWS Application Load Balancer
ingress controller, which automates, manages, and simplifies deployments of application load balancers and ingresses
for developers running applications on the AWS network.

### Virtual private cloud

The basis of the AWS network is the virtual private cloud (VPC). A majority of AWS resources will work inside the VPC.
VPC networking is an isolated virtual network defined by administrators for only their account and its resources. In
[Figure 6-1](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch06.html#VPC), we can see a VPC defined with a single CIDR of `192.168.0.0/16`. All resources inside the VPC will use that
range for private IP addresses. AWS is constantly enhancing its service offerings; now, network administrators can use
multiple nonoverlapping CIDRs in a VPC. The pod IP addresses will also come from VPC CIDR and host IP addressing; more on that in [“AWS VPC CNI”](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch06.html#awsvpccni). A VPC is set up per AWS region; you can have multiple VPCs per region, but a VPC is defined in only one.

![neku 0601](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492081647/files/assets/neku_0601.png)

###### Figure 6-1. AWS virtual private cloud

### Region and availability zones

Resources are defined by boundaries in AWS, such as global, region, or availability zone. AWS networking comprises multiple
regions; each AWS region consists of multiple isolated and physically separate availability zones (AZs) within a
geographic area. An AZ can contain multiple data centers, as shown in [Figure 6-2](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch06.html#aws-regiom). Some regions can contain six
AZs, while newer regions could contain only two. Each AZ is directly connected to the
others but is isolated from the failures of another AZ. This design is important to understand for multiple reasons:
high availability, load balancing, and subnets are all affected. In one region a load balancer will route traffic
over multiple AZs, which have separate subnets and thus enable HA for applications.

![neku 0602](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492081647/files/assets/neku_0602.png)

###### Figure 6-2. AWS region network layout

###### Note

An up-to-date list of AWS regions and AZs is available in the
[documentation](https://oreil.ly/gppRp).

### Subnet

A VPC is compromised of multiple subnets from the CIDR range and deployed to a single AZ. Applications that
require high availability should run in multiple AZs and be load balanced with any one of the load balancers
available, as discussed in [“Region and availability zones”](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch06.html#region).

A subnet is public if the routing table has a route to an internet gateway. In [Figure 6-3](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch06.html#Private-subnet), there are three public and private subnets. Private subnets have no direct route to the internet. These subnets are for
internal network traffic, such as databases. The size of your VPC CIDR range and the number of public and private subnets
are a design consideration when deploying your network architecture. Recent improvements to VPC like allowing
multiple CIDR ranges help lessen the ramification of poor design choices, since now network engineers can simply add
another CIDR range to a provisioned VPC.

![Subnet](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492081647/files/assets/neku_0603.png)

###### Figure 6-3. VPC subnets

Let’s discuss those components that help define if a subnet is public or private.

### Routing tables

Each subnet has exactly one route table associated with it. If one is not explicitly associated with it, the main
route table is the default one. Network connectivity issues can manifest here; developers deploying applications
inside a VPC must know to manipulate route tables to ensure traffic flows where it’s intended.

The following are rules for the main route table:

-

The main route table cannot be deleted.

-

A gateway route table cannot be set as the main.

-

The main route table can be replaced with a custom route table.

-

Admins can add, remove, and modify routes in the main route table.

-

The local route is the most specific.

-

Subnets can explicitly associate with the main route table.

There are route tables with specific goals in mind; here is a list of them and a description of how they are
different:

Main route tableThis route table automatically controls routing for all subnets that are not explicitly
associated with any other route table.

Custom route tableA route table network engineers create and customize for specific application traffic flow.

Edge associationA routing table to route inbound VPC traffic to an edge appliance.

Subnet route tableA route table that’s associated with a subnet.

Gateway route tableA route table that’s associated with an internet gateway or virtual private gateway.

Each route table has several components that determine its responsibilities:

Route table associationThe association between a route table and a subnet, internet
gateway, or virtual private gateway.

RulesA list of routing entries that define the table; each rule has a destination, target, status, and
propagated flag.

DestinationThe range of IP addresses where you want traffic to go (destination CIDR).

TargetThe gateway, network interface, or connection through which to send the destination traffic; for example,
an internet gateway.

StatusThe state of a route in the route table: active or blackhole. The blackhole state indicates that the
route’s target isn’t available.

PropagationRoute propagation allows a virtual private gateway to automatically propagate routes to the route
tables. This flag lets you know if it was added via propagation.

Local routeA default route for communication within the VPC.

In [Figure 6-4](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch06.html#route-table_6), there are two routes in the route table. Any traffic destined for `11.0.0.0/16` stays on the local network
inside the VPC. All other traffic, `0.0.0.0/0`, goes to the internet gateway, `igw-f43c4690`, making it a public subnet.

![Route](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492081647/files/assets/neku_0604.png)

###### Figure 6-4. Route table

### Elastic network interface

An elastic network interface (ENI) is a logical networking component in a VPC that is equivalent to a virtual network
card. ENIs contain an IP address, for the instance, and they are elastic in the sense that they can be associated and
disassociated to an instance while retaining its properties.

ENIs have these properties:

-

Primary private IPv4 address

-

Secondary private IPv4 addresses

-

One elastic IP (EIP) address per private IPv4 address

-

One public IPv4 address, which can be auto-assigned to the network interface for `eth0` when you launch an instance

-

One or more IPv6 addresses

-

One or more security groups

-

MAC address

-

Source/destination check flag

-

Description

A common use case for ENIs is the creation of management networks that are accessible only from a corporate network.
AWS services like Amazon WorkSpaces use ENIs to allow access to the customer VPC and the AWS-managed VPC. Lambda can
reach resources, like databases, inside a VPC by provisioning and attaching to an ENI.

Later in the section we will see how the AWS VPC CNI uses and manages ENIs along with IP addresses for pods.

### Elastic IP address

An EIP address is a static public IPv4 address used for dynamic network addressing in the AWS cloud. An
EIP is associated with any instance or network interface in any VPC. With an EIP, application developers can mask
an instance’s failures by remapping the address to another instance.

An EIP address is a property of an ENI and is associated with an instance by updating the ENI attached to the
instance. The advantage of associating an EIP with the ENI rather than directly to the instance is that all the
network interface attributes move from one instance to another in a single step.

The following rules apply:

-

An EIP address can be associated with either a single instance or a network interface at a time.

-

An EIP address can migrate from one instance or network interface to another.

-

There is a (soft) limit of five EIP addresses.

-

IPv6 is not supported.

Services like NAT and internet gateway use EIPs for consistency between the AZ. Other gateway services like a
bastion can benefit from using an EIP. Subnets can automatically assign public IP addresses to EC2 instances, but that
address could change; using an EIP would prevent that.

### Security controls

There are two fundamental security controls within AWS networking: security groups and network access control lists
(NACLs). In our experience, lots of issues arise from misconfigured security groups and NACLs. Developers and network
engineers need to understand the differences between the two and the impacts of changes on them.

#### Security groups

Security groups operate at the instance or network interface level and act as a firewall for those devices associated with them. A security group is a group of network devices that require common network access to each other and other devices on the network. In [Figure 6-5](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch06.html#sec-group) ,we can see that security works across AZs. Security groups have two tables, for inbound and outbound traffic flow. Security groups are stateful, so if traffic is allowed on the inbound flow, the outgoing traffic is allowed. Each security group has a list of rules that define the filter for traffic. Each rule is evaluated before a forwarding decision is made.

![Security Group](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492081647/files/assets/neku_0605.png)

###### Figure 6-5. Security group

The following is a list of components of security group rules:

Source/destinationSource (inbound rules) or destination (outbound rules) of the traffic inspected:

-

Individual or range of IPv4 or IPv6 addresses

-

Another security group

-

Other ENIs, gateways, or interfaces

ProtocolWhich layer 4 protocol being filtered, 6 (TCP), 17 (UDP), and 1 (ICMP)

Port rangeSpecific ports for the protocol being filtered

DescriptionUser-defined field to inform others of the intent of the security group

Security groups are similar to the Kubernetes network policies we discussed in earlier chapters. They are a
fundamental network technology and should always be used to secure your instances in the AWS VPC. EKS deploys several
security groups for communication between the AWS-managed data plane and your worker nodes.

#### Network access control lists

Network access control lists operate similarly to how they do in other firewalls so that network engineers will be
familiar with them. In [Figure 6-6](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch06.html#NACL), you can see each subnet has a default NACL associated with it and is bounded to an
AZ, unlike the security group. Filter rules must be defined explicitly in both directions. The default rules are quite
permissive, allowing all traffic in both directions. Users can define their own NACLs to use with a subnet for an
added security layer if the security group is too open. By default, custom NACLs deny all traffic, and therefore add rules when
deployed; otherwise, instances will lose connectivity.

Here are the components of an NACL:

Rule numberRules are evaluated starting with the lowest numbered rule.

TypeThe type of traffic, such as SSH or HTTP.

ProtocolAny protocol that has a standard protocol number: TCP/UDP or ALL.

Port rangeThe listening port or port range for the traffic. For example, 80 for HTTP traffic.

SourceInbound rules only; the CIDR range source of the traffic.

DestinationOutbound rules only; the destination for the traffic.

Allow/DenyWhether to allow or deny the specified traffic.

![NACL](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492081647/files/assets/neku_0606.png)

###### Figure 6-6. NACL

NACLs add an extra layer of security for subnets that may protect from lack or misconfiguration of security groups.

[Table 6-1](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch06.html#security_and_nacl_comparison_table) summarizes the fundamental differences between security groups and network ACLs.

| Security group | Network ACL |
| --- | --- |
| Operates at the instance level. | Operates at the subnet level. |
| Supports allow rules only. | Supports allow rules and deny rules. |
| Stateful: Return traffic is automatically allowed, regardless of any rules. | Stateless: Return traffic must be explicitly allowed by rules. |
| All rules are evaluated before a forwarding decision is made. | Rules are processed in order, starting with the lowest numbered rule. |
| Applies to an instance or network interface. | All rules apply to all instances in the subnets that it’s associated with. |

It is crucial to understand the differences between NACL and security groups. Network connectivity issues often arise
due to a security group not allowing traffic on a specific port or someone not adding an outbound rule on an NACL. When
troubleshooting issues with AWS networking, developers and network engineers alike should add checking these components
to their troubleshooting list.

All the components we have discussed thus far manage traffic flow inside the VPC. The following services
manage traffic into the VPC from client requests and ultimately to applications running inside a Kubernetes cluster:
network address translation devices, internet gateway, and load balancers. Let’s dig into those a little more.

### Network address translation devices

Network address translation (NAT) devices are used when instances inside a VPC require internet connectivity, but
network connections should not be made directly to instances. Examples of instances that should run behind a NAT
device are database instances or other middleware needed to run applications.

In AWS, network engineers have several options for running NAT devices. They can manage their own NAT
devices deployed as EC2 instances or use the AWS Managed Service NAT gateway (NAT GW). Both require public subnets
deployed in multiple AZs for high availability and EIP. A restriction of a NAT GW is that the IP address of it cannot
change after you deploy it. Also, that IP address will be the source IP address used to communicate with the internet
gateway.

In the VPC route table in [Figure 6-7](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch06.html#Nat-Int-Routing-Diagram), we can see how the two route tables exist to establish a connection to the
internet. The main route table has two rules, a local route for the inter-VPC and a route for `0.0.0.0/0` with a target of
the NAT GW ID. The private subnet’s database servers will route traffic to the internet via that NAT GW rule in
their route tables.

Pods and instances in EKS will need to egress the VPC, so a NAT device must be deployed. Your choice of NAT device
will depend on the operational overhead, cost, or availability requirements for your network design.

![net-int](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492081647/files/assets/neku_0607.png)

###### Figure 6-7. VPC routing diagram

### Internet gateway

The internet gateway is an AWS-managed service and device in the VPC network that allows connectivity to the internet
for all devices in the VPC. Here are the steps to ensure access to or from the internet in a VPC:

1.

Deploy and attach an IGW to the VPC.

1.

Define a route in the subnet’s route table that directs internet-bound traffic to the IGW.

1.

Verify NACLs and security group rules allow the traffic to flow to and from instances.

All of this is shown in the VPC routing from [Figure 6-7](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch06.html#Nat-Int-Routing-Diagram). We see the IGW deploy for the VPC, a custom route table
setup that routes all traffic, `0.0.0.0/0`, to the IGW. The web instances have an IPv4 internet routable address,
`198.51.100.1-3`.

### Elastic load balancers

Now that traffic flows from the internet and clients can request access to applications running inside a VPC, we
will need to scale and distribute the load for requests. AWS has several options for developers, depending on the
type of application load and network traffic requirements needed.

The elastic load balancer has four options:

ClassicA classic load balancer provides fundamental load balancing of EC2 instances. It operates at the request and
the connection level. Classic load balancers are limited in functionality and are not to be used with
containers.

ApplicationApplication load balancers are layer 7 aware. Traffic routing is made with request-specific
information like HTTP headers or HTTP paths. The application load balancer is used with the application load balancer
controller. The ALB controller allows devs to automate the deployment and ALB without using the console or API, instead just
a few YAML lines.

NetworkThe network load balancer operates at layer 4. Traffic can be routed based on incoming TCP/UDP ports to
individual hosts running services on that port. The network load balancer also allows admins to deploy then with an EIP, a
feature unique to the network load balancer.

GatewayThe gateway load balancer manages traffic for appliances at the VPC level. Such network devices
like deep packet inspection or proxies can be used with a gateway load balancer. The gateway load balancer is added here
to complete the AWS service offering but is not used within the EKS ecosystem.

AWS load balancers have several attributes that are important to understand when working with not only containers but
other workloads inside the VPC:

Rule(ALB only) The rules that you define for your listener determine how the load balancer routes all requests to
the targets in the target groups.

ListenerChecks for requests from clients. They support HTTP and HTTPS on ports 1–65535.

TargetAn EC2 instance, IP address, pods, or lambda running application code.

Target GroupUsed to route requests to a registered target.

Health CheckTest to ensure targets are still able to accept client requests.

Each of these components of an ALB is outlined in [Figure 6-8](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch06.html#loadbalancer_6). When a request comes into the load balancer, a listener is
continually checking for requests that match the protocol and port defined for it. Each listener has a set of rules that
define where to direct the request. The rule will have an action type to determine how to handle the request:

authenticate-cognito(HTTPS listeners) Use Amazon Cognito to authenticate users.

authenticate-oidc(HTTPS listeners) Use an identity provider that is compliant with OpenID Connect to authenticate users.

fixed-responseReturns a custom HTTP response.

forwardForward requests to the specified target groups.

redirectRedirect requests from one URL to another.

The action with the lowest order value is performed first. Each rule must include exactly one of the following
actions: forward, redirect, or fixed-response. In [Figure 6-8](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch06.html#loadbalancer_6), we have target groups, which will be the recipient of
our forward rules. Each target in the target group will have health checks so the load balancer will know which
instances are healthy and ready to receive requests.

![loadbalancer](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492081647/files/assets/neku_0608.png)

###### Figure 6-8. Load balancer components

Now that we have a basic understanding of how AWS structures its networking components, we can begin to see how EKS
leverages these components to the network and secure the managed Kubernetes cluster and network.

## Amazon Elastic Kubernetes Service

Amazon Elastic Kubernetes Service (EKS) is AWS’s managed Kubernetes service. It allows developers, cluster administrators,
and network administrators to quickly deploy a production-scale Kubernetes cluster. Using the scaling nature
of the cloud and AWS network services, with one API request, many services are deployed, including all the
components we reviewed in the previous sections.

How does EKS accomplish this? Like with any new service AWS releases, EKS has gotten significantly more feature-rich and
easier to use. EKS now supports on-prem deploys with EKS Anywhere, serverless with EKS Fargate, and even Windows
nodes. EKS clusters can be deployed traditionally with the AWS CLI or console. `eksctl` is a command-line tool
developed by Weaveworks, and it is by far the easiest way to date to deploy all the components needed to run EKS. Our
next section will detail the requirements to run an EKS cluster and how `eksctl` accomplishes this for cluster admins
and devs.

Let’s discuss the components of EKS cluster networking.

### EKS nodes

Workers nodes in EKS come in three flavors: EKS-managed node groups, self-managed nodes, and AWS Fargate.  The choice
for the administrator is how much control and operational overhead they would like to accrue.

Managed node groupAmazon EKS managed node groups create and manage EC2 instances for you. All managed nodes are provisioned as
part of an  EC2 Auto Scaling group that’s managed by Amazon EKS as well. All resources including  EC2 instances and
Auto Scaling groups run within your AWS account. A managed-node group’s Auto Scaling group spans all the subnets that
you specify when you create the group.

Self-managed node groupAmazon EKS nodes run in your AWS account and connect to your cluster’s control plane via the API
endpoint. You deploy nodes into a node group. A node group is a collection of EC2 instances that are
deployed in an EC2 Auto Scaling group. All instances in a node group must do the following:

-

Be the same instance type

-

Be running the same Amazon Machine Image

-

Use the same Amazon EKS node IAM role

FargateAmazon EKS integrates Kubernetes with AWS Fargate by using controllers that are built by AWS using the upstream,
extensible model provided by Kubernetes. Each pod running on Fargate has its own isolation boundary and does not
share the underlying kernel, CPU, memory, or elastic network interface with another pod. You also
cannot use security groups for pods with pods running on Fargate.

The instance type also affects the cluster network. In EKS the number of pods that can run on the nodes is defined
by the number of IP addresses that instance can run. We discuss this further in [“AWS VPC CNI”](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch06.html#awsvpccni) and [“eksctl”](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch06.html#eksctl).

Nodes must be able to communicate with the Kubernetes control plane and other AWS services. The IP address space is
crucial to run an EKS cluster. Nodes, pods, and all other services will use the VPC CIDR address ranges for
components. The EKS VPC requires a NAT gateway for private subnets and that those subnets be tagged for use with EKS:

```
Key – kubernetes.io/cluster/<cluster-name>
Value – shared
```

The placement of each node will determine the network “mode” that EKS operates; this has design considerations for
your subnets and Kubernetes API traffic routing.

### EKS mode

[Figure 6-9](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch06.html#eks-comms) outlines EKS components. The Amazon EKS control plane creates up to four cross-account elastic network
interfaces in your VPC for each cluster. EKS uses two VPCs, one for the Kubernetes control plane, including the
Kubernetes API masters, API loadbalancer, and etcd depending on the networking model; the other is the customer VPC
where the EKS worker nodes run your pods. As part of the boot process for the EC2 instance, the Kubelet is started. The node’s Kubelet reaches out to the Kubernetes cluster endpoint to register the node. It connects either to
the public
endpoint outside the VPC or to the private endpoint within the VPC. `kubectl` commands reach out to the API
endpoint in the EKS VPC. End users reach applications running in the customer VPC.

![eks-comms](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492081647/files/assets/neku_0609.png)

###### Figure 6-9. EKS communication path

There are three ways to configure cluster control traffic and the Kubernetes API endpoint for EKS, depending on where
the control and data planes of the Kubernetes components run.

The networking modes are as follows:

Public-onlyEverything runs in a public subnet, including worker nodes.

Private-onlyRuns solely in a private subnet, and Kubernetes cannot create internet-facing load balancers.

MixedCombo of public and private.

The public endpoint is the default option; it is public because the load balancer for the API endpoint is on a
public subnet, as shown in [Figure 6-10](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch06.html#eks-public). Kubernetes API requests that originate from within the cluster’s VPC, like when
the worker node reaches out to the control plane, leave the customer VPC, but not the Amazon network. One security
concern to consider when using a public endpoint is that the API endpoints are on a public subnet and reachable on
the internet.

![eks-public](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492081647/files/assets/neku_0610.png)

###### Figure 6-10. EKS public-only network mode

[Figure 6-11](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch06.html#eks-priv) shows the private endpoint mode; all traffic to your cluster API must come from within
your cluster’s VPC. There’s no internet access to your API server; any `kubectl` commands must come from within the
VPC or a connected network. The cluster’s API endpoint is resolved by public DNS to a private IP address in
the VPC.

![eks-priv](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492081647/files/assets/neku_0611.png)

###### Figure 6-11. EKS private-only network mode

When both public and private endpoints are enabled, any Kubernetes API requests from within the VPC communicate to the
control plane by the EKS-managed ENIs within the customer VPC, as demonstrated in [Figure 6-12](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch06.html#eks-combo). The cluster API is
still accessible from the internet, but it can be limited using security groups and NACLs.

###### Note

Please see the [AWS documentation](https://oreil.ly/mW7ii) for more ways to deploy an EKS.

Determining what mode to operate in is a critical decision administrators will make. It will affect the
application traffic, the routing for load balancers, and the security of the cluster. There are many other requirements
when deploying a cluster in EKS as well. `eksctl` is one tool to help manage all those requirements. But how does `eksctl`
accomplish that?

![eks-combo](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492081647/files/assets/neku_0612.png)

###### Figure 6-12. EKS public and private network mode

### eksctl

`eksctl` is a command-line tool developed by Weaveworks, and it is by far the easiest way to deploy all the components needed to run EKS.

###### Note

All the information about `eksctl` is available on its [website](https://eksctl.io/).

`eksctl` defaults to creating a cluster with the following default parameters:

-

An autogenerated cluster name

-

Two m5.large worker nodes

-

Use of the official AWS EKS AMI

-

Us-west-2 default AWS region

-

A dedicated VPC

A dedicated VPC with 192.168.0.0/16 CIDR range, `eksctl` will create by default 8 /19 subnets: three private, three
public, and two reserved subnets. `eksctl` will also deploy a NAT GW that allows for communication of nodes placed in
private subnets and an internet gateway to enable access for needed container images and communication  to the Amazon
S3 and Amazon ECR APIs.

Two security groups are set up for the EKS cluster:

Ingress inter node group SGAllows nodes to communicate with each other  on all ports

Control plane security groupAllows communication between the control plane and worker node groups

Node groups in public subnets will have SSH disabled. EC2 instances in the initial node group get a public IP and can be
accessed on high-level ports.

One node group containing two m5.large nodes is the default for `eksctl`. But how many pods can that node run? AWS has
a formula based on the node type and the number of interfaces and IP addresses it can support. That formula is as follows:

```
(Number of network interfaces for the instance type ×
(the number of IP addresses per network interface - 1)) + 2
```

Using the preceding formula and the default instance size on `eksctl`, an m5.large can support a maximum of 29 pods.

###### Warning

System pods count toward the maximum pods. The CNI plugin and `kube-proxy` pods run on every node
in a cluster, so you’re only able to deploy 27 additional pods to an m5.large instance.
CoreDNS runs on nodes in the cluster, which further decrements the maximum number of pods a node can run.

Teams running clusters must decide on cluster sizing and instance types to ensure no deployment issues with
hitting node and IP limitations. Pods will sit in the “waiting” state if there are no nodes available with the pod’s
IP address. Scaling events for the EKS node groups can also hit EC2 instance type limits and cause cascading
issues.

All of these networking options are configurable via the `eksctl` config file.

###### Note

`eksctl` VPC options are available in the [eksctl documentation](https://oreil.ly/m2Nqc).

We have discussed how the size node is important for pod IP addressing and the number of them we can run. Once the
node is deployed, the AWS VPC CNI manages pod IP addressing for nodes. Let’s dive into the inner workings of the CNI.

### AWS VPC CNI

AWS has its open source implementation of a CNI. AWS VPC CNI for the Kubernetes plugin offers high throughput and
availability, low latency, and minimal network jitter on the AWS network. Network engineers can apply existing AWS
VPC networking and security best practices for building Kubernetes clusters on  AWS. It includes using native AWS
services like VPC flow logs, VPC routing policies, and security groups for network traffic isolation.

###### Note

The open source for AWS VPC CNI is on [GitHub](https://oreil.ly/akwqx).

There are two components to the AWS VPC CNI:

CNI pluginThe CNI plugin is responsible for wiring up the host’s and pod’s network stack when called. It also
configures the interfaces and virtual Ethernet pairs.

ipamdA long-running node-local IPAM daemon is responsible for maintaining a
warm pool of available IP addresses and assigning an IP address to a pod.

[Figure 6-13](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch06.html#aws-VPC-cni) demonstrates what the VPC CNI will do for nodes. A customer VPC with a subnet 10.200.1.0/24 in AWS
gives us 250 usable addresses in this subnet. There are two nodes in our cluster. In EKS, the managed nodes run
with the AWS CNI as a daemon set. In our example, each node has  only one pod running, with a secondary IP address on
the ENI, `10.200.1.6` and `10.200.1.8`, for each pod. When a worker node first joins the cluster, there is only one ENI
and all its addresses in the ENI. When pod three gets scheduled to node 1, ipamd assigns the IP address to
the ENI for that pod. In this case, `10.200.1.7` is the same thing on node 2 with pod 4.

When a worker node first joins the cluster, there is only one ENI and all of its addresses in the ENI. Without
any configuration, `ipamd` always tries to keep one extra ENI. When several pods running on the node exceeds the number
of addresses on a single ENI, the CNI backend starts allocating a new ENI. The CNI plugin works by allocating multiple
ENIs to EC2 instances and then attaches secondary IP addresses to these ENIs. This plugin allows the CNI to allocate
as many IPs per instance as
possible.

![neku 0613](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492081647/files/assets/neku_0613.png)

###### Figure 6-13. AWS VPC CNI example

The AWS VPC CNI is highly configurable. This list includes just a few options:

AWS_VPC_CNI_NODE_PORT_SUPPORTSpecifies whether NodePort services are enabled on a worker node’s primary network
interface. This requires additional `iptables` rules and that the kernel’s reverse path filter on the primary interface
is set to loose.

AWS_VPC_K8S_CNI_CUSTOM_NETWORK_CFGWorker nodes can be configured in public subnets, so you need to configure
pods to be deployed in private subnets, or if pods’ security requirement needs are different from others running on the
node, setting this to `true` will enable that.

AWS_VPC_ENI_MTUDefault: 9001. Used to configure the MTU size for attached ENIs. The valid range is
from 576 to 9001.

WARM_ENI_TARGETSpecifies the number of free elastic network interfaces (and all of their available IP addresses)
that the `ipamd` daemon should attempt to keep available for pod assignment on the node. By default, `ipamd` attempts to
keep one elastic network interface and all of its IP addresses available for pod assignment. The number of IP addresses
per network interface varies by instance type.

AWS_VPC_K8S_CNI_EXTERNALSNATSpecifies whether an external NAT gateway should be used to provide SNAT of secondary
ENI IP addresses. If set to `true`, the SNAT `iptables` rule and external VPC IP rule are not applied, and these rules are
removed if they have already been applied. Disable SNAT if you need to allow inbound communication to your pods from
external VPNs, direct connections, and external VPCs, and your pods do not need to access the internet directly via
an internet gateway.

For example, if your pods with a private IP address need to communicate with others’ private IP address spaces, you
enable `AWS_VPC_K8S_CNI_EXTERNALSNAT` by using this command:

```bash
kubectl set env daemonset
-n kube-system aws-node AWS_VPC_K8S_CNI_EXTERNALSNAT=true
```

###### Note

All the information for EKS pod networking can be found in the [EKS documentation](https://oreil.ly/RAVVY).

The AWS VPC CNI allows for maximum control over the networking options on EKS in the AWS network.

There is also the AWS ALB ingress controller that makes managing and deploying applications on the
AWS cloud network smooth and automated. Let’s dig into that next.

### AWS ALB ingress controller

Let’s walk through the example in [Figure 6-14](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch06.html#alb) of how the AWS ALB works with Kubernetes. For a review of what an
ingress controller is, please check out [Chapter 5](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch05.html#kubernetes_networking_abstractions).

Let’s discuss all the moving parts of ALB Ingress controller:

1.

The ALB ingress controller watches for ingress events from the API server. When requirements are met,
it will start the creation process of an ALB.

1.

An ALB is created in AWS for the new ingress resource. Those resources can be internal or external to the cluster.

1.

Target groups are created in AWS for each unique Kubernetes service described in the ingress resource.

1.

Listeners are created for every port detailed in your ingress resource annotations. Default ports
for HTTP and HTTPS traffic are set up if not specified. NodePort
services for each service create the node ports that are used for our health checks.

1.

Rules are created for each path specified in your ingress resource. This ensures traffic to a specific
path is routed to the correct Kubernetes service.

![ALB](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492081647/files/assets/neku_0614.png)

###### Figure 6-14. AWS ALB example

How traffic reaches nodes and pods is affected by one of two modes the ALB can run:

Instance modeIngress traffic starts at the ALB and reaches the Kubernetes nodes through each service’s NodePort.
This means that services referenced from ingress resources must be exposed by `type:NodePort` to be reached by the ALB.

IP modeIngress traffic starts at the ALB and reaches directly to the Kubernetes pods. CNIs must support a directly
accessible pod IP address via secondary IP addresses on ENI.

The AWS ALB ingress controller allows developers to manage their network needs like their application components.
There is no need for other tool sets in the pipeline.

The AWS networking components are tightly integrated with EKS. Understanding the basic options of how they work is
fundamental for all those looking to scale their applications on Kubernetes on AWS using EKS. The size of your
subnets, the placements of the nodes in those subnets, and of course the size of nodes will affect how large of a network
of pods and services you can run on the AWS network. Using a managed service such as EKS, with open source tools like
`eksctl`, will greatly reduce the operational overhead of running an AWS Kubernetes cluster.

## Deploying an Application on an AWS EKS Cluster

Let’s walk through deploying an EKS cluster to manage our Golang web server:

1.

Deploy the EKS cluster.

1.

Deploy the web server Application and LoadBalancer.

1.

Verify.

1.

Deploy ALB Ingress Controller and Verify.

1.

Clean up.

### Deploy EKS cluster

Let’s deploy an EKS cluster, with the current and latest version EKS supports, 1.20:

```bash
export CLUSTER_NAME=eks-demo
eksctl create cluster -N 3 --name ${CLUSTER_NAME} --version=1.20
eksctl version 0.54.0
using region us-west-2
setting availability zones to [us-west-2b us-west-2a us-west-2c]
subnets for us-west-2b - public:192.168.0.0/19 private:192.168.96.0/19
subnets for us-west-2a - public:192.168.32.0/19 private:192.168.128.0/19
subnets for us-west-2c - public:192.168.64.0/19 private:192.168.160.0/19
nodegroup "ng-90b7a9a5" will use "ami-0a1abe779ecfc6a3e" [AmazonLinux2/1.20]
using Kubernetes version 1.20
creating EKS cluster "eks-demo" in "us-west-2" region with un-managed nodes
will create 2 separate CloudFormation stacks for cluster itself and the initial
nodegroup
if you encounter any issues, check CloudFormation console or try
'eksctl utils describe-stacks --region=us-west-2 --cluster=eks-demo'
CloudWatch logging will not be enabled for cluster "eks-demo" in "us-west-2"
you can enable it with
'eksctl utils update-cluster-logging --enable-types={SPECIFY-YOUR-LOG-TYPES-HERE
(e.g. all)} --region=us-west-2 --cluster=eks-demo'
Kubernetes API endpoint access will use default of
{publicAccess=true, privateAccess=false} for cluster "eks-demo" in "us-west-2"
2 sequential tasks: { create cluster control plane "eks-demo",
3 sequential sub-tasks: { wait for control plane to become ready, 1 task:
{ create addons }, create nodegroup "ng-90b7a9a5" } }
building cluster stack "eksctl-eks-demo-cluster"
deploying stack "eksctl-eks-demo-cluster"
waiting for CloudFormation stack "eksctl-eks-demo-cluster"
<truncate>
building nodegroup stack "eksctl-eks-demo-nodegroup-ng-90b7a9a5"
--nodes-min=3 was set automatically for nodegroup ng-90b7a9a5
deploying stack "eksctl-eks-demo-nodegroup-ng-90b7a9a5"
waiting for CloudFormation stack "eksctl-eks-demo-nodegroup-ng-90b7a9a5"
<truncated>
waiting for the control plane availability...
saved kubeconfig as "/Users/strongjz/.kube/config"
no tasks
all EKS cluster resources for "eks-demo" have been created
adding identity
"arn:aws:iam::1234567890:role/
eksctl-eks-demo-nodegroup-ng-9-NodeInstanceRole-TLKVDDVTW2TZ" to auth ConfigMap
nodegroup "ng-90b7a9a5" has 0 node(s)
waiting for at least 3 node(s) to become ready in "ng-90b7a9a5"
nodegroup "ng-90b7a9a5" has 3 node(s)
node "ip-192-168-31-17.us-west-2.compute.internal" is ready
node "ip-192-168-58-247.us-west-2.compute.internal" is ready
node "ip-192-168-85-104.us-west-2.compute.internal" is ready
kubectl command should work with "/Users/strongjz/.kube/config",
try 'kubectl get nodes'
EKS cluster "eks-demo" in "us-west-2" region is ready
```

In the output we can see that EKS creating a nodegroup, `eksctl-eks-demo-nodegroup-ng-90b7a9a5`, with three nodes:

```
ip-192-168-31-17.us-west-2.compute.internal
ip-192-168-58-247.us-west-2.compute.internal
ip-192-168-85-104.us-west-2.compute.internal
```

They are all inside a VPC with three public and three private subnets across three AZs:

```
public:192.168.0.0/19 private:192.168.96.0/19
public:192.168.32.0/19 private:192.168.128.0/19
public:192.168.64.0/19 private:192.168.160.0/19
```

###### Warning

We used the default settings of eksctl, and it deployed the k8s API as a public endpoint, `{publicAccess=true,
privateAccess=false}`.

Now we can deploy our Golang web application in the cluster and expose it with a LoadBalancer service.

### Deploy test application

You can deploy applications individually or all together. *dnsutils.yml* is our `dnsutils` testing pod, *database.yml* is the
Postgres database for pod connectivity testing, *web.yml* is the Golang web server and the LoadBalancer service:

```bash
kubectl apply -f dnsutils.yml,database.yml,web.yml
```

Let’s run a `kubectl get pods` to see if all the pods are running fine:

```bash
kubectl get pods -o wide
NAME                   READY   STATUS    IP               NODE
app-6bf97c555d-5mzfb   1/1     Running   192.168.15.108   ip-192-168-0-94
app-6bf97c555d-76fgm   1/1     Running   192.168.52.42    ip-192-168-63-151
app-6bf97c555d-gw4k9   1/1     Running   192.168.88.61    ip-192-168-91-46
dnsutils               1/1     Running   192.168.57.174   ip-192-168-63-151
postgres-0             1/1     Running   192.168.70.170   ip-192-168-91-46
```

Now check on the LoadBalancer service:

```bash
kubectl get svc clusterip-service
NAME                TYPE           CLUSTER-IP
EXTERNAL-IP                                                              PORT(S)        AGE
clusterip-service   LoadBalancer   10.100.159.28
a76d1c69125e543e5b67c899f5e45284-593302470.us-west-2.elb.amazonaws.com   80:32671/TCP   29m
```

The service has endpoints as well:

```bash
kubectl get endpoints clusterip-service
NAME                ENDPOINTS                                                   AGE
clusterip-service   192.168.15.108:8080,192.168.52.42:8080,192.168.88.61:8080   58m
```

We should verify the application is reachable inside the cluster, with the ClusterIP and port, `10.100.159.28:8080`; service name and port, `clusterip-service:80`; and finally pod IP and port, `192.168.15.108:8080`:

```bash
kubectl exec dnsutils -- wget -qO- 10.100.159.28:80/data
Database Connected

kubectl exec dnsutils -- wget -qO- 10.100.159.28:80/host
NODE: ip-192-168-63-151.us-west-2.compute.internal, POD IP:192.168.52.42

kubectl exec dnsutils -- wget -qO- clusterip-service:80/host
NODE: ip-192-168-91-46.us-west-2.compute.internal, POD IP:192.168.88.61

kubectl exec dnsutils -- wget -qO- clusterip-service:80/data
Database Connected

kubectl exec dnsutils -- wget -qO- 192.168.15.108:8080/data
Database Connected

kubectl exec dnsutils -- wget -qO- 192.168.15.108:8080/host
NODE: ip-192-168-0-94.us-west-2.compute.internal, POD IP:192.168.15.108
```

The database port is reachable from `dnsutils`, with the pod IP and port `192.168.70.170:5432`, and the service name and port - `postgres:5432`:

```bash
kubectl exec dnsutils -- nc -z -vv -w 5 192.168.70.170 5432
192.168.70.170 (192.168.70.170:5432) open
sent 0, rcvd 0

kubectl exec dnsutils -- nc -z -vv -w 5 postgres 5432
postgres (10.100.106.134:5432) open
sent 0, rcvd 0
```

The application inside the cluster is up and running. Let’s test it from external to the cluster.

### Verify LoadBalancer services for Golang web server

`kubectl` will return all the information we will need to test, the ClusterIP, the external IP, and all the ports:

```bash
kubectl get svc clusterip-service
NAME                TYPE           CLUSTER-IP
EXTERNAL-IP                                                              PORT(S)        AGE
clusterip-service   LoadBalancer   10.100.159.28
a76d1c69125e543e5b67c899f5e45284-593302470.us-west-2.elb.amazonaws.com   80:32671/TCP   29m
```

Using the external IP of the load balancer:

```
wget -qO-
a76d1c69125e543e5b67c899f5e45284-593302470.us-west-2.elb.amazonaws.com/data
Database Connected
```

Let’s test the load balancer and make multiple requests to our backends:

```
wget -qO-
a76d1c69125e543e5b67c899f5e45284-593302470.us-west-2.elb.amazonaws.com/host
NODE: ip-192-168-63-151.us-west-2.compute.internal, POD IP:192.168.52.42

wget -qO-
a76d1c69125e543e5b67c899f5e45284-593302470.us-west-2.elb.amazonaws.com/host
NODE: ip-192-168-91-46.us-west-2.compute.internal, POD IP:192.168.88.61

wget -qO-
a76d1c69125e543e5b67c899f5e45284-593302470.us-west-2.elb.amazonaws.com/host
NODE: ip-192-168-0-94.us-west-2.compute.internal, POD IP:192.168.15.108

wget -qO-
a76d1c69125e543e5b67c899f5e45284-593302470.us-west-2.elb.amazonaws.com/host
NODE: ip-192-168-0-94.us-west-2.compute.internal, POD IP:192.168.15.108
```

`kubectl get pods -o wide` again will verify our pod information matches the loadbalancer requests:

```bash
kubectl get pods -o wide
NAME                  READY  STATUS    IP              NODE
app-6bf97c555d-5mzfb  1/1    Running   192.168.15.108  ip-192-168-0-94
app-6bf97c555d-76fgm  1/1    Running   192.168.52.42   ip-192-168-63-151
app-6bf97c555d-gw4k9  1/1    Running   192.168.88.61   ip-192-168-91-46
dnsutils              1/1    Running   192.168.57.174  ip-192-168-63-151
postgres-0            1/1    Running   192.168.70.170  ip-192-168-91-46
```

We can also check the nodeport, since `dnsutils` is running inside our VPC, on an EC2 instance; it can do a DNS lookup on
the private host, `ip-192-168-0-94.us-west-2.compute.internal`, and the `kubectl get service` command gave us the
node port, 32671:

```bash
kubectl exec dnsutils -- wget -qO-
ip-192-168-0-94.us-west-2.compute.internal:32671/host
NODE: ip-192-168-0-94.us-west-2.compute.internal, POD IP:192.168.15.108
```

Everything seems to running just fine externally and locally in our cluster.

### Deploy ALB ingress and verify

For some sections of the deployment, we will need to know the AWS account ID we are deploying. Let’s put that into
an environment variable. To get your account ID, you can run the following:

```
aws sts get-caller-identity
{
    "UserId": "AIDA2RZMTHAQTEUI3Z537",
    "Account": "1234567890",
    "Arn": "arn:aws:iam::1234567890:user/eks"
}

export ACCOUNT_ID=1234567890
```

If it is not set up for the cluster already, we will have to set up an OIDC provider with the cluster.

This step is needed to give IAM permissions to a pod running in the cluster using the IAM for SA:

```
eksctl utils associate-iam-oidc-provider \
--region ${AWS_REGION} \
--cluster ${CLUSTER_NAME}  \
--approve
```

For the SA role, we will need to create an IAM policy to determine the permissions for the ALB controller in AWS:

```
aws iam create-policy \
--policy-name AWSLoadBalancerControllerIAMPolicy \
--policy-document iam_policy.json
```

Now we need to create the SA and attach it to the IAM role we created:

```
eksctl create iamserviceaccount \
> --cluster ${CLUSTER_NAME} \
> --namespace kube-system \
> --name aws-load-balancer-controller \
> --attach-policy-arn
arn:aws:iam::${ACCOUNT_ID}:policy/AWSLoadBalancerControllerIAMPolicy \
> --override-existing-serviceaccounts \
> --approve
eksctl version 0.54.0
using region us-west-2
1 iamserviceaccount (kube-system/aws-load-balancer-controller) was included
(based on the include/exclude rules)
metadata of serviceaccounts that exist in Kubernetes will be updated,
as --override-existing-serviceaccounts was set
1 task: { 2 sequential sub-tasks: { create IAM role for serviceaccount
"kube-system/aws-load-balancer-controller", create serviceaccount
"kube-system/aws-load-balancer-controller" } }
building iamserviceaccount stack
deploying stack
waiting for CloudFormation stack
waiting for CloudFormation stack
waiting for CloudFormation stack
created serviceaccount "kube-system/aws-load-balancer-controller"
```

We can see all the details of the SA with the following:

```bash
kubectl get sa aws-load-balancer-controller -n kube-system -o yaml
apiVersion: v1
kind: ServiceAccount
metadata:
annotations:
eks.amazonaws.com/role-arn:
arn:aws:iam::1234567890:role/eksctl-eks-demo-addon-iamserviceaccount-Role1
creationTimestamp: "2021-06-27T18:40:06Z"
labels:
app.kubernetes.io/managed-by: eksctl
name: aws-load-balancer-controller
namespace: kube-system
resourceVersion: "16133"
uid: 30281eb5-8edf-4840-bc94-f214c1102e4f
secrets:
- name: aws-load-balancer-controller-token-dtq48
```

The `TargetGroupBinding` CRD allows the controller to bind a Kubernetes
service endpoint to an AWS `TargetGroup`:

```bash
kubectl apply -f crd.yml
customresourcedefinition.apiextensions.k8s.io/ingressclassparams.elbv2.k8s.aws
configured
customresourcedefinition.apiextensions.k8s.io/targetgroupbindings.elbv2.k8s.aws
configured
```

Now we’re ready to the deploy the ALB controller with Helm.

Set the version environment to deploy:

```
export ALB_LB_VERSION="v2.2.0"
```

Now deploy it, add the `eks` Helm repo, get the VPC ID the cluster is running in, and finally deploy via Helm.

```
helm repo add eks https://aws.github.io/eks-charts

export VPC_ID=$(aws eks describe-cluster \
--name ${CLUSTER_NAME} \
--query "cluster.resourcesVpcConfig.vpcId" \
--output text)

helm upgrade -i aws-load-balancer-controller \
eks/aws-load-balancer-controller \
-n kube-system \
--set clusterName=${CLUSTER_NAME} \
--set serviceAccount.create=false \
--set serviceAccount.name=aws-load-balancer-controller \
--set image.tag="${ALB_LB_VERSION}" \
--set region=${AWS_REGION} \
--set vpcId=${VPC_ID}

Release "aws-load-balancer-controller" has been upgraded. Happy Helming!
NAME: aws-load-balancer-controller
LAST DEPLOYED: Sun Jun 27 14:43:06 2021
NAMESPACE: kube-system
STATUS: deployed
REVISION: 2
TEST SUITE: None
NOTES:
AWS Load Balancer controller installed!
```

We can watch the deploy logs here:

```bash
kubectl logs -n kube-system -f deploy/aws-load-balancer-controller
```

Now to deploy our ingress with ALB:

```bash
kubectl apply -f alb-rules.yml
ingress.networking.k8s.io/app configured
```

With the `kubectl describe ing app` output, we can see the ALB has been deployed.

We can also see the ALB public DNS address, the rules for the instances, and the endpoints backing the service.

```bash
kubectl describe ing app
Name:             app
Namespace:        default
Address:
k8s-default-app-d5e5a26be4-2128411681.us-west-2.elb.amazonaws.com
Default backend:  default-http-backend:80
(<error: endpoints "default-http-backend" not found>)
Rules:
Host        Path  Backends
  ----        ----  --------
*
          /data   clusterip-service:80 (192.168.3.221:8080,
192.168.44.165:8080,
192.168.89.224:8080)
          /host   clusterip-service:80 (192.168.3.221:8080,
192.168.44.165:8080,
192.168.89.224:8080)
Annotations:  alb.ingress.kubernetes.io/scheme: internet-facing
kubernetes.io/ingress.class: alb
Events:
Type     Reason                  Age                     From
Message
----     ------                  ----                    ----
-------
Normal   SuccessfullyReconciled  4m33s (x2 over 5m58s)   ingress
Successfully reconciled
```

It’s time to test our ALB!

```
wget -qO- k8s-default-app-d5e5a26be4-2128411681.us-west-2.elb.amazonaws.com/data
Database Connected

wget -qO- k8s-default-app-d5e5a26be4-2128411681.us-west-2.elb.amazonaws.com/host
NODE: ip-192-168-63-151.us-west-2.compute.internal, POD IP:192.168.44.165
```

### Cleanup

Once you are done working with EKS and testing, make sure to delete the applications pods and the service to ensure
that everything is deleted:

```bash
kubectl delete -f dnsutils.yml,database.yml,web.yml
```

Clean up the ALB:

```bash
kubectl delete -f alb-rules.yml
```

Remove the IAM policy for ALB controller:

```
aws iam  delete-policy
--policy-arn arn:aws:iam::${ACCOUNT_ID}:policy/AWSLoadBalancerControllerIAMPolicy
```

Verify there are no leftover EBS volumes from the PVCs for test application. Delete any EBS volumes found for the
PVC’s for the Postgres test database:

```
aws ec2 describe-volumes --filters
Name=tag:kubernetes.io/created-for/pv/name,Values=*
--query "Volumes[].{ID:VolumeId}"
```

Verify there are no load balancers running, ALB or otherwise:

```
aws elbv2 describe-load-balancers --query "LoadBalancers[].LoadBalancerArn"
```

```
aws elb describe-load-balancers --query "LoadBalancerDescriptions[].DNSName"
```

Let’s make sure we delete the cluster, so you don’t get charged for a cluster doing nothing:

```
eksctl delete cluster --name ${CLUSTER_NAME}
```

We deployed a service load balancer that will for each service deploy a classical ELB into AWS. The ALB controller allows developers to use ingress with ALB or NLBs to expose the application externally. If we were to scale our application to multiple backend services, the ingress allows us to use one load balancer and route based on layer 7
information.

In the next section, we will explore GCP in the same manner we just did for AWS.

# Google Compute Cloud (GCP)

In 2008, Google announced App Engine, a platform as a service to deploy Java, Python, Ruby, and Go applications.
Like its competitors, GCP has extended its service offerings. Cloud providers work to distinguish their
offerings, so no two products are ever the same. Nonetheless, many products do have a lot in common. For instance,
GCP Compute Engine is an infrastructure as a service to run virtual machines. The GCP network consists of 25 cloud
regions, 76 zones, and 144 network edge locations. Utilizing both the scale of the GCP network and Compute
Engine, GCP has released Google Kubernetes Engine, its container as a service platform.

## GCP Network Services

Managed and unmanaged Kubernetes clusters on GCP share the same networking principles. Nodes in either managed or
unmanaged clusters run as Google Compute Engine instances. Networks in GCP are VPC networks. GCP VPC networks, like in AWS, contain functionality for IP management, routing, firewalling, and peering.

The GCP network is divided into tiers for customers to choose from; there are premium and standard tiers. They differ in
performance, routing, and functionality, so network engineers must decide which is suitable for their workloads. The
premium tier is the highest performance for your workloads. All the traffic between the internet and instances in
the VPC network is routed within Google’s network as far as possible. If your services need global availability, you
should use premium. Make sure to remember that the premium tier is the default unless you make configuration changes.

The standard tier is a cost-optimized tier where traffic between the internet and VMs in the VPC network is routed over
the internet in general. Network engineers should pick this tier for services that are going to be hosted entirely
within a region. The standard tier cannot guarantee performance as it is subject to the same performance that all
workloads share on the internet.

The GCP network differs from the other providers by having what is called *global* resources. Global because users can
access them in any zone within the same project. These resources include such things as VPC, firewalls, and their
routes.

###### Note

See the [GCP documentation](https://oreil.ly/mzgG2) for a more comprehensive overview of the network tiers.

### Regions and zones

Regions are independent geographic areas that contain multiple zones. Regional resources offer redundancy by being
deployed across multiple zones for that region. Zones are deployment areas for resources within a region. One zone is
typically a data center within a region, and administrators should consider them a single fault domain. In
fault-tolerant application deployments, the best practice is to deploy applications across multiple zones within a
region, and for high availability, you should deploy applications across various regions. If a zone becomes
unavailable, all the zone resources will be unavailable  until owners restore services.

### Virtual private cloud

A VPC is a virtual network that provides connectivity for resources within a GCP project. Like accounts and
subscriptions, projects can contain multiple VPC networks, and by default, new projects start with a default
auto-mode VPC network that also includes one subnet in each region. Custom-mode VPC networks can contain no subnets.
As stated earlier, VPC networks are global resources and are not associated with any particular region or zone.

A VPC network contains one or more regional subnets. Subnets have a region, CIDR, and globally unique name. You can
use any CIDR for a subnet, including one that overlaps with another private address space. The specific choice of
subnet CIDR impacts which IP addresses you can reach and which networks you can peer.

###### Warning

Google creates a “default” VPC network,
with randomly generated subnets for each region.
Some subnets may overlap with another VPC’s subnet
(such as the default VPC network in another Google Cloud project),
which will prevent peering.

VPC networks support peering and shared VPC configuration. Peering a VPC network allows the VPC in one project to
route to the VPC in another, placing them on the same L3 network. You cannot peer with any overlapping VPC network,
as some IP addresses exist in both networks. A shared VPC allows another project to use specific subnets, such as
creating machines that are part of that subnet. The  [VPC documentation](https://oreil.ly/98Wav) has more information.

###### Tip

Peering VPC networks is standard, as organizations often assign different teams, applications, or components to their
project in Google Cloud. Peering has upsides for access control, quota, and reporting. Some admins may also create
multiple VPC networks within a project for similar reasons.

### Subnet

Subnets are portions within a VPC network with one primary IP range with the ability to have zero or more
secondary ranges. Subnets are regional resources, and each subnet defines a range of IP addresses. A region can have
more than one subnet. There are two modes of subnet formulation when you create them: auto or custom. When you create
an auto-mode VPC network, one subnet from each region is automatically created within it using predefined IP ranges.
When you define a custom-mode VPC network, GCP does not provision any subnets, giving administrators control over the
ranges. Custom-mode VPC networks are suited for enterprises and production environments for network engineers to use.

Google Cloud allows you to “reserve” static IP addresses for internal and external IP addresses. Users can utilize
reserved IP addresses for GCE instances, load balancers, and other products beyond our scope. Reserved internal IP
addresses have a name and can be generated automatically or assigned manually. Reserving an internal static IP
address prevents it from being randomly automatically assigned while not in use.

Reserving external IP addresses is similar; although you can request an automatically assigned IP address, you
cannot choose what IP address to reserve. Because you are reserving a globally routable IP address, charges apply in
some circumstances. You cannot secure an external IP address that you were assigned automatically as an ephemeral IP
address.

### Routes and firewall rules

When deploying a VPC, you can use firewall rules to allow or deny connections to and from your application instances
based on the rules you deploy. Each firewall rule can apply to ingress or egress connections, but not both. The
instance level is where GCP enforces rules, but the configuration pairs with the VPC network, and you cannot share
firewall rules among VPC networks, peered networks included. VPC firewall rules are stateful, so when a TCP session
starts, firewall rules allow bidirectional traffic similar to an AWS security group.

### Cloud load balancing

Google Cloud Load Balancer (GCLB) offers a fully distributed, high-performance, scalable load balancing service
across GCP, with various load balancer options. With GCLB, you get a single Anycast IP that fronts all your backend
instances across the globe, including multiregion failover. In addition, software-defined load balancing services
enable you to apply load balancing to your HTTP(S), TCP/SSL, and UDP traffic. You can also terminate your SSL traffic
with an SSL proxy and HTTPS load balancing. Internal load balancing enables you to build highly available internal
services for your internal instances without requiring any load balancers to be exposed to the internet.

The vast majority of GCP users make use of GCP’s load balancers with Kubernetes ingress. GCP has internal-facing and
external-facing load balancers, with L4 and L7 support. GKE clusters default to creating a GCP load balancer for
ingresses and `type: LoadBalancer` services.

To expose applications outside a GKE cluster, GKE provides a built-in GKE ingress controller and GKE service
controller, which deploys a Google Cloud load balancer on behalf of GKE users. GKE provides three different load
balancers to control access and spread incoming traffic across your cluster as evenly as possible. You can configure
one service to use multiple types of load balancers simultaneously:

External load balancersManage traffic from outside the cluster and outside the VPC network. External load balancers use forwarding
rules associated with the Google Cloud network to route traffic to a Kubernetes node.

Internal load balancersManage traffic coming from within the same VPC network. Like external load balancers,
internal ones use forwarding rules associated with the Google Cloud network to route traffic to a Kubernetes node.

HTTP load balancersSpecialized external load balancers used for HTTP traffic. They use an ingress resource rather
than a forwarding rule to route traffic to a Kubernetes node.

When you create an ingress object, the GKE ingress controller configures a Google Cloud HTTP(S) load balancer
according to the ingress manifest and the associated Kubernetes service rules manifest. The client sends a request to
the load balancer. The load balancer is a proxy; it chooses a node and forwards the request to that node’s
NodeIP:NodePort combination. The node uses its `iptables` NAT table to select a pod. As we learned in earlier chapters,
`kube-proxy` manages the `iptables` rules on that node.

When an ingress creates a load balancer, the load balancer is “pod aware” instead of routing to all nodes (and
relying on the service to route requests to a pod), and the load balancer routes to individual pods.
It does this by tracking the underlying `Endpoints`/`EndpointSlice` object (as covered in [Chapter 5](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch05.html#kubernetes_networking_abstractions)) and using individual
pod IP addresses as target addresses.

Cluster administrators can use an in-cluster ingress provider, such as ingress-Nginx or Contour. A load
balancer points to applicable nodes running the ingress proxy in such a setup, which routes requests to the
applicable pods from there. This setup is cheaper for clusters that have many ingresses but incurs performance overhead.

### GCE instances

GCE instances have one or more network interfaces. A network interface has a network and subnetwork, a private IP
address, and a public IP address. The private IP address must be part of the subnetwork. Private IP addresses can
be automatic and ephemeral, custom and ephemeral, or static. External IP addresses can be automatic and ephemeral, or
static. You can add more network interfaces to a GCE instance. Additional network interfaces don’t need to be in the
same VPC network. For example, you may have an instance that bridges two VPCs with varying levels of security. Let’s
discuss how GKE uses these instances and manages the network services that empower GKE.

## GKE

Google Kubernetes Engine (GKE) is Google’s managed Kubernetes service. GKE runs a hidden control plane, which cannot
be directly viewed or accessed. You can only access specific control plane configurations and the Kubernetes API.

GKE exposes broad cluster config around things like machine types and cluster scaling. It reveals only some
network-related settings. At the time of writing, NetworkPolicy support (via Calico), max pods per node (`maxPods` in
the kubelet, `--node-CIDR-mask-size` in `kube-controller-manager`), and the pod address range (`--cluster-CIDR` in
`kube-controller-manager`) are the customizable options. It is not possible to directly set
`apiserver/kube-controller-manager` flags.

GKE supports public and private clusters. Private clusters don’t issue public IP addresses to nodes, which means
nodes are accessible only within your private network. Private clusters also allow you to restrict access to the
Kubernetes API to specific IP addresses. GKE runs worker nodes using automatically managed GCE instances by creating
creates *node pools*.

### GCP GKE nodes

Networking for GKE nodes is comparable to networking for self-managed Kubernetes clusters on GKE. GKE clusters
define *node pools,* which are a set of nodes with an identical configuration. This configuration contains
GCE-specific settings as well as general Kubernetes settings. Node pools define (virtual) machine type, autoscaling,
and the GCE service account. You can also set custom taints and labels per node pool.

A cluster exists on exactly one VPC network. Individual nodes can have their
network tags for crafting specific
firewall rules. Any GKE cluster running 1.16 or later will have a `kube-proxy` DaemonSet so that all new nodes in the
cluster will automatically have the `kube-proxy` start. The size of the subnet allows will affect the size of the
cluster. So, pay attention to the size of that when you deploy clusters that scale. There is a formula you can use to
calculate the maximum number of nodes, `N`, that a given netmask can support. Use `S` for the netmask size, whose valid
range is between 8 and 29:

```
N = 2(32 -S) - 4
```

Calculate the size of the netmask, `S`, required to support a maximum of `N` nodes:

```
S = 32 - ⌈log2(N + 4)⌉
```

[Table 6-2](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch06.html#cluster_node_scale_with_subnet_size) also outlines cluster node and how it scales with subnet size.

| Subnet primary IP range | Maximum nodes |
| --- | --- |
| /29 | Minimum size for a subnet’s primary IP range: 4 nodes |
| /28 | 12 nodes |
| /27 | 28 nodes |
| /26 | 60 nodes |
| /25 | 124 nodes |
| /24 | 252 nodes |
| /23 | 508 nodes |
| /22 | 1,020 nodes |
| /21 | 2,044 nodes |
| /20 | The default size of a subnet’s primary IP range in auto mode networks: 4,092 nodes |
| /19 | 8,188 nodes |
| /8 | Maximum size for a subnet’s primary IP range: 16,777,212 nodes |

If you use GKE’s CNI, one end of the veth pair is attached to the pod in its namespace and connects the other side to the Linux bridge device cbr0.1, exactly how we outlined it in Chapters [2](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch02.html#linux_networking) and [3](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch03.html#container_networking_basics).

Clusters span either the zone or region boundary; zonal clusters have only a single control plane. Regional
clusters have multiple replicas of the control plane. Also, when you deploy clusters, there are two cluster modes with
GKE: VPC-native and routes based. A cluster that uses alias IP address ranges is considered a VPC-native cluster. A cluster that uses custom
static routes in a VPC network is called a *routes-based cluster*. [Table 6-3](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch06.html#cluster_mode_with_cluster_creation_method) outlines how the creation method
maps with the cluster mode.

| Cluster creation method | Cluster network mode |
| --- | --- |
| Google Cloud Console | VPC-native |
| REST API | Routes-based |
| gcloud v256.0.0 and higher or v250.0.0 and lower | Routes-based |
| gcloud v251.0.0–255.0.0 | VPC-native |

When using VPC-native, administrators can also take advantage of network endpoint groups (NEG), which represent a
group of backends served by a load balancer. NEGs are lists of IP addresses managed by an NEG controller and are used
by Google Cloud load balancers. IP addresses in an NEG can be primary or secondary IP addresses of a VM, which means
they can be pod IPs. This enables container-native load balancing that sends traffic directly to pods from a Google
Cloud load balancer.

VPC-native clusters have several benefits:

-

Pod IP addresses are natively routable inside the cluster’s VPC network.

-

Pod IP addresses are reserved in network before pod creation.

-

Pod IP address ranges are dependent on custom static routes.

-

Firewall rules apply to just pod IP address ranges instead of any IP address on the cluster’s nodes.

-

GCP cloud network connectivity to on-premise extends to pod IP address ranges.

[Figure 6-15](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch06.html#neg) shows the mapping of GKE to GCE components.

![NEG](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492081647/files/assets/neku_0615.png)

###### Figure 6-15. NEG to GCE components

Here is a list of improvements that NEGs bring to the GKE network:

Improved network performanceThe container-native load balancer talks directly with the pods, and connections have fewer network hops; both
latency and throughput are improved.

Increased visibilityWith container-native load balancing, you have visibility into the latency from the HTTP
load balancer to the pods. The latency from the HTTP load balancer to each pod is visible, which was aggregated with
node IP-based container-native load balancing. This increased visibility makes troubleshooting your services at the NEG
level easier.

Support for advanced load balancingContainer-native load balancing offers native support in GKE for several HTTP load-balancing
features, such as integration with Google Cloud services like Google Cloud Armor, Cloud CDN, and Identity-Aware Proxy.
It also features load-balancing algorithms for accurate traffic distribution.

Like most managed Kubernetes offerings from major providers,
GKE is tightly integrated with Google Cloud offerings.
Although much of the software driving GKE is opaque, it uses standard resources such as GCE instances
that can be inspected and debugged like any other GCP resources.
If you really need to manage your own clusters, you will lose out on some functionality,
such as container-aware load balancing.

It’s worth noting that GCP does not yet support IPv6, unlike AWS and Azure.

Finally, we’ll look at Kubernetes networking on Azure.

# Azure

Microsoft Azure, like other cloud providers, offers an assortment of enterprise-ready network solutions and services.
Before we can discuss how Azure AKS networking works, we should discuss Azure deployment models. Azure has gone
through some significant iterations and improvements over the years, resulting in two different deployment models
that can encounter Azure. These models differ in how resources are deployed and managed and may impact how users
leverage the resources.

The first deployment model was the classic deployment model. This model was the initial deployment and management
method for Azure.
All resources existed independently of each other, and you could not logically group them. This was cumbersome; users
had to create, update, and delete each component of a solution, leading to errors, missed resources, and additional
time, effort, and cost. Finally, these resources could not even be tagged for easy searching, adding to the
difficulty of the solution.

In 2014, Microsoft introduced the Azure Resource Manager as the second model. This new model is the recommended model
from Microsoft, with the recommendation going so far as to say that you should redeploy your resources using the
Azure Resource Manager (ARM). The primary change with this model was the introduction of the resource group. Resource
groups are a logical grouping of resources that allows for tracking, tagging, and configuring the resources as a group
rather than
individually.

Now that we understand the basics of how resources are deployed and managed in Azure, we can discuss the Azure network service
offerings and how they interact with the Azure Kubernetes Service (AKS) and non-Azure Kubernetes offerings.

## Azure Networking Services

The core of Azure networking services is the virtual network, also known as an Azure Vnet. The Vnet establishes an
isolated virtual network infrastructure to connect your deployed Azure resources such as virtual machines and AKS
clusters. Through additional resources, Vnets connect your deployed resources to the public internet as well as your
on-premise infrastructure. Unless the configuration is changed, all Azure Vnets can communicate with the internet
through a default route.

In [Figure 6-16](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch06.html#Vnet), an Azure Vnet has a single CIDR of `192.168.0.0/16`. Vnets, like other Azure resources, require a
subscription to place the Vnet into a resource group for the Vnet. The security of the Vnet can be configured
while some options, such as IAM permissions, are inherited from the resource group and the subscription. The Vnet is
confined to a specified region. Multiple Vnets can exist within a single region, but a Vnet can exist within only one region.

![Vnet](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492081647/files/assets/neku_0616.png)

###### Figure 6-16. Azure Vnet

### Azure backbone infrastructure

Microsoft Azure leverages a globally dispersed network of data centers and zones. The foundation of this dispersal is
the Azure region, which comprises a set of data centers within a latency-defined area, connected by a low-latency,
dedicated network infrastructure. A region can contain any number of data centers that meet these criteria, but two
to three are often present per region. Any area of the world containing at least one Azure region is known as Azure geography.

Availability zones further divide a region. Availability zones are physical locations that can consist of one or more
data centers maintained by independent power,
cooling, and networking infrastructure. The relationship of a region to
its availability zones is architected so that a single availability zone failure cannot bring down an entire region
of services. Each availability zone in a region is connected to the other availability zones in the region but not
dependent on the different zones. Availability zones allow Azure to offer 99.99% uptime for supported services. A
region can consist of multiple availability zones, as shown in [Figure 6-17](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch06.html#Region), which can, in turn, consist of numerous data
centers.

![Region](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492081647/files/assets/neku_0617.png)

###### Figure 6-17. Region

Since a Vnet is within a region and regions are divided into availability zones, Vnets are also available across the
availability zones of the region they are deployed. As shown in [Figure 6-18](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch06.html#VnetWithAzs), it is a best practice when deploying infrastructure for high
availability to leverage multiple availability zones for redundancy. Availability zones allow Azure to offer 99.99%
uptime for supported services. Azure allows for the use of load balancers for networking across redundant systems
such as these.

![Vnet With availability zones](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492081647/files/assets/neku_0618.png)

###### Figure 6-18. Vnet with availability zones

###### Note

The Azure [documentation](https://oreil.ly/Pv0iq) has an up-to-date list of Azure geographies, regions, and availability zones.

### Subnets

Resource IPs are not assigned directly from the Vnet. Instead, subnets divide and define a Vnet. The subnets receive
their address space from the Vnet. Then, private IPs are allocated to provisioned resources within each subnet. This
is where the IP addressing AKS clusters and pods will come. Like Vnets, Azure subnets span availability zones, as depicted in [Figure 6-19](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch06.html#SubnetsAcrossAzs).

![Subnets Across availability zones](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492081647/files/assets/neku_0619.png)

###### Figure 6-19. Subnets across availability zones

### Route tables

As mentioned in previous sections, a route table governs subnet communication or an array of directions on where to send network traffic. Each newly provisioned subnet comes equipped with a default route table populated with some default system routes. This route cannot be deleted or changed. The system routes include a route to the Vnet the subnet is defined within, routes for `10.0.0.0/8` and `192.168.0.0/16` that are by default set to go nowhere, and most importantly a default route to the
internet. The default route to the internet allows any newly provisioned resource with an Azure IP to communicate out
to the internet by default. This default route is an essential difference between Azure and some other cloud service
providers and requires adequate security measures to protect each Azure Vnet.

[Figure 6-20](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch06.html#Route_Table) shows a standard route table for a newly provisioned AKS setup. There are routes for the agent pools with
their CIDRs as well as their next-hop IP. The next-hop IP is the route the table has defined for the path, and the
next-hop type is set for a virtual appliance, which would be the load balancer in this case. What is not present are
those default system routes. The default routes are still in the configuration, just not viewable in the route table.
Understanding Azure’s default networking behavior is critical from a security perspective and from troubleshooting and
planning
perspectives.

![AKS Route Table](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492081647/files/assets/neku_0620.png)

###### Figure 6-20. Route table

Some system routes, known as optional default routes, affect only if the capabilities, such as Vnet peering, are
enabled. Vnet peering allows Vnets anywhere globally to establish a private connection across the Azure global
infrastructure backbone to communicate.

Custom routes can also populate route tables, which the Border Gateway Protocol either creates if leveraged or uses
user-defined routes. User-defined routes are essential because they allow the network administrators to define routes
beyond what Azure establishes by default, such as proxies or firewall routes. Custom routes also impact the system
default routes. While you cannot alter the default routes, a customer route with a higher priority can overrule it.
An example of this is to use a user-defined route to send traffic bound for the internet to a next-hop of a virtual
firewall appliance rather than the internet directly. [Figure 6-21](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch06.html#Route_Table_with_Custom_Route) defines a custom route called Google with a
next-hop type of internet. As long as the priorities are set up correctly, this custom route will send that traffic
out the default system route for the internet, even if another rule redirects the remaining internet traffic.

![AKS Route Table with Custom Route](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492081647/files/assets/neku_0621.png)

###### Figure 6-21. Route table with custom route

Route tables can also be created on their own and then used to configure a subnet. This is useful for maintaining a
single route table for multiple subnets, especially when there are many user-defined routes involved. A subnet can
have only one route table associated with it, but a route table can be associated with multiple subnets. The rules of
configuring a user-created route table and a route table created as part of the subnet’s default creation are the same. They have the same default system routes and will update with the same optional default routes as they come into
effect.

While most routes within a route table will use an IP range as the source address, Azure has begun to introduce the concept
of using service tags for sources. A service tag is a phrase that represents a collection of service IPs within the
Azure backend, such as SQL.EastUs, which is a service tag that describes the IP address range for the Microsoft SQL
Platform service offering in the eastern US. With this feature, it could be possible to define a route from one Azure
service, such as AzureDevOps, as the source, and another service, such as Azure AppService, as the destination
without knowing the IP ranges for either.

###### Note

The [Azure documentation](https://oreil.ly/CDedn) has a list of available service tags.

### Public and private IPs

Azure allocates IP addresses as independent resources themselves, which means that a user can create a public IP or
private IP without attaching it to anything. These IP addresses can be named and built in a resource group that
allows for future allocation. This is a crucial step when preparing for AKS cluster scaling as you want to make sure
that enough private IP addresses have been reserved for the possible pods if you decide to leverage Azure CNI for networking.
Azure CNI will be discussed in a later section.

IP address resources, both public and private, are also defined as either dynamic or static. A static IP address is reserved
to not change, while a dynamic IP address can change if it is not allocated to a resource, such as a virtual machine or AKS pod.

### Network security groups

NSGs are used to configure Vnets, subnets, and network interface cards (NICs) with inbound and outbound security rules. The rules filter traffic and determine whether the traffic will be allowed to proceed or be dropped. NSG rules are flexible to filter traffic based on source and destination IP addresses, network
ports, and network protocols. An NSG rule can use one or multiple of these filter items and can apply many NSGs.

An NSG rule can have any of the following components to define its filtering:

PriorityThis is a number between 100 and 4096. The lowest numbers are evaluated first, and the first match is the
rule that is used. Once a match is found, no further rules are evaluated.

Source/destinationSource (inbound rules) or destination (outbound rules) of the traffic inspected. The
source/destination can be any of the following:

-

Individual IP address

-

CIDR block (i.e., 10.2.0.0/24)

-

Microsoft Azure service tag

-

Application security groups

ProtocolTCP, UDP, ICMP, ESP, AH, or Any.

DirectionThe rule for inbound or outbound traffic.

Port rangeSingle ports or ranges can be specified here.

ActionAllow or deny the traffic.

[Figure 6-22](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch06.html#Azure_NSG) shows an example of an NSG.

![Azure NSG](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492081647/files/assets/neku_0622.png)

###### Figure 6-22. Azure NSG

There are some considerations to keep in mind when configuring Azure network security groups. First, two or more
rules cannot exist with the same priority and direction. The priority or direction can match as long as the other
does not. Second, port ranges can be used only in the Resource Manager deployment model, not the classic deployment
model. This limitation also applies to IP address ranges and service tags for the source/destination. Third, when
specifying the IP address for an Azure resource as the source/destination, if the resource has both a public and
private IP address, use the private IP address. Azure performs the translation from public to private IP addressing
outside this process, and the private IP address will be the right choice at the time of processing.

### Communication outside the virtual network

The concepts described so far have mainly pertained to Azure networking within a single Vnet. This type of
communication is vital in Azure networking but far from the only type. Most Azure implementations will require
communication outside the virtual network to other networks, including, but not limited to, on-premise networks,
other Azure virtual networks, and the internet. These communication paths require many of the same considerations as
the internal networking processes and use many of the same resources, with a few differences. This section will expand
on some of those differences.

Vnet peering can connect Vnets in different regions using global virtual network peering, but there are constraints
with certain services such as load balancers.

###### Note

For a list of these constraints, see the Azure [documentation](https://oreil.ly/wnaEi).

Communication outside of Azure to the internet uses a different set of resources. Public IPs, as discussed earlier,
can be created and assigned to a resource in Azure. The resource uses its private IP address for all networking
internal to Azure. When the traffic from the resource needs to exit the internal networks to the internet, Azure
translates the private IP address into the resource’s assigned public IP. At this point, the traffic can leave to the
internet. Incoming traffic bound for the public IP address of an Azure resource translates to the resource’s assigned
private IP address at the Vnet boundary, and the private IP is used from then on for the rest of the traffic’s trip
to its destination. This traffic path is why all subnet rules for things like NSGs are defined using private IP addresses.

NAT can also be configured on a subnet. If configured, resources on a subnet with NAT
enabled do not need a public IP address to communicate with the internet. NAT is enabled on a subnet to allow
outbound-only internet traffic with a public IP from a pool of provisioned public IP addresses. NAT will enable
resources to route traffic to the internet for requests such as updates or installs and return with the requested
traffic but prevents the resources from being accessible on the internet. It is important to note that, when
configured, NAT takes priority over all other outbound rules and replaces the default internet destination for the
subnet. NAT also uses port address translation (PAT) by default.

### Azure load balancer

Now that you have a method of communicating outside the network and communication to flow back into the Vnet, a
way to keep those lines of communication available is needed. Azure load balancers are often used to accomplish this
by distributing traffic across backend pools of resources rather than a single resource to handle the request. There
are two primary load balancer types in Azure: the standard load balancer and the application gateway.

Azure standard load balancers are layer 4 systems that distribute incoming traffic based on layer 4 protocols
such as TCP and UDP, meaning traffic is routed based on IP address and port. These load balancers filter incoming
traffic from the internet, but they can also load balance traffic from one Azure resource to a set of other Azure
resources. The standard load balancer uses a zero-trust network model. This model requires an NSG to “open” traffic
to be inspected by the load balancer. If the attached NSG does not permit the traffic, the load balancer will not
attempt to route it.

Azure application gateways are similar to standard load balancers in that they distribute incoming traffic but
differently in that they do so at layer 7. This allows for the inspection of incoming HTTP requests to filter based on
URI or host headers. Application gateways can also be used as web application firewalls to further secure and filter
traffic. Additionally, the application gateway can also be used as the ingress controller for AKS clusters.

Load balancers, whether standard or application gateways, have some basic concepts that sound be considered:

Frontend IP addressEither public or private depending on the use, this is the IP address used to target the load
balancer and, by extension, the backend resources it is balancing.

SKULike other Azure resources, this defines the “type” of the load balancer and, therefore, the different
configuration options available.

Backend poolThis is the collection of resources that the load balancer is distributing traffic to, such as a
collection
of virtual machines or the pods within an AKS cluster.

Health probesThese are methods used by the load balancer to ensure the backend resource is available for traffic,
such as a health endpoint that returns an OK status:

ListenerA configuration that tells the load balancer what type of traffic to expect, such as HTTP requests.

RulesDetermines how to route the incoming traffic for that listener.

[Figure 6-23](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch06.html#Azure_Load_Balancer_Components) illustrates some of these primary components within the Azure load balancer architecture. Traffic comes
into the load balancer and is compared to the listeners to determine if the load balancer balances the traffic. Then
the traffic is evaluated against the rules and finally sent on to the backend pool. Backend pool
resources with appropriately responding health probes will process the traffic.

![Azure Load Balancer Components](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492081647/files/assets/neku_0623.png)

###### Figure 6-23. Azure load balancer components

[Figure 6-24](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch06.html#AKS_Load_Balancing) shows how AKS would use the load balancer.

Now that we have a basic knowledge of the Azure network, we can discuss how Azure uses these constructs in its
managed Kubernetes offering, Azure Kubernetes Service.

![AKS Load Balancing](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492081647/files/assets/neku_0624.png)

###### Figure 6-24. AKS load balancing

## Azure Kubernetes Service

Like other cloud providers, Microsoft understood the need to leverage the power of Kubernetes and therefore
introduced the Azure Kubernetes Service as the Azure Kubernetes offering. AKS is a hosted service offering from Azure and therefore handles a large portion of the overhead of
managing Kubernetes. Azure handles components such as health monitoring and maintenance, leaving more time for
development and operations engineers to leverage the scalability and power of Kubernetes for their solutions.

AKS can have clusters created and managed using the Azure CLI, Azure PowerShell, the Azure Portal, and other
template-based deployment options such as ARM templates and HashiCorp’s Terraform. With AKS, Azure manages the
Kubernetes masters so that the user only needs to handle the node agents. This allows Azure to offer the core of AKS
as a free service where the only payment required is for the agent nodes and peripheral services such as storage and
networking.

The Azure Portal allows for easy management and configuration of the AKS environment. [Figure 6-25](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch06.html#Azure_Portal_AKS_Overview) shows the overview
page of a newly provisioned AKS environment. On this page, you can see information and links to many of the crucial
integrations and properties. The cluster’s resource group, DNS address, Kubernetes version, networking type, and a
link to the node pools are visible in the Essentials section.

[Figure 6-26](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch06.html#Azure_Portal_AKS_Properties) zooms in on the Properties section of the overview page, where users can find additional information and links to corresponding components. Most of the data is the same as the information in the Essentials section.
However, the various subnet CIDRs for the AKS environment components can be viewed here for things such as the Docker
bridge and the pod subnet.

![Azure Portal AKS Overview](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492081647/files/assets/neku_0625.png)

###### Figure 6-25. Azure Portal AKS overview

![Azure Portal AKS Properties](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492081647/files/assets/neku_0626.png)

###### Figure 6-26. Azure Portal AKS properties

Kubernetes pods created within AKS are attached to virtual networks and can access network resources through
abstraction. The kube-proxy on each AKS node creates this abstraction, and this component allows for inbound and
outbound traffic. Additionally, AKS seeks to make Kubernetes management even more streamlined by simplifying how to
roll changes to virtual network changes. Network services in AKS are autoconfigured when specific changes occur. For
example, opening a network port to a pod will also trigger relevant changes to the attached NSGs to open those ports.

By default, AKS will create an Azure DNS record that has a public IP. However, the default network rules prevent
public access. The private mode can create the cluster to use no public IPs and block public access for only
internal use of the cluster. This mode will cause the cluster access to be available only from within the Vnet. By
default, the standard SKU will create an AKS load balancer. This configuration can be changed during deployment if
deploying via the CLI. Resources not included in the cluster are made in a separate, auto-generated resource group.

When leveraging the kubenet networking model for AKS, the following rules are true:

-

Nodes receive an IP address from the Azure virtual network subnet.

-

Pods receive an IP address from a logically different address space than the nodes.

-

The source IP address of the traffic switches to the node’s primary address.

-

NAT is configured for the pods to reach Azure resources on the Vnet.

It is important to note that only the nodes receive a routable IP; the pods do not.

While kubenet is an easy way to administer Kubernetes networking within the Azure Kubernetes Service, it is not
the only way. Like other cloud providers, Azure also allows for the use the CNI when managing Kubernetes infrastructure.
Let’s discuss CNI in the next section.

### Azure CNI

Microsoft has provided its own CNI plugin for Azure and AKS, Azure CNI. The first
significant difference between this and kubenet is that the pods receive routable IP information and can be accessed
directly. This difference places additional importance on the need for IP address space planning. Each node has a
maximum number of pods it can use, and many IP addresses are reserved for that use.

###### Note

More information can be found on the Azure
Container Networking [GitHub](https://oreil.ly/G2zyC).

With Azure CNI, traffic inside the Vnet is no longer NAT’d to the node’s IP address but to the pod’s IP itself, as
illustrated in [Figure 6-27](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch06.html#Azure_CNI). Outside traffic, such as to the internet, is still NAT’d to the node’s IP address. Azure
CNI still performs the backend IP address management and routing for these items, though, as all resources on the
same Azure Vnet can communicate with each other by default.

The Azure CNI can also be used for Kubernetes deployments outside AKS. While there is additional work to be done on
the cluster that Azure would typically handle, this allows you to leverage Azure networking and other resources while
maintaining more control over the customarily managed aspects of Kubernetes under AKS.

![Azure CNI](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492081647/files/assets/neku_0627.png)

###### Figure 6-27. Azure CNI

Azure CNI also provides the added benefit of allowing for the separation of duties while maintaining the AKS
infrastructure. The Azure CNI creates the networking resources in a separate resource group. Being in a different
resource group allows for more control over permissions at the resource group level within the Azure Resource
Management deployment model. Different teams can access some components of AKS, such as the networking, without
needing access to others, such as the application deployments.

Azure CNI is not the only way to leverage additional Azure services to enhance your Kubernetes network infrastructure.
The next section will discuss the use of an Azure application gateway as a means of controlling ingress into your
Kubernetes cluster.

### Application gateway ingress controller

Azure allows for the deployment of an application gateway inside the AKS cluster deployment to serve as the application gateway ingress controller (AGIC). This deployment model eliminates the need for maintaining a secondary
load balancer outside the AKS infrastructure, thereby reducing maintenance overhead and error points. AGIC deploys
its pods in the cluster. It then monitors other aspects of the cluster for configuration changes. When a change is
detected, AGIC updates the Azure Resource Manager template that configures the load balancer and
then applies the updated configuration. [Figure 6-28](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch06.html#Azure_AGIC) illustrates this.

![Azure Application Gateway Ingress Controller](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492081647/files/assets/neku_0628.png)

###### Figure 6-28. Azure AGIC

There are AKS SKU limitations for the use of the AGIC, only supporting Standard_v2 and WAF_v2, but those SKUs also
have autoscaling capabilities. Use cases for using such a form of ingress, such as the need for high scalability,
have the potential for the AKS environment to scale. Microsoft supports the use of both Helm and the AKS add-on as
deployment options for the AGIC. These are the critical differences between the two options:

-

Helm deployment values cannot be edited when using the AKS add-on.

-

Helm supports Prohibited Target configuration. An AGIC can configure the application gateway to target only the AKS
instances without impacting other backend components.

-

The AKS add-on, as a managed service, will be automatically updated to its current and more secure versions. Helm
deployments will need manual updating.

Even though AGIC is configured as the Kubernetes ingress resource, it still carries the full benefit of the cluster’s
standard layer 7 application gateway. Application gateway services such as TLS termination, URL routing, and the
web application firewall capability are all configurable for the cluster as part of the AGIC.

While many Kubernetes and networking fundamentals are universal across cloud providers, Azure offers its own spin on Kubernetes
networking through its enterprise-focused resource design and management. Whether you have a need for a single cluster using basic
settings and kubenet or a large-scale deployment with advanced networking through the use of deployed load balancers and application
gateways, Microsoft’s Azure Kubernetes Service can be leveraged to deliver a reliable, managed Kubernetes infrastructure.

## Deploying an Application to Azure Kubernetes Service

Standing up an Azure Kubernetes Service cluster is one of the basic skills needed to begin exploring AKS networking.
This section will go through the steps of standing up a sample cluster and deploying the Golang web server example
from [Chapter 1](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch01.html#networking_introduction) to that cluster. We will be using a combination of the Azure Portal, the Azure CLI, and `kubectl` to
perform these actions.

Before we begin with the cluster deployment and configuration, we should discuss the Azure Container Registry (ACR).
The ACR is where you store container images in Azure. For this example, we will use the ACR as the location
for the container image we will be deploying. To import an image to the ACR, you will need to have the image locally
available on your computer. Once you have the image available, we have to prep it for the ACR.

First, identify the ACR repository you want to store the image in and log in from the Docker CLI with `docker login
<acr_repository>.azurecr.io`. For this example, we will use the ACR repository `tjbakstestcr`, so the command would
be `docker login tjbakstestcr.azurecr.io`. Next, tag the local image you wish to import to the ACR with
`<acr_repository>.azurecr.io\<imagetag>`. For this example, we will use an image currently tagged `aksdemo`. Therefore,
the tag would be `tjbakstestcr.azure.io/aksdemo`. To tag the image, use the command `docker tag <local_image_tag>
<acr_image_tag>`. This example would use the command `docker tag aksdemo tjbakstestcr.azure.io/aksdem`. Finally,
we push the image to the ACR with `docker push tjbakstestcr.azure.io/aksdem`.

###### Note

You can find additional information on Docker and the Azure Container Registry in the official [documentation](https://oreil.ly/5swhT).

Once the image is in the ACR, the final prerequisite is to set up a service principal. This is easier to set up before
you begin, but you can do this during the AKS cluster creation. An Azure service principal is a representation of an
Azure Active Directory Application object. Service principals are generally used to interact with Azure through
application automation. We will be using a service principal to allow the AKS cluster to pull the `aksdemo` image from
the ACR. The service principal needs to have access to the ACR repository that you store the image in. You will need to
record the client ID and secret of the service principal you want to use.

###### Note

You can find additional information on Azure Active Directory service principals in the [documentation](https://oreil.ly/pnZTw).

Now that we have our image in the ACR and our service principal client ID and secret, we can begin deploying the AKS cluster.

### Deploying an Azure Kubernetes Service cluster

The time has come to deploy our cluster. We are going to start in the Azure Portal. Go to [portal.azure.com](https://oreil.ly/Wx4Ny) to log in.
Once logged in, you should see a dashboard with a search bar at the top that will be used to locate services. From the
search bar, we will be typing **kubernetes** and selecting the Kubernetes Service option from the drop-down menu, which is
outlined in [Figure 6-29](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch06.html#Azure_Kubernetes_Search).

![Azure Kubernetes Search](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492081647/files/assets/neku_0629.png)

###### Figure 6-29. Azure Kubernetes search

Now we are on the Azure Kubernetes Services blade. Deployed AKS clusters are viewed from this screen using
filters and queries. This is also the screen for creating new AKS clusters. Near the top of the screen, we are going
to select Create as shown in [Figure 6-30](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch06.html#Azure_Kubernetes_Create). This will cause a drop-down menu to appear, where we will select “Create a
Kubernetes cluster.”

![Azure Kubernetes Create](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492081647/files/assets/neku_0630.png)

###### Figure 6-30. Creating an Azure Kubernetes cluster

Next we will define the properties of the AKS cluster from the “Create Kubernetes cluster” screen. First, we will
populate the Project Details section by selecting the subscription that the cluster will be deployed to. There is a
drop-down menu that allows for easier searching and selection. For this example, we are using the `tjb_azure_test_2` subscription,
but any subscription can work as long as you have access to it. Next, we have to define the resource group we will use
to group the AKS cluster. This can be an existing resource group or a new one can be created. For this example, we will
create a new resource group named `go-web`.

After the Project Details section is complete, we move on to the Cluster Details section. Here, we will define the
name of the cluster, which will be “go-web” for this example. The region, availability zones, and Kubernetes version
fields are also defined in this section and will have predefined defaults that can be changed. For this example, however,
we will use the default “(US) West 2” region with no availability zones and the default Kubernetes version of 1.19.11.

###### Note

Not all Azure regions have availability zones that can be selected. If availability zones are part of the AKS architecture
that is being deployed, the appropriate regions should be considered. You can find more information on AKS regions in the availability zones [documentation](https://oreil.ly/enxii).

Finally, we will complete the Primary Node Pool section of the “Create Kubernetes cluster” screen by selecting the
node size and node count. For this example, we are going to keep the default node size of DS2 v2 and the default node
count of 3. While most virtual machines, sizes are available for use within AKS, there are some restrictions. [Figure 6-31](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch06.html#Azure_Kubernetes_Create_Page)
shows the options we have selected filled in.

###### Note

You can find more information on AKS restrictions, including restricted node sizes, in the [documentation](https://oreil.ly/A4bHq).

Click the “Next: Node pools” button to move to the Node Pools tab. This page allows for the configuration of additional
node pools for the AKS cluster. For this example, we are going to leave the defaults on this page and move on to the
Authentication page by clicking the “Next: Authentication” button at the bottom of the screen.

![Azure Kubernetes Create Page](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492081647/files/assets/neku_0631.png)

###### Figure 6-31. Azure Kubernetes create page

[Figure 6-32](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch06.html#Azure_Kubernetes_Authentication_Page) shows the Authentication page, where we will define the authentication method that the AKS cluster will use
to connect to attached Azure services such as the ACR we discussed previously in this chapter. “System-Assigned Managed Identity”
is the default authentication method, but we are going to select the “Service principal” radio button.

If you did not create a service principal at the beginning of this section, you can create a new one here. If you create a
service principal at this stage, you will have to go back and grant that service principal permissions to access the ACR.
However, since we will use a previously created service principal, we are going to click the “Configure service principal”
link and enter the client ID and secret.

![Azure Kubernetes Authentication Page](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492081647/files/assets/neku_0632.png)

###### Figure 6-32. Azure Kubernetes Authentication page

The remaining configurations will remain at the defaults at this time. To complete the AKS cluster creation, we are going to click
the “Review + create” button. This will take us to the validation page. As shown in [Figure 6-33](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch06.html#Azure_Kubernetes_Validation_Page), if everything is
defined appropriately, the validation will return a “Validation Passed” message at the top of the screen. If
something is misconfigured, a “Validation Failed” message will be there instead. As long as validation passes, we
will review the settings and click Create.

![Azure Kubernetes Validation Page](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492081647/files/assets/neku_0633.png)

###### Figure 6-33. Azure Kubernetes validation page

You can view the deployment status from the notification bell on the top of the Azure screen. [Figure 6-34](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch06.html#Azure_Kubernetes_Deployment_Progress) shows our example
deployment in progress. This page has information that can be used to troubleshoot with Microsoft should an issue arise
such as the deployment name, start time, and correlation ID.

Our example deployed completely without issue, as shown in [Figure 6-35](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch06.html#Azure_Kubernetes_Deployment_Complete). Now that the AKS cluster is deployed, we need
to connect to it and configure it for use with our example web server.

![Azure Kubernetes Deployment Progress](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492081647/files/assets/neku_0634.png)

###### Figure 6-34. Azure Kubernetes deployment progress

![Azure Kubernetes Deployment Complete](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492081647/files/assets/neku_0635.png)

###### Figure 6-35. Azure Kubernetes deployment complete

### Connecting to and configuring AKS

We will now shift to working with the example `go-web` AKS cluster from the
command line. To manage AKS clusters from
the command line, we will primarily use the `kubectl` command. Azure CLI has a simple command, `az aks install-cli`, to
install the `kubectl` program for use. Before we can use `kubectl`, though, we need to gain access to the cluster. The command
`az aks get-credentials`
`--resource-group` `<resource_group_name> --name <aks_cluster_name>` is used to gain access to the
AKS cluster. For our example, we will use `az aks get-credentials --resource-group go-web --name go-web` to access our
`go-web` cluster in the `go-web` resource group.

Next we will attach the Azure container registry that has our `aksdemo` image.
The command `az aks update -n` `<aks_cluster_name>
-g` `<clus⁠⁠ter_resource_​​group_name>` `--attach-acr <acr_repo_name>` will attach a named ACR repo to an existing AKS cluster.
For our example, we will use the command `az aks update -n tjbakstest -g tjbakstest --attach-acr tjbakstestcr`. Our example
runs for a few moments and then produces the output shown in [Example 6-1](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch06.html#EX6).

##### Example 6-1. AttachACR output

```json
{- Finished ..
  "aadProfile": null,
  "addonProfiles": {
    "azurepolicy": {
      "config": null,
      "enabled": false,
      "identity": null
    },
    "httpApplicationRouting": {
      "config": null,
      "enabled": false,
      "identity": null
    },
    "omsAgent": {
      "config": {
        "logAnalyticsWorkspaceResourceID":
        "/subscriptions/7a0e265a-c0e4-4081-8d76-aafbca9db45e/
        resourcegroups/defaultresourcegroup-wus2/providers/
        microsoft.operationalinsights/
        workspaces/defaultworkspace-7a0e265a-c0e4-4081-8d76-aafbca9db45e-wus2"
      },
      "enabled": true,
      "identity": null
    }
  },
  "agentPoolProfiles": [
    {
      "availabilityZones": null,
      "count": 3,
      "enableAutoScaling": false,
      "enableNodePublicIp": null,
      "maxCount": null,
      "maxPods": 110,
      "minCount": null,
      "mode": "System",
      "name": "agentpool",
      "nodeImageVersion": "AKSUbuntu-1804gen2containerd-2021.06.02",
      "nodeLabels": {},
      "nodeTaints": null,
      "orchestratorVersion": "1.19.11",
      "osDiskSizeGb": 128,
      "osDiskType": "Managed",
      "osType": "Linux",
      "powerState": {
        "code": "Running"
      },
      "provisioningState": "Succeeded",
      "proximityPlacementGroupId": null,
      "scaleSetEvictionPolicy": null,
      "scaleSetPriority": null,
      "spotMaxPrice": null,
      "tags": null,
      "type": "VirtualMachineScaleSets",
      "upgradeSettings": null,
      "vmSize": "Standard_DS2_v2",
      "vnetSubnetId": null
    }
  ],
  "apiServerAccessProfile": {
    "authorizedIpRanges": null,
    "enablePrivateCluster": false
  },
  "autoScalerProfile": null,
  "diskEncryptionSetId": null,
  "dnsPrefix": "go-web-dns",
  "enablePodSecurityPolicy": null,
  "enableRbac": true,
  "fqdn": "go-web-dns-a59354e4.hcp.westus.azmk8s.io",
  "id":
  "/subscriptions/7a0e265a-c0e4-4081-8d76-aafbca9db45e/
  resourcegroups/go-web/providers/Microsoft.ContainerService/managedClusters/go-web",
  "identity": null,
  "identityProfile": null,
  "kubernetesVersion": "1.19.11",
  "linuxProfile": null,
  "location": "westus",
  "maxAgentPools": 100,
  "name": "go-web",
  "networkProfile": {
    "dnsServiceIp": "10.0.0.10",
    "dockerBridgeCidr": "172.17.0.1/16",
    "loadBalancerProfile": {
      "allocatedOutboundPorts": null,
      "effectiveOutboundIps": [
        {
          "id":
          "/subscriptions/7a0e265a-c0e4-4081-8d76-aafbca9db45e/
          resourceGroups/MC_go-web_go-web_westus/providers/Microsoft.Network/
          publicIPAddresses/eb67f61d-7370-4a38-a237-a95e9393b294",
          "resourceGroup": "MC_go-web_go-web_westus"
        }
      ],
      "idleTimeoutInMinutes": null,
      "managedOutboundIps": {
        "count": 1
      },
      "outboundIpPrefixes": null,
      "outboundIps": null
    },
    "loadBalancerSku": "Standard",
    "networkMode": null,
    "networkPlugin": "kubenet",
    "networkPolicy": null,
    "outboundType": "loadBalancer",
    "podCidr": "10.244.0.0/16",
    "serviceCidr": "10.0.0.0/16"
  },
  "nodeResourceGroup": "MC_go-web_go-web_westus",
  "powerState": {
    "code": "Running"
  },
  "privateFqdn": null,
  "provisioningState": "Succeeded",
  "resourceGroup": "go-web",
  "servicePrincipalProfile": {
    "clientId": "bbd3ac10-5c0c-4084-a1b8-39dd1097ec1c",
    "secret": null
  },
  "sku": {
    "name": "Basic",
    "tier": "Free"
  },
  "tags": {
    "createdby": "tjb"
  },
  "type": "Microsoft.ContainerService/ManagedClusters",
  "windowsProfile": null
}
```

This output is the CLI representation of the AKS cluster information. This means that the attachment was successful.
Now that we have access to the AKS cluster and the ACR is attached, we can deploy the example Go web server to the
AKS cluster.

### Deploying the Go web server

We are going to deploy the Golang code shown in [Example 6-2](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch06.html#kubernetes_podspec_for_golang_minimal_webserver). As mentioned earlier in this
chapter, this code has been built into a Docker image and now is stored in the ACR in the `tjbakstestcr` repository. We will be using the following deployment YAML file to deploy the application.

##### Example 6-2. Kubernetes Podspec for Golang minimal webserver

```yaml
apiVersion: v1
kind: Pod
metadata:
  labels:
    test: liveness
  name: go-web
spec:
  containers:
  - name: go-web
    image: go-web:v0.0.1
    ports:
    - containerPort: 8080
    livenessProbe:
      httpGet:
        path: /healthz
        port: 8080
      initialDelaySeconds: 5
      periodSeconds: 5
    readinessProbe:
      httpGet:
        path: /
        port: 8080
      initialDelaySeconds: 5
      periodSeconds: 5
```

Breaking down this YAML file, we see that we are creating two AKS resources: a deployment and a service. The deployment is
configured for the creation of a container named `go-web` and a container port 8080. The deployment also references the

`aksdemo` ACR image with the line `image: tjbakstestcr.azurecr.io/aksdemo` as the image that will be deployed to the container.
The service is also configured with the name go-web. The YAML specifies the service is a load balancer listening on port
8080 and targeting the `go-web` app.

Now we need to publish the application to the AKS cluster. The command `kubectl apply -f <yaml_file_name>.yaml` will
publish the application to the cluster. We will see from the output that two things are created: `deployment.apps/go-web`
and
`service/go-web`. When we run the command `kubectl get pods`, we can see an output like that shown here:

```bash
○ → kubectl get pods
NAME                      READY   STATUS    RESTARTS   AGE
go-web-574dd4c94d-2z5lp   1/1     Running   0          5h29m
```

Now that the application is deployed, we will connect to it to verify it is up and running. When a default AKS cluster
is stood up, a load balancer is deployed with it with a public IP address. We could go through the portal and locate
that load balancer and public IP address, but `kubectl` offers an easier path. The command `kubectl get` [.keep-together]#`service` `go-web`
produces this output:

```bash
○ → kubectl get service go-web
NAME     TYPE           CLUSTER-IP   EXTERNAL-IP    PORT(S)          AGE
go-web   LoadBalancer   10.0.3.75    13.88.96.117   8080:31728/TCP   21h
```

In this output, we see the external IP address of 13.88.96.117. Therefore, if everything deployed correctly, we should
be able to cURL 13.88.96.117 at port 8080 with the command `curl 13.88.96.117:8080`. As we can see from this output,
we have a successful deployment:

```
○ → curl 13.88.96.117:8080 -vvv
*   Trying 13.88.96.117...
* TCP_NODELAY set
* Connected to 13.88.96.117 (13.88.96.117) port 8080 (#0)
> GET / HTTP/1.1
> Host: 13.88.96.117:8080
> User-Agent: curl/7.64.1
> Accept: */*
>
< HTTP/1.1 200 OK
< Date: Fri, 25 Jun 2021 20:12:48 GMT
< Content-Length: 5
< Content-Type: text/plain; charset=utf-8
<
* Connection #0 to host 13.88.96.117 left intact
Hello* Closing connection 0
```

Going to a web browser and navigating to http://13.88.96.117:8080 will also be available, as shown in [Figure 6-36](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch06.html#Azure_Kubernetes_Hello_App).

![Azure Kubernetes Hello App](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492081647/files/assets/neku_0636.png)

###### Figure 6-36. Azure Kubernetes Hello app

### AKS conclusion

In this section, we deployed an example Golang web server to an Azure Kubernetes Service cluster. We used the Azure Portal,
the `az cli`, and `kubectl` to deploy and configure the cluster and then deploy the application. We leveraged the Azure container
registry to host our web server image. We also used a YAML file to deploy the application and tested it with cURL and web browsing.

# Conclusion

Each cloud provider has its nuanced differences when it comes to network services provided for Kubernetes clusters.
[Table 6-4](https://learning.oreilly.com/library/view/networking-and-kubernetes/9781492081647/ch06.html#cloud_network_and_kubernetes_summary) highlights some of those differences.  There are lots of factors to choose from when picking a cloud
service provider, and even more when selecting the managed Kubernetes platform to run. Our aim in this chapter was to
educate administrators and developers on the choices you will have to make when managing workloads on Kubernetes.

|   | AWS | Azure | GCP |
| --- | --- | --- | --- |
| Virtual network | VPC | Vnet | VPC |
| Network scope | Region | Region | Global |
| Subnet boundary | Zone | Region | Region |
| Routing scope | Subnet | Subnet | VPC |
| Security controls | NACL/SecGroups | Network security groups/Application SecGroup | Firewall |
| IPv6 | Yes | Yes | No |
| Kubernetes managed | eks | aks | gke |
| ingress | AWS ALB controller | Nginx-Ingress | GKE ingress controller |
| Cloud custom CNI | AWS VPC CNI | Azure CNI | GKE CNI |
| Load Balancer support | ALB L7, L4 w/NLB, and Nginx | L4 Azure Load Balancer, L7 w/Nginx | L7, HTTP(S) |
| Network policies | Yes (Calico/Cilium) | Yes (Calico/Cilium) | Yes (Calico/Cilium) |

We have covered many layers, from the OSI foundation to running networks in the cloud for our clusters. Cluster
administrators, network engineers, and developers alike have many decisions to make, such as the subnet size, the CNI to choose,
and the load balancer type, to name a few. Understanding all of those and how they will affect the cluster network
was the basis for this book. This is just the beginning of your journey for managing your clusters at scale. We have
managed to cover only the networking options available for managing Kubernetes clusters. Storage, compute, and even
how to deploy workloads onto those clusters are decisions you will have to make now. The O’Reilly library has an extensive
number of books to help, such as [Production Kubernetes](https://oreil.ly/Xx12u) (Rosso et al.), where you learn what the path to production looks like when using
Kubernetes, and [Hacking Kubernetes](https://oreil.ly/FcU8C) (Martin and Hausenblas), on how to harden Kubernetes and how to review Kubernetes clusters for
security weaknesses.

We hope this guide has helped make those networking choices easy for you. We were inspired to see what the Kubernetes
community has done and are excited to see what you build on top of the abstractions Kubernetes provides for you.

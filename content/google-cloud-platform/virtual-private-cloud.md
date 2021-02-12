---
title: Virtual Private Cloud (VPC)
---

I don't know a lot about networks, but is seems that some GCP components (notably Kubernetes, Dataproc, and Dataflow) require a VPC (Virtual Private Cloud) to be setup for them to work.  You can create a VPC Network in Google easy enough.  There is an automated configuration that will setup IP address ranges in each of the GCP regions so that you can deploy components into any of them.  Every machine within the VPC will be able to talk to each other.  However, your VPC will be isolated from external traffic.  Specifically, no computer in the VPC will be able to talk to the internet unless it is given an external IP address.  An alternate way to enable this is with a Cloud NAT service (Google docs here).  This allows computers to initiate connections outside of the VPC, but no one outside the VPC will be able to initiate a connection into the VPC.

## GCP Links

* [Best Practices for Enterprise Organizations](https://cloud.google.com/docs/enterprise/best-practices-for-enterprise-organizations)
* [Virtual Private Cloud (VPC) Network Overview](https://cloud.google.com/vpc/docs/vpc)
* [Cloud NAT](https://cloud.google.com/nat/docs/overview)
* [VPC Private Access Options](https://cloud.google.com/vpc/docs/private-access-options)

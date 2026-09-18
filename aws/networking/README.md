# AWS Networking Module

This module creates the reusable EKS-ready VPC foundation used by the DevEx platform. It manages a DNS-enabled VPC, public and private subnets across multiple availability zones, internet access for public subnets, NAT egress for private subnets, explicit route tables and associations, and Kubernetes load-balancer subnet discovery tags.

## NAT modes

- `single` creates one Elastic IP and NAT Gateway in the first public subnet. Every private subnet routes through it. This reduces cost but does not provide zonal NAT resilience.
- `one_per_az` creates one Elastic IP and NAT Gateway per availability zone. Each private subnet uses its same-zone gateway.

## Kubernetes subnet tags

Public subnets receive `kubernetes.io/role/elb = "1"`. Private subnets receive `kubernetes.io/role/internal-elb = "1"`. Cluster-specific legacy tags are intentionally not used, so the network remains reusable.

The module does not create EKS, security groups, EC2 instances, VPC endpoints, peering, transit gateways, Kubernetes resources, or Argo CD.

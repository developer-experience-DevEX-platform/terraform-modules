# Networking

Module: `aws/networking`

EKS-ready VPC foundation. DNS-enabled VPC, public and private subnets
across at least two AZs, internet access for public subnets, NAT egress
for private subnets, route tables, and Kubernetes load-balancer
discovery tags.

The module does not create EKS, security groups, EC2, VPC endpoints,
peering, transit gateways, Kubernetes resources, or Argo CD.

## NAT modes

| Mode | What it creates |
| --- | --- |
| `single` | One EIP and NAT Gateway in the first public subnet. Every private subnet routes through it. Cheaper. No zonal NAT resilience. |
| `one_per_az` | One EIP and NAT Gateway per AZ. Each private subnet uses its same-zone gateway. |

## Kubernetes subnet tags

- Public: `kubernetes.io/role/elb = "1"`
- Private: `kubernetes.io/role/internal-elb = "1"`

Cluster-specific legacy tags are not used, so the network stays
reusable across clusters.

## Caller

```hcl
module "networking" {
  source = "git::https://github.com/developer-experience-DevEX-platform/terraform-modules.git//aws/networking?ref=v0.3.0"

  name     = "devex-staging"
  vpc_cidr = "10.10.0.0/16"

  availability_zones = [
    "eu-west-2a",
    "eu-west-2b",
  ]

  public_subnet_cidrs = [
    "10.10.0.0/24",
    "10.10.1.0/24",
  ]

  private_subnet_cidrs = [
    "10.10.16.0/20",
    "10.10.32.0/20",
  ]

  nat_gateway_mode = "single"

  tags = {
    Environment = "staging"
  }
}
```

Pass `vpc_id` and `private_subnet_ids` into [EKS](eks.md).

## Inputs

| Input | Required | Notes |
| --- | --- | --- |
| `name` | yes | Prefix on networking resources. |
| `vpc_cidr` | yes | VPC IPv4 CIDR. |
| `availability_zones` | yes | At least two unique AZs. |
| `public_subnet_cidrs` | yes | One CIDR per AZ, same order. |
| `private_subnet_cidrs` | yes | One CIDR per AZ, same order. |
| `nat_gateway_mode` | yes | `single` or `one_per_az`. |
| `tags` | no | |

## Outputs

| Output | Notes |
| --- | --- |
| `vpc_id` | |
| `vpc_cidr` | |
| `public_subnet_ids` | AZ order. |
| `private_subnet_ids` | AZ order. Pass these to EKS. |
| `nat_gateway_ids` | Depends on NAT mode. |
| `availability_zones` | Echo of the input. |

## Related

- [EKS](eks.md)
- [Overview](../overview.md)

# EKS

Module: `aws/eks`

Amazon EKS cluster, separate cluster and node IAM roles, one managed
system node group, and the `vpc-cni`, `coredns`, and `kube-proxy`
add-ons.

It accepts VPC and private subnet IDs from the calling stack. It does
not create networking or custom security groups. Pair it with
[networking](networking.md).

The cluster uses EKS API access entries rather than the legacy
`aws-auth` ConfigMap. Control plane and managed nodes use only the
supplied private subnets.

## Node-role bootstrap policy

The node role temporarily receives `AmazonEKS_CNI_Policy` so the VPC
CNI has AWS permissions during initial bootstrap. AWS recommends
moving those permissions to IRSA or EKS Pod Identity later. The node
role also receives `AmazonEKSWorkerNodePolicy` and
`AmazonEC2ContainerRegistryPullOnly`.

The module does not create Fargate profiles, Auto Mode, Pod Identity,
IRSA, workloads, Argo CD, ingress, load balancers, Route 53, or
customer-managed KMS keys.

## Caller

```hcl
module "eks" {
  source = "git::https://github.com/developer-experience-DevEX-platform/terraform-modules.git//aws/eks?ref=v0.3.0"

  cluster_name       = "devex-staging"
  kubernetes_version = "1.36"
  vpc_id             = module.networking.vpc_id
  private_subnet_ids = module.networking.private_subnet_ids

  node_instance_types = ["t3.medium"]
  node_min_size       = 2
  node_desired_size   = 2
  node_max_size       = 4
}
```

Public API access defaults to off. Private access defaults to on.

## Inputs

| Input | Default | Notes |
| --- | --- | --- |
| `cluster_name` | — | Required. Also prefixes related resources. |
| `kubernetes_version` | — | Required. `major.minor`, for example `1.36`. |
| `vpc_id` | — | Required. |
| `private_subnet_ids` | — | Required. At least two unique subnet IDs. |
| `endpoint_private_access` | `true` | |
| `endpoint_public_access` | `false` | |
| `public_access_cidrs` | `[]` | Used when public access is on. |
| `node_instance_types` | — | Required. At least one. |
| `node_capacity_type` | `ON_DEMAND` | `ON_DEMAND`, `SPOT`, or `CAPACITY_BLOCK`. |
| `node_min_size` | — | Required. |
| `node_desired_size` | — | Required. |
| `node_max_size` | — | Required. At least 1. |
| `node_disk_size` | `30` | GiB; minimum 20. |
| `enabled_cluster_log_types` | api, audit, authenticator, controllerManager, scheduler | |
| `tags` | `{}` | |

## Outputs

| Output | Notes |
| --- | --- |
| `cluster_name` | |
| `cluster_arn` | |
| `cluster_endpoint` | |
| `cluster_version` | |
| `cluster_certificate_authority_data` | |
| `cluster_security_group_id` | EKS-managed cluster SG. |
| `cluster_role_arn` | |
| `node_role_arn` | |
| `node_group_name` | |
| `node_group_arn` | |
| `private_subnet_ids` | Echo of the input. |

## Related

- [Networking](networking.md)
- [Kubernetes GitOps](https://github.com/developer-experience-DevEX-platform/ci-cd-templates/blob/main/docs/cd/kubernetes-gitops.md) — deploys into the cluster; Terraform does not

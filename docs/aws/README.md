# AWS primitives

Every `aws/` module creates one resource family with company defaults
that callers cannot turn off. No GitHub, OIDC, or service naming.

Environment and bootstrap stacks call these. Service stacks call
`platform` modules, which compose primitives when they need them.

| Module | Creates | Locked |
| --- | --- | --- |
| [S3](s3.md) | One private bucket plus `${name}-logs` | Versioning, AES-256, public-access block, BucketOwnerEnforced, TLS-only policy, access logging, no force-destroy |
| [CloudFront](cloudfront.md) | One distribution in front of `aws/s3` | OAC, HTTPS, default cert, SPA error pages, PriceClass_100, access logs |
| [ECR](ecr.md) | One repository | Immutable tags, scan-on-push, AES-256, no force-delete |
| [Networking](networking.md) | VPC, subnets, NAT, routes | DNS, LB discovery tags |
| [EKS](eks.md) | Cluster, system node group, add-ons | Private subnets, API access entries |
| [Lambda](lambda.md) | One ZIP function and log group | Terraform owns config; CD owns later code |

Inputs are identity (`name`, CIDRs, subnet IDs) and optional `tags`.
There is no encryption or mutability flag.

Relative compose from a `platform` module:

```hcl
module "ecr" {
  source = "../../aws/ecr"

  name = local.ecr_repository_name
  tags = local.tags
}
```

Stacks never use that relative path. They pin a git tag.

# CloudFront

Module: `aws/cloudfront`

Creates one distribution that reads a private `aws/s3` bucket through
origin access control. Callers pass identity (`name` and the bucket
outputs) and optional `tags`. There are no inputs for aliases, ACM,
price class, or WAF.

Service stacks do not call this module. A later `platform` module
composes it.

## Locked defaults

- Origin access control, SigV4, always sign
- Default `*.cloudfront.net` certificate
- HTTPS redirect
- `PriceClass_100`
- SPA errors `403` and `404` serve `/index.html`
- Managed `CachingOptimized` cache policy
- IPv6 on
- The origin bucket stays private; only this distribution can `GetObject`
- Replaces the origin bucket policy and keeps the TLS-only deny
- Standard access logs go to `${name}-cf-logs` (that bucket does not log to itself)

## Caller

From a `platform` module inside this repository:

```hcl
module "cdn" {
  source = "../../aws/cloudfront"

  name                         = var.service_name
  bucket_name                 = module.site.name
  bucket_arn                  = module.site.arn
  bucket_regional_domain_name = module.site.bucket_regional_domain_name
  tags                        = var.tags
}
```

`module.site` is `aws/s3`.

## Inputs

| Input | Required | Notes |
| --- | --- | --- |
| `name` | yes | Origin access control name, at most 55 characters so `${name}-cf-logs` fits. |
| `bucket_name` | yes | Private origin bucket. |
| `bucket_arn` | yes | Used in the bucket policy. |
| `bucket_regional_domain_name` | yes | CloudFront origin domain. |
| `tags` | no | Merged with `ManagedBy=Terraform` and `Platform=DevEx`. |

## Outputs

| Output | Notes |
| --- | --- |
| `id` | Distribution ID. |
| `arn` | Distribution ARN. |
| `domain_name` | `*.cloudfront.net` hostname. |
| `hosted_zone_id` | For a later Route 53 alias. |

## Related

- [S3](s3.md)
- [AWS primitives](README.md)

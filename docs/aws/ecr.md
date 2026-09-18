# ECR

Module: `aws/ecr`

Creates one repository. Callers pass `name` and optional `tags`. There
are no inputs for mutability, scanning, encryption, or deletion.

Service stacks do not call this module. `service-container-release`
composes it.

## Locked defaults

- Image tags `IMMUTABLE`
- Scan on push
- AES-256 encryption
- `force_delete = false`

`latest` is not a platform tag. CI/CD publishes the 40-character Git
SHA only.

## Caller

From a `platform` module inside this repository:

```hcl
module "ecr" {
  source = "../../aws/ecr"

  name = var.service_name
  tags = var.tags
}
```

From a stack (rare; prefer the platform module):

```hcl
module "ecr" {
  source = "git::https://github.com/developer-experience-DevEX-platform/terraform-modules.git//aws/ecr?ref=v0.3.0"

  name = "catalog-api"
}
```

## Inputs

| Input | Required | Notes |
| --- | --- | --- |
| `name` | yes | Valid ECR repository name. |
| `tags` | no | Merged with `ManagedBy=Terraform` and `Platform=DevEx`. |

## Outputs

| Output | Notes |
| --- | --- |
| `name` | Repository name. |
| `arn` | Repository ARN. |
| `url` | Repository URL. |
| `registry_id` | Registry that hosts it. |

## Related

- [Container release](../platform/service-container-release.md)
- [CI/CD container release](https://github.com/developer-experience-DevEX-platform/ci-cd-templates/blob/main/docs/cd/container-release.md)

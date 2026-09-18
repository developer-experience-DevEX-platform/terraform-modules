# Platform

For people who maintain these modules and the live stacks. Teams
adopting a service can skip this page; use
[getting started](getting-started.md).

## Pinning

Documented stacks use a git tag. That is the contract. Do not pin
`main`. A lab stack may pin a branch while a module is under test;
switch it back to a tag before the stack is considered done.

CI/CD templates pin reusable workflows at `@main`. Terraform does not.
A workflow change is cheap to roll forward. An applied module change
is not.

All stacks in `platform-infrastructure` should share one tag. Bump them
together when you cut a release.

```hcl
source = "git::https://github.com/developer-experience-DevEX-platform/terraform-modules.git//platform/service-container-release?ref=v0.3.0"
```

## Releasing a version

1. Change the module. Keep defaults locked.
2. Push `main`. Validate must be green.
3. Tag `vX.Y.Z` on that commit. Tags are the unit stacks consume.
4. Bump `?ref=` in `platform-infrastructure` to the new tag.
5. Plan the affected stacks. Existing resources must `moved`, not
   recreate.

Do not delete AWS resources in order to point a stack at a new module
path. Add `moved` blocks in the stack or in the module that absorbed
the resource (see `service-container-release` → `aws/ecr`).

## Validate

`.github/workflows/validate.yml` runs `terraform fmt`, `init
-backend=false`, and `validate` for every module on pull requests and
on `main`. It does not apply.

## Providers

The stack configures providers. A conceptual root looks like:

```hcl
provider "aws" {
  region = var.aws_region
}

provider "github" {
  owner = var.github_owner
}
```

`platform` modules need both. `aws` primitives need only AWS.
Terraform `>= 1.8.0` and the AWS provider `>= 5.0` are the floor for
the primitives.

The account-level GitHub Actions OIDC provider is bootstrap, not a
per-service resource. Pass its ARN into `platform` modules as
`github_oidc_provider_arn`.

## Bootstrap vs service

| Stack | Calls | Examples |
| --- | --- | --- |
| Bootstrap / account | `aws/s3` | Terraform state bucket, Lambda artifact bucket |
| Environment | `aws/networking`, `aws/eks` | Staging VPC and cluster |
| Service | `platform/service-container-release` or `platform/service-lambda` | ECR + release role, or Lambda publish + staging function |

GitHub owner ID and repository ID are immutable numeric IDs. Platform
automation discovers them through the GitHub API. Do not type them by
hand in a service repo, and do not trust a renamed repository slug
alone in OIDC `sub`.

## Container release variables

Set per repository by `service-container-release`, not by the team:

- `AWS_REGION`
- `AWS_RELEASE_ROLE_ARN`
- `ECR_REPOSITORY`

The reusable workflow assumes the role with GitHub OIDC. Trust is
repository- and `main`-scoped. If any variable is unset, Release fails.
Details: [container release](platform/service-container-release.md) and
the [CI/CD container-release](https://github.com/developer-experience-DevEX-platform/ci-cd-templates/blob/main/docs/cd/container-release.md)
page.

## In-tree copies

`platform-infrastructure/modules/` may still contain older copies.
Live stacks must not source those paths. Delete the in-tree tree only
after every stack plans clean against a tagged git source.

# Getting started

Add infrastructure for one service in one sitting. The stack is a thin
caller in `platform-infrastructure`. You do not copy IAM, ECR, or OIDC
into the service repository.

Application developers skip this page. They keep a Dockerfile and the
CI/CD callers. Backstage and platform automation supply the stack.

## 1. Add a stack

Create `platform-infrastructure/services/<service>/main.tf`.

**Container service**

```hcl
module "container_release" {
  source = "git::https://github.com/developer-experience-DevEX-platform/terraform-modules.git//platform/service-container-release?ref=v0.3.0"

  service_name             = "catalog-api"
  github_owner             = "developer-experience-DevEX-platform"
  github_owner_id          = var.github_owner_id
  github_repository        = "catalog-api"
  github_repository_id     = var.github_repository_id
  github_oidc_provider_arn = var.github_oidc_provider_arn
  aws_region               = "eu-west-2"
}
```

Replace `v0.3.0` with the current release tag. Do not use `main`.

The developer never supplies the IAM role ARN, AWS account ID, or ECR
URL. Terraform writes `AWS_REGION`, `AWS_RELEASE_ROLE_ARN`, and
`ECR_REPOSITORY` into the GitHub repository.

**Lambda service** — same stack layout, with
`platform/service-lambda` instead of `service-container-release`. Lambda
CD in the reusable workflows is not reviewed yet. See
[Lambda service](platform/service-lambda.md).

Environment stacks (VPC, EKS, shared buckets) call `aws` modules
directly. Service stacks do not. Details: [overview](overview.md).

## 2. Pin a tag

Every `source` ends with `?ref=<tag>`. All stacks in
`platform-infrastructure` should share the same tag.

```text
git::https://github.com/developer-experience-DevEX-platform/terraform-modules.git//<path>?ref=v0.3.0
```

Relative paths (`source = "../../aws/ecr"`) are only for `platform`
modules composing `aws` modules inside this repository. Stacks always
use the git source.

## 3. Confirm it works

From the stack directory: `terraform init` then `terraform plan`.

You are done when the plan creates the service ECR repository (or moves
an existing one), the `*-github-release` role, and the three GitHub
Actions variables. A merge to `main` in the service repo can then
publish. Missing variables fail Release; do not skip that job.

## Next

- [How the two layers work](overview.md)
- [Container release module](platform/service-container-release.md)
- [Container release workflow](https://github.com/developer-experience-DevEX-platform/ci-cd-templates/blob/main/docs/cd/container-release.md)
- [Platform](platform.md) — tagging, providers, bootstrap

# Terraform modules

Reusable Terraform modules for the DevEx platform. Live stacks stay in `platform-infrastructure`.

```text
aws/          s3, ecr, networking, eks, lambda
platform/     DevEx composition (GitHub, OIDC, service naming)
```

Pin a git tag. Do not follow `main`.

```hcl
module "artifacts" {
  source = "git::https://github.com/developer-experience-DevEX-platform/terraform-modules.git//aws/s3?ref=v0.1.0"

  name = "devex-lambda-artifacts-123456789012"
  tags = {
    Purpose = "LambdaArtifacts"
  }
}

module "container_release" {
  source = "git::https://github.com/developer-experience-DevEX-platform/terraform-modules.git//platform/service-container-release?ref=v0.1.0"

  service_name             = "catalog-api"
  github_owner             = "developer-experience-DevEX-platform"
  github_owner_id          = var.github_owner_id
  github_repository        = "catalog-api"
  github_repository_id     = var.github_repository_id
  github_oidc_provider_arn = var.github_oidc_provider_arn
  aws_region               = "eu-west-2"
}
```

`platform` modules may compose `aws` modules with a relative path inside this repository. Application stacks should call `platform` modules for service IAM and OIDC, not `aws` primitives, except environment stacks that own VPC and EKS.

# Terraform modules

Reusable Terraform modules for this organization.

Live stacks stay in `platform-infrastructure`. This repository is the
module library. CI/CD templates consume what these modules provision;
they do not create AWS resources.

`aws` and `platform` are documented. Pin a git tag. Do not follow `main`.

## Start here

1. [Getting started](docs/getting-started.md) — paste a stack call and pin a tag
2. [Overview](docs/overview.md) — two layers, who calls what, locked defaults
3. Your module: [S3](docs/aws/s3.md), [ECR](docs/aws/ecr.md), or
   [service container release](docs/platform/service-container-release.md)

## AWS primitives

One resource family. Locked company defaults. No GitHub, OIDC, or service
naming.

| Module | Status | Docs |
| --- | --- | --- |
| S3 | Available | [docs/aws/s3.md](docs/aws/s3.md) |
| ECR | Available | [docs/aws/ecr.md](docs/aws/ecr.md) |
| Networking | Available | [docs/aws/networking.md](docs/aws/networking.md) |
| EKS | Available | [docs/aws/eks.md](docs/aws/eks.md) |
| Lambda | Available | [docs/aws/lambda.md](docs/aws/lambda.md) |

How they fit: [docs/aws/README.md](docs/aws/README.md).

## Platform composition

Service IAM, GitHub OIDC, repository variables, and naming. These modules
may compose `aws` primitives with a relative path inside this repository.

| Module | Status | Docs |
| --- | --- | --- |
| Container release | Available | [docs/platform/service-container-release.md](docs/platform/service-container-release.md) |
| Lambda service | Exists | [docs/platform/service-lambda.md](docs/platform/service-lambda.md) |

How they fit: [docs/platform/README.md](docs/platform/README.md).

## Platform

Tagging, providers, bootstrap vs service stacks, and how we pin versions
live in [docs/platform.md](docs/platform.md). Application developers do
not need that page, or this repository.

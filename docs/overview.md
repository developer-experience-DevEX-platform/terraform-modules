# Overview

This repository answers: what AWS and GitHub objects does one service or
one environment get? It does not apply them. `platform-infrastructure`
applies. CI/CD templates consume the GitHub variables and IAM roles
after Terraform has run.

## Layers

```text
service repo                 Dockerfile, ci.yml, release.yml
ci-cd-templates              build, scan, publish, GitOps SHA
terraform-modules            this repo: reusable modules
platform-infrastructure      live stacks, providers, state
AWS / GitHub                 ECR, IAM, VPC, EKS, repository variables
```

Two module families:

```text
environment stack                 service stack
      ↓                                 ↓
aws/networking                    platform/service-container-release
aws/eks                                 ↓
aws/s3                            aws/ecr   (relative compose)
```

| Layer | Lives in | Owns |
| --- | --- | --- |
| `aws/` | this repo | One resource family and locked defaults. No GitHub. |
| `platform/` | this repo | Service naming, OIDC trust, GitHub variables, composition. |
| Stack | `platform-infrastructure` | Providers, backend, which module, GitHub IDs. |
| Service repo | the application | Code and Dockerfile. |

Application stacks call `platform` modules. Environment stacks that own
the VPC or EKS call `aws` primitives. Do not call `aws/ecr` from a
service stack; `service-container-release` already composes it.

## Locked defaults

Company controls are not inputs. Callers pass identity (`name`, GitHub
IDs, region) and optional tags. There is no flag for mutable ECR tags,
public S3, or `force_destroy`.

If a default must change, change the module and cut a new tag. Do not
add an override on the stack.

## What belongs in a module

The module owns the process: which resources exist, which defaults are
locked, and which GitHub variables are written.

The stack owns wiring: AWS and GitHub providers, Terraform state, and
the IDs platform automation discovers from the GitHub API.

The service owns application code. It does not declare IAM or ECR.

Not supported:

- Following `main` from a live stack
- Optional flags that turn off encryption, immutability, or scanning
- Per-service OIDC providers
- Long-lived AWS keys in GitHub
- Secrets Manager roles for integration tests

## Providers

Modules declare required providers. They do not configure credentials.

The calling stack must set `provider "aws"` and, for `platform`
modules, `provider "github"`. Details: [platform](platform.md).

## Related

- [AWS primitives](aws/README.md)
- [Platform composition](platform/README.md)
- [CI/CD templates](https://github.com/developer-experience-DevEX-platform/ci-cd-templates)

# Service container release

Module: `platform/service-container-release`

Gives one containerized service a secure ECR publish path through
GitHub Actions OIDC. Backstage and platform automation supply the
infrastructure; application developers keep code and a Dockerfile.

The module composes `aws/ecr`. Image tags are immutable, scan-on-push
is on, and force deletion is off. Callers cannot turn those off.

## What it creates

```text
ECR repository
    +
<service>-github-release
    +
AWS_REGION / AWS_RELEASE_ROLE_ARN / ECR_REPOSITORY
    +
GitHub production environment
```

## Caller

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

The stack must configure AWS and GitHub providers.
[Platform](../platform.md) shows the shape. This module does not.

## OIDC trust

Role name: `<service_name>-github-release`.

Trusts the account-level GitHub OIDC provider (not a per-service
provider):

- Audience: `sts.amazonaws.com`
- Subject: `repo:<owner>@<owner_id>/<repo>@<repo_id>:ref:refs/heads/<branch>`

Default branch is `main`. Pull requests, other branches, other
repositories, and wildcard subjects are not trusted.

```text
<owner>@<owner_id>/<repo>@<repo_id> from refs/heads/main
        ↓
GitHub OIDC
        ↓
service release role
```

Platform automation discovers the numeric owner and repository IDs.
Developers never manage OIDC subjects.

## ECR policy

`ecr:GetAuthorizationToken` requires `Resource "*"`. Every repository
operation is limited to this service's ECR ARN:

- `ecr:BatchCheckLayerAvailability`
- `ecr:GetDownloadUrlForLayer`
- `ecr:BatchGetImage`
- `ecr:InitiateLayerUpload`
- `ecr:UploadLayerPart`
- `ecr:CompleteLayerUpload`
- `ecr:DescribeImages`
- `ecr:DescribeRepositories`
- `ecr:PutImage`

The role cannot delete the repository or images, change lifecycle or
repository policies, or administer ECR.

Published image:

```text
<account>.dkr.ecr.<region>.amazonaws.com/<ECR_REPOSITORY>:<git-sha>
```

`latest` is not used. The reusable workflow refuses it.

## GitHub Actions variables

Non-secret, platform-managed:

- `AWS_REGION`
- `AWS_RELEASE_ROLE_ARN`
- `ECR_REPOSITORY`

The module does not create `AWS_ACCESS_KEY_ID`,
`AWS_SECRET_ACCESS_KEY`, `AWS_SESSION_TOKEN`, `AWS_ACCOUNT_ID`, or
`ECR_REGISTRY`. GitHub Actions uses OIDC. The registry hostname comes
from ECR login.

If these variables are missing, Release fails. Do not skip the publish
job when they are empty.

## Production environment

The module grants each reviewer team `pull` on the repository, then
creates the GitHub `production` environment used by the manual
promotion workflow.

At least one reviewer from `production_environment_reviewer_team_ids`
must approve. Self-review defaults to allowed for the current
single-reviewer lab. Administrator bypass stays off.

Deployment branch policy is `main` only. Staging delivery is automatic
and does not use this gate.

## Inputs

| Input | Default | Notes |
| --- | --- | --- |
| `service_name` | — | Required. Lowercase kebab-case. |
| `github_owner` | — | Required. |
| `github_owner_id` | — | Required. Numeric org ID. |
| `github_repository` | — | Required. |
| `github_repository_id` | — | Required. Numeric repo ID. |
| `github_branch` | `main` | Branch allowed to release. |
| `github_oidc_provider_arn` | — | Required. Account-level provider. |
| `aws_region` | — | Required. |
| `ecr_repository_name` | `""` | Empty uses `service_name`. |
| `production_environment_reviewer_team_ids` | `[19182366]` | One to six team IDs. |
| `production_environment_prevent_self_review` | `false` | |
| `tags` | `{}` | |

## Outputs

| Output | Notes |
| --- | --- |
| `ecr_repository_name` | |
| `ecr_repository_arn` | |
| `ecr_repository_url` | |
| `release_role_name` | |
| `release_role_arn` | |

## Responsibility

| Owner | Owns |
| --- | --- |
| Bootstrap | Account OIDC provider, Terraform state, execution identity |
| This module | ECR, release role, ECR policy, GitHub variables, production environment |
| Developer | Application code, Dockerfile |

## Related

- [ECR primitive](../aws/ecr.md)
- [CI/CD container release](https://github.com/developer-experience-DevEX-platform/ci-cd-templates/blob/main/docs/cd/container-release.md)
- [Kubernetes GitOps](https://github.com/developer-experience-DevEX-platform/ci-cd-templates/blob/main/docs/cd/kubernetes-gitops.md)

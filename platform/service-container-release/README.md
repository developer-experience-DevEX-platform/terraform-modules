# Service Container Release

This module defines the platform abstraction for giving one containerized service a secure AWS ECR release path through GitHub Actions OIDC. Backstage and platform automation supply the infrastructure details; application developers only maintain their application code and Dockerfile.

The service-owned ECR repository, IAM release role, GitHub OIDC trust, repository-scoped ECR permissions, GitHub Actions repository variables, and protected production environment are implemented.

## Example

Backstage service provisioning will eventually call the module like this:

```hcl
module "container_release" {
  source = "../../../../modules/platform/service-container-release"

  service_name             = "catalog-api"
  github_owner             = "developer-experience-DevEX-platform"
  github_owner_id          = var.github_owner_id
  github_repository        = "catalog-api"
  github_repository_id     = var.github_repository_id
  github_oidc_provider_arn = var.github_oidc_provider_arn
  aws_region               = "eu-west-2"
}
```

The developer never needs to supply or understand the resulting IAM role ARN, AWS account ID, or ECR repository URL.

## Implementation status

### ECR repository

**Implemented.** The repository name uses `ecr_repository_name` when supplied and otherwise falls back to `service_name`.

This platform module currently owns the ECR resource directly. It may later compose `modules/aws/ecr` if the ECR behavior becomes reusable outside this platform capability.

Effective defaults:

- Repository name defaults to `service_name`.
- Image tags are immutable.
- ECR scan-on-push is enabled.
- Force deletion is disabled, protecting non-empty repositories from accidental Terraform deletion.

The reusable `container-release` workflow will eventually publish immutable Git SHA tags in this form:

```text
<repository-url>:<git-sha>
```

For example:

```text
123456789012.dkr.ecr.eu-west-2.amazonaws.com/catalog-api:<git-sha>
```

The `latest` tag is not used or recommended.

### Service release role

**Implemented.**

Each service will receive an IAM role conceptually named `<service_name>-github-release`. The role will trust the existing account-level GitHub Actions OIDC provider with:

- Audience: `sts.amazonaws.com`
- Subject: `repo:<github_owner>@<github_owner_id>/<github_repository>@<github_repository_id>:ref:refs/heads/<github_branch>`

For example:

```text
repo:my-company@123456789/catalog-api@987654321:ref:refs/heads/main
```

This trust policy limits role assumption to the configured repository and branch. The module will not create a separate OIDC provider for each service.

The trust boundary is:

```text
<github_owner>@<github_owner_id>/<github_repository>@<github_repository_id> from refs/heads/<github_branch>
        ↓
GitHub OIDC
        ↓
service-specific release role
```

For the normal platform configuration, only the service repository's `main` branch may assume its release role. Pull requests, other branches, other repositories, and wildcard subjects are not trusted.

GitHub repositories using immutable OIDC subjects include both the owner ID and repository ID. The platform Terraform workflow discovers these numeric identifiers automatically through the GitHub API. Application developers never provide or manage owner IDs, repository IDs, OIDC subjects, or IAM role trust configuration.

### Least-privilege ECR policy

**Implemented.**

The release role will receive only the permissions needed to push and pull the service image. `ecr:GetAuthorizationToken` requires `Resource "*"`; repository operations will be restricted to the ARN of this service's ECR repository.

Expected repository operations include:

- `ecr:BatchCheckLayerAvailability`
- `ecr:GetDownloadUrlForLayer`
- `ecr:BatchGetImage`
- `ecr:InitiateLayerUpload`
- `ecr:UploadLayerPart`
- `ecr:CompleteLayerUpload`
- `ecr:PutImage`

The permission boundary is:

```text
release role
        ↓
ecr:GetAuthorizationToken
        +
push/pull operations
        ↓
only the service's ECR repository
```

The role cannot delete the repository or images, change lifecycle or repository policies, or administer ECR.

### PR integration-test secret access

**Implemented.** The module always creates a separate `<service_name>-github-integration-test` IAM role and the corresponding `AWS_INTEGRATION_TEST_ROLE_ARN` repository variable during initial service provisioning. Its GitHub OIDC trust is restricted to the immutable service repository identity, the `pull_request` context, and `developer-experience-DevEX-platform/ci-cd-templates/.github/workflows/nodejs-ci.yml@refs/heads/main`. The role can therefore be assumed only through the approved central reusable Node.js CI workflow; feature-branch pushes, main/release jobs, and other workflows cannot assume it.

Integration-test secrets are created and maintained outside Terraform using this naming convention:

```text
<service_name>/integration/<secret_name>
```

For example, `payments-api/integration/stripe` and `payments-api/integration/database` follow the standard convention. Terraform does not create, update, rotate, or delete these secrets, and secret values never enter Terraform state.

The role receives only `secretsmanager:GetSecretValue`, scoped to the service's integration namespace:

```text
arn:<partition>:secretsmanager:<region>:<account>:secret:<service_name>/integration/*
```

That namespace alone is not sufficient. AWS also requires this resource tag to match:

- `RepositoryId` equals the service repository's immutable numeric GitHub ID.

The manual Platform/Security secret process owns this authorization tag. Application developers cannot grant access merely by adding a declaration to their repository, and the integration-test role has no secret creation, mutation, deletion, or tag-management permissions. A missing or incorrect `RepositoryId` causes AWS to deny `GetSecretValue`.

Adding or rotating a correctly named and tagged secret requires no Terraform change. `.platform/integration-tests.yaml` selects which approved secret is wired into a test environment variable; it does not grant IAM authorization.

### GitHub Actions variables

**Implemented.**

The module automatically populates these non-secret, platform-managed repository variables:

- `AWS_REGION`
- `AWS_RELEASE_ROLE_ARN`
- `ECR_REPOSITORY`
- `AWS_INTEGRATION_TEST_ROLE_ARN`

Application developers do not create or maintain these values. The module does not create `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_SESSION_TOKEN`, `AWS_ACCOUNT_ID`, or `ECR_REGISTRY`. GitHub Actions obtains short-lived AWS credentials through OIDC, and the registry hostname is discovered during ECR login.

### Production environment protection

**Implemented.**

The module grants each configured reviewer team `pull` access to the service repository before creating the GitHub `production` environment used by the manual production-promotion workflow. At least one reviewer from `production_environment_reviewer_team_ids` must approve a deployment. Self-review is configurable and defaults to allowed for the current single-reviewer platform lab; administrator bypass remains disabled.

Deployment branch policies use a single custom pattern, `main`. Feature branches, pull-request refs, tags, and other branches cannot deploy through the production environment. Staging delivery remains automatic and does not use this approval gate.

## Provider responsibility

The calling environment stack must configure both the AWS and GitHub providers. This reusable module declares provider requirements but contains no credentials or provider authentication configuration.

A conceptual root configuration looks like:

```hcl
provider "aws" {
  region = var.aws_region
}

provider "github" {
  owner = var.github_owner
}
```

This configuration belongs in the calling environment stack, not inside this module.

## Provisioning lifecycle

```text
Backstage
    ↓
creates service repository
    ↓
creates infrastructure pull request
    ↓
Terraform applies service-container-release
    ↓
ECR repository created
    ↓
OIDC release role created
    ↓
GitHub repository variables populated
    ↓
generated release workflow works automatically
```

## Responsibility model

### Account and platform bootstrap

- Account-level GitHub Actions OIDC provider
- Terraform state
- Terraform execution identity

### `service-container-release` module

- Service ECR repository
- Service release IAM role
- Repository-scoped ECR policy
- GitHub Actions repository variables

### Application developer

- Application code
- Dockerfile

In short, the developer owns application code and the Dockerfile. The platform owns ECR, IAM, OIDC, AWS region configuration, the release role ARN, and ECR repository configuration.

## Inputs

| Name | Type | Required | Default | Purpose |
|---|---|---:|---|---|
| `service_name` | `string` | Yes | — | Lowercase kebab-case platform service name. |
| `github_owner` | `string` | Yes | — | Organization that owns the repository. |
| `github_owner_id` | `string` | Yes | — | Immutable numeric organization ID discovered by platform automation. |
| `github_repository` | `string` | Yes | — | Repository permitted to assume the release role. |
| `github_repository_id` | `string` | Yes | — | Immutable numeric repository ID discovered by platform automation. |
| `github_branch` | `string` | No | `main` | Branch permitted to release containers. |
| `production_environment_reviewer_team_ids` | `set(number)` | No | `[19182366]` | GitHub teams permitted to approve the protected production environment. |
| `production_environment_prevent_self_review` | `bool` | No | `false` | Prevents a deployment requester from approving their own production deployment when enabled. |
| `github_oidc_provider_arn` | `string` | Yes | — | Existing account-level GitHub OIDC provider ARN. |
| `aws_region` | `string` | Yes | — | Region containing the ECR repository. |
| `ecr_repository_name` | `string` | No | `""` | Repository override; empty uses `service_name`. |
| `ecr_image_tag_mutability` | `string` | No | `IMMUTABLE` | ECR tag mutability mode. |
| `ecr_scan_on_push` | `bool` | No | `true` | Enables ECR scan-on-push. |
| `force_delete_ecr_repository` | `bool` | No | `false` | Allows deletion of a non-empty repository. |
| `tags` | `map(string)` | No | `{}` | Additional AWS resource tags. |

## Outputs

| Name | Purpose |
|---|---|
| `ecr_repository_name` | Effective ECR repository name. |
| `ecr_repository_arn` | ECR repository ARN. |
| `ecr_repository_url` | Full ECR repository URL. |
| `release_role_name` | Service IAM release role name. |
| `release_role_arn` | Service IAM release role ARN. |

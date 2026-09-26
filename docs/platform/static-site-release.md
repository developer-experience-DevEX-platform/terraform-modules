# Static site release

Module: `platform/static-site-release`

Gives one static website a secure S3 + CloudFront publish path through
GitHub Actions OIDC. Backstage and platform automation supply the
infrastructure; application developers keep frontend code. There is no
ECR, Dockerfile, or Kubernetes.

The module composes `aws/s3` and `aws/cloudfront`. Callers cannot turn
off TLS, access logging, or origin access control.

## What it creates

```text
<service>-<account-id> content bucket
    +
<service>-<account-id>-logs
    +
CloudFront distribution
    +
<service>-cf-logs
    +
<service>-github-release
    +
AWS_REGION / AWS_RELEASE_ROLE_ARN / STATIC_SITE_BUCKET /
CLOUDFRONT_DISTRIBUTION_ID / TECHDOCS_S3_BUCKET
    +
GitHub production environment
```

## Caller

```hcl
module "static_site_release" {
  source = "git::https://github.com/developer-experience-DevEX-platform/terraform-modules.git//platform/static-site-release?ref=v0.4.0"

  service_name             = "billing-ui"
  github_owner             = "developer-experience-DevEX-platform"
  github_owner_id          = var.github_owner_id
  github_repository        = "billing-ui"
  github_repository_id     = var.github_repository_id
  github_oidc_provider_arn = var.github_oidc_provider_arn
  aws_region               = "eu-west-2"
}
```

Replace the tag with the current release once this module is tagged. Do not use `main`.

The stack must configure AWS and GitHub providers.
[Platform](../platform.md) shows the shape. This module does not.

## OIDC trust

Role name: `<service_name>-github-release`.

Same subject as container release. Default branch is `main`. Pull
requests, other branches, other repositories, and wildcard subjects are
not trusted.

## Site policy

The role may list the content bucket and get, put, or delete objects in
it. It may create a CloudFront invalidation on this distribution only.

The role cannot change bucket policy, encryption, log buckets, or other
distributions.

## TechDocs policy

Same prefix IAM as container release:

```text
default/component/<service_name>/
```

on the shared bootstrap bucket `devex-techdocs-<account-id>`.

## GitHub Actions variables

Non-secret, platform-managed:

- `AWS_REGION`
- `AWS_RELEASE_ROLE_ARN`
- `STATIC_SITE_BUCKET`
- `CLOUDFRONT_DISTRIBUTION_ID`
- `TECHDOCS_S3_BUCKET`

The module does not create long-lived AWS keys. If `STATIC_SITE_BUCKET`
is missing, the later static-site release workflow should skip publish.

## Production environment

Same GitHub `production` environment as container release. Reviewer
teams, `main` only, administrator bypass off.

## Inputs

| Input | Default | Notes |
| --- | --- | --- |
| `service_name` | — | Required. Lowercase kebab-case, at most 45 characters. |
| `github_owner` | — | Required. |
| `github_owner_id` | — | Required. Numeric org ID. |
| `github_repository` | — | Required. |
| `github_repository_id` | — | Required. Numeric repo ID. |
| `github_branch` | `main` | Branch allowed to publish. |
| `github_oidc_provider_arn` | — | Required. Account-level provider. |
| `aws_region` | — | Required. |
| `techdocs_bucket_name` | `""` | Empty uses `devex-techdocs-<account-id>`. |
| `production_environment_reviewer_team_ids` | `[19182366]` | One to six team IDs. |
| `production_environment_prevent_self_review` | `false` | |
| `tags` | `{}` | |

## Outputs

| Output | Notes |
| --- | --- |
| `site_bucket_name` | Content bucket. |
| `site_bucket_arn` | |
| `cloudfront_distribution_id` | |
| `cloudfront_domain_name` | `*.cloudfront.net`. |
| `release_role_name` | |
| `release_role_arn` | |
| `techdocs_bucket_name` | Shared bucket the role may publish into. |

## Responsibility

| Owner | Owns |
| --- | --- |
| Bootstrap | Account OIDC provider, Terraform state, TechDocs bucket |
| This module | Site bucket, CloudFront, release role, GitHub variables, production environment |
| Developer | Frontend code |

## Related

- [S3 primitive](../aws/s3.md)
- [CloudFront primitive](../aws/cloudfront.md)

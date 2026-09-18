# Service Lambda

Module: `platform/service-lambda`

Opt-in module for a Lambda-target service. It does not affect
Kubernetes services.

Lambda CD in `ci-cd-templates` exists and is **not reviewed** yet. Do
not treat this as the golden path. Prefer
[container release](service-container-release.md) for a new service.

The shared artifact bucket is owned by bootstrap (`aws/s3`). Callers
pass `lambda_artifact_bucket_name`. Artifact keys are immutable:

```text
<service>/<40-character-git-sha>/function.zip
<service>/<40-character-git-sha>/function.zip.sha256
```

## What it creates

- `<service>-github-lambda-release` — publish objects under
  `<service>/*` only. No bucket admin or delete.
- Staging function `<service>-staging` via `aws/lambda`
- `<service>-lambda-staging-execution` — logs only
- `<service>-github-lambda-staging-deploy` — update that function's
  code from the artifact prefix
- Repository variables for those roles and names

The release role cannot update a Lambda function. The deploy role
cannot publish artifacts.

## OIDC trust

Both GitHub roles require:

- `aud` = `sts.amazonaws.com`
- `sub` = immutable owner/repository identity on `main`
- `job_workflow_ref` = the matching reusable workflow on
  `ci-cd-templates` `@refs/heads/main`

Release: `nodejs-lambda-release.yml`. Staging deploy:
`nodejs-lambda-staging-deploy.yml`.

## Staging runtime

Defaults: Node.js 24, `dist/handler.handler`, `x86_64`, 256 MB, 10
second timeout. Initial code is `initial_artifact_key`. Terraform
never builds a ZIP.

The execution role trusts only `lambda.amazonaws.com` and can create
log streams and write events in `/aws/lambda/<service>-staging`.
Terraform manages that log group (30-day retention by default). No
artifact-bucket or application permissions.

Terraform owns runtime, handler, architecture, memory, timeout,
execution role, log group, and tags. CD owns later code. Terraform
ignores `s3_bucket`, `s3_key`, and `s3_object_version` after create.

## GitHub Actions variables

- `AWS_REGION` (same name as the container contract)
- `AWS_LAMBDA_RELEASE_ROLE_ARN`
- `AWS_LAMBDA_ARTIFACT_BUCKET`
- `AWS_LAMBDA_STAGING_DEPLOY_ROLE_ARN`
- `AWS_LAMBDA_STAGING_FUNCTION_NAME`

No credentials in GitHub.

## Inputs

| Input | Default | Notes |
| --- | --- | --- |
| `service_name` | — | Required. Prefix for artifacts and names. |
| `github_owner` | — | Required. |
| `github_owner_id` | — | Required. |
| `github_repository` | — | Required. |
| `github_repository_id` | — | Required. |
| `github_branch` | `main` | |
| `github_oidc_provider_arn` | — | Required. |
| `aws_region` | — | Required. |
| `lambda_artifact_bucket_name` | — | Required. Bootstrap bucket. |
| `initial_artifact_key` | — | Required. `<service>/<sha>/function.zip`. |
| `staging_runtime` | `nodejs24.x` | |
| `staging_handler` | `dist/handler.handler` | |
| `staging_memory_size` | `256` | |
| `staging_timeout` | `10` | |
| `staging_log_retention_days` | `30` | |
| `tags` | `{}` | |

## Outputs

| Output | Notes |
| --- | --- |
| `lambda_release_role_arn` | |
| `lambda_artifact_prefix` | |
| `staging_function_name` | |
| `staging_function_arn` | |
| `staging_execution_role_arn` | |
| `staging_deploy_role_arn` | |
| `staging_log_group_name` | |

## Related

- [Lambda primitive](../aws/lambda.md)
- [S3](../aws/s3.md)
- [Platform](../platform.md)

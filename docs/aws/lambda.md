# Lambda

Module: `aws/lambda`

One ZIP-based function and its CloudWatch log group. Callers provide
the execution-role ARN, the initial immutable S3 artifact, runtime
configuration, retention, and tags.

No GitHub, OIDC, repository variables, or deployment-role logic.
`platform/service-lambda` owns those and composes this module.

Terraform owns function configuration and the log group. External CD
owns later code updates, so only `s3_bucket`, `s3_key`, and
`s3_object_version` are ignored after initial creation. Runtime,
handler, architecture, memory, timeout, execution role, tags, and log
retention stay reconciled.

## Caller

From a `platform` module:

```hcl
module "staging_lambda" {
  source = "../../aws/lambda"

  function_name        = "${var.service_name}-staging"
  execution_role_arn   = aws_iam_role.lambda_execution.arn
  artifact_bucket_name = var.lambda_artifact_bucket_name
  initial_artifact_key = var.initial_artifact_key
  runtime              = var.staging_runtime
  handler              = var.staging_handler
  architecture         = "x86_64"
  memory_size          = var.staging_memory_size
  timeout              = var.staging_timeout
  log_retention_days   = var.staging_log_retention_days
  tags                 = var.tags
}
```

`initial_artifact_key` must be
`<service>/<40-character-lowercase-git-sha>/function.zip`.

## Inputs

| Input | Required | Notes |
| --- | --- | --- |
| `function_name` | yes | |
| `execution_role_arn` | yes | Runtime role. This module does not create it. |
| `artifact_bucket_name` | yes | Bucket from `aws/s3`. |
| `initial_artifact_key` | yes | Immutable key; used only at create. |
| `runtime` | yes | |
| `handler` | yes | |
| `architecture` | yes | `x86_64` or `arm64`. |
| `memory_size` | yes | 128–10240 MB. |
| `timeout` | yes | 1–900 seconds. |
| `log_retention_days` | yes | |
| `description` | no | |
| `tags` | no | |

## Outputs

| Output | Notes |
| --- | --- |
| `function_name` | |
| `function_arn` | |
| `invoke_arn` | |
| `log_group_name` | |
| `log_group_arn` | |

## Related

- [S3](s3.md)
- [Lambda service](../platform/service-lambda.md)

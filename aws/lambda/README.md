# AWS Lambda module

This low-level module creates one ZIP-based Lambda function and its explicitly managed CloudWatch log group. Callers provide the execution-role ARN, initial immutable S3 artifact location, runtime configuration, retention, and tags.

The module has no GitHub, OIDC, repository, service-policy, or deployment-role logic. Higher-level platform modules own those concerns.

Terraform owns the function configuration and log group. External CD owns later code updates, so only `s3_bucket`, `s3_key`, and `s3_object_version` are ignored after initial creation. Runtime, handler, architecture, memory, timeout, execution role, tags, and log retention continue to be reconciled.

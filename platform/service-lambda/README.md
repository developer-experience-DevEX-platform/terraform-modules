# Service Lambda platform module

This opt-in module provisions Lambda artifact publishing and a staging runtime for a Lambda-target service. It does not affect existing Kubernetes services.

The shared artifact bucket is owned by `bootstrap/aws-account`; callers pass its `lambda_artifact_bucket_name` output into this module. Artifacts use immutable keys:

```text
<service>/<40-character-git-sha>/function.zip
<service>/<40-character-git-sha>/function.zip.sha256
```

The `<service>-github-lambda-release` role can list only `<service>/*` and can get or put objects only beneath that prefix. It has no bucket administration or deletion permissions.

OIDC trust requires all of the following:

- `aud` is `sts.amazonaws.com`
- `sub` is the immutable owner/repository identity on the configured `main` branch
- `job_workflow_ref` is `developer-experience-DevEX-platform/ci-cd-templates/.github/workflows/nodejs-lambda-release.yml@refs/heads/main`

The release role is separate from the staging deployment role and cannot update a Lambda function.

The module creates the non-secret repository variables `AWS_REGION`, `AWS_LAMBDA_RELEASE_ROLE_ARN`, and `AWS_LAMBDA_ARTIFACT_BUCKET`. `AWS_REGION` intentionally matches the existing platform variable contract.

## Staging runtime

The platform module composes `modules/aws/lambda`, which owns only the Lambda function and CloudWatch log group. Platform-specific naming, IAM, OIDC, repository variables, and deployment policy remain here.

The composition creates `<service>-staging` as a ZIP Lambda using secure platform defaults: Node.js 24, `dist/handler.handler`, `x86_64`, 256 MB memory, and a 10-second timeout. The initial function code comes from the caller-provided immutable `initial_artifact_key`; Terraform never builds or manufactures a ZIP.

The runtime role `<service>-lambda-staging-execution` trusts only `lambda.amazonaws.com` and can only create log streams and write log events in `/aws/lambda/<service>-staging`. Terraform manages that log group with 30-day retention by default. The runtime has no artifact-bucket or application-service permissions.

The future `<service>-github-lambda-staging-deploy` role requires:

- `aud` equal to `sts.amazonaws.com`
- the immutable service repository identity on `main`
- `job_workflow_ref` equal to `developer-experience-DevEX-platform/ci-cd-templates/.github/workflows/nodejs-lambda-staging-deploy.yml@refs/heads/main`

It can read only the service artifact prefix and call `GetFunction`, `GetFunctionConfiguration`, `UpdateFunctionCode`, and `PublishVersion` only for `<service>-staging`. The workflow does not exist until Phase 4B, so no other workflow can assume the role.

## Terraform and CD ownership

Terraform owns the function resource and configuration: runtime, handler, architecture, memory, timeout, execution role, log group, tags, and platform identities. Future CD owns code updates and published versions. Consequently, Terraform ignores only `s3_bucket`, `s3_key`, and `s3_object_version` after initial function creation; it continues reconciling all runtime configuration.

The staging CD variables are `AWS_LAMBDA_STAGING_DEPLOY_ROLE_ARN` and `AWS_LAMBDA_STAGING_FUNCTION_NAME`. They reuse the existing `AWS_REGION` and `AWS_LAMBDA_ARTIFACT_BUCKET` values. No credentials are stored in GitHub.

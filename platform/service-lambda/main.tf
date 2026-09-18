data "aws_partition" "current" {}
data "aws_caller_identity" "current" {}

locals {
  artifact_bucket_arn   = "arn:${data.aws_partition.current.partition}:s3:::${var.lambda_artifact_bucket_name}"
  artifact_prefix       = "${var.service_name}/"
  staging_function_name = "${var.service_name}-staging"
  staging_log_group_arn = "arn:${data.aws_partition.current.partition}:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${local.staging_function_name}"

  tags = merge(
    {
      ManagedBy = "Terraform"
      Platform  = "DevEx"
      Service   = var.service_name
    },
    var.tags,
  )
}

data "aws_iam_policy_document" "lambda_release_assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.github_oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_owner}@${var.github_owner_id}/${var.github_repository}@${var.github_repository_id}:ref:refs/heads/${var.github_branch}"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:job_workflow_ref"
      values   = ["developer-experience-DevEX-platform/ci-cd-templates/.github/workflows/nodejs-lambda-release.yml@refs/heads/main"]
    }
  }
}

resource "aws_iam_role" "lambda_release" {
  name               = "${var.service_name}-github-lambda-release"
  assume_role_policy = data.aws_iam_policy_document.lambda_release_assume_role.json
  tags               = local.tags
}

data "aws_iam_policy_document" "lambda_artifacts" {
  statement {
    sid       = "ListServiceArtifactPrefix"
    actions   = ["s3:ListBucket"]
    resources = [local.artifact_bucket_arn]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = ["${local.artifact_prefix}*"]
    }
  }

  statement {
    sid = "PublishServiceArtifacts"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
    ]
    resources = ["${local.artifact_bucket_arn}/${local.artifact_prefix}*"]
  }
}

resource "aws_iam_role_policy" "lambda_artifacts" {
  name   = "${var.service_name}-lambda-artifact-release"
  role   = aws_iam_role.lambda_release.id
  policy = data.aws_iam_policy_document.lambda_artifacts.json
}

resource "github_actions_variable" "aws_region" {
  repository    = var.github_repository
  variable_name = "AWS_REGION"
  value         = var.aws_region
}

resource "github_actions_variable" "aws_lambda_release_role_arn" {
  repository    = var.github_repository
  variable_name = "AWS_LAMBDA_RELEASE_ROLE_ARN"
  value         = aws_iam_role.lambda_release.arn
}

resource "github_actions_variable" "aws_lambda_artifact_bucket" {
  repository    = var.github_repository
  variable_name = "AWS_LAMBDA_ARTIFACT_BUCKET"
  value         = var.lambda_artifact_bucket_name
}

data "aws_iam_policy_document" "lambda_execution_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda_execution" {
  name               = "${var.service_name}-lambda-staging-execution"
  assume_role_policy = data.aws_iam_policy_document.lambda_execution_assume_role.json
  tags               = local.tags
}

data "aws_iam_policy_document" "lambda_execution_logs" {
  statement {
    sid = "WriteStagingFunctionLogs"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = ["${local.staging_log_group_arn}:*"]
  }
}

resource "aws_iam_role_policy" "lambda_execution_logs" {
  name   = "${var.service_name}-lambda-staging-logs"
  role   = aws_iam_role.lambda_execution.id
  policy = data.aws_iam_policy_document.lambda_execution_logs.json
}

module "staging_lambda" {
  source = "../../aws/lambda"

  function_name        = local.staging_function_name
  description          = "Staging Lambda function for ${var.service_name}."
  execution_role_arn   = aws_iam_role.lambda_execution.arn
  artifact_bucket_name = var.lambda_artifact_bucket_name
  initial_artifact_key = var.initial_artifact_key
  runtime              = var.staging_runtime
  handler              = var.staging_handler
  architecture         = "x86_64"
  memory_size          = var.staging_memory_size
  timeout              = var.staging_timeout
  log_retention_days   = var.staging_log_retention_days
  tags                 = local.tags

  depends_on = [aws_iam_role_policy.lambda_execution_logs]
}

data "aws_iam_policy_document" "staging_deploy_assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.github_oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_owner}@${var.github_owner_id}/${var.github_repository}@${var.github_repository_id}:ref:refs/heads/${var.github_branch}"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:job_workflow_ref"
      values   = ["developer-experience-DevEX-platform/ci-cd-templates/.github/workflows/nodejs-lambda-staging-deploy.yml@refs/heads/main"]
    }
  }
}

resource "aws_iam_role" "staging_deploy" {
  name               = "${var.service_name}-github-lambda-staging-deploy"
  assume_role_policy = data.aws_iam_policy_document.staging_deploy_assume_role.json
  tags               = local.tags
}

data "aws_iam_policy_document" "staging_deploy" {
  statement {
    sid = "DeployStagingFunctionCode"
    actions = [
      "lambda:GetFunction",
      "lambda:GetFunctionConfiguration",
      "lambda:PublishVersion",
      "lambda:UpdateFunctionCode",
    ]
    resources = [module.staging_lambda.function_arn]
  }

  statement {
    sid       = "ReadServiceArtifacts"
    actions   = ["s3:GetObject"]
    resources = ["${local.artifact_bucket_arn}/${local.artifact_prefix}*"]
  }
}

resource "aws_iam_role_policy" "staging_deploy" {
  name   = "${var.service_name}-lambda-staging-deploy"
  role   = aws_iam_role.staging_deploy.id
  policy = data.aws_iam_policy_document.staging_deploy.json
}

resource "github_actions_variable" "aws_lambda_staging_deploy_role_arn" {
  repository    = var.github_repository
  variable_name = "AWS_LAMBDA_STAGING_DEPLOY_ROLE_ARN"
  value         = aws_iam_role.staging_deploy.arn
}

resource "github_actions_variable" "aws_lambda_staging_function_name" {
  repository    = var.github_repository
  variable_name = "AWS_LAMBDA_STAGING_FUNCTION_NAME"
  value         = module.staging_lambda.function_name
}

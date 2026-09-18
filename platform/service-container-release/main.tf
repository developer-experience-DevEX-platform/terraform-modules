data "aws_partition" "current" {}

data "aws_caller_identity" "current" {}

locals {
  ecr_repository_name                   = var.ecr_repository_name != "" ? var.ecr_repository_name : var.service_name
  integration_test_secret_namespace_arn = "arn:${data.aws_partition.current.partition}:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:${var.service_name}/integration/*"

  tags = merge(
    {
      ManagedBy = "Terraform"
      Platform  = "DevEx"
      Service   = var.service_name
    },
    var.tags,
  )
}

resource "aws_ecr_repository" "service" {
  name                 = local.ecr_repository_name
  image_tag_mutability = var.ecr_image_tag_mutability
  force_delete         = var.force_delete_ecr_repository

  image_scanning_configuration {
    scan_on_push = var.ecr_scan_on_push
  }

  tags = local.tags
}

data "aws_iam_policy_document" "release_assume_role" {
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
  }
}

resource "aws_iam_role" "release" {
  name               = "${var.service_name}-github-release"
  assume_role_policy = data.aws_iam_policy_document.release_assume_role.json
  tags               = local.tags
}

data "aws_iam_policy_document" "release_ecr" {
  statement {
    sid       = "ECRAuthentication"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    sid = "ServiceRepositoryPushPull"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:DescribeImages",
      "ecr:DescribeRepositories",
      "ecr:PutImage",
    ]
    resources = [aws_ecr_repository.service.arn]
  }
}

resource "aws_iam_role_policy" "release_ecr" {
  name   = "${var.service_name}-ecr-release"
  role   = aws_iam_role.release.id
  policy = data.aws_iam_policy_document.release_ecr.json
}

data "aws_iam_policy_document" "integration_test_assume_role" {
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
      values   = ["repo:${var.github_owner}@${var.github_owner_id}/${var.github_repository}@${var.github_repository_id}:pull_request"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:job_workflow_ref"
      values   = ["developer-experience-DevEX-platform/ci-cd-templates/.github/workflows/nodejs-ci.yml@refs/heads/main"]
    }
  }
}

resource "aws_iam_role" "integration_test" {
  name               = "${var.service_name}-github-integration-test"
  assume_role_policy = data.aws_iam_policy_document.integration_test_assume_role.json
  tags               = local.tags
}

moved {
  from = aws_iam_role.integration_test[0]
  to   = aws_iam_role.integration_test
}

data "aws_iam_policy_document" "integration_test_secrets" {
  statement {
    sid       = "ReadApprovedIntegrationTestSecrets"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [local.integration_test_secret_namespace_arn]

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/RepositoryId"
      values   = [var.github_repository_id]
    }
  }
}

resource "aws_iam_role_policy" "integration_test_secrets" {
  name   = "${var.service_name}-integration-test-secrets"
  role   = aws_iam_role.integration_test.id
  policy = data.aws_iam_policy_document.integration_test_secrets.json
}

moved {
  from = aws_iam_role_policy.integration_test_secrets[0]
  to   = aws_iam_role_policy.integration_test_secrets
}

resource "github_actions_variable" "aws_region" {
  repository    = var.github_repository
  variable_name = "AWS_REGION"
  value         = var.aws_region
}

resource "github_actions_variable" "aws_release_role_arn" {
  repository    = var.github_repository
  variable_name = "AWS_RELEASE_ROLE_ARN"
  value         = aws_iam_role.release.arn
}

resource "github_actions_variable" "ecr_repository" {
  repository    = var.github_repository
  variable_name = "ECR_REPOSITORY"
  value         = aws_ecr_repository.service.name
}

resource "github_actions_variable" "aws_integration_test_role_arn" {
  repository    = var.github_repository
  variable_name = "AWS_INTEGRATION_TEST_ROLE_ARN"
  value         = aws_iam_role.integration_test.arn
}

moved {
  from = github_actions_variable.aws_integration_test_role_arn[0]
  to   = github_actions_variable.aws_integration_test_role_arn
}

resource "github_team_repository" "production_reviewer" {
  for_each = {
    for team_id in var.production_environment_reviewer_team_ids : tostring(team_id) => team_id
  }

  team_id    = each.value
  repository = var.github_repository
  permission = "pull"
}

resource "github_repository_environment" "production" {
  repository          = var.github_repository
  environment         = "production"
  prevent_self_review = var.production_environment_prevent_self_review
  can_admins_bypass   = false

  reviewers {
    teams = var.production_environment_reviewer_team_ids
  }

  deployment_branch_policy {
    protected_branches     = false
    custom_branch_policies = true
  }

  depends_on = [github_team_repository.production_reviewer]
}

resource "github_repository_environment_deployment_policy" "production_main" {
  repository     = var.github_repository
  environment    = github_repository_environment.production.environment
  branch_pattern = "main"
}

data "aws_partition" "current" {}
data "aws_caller_identity" "current" {}

# Site bucket name, TechDocs prefix, and tags.
locals {
  site_bucket_name     = "${var.service_name}-${data.aws_caller_identity.current.account_id}"
  techdocs_bucket_name = var.techdocs_bucket_name != "" ? var.techdocs_bucket_name : "devex-techdocs-${data.aws_caller_identity.current.account_id}"
  techdocs_bucket_arn  = "arn:${data.aws_partition.current.partition}:s3:::${local.techdocs_bucket_name}"
  techdocs_prefix      = "default/component/${var.service_name}/"

  tags = merge(
    {
      ManagedBy = "Terraform"
      Platform  = "DevEx"
      Service   = var.service_name
    },
    var.tags,
  )
}

# Private content bucket plus S3 access-log bucket.
module "site" {
  source = "../../aws/s3"

  name = local.site_bucket_name
  tags = local.tags
}

# CloudFront in front of the content bucket, plus CloudFront logs.
module "cdn" {
  source = "../../aws/cloudfront"

  name                        = var.service_name
  bucket_name                 = module.site.name
  bucket_arn                  = module.site.arn
  bucket_regional_domain_name = module.site.bucket_regional_domain_name
  tags                        = local.tags
}

# Trust only this repo and branch via the account OIDC provider.
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

# Sync the built site and invalidate the distribution.
data "aws_iam_policy_document" "release_site" {
  statement {
    sid       = "ListSiteBucket"
    actions   = ["s3:ListBucket"]
    resources = [module.site.arn]
  }

  statement {
    sid = "PublishSiteObjects"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
    ]
    resources = ["${module.site.arn}/*"]
  }

  statement {
    sid       = "InvalidateCloudFront"
    actions   = ["cloudfront:CreateInvalidation"]
    resources = [module.cdn.arn]
  }
}

resource "aws_iam_role_policy" "release_site" {
  name   = "${var.service_name}-site-release"
  role   = aws_iam_role.release.id
  policy = data.aws_iam_policy_document.release_site.json
}

# Same TechDocs prefix IAM as container services.
data "aws_iam_policy_document" "release_techdocs" {
  statement {
    sid       = "ListServiceTechDocsPrefix"
    actions   = ["s3:ListBucket"]
    resources = [local.techdocs_bucket_arn]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values = [
        local.techdocs_prefix,
        "${local.techdocs_prefix}*",
      ]
    }
  }

  statement {
    sid = "PublishServiceTechDocs"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
    ]
    resources = ["${local.techdocs_bucket_arn}/${local.techdocs_prefix}*"]
  }
}

resource "aws_iam_role_policy" "release_techdocs" {
  name   = "${var.service_name}-techdocs-release"
  role   = aws_iam_role.release.id
  policy = data.aws_iam_policy_document.release_techdocs.json
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

resource "github_actions_variable" "static_site_bucket" {
  repository    = var.github_repository
  variable_name = "STATIC_SITE_BUCKET"
  value         = module.site.name
}

resource "github_actions_variable" "cloudfront_distribution_id" {
  repository    = var.github_repository
  variable_name = "CLOUDFRONT_DISTRIBUTION_ID"
  value         = module.cdn.id
}

resource "github_actions_variable" "techdocs_s3_bucket" {
  repository    = var.github_repository
  variable_name = "TECHDOCS_S3_BUCKET"
  value         = local.techdocs_bucket_name
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

# Account owner ID, used in the CloudFront logs bucket ACL.
data "aws_canonical_user_id" "current" {}

# Shared names, AWS log-delivery ID, and tags.
locals {
  origin_id                           = var.bucket_name
  cf_logs_bucket                      = "${lower(var.name)}-cf-logs"
  aws_logs_delivery_canonical_user_id = "c4c1ede66af53448b93c934b7264043e8e58f318"

  common_tags = merge(
    {
      ManagedBy = "Terraform"
      Platform  = "DevEx"
    },
    var.tags,
  )
}

# AWS managed cache policy for GET/HEAD.
data "aws_cloudfront_cache_policy" "caching_optimized" {
  name = "Managed-CachingOptimized"
}

# CloudFront access-log destination. Must not log to itself.
# NOSONAR
resource "aws_s3_bucket" "cf_logs" { # NOSONAR
  bucket        = local.cf_logs_bucket
  force_destroy = false

  tags = local.common_tags
}

# Keep CloudFront log objects versioned.
resource "aws_s3_bucket_versioning" "cf_logs" {
  bucket = aws_s3_bucket.cf_logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

# AES-256 on CloudFront log objects.
resource "aws_s3_bucket_server_side_encryption_configuration" "cf_logs" {
  bucket = aws_s3_bucket.cf_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# ACLs required so CloudFront can write logs.
resource "aws_s3_bucket_ownership_controls" "cf_logs" {
  bucket = aws_s3_bucket.cf_logs.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# Block public access after the log-delivery ACL is set.
resource "aws_s3_bucket_public_access_block" "cf_logs" {
  bucket = aws_s3_bucket.cf_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  depends_on = [aws_s3_bucket_acl.cf_logs]
}

# Allow this account and AWS log-delivery to write CloudFront logs.
resource "aws_s3_bucket_acl" "cf_logs" {
  bucket = aws_s3_bucket.cf_logs.id

  access_control_policy {
    owner {
      id = data.aws_canonical_user_id.current.id
    }

    grant {
      grantee {
        id   = data.aws_canonical_user_id.current.id
        type = "CanonicalUser"
      }
      permission = "FULL_CONTROL"
    }

    grant {
      grantee {
        id   = local.aws_logs_delivery_canonical_user_id
        type = "CanonicalUser"
      }
      permission = "FULL_CONTROL"
    }
  }

  depends_on = [aws_s3_bucket_ownership_controls.cf_logs]
}

# TLS-only access to the CloudFront logs bucket.
data "aws_iam_policy_document" "cf_logs" {
  statement {
    sid    = "DenyInsecureTransport"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.cf_logs.arn,
      "${aws_s3_bucket.cf_logs.arn}/*",
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

# Attach the TLS-only policy to the CloudFront logs bucket.
resource "aws_s3_bucket_policy" "cf_logs" {
  bucket = aws_s3_bucket.cf_logs.id
  policy = data.aws_iam_policy_document.cf_logs.json

  depends_on = [aws_s3_bucket_acl.cf_logs]
}

# Sign origin requests so the private site bucket can stay closed.
resource "aws_cloudfront_origin_access_control" "this" {
  name                              = var.name
  description                       = var.name
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# CDN in front of the site bucket. Default cert, SPA errors, access logs.
resource "aws_cloudfront_distribution" "this" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = var.name
  default_root_object = "index.html"
  http_version        = "http2"
  price_class         = "PriceClass_100"
  wait_for_deployment = false

  logging_config {
    include_cookies = false
    bucket          = aws_s3_bucket.cf_logs.bucket_domain_name
    prefix          = "cloudfront/"
  }

  origin {
    domain_name              = var.bucket_regional_domain_name
    origin_id                = local.origin_id
    origin_access_control_id = aws_cloudfront_origin_access_control.this.id
  }

  default_cache_behavior {
    target_origin_id       = local.origin_id
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true
    cache_policy_id        = data.aws_cloudfront_cache_policy.caching_optimized.id
  }

  custom_error_response {
    error_code         = 403
    response_code      = 200
    response_page_path = "/index.html"
  }

  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/index.html"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = local.common_tags
}

# Site bucket: TLS-only, plus GetObject for this distribution only.
data "aws_iam_policy_document" "origin" {
  statement {
    sid    = "DenyInsecureTransport"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions   = ["s3:*"]
    resources = [var.bucket_arn, "${var.bucket_arn}/*"]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }

  statement {
    sid    = "AllowCloudFrontRead"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions   = ["s3:GetObject"]
    resources = ["${var.bucket_arn}/*"]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.this.arn]
    }
  }
}

# Replace the site bucket policy with the origin document above.
resource "aws_s3_bucket_policy" "origin" {
  bucket = var.bucket_name
  policy = data.aws_iam_policy_document.origin.json
}

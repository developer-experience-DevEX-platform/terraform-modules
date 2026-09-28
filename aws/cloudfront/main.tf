# Origin ID and shared tags. Legacy CloudFront S3 ACLs are omitted:
# PutBucketAcl rejects the awslogsdelivery canonical ID (Invalid id).
locals {
  origin_id = var.bucket_name

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

# Sign origin requests so the private site bucket can stay closed.
resource "aws_cloudfront_origin_access_control" "this" {
  name                              = var.name
  description                       = var.name
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# CDN in front of the site bucket. Default cert, SPA errors.
# NOSONAR
resource "aws_cloudfront_distribution" "this" { # NOSONAR
  enabled             = true
  is_ipv6_enabled     = true
  comment             = var.name
  default_root_object = "index.html"
  http_version        = "http2"
  price_class         = "PriceClass_100"
  wait_for_deployment = false

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

# Only policy on the origin bucket: TLS-only, plus GetObject for this distribution.
resource "aws_s3_bucket_policy" "origin" {
  bucket = var.bucket_name
  policy = data.aws_iam_policy_document.origin.json
}

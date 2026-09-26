output "site_bucket_name" {
  description = "Content bucket the release role may publish into."
  value       = module.site.name
}

output "site_bucket_arn" {
  description = "Content bucket ARN."
  value       = module.site.arn
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID."
  value       = module.cdn.id
}

output "cloudfront_domain_name" {
  description = "CloudFront domain name."
  value       = module.cdn.domain_name
}

output "release_role_name" {
  description = "IAM release role name."
  value       = aws_iam_role.release.name
}

output "release_role_arn" {
  description = "IAM release role ARN."
  value       = aws_iam_role.release.arn
}

output "techdocs_bucket_name" {
  description = "Shared TechDocs bucket the release role may publish into."
  value       = local.techdocs_bucket_name
}

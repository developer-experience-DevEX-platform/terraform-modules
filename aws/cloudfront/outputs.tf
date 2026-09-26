output "id" {
  description = "ID of the distribution."
  value       = aws_cloudfront_distribution.this.id
}

output "arn" {
  description = "ARN of the distribution."
  value       = aws_cloudfront_distribution.this.arn
}

output "domain_name" {
  description = "CloudFront domain name."
  value       = aws_cloudfront_distribution.this.domain_name
}

output "hosted_zone_id" {
  description = "Route 53 hosted zone ID for the CloudFront domain."
  value       = aws_cloudfront_distribution.this.hosted_zone_id
}

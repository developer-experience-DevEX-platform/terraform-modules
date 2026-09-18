output "ecr_repository_name" {
  description = "ECR repository name."
  value       = module.ecr.name
}

output "ecr_repository_arn" {
  description = "ECR repository ARN."
  value       = module.ecr.arn
}

output "ecr_repository_url" {
  description = "Full ECR repository URL."
  value       = module.ecr.url
}

output "release_role_name" {
  description = "IAM release role name."
  value       = aws_iam_role.release.name
}

output "release_role_arn" {
  description = "IAM release role ARN."
  value       = aws_iam_role.release.arn
}

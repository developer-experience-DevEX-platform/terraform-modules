output "name" {
  description = "Name of the repository."
  value       = aws_ecr_repository.this.name
}

output "arn" {
  description = "ARN of the repository."
  value       = aws_ecr_repository.this.arn
}

output "url" {
  description = "URL of the repository."
  value       = aws_ecr_repository.this.repository_url
}

output "registry_id" {
  description = "Registry ID that hosts the repository."
  value       = aws_ecr_repository.this.registry_id
}

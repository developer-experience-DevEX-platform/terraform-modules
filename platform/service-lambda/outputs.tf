output "lambda_release_role_name" {
  description = "Name of the GitHub OIDC role that publishes Lambda artifacts."
  value       = aws_iam_role.lambda_release.name
}

output "lambda_release_role_arn" {
  description = "ARN of the GitHub OIDC role that publishes Lambda artifacts."
  value       = aws_iam_role.lambda_release.arn
}

output "lambda_artifact_bucket_name" {
  description = "Name of the shared Lambda artifact bucket."
  value       = var.lambda_artifact_bucket_name
}

output "lambda_artifact_prefix" {
  description = "S3 prefix reserved for this service."
  value       = local.artifact_prefix
}

output "staging_function_name" {
  description = "Name of the staging Lambda function."
  value       = module.staging_lambda.function_name
}

output "staging_function_arn" {
  description = "ARN of the staging Lambda function."
  value       = module.staging_lambda.function_arn
}

output "staging_execution_role_arn" {
  description = "ARN of the staging Lambda runtime execution role."
  value       = aws_iam_role.lambda_execution.arn
}

output "staging_deploy_role_arn" {
  description = "ARN of the GitHub OIDC role for future staging code deployment."
  value       = aws_iam_role.staging_deploy.arn
}

output "staging_log_group_name" {
  description = "Name of the staging Lambda CloudWatch log group."
  value       = module.staging_lambda.log_group_name
}

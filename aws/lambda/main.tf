resource "aws_cloudwatch_log_group" "function" {
  name              = "/aws/lambda/${var.function_name}"
  retention_in_days = var.log_retention_days
  tags              = var.tags
}

resource "aws_lambda_function" "function" {
  function_name = var.function_name
  description   = var.description
  role          = var.execution_role_arn
  package_type  = "Zip"
  runtime       = var.runtime
  handler       = var.handler
  architectures = [var.architecture]
  memory_size   = var.memory_size
  timeout       = var.timeout
  s3_bucket     = var.artifact_bucket_name
  s3_key        = var.initial_artifact_key
  tags          = var.tags

  lifecycle {
    ignore_changes = [
      s3_bucket,
      s3_key,
      s3_object_version,
    ]
  }
}

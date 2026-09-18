output "id" {
  description = "ID of the bucket."
  value       = aws_s3_bucket.this.id
}

output "arn" {
  description = "ARN of the bucket."
  value       = aws_s3_bucket.this.arn
}

output "name" {
  description = "Name of the bucket."
  value       = aws_s3_bucket.this.bucket
}

variable "name" {
  description = "Name used for the origin access control and tags."
  type        = string

  validation {
    condition     = length(var.name) >= 1 && length(var.name) <= 55
    error_message = "name must be between 1 and 55 characters so the CloudFront logs bucket name fits."
  }
}

variable "bucket_name" {
  description = "Name of the private origin bucket created by aws/s3."
  type        = string
}

variable "bucket_arn" {
  description = "ARN of the private origin bucket created by aws/s3."
  type        = string
}

variable "bucket_regional_domain_name" {
  description = "Regional domain name of the origin bucket."
  type        = string
}

variable "tags" {
  description = "Additional tags applied to the distribution."
  type        = map(string)
  default     = {}
}

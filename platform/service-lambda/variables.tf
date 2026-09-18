variable "service_name" {
  description = "Platform service name and S3 artifact prefix."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]+(?:-[a-z0-9]+)*$", var.service_name))
    error_message = "service_name must use lowercase kebab-case."
  }
}

variable "github_owner" {
  description = "GitHub organization that owns the service repository."
  type        = string
}

variable "github_owner_id" {
  description = "Immutable numeric GitHub organization ID."
  type        = string

  validation {
    condition     = can(regex("^[0-9]+$", var.github_owner_id))
    error_message = "github_owner_id must contain only digits."
  }
}

variable "github_repository" {
  description = "GitHub service repository allowed to publish Lambda artifacts."
  type        = string
}

variable "github_repository_id" {
  description = "Immutable numeric GitHub repository ID."
  type        = string

  validation {
    condition     = can(regex("^[0-9]+$", var.github_repository_id))
    error_message = "github_repository_id must contain only digits."
  }
}

variable "github_branch" {
  description = "Branch allowed to publish Lambda release artifacts."
  type        = string
  default     = "main"
}

variable "github_oidc_provider_arn" {
  description = "ARN of the existing account-level GitHub Actions OIDC provider."
  type        = string
}

variable "aws_region" {
  description = "AWS region used by Lambda release workflows."
  type        = string
}

variable "lambda_artifact_bucket_name" {
  description = "Name of the shared platform-owned Lambda artifact bucket."
  type        = string
}

variable "initial_artifact_key" {
  description = "Immutable S3 key used only to create the initial staging Lambda function."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]+(?:-[a-z0-9]+)*/[0-9a-f]{40}/function\\.zip$", var.initial_artifact_key)) && startswith(var.initial_artifact_key, "${var.service_name}/")
    error_message = "initial_artifact_key must be <service_name>/<40-character-lowercase-git-sha>/function.zip."
  }
}

variable "staging_runtime" {
  description = "Lambda runtime for the staging function."
  type        = string
  default     = "nodejs24.x"
}

variable "staging_handler" {
  description = "Handler exported by the staged Lambda package."
  type        = string
  default     = "dist/handler.handler"
}

variable "staging_memory_size" {
  description = "Memory allocated to the staging Lambda function in MB."
  type        = number
  default     = 256

  validation {
    condition     = var.staging_memory_size >= 128 && var.staging_memory_size <= 10240
    error_message = "staging_memory_size must be between 128 and 10240 MB."
  }
}

variable "staging_timeout" {
  description = "Staging Lambda function timeout in seconds."
  type        = number
  default     = 10

  validation {
    condition     = var.staging_timeout >= 1 && var.staging_timeout <= 900
    error_message = "staging_timeout must be between 1 and 900 seconds."
  }
}

variable "staging_log_retention_days" {
  description = "CloudWatch Logs retention period for the staging Lambda function."
  type        = number
  default     = 30
}

variable "tags" {
  description = "Additional tags for service-owned IAM resources."
  type        = map(string)
  default     = {}
}

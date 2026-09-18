variable "function_name" {
  description = "Name of the Lambda function."
  type        = string
}

variable "description" {
  description = "Description of the Lambda function."
  type        = string
  default     = null
}

variable "execution_role_arn" {
  description = "ARN of the IAM role assumed by the Lambda runtime."
  type        = string
}

variable "artifact_bucket_name" {
  description = "S3 bucket containing the initial immutable deployment package."
  type        = string
}

variable "initial_artifact_key" {
  description = "Immutable S3 key used only for initial function creation."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]+(?:-[a-z0-9]+)*/[0-9a-f]{40}/function\\.zip$", var.initial_artifact_key))
    error_message = "initial_artifact_key must be <service>/<40-character-lowercase-git-sha>/function.zip."
  }
}

variable "runtime" {
  description = "Lambda runtime identifier."
  type        = string
}

variable "handler" {
  description = "Lambda function entrypoint."
  type        = string
}

variable "architecture" {
  description = "Lambda instruction-set architecture."
  type        = string

  validation {
    condition     = contains(["x86_64", "arm64"], var.architecture)
    error_message = "architecture must be x86_64 or arm64."
  }
}

variable "memory_size" {
  description = "Memory allocated to the Lambda function in MB."
  type        = number

  validation {
    condition     = var.memory_size >= 128 && var.memory_size <= 10240
    error_message = "memory_size must be between 128 and 10240 MB."
  }
}

variable "timeout" {
  description = "Lambda function timeout in seconds."
  type        = number

  validation {
    condition     = var.timeout >= 1 && var.timeout <= 900
    error_message = "timeout must be between 1 and 900 seconds."
  }
}

variable "log_retention_days" {
  description = "CloudWatch Logs retention period."
  type        = number
}

variable "tags" {
  description = "Tags applied to the Lambda function and log group."
  type        = map(string)
  default     = {}
}

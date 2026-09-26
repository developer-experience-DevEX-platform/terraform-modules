variable "name" {
  description = "Globally unique S3 bucket name."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9.-]{1,56}[a-z0-9]$", var.name))
    error_message = "name must be a valid S3 bucket name at most 58 characters so the logs bucket name fits."
  }
}

variable "tags" {
  description = "Additional tags applied to the bucket."
  type        = map(string)
  default     = {}
}

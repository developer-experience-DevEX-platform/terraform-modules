variable "name" {
  description = "ECR repository name."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]+(?:[._-][a-z0-9]+)*$", var.name)) && length(var.name) >= 2 && length(var.name) <= 256
    error_message = "name must be a valid ECR repository name."
  }
}

variable "tags" {
  description = "Additional tags applied to the repository."
  type        = map(string)
  default     = {}
}

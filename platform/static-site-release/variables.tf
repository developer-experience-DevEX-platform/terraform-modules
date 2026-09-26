variable "service_name" {
  description = "Platform website name."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]+(?:-[a-z0-9]+)*$", var.service_name)) && length(var.service_name) <= 45
    error_message = "service_name must use lowercase kebab-case and be at most 45 characters so the site bucket name fits."
  }
}

variable "github_owner" {
  description = "GitHub organization that owns the service repository."
  type        = string
}

variable "github_owner_id" {
  description = "Immutable numeric GitHub owner/organization ID."
  type        = string

  validation {
    condition     = can(regex("^[0-9]+$", var.github_owner_id))
    error_message = "github_owner_id must contain only digits."
  }
}

variable "github_repository" {
  description = "GitHub repository allowed to assume the release role."
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
  description = "Branch allowed to publish the static site."
  type        = string
  default     = "main"
}

variable "production_environment_reviewer_team_ids" {
  description = "GitHub team IDs allowed to approve deployments to the production environment."
  type        = set(number)
  default     = [19182366]

  validation {
    condition     = length(var.production_environment_reviewer_team_ids) >= 1 && length(var.production_environment_reviewer_team_ids) <= 6
    error_message = "production_environment_reviewer_team_ids must contain between one and six GitHub team IDs."
  }
}

variable "production_environment_prevent_self_review" {
  description = "Whether the deployment requester is prevented from approving their own production deployment."
  type        = bool
  default     = false
}

variable "github_oidc_provider_arn" {
  description = "Existing account-level GitHub Actions OIDC provider ARN. The module does not create an OIDC provider per service."
  type        = string
}

variable "aws_region" {
  description = "AWS region containing the site bucket."
  type        = string
}

variable "techdocs_bucket_name" {
  description = "Shared TechDocs bucket from account bootstrap. An empty value uses devex-techdocs-<account-id>."
  type        = string
  default     = ""

  validation {
    condition     = var.techdocs_bucket_name == "" || can(regex("^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$", var.techdocs_bucket_name))
    error_message = "techdocs_bucket_name must be empty or a valid S3 bucket name."
  }
}

variable "tags" {
  description = "Additional AWS resource tags."
  type        = map(string)
  default     = {}
}

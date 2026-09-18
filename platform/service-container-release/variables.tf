variable "service_name" {
  description = "Platform service name."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]+(?:-[a-z0-9]+)*$", var.service_name))
    error_message = "service_name must use lowercase kebab-case, for example catalog-api."
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
  description = "Branch allowed to perform container releases."
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
  description = "AWS region containing the service ECR repository."
  type        = string
}

variable "ecr_repository_name" {
  description = "Optional ECR repository name override. An empty value uses service_name."
  type        = string
  default     = ""
}

variable "ecr_image_tag_mutability" {
  description = "Tag mutability setting for the ECR repository."
  type        = string
  default     = "IMMUTABLE"

  validation {
    condition     = contains(["IMMUTABLE", "MUTABLE"], var.ecr_image_tag_mutability)
    error_message = "ecr_image_tag_mutability must be either IMMUTABLE or MUTABLE."
  }
}

variable "ecr_scan_on_push" {
  description = "Whether ECR scans images when they are pushed."
  type        = bool
  default     = true
}

variable "force_delete_ecr_repository" {
  description = "Whether Terraform may delete a non-empty ECR repository."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Additional AWS resource tags."
  type        = map(string)
  default     = {}
}

variable "cluster_name" {
  description = "Name of the EKS cluster and prefix for related resources."
  type        = string

  validation {
    condition     = can(regex("^[0-9A-Za-z][0-9A-Za-z_-]*$", var.cluster_name)) && length(var.cluster_name) <= 75
    error_message = "cluster_name must be 1-75 characters and contain only letters, numbers, hyphens, and underscores."
  }
}

variable "kubernetes_version" {
  description = "Kubernetes version for the EKS control plane."
  type        = string

  validation {
    condition     = can(regex("^[0-9]+\\.[0-9]+$", var.kubernetes_version))
    error_message = "kubernetes_version must use major.minor format, for example 1.36."
  }
}

variable "vpc_id" {
  description = "ID of the VPC containing the EKS cluster."
  type        = string

  validation {
    condition     = can(regex("^vpc-[0-9a-f]+$", var.vpc_id))
    error_message = "vpc_id must be a valid VPC ID."
  }
}

variable "private_subnet_ids" {
  description = "Private subnet IDs used by the control plane and managed node group."
  type        = list(string)

  validation {
    condition     = length(var.private_subnet_ids) >= 2 && length(distinct(var.private_subnet_ids)) == length(var.private_subnet_ids) && alltrue([for id in var.private_subnet_ids : can(regex("^subnet-[0-9a-f]+$", id))])
    error_message = "private_subnet_ids must contain at least two unique subnet IDs."
  }
}

variable "endpoint_private_access" {
  description = "Whether the EKS private API endpoint is enabled."
  type        = bool
  default     = true
}

variable "endpoint_public_access" {
  description = "Whether the EKS public API endpoint is enabled."
  type        = bool
  default     = false
}

variable "public_access_cidrs" {
  description = "IPv4 CIDRs allowed to access the public EKS API endpoint."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for cidr in var.public_access_cidrs : can(cidrnetmask(cidr))])
    error_message = "public_access_cidrs must contain valid IPv4 CIDR blocks."
  }
}

variable "node_instance_types" {
  description = "EC2 instance types used by the managed node group."
  type        = list(string)

  validation {
    condition     = length(var.node_instance_types) > 0 && alltrue([for instance_type in var.node_instance_types : length(trimspace(instance_type)) > 0])
    error_message = "node_instance_types must contain at least one instance type."
  }
}

variable "node_capacity_type" {
  description = "Capacity type for the managed node group."
  type        = string
  default     = "ON_DEMAND"

  validation {
    condition     = contains(["ON_DEMAND", "SPOT", "CAPACITY_BLOCK"], var.node_capacity_type)
    error_message = "node_capacity_type must be ON_DEMAND, SPOT, or CAPACITY_BLOCK."
  }
}

variable "node_min_size" {
  description = "Minimum number of managed nodes."
  type        = number

  validation {
    condition     = var.node_min_size >= 0
    error_message = "node_min_size must be zero or greater."
  }
}

variable "node_desired_size" {
  description = "Desired number of managed nodes."
  type        = number

  validation {
    condition     = var.node_desired_size >= 0
    error_message = "node_desired_size must be zero or greater."
  }
}

variable "node_max_size" {
  description = "Maximum number of managed nodes."
  type        = number

  validation {
    condition     = var.node_max_size >= 1
    error_message = "node_max_size must be one or greater."
  }
}

variable "node_disk_size" {
  description = "Managed-node root volume size in GiB."
  type        = number
  default     = 30

  validation {
    condition     = var.node_disk_size >= 20
    error_message = "node_disk_size must be at least 20 GiB."
  }
}

variable "enabled_cluster_log_types" {
  description = "EKS control-plane log types enabled in CloudWatch Logs."
  type        = list(string)
  default = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler",
  ]

  validation {
    condition     = alltrue([for log_type in var.enabled_cluster_log_types : contains(["api", "audit", "authenticator", "controllerManager", "scheduler"], log_type)])
    error_message = "enabled_cluster_log_types contains an unsupported EKS control-plane log type."
  }
}

variable "tags" {
  description = "Additional tags applied to all supported resources."
  type        = map(string)
  default     = {}
}

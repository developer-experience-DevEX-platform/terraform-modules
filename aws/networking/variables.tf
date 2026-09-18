variable "name" {
  description = "Name prefix applied to networking resources."
  type        = string

  validation {
    condition     = length(trimspace(var.name)) > 0
    error_message = "name must not be empty."
  }
}

variable "vpc_cidr" {
  description = "IPv4 CIDR block for the VPC."
  type        = string

  validation {
    condition     = can(cidrnetmask(var.vpc_cidr))
    error_message = "vpc_cidr must be a valid IPv4 CIDR block."
  }
}

variable "availability_zones" {
  description = "Availability zones used for public and private subnets."
  type        = list(string)

  validation {
    condition     = length(var.availability_zones) >= 2 && length(distinct(var.availability_zones)) == length(var.availability_zones)
    error_message = "availability_zones must contain at least two unique availability zones."
  }
}

variable "public_subnet_cidrs" {
  description = "Public subnet IPv4 CIDRs, ordered to match availability_zones."
  type        = list(string)

  validation {
    condition     = length(var.public_subnet_cidrs) == length(var.availability_zones) && alltrue([for cidr in var.public_subnet_cidrs : can(cidrnetmask(cidr))])
    error_message = "public_subnet_cidrs must contain one valid IPv4 CIDR for every availability zone."
  }
}

variable "private_subnet_cidrs" {
  description = "Private subnet IPv4 CIDRs, ordered to match availability_zones."
  type        = list(string)

  validation {
    condition     = length(var.private_subnet_cidrs) == length(var.availability_zones) && alltrue([for cidr in var.private_subnet_cidrs : can(cidrnetmask(cidr))])
    error_message = "private_subnet_cidrs must contain one valid IPv4 CIDR for every availability zone."
  }
}

variable "nat_gateway_mode" {
  description = "NAT gateway topology: one shared gateway or one gateway per availability zone."
  type        = string

  validation {
    condition     = contains(["single", "one_per_az"], var.nat_gateway_mode)
    error_message = "nat_gateway_mode must be either single or one_per_az."
  }
}

variable "tags" {
  description = "Additional tags applied to all resources."
  type        = map(string)
  default     = {}
}

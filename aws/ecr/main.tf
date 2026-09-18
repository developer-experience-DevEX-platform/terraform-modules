locals {
  common_tags = merge(
    {
      ManagedBy = "Terraform"
      Platform  = "DevEx"
    },
    var.tags,
  )
}

resource "aws_ecr_repository" "this" {
  name                 = var.name
  image_tag_mutability = "IMMUTABLE"
  force_delete         = false

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = local.common_tags
}

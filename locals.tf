locals {
  name_prefix = "${var.name}-${var.environment}"
  selected_public_subnet_ids = slice(sort(data.aws_subnets.public.ids), 0, 3)
  has_private_subnets = length(data.aws_subnets.private.ids) > 0
  selected_private_subnet_ids = local.has_private_subnets ? slice(sort(data.aws_subnets.private.ids), 0, min(3, length(data.aws_subnets.private.ids))) : []
  selected_workload_subnet_ids = local.has_private_subnets ? local.selected_private_subnet_ids : local.selected_public_subnet_ids
  workload_associate_public_ip = local.has_private_subnets ? false : true
  common_tags = {
    Project       = var.name
    Environment   = var.environment
    Purpose       = "SimPayForge-Payment-POC"
    ManagedBy     = "Terraform"
    AuditDate     = "2026-03-17"
    Owner         = "Dmytro Grendach"
  }
}

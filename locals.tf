locals {
  name_prefix = "${var.name}-${var.environment}"

  # VPC selection: default or custom
  vpc_id = var.use_default_vpc ? data.aws_vpc.default[0].id : aws_vpc.custom[0].id

  # Subnet selection based on VPC mode
  public_subnet_ids = var.use_default_vpc ? data.aws_subnets.public[0].ids : aws_subnet.public[*].id
  private_subnet_ids = var.use_default_vpc ? data.aws_subnets.private[0].ids : aws_subnet.private[*].id

  selected_public_subnet_ids = var.use_default_vpc ? slice(sort(local.public_subnet_ids), 0, 3) : aws_subnet.public[*].id

  has_private_subnets = length(local.private_subnet_ids) > 0
  selected_private_subnet_ids = local.has_private_subnets ? slice(sort(local.private_subnet_ids), 0, min(3, length(local.private_subnet_ids))) : []
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

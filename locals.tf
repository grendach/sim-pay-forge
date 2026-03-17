locals {
  name_prefix = "${var.name}-${var.environment}"
  common_tags = {
    Project       = var.name
    Environment   = var.environment
    Purpose       = "SimPayForge-Payment-POC"
    ManagedBy     = "Terraform"
    AuditDate     = "2026-03-17"
    Owner         = "Dmytro Grendach"
  }
}

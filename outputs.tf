# ========================================
# INFRASTRUCTURE ENDPOINTS
# ========================================

output "alb_dns_name" {
  description = "ALB HTTPS endpoint - your payment provider URL"
  value       = module.alb.alb_dns_name
}

output "alb_https_url" {
  description = "Ready-to-use HTTPS URL"
  value       = "https://${module.alb.alb_dns_name}"
}

# ========================================
# NETWORKING (VPC & SUBNETS)
# ========================================

output "vpc_id" {
  description = "VPC ID (either default or custom)"
  value       = local.vpc_id
}

output "alb_subnet_ids" {
  description = "Three selected public subnets used by ALB"
  value       = local.selected_public_subnet_ids
}

output "workload_subnet_ids" {
  description = "Effective subnets used by app ASG and DB EC2 (private preferred, public fallback)"
  value       = local.selected_workload_subnet_ids
}

output "workload_network_mode" {
  description = "Whether workloads are deployed into private subnets or fallback public subnets"
  value       = local.has_private_subnets ? "private" : "public-fallback"
}

# ========================================
# SECURITY
# ========================================

output "alb_sg_id" {
  description = "ALB Security Group ID"
  value       = module.security.alb_sg_id
}

output "app_sg_id" {
  description = "App Security Group ID"
  value       = module.security.app_sg_id
}

output "db_sg_id" {
  description = "DB Security Group ID"
  value       = module.security.db_sg_id
}

# ========================================
# ACM CERTIFICATE
# ========================================

output "certificate_arn" {
  description = "ACM Certificate ARN (auto-created)"
  value       = module.acm_certificate.certificate_arn
}

output "certificate_validation_records" {
  description = "DNS validation records (if DNS method)"
  value       = try(module.acm_certificate.validation_records, {})
}

# ========================================
# COMPUTE
# ========================================

output "app_asg_name" {
  description = "ASG name"
  value       = module.app_asg.asg_name
}

output "db_instance_id" {
  description = "Database EC2 instance ID"
  value       = module.db_ec2.db_instance_id
}

output "db_private_ip" {
  description = "Database EC2 private IP"
  value       = module.db_ec2.db_private_ip
}

# ========================================
# AUDIT / SUMMARY
# ========================================

output "deployed_resources_summary" {
  description = "Summary of deployed resources"
  value = {
    vpc             = 1
    alb_subnets     = length(local.selected_public_subnet_ids)
    workload_subnets = length(local.selected_workload_subnet_ids)
    alb             = 1
    asg             = 1
    db_instance     = 1
    security_groups = 3
    certificate     = 1
  }
}

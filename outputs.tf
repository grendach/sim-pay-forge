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
# NETWORKING (DEFAULT VPC)
# ========================================

output "vpc_id" {
  description = "Default VPC ID"
  value       = data.aws_vpc.default.id
}

output "subnet_ids" {
  description = "Subnets used (ALB + ASG + DB)"
  value       = data.aws_subnets.public.ids
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

output "db_asg_name" {
  description = "Database ASG name"
  value       = module.db_asg.db_asg_name
}

# ========================================
# AUDIT / SUMMARY
# ========================================

output "deployed_resources_summary" {
  description = "Summary of deployed resources"
  value = {
    vpc             = 1
    subnets_total   = length(data.aws_subnets.public.ids)
    alb             = 1
    asg             = 1
    db_instance     = 1
    security_groups = 3
    certificate     = 1
  }
}

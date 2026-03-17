# Infrastructure endpoints
output "alb_dns_name" {
  description = "ALB HTTPS endpoint - your payment provider URL"
  value       = module.alb.alb_dns_name
}

output "alb_https_url" {
  description = "Ready-to-use HTTPS URL"
  value       = "https://${module.alb.alb_dns_name}"
}

# Networking
output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs (ALB)"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs (App/DB)"
  value       = module.vpc.private_subnet_ids
}

# Security
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

# ACM Certificate
output "certificate_arn" {
  description = "ACM Certificate ARN (auto-created)"
  value       = module.acm_certificate.certificate_arn
}

output "certificate_validation_records" {
  description = "DNS validation records (if DNS method)"
  value       = module.acm_certificate.validation_records
}

# Compute
output "app_asg_name" {
  description = "ASG name"
  value       = module.app_asg.asg_name
}

output "db_instance_id" {
  description = "Database instance ID"
  value       = module.db_ec2.db_instance_id
}

# Audit summary
output "deployed_resources_summary" {
  description = "Audit-ready resource count"
  value = {
    vpc              = 1
    subnets_public   = length(module.vpc.public_subnet_ids)
    subnets_private  = length(module.vpc.private_subnet_ids)
    alb              = 1
    asg              = 1
    db_instance      = 1
    security_groups  = 3
    certificate      = 1
  }
}

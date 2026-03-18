# Data sources
data "aws_availability_zones" "available" {
  state = "available"
}

# VPC module
module "vpc" {
  source               = "./modules/vpc"
  name                 = local.name_prefix
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
}

# Security groups module
module "security" {
  source               = "./modules/security"
  name                 = local.name_prefix
  vpc_id               = module.vpc.vpc_id
  app_port             = var.app_port
  db_port              = var.db_port
  allowed_client_cidrs = var.allowed_client_cidrs
}

# ACM certificate (DNS validation optional)
module "acm_certificate" {
  source                      = "./modules/acm-certificate"
  name                        = local.name_prefix
  domain_name                 = var.certificate_domain_name
  subject_alternative_names   = var.certificate_sans
  validation_method           = var.certificate_validation_method
  create_validation_records   = var.create_dns_validation_records
  route53_zone_id             = var.route53_zone_id
  wait_for_validation         = true
}

# ALB module
module "alb" {
  source             = "./modules/alb"
  name               = local.name_prefix
  vpc_id             = module.vpc.vpc_id
  public_subnet_ids  = module.vpc.public_subnet_ids
  alb_sg_id          = module.security.alb_sg_id
  target_group_port  = var.app_port
  certificate_arn    = module.acm_certificate.certificate_arn
  environment        = var.environment
}

# App ASG
module "app_asg" {
  source             = "./modules/app-asg"
  name               = local.name_prefix
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  app_sg_id          = module.security.app_sg_id
  instance_type      = var.app_instance_type
  alb_tg_arn         = module.alb.target_group_arn
  app_port           = var.app_port
}

# Database EC2
module "db_ec2" {
  source        = "./modules/db-ec2"
  name          = local.name_prefix
  subnet_id     = module.vpc.private_subnet_ids[0]
  db_sg_id      = module.security.db_sg_id
  db_ami_id     = var.db_ami_id
  instance_type = var.db_instance_type
}

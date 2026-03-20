# ========================================
# DATA SOURCES (DEFAULT VPC)
# ========================================

data "aws_availability_zones" "available" {
  state = "available"
}

# Default VPC
data "aws_vpc" "default" {
  default = true
}

# Only PUBLIC subnets (important!)
data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }

  filter {
    name   = "map-public-ip-on-launch"
    values = ["true"]
  }
}

# ========================================
# SECURITY GROUPS
# ========================================

module "security" {
  source               = "./modules/security"
  name                 = local.name_prefix
  vpc_id               = data.aws_vpc.default.id
  app_port             = var.app_port
  db_port              = var.db_port
  allowed_client_cidrs = var.allowed_client_cidrs
}

# ========================================
# ACM CERTIFICATE
# ========================================

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

# ========================================
# APPLICATION LOAD BALANCER (PUBLIC)
# ========================================

module "alb" {
  source             = "./modules/alb"
  name               = local.name_prefix
  vpc_id             = data.aws_vpc.default.id
  public_subnet_ids  = data.aws_subnets.public.ids
  alb_sg_id          = module.security.alb_sg_id
  target_group_port  = var.app_port
  certificate_arn    = module.acm_certificate.certificate_arn
  environment        = var.environment
}

# ========================================
# APPLICATION ASG (NGINX APP)
# ========================================

module "app_asg" {
  source             = "./modules/app-asg"
  name               = local.name_prefix
  vpc_id             = data.aws_vpc.default.id

  # For POC → use public subnets (ensures internet access)
  private_subnet_ids = data.aws_subnets.public.ids

  app_sg_id          = module.security.app_sg_id
  instance_type      = var.app_instance_type
  alb_tg_arn         = module.alb.target_group_arn
  app_port           = var.app_port
}

# ========================================
# DATABASE EC2 (MYSQL)
# ========================================

module "db_ec2" {
  source        = "./modules/db-ec2"
  name          = local.name_prefix
  subnet_id     = data.aws_subnets.public.ids[0]

  db_sg_id      = module.security.db_sg_id
  instance_type = var.db_instance_type
  db_ami_id     =  var.db_ami_id
  mysql_root_password = var.mysql_root_password
}

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

# Private subnets in default VPC, if any exist.
data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }

  filter {
    name   = "map-public-ip-on-launch"
    values = ["false"]
  }
}

check "default_vpc_has_at_least_three_public_subnets" {
  assert {
    condition     = length(data.aws_subnets.public.ids) >= 3
    error_message = "Default VPC must have at least 3 public subnets for this POC."
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
  public_subnet_ids  = local.selected_public_subnet_ids
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

  # Prefer private subnets for workloads; fallback to selected public subnets when default VPC has none.
  private_subnet_ids  = local.selected_workload_subnet_ids
  associate_public_ip = local.workload_associate_public_ip

  app_sg_id          = module.security.app_sg_id
  instance_type      = var.app_instance_type
  alb_tg_arn         = module.alb.target_group_arn
  app_port           = var.app_port
  required_package_repo_baseurl = var.required_package_repo_baseurl
  required_package_name         = var.required_package_name
}

# ========================================
# DATABASE EC2 (MYSQL)
# ========================================

module "db_ec2" {
  source        = "./modules/db-ec2"
  name          = local.name_prefix
  subnet_id     = local.selected_workload_subnet_ids[0]
  associate_public_ip = local.workload_associate_public_ip

  db_sg_id      = module.security.db_sg_id
  instance_type = var.db_instance_type
  db_ami_id     =  var.db_ami_id
  mysql_root_password = var.mysql_root_password
}

# ========================================
# DATA SOURCES & RESOURCES (VPC)
# ========================================

data "aws_availability_zones" "available" {
  state = "available"
}

# ========================================
# DEFAULT VPC (used when use_default_vpc = true)
# ========================================

data "aws_vpc" "default" {
  count   = var.use_default_vpc ? 1 : 0
  default = true
}

# Only PUBLIC subnets in default VPC
data "aws_subnets" "public" {
  count = var.use_default_vpc ? 1 : 0
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default[0].id]
  }

  filter {
    name   = "map-public-ip-on-launch"
    values = ["true"]
  }
}

# Private subnets in default VPC, if any exist.
data "aws_subnets" "private" {
  count = var.use_default_vpc ? 1 : 0
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default[0].id]
  }

  filter {
    name   = "map-public-ip-on-launch"
    values = ["false"]
  }
}

check "default_vpc_has_at_least_three_public_subnets" {
  assert {
    condition     = var.use_default_vpc ? try(length(data.aws_subnets.public[0].ids), 0) >= 3 : true
    error_message = "Default VPC must have at least 3 public subnets for this POC."
  }
}

# ========================================
# CUSTOM VPC (used when use_default_vpc = false)
# ========================================

resource "aws_vpc" "custom" {
  count                = var.use_default_vpc ? 0 : 1
  cidr_block           = var.custom_vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(
    local.common_tags,
    { Name = "${local.name_prefix}-vpc" }
  )
}

resource "aws_internet_gateway" "custom" {
  count  = var.use_default_vpc ? 0 : 1
  vpc_id = aws_vpc.custom[0].id

  tags = merge(
    local.common_tags,
    { Name = "${local.name_prefix}-igw" }
  )
}

# 3 Public subnets for custom VPC
resource "aws_subnet" "public" {
  count                   = var.use_default_vpc ? 0 : 3
  vpc_id                  = aws_vpc.custom[0].id
  cidr_block              = "10.0.${count.index + 1}.0/24"
  availability_zone       = data.aws_availability_zones.available.names[count.index % length(data.aws_availability_zones.available.names)]
  map_public_ip_on_launch = true

  tags = merge(
    local.common_tags,
    { Name = "${local.name_prefix}-public-subnet-${count.index + 1}" }
  )
}

# Route table for public subnets
resource "aws_route_table" "public" {
  count  = var.use_default_vpc ? 0 : 1
  vpc_id = aws_vpc.custom[0].id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.custom[0].id
  }

  tags = merge(
    local.common_tags,
    { Name = "${local.name_prefix}-public-rt" }
  )
}

resource "aws_route_table_association" "public" {
  count          = var.use_default_vpc ? 0 : 3
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public[0].id
}

# NAT for private subnet egress in custom VPC mode
resource "aws_eip" "nat" {
  count  = var.use_default_vpc ? 0 : 1
  domain = "vpc"

  tags = merge(
    local.common_tags,
    { Name = "${local.name_prefix}-nat-eip" }
  )
}

resource "aws_nat_gateway" "custom" {
  count         = var.use_default_vpc ? 0 : 1
  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public[0].id
  depends_on    = [aws_internet_gateway.custom]

  tags = merge(
    local.common_tags,
    { Name = "${local.name_prefix}-nat" }
  )
}

# 3 Private subnets for custom VPC
resource "aws_subnet" "private" {
  count                   = var.use_default_vpc ? 0 : 3
  vpc_id                  = aws_vpc.custom[0].id
  cidr_block              = "10.0.${count.index + 101}.0/24"
  availability_zone       = data.aws_availability_zones.available.names[count.index % length(data.aws_availability_zones.available.names)]
  map_public_ip_on_launch = false

  tags = merge(
    local.common_tags,
    { Name = "${local.name_prefix}-private-subnet-${count.index + 1}" }
  )
}

# Route table for private subnets (no IGW route)
resource "aws_route_table" "private" {
  count  = var.use_default_vpc ? 0 : 1
  vpc_id = aws_vpc.custom[0].id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.custom[0].id
  }

  tags = merge(
    local.common_tags,
    { Name = "${local.name_prefix}-private-rt" }
  )
}

resource "aws_route_table_association" "private" {
  count          = var.use_default_vpc ? 0 : 3
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[0].id
}

# ========================================
# SECURITY GROUPS
# ========================================

module "security" {
  source               = "./modules/security"
  name                 = local.name_prefix
  vpc_id               = local.vpc_id
  app_port             = var.app_port
  db_port              = var.db_port
  allowed_client_cidrs = var.allowed_client_cidrs
}

# ========================================
# ACM CERTIFICATE
# ========================================

module "acm_certificate" {
  source                    = "./modules/acm-certificate"
  name                      = local.name_prefix
  domain_name               = var.certificate_domain_name
  subject_alternative_names = var.certificate_sans
  validation_method         = var.certificate_validation_method
  create_validation_records = var.create_dns_validation_records
  route53_zone_id           = var.route53_zone_id
  wait_for_validation       = true
}

# ========================================
# APPLICATION LOAD BALANCER (PUBLIC)
# ========================================

module "alb" {
  source            = "./modules/alb"
  name              = local.name_prefix
  vpc_id            = local.vpc_id
  public_subnet_ids = local.selected_public_subnet_ids
  alb_sg_id         = module.security.alb_sg_id
  target_group_port = var.app_port
  certificate_arn   = module.acm_certificate.certificate_arn
  environment       = var.environment
}

# ========================================
# APPLICATION ASG (NGINX APP)
# ========================================

module "app_asg" {
  source = "./modules/app-asg"
  name   = local.name_prefix
  vpc_id = local.vpc_id

  # Prefer private subnets for workloads; fallback to selected public subnets when default VPC has none.
  private_subnet_ids  = local.selected_workload_subnet_ids
  associate_public_ip = local.workload_associate_public_ip

  app_sg_id                     = module.security.app_sg_id
  instance_type                 = var.app_instance_type
  alb_tg_arn                    = module.alb.target_group_arn
  app_port                      = var.app_port
  required_package_repo_baseurl = var.required_package_repo_baseurl
  required_package_name         = var.required_package_name
}

# ========================================
# DATABASE EC2 (MYSQL)
# ========================================

module "db_ec2" {
  source              = "./modules/db-ec2"
  name                = local.name_prefix
  subnet_id           = local.selected_workload_subnet_ids[0]
  associate_public_ip = local.workload_associate_public_ip

  db_sg_id            = module.security.db_sg_id
  instance_type       = var.db_instance_type
  db_ami_id           = var.db_ami_id
  mysql_root_password = var.mysql_root_password
}

name            = "sim-pay-forge"
environment     = "dev"
region          = "eu-central-1"
use_default_vpc = true

# Default open ingress for POC. Multiple CIDR blocks are supported here.
allowed_client_cidrs = [
  "0.0.0.0/0",
  # "185.72.187.163/32",
]

# AMIs
# Leave db_ami_id unset to use the latest Amazon Linux 2023 AMI from AWS SSM for the selected region.
mysql_root_password = "ChangeMe123!"

# Sizing
app_instance_type = "t3.micro"
db_instance_type  = "t3.micro"

# ACM Certificate (manual DNS validation)
certificate_validation_method = "DNS"
create_dns_validation_records = false
certificate_domain_name       = "altm-dev.grendach.dev"
certificate_sans              = ["*.altm-dev.grendach.dev"]

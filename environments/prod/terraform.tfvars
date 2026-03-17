# ========================================
# sim-pay-forge PROD Environment (AUDIT-READY)
# ========================================
name                  = "sim-pay-forge"
environment           = "prod"
region                = "eu-west-1"

# SECURITY: FINITE IP LIST REQUIRED FOR AUDIT
allowed_client_cidrs  = [
  "203.0.113.0/24",    # Replace with auditor IPs
  "198.51.100.0/24",   # Your office/CIDR
  "185.220.101.XX/32"  # Specific IP example
]

# Production AMIs
db_ami_id             = "ami-0c02fb55956c7d316"  # Custom MySQL AMI

# Production sizing
app_instance_type     = "t3.small"
db_instance_type      = "t3.medium"

# Production ACM Certificate
certificate_validation_method = "DNS"    # Production standard
create_dns_validation_records = false      # Auto Route53 records
certificate_domain_name       = "altm-prod.grendach.dev" 

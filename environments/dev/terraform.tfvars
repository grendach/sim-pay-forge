name                          = "sim-pay-forge"
environment                   = "dev"
region                        = "eu-central-1"

allowed_client_cidrs          = ["0.0.0.0/0"]

# AMIs
db_ami_id                     = "ami-0c02fb55956c7d316"

# Sizing
app_instance_type             = "t3.micro"
db_instance_type              = "t3.micro"

# ACM Certificate (manual DNS validation)
certificate_validation_method = "DNS"
create_dns_validation_records = false
certificate_domain_name       = "dev.grendach.dev"

variable "name" {
  type        = string
  description = "Project name (kebab-case)"
  default     = "sim-pay-forge"
}

variable "environment" {
  type        = string
  description = "dev/prod/staging"
  validation {
    condition     = contains(["dev", "prod", "staging"], var.environment)
    error_message = "Must be dev, prod, or staging."
  }
}

variable "region" {
  type        = string
  default     = "eu-west-1"  # Wrocław optimal
}

# SECURITY: Finite IP list for audit compliance
variable "allowed_client_cidrs" {
  type        = list(string)
  description = "Client IPs allowed to ALB HTTPS:443"
}

# Instance configuration

variable "db_ami_id" {
  type        = string
  description = "Database AMI ID"
  default     = ""
}

variable "app_instance_type" {
  type        = string
  default     = "t3.micro"
}

variable "required_package_repo_baseurl" {
  type        = string
  description = "URL used to bootstrap the external repository that provides the required app dependency"
  default     = "https://download.docker.com/linux/centos/docker-ce.repo"
}

variable "required_package_name" {
  type        = string
  description = "Package that must be installed before the application starts"
  default     = "docker-ce"
}

variable "db_instance_type" {
  type        = string
  default     = "t3.small"
}

# Service ports
variable "app_port" {
  type        = number
  default     = 80
  description = "Application port"
}

variable "db_port" {
  type        = number
  default     = 3306
  description = "Database port"
}

variable "mysql_root_password" {
  type        = string
  description = "MySQL root password for DB instance bootstrap"
  sensitive   = true
}

# CERTIFICATE AUTOMATION
variable "certificate_domain_name" {
  type        = string
  description = "Primary domain for ACM cert"
}

variable "certificate_sans" {
  type        = list(string)
  description = "Subject Alternative Names"
}

variable "certificate_validation_method" {
  type        = string
  default     = "EMAIL"
  validation {
    condition     = contains(["EMAIL", "DNS"], var.certificate_validation_method)
    error_message = "Must be EMAIL or DNS."
  }
}

variable "create_dns_validation_records" {
  type        = bool
  default     = false
  description = "Create Route53 validation records"
}

variable "route53_zone_id" {
  type        = string
  default     = ""
  description = "Route53 Hosted Zone ID (for DNS validation)"
}

# Public subnet CIDRs (customize if needed)
variable "public_subnet_cidrs" {
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  type        = list(string)
  default     = ["10.0.3.0/24", "10.0.4.0/24"]
}

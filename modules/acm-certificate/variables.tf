variable "name" {
  type = string
}

variable "domain_name" {
  type = string
}

variable "subject_alternative_names" {
  type        = list(string)
  default     = []
  description = "SANs like ['*.example.com']"
}

variable "validation_method" {
  type        = string
  default     = "EMAIL"
  validation {
    condition     = contains(["EMAIL", "DNS"], var.validation_method)
    error_message = "Must be EMAIL or DNS."
  }
}

variable "create_validation_records" {
  type    = bool
  default = false
}

variable "route53_zone_id" {
  type        = string
  default     = ""
  description = "Route53 zone ID for auto DNS validation"
}

variable "wait_for_validation" {
  type    = bool
  default = true
}

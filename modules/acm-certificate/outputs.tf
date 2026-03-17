output "certificate_arn" {
  value = aws_acm_certificate.this.arn
}

output "validation_records" {
  value = var.create_validation_records ? aws_route53_record.validation : {}
}

output "validation_record_fqdns" {
  value = var.create_validation_records ? [for r in aws_route53_record.validation : r.fqdn] : []
}

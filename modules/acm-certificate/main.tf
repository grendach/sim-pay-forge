resource "aws_acm_certificate" "this" {
  domain_name               = var.domain_name
  subject_alternative_names = var.subject_alternative_names
  validation_method         = var.validation_method

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = var.name
  }
}

# Only create Route53 records if explicitly requested
resource "aws_route53_record" "validation" {
  for_each = (
    var.validation_method == "DNS" && var.create_validation_records
  ) ? {
    for dvo in aws_acm_certificate.this.domain_validation_options :
    dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  } : {}

  zone_id         = var.route53_zone_id
  name            = each.value.name
  type            = each.value.type
  ttl             = 60
  records         = [each.value.record]
  allow_overwrite = true
}

# Only validate if DNS records are created (Route53) and wait is requested
resource "aws_acm_certificate_validation" "this" {
  count                  = var.create_validation_records && var.wait_for_validation ? 1 : 0
  certificate_arn        = aws_acm_certificate.this.arn
  validation_record_fqdns = [for record in aws_route53_record.validation : record.fqdn]
}

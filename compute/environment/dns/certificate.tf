resource "aws_acm_certificate" "main" {
  domain_name               = local.main_dns_fqdn
  subject_alternative_names = ["*.${local.main_dns_fqdn}"]
  validation_method         = "DNS"

  tags = {
    Workspace   = terraform.workspace
    Environment = var.environment
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "main_cert_validation" {
  name    = aws_acm_certificate.main.domain_validation_options[0].resource_record_name
  type    = aws_acm_certificate.main.domain_validation_options[0].resource_record_type
  zone_id = data.aws_route53_zone.caronae.id
  records = [aws_acm_certificate.main.domain_validation_options[0].resource_record_value]
  ttl     = 60
}

resource "aws_acm_certificate_validation" "cert" {
  certificate_arn         = aws_acm_certificate.main.arn
  validation_record_fqdns = [aws_route53_record.main_cert_validation.fqdn]
}

output "acm_certificate_arn" {
  value = aws_acm_certificate.main.arn
}

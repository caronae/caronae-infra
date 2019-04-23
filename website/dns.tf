data "aws_route53_zone" "caronae" {
  name = "${local.dns_zone}"
}

resource "aws_route53_record" "website" {
  zone_id = "${data.aws_route53_zone.caronae.zone_id}"
  name    = "${local.dns_record}"
  type    = "CNAME"
  ttl     = "300"
  records = ["${aws_cloudfront_distribution.website.domain_name}"]
}

resource "aws_acm_certificate" "website" {
  domain_name       = "${local.dns_record}.${local.dns_zone}"
  validation_method = "DNS"

  tags {
    Workspace = "${terraform.workspace}"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "website_cert_validation" {
  name    = "${aws_acm_certificate.website.domain_validation_options.0.resource_record_name}"
  type    = "${aws_acm_certificate.website.domain_validation_options.0.resource_record_type}"
  zone_id = "${data.aws_route53_zone.caronae.id}"
  records = ["${aws_acm_certificate.website.domain_validation_options.0.resource_record_value}"]
  ttl     = 60
}

resource "aws_acm_certificate_validation" "cert" {
  certificate_arn         = "${aws_acm_certificate.website.arn}"
  validation_record_fqdns = ["${aws_route53_record.website_cert_validation.fqdn}"]
}

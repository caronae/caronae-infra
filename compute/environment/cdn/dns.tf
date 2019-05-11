data "aws_route53_zone" "caronae" {
  name = "${local.dns_zone}"
}

resource "aws_route53_record" "alias" {
  zone_id = "${data.aws_route53_zone.caronae.zone_id}"
  name    = "${var.dns_record}"
  type    = "A"

  alias {
    name                   = "${aws_cloudfront_distribution.main.domain_name}"
    zone_id                = "${aws_cloudfront_distribution.main.hosted_zone_id}"
    evaluate_target_health = true
  }
}

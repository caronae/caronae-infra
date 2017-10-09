variable "domain" {}
variable "api_domain" {}
variable "ufrj_domain" {}
variable "site_domain" {}
variable "backend_instance_ip" {}

data "aws_route53_zone" "caronae" {
  name = "${var.domain}."
}

resource "aws_route53_record" "api" {
  zone_id = "${data.aws_route53_zone.caronae.zone_id}"
  name    = "${var.api_domain}"
  type    = "A"
  ttl     = "300"
  records = ["${var.backend_instance_ip}"]
}

resource "aws_route53_record" "ufrj" {
  zone_id = "${data.aws_route53_zone.caronae.zone_id}"
  name    = "${var.ufrj_domain}"
  type    = "A"
  ttl     = "300"
  records = ["${var.backend_instance_ip}"]
}

resource "aws_route53_record" "site" {
  zone_id = "${data.aws_route53_zone.caronae.zone_id}"
  name    = "${var.site_domain}"
  type    = "A"
  ttl     = "300"
  records = ["${var.backend_instance_ip}"]
}

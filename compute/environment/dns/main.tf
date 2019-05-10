variable "domain" {
  default = "caronae.org"
}

variable "environment" {}
variable "backend_instance_ip" {}

locals {
  workspace_suffix = "${terraform.workspace == "default" ? "" : format(".%s", terraform.workspace)}"
  environment_suffix = "${var.environment == "prod" ? "" : var.environment}"
  resource_suffix = "${format("%s%s", local.environment_suffix, local.workspace_suffix)}"
  main_dns_fqdn = "${local.resource_suffix == "" ? var.domain : format("%s.%s", local.resource_suffix, var.domain)}"
}

data "aws_route53_zone" "caronae" {
  name = "${var.domain}"
}

resource "aws_route53_record" "origin" {
  zone_id = "${data.aws_route53_zone.caronae.zone_id}"
  name    = "origin.${local.resource_suffix}"
  type    = "A"
  ttl     = "300"
  records = ["${var.backend_instance_ip}"]
}

resource "aws_route53_record" "ufrj" {
  zone_id = "${data.aws_route53_zone.caronae.zone_id}"
  name    = "ufrj.${local.resource_suffix}"
  type    = "A"
  ttl     = "300"
  records = ["${var.backend_instance_ip}"]
}

resource "aws_route53_record" "site" {
  zone_id = "${data.aws_route53_zone.caronae.zone_id}"
  name    = "${local.resource_suffix}"
  type    = "A"
  ttl     = "300"
  records = ["${var.backend_instance_ip}"]
}

resource "aws_route53_record" "www" {
  count   = "${var.environment == "prod" ? 1 : 0}"
  zone_id = "${data.aws_route53_zone.caronae.zone_id}"
  name    = "www.${local.resource_suffix}"
  type    = "A"
  ttl     = "300"
  records = ["${var.backend_instance_ip}"]
}

output "origin_fqdn" {
  value = "${aws_route53_record.origin.fqdn}"
}

variable "domain" {}
variable "environment" {}
variable "backend_instance_ip" {}

variable "www_domain" {
  default = ""
}

data "aws_route53_zone" "caronae" {
  name = "${var.domain}."
}

data "template_file" "workspace_dns_domain" {
  template = "${ terraform.workspace == "default" ? "" : "${terraform.workspace}" }"
}

data "template_file" "workspace_dns_domain_with_dot" {
  template = "${ terraform.workspace == "default" ? "" : ".${terraform.workspace}" }"
}

data "template_file" "environment_prefix" {
  template = "${ var.environment == "prod" ? "" : "dev" }"
}

data "template_file" "environment_prefix_with_dot" {
  template = "${ var.environment == "prod" ? "" : ".dev" }"
}

resource "aws_route53_record" "api" {
  zone_id = "${data.aws_route53_zone.caronae.zone_id}"
  name    = "api${data.template_file.environment_prefix_with_dot.rendered}${data.template_file.workspace_dns_domain_with_dot.rendered}"
  type    = "A"
  ttl     = "300"
  records = ["${var.backend_instance_ip}"]
}

resource "aws_route53_record" "ufrj" {
  zone_id = "${data.aws_route53_zone.caronae.zone_id}"
  name    = "ufrj${data.template_file.environment_prefix_with_dot.rendered}${data.template_file.workspace_dns_domain_with_dot.rendered}"
  type    = "A"
  ttl     = "300"
  records = ["${var.backend_instance_ip}"]
}

resource "aws_route53_record" "site" {
  zone_id = "${data.aws_route53_zone.caronae.zone_id}"
  name    = "${data.template_file.environment_prefix.rendered}${data.template_file.workspace_dns_domain.rendered}"
  type    = "A"
  ttl     = "300"
  records = ["${var.backend_instance_ip}"]
}

resource "aws_route53_record" "www" {
  count   = "${var.environment == "prod" ? 1 : 0}"
  zone_id = "${data.aws_route53_zone.caronae.zone_id}"
  name    = "www${data.template_file.workspace_dns_domain_with_dot.rendered}"
  type    = "A"
  ttl     = "300"
  records = ["${var.backend_instance_ip}"]
}

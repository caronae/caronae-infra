terraform {
  backend "s3" {
    bucket = "terraform.caronae"
    key    = "terraform/terraform.tfstate"
    region = "sa-east-1"
  }
}

variable "region" {
  default = "us-east-1"
}

provider "aws" {
  region = "${var.region}"
}

module "network" {
  source = "./network"

  region = "${var.region}"
}

module "iam" {
  source = "./iam"
}

module "backend" {
  source = "./backend"

  region               = "${var.region}"
  security_group       = "${module.network.web_security_group}"
  iam_instance_profile = "${module.iam.instance_iam_profile}"
  subnet               = "${module.network.subnet}"
}

data "aws_route53_zone" "caronae" {
  name = "caronae.com.br."
}

resource "aws_route53_record" "api" {
  zone_id = "${data.aws_route53_zone.caronae.zone_id}"
  name    = "api2-${terraform.workspace}"
  type    = "A"
  ttl     = "300"
  records = ["${module.backend.instance_ip}"]
}

resource "aws_route53_record" "ufrj" {
  zone_id = "${data.aws_route53_zone.caronae.zone_id}"
  name    = "ufrj-${terraform.workspace}"
  type    = "A"
  ttl     = "300"
  records = ["${module.backend.instance_ip}"]
}

resource "aws_route53_record" "site" {
  zone_id = "${data.aws_route53_zone.caronae.zone_id}"
  name    = "site-${terraform.workspace}"
  type    = "A"
  ttl     = "300"
  records = ["${module.backend.instance_ip}"]
}

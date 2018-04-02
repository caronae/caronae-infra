terraform {
  backend "s3" {
    bucket = "terraform.caronae"
    key    = "terraform/terraform.tfstate"
    region = "sa-east-1"
  }
}

locals {
  region            = "us-east-1"
  availability_zone = "us-east-1a"
  domain            = "caronae.org"
}

variable "letsencrypt_challenge_prod" {
  default = ""
}

variable "letsencrypt_challenge_dev" {
  default = ""
}

provider "aws" {
  region = "${local.region}"
}

module "network" {
  source = "./network"

  region = "${local.region}"
}

module "storage" {
  source = "./storage"
}

module "iam" {
  source              = "./iam"
  certificates_bucket = "${module.storage.certificates_bucket_arn}"
}

data "template_file" "workspace_domain" {
  template = "${ terraform.workspace == "default" ? "${local.domain}" : "${terraform.workspace}.${local.domain}" }"
}

module "compute" {
  source = "./compute"

  region              = "${local.region}"
  availability_zone   = "${local.availability_zone}"
  subnet              = "${module.network.subnet}"
  elastic_ips_ids     = "${module.network.elastic_ips_ids}"
  security_group      = "${module.network.web_security_group}"
  iam_profile         = "${module.iam.instance_iam_profile}"
  workspace_domain    = "${data.template_file.workspace_domain.rendered}"
  certificates_bucket = "${module.storage.certificates_bucket_name}"
}

module "dns_prod" {
  source = "./dns"

  domain                = "${local.domain}"
  environment           = "prod"
  backend_instance_ip   = "${module.network.elastic_ips[0]}"
  letsencrypt_challenge = "${var.letsencrypt_challenge_prod}"
}

module "dns_dev" {
  source = "./dns"

  domain                = "${local.domain}"
  environment           = "dev"
  backend_instance_ip   = "${module.network.elastic_ips[1]}"
  letsencrypt_challenge = "${var.letsencrypt_challenge_dev}"
}

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

variable "letsencrypt_challenge" {
  default = ""
}

provider "aws" {
  region = "${local.region}"
}

module "network" {
  source = "./network"

  region = "${local.region}"
}

module "iam" {
  source = "./iam"
}

data "template_file" "workspace_domain" {
  template = "${ terraform.workspace == "default" ? "${local.domain}" : "${terraform.workspace}.${local.domain}" }"
}

data "template_file" "workspace_dns_domain" {
  template = "${ terraform.workspace == "default" ? "" : "${terraform.workspace}" }"
}

data "template_file" "workspace_dns_domain_with_dot" {
  template = "${ terraform.workspace == "default" ? "" : ".${terraform.workspace}" }"
}

module "compute" {
  source = "./compute"

  region            = "${local.region}"
  availability_zone = "${local.availability_zone}"
  subnet            = "${module.network.subnet}"
  elastic_ips_ids   = "${module.network.elastic_ips_ids}"
  security_group    = "${module.network.web_security_group}"
  iam_profile       = "${module.iam.instance_iam_profile}"
  workspace_domain  = "${data.template_file.workspace_domain.rendered}"
}

module "storage_prod" {
  source      = "./storage"
  environment = "prod"
}

module "storage_dev" {
  source      = "./storage"
  environment = "dev"
}

module "dns_prod" {
  source = "./dns"

  domain                = "${local.domain}"
  api_domain            = "api${data.template_file.workspace_dns_domain_with_dot.rendered}"
  ufrj_domain           = "ufrj${data.template_file.workspace_dns_domain_with_dot.rendered}"
  www_domain            = "www${data.template_file.workspace_dns_domain_with_dot.rendered}"
  site_domain           = "${data.template_file.workspace_dns_domain.rendered}"
  backend_instance_ip   = "${module.network.elastic_ips[0]}"
  letsencrypt_challenge = "${var.letsencrypt_challenge}"
}

module "dns_dev" {
  source = "./dns"

  domain              = "${local.domain}"
  api_domain          = "api.dev${data.template_file.workspace_dns_domain_with_dot.rendered}"
  ufrj_domain         = "ufrj.dev${data.template_file.workspace_dns_domain_with_dot.rendered}"
  site_domain         = "dev${data.template_file.workspace_dns_domain_with_dot.rendered}"
  backend_instance_ip = "${module.network.elastic_ips[1]}"
}

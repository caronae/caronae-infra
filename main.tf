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

variable "domain" {
  default = "caronae.org"
}

data "template_file" "workspace_domain" {
  template = "${ terraform.workspace == "default" ? "${var.domain}" : "${terraform.workspace}.${var.domain}" }"
}

module "backend_prod" {
  source = "./backend"

  environment          = "prod"
  api_domain           = "api.${data.template_file.workspace_domain.rendered}"
  ufrj_domain          = "ufrj.${data.template_file.workspace_domain.rendered}"
  site_domain          = "${data.template_file.workspace_domain.rendered}"
  region               = "${var.region}"
  security_group       = "${module.network.web_security_group}"
  iam_instance_profile = "${module.iam.instance_iam_profile}"
  subnet               = "${module.network.subnet}"
}

module "backend_dev" {
  source = "./backend"

  environment          = "dev"
  api_domain           = "api.dev.${data.template_file.workspace_domain.rendered}"
  ufrj_domain          = "ufrj.dev.${data.template_file.workspace_domain.rendered}"
  site_domain          = "dev.${data.template_file.workspace_domain.rendered}"
  region               = "${var.region}"
  security_group       = "${module.network.web_security_group}"
  iam_instance_profile = "${module.iam.instance_iam_profile}"
  subnet               = "${module.network.subnet}"
}

data "template_file" "workspace_dns_domain" {
  template = "${ terraform.workspace == "default" ? "" : ".${terraform.workspace}" }"
}

module "dns_prod" {
  source = "./dns"

  domain              = "${var.domain}"
  api_domain          = "api${data.template_file.workspace_dns_domain.rendered}"
  ufrj_domain         = "ufrj${data.template_file.workspace_dns_domain.rendered}"
  site_domain         = "${data.template_file.workspace_dns_domain.rendered}"
  backend_instance_ip = "${module.backend_prod.instance_ip}"
}

module "dns_dev" {
  source = "./dns"

  domain              = "${var.domain}"
  api_domain          = "api.dev${data.template_file.workspace_dns_domain.rendered}"
  ufrj_domain         = "ufrj.dev${data.template_file.workspace_dns_domain.rendered}"
  site_domain         = "dev${data.template_file.workspace_dns_domain.rendered}"
  backend_instance_ip = "${module.backend_dev.instance_ip}"
}

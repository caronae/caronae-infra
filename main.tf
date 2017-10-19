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

variable "domain" {
  default = "caronae.org"
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

module "backend_prod" {
  source = "./backend"

  environment          = "prod"
  api_domain           = "api.${terraform.workspace}.${var.domain}"
  ufrj_domain          = "ufrj.${terraform.workspace}.${var.domain}"
  site_domain          = "${terraform.workspace}.${var.domain}"
  region               = "${var.region}"
  security_group       = "${module.network.web_security_group}"
  iam_instance_profile = "${module.iam.instance_iam_profile}"
  subnet               = "${module.network.subnet}"
}

module "backend_dev" {
  source = "./backend"

  environment          = "dev"
  api_domain           = "api.dev.${terraform.workspace}.${var.domain}"
  ufrj_domain          = "ufrj.dev.${terraform.workspace}.${var.domain}"
  site_domain          = "dev.${terraform.workspace}.${var.domain}"
  region               = "${var.region}"
  security_group       = "${module.network.web_security_group}"
  iam_instance_profile = "${module.iam.instance_iam_profile}"
  subnet               = "${module.network.subnet}"
}

module "dns_prod" {
  source = "./dns"

  domain              = "${var.domain}"
  api_domain          = "api.${terraform.workspace}"
  ufrj_domain         = "ufrj.${terraform.workspace}"
  site_domain         = "${terraform.workspace}"
  backend_instance_ip = "${module.backend_prod.instance_ip}"
}

module "dns_dev" {
  source = "./dns"

  domain              = "${var.domain}"
  api_domain          = "api.dev.${terraform.workspace}"
  ufrj_domain         = "ufrj.dev.${terraform.workspace}"
  site_domain         = "dev.${terraform.workspace}"
  backend_instance_ip = "${module.backend_dev.instance_ip}"
}

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

module "backend" {
  source = "./backend"

  api_domain           = "api.${terraform.workspace}.${var.domain}"
  ufrj_domain          = "ufrj.${terraform.workspace}.${var.domain}"
  site_domain          = "${terraform.workspace}.${var.domain}"
  region               = "${var.region}"
  security_group       = "${module.network.web_security_group}"
  iam_instance_profile = "${module.iam.instance_iam_profile}"
  subnet               = "${module.network.subnet}"
}

module "dns" {
  source = "./dns"

  domain              = "${var.domain}"
  api_domain          = "api.${terraform.workspace}"
  ufrj_domain         = "ufrj.${terraform.workspace}"
  site_domain         = "${terraform.workspace}"
  backend_instance_ip = "${module.backend.instance_ip}"
}

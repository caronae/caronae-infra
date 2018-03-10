variable "region" {}
variable "availability_zone" {}
variable "subnet" {}
variable "security_group" {}
variable "iam_profile" {}
variable "workspace_domain" {}

variable "elastic_ips_ids" {
  type = "list"
}

module "cluster_prod" {
  source      = "./cluster"
  environment = "prod"
}

module "volume_prod" {
  source = "./volume"

  environment       = "prod"
  availability_zone = "${var.availability_zone}"
}

module "instance_prod" {
  source = "./instance"

  environment          = "prod"
  cluster              = "${module.cluster_prod.cluster_name}"
  image_tag            = "latest"
  api_domain           = "api.${var.workspace_domain}"
  ufrj_domain          = "ufrj.${var.workspace_domain}"
  site_domain          = "${var.workspace_domain}"
  region               = "${var.region}"
  availability_zone    = "${var.availability_zone}"
  security_group       = "${var.security_group}"
  iam_instance_profile = "${var.iam_profile}"
  subnet               = "${var.subnet}"
  elastic_ip_id        = "${var.elastic_ips_ids[0]}"
  data_volume_id       = "${module.volume_prod.data_volume}"
}

module "volume_dev" {
  source = "./volume"

  environment       = "dev"
  availability_zone = "${var.availability_zone}"
}

module "instance_dev" {
  source = "./instance"

  environment          = "dev"
  image_tag            = "develop"
  api_domain           = "api.dev.${var.workspace_domain}"
  ufrj_domain          = "ufrj.dev.${var.workspace_domain}"
  site_domain          = "dev.${var.workspace_domain}"
  region               = "${var.region}"
  availability_zone    = "${var.availability_zone}"
  security_group       = "${var.security_group}"
  iam_instance_profile = "${var.iam_profile}"
  subnet               = "${var.subnet}"
  elastic_ip_id        = "${var.elastic_ips_ids[1]}"
  data_volume_id       = "${module.volume_dev.data_volume}"
}

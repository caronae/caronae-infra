variable "region" {}
variable "availability_zone" {}
variable "subnet" {}
variable "security_group" {}
variable "iam_profile" {}
variable "workspace_domain" {}
variable "certificates_bucket" {}

variable "elastic_ips_ids" {
  type = "list"
}

module "volume_prod" {
  source = "./volume"

  environment       = "prod"
  availability_zone = "${var.availability_zone}"
}

module "instance_prod" {
  source = "./instance"

  environment          = "prod"
  image_tag            = "latest"
  region               = "${var.region}"
  availability_zone    = "${var.availability_zone}"
  security_group       = "${var.security_group}"
  iam_instance_profile = "${var.iam_profile}"
  subnet               = "${var.subnet}"
  elastic_ip_id        = "${var.elastic_ips_ids[0]}"
  data_volume_id       = "${module.volume_prod.data_volume}"
  certificates_bucket  = "${var.certificates_bucket}"
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
  region               = "${var.region}"
  availability_zone    = "${var.availability_zone}"
  security_group       = "${var.security_group}"
  iam_instance_profile = "${var.iam_profile}"
  subnet               = "${var.subnet}"
  elastic_ip_id        = "${var.elastic_ips_ids[1]}"
  data_volume_id       = "${module.volume_dev.data_volume}"
  certificates_bucket  = "${var.certificates_bucket}"
}

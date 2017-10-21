variable "region" {}
variable "subnet" {}
variable "security_group" {}
variable "iam_profile" {}
variable "workspace_domain" {}

variable "elastic_ips_ids" {
  type = "list"
}

module "backend_prod" {
  source = "./instance"

  environment          = "prod"
  image_tag            = "latest"
  api_domain           = "api.${var.workspace_domain}"
  ufrj_domain          = "ufrj.${var.workspace_domain}"
  site_domain          = "${var.workspace_domain}"
  region               = "${var.region}"
  security_group       = "${var.security_group}"
  iam_instance_profile = "${var.iam_profile}"
  subnet               = "${var.subnet}"
  elastic_ip_id        = "${var.elastic_ips_ids[0]}"
}

module "backend_dev" {
  source = "./instance"

  environment          = "dev"
  image_tag            = "develop"
  api_domain           = "api.dev.${var.workspace_domain}"
  ufrj_domain          = "ufrj.dev.${var.workspace_domain}"
  site_domain          = "dev.${var.workspace_domain}"
  region               = "${var.region}"
  security_group       = "${var.security_group}"
  iam_instance_profile = "${var.iam_profile}"
  subnet               = "${var.subnet}"
  elastic_ip_id        = "${var.elastic_ips_ids[1]}"
}

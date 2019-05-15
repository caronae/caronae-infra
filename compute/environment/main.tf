variable "region" {}
variable "availability_zone" {}
variable "subnet" {}
variable "security_group" {}
variable "iam_profile" {}
variable "certificates_bucket" {}
variable "image_tag" {}
variable "environment" {}

resource "aws_eip" "instance" {
  vpc = true
  tags {
    Name        = "caronae-eip-${terraform.workspace}-${var.environment}"
    Environment = "${var.environment}"
    Workspace   = "${terraform.workspace}"
  }
}

module "dns" {
  source              = "./dns"
  environment         = "${var.environment}"
  backend_instance_ip = "${aws_eip.instance.public_ip}"
}

module "volume" {
  source            = "./volume"
  environment       = "${var.environment}"
  availability_zone = "${var.availability_zone}"
}

module "instance" {
  source               = "./instance"
  environment          = "${var.environment}"
  image_tag            = "${var.image_tag}"
  region               = "${var.region}"
  availability_zone    = "${var.availability_zone}"
  security_group       = "${var.security_group}"
  iam_instance_profile = "${var.iam_profile}"
  subnet               = "${var.subnet}"
  elastic_ip_id        = "${aws_eip.instance.id}"
  data_volume_id       = "${module.volume.data_volume}"
  certificates_bucket  = "${var.certificates_bucket}"
}

module "website" {
  source               = "./website"
  environment          = "${var.environment}"
  acm_certificate_arn   = "${module.dns.acm_certificate_arn}"
}

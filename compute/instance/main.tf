variable "region" {}
variable "subnet" {}
variable "elastic_ip_id" {}
variable "security_group" {}
variable "iam_instance_profile" {}
variable "api_domain" {}
variable "ufrj_domain" {}
variable "site_domain" {}
variable "environment" {}
variable "image_tag" {}

resource "aws_cloudwatch_log_group" "default" {
  name = "${var.environment}"

  tags {
    Workspace = "${terraform.workspace}"
  }
}

data "template_file" "cloud_config" {
  template = "${file("compute/instance/cloud-config.yml")}"

  vars {
    encrypted_envs = "${file("compute/instance/.encrypted_envs_${var.environment}")}"
    api_domain     = "${var.api_domain}"
    ufrj_domain    = "${var.ufrj_domain}"
    site_domain    = "${var.site_domain}"
    region         = "${var.region}"
    image_tag      = "${var.image_tag}"
    log_group      = "${aws_cloudwatch_log_group.default.name}"
  }
}

resource "aws_instance" "caronae_instance" {
  ami                    = "ami-8c1be5f6"
  instance_type          = "t2.micro"
  subnet_id              = "${var.subnet}"
  vpc_security_group_ids = ["${var.security_group}"]
  key_name               = "terraform"
  iam_instance_profile   = "${var.iam_instance_profile}"
  user_data              = "${data.template_file.cloud_config.rendered}"

  tags {
    Name        = "caronae-${var.environment}"
    Environment = "${var.environment}"
    Workspace   = "${terraform.workspace}"
  }
}

resource "aws_eip_association" "eip_assoc" {
  instance_id   = "${aws_instance.caronae_instance.id}"
  allocation_id = "${var.elastic_ip_id}"
}

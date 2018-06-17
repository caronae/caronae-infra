variable "region" {}
variable "availability_zone" {}
variable "subnet" {}
variable "elastic_ip_id" {}
variable "security_group" {}
variable "iam_instance_profile" {}
variable "data_volume_id" {}
variable "api_domain" {}
variable "ufrj_domain" {}
variable "site_domain" {}
variable "environment" {}
variable "image_tag" {}
variable "certificates_bucket" {}

data "template_file" "instance_name" {
  template = "${ terraform.workspace == "default" ? "caronae-${var.environment}" : "caronae-${terraform.workspace}-${var.environment}" }"
}

resource "aws_cloudwatch_log_group" "default" {
  name = "${data.template_file.instance_name.rendered}"

  tags {
    Workspace = "${terraform.workspace}"
  }
}

data "template_file" "cloud_config" {
  template = "${file("compute/instance/cloud-config.yml")}"

  vars {
    api_domain           = "${var.api_domain}"
    ufrj_domain          = "${var.ufrj_domain}"
    site_domain          = "${var.site_domain}"
    region               = "${var.region}"
    environment          = "${var.environment}"
    image_tag            = "${var.image_tag}"
    certificates_bucket  = "${var.certificates_bucket}"
    log_group            = "${aws_cloudwatch_log_group.default.name}"
    mount_volumes_script = "${file("compute/instance/mount_volumes.sh")}"
  }
}

resource "aws_instance" "caronae_instance" {
  ami                    = "ami-97785bed"
  instance_type          = "t2.micro"
  availability_zone      = "${var.availability_zone}"
  subnet_id              = "${var.subnet}"
  vpc_security_group_ids = ["${var.security_group}"]
  key_name               = "terraform"
  iam_instance_profile   = "${var.iam_instance_profile}"
  user_data              = "${data.template_file.cloud_config.rendered}"

  tags {
    Name        = "${data.template_file.instance_name.rendered}"
    Environment = "${var.environment}"
    Workspace   = "${terraform.workspace}"
  }
}

resource "aws_eip_association" "eip_assoc" {
  instance_id   = "${aws_instance.caronae_instance.id}"
  allocation_id = "${var.elastic_ip_id}"
}

resource "aws_volume_attachment" "data_volume" {
  device_name = "/dev/sdh"
  volume_id   = "${var.data_volume_id}"
  instance_id = "${aws_instance.caronae_instance.id}"
}

data "template_file" "dashboard" {
  template = "${file("compute/instance/dashboard.json.tpl")}"

  vars {
    instance_id = "${aws_instance.caronae_instance.id}"
    region      = "${var.region}"
  }
}

resource "aws_cloudwatch_dashboard" "default" {
  dashboard_name = "dashboard-${data.template_file.instance_name.rendered}"
  dashboard_body = "${data.template_file.dashboard.rendered}"
}

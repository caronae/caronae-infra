variable "region" {}
variable "subnet" {}
variable "security_group" {}
variable "iam_instance_profile" {}
variable "api_domain" {}
variable "ufrj_domain" {}
variable "site_domain" {}

data "template_file" "cloud_config" {
  template = "${file("backend/cloud-config.yml")}"

  vars {
    encrypted_envs = "${file("backend/.encrypted_envs")}"
    api_domain     = "${var.api_domain}"
    ufrj_domain    = "${var.ufrj_domain}"
    site_domain    = "${var.site_domain}"
    region         = "${var.region}"
  }
}

resource "aws_instance" "caronae_instance" {
  ami                    = "ami-4fffc834"
  instance_type          = "t2.micro"
  subnet_id              = "${var.subnet}"
  vpc_security_group_ids = ["${var.security_group}"]
  key_name               = "terraform"
  iam_instance_profile   = "${var.iam_instance_profile}"
  user_data              = "${data.template_file.cloud_config.rendered}"

  tags {
    Name = "caronae-${terraform.workspace}"
  }
}

output "instance_ip" {
  value = "${aws_instance.caronae_instance.instance_ip}"
}

variable "region" {}
variable "subnet" {}
variable "security_group" {}
variable "iam_instance_profile" {}

data "template_file" "cloud_config" {
  template = "${file("backend/cloud-config.yml")}"

  vars {
    encrypted_envs = "${file("backend/.encrypted_envs")}"
    api_domain     = "api2-${terraform.workspace}.caronae.com.br"
    ufrj_domain    = "ufrj-${terraform.workspace}.caronae.com.br"
    site_domain    = "site-${terraform.workspace}.caronae.com.br"
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

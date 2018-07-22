variable "region" {}
variable "availability_zone" {}
variable "subnet" {}
variable "elastic_ip_id" {}
variable "security_group" {}
variable "iam_instance_profile" {}
variable "data_volume_id" {}
variable "environment" {}
variable "image_tag" {}
variable "certificates_bucket" {}

data "template_file" "instance_name" {
  template = "${ terraform.workspace == "default" ? "caronae-${var.environment}" : "caronae-${terraform.workspace}-${var.environment}" }"
}

resource "aws_instance" "caronae" {
  ami                    = "ami-14c5486b"
  instance_type          = "t2.micro"
  availability_zone      = "${var.availability_zone}"
  subnet_id              = "${var.subnet}"
  vpc_security_group_ids = ["${var.security_group}"]
  key_name               = "terraform"
  iam_instance_profile   = "${var.iam_instance_profile}"

  tags {
    Name        = "${data.template_file.instance_name.rendered}"
    Environment = "${var.environment}"
    Workspace   = "${terraform.workspace}"
  }
}

resource "aws_eip_association" "eip_assoc" {
  instance_id   = "${aws_instance.caronae.id}"
  allocation_id = "${var.elastic_ip_id}"
}

resource "aws_volume_attachment" "data_volume" {
  device_name = "/dev/sdh"
  volume_id   = "${var.data_volume_id}"
  instance_id = "${aws_instance.caronae.id}"
}

resource "null_resource" "ansible_provisioner" {
  triggers {
    instance = "${aws_instance.caronae.id}"
    volume   = "${aws_volume_attachment.data_volume.volume_id}"
  }

  provisioner "local-exec" {
    command = "sleep 60; ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -v -u ec2-user --private-key terraform.pem -i '${aws_eip_association.eip_assoc.public_ip},' --extra-vars 'caronae_env=${var.environment} image_tag=${var.image_tag} certificates_bucket=${var.certificates_bucket} region=${var.region} log_group=${aws_cloudwatch_log_group.default.name}' compute/instance/ansible-playbook.yml"
  }
}

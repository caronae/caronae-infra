variable "environment" {}

data "template_file" "cluster-name" {
  template = "${ terraform.workspace == "default" ? "caronae-${var.environment}" : "caronae-${terraform.workspace}-${var.environment}" }"
}

resource "aws_ecs_cluster" "caronae" {
  name = "${data.template_file.cluster-name.rendered}"
}

output "cluster_name" {
  value = "${aws_ecs_cluster.caronae.name}"
}

variable "environment" {}

data "template_file" "bucket_prefix" {
  template = "${ terraform.workspace == "default" ? "" : "-${terraform.workspace}" }"
}

resource "aws_s3_bucket" "certificates" {
  bucket = "certificates-${data.template_file.bucket_prefix.rendered}${var.environment}.caronae"
  acl    = "private"

  tags {
    Environment = "${var.environment}"
    Workspace   = "${terraform.workspace}"
  }
}

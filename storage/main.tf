data "template_file" "bucket_suffix" {
  template = "${ terraform.workspace == "default" ? "" : "-${terraform.workspace}" }"
}

resource "aws_s3_bucket" "certificates" {
  bucket = "certificates${data.template_file.bucket_suffix.rendered}.caronae"
  acl    = "private"

  tags {
    Workspace = "${terraform.workspace}"
  }
}

resource "aws_s3_bucket" "user_content" {
  bucket = "usercontent${data.template_file.bucket_suffix.rendered}.caronae"
  acl    = "public-read"

  tags {
    Workspace = "${terraform.workspace}"
  }
}

resource "aws_s3_bucket" "backups" {
  bucket = "backups${data.template_file.bucket_suffix.rendered}.caronae"
  acl    = "private"

  tags {
    Workspace = "${terraform.workspace}"
  }
}

output "certificates_bucket_arn" {
  value = "${aws_s3_bucket.certificates.arn}"
}

output "certificates_bucket_name" {
  value = "${aws_s3_bucket.certificates.id}"
}

output "user_content_bucket_arn" {
  value = "${aws_s3_bucket.user_content.arn}"
}

output "backups_bucket_arn" {
  value = "${aws_s3_bucket.backups.arn}"
}

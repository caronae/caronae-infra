data "template_file" "bucket_suffix" {
  template = terraform.workspace == "default" ? "" : "-${terraform.workspace}"
}

resource "aws_s3_bucket" "user_content" {
  bucket = "usercontent${data.template_file.bucket_suffix.rendered}.caronae"
  acl    = "public-read"

  tags = {
    Workspace = terraform.workspace
  }
}

resource "aws_s3_bucket" "backups" {
  bucket = "backups${data.template_file.bucket_suffix.rendered}.caronae"
  acl    = "private"

  tags = {
    Workspace = terraform.workspace
  }
}

resource "aws_s3_bucket_public_access_block" "backups" {
  bucket = aws_s3_bucket.backups.id

  block_public_acls   = true
  block_public_policy = true
  ignore_public_acls  = true
}

output "user_content_bucket_arn" {
  value = aws_s3_bucket.user_content.arn
}

output "backups_bucket_arn" {
  value = aws_s3_bucket.backups.arn
}

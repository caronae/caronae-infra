resource "aws_s3_bucket" "website" {
  bucket = local.s3_bucket_name
  acl    = "private"

  website {
    index_document = "index.html"
  }

  tags = {
    Workspace = terraform.workspace
  }
}

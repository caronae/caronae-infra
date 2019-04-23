locals {
  resource_suffix = "${terraform.workspace == "default" ? "" : format("-%s", terraform.workspace)}"
}

resource "aws_s3_bucket" "website" {
  bucket = "website${local.resource_suffix}.caronae"
  acl    = "private"

  website {
    index_document = "index.html"
  }

  tags {
    Workspace = "${terraform.workspace}"
  }
}

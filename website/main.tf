locals {
  resource_suffix = "${terraform.workspace == "default" ? "" : format("-%s", terraform.workspace)}"
  s3_origin_id = "website-bucket-origin"
  dns_zone = "caronae.org"
  dns_record = "website${local.resource_suffix}"
  dns_fqdn = "${local.dns_record}${local.resource_suffix}"
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

resource "aws_cloudfront_distribution" "website" {
  enabled = true
  default_root_object = "index.html"
  aliases = ["${local.dns_record}.${local.dns_zone}"]

  origin {
    domain_name = "${aws_s3_bucket.website.bucket_regional_domain_name}"
    origin_id   = "${local.s3_origin_id}"
  }

  default_cache_behavior {
    target_origin_id = "${local.s3_origin_id}"
    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods  = ["GET", "HEAD"]
    viewer_protocol_policy = "redirect-to-https"
    compress = true

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn = "${aws_acm_certificate.website.arn}"
    ssl_support_method = "sni-only"
  }

  tags {
    Workspace = "${terraform.workspace}"
  }
}

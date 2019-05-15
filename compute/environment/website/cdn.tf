resource "aws_cloudfront_distribution" "main" {
  comment             = "Website ${var.environment} - ${terraform.workspace}"
  enabled             = true
  default_root_object = "index.html"
  aliases             = [
    "${local.main_dns_fqdn}",
    "www.${local.main_dns_fqdn}",
  ]

  origin {
    domain_name = "${aws_s3_bucket.website.bucket_regional_domain_name}"
    origin_id   = "${local.s3_origin_id}"
  }

  default_cache_behavior {
    target_origin_id       = "${local.s3_origin_id}"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    viewer_protocol_policy = "redirect-to-https"
    compress               = true

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
    acm_certificate_arn = "${var.acm_certificate_arn}"
    ssl_support_method  = "sni-only"
  }
}

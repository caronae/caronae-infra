resource "aws_cloudfront_distribution" "main" {
  comment             = "website ${var.environment} - ${terraform.workspace}"
  enabled             = true
  default_root_object = "index.html"
  aliases             = [
    "${local.main_dns_fqdn}",
    "www.${local.main_dns_fqdn}",
  ]

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn = "${var.acm_certificate_arn}"
    ssl_support_method  = "sni-only"
  }

  # Website bucket
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

  # API
  origin {
    domain_name = "${var.api_origin_fqdn}"
    origin_id   = "${local.api_origin_id}"

    custom_origin_config {
      origin_protocol_policy = "http-only"
      origin_ssl_protocols = ["TLSv1.2"]
      http_port = "${var.api_origin_http_port}"
      https_port = "443"
    }

    custom_header {
      name = "X-Forwarded-Host"
      value = "${var.api_dns_record}"
    }
  }

  ordered_cache_behavior {
    path_pattern           = "carona/*"
    target_origin_id       = "${local.api_origin_id}"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    forwarded_values {
      query_string = false
      headers = ["*"]
      cookies {
        forward = "none"
      }
    }
  }
}

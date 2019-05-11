resource "aws_cloudfront_distribution" "main" {
  enabled             = true
  aliases             = ["${var.dns_record}.${local.dns_zone}"]

  origin {
    domain_name = "${var.origin_fqdn}"
    origin_id   = "${var.origin_id}"

    custom_origin_config {
      origin_protocol_policy = "http-only"
      origin_ssl_protocols = ["TLSv1.2"]
      http_port = "${var.origin_http_port}"
      https_port = "443"
    }
  }

  default_cache_behavior {
    target_origin_id       = "${var.origin_id}"
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    forwarded_values {
      query_string = true
      headers = ["*"]

      cookies {
        forward = "all"
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

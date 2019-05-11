locals {
  workspace_suffix = "${terraform.workspace == "default" ? "" : format(".%s", terraform.workspace)}"
  environment_suffix = "${var.environment == "prod" ? "" : var.environment}"
  resource_suffix = "${format("%s%s", local.environment_suffix, local.workspace_suffix)}"
  origin_id = "api"
  dns_record = "api.${local.resource_suffix}"
  dns_zone = "caronae.org"
}

data "aws_route53_zone" "caronae" {
  name = "${local.dns_zone}"
}

resource "aws_route53_record" "api" {
  zone_id = "${data.aws_route53_zone.caronae.zone_id}"
  name    = "${local.dns_record}"
  type    = "A"

  alias {
    name                   = "${aws_cloudfront_distribution.api.domain_name}"
    zone_id                = "${aws_cloudfront_distribution.api.hosted_zone_id}"
    evaluate_target_health = true
  }
}

resource "aws_cloudfront_distribution" "api" {
  enabled             = true
  aliases             = ["${local.dns_record}.${local.dns_zone}"]

  origin {
    domain_name = "${module.dns.origin_fqdn}"
    origin_id   = "${local.origin_id}"

    custom_origin_config {
      origin_protocol_policy = "http-only"
      origin_ssl_protocols = ["TLSv1.2"]
      http_port = "8000"
      https_port = "443"
    }
  }

  default_cache_behavior {
    target_origin_id       = "${local.origin_id}"
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
    acm_certificate_arn = "${module.dns.acm_certificate_arn}"
    ssl_support_method  = "sni-only"
  }

  tags {
    Workspace = "${terraform.workspace}"
    Environment = "${var.environment}"
  }
}

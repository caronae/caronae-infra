variable "environment" {
}

variable "acm_certificate_arn" {
}

variable "api_origin_fqdn" {
}

variable "api_origin_http_port" {
}

variable "api_dns_record" {
}

locals {
  workspace_suffix   = terraform.workspace == "default" ? "" : format(".%s", terraform.workspace)
  environment_suffix = var.environment == "prod" ? "" : var.environment
  resource_suffix    = format("%s%s", local.environment_suffix, local.workspace_suffix)
  dns_zone           = "caronae.org"
  dns_record         = local.resource_suffix
  dns_fqdn           = "${local.dns_record}${local.resource_suffix}"
  main_dns_fqdn      = local.resource_suffix == "" ? local.dns_zone : format("%s.%s", local.resource_suffix, local.dns_zone)
  s3_origin_id       = "website-bucket"
  s3_bucket_name     = "website.${local.resource_suffix == "" ? "" : format("%s.", local.resource_suffix)}caronae"
  api_origin_id      = "api"
}

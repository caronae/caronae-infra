locals {
  workspace_suffix   = terraform.workspace == "default" ? "" : format(".%s", terraform.workspace)
  environment_suffix = var.environment == "prod" ? "" : var.environment
  resource_suffix    = local.environment_suffix != "" || local.workspace_suffix != "" ? format(".%s%s", local.environment_suffix, local.workspace_suffix) : ""
}

module "cdn-api" {
  source              = "./cdn"
  dns_record          = "api${local.resource_suffix}"
  origin_id           = "api"
  origin_fqdn         = module.dns.origin_fqdn
  origin_http_port    = 8000
  acm_certificate_arn = module.dns.acm_certificate_arn
}

module "cdn-ufrj-authentication" {
  source              = "./cdn"
  dns_record          = "ufrj${local.resource_suffix}"
  origin_id           = "ufrj-authentication"
  origin_fqdn         = module.dns.origin_fqdn
  origin_http_port    = 8001
  acm_certificate_arn = module.dns.acm_certificate_arn
}


variable "dns_record" {}
variable "origin_id" {}
variable "origin_fqdn" {}
variable "origin_http_port" {}
variable "acm_certificate_arn" {}

locals {
  dns_zone = "caronae.org"
}

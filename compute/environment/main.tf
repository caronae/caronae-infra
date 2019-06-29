variable "region" {
}

variable "availability_zone" {
}

variable "subnet" {
}

variable "security_group" {
}

variable "iam_profile" {
}

variable "image_tag" {
}

variable "environment" {
}

variable "vpc_id" {
}

resource "aws_eip" "instance" {
  vpc = true
  tags = {
    Name        = "caronae-eip-${terraform.workspace}-${var.environment}"
    Environment = var.environment
    Workspace   = terraform.workspace
  }
}

# module "dns" {
#   source              = "./dns"
#   environment         = var.environment
#   backend_instance_ip = aws_eip.instance.public_ip
# }

# module "volume" {
#   source            = "./volume"
#   environment       = var.environment
#   availability_zone = var.availability_zone
# }

module "instance" {
  source               = "./instance"
  environment          = var.environment
  image_tag            = var.image_tag
  region               = var.region
  availability_zone    = var.availability_zone
  security_group       = var.security_group
  iam_instance_profile = var.iam_profile
  subnet               = var.subnet
  # elastic_ip_id        = aws_eip.instance.id
  # data_volume_id       = module.volume.data_volume
}

# module "website" {
#   source               = "./website"
#   environment          = var.environment
#   acm_certificate_arn  = module.dns.acm_certificate_arn
#   api_origin_fqdn      = module.dns.origin_fqdn
#   api_dns_record       = module.cdn-api.fqdn
#   api_origin_http_port = 8000
# }

module "services" {
  source = "./services"
  cluster_name = var.environment
  region = var.region
  vpc_id = var.vpc_id
  subnet               = var.subnet
  security_group       = var.security_group
}

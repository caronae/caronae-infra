terraform {
  backend "s3" {
    bucket = "terraform.caronae"
    key    = "terraform/terraform.tfstate"
    region = "sa-east-1"
  }
}

variable "region" {
  default = "us-east-1"
}

variable "availability_zone" {
  default = "us-east-1a"
}

provider "aws" {
  version = "~> 2.11.0"
  region  = var.region
}

provider "template" {
  version = "~> 2.1.2"
}

provider "null" {
  version = "~> 2.1.2"
}

module "network" {
  source = "./network"
  region = var.region
}

module "storage" {
  source = "./storage"
}

module "iam" {
  source              = "./iam"
  user_content_bucket = module.storage.user_content_bucket_arn
  backups_bucket      = module.storage.backups_bucket_arn
}

module "compute" {
  source            = "./compute"
  region            = var.region
  availability_zone = var.availability_zone
  subnet            = module.network.subnet
  security_group    = module.network.web_security_group
  iam_profile        = module.iam.instance_iam_profile
  vpc_id            = module.network.vpc_id
}

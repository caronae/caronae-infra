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

module "prod" {
  source            = "./environment"
  environment       = "prod"
  image_tag         = "latest"
  region            = var.region
  availability_zone = var.availability_zone
  subnet            = var.subnet
  security_group    = var.security_group
  iam_profile       = var.iam_profile
}

module "dev" {
  source            = "./environment"
  environment       = "dev"
  image_tag         = "develop"
  region            = var.region
  availability_zone = var.availability_zone
  subnet            = var.subnet
  security_group    = var.security_group
  iam_profile       = var.iam_profile
}

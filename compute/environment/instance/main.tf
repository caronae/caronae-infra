variable "region" {
}

variable "availability_zone" {
}

variable "subnet" {
}

variable "security_group" {
}

variable "iam_instance_profile" {
}

variable "environment" {
}

variable "image_tag" {
}

locals {
  instance_name = terraform.workspace == "default" ? "caronae-${var.environment}" : "caronae-${terraform.workspace}-${var.environment}"
}

resource "aws_ecs_cluster" "default" {
  name = var.environment
}

resource "aws_launch_configuration" "ecs-launch-configuration" {
  name_prefix = "caronae-${var.environment}-ecs-launch-configuration"
  image_id               = "ami-02507631a9f7bc956"
  instance_type          = "t3.micro"
  iam_instance_profile   = var.iam_instance_profile
  security_groups = [var.security_group]

  lifecycle {
    create_before_destroy = true
  }

  associate_public_ip_address = "false"
  key_name = "terraform"

  user_data            = <<EOF
#cloud-config
write_files:
  - path: /etc/ecs/ecs.config
    content: 'ECS_CLUSTER=${aws_ecs_cluster.default.name}'
EOF
}

resource "aws_autoscaling_group" "ecs-autoscaling-group" {
  name = "ecs-autoscaling-group"
  max_size = "1"
  min_size = "1"
  desired_capacity = "1"

  vpc_zone_identifier = [var.subnet]
  launch_configuration = aws_launch_configuration.ecs-launch-configuration.name

  tag {
    key = "Name"
    value = "ECS-myecscluster"
    propagate_at_launch = true
  }
}

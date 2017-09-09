terraform {
  backend "s3" {
    bucket = "caronae"
    key    = "terraform/terraform.tfstate"
    region = "us-east-1"
  }
}

variable "region" { default = "us-east-1" }
provider "aws" {
  region = "${var.region}"
}

resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"
  tags {
    Name = "caronae-${terraform.workspace}"
  }
}

resource "aws_internet_gateway" "default" {
  vpc_id = "${aws_vpc.vpc.id}"
  tags {
    Name = "caronae-igw-${terraform.workspace}"
  }
}

resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.default.id}"
  }

  tags {
    Name = "public-${terraform.workspace}"
    env = "${terraform.workspace}"
  }
}

resource "aws_subnet" "default" {
  vpc_id = "${aws_vpc.vpc.id}"
  cidr_block = "10.0.0.0/24"
  map_public_ip_on_launch = true
  availability_zone = "${var.region}a"

  tags {
    Name = "caronae-default-${terraform.workspace}"
  }
}

resource "aws_subnet" "useless" {
  vpc_id = "${aws_vpc.vpc.id}"
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone = "${var.region}b"

  tags {
    Name = "caronae-useless-${terraform.workspace}"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = "${aws_subnet.default.id}"
  route_table_id = "${aws_route_table.public.id}"
}

resource "aws_security_group" "web-security-group" {
  name = "caronae-web"
  description = "Web server security group"
  vpc_id = "${aws_vpc.vpc.id}"

  tags {
    Name = "caronae-http-ssh-${terraform.workspace}"
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 81
    to_port     = 81
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_iam_policy_document" "caronae_instance_policy_document" {
  statement {
    actions = ["sts:AssumeRole"]
    effect = "Allow"

    principals {
      type = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "caronae_instance" {
  name = "caronae-instance-${terraform.workspace}"
  assume_role_policy = "${data.aws_iam_policy_document.caronae_instance_policy_document.json}"
}

resource "aws_iam_policy" "caronae_instance" {
  name = "caronae-instance-${terraform.workspace}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["iam:*"],
      "Resource": "arn:aws:iam:::instance-profile/"
    },
    {
      "Effect": "Allow",
      "Action": ["iam:*"],
      "Resource": "arn:aws:iam:::policy/"
    },
    {
      "Effect": "Allow",
      "Action": ["iam:*"],
      "Resource": "arn:aws:iam:::role/"
    },
    {
      "Effect": "Allow",
      "Action": ["kms:Decrypt"],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_policy_attachment" "roles_for_caronae_instance" {
  name = "roles-for-caronae-instance-${terraform.workspace}"
  roles = ["${aws_iam_role.caronae_instance.name}"]
  policy_arn = "${aws_iam_policy.caronae_instance.arn}"
}

resource "aws_iam_instance_profile" "caronae_instance" {
  name = "caronae-instance-${terraform.workspace}"
  role = "${aws_iam_role.caronae_instance.name}"
}

data "template_file" "cloud_config" {
  template = "${file("./cloud-config.yml")}"

  vars {
    encrypted_envs = "${file(".encrypted_envs")}"
    region = "${var.region}"
  }
}

resource "aws_instance" "caronae-instance" {
  ami = "ami-4fffc834"
  instance_type = "t2.micro"
  subnet_id = "${aws_subnet.default.id}"
  vpc_security_group_ids = [ "${aws_security_group.web-security-group.id}" ]
  key_name = "terraform"
  iam_instance_profile = "${aws_iam_instance_profile.caronae_instance.id}"
  user_data = "${data.template_file.cloud_config.rendered}"

  tags {
    Name = "caronae-${terraform.workspace}"
  }
}

resource "aws_alb" "api" {
  name            = "caronae-api-${terraform.workspace}"
  internal        = false
  security_groups = [ "${aws_security_group.web-security-group.id}" ]
  subnets         = [ "${aws_subnet.default.id}", "${aws_subnet.useless.id}" ]
}

resource "aws_alb_target_group" "api" {
  name     = "caronae-api-${terraform.workspace}"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "${aws_vpc.vpc.id}"
}

resource "aws_alb_target_group" "ufrj-authentication" {
  name     = "caronae-ufrj-${terraform.workspace}"
  port     = 81
  protocol = "HTTP"
  vpc_id   = "${aws_vpc.vpc.id}"
}

resource "aws_alb_listener" "http" {
  load_balancer_arn = "${aws_alb.api.arn}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${aws_alb_target_group.api.arn}"
    type             = "forward"
  }
}

data "aws_acm_certificate" "caronae" {
  domain   = "*.caronae.com.br"
}

resource "aws_alb_listener" "https" {
  load_balancer_arn = "${aws_alb.api.arn}"
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = "${data.aws_acm_certificate.caronae.arn}"

  default_action {
    target_group_arn = "${aws_alb_target_group.api.arn}"
    type             = "forward"
  }
}

resource "aws_alb_listener_rule" "ufrj-authentication" {
  listener_arn = "${aws_alb_listener.https.arn}"
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = "${aws_alb_target_group.ufrj-authentication.arn}"
  }

  condition {
    field  = "host-header"
    values = ["ufrj-${terraform.workspace}.caronae.com.br"]
  }
}

resource "aws_alb_target_group_attachment" "api" {
  target_group_arn = "${aws_alb_target_group.api.arn}"
  target_id        = "${aws_instance.caronae-instance.id}"
  port             = 80
}

resource "aws_alb_target_group_attachment" "ufrj-authentication" {
  target_group_arn = "${aws_alb_target_group.ufrj-authentication.arn}"
  target_id        = "${aws_instance.caronae-instance.id}"
  port             = 81
}

data "aws_route53_zone" "caronae" {
  name = "caronae.com.br."
}

resource "aws_route53_record" "api" {
  zone_id = "${data.aws_route53_zone.caronae.zone_id}"
  name    = "api2-${terraform.workspace}"
  type    = "A"

  alias {
    name                   = "${aws_alb.api.dns_name}"
    zone_id                = "${aws_alb.api.zone_id}"
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "ufrj" {
  zone_id = "${data.aws_route53_zone.caronae.zone_id}"
  name    = "ufrj-${terraform.workspace}"
  type    = "A"

  alias {
    name                   = "${aws_alb.api.dns_name}"
    zone_id                = "${aws_alb.api.zone_id}"
    evaluate_target_health = true
  }
}

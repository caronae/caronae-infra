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

resource "aws_instance" "caronae-instance" {
  ami = "ami-4fffc834"
  instance_type = "t2.micro"
  subnet_id = "${aws_subnet.default.id}"
  vpc_security_group_ids = [ "${aws_security_group.web-security-group.id}" ]
  key_name = "terraform"

  user_data = <<EOF
#cloud-config

ssh_authorized_keys:
  - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDL9qZDkCmWYXAFjTHJJjWi6Fk2+2P/1ZSVeDGoHhcOSqwq3TSqzg/Rft8jRhTMOQ9lbGXC+qke94X0VMeUw6e+MbtDAi+QNDfq8NOu0fXJe+ngKlN4nzW935e+LqtmN6CytCrL9w4LNPzKcQANFb+g/YzMeoedWLvAkgmqKXXby30/Qz4B5JwPXUMFnvrNw+HsiHaNUc15xLoTPzS11mfREXqbZcFia+uTeMbDqcOcflXP313Jr6l4/wW7nBdbST3wy4L1ylSS3JrwLXkFnTiNuDjOi5uhMxK4VhzDXwEcpqZV9wBFssc6QomKgX2cMSMDGwcLoZi3oukJY+mEadGLDZa7LnjkvuMo91rETTSE1Kjl9n3JoTplF5QM6t7NHqPtFfjbuHSNNQ4egYOsiLQTVx/WBOZTj65UWEptnUpkv6VVi5vp5FoemigzRIxMk/AR1rn7VlxY/gcDtydEhKIZ1eP04dVyqgOMSem4IdXiPoChOb+jRsoxM+T6pl4xPLqL5Qoi8E8LTgEkysABktx98ZfYDC4m7WV+1Hp2CsP9eZ5hV1Buv9GQbmKkNJQyQi9IpDqwbVEKHQB/Wg3nW9/S51GxZmUS1l0m4Q2WMEBPncGuhq5MndGW3HjeAbyXiJzqUL1u7GcnTSE3F1PdrAlGlZQmnfpS1BZ4jbZ7KI+nPw== TW-mcecchi
  - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDIAvy3fgLDLMlsojze1eY5mEkPCfy6SP+LcxlCD3rIF2ZMBHj5xeCpMEmHR1AXoOTWY2GrKaOI3rzg5AKeisTS5e/92859q/HDjDQunj7Q8JzaqsGtwukyWsCeHI/sgZOraADy5BG5lgOKQ244dfDFytZqseo0/kaWMvv2DRGcsSMCfJtn0QBP9lnlik16Fn716r+r7Z1YLiZaO0Tz977PSlewZomVDBja+0VXaCFAp3dBZ3fqJbCpCz6C0ajTu6beQbSqSuy/rwmB5wq9ZOFF33Yld3FQdkYGIYGHPk5yLGhCv+0R0Pg+eSDE5z/TC/7O10e5CAgLEWkl+7bCO8MZ lhanke@thoughtworks.com

packages:
  - git
  - docker

runcmd:
  - pip install docker-compose
  - usermod -a -G docker ec2-user
  - service docker start
EOF

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

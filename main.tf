provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/24"
  tags {
    Name = "caronae"
  }
}

resource "aws_internet_gateway" "default" {
  vpc_id = "${aws_vpc.vpc.id}"
  tags {
    Name = "caronae-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.default.id}"
  }

  tags {
    Name = "public"
    env = "${terraform.workspace}"
  }
}

resource "aws_subnet" "default" {
  vpc_id = "${aws_vpc.vpc.id}"
  cidr_block = "10.0.0.0/24"
  map_public_ip_on_launch = true

  tags {
    Name = "caronae"
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
    Name = "caronae-http-ssh"
  }

  ingress {
    from_port   = 80
    to_port     = 80
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
  ami = "ami-b14ba7a7"
  instance_type = "t2.micro"
  subnet_id = "${aws_subnet.default.id}"
  security_groups = [ "${aws_security_group.web-security-group.id}" ]

  user_data = <<EOF
#cloud-config
ssh_authorized_keys:
  - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDL9qZDkCmWYXAFjTHJJjWi6Fk2+2P/1ZSVeDGoHhcOSqwq3TSqzg/Rft8jRhTMOQ9lbGXC+qke94X0VMeUw6e+MbtDAi+QNDfq8NOu0fXJe+ngKlN4nzW935e+LqtmN6CytCrL9w4LNPzKcQANFb+g/YzMeoedWLvAkgmqKXXby30/Qz4B5JwPXUMFnvrNw+HsiHaNUc15xLoTPzS11mfREXqbZcFia+uTeMbDqcOcflXP313Jr6l4/wW7nBdbST3wy4L1ylSS3JrwLXkFnTiNuDjOi5uhMxK4VhzDXwEcpqZV9wBFssc6QomKgX2cMSMDGwcLoZi3oukJY+mEadGLDZa7LnjkvuMo91rETTSE1Kjl9n3JoTplF5QM6t7NHqPtFfjbuHSNNQ4egYOsiLQTVx/WBOZTj65UWEptnUpkv6VVi5vp5FoemigzRIxMk/AR1rn7VlxY/gcDtydEhKIZ1eP04dVyqgOMSem4IdXiPoChOb+jRsoxM+T6pl4xPLqL5Qoi8E8LTgEkysABktx98ZfYDC4m7WV+1Hp2CsP9eZ5hV1Buv9GQbmKkNJQyQi9IpDqwbVEKHQB/Wg3nW9/S51GxZmUS1l0m4Q2WMEBPncGuhq5MndGW3HjeAbyXiJzqUL1u7GcnTSE3F1PdrAlGlZQmnfpS1BZ4jbZ7KI+nPw== TW-mcecchi
EOF

  tags {
    Name = "caronae-prod"
  }
}

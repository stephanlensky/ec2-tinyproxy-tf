terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.78.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key

  default_tags {
    tags = {
      Project = "ec2-tinyproxy-tf"
    }
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_vpc" "vpc" {
  cidr_block           = var.cidr_vpc
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "ec2-tinyproxy-tf"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
}

resource "aws_subnet" "subnet_public" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = var.cidr_subnet
}

resource "aws_route_table" "rtb_public" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "rta_subnet_public" {
  subnet_id      = aws_subnet.subnet_public.id
  route_table_id = aws_route_table.rtb_public.id
}

resource "aws_security_group" "proxy" {
  name        = "proxy"
  description = "Allow proxy/ssh inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.vpc.id
}

resource "aws_vpc_security_group_ingress_rule" "proxy_ipv4" {
  security_group_id = aws_security_group.proxy.id
  from_port         = var.proxy_port
  to_port           = var.proxy_port
  ip_protocol       = "tcp"
  cidr_ipv4         = var.inbound_ipv4_cidr
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh_ipv4" {
  security_group_id = aws_security_group.proxy.id
  from_port        = 22
  to_port          = 22
  ip_protocol      = "tcp"
  cidr_ipv4        = var.inbound_ipv4_cidr
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.proxy.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv6" {
  security_group_id = aws_security_group.proxy.id
  ip_protocol       = "-1"
  cidr_ipv6         = "::/0"
}

resource "aws_instance" "proxy" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.subnet_public.id
  vpc_security_group_ids      = [aws_security_group.proxy.id]
  associate_public_ip_address = true
  user_data                   = file("./scripts/add-ssh-tinyproxy.yaml")

  tags = {
    Name = "ec2-tinyproxy-tf"
  }
}

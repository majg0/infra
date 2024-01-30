variable "region" {
  description = "The AWS region to create resources in"
  type        = string
}

variable "ami" {
  description = "The Amazon Machine Image id to deploy"
  type        = string
}

provider "aws" {
  region = var.region
}

terraform {
  required_version = ">= 1.0"

  backend "s3" {
    # NOTE: populated by a .tfbackend file
  }
}

#
# VPC
#

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_eip" "nat" {
  domain = "vpc"
  depends_on = [aws_internet_gateway.gw]
}

resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.0.0/24"
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id
}

#
# Private Subnet
#

resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

#
# SSM VPC Endpoints
#

resource "aws_security_group" "ssm_vpc_endpoint_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

locals {
  ssm_services = {
    "ssm"           = "com.amazonaws.${var.region}.ssm",
    "ssm_messages"  = "com.amazonaws.${var.region}.ssmmessages",
    "ec2"           = "com.amazonaws.${var.region}.ec2",
    "ec2_messages"  = "com.amazonaws.${var.region}.ec2messages"
  }
}

resource "aws_vpc_endpoint" "ssm_endpoints" {
  for_each          = local.ssm_services
  vpc_id            = aws_vpc.main.id
  service_name      = each.value
  vpc_endpoint_type = "Interface"
  subnet_ids        = [aws_subnet.public.id]
  security_group_ids = [aws_security_group.ssm_vpc_endpoint_sg.id]
}

resource "aws_vpc_endpoint" "s3_endpoint" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.${var.region}.s3"
  route_table_ids = [aws_route_table.private.id]
}

#
# OpenVPN
#

resource "aws_security_group" "ovpn" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 1194
    to_port     = 1194
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1 # all
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "ovpn" {
  ami           = var.ovpn_ami
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.public.id
  security_groups = [aws_security_group.ovpn.id]
  user_data = <<-EOF
#!/bin/bash
echo bootstrap
EOF

  metadata_options {
    # NOTE: Require the recommended Instance Metadata Service Version 2 (IMDSv2)
    http_tokens   = "required"
  }
}

resource "aws_eip" "ovpn" {
  domain = "vpc"
  depends_on = [aws_internet_gateway.gw]
}

resource "aws_eip_association" "ovpn" {
  instance_id = aws_instance.ovpn.id
  allocation_id = aws_eip.ovpn.id
}

#
# EC2 Instance
#

# resource "aws_instance" "example" {
#   ami           = var.ami
#   instance_type = "t3.micro"
#   subnet_id     = aws_subnet.private.id
# 
#   metadata_options {
#     # NOTE: Require the recommended Instance Metadata Service Version 2 (IMDSv2)
#     http_tokens   = "required"
#   }
# }

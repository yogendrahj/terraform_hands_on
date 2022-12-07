terraform {
  required_version = ">= 1.0.0" # Terraform Core version
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = "eu-west-2"
}

#looking for available AMI's
data "aws_ami" "amazon_linux_2" {
  most_recent      = true
  owners           = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-5.10-hvm*"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

#creating SG
resource "aws_security_group" "server_sg" {
  vpc_id      = aws_vpc.vpc.id
  name = "${var.tag}-terraform-sec-grp"
  tags = {
    Name = var.tag
  }

  dynamic "ingress" {
    for_each = var.server_ports
    iterator = port
    content {
      from_port = port.value
      to_port = port.value
      protocol = "tcp"
      cidr_blocks = var.vpc_cidr
    }
  }

  egress {
    from_port =0
    protocol = "-1"
    to_port =0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#listing AZ's
data "aws_availability_zones" "available" {}
data "aws_region" "current" {}

#creating vpc
resource "aws_vpc" "vpc" {
  cidr_block       = var.vpc_cidr
  instance_tenancy = "default"

  tags = {
    Name = var.vpc_name
  }
  enable_dns_hostnames = true
}

#creating public and private subnet
resource "aws_subnet" "public_subnet_module" {
  for_each = var.public_subnets
  vpc_id     = aws_vpc.vpc.id
  cidr_block = cidrsubnet(var.vpc_cidr, 8, each.value + 100)
  availability_zone       = tolist(data.aws_availability_zones.available.names)[each.value]
  map_public_ip_on_launch = true
  tags = {
    Name = each.key
    Terraform = "true"
  }
}

resource "aws_subnet" "private_subnet_module" {
  for_each = var.private_subnets
  vpc_id     = aws_vpc.vpc.id
  cidr_block = cidrsubnet(var.vpc_cidr, 8, each.value)
  availability_zone       = tolist(data.aws_availability_zones.available.names)[each.value]
  tags = {
    Name = each.key
    Terraform = "true"
  }
}

#creating ec2 instance using moule block
module "server1" {
  source = "D:/Terraform/terraform_hands_on/Lab_02/Lab_02_d/server"
  subnet_id = aws_subnet.public_subnet_module["public_subnet_1"].id
  ami             = data.aws_ami.amazon_linux_2.id
  security_groups = [aws_security_group.server_sg.id]
}

output "public_ip" {
  value = module.server1.public_ip
 }


 output "public_dns" {
  value = module.server1.public_dns
 }

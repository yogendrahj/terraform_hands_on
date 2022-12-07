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

resource "aws_instance" "imported" {
  ami           = lookup(var.ami, terraform.workspace)
  instance_type = var.instance_type
  tags = {
    Name = terraform.workspace
  }
}
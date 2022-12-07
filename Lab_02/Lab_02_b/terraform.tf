terraform {
  required_version = ">= 1.0.0" # Terraform Core version
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}
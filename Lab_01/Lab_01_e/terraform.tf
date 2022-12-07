terraform {
  required_version = ">= 1.0.0" # Terraform Core version
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "4.45.0"
    }
    http = {
      source = "hashicorp/http"
      version = "3.2.1"
    }
    random = {
      source = "hashicorp/random"
      version = "3.4.3"
    }
    local = {
      source = "hashicorp/local"
      version = "2.2.3"
    }
  }
}
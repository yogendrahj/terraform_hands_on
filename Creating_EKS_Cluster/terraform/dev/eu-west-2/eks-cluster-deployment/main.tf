# --- root/main.tf ---

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.60.0"
    }
  }
}

provider "aws" {
  region = local.location
}


locals {
  cwd         = reverse(split("/", path.cwd))
  name        = local.cwd[0]
  location    = local.cwd[1]
  environment = local.cwd[2]
  vpc_cidr    = "10.123.0.0/16"

  tags = {
    project     = "eks_project"
    environment = "dev"
    managedby   = "terraform"
    owner       = "Yogendra Jagadeesh"
  }
}


module "networking" {
  source           = "D:/Terraform/terraform_hands_on/Creating_EKS_Cluster/modules/networking"
  vpc_cidr         = local.vpc_cidr
  tags             = local.tags
  public_sn_count  = 2
  private_sn_count = 2
  availabilityzone = "eu-west-2a"
  azs              = 2
}


module "cluster" {
  source          = "D:/Terraform/terraform_hands_on/Creating_EKS_Cluster/modules/cluster"
  tags            = local.tags
  name            = local.name
  vpc_id          = module.networking.vpc_id
  ec2_ssh_key     = "EKS-Key"
  desired_size    = 2
  min_size        = 1
  max_size        = 5
  public_subnets  = module.networking.public_subnets
  private_subnets = module.networking.private_subnets
}


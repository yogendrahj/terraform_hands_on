# --- root/main.tf ---

#creating required providers
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.46.0"
    }
  }
}

provider "aws" {
  region = "eu-west-2"
}

#defining locals that can be called throughout this script
locals {
  instance_type = "t2.micro"
  location      = "eu-west-2"
  vpc_cidr      = "10.123.0.0/16"
}

#defining module block - networking
module "networking" {
  source           = "D:/Terraform/terraform_hands_on/AWS_Project/three_tier_infra/modules/networking"
  vpc_cidr         = local.vpc_cidr
  access_ip        = var.access_ip
  public_sn_count  = 2
  private_sn_count = 2
  db_subnet_group  = true
  availabilityzone = "eu-weat-2a"
  azs              = 2
}

#defining module block - compute
module "compute" {
  source                 = "D:/Terraform/terraform_hands_on/AWS_Project/three_tier_infra/modules/compute"
  frontend_app_sg        = module.networking.frontend_app_sg
  backend_app_sg         = module.networking.backend_app_sg
  bastion_sg             = module.networking.bastion_sg
  public_subnets         = module.networking.public_subnets
  private_subnets        = module.networking.private_subnets
  bastion_instance_count = 1
  instance_type          = local.instance_type
  key_name               = "intellipaat-test-key-pair-09122022"
  lb_tg_name             = module.loadbalancing.lb_tg_name
  lb_tg                  = module.loadbalancing.lb_tg
}

#defining module block - database
module "database" {
  source               = "D:/Terraform/terraform_hands_on/AWS_Project/three_tier_infra/modules/database"
  db_storage           = 10
  db_engine_version    = "5.7.22"
  db_instance_class    = "db.t2.micro"
  db_name              = var.db_name
  dbuser               = var.dbuser
  dbpassword           = var.dbpassword
  db_identifier        = "three-tier-db"
  skip_db_snapshot     = true
  rds_sg               = module.networking.rds_sg
  db_subnet_group_name = module.networking.db_subnet_group_name[0]
}

#defining module block - loadbalancing
module "loadbalancing" {
  source            = "D:/Terraform/terraform_hands_on/AWS_Project/three_tier_infra/modules/loadbalancing"
  lb_sg             = module.networking.lb_sg
  public_subnets    = module.networking.public_subnets
  tg_port           = 80
  tg_protocol       = "HTTP"
  vpc_id            = module.networking.vpc_id
  app_asg           = module.compute.app_asg
  listener_port     = 80
  listener_protocol = "HTTP"
  azs               = 2
}
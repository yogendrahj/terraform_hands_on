variable "aws_region" {
    type = string
    default = "eu-west-2"
}

variable "vpc_name" {
    type = string
    default = "demo_vpc"
}

variable "vpc_cidr" {
    type = string
    default = "10.0.0.0/16"
}

variable "Lab_01_a_vpc_pub_sn" {
  default = {
    "public_subnet_1" = 1
    "public_subnet_2" = 2
    "public_subnet_3" = 3
  }
}

variable "Lab_01_a_vpc_prvt_sn" {
  default = {
    "private_subnet_1" = 1
    "private_subnet_2" = 2
    "private_subnet_3" = 3
  }
}

variable "variables_subnet_cidr"{
    description = "CIDR block for the variables subnet"
    type = string
    default = "10.0.202.0/24"
}

variable "variables_subnet_az"{
    description = "AZ used variable subnet"
    type = string
    default = "eu-west-2a"
}

variable "variables_subnet_auto_ip"{
    description = "Set automatic IP for variables subnet"
    type = bool
    default = true
}

variable "environment"{
  description = "Environment for deployment"
  type = string
  default = "dev"
}
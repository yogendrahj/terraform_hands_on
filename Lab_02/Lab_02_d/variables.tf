variable "region" {
    type = string
    default = "eu-west-2"
}

variable "instance_type" {
    type = string
    default = "t2.micro"
}

variable "key_name" {
  type = string
  default = "FirstKey"
}

variable "num_of_instance" {
  type = number
  default = 1
}

variable "tag" {
  type = string
  default = "Module-Instance"
}

variable "server-name" {
  type = string
  default = "module-server"
}

variable "ami" {
  type = map
  default = {
    "Test" = "ami-039e314f611dbc210",
    "Production" = "ami-01315de4848c1165e"
  }
}

variable "vpc_name" {
  type    = string
  default = "demo_vpc"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "server_ports" {
  type = list(number)
  description = "server-sec-gr-inbound-rules"
  default = [22, 80, 443]
}

variable "private_subnets" {
  default = {
    "private_subnet_1" = 1
    "private_subnet_2" = 2
    "private_subnet_3" = 3
  }
}

variable "public_subnets" {
  default = {
    "public_subnet_1" = 1
    "public_subnet_2" = 2
    "public_subnet_3" = 3
  }
}

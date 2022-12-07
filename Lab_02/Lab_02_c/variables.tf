variable "region" {
    type = string
    default = "eu-west-2"
}

variable "instance_type" {
    type = string
    default = "t2.micro"
}

variable "ami" {
  type = map
  default = {
    "Test" = "ami-039e314f611dbc210",
    "Production" = "ami-01315de4848c1165e"
  }
}
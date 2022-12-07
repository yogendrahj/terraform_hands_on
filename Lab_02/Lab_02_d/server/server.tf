variable "ami" {}
variable "size" {
  default = "t2.micro"
}

variable "subnet_id" {}
variable "security_groups" {
  type = list(any)
}

resource "aws_instance" "module_test" {
  ami           = var.ami
  instance_type = var.size
  subnet_id = var.subnet_id
  security_groups = var.security_groups
  tags = {
    Name = "module_test"
  }
}

output "public_ip" {
  value = aws_instance.module_test.public_ip
}
output "public_dns" {
  value = aws_instance.module_test.public_dns
}


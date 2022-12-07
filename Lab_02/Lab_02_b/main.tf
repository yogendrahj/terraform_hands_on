provider "aws" {
  region = "eu-west-2"
}

resource "aws_instance" "imported" {
  ami           = "ami-0cff7528ff583bf9a"
  instance_type = "t2.micro"

  tags = {
    Name = "imported"
  }
}

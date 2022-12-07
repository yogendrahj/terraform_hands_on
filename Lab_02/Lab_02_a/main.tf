#configure providers
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "4.45.0"
    }
  }
}

provider "aws" {
  region = "eu-west-2"
}

#retrieve the list of az's in the current aws region
data "aws_region" "current" {}
data "aws_availability_zones" "available" {}

#defining local variables
locals{
    team = "api_mgmt_dev"
    application = "corp_api"
    server_name = "ec2-${var.environment}-api-${var.variables_subnet_az}"
}

#creating vpc
resource "aws_vpc" "Lab_01_a_vpc" {
 cidr_block = var.vpc_cidr
  tags = {
    Name        = var.vpc_name
    Environment = "demo_environment"
    Terraform   = "true"
  }
}

#creating IGW
resource "aws_internet_gateway" "Lab_01_a_vpc_igw" {
  vpc_id = aws_vpc.Lab_01_a_vpc.id

  tags = {
    Name = "Lab_01_a_vpc_igw"
  }
}

#creating NGW
resource "aws_nat_gateway" "Lab_01_a_vpc_ngw" {
  allocation_id = aws_eip.Lab_01_a_vpc_eip.id
  subnet_id     = aws_subnet.Lab_01_a_vpc_pub_sn["public_subnet_1"].id
  depends_on    = [aws_subnet.Lab_01_a_vpc_pub_sn]
  tags = {
    Name = "Lab_01_a_vpc_ngw"
  }
}

#creating EIP for NAT Gateway
resource "aws_eip" "Lab_01_a_vpc_eip" {
  vpc        = true
  depends_on = [aws_internet_gateway.Lab_01_a_vpc_igw]
  tags = {
    Name = "Lab_01_a_vpc_igw_eip"
  }
}

#creating public subnets
resource "aws_subnet" "Lab_01_a_vpc_pub_sn" {
  for_each   = var.Lab_01_a_vpc_pub_sn
  vpc_id     = aws_vpc.Lab_01_a_vpc.id
  cidr_block = cidrsubnet(var.vpc_cidr, 8, each.value + 100)
  availability_zone = tolist(data.aws_availability_zones.available.names)[each.value]
  map_public_ip_on_launch = true
  tags = {
    Name      = each.key
    Terraform = "true"
  }
}

#creating private subnets
resource "aws_subnet" "Lab_01_a_vpc_prvt_sn" {
  for_each   = var.Lab_01_a_vpc_prvt_sn
  vpc_id     = aws_vpc.Lab_01_a_vpc.id
  cidr_block = cidrsubnet(var.vpc_cidr, 8, each.value)
  availability_zone = tolist(data.aws_availability_zones.available.names)[each.value]
  tags = {
    Name      = each.key
    Terraform = "true"
  }
}

#creating public route table
resource "aws_route_table" "Lab_01_a_vpc_pub_rt" {
  vpc_id = aws_vpc.Lab_01_a_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.Lab_01_a_vpc_igw.id
    #nat_gateway_id = aws_nat_gateway.Lab_01_a_vpc_ngw.id
  }
  tags = {
    Name = "Lab_01_a_vpc_pub_rt"
    Terraform = "True"
  }
}

#creating private route table
resource "aws_route_table" "Lab_01_a_vpc_prvt_rt" {
  vpc_id = aws_vpc.Lab_01_a_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    #gateway_id = aws_internet_gateway.Lab_01_a_vpc_igw.id
    nat_gateway_id = aws_nat_gateway.Lab_01_a_vpc_ngw.id
  }
  tags = {
    Name = "Lab_01_a_vpc_prvt_rt"
    Terraform = "True"
  }
}

#creating route table assocication
resource "aws_route_table_association" "public" {
  depends_on     = [aws_subnet.Lab_01_a_vpc_pub_sn]
  route_table_id = aws_route_table.Lab_01_a_vpc_pub_rt.id
  for_each       = aws_subnet.Lab_01_a_vpc_pub_sn
  subnet_id      = each.value.id
}
resource "aws_route_table_association" "private" {
  depends_on     = [aws_subnet.Lab_01_a_vpc_prvt_sn]
  route_table_id = aws_route_table.Lab_01_a_vpc_prvt_rt.id
  for_each       = aws_subnet.Lab_01_a_vpc_prvt_sn
  subnet_id      = each.value.id
}

#looking up for latest Ubuntu AMI 20.04 image
data "aws_ami" "ubuntu_ami" {
  most_recent      = true
  owners           = ["736750855543"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
} 

#creating variables subnet
resource "aws_subnet" "variables-subnet" {
  vpc_id     = aws_vpc.Lab_01_a_vpc.id
  cidr_block = var.variables_subnet_cidr
  availability_zone = var.variables_subnet_az
  map_public_ip_on_launch = var.variables_subnet_auto_ip
  tags = {
    Name      = "sub-variables-${var.variables_subnet_az}"
    Terraform = "true"
  }
}

#creating SG to allow ssh on port 22 from anywhere
resource "aws_security_group" "allow_ssh" {
  name        = "allow_all-ssh"
  description = "Allow SSH inbound traffic"
  vpc_id      = aws_vpc.Lab_01_a_vpc.id

  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  // Terraform removes the default rule
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_ssh"
  }
}

#creating SG to allow Web traffic on port 80 from anywhere
resource "aws_security_group" "web_traffic" {
  name        = "web_traffic-${terraform.workspace}"
  vpc_id      = aws_vpc.Lab_01_a_vpc.id
  description = "Allow port 80"
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Allow port 443"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "Allow all ip and ports outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "vpc-ping" {
  name        = "vpc-ping"
  vpc_id      = aws_vpc.Lab_01_a_vpc.id
  description = "ICMP for Ping Access"
  ingress {
    description = "Allow ICMP Traffic"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "Allow all ip and ports outboun"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#creating ec2 instances i public subnet
resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu_ami.id
  instance_type = "t2.micro"
  subnet_id = aws_subnet.Lab_01_a_vpc_pub_sn["public_subnet_1"].id
  security_groups = [aws_security_group.vpc-ping.id,
  aws_security_group.allow_ssh.id, aws_security_group.web_traffic.id]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.generated.key_name

  connection {
    user = "ubuntu"
    type = "ssh"
    private_key = tls_private_key.generated.private_key_pem
    host        = self.public_ip
  }

  tags = {
    Name = "Ubuntu EC2 Server"
    Owner = local.team
    App = local.application
  }
  lifecycle {
    ignore_changes = [security_groups]
  }
} 

#creating provisioners
provisioner "local_exec" {
    command = "chmod 400 ${local_file.private_key_pem.filename}"
}

provisioner "remote-exec" {
    inline = [
      "sudo rm -rf /tmp",
      "sudo git clone https://github.com/hashicorp/demo-terraform-101 /tmp",
      "sudo sh /tmp/assets/setup-web.sh",
    ]
  }

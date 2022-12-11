#creating required providers
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
}

provider "aws" {
  region = "eu-west-2"
}

#creating blank vpc
resource "aws_vpc" "two_tier_project_vpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "2_tier_project_vpc"
  }
}

/* variable "vpc_id" {}
data "aws_vpc" "vpc" {
  id = var.vpc_id
} */

#creating IGW
resource "aws_internet_gateway" "two_tier_project_igw" {
  vpc_id = aws_vpc.two_tier_project_vpc.id

  tags = {
    Name = "two_tier_project_igw"
  }
}

/* data "aws_internet_gateway" "igw" {
  filter {
    name   = "attachment.vpc-id"
    values = [var.vpc_id]
  }
} */

#creating 2 public subnet
resource "aws_subnet" "public_subnet_1" {
  vpc_id                  = aws_vpc.two_tier_project_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-west-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "public_subnet_1"
  }
}
resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.two_tier_project_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "eu-west-2b"
  map_public_ip_on_launch = true

  tags = {
    Name = "public_subnet_2"
  }
}

#creating 2 private subnet
resource "aws_subnet" "private_subnet_1" {
  vpc_id                  = aws_vpc.two_tier_project_vpc.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "eu-west-2a"
  map_public_ip_on_launch = false

  tags = {
    Name = "private_subnet_1"
  }
}
resource "aws_subnet" "private_subnet_2" {
  vpc_id                  = aws_vpc.two_tier_project_vpc.id
  cidr_block              = "10.0.4.0/24"
  availability_zone       = "eu-west-2b"
  map_public_ip_on_launch = false

  tags = {
    Name = "private_subnet_2"
  }
}

#creating public route table
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.two_tier_project_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.two_tier_project_igw.id
  }
}

#associating public subnets with public route table
resource "aws_route_table_association" "public_route_association_1" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_route_table.id
}
resource "aws_route_table_association" "public_route_association_2" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_route_table.id
}

#creating a public SG for SSH and Web access
resource "aws_security_group" "public_sg" {
  name        = "public_sg"
  description = "Allow SSH inbound traffic"
  vpc_id      = aws_vpc.two_tier_project_vpc.id

  ingress {
    description = "SSH from internet"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Web access from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "public_sg"
  }
}

#creating a private SG
resource "aws_security_group" "private_sg" {
  name        = "private_sg"
  description = "Allow inbound traffic to DB within VPC"
  vpc_id      = aws_vpc.two_tier_project_vpc.id
  ingress {
    description = "DB access within VPC"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  ingress {
    description = "SSH access from public sg"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "private_sg"
  }
}

#creating ALB 
resource "aws_lb" "project_alb" {
  name               = "project-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]
}

#creating SG for ALB
resource "aws_security_group" "alb_sg" {
  name        = "alb-sg"
  description = "security group for alb"
  vpc_id      = aws_vpc.two_tier_project_vpc.id

  ingress {
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#crearting target group for load balancer
resource "aws_lb_target_group" "project_tg" {
  name       = "project-tg"
  port       = 80
  protocol   = "HTTP"
  vpc_id     = aws_vpc.two_tier_project_vpc.id
  depends_on = [aws_vpc.two_tier_project_vpc]
}

#crearting target group attachment for load balancer
resource "aws_lb_target_group_attachment" "project_tg_attachment_1" {
  target_group_arn = aws_lb_target_group.project_tg.arn
  target_id        = aws_instance.web1.id
  port             = 80
  depends_on       = [aws_instance.web1]
}
resource "aws_lb_target_group_attachment" "project_tg_attachment_2" {
  target_group_arn = aws_lb_target_group.project_tg.arn
  target_id        = aws_instance.web2.id
  port             = 80
  depends_on       = [aws_instance.web2]
}

# creating listener for load balancer
resource "aws_lb_listener" "listener_lb" {
  load_balancer_arn = aws_lb.project_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.project_tg.arn
  }
}

#creating public ec2 instance in public sunet a
resource "aws_instance" "web1" {
  ami                         = "ami-04706e771f950937f"
  instance_type               = "t2.micro"
  key_name                    = "intellipaat-test-key-pair-09122022"
  availability_zone           = "eu-west-2a"
  vpc_security_group_ids      = [aws_security_group.public_sg.id]
  subnet_id                   = aws_subnet.public_subnet_1.id
  associate_public_ip_address = true

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install httpd -y
    systemctl start httpd
    systemctl enable httpd
    echo "<html><body><h1>Hi there</h1></body></html>" > /var/www/html/index.html
    EOF

  tags = {
    Name = "web1_instance"
  }
}

#creating public instance in public subnet b
resource "aws_instance" "web2" {
  ami                         = "ami-04706e771f950937f"
  instance_type               = "t2.micro"
  key_name                    = "intellipaat-test-key-pair-09122022"
  availability_zone           = "eu-west-2b"
  vpc_security_group_ids      = [aws_security_group.public_sg.id]
  subnet_id                   = aws_subnet.public_subnet_2.id
  associate_public_ip_address = true

  user_data                   = <<-EOF
        #!/bin/bash
        yum update -y
        yum install httpd -y
        systemctl start httpd
        systemctl enable httpd
        echo "<html><body><h1>Hi there again</h1></body></html>" > /var/www/html/index.html
        EOF

  tags = {
    Name = "web2_instance"
  }
}

#creating DB subnet group
resource "aws_db_subnet_group" "db_subnet" {
  name       = "db_subnet"
  subnet_ids = [aws_subnet.private_subnet_1.id,aws_subnet.private_subnet_2.id]
}

#creating database instance
resource "aws_db_instance" "project_db" {
  allocated_storage    = 5
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t3.micro"
  identifier           = "db-instance"
  db_name              = "project_db"
  username             = "admin"
  password             = "password"
  db_subnet_group_name = aws_db_subnet_group.db_subnet.id
  vpc_security_group_ids = [aws_security_group.private_sg.id]  
  publicly_accessible = false
  skip_final_snapshot  = true
}
resource "aws_vpc" "ecs-vpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "ecs-vpc"
  }
}


resource "aws_internet_gateway" "ecs-igw" {
  vpc_id = aws_vpc.ecs-vpc.id

  tags = {
    Name = "ecs-igw"
  }
}


resource "aws_subnet" "ecs-pub-sn-1" {
  vpc_id     = aws_vpc.ecs-vpc.id
  cidr_block = "10.0.0.0/23"

  tags = {
    Name = "ecs-pub-sn-1"
  }
}

resource "aws_subnet" "ecs-pub-sn-2" {
  vpc_id     = aws_vpc.ecs-vpc.id
  cidr_block = "10.0.2.0/23"

  tags = {
    Name = "ecs-pub-sn-2"
  }
}


resource "aws_subnet" "ecs-prvt-sn-1" {
  vpc_id     = aws_vpc.ecs-vpc.id
  cidr_block = "10.0.8.0/22"

  tags = {
    Name = "ecs-prvt-sn-1"
  }
}

resource "aws_subnet" "ecs-prvt-sn-2" {
  vpc_id     = aws_vpc.ecs-vpc.id
  cidr_block = "10.0.12.0/22"

  tags = {
    Name = "ecs-prvt-sn-2"
  }
}


resource "aws_route_table" "ecs-pub-rt" {
  vpc_id = aws_vpc.ecs-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ecs-igw.id
  }
  tags = {
    Name = "ecs-pub-rt"
  }
}

resource "aws_route_table_association" "ecs-pub-rt-assoc-1" {
  subnet_id      = aws_subnet.ecs-pub-sn-1.id
  route_table_id = aws_route_table.ecs-pub-rt.id
}

resource "aws_route_table_association" "ecs-pub-rt-assoc-2" {
  subnet_id      = aws_subnet.ecs-pub-sn-2.id
  route_table_id = aws_route_table.ecs-pub-rt.id
}


resource "aws_route_table" "ecs-prvt-rt" {
  vpc_id = aws_vpc.ecs-vpc.id

  route {
    cidr_block = "10.0.0.0/16"
    gateway_id = aws_internet_gateway.ecs-igw.id
  }
  tags = {
    Name = "ecs-prvt-rt"
  }
}

resource "aws_route_table_association" "ecs-prvt-rt-assoc-1" {
  subnet_id      = aws_subnet.ecs-prvt-sn-1.id
  route_table_id = aws_route_table.ecs-prvt-rt.id
}

resource "aws_route_table_association" "ecs-prvt-rt-assoc-2" {
  subnet_id      = aws_subnet.ecs-prvt-sn-2.id
  route_table_id = aws_route_table.ecs-prvt-rt.id
}
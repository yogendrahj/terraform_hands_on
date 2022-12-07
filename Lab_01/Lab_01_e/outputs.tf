output "vpc_id"{
    description = "output the id of primary vpc"
    value = aws_vpc.Lab_01_a_vpc.id
}

output "web_server_public_ip"{
    value = aws_instance.web.public_ip
}

output "public_url" {
    description = "public url for our web server"
    value = "https://${aws_instance.web.private_ip}:8080/index.html"
}

output "vpc_information" {
    description = "Information about our VPC"
    value = "Your ${aws_vpc.Lab_01_a_vpc.tags.Environment} VPC has an ID of ${aws_vpc.Lab_01_a_vpc.id}"
}

output "igw_information" {
  description = "Information about your IGW"
  value = "Your ${aws_internet_gateway.Lab_01_a_vpc_igw.tags.Name} IGW has an ID of ${aws_internet_gateway.Lab_01_a_vpc_igw}"
}
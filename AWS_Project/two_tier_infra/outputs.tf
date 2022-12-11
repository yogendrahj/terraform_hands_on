#output the public ip of web1
output "public_ip_web_1" {
    value = aws_instance.web1.public_ip
}

#output the public ip of web2
output "public_ip_web_2" {
    value = aws_instance.web2.public_ip
}

#output the db instace address
output "db_instance_address" {
    value = aws_db_instance.project_db.address
}

#output the dns of load balancer
output "dns_of_load_balancer" {
    value = "${aws_lb.project_alb.dns_name}"
}
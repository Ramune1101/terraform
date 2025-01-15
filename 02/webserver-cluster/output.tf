output "myalb_dns_name" {
    value = aws_lb.test.dns_name
    description = "Web DNS Name"
}
output "myVPC_id" {
  value = aws_vpc.myVPC.id
  description = "VPC ID"
}

output "subnet_id" {
  value = aws_subnet.mysubnet.id
  description = "subnet ID"
}

output "sg_id" {
  value = aws_security_group.mysg.id
  description = "SG_id"
}
# VPC 생성
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc
resource "aws_vpc" "myVPC" {
  cidr_block       = var.vpc_cidr_block

  tags = var.vpc_tags

}

# IGW create and asso
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway_attachment

resource "aws_internet_gateway" "myigw" {
  vpc_id = aws_vpc.myVPC.id
  tags = var.igw_tags
}

# Public Subnet create
resource "aws_subnet" "mysubnet" {
  vpc_id     = aws_vpc.myVPC.id
  cidr_block = var.Subnet_cidr_block
  availability_zone = "ap-northeast-2a"
  tags = var.subnet_tags 
}

# Public Routing Table create
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association

resource "aws_route_table" "mypubtalbe" {
  vpc_id = aws_vpc.myVPC.id
  tags = var.routingtable_tags

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myigw.id
  }
}

resource "aws_route_table_association" "myassoc" {
  subnet_id      = aws_subnet.mysubnet.id
  route_table_id = aws_route_table.mypubtalbe.id
}

# SG


resource "aws_security_group" "mysg" {
  name        = "allow_web"
  description = "Allow HTTP/HTTPS inbound traffic and all outbound traffic"
  vpc_id = aws_vpc.myVPC.id
  tags = var.mysg_tag
  
}

resource "aws_vpc_security_group_ingress_rule" "allow_http" {
  security_group_id = aws_security_group.mysg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "allow_https" {
  security_group_id = aws_security_group.mysg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh" {
  security_group_id = aws_security_group.mysg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}



resource "aws_vpc_security_group_egress_rule" "allow_all_traffic" {
  security_group_id = aws_security_group.mysg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}


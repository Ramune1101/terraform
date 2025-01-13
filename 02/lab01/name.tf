# Provider setting
provider "aws" {
    region = "us-east-2"
  
}

# VPC create
resource "aws_vpc" "myVPC" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name= "myVPC"
  }
}

# Internet Gateway create & VPC connection
resource "aws_internet_gateway" "myIGW" {
  vpc_id = aws_vpc.myVPC.id

  tags = {
    Name = "myIGW"
  }
}


# Pubic Subnet create
resource "aws_subnet" "myPubSubnet" {
  vpc_id     = aws_vpc.myVPC.id
  cidr_block = "10.0.0.0/24"
  map_public_ip_on_launch = true
 tags = {
    Name = "myPubSubnet"
  }
}


# Route Table create & public subnet connection
resource "aws_route_table" "myPubRT" {
  vpc_id = aws_vpc.myVPC.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myIGW.id
  }

  tags = {
    Name = "myPubRT"
  }
}


resource "aws_route_table_association" "myPubRTassoc" {
  subnet_id      = aws_subnet.myPubSubnet.id
  route_table_id = aws_route_table.myPubRT.id
}


# SG create
resource "aws_security_group" "allow_http" {
  name        = "allow_http"
  description = "Allow http inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.myVPC.id

  tags = {
    Name = "allow_http"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_http_ipv4" {
  security_group_id = aws_security_group.allow_http.id
  cidr_ipv4         = "10.0.0.0/24"
  from_port         = 8080
  ip_protocol       = "tcp"
  to_port           = 8080
}


resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.allow_http.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}



# SG Security Group Rule



# EC2 create
resource "aws_instance" "myweb" {
  ami           = "ami-036841078a4b68e14"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.myPubSubnet.id

  vpc_security_group_ids = [aws_security_group.allow_http.id]
  
  user_data_replace_on_change = true   
  user_data = <<-EOF
    #!/bin/bash
    yum -y install httpd
    echo 'MyWEB' > /var/www/html/index.html
    systemctl enable --now httpd
    EOF

  tags = {
    Name = "myweb"
  }
}
# 프로바이더 생성
provider "aws" {
  region = "us-east-2"
}

# aws vpc
resource "aws_vpc" "my_vpc" {
    cidr_block = "10.0.0.0/16"
    enable_dns_hostnames = true
    enable_dns_support = true

    tags = {
    Name = "my_vpc"
  }
}

# internet GW
resource "aws_internet_gateway" "my_IGW" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "my_IGW"
  }
}

# # IGW Attach
# resource "aws_internet_gateway_attachment" "myIGW_att" {
#   internet_gateway_id = aws_internet_gateway.my_IGW.id
#   vpc_id              = aws_vpc.my_vpc.id
# }

# Public RT
resource "aws_route_table" "myPublic_RT" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_IGW.id
  }
}

# default PublicRoute
resource "aws_default_route_table" "deault_Public_Route" {
  default_route_table_id = aws_vpc.my_vpc.default_route_table_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_IGW.id
  }
  tags = {
    Name = "deault_Public_Route"
  }
}

# public_subnet
resource "aws_subnet" "mysubnet" {
  vpc_id     = aws_vpc.my_vpc.id
  availability_zone       = "us-east-2a"
  cidr_block = "10.0.0.0/24"

  tags = {
    Name = "mysubnet"
  }
}

# public_subet1

resource "aws_subnet" "mysubnet1" {
  vpc_id     = aws_vpc.my_vpc.id
  availability_zone       = "us-east-2b"
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "mysubnet1"
  }
}

# aws_route_table_association

resource "aws_route_table_association" "myroute_tanlbe_asso" {
  subnet_id      = aws_subnet.mysubnet.id
  route_table_id = aws_route_table.myPublic_RT.id
}

# aws_route_table_association 1

resource "aws_route_table_association" "myroute_tanlbe_asso1" {
  subnet_id      = aws_subnet.mysubnet1.id
  route_table_id = aws_route_table.myPublic_RT.id
}

# aws_security_group

resource "aws_security_group" "allow_80_22" {
  name        = "allow_80_22"
  description = "Allow 80_22 inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.my_vpc.id

  tags = {
    Name = "allow_80_22"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_80" {
  security_group_id = aws_security_group.allow_80_22.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "allow_22" {
  security_group_id = aws_security_group.allow_80_22.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}


resource "aws_vpc_security_group_egress_rule" "allow_all_traffic" {
  security_group_id = aws_security_group.allow_80_22.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}


# aws_instance

data "aws_ami" "ubuntu" {
  most_recent = true
  
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-20250112"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  subnet_id   = aws_subnet.mysubnet.id

  associate_public_ip_address = true
  user_data = base64encode(<<EOF
    #!/bin/bash
    hostname EC2-1
    yum install httpd -y
    service httpd start
    chkconfig httpd on
    echo "<h1>CloudNet@ EC2-1 Web Server</h1>" > /var/www/html/index.html
    EOF
    )
  tags = {
    Name = "web"
  }
}


# aws_instance2

resource "aws_instance" "web1" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  subnet_id   = aws_subnet.mysubnet1.id

  associate_public_ip_address = true
  user_data = base64encode(<<EOF
     #!/bin/bash
    hostname ELB-EC2-2
    yum install httpd -y
    service httpd start
    chkconfig httpd on
    echo "<h1>CloudNet@ EC2-2 Web Server</h1>" > /var/www/html/index.html
    EOF
    )
  tags = {
    Name = "web1"
  }
}

# aws_EIP
# resource "aws_eip" "lb" {
#   instance = aws_instance.web.id
#   domain   = "vpc"
#   vpc = true

# }

# resource "aws_eip" "lb1" {
#   instance = aws_instance.web.id
#   domain   = "vpc"
# }

# # aws_EIP_aaso
# resource "aws_eip_association" "eip_assoc" {
#   instance_id   = aws_instance.web_eip.id
#   allocation_id = aws_eip.lb.id
# }

# resource "aws_instance" "web_eip" {
#   ami               = "ami-21f78e11"
#   availability_zone = "us-east-2a"
#   instance_type     = "t2.micro"

#   tags = {
#     Name = "web"
#   }
# }

# resource "aws_eip_association" "eip_assoc1" {
#   instance_id   = aws_instance.web_eip.id
#   allocation_id = aws_eip.lb1.id
# }

# resource "aws_instance" "web2" {
#   ami               = "ami-21f78e11"
#   availability_zone = "us-east-2b"
#   instance_type     = "t2.micro"

#   tags = {
#     Name = "web2"
#   }
# }




# ALB target grp
resource "aws_lb_target_group" "alb-tg-grp" {
  name     = "alb-tg-grp"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.my_vpc.id
}

# ALB

resource "aws_lb" "ALB" {
  name               = "myALB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.allow_80_22.id]
  subnets            = [aws_subnet.mysubnet.id,aws_subnet.mysubnet1.id]
  enable_deletion_protection = false

  tags = {
    Environment = "myALB"
  }
}

# ALB Listner

resource "aws_lb_listener" "alb_listner" {
  load_balancer_arn = aws_lb.ALB.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb-tg-grp.arn
  }
}
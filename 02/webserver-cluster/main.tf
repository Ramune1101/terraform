terraform {
  required_providers {
    aws = {
        source = "hashicorp/aws"
    }
   }
  }

  provider "aws" {
    region = var.region
  }
  
  # 0. 기본 인프라 구성
  # Base Infrastucture
  #

 # vpc
  data "aws_vpc" "default" {
    default = true
  }

 # subnet
  data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

###################
# 1. ASG 생성
###################

# -1. 보안 그룹 생성

resource "aws_security_group" "Myasg_sg" {
  name        = "Myasg_sg"
  description = "Allow SSH,HTTP inbound traffic and all outbound traffic"
  vpc_id      = data.aws_vpc.default.id

  tags = {
    Name = "Myasg_sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh_ipv4" {
  security_group_id = aws_security_group.Myasg_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "allow_http_ipv4" {
  security_group_id = aws_security_group.Myasg_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = var.web_port
  ip_protocol       = "tcp"
  to_port           = var.web_port
}


resource "aws_vpc_security_group_egress_rule" "allow_all_traffic" {
  security_group_id = aws_security_group.Myasg_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

# -2. 시작 템플릿 생성

data "aws_ami" "amazone_2023_ami" {
  most_recent      = true
  owners           = [var.amazone]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-kernel-6.1-x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
  

resource "aws_launch_template" "myasg_template" {
  name = "myasg_template"
  image_id = data.aws_ami.amazone_2023_ami.id
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.Myasg_sg.id]
  user_data = filebase64("./userdata.sh")

  lifecycle {
    create_before_destroy = true
  }
}

# -3. AutoScaling Group 생성
resource "aws_autoscaling_group" "myasg" {

  name                      = "myasg"
  vpc_zone_identifier = data.aws_subnets.default.ids
  min_size                  = var.min_instance
  max_size                  = var.max_instance

  ##############주의##############
  # 로드밸런서
  # 타켓 그룹 arns
  ###############################

  target_group_arns = [ aws_lb_target_group.myLB_tg.arn ]
  depends_on = [ aws_lb_target_group.myLB_tg ]

  launch_template {
  id      = aws_launch_template.myasg_template.id
  }

  tag {
    key                 = "Name"
    value               = "myasg"
    propagate_at_launch = true
    }
}

# 2. ALB 생성


# -1. LB target group 생성
resource "aws_lb_target_group" "myLB_tg" {
  name     = "myLB-tg"
  port     = var.web_port
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.main_route_table_id
}


# -2. LB 구성

resource "aws_lb" "test" {
  name               = "mylb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.Myasg_sg.id]
  subnets            = data.aws_subnets.default.ids
}

# -3. LB listner 구성

resource "aws_lb_listener" "myLB_linstner" {
  load_balancer_arn = aws_lb.test.arn
  port              = "${var.web_port}"
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "404 Not Found"
      status_code  = "404"
    }
  }
}

# -4. LB linstner Rule 구성

resource "aws_lb_listener_rule" "myLB_linstner_rule" {
  listener_arn = aws_lb_listener.myLB_linstner.arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.myLB_tg.arn
  }

  condition {
    path_pattern {
      values = ["/index.html"]
    }
  }
}


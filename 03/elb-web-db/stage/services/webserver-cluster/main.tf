provider "aws" {
  region = "us-east-2"
}

# 작업 절차
# 1. 베이직 인프라 구성

# default vpc
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc


data "aws_vpc" "default" {
  default = true
}

# default subnets
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnets

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# 2. ALB+TG(ASG,EC2*2)
# SG // for ASG
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group

resource "aws_security_group" "asg_8080" {
  name        = "asg_8080"
  description = "Allow 8080 inbound traffic and all outbound traffic"
  vpc_id      = data.aws_vpc.default.id

  tags = {
    Name = "asg_8080"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_8080_ipv4" {
  security_group_id = aws_security_group.asg_8080.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 8080
  ip_protocol       = "tcp"
  to_port           = 8080
}

resource "aws_vpc_security_group_ingress_rule" "allow_22_ipv4" {
  security_group_id = aws_security_group.asg_8080.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.asg_8080.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}


# Lanch Template
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template
# https://developer.hashicorp.com/terraform/language/backend/remote
data "terraform_remote_state" "myremote_state" {
  backend = "s3"
  config = {
    bucket = "bucket-2000-0117"
    key    = "global/s3/terraform.tfstate"
    region = "us-east-2"
  }
  
}
resource "aws_launch_template" "myLT" {
  name = "myLT"

  image_id = data.aws_ami.ubuntu2404.id
  instance_type = "t2.micro"
  key_name = "mykeypair2"

  vpc_security_group_ids = [aws_security_group.asg_8080.id]
   
  user_data = base64encode(templatefile("user-data.sh",{
    db_address = data.terraform_remote_state.myTFstate.output.address ,
    db_port = data.terraform_remote_state.myTFstate.output.port ,
    server_port = 8080
    }))
  

  lifecycle {
    create_before_destroy = true
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "myLT"
    }
  }
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami
data "aws_ami" "ubuntu2404" {
  most_recent      = true
  owners           = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-20250115"]
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

# ASG
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group
# target group arns 주의
resource "aws_autoscaling_group" "myasg" {
  name                      = "myasg"
  max_size                  = 10
  min_size                  = 2
  health_check_grace_period = 300
  health_check_type         = "ELB"
  desired_capacity          = 2
  force_delete              = true
  # depends_ on 까지 주의 하시길 // HCL은 순차적으로 실행하는것이 아니라 의존성 관계로 실행하는듯
  target_group_arns         = [aws_lb_target_group.my-ALB-TG.arn]
  depends_on                = [aws_lb_target_group.my-ALB-TG]

  launch_template {
    id = aws_launch_template.myLT.id
    version = aws_launch_template.myLT.latest_version
  }
  vpc_zone_identifier       = data.aws_subnets.default.ids

  tag {
    key                 = "Name"
    value               = "myasg"
    propagate_at_launch = true
  }
}

# TG + ASG
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group
resource "aws_lb_target_group" "my-ALB-TG" {
  name     = "my-ALB-TG"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

# SG  // for ALB
resource "aws_security_group" "myalb_80" {
  name        = "myalb_80"
  description = "Allow 80 inbound traffic and all outbound traffic"
  vpc_id      = data.aws_vpc.default.id

  tags = {
    Name = "myalb_80"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_80" {
  security_group_id = aws_security_group.myalb_80.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}


resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_myalb" {
  security_group_id = aws_security_group.myalb_80.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

# TF >  미리 구성되어있음
# ALB
# 

# LB
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb

resource "aws_lb" "myalb" {
  name               = "myalb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.myalb_80.id]
  subnets = data.aws_subnets.default.ids

  enable_deletion_protection = true

  tags = {
    Environment = "myalb"
  }
}

# LB Linstner
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener

resource "aws_lb_listener" "myalb_listner" {
  load_balancer_arn = aws_lb.myalb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.my-ALB-TG.arn
  }
}

# Listner Rule > default_action으로 처리됨




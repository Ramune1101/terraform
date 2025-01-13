#프로바이더 설정

provider "aws" {
    region = "us-east-2"
}

# 보안그룹 설정
resource "aws_security_group" "allow_8080" {
  name        = "allow_8080"
  description = "Allow 8080 inbound traffic and all outbound traffic"

  tags = {
    Name = "allow_8080"
  }
}

# 보안그룹 인그레스 룰
resource "aws_vpc_security_group_ingress_rule" "allow_http_8080" {
  security_group_id = aws_security_group.allow_8080.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 8080
  ip_protocol       = "tcp"
  to_port           = 8080
}

# 보안그룹 egress rule
resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.allow_8080.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

# EC2 생성

resource "aws_instance" "myweb" {
  ami           = "ami-036841078a4b68e14"
  instance_type = "t2.micro"

  vpc_security_group_ids = [aws_security_group.allow_8080.id]
  user_data = <<-EOF
    #!/bin/bash
    echo "Hello World" > index.html
    nohup busybox httpd -f -p 8080 &
    EOF

  user_data_replace_on_change = true # 새로만들때마다 유저데이터 지우고 다시실행하는 역할 ==  terraform plan -replace CMD
  tags = {
    Name = "myweb"
  }
}
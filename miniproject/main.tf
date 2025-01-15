# * provier 설정 - provider.tf
##################################
#        기본 인프라 구성         #
##################################

# 1.  VPC 설정 // 신경 써야하는거 enable_dns_hostnames
resource "aws_vpc" "myVPC" {
    cidr_block = "10.123.0.0/16"
    enable_dns_hostnames = true

    tags = {
      Name = "myVPC"
    }
}

# 2.  Public subnet 설정 // 신경 써야하는 것 map_public_ip_on_launch, availability_zone

data "aws_subnets" "pubsub" {
  filter {
    name   = "vpc-id"
    values = [aws_vpc.myVPC.id]
  }
}



resource "aws_subnet" "my_PubSubnet" {
  vpc_id     = aws_vpc.myVPC.id
  cidr_block = "10.123.0.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "my_PubSubnet"
  }
}

# 3.  Internet Gateway 설정
resource "aws_internet_gateway" "myIGW" {
  vpc_id = aws_vpc.myVPC.id

  tags = {
    Name = "myIGW"
  }
}
# 4.  Public Routing 설정

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

# 5.  Public Routing Table Association(Public subnet <-> Public Routing) 설정
resource "aws_main_route_table_association" "myPubRTaso" {
  vpc_id         = aws_vpc.myVPC.id
  route_table_id = aws_route_table.myPubRT.id
}

# 6.  Public Security Group 설정
resource "aws_security_group" "mySG" {
  name        = "mySG"
  description = "Allow all inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.myVPC.id

  tags = {
    Name = "mySG"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_all" {
  security_group_id = aws_security_group.mySG.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_egress_rule" "allow_all" {
  security_group_id = aws_security_group.mySG.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}



##################################
#      EC2 인스턴스 생성          #    
##################################

# 1.  SSH Key 생성
resource "aws_key_pair" "mykeypair3" {
  key_name   = "mykeypair"
  public_key = file("~/.ssh/id_ed25519.pub")
}

# 2.  AMI Data Source 설정

data "aws_ami" "ubuntu2204" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-20241109"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

# 3.  EC2 Instance 생성

resource "aws_instance" "myDevServer" {
  ami           = data.aws_ami.ubuntu2204.id
  instance_type = "t2.micro"

  key_name = aws_key_pair.mykeypair3.id
  vpc_security_group_ids = [aws_security_group.mySG.id]
  subnet_id = aws_subnet.my_PubSubnet.id

  user_data_replace_on_change = true

  provisioner "local-exec" {
    command = templatefile("ssh-config.tpl",{hostname = self.public_ip,
    username = "ubuntu", identityfile = "~/.ssh/id_ed25519"})
    interpreter = ["bash", "-c"]
  }

  user_data = file("userdata.tpl")
  tags = {
    Name = "myDevServer"
  }
}
# EC2 instance
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance
data "aws_ami" "myubuntu2404" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}




resource "aws_instance" "myec2" {
  ami                         = data.aws_ami.myubuntu2404.id
  instance_type               = var.instance_type
  user_data = file("./userdata.sh")
  subnet_id                   = var.subnet_id // 필수 입력 사항, dev에 main에서 지정해 줬음
  associate_public_ip_address = true
  vpc_security_group_ids      = var.sg-ids // 필수 입력 사항, dev에 main에서 지정해 줬음
  key_name                    = var.key_pair
  tags                        = var.ec2_tags
}



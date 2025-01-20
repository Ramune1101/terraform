variable "instance_type" {
  default = "t2.micro"
  description = "instance_type"
  type = string
}

variable "ec2_tags" {
  default = {
    Name = "myec2"
  }
  description = "ec2 instance tag"
  type = map(string)
}


variable "subnet_id" {
  description = "Subnet ID"
  type = string
}

variable "sg-ids" {
  description = "SG IDS"
  type = list
}

variable "key_pair" {
  description = "key pair for ec2"
  type = string
}

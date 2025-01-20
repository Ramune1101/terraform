variable "vpc_cidr_block" {
    default = "10.0.0.0/16"
    description = "myVPC cidr"
    type = string
}

variable "vpc_tags" {
    default = {
        Name = "myVPC"
        }
    description = "VPC tags Name"
    type = map(string)
}

variable "igw_tags" {
    default = {
        Name = "myigw"
        }
    description = "igw tags Name"
    type = map(string)
}

variable "Subnet_cidr_block" {
    default = "10.0.1.0/24"
    description = "vpc_subnet"
    type = string
}

variable "subnet_tags" {
  default = {
    Name = "mysubnet"
  }
  description = "Pulbic Subnet Tag"
  type = map(string)
}

variable "routingtable_tags" {
  default = {
    Name = "mypubtalbe"
  }
  description = "Pulbic pubtalbe Tag"
  type = map(string)
}


variable "mysg_tag" {
  default = {
    Name = "mysg"
  }
}
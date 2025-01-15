variable "region" {
    default = "us-east-2"
    description = "aws_default_region"
    type = string
}

variable "web_port" {
    default = 80
}

variable "amazone" {
    default = "137112412989"
    type = string
}

variable "min_instance" {
    default = 2
}

variable "max_instance" {
    default = 10
}
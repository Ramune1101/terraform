# Terraforem setting
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.83.1"
    }
  }
    backend "s3" {
    bucket = "bucket-2000-0117"
    key    = "global/s3/terraform.tfstate"
    region = "us-east-2"
  } 
}


 

provider "aws" {
  region = "us-east-2"
}

# MySQL DB Instance 설정
resource "aws_db_instance" "myDBinstance" {
  allocated_storage    = 10
  db_name              = "mydb"
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.micro"
  username             = var.dbuser
  password             = var.dbpassword
  parameter_group_name = "default.mysql8.0"
  skip_final_snapshot  = true
}
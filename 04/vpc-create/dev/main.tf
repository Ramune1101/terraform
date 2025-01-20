module "myvpc" {
  source = "../modules/vpc"
}

module "my_ec2" { 
  source = "../modules/ec2"
  subnet_id = module.myvpc.subnet_id // vpc output에서 지정해줘야만 쓸수 있음
  sg-ids = [module.myvpc.sg_id] // vpc output에서 지정해줘야만 쓸수 있음
  key_pair = "mykeypair"
}


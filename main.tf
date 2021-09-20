module "vpc" {
  source = "./modules/vpc"

  stack_name = local.stack_name
}

module "ec2" {
  source = "./modules/ec2"

  stack_name = local.stack_name
  subnet_id  = values(module.vpc.public_subnets)[0].id
  vpc_id  = module.vpc.vpc.id
}

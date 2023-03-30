module "VPC" {
  source = "./modules/VPC"
  vpc_cidr             = var.vpc_cidr
  availability_zone    = var.availability_zone
  public_subnets_cidr  = var.public_subnets_cidr
  private_subnets_cidr = var.private_subnets_cidr
}


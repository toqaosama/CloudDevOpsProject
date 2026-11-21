data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, 2)
}

module "network" {
  source               = "./modules/network"
  name                 = var.project
  vpc_cidr             = var.vpc_cidr
  azs                  = local.azs
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  cluster_name         = "${var.project}-eks"
}

module "ecr" {
  source       = "./modules/ecr"
  repositories = var.ecr_repositories
  prefix       = var.project
}

module "server" {
  source        = "./modules/server"
  name          = "${var.project}-jenkins"
  vpc_id        = module.network.vpc_id
  subnet_id     = module.network.public_subnet_ids[0]
  instance_type = var.jenkins_instance_type
  key_name      = var.key_name
  admin_cidr    = var.admin_cidr
  ecr_repo_arns = module.ecr.repository_arns
}

module "eks" {
  source             = "./modules/eks"
  cluster_name       = "${var.project}-eks"
  cluster_version    = var.eks_version
  private_subnet_ids = module.network.private_subnet_ids
  node_instance_type = var.node_instance_type
  jenkins_role_arn   = module.server.iam_role_arn
}

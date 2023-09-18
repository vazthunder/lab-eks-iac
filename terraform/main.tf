### Static resources

module "network" {
  source = "./modules/network"

  region         = var.region
  project        = var.project
  env            = var.env
  cidr_vpc       = var.cidr_vpc
  cidr_private_a = var.cidr_private_a
  cidr_private_b = var.cidr_private_b
  cidr_public_a  = var.cidr_public_a
  cidr_public_b  = var.cidr_public_b
}

module "bastion" {
  source = "./modules/bastion"

  project               = var.project
  env                   = var.env
  bastion_ami_id        = var.bastion_ami_id
  bastion_instance_type = var.bastion_instance_type
  bastion_storage_size  = var.bastion_storage_size
  key_name              = var.key_name
  vpc_id                = module.network.vpc_id
  subnet-public-a_id    = module.network.subnet-public-a_id
  master-role_name      = aws_iam_role.eks-master.name
}

module "cluster" {
  source = "./modules/cluster"

  providers = {
    aws.assume-master-role = aws.assume-master-role
  }

  project              = var.project
  env                  = var.env
  cidr_vpc             = var.cidr_vpc
  cidr_cluster         = var.cidr_cluster
  worker_instance_type = var.worker_instance_type
  worker_capacity_type = var.worker_capacity_type
  worker_storage_size  = var.worker_storage_size
  worker_initial_size  = var.worker_initial_size
  worker_max_size      = var.worker_max_size
  worker_min_size      = var.worker_min_size
  key_name             = var.key_name
  vpc_id               = module.network.vpc_id
  subnet-public-a_id   = module.network.subnet-public-a_id
  subnet-public-b_id   = module.network.subnet-public-b_id
  subnet-private-a_id  = module.network.subnet-private-a_id
  subnet-private-b_id  = module.network.subnet-private-b_id
  bastion-sg_id        = module.bastion.bastion-sg_id
}


### Dynamic resources

module "repo_app" {
  source = "./modules/registry"
  
  project  = var.project
  env      = var.env
  app_name = "app"
}

module "build_app" {
  source = "./modules/build"

  project             = var.project
  env                 = var.env
  vpc_id              = module.network.vpc_id
  subnet-private-a_id = module.network.subnet-private-a_id
  subnet-private-b_id = module.network.subnet-private-b_id
  codebuild-sg_id     = aws_security_group.codebuild.id
  codebuild-role_arn  = aws_iam_role.codebuild.arn
  master-role_arn     = aws_iam_role.eks-master.arn

  build_app_name      = "app"
  build_branch        = "dev"
  build_source_url    = "https://github.com/vazthunder/myproj-app"
  build_compute_type  = "BUILD_GENERAL1_SMALL"
  build_image         = "aws/codebuild/standard:7.0"
  build_timeout       = "20"
}

terraform {
  backend "s3" { }
}

provider "aws" { }

data "aws_caller_identity" "current" { }

resource "aws_iam_role" "master-role" {
  name = "${var.project}-${var.env}-eks-master-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Principal = {
          Service = "ec2.amazonaws.com",
          Service = "codebuild.amazonaws.com",
          AWS = "${data.aws_caller_identity.current.arn}"
        },
        Effect = "Allow"
      }
    ]
  })

  inline_policy {
    name   = "${var.project}-${var.env}-eks-master-policy"
    policy = jsonencode({
      Version = "2012-10-17",
      Statement = [
        {
          Effect = "Allow",
          Action = "eks:*",
          Resource = "*"
        },
        {
          Effect = "Allow",
          Action = "ecr:*",
          Resource = "*"
        },
        {
          Effect = "Allow",
          Action = "iam:PassRole",
          Resource = "arn:aws:iam::*:role/${var.project}-${var.env}-eks-cluster-role"
        }
      ]
    })
  }
}

provider "aws" {
  alias   = "assume-master-role"

  assume_role {
    role_arn = aws_iam_role.master-role.arn
  }
}


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
  master_role_name      = aws_iam_role.master-role.name
  vpc_id                = module.network.vpc_id
  subnet-public-a_id    = module.network.subnet-public-a_id
}

module "registry" {
  source = "./modules/registry"
  
  project = var.project
  env     = var.env
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

module "cicd" {
  source = "./modules/cicd"
  
  project             = var.project
  env                 = var.env
  vpc_id              = module.network.vpc_id
  subnet-private-a_id = module.network.subnet-private-a_id
  subnet-private-b_id = module.network.subnet-private-b_id
  master_role_name    = aws_iam_role.master-role.name
  code_source         = var.code_source
  code_repository     = var.code_repository
  code_branch         = var.code_branch
  build_compute_type  = var.build_compute_type
  build_image         = var.build_image
  build_timeout       = var.build_timeout
}

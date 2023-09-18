terraform {
  backend "s3" { }
}

provider "aws" { }

data "aws_caller_identity" "current" { }

locals { account_id = data.aws_caller_identity.current.account_id }


resource "aws_iam_role" "eks-master" {
  name = "${var.project}-${var.env}-eks-master"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Effect = "Allow"
      },
      {
        Action = "sts:AssumeRole",
        Principal = {
          AWS = "arn:aws:iam::${local.account_id}:root"
        },
        Condition = {
          StringLike = {
            "aws:PrincipalArn" = [
              "${data.aws_caller_identity.current.arn}",
              "arn:aws:iam::${local.account_id}:role/${var.project}-${var.env}-codebuild"
            ]
          }
        }
        Effect = "Allow"
      }
    ]
  })

  inline_policy {
    name   = "${var.project}-${var.env}-eks-master"
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
          Resource = "arn:aws:iam::${local.account_id}:role/${var.project}-${var.env}-eks-cluster"
        }
      ]
    })
  }
}

provider "aws" {
  alias   = "assume-master-role"

  assume_role {
    role_arn = aws_iam_role.eks-master.arn
  }
}


### Base resources for CodeBuild

resource "aws_security_group" "codebuild" {
  name          = "${var.project}-${var.env}-codebuild"
  vpc_id        = module.network.vpc_id
  description   = "${var.project}-${var.env}-codebuild"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = [ "0.0.0.0/0" ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = [ "0.0.0.0/0" ]
  }

  tags = {
    Group = "${var.project}-${var.env}"
  }
}

resource "aws_iam_role" "codebuild" {
  name = "${var.project}-${var.env}-codebuild"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "codebuild.amazonaws.com"
      }
    }]
  })

  inline_policy {
    name   = "${var.project}-${var.env}-codebuild"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ]
          Resource = "*"
        },
        {
          Effect = "Allow"
          Action = [
            "ec2:CreateNetworkInterface",
            "ec2:CreateNetworkInterfacePermission",
            "ec2:DescribeDhcpOptions",
            "ec2:DescribeNetworkInterfaces",
            "ec2:DeleteNetworkInterface",
            "ec2:DescribeSubnets",
            "ec2:DescribeSecurityGroups",
            "ec2:DescribeVpcs"
          ]
          Resource = "*"
        },
        {
          Effect = "Allow"
          Action = "sts:AssumeRole"
          Resource = "arn:aws:iam::${local.account_id}:role/${var.project}-${var.env}-eks-master"
        }
      ]
    })
  }
}

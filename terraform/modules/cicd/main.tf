resource "aws_security_group" "codebuild-sg" {
  name          = "${var.project}-${var.env}-codebuild-sg"
  vpc_id        = var.vpc_id
  description   = "${var.project}-${var.env}-codebuild-sg"

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
    Name  = "${var.project}-${var.env}-codebuild-sg"
    Group = "${var.project}"
  }
}

resource "aws_s3_bucket" "codebuild-bucket" {
  bucket = "${var.project}-${var.env}-codebuild-bucket"
}

data "aws_iam_policy_document" "codebuild-assume-role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "codebuild-role" {
  name = "${var.project}-${var.env}-codebuild-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "codebuild.amazonaws.com"
      }
    }]
  })

  inline_policy {
    name   = "${var.project}-${var.env}-codebuild-policy"

    policy = jsonencode({
      Version = "2012-10-17",
      Statement = [
        {
          Effect = "Allow",
          Action = [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents",
          ],
          Resource = "*"
        },
        {
          Effect = "Allow",
          Action = [
            "ec2:CreateNetworkInterface",
            "ec2:DescribeDhcpOptions",
            "ec2:DescribeNetworkInterfaces",
            "ec2:DeleteNetworkInterface",
            "ec2:DescribeSubnets",
            "ec2:DescribeSecurityGroups",
            "ec2:DescribeVpcs",
          ],
          Resource = "*"
        },
        {
          Effect = "Allow",
          Action = "s3:*",
          Resource = [
            aws_s3_bucket.codebuild-bucket.arn,
            "${aws_s3_bucket.codebuild-bucket.arn}/*",
          ]
        },
        {
          Effect = "Allow",
          Action = "ec2:CreateNetworkInterfacePermission",
          Resource = "*"
          Condition = {
            test     = "StringEquals"
            variable = "ec2:AuthorizedService"
            values   = ["codebuild.amazonaws.com"]
          }
        },
        {
          Effect = "Allow",
          Action = "sts:AssumeRole",
          Resource = var.master_role_name
        }
      ]
    })
  }
}

resource "aws_codebuild_project" "codebuild-project" {
  name          = "${var.project}-${var.env}-app"
  description   = "${var.project}-${var.env}-app"
  build_timeout = var.build_timeout
  service_role  = aws_iam_role.codebuild-role.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  cache {
    type     = "S3"
    location = aws_s3_bucket.codebuild-bucket.bucket
  }

  environment {
    compute_type                = var.build_compute_type
    image                       = var.build_image
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "EKS_CLUSTER_NAME"
      value = "${var.project}-${var.env}-cluster"
    }

    environment_variable {
      name  = "EKS_MASTER_ROLE"
      value = var.master_role_name
    }
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "${var.project}-${var.env}-app"
      stream_name = "codebuild-logs"
    }
  }

  source {
    type            = var.code_source
    location        = var.code_repository
    git_clone_depth = 1
  }

  source_version = var.code_branch

  vpc_config {
    vpc_id  = var.vpc_id
    subnets = [ var.subnet-private-a_id, var.subnet-private-b_id ]
    security_group_ids = [ aws_security_group.codebuild-sg.id ]
  }

  tags = {
    Name  = "${var.project}-${var.env}-app"
    Group = "${var.project}"
  }
}

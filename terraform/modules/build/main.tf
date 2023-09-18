resource "aws_codebuild_project" "main" {
  name          = "${var.project}-${var.env}-${var.build_app_name}"
  description   = "${var.project}-${var.env}-${var.build_app_name}"
  build_timeout = var.build_timeout 
  service_role  = var.codebuild-role_arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  cache {
    type = "NO_CACHE"
  }

  environment {
    compute_type                = var.build_compute_type
    image                       = var.build_image
    privileged_mode             = true
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "EKS_CLUSTER_NAME"
      value = "${var.project}-${var.env}-cluster"
    }

    environment_variable {
      name  = "EKS_MASTER_ROLE"
      value = var.master-role_arn
    }
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "/aws/codebuild/${var.project}/${var.env}"
      stream_name = "${var.build_app_name}"
    }
  }

  source {
    type      = "GITHUB"
    location  = var.build_source_url
    buildspec = ".codebuild/buildspec.${var.build_branch}.yml"
  }

  source_version         = var.build_branch
  concurrent_build_limit = 1

  vpc_config {
    vpc_id             = var.vpc_id
    subnets            = [ var.subnet-private-a_id, var.subnet-private-b_id ]
    security_group_ids = [ var.codebuild-sg_id ]
  }

  tags = {
    Group = "${var.project}-${var.env}"
  }
}

### WARNING: must connect to Github with OAuth manually via AWS CodeBuild console beforehand

resource "aws_codebuild_webhook" "trigger" {
  project_name = aws_codebuild_project.main.name
  build_type   = "BUILD"

  filter_group {
    filter {
      type    = "EVENT"
      pattern = "PUSH"
    }

    filter {
      type    = "HEAD_REF"
      pattern = "^refs/heads/${var.build_branch}$"
    }
  }
}

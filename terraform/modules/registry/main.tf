resource "aws_ecr_repository" "image-repo" {
  name                 = "${var.project}-${var.env}-${var.build_app_name}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name  = "${var.project}-app-${var.env}"
    Group = "${var.project}"
  }
}

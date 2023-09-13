resource "aws_ecr_repository" "image-repo" {
  name                 = "${var.project}-app-${var.env}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name  = "${var.project}-app-${var.env}"
    Group = "${var.project}"
  }
}

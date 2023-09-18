resource "aws_ecr_repository" "private" {
  name                 = "${var.project}-${var.env}-${var.app_name}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Group = "${var.project}-${var.env}"
  }
}

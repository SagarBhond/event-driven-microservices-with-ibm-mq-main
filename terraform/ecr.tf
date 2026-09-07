locals {
  ecr_repos = toset(["producer", "inventory", "payment", "notification"])
}

resource "aws_ecr_repository" "app" {
  for_each = local.ecr_repos

  name                 = "order-saga-${each.key}"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "order-saga-${each.key}"
  }
}

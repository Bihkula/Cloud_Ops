# Container registry the cluster pulls from. Repo name follows var.app_name, so
# the v2 rebrand renames the repo just by changing that variable.
resource "aws_ecr_repository" "app" {
  name                 = var.app_name
  image_tag_mutability = "IMMUTABLE" # tags are content-addressed (git sha); never overwrite

  image_scanning_configuration {
    scan_on_push = true # Trivy runs in CI too, but native scanning is free defence in depth
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = { Name = "${local.name_prefix}-ecr" }
}

# Keep the registry from growing forever: retain the last 20 images, and expire
# untagged layers after a day.
resource "aws_ecr_lifecycle_policy" "app" {
  repository = aws_ecr_repository.app.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Expire untagged images after 1 day"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 1
        }
        action = { type = "expire" }
      },
      {
        rulePriority = 2
        description  = "Keep only the last 20 tagged images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v", "sha", "cirrus", var.app_name]
          countType     = "imageCountMoreThan"
          countNumber   = 20
        }
        action = { type = "expire" }
      }
    ]
  })
}

moved {
  from = aws_ecr_repository.final_project
  to   = aws_ecr_repository.final_project_repo
}

resource "aws_ecr_repository" "final_project_repo" {
  name                 = "${local.prefix}/final-project-${local.owner}"
  image_tag_mutability = "MUTABLE"

  # Allows terraform destroy to succeed even if images exist in the repo.
  force_delete = true

  image_scanning_configuration {
    scan_on_push = true
  }
}

# Keep only the most recent 10 images to avoid uncontrolled growth.
resource "aws_ecr_lifecycle_policy" "keep_recent" {
  repository = aws_ecr_repository.final_project_repo.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1,
        description  = "Keep last 10 images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 10
        }
        action = { type = "expire" }
      }
    ]
  })
}

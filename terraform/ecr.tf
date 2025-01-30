resource "aws_ecr_repository" "frontend_repo" {
  name                 = "myorg/frontend"
  image_tag_mutability = "IMMUTABLE"
  tags = {
    Name = "frontend-repo"
  }
}

resource "aws_ecr_lifecycle_policy" "frontend_policy" {
  repository = aws_ecr_repository.frontend_repo.name
  policy     = <<EOF
{
  "rules": [
    {
      "rulePriority": 1,
      "description": "Keep only 50 images",
      "selection": {
        "tagStatus": "any",
        "countType": "imageCountMoreThan",
        "countNumber": 50
      },
      "action": {
        "type": "expire"
      }
    }
  ]
}
EOF
}

resource "aws_ecr_repository" "service_a_repo" {
  name                 = "myorg/service-a"
  image_tag_mutability = "IMMUTABLE"
}

resource "aws_ecr_lifecycle_policy" "service_a_policy" {
  repository = aws_ecr_repository.service_a_repo.name
  policy     = <<EOF
{
  "rules": [
    {
      "rulePriority": 1,
      "description": "Keep only 50 images",
      "selection": {
        "tagStatus": "any",
        "countType": "imageCountMoreThan",
        "countNumber": 50
      },
      "action": {
        "type": "expire"
      }
    }
  ]
}
EOF
}

resource "aws_ecr_repository" "service_b_repo" {
  name                 = "myorg/service-b"
  image_tag_mutability = "IMMUTABLE"
}

resource "aws_ecr_lifecycle_policy" "service_b_policy" {
  repository = aws_ecr_repository.service_b_repo.name
  policy     = <<EOF
{
  "rules": [
    {
      "rulePriority": 1,
      "description": "Keep only 50 images",
      "selection": {
        "tagStatus": "any",
        "countType": "imageCountMoreThan",
        "countNumber": 50
      },
      "action": {
        "type": "expire"
      }
    }
  ]
}
EOF
}

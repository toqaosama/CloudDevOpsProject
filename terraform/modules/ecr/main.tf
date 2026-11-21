variable "repositories" {
  description = "One ECR repository per microservice"
  type        = list(string)
}

variable "prefix" {
  type = string
}

resource "aws_ecr_repository" "this" {
  for_each             = toset(var.repositories)
  name                 = "${var.prefix}/${each.value}"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }
}

# keep only the last 10 images in every repository
resource "aws_ecr_lifecycle_policy" "this" {
  for_each   = aws_ecr_repository.this
  repository = each.value.name
  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "keep last 10 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 10
      }
      action = { type = "expire" }
    }]
  })
}

output "repository_urls" {
  value = { for k, r in aws_ecr_repository.this : k => r.repository_url }
}

output "repository_arns" {
  value = [for r in aws_ecr_repository.this : r.arn]
}

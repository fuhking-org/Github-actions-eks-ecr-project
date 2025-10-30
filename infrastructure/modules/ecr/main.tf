resource "aws_ecr_repository" "web_app" {
  name                 = var.web_app_repo_name
  image_tag_mutability = "MUTABLE" # Or IMMUTABLE for stricter versioning

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name    = "${var.project_name}-web-app-ecr"
    Project = var.project_name
  }
}

resource "aws_ecr_repository" "redis" {
  name                 = var.redis_repo_name
  image_tag_mutability = "MUTABLE" # Or IMMUTABLE

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name    = "${var.project_name}-redis-ecr"
    Project = var.project_name
  }
}

output "web_ecr_repo_url" {
  description = "The URL of the ECR repository for the web application."
  value       = aws_ecr_repository.web_app.repository_url
}

output "redis_ecr_repo_url" {
  description = "The URL of the ECR repository for Redis."
  value       = aws_ecr_repository.redis.repository_url
}
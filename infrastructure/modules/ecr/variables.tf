variable "project_name" {
  description = "A unique name for the project."
  type        = string
}

variable "web_app_repo_name" {
  description = "Name for the ECR repository for the web application."
  type        = string
}

variable "redis_repo_name" {
  description = "Name for the ECR repository for Redis."
  type        = string
}
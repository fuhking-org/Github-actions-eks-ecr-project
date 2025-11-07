module "vpc" {
  source = "./modules/vpc"

  project_name    = var.project_name
  vpc_cidr        = var.vpc_cidr
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets
  azs             = var.azs
}

module "ecr" {
  source = "./modules/ecr"

  project_name      = var.project_name
  web_app_repo_name = var.web_app_repo_name
  redis_repo_name   = var.redis_repo_name
}

module "eks" {
  source = "./modules/eks"

  project_name       = var.project_name
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  public_subnet_ids  = module.vpc.public_subnet_ids # For ALB
  instance_types     = var.eks_instance_types
  min_size           = var.eks_min_size
  max_size           = var.eks_max_size
  desired_size       = var.eks_desired_size
}

# Output ECR repository URLs for GitHub Actions
output "web_ecr_repo_url" {
  value       = module.ecr.web_ecr_repo_url
  description = "URL of the ECR repository for the web application"
}

output "redis_ecr_repo_url" {
  value       = module.ecr.redis_ecr_repo_url
  description = "URL of the ECR repository for Redis (if custom image is built)"
}

# Output EKS cluster name for kubectl configuration
output "cluster_name" {
  value       = module.eks.cluster_name
  description = "Name of the EKS cluster"
}

output "kubeconfig_command" {
  description = "Command to update kubeconfig for the EKS cluster."
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
}
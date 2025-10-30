variable "project_name" {
  description = "A unique name for the project, used for resource tagging."
  type        = string
  default     = "my-eks-app"
}

variable "aws_region" {
  description = "The AWS region to deploy resources in."
  type        = string
  default     = "eu-west-1"
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnets" {
  description = "List of CIDR blocks for public subnets."
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnets" {
  description = "List of CIDR blocks for private subnets."
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24"]
}

variable "azs" {
  description = "List of availability zones to use."
  type        = list(string)
  default     = ["eu-west-1a", "eu-west-1b"]
}

variable "web_app_repo_name" {
  description = "Name for the ECR repository for the web application."
  type        = string
  default     = "my-web-app"
}

variable "redis_repo_name" {
  description = "Name for the ECR repository for Redis."
  type        = string
  default     = "my-redis"
}

variable "eks_instance_types" {
  description = "EC2 instance types for the EKS worker nodes."
  type        = list(string)
  default     = ["t3.medium"]
}

variable "eks_min_size" {
  description = "Minimum number of instances in the EKS node group."
  type        = number
  default     = 1
}

variable "eks_max_size" {
  description = "Maximum number of instances in the EKS node group."
  type        = number
  default     = 3
}

variable "eks_desired_size" {
  description = "Desired number of instances in the EKS node group."
  type        = number
  default     = 2
}
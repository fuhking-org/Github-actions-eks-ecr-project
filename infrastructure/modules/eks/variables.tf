variable "project_name" {
  description = "A unique name for the project."
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC."
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for EKS worker nodes."
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs (for ALB access)."
  type        = list(string)
}

variable "instance_types" {
  description = "EC2 instance types for the EKS worker nodes."
  type        = list(string)
}

variable "min_size" {
  description = "Minimum number of instances in the EKS node group."
  type        = number
}

variable "max_size" {
  description = "Maximum number of instances in the EKS node group."
  type        = number
}

variable "desired_size" {
  description = "Desired number of instances in the EKS node group."
  type        = number
}
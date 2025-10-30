resource "aws_eks_cluster" "main" {
  name     = "${var.project_name}-eks"
  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = "1.28" # Specify your desired Kubernetes version

  vpc_config {
    subnet_ids = concat(var.private_subnet_ids, var.public_subnet_ids) # EKS needs access to both
    security_group_ids = [aws_security_group.eks_cluster_sg.id]
    endpoint_private_access = false # Set to true for private endpoint access only
    endpoint_public_access  = true
  }

  # Enable logging for control plane
  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  tags = {
    Name    = "${var.project_name}-eks"
    Project = var.project_name
  }

  # Ensure that IAM Role permissions are propagated
  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
    aws_iam_role_policy_attachment.eks_service_policy,
  ]
}

resource "aws_iam_role" "eks_cluster_role" {
  name = "${var.project_name}-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    Project = var.project_name
  }
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

resource "aws_iam_role_policy_attachment" "eks_service_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

resource "aws_security_group" "eks_cluster_sg" {
  name        = "${var.project_name}-eks-cluster-sg"
  description = "Cluster security group for EKS"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.project_name}-eks-cluster-sg"
    Project = var.project_name
  }
}

resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.project_name}-worker-nodes"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = var.private_subnet_ids # Worker nodes typically in private subnets
  instance_types  = var.instance_types

  scaling_config {
    desired_size = var.desired_size
    max_size     = var.max_size
    min_size     = var.min_size
  }

  update_config {
    max_unavailable_percentage = 50 # Or number, e.g., 1
  }

  # remote_access {
  #   ec2_ssh_key = "your-ssh-key-name" # OPTIONAL: Specify an SSH key for bastion host access
  #   # source_security_group_ids = [aws_security_group.bastion_sg.id] # If you have a bastion host
  # }

  # Ensure the latest AMI is used
  ami_type = "AL2_x86_64" # Amazon Linux 2 (Recommended for EKS)

  # Attach relevant EKS worker node policies
  # https://docs.aws.amazon.com/eks/latest/userguide/managed-node-groups.html#managed-node-group-iam-role
  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.ecr_readonly_policy,
  ]

  tags = {
    Name    = "${var.project_name}-eks-worker-nodes"
    Project = var.project_name
  }
}

resource "aws_iam_role" "eks_node_role" {
  name = "${var.project_name}-eks-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    Project = var.project_name
  }
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "ecr_readonly_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_role.name
}

# IAM Role for Service Account (IRSA) for AWS Load Balancer Controller
resource "aws_iam_policy" "alb_controller_policy" {
  name        = "${var.project_name}-alb-controller-policy"
  description = "IAM policy for AWS Load Balancer Controller"
  policy = file("${path.module}/alb-controller-iam-policy.json") # Policy JSON will be provided below
  tags = {
    Project = var.project_name
  }
}

resource "aws_iam_role" "alb_controller_irsa_role" {
  name        = "${var.project_name}-alb-controller-irsa-role"
  description = "IRSA role for AWS Load Balancer Controller"

  # OIDC provider URL from EKS cluster
  # Replace ACCOUNT_ID with your AWS Account ID and REGION with your AWS region
  # The OIDC provider for EKS will be created by AWS automatically
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${replace(aws_eks_cluster.main.identity[0].oidc[0].issuer, "https://", "")}"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "${replace(aws_eks_cluster.main.identity[0].oidc[0].issuer, "https://", "")}:sub": "system:serviceaccount:kube-system:aws-load-balancer-controller"
        }
      }
    }
  ]
}
EOF
  tags = {
    Project = var.project_name
  }
}

resource "aws_iam_role_policy_attachment" "alb_controller_irsa_attach" {
  policy_arn = aws_iam_policy.alb_controller_policy.arn
  role       = aws_iam_role.alb_controller_irsa_role.name
}

data "aws_caller_identity" "current" {}

output "cluster_name" {
  description = "The name of the EKS cluster."
  value       = aws_eks_cluster.main.name
}

output "alb_controller_irsa_role_arn" {
  description = "The ARN of the IAM role for the AWS Load Balancer Controller IRSA."
  value       = aws_iam_role.alb_controller_irsa_role.arn
}
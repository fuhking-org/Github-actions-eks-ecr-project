resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.project_name}-vpc"
    Project     = var.project_name
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name    = "${var.project_name}-igw"
    Project = var.project_name
  }
}

resource "aws_nat_gateway" "main" {
  count         = length(var.public_subnets) # One NAT Gateway per public subnet
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name    = "${var.project_name}-nat-gateway-${count.index}"
    Project = var.project_name
  }
  depends_on = [aws_internet_gateway.main]
}

resource "aws_eip" "nat" {
  count = length(var.public_subnets)
  domain   = "vpc"
  tags = {
    Name    = "${var.project_name}-nat-eip-${count.index}"
    Project = var.project_name
  }
}

resource "aws_subnet" "public" {
  count                   = length(var.public_subnets)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnets[count.index]
  availability_zone       = var.azs[count.index % length(var.azs)] # Distribute across AZs
  map_public_ip_on_launch = true

  tags = {
    Name                                = "${var.project_name}-public-subnet-${count.index}"
    Project                             = var.project_name
    "kubernetes.io/cluster/${var.project_name}-eks" = "shared" # Required for EKS
    "kubernetes.io/role/elb"            = "1" # Required for ALB
  }
}

resource "aws_subnet" "private" {
  count                   = length(var.private_subnets)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.private_subnets[count.index]
  availability_zone       = var.azs[count.index % length(var.azs)]
  map_public_ip_on_launch = false

  tags = {
    Name                                = "${var.project_name}-private-subnet-${count.index}"
    Project                             = var.project_name
    "kubernetes.io/cluster/${var.project_name}-eks" = "shared" # Required for EKS
    "kubernetes.io/role/internal-elb"   = "1" # Required for internal ALB
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name    = "${var.project_name}-public-rt"
    Project = var.project_name
  }
}

resource "aws_route_table_association" "public" {
  count          = length(var.public_subnets)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  count  = length(var.private_subnets) # One route table per private subnet
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[count.index % length(aws_nat_gateway.main)].id # Distribute NAT Gateways
  }

  tags = {
    Name    = "${var.project_name}-private-rt-${count.index}"
    Project = var.project_name
  }
}

resource "aws_route_table_association" "private" {
  count          = length(var.private_subnets)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}
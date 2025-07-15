# # --- VPC per RDS ---
# resource "aws_vpc" "main" {
#   cidr_block = "10.0.0.0/16"
#   enable_dns_hostnames = true

#   tags = {
#     Name = "weather-scanner-vpc"
#   }
# }

# ################################
# #                              #
# #          RDS Subnet          #
# #                              #
# ################################

# resource "aws_subnet" "private_subnet_a" {
#   vpc_id            = aws_vpc.main.id
#   cidr_block        = "10.0.1.0/24"
#   availability_zone = "${aws_vpc.main.region}a"

#   tags = {
#     Name = "free-tier-rds-private-subnet-a"
#   }
# }

# resource "aws_subnet" "private_subnet_b" {
#   vpc_id            = aws_vpc.main.id
#   cidr_block        = "10.0.2.0/24"
#   availability_zone = "${aws_vpc.main.region}b"

#   tags = {
#     Name = "free-tier-rds-private-subnet-b"
#   }
# }

# resource "aws_db_subnet_group" "default" {
#   subnet_ids = [aws_subnet.private_subnet_a.id, aws_subnet.private_subnet_b.id]
#   name       = "free-tier-rds-subnet-group"
#   description = "A subnet group for free tier RDS instance"
# }

# ################################
# #                              #
# #          EKS Subnet          #
# #                              #
# ################################

# # Sottorete pubblica A (per il bilanciamento del carico, se necessario, e per i nodi worker)
# resource "aws_subnet" "eks_public_subnet_a" {
#   vpc_id = aws_vpc.eks_vpc.id
#   cidr_block = "10.1.1.0/24"
#   availability_zone = "${data.aws_availability_zones.available.names[0]}"
#   map_public_ip_on_launch = true

#   tags = {
#     Name = "eks-free-tier-public-subnet-a"
#     "kubernetes.io/cluster/${aws_eks_cluster.free_tier_eks.name}" = "owned"
#     "kubernetes.io/role/elb" = "1"
#   }
# }

# # Sottorete pubblica B (per la ridondanza)
# resource "aws_subnet" "eks_public_subnet_b" {
#   vpc_id = aws_vpc.eks_vpc.id
#   cidr_block = "10.1.2.0/24"
#   availability_zone = "${data.aws_availability_zones.available.names[1]}"
#   map_public_ip_on_launch = true

#   tags = {
#     Name = "eks-free-tier-public-subnet-b"
#     "kubernetes.io/cluster/${aws_eks_cluster.free_tier_eks.name}" = "owned"
#     "kubernetes.io/role/elb" = "1"
#   }
# }

# ################################
# #                              #
# #      DocumentDB Subnet       #
# #                              #
# ################################


module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.2"

  name = "weather-scanner-vpc"
  cidr = "10.0.0.0/16"

  azs = data.aws_availability_zones.available.names


  database_subnet_names = ["free-tier-rds-private-subnet-a", "free-tier-rds-private-subnet-b"]
  database_subnets    = ["10.0.1.0/24", "10.0.2.0/24"]

  public_subnet_names = ["eks-free-tier-public-subnet-a", "eks-free-tier-public-subnet-b"]
  public_subnets      = ["10.1.1.0/24", "10.1.2.0/24"] # per EKS

  enable_dns_hostnames = true
  enable_dns_support   = true

  public_subnet_tags = {
    # "kubernetes.io/role/elb" = "1"
  }

  private_subnet_tags = {
    # "kubernetes.io/role/internal-elb" = "1"
  }

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }

  vpc_tags = {
    Name = "weather-scanner-vpc"
  }

}

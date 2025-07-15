# ################################
# #                              #
# #          RDS Subnet          #
# #                              #
# ################################

resource "aws_db_subnet_group" "default" {
  subnet_ids = [module.vpc.database_subnets[0], module.vpc.database_subnets[1]]
  name       = "free-tier-rds-subnet-group"
  description = "Subnet group per Amazon RDS"
}

################################
#                              #
#          EKS Subnet          #
#                              #
################################

# # Sottorete pubblica A (per il bilanciamento del carico, se necessario, e per i nodi worker)
# resource "aws_subnet" "eks_public_subnet_a" {
#   vpc_id = module.vpc.vpc_id
#   cidr_block = "10.1.1.0/24"
#   availability_zone = "${data.aws_availability_zones.available.names[0]}"
#   map_public_ip_on_launch = true

#   tags = {
#     Name = "eks-public-subnet-a"
#     "kubernetes.io/cluster/${aws_eks_cluster.free_tier_eks.name}" = "owned"
#     "kubernetes.io/role/elb" = "1"
#   }
# }

# # Sottorete pubblica B (per la ridondanza)
# resource "aws_subnet" "eks_public_subnet_b" {
#   vpc_id = module.vpc.vpc_id
#   cidr_block = "10.1.2.0/24"
#   availability_zone = "${data.aws_availability_zones.available.names[1]}"
#   map_public_ip_on_launch = true

#   tags = {
#     Name = "eks-public-subnet-b"
#     "kubernetes.io/cluster/${aws_eks_cluster.free_tier_eks.name}" = "owned"
#     "kubernetes.io/role/elb" = "1"
#   }
# }

#############################
# #                         #
# #      VPC Generica       #
# #                         #
# ###########################

# Data source per ottenere gli AZ disponibili
data "aws_availability_zones" "available" {
  state = "available"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.2"

  name = "weather-scanner-vpc"
  cidr = "10.0.0.0/16"

  azs = data.aws_availability_zones.available.names

  database_subnets    = ["10.0.1.0/24", "10.0.2.0/24", ] # per RDS
  database_subnet_names = ["rds-private-subnet-a", "rds-private-subnet-b"]

  public_subnets = ["10.0.0.0/24"]

  private_subnets      = ["10.0.5.0/24", "10.0.6.0/24"] # per EKS
  private_subnet_names = ["eks-public-subnet-a", "eks-public-subnet-b"]

  create_database_subnet_group           = false
  create_database_subnet_route_table     = true
  create_database_internet_gateway_route = false

  enable_dns_hostnames = true
  enable_dns_support   = true

  # public_subnet_tags = {
  #   # "kubernetes.io/role/elb" = "1"
  # }

  # private_subnet_tags = {
  #   # "kubernetes.io/role/internal-elb" = "1"
  # }

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }

  vpc_tags = {
    Name = "weather-scanner-vpc"
  }
}

# ################################
# #                              #
# #          RDS Subnet          #
# #                              #
# ################################

resource "aws_db_subnet_group" "default" {
  subnet_ids = module.vpc.database_subnets
  name       = "free-tier-rds-subnet-group"
  description = "Subnet group per Amazon RDS"
}

###########################
#                         #
#      VPC Generica       #
#                         #
###########################

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

  database_subnets    = ["10.0.1.0/24", "10.0.2.0/24"] # per RDS
  database_subnet_names = ["rds-private-subnet-a", "rds-private-subnet-b"]

  public_subnets = ["10.0.0.0/24"]

  create_database_subnet_group           = false
  create_database_subnet_route_table     = true
  create_database_internet_gateway_route = true

  enable_nat_gateway = false
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }

  vpc_tags = {
    Name = "weather-scanner-vpc"
  }
}

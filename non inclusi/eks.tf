# Security Group per accesso a RDS/Postgres e DocumentDB
resource "aws_security_group" "db_access" {
  name        = "eks-db-access"
  description = "Permetti l'accesso a RDS e DocumentDB"
  vpc_id      = module.vpc.vpc_id

  # EKS node group può uscire verso RDS (3306) e DocumentDB (27017)
  egress {
    description = "Verso RDS"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    # cidr_blocks = ["10.0.1.0/24", "10.0.2.0/24"]
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "Verso DocumentDB"
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    # cidr_blocks = ["10.0.5.0/24", "10.0.6.0/24"]
    cidr_blocks = ["0.0.0.0/0"]
  }
  # Permetti tutto outbound se serve
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EKS Cluster + Node Group
module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "20.37.2"

  cluster_name    = "weather-scanner-cluster"
  cluster_version = "1.33"
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.private_subnets

  cluster_endpoint_public_access = true

  # Node Group free-tier
  eks_managed_node_groups = {
    example = {
      ami_type       = "AL2_x86_64"
      instance_types = ["t2.medium"]
      capacity_type  = "SPOT"
      min_size     = 2
      max_size     = 2
      desired_size = 2
    }
  }
}
resource "aws_docdb_cluster" "docdb" {
  cluster_identifier      = "my-docdb-cluster"
  engine                  = "docdb"
  master_username         = "foo"
  master_password         = "mustbeeightchars"
  backup_retention_period = 5
  preferred_backup_window = "07:00-09:00"
  skip_final_snapshot     = true
  db_subnet_group_name    = aws_docdb_subnet_group.weather_scanner_docdb_subnet_group.name
  provider = aws.anto11200
}

resource "aws_docdb_cluster_instance" "default" {
  identifier                   = "mydocdb-cluster-instance"
  cluster_identifier           = aws_docdb_cluster.docdb.id
  instance_class               = "db.t3.medium"
  provider = aws.anto11200
}

resource "aws_security_group" "docdb_sg" {
  name = "weather-scanner-docdb-sg"
  description = "Consente accesso da EKS a DocumentDB"
  vpc_id = module.vpc_docdb.vpc_id

  ingress {
    from_port = 27017 # Porta predefinita di DocumentDB (MongoDB)
    to_port = 27017
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Accesso da security group dei nodi EKS"
  }

  # Regola di uscita: Permetti tutto il traffico in uscita (comune per DB)
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "weather-scanner-docdb-sg"
    Environment = "FreeTier"
  }
  provider = aws.anto11200
}

################################
#                              #
#      DocumentDB Subnet       #
#                              #
################################

resource "aws_docdb_subnet_group" "weather_scanner_docdb_subnet_group" {
  subnet_ids = module.vpc_docdb.public_subnets
  name = "docdb-subnet-group"
  description = "Subnet group per Amazon DocumentDB"
  provider = aws.anto11200
}

#############################
#                           #
#       VPC DocumentDB      #
#                           #
#############################

# Data source per ottenere gli AZ disponibili
data "aws_availability_zones" "available_eu" {
  state = "available"
  provider = aws.anto11200
}

module "vpc_docdb" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.2"

  name = "weather-scanner-vpc"
  cidr = "10.0.0.0/16"

  azs = data.aws_availability_zones.available_eu.names

  public_subnets    = ["10.0.0.0/24", "10.0.1.0/24"] # per RDS
  public_subnet_names = ["docdb-public-subnet-a", "docdb-public-subnet-b"]

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }

  vpc_tags = {
    Name = "weather-scanner-vpc"
  }

  providers = {aws = aws.anto11200}
}


data "dns_a_record_set" "docdb_dynamic_ip" {
  host = aws_docdb_cluster_instance.default.endpoint
}

module "nlb" {
  source = "terraform-aws-modules/alb/aws"

  name               = "weather-scanner-nlb"
  load_balancer_type = "network"
  vpc_id             = module.vpc_docdb.vpc_id
  subnets            = module.vpc_docdb.public_subnets

  security_group_ingress_rules = {
    mongo_traffic = {
      from_port   = 27017
      to_port     = 27017
      ip_protocol = "tcp"
      description = "MongoDB traffic"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }
  security_group_egress_rules = {
    all = {
      ip_protocol = "-1"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }
  listeners = {
    ex-tcp-udp = {
      port     = 27017
      protocol = "TCP_UDP"
      forward = {
        target_group_key = "ex-target"
      }
    }
  }

  target_groups = {
    ex-target = {
      protocol    = "TCP"
      port        = 27017
      target_type = "ip"
      target_id   = data.dns_a_record_set.docdb_dynamic_ip.addrs[0]
    }
  }

  tags = {
    Environment = "Development"
  }
}
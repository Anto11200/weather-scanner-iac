resource "aws_db_instance" "free_tier_rds" {
  allocated_storage      = 20 # 20 GB è solitamente il limite del free tier
  storage_type           = "gp2"
  engine                 = "mysql"
  engine_version         = "8.0.35"      # Scegli una versione supportata e comune
  instance_class         = "db.t2.micro" # db.t2.micro o db.3.micro sono tipici per il free tier
  username               = "admin"
  password               = "mypassword" # CAMBIA QUESTA PASSWORD! Usa variabili d'ambiente o Vault in produzione.
  parameter_group_name   = "default.mysql8.0"
  skip_final_snapshot    = true                     # Non crea uno snapshot finale quando l'istanza viene eliminata
  publicly_accessible    = false                    # Generalmente è una buona pratica impostare su false per sicurezza
  identifier             = "free-tier-rds-instance" # Identificatore univoco per l'istanza DB
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  multi_az               = false
  # Capire come andare a ottenere il db subnet group name dal modulo: https://registry.terraform.io/modules/terraform-aws-modules/rds/aws/latest?tab=outputs - db_subnet_group_id
  db_subnet_group_name   = aws_db_subnet_group.default.name
}


resource "aws_security_group" "rds_sg" {
  name        = "rds-security-group"
  description = "Allow inbound traffic to RDS instance"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 3306 # Porta MySQL
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.1.1.0/24", "10.1.2.0/24"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "free-tier-rds-sg"
  }
}
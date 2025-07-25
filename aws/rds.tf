resource "aws_db_instance" "free_tier_rds" {
  allocated_storage      = 20 # Limite del free tier
  storage_type           = "gp2"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  username               = "admin"
  password               = "mypassword"
  parameter_group_name   = "default.mysql8.0"
  skip_final_snapshot    = true # Non crea uno snapshot finale quando l'istanza viene eliminata
  publicly_accessible    = true
  identifier             = "rds-instance" # Identificatore univoco per l'istanza DB
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  multi_az               = false
  db_subnet_group_name   = aws_db_subnet_group.default.name
}

resource "aws_security_group" "rds_sg" {
  name        = "rds-security-group"
  description = "Allow inbound traffic to RDS instance"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 3306 # Porta MySQL
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "rds-sg"
  }
}
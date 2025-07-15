# Data source per ottenere gli AZ disponibili (già presente in main.tf/network.tf)
data "aws_availability_zones" "available" {
  state = "available"
}

# DocumentDB Subnet Group
# Necessario per distribuire il cluster DocumentDB nelle sottoreti della tua VPC.
# Queste sottoreti dovrebbero essere PRIVATE per sicurezza.
resource "aws_docdb_subnet_group" "weather_scanner_docdb_subnet_group" {
  name       = "weather-scanner-docdb-subnet-group"
  # Sostituisci con gli ID delle tue sottoreti PRIVATE dove vuoi distribuire DocumentDB
  # Assicurati che siano almeno due sottoreti in due AZ diverse per alta disponibilità (anche se qui con 1 istanza non ha senso)
  # Per Free Tier, 2 sottoreti bastano.
  subnet_ids = [aws_subnet.private_subnet_a_rds.id, aws_subnet.private_subnet_b_rds.id] # Esempio usando le subnet della VPC RDS
  # Se preferisci una VPC separata per i database, assicurati di usare le sue sottoreti.
}

# DocumentDB Security Group
# Controlla il traffico in entrata e uscita dal tuo cluster DocumentDB.
# Limita l'accesso solo all'applicazione (es. il tuo cluster EKS) che ne ha bisogno.
resource "aws_security_group" "weather_scanner_docdb_sg" {
  name        = "weather-scanner-docdb-sg"
  description = "Allow inbound traffic to DocumentDB cluster"
  vpc_id      = aws_vpc.main.id # O la VPC in cui risiedono le tue sottoreti DocumentDB

  ingress {
    from_port   = 27017 # Porta predefinita di DocumentDB (MongoDB)
    to_port     = 27017
    protocol    = "tcp"

    source_security_group_id = aws_eks_cluster.free_tier_eks.vpc_config[0].security_group_ids[0] # per EKS
    cidr_blocks = ["10.1.1.0/24", "10.1.2.0/24"]   # Regola di ingresso: Permetti traffico dalla tua applicazione (EKS Security Group)
    description = "Allow traffic from EKS/Application to DocumentDB"
  }
  
  # Regola di uscita: Permetti tutto il traffico in uscita (comune per DB)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "weather-scanner-docdb-sg"
    Environment = "FreeTier"
  }
}
# Gateway Internet (per permettere alla VPC di comunicare con Internet)
resource "aws_internet_gateway" "eks_igw" {
  vpc_id = aws_vpc.eks_vpc.id

  tags = {
    Name = "eks-free-tier-igw"
  }
}

# Tabella di routing per il traffico Internet
resource "aws_route_table" "eks_public_rt" {
  vpc_id = aws_vpc.eks_vpc.id

  route {
    cidr_block = "0.0.0.0/0" # Tutto il traffico verso internet
    gateway_id = aws_internet_gateway.eks_igw.id
  }

  tags = {
    Name = "eks-free-tier-public-rt"
  }
}

# Associa la tabella di routing alle sottoreti pubbliche
resource "aws_route_table_association" "public_a_assoc" {
  subnet_id      = aws_subnet.public_subnet_a.id
  route_table_id = aws_route_table.eks_public_rt.id
}

resource "aws_route_table_association" "public_b_assoc" {
  subnet_id      = aws_subnet.public_subnet_b.id
  route_table_id = aws_route_table.eks_public_rt.id
}

# -----------------------------------------------------------------------------
# 2. Ruoli IAM per EKS (Permissions)
# I ruoli IAM danno i permessi ai servizi AWS di fare cose.
# -----------------------------------------------------------------------------
# Ruolo per il piano di controllo EKS
resource "aws_iam_role" "eks_cluster_role" {
  name = "eks-free-tier-cluster-role"

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
}

# Policy (permessi) per il ruolo del cluster EKS
resource "aws_iam_role_policy_attachment" "eks_cluster_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

resource "aws_iam_role_policy_attachment" "eks_service_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

# Ruolo per i nodi worker EKS
resource "aws_iam_role" "eks_node_role" {
  name = "eks-free-tier-node-role"

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
}

# Policy per il ruolo dei nodi worker
resource "aws_iam_role_policy_attachment" "eks_worker_node_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "ec2_container_registry_readonly_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_role.name
}

# -----------------------------------------------------------------------------
# 3. Creazione del Cluster EKS
# Questo è il piano di controllo di Kubernetes.
# -----------------------------------------------------------------------------
resource "aws_eks_cluster" "free_tier_eks" {
  name     = "free-tier-eks-cluster"
  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = "1.28" # Scegli una versione di Kubernetes supportata da EKS

  vpc_config {
    subnet_ids             = [aws_subnet.public_subnet_a.id, aws_subnet.public_subnet_b.id]
    security_group_ids     = []   # EKS crea un security group di default, puoi aggiungerne altri qui
    endpoint_public_access = true # Permette l'accesso pubblico all'API del cluster
    # endpoint_private_access = false # Puoi impostarlo su true per accesso privato da VPC
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy_attachment,
    aws_iam_role_policy_attachment.eks_service_policy_attachment,
  ]

  tags = {
    Name = "free-tier-eks-cluster"
  }
}

# -----------------------------------------------------------------------------
# 4. Creazione del Managed Node Group (Nodi Worker)
# Questo gestisce le istanze EC2 che saranno i tuoi nodi worker.
# -----------------------------------------------------------------------------
resource "aws_eks_node_group" "free_tier_node_group" {
  cluster_name    = aws_eks_cluster.free_tier_eks.name
  node_group_name = "free-tier-node-group"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = [aws_subnet.public_subnet_a.id, aws_subnet.public_subnet_b.id]
  instance_types  = ["t2.micro"] # *** CRUCIALE per il free tier ***
  disk_size       = 20           # 20 GB è solitamente il limite del free tier di EBS
  desired_size    = 1            # Un solo nodo per rimanere nel free tier
  max_size        = 1
  min_size        = 1

  ami_type = "AL2_x86_64" # Tipo di AMI (Amazon Machine Image) per i nodi

  # Assicurati che il cluster sia pronto prima di creare il node group
  depends_on = [
    aws_eks_cluster.free_tier_eks,
    aws_iam_role_policy_attachment.eks_worker_node_policy_attachment,
    aws_iam_role_policy_attachment.eks_cni_policy_attachment,
    aws_iam_role_policy_attachment.ec2_container_registry_readonly_policy_attachment,
  ]

  labels = {
    env = "free-tier"
  }

  tags = {
    Name = "free-tier-eks-node"
  }
}

# -----------------------------------------------------------------------------
# 5. Data Source per ottenere le zone di disponibilità (AZs)
# Usato per rendere la configurazione più flessibile e non hardcoded.
# -----------------------------------------------------------------------------
data "aws_availability_zones" "available" {
  state = "available"
}
resource "aws_security_group" "cluster-sg" {
  name          = "${var.project}-${var.env}-cluster-sg"
  vpc_id        = var.vpc_id
  description   = "${var.project}-${var.env}-cluster-sg"

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [ var.bastion-sg_id ]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [ var.cidr_vpc ]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    self        = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = [ "0.0.0.0/0" ]
  }

  tags = {
    Name  = "${var.project}-${var.env}-cluster-sg"
    Group = "${var.project}"

    # EKS - Karpenter
    "karpenter.sh/discovery" = "${var.project}-${var.env}-cluster"
  }
}

resource "aws_iam_role" "eks-cluster-role" {
  name = "${var.project}-${var.env}-eks-cluster-role"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "eks-cluster-policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks-cluster-role.name
}

resource "aws_iam_role_policy_attachment" "eks-service-policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.eks-cluster-role.name
}

resource "aws_eks_cluster" "main" {
  provider                  = aws.assume-master-role
  name                      = "${var.project}-${var.env}-cluster"
  role_arn                  = aws_iam_role.eks-cluster-role.arn
  enabled_cluster_log_types = ["api", "audit", "authenticator", "scheduler", "controllerManager"]

  vpc_config {
    endpoint_private_access = true
    endpoint_public_access  = false 
    subnet_ids              = [ var.subnet-private-a_id, var.subnet-private-b_id ]
    security_group_ids      = [ aws_security_group.cluster-sg.id ]
  }

  kubernetes_network_config {
    service_ipv4_cidr = var.cidr_cluster
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Cluster handling.
  depends_on = [
    aws_cloudwatch_log_group.eks-log-group,
    aws_iam_role_policy_attachment.eks-cluster-policy,
    aws_iam_role_policy_attachment.eks-service-policy
  ]

  tags = {
    Name  = "${var.project}-${var.env}-cluster"
    Group = "${var.project}"
  }
}

data "tls_certificate" "eks" {
  url = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks-oidc-provider" {
  client_id_list  = [ "sts.amazonaws.com" ]
  thumbprint_list = [ data.tls_certificate.eks.certificates[0].sha1_fingerprint ]
  url             = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

resource "aws_cloudwatch_log_group" "eks-log-group" {
  name              = "/aws/eks/${var.project}-${var.env}-cluster/main"
  retention_in_days = 14
}

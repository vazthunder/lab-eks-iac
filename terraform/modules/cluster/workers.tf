resource "aws_iam_role" "eks-worker" {
  name = "${var.project}-${var.env}-eks-worker"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "eks-worker-node" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks-worker.name
}

resource "aws_iam_role_policy_attachment" "eks-worker-cni" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks-worker.name
}

resource "aws_iam_role_policy_attachment" "eks-worker-ecr" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks-worker.name
}

resource "aws_iam_role_policy_attachment" "eks-worker-acm" {
  policy_arn = "arn:aws:iam::aws:policy/AWSCertificateManagerReadOnly"
  role       = aws_iam_role.eks-worker.name
}

resource "aws_eks_node_group" "worker" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.project}-${var.env}-worker"
  node_role_arn   = aws_iam_role.eks-worker.arn
  subnet_ids      = [ var.subnet-private-a_id, var.subnet-private-b_id ]
  disk_size       = var.worker_storage_size
  instance_types  = [ var.worker_instance_type ]
  capacity_type   = var.worker_capacity_type
  ami_type        = "AL2_x86_64"

  remote_access {
    ec2_ssh_key               = var.key_name
    source_security_group_ids = [ var.bastion-sg_id ]
  }

  scaling_config {
    desired_size = var.worker_initial_size
    max_size     = var.worker_max_size
    min_size     = var.worker_min_size
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  depends_on = [
    aws_iam_role_policy_attachment.eks-worker-node,
    aws_iam_role_policy_attachment.eks-worker-cni,
    aws_iam_role_policy_attachment.eks-worker-ecr,
    aws_iam_role_policy_attachment.eks-worker-acm
  ]

  tags = {
    Group = "${var.project}-${var.env}"
  }

  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }
}

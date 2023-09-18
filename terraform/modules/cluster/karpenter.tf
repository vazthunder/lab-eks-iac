resource "aws_iam_role" "karpenter-role" {
  name = "${var.project}-${var.env}-karpenter"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRoleWithWebIdentity"
      Effect = "Allow"
      Principal = {
        Federated = "${aws_iam_openid_connect_provider.eks-cluster.arn}"
      }
      Condition = {
        StringEquals = {
          "${trimprefix(aws_eks_cluster.main.identity[0].oidc[0].issuer, "https://")}:sub" = "system:serviceaccount:karpenter:karpenter"
        }
      }
    }]
  })

  inline_policy {
    name   = "${var.project}-${var.env}-karpenter"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = "eks:DescribeCluster"
          Resource = "${aws_eks_cluster.main.arn}"
        },
        {
          Effect = "Allow"
          Action = "iam:PassRole"
          Resource = "${aws_iam_role.eks-worker.arn}"
        },
        {
          Effect = "Allow"
          Action = [
            "sqs:DeleteMessage", 
            "sqs:GetQueueUrl", 
            "sqs:GetQueueAttributes", 
            "sqs:ReceiveMessage"
          ]
          Resource = "${aws_sqs_queue.karpenter.arn}"
        },
        {
          Effect = "Allow"
          Action = [
            "ec2:DescribeImages", 
            "ec2:RunInstances", 
            "ec2:DescribeSubnets", 
            "ec2:DescribeSecurityGroups", 
            "ec2:DescribeLaunchTemplates", 
            "ec2:DescribeInstances", 
            "ec2:DescribeInstanceTypes", 
            "ec2:DescribeInstanceTypeOfferings", 
            "ec2:DescribeAvailabilityZones", 
            "ec2:DeleteLaunchTemplate", 
            "ec2:CreateTags", 
            "ec2:CreateLaunchTemplate", 
            "ec2:CreateFleet", 
            "ec2:DescribeSpotPriceHistory", 
            "pricing:GetProducts", 
            "ssm:GetParameter"
          ]
          Resource = "*"
        },
        {
          Effect = "Allow"
          Action = [
            "ec2:TerminateInstances", 
            "ec2:DeleteLaunchTemplate" 
          ]
          Resource = "*"
          Condition = {
            StringEquals = {
              "ec2:ResourceTag/karpenter.sh/discovery" = "${var.project}-${var.env}-cluster"
            }
          }
        }
      ]
    })
  }
}

resource "aws_iam_instance_profile" "karpenter" {
  name = "${var.project}-${var.env}-karpenter"
  role = aws_iam_role.eks-worker.name
}

resource "aws_sqs_queue" "karpenter" {
  name                      = "${var.project}-${var.env}-karpenter"
  message_retention_seconds = 300
}

resource "aws_sqs_queue_policy" "karpenter" {
  queue_url = aws_sqs_queue.karpenter.url

  policy = jsonencode({
    Version = "2008-10-17"
    Statement = {
      Resource  = "${aws_sqs_queue.karpenter.arn}"
      Action    = "sqs:SendMessage"
      Principal =  {
        Service = [ "events.amazonaws.com", "sqs.amazonaws.com" ]
      }
      Effect    = "Allow"
    }
  })
}

resource "aws_iam_role" "eks_cluster_role" {
  provider = aws.UAT
  name     = var.eks_cluster_role

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

# Defining IAM ROLE POLICY attachment

resource "aws_iam_role_policy_attachment" "AmazonEKSClusterPolicy" {
  provider   = aws.UAT
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKSServicePolicy" {
  provider   = aws.UAT
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

# Defining Creation of EKS Cluster

resource "aws_eks_cluster" "aws_eks" {
  provider = aws.UAT
  name     = var.eks_cluster_name
  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = var.master_version
  vpc_config {
    subnet_ids = "${var.uatprivate-subnets}"
  }

  tags = {
    Name = "Khosla-Test"
  }
}

# Defining Role for EKS NODES

resource "aws_iam_role" "eks_nodes_role" {
  provider = aws.UAT
  name     = var.eks_node_group

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

# Defining Nodes ROLE Attachment

resource "aws_iam_role_policy_attachment" "AmazonEKSWorkerNodePolicy" {
  provider   = aws.UAT
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_nodes_role.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy" {
  provider   = aws.UAT
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_nodes_role.name
}

resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly" {
  provider   = aws.UAT
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_nodes_role.name
}

# Defining creation of EKS WORKER NODES

resource "aws_eks_node_group" "node" {
  provider        = aws.UAT
  cluster_name    = aws_eks_cluster.aws_eks.name
  node_group_name = var.node_group_name
  node_role_arn   = aws_iam_role.eks_nodes_role.arn
  subnet_ids      = "${var.uatprivate-subnets}"

  scaling_config {
    desired_size = 1
    max_size     = 1
    min_size     = 1
  }

  instance_types = [var.node_instances_type]
  disk_size      = var.nodes_disk_size

  remote_access {
    ec2_ssh_key = var.nodes_ssh_key
  }

  tags = {
    Name = "EKS-WorkerNode"
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly,
  ]
}



# Defining Load Balancer Security Group

resource "aws_security_group" "lbsecurity" {
  provider = aws.UAT
  #count      = var.cluster_create_security_group && var.create_eks ? 1 : 0
  name_prefix = var.alb_name
  description = "EKS cluster security group."
  vpc_id      = var.uatvpc
  tags = merge(
    # var.tags,
    {
      "Name" = "${var.alb_name}-eks_lb_sg"
    },
  )
}

resource "aws_security_group_rule" "lb_ingress" {
  provider          = aws.UAT
  description       = "Allow cluster egress access to the Internet."
  protocol          = "TCP"
  security_group_id = aws_security_group.lbsecurity.id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 80
  to_port           = 80
  type              = "ingress"
}

#resource "aws_security_group_rule" "lb_ingress" {
#  description       = "Allow cluster egress access to the Internet."
#  protocol          = "-1"
#  security_group_id = local.cluster_security_group_id
#  cidr_blocks       = ["0.0.0.0/0"]
#  from_port         = 0
#  to_port           = 0
#  type              = "egress"
#}

# Defining creation of internal ALB

resource "aws_lb" "newalb" {
  provider           = aws.UAT
  name               = var.alb_name
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lbsecurity.id]
  subnets            = "${var.uatprivate-subnets}"

  enable_deletion_protection = false

  tags = {
    Name = "Khosla-ALB"
  }
}

# Defining ALB Listener

resource "aws_lb_listener" "front_end_http" {
  provider          = aws.UAT
  load_balancer_arn = aws_lb.newalb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}
# Defining HTTPS Listener

resource "aws_lb_listener" "front_end_https" {
  provider          = aws.UAT
  load_balancer_arn = aws_lb.newalb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}

# Defining Target Group for ALB

resource "aws_lb_target_group" "app_tg" {
  provider    = aws.UAT
  name        = var.target_group_name
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.uatvpc
}

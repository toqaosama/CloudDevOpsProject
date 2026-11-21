variable "cluster_name" {
  type = string
}

variable "cluster_version" {
  type = string
}

variable "private_subnet_ids" {
  description = "Two private subnets in two different availability zones"
  type        = list(string)
}

variable "node_instance_type" {
  type = string
}

variable "jenkins_role_arn" {
  description = "IAM role of the Jenkins server, given admin access to the cluster"
  type        = string
}

# ---------------- cluster IAM role ----------------
resource "aws_iam_role" "cluster" {
  name = "${var.cluster_name}-cluster-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "eks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "cluster" {
  role       = aws_iam_role.cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  version  = var.cluster_version
  role_arn = aws_iam_role.cluster.arn

  vpc_config {
    subnet_ids              = var.private_subnet_ids
    endpoint_private_access = true
    endpoint_public_access  = true
  }

  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }

  depends_on = [aws_iam_role_policy_attachment.cluster]
}

# ---------------- worker node IAM role ----------------
resource "aws_iam_role" "nodes" {
  name = "${var.cluster_name}-node-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "nodes" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy",
  ])
  role       = aws_iam_role.nodes.name
  policy_arn = each.value
}

# ---------------- 2 worker nodes in 2 private subnets / AZs ----------------
# One node group with two subnets does not guarantee one node per AZ,
# so every private subnet gets its own node group with exactly 1 node.
resource "aws_eks_node_group" "this" {
  count           = length(var.private_subnet_ids)
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${var.cluster_name}-ng-${count.index + 1}"
  node_role_arn   = aws_iam_role.nodes.arn
  subnet_ids      = [var.private_subnet_ids[count.index]]
  instance_types  = [var.node_instance_type]

  scaling_config {
    desired_size = 1
    min_size     = 1
    max_size     = 2
  }

  depends_on = [aws_iam_role_policy_attachment.nodes]
}

# EBS CSI driver: provisions the volumes behind the StorageClass used by the MySQL StatefulSet
resource "aws_eks_addon" "ebs_csi" {
  cluster_name = aws_eks_cluster.this.name
  addon_name   = "aws-ebs-csi-driver"
  depends_on   = [aws_eks_node_group.this]
}

# the Jenkins server role may run kubectl against the cluster
resource "aws_eks_access_entry" "jenkins" {
  cluster_name  = aws_eks_cluster.this.name
  principal_arn = var.jenkins_role_arn
}

resource "aws_eks_access_policy_association" "jenkins" {
  cluster_name  = aws_eks_cluster.this.name
  principal_arn = var.jenkins_role_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.jenkins]
}

output "cluster_name" {
  value = aws_eks_cluster.this.name
}

output "cluster_endpoint" {
  value = aws_eks_cluster.this.endpoint
}

output "node_group_names" {
  value = aws_eks_node_group.this[*].node_group_name
}

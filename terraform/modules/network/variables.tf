variable "name" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "azs" {
  description = "Two availability zones"
  type        = list(string)
}

variable "public_subnet_cidrs" {
  type = list(string)
}

variable "private_subnet_cidrs" {
  type = list(string)
}

variable "cluster_name" {
  description = "Used for the kubernetes.io/cluster tags that EKS needs on subnets"
  type        = string
}

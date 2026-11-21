variable "project" {
  description = "Name prefix for all resources"
  type        = string
  default     = "clouddevops"
}

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "jenkins_instance_type" {
  type    = string
  default = "t3.medium"
}

variable "key_name" {
  description = "Existing EC2 key pair used to SSH into the Jenkins server"
  type        = string
}

variable "admin_cidr" {
  description = "CIDR allowed to SSH / open Jenkins UI (e.g. your public IP/32)"
  type        = string
}

variable "eks_version" {
  type    = string
  default = "1.33"
}

variable "node_instance_type" {
  type    = string
  default = "t3.medium"
}

variable "ecr_repositories" {
  type    = list(string)
  default = ["frontend", "auth-service", "roadmap-service"]
}

output "vpc_id" {
  value = module.network.vpc_id
}

output "jenkins_public_ip" {
  value = module.server.public_ip
}

output "jenkins_url" {
  value = "http://${module.server.public_ip}:8080"
}

output "ecr_repository_urls" {
  value = module.ecr.repository_urls
}

output "eks_cluster_name" {
  value = module.eks.cluster_name
}

output "eks_update_kubeconfig" {
  value = "aws eks update-kubeconfig --region ${var.region} --name ${module.eks.cluster_name}"
}

# Remote state in S3 (bucket created by terraform/bootstrap).
# use_lockfile = native S3 state locking (Terraform >= 1.10), no DynamoDB table needed.
terraform {
  backend "s3" {
    bucket       = "clouddevops-tfstate-toqaosama"
    key          = "clouddevops/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}

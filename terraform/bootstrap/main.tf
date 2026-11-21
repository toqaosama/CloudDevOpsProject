# One-time bootstrap: creates the S3 bucket that stores the Terraform state
# of the main stack (terraform/). Run it once with local state:
#   cd terraform/bootstrap && terraform init && terraform apply
terraform {
  required_version = ">= 1.10"
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 6.0" }
  }
}

provider "aws" {
  region = var.region
}

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "state_bucket_name" {
  description = "Globally unique name of the state bucket (must match terraform/backend.tf)"
  type        = string
  default     = "clouddevops-tfstate-toqaosama"
}

resource "aws_s3_bucket" "state" {
  bucket = var.state_bucket_name
  tags   = { Project = "CloudDevOpsProject", Purpose = "terraform-state" }
}

resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id
  rule {
    apply_server_side_encryption_by_default { sse_algorithm = "AES256" }
  }
}

resource "aws_s3_bucket_public_access_block" "state" {
  bucket                  = aws_s3_bucket.state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

output "state_bucket" {
  value = aws_s3_bucket.state.bucket
}

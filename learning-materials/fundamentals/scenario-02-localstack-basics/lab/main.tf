terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# TODO: Configure AWS provider for LocalStack
# HINT: Set access_key = "test", secret_key = "test", region = "us-east-1"
# HINT: Add endpoints block with s3 = "http://localhost:4566" and dynamodb = "http://localhost:4566"
# HINT: Set skip_credentials_validation, skip_metadata_api_check, skip_requesting_account_id to true

# Variables
variable "bucket_name" {
  description = "Name of S3 bucket"
  default     = "raw-uploads-bucket"
  type        = string
}

variable "table_name" {
  description = "Name of DynamoDB table"
  default     = "users-table"
  type        = string
}

variable "user_id" {
  description = "Sample user ID"
  default     = "user-123"
  type        = string
}

variable "environment" {
  description = "Environment tag"
  default     = "dev"
  type        = string
}

# TODO: Create S3 bucket resource
# HINT: resource "aws_s3_bucket" "data" { bucket = var.bucket_name }

# TODO: Enable S3 bucket versioning
# HINT: Use aws_s3_bucket_versioning resource, set status = "Enabled"

# TODO: Create S3 object resource
# HINT: resource "aws_s3_object" "sample" { bucket = aws_s3_bucket.data.id, key = "sample-data.json", source = "./sample-data.json" }

# TODO: Create DynamoDB table
# HINT: resource "aws_dynamodb_table" "users" { name = var.table_name, billing_mode = "PAY_PER_REQUEST", hash_key = "user_id", range_key = "timestamp" }
# HINT: Add attribute blocks for user_id (String) and timestamp (String)

# TODO: Create DynamoDB table item
# HINT: resource "aws_dynamodb_table_item" "sample" { table_name = aws_dynamodb_table.users.name, hash_key = "...", range_key = "..." }
# HINT: item = <<ITEM {"user_id": {"S": "${var.user_id}"}, ...} ITEM

# Outputs
output "bucket_name" {
  description = "S3 bucket name"
  value       = try(aws_s3_bucket.data.id, "not created")
}

output "table_name" {
  description = "DynamoDB table name"
  value       = try(aws_dynamodb_table.users.name, "not created")
}

output "s3_endpoint" {
  description = "S3 endpoint URL"
  value       = "http://localhost:4566"
}

output "dynamodb_endpoint" {
  description = "DynamoDB endpoint URL"
  value       = "http://localhost:4566"
}

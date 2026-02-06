# -----------------------------------------------------------------------------
# Scenario 2: LocalStack - AWS Fundamentals (Answer Key)
# -----------------------------------------------------------------------------

# This solution implements a simple serverless data pipeline with:
# - S3 bucket for file uploads
# - S3 object with sample data
# - DynamoDB table for user data
# - DynamoDB item with sample user data

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# -----------------------------------------------------------------------------
# Provider Configuration for LocalStack
# -----------------------------------------------------------------------------
# LocalStack runs on localhost:4566 and mocks AWS services.
# The provider needs special configuration to work with LocalStack.

provider "aws" {
  access_key = "test"           # LocalStack requires these values
  secret_key = "test"           # but doesn't validate them
  region     = "us-east-1"

  endpoints {
    s3       = "http://localhost:4566"
    dynamodb = "http://localhost:4566"
    lambda   = "http://localhost:4566"
  }

  # Skip validation steps that would fail against LocalStack
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id   = true
}

# -----------------------------------------------------------------------------
# Variables
# -----------------------------------------------------------------------------
variable "bucket_name" {
  description = "Name of S3 bucket"
  type        = string
  default     = "raw-uploads-bucket"
}

variable "table_name" {
  description = "Name of DynamoDB table"
  type        = string
  default     = "users-table"
}

variable "user_id" {
  description = "Sample user ID"
  type        = string
  default     = "user-123"
}

variable "environment" {
  description = "Environment tag"
  type        = string
  default     = "dev"
}

# -----------------------------------------------------------------------------
# S3 Bucket
# -----------------------------------------------------------------------------
# S3 (Simple Storage Service) is object storage.
# Good for: images, videos, backups, static files, data lakes.

resource "aws_s3_bucket" "data" {
  bucket = var.bucket_name

  tags = {
    Environment = var.environment
    Purpose     = "raw-uploads"
  }
}

# Enable versioning on the bucket
# Versioning keeps multiple versions of an object.
# Useful for: backup, rollback, protection against accidental deletion.
resource "aws_s3_bucket_versioning" "data" {
  bucket = aws_s3_bucket.data.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Prevent public access (security best practice)
resource "aws_s3_bucket_public_access_block" "data" {
  bucket = aws_s3_bucket.data.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# -----------------------------------------------------------------------------
# S3 Object
# -----------------------------------------------------------------------------
# Create a sample data file for upload
resource "local_file" "sample_data" {
  content = jsonencode({
    users = [
      {
        id    = "user-123"
        name  = "Test User"
        email = "test@example.com"
        role  = "developer"
      },
      {
        id    = "user-456"
        name  = "Another User"
        email = "another@example.com"
        role  = "designer"
      }
    ]
    created_at = "2024-01-01T00:00:00Z"
  })
  filename = "${path.module}/sample-data.json"
}

# Upload the file to S3
resource "aws_s3_object" "sample" {
  bucket = aws_s3_bucket.data.id
  key    = "sample-data.json"
  source = local_file.sample_data.filename

  # Force deletion even if bucket has objects
  # Without this, terraform destroy will fail if objects exist
  force_destroy = true

  tags = {
    Purpose = "sample-data"
  }

  # Ensure file exists before trying to upload
  depends_on = [local_file.sample_data]
}

# -----------------------------------------------------------------------------
# DynamoDB Table
# -----------------------------------------------------------------------------
# DynamoDB is a managed NoSQL database.
# Good for: single-digit millisecond latency, unlimited scale, key-value access.

resource "aws_dynamodb_table" "users" {
  name           = var.table_name
  billing_mode   = "PAY_PER_REQUEST"  # On-demand pricing (no capacity planning)
  hash_key       = "user_id"           # Partition key (required)
  range_key      = "timestamp"         # Sort key (optional, enables sorting)

  # Define attributes for keys (all attributes used in keys must be defined)
  attribute {
    name = "user_id"
    type = "S"  # S = String, N = Number, B = Binary
  }

  attribute {
    name = "timestamp"
    type = "S"
  }

  # Enable server-side encryption
  server_side_encryption {
    enabled = true
  }

  # Point-in-time recovery (disaster recovery)
  point_in_time_recovery {
    enabled = true
  }

  tags = {
    Environment = var.environment
    Purpose     = "user-data"
  }
}

# -----------------------------------------------------------------------------
# DynamoDB Table Item
# -----------------------------------------------------------------------------
# Insert sample data into the table.
# In real scenarios, you'd use application code, not Terraform, for data.

resource "aws_dynamodb_table_item" "sample" {
  table_name = aws_dynamodb_table.users.name
  hash_key   = aws_dynamodb_table.users.hash_key
  range_key  = "${var.user_id}#2024-01-01T00:00:00Z"

  # DynamoDB items use a specific JSON format
  # Each value must have its type specified: {"S": "string"}, {"N": "123"}, etc.
  item = <<ITEM
{
  "user_id": {"S": "${var.user_id}"},
  "timestamp": {"S": "2024-01-01T00:00:00Z"},
  "email": {"S": "user@example.com"},
  "name": {"S": "Test User"},
  "role": {"S": "Developer"},
  "active": {"BOOL": true},
  "login_count": {"N": "42"}
}
ITEM
}

# -----------------------------------------------------------------------------
# Outputs
# -----------------------------------------------------------------------------
# Outputs show important values after terraform apply.
# These can also be used as inputs to other Terraform configurations.

output "bucket_name" {
  description = "Name of the S3 bucket"
  value       = aws_s3_bucket.data.id
}

output "bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.data.arn
}

output "s3_endpoint" {
  description = "LocalStack S3 endpoint for AWS CLI"
  value       = "http://localhost:4566"
}

output "table_name" {
  description = "Name of the DynamoDB table"
  value       = aws_dynamodb_table_users.name
}

output "table_arn" {
  description = "ARN of the DynamoDB table"
  value       = aws_dynamodb_table_users.arn
}

output "dynamodb_endpoint" {
  description = "LocalStack DynamoDB endpoint for AWS CLI"
  value       = "http://localhost:4566"
}

output "sample_user_id" {
  description = "ID of the sample user created"
  value       = var.user_id
}

# -----------------------------------------------------------------------------
# Key Takeaways
# -----------------------------------------------------------------------------
# 1. **S3 Buckets**: Object storage with versioning and access controls
# 2. **S3 Objects**: Individual files with metadata
# 3. **DynamoDB Tables**: NoSQL tables with partition and sort keys
# 4. **DynamoDB Items**: Individual records with typed values
# 5. **LocalStack**: Mock AWS endpoints for local development
# 6. **Tags**: Important for organization, cost allocation, and access control
# 7. **Outputs**: How to expose values for other systems to use

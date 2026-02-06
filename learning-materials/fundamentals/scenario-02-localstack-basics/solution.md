# Solution: LocalStack - AWS Fundamentals

## Complete main.tf

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  access_key = "test"
  secret_key = "test"
  region     = "us-east-1"

  endpoints {
    s3       = "http://localhost:4566"
    dynamodb = "http://localhost:4566"
    lambda   = "http://localhost:4566"
  }

  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id   = true
}

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

# S3 Bucket
resource "aws_s3_bucket" "data" {
  bucket = var.bucket_name

  tags = {
    Environment = var.environment
  }
}

resource "aws_s3_bucket_versioning" "data" {
  bucket = aws_s3_bucket.data.id

  versioning_configuration {
    status = "Enabled"
  }
}

# S3 Object (requires sample-data.json to exist)
resource "aws_s3_object" "sample" {
  bucket = aws_s3_bucket.data.id
  key    = "sample-data.json"
  source = "${path.module}/sample-data.json"

  force_destroy = true

  depends_on = [
    aws_s3_bucket_versioning.data
  ]
}

# DynamoDB Table
resource "aws_dynamodb_table" "users" {
  name           = var.table_name
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "user_id"
  range_key      = "timestamp"

  attribute {
    name = "user_id"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "S"
  }

  tags = {
    Environment = var.environment
  }
}

# DynamoDB Table Item
resource "aws_dynamodb_table_item" "sample" {
  table_name = aws_dynamodb_table.users.name
  hash_key   = aws_dynamodb_table.users.hash_key
  range_key  = "${var.user_id}#2024-01-01T00:00:00Z"

  item = <<ITEM
{
  "user_id": {"S": "${var.user_id}"},
  "timestamp": {"S": "2024-01-01T00:00:00Z"},
  "email": {"S": "user@example.com"},
  "name": {"S": "Test User"}
}
ITEM
}

# Outputs
output "bucket_name" {
  description = "S3 bucket name"
  value       = aws_s3_bucket.data.id
}

output "table_name" {
  description = "DynamoDB table name"
  value       = aws_dynamodb_table.users.name
}

output "table_arn" {
  description = "DynamoDB table ARN"
  value       = aws_dynamodb_table.users.arn
}

output "s3_endpoint" {
  description = "S3 endpoint URL"
  value       = "http://localhost:4566"
}

output "dynamodb_endpoint" {
  description = "DynamoDB endpoint URL"
  value       = "http://localhost:4566"
}
```

## sample-data.json

```json
{
  "test": "data",
  "uploaded": "via terraform",
  "timestamp": "2024-01-01T00:00:00Z"
}
```

---

## Explanation

### Provider Configuration
- Uses `test` credentials for LocalStack compatibility
- Redirects S3, DynamoDB, and Lambda to localhost:4566
- Skips credential validation since LocalStack doesn't check

### S3 Resources
- `aws_s3_bucket`: Creates the bucket
- `aws_s3_bucket_versioning`: Enables versioning (separate resource in newer AWS provider)
- `aws_s3_object`: Uploads a file to the bucket
- `depends_on`: Ensures versioning is configured before object upload

### DynamoDB Resources
- `aws_dynamodb_table`: Creates a table with composite key (user_id + timestamp)
- `aws_dynamodb_table_item`: Inserts sample data
- Uses PAY_PER_REQUEST billing for simplicity

---

## Testing

```bash
# Start LocalStack
docker run --rm -it -p 4566:4566 -p 4510-4559:4510-4559 \
  -e SERVICES=s3,dynamodb \
  localstack/localstack:latest

# Initialize
terraform init

# Plan
terraform plan

# Apply
terraform apply -auto-approve

# Verify S3
aws --endpoint-url=http://localhost:4566 s3 ls
aws --endpoint-url=http://localhost:4566 s3api head-object \
  --bucket raw-uploads-bucket --key sample-data.json

# Verify DynamoDB
aws --endpoint-url=http://localhost:4566 dynamodb list-tables
aws --endpoint-url=http://localhost:4566 dynamodb describe-table \
  --table-name users-table

# Get item from DynamoDB
aws --endpoint-url=http://localhost:4566 dynamodb get-item \
  --table-name users-table \
  --key '{"user_id": {"S": "user-123"}, "timestamp": {"S": "2024-01-01T00:00:00Z"}}'

# Cleanup
terraform destroy -auto-approve
```

---

## Key Concepts Demonstrated

| Concept | How It's Shown |
|---------|----------------|
| AWS Provider Configuration | Provider block with LocalStack endpoints |
| S3 Bucket Management | aws_s3_bucket + versioning |
| S3 Object Upload | aws_s3_object with local file |
| DynamoDB Table | Composite key with PAY_PER_REQUEST |
| DynamoDB Items | aws_dynamodb_table_item with JSON |
| Terraform State | State file tracks all created resources |
| Outputs | Output blocks show important values |

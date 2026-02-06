# Solution: LocalStack - AWS Security

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
    iam             = "http://localhost:4566"
    kms             = "http://localhost:4566"
    secretsmanager  = "http://localhost:4566"
    lambda          = "http://localhost:4566"
    sts             = "http://localhost:4566"
  }

  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id   = true
}

# Variables
variable "user_name" {
  description = "IAM username"
  default     = "app-user"
  type        = string
}

variable "group_name" {
  description = "IAM group name"
  default     = "developers"
  type        = string
}

variable "role_name" {
  description = "IAM role name"
  default     = "app-lambda-role"
  type        = string
}

variable "key_alias" {
  description = "KMS key alias"
  default     = "app-master-key"
  type        = string
}

variable "secret_name" {
  description = "Secret name"
  default     = "db-credentials"
  type        = string
}

variable "secret_value" {
  description = "Secret value"
  default     = "admin:password123"
  type        = string
  sensitive   = true
}

# KMS Key
resource "aws_kms_key" "main" {
  description             = "Master encryption key for application"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  tags = {
    Name = "app-master-key"
  }
}

# KMS Alias
resource "aws_kms_alias" "main" {
  name          = "alias/${var.key_alias}"
  target_key_id = aws_kms_key.main.key_id
}

# IAM User
resource "aws_iam_user" "app_user" {
  name = var.user_name
  path = "/application/"

  tags = {
    Purpose = "Programmatic access"
  }
}

# IAM Access Key
resource "aws_iam_access_key" "app_user" {
  user = aws_iam_user.app_user.name
}

# IAM Policy (S3 Read-Only)
resource "aws_iam_policy" "s3_readonly" {
  name        = "s3-readonly-policy"
  description = "Read-only access to S3"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:Get*",
          "s3:List*"
        ]
        Resource = "*"
      }
    ]
  })
}

# IAM Group
resource "aws_iam_group" "developers" {
  name = var.group_name
  path = "/developers/"
}

# IAM Group Policy Attachment
resource "aws_iam_group_policy_attachment" "s3_readonly" {
  group      = aws_iam_group.developers.name
  policy_arn = aws_iam_policy.s3_readonly.arn
}

# IAM Group Membership
resource "aws_iam_group_membership" "developers" {
  group = aws_iam_group.developers.name
  users = [aws_iam_user.app_user.name]
}

# IAM Role for Lambda
resource "aws_iam_role" "lambda" {
  name = var.role_name
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Purpose = "Lambda execution"
  }
}

# IAM Role Policy Attachment (AWS Managed)
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# IAM Role Policy (Custom - DynamoDB Access)
resource "aws_iam_role_policy" "lambda_dynamodb" {
  name = "dynamodb-access"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Resource = "arn:aws:dynamodb:*:*:table/app-*"
      }
    ]
  })
}

# Secrets Manager Secret
resource "aws_secretsmanager_secret" "db_creds" {
  name                    = var.secret_name
  description             = "Database credentials"
  recovery_window_in_days = 0

  kms_key_id = aws_kms_alias.main.target_key_id

  tags = {
    Environment = "dev"
  }
}

# Secrets Manager Secret Version
resource "aws_secretsmanager_secret_version" "db_creds" {
  secret_id     = aws_secretsmanager_secret.db_creds.id
  secret_string = var.secret_value

  version_stages = ["AWSCURRENT"]
}

# Outputs
output "kms_key_id" {
  description = "KMS Key ID"
  value       = aws_kms_key.main.id
}

output "kms_key_arn" {
  description = "KMS Key ARN"
  value       = aws_kms_key.main.arn
}

output "kms_alias_arn" {
  description = "KMS Alias ARN"
  value       = aws_kms_alias.main.arn
}

output "iam_user_name" {
  description = "IAM User name"
  value       = aws_iam_user.app_user.name
}

output "iam_user_arn" {
  description = "IAM User ARN"
  value       = aws_iam_user.app_user.arn
}

output "access_key_id" {
  description = "Access Key ID"
  value       = aws_iam_access_key.app_user.id
  sensitive   = true
}

output "secret_access_key" {
  description = "Secret Access Key"
  value       = aws_iam_access_key.app_user.secret
  sensitive   = true
}

output "iam_role_name" {
  description = "IAM Role name"
  value       = aws_iam_role.lambda.name
}

output "iam_role_arn" {
  description = "IAM Role ARN"
  value       = aws_iam_role.lambda.arn
}

output "secret_arn" {
  description = "Secret ARN"
  value       = aws_secretsmanager_secret.db_creds.arn
}
```

---

## Explanation

### KMS Configuration
- Master key with automatic annual rotation
- Friendly alias for easy reference
- 10-day deletion window for safety

### IAM User + Group + Policy
- User represents an application
- Group organizes users
- Policy grants least-privilege S3 read access
- Group membership applies policy to user

### IAM Role
- Trust policy allows Lambda to assume the role
- AWS managed policy for basic Lambda execution
- Custom inline policy for DynamoDB access (least privilege)

### Secrets Manager
- Secret encrypted with customer-managed KMS key
- Immediate deletion (no recovery window) for dev environment
- Version with AWSCURRENT stage

---

## Testing

```bash
# Start LocalStack
docker run --rm -it -p 4566:4566 -p 4510-4559:4510-4559 \
  -e SERVICES=iam,kms,secretsmanager,lambda,sts \
  -e DEBUG=1 \
  localstack/localstack:latest

# Initialize
terraform init

# Plan
terraform plan

# Apply
terraform apply -auto-approve

# List IAM users
aws --endpoint-url=http://localhost:4566 iam list-users

# Get user details
aws --endpoint-url=http://localhost:4566 iam get-user --user-name app-user

# List KMS keys
aws --endpoint-url=http://localhost:4566 kms list-keys

# Describe KMS key
KEY_ID=$(terraform output -raw kms_key_id)
aws --endpoint-url=http://localhost:4566 kms describe-key --key-id "$KEY_ID"

# List secrets
aws --endpoint-url=http://localhost:4566 secretsmanager list-secrets

# Get secret value
SECRET_ARN=$(terraform output -raw secret_arn)
aws --endpoint-url=http://localhost:4566 secretsmanager get-secret-value --secret-id "$SECRET_ARN"

# Check outputs (sensitive values won't show without -raw)
terraform output kms_key_arn
terraform output iam_role_arn

# Cleanup
terraform destroy -auto-approve
```

---

## Key Concepts Demonstrated

| Concept | How It's Shown |
|---------|----------------|
| KMS Key Management | aws_kms_key with rotation |
| KMS Alias | Friendly name reference |
| IAM Users | Long-lived credentials |
| IAM Groups | Organize users, apply policies |
| IAM Policies | JSON permissions, least privilege |
| IAM Roles | Temporary credentials for services |
| Trust Policies | Define who can assume role |
| Secrets Manager | Encrypted secret storage |
| Sensitive Outputs | sensitive = true |

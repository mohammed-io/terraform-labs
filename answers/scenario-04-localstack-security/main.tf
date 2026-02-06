# -----------------------------------------------------------------------------
# Scenario 4: LocalStack - AWS Security (Answer Key)
# -----------------------------------------------------------------------------

# This solution implements a comprehensive IAM and security setup:
# - KMS key with rotation for encryption
# - IAM user with programmatic access
# - IAM policy with least privilege
# - IAM group for user organization
# - IAM role for Lambda/service access
# - Secrets Manager secret encrypted with KMS

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

# -----------------------------------------------------------------------------
# Variables
# -----------------------------------------------------------------------------
variable "user_name" {
  description = "IAM username"
  type        = string
  default     = "app-user"
}

variable "group_name" {
  description = "IAM group name"
  type        = string
  default     = "developers"
}

variable "role_name" {
  description = "IAM role name"
  type        = string
  default     = "app-lambda-role"
}

variable "key_alias" {
  description = "KMS key alias"
  type        = string
  default     = "alias/app-master-key"
}

variable "secret_name" {
  description = "Secret name"
  type        = string
  default     = "db-credentials"
}

variable "secret_value" {
  description = "Secret value (JSON string)"
  type        = string
  sensitive   = true
  default     = "{\"username\":\"admin\",\"password\":\"password123\",\"host\":\"db.example.com\",\"port\":5432}"
}

# -----------------------------------------------------------------------------
# KMS (Key Management Service)
# -----------------------------------------------------------------------------
# KMS is a managed service for creating and controlling encryption keys.
# It's used to encrypt data at rest for: S3, EBS, RDS, Secrets Manager, etc.

resource "aws_kms_key" "main" {
  description             = "Master encryption key for application data"
  deletion_window_in_days = 10  # Key deletion takes 7-30 days (safety)
  enable_key_rotation     = true # Automatic yearly rotation of key material

  # Key policy: who can use this key
  # By default, the root account has full access
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "*"
        }
        Action   = "kms:*"
        Resource = "*"
      }
    ]
  })

  tags = {
    Name        = "app-master-key"
    Environment = "dev"
    Purpose     = "data-encryption"
  }
}

# KMS Key Alias
# Aliases provide friendly names for keys.
# You can reference keys by alias: alias/my-key instead of key ID.

resource "aws_kms_alias" "main" {
  name          = var.key_alias
  target_key_id = aws_kms_key.main.key_id
}

# -----------------------------------------------------------------------------
# IAM User
# -----------------------------------------------------------------------------
# IAM Users represent people or applications that need AWS access.
# They can have: password for console login, access keys for API/CLI access.

resource "aws_iam_user" "app_user" {
  name = var.user_name
  path = "/application/"  # Organizational path

  tags = {
    Purpose = "Programmatic access for application"
  }
}

# IAM Access Key
# Provides programmatic access (Access Key ID + Secret Access Key).
# These are credentials for the AWS CLI/SDK.

resource "aws_iam_access_key" "app_user" {
  user = aws_iam_user.app_user.name
}

# -----------------------------------------------------------------------------
# IAM Policy
# -----------------------------------------------------------------------------
# IAM Policies are JSON documents that define permissions.
# They follow the structure: Effect (Allow/Deny) + Action + Resource.

resource "aws_iam_policy" "s3_readonly" {
  name        = "S3ReadOnlyAccess"
  description = "Read-only access to specific S3 buckets"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3ReadAccess"
        Effect = "Allow"
        Action = [
          "s3:Get*",
          "s3:List*"
        ]
        Resource = [
          "arn:aws:s3:::app-data-bucket",
          "arn:aws:s3:::app-data-bucket/*"
        ]
      }
    ]
  })
}

# Policy for Lambda logging
resource "aws_iam_policy" "lambda_logging" {
  name        = "LambdaLoggingPolicy"
  description = "Policy for Lambda to write to CloudWatch Logs"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# IAM Group
# -----------------------------------------------------------------------------
# IAM Groups help organize users and apply permissions collectively.
# Best practice: Add users to groups, attach policies to groups (not users).

resource "aws_iam_group" "developers" {
  name = var.group_name
  path = "/groups/"

  tags = {
    Purpose = "Developers team"
  }
}

# Attach policy to group
resource "aws_iam_group_policy_attachment" "developers_s3" {
  group      = aws_iam_group.developers.name
  policy_arn = aws_iam_policy.s3_readonly.arn
}

# Add user to group
resource "aws_iam_user_group_membership" "app_user" {
  user = aws_iam_user.app_user.name

  groups = [
    aws_iam_group.developers.name
  ]
}

# -----------------------------------------------------------------------------
# IAM Role
# -----------------------------------------------------------------------------
# IAM Roles provide temporary credentials.
# They're used by: AWS services (Lambda, EC2), external identities, federated users.

resource "aws_iam_role" "lambda_role" {
  name                = var.role_name
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
    Purpose = "Lambda execution role"
  }
}

# Attach logging policy to Lambda role
resource "aws_iam_role_policy_attachment" "lambda_logging" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_logging.arn
}

# Also attach AWS managed policy for basic Lambda execution
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# -----------------------------------------------------------------------------
# IAM Policy Inline (Alternative to managed policies)
# -----------------------------------------------------------------------------
# Inline policies are embedded directly into the user/role/group.
# They're useful for single-use policies.

resource "aws_iam_user_policy" "app_user_secrets" {
  name = "SecretsReadAccess"
  user = aws_iam_user.app_user.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = "arn:aws:secretsmanager:*:*:secret:${var.secret_name}*"
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# Secrets Manager
# -----------------------------------------------------------------------------
# Secrets Manager securely stores, encrypts, and rotates secrets.
# It's better than hardcoded secrets or environment variables.

resource "aws_secretsmanager_secret" "db_creds" {
  name                    = var.secret_name
  description             = "Database credentials for application"
  recovery_window_in_days = 0  # Immediate deletion (use 7-30 days in production)

  # Encrypt with our KMS key
  kms_key_id = aws_kms_alias.main.target_key_id

  tags = {
    Environment = "dev"
    Type        = "database"
  }
}

# Secret Version
# Secrets Manager versions allow rotation without changing the secret ID.
# AWSCURRENT = the current version
# AWSPENDING = staging for rotation
# AWSPREVIOUS = the previous version

resource "aws_secretsmanager_secret_version" "db_creds" {
  secret_id     = aws_secretsmanager_secret.db_creds.id
  secret_string = var.secret_value

  # Mark this as the current version
  version_stages = ["AWSCURRENT"]
}

# -----------------------------------------------------------------------------
# Outputs
# -----------------------------------------------------------------------------
output "kms_key_id" {
  description = "KMS Key ID"
  value       = aws_kms_key.main.id
}

output "kms_key_arn" {
  description = "KMS Key ARN"
  value       = aws_kms_key.main.arn
}

output "kms_alias_name" {
  description = "KMS Key Alias"
  value       = aws_kms_alias.main.name
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
  description = "Access Key ID (SENSITIVE!)"
  value       = aws_iam_access_key.app_user.id
  sensitive   = true
}

output "secret_access_key" {
  description = "Secret Access Key (SENSITIVE!)"
  value       = aws_iam_access_key.app_user.secret
  sensitive   = true
}

output "group_name" {
  description = "IAM Group name"
  value       = aws_iam_group.developers.name
}

output "role_name" {
  description = "IAM Role name"
  value       = aws_iam_role.lambda_role.name
}

output "role_arn" {
  description = "IAM Role ARN (for Lambda configuration)"
  value       = aws_iam_role.lambda_role.arn
}

output "secret_arn" {
  description = "Secret ARN"
  value       = aws_secretsmanager_secret.db_creds.arn
}

output "secret_name" {
  description = "Secret name"
  value       = aws_secretsmanager_secret.db_creds.name
}

# -----------------------------------------------------------------------------
# Key Takeaways
# -----------------------------------------------------------------------------
# 1. **IAM Users**: Long-lived credentials for people/applications
# 2. **IAM Access Keys**: Programmatic access (AWS CLI/SDK)
# 3. **IAM Roles**: Temporary credentials for AWS services
#    - Trust policy defines who can assume the role
# 4. **IAM Policies**: JSON documents defining permissions (who can do what)
#    - Effect: Allow or Deny
#    - Action: Specific API calls
#    - Resource: ARN of affected resources
#    - Deny always overrides Allow
# 5. **IAM Groups**: Organize users, apply permissions collectively
# 6. **KMS**: Encryption key management service
#    - Key rotation: Automatic yearly rotation of key material
#    - Key alias: Friendly name for referencing
#    - Key policy: Who can use/managed the key
# 7. **Secrets Manager**: Secure secret storage with encryption
#    - Versions allow rotation without changing secret ID
#    - Can be encrypted with KMS
# 8. **Least Privilege**: Grant only minimum required permissions
# 9. **Separation of Duties**: Different users/roles for different concerns
# 10. **Sensitive Outputs**: Mark sensitive outputs to prevent accidental logging

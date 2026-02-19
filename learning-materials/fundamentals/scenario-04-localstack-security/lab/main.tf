terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# TODO: Configure AWS provider for LocalStack
# HINT: Add iam, kms, secretsmanager, lambda, sts to endpoints

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

# TODO: Create KMS Key with rotation
# HINT: resource "aws_kms_key" "main" { enable_key_rotation = true }

# TODO: Create KMS Alias
# HINT: resource "aws_kms_alias" "main" { name = "alias/${var.key_alias}", target_key_id = ... }

# TODO: Create IAM User
# HINT: resource "aws_iam_user" "app_user" { name = var.user_name, path = "/application/" }

# TODO: Create IAM Access Key
# HINT: resource "aws_iam_access_key" "app_user" { user = aws_iam_user.app_user.name }

# TODO: Create IAM Policy for S3 read-only
# HINT: resource "aws_iam_policy" "s3_readonly" { policy = jsonencode({ ... }) }

# TODO: Create IAM Group
# HINT: resource "aws_iam_group" "developers" { name = var.group_name }

# TODO: Attach policy to group
# HINT: resource "aws_iam_group_policy_attachment" "s3_readonly" { ... }

# TODO: Add user to group
# HINT: resource "aws_iam_group_membership" "developers" { group = ..., users = [...] }

# TODO: Create IAM Role for Lambda
# HINT: resource "aws_iam_role" "lambda" { assume_role_policy = jsonencode({ Principal = { Service = "lambda.amazonaws.com" } }) }

# TODO: Attach AWS Lambda basic execution policy to role
# HINT: resource "aws_iam_role_policy_attachment" "lambda_logs" { policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole" }

# TODO: Create Secrets Manager Secret
# HINT: resource "aws_secretsmanager_secret" "db_creds" { kms_key_id = aws_kms_alias.main.target_key_id }

# TODO: Create Secret Version
# HINT: resource "aws_secretsmanager_secret_version" "db_creds" { secret_string = var.secret_value }

# Outputs
output "iam_user_name" {
  description = "IAM User Name"
  value       = try(aws_iam_user.app_user.name, "not created")
}

output "iam_user_arn" {
  description = "IAM User ARN"
  value       = try(aws_iam_user.app_user.arn, "not created")
}

output "group_name" {
  description = "IAM Group Name"
  value       = try(aws_iam_group.developers.name, "not created")
}

output "kms_key_id" {
  description = "KMS Key ID"
  value       = try(aws_kms_key.main.key_id, "not created")
}

output "kms_key_arn" {
  description = "KMS Key ARN"
  value       = try(aws_kms_key.main.arn, "not created")
}

output "iam_role_name" {
  description = "IAM Role Name"
  value       = try(aws_iam_role.lambda.name, "not created")
}

output "iam_role_arn" {
  description = "IAM Role ARN"
  value       = try(aws_iam_role.lambda.arn, "not created")
}

output "secret_arn" {
  description = "Secret ARN"
  value       = try(aws_secretsmanager_secret.db_creds.arn, "not created")
}

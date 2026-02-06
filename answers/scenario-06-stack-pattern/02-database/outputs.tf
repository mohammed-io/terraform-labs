# -----------------------------------------------------------------------------
# Outputs - Stack 2: Database
# -----------------------------------------------------------------------------

output "main_table_name" {
  description = "Main DynamoDB table name"
  value       = aws_dynamodb_table.main.name
}

output "main_table_arn" {
  description = "Main DynamoDB table ARN"
  value       = aws_dynamodb_table.main.arn
}

output "sessions_table_name" {
  description = "Sessions DynamoDB table name"
  value       = aws_dynamodb_table.sessions.name
}

output "audit_log_table_name" {
  description = "Audit log DynamoDB table name"
  value       = aws_dynamodb_table.audit_log.name
}

output "kms_key_arn" {
  description = "KMS key ARN for database encryption"
  value       = aws_kms_key.database.arn
}

output "kms_key_alias" {
  description = "KMS key alias"
  value       = aws_kms_alias.database.name
}

output "secret_arn" {
  description = "Secrets Manager secret ARN"
  value       = aws_secretsmanager_secret.database.arn
}

output "secret_name" {
  description = "Secrets Manager secret name"
  value       = aws_secretsmanager_secret.database.name
}

output "iam_policy_arn" {
  description = "IAM policy ARN for database access"
  value       = aws_iam_policy.database_access.arn
}

output "iam_policy_name" {
  description = "IAM policy name for database access"
  value       = aws_iam_policy.database_access.name
}

# -----------------------------------------------------------------------------
# Dependency Outputs
# -----------------------------------------------------------------------------
# These demonstrate the connection to the networking stack

output "networking_stack_vpc_id" {
  description = "VPC ID from networking stack"
  value       = data.terraform_remote_state.networking.outputs.vpc_id
}

output "networking_stack_database_subnet_ids" {
  description = "Database subnet IDs from networking stack"
  value       = data.terraform_remote_state.networking.outputs.database_subnet_ids
}

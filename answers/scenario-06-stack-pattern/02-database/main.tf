# -----------------------------------------------------------------------------
# Stack 2: Database
# -----------------------------------------------------------------------------
# This stack creates database resources that depend on networking stack.
# NOTE: Using DynamoDB instead of RDS for LocalStack free tier compatibility.
# In production, you'd use aws_db_instance for RDS.

# -----------------------------------------------------------------------------
# DynamoDB Table - Main Data Store
# -----------------------------------------------------------------------------
# In real AWS, you might use RDS (PostgreSQL/MySQL).
# For LocalStack free tier, DynamoDB is the best database option.

resource "aws_dynamodb_table" "main" {
  name             = "${var.environment}-${var.database_name}"
  billing_mode     = "PAY_PER_REQUEST"
  hash_key         = "PK"
  range_key        = "SK"

  # Partition key
  attribute {
    name = "PK"
    type = "S"
  }

  # Sort key
  attribute {
    name = "SK"
    type = "S"
  }

  # Global Secondary Index for alternate queries
  global_secondary_index {
    name            = "GSI1"
    hash_key        = "GSI1PK"
    range_key       = "GSI1SK"
    projection_type = "ALL"
  }

  attribute {
    name = "GSI1PK"
    type = "S"
  }

  attribute {
    name = "GSI1SK"
    type = "S"
  }

  # Point-in-time recovery
  point_in_time_recovery {
    enabled = true
  }

  # Server-side encryption
  server_side_encryption {
    enabled = true
  }

  # Tags
  tags = {
    Name        = "${var.environment}-database"
    Environment = var.environment
    Purpose     = "application-data"
    Stack       = "02-database"
  }
}

# -----------------------------------------------------------------------------
# DynamoDB Table - Sessions (for authentication)
# -----------------------------------------------------------------------------
resource "aws_dynamodb_table" "sessions" {
  name             = "${var.environment}-sessions"
  billing_mode     = "PAY_PER_REQUEST"
  hash_key         = "session_id"

  attribute {
    name = "session_id"
    type = "S"
  }

  # TTL for automatic session expiration
  ttl {
    attribute_name = "expires_at"
    enabled        = true
  }

  point_in_time_recovery {
    enabled = false  # Sessions are transient
  }

  tags = {
    Name        = "${var.environment}-sessions"
    Environment = var.environment
    Purpose     = "user-sessions"
    Stack       = "02-database"
  }
}

# -----------------------------------------------------------------------------
# DynamoDB Table - Audit Log
# -----------------------------------------------------------------------------
resource "aws_dynamodb_table" "audit_log" {
  name             = "${var.environment}-audit-log"
  billing_mode     = "PAY_PER_REQUEST"
  hash_key         = "timestamp"

  attribute {
    name = "timestamp"
    type = "S"
  }

  point_in_time_recovery {
    enabled = var.enable_backup
  }

  tags = {
    Name        = "${var.environment}-audit-log"
    Environment = var.environment
    Purpose     = "audit-trail"
    Stack       = "02-database"
  }
}

# -----------------------------------------------------------------------------
# KMS Key for Database Encryption
# -----------------------------------------------------------------------------
# Using KMS for additional security layer.

resource "aws_kms_key" "database" {
  description             = "KMS key for ${var.environment} database encryption"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  tags = {
    Name        = "${var.environment}-database-kms"
    Environment = var.environment
    Stack       = "02-database"
  }
}

resource "aws_kms_alias" "database" {
  name          = "alias/${var.environment}-database"
  target_key_id = aws_kms_key.database.key_id
}

# -----------------------------------------------------------------------------
# Secrets Manager - Database Credentials
# -----------------------------------------------------------------------------
# In a real scenario with RDS, this would store the database password.
# For DynamoDB, we store application access credentials.

resource "aws_secretsmanager_secret" "database" {
  name                    = "${var.environment}/database/credentials"
  description             = "Database credentials for ${var.environment}"
  recovery_window_in_days = 0

  kms_key_id = aws_kms_alias.database.target_key_id

  tags = {
    Environment = var.environment
    Stack       = "02-database"
  }
}

resource "aws_secretsmanager_secret_version" "database" {
  secret_id = aws_secretsmanager_secret.database.id
  secret_string = jsonencode({
    database_name = aws_dynamodb_table.main.name
    table_name    = aws_dynamodb_table.main.name
    sessions_table = aws_dynamodb_table.sessions.name
    audit_table   = aws_dynamodb_table.audit_log.name
    kms_key_arn   = aws_kms_key.database.arn
    kms_key_id    = aws_kms_alias.database.name
    environment   = var.environment
  })
}

# -----------------------------------------------------------------------------
# IAM Policy for Database Access
# -----------------------------------------------------------------------------
# This policy grants least-privilege access to the database tables.
# Application stacks will attach this to their IAM roles.

resource "aws_iam_policy" "database_access" {
  name        = "${var.environment}-database-access"
  description = "Policy for application to access database tables"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DynamoDBMainAccess"
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:BatchGetItem",
          "dynamodb:Query",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:BatchWriteItem"
        ]
        Resource = [
          aws_dynamodb_table.main.arn,
          "${aws_dynamodb_table.main.arn}/*",
          aws_dynamodb_table.sessions.arn,
          "${aws_dynamodb_table.sessions.arn}/*",
          aws_dynamodb_table.audit_log.arn,
          "${aws_dynamodb_table.audit_log.arn}/*"
        ]
      },
      {
        Sid    = "DynamoDBReadWriteStream"
        Effect = "Allow"
        Action = [
          "dynamodb:DescribeStream",
          "dynamodb:GetRecords",
          "dynamodb:GetShardIterator",
          "dynamodb:ListStreams"
        ]
        Resource = "arn:aws:dynamodb:*:*:table/${var.environment}-*/stream/*"
      },
      {
        Sid    = "KMSDecrypt"
        Effect = "Allow"
        Action = [
          "kms:Decrypt"
        ]
        Resource = aws_kms_key.database.arn
      },
      {
        Sid    = "SecretsManagerAccess"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = aws_secretsmanager_secret.database.arn
      }
    ]
  })

  tags = {
    Environment = var.environment
    Stack       = "02-database"
  }
}

# -----------------------------------------------------------------------------
# Sample Data (for development)
# -----------------------------------------------------------------------------
# In production, this would be managed by the application.

resource "aws_dynamodb_table_item" "sample_config" {
  table_name = aws_dynamodb_table.main.name
  hash_key   = "CONFIG"
  range_key  = "GLOBAL"

  item = jsonencode({
    PK       = { "S": "CONFIG" }
    SK       = { "S": "GLOBAL" }
    setting  = { "S": "maintenance_mode" }
    value    = { "S": "false" }
    updated_at = { "S": timestamp() }
  })
}

# Step 2: DynamoDB, S3, and Advanced Lambda Configuration

## DynamoDB Table with GSI

DynamoDB tables can have Global Secondary Indexes (GSIs) for alternative query patterns:

```hcl
resource "aws_dynamodb_table" "users" {
  name           = "${var.environment}-users"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "user_id"
  range_key      = "created_at"

  attribute {
    name = "user_id"
    type = "S"
  }

  attribute {
    name = "created_at"
    type = "S"
  }

  attribute {
    name = "email"
    type = "S"
  }

  # Global Secondary Index for email lookups
  global_secondary_index {
    name            = "EmailIndex"
    hash_key        = "email"
    projection_type = "ALL"
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled = true
  }

  tags = {
    Environment = var.environment
  }
}
```

**GSI Usage**: Query by email instead of user_id

## S3 Bucket with Versioning

```hcl
resource "aws_s3_bucket" "assets" {
  bucket = "${var.environment}-assets"

  tags = {
    Environment = var.environment
  }
}

resource "aws_s3_bucket_versioning" "assets" {
  bucket = aws_s3_bucket.assets.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption" "assets" {
  bucket = aws_s3_bucket.assets.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
```

## IAM Policy for DynamoDB Access

Add DynamoDB permissions to your Lambda role:

```hcl
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
          "dynamodb:UpdateItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Resource = [
          aws_dynamodb_table.users.arn,
          "${aws_dynamodb_table.users.arn}/*",
          "${aws_dynamodb_table.users.arn}/index/*"
        ]
      }
    ]
  })
}
```

## IAM Policy for S3 Access

```hcl
resource "aws_iam_role_policy" "lambda_s3" {
  name = "s3-access"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = "${aws_s3_bucket.assets.arn}/*"
      }
    ]
  })
}
```

## Pass Environment Variables to Lambda

```hcl
resource "aws_lambda_function" "app" {
  # ... other config ...

  environment {
    variables = {
      DYNAMODB_TABLE = aws_dynamodb_table.users.name
      S3_BUCKET      = aws_s3_bucket.assets.id
      ENVIRONMENT    = var.environment
      LOG_LEVEL      = "INFO"
    }
  }
}
```

## Outputs for API URL

```hcl
output "api_endpoint" {
  description = "API Gateway endpoint URL"
  value       = "${aws_apigatewayv2_api.main.id}.execute-api.${var.region}.amazonaws.com/${aws_apigatewayv2_stage.main.name}"
}

output "lambda_function_name" {
  description = "Lambda function name"
  value       = aws_lambda_function.app.function_name
}

output "dynamodb_table_name" {
  description = "DynamoDB table name"
  value       = aws_dynamodb_table.users.name
}

output "s3_bucket_name" {
  description = "S3 bucket name"
  value       = aws_s3_bucket.assets.id
}
```

## Creating Lambda Code

Create a simple `index.py`:

```python
import json
import os

DYNAMODB_TABLE = os.environ.get('DYNAMODB_TABLE')

def handler(event, context):
    print(f"Received event: {json.dumps(event)}")

    route = event.get('rawPath', '/')

    if route == '/health':
        return {
            'statusCode': 200,
            'body': json.dumps({'status': 'healthy'})
        }
    elif route == '/api/users':
        return {
            'statusCode': 200,
            'body': json.dumps({'users': []})
        }

    return {
        'statusCode': 404,
        'body': json.dumps({'error': 'Not found'})
    }
```

Then zip it:
```bash
zip lambda.zip index.py
```

## Your Task

1. Create DynamoDB table with GSI on email
2. Enable point-in-time recovery and encryption
3. Create S3 bucket with versioning and encryption
4. Create IAM policies for Lambda to access DynamoDB and S3
5. Update Lambda environment variables with resource names
6. Create outputs for API endpoint, Lambda name, table name, and bucket

## Quick Check

Test your understanding:

1. What's a Global Secondary Index (GSI) in DynamoDB? (An alternate key for querying your table - allows querying by different attributes than the primary key)

2. What does PAY_PER_REQUEST billing mode mean? (You pay only for what you use - no need to specify read/write capacity, it scales automatically)

3. Why pass resource names as environment variables instead of hardcoding? (Makes your Lambda function reusable across environments and follows infrastructure-as-code principles)

4. What does point_in_time_recovery enable? (Allows you to restore the table to any point in the last 35 days - protects against accidental writes/deletes)

5. What's the difference between `s3:GetObject` and `s3:ListBucket`? (GetObject retrieves a specific file from a bucket; ListBucket lists all objects in a bucket - they're different permissions for different operations)

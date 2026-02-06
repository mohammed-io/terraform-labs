# Solution: LocalStack - Full-Stack Serverless

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
    apigateway  = "http://localhost:4566"
    lambda      = "http://localhost:4566"
    dynamodb    = "http://localhost:4566"
    s3          = "http://localhost:4566"
    iam         = "http://localhost:4566"
    cloudwatch  = "http://localhost:4566"
    logs        = "http://localhost:4566"
    sts         = "http://localhost:4566"
  }

  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id   = true
}

# Variables
variable "environment" {
  description = "Environment name"
  default     = "dev"
  type        = string
}

variable "api_name" {
  description = "API Gateway name"
  default     = "serverless-api"
  type        = string
}

variable "api_stage" {
  description = "API Gateway stage"
  default     = "v1"
  type        = string
}

variable "lambda_timeout" {
  description = "Lambda timeout"
  default     = 30
  type        = number
}

variable "lambda_memory" {
  description = "Lambda memory"
  default     = 256
  type        = number
}

# API Gateway v2
resource "aws_apigatewayv2_api" "main" {
  name          = var.api_name
  protocol_type = "HTTP"
  description   = "Serverless application API"

  tags = {
    Environment = var.environment
  }
}

# API Gateway Stage
resource "aws_cloudwatch_log_group" "api" {
  name              = "/aws/apigateway/${var.api_name}"
  retention_in_days = 7
}

resource "aws_apigatewayv2_stage" "main" {
  api_id      = aws_apigatewayv2_api.main.id
  name        = var.api_stage
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api.arn

    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      routeKey       = "$context.routeKey"
      status         = "$context.status"
    })
  }
}

# Lambda IAM Role
resource "aws_iam_role" "lambda" {
  name = "${var.environment}-lambda-role"

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
    Environment = var.environment
  }
}

# Lambda Basic Execution Policy
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# DynamoDB Table
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

# S3 Bucket
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

# IAM Policies for Lambda
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

# CloudWatch Log Group for Lambda
resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.environment}-app"
  retention_in_days = 7
}

# Lambda Function
resource "aws_lambda_function" "app" {
  filename      = "lambda.zip"
  function_name = "${var.environment}-app"
  role          = aws_iam_role.lambda.arn
  handler       = "index.handler"
  runtime       = "python3.11"

  timeout     = var.lambda_timeout
  memory_size = var.lambda_memory

  environment {
    variables = {
      DYNAMODB_TABLE = aws_dynamodb_table.users.name
      S3_BUCKET      = aws_s3_bucket.assets.id
      ENVIRONMENT    = var.environment
      LOG_LEVEL      = "INFO"
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.lambda
  ]

  tags = {
    Environment = var.environment
  }
}

# Lambda Permission for API Gateway
resource "aws_lambda_permission" "api" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.app.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.main.execution_arn}/*/*"
}

# API Gateway Integration
resource "aws_apigatewayv2_integration" "app" {
  api_id           = aws_apigatewayv2_api.main.id
  integration_type = "AWS_PROXY"

  connection_type         = "INTERNET"
  description            = "Lambda integration"
  integration_uri        = aws_lambda_function.app.arn
  payload_format_version = "2.0"
}

# API Routes
resource "aws_apigatewayv2_route" "health" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "GET /health"
  target    = "integrations/${aws_apigatewayv2_integration.app.id}"
}

resource "aws_apigatewayv2_route" "users" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "GET /api/users"
  target    = "integrations/${aws_apigatewayv2_integration.app.id}"
}

resource "aws_apigatewayv2_route" "data" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "GET /api/data"
  target    = "integrations/${aws_apigatewayv2_integration.app.id}"
}

# Outputs
output "api_endpoint" {
  description = "API Gateway endpoint URL"
  value       = "${aws_apigatewayv2_api.main.id}.execute-api.us-east-1.amazonaws.com:${aws_apigatewayv2_stage.main.name}"
}

output "api_id" {
  description = "API Gateway ID"
  value       = aws_apigatewayv2_api.main.id
}

output "lambda_function_name" {
  description = "Lambda function name"
  value       = aws_lambda_function.app.function_name
}

output "lambda_role_arn" {
  description = "Lambda role ARN"
  value       = aws_iam_role.lambda.arn
}

output "dynamodb_table_name" {
  description = "DynamoDB table name"
  value       = aws_dynamodb_table.users.name
}

output "s3_bucket_name" {
  description = "S3 bucket name"
  value       = aws_s3_bucket.assets.id
}

output "cloudwatch_log_group" {
  description = "CloudWatch log group"
  value       = aws_cloudwatch_log_group.lambda.name
}
```

## Lambda Code (index.py)

```python
import json
import os

DYNAMODB_TABLE = os.environ.get('DYNAMODB_TABLE')
S3_BUCKET = os.environ.get('S3_BUCKET')
ENVIRONMENT = os.environ.get('ENVIRONMENT', 'dev')

def handler(event, context):
    """Lambda handler for serverless API"""

    print(f"Received event: {json.dumps(event)}")

    route = event.get('rawPath', '/')

    if route == '/health':
        return {
            'statusCode': 200,
            'headers': {'Content-Type': 'application/json'},
            'body': json.dumps({
                'status': 'healthy',
                'environment': ENVIRONMENT
            })
        }

    elif route == '/api/users':
        return {
            'statusCode': 200,
            'headers': {'Content-Type': 'application/json'},
            'body': json.dumps({
                'users': [],
                'table': DYNAMODB_TABLE
            })
        }

    elif route == '/api/data':
        return {
            'statusCode': 200,
            'headers': {'Content-Type': 'application/json'},
            'body': json.dumps({
                'bucket': S3_BUCKET,
                'environment': ENVIRONMENT
            })
        }

    return {
        'statusCode': 404,
        'headers': {'Content-Type': 'application/json'},
        'body': json.dumps({'error': 'Not found'})
    }
```

---

## Testing

```bash
# Create lambda.zip
cat > index.py << 'EOF'
import json
import os
def handler(event, context):
    route = event.get('rawPath', '/')
    if route == '/health':
        return {'statusCode': 200, 'body': json.dumps({'status': 'healthy'})}
    return {'statusCode': 404, 'body': json.dumps({'error': 'Not found'})}
EOF
zip lambda.zip index.py

# Start LocalStack
docker run --rm -it -p 4566:4566 -p 4510-4559:4510-4559 \
  -e SERVICES=lambda,apigateway,dynamodb,s3,iam,cloudwatch,logs,sts \
  -e DEBUG=1 \
  localstack/localstack:latest

# Initialize
terraform init

# Plan
terraform plan

# Apply
terraform apply -auto-approve

# Get API endpoint
API_URL=$(terraform output -raw api_endpoint)
echo "API URL: http://$API_URL"

# Test the API
curl "http://$API_URL/health"
curl "http://$API_URL/api/users"

# List Lambda functions
aws --endpoint-url=http://localhost:4566 lambda list-functions

# List DynamoDB tables
aws --endpoint-url=http://localhost:4566 dynamodb list-tables

# List S3 buckets
aws --endpoint-url=http://localhost:4566 s3 ls

# Cleanup
terraform destroy -auto-approve
```

---

## Key Concepts Demonstrated

| Concept | How It's Shown |
|---------|----------------|
| API Gateway v2 | HTTP API with stage and routes |
| Lambda Functions | Python runtime with environment variables |
| IAM Roles for Lambda | Trust policy + execution policies |
| DynamoDB Tables | GSI, PITR, encryption |
| S3 Buckets | Versioning, encryption |
| CloudWatch Logs | Log groups for Lambda and API |
| API Integration | AWS_PROXY integration type |
| Lambda Permissions | API Gateway invoke permission |

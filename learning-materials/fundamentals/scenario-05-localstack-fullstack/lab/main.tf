terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# TODO: Configure AWS provider for LocalStack
# HINT: Add apigateway, lambda, dynamodb, s3, iam, cloudwatch, logs, sts to endpoints

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

# TODO: Create API Gateway v2 HTTP API
# HINT: resource "aws_apigatewayv2_api" "main" { protocol_type = "HTTP" }

# TODO: Create CloudWatch log group for API
# HINT: resource "aws_cloudwatch_log_group" "api" { name = "/aws/apigateway/${var.api_name}" }

# TODO: Create API Gateway stage with auto_deploy
# HINT: resource "aws_apigatewayv2_stage" "main" { auto_deploy = true }

# TODO: Create IAM Role for Lambda
# HINT: resource "aws_iam_role" "lambda" { assume_role_policy allows lambda.amazonaws.com }

# TODO: Attach AWSLambdaBasicExecutionRole to Lambda role
# HINT: resource "aws_iam_role_policy_attachment" "lambda_logs" { ... }

# TODO: Create DynamoDB table with GSI
# HINT: resource "aws_dynamodb_table" "users" { global_secondary_index { name = "EmailIndex" } }

# TODO: Create S3 bucket with versioning
# HINT: resource "aws_s3_bucket" "assets" { ... } + aws_s3_bucket_versioning

# TODO: Create IAM policy for DynamoDB access
# HINT: resource "aws_iam_role_policy" "lambda_dynamodb" { ... }

# TODO: Create IAM policy for S3 access
# HINT: resource "aws_iam_role_policy" "lambda_s3" { ... }

# TODO: Create CloudWatch log group for Lambda
# HINT: resource "aws_cloudwatch_log_group" "lambda" { name = "/aws/lambda/${var.environment}-app" }

# TODO: Create Lambda function
# HINT: resource "aws_lambda_function" "app" { filename = "lambda.zip", runtime = "python3.11" }

# TODO: Create Lambda permission for API Gateway
# HINT: resource "aws_lambda_permission" "api" { principal = "apigateway.amazonaws.com" }

# TODO: Create API Gateway integration
# HINT: resource "aws_apigatewayv2_integration" "app" { integration_type = "AWS_PROXY" }

# TODO: Create API routes
# HINT: resource "aws_apigatewayv2_route" "health" { route_key = "GET /health" }

# Outputs
output "api_endpoint" {
  description = "API Gateway endpoint URL"
  value       = try("${aws_apigatewayv2_api.main.id}.execute-api.us-east-1.amazonaws.com:${aws_apigatewayv2_stage.main.name}", "not created")
}

output "lambda_function_name" {
  description = "Lambda function name"
  value       = try(aws_lambda_function.app.function_name, "not created")
}

output "dynamodb_table_name" {
  description = "DynamoDB table name"
  value       = try(aws_dynamodb_table.users.name, "not created")
}

output "s3_bucket_name" {
  description = "S3 bucket name"
  value       = try(aws_s3_bucket.assets.id, "not created")
}

# -----------------------------------------------------------------------------
# Stack 3: Application
# -----------------------------------------------------------------------------
# This stack creates the application layer:
# - Lambda functions (API handlers)
# - API Gateway v2 (HTTP API)
# - IAM roles for Lambda
# - CloudWatch log groups
#
# Dependencies:
# - Reads VPC config from networking stack
# - Reads database config from database stack

# -----------------------------------------------------------------------------
# IAM Role for Lambda
# -----------------------------------------------------------------------------
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
    Stack       = "03-application"
  }
}

# Attach basic Lambda execution policy
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Attach database access policy from database stack
resource "aws_iam_role_policy_attachment" "lambda_database" {
  role       = aws_iam_role.lambda.name
  policy_arn = data.terraform_remote_state.database.outputs.iam_policy_arn
}

# Additional Lambda policy for CloudWatch Logs
resource "aws_iam_role_policy" "lambda_logs" {
  name = "${var.environment}-lambda-logs"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${var.environment}-*"
      }
    ]
  })
}

# Additional Lambda policy for X-Ray tracing (optional)
resource "aws_iam_role_policy" "lambda_xray" {
  name = "${var.environment}-lambda-xray"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "xray:PutTraceSegments",
          "xray:PutTelemetryRecords",
          "xray:GetSamplingRules",
          "xray:GetSamplingTargets"
        ]
        Resource = "*"
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# CloudWatch Log Groups
# -----------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.environment}-app"
  retention_in_days = var.log_retention_days

  tags = {
    Environment = var.environment
    Stack       = "03-application"
  }
}

# -----------------------------------------------------------------------------
# Lambda Function - Main Application
# -----------------------------------------------------------------------------
# Note: In a real project, you'd build the Lambda code separately
# and reference the zip file. Here we use a placeholder.

data "archive_file" "lambda" {
  type        = "zip"
  output_path = "${path.module}/lambda.zip"

  source {
    content = <<EOF
import json
import os

def handler(event, context):
    # Read database config from environment variables
    table_name = os.environ.get('TABLE_NAME')
    secret_arn = os.environ.get('SECRET_ARN')

    return {
        'statusCode': 200,
        'headers': {'Content-Type': 'application/json'},
        'body': json.dumps({
            'message': 'Hello from Lambda!',
            'environment': os.environ.get('ENVIRONMENT'),
            'table': table_name,
            'database_stack_secret': secret_arn
        })
    }
EOF
    filename = "index.py"
  }
}

resource "aws_lambda_function" "app" {
  function_name = "${var.environment}-app"
  description   = "Main application Lambda function"
  role          = aws_iam_role.lambda.arn
  handler       = "index.handler"
  runtime       = "python3.11"

  filename         = data.archive_file.lambda.output_path
  source_code_hash = data.archive_file.lambda.output_base64sha256

  timeout    = var.lambda_timeout
  memory_size = var.lambda_memory

  environment {
    variables = {
      ENVIRONMENT      = var.environment
      TABLE_NAME       = data.terraform_remote_state.database.outputs.main_table_name
      SESSIONS_TABLE   = data.terraform_remote_state.database.outputs.sessions_table_name
      SECRET_ARN       = data.terraform_remote_state.database.outputs.secret_arn
      KMS_KEY_ARN      = data.terraform_remote_state.database.outputs.kms_key_arn
      VPC_ID           = data.terraform_remote_state.networking.outputs.vpc_id
    }
  }

  tags = {
    Environment = var.environment
    Stack       = "03-application"
  }

  depends_on = [
    aws_cloudwatch_log_group.lambda
  ]
}

# -----------------------------------------------------------------------------
# Lambda Function - Health Check
# -----------------------------------------------------------------------------
data "archive_file" "lambda_health" {
  type        = "zip"
  output_path = "${path.module}/lambda-health.zip"

  source {
    content = <<EOF
import json

def handler(event, context):
    return {
        'statusCode': 200,
        'headers': {'Content-Type': 'application/json'},
        'body': json.dumps({'status': 'healthy'})
    }
EOF
    filename = "health.py"
  }
}

resource "aws_lambda_function" "health" {
  function_name = "${var.environment}-health"
  description   = "Health check Lambda function"
  role          = aws_iam_role.lambda.arn
  handler       = "health.handler"
  runtime       = "python3.11"

  filename         = data.archive_file.lambda_health.output_path
  source_code_hash = data.archive_file.lambda_health.output_base64sha256

  timeout    = 3
  memory_size = 128

  environment {
    variables = {
      ENVIRONMENT = var.environment
    }
  }

  tags = {
    Environment = var.environment
    Stack       = "03-application"
  }
}

# -----------------------------------------------------------------------------
# API Gateway v2 - HTTP API
# -----------------------------------------------------------------------------
resource "aws_apigatewayv2_api" "main" {
  name          = "${var.environment}-${var.api_name}"
  protocol_type = "HTTP"
  description   = "Main application API"

  tags = {
    Environment = var.environment
    Stack       = "03-application"
  }
}

# API Gateway Stage
resource "aws_apigatewayv2_stage" "main" {
  api_id      = aws_apigatewayv2_api.main.id
  name        = var.api_stage
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api.arn
    format = jsonencode({
      requestId        = "$context.requestId"
      ip               = "$context.identity.sourceIp"
      requestTime      = "$context.requestTime"
      httpMethod       = "$context.httpMethod"
      routeKey         = "$context.routeKey"
      status           = "$context.status"
      protocol         = "$context.protocol"
      responseLength   = "$context.responseLength"
      integrationLatency = "$context.integrationLatency"
    })
  }

  tags = {
    Environment = var.environment
    Stack       = "03-application"
  }
}

# API Gateway Log Group
resource "aws_cloudwatch_log_group" "api" {
  name              = "/aws/apigateway/${var.environment}-${var.api_name}"
  retention_in_days = var.log_retention_days

  tags = {
    Environment = var.environment
    Stack       = "03-application"
  }
}

# -----------------------------------------------------------------------------
# API Gateway - Lambda Integrations
# -----------------------------------------------------------------------------

# Lambda permission for API Gateway to invoke app function
resource "aws_lambda_permission" "app_api" {
  statement_id  = "AllowAPIGatewayInvokeApp"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.app.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.main.execution_arn}/*/*"
}

# Lambda permission for health function
resource "aws_lambda_permission" "health_api" {
  statement_id  = "AllowAPIGatewayInvokeHealth"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.health.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.main.execution_arn}/*/*"
}

# App Lambda integration
resource "aws_apigatewayv2_integration" "app" {
  api_id           = aws_apigatewayv2_api.main.id
  integration_type = "AWS_PROXY"

  connection_type    = "INTERNET"
  description       = "App Lambda integration"
  integration_uri    = aws_lambda_function.app.arn
  payload_format_version = "2.0"
}

# Health Lambda integration
resource "aws_apigatewayv2_integration" "health" {
  api_id           = aws_apigatewayv2_api.main.id
  integration_type = "AWS_PROXY"

  connection_type    = "INTERNET"
  description       = "Health Lambda integration"
  integration_uri    = aws_lambda_function.health.arn
  payload_format_version = "2.0"
}

# -----------------------------------------------------------------------------
# API Gateway - Routes
# -----------------------------------------------------------------------------

# Health check route
resource "aws_apigatewayv2_route" "health" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "GET /health"
  target    = "integrations/${aws_apigatewayv2_integration.health.id}"
}

# API routes
resource "aws_apigatewayv2_route" "api_root" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "GET /api"
  target    = "integrations/${aws_apigatewayv2_integration.app.id}"
}

resource "aws_apigatewayv2_route" "api_users" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "GET /api/users"
  target    = "integrations/${aws_apigatewayv2_integration.app.id}"
}

resource "aws_apigatewayv2_route" "api_data" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "ANY /api/{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.app.id}"
}

# Default route (catch-all)
resource "aws_apigatewayv2_route" "default" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "$default"
  target    = "integrations/${aws_apigatewayv2_integration.health.id}"
}

# -----------------------------------------------------------------------------
# CloudWatch Alarms
# -----------------------------------------------------------------------------

# Lambda error alarm
resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name          = "${var.environment}-lambda-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Sum"
  threshold           = "5"

  dimensions = {
    FunctionName = aws_lambda_function.app.function_name
  }

  alarm_actions = []  # In prod, add SNS topic ARN
  ok_actions    = []

  tags = {
    Environment = var.environment
    Stack       = "03-application"
  }
}

# API Gateway 4XX alarm
resource "aws_cloudwatch_metric_alarm" "api_4xx" {
  alarm_name          = "${var.environment}-api-4xx"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "4XXError"
  namespace           = "AWS/ApiGateway"
  period              = "300"
  statistic           = "Sum"
  threshold           = "50"

  dimensions = {
    ApiId = aws_apigatewayv2_api.main.id
  }

  tags = {
    Environment = var.environment
    Stack       = "03-application"
  }
}

# API Gateway 5XX alarm
resource "aws_cloudwatch_metric_alarm" "api_5xx" {
  alarm_name          = "${var.environment}-api-5xx"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "5XXError"
  namespace           = "AWS/ApiGateway"
  period              = "60"
  statistic           = "Sum"
  threshold           = "10"

  dimensions = {
    ApiId = aws_apigatewayv2_api.main.id
  }

  tags = {
    Environment = var.environment
    Stack       = "03-application"
  }
}

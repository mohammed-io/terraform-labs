# Step 1: API Gateway v2 and Lambda

## API Gateway v2 (HTTP API)

API Gateway v2 HTTP APIs are faster and cheaper than v1 REST APIs:

```hcl
resource "aws_apigatewayv2_api" "main" {
  name          = var.api_name
  protocol_type = "HTTP"
  description   = "Serverless application API"

  tags = {
    Environment = var.environment
  }
}
```

## API Gateway Stage

A stage is a snapshot of your API for deployment:

```hcl
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
      protocol       = "$context.protocol"
      responseLength = "$context.responseLength"
    })
  }
}
```

**auto_deploy = true**: Automatically deploy changes when you update the API

## Lambda Function

```hcl
resource "aws_lambda_function" "app" {
  filename      = "lambda.zip"
  function_name = "${var.environment}-app"
  role          = aws_iam_role.lambda.arn
  handler       = "index.handler"
  runtime       = "python3.11"

  timeout       = var.lambda_timeout
  memory_size   = var.lambda_memory

  environment {
    variables = {
      ENVIRONMENT = var.environment
      LOG_LEVEL   = "INFO"
    }
  }
}
```

**Lambda zip file**: You'll need to create a simple lambda function first.

## Lambda IAM Role

Lambda needs a role to access other AWS services:

```hcl
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
}
```

## Lambda Basic Execution Policy

```hcl
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
```

This gives Lambda permission to write to CloudWatch Logs.

## API Gateway Integration

Connect API Gateway to Lambda:

```hcl
resource "aws_apigatewayv2_integration" "app" {
  api_id           = aws_apigatewayv2_api.main.id
  integration_type = "AWS_PROXY"

  connection_type            = "INTERNET"
  description               = "Lambda integration"
  integration_uri           = aws_lambda_function.app.arn
  payload_format_version    = "2.0"
}
```

## Lambda Permission for API Gateway

```hcl
resource "aws_lambda_permission" "api" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.app.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.main.execution_arn}/*/*"
}
```

## API Routes

Create routes for your API:

```hcl
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
```

## CloudWatch Log Group

```hcl
resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.environment}-app"
  retention_in_days = 7
}
```

## Your Task

1. Create API Gateway v2 HTTP API
2. Create deployment stage with access logging
3. Create a simple Lambda function (create index.py and lambda.zip)
4. Create IAM role for Lambda with proper trust policy
5. Attach basic execution policy to the role
6. Create API Gateway integration with Lambda
7. Add Lambda permission for API Gateway to invoke it
8. Create routes for /health and /api/users
9. Create CloudWatch log group

## Quick Check

Test your understanding:

1. What's the difference between API Gateway v1 (REST) and v2 (HTTP)? (v2 HTTP APIs are faster, cheaper, and simpler - designed for modern serverless applications; v1 REST APIs have more features but are more complex)

2. What does `auto_deploy = true` do on an API Gateway stage? (Automatically deploys any changes to the API without requiring a manual deployment action)

3. What's the purpose of `payload_format_version = "2.0"`? (It specifies the newer, simpler payload format for API Gateway integrations - 2.0 is the modern format for HTTP APIs)

4. Why does Lambda need a permission for API Gateway? (API Gateway needs explicit permission to invoke your Lambda function - this is a security feature in AWS)

5. What does `AWS_PROXY` integration type mean? (API Gateway passes the entire request to Lambda and Lambda returns the response directly - API Gateway doesn't transform the request/response)

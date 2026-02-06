# -----------------------------------------------------------------------------
# Outputs - Stack 3: Application
# -----------------------------------------------------------------------------

output "api_endpoint" {
  description = "API Gateway endpoint URL"
  value       = aws_apigatewayv2_api.main.api_endpoint
}

output "api_url" {
  description = "Full API URL"
  value       = "${aws_apigatewayv2_api.main.api_endpoint}/${aws_apigatewayv2_stage.main.name}"
}

output "api_id" {
  description = "API Gateway ID"
  value       = aws_apigatewayv2_api.main.id
}

output "api_arn" {
  description = "API Gateway ARN"
  value       = aws_apigatewayv2_api.main.arn
}

output "lambda_function_name" {
  description = "Main Lambda function name"
  value       = aws_lambda_function.app.function_name
}

output "lambda_function_arn" {
  description = "Main Lambda function ARN"
  value       = aws_lambda_function.app.arn
}

output "lambda_invoke_arn" {
  description = "Main Lambda invoke ARN"
  value       = aws_lambda_function.app.invoke_arn
}

output "lambda_role_arn" {
  description = "Lambda execution role ARN"
  value       = aws_iam_role.lambda.arn
}

output "health_check_url" {
  description = "Health check endpoint"
  value       = "${aws_apigatewayv2_api.main.api_endpoint}/${aws_apigatewayv2_stage.main.name}/health"
}

# -----------------------------------------------------------------------------
# Dependency Outputs
# -----------------------------------------------------------------------------
# These demonstrate the connection to dependent stacks

output "depends_on_networking_stack" {
  description = "Networking stack VPC ID"
  value       = data.terraform_remote_state.networking.outputs.vpc_id
}

output "depends_on_database_stack" {
  description = "Database stack main table"
  value       = data.terraform_remote_state.database.outputs.main_table_name
}

# -----------------------------------------------------------------------------
# Test Commands
# -----------------------------------------------------------------------------
output "test_commands" {
  description = "Commands to test the application"
  value       = <<-EOT
    # Test health endpoint
    curl ${aws_apigatewayv2_api.main.api_endpoint}/${aws_apigatewayv2_stage.main.name}/health

    # Test API endpoint
    curl ${aws_apigatewayv2_api.main.api_endpoint}/${aws_apigatewayv2_stage.main.name}/api

    # Test with AWS CLI (LocalStack)
    aws --endpoint-url=http://localhost:4566 lambda invoke \
      --function-name ${aws_lambda_function.app.function_name} \
      response.json && cat response.json
  EOT
}

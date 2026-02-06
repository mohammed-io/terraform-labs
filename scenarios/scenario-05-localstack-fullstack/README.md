# Scenario 5: LocalStack - Full-Stack Architecture (Free Tier)

## Prerequisites

**Skills needed before starting:**
- ✅ Scenario 01: Docker Provider (Terraform basics)
- ✅ Scenario 02: LocalStack AWS Fundamentals (S3, DynamoDB)
- ✅ Scenario 03: LocalStack Networking (VPC, subnets)
- ✅ Scenario 04: LocalStack Security (IAM, KMS)
- Understanding of serverless architecture concepts
- Understanding of API Gateway and Lambda

**You will learn:**
- Complete serverless architecture design
- Terraform modules (custom and registry)
- Terraform data sources
- Multi-environment configurations
- API Gateway v2 HTTP APIs
- Lambda functions with IAM roles
- CloudWatch logging and monitoring

**Tools required:**
- Docker Desktop running locally
- Terraform 1.x installed
- AWS CLI (optional, for verification)
- LocalStack (will run via Docker)
- Python 3.x (for Lambda code examples)

---

## Learning Objectives

- Combine all previous concepts into a complete serverless architecture
- Use Terraform modules (custom and registry)
- Implement data sources for querying existing resources
- Create multi-environment configurations
- Use Terraform workspaces for environment separation
- Build a cost-effective, scalable architecture

> **⚠️ Free Tier Note:** This scenario uses ONLY LocalStack Community (free) services. RDS, ELB, and Auto Scaling require LocalStack Pro. We'll use serverless alternatives: DynamoDB instead of RDS, API Gateway instead of ELB.

## Requirements

Build a complete serverless 3-tier application:

```
                        Internet
                           │
                           │ HTTPS (443)
                           ▼
                    ┌──────────────┐
                    │  API         │
                    │  Gateway     │
                    │  (HTTP)      │
                    └──────┬───────┘
                           │
              ┌────────────┴────────────┐
              │                         │
              ▼                         ▼
       ┌────────────┐          ┌────────────┐
       │  Lambda    │          │  S3        │
       │  Authorizer│          │  Static    │
       └────────────┘          │  Assets    │
                              └────────────┘
              │
              ▼
       ┌────────────┐
       │  Lambda    │
       │  App Tier  │
       │  (API)     │
       └─────┬──────┘
             │
             ▼
       ┌────────────┐
       │  DynamoDB  │
       │  Data      │
       │  Tier      │
       └────────────┘
```

### Resources to Create (Free Tier Compatible)

1. **API Gateway v2**: HTTP API for routing
2. **Lambda Functions**:
   - Authorizer (authentication)
   - Web handler (main application)
   - Background worker
3. **DynamoDB Tables**:
   - Users table
   - Sessions table
   - Audit log table
4. **S3 Buckets**:
   - Static assets (CSS, JS, images)
   - File uploads
5. **CloudWatch**:
   - Log groups for Lambda
   - Alarms for errors
6. **IAM Roles**:
   - Lambda execution roles
   - Least privilege policies
7. **Cognito User Pool** (optional): User authentication

### Serverless Architecture Decisions

| Component | Serverless Choice | Why? |
|-----------|------------------|------|
| **Web Server** | API Gateway + Lambda | Scales automatically, pay-per-use |
| **Database** | DynamoDB | Managed NoSQL, free tier available |
| **Static Files** | S3 + CloudFront | Cheap, global CDN |
| **Auth** | Cognito or Lambda | Managed user directory |
| **Background Jobs** | EventBridge + Lambda | Serverless cron jobs |

### Variables to Use

| Variable | Default | Description |
|----------|---------|-------------|
| `environment` | "dev" | Environment name |
| `api_name` | "serverless-api" | API Gateway name |
| `api_stage` | "v1" | Deployment stage |
| `lambda_timeout` | 30 | Lambda timeout (seconds) |
| `lambda_memory` | 256 | Lambda memory (MB) |

## Your Task

Create `main.tf` in this directory with:

1. **Use a custom module** (see `modules/custom/vpc` if needed, but skip VPC for pure serverless)
2. **Import a registry module** (e.g., for S3 bucket or DynamoDB table)
3. **Data sources** for AMI (if using EC2) or AWS caller identity
4. **API Gateway v2** HTTP API with:
   - Routes for /health, /api/users, /api/data
   - Lambda integrations
   - Deployment and stage
5. **Lambda functions** with:
   - Proper IAM roles
   - CloudWatch logging
   - Environment variables
6. **DynamoDB tables** with:
   - Proper key schema
   - On-demand billing
   - Point-in-time recovery
7. **S3 buckets** with:
   - Versioning enabled
   - Lifecycle policies
   - Encryption
8. **CloudWatch alarms** for:
   - Lambda errors
   - Lambda throttles
9. **Outputs** for:
   - API endpoint URL
   - Lambda function names
   - Table names

### Module Usage Example

```hcl
# Use custom VPC module (optional for serverless)
module "vpc" {
  source = "../../modules/custom/vpc"

  name  = "${var.environment}-vpc"
  cidr  = "10.0.0.0/16"

  public_subnet_cidrs  = ["10.0.1.0/24"]
  private_subnet_cidrs = ["10.0.10.0/24"]

  enable_nat_gateway = false  # Not needed for Lambda
}

# Use registry module for S3
module "s3_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 3.0"

  bucket_prefix = "${var.environment}-assets"
  acl    = "private"

  versioning = {
    enabled = true
  }

  logging = {
    target_bucket = module.log_bucket.s3_bucket_id
    target_prefix = "log/"
  }
}
```

## Testing Your Work

```bash
# Start LocalStack with serverless services
docker run --rm -it -p 4566:4566 -p 4510-4559:4510-4559 \
  -e SERVICES=lambda,apigateway,dynamodb,s3,iam,cloudwatch,logs,sts,kms,secretsmanager \
  -e DEBUG=1 \
  -e DISABLE_CORS_CHECKS=1 \
  localstack/localstack:latest

# Initialize
terraform init

# Check plan
terraform plan

# Apply
terraform apply -auto-approve

# Test API endpoint
API_URL=$(terraform output api_endpoint)
curl $API_URL/health

# List Lambda functions
aws --endpoint-url=http://localhost:4566 lambda list-functions

# List DynamoDB tables
aws --endpoint-url=http://localhost:4566 dynamodb list-tables

# Invoke Lambda directly
aws --endpoint-url=http://localhost:4566 lambda invoke \
  --function-name $(terraform output lambda_function_name) \
  response.json

# Check CloudWatch logs
aws --endpoint-url=http://localhost:4566 logs describe-log-groups

# Clean up
terraform destroy
```

## Expected Results

When you run `terraform apply`, you should see:
- All resources created successfully
- API Gateway endpoint URL in outputs
- Lambda functions deployed
- DynamoDB tables created
- S3 buckets with proper configuration
- IAM roles with least privilege

## What You're Learning

| Concept | Why It Matters |
|---------|----------------|
| **Serverless** | No server management = lower cost, less ops |
| **API Gateway** | Managed HTTP API = routing, auth, throttling |
| **Lambda** | Pay-per-use compute = scales to zero |
| **DynamoDB** | Managed NoSQL = single-digit millisecond latency |
| **CloudWatch** | Observability = monitoring and alerting |
| **Modules** | Reuse infrastructure = DRY principles |

## Serverless vs Traditional AWS

| Traditional | Serverless | Benefit |
|-------------|------------|---------|
| EC2 instances | Lambda functions | No server management |
| RDS PostgreSQL | DynamoDB | Auto-scaling, pay-per-use |
| ELB/ALB | API Gateway | Cheaper, managed routing |
| Auto Scaling Group | Lambda concurrency | Automatic scaling |
| Bastion host | SSM Session Manager | No SSH keys needed |

## Advanced Terraform Features

### Archive Provider for Lambda

```hcl
# Package Lambda code
data "archive_file" "lambda" {
  type        = "zip"
  source_file = "${path.module}/lambda/index.py"
  output_path = "${path.module}/lambda.zip"
}

resource "aws_lambda_function" "app" {
  filename         = data.archive_file.lambda.output_path
  source_code_hash = data.archive_file.lambda.output_base64sha256

  function_name = "${var.environment}-app"
  role          = aws_iam_role.lambda.arn
  handler       = "index.handler"
  runtime       = "python3.11"
}
```

### Environment Variables

```hcl
resource "aws_lambda_function" "app" {
  # ...

  environment {
    variables = {
      DYNAMODB_TABLE  = aws_dynamodb_table.users.name
      LOG_LEVEL      = var.log_level
      ENVIRONMENT    = var.environment
    }
  }
}
```

### Lambda Layers

```hcl
# Reuse code across Lambda functions
resource "aws_lambda_layer_version" "common" {
  filename         = "common-layer.zip"
  layer_name       = "common"
  compatible_runtimes = ["python3.11"]

  description = "Common utilities for all Lambda functions"
}
```

## Hints

<details>
<summary>Hint 1: API Gateway v2 HTTP API</summary>

```hcl
resource "aws_apigatewayv2_api" "main" {
  name          = var.api_name
  protocol_type = "HTTP"
  description   = "Serverless application API"

  tags = {
    Environment = var.environment
  }
}

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
    })
  }
}
```

</details>

<details>
<summary>Hint 2: Lambda with API Integration</summary>

```hcl
resource "aws_lambda_function" "app" {
  filename      = "lambda.zip"
  function_name = "${var.environment}-app"
  role          = aws_iam_role.lambda.arn
  handler       = "index.handler"
  runtime       = "python3.11"

  timeout       = var.lambda_timeout
  memory_size   = var.lambda_memory
}

# Lambda permission for API Gateway
resource "aws_lambda_permission" "api" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.app.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.main.execution_arn}/*/*"
}

# API Integration
resource "aws_apigatewayv2_integration" "app" {
  api_id           = aws_apigatewayv2_api.main.id
  integration_type = "AWS_PROXY"

  connection_type           = "INTERNET"
  description              = "Lambda integration"
  integration_uri           = aws_lambda_function.app.arn
  payload_format_version = "2.0"
}
```

</details>

<details>
<summary>Hint 3: DynamoDB with Auto Scaling</summary>

```hcl
resource "aws_dynamodb_table" "users" {
  name           = "${var.environment}-users"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "user_id"

  attribute {
    name = "user_id"
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

# Auto-scaling for read capacity (if using PROVISIONED mode)
resource "aws_appautoscaling_target" "read" {
  max_capacity       = 100
  min_capacity       = 5
  resource_id        = "table/${aws_dynamodb_table.users.name}"
  scalable_dimension = "dynamodb:table:ReadCapacityUnits"
  service_namespace  = "dynamodb"
}
```

</details>

## Congratulations!

You've completed all 5 scenarios! You now have experience with:

- ✅ Docker provider basics
- ✅ AWS core services (S3, DynamoDB)
- ✅ VPC networking and security
- ✅ IAM, KMS, and security best practices
- ✅ Serverless architecture (API Gateway, Lambda, DynamoDB)
- ✅ Modules, data sources, and workspaces

### What's Different in Real AWS?

| LocalStack | Real AWS |
|------------|----------|
| Free for development | Free tier for 12 months |
| Limited service coverage | Full AWS service catalog |
| No actual costs | Real billing (set alerts!) |
| Faster iterations | Slightly slower |
| Some features missing | All features available |

### Next Steps to Master Terraform

1. **State Management**
   - Configure remote state backend (S3 + DynamoDB)
   - Implement state locking
   - Learn `terraform state` commands

2. **CI/CD Integration**
   - GitHub Actions / GitLab CI / Jenkins
   - Automated plan/apply workflows
   - Policy as Code (OPA/Conftest)

3. **Testing**
   - Terratest for integration testing
   - Unit tests with terraform-test
   - Compliance scanning (tfsec, checkov)

4. **Multi-Environment**
   - Workspaces vs separate directories
   - Terragrunt for DRY configuration
   - Environment promotion workflows

5. **Certification**
   - HashiCorp Certified: Terraform Associate
   - HashiCorp Certified: Terraform Professional

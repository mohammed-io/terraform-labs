# Lab: LocalStack - Full-Stack Serverless

## Setup

This lab uses LocalStack to simulate a complete serverless architecture with API Gateway, Lambda, DynamoDB, and S3.

## Prerequisites

1. Docker Desktop running
2. Terraform 1.5+ installed
3. LocalStack container running
4. Python 3.x (for Lambda code)

## Quick Start

```bash
# Create Lambda zip file
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

# Terminal 1: Start LocalStack
docker run --rm -it -p 4566:4566 -p 4510-4559:4510-4559 \
  -e SERVICES=lambda,apigateway,dynamodb,s3,iam,cloudwatch,logs,sts \
  -e DEBUG=1 \
  -e DISABLE_CORS_CHECKS=1 \
  localstack/localstack:latest

# Terminal 2: Run Terraform
terraform init
terraform plan
terraform apply
```

## Verification

```bash
# Run verification script
bash verify.sh

# Test the API manually
API_URL=$(terraform output -raw api_endpoint)
curl "http://$API_URL/health"
curl "http://$API_URL/api/users"
```

## Files

- `main.tf` - Starter code (complete solution in solution.md)
- `verify.sh` - Automated verification script
- `index.py` - Sample Lambda code (create and zip to lambda.zip)

## Cleanup

```bash
terraform destroy
```

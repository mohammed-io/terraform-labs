# LocalStack Free Tier Services

## Free (Community) vs Paid (Pro/Team)

### ✅ Free Tier Services (Used in Scenarios)

| Service | Status | Scenarios |
|---------|--------|-----------|
| **S3** | ✅ Full | 02, 05 |
| **DynamoDB** | ✅ Full | 02, 05 |
| **IAM** | ✅ Full | 03, 04 |
| **KMS** | ✅ Full | 04 |
| **Secrets Manager** | ✅ Full | 04 |
| **Lambda** | ✅ Full | 05 |
| **CloudWatch** | ✅ Full | 05 |
| **STS** | ✅ Full | 04 |
| **SSM** | ✅ Full | 05 |
| **API Gateway** | ✅ Full | - |
| **SQS** | ✅ Full | - |
| **SNS** | ✅ Full | - |
| **Step Functions** | ✅ Full | - |

### ❌ Paid Services (Not in Free Tier)

| Service | Status | Requires | Used in Scenario |
|---------|--------|----------|------------------|
| **RDS** | ❌ Pro | $25/month | 05 (alternative: use DynamoDB or containerized DB) |
| **EC2** | ⚠️ Limited | Pro for full | 03, 05 (basic networking still works) |
| **ELB/ALB** | ❌ Pro | $25/month | 05 (alternative: use API Gateway + Lambda) |
| **Auto Scaling** | ❌ Pro | $25/month | 05 (alternative: manual scaling) |
| **NAT Gateway** | ❌ Pro | $25/month | 03, 05 (not needed for LocalStack) |
| **EKS** | ❌ Team | $50/month | - |
| **ECS** | ❌ Pro | $25/month | - |

---

## Scenario Compatibility

| Scenario | Free Tier Compatible? | Notes |
|----------|----------------------|-------|
| **01 - Docker** | ✅ Yes | Uses Docker provider, not AWS |
| **02 - Basics** | ✅ Yes | S3 + DynamoDB fully supported |
| **03 - Networking** | ⚠️ Partial | VPC concepts work, but EC2 instances limited |
| **04 - Security** | ✅ Yes | IAM + KMS + Secrets fully supported |
| **05 - Full-Stack** | ⚠️ Modified | RDS/ELB need alternatives (see below) |

---

## Free Alternatives for Paid Services

### Instead of RDS (PostgreSQL/MySQL)

**Option 1: DynamoDB** (Serverless, free)
```hcl
resource "aws_dynamodb_table" "users" {
  name           = "users"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }
}
```

**Option 2: Docker + RDS in container**
```bash
# Run PostgreSQL locally
docker run -d -p 5432:5432 \
  -e POSTGRES_PASSWORD=secret \
  postgres:15
```

### Instead of ELB/ALB

**Option 1: API Gateway + Lambda** (Serverless, free)
```hcl
resource "aws_apigatewayv2_api" "lambda" {
  name          = "lambda-api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "lambda" {
  api_id           = aws_apigatewayv2_api.lambda.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.test.invoke_arn
}
```

**Option 2: Docker Compose + Nginx**
```yaml
services:
  nginx:
    image: nginx
    ports:
      - "8080:80"
  app:
    image: myapp
```

### Instead of Auto Scaling Groups

**Option 1: Lambda concurrency** (Serverless, free)
```hcl
resource "aws_lambda_function" "app" {
  function_name = "my-app"
  runtime       = "python3.11"
  handler       = "index.handler"

  # Concurrency acts as scaling
  reserved_concurrent_executions = 10
}
```

---

## Testing with Free Tier

```bash
# Start LocalStack (community edition)
docker run --rm -it \
  -p 4566:4566 \
  -e SERVICES=s3,dynamodb,iam,kms,secretsmanager,lambda,apigateway \
  localstack/localstack

# Verify available services
curl http://localhost:4566/health | jq
```

---

## Recommendation for Learning

If you want to practice with **all AWS services** including RDS, ELB, Auto Scaling:

1. **Use AWS Free Tier** - 12 months free, includes:
   - 750 hours/month of EC2 (t2.micro/t3.micro)
   - 750 hours/month of ELB
   - 25 GB of DynamoDB
   - 5 GB of S3 storage

2. **Set up budget alerts** - Avoid surprise charges:
   ```bash
   aws budgets create-budget \
     --account-id $ACCOUNT_ID \
     --budget 'file://budget.json'
   ```

3. **Always destroy resources**:
   ```bash
   terraform destroy
   ```

---

## LocalStack Pricing (as of 2024)

| Plan | Price | Key Features |
|------|-------|--------------|
| **Community** | Free | S3, DynamoDB, Lambda, IAM, KMS, Secrets |
| **Pro** | $25/month | Add RDS, EC2, ELB, Auto Scaling |
| **Team** | $50/month | Add EKS, ECS, multi-user |
| **Enterprise** | Custom | SSO, audit logs, support |

For learning Terraform, **Community edition is sufficient** for most core concepts!

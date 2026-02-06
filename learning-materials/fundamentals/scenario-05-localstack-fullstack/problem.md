---
name: "LocalStack - Full-Stack Serverless"
category: "fundamentals"
difficulty: "advanced"
time: "60 minutes"
services: ["apigateway", "lambda", "dynamodb", "s3", "cloudwatch"]
concepts: ["api-gateway-v2", "lambda-functions", "dynamodb-tables", "s3-buckets", "iam-roles"]
---

# LocalStack - Full-Stack Serverless

## Scenario

You're building a complete serverless application with API Gateway, Lambda, DynamoDB, and S3. This brings together everything from the previous scenarios into a real-world architecture.

## Architecture

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
       │  App Tier  │          │  Static    │
       │  (API)     │          │  Assets    │
       └─────┬──────┘          └────────────┘
             │
             ▼
       ┌────────────┐
       │  DynamoDB  │
       │  Data      │
       │  Tier      │
       └────────────┘
```

## Requirements

Build a complete serverless 3-tier application:

1. **API Gateway v2**: HTTP API with routes for `/health`, `/api/users`, `/api/data`
2. **Lambda Functions**:
   - Main app handler (Python runtime)
   - IAM execution role with least privilege
3. **DynamoDB Tables**:
   - Users table with GSI on email
   - Sessions table
4. **S3 Buckets**:
   - Static assets bucket (versioning enabled)
   - File uploads bucket
5. **CloudWatch**:
   - Log groups for Lambda
6. **IAM Roles**:
   - Lambda execution role with proper permissions

## Constraints

- Use API Gateway v2 (HTTP APIs) - not v1
- Lambda must use Python 3.11 runtime
- DynamoDB tables must use PAY_PER_REQUEST billing
- S3 buckets must have versioning enabled
- IAM role must follow least privilege principle

## Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `environment` | "dev" | Environment name |
| `api_name` | "serverless-api" | API Gateway name |
| `api_stage` | "v1" | Deployment stage |
| `lambda_timeout` | 30 | Lambda timeout (seconds) |
| `lambda_memory` | 256 | Lambda memory (MB) |

## Prerequisites

- Complete scenarios 01-04
- Docker Desktop running
- Terraform 1.x installed
- Understanding of serverless architecture

## What You'll Learn

| Concept | Why It Matters |
|---------|----------------|
| **API Gateway v2** | Managed HTTP API = routing, auth, throttling |
| **Lambda** | Pay-per-use compute = scales to zero |
| **DynamoDB** | Managed NoSQL = single-digit millisecond latency |
| **CloudWatch** | Observability = monitoring and alerting |
| **IAM for Lambda** | Service roles with least privilege |
| **Serverless Architecture** | No server management = lower cost, less ops |

## Getting Started

1. Make sure LocalStack is running with all required services:
   ```bash
   docker run --rm -it -p 4566:4566 -p 4510-4559:4510-4559 \
     -e SERVICES=lambda,apigateway,dynamodb,s3,iam,cloudwatch,logs,sts \
     -e DEBUG=1 \
     -e DISABLE_CORS_CHECKS=1 \
     localstack/localstack:latest
   ```

2. Navigate to the lab directory and start building!

3. Check `step-01.md` for hints on API Gateway and Lambda.

4. Check `step-02.md` for hints on DynamoDB and S3 integration.

## Verification

Run the lab's `verify.sh` script to check your work:

```bash
cd lab
bash verify.sh
```

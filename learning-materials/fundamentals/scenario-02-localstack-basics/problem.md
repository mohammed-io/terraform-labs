---
name: "LocalStack - AWS Fundamentals"
category: "fundamentals"
difficulty: "beginner"
time: "30 minutes"
services: ["s3", "dynamodb"]
concepts: ["aws-provider", "s3-buckets", "dynamodb-tables", "terraform-state"]
---

# LocalStack - AWS Fundamentals

## Scenario

You're building a simple serverless data pipeline that stores file uploads in S3 and user data in DynamoDB. Before deploying to real AWS, you want to test everything locally using LocalStack.

## Architecture

```
┌─────────────┐      ┌──────────────┐      ┌─────────────┐
│  S3 Bucket  │──────│  Lambda      │──────│ DynamoDB    │
│  (Uploads)  │      │  (Process)   │      │  (Database) │
└─────────────┘      └──────────────┘      └─────────────┘
```

## Requirements

Build a serverless data pipeline with:

1. **S3 Bucket**: `raw-uploads-bucket` with versioning enabled
2. **S3 Object**: Upload a sample file to the bucket
3. **DynamoDB Table**: `users-table` with:
   - Partition key: `user_id` (String)
   - Sort key: `timestamp` (String)
   - Billing mode: PAY_PER_REQUEST
4. **DynamoDB Table Item**: Sample user data

## Constraints

- Use LocalStack endpoints (`http://localhost:4566`)
- Configure AWS provider for LocalStack (test credentials, skip validations)
- S3 bucket must have `force_destroy = true` for easy cleanup
- DynamoDB table must use PAY_PER_REQUEST billing

## Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `bucket_name` | "raw-uploads-bucket" | Name of S3 bucket |
| `table_name` | "users-table" | Name of DynamoDB table |
| `user_id` | "user-123" | Sample user ID |
| `environment` | "dev" | Environment tag |

## Prerequisites

- Docker Desktop running
- Terraform 1.x installed
- Complete scenario-01-docker first

## What You'll Learn

| Concept | Why It Matters |
|---------|----------------|
| **AWS Provider Configuration** | Connect Terraform to AWS (or LocalStack) |
| **S3 Buckets** | Object storage = foundation of data lakes |
| **DynamoDB** | NoSQL database = serverless at scale |
| **Terraform State** | State file tracks all AWS resources created |
| **LocalStack Endpoints** | How to redirect AWS SDK to local mock |

## Getting Started

1. Make sure LocalStack is running:
   ```bash
   docker run --rm -it -p 4566:4566 -p 4510-4559:4510-4559 \
     -e SERVICES=s3,dynamodb \
     localstack/localstack:latest
   ```

2. Navigate to the lab directory and start building!

3. Check `step-01.md` for hints on AWS provider configuration and S3 buckets.

4. Check `step-02.md` for hints on DynamoDB tables and items.

## Verification

Run the lab's `verify.sh` script to check your work:

```bash
cd lab
bash verify.sh
```

Or manually test:

```bash
# List S3 buckets
aws --endpoint-url=http://localhost:4566 s3 ls

# List DynamoDB tables
aws --endpoint-url=http://localhost:4566 dynamodb list-tables

# Check outputs
terraform output bucket_name
terraform output table_name
```

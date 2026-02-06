# Lab: LocalStack - AWS Fundamentals

## Setup

This lab uses LocalStack (AWS mock running in Docker).

## Prerequisites

1. Docker Desktop running
2. Terraform 1.5+ installed
3. LocalStack container running

## Quick Start

```bash
# Terminal 1: Start LocalStack
docker run --rm -it -p 4566:4566 -p 4510-4559:4510-4559 \
  -e SERVICES=s3,dynamodb \
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

# Or check manually
aws --endpoint-url=http://localhost:4566 s3 ls
aws --endpoint-url=http://localhost:4566 dynamodb list-tables
```

## Files

- `main.tf` - Starter code (complete solution in solution.md)
- `verify.sh` - Automated verification script
- `sample-data.json` - Sample file for S3 upload

## Cleanup

```bash
terraform destroy
```

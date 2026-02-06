# Lab: LocalStack - AWS Security

## Setup

This lab uses LocalStack to simulate AWS security services (IAM, KMS, Secrets Manager).

## Prerequisites

1. Docker Desktop running
2. Terraform 1.5+ installed
3. LocalStack container running

## Quick Start

```bash
# Terminal 1: Start LocalStack
docker run --rm -it -p 4566:4566 -p 4510-4559:4510-4559 \
  -e SERVICES=iam,kms,secretsmanager,lambda,sts \
  -e DEBUG=1 \
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
aws --endpoint-url=http://localhost:4566 iam list-users
aws --endpoint-url=http://localhost:4566 kms list-keys
aws --endpoint-url=http://localhost:4566 secretsmanager list-secrets
```

## Files

- `main.tf` - Starter code (complete solution in solution.md)
- `verify.sh` - Automated verification script

## Cleanup

```bash
terraform destroy
```

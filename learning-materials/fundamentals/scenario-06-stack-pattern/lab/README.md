# Lab: The Stack Pattern

This lab demonstrates real-world Terraform organization using multiple stacks.

## Prerequisites

1. Docker Desktop running
2. Terraform 1.5+ installed
3. LocalStack container running

## Quick Start

```bash
# Terminal 1: Start LocalStack
docker run --rm -it -p 4566:4566 -p 4510-4559:4510-4559 \
  -e SERVICES=ec2,dynamodb,iam,elb \
  -e DEBUG=1 \
  localstack/localstack:latest

# Terminal 2: Deploy all stacks
bash deploy-all.sh
```

## Directory Structure

```
lab/
├── deploy-all.sh       # Deploy all stacks in order
├── destroy-all.sh      # Destroy all stacks in reverse order
├── 01-networking/
│   ├── main.tf         # VPC, subnets, security groups
│   └── outputs.tf      # Outputs for other stacks
├── 02-database/
│   ├── main.tf         # DynamoDB (reads from networking)
│   └── outputs.tf      # Outputs for application stack
└── 03-application/
    ├── main.tf         # ALB (reads from networking + database)
    └── outputs.tf
```

## Verification

```bash
# After deployment, check each stack
terraform -chdir=01-networking output
terraform -chdir=02-database output
terraform -chdir=03-application output
```

## Cleanup

```bash
bash destroy-all.sh
```

---
name: "The Stack Pattern - Real-World Organization"
category: "fundamentals"
difficulty: "advanced"
time: "60 minutes"
services: ["vpc", "rds", "ecs", "alb"]
concepts: ["terraform-remote-state", "stack-pattern", "multi-directory", "cross-stack-outputs"]
---

# The Stack Pattern - Real-World Organization

## Scenario

You're organizing infrastructure like real companies do - splitting it into logical "stacks" that can be deployed independently. This is how most production environments are structured.

## What is a Stack?

A **stack** is a logical grouping of infrastructure that:
- Has ONE `terraform.tfstate` file
- Can be deployed independently
- Has clear ownership
- Can be destroyed without affecting other stacks

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    My Application                          │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  Stack 1: Networking      (VPC, Subnets, Security Groups)   │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  VPC: 10.0.0.0/16                                   │   │
│  │  Public Subnets: 10.0.1.0/24, 10.0.2.0/24           │   │
│  │  Private Subnets: 10.0.10.0/24, 10.0.11.0/24        │   │
│  └─────────────────────────────────────────────────────┘   │
│                          ▼                                  │
│  Stack 2: Database        (DynamoDB)                        │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  Table: users-table                                 │   │
│  │  Endpoint: Reads from networking stack outputs     │   │
│  └─────────────────────────────────────────────────────┘   │
│                          ▼                                  │
│  Stack 3: Application     (ECS/Lambda, ALB)                │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  Load Balancer: Reads from networking stack        │   │
│  │  ECS Service: Reads from database stack            │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

## Requirements

Implement three stacks in dependency order:

### Stack 1: Networking (01-networking/)
- VPC with CIDR `10.0.0.0/16`
- 2 public subnets (for ALB)
- 2 private subnets (for ECS)
- Internet Gateway
- Security Groups (web, app)

**Outputs for other stacks:**
- `vpc_id`
- `public_subnet_ids`
- `private_subnet_ids`
- `web_security_group_id`
- `app_security_group_id`

### Stack 2: Database (02-database/)
- DynamoDB table
- Reads VPC and subnet IDs from networking stack via `terraform_remote_state`

**Outputs for other stacks:**
- `table_name`
- `table_arn`

### Stack 3: Application (03-application/)
- Application Load Balancer (or simplified for LocalStack)
- Reads networking outputs from Stack 1
- Reads database outputs from Stack 2

**Outputs:**
- `application_url`

## Constraints

- Each stack must have its own state file
- Stack 2 depends on Stack 1 (reads remote state)
- Stack 3 depends on both Stack 1 and Stack 2
- Use `terraform_remote_state` data source for cross-stack communication

## Why Use Stacks?

| Benefit | Explanation |
|---------|-------------|
| **Blast Radius** | If one stack fails, others are unaffected |
| **Deploy Speed** | Only deploy what changed (app changes ≠ DB changes) |
| **Team Ownership** | Different teams own different stacks |
| **Parallel Work** | Multiple engineers can work on different stacks |
| **Easier Debugging** | Smaller state files, fewer resources per plan |

## Prerequisites

- Complete scenarios 01-05
- Docker Desktop running
- Terraform 1.x installed
- Understanding of Terraform state

## Getting Started

1. Start LocalStack:
   ```bash
   docker run --rm -it -p 4566:4566 -p 4510-4559:4510-4559 \
     -e SERVICES=ec2,dynamodb,iam,elb \
     -e DEBUG=1 \
     localstack/localstack:latest
   ```

2. Deploy stacks IN ORDER:
   ```bash
   cd 01-networking && terraform apply && cd ..
   cd 02-database && terraform apply && cd ..
   cd 03-application && terraform apply && cd ..
   ```

3. Check `step-01.md` for hints on the terraform_remote_state data source.

## Verification

Run the deploy script to verify all stacks work together:

```bash
bash lab/deploy-all.sh
```

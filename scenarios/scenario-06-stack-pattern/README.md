# Scenario 6: The "Stack" Pattern - Real-World Organization

## Prerequisites

**Skills needed before starting:**
- ✅ Scenario 01: Docker Provider (Terraform basics)
- ✅ Scenario 02: LocalStack AWS Fundamentals
- ✅ Scenario 03: LocalStack Networking
- ✅ Scenario 04: LocalStack Security
- ✅ Scenario 05: Full-Stack Architecture
- Understanding of Terraform state files
- Understanding of infrastructure dependencies

**You will learn:**
- The "stack" pattern used in production
- How to split infrastructure into logical units
- `terraform_remote_state` data source
- Cross-stack communication via outputs
- Deployment ordering and dependencies
- Real-world project organization

**Tools required:**
- Docker Desktop running locally
- Terraform 1.x installed
- AWS CLI (optional, for verification)
- LocalStack (will run via Docker)

---

## Learning Objectives

- Understand the **stack** pattern used by most companies
- Learn how to split infrastructure into logical units
- Handle dependencies between stacks using remote state
- Deploy infrastructure incrementally
- Mimic real-world project structure

## What is a "Stack"?

A **stack** is a logical grouping of infrastructure that:
- Has ONE `terraform.tfstate` file
- Can be deployed independently
- Has clear ownership
- Can be destroyed without affecting other stacks

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
│  Stack 2: Database        (RDS/DynamoDB)                   │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  PostgreSQL: app-db                                 │   │
│  │  Endpoint: app-db.xxx.us-east-1.rds.amazonaws.com   │   │
│  └─────────────────────────────────────────────────────┘   │
│                          ▼                                  │
│  Stack 3: Application     (ECS/Lambda, ALB)                │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  ECS Cluster: app-cluster                           │   │
│  │  ECS Service: app-service                           │   │
│  │  Load Balancer: app-alb                             │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

## Why Use Stacks?

| Benefit | Explanation |
|---------|-------------|
| **Blast Radius** | If one stack fails, others are unaffected |
| **Deploy Speed** | Only deploy what changed (app code changes ≠ DB changes) |
| **Team Ownership** | Different teams own different stacks |
| **Parallel Work** | Multiple engineers can work on different stacks |
| **Easier Debugging** | Smaller state files, fewer resources per plan |

## Scenario Structure

```
scenario-06-stack-pattern/
├── README.md                      # This file
├── 01-networking/                 # Stack 1: Deploy FIRST
│   ├── main.tf                    # Creates VPC, subnets, SGs
│   ├── backend.tf                 # State configuration
│   └── outputs.tf                 # Outputs for other stacks to use
├── 02-database/                   # Stack 2: Deploy SECOND
│   ├── main.tf                    # Creates RDS/DynamoDB
│   ├── backend.tf                 # State configuration
│   ├── data.tf                    # Reads outputs from 01-networking
│   └── outputs.tf                 # Outputs for other stacks to use
└── 03-application/                # Stack 3: Deploy LAST
    ├── main.tf                    # Creates ECS/Lambda/ALB
    ├── backend.tf                 # State configuration
    ├── data.tf                    # Reads outputs from 01 & 02
    └── outputs.tf
```

## Your Task

Implement the three stacks in order. Each stack depends on the previous one.

### Stack 1: Networking (01-networking/)

Create a VPC with:
- 2 public subnets (for ALB)
- 2 private subnets (for ECS)
- 2 database subnets (for RDS)
- Internet Gateway
- Security Groups (web, app, database)

**Outputs to provide:**
- `vpc_id`
- `public_subnet_ids`
- `private_subnet_ids`
- `database_subnet_ids`
- `web_security_group_id`
- `app_security_group_id`
- `database_security_group_id`

### Stack 2: Database (02-database/)

Create a database that:
- Uses subnets from Stack 1 (via `terraform_remote_state`)
- Uses security group from Stack 1
- Is NOT accessible from the internet

**Outputs to provide:**
- `database_endpoint`
- `database_port`
- `database_name`

### Stack 3: Application (03-application/)

Create an application that:
- Uses subnets from Stack 1
- Uses database endpoint from Stack 2
- Is accessible from the internet via ALB

**Outputs to provide:**
- `load_balancer_dns_name`
- `application_url`

---

## The Magic: terraform_remote_state

This is how stacks communicate. Stack 2 reads outputs from Stack 1:

```hcl
# In 02-database/data.tf
data "terraform_remote_state" "networking" {
  backend = "local"  # In real AWS, use "s3"

  config = {
    path = "${path.module}/../01-networking/terraform.tfstate"
  }
}

# Now use the outputs
resource "aws_db_subnet_group" "main" {
  name       = "main"
  subnet_ids = data.terraform_remote_state.networking.outputs.database_subnet_ids
}
```

---

## Deployment Order

**IMPORTANT:** Deploy in order!

```bash
# Step 1: Deploy networking
cd 01-networking
terraform init
terraform apply
cd ..

# Step 2: Deploy database (reads from networking state)
cd 02-database
terraform init
terraform apply
cd ..

# Step 3: Deploy application (reads from networking + database state)
cd 03-application
terraform init
terraform apply
cd ..
```

---

## State Files

After deploying, you'll have 3 state files:

```
terraform.tfstate files:

01-networking/terraform.tfstate
  ├─ VPC
  ├─ Subnets (6)
  ├─ Internet Gateway
  └─ Security Groups (3)

02-database/terraform.tfstate
  ├─ RDS Instance
  └─ DB Subnet Group
  (References networking state via data source)

03-application/terraform.tfstate
  ├─ ECS Cluster
  ├─ ECS Service
  └─ Load Balancer
  (References networking + database states)
```

---

## Real-World Backend Configuration

In production, you'd use S3 for remote state:

```hcl
# backend.tf (in each stack)
terraform {
  backend "s3" {
    bucket         = "my-company-terraform-state"
    key            = "myapp/prod/us-east-1/01-networking/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}
```

Each stack has a different `key`:
```
01-networking → key = "myapp/prod/us-east-1/01-networking/terraform.tfstate"
02-database   → key = "myapp/prod/us-east-1/02-database/terraform.tfstate"
03-application→ key = "myapp/prod/us-east-1/03-application/terraform.tfstate"
```

---

## Hints

<details>
<summary>Hint 1: Stack 1 - Outputs</summary>

```hcl
# 01-networking/outputs.tf
output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "database_subnet_ids" {
  value = aws_subnet.database[*].id
}

output "database_security_group_id" {
  value = aws_security_group.database.id
}
```

</details>

<details>
<summary>Hint 2: Stack 2 - Reading Remote State</summary>

```hcl
# 02-database/data.tf
terraform {
  # This is required for terraform_remote_state to work
  # It tells Terraform where to find the backend configuration
}

data "terraform_remote_state" "networking" {
  backend = "local"

  config = {
    path = "${path.module}/../01-networking/terraform.tfstate"
  }
}

# Use the outputs
resource "aws_db_subnet_group" "main" {
  name       = "app-db-subnet-group"
  subnet_ids = data.terraform_remote_state.networking.outputs.database_subnet_ids
}

resource "aws_security_group" "database" {
  name   = "database-sg"
  vpc_id = data.terraform_remote_state.networking.outputs.vpc_id
}
```

</details>

<details>
<summary>Hint 3: Stack 3 - Reading Multiple States</summary>

```hcl
# 03-application/data.tf
data "terraform_remote_state" "networking" {
  backend = "local"
  config = {
    path = "${path.module}/../01-networking/terraform.tfstate"
  }
}

data "terraform_remote_state" "database" {
  backend = "local"
  config = {
    path = "${path.module}/../02-database/terraform.tfstate"
  }
}

# Use outputs from both
resource "aws_ecs_task_definition" "app" {
  # ...

  environment {
    name  = "DB_ENDPOINT"
    value = data.terraform_remote_state.database.outputs.database_endpoint
  }
}
```

</details>

---

## Testing Your Stack

```bash
# Deploy all stacks
./deploy-all.sh

# Check application
curl $(terraform -chdir=03-application output -raw application_url)

# Destroy all stacks (reverse order!)
terraform -chdir=03-application destroy
terraform -chdir=02-database destroy
terraform -chdir=01-networking destroy
```

---

## Why This Matters

When you join a company using Terraform, you'll likely see:

```
$ cd infrastructure/stacks/payment-service
$ terraform plan
```

Understanding stacks means you know:
1. What resources this stack manages
2. What other stacks this depends on
3. What will happen when you run apply
4. How to find outputs from other stacks

---

## Common Pitfalls

### 1. Circular Dependencies

```
Stack A depends on Stack B
Stack B depends on Stack A
❌ This will never work!
```

**Solution:** Reorganize stacks. Put shared resources in their own stack.

### 2. Missing Outputs

```
Stack B tries to read: data.terraform_remote_state.a.outputs.some_value
But Stack A doesn't output some_value
❌ Error: output not found
```

**Solution:** Always define needed outputs in the source stack.

### 3. Wrong Deployment Order

```
You deploy Stack 2 before Stack 1
❌ Error: networking state not found
```

**Solution:** Always deploy dependencies first. Use a deployment script.

---

## After This Scenario

You understand how companies organize Terraform. Next steps:

1. **Scenario 5**: Full-stack serverless architecture
2. **docs/PROJECT_ORGANIZATION.md**: More patterns used by big companies
3. **Practice**: Design your own app stack structure

---

## Answer Keys

- `01-networking/main.tf` - Complete networking stack
- `02-database/main.tf` - Database stack with remote state
- `03-application/main.tf` - Application stack with multiple dependencies

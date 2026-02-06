# Terraform File Conventions - Quick Reference

## Standard File Structure

This is what you'll see in 95% of companies using Terraform:

```
project-root/
├── backend.tf          # Remote state backend config
├── provider.tf         # Provider configuration
├── versions.tf         # Terraform and provider version constraints
├── variables.tf        # All variable definitions
├── terraform.tfvars    # Variable values (gitignored!)
├── data.tf             # Data sources (reads from other stacks/AWS)
├── main.tf             # Main resource definitions
├── outputs.tf          # Output definitions
├── locals.tf           # Local values (optional)
└── README.md           # Documentation
```

## File-by-File Breakdown

### `backend.tf`
Remote state configuration - Where your state file lives.

```hcl
terraform {
  backend "s3" {
    bucket         = "my-terraform-state"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}
```

### `provider.tf`
Provider configuration - Which cloud/services you're using.

```hcl
provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      Environment = "prod"
      ManagedBy   = "terraform"
    }
  }
}
```

### `versions.tf`
Version constraints - Ensures consistent runs.

```hcl
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
```

### `variables.tf`
Input variable definitions - What your code accepts.

```hcl
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"

  validation {
    condition     = can(regex("^t[23]\\.", var.instance_type))
    error_message = "Must be t2 or t3 instance."
  }
}
```

### `terraform.tfvars`
**DO NOT COMMIT** - Contains actual values for variables.

```hcl
instance_type = "t3.small"
environment   = "prod"
db_password   = "supersecret"  # NEVER commit this!
```

Use `terraform.tfvars.example` instead:
```hcl
instance_type = "t3.small"
environment   = "prod"
db_password   = "CHANGE_ME"
```

### `data.tf`
Data sources - Reading existing resources or remote state.

```hcl
# Read from another stack
data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "my-terraform-state"
    key    = "vpc/terraform.tfstate"
  }
}

# Read from AWS
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
}
```

### `main.tf`
Main resource definitions - The core infrastructure.

```hcl
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
}

resource "aws_subnet" "public" {
  count      = length(var.public_subnet_cidrs)
  vpc_id     = aws_vpc.main.id
  cidr_block = var.public_subnet_cidrs[count.index]
}
```

### `outputs.tf`
Output values - What your stack produces.

```hcl
output "vpc_id" {
  description = "VPC identifier"
  value       = aws_vpc.main.id
}

output "db_connection_string" {
  description = "Database connection"
  value       = "postgresql://${var.db_user}:${var.db_pass}@${aws_db.main.endpoint}"
  sensitive   = true
}
```

### `locals.tf` (optional)
Local values - Reusable expressions within your module.

```hcl
locals {
  name_prefix = "${var.environment}-myapp"
  common_tags = {
    Project   = "myapp"
    ManagedBy = "terraform"
  }
}

resource "aws_vpc" "main" {
  tags = merge(local.common_tags, { Name = "${local.name_prefix}-vpc" })
}
```

---

## File Naming Rules

| Rule | Correct | Incorrect |
|------|---------|-----------|
| Use lowercase | `main.tf` | `Main.tf` |
| Use `.tf` extension | `variables.tf` | `variables.tf.json` |
| Use hyphens for compound | `backend.tf` | `backendConfig.tf` |
| One purpose per file | `provider.tf` | `providers-and-variables.tf` |
| `.tfvars` for values | `dev.tfvars` | `dev-values.tf` |

---

## When to Create New Files

### Create a new `.tf` file when:
- You have 50+ lines of one resource type → `ec2.tf`, `s3.tf`
- You want to separate concerns → `security_groups.tf`, `iam.tf`
- Working with a team → Clear file ownership

### Keep it simple when:
- Learning Terraform → One or two files is fine
- Small projects (< 100 resources) → 3-5 files is enough

---

## Module File Structure

```
modules/
└── my-module/
    ├── README.md           # Usage documentation
    ├── main.tf             # Resources
    ├── variables.tf        # Inputs
    ├── outputs.tf          # Outputs
    └── versions.tf         # Version constraints
```

---

## Scenario 6: Complete Example

See `answers/scenario-06-stack-pattern/` for a complete multi-file implementation:

```
01-networking/
├── backend.tf      # Remote state config
├── provider.tf     # AWS provider
├── versions.tf     # Version constraints
├── variables.tf    # VPC CIDR, subnet CIDRs, etc.
├── main.tf         # VPC, subnets, security groups
└── outputs.tf      # vpc_id, subnet_ids, sg_ids

02-database/
├── backend.tf
├── provider.tf
├── versions.tf
├── data.tf         # Reads from 01-networking state
├── variables.tf
├── main.tf         # DynamoDB tables, KMS, Secrets
└── outputs.tf

03-application/
├── backend.tf
├── provider.tf
├── versions.tf
├── data.tf         # Reads from 01 & 02 states
├── variables.tf
├── main.tf         # Lambda, API Gateway, IAM
└── outputs.tf
```

---

## Quick Checklist

- [ ] `backend.tf` - Configured for remote state
- [ ] `provider.tf` - Provider(s) configured
- [ ] `versions.tf` - Versions pinned
- [ ] `variables.tf` - All inputs defined
- [ ] `terraform.tfvars.example` - Example values provided
- [ ] `data.tf` - Remote state or AWS data sources
- [ ] `main.tf` - Resources defined
- [ ] `outputs.tf` - Important values exported
- [ ] `README.md` - Documentation for the next person

---

## Remember

> Terraform loads ALL `.tf` files in a directory alphabetically.
> File order doesn't matter - Terraform sees them as one combined file.

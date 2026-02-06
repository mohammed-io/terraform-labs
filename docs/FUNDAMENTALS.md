# Terraform Fundamentals - Complete Learning Guide

**Comprehensive guide for learning Terraform from scratch to advanced.**

---

## Table of Contents

1. [Core Concepts](#1-core-concepts)
2. [Installation & Setup](#2-installation--setup)
3. [Basic Commands](#3-basic-commands)
4. [HCL Syntax Deep Dive](#4-hcl-syntax-deep-dive)
5. [State Management](#5-state-management)
6. [Modules](#6-modules)
7. [Data Sources](#7-data-sources)
8. [Provisioners](#8-provisioners)
9. [Variables & Outputs](#9-variables--outputs)
10. [Resource Dependencies](#10-resource-dependencies)
11. [Workspaces](#11-workspaces)
12. [CI/CD Integration](#12-cicd-integration)
13. [Testing](#13-testing)
14. [Best Practices](#14-best-practices)

---

## 1. Core Concepts

### What is Terraform?

**Terraform** is Infrastructure as Code (IaC) tool that:
- Declaratively defines infrastructure (desired state)
- Manages 100+ providers (AWS, Azure, GCP, Kubernetes, Docker, etc.)
- Creates, updates, and deletes resources safely
- Tracks state in a state file

### Declarative vs Imperative

```hcl
# Declarative (Terraform): "I want a web server"
resource "aws_instance" "web" {
  ami           = "ami-12345"
  instance_type = "t3.micro"
}

# Imperative (CLI): "Create server, then add security group, then attach disk..."
# Imperative = HOW to get there
# Declarative = WHAT you want
```

### Key Files

| File | Purpose |
|------|---------|
| `main.tf` | Main configuration file |
| `variables.tf` | Input variable definitions |
| `outputs.tf` | Output definitions |
| `terraform.tfvars` | Variable values (usually gitignored) |
| `versions.tf` | Required provider and Terraform versions |
| `terraform.tfstate` | Current state of infrastructure (**NEVER edit**) |
| `.terraform.lock.hcl` | Dependency lock file (commit to git) |

---

## 2. Installation & Setup

### Install Terraform

```bash
# macOS (Homebrew)
brew install terraform

# Linux (download binary)
wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
unzip terraform_1.6.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/

# Verify
terraform version
```

### Environment Variables

```bash
# AWS credentials (when not using profiles)
export AWS_ACCESS_KEY_ID="your-key"
export AWS_SECRET_ACCESS_KEY="your-secret"
export AWS_REGION="us-east-1"

# Terraform specific
export TF_LOG=INFO          # Debug: TRACE, DEBUG, INFO, WARN, ERROR
export TF_LOG_PATH=./tf.log # Log to file
export TF_INPUT=0           # Non-interactive mode
export TF_VAR_environment=prod # Set variable value
```

### Shell Auto-Completion

```bash
terraform -install-autocomplete
source ~/.bashrc  # or ~/.zshrc
```

---

## 3. Basic Commands

### Lifecycle Commands

```bash
# Initialize (download providers, create initial state)
terraform init

# Preview changes
terraform plan

# Create execution plan and save
terraform plan -out=tfplan

# Apply
terraform apply

# Apply saved plan
terraform apply tfplan

# Apply without confirmation
terraform apply -auto-approve

# Destroy
terraform destroy

# Destroy specific resource
terraform destroy -target=aws_instance.web
```

### Formatting & Validation

```bash
# Format
terraform fmt
terraform fmt -recursive
terraform fmt -check  # Check without formatting

# Validate syntax
terraform validate
terraform validate -json
```

### State Inspection

```bash
# Show current state
terraform show

# Show specific resource
terraform show aws_vpc.main

# List all resources in state
terraform state list

# Show resource details
terraform state show aws_instance.web

# Remove from state (doesn't delete)
terraform state rm aws_instance.old

# Move in state
terraform state mv aws_instance.old aws_instance.new

# Import existing
terraform import aws_instance.web i-1234567890abcdef0
```

### Output Commands

```bash
# Show all
terraform output

# Show specific
terraform output vpc_id

# Raw string
terraform output -raw vpc_id

# JSON format
terraform output -json
```

### Workspace Commands

```bash
# List
terraform workspace list

# Show current
terraform workspace show

# Create new
terraform workspace new staging

# Switch
terraform workspace select prod

# Delete
terraform workspace delete dev
```

---

## 4. HCL Syntax Deep Dive

### Basic Structure

```hcl
# Resource
resource "RESOURCE_TYPE" "RESOURCE_NAME" {
  argument1 = "value"
  argument2 = var.variable_name
}

# Data source
data "DATA_TYPE" "DATA_NAME" {
  argument = "value"
}

# Provider
provider "PROVIDER_NAME" {
  region = "us-east-1"
}

# Variable
variable "NAME" {
  type    = string
  default = "value"
}

# Output
output "NAME" {
  value = resource.value
}

# Module
module "MODULE_NAME" {
  source = "./path/to/module"
  input  = "value"
}
```

### Data Types

```hcl
# Primitive types
string
number
bool

# Complex types
list(string)        # ["a", "b", "c"]
map(string)         # {key = "value"}
set(string)         # Unique values only
tuple([string, number])  # Fixed length, mixed types
object({name = string, count = number})  # Key-value
any                  # Avoid when possible
```

### Comments

```hcl
# Single-line comment

#=
  Multi-line comment
  Useful for documenting complex logic
=#
```

### String Literals

```hcl
# Plain string
name = "my-resource"

# Heredoc (multi-line)
user_data = <<-EOT
  #!/bin/bash
  echo "Hello World"
EOT

# Interpolation
"Hello, ${var.name}!"
```

### Expressions & Functions

```hcl
# Conditional (ternary)
value = var.env == "prod" ? "large" : "small"

# Operators
# Arithmetic: +, -, *, /, %, -
# Comparison: ==, !=, <, >, <=, >=
# Logical: &&, ||, !
# Lists: length(), element(), concat()

# Useful functions
tolist(["a", "b"])              # Convert to list
toset(["a", "b", "a"])          # Convert to set
merge(map1, map2)               # Merge maps
keys({"a" = 1})                 # ["a"]
values({"a" = 1})               # [1]
lookup(map, "key", "default")   # Safe map access

# String functions
upper("hello")                  # "HELLO"
lower("HELLO")                  # "hello"
replace("hello", "l", "x")      # "hexxo"
substr("hello", 0, 3)           # "hel"

# File functions
file(path)                      # Read file
fileexists(path)                # Check exists
templatefile(path, vars)        # Template with vars
filebase64(path)                # Base64 encoded

# YAML/JSON
yamldecode(string)              # Parse YAML
yamlencode(object)              # Encode YAML
jsondecode(string)              # Parse JSON
jsonencode(object)              # Encode JSON
```

---

## 5. State Management

### What is State?

The state file (`terraform.tfstate`) maps:
- Resource names in your code → Real-world resource IDs
- Tracks metadata and dependencies
- Enables Terraform to know what exists

### Local vs Remote State

```hcl
# Local (default, BAD for teams)
# State in local file

# Remote (GOOD for teams)
terraform {
  backend "s3" {
    bucket         = "my-terraform-state"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"  # Locking
  }
}
```

### Backend Types

| Backend | Use Case |
|---------|----------|
| `s3` | AWS, most common |
| `azurerm` | Azure, Blob Storage |
| `gcs` | GCP, Cloud Storage |
| `pg` | PostgreSQL, database-backed |
| `local` | Local development only |

### State Commands

```bash
# Pull remote state to local
terraform state pull > backup.tfstate

# Push local state to remote
terraform state push backup.tfstate

# Force unlock (use carefully!)
terraform force-unlock LOCK_ID

# Migrate state to new backend
terraform init -migrate-state
```

### State Isolation Strategies

```hcl
# Strategy 1: Workspaces
terraform workspace new dev

# Strategy 2: File layout
├── prod/
│   └── terraform.tfstate
├── staging/
│   └── terraform.tfstate

# Strategy 3: Terragrunt (recommended for large orgs)
```

---

## 6. Modules

### Module Structure

```
modules/
└── vpc/
    ├── main.tf              # Resources
    ├── variables.tf         # Inputs
    ├── outputs.tf           # Outputs
    ├── README.md            # Documentation
    └── examples/
        └── complete/
            └── main.tf
```

### Using a Module

```hcl
# Local module
module "vpc" {
  source = "./modules/vpc"
  cidr   = "10.0.0.0/16"
}

# Registry module
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.2"
  cidr   = "10.0.0.0/16"
}

# Git module
module "vpc" {
  source = "git::https://github.com/user/vpc.git?ref=v1.0.0"
}
```

### Module Best Practices

1. Keep modules focused - Single responsibility
2. Version everything - Use `version` argument
3. Document inputs/outputs - README with examples
4. Default to empty - Don't over-parameterize
5. Use locals - Reduce repetition

---

## 7. Data Sources

### Querying AWS Resources

```hcl
# Get latest AMI
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# Get caller info
data "aws_caller_identity" "current" {}

# Get current region
data "aws_region" "current" {}

# Get existing VPC
data "aws_vpc" "existing" {
  id = var.vpc_id
}
```

### Using Data Sources

```hcl
resource "aws_instance" "web" {
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = "t3.micro"
}
```

---

## 8. Provisioners

**Warning:** Provisioners are a last resort! Use user data or configuration management instead.

```hcl
# File provisioner
resource "aws_instance" "web" {
  provisioner "file" {
    source      = "app.conf"
    destination = "/etc/app/app.conf"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("~/.ssh/id_rsa")
      host        = self.public_ip
    }
  }
}

# Remote-exec provisioner
resource "aws_instance" "web" {
  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y docker",
    ]
  }
}

# Local-exec provisioner
resource "aws_instance" "web" {
  provisioner "local-exec" {
    command = "echo ${self.private_ip} >> inventory.ini"
  }
}
```

---

## 9. Variables & Outputs

### Variable Definition

```hcl
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"

  validation {
    condition     = can(regex("^t[23]\\.", var.instance_type))
    error_message = "Must be t2/t3 micro/small/medium."
  }
}
```

### Output Definition

```hcl
output "vpc_id" {
  description = "VPC identifier"
  value       = aws_vpc.main.id
}

output "db_connection_string" {
  description = "Database connection"
  value       = "postgresql://${user}:${pass}@${host}"
  sensitive   = true
}
```

---

## 10. Resource Dependencies

### Implicit Dependencies

```hcl
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.main.id  # Creates dependency
  cidr_block = "10.0.1.0/24"
}
```

### Explicit Dependencies

```hcl
resource "aws_instance" "web" {
  depends_on = [aws_lb.main]
}
```

### Lifecycle Rules

```hcl
resource "aws_instance" "web" {
  lifecycle {
    create_before_destroy = true
    prevent_destroy       = true
    ignore_changes = [tags["CreatedDate"]]
  }
}
```

### count vs for_each

```hcl
# count: Index-based
resource "aws_instance" "app" {
  count = 3
  name  = "app-${count.index}"
}

# for_each: Key-based
resource "aws_instance" "app" {
  for_each = toset(["web", "api"])
  name  = "app-${each.value}"
}
```

---

## 11. Workspaces

### Using Workspaces

```hcl
locals {
  environment = terraform.workspace
}

resource "aws_instance" "web" {
  instance_type = terraform.workspace == "prod" ? "t3.large" : "t3.micro"
}
```

### Workspace-Specific Variables

```hcl
# prod.tfvars
instance_type = "t3.large"

# dev.tfvars
instance_type = "t3.micro"
```

---

## 12. CI/CD Integration

### GitHub Actions

```yaml
name: Terraform

on: [push, pull_request]

jobs:
  plan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: hashicorp/setup-terraform@v3
      - run: terraform init
      - run: terraform plan

  apply:
    needs: plan
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: hashicorp/setup-terraform@v3
      - run: terraform init
      - run: terraform apply -auto-approve
```

---

## 13. Testing

### terratest (Go)

```go
func TestVPC(t *testing.T) {
  terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
    TerraformDir: "../vpc",
  })

  defer terraform.Destroy(t, terraformOptions)
  terraform.InitAndApply(t, terraformOptions)

  vpcID := terraform.Output(t, terraformOptions, "vpc_id")
  assert.NotNil(t, vpcID)
}
```

---

## 14. Best Practices

### Code Structure

```
project/
├── main.tf
├── variables.tf
├── outputs.tf
├── versions.tf
└── terraform.tfvars
```

### Naming Conventions

| Resource | Convention | Example |
|----------|------------|---------|
| Resources | `resource_TYPE_name` | `aws_vpc_main` |
| Variables | `snake_case` | `instance_count` |
| Outputs | `snake_case` | `vpc_id` |
| Files | `lowercase.tf` | `main.tf` |

### Version Constraints

```hcl
terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
```

### Remote State (Always)

```hcl
terraform {
  backend "s3" {
    bucket         = "terraform-state"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "locks"
  }
}
```

---

**For quick command reference, see `docs/QUICK_REFERENCE.md`**

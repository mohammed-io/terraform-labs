# Terraform Quick Reference - Cheat Sheet

**One-page reference for daily Terraform usage.**

---

## Essential Commands

```bash
# Lifecycle
terraform init              # Initialize (first command always)
terraform plan              # Preview changes
terraform apply             # Apply changes
terraform destroy           # Destroy everything

# Code Quality
terraform fmt               # Format code
terraform validate          # Check syntax

# State
terraform state list        # List all resources
terraform state show NAME   # Show resource details
terraform output            # Show outputs
terraform refresh           # Sync state with reality

# Workspaces
terraform workspace list    # List workspaces
terraform workspace new X   # Create workspace
terraform workspace select X # Switch workspace
```

---

## HCL Syntax Quick Reference

### Resource
```hcl
resource "TYPE" "NAME" {
  argument1 = "value"
  argument2 = var.variable_name
}
```

### Variable
```hcl
variable "NAME" {
  type    = string | number | bool | list() | map()
  default = "value"
}
```

### Output
```hcl
output "NAME" {
  value = resource.value
}
```

### Data Source
```hcl
data "TYPE" "NAME" {
  filter {
    name   = "name"
    values = ["value"]
  }
}
```

### Module
```hcl
module "NAME" {
  source = "./path/to/module"
  input  = "value"
}
```

---

## Data Types

| Type | Example |
|------|---------|
| `string` | `"hello"` |
| `number` | `42`, `3.14` |
| `bool` | `true`, `false` |
| `list(string)` | `["a", "b", "c"]` |
| `map(string)` | `{key = "value"}` |
| `object({...})` | `{name = string, count = number}` |

---

## Expressions

```hcl
# String interpolation
"Hello ${var.name}!"

# Conditional
value = condition ? true_value : false_value

# Operators
==  !=  <  >  <=  >=  # Comparison
&&  ||  !            # Logical
+  -  *  /  %        # Arithmetic
```

---

## Useful Functions

```hcl
# String
upper("hello")              # "HELLO"
lower("HELLO")              # "hello"
replace("hello", "l", "x")  # "hexxo"

# Collection
length(list)                # Count elements
element(list, index)        # Get element
tolist(set)                 # Convert to list

# File
file("path.txt")            # Read file
templatefile(".tmpl", {v})  # Template with vars

# AWS Specific
aws_vpc.main.id             # Reference resource
var.vpc_id                  # Reference variable
```

---

## Count vs For_Each

```hcl
# count: Index-based (0, 1, 2...)
resource "aws_instance" "app" {
  count = 3
  # use count.index
}

# for_each: Key-based (preferred)
resource "aws_instance" "app" {
  for_each = toset(["web", "api"])
  # use each.value, each.key
}
```

---

## Locals vs Variables

```hcl
# Locals: Internal values
locals {
  name = "${var.env}-app"
}

# Variables: External inputs
variable "env" {
  default = "dev"
}
```

---

## Dependency Patterns

```hcl
# Implicit (from reference)
resource "aws_subnet" "private" {
  vpc_id = aws_vpc.main.id  # Creates dependency
}

# Explicit
resource "aws_instance" "web" {
  depends_on = [aws_subnet.private]
}
```

---

## Output Patterns

```hcl
# Simple
output "vpc_id" {
  value = aws_vpc.main.id
}

# Sensitive (hidden)
output "password" {
  value     = var.password
  sensitive = true
}

# Computed
output "db_url" {
  value = "postgres://${user}:${pass}@${host}"
}
```

---

## State Commands

```bash
# List state
terraform state list

# Show resource
terraform state show aws_vpc.main

# Remove from state (doesn't delete)
terraform state rm aws_instance.old

# Move in state
terraform state mv aws_instance.old aws_instance.new

# Import existing
terraform import aws_vpc.main vpc-12345
```

---

## Workspace Usage

```hcl
# In code
environment = terraform.workspace
```

```bash
# In CLI
terraform workspace list
terraform workspace new prod
terraform workspace select prod
```

---

## Common Gotchas

| Issue | Fix |
|-------|-----|
| "Variable not found" | Define in `variables.tf` or pass `-var` |
| "Resource already exists" | Use `terraform import` or remove state |
| "Circular dependency" | Reorganize resources |
| "for_each not known" | Use known values, not variables |
| "Module not found" | Run `terraform init` first |

---

## .gitignore

```
.terraform/
*.tfstate
*.tfstate.*
*.tfvars
!example.tfvars
*.tfplan
crash.log
.terraform.lock.hcl  # Optional: commit for consistency
```

---

## One-File Structure

For small projects, one file is fine:

```hcl
terraform {
  required_providers {
    aws = { source = "hashicorp/aws" }
  }
}

provider "aws" { region = "us-east-1" }

variable "instance_type" { default = "t3.micro" }

resource "aws_instance" "web" {
  ami           = "ami-12345"
  instance_type = var.instance_type
}

output "public_ip" {
  value = aws_instance.web.public_ip
}
```

---

## Multi-File Structure

For real projects:

```
├── backend.tf       # State backend
├── provider.tf      # Providers
├── versions.tf      # Version pins
├── variables.tf     # Inputs
├── terraform.tfvars # Values (gitignore)
├── data.tf          # Data sources
├── main.tf          # Resources
└── outputs.tf       # Outputs
```

---

**See `docs/FUNDAMENTALS.md` for detailed learning content.**

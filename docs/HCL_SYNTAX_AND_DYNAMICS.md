# HCL Syntax & Dynamic Features - Complete Guide

**Everything about interpolation, variables, environment injection, and dynamic blocks.**

---

## Table of Contents

1. [String Interpolation](#1-string-interpolation)
2. [Variables & How to Pass Them](#2-variables--how-to-pass-them)
3. [Environment Variables](#3-environment-variables)
4. [Dynamic Blocks](#4-dynamic-blocks)
5. [Template Functions](#5-template-functions)
6. [Expressions & Operators](#6-expressions--operators)
7. [Loops & Iterations](#7-loops--iterations)
8. [Conditional Logic](#8-conditional-logic)

---

## 1. String Interpolation

### Basic Interpolation

```hcl
# Single variable
name = "my-${var.environment}-server"

# Multiple variables
bucket_name = "${var.project}-${var.environment}-data"

# Resource attributes
subnet_id = aws_subnet.public.id

# Combined
description = "Server in ${var.environment} for ${var.project} in ${aws_vpc.main.id}"
```

### Escaping Interpolation

```hcl
# Literal ${} - use double $
literal = "This is a literal $${variable}"

# Or use %% in some contexts
```

### Nested Interpolation

```hcl
# Interpolation within expressions
identifier = "${var.prefix}-${var.environment}-${replace(var.name, "/[^a-z0-9]/", "-")}-${random_id.suffix.hex}"
```

### Heredoc with Interpolation

```hcl
user_data = <<-EOT
  #!/bin/bash
  export DB_HOST="${aws_db.main.endpoint}"
  export ENVIRONMENT="${var.environment}"
  echo "Running in ${var.environment}" > /tmp/config.txt
EOT
```

### Heredoc Types

```hcl
# Trimmed heredoc (removes leading/trailing whitespace)
config = <<-EOT
    indented
    but trimmed
EOT

# Regular heredoc (preserves whitespace)
script = <<SCRIPT
  echo "exact spacing"
SCRIPT
```

---

## 2. Variables & How to Pass Them

### Variable Definition (variables.tf)

```hcl
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "ports" {
  description = "List of ports to open"
  type        = list(number)
  default     = [80, 443]
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}

variable "config" {
  description = "Complex configuration"
  type = object({
    enabled = bool
    timeout = number
    retries = optional(number, 3)
  })
}
```

### Ways to Pass Variables

#### Method 1: Command Line Flags

```bash
# Single variable
terraform apply -var="instance_type=t3.small"

# Multiple variables
terraform apply -var="instance_type=t3.small" -var="environment=prod"

# From a file
terraform apply -var-file="prod.tfvars"

# Auto-load *.tfvars files (terraform.tfvars, *.auto.tfvars)
terraform apply
```

#### Method 2: Environment Variables (TF_VAR_)

```bash
# Terraform recognizes TF_VAR_ prefix
export TF_VAR_instance_type=t3.small
export TF_VAR_environment=prod
export TF_VAR_ports="[80,443,8080]"

# JSON format for complex types
export TF_VAR_tags='{"Environment":"prod","Project":"myapp"}'

terraform apply
```

#### Method 3: terraform.tfvars File

```hcl
# terraform.tfvars (gitignored!)
instance_type = "t3.small"
environment   = "prod"
ports         = [80, 443]

tags = {
  Environment = "prod"
  Project     = "myapp"
}

config = {
  enabled = true
  timeout = 30
}
```

#### Method 4: Auto-loaded Files

```
# These load automatically (in order):
terraform.tfvars       # Always loaded
*.auto.tfvars          # Always loaded
terraform.tfvars.json  # Always loaded

# Use .auto.tfvars for environment-specific:
dev.auto.tfvars        # Loaded
prod.auto.tfvars       # Loaded

# These do NOT load automatically:
dev.tfvars             # Requires -var-file=dev.tfvars
```

#### Method 5: Input Prompt (Interactive)

```bash
terraform apply
# Terraform will prompt for undefined required variables
```

---

## 3. Environment Variables

### Application Environment Variables (not Terraform vars)

These are variables passed TO your application, not Terraform itself.

#### Method 1: Lambda Environment Variables

```hcl
resource "aws_lambda_function" "app" {
  function_name = "${var.environment}-app"
  role          = aws_iam_role.lambda.arn
  handler       = "index.handler"
  runtime       = "python3.11"

  environment {
    variables = {
      ENVIRONMENT      = var.environment
      DB_HOST         = aws_db.main.endpoint
      DB_PORT         = "5432"
      LOG_LEVEL       = var.log_level
      MAX_CONNECTIONS = tostring(var.max_conns)  # Must be string
      API_KEY         = aws_secretsmanager_secret.api.id
    }
  }
}
```

#### Method 2: EC2 User Data

```hcl
resource "aws_instance" "web" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type

  user_data = <<-EOF
    #!/bin/bash
    # Export environment variables for the application
    export DB_HOST="${aws_db.main.endpoint}"
    export ENVIRONMENT="${var.environment}"
    export API_KEY="${var.api_key}"

    # Or write to /etc/environment
    echo "DB_HOST=${aws_db.main.endpoint}" >> /etc/environment
    echo "ENVIRONMENT=${var.environment}" >> /etc/environment
  EOF
}
```

#### Method 3: ECS Container Definitions

```hcl
resource "aws_ecs_task_definition" "app" {
  family = "my-app"

  container_definitions = jsonencode([
    {
      name      = "app"
      image     = "${var.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/myapp:${var.image_tag}"
      cpu       = 256
      memory    = 512
      essential = true

      environment = [
        {
          name  = "ENVIRONMENT"
          value = var.environment
        },
        {
          name  = "DB_HOST"
          value = aws_db.main.endpoint
        }
      ]

      # Or use secrets from Secrets Manager/Parameter Store
      secrets = [
        {
          name      = "API_KEY"
          valueFrom = aws_secretsmanager_secret.api.arn
        }
      ]
    }
  ])
}
```

#### Method 4: Kubernetes ConfigMap (via Terraform)

```hcl
resource "kubernetes_config_map" "app" {
  metadata {
    name = "app-config"
  }

  data = {
    "environment"   = var.environment
    "db_host"       = aws_db.main.endpoint
    "log_level"     = var.log_level
    "feature_flags" = jsonencode(var.feature_flags)
  }
}
```

#### Method 5: SSM Parameter Store

```hcl
# Store parameters
resource "aws_ssm_parameter" "db_host" {
  name  = "/${var.environment}/app/db/host"
  type  = "String"
  value = aws_db.main.endpoint
}

resource "aws_ssm_parameter" "db_port" {
  name  = "/${var.environment}/app/db/port"
  type  = "String"
  value = "5432"
}

# Application reads these at runtime
```

---

## 4. Dynamic Blocks

Dynamic blocks let you dynamically construct nested blocks based on data.

### Basic Dynamic Block

```hcl
# Without dynamic - repetitive
ingress {
  description = "Allow HTTP"
  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}

ingress {
  description = "Allow HTTPS"
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}

ingress {
  description = "Allow custom app port"
  from_port   = 8080
  to_port     = 8080
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}
```

### With Dynamic Block

```hcl
variable "ingress_ports" {
  description = "Ports to allow"
  type = list(object({
    port        = number
    protocol    = string
    description = string
    cidr_blocks = list(string)
  }))
  default = [
    { port = 80, protocol = "tcp", description = "HTTP", cidr_blocks = ["0.0.0.0/0"] },
    { port = 443, protocol = "tcp", description = "HTTPS", cidr_blocks = ["0.0.0.0/0"] },
    { port = 8080, protocol = "tcp", description = "App", cidr_blocks = ["0.0.0.0/0"] }
  ]
}

resource "aws_security_group" "web" {
  name        = "web-sg"
  description = "Web security group"
  vpc_id      = aws_vpc.main.id

  dynamic "ingress" {
    for_each = var.ingress_ports
    content {
      description = ingress.value.description
      from_port   = ingress.value.port
      to_port     = ingress.value.port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }
}
```

### Dynamic Block with Conditional

```hcl
resource "aws_security_group" "web" {
  name = "web-sg"
  vpc_id = aws_vpc.main.id

  # Only add egress rule if enabled
  dynamic "egress" {
    for_each = var.enable_egress ? [1] : []
    content {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
}
```

### Dynamic Block with Nested Content

```hcl
resource "aws_appautoscaling_policy" "this" {
  name               = "${var.name}-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.this.arn
  scalable_dimension = aws_appautoscaling_target.this.scalable_dimension
  service_namespace  = aws_appautoscaling_target.this.service_namespace

  dynamic "target_tracking_scaling_policy_configuration" {
    for_each = var.target_tracking_config != null ? [1] : []

    content {
      target_value       = var.target_tracking_config.target_value
      scale_in_cooldown  = var.target_tracking_config.scale_in_cooldown
      scale_out_cooldown = var.target_tracking_config.scale_out_cooldown

      # Dynamic nested dynamic!
      dynamic "customized_metric_specification" {
        for_each = var.target_tracking_config.custom_metric != null ? [1] : []
        content {
          metric_name = var.target_tracking_config.custom_metric.name
          namespace   = var.target_tracking_config.custom_metric.namespace
          statistic   = var.target_tracking_config.custom_metric.statistic
        }
      }

      # Or predefined metric
      dynamic "predefined_metric_specification" {
        for_each = var.target_tracking_config.custom_metric == null ? [1] : []
        content {
          predefined_metric_type = var.target_tracking_config.metric_type
        }
      }
    }
  }
}
```

### Dynamic Block for Tags

```hcl
resource "aws_instance" "web" {
  ami           = "ami-12345"
  instance_type = "t3.micro"

  # Merge base tags with dynamic tags
  tags = merge(
    local.common_tags,
    {
      Name = "${var.environment}-web"
    }
  )
}

# Or use dynamic for tag generation
dynamic "tags" {
  for_each = var.additional_tags
  content {
    key   = tags.key
    value = tags.value
  }
}
```

---

## 5. Template Functions

### templatefile() Function

The `templatefile()` function reads a file and substitutes variables.

#### Template File (config.tpl)

```bash
# config.tpl
#!/bin/bash
# Generated by Terraform

export ENVIRONMENT="${environment}"
export DB_HOST="${db_host}"
export DB_PORT="${db_port}"
export ENABLE_CACHE=${enable_cache}
export MAX_WORKERS=${max_workers}

# Optional feature
%{if enable_feature_x}
export FEATURE_X_ENABLED=true
%{endif}

# Multiple servers
%{for server in servers}
echo "Server: ${server}"
%{endfor}
```

#### Terraform Usage

```hcl
resource "aws_instance" "web" {
  ami           = "ami-12345"
  instance_type = "t3.micro"

  user_data = templatefile("${path.module}/config.tpl", {
    environment    = var.environment
    db_host        = aws_db.main.endpoint
    db_port        = "5432"
    enable_cache   = var.enable_cache
    max_workers    = var.max_workers
    enable_feature_x = var.feature_x_enabled
    servers        = var.server_list
  })
}
```

### Template with Conditional Blocks

```hcl
# startup.sh.tpl
#!/bin/bash

# Main configuration
export APP_NAME="${app_name}"

%{if db_enabled}
# Database configuration
export DB_HOST="${db_host}"
export DB_PORT="${db_port}"
%{endif}

%{if cache_enabled}
# Cache configuration
export CACHE_HOST="${cache_host}"
export CACHE_PORT="${cache_port}"
%{endif}

# Application specific
%{if environment == "production"}
export LOG_LEVEL="WARN"
export MAX_WORKERS=10
%{else}
export LOG_LEVEL="DEBUG"
export MAX_WORKERS=2
%{endif}
```

```hcl
user_data = templatefile("${path.module}/startup.sh.tpl", {
  app_name       = var.app_name
  db_enabled     = var.database != null
  db_host        = try(var.database.host, "")
  db_port        = try(var.database.port, "")
  cache_enabled  = var.cache_enabled
  cache_host     = var.cache_host
  cache_port     = var.cache_port
  environment    = var.environment
})
```

### templatefile with Iteration

```hcl
# hosts.tpl
%{for ip in web_ips}
${ip} web
%{endfor}

%{for ip, name in api_servers}
${ip} ${name}-api
%{endfor}
```

```hcl
templatefile("${path.module}/hosts.tpl", {
  web_ips     = aws_instance.web[*].public_ip
  api_servers = zipmap(
    aws_instance.api[*].public_ip,
    aws_instance.api[*].tags["Name"]
  )
})
```

---

## 6. Expressions & Operators

### Conditional Expression (Ternary)

```hcl
# Basic
size = var.environment == "prod" ? "large" : "small"

# Nested
size = var.environment == "prod" ? (
  var.region == "us-east-1" ? "xlarge" : "large"
) : "small"

# With null coalescing
value = var.override != null ? var.override : var.default
```

### Logical Operators

```hcl
# AND
condition = var.enabled && var.environment != "test"

# OR
condition = var.force || var.auto

# NOT
condition = !var.disabled
```

### String Functions

```hcl
# Case conversion
upper("hello")              # "HELLO"
lower("HELLO")              # "hello"
title("hello world")        # "Hello World"

# Substring
substr("hello", 0, 3)       # "hel"
substr("hello", -3, -1)     # "llo"

# Replace
replace("hello", "l", "x")  # "hexxo"
replace("hello", "/l/", "")  # "heo" (regex)

# Split/Join
split(",", "a,b,c")          # ["a", "b", "c"]
join("-", ["a", "b", "c"])   # "a-b-c"

# Format
format("Hello %s!", "World") # "Hello World!"
formatdate("YYYY-MM-DD", timestamp())
```

### Collection Functions

```hcl
# Length
length(["a", "b", "c"])      # 3
length({a = 1, b = 2})       # 2

# Element access
element(["a", "b", "c"], 1)   # "b"
lookup({a = 1, b = 2}, "a")  # 1

# Merge maps
merge({a = 1}, {b = 2})       # {a = 1, b = 2}

# Keys and values
keys({a = 1, b = 2})         # ["a", "b"]
values({a = 1, b = 2})       # [1, 2]

# Flatten
flatten([["a", "b"], ["c"]])  # ["a", "b", "c"]

# Set operations
tolist(toset(["a", "b", "a"])) # ["a", "b"] (deduped)

# Contains
contains(["a", "b", "c"], "b") # true
```

### Numeric Functions

```hcl
# Min/Max
min(1, 2, 3)                # 1
max(1, 2, 3)                # 3

# Floor/Ceiling
floor(2.7)                   # 2
ceil(2.3)                    # 3

# Absolute value
abs(-5)                      # 5

# Power
pow(2, 3)                    # 8
```

### try() Function (Error Handling)

```hcl
# Try multiple options, use first that succeeds
value = try(
  var.override_value,
  local.default_value,
  "final-fallback"
)

# Nested try
value = try(
  var.config.value,
  var.config.default_value,
  local.fallback,
  null
)
```

### can() Function (Check Validity)

```hcl
# Check if operation would succeed
valid = can(regex("^t[23]\\.", var.instance_type))

# Conditional based on validity
instance_type = can(regex("^t[23]\\.", var.instance_type)) ? var.instance_type : "t3.micro"

# Check if key exists
has_key = can(var.config.important_key)
```

---

## 7. Loops & Iterations

### count with Index

```hcl
resource "aws_instance" "web" {
  count = 3

  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"

  tags = {
    Name  = "web-${count.index}"
    Index = tostring(count.index)
  }
}

# Reference specific instances
aws_instance.web[0].id
aws_instance.web[1].id

# All instances
aws_instance.web[*].id
```

### count with Conditional

```hcl
# Only create in production
resource "aws_instance" "web" {
  count = var.environment == "prod" ? 3 : 0

  # ... resource config
}

# Conditional based on list
resource "aws_iam_user" "admin" {
  count = length(var.admin_users)

  name = var.admin_users[count.index]
}
```

### for_each with Map

```hcl
resource "aws_instance" "app" {
  for_each = {
    web  = "t3.micro"
    api  = "t3.small"
    worker = "t3.medium"
  }

  ami           = data.aws_ami.amazon_linux.id
  instance_type = each.value

  tags = {
    Name = "app-${each.key}"
  }
}

# Reference specific instances
aws_instance.app["web"].id
aws_instance.app["api"].id

# All instances (returns map)
aws_instance.app
```

### for_each with List

```hcl
resource "aws_security_group_rule" "ingress" {
  for_each = var.ingress_ports

  type              = "ingress"
  from_port         = each.value
  to_port           = each.value
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.main.id
}

# Or with toset (unique values only)
resource "aws_subnet" "private" {
  for_each = toset(var.availability_zones)

  vpc_id     = aws_vpc.main.id
  cidr_block = cidrsubnet(var.vpc_cidr, 8, each.key)
}
```

### for Loop in Expressions

```hcl
# Transform list
upper_names = [for s in var.names : upper(s)]

# Transform map
upper_tags = { for k, v in var.tags : k => upper(v) }

# With index
enumerated = [for i, v in var.list : "${i}:${v}"]

# With filter (if)
odd_numbers = [for n in range(1, 10) : n if n % 2 != 0]

# Transform map (filter and transform)
admins = {
  for user in data.aws_iam_users.all.users : user.user_name => user
  if length(user.tags) > 0
}
```

### flatten Function

```hcl
# Nested lists to flat list
nested = [
  ["a", "b"],
  ["c", "d", "e"]
]

flat = flatten(nested)  # ["a", "b", "c", "d", "e"]

# Practical example: flatten subnet IDs across VPCs
all_subnet_ids = flatten([
  for vpc in var.vpcs : vpc.subnet_ids
])
```

---

## 8. Conditional Logic

### if / else in Strings

```hcl
# Inline conditional (ternary)
instance_type = var.environment == "prod" ? "t3.large" : "t3.micro"

# Nested conditional
size = var.environment == "prod" ? (
  var.region == "us-east-1" ? "xlarge" : "large"
) : (
  var.environment == "staging" ? "medium" : "small"
)
```

### Conditional in Templates

```hcl
user_data = <<-EOT
  #!/bin/bash
  export ENVIRONMENT="${var.environment}"

  %{if var.enable_monitoring}
  # Install monitoring agent
  yum install -y cloudwatch-agent
  %{endif}

  %{if var.environment == "production"}
  export LOG_LEVEL=WARN
  export MAX_WORKERS=10
  %{else}
  export LOG_LEVEL=DEBUG
  export MAX_WORKERS=2
  %{endif}
EOT
```

### Conditional Resource Creation

```hcl
# Method 1: count
resource "aws_eip" "nat" {
  count = var.enable_nat_gateway ? 1 : 0

  # ...
}

# Method 2: for_each with empty collection
resource "aws_instance" "worker" {
  for_each = var.enable_workers ? var.worker_names : toset([])

  # ...
}

# Method 3: Dynamic block
resource "aws_autoscaling_group" "app" {
  # ...

  dynamic "tag" {
    for_each = var.additional_tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}
```

### Conditional Values

```hcl
# Using coalesce
value = var.override != null ? var.override : var.default

# Using try
value = try(var.config.value, local.fallback, "default")

# Using can
instance_type = can(var.instance_type) ? var.instance_type : "t3.micro"
```

---

## Quick Reference Card

| Feature | Syntax | Example |
|---------|--------|--------|
| **Interpolation** | `${...}` | `"Hello ${var.name}"` |
| **Environment var** | `TF_VAR_` | `export TF_VAR_env=prod` |
| **Conditional** | `? : ` | `x ? y : z` |
| **Dynamic block** | `dynamic` | See section 4 |
| **Template file** | `templatefile()` | See section 5 |
| **Loop in value** | `for` | `[for x in list : x]` |
| **Loop resources** | `count` / `for_each` | See section 7 |
| **Error handling** | `try()` / `can()` | See section 6 |

---

## Practice Exercises

1. **Variable Passing**: Try passing a variable via:
   - Command line `-var`
   - Environment variable `TF_VAR_`
   - `terraform.tfvars` file

2. **Template Function**: Create a `config.tpl` file and use `templatefile()` with variables

3. **Dynamic Block**: Convert repetitive `ingress` blocks to a `dynamic "ingress"` block

4. **Conditional**: Create a resource that only exists in `prod` environment

5. **For Loop**: Use `[for x in list : upper(x)]` to transform a list

---

**Check `answers/scenario-06-stack-pattern/` for real-world examples of all these patterns.**

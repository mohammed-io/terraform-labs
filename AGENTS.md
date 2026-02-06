# Terraform Lab - AGENTS.md

**This file defines the structure and conventions for adding new scenarios to the terraform-lab.**

---

## Directory Structure

```
terraform-lab/
├── learning-materials/
│   └── fundamentals/
│       ├── scenario-01-docker/
│       ├── scenario-02-localstack-basics/
│       ├── scenario-03-localstack-networking/
│       ├── scenario-04-localstack-security/
│       ├── scenario-05-localstack-fullstack/
│       └── scenario-06-stack-pattern/
└── each-scenario-directory/
    ├── problem.md          # Required: Scenario overview
    ├── step-01.md          # Guided hints
    ├── step-02.md
    ├── solution.md         # Required: Complete solution
    └── lab/                # Required: Hands-on workspace
        ├── README.md       # Setup instructions
        ├── main.tf         # Starter code with TODOs
        └── verify.sh       # Automated verification
```

---

## File Format Specifications

### problem.md (Required)

```yaml
---
name: "Scenario Name"
category: "fundamentals"
difficulty: "beginner|intermediate|advanced"
time: "XX minutes"
services: ["s3", "dynamodb"]   # AWS services used
concepts: ["provider", "resource", "state"]
---

# Scenario Title

**Brief description**

## Scenario

Real-world context for this infrastructure.

## Architecture

ASCII diagram showing components.

## Requirements

Numbered list of resources to create.

## Constraints

Limitations or specific approaches required.

## Variables

Table of configurable variables.

## Prerequisites

Skills and tools needed.

## What You'll Learn

Table of concepts and why they matter.

## Getting Started

Environment setup commands.

## Verification

How to verify the solution.
```

### step-*.md (Optional)

```markdown
# Step N: Title

**Concept explanation**

## [Resource Type]

Detailed explanation with HCL examples.

## Your Task

Specific implementation tasks.

## Quick Check

5 questions with parenthetical answers.
```

### solution.md (Required)

```markdown
# Solution: Scenario Name

## Complete main.tf

Full working Terraform configuration.

## Explanation

What each resource does and why.

## Testing

Commands to verify and test.

## Key Concepts Demonstrated

Summary table.
```

### lab/ (Required)

```
lab/
├── README.md       # Setup, LocalStack commands
├── main.tf         # Starter with TODO/HINT comments
└── verify.sh       # Automated verification
```

---

## Frontmatter Fields

| Field | Required | Values |
|-------|----------|--------|
| `name` | Yes | string |
| `category` | Yes | Currently only "fundamentals" |
| `difficulty` | Yes | beginner, intermediate, advanced |
| `time` | Yes | "XX minutes" |
| `services` | No | [AWS service names] |
| `concepts` | Yes | [Terraform concept names] |

---

## Quick Check Format

Each step must have exactly 5 questions:

```markdown
## Quick Check

Test your understanding:

1. What's a Terraform provider? (A plugin that connects to a specific service API like Docker, AWS, etc.)

2. What does terraform init do? (Downloads providers, initializes backend, sets up working directory)

3. What's the resource type format? ("provider_resource" like "docker_image" or "aws_instance")
...
```

---

## Lab File Guidelines

### main.tf

```hcl
# TODO: Create docker_image resource
# HINT: Use name = "nginx:alpine" and keep_locally = false

# TODO: Create docker_container resource
# HINT: Use for_each = range(var.app_count)
```

### verify.sh

```bash
#!/bin/bash
set -e

echo "=== Verification ==="

# Check if tool is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker not running"
    exit 1
fi

# Check if terraform is initialized
if [ ! -d ".terraform" ]; then
    echo "❌ Run terraform init first"
    exit 1
fi

# Check if resources exist
# ... specific checks ...

echo "=== All checks passed ==="
```

---

## Naming Conventions

- **Scenarios**: `scenario-XX-name` (2-digit number, kebab-case)
- **Files**: lowercase, kebab-case for multi-word

---

## Adding New Scenarios

1. **Create scenario directory** in `learning-materials/fundamentals/`
2. **Write problem.md** with complete frontmatter
3. **Create step-*.md files** (1-2 steps typical)
4. **Write solution.md** with complete HCL
5. **Create lab/** with:
   - README.md (setup including LocalStack)
   - main.tf (TODO/HINT format)
   - verify.sh (executable)
6. **Update main.py** to include new scenario

---

## LocalStack Services

For scenarios using LocalStack, specify required services:

```bash
# Scenario 2: S3 + DynamoDB
docker run --rm -it -p 4566:4566 \
  -e SERVICES=s3,dynamodb \
  localstack/localstack:latest

# Scenario 3: Networking
docker run --rm -it -p 4566:4566 \
  -e SERVICES=ec2,iam \
  -e DEBUG=1 \
  localstack/localstack:latest
```

---

## Testing New Scenarios

1. Start LocalStack with required services
2. Run `terraform init` in lab directory
3. Follow your own step-by-step guidance
4. Verify with `terraform plan` and `terraform apply`
5. Run verify.sh script
6. Test `terraform destroy`

---

## What NOT To Do

- ❌ Skip Quick Check sections
- ❌ Create scenarios without practical infrastructure patterns
- ❌ Use hardcoded values instead of variables
- ❌ Skip HINT comments in lab files
- ❌ Create verify.sh that doesn't actually verify

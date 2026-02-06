# Terraform Lab Restructure Plan

## Goal
Transform terraform-lab to match the problem-solving-coach learning format with step-based guidance, Quick Check questions, and a Streamlit web interface.

---

## Current Structure (terraform-lab/)

```
terraform-lab/
├── README.md
├── docs/
│   ├── QUICK_REFERENCE.md
│   ├── HCL_SYNTAX_AND_DYNAMICS.md
│   ├── FUNDAMENTALS.md
│   ├── FILE_CONVENTIONS.md
│   ├── PROJECT_ORGANIZATION.md
│   └── LOCALSTACK_SERVICES.md
├── modules/
│   ├── custom/vpc/
│   └── registry/
├── scenarios/
│   ├── scenario-01-docker/README.md
│   ├── scenario-02-localstack-basics/README.md
│   ├── scenario-03-localstack-networking/README.md
│   ├── scenario-04-localstack-security/README.md
│   ├── scenario-05-localstack-fullstack/README.md
│   └── scenario-06-stack-pattern/
│       ├── 01-networking/
│       ├── 02-database/
│       └── 03-application/
└── answers/
    └── scenario-XX/main.tf
```

---

## Target Structure

```
terraform-lab/
├── main.py                          # Streamlit web app (drop-in from problem-solving-coach)
├── README.md                        # Updated project overview
├── .coach-data/                     # Progress tracking (auto-created)
│   ├── completed.txt
│   ├── current_problem.txt
│   └── history.txt
│
├── learning-materials/              # NEW: Main learning content
│   ├── fundamentals/                # Category
│   │   ├── scenario-01-docker/
│   │   │   ├── problem.md           # Problem statement with frontmatter
│   │   │   ├── solution.md          # Full solution explanation
│   │   │   ├── step-01.md           # Step-by-step guidance
│   │   │   ├── step-02.md           # Additional steps
│   │   │   └── lab/                 # Lab environment
│   │   │       ├── README.md
│   │   │       ├── docker-compose.yml
│   │   │       ├── main.tf          # Starter/solution code
│   │   │       └── verify.sh        # Verification script
│   │   │
│   │   ├── scenario-02-localstack-basics/
│   │   └── scenario-03-localstack-networking/
│   │
│   ├── advanced/                    # Category
│   │   ├── scenario-04-localstack-security/
│   │   ├── scenario-05-localstack-fullstack/
│   │   └── scenario-06-stack-pattern/
│   │       ├── problem.md
│   │       ├── solution.md
│   │       ├── step-01.md
│   │       ├── step-02.md
│   │       └── lab/
│   │
│   └── modules/                     # Module learning
│       ├── custom-vpc/
│       └── registry-modules/
│
├── docs/                            # Reference materials (keep existing)
│   ├── QUICK_REFERENCE.md
│   ├── HCL_SYNTAX_AND_DYNAMICS.md
│   └── ...
│
└── modules/                         # Keep existing module examples
    ├── custom/
    └── registry/
```

---

## Content Transformation Guide

### 1. problem.md Format

```markdown
---
name: "Docker Provider Basics"
category: "fundamentals"
difficulty: "beginner"
time: "15 minutes"
---

# Docker Provider with Terraform

Learn to use the Docker provider to manage containers.

## The Problem

You need to deploy an NGINX container using Terraform's Docker provider...

## Learning Objectives

- Understand provider configuration
- Learn resource blocks
- Manage container lifecycle

## Prerequisites

- Docker installed locally
- Terraform 1.5+
```

### 2. step-01.md Format

```markdown
# Step 1: Provider Configuration

---

## Understanding Providers

Providers are plugins that Terraform uses to manage resources...

```hcl
terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0.0"
    }
  }
}

provider "docker" {}
```

## Your Task

1. Create a new directory for your Terraform project
2. Create `main.tf` with the provider block above
3. Run `terraform init`

## Verify

```bash
terraform init
# Should see: "Terraform has been successfully initialized!"
```

---

## Quick Check

Before moving on, make sure you understand:

1. What's a Terraform provider? (A plugin that connects to a specific service API)
2. What does `terraform init` do? (Downloads provider plugins and initializes backend)
3. What's the provider block syntax? (provider "NAME" {})
4. Why specify version constraints? (Ensures reproducible builds)
5. Where are providers downloaded from? (Terraform Registry by default)

---

**Continue to `step-02.md`**
```

### 3. solution.md Format

```markdown
# Solution: Docker Provider Basics

---

## Complete main.tf

```hcl
terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0.0"
    }
  }
}

provider "docker" {}

resource "docker_image" "nginx" {
  name         = "nginx:latest"
  keep_locally = false
}

resource "docker_container" "nginx" {
  image = docker_image.nginx.image_id
  name  = "tutorial"
  ports {
    internal = 80
    external = 8000
  }
}
```

## Explanation

1. **Provider block**: Connects to Docker daemon
2. **docker_image**: Pulls the nginx image
3. **docker_container**: Creates container with port mapping

## Testing

```bash
terraform apply
curl http://localhost:8000
```
```

---

## main.py Adaptations

Changes needed for terraform-lab:

| Change | Original | Terraform Lab |
|--------|----------|---------------|
| Page title | "Problem Solving Coach" | "Terraform Lab" |
| Icon | 🎯 | 🏗️ |
| Directory | `learning-materials/` | `learning-materials/` |
| Problem files | `problem.md` | `problem.md` |
| Step files | `step-*.md` | `step-*.md` |
| Lab download | `.zip` | `.zip` (Terraform files) |
| Categories | basic/intermediate/advanced/... | fundamentals/advanced/modules/... |

---

## Migration Tasks

### Phase 1: Structure Setup
- [ ] Create `learning-materials/` directory
- [ ] Create category subdirectories (fundamentals/, advanced/)
- [ ] Copy existing scenarios to new structure
- [ ] Create `.coach-data/` directory placeholder

### Phase 2: Content Conversion
For each scenario (6 scenarios):
- [ ] Create `problem.md` with frontmatter metadata
- [ ] Break README content into `step-01.md`, `step-02.md`, etc.
- [ ] Add "Quick Check" sections with 5 questions each
- [ ] Create `solution.md` from answers/

### Phase 3: Lab Setup
For each scenario:
- [ ] Create `lab/` subdirectory
- [ ] Add `docker-compose.yml` for environment (Docker, LocalStack)
- [ ] Add starter `main.tf` or blank template
- [ ] Add `verify.sh` validation script
- [ ] Add `README.md` with lab setup instructions

### Phase 4: Web Interface
- [ ] Copy and adapt `main.py` from problem-solving-coach
- [ ] Update page title, icon, branding
- [ ] Adjust category names for Terraform context
- [ ] Test Streamlit app with new content

### Phase 5: Documentation
- [ ] Update main README.md
- [ ] Add "Getting Started" guide
- [ ] Document new folder structure
- [ ] Update contribution guidelines

---

## Frontmatter Metadata Example

```yaml
---
name: "LocalStack S3 Bucket"
category: "fundamentals"
difficulty: "beginner"
time: "20 minutes"
services: ["s3"]
concepts: ["provider", "resource", "state"]
---
```

---

## Lab Directory Template

```
lab/
├── README.md           # How to use this lab
├── docker-compose.yml  # Service dependencies (LocalStack, etc.)
├── main.tf             # Starter code (partial or empty)
├── terraform.tfvars    # Variable values (if needed)
├── verify.sh           # Verification script
└── outputs/            # Expected outputs (for reference)
```

---

## Priority Order

1. **High Priority** (Do first):
   - scenario-01-docker (simplest, good for testing format)
   - scenario-02-localstack-basics (foundational)

2. **Medium Priority**:
   - scenario-03-localstack-networking
   - scenario-04-localstack-security

3. **Lower Priority**:
   - scenario-05-localstack-fullstack (complex, may need more steps)
   - scenario-06-stack-pattern (multi-file, advanced)

---

## Testing Checklist

After conversion, verify:
- [ ] Streamlit app loads without errors
- [ ] All scenarios appear in sidebar
- [ ] Step buttons open dialogs correctly
- [ ] Lab download creates working zip
- [ ] Progress tracking works (mark as completed)
- [ ] History navigation works
- [ ] Mermaid diagrams render (if any)

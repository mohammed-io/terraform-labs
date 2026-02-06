# Terraform Project Organization - Industry Practices

## The Question: How Do Big Companies Organize Terraform?

Every company structures Terraform differently based on:
- Team size (1 person vs 100+ engineers)
- Number of environments (dev/staging/prod vs multi-region)
- Complexity (single app vs microservices)
- Compliance requirements

---

## Common Organizational Patterns

### Pattern 1: The "Stack" Pattern (Most Common)

A **stack** is a self-contained unit of infrastructure. One stack = one set of resources.

```
company-infrastructure/
├── stacks/
│   ├── frontend-app/          # One stack
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── backend-api/           # Another stack
│   │   ├── main.tf
│   │   └── variables.tf
│   ├── data-pipeline/         # Another stack
│   │   └── ...
│   └── shared-resources/      # VPC, IAM, etc.
│       └── ...
├── modules/                   # Shared modules
│   ├── vpc/
│   ├── ecs-service/
│   └── rds/
└── live/                      # Alternative to stacks/
    ├── prod/
    ├── staging/
    └── dev/
```

**Who uses this:** Airbnb, Stripe, most mid-size companies

**Pros:**
- Clear ownership (one team per stack)
- Independent deployment (deploy backend-api without touching frontend)
- Blasts radius limited to one stack
- Parallel CI/CD possible

**Cons:**
- More state files to manage
- Can't share variables easily between stacks
- Need to handle dependencies between stacks

---

### Pattern 2: The "Environment-Based" Pattern (Simple)

```
terraform-infrastructure/
├── environments/
│   ├── dev/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── terraform.tfvars
│   │   └── backend.tf
│   ├── staging/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── terraform.tfvars
│   │   └── backend.tf
│   └── prod/
│       ├── main.tf
│       ├── variables.tf
│       ├── terraform.tfvars
│       └── backend.tf
├── modules/
│   ├── vpc/
│   ├── ecs/
│   └── rds/
└── provider.tf
```

**Who uses this:** Small teams, startups, single-product companies

**Pros:**
- Simple to understand
- Easy to see what's different between environments
- One state per environment

**Cons:**
- Code duplication (main.tf copied 3 times)
- Can't deploy dev without potentially affecting prod logic
- Blasts radius = entire environment

---

### Pattern 3: The "Component-Based" Pattern (Netflix-style)

```
infrastructure/
├── components/
│   ├── networking/            # Global network
│   │   ├── global/
│   │   ├── regions/
│   │   └── availability_zones/
│   ├── compute/               # All compute resources
│   │   ├── ecs/
│   │   ├── eks/
│   │   └── ec2/
│   ├── databases/             # All databases
│   │   ├── rds/
│   │   ├── dynamodb/
│   │   └── elasticache/
│   ├── storage/               # S3, EFS
│   └── security/              # IAM, KMS, Secrets
├── environments/              # Environment-specific values
│   ├── dev.yaml
│   ├── staging.yaml
│   └── prod.yaml
└── modules/
    └── ...
```

**Who uses this:** Netflix, large enterprises with multiple products

**Pros:**
- Experts own each component (DBA owns databases/)
- Consistent patterns across environments
- Reusable components

**Cons:**
- Complex dependency management
- Requires strong coordination

---

### Pattern 4: The "Terragrunt" Pattern (DRY Principle)

Terragrunt is a wrapper that keeps your code DRY. You write Terraform ONCE, Terragrunt applies it to multiple environments.

```
infrastructure/
├── modules/                   # The actual Terraform code
│   ├── vpc/
│   ├── ecs-service/
│   └── rds/
├── live/                      # Environment configuration
│   ├── prod/
│   │   ├── us-east-1/        # Region
│   │   │   ├── vpc/
│   │   │   │   └── terragrunt.hcl
│   │   │   ├── frontend-app/
│   │   │   │   └── terragrunt.hcl
│   │   │   └── backend-api/
│   │   │       └── terragrunt.hcl
│   │   └── eu-west-1/
│   └── dev/
│       └── us-east-1/
└── terraform/                 # Shared Terraform configs
    └── _base/                 # Common provider configs
```

**Who uses this:** Companies with many environments/regions (Gruntwork, customers)

**Pros:**
- ZERO code duplication
- Easy to add new environments/regions
- Remote state configured once, used everywhere
- Dependencies handled automatically

**Cons:**
- Another tool to learn
- Debugging can be harder
- Lock-in to Terragrunt patterns

---

## Real-World Examples

### Spotify's Structure (Simplified)

```
spotify-infrastructure/
├── stacks/
│   ├── data-pipeline/        # Owns all data infrastructure
│   ├── user-service/         # Owns user API infrastructure
│   ├── playlist-service/     # Owns playlist infrastructure
│   └── shared/
│       ├── monitoring/       # Prometheus, Grafana
│       ├── logging/          # ELK stack
│       └── networking/       # VPCs, subnets
├── lib/                      # Internal modules
│   ├── spotify-ecs-service/
│   ├── spotify-rds/
│   └── spotify-s3/
└── scripts/                  # Utility scripts
    └── validate-plan.sh
```

### Shopify's Structure (Simplified)

```
shopify-infrastructure/
├──terraform/
│   ├── modules/              # Reusable modules
│   │   ├── shopify-vpc/
│   │   ├── shopify-kubernetes-cluster/
│   │   └── shopify-mysql/
│   ├── projects/             # One directory per "project"
│   │   ├── storefront/       # Main e-commerce site
│   │   │   ├── prod/
│   │   │   ├── staging/
│   │   │   └── dev/
│   │   ├── admin/            # Admin interface
│   │   │   ├── prod/
│   │   │   └── staging/
│   │   └── payments/         # Payment processing
│   │       ├── prod/
│   │       └── dr/           # Disaster recovery
│   └── environments/         # Global configs
│       ├── prod.tfvars
│       ├── staging.tfvars
│       └── dev.tfvars
```

### GitLab's Structure (Reference Architecture)

```
gitlab-infrastructure/
├── environments/
│   ├── gdk/                  # Local development
│   ├── dev/
│   ├── staging/
│   ├── preprod/
│   └── prod/
│       ├── us-east-1/
│       │   ├── gitlab/       # Main app
│       │   ├── pages/        # Pages hosting
│       │   ├── registry/     # Container registry
│       │   └── runners/      # CI runners
│       └── eu-west-1/        # DR region
├── modules/
│   └── gitlab/               # Internal modules
│       ├── gitlab-instance/
│       ├── gitlab-rds/
│       └── gitlab-redis/
└── tools/                    # Scripts and utilities
```

---

## Key Concepts

### What is a "Stack"?

A **stack** is a logical grouping of infrastructure that:
- Has a single `terraform.tfstate` file
- Is deployed together
- Has clear ownership
- Can be destroyed without affecting other stacks

```
One Application = Multiple Stacks

my-app/
├── 01-networking/          # Stack 1: VPC, subnets (deploy once, rarely changes)
├── 02-datastore/           # Stack 2: RDS, Redis (deploy after networking)
├── 03-ecs-cluster/         # Stack 3: ECS, ASG (deploy after datastore)
├── 04-services/            # Stack 4: ECS services (deploy frequently)
└── 05-monitoring/          # Stack 5: CloudWatch, alarms (independent)
```

### Stack Dependencies

```hcl
# 04-services/terraform.tfvars
# Uses data sources to read from other stacks

data "terraform_remote_state" "networking" {
  backend = "s3"

  config = {
    bucket = "my-terraform-state"
    key    = "networking/terraform.tfstate"
    region = "us-east-1"
  }
}

data "terraform_remote_state" "datastore" {
  backend = "s3"

  config = {
    bucket = "my-terraform-state"
    key    = "datastore/terraform.tfstate"
    region = "us-east-1"
  }
}

resource "aws_ecs_service" "app" {
  # Use outputs from other stacks
  subnet_ids         = data.terraform_remote_state.networking.outputs.private_subnet_ids
  security_group_ids = [data.terraform_remote_state.networking.outputs.app_security_group_id]

  # The RDS endpoint from the datastore stack
  environment {
    name  = "DB_ENDPOINT"
    value = data.terraform_remote_state.datastore.outputs.rds_endpoint
  }
}
```

---

## State Management Strategies

### Strategy 1: State per Environment (Common)

```
terraform-state/
├── dev/
│   ├── networking/terraform.tfstate
│   ├── database/terraform.tfstate
│   └── app/terraform.tfstate
├── staging/
│   ├── networking/terraform.tfstate
│   ├── database/terraform.tfstate
│   └── app/terraform.tfstate
└── prod/
    ├── networking/terraform.tfstate
    ├── database/terraform.tfstate
    └── app/terraform.tfstate
```

### Strategy 2: State per Component (Large orgs)

```
terraform-state/
├── networking/
│   ├── prod-use1/terraform.tfstate
│   ├── prod-use2/terraform.tfstate
│   └── staging-use1/terraform.tfstate
├── compute/
│   ├── prod-use1-ecs/terraform.tfstate
│   └── staging-use1-ecs/terraform.tfstate
└── databases/
    ├── prod-use1-rds/terraform.tfstate
    └── staging-use1-rds/terraform.tfstate
```

---

## Module Organization

### Module Types

1. **Internal Modules** - Your company's standards
   ```
   modules/
   ├── company-vpc/              # Your standard VPC setup
   ├── company-ecs-service/      # Your ECS patterns
   └── company-rds/              # Your RDS standards
   ```

2. **Registry Modules** - Community modules
   ```hcl
   module "vpc" {
     source  = "terraform-aws-modules/vpc/aws"
     version = "5.1.2"
     # ...
   }
   ```

3. **Child Modules** - Part of your stack
   ```
   stacks/
   └── frontend-app/
       ├── main.tf
       └── modules/
           ├── alb/
           ├── ecs/
           └── cloudfront/
   ```

---

## CI/CD Integration Patterns

### Pattern 1: Monorepo + Single Pipeline

```
.github/
└── workflows/
    └── terraform.yml

# One workflow handles all stacks
on: [pull_request, push]

jobs:
  terraform:
    strategy:
      matrix:
        stack: [networking, database, app]
        environment: [dev, staging, prod]
    steps:
      - name: Plan ${{ matrix.stack }} in ${{ matrix.environment }}
        run: terraform plan
```

### Pattern 2: Stack-Specific Pipelines

```
stacks/
├── networking/
│   └── .github/workflows/terraform.yml
├── database/
│   └── .github/workflows/terraform.yml
└── app/
    └── .github/workflows/terraform.yml

# Each stack owns its pipeline
```

### Pattern 3: Atlantis (GitOps)

```
# Atlantis runs Terraform on pull request comments
# Comment on PR:
#   atlantis apply -d stacks/app

# Atlantis responds with plan, waits for approval, then applies
```

**Who uses this:** Airbnb, CrowdStrike, many large companies

---

## Environment Separation

### Option 1: Workspaces (Simple)

```bash
terraform workspace new dev
terraform apply

terraform workspace new prod
terraform apply
```

**Use when:** Small team, simple infrastructure

### Option 2: Directories (Most Common)

```
environments/
├── dev/main.tf
├── staging/main.tf
└── prod/main.tf
```

**Use when:** Multiple environments, different configurations

### Option 3: Terragrunt (DRY)

```
live/
├── dev/us-east-1/app/terragrunt.hcl
├── staging/us-east-1/app/terragrunt.hcl
└── prod/us-east-1/app/terragrunt.hcl
```

**Use when:** Many environments/regions, want to avoid duplication

---

## Variable Management

### Option 1: .tfvars Files

```
terraform.tfvars      # Local overrides (gitignored)
terraform.tfvars.example  # Template (committed)
dev.tfvars            # Dev values
staging.tfvars        # Staging values
prod.tfvars           # Prod values
```

### Option 2: YAML + yamldecode

```yaml
# config.yaml
environments:
  prod:
    instance_count: 10
    instance_type: "t3.large"
  dev:
    instance_count: 1
    instance_type: "t3.micro"
```

```hcl
# main.tf
locals {
  config = yamldecode(file("config.yaml"))
}

resource "aws_instance" "app" {
  count         = local.config.environments[terraform.workspace].instance_count
  instance_type = local.config.environments[terraform.workspace].instance_type
}
```

### Option 3: Environment Variables

```bash
export TF_VAR_instance_count=5
export TF_VAR_environment=prod
terraform apply
```

---

## Recommended Structure for Your Learning

### Small Project (1-3 people)

```
myapp-infrastructure/
├── environments/
│   ├── dev/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── terraform.tfvars
│   └── prod/
│       ├── main.tf
│       ├── variables.tf
│       └── terraform.tfvars
├── modules/
│   └── (if you create reusable components)
└── README.md
```

### Medium Project (3-20 people)

```
myapp-infrastructure/
├── stacks/
│   ├── 01-shared/
│   │   ├── main.tf        # VPC, IAM, etc.
│   │   └── outputs.tf
│   ├── 02-database/
│   │   ├── main.tf        # RDS, Redis
│   │   └── outputs.tf
│   └── 03-application/
│       ├── main.tf        # ECS, Lambda, etc.
│       └── outputs.tf
├── modules/
│   ├── vpc/
│   ├── ecs-service/
│   └── rds/
├── environments/
│   ├── dev.tfvars
│   └── prod.tfvars
└── scripts/
    └── validate-all.sh
```

### Large Project (20+ people, multiple teams)

```
infrastructure/
├── platforms/              # Shared platform infrastructure
│   ├── networking/
│   ├── security/
│   └── observability/
├── products/               # Application-specific
│   ├── payments/
│   │   ├── stacks/
│   │   └── modules/
│   ├── user-service/
│   │   ├── stacks/
│   │   └── modules/
│   └── frontend/
│       ├── stacks/
│       └── modules/
├── lib/                    # Shared internal modules
│   ├── company-ecs/
│   ├── company-rds/
│   └── company-s3/
└── tools/
    ├── terraform-wrapper/   # Wrapper script
    └── ci-templates/
```

---

## Summary Table

| Pattern | Best For | Complexity | Team Size |
|---------|----------|------------|-----------|
| **Environment-Based** | Simple apps, small teams | Low | 1-5 |
| **Stack-Based** | Growing apps, clear ownership | Medium | 5-50 |
| **Component-Based** | Large enterprises, specialists | High | 50+ |
| **Terragrunt** | Multi-region, multi-env | High | Any (with buy-in) |

---

## Tools That Help

| Tool | Purpose |
|------|---------|
| **Terragrunt** | DRY configuration, dependencies |
| **Atlantis** | GitOps for Terraform (PR-based applies) |
| **tfenv** | Multiple Terraform versions |
| **tfsec** | Security scanning |
| **checkov** | Compliance scanning |
| **infracost** | Cost estimation |
| **terraform-docs** | Auto-generate module docs |

---

## Further Reading

- [Terraform Module Composition](https://www.terraform.io/docs/cloud/guides/recommended-practices/module-structure.html)
- [Gruntwork's Terraform Guide](https://gruntwork.io/guides/)
- [Spotify's Terraform Journey](https://engineering.atspotify.com/2021/04/spotifys-journey-to-the-cloud/)
- [GitOps with Terraform and Atlantis](https://www.runatlantis.io/)

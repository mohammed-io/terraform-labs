# Terraform Learning Lab

**Complete hands-on Terraform learning environment with real feedback, zero cloud costs.**

Perfect for beginners learning Infrastructure as Code or anyone wanting to practice Terraform without AWS costs.

---

## Quick Start

```bash
# 1. Install Terraform
brew install terraform

# 2. Start the web interface (optional)
python main.py
# Opens at http://localhost:8501

# 3. Or work directly with files
cd learning-materials/fundamentals/scenario-01-docker/lab
terraform init
terraform apply
```

---

## Project Structure

```
terraform-lab/
├── README.md                    # This file
├── main.py                      # 🆕 Streamlit web interface
├── learning-materials/          # 🆕 All learning content
│   └── fundamentals/
│       ├── scenario-01-docker/          # Docker provider basics
│       ├── scenario-02-localstack-basics/    # S3 + DynamoDB
│       ├── scenario-03-localstack-networking/ # VPC, subnets, security groups
│       ├── scenario-04-localstack-security/   # IAM, KMS, Secrets Manager
│       ├── scenario-05-localstack-fullstack/  # Complete serverless app
│       └── scenario-06-stack-pattern/        # Multi-stack architecture
├── docs/                        # Additional documentation
│   └── CHEAT_SHEET.md          # ⭐ Comprehensive Terraform reference
├── modules/                     # Reusable modules
│   ├── custom/
│   │   └── vpc/                 # Reusable VPC module (built by you)
│   └── registry/
│       └── README.md            # Guide to using Terraform Registry modules
├── scenarios/                   # 🔄 Old structure (kept for reference)
└── answers/                     # 🔄 Old answers (kept for reference)
```

---

## Web Interface

```bash
# Launch the interactive learning interface
python main.py
```

The web interface provides:
- Browse all scenarios by category and difficulty
- Track your progress
- View hints and solutions step-by-step
- Download lab files with one click

---

## Learning Format

Each scenario follows a structured learning approach:

```
scenario-XX-name/
├── problem.md           # The challenge with requirements
├── step-01.md          # Guided hints with Quick Check
├── step-02.md          # More hints if needed
├── solution.md         # Complete reference solution
└── lab/                # Hands-on workspace
    ├── README.md       # Setup instructions
    ├── main.tf         # Starter code with TODOs
    ├── verify.sh       # Automated verification
    └── (other files)
```

### Quick Check Sections

Each step includes a 5-question self-assessment:

1. What's a Terraform provider? **(A plugin that connects to a specific service API like Docker, AWS, etc.)**

The parenthetical answer lets you test yourself before revealing it.

---

## How to Use

### Option 1: Web Interface (Recommended)

1. Run `python main.py`
2. Browse scenarios
3. Follow the step-by-step guidance
4. Download lab files
5. Run verification script

### Option 2: Command Line

1. **Read the problem** - `learning-materials/fundamentals/scenario-XX/problem.md`
2. **Open the lab** - `cd learning-materials/fundamentals/scenario-XX/lab`
3. **Implement** - Complete the TODOs in `main.tf`
4. **Verify** - Run `bash verify.sh`
5. **Check hints** - Read `step-01.md`, `step-02.md` if stuck
6. **Compare** - Review `solution.md` for complete answer

---

## Prerequisites

| Tool | For | Install |
|------|-----|--------|
| **Python 3.9+** | Web interface | `python.org` |
| **Streamlit** | Web interface | `pip install streamlit frontmatter` |
| **Terraform** | All scenarios | `brew install terraform` |
| **Docker** | Scenario 1 | `brew install --cask docker` |
| **LocalStack** | Scenarios 2-6 | `docker pull localstack/localstack` |

---

## Learning Path

| Scenario | Focus | Time | Difficulty |
|----------|-------|------|------------|
| **01** | Docker Provider | 15 min | Beginner |
| **02** | AWS Basics | 30 min | Beginner |
| **03** | Networking | 45 min | Intermediate |
| **04** | Security | 45 min | Intermediate |
| **05** | Serverless | 60 min | Advanced |
| **06** | Stack Pattern | 60 min | Advanced |

**Total Time:** ~4 hours of hands-on practice

---

## Starting LocalStack

For Scenarios 2-6, start LocalStack in a separate terminal:

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

# Scenario 4: Security
docker run --rm -it -p 4566:4566 \
  -e SERVICES=iam,kms,secretsmanager,lambda,sts \
  -e DEBUG=1 \
  localstack/localstack:latest

# Scenario 5: Full Stack
docker run --rm -it -p 4566:4566 -p 4510-4559:4510-4559 \
  -e SERVICES=lambda,apigateway,dynamodb,s3,iam,cloudwatch,logs,sts \
  -e DEBUG=1 \
  -e DISABLE_CORS_CHECKS=1 \
  localstack/localstack:latest

# Scenario 6: Stack Pattern
docker run --rm -it -p 4566:4566 -p 4510-4559:4510-4559 \
  -e SERVICES=ec2,dynamodb,iam,elb \
  -e DEBUG=1 \
  localstack/localstack:latest
```

---

## Essential Commands

```bash
# Daily workflow
terraform init          # Download providers, create backend
terraform plan          # Preview changes
terraform apply         # Create/update resources
terraform destroy       # Clean up

# Code quality
terraform fmt           # Format HCL code
terraform validate      # Check syntax

# Inspection
terraform output        # Show outputs
terraform state list    # List all resources
terraform show          # Show full state
```

---

## Documentation

| Document | Purpose |
|----------|---------|
| **`docs/QUICK_REFERENCE.md`** | One-page cheat sheet |
| **`docs/HCL_SYNTAX_AND_DYNAMICS.md`** | Interpolation, env vars, dynamic blocks |
| **`docs/FUNDAMENTALS.md`** | Complete learning guide |
| **`docs/PROJECT_ORGANIZATION.md`** | How companies organize Terraform |
| **`docs/LOCALSTACK_SERVICES.md`** | Free tier vs paid services |

---

## What You'll Learn

| Concept | Why It Matters |
|---------|----------------|
| **HCL Syntax** | Terraform's configuration language |
| **Providers** | Connect to Docker, AWS, etc. |
| **Resources** | The building blocks of infrastructure |
| **Variables** | Make configuration flexible |
| **Outputs** | Extract important values |
| **State** | How Terraform tracks what exists |
| **Modules** | Reuse code across projects |
| **Data Sources** | Query existing resources |
| **Dependencies** | Control resource creation order |
| **Remote State** | Share data between stacks |

---

## Tips for Success

1. **Use the web interface** - Easier navigation and progress tracking
2. **Run `plan` before `apply`** - See what will change
3. **Read error messages** - They're usually helpful
4. **Use `terraform fmt`** - Keep code readable
5. **Destroy when done** - Clean up resources
6. **Never edit `.terraform/` or state files** - Let Terraform manage these
7. **Try before checking hints** - Real learning happens when you struggle

---

## Going Further

After completing all scenarios:

1. **Practice with real AWS** - Use a free tier account
2. **Learn Terratest** - Write automated tests
3. **Study for certification** - HashiCorp Certified: Terraform Associate
4. **Contribute to modules** - Open source your modules
5. **Build a reference architecture** - Design a complete production setup

---

## Resources

- [Terraform Documentation](https://developer.hashicorp.com/terraform)
- [Terraform Registry](https://registry.terraform.io/)
- [AWS Provider Docs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [LocalStack Documentation](https://docs.localstack.cloud/)
- [Terraform Associate Study Guide](https://developer.hashicorp.com/terraform/certification)

---

**Happy learning! 🚀**

Remember: The best way to learn Terraform is to practice. Start simple, make mistakes, and build up from there.

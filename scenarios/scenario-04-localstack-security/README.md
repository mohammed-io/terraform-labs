# Scenario 4: LocalStack - AWS Security

## Prerequisites

**Skills needed before starting:**
- ✅ Scenario 01: Docker Provider (Terraform basics)
- ✅ Scenario 02: LocalStack AWS Fundamentals (provider configuration)
- ✅ Basic understanding of security concepts (authentication, authorization)
- Understanding of encryption at rest

**You will learn:**
- IAM (Identity and Access Management) fundamentals
- IAM users, groups, roles, and policies
- KMS (Key Management Service) for encryption
- Secrets Manager for secure secret storage
- Least privilege security principle
- IAM policies (JSON-based permissions)

**Tools required:**
- Docker Desktop running locally
- Terraform 1.x installed
- AWS CLI (optional, for verification)
- LocalStack (will run via Docker)

---

## Learning Objectives

- Create and manage IAM users, groups, and policies
- Understand least privilege principle
- Work with KMS (Key Management Service) for encryption
- Store secrets in Secrets Manager
- Understand IAM roles vs users

## Requirements

Build a secure infrastructure with:

```
┌─────────────────────────────────────────────────────────────────┐
│                        IAM Security Layer                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐      │
│  │ IAM User     │    │ IAM Group    │    │ IAM Role     │      │
│  │ "app-user"   │───▶│ "developers" │    │ "app-role"   │      │
│  │              │    │              │    │              │      │
│  │ Access Key   │    │ Managed Policy│    │ Trust Policy │      │
│  │ + Secret Key │    │ (Permissions) │    │ (for Lambda)  │      │
│  └──────────────┘    └──────────────┘    └──────────────┘      │
│                                                                  │
├─────────────────────────────────────────────────────────────────┤
│                      Secrets & Encryption                         │
├─────────────────────────────────────────────────────────────────┤
│  ┌──────────────┐              ┌──────────────┐                    │
│  │ Secrets Mgr  │              │     KMS      │                    │
│  │              │              │              │                    │
│  │ db_password │───encrypt───▶│  Master Key  │                    │
│  │ api_key      │              │              │                    │
│  └──────────────┘              └──────────────┘                    │
└─────────────────────────────────────────────────────────────────┘
```

### Resources to Create

1. **KMS Key**: Master encryption key for data at rest
2. **IAM User**: Programmatic user for application access
3. **IAM Access Key**: Access key + secret key for the user
4. **IAM Policy**: Least-privilege policy for specific actions
5. **IAM Group**: Group to organize users
6. **IAM Group Membership**: Add user to group
7. **IAM Role**: Role for Lambda/service-to-service access
8. **IAM Policy Attachment**: Attach policy to role
9. **Secrets Manager Secret**: Encrypted secret storage
10. **Secret Version**: Versioned secret (allows rotation)

### Security Best Practices to Implement

| Principle | Implementation |
|-----------|----------------|
| **Least Privilege** | IAM policy allows only specific actions on specific resources |
| **Rotation** | KMS key rotation enabled; Secrets use versions |
| **Separation of Duties** | Different users/roles for different concerns |
| **Encryption at Rest** | S3 buckets, RDS, EBS volumes use KMS encryption |
| **Audit** | CloudTrail logging (simulated with outputs) |

### Variables to Use

| Variable | Default | Description |
|----------|---------|-------------|
| `user_name` | "app-user" | IAM username |
| `group_name` | "developers" | IAM group name |
| `role_name` | "app-lambda-role" | IAM role name |
| `key_alias` | "app-master-key" | KMS key alias |
| `secret_name` | "db-credentials" | Secret name |
| `secret_value` | "admin:password123" | Secret value (in real life, use variable) |

## Your Task

Create `main.tf` in this directory with:

1. AWS provider configured for LocalStack
2. KMS key with automatic key rotation enabled
3. IAM user with programmatic access (access key)
4. IAM policy granting read-only access to S3
5. IAM group for developers
6. IAM group policy attachment
7. Add user to group
8. IAM role for Lambda with basic execution permissions
9. IAM policy for Lambda logging
10. Secrets Manager secret (encrypted with KMS key)
11. Outputs showing access keys (careful!), ARNs, and secret references

## Testing Your Work

```bash
# Start LocalStack
docker run --rm -it -p 4566:4566 -p 4510-4559:4510-4559 \
  -e SERVICES=iam,kms,secretsmanager,lambda,sts \
  -e DEBUG=1 \
  localstack/localstack:latest

# Initialize and apply
terraform init
terraform plan
terraform apply

# List IAM users
aws --endpoint-url=http://localhost:4566 iam list-users

# Get user details (includes access keys)
aws --endpoint-url=http://localhost:4566 iam get-user \
  --user-name app-user

# List KMS keys
aws --endpoint-url=http://localhost:4566 kms list-keys

# Describe KMS key
aws --endpoint-url=http://localhost:4566 kms describe-key \
  --key-id <key-id-from-output>

# List secrets
aws --endpoint-url=http://localhost:4566 secretsmanager list-secrets

# Get secret value
aws --endpoint-url=http://localhost:4566 secretsmanager get-secret-value \
  --secret-id <secret-arn>

# Clean up
terraform destroy
```

## Expected Results

When you run `terraform apply`, you should see:
- 11 resources created (KMS key, IAM user, access key, policy, group, membership, role, 2 policy attachments, secret)
- KMS key with rotation enabled
- IAM user with programmatic access
- Secret encrypted with KMS key
- All outputs show ARNs and sensitive data

## What You're Learning

| Concept | Why It Matters |
|---------|----------------|
| **IAM Users** | Long-lived credentials for people/applications |
| **IAM Roles** | Temporary credentials for services/AWS resources |
| **IAM Policies** | JSON-based permissions (who can do what) |
| **KMS** | Encryption key management = data protection |
| **Secrets Manager** | Secure secret storage = no hardcoded secrets |
| **Least Privilege** | Grant minimum needed permissions = reduce blast radius |

## Security Concepts

### IAM Policy Structure

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "VisualEditor0",
      "Effect": "Allow",
      "Action": [
        "s3:Get*"
      ],
      "Resource": [
        "arn:aws:s3:::my-bucket/*"
      ]
    }
  ]
}
```

**Key Elements:**
- `Effect`: Allow or Deny (Deny always takes precedence)
- `Action`: Specific AWS API calls (use wildcards carefully)
- `Resource`: ARN of resources affected
- `Condition`: Optional (time, IP, MFA, etc.)

### KMS Key Usage

```hcl
# Encrypt a secret with KMS
resource "aws_secretsmanager_secret" "db_password" {
  name = "db/password"

  # KMS encryption
  kms_key_id = aws_kms_key.main.arn
}
```

### IAM Trust Policy (for Roles)

```hcl
# Role can be assumed by Lambda
assume_role_policy = jsonencode({
  Version = "2012-10-17"
  Statement = [
    {
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }
  ]
})
```

## Hints

<details>
<summary>Hint 1: KMS Key with Rotation</summary>

```hcl
resource "aws_kms_key" "main" {
  description             = "Master encryption key for application"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  tags = {
    Name = "app-master-key"
  }
}

# KMS Key Alias (easier reference)
resource "aws_kms_alias" "main" {
  name          = var.key_alias
  target_key_id = aws_kms_key.main.key_id
}
```

</details>

<details>
<summary>Hint 2: IAM User with Access Key</summary>

```hcl
resource "aws_iam_user" "app_user" {
  name = var.user_name
  path = "/application/"

  tags = {
    Purpose = "Programmatic access"
  }
}

resource "aws_iam_access_key" "app_user" {
  user = aws_iam_user.app_user.name
}

# Output the credentials (WARNING: In production, never do this!)
output "access_key_id" {
  value     = aws_iam_access_key.app_user.id
  sensitive = true
}

output "secret_access_key" {
  value     = aws_iam_access_key.app_user.secret
  sensitive = true
}
```

</details>

<details>
<summary>Hint 3: Secrets Manager Secret</summary>

```hcl
resource "aws_secretsmanager_secret" "db_creds" {
  name                    = var.secret_name
  description              = "Database credentials"
  recovery_window_in_days = 0

  # Encrypt with KMS
  kms_key_id = aws_kms_alias.main.target_key_id

  tags = {
    Environment = "dev"
  }
}

resource "aws_secretsmanager_secret_version" "db_creds" {
  secret_id     = aws_secretsmanager_secret.db_creds.id
  secret_string = var.secret_value

  # Store versions (allows rotation without changing the secret ID)
  version_stages = ["AWSCURRENT"]
}
```

</details>

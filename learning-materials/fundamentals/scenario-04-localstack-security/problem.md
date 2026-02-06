---
name: "LocalStack - AWS Security"
category: "fundamentals"
difficulty: "intermediate"
time: "45 minutes"
services: ["iam", "kms", "secretsmanager"]
concepts: ["iam-users", "iam-roles", "iam-policies", "kms-keys", "secrets-manager"]
---

# LocalStack - AWS Security

## Scenario

You're building the security foundation for an application. You need to set up IAM for access control, KMS for encryption, and Secrets Manager for secure credential storage.

## Architecture

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

## Requirements

Build a secure infrastructure with:

1. **KMS Key**: Master encryption key with automatic rotation
2. **KMS Alias**: Friendly name for the key
3. **IAM User**: Programmatic user for application access
4. **IAM Access Key**: Access key + secret for the user
5. **IAM Policy**: Least-privilege S3 read policy
6. **IAM Group**: Group to organize users
7. **IAM Group Membership**: Add user to group
8. **IAM Role**: Role for Lambda with trust policy
9. **IAM Policy Attachment**: Attach policy to role
10. **Secrets Manager Secret**: Encrypted secret storage
11. **Secret Version**: Versioned secret value

## Constraints

- KMS key must have automatic rotation enabled
- IAM policy must follow least privilege (only specific actions)
- IAM role must have proper trust policy for Lambda
- Secret must be encrypted with the KMS key
- All sensitive outputs must be marked as `sensitive = true`

## Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `user_name` | "app-user" | IAM username |
| `group_name` | "developers" | IAM group name |
| `role_name` | "app-lambda-role" | IAM role name |
| `key_alias` | "app-master-key" | KMS key alias |
| `secret_name` | "db-credentials" | Secret name |
| `secret_value` | "admin:password123" | Secret value |

## Prerequisites

- Complete scenarios 01-03
- Docker Desktop running
- Terraform 1.x installed
- Understanding of basic security concepts

## What You'll Learn

| Concept | Why It Matters |
|---------|----------------|
| **IAM Users** | Long-lived credentials for people/applications |
| **IAM Roles** | Temporary credentials for services/AWS resources |
| **IAM Policies** | JSON-based permissions (who can do what) |
| **KMS** | Encryption key management = data protection |
| **Secrets Manager** | Secure secret storage = no hardcoded secrets |
| **Least Privilege** | Grant minimum needed permissions = reduce blast radius |

## Getting Started

1. Make sure LocalStack is running:
   ```bash
   docker run --rm -it -p 4566:4566 -p 4510-4559:4510-4559 \
     -e SERVICES=iam,kms,secretsmanager,lambda,sts \
     -e DEBUG=1 \
     localstack/localstack:latest
   ```

2. Navigate to the lab directory and start building!

3. Check `step-01.md` for hints on KMS and IAM basics.

4. Check `step-02.md` for hints on IAM roles and Secrets Manager.

## Verification

Run the lab's `verify.sh` script to check your work:

```bash
cd lab
bash verify.sh
```

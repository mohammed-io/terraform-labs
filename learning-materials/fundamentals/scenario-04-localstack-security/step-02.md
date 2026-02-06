# Step 2: IAM Roles and Secrets Manager

## IAM Role

Roles are for temporary credentials, typically used by AWS services:

```hcl
resource "aws_iam_role" "lambda" {
  name                = var.role_name
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
}
```

**Trust Policy (assume_role_policy)**:
- Defines WHO can assume this role
- In this case: Lambda service can assume it
- Other common principals: `ec2.amazonaws.com`, `s3.amazonaws.com`, AWS accounts

## IAM Policy Attachment for Roles

Attach a policy to a role:

```hcl
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
```

This uses an AWS-managed policy for Lambda logging.

## Custom Inline Policy for Role

Or create a custom policy directly on the role:

```hcl
resource "aws_iam_role_policy" "lambda_dynamodb" {
  name = "dynamodb-access"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:Query"
        ]
        Resource = "arn:aws:dynamodb:*:*:table/app-*"
      }
    ]
  })
}
```

**Least Privilege**: Only grant specific actions on specific resources!

## Secrets Manager Secret

Store encrypted secrets:

```hcl
resource "aws_secretsmanager_secret" "db_creds" {
  name                    = var.secret_name
  description             = "Database credentials"
  recovery_window_in_days = 0

  kms_key_id = aws_kms_alias.main.target_key_id

  tags = {
    Environment = "dev"
  }
}
```

**Settings:**
- `recovery_window_in_days`: 0 = immediate deletion (no recovery), 7-30 = soft delete
- `kms_key_id`: Encrypt with this specific KMS key

## Secret Version

Add the actual secret value:

```hcl
resource "aws_secretsmanager_secret_version" "db_creds" {
  secret_id     = aws_secretsmanager_secret.db_creds.id
  secret_string = var.secret_value

  version_stages = ["AWSCURRENT"]
}
```

**Version Stages**:
- `AWSCURRENT`: The active version
- `AWSPREVIOUS`: The previous version
- Custom stages for rotation workflows

## Sensitive Outputs

Mark sensitive outputs:

```hcl
output "access_key_id" {
  value     = aws_iam_access_key.app_user.id
  sensitive = true
}

output "secret_access_key" {
  value     = aws_iam_access_key.app_user.secret
  sensitive = true
}
```

**Why `sensitive = true`?**
- Prevents Terraform from showing the value in output
- Won't be logged by CI/CD systems
- Requires explicit command to view

## Your Task

1. Create an IAM role for Lambda with proper trust policy
2. Attach the AWSLambdaBasicExecutionRole policy to the role
3. Create a Secrets Manager secret encrypted with your KMS key
4. Create a secret version with the secret value
5. Add outputs for ARNs and mark sensitive outputs appropriately

## Quick Check

Test your understanding:

1. What's the difference between a trust policy and a permissions policy? (Trust policy defines who can assume the role; permissions policy defines what the role can do once assumed)

2. Why use `recovery_window_in_days = 0` for a secret in dev? (It allows immediate deletion - useful for development/testing where you don't need soft delete)

3. What does the `AWSCURRENT` version stage mean? (It's the currently active version of the secret that applications will use)

4. What's the difference between `aws_iam_role_policy_attachment` and `aws_iam_role_policy`? (aws_iam_role_policy_attachment attaches an existing managed policy; aws_iam_role_policy creates a new inline policy directly on the role)

5. Why use `kms_key_id` in Secrets Manager instead of the default AWS key? (Using a customer-managed key gives you control over the encryption key, rotation, and access policies)

## Key IAM vs Role Decision Guide

| Use Case | Use |
|----------|-----|
| Human needs console access | IAM User |
| Application needs permanent credentials | IAM User + Access Key |
| EC2/Lambda needs to access other AWS services | IAM Role |
| Cross-account access | IAM Role |
| Federated access (SAML/OIDC) | IAM Role |

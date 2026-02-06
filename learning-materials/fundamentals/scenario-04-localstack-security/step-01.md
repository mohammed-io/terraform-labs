# Step 1: KMS and IAM Users/Groups

## KMS Key

KMS (Key Management Service) manages encryption keys:

```hcl
resource "aws_kms_key" "main" {
  description             = "Master encryption key for application"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  tags = {
    Name = "app-master-key"
  }
}
```

**Key settings:**
- `deletion_window_in_days`: Waiting period before key deletion (7-30 days)
- `enable_key_rotation`: Automatically rotate the key annually

## KMS Alias

An alias gives your key a friendly name:

```hcl
resource "aws_kms_alias" "main" {
  name          = "alias/${var.key_alias}"
  target_key_id = aws_kms_key.main.key_id
}
```

**Why use aliases?**
- Keys have random IDs like `mrk-1234567890abcdef`
- Aliases are readable: `alias/app-master-key`
- You can reference the key by alias in other resources

## IAM User

IAM users represent people or applications:

```hcl
resource "aws_iam_user" "app_user" {
  name = var.user_name
  path = "/application/"

  tags = {
    Purpose = "Programmatic access"
  }
}
```

**Path**: Organizes users under `/application/` for hierarchy

## IAM Access Key

For programmatic (not console) access:

```hcl
resource "aws_iam_access_key" "app_user" {
  user = aws_iam_user.app_user.name
}
```

**⚠️ WARNING**: In production, NEVER output access keys in plain text!

## IAM Policy

Policies define what actions are allowed:

```hcl
resource "aws_iam_policy" "s3_readonly" {
  name        = "s3-readonly-policy"
  description = "Read-only access to S3"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:Get*",
          "s3:List*"
        ]
        Resource = "*"
      }
    ]
  })
}
```

**Policy structure:**
- `Effect`: Allow or Deny (Deny always wins)
- `Action`: Specific AWS API calls
- `Resource`: ARN of affected resources

## IAM Group and Membership

Groups organize users and apply policies collectively:

```hcl
resource "aws_iam_group" "developers" {
  name = var.group_name
  path = "/developers/"
}

resource "aws_iam_group_policy_attachment" "s3_readonly" {
  group      = aws_iam_group.developers.name
  policy_arn = aws_iam_policy.s3_readonly.arn
}

resource "aws_iam_group_membership" "developers" {
  group = aws_iam_group.developers.name
  users = [aws_iam_user.app_user.name]
}
```

**Why groups?**
- Apply policies to many users at once
- Easier to manage permissions
- Follows organizational structure

## Your Task

1. Create a KMS key with rotation enabled
2. Create a KMS alias for the key
3. Create an IAM user
4. Create an IAM access key for the user
5. Create an IAM policy for S3 read-only access
6. Create an IAM group
7. Attach the policy to the group
8. Add the user to the group

## Quick Check

Test your understanding:

1. What's the difference between an IAM user and an IAM role? (Users have long-lived credentials for people/apps; roles provide temporary credentials for services or cross-account access)

2. Why use `enable_key_rotation = true` on a KMS key? (It automatically rotates the encryption key annually, improving security without requiring manual intervention)

3. What does `Effect = "Deny"` do in an IAM policy? (It explicitly denies the action - Deny statements always override Allow statements)

4. Why organize users into groups instead of attaching policies directly? (Groups make it easier to manage permissions - add/remove users from groups rather than managing individual policies)

5. What's the minimum `deletion_window_in_days` for a KMS key? (7 days - this is the AWS minimum waiting period before a key can be permanently deleted)

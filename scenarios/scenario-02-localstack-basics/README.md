# Scenario 2: LocalStack - AWS Fundamentals

## Prerequisites

**Skills needed before starting:**
- ✅ Scenario 01: Docker Provider (Terraform basics)
- Basic understanding of AWS services (S3, DynamoDB)
- Command line familiarity

**You will learn:**
- AWS provider configuration for LocalStack
- S3 buckets and object storage
- DynamoDB tables and items
- How LocalStack mimics AWS locally

**Tools required:**
- Docker Desktop running locally
- Terraform 1.x installed
- AWS CLI (optional, for verification)
- LocalStack (will run via Docker)

---

## Learning Objectives

- Work with AWS provider in LocalStack
- Create S3 buckets and objects
- Create DynamoDB tables
- Understand AWS resource naming and region configuration
- Learn about Terraform state with cloud resources

## Requirements

Build a simple serverless data pipeline:

```
┌─────────────┐      ┌──────────────┐      ┌─────────────┐
│  S3 Bucket  │──────│  Lambda      │──────│ DynamoDB    │
│  (Uploads)  │      │  (Process)   │      │  (Database) │
└─────────────┘      └──────────────┘      └─────────────┘
```

### Resources to Create

1. **S3 Bucket**: Raw file uploads bucket
2. **S3 Bucket Object**: Upload a sample file
3. **DynamoDB Table**: User data table with:
   - Partition key: `user_id` (String)
   - Sort key: `timestamp` (String)
   - Billing mode: PAY_PER_REQUEST
4. **DynamoDB Table Item**: Add sample data

### AWS Provider Configuration

LocalStack runs on `localhost:4566`. Configure AWS provider:

```hcl
provider "aws" {
  access_key = "test"           # LocalStack requires these
  secret_key = "test"           # but doesn't validate them
  region     = "us-east-1"

  endpoints {
    s3       = "http://localhost:4566"
    dynamodb = "http://localhost:4566"
    lambda   = "http://localhost:4566"
  }

  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id   = true
}
```

### Setup LocalStack First

```bash
# Start LocalStack
docker run --rm -it \
  -p 4566:4566 \
  -p 4510-4559:4510-4559 \
  -e SERVICES=s3,dynamodb,lambda \
  localstack/localstack:latest
```

## Your Task

Create `main.tf` in this directory with:

1. AWS provider configured for LocalStack
2. S3 bucket named `raw-uploads-bucket`
3. S3 object uploading a test file (create one locally first)
4. DynamoDB table named `users-table`
5. DynamoDB item with sample user data
6. Outputs showing bucket name, table name, and endpoints

## Variables to Use

| Variable | Default | Description |
|----------|---------|-------------|
| `bucket_name` | "raw-uploads-bucket" | Name of S3 bucket |
| `table_name` | "users-table" | Name of DynamoDB table |
| `user_id` | "user-123" | Sample user ID |
| `environment` | "dev" | Environment tag |

## Testing Your Work

```bash
# Start LocalStack first (in separate terminal)
docker run --rm -it -p 4566:4566 -p 4510-4559:4510-4559 \
  -e SERVICES=s3,dynamodb,lambda \
  localstack/localstack:latest

# Initialize and apply
terraform init
terraform plan
terraform apply

# Verify S3 bucket was created
aws --endpoint-url=http://localhost:4566 s3 ls

# Verify DynamoDB table was created
aws --endpoint-url=http://localhost:4566 dynamodb list-tables

# Describe the table
aws --endpoint-url=http://localhost:4566 dynamodb describe-table \
  --table-name users-table

# Check outputs
terraform output bucket_name
terraform output table_name

# Clean up
terraform destroy
```

## Expected Results

When you run `terraform apply`, you should see:
- 4 resources created (S3 bucket, S3 object, DynamoDB table, DynamoDB item)
- No errors in the plan
- S3 bucket accessible via AWS CLI at localhost:4566
- DynamoDB table with correct key schema

## What You're Learning

| Concept | Why It Matters |
|---------|----------------|
| **S3 Buckets** | Object storage = foundation of data lakes |
| **DynamoDB** | NoSQL database = serverless at scale |
| **Terraform State** | State file tracks all AWS resources created |
| **LocalStack Endpoints** | How to redirect AWS SDK to local mock |

## Hints

<details>
<summary>Hint 1: S3 Bucket with versioning</summary>

```hcl
resource "aws_s3_bucket" "data" {
  bucket = var.bucket_name

  # Enable versioning (optional, but good practice)
  versioning {
    status = "Enabled"
  }
}

resource "aws_s3_object" "sample" {
  bucket = aws_s3_bucket.data.id
  key    = "sample-data.json"
  source = "./sample-data.json"  # Create this file first

  # Force deletion even if bucket has objects
  force_destroy = true
}
```

</details>

<details>
<summary>Hint 2: DynamoDB Table</summary>

```hcl
resource "aws_dynamodb_table" "users" {
  name           = var.table_name
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "user_id"
  range_key      = "timestamp"

  attribute {
    name = "user_id"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "S"
  }

  tags = {
    Environment = var.environment
  }
}
```

</details>

<details>
<summary>Hint 3: DynamoDB Item</summary>

```hcl
resource "aws_dynamodb_table_item" "sample" {
  table_name = aws_dynamodb_table.users.name
  hash_key   = aws_dynamodb_table.users.hash_key
  range_key  = "${var.user_id}#$(timestamp())"

  item = <<ITEM
{
  "user_id": {"S": "${var.user_id}"},
  "timestamp": {"S": "2024-01-01T00:00:00Z"},
  "email": {"S": "user@example.com"},
  "name": {"S": "Test User"}
}
ITEM
}
```

</details>

# Step 1: AWS Provider & S3 Buckets

## AWS Provider for LocalStack

LocalStack runs on `localhost:4566` and mimics AWS APIs locally. To use it, configure the AWS provider with special endpoints:

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

**Why these settings?**
- `access_key`/`secret_key`: Required by AWS SDK but not validated by LocalStack
- `endpoints`: Redirect AWS calls to LocalStack instead of real AWS
- `skip_*` settings: Prevent Terraform from trying to validate credentials

## S3 Bucket Resource

S3 buckets are object storage containers. Here's the basic pattern:

```hcl
resource "aws_s3_bucket" "data" {
  bucket = var.bucket_name
}

resource "aws_s3_bucket_versioning" "data" {
  bucket = aws_s3_bucket.data.id

  versioning_configuration {
    status = "Enabled"
  }
}
```

**Key attributes:**
- `bucket`: Globally unique name (in real AWS; LocalStack is more lenient)
- `force_destroy`: Set to `true` to allow deletion even with objects inside

## S3 Object Resource

To upload a file to S3:

```hcl
resource "aws_s3_object" "sample" {
  bucket = aws_s3_bucket.data.id
  key    = "sample-data.json"
  source = "./sample-data.json"

  # Force deletion even if bucket has objects
  force_destroy = true
}
```

**Note:** You'll need to create a `sample-data.json` file first, or the Terraform will fail.

## Your Task

1. Configure the AWS provider for LocalStack
2. Create an S3 bucket with versioning enabled
3. Create a sample JSON file (e.g., `{"test": "data"}`)
4. Upload the file to S3 using `aws_s3_object`

## Quick Check

Test your understanding:

1. What's the purpose of the `endpoints` block in the AWS provider? (To redirect AWS API calls to LocalStack at localhost:4566 instead of real AWS)

2. Why does LocalStack require access_key and secret_key if it doesn't validate them? (The AWS SDK requires these fields to be present, even though LocalStack ignores the values)

3. What does `force_destroy = true` do on an S3 bucket? (Allows Terraform to delete the bucket even if it contains objects)

4. What's the difference between `aws_s3_bucket` and `aws_s3_object`? (aws_s3_bucket creates the container/storage bucket; aws_s3_object uploads a specific file into a bucket)

5. Why would you enable versioning on an S3 bucket? (To keep multiple versions of each object, protecting against accidental deletion or overwrites)

# -----------------------------------------------------------------------------
# Provider Configuration
# -----------------------------------------------------------------------------
provider "aws" {
  access_key = "test"
  secret_key = "test"
  region     = "us-east-1"

  endpoints {
    lambda = "http://localhost:4566"
    apigateway = "http://localhost:4566"
    iam = "http://localhost:4566"
    cloudwatch = "http://localhost:4566"
    logs = "http://localhost:4566"
  }

  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id   = true

  default_tags {
    tags = {
      Project     = "stack-pattern-demo"
      ManagedBy   = "terraform"
    }
  }
}

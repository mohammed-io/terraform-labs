terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  access_key = "test"
  secret_key = "test"
  region     = "us-east-1"

  endpoints {
    dynamodb = "http://localhost:4566"
  }

  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id   = true
}

# TODO: Read remote state from networking stack
# HINT: data "terraform_remote_state" "networking" { backend = "local", config = { path = "${path.module}/../01-networking/terraform.tfstate" } }

# TODO: Create DynamoDB table
# HINT: resource "aws_dynamodb_table" "users" { name = "users-table", hash_key = "user_id" }

# TODO: Add tag with VPC ID from remote state
# HINT: tags = { VPC_ID = data.terraform_remote_state.networking.outputs.vpc_id }

output "table_name" {
  value = try(aws_dynamodb_table.users.name, "not created")
}

output "table_arn" {
  value = try(aws_dynamodb_table.users.arn, "not created")
}

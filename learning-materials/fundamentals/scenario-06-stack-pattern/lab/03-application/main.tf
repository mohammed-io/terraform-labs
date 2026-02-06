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
    ec2      = "http://localhost:4566"
    elb      = "http://localhost:4566"
    dynamodb = "http://localhost:4566"
  }

  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id   = true
}

# TODO: Read remote state from networking stack
# HINT: data "terraform_remote_state" "networking" { backend = "local", config = { path = "${path.module}/../01-networking/terraform.tfstate" } }

# TODO: Read remote state from database stack
# HINT: data "terraform_remote_state" "database" { backend = "local", config = { path = "${path.module}/../02-database/terraform.tfstate" } }

# TODO: Create Load Balancer using subnets and SG from networking stack
# HINT: resource "aws_lb" "app" { subnets = data.terraform_remote_state.networking.outputs.public_subnet_ids }

# TODO: Create resource that uses database table name
# HINT: Reference: data.terraform_remote_state.database.outputs.table_name

output "load_balancer_arn" {
  value = try(aws_lb.app.arn, "not created")
}

output "load_balancer_dns_name" {
  value = try(aws_lb.app.dns_name, "N/A in LocalStack")
}

output "application_url" {
  value = try("http://${aws_lb.app.dns_name}", "http://localhost:8080")
}

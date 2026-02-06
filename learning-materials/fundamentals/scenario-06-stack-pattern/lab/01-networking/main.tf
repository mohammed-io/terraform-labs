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
    ec2 = "http://localhost:4566"
    iam = "http://localhost:4566"
  }

  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id   = true
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  default = ["10.0.10.0/24", "10.0.11.0/24"]
}

# TODO: Create VPC
# HINT: resource "aws_vpc" "main" { cidr_block = var.vpc_cidr, enable_dns_hostnames = true }

# TODO: Create Internet Gateway
# HINT: resource "aws_internet_gateway" "gw" { vpc_id = aws_vpc.main.id }

# TODO: Create Public Subnets (use count)
# HINT: resource "aws_subnet" "public" { count = length(var.public_subnet_cidrs), map_public_ip_on_launch = true }

# TODO: Create Private Subnets (use count)
# HINT: resource "aws_subnet" "private" { count = length(var.private_subnet_cidrs) }

# TODO: Create Route Table for public subnets
# HINT: resource "aws_route_table" "public" { route { cidr_block = "0.0.0.0/0", gateway_id = aws_internet_gateway.gw.id } }

# TODO: Create Route Table Associations
# HINT: resource "aws_route_table_association" "public" { count = length(var.public_subnet_cidrs) }

# TODO: Create Web Security Group (HTTP/HTTPS)
# HINT: resource "aws_security_group" "web" { ingress with ports 80 and 443 }

# TODO: Create App Security Group (from web SG only)
# HINT: resource "aws_security_group" "app" { ingress uses security_groups = [aws_security_group.web.id] }

output "vpc_id" {
  value = try(aws_vpc.main.id, "not created")
}

output "public_subnet_ids" {
  value = try(aws_subnet.public[*].id, [])
}

output "private_subnet_ids" {
  value = try(aws_subnet.private[*].id, [])
}

output "web_security_group_id" {
  value = try(aws_security_group.web.id, "not created")
}

output "app_security_group_id" {
  value = try(aws_security_group.app.id, "not created")
}

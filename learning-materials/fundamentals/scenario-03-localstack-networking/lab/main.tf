terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# TODO: Configure AWS provider for LocalStack
# HINT: Same as scenario-02, but add ec2 and iam to endpoints

# Variables
variable "vpc_cidr" {
  description = "VPC CIDR block"
  default     = "10.0.0.0/16"
  type        = string
}

variable "public_subnet_cidr" {
  description = "Public subnet CIDR"
  default     = "10.0.1.0/24"
  type        = string
}

variable "private_subnet_cidr" {
  description = "Private subnet CIDR"
  default     = "10.0.2.0/24"
  type        = string
}

variable "availability_zone" {
  description = "Availability zone"
  default     = "us-east-1a"
  type        = string
}

# TODO: Create VPC
# HINT: resource "aws_vpc" "main" { cidr_block = var.vpc_cidr, enable_dns_hostnames = true, enable_dns_support = true }

# TODO: Create Internet Gateway
# HINT: resource "aws_internet_gateway" "gw" { vpc_id = aws_vpc.main.id }

# TODO: Create Public Subnet
# HINT: resource "aws_subnet" "public" { vpc_id = ..., map_public_ip_on_launch = true }

# TODO: Create Private Subnet
# HINT: resource "aws_subnet" "private" { vpc_id = ..., NO map_public_ip_on_launch }

# TODO: Create Route Table for public subnet
# HINT: resource "aws_route_table" "public" { route { cidr_block = "0.0.0.0/0", gateway_id = aws_internet_gateway.gw.id } }

# TODO: Associate route table with public subnet
# HINT: resource "aws_route_table_association" "public" { subnet_id = ..., route_table_id = ... }

# TODO: Create Web Security Group (HTTP/HTTPS from anywhere)
# HINT: resource "aws_security_group" "web" { ingress with ports 80 and 443, egress all }

# TODO: Create App Security Group (only from web SG)
# HINT: resource "aws_security_group" "app" { ingress uses security_groups = [aws_security_group.web.id] }

# Outputs
output "internet_gateway_id" {
  description = "Internet Gateway ID"
  value       = try(aws_internet_gateway.gw.id, "not created")
}

output "vpc_id" {
  description = "VPC ID"
  value       = try(aws_vpc.main.id, "not created")
}

output "public_subnet_id" {
  description = "Public subnet ID"
  value       = try(aws_subnet.public.id, "not created")
}

output "private_subnet_id" {
  description = "Private subnet ID"
  value       = try(aws_subnet.private.id, "not created")
}

output "web_security_group_id" {
  description = "Web security group ID"
  value       = try(aws_security_group.web.id, "not created")
}

output "app_security_group_id" {
  description = "App security group ID"
  value       = try(aws_security_group.app.id, "not created")
}

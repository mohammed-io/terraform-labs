# -----------------------------------------------------------------------------
# Scenario 3: LocalStack - AWS Networking (Answer Key)
# -----------------------------------------------------------------------------

# This solution implements a secure multi-tier network architecture:
# - VPC with DNS enabled
# - Internet Gateway for public internet access
# - Public subnet (can reach internet)
# - Private subnet (isolated from internet)
# - Route table for public subnet
# - Security group for web tier (HTTP/HTTPS)
# - Security group for app tier (restricted access)

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# -----------------------------------------------------------------------------
# Provider Configuration for LocalStack
# -----------------------------------------------------------------------------
provider "aws" {
  access_key = "test"
  secret_key = "test"
  region     = "us-east-1"

  endpoints {
    ec2  = "http://localhost:4566"
    iam  = "http://localhost:4566"
    lambda = "http://localhost:4566"
  }

  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id   = true
}

# -----------------------------------------------------------------------------
# Variables
# -----------------------------------------------------------------------------
variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "Public subnet CIDR"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  description = "Private subnet CIDR"
  type        = string
  default     = "10.0.2.0/24"
}

variable "availability_zone" {
  description = "Availability zone"
  type        = string
  default     = "us-east-1a"
}

# -----------------------------------------------------------------------------
# VPC (Virtual Private Cloud)
# -----------------------------------------------------------------------------
# A VPC is a logically isolated section of the AWS Cloud.
# Think of it as your own virtual data center in the cloud.

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true  # Instances get DNS hostnames
  enable_dns_support   = true  # DNS resolution works

  tags = {
    Name        = "main-vpc"
    Environment = "dev"
    Purpose     = "multi-tier-app"
  }
}

# -----------------------------------------------------------------------------
# Internet Gateway
# -----------------------------------------------------------------------------
# An Internet Gateway allows communication between instances in your VPC
# and the internet. It's a managed, highly available component.

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main-igw"
  }
}

# -----------------------------------------------------------------------------
# Public Subnet
# -----------------------------------------------------------------------------
# A subnet is a range of IP addresses in your VPC.
# Public subnet: Has route to Internet Gateway + instances get public IPs

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = var.availability_zone

  # This is what makes the subnet "public"
  # Instances launched here get a public IP address
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet"
    Type = "public"
  }
}

# -----------------------------------------------------------------------------
# Private Subnet
# -----------------------------------------------------------------------------
# Private subnet: No route to Internet Gateway, no public IPs
# Used for: databases, backend services, internal applications

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block          = var.private_subnet_cidr
  availability_zone   = var.availability_zone

  # No map_public_ip_on_launch = instances won't get public IPs

  tags = {
    Name = "private-subnet"
    Type = "private"
  }
}

# -----------------------------------------------------------------------------
# Route Table for Public Subnet
# -----------------------------------------------------------------------------
# Route tables control where network traffic is directed.
# Each subnet must be associated with a route table.

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  # Default route: send all internet traffic to the Internet Gateway
  route {
    cidr_block = "0.0.0.0/0"  # 0.0.0.0/0 means "all IPv4 addresses"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "public-rt"
  }
}

# -----------------------------------------------------------------------------
# Route Table Association
# -----------------------------------------------------------------------------
# Connects the route table to the subnet.
# A subnet can only be associated with ONE route table at a time.

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Note: Private subnets use the VPC's main route table by default.
# The main route table has NO route to the internet, keeping it private.

# -----------------------------------------------------------------------------
# Security Group: Web Tier
# -----------------------------------------------------------------------------
# Security Groups are stateful firewalls that control inbound/outbound traffic.
# They operate at the INSTANCE level (unlike NACLs which operate at subnet level).

resource "aws_security_group" "web" {
  name        = "web-sg"
  description = "Allow HTTP/HTTPS from anywhere"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "web-sg"
    Tier = "web"
  }
}

# Inbound rule: Allow HTTP from anywhere
resource "aws_vpc_security_group_ingress_rule" "web_http" {
  security_group_id = aws_security_group.web.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 80
  ip_protocol = "tcp"
  to_port     = 80

  description = "Allow HTTP from anywhere"
}

# Inbound rule: Allow HTTPS from anywhere
resource "aws_vpc_security_group_ingress_rule" "web_https" {
  security_group_id = aws_security_group.web.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 443
  ip_protocol = "tcp"
  to_port     = 443

  description = "Allow HTTPS from anywhere"
}

# Outbound rule: Allow all outbound traffic (default behavior)
resource "aws_vpc_security_group_egress_rule" "web_all" {
  security_group_id = aws_security_group.web.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"  # -1 means "all protocols"

  description = "Allow all outbound traffic"
}

# -----------------------------------------------------------------------------
# Security Group: App Tier
# -----------------------------------------------------------------------------
# More restrictive: only allows traffic from the web tier.
# This follows the principle of least privilege.

resource "aws_security_group" "app" {
  name        = "app-sg"
  description = "Allow traffic only from web tier"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "app-sg"
    Tier = "app"
  }
}

# Inbound rule: Allow app port only from web security group
# This is SG-to-SG communication, not CIDR-based
resource "aws_vpc_security_group_ingress_rule" "app_from_web" {
  security_group_id = aws_security_group.app.id

  referenced_security_group_id = aws_security_group.web.id
  from_port                   = 8080
  ip_protocol                  = "tcp"
  to_port                     = 8080

  description = "Allow traffic from web tier only"
}

# Outbound rule: Allow all outbound
resource "aws_vpc_security_group_egress_rule" "app_all" {
  security_group_id = aws_security_group.app.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"

  description = "Allow all outbound traffic"
}

# -----------------------------------------------------------------------------
# Network ACL (Optional - Additional Security Layer)
# -----------------------------------------------------------------------------
# NACLs are stateless firewalls at the SUBNET level.
# They're less commonly used than SGs but provide defense-in-depth.

resource "aws_network_acl" "public" {
  vpc_id     = aws_vpc.main.id
  subnet_ids = [aws_subnet.public.id]

  tags = {
    Name = "public-nacl"
  }
}

# NACL Ingress rules (order matters!)
resource "aws_network_acl_rule" "public_in_http" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 100
  egress         = false
  protocol       = "tcp"
  from_port      = 80
  to_port        = 80
  cidr_block     = "0.0.0.0/0"
  rule_action    = "allow"
}

resource "aws_network_acl_rule" "public_in_https" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 110
  egress         = false
  protocol       = "tcp"
  from_port      = 443
  to_port        = 443
  cidr_block     = "0.0.0.0/0"
  rule_action    = "allow"
}

# NACL Egress rules (must allow return traffic too!)
resource "aws_network_acl_rule" "public_out_all" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 100
  egress         = true
  protocol       = "-1"
  from_port      = 0
  to_port        = 0
  cidr_block     = "0.0.0.0/0"
  rule_action    = "allow"
}

# -----------------------------------------------------------------------------
# Outputs
# -----------------------------------------------------------------------------
output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "VPC CIDR block"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_id" {
  description = "Public subnet ID"
  value       = aws_subnet.public.id
}

output "private_subnet_id" {
  description = "Private subnet ID"
  value       = aws_subnet.private.id
}

output "internet_gateway_id" {
  description = "Internet Gateway ID"
  value       = aws_internet_gateway.gw.id
}

output "web_security_group_id" {
  description = "Web tier security group ID"
  value       = aws_security_group.web.id
}

output "app_security_group_id" {
  description = "App tier security group ID"
  value       = aws_security_group.app.id
}

# -----------------------------------------------------------------------------
# Key Takeaways
# -----------------------------------------------------------------------------
# 1. **VPC**: Your isolated network in the cloud (like a virtual data center)
# 2. **Subnets**: Divide VPC into segments (public vs private)
# 3. **Internet Gateway**: VPC's door to the internet
# 4. **Route Tables**: Control traffic flow between subnets and internet
# 5. **Security Groups**: Stateful firewalls at instance level
#    - Inbound rules are explicitly defined
#    - Outbound traffic is automatically allowed for related requests
# 6. **NACLs**: Stateless firewalls at subnet level (defense-in-depth)
# 7. **Public Subnet**: Has route to IGW + map_public_ip_on_launch
# 8. **Private Subnet**: No IGW route, no public IPs, used for databases
# 9. **SG-to-SG References**: Use security_groups instead of cidr_blocks for internal traffic

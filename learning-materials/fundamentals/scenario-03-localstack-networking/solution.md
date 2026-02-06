# Solution: LocalStack - AWS Networking

## Complete main.tf

```hcl
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

# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "main-vpc"
    Environment = "dev"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main-igw"
  }
}

# Public Subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet"
    Type = "public"
  }
}

# Private Subnet
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block          = var.private_subnet_cidr
  availability_zone   = var.availability_zone

  tags = {
    Name = "private-subnet"
    Type = "private"
  }
}

# Route Table for Public Subnet
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "public-rt"
  }
}

# Route Table Association
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Security Group: Web Tier
resource "aws_security_group" "web" {
  name        = "web-sg"
  description = "Allow HTTP/HTTPS inbound"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "web-sg"
    Tier = "web"
  }
}

# Security Group: App Tier
resource "aws_security_group" "app" {
  name        = "app-sg"
  description = "Application tier - only from web SG"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Allow from web tier"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "app-sg"
    Tier = "app"
  }
}

# Outputs
output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "public_subnet_id" {
  description = "Public subnet ID"
  value       = aws_subnet.public.id
}

output "private_subnet_id" {
  description = "Private subnet ID"
  value       = aws_subnet.private.id
}

output "web_security_group_id" {
  description = "Web security group ID"
  value       = aws_security_group.web.id
}

output "app_security_group_id" {
  description = "App security group ID"
  value       = aws_security_group.app.id
}

output "internet_gateway_id" {
  description = "Internet Gateway ID"
  value       = aws_internet_gateway.gw.id
}
```

---

## Explanation

### VPC Configuration
- CIDR block `10.0.0.0/16` provides 65,536 IP addresses
- DNS enabled for hostname resolution and DNS support
- Tags for identification

### Internet Gateway
- Single gateway attached to VPC
- Enables internet traffic in/out of VPC

### Subnets
- **Public subnet**: Auto-assigns public IPs, has route to IGW
- **Private subnet**: No public IP assignment, no direct internet route

### Route Table
- Default route (`0.0.0.0/0`) sends traffic to Internet Gateway
- Associated only with public subnet
- Private subnet has no explicit association → uses main route table (no IGW route)

### Security Groups
- **Web SG**: Allows HTTP/HTTPS from anywhere
- **App SG**: Only allows traffic from instances with Web SG
- Both allow all outbound traffic
- Stateful: return traffic automatically allowed

---

## Testing

```bash
# Start LocalStack
docker run --rm -it -p 4566:4566 -p 4510-4559:4510-4559 \
  -e SERVICES=ec2,iam \
  -e DEBUG=1 \
  localstack/localstack:latest

# Initialize
terraform init

# Plan
terraform plan

# Apply
terraform apply -auto-approve

# Verify VPC
aws --endpoint-url=http://localhost:4566 ec2 describe-vpcs

# Verify subnets
aws --endpoint-url=http://localhost:4566 ec2 describe-subnets

# Verify security groups
aws --endpoint-url=http://localhost:4566 ec2 describe-security-groups

# Check outputs
terraform output vpc_id
terraform output public_subnet_id
terraform output web_security_group_id

# Cleanup
terraform destroy -auto-approve
```

---

## Key Concepts Demonstrated

| Concept | How It's Shown |
|---------|----------------|
| VPC Creation | aws_vpc with CIDR block and DNS settings |
| Internet Gateway | aws_internet_gateway attached to VPC |
| Public Subnet | aws_subnet with map_public_ip_on_launch |
| Private Subnet | aws_subnet without public IP setting |
| Route Tables | aws_route_table with default route to IGW |
| Route Association | aws_route_table_association linking subnet to route table |
| Security Groups | Stateful firewall with ingress/egress rules |
| SG-to-SG References | security_groups parameter for restricted access |

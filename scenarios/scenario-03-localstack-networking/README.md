# Scenario 3: LocalStack - AWS Networking

## Prerequisites

**Skills needed before starting:**
- ✅ Scenario 01: Docker Provider (Terraform basics)
- ✅ Scenario 02: LocalStack AWS Fundamentals (provider configuration)
- Basic understanding of networking concepts (IP addresses, subnets, routing)
- Understanding of security fundamentals (firewalls, access control)

**You will learn:**
- VPC (Virtual Private Cloud) fundamentals
- Subnet segmentation (public vs private)
- Security Groups as stateful firewalls
- Route tables and internet gateways
- Network isolation patterns

**Tools required:**
- Docker Desktop running locally
- Terraform 1.x installed
- AWS CLI (optional, for verification)
- LocalStack (will run via Docker)

---

## Learning Objectives

- Create VPC (Virtual Private Cloud)
- Configure subnets (public and private)
- Set up security groups and firewall rules
- Understand route tables and internet gateways
- Learn network isolation and segmentation

> **⚠️ Free Tier Note:** VPC, subnets, security groups, and route tables are fully supported in LocalStack Community. However, launching actual EC2 instances requires LocalStack Pro. This scenario focuses on the networking infrastructure itself, which works perfectly in the free tier.

## Requirements

Build a secure multi-tier network architecture:

```
                    ┌─────────────────────────────┐
                    │         Internet             │
                    └──────────────┬──────────────┘
                                   │
                                   │ Internet Gateway
                                   │
                    ┌──────────────▼──────────────┐
                    │         Public Subnet        │
                    │   (10.0.1.0/24)              │
                    │  ┌─────────────────────┐   │
                    │  │   Security Group    │   │
                    │  │   (Web Tier)        │   │
                    │  │   HTTP: 80          │   │
                    │  │   HTTPS: 443        │   │
                    │  └─────────────────────┘   │
                    └──────────────┬──────────────┘
                                   │
                    ┌──────────────▼──────────────┐
                    │       Private Subnet        │
                    │   (10.0.2.0/24)              │
                    │  ┌─────────────────────┐   │
                    │  │   Security Group    │   │
                    │  │   (App Tier)        │   │
                    │  │   No inbound        │   │
                    │  │   from internet     │   │
                    │  └─────────────────────┘   │
                    └─────────────────────────────┘
```

### Resources to Create

1. **VPC**: `aws_vpc` with CIDR `10.0.0.0/16`
2. **Internet Gateway**: `aws_internet_gateway` attached to VPC
3. **Public Subnet**: `10.0.1.0/24` in us-east-1a
4. **Private Subnet**: `10.0.2.0/24` in us-east-1a
5. **Route Table**: Public subnet routes to internet gateway
6. **Route Table Association**: Connect public subnet to route table
7. **Security Group (Web)**: Allows HTTP/HTTPS from anywhere
8. **Security Group (App)**: Allows traffic only from web SG
9. **Network ACL**: Additional layer of security (optional)

### Security Group Rules

| Security Group | Rule | Direction | Protocol | Port Range | Source |
|----------------|------|----------|----------|------------|--------|
| **Web** | Inbound | Ingress | TCP | 80 | 0.0.0.0/0 |
| **Web** | Inbound | Ingress | TCP | 443 | 0.0.0.0/0 |
| **Web** | Outbound | Egress | All | All | 0.0.0.0/0 |
| **App** | Inbound | Ingress | TCP | 8080 | Web SG ID |
| **App** | Outbound | Egress | All | All | 0.0.0.0/0 |

### Variables to Use

| Variable | Default | Description |
|----------|---------|-------------|
| `vpc_cidr` | "10.0.0.0/16" | VPC CIDR block |
| `public_subnet_cidr` | "10.0.1.0/24" | Public subnet CIDR |
| `private_subnet_cidr` | "10.0.2.0/24" | Private subnet CIDR |
| `availability_zone` | "us-east-1a" | Availability zone |

## Your Task

Create `main.tf` in this directory with:

1. AWS provider configured for LocalStack
2. VPC with DNS enabled and DNS hostnames enabled
3. Internet Gateway attached to VPC
4. Public subnet with auto-assign public IP
5. Private subnet without public IP
6. Route table with default route (0.0.0.0/0) to internet gateway
7. Route table association for public subnet
8. Security group for web tier (HTTP/HTTPS inbound)
9. Security group for app tier (restrictive ingress)
10. Outputs showing VPC ID, subnet IDs, and security group IDs

## Testing Your Work

```bash
# Start LocalStack with networking services
docker run --rm -it -p 4566:4566 -p 4510-4559:4510-4559 \
  -e SERVICES=ec2,iam,lambda \
  -e DEBUG=1 \
  localstack/localstack:latest

# Initialize and apply
terraform init
terraform plan
terraform apply

# Verify VPC was created
aws --endpoint-url=http://localhost:4566 ec2 describe-vpcs

# Verify subnets
aws --endpoint-url=http://localhost:4566 ec2 describe-subnets

# Verify security groups
aws --endpoint-url=http://localhost:4566 ec2 describe-security-groups

# Check outputs
terraform output vpc_id
terraform output public_subnet_id
terraform output web_sg_id

# Clean up
terraform destroy
```

## Expected Results

When you run `terraform apply`, you should see:
- 8 resources created (VPC, IGW, 2 subnets, route table, association, 2 SGs)
- VPC with enabled DNS
- Public subnet can reach internet (via route to IGW)
- Private subnet has no direct internet access
- Security groups properly restrict traffic

## What You're Learning

| Concept | Why It Matters |
|---------|----------------|
| **VPC** | Network isolation = security boundary |
| **Subnets** | Segment network = public vs private resources |
| **Route Tables** | Control traffic flow between subnets/internet |
| **Security Groups** | Stateful firewall = instance-level security |
| **NACLs** | Stateless firewall = subnet-level security |
| **CIDR Notation** | IP address ranges = fundamental networking |

## Key Concepts

### Public vs Private Subnets

**Public Subnet:**
- Has route to Internet Gateway
- Instances get public IP addresses
- Can send/receive traffic from internet

**Private Subnet:**
- No direct route to internet
- Instances have only private IPs
- Can access internet via NAT Gateway (not in this scenario)
- Used for databases, backend services

### Security Group Rules

```hcl
# Allow HTTP from anywhere
ingress {
  description     = "Allow HTTP"
  from_port       = 80
  to_port         = 80
  protocol        = "tcp"
  cidr_blocks     = ["0.0.0.0/0"]
}

# Allow all outbound traffic
egress {
  description     = "Allow all outbound"
  from_port       = 0
  to_port         = 0
  protocol        = "-1"  # -1 = all protocols
  cidr_blocks     = ["0.0.0.0/0"]
}
```

### Security Group References

To reference another security group (for SG-to-SG communication):

```hcl
# Reference another SG instead of CIDR
security_groups = [aws_security_group.web.id]
```

This allows traffic from instances in the web SG to instances in the app SG.

## Hints

<details>
<summary>Hint 1: VPC Configuration</summary>

```hcl
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "main-vpc"
    Environment = "dev"
  }
}
```

</details>

<details>
<summary>Hint 2: Internet Gateway & Route Table</summary>

```hcl
# Internet Gateway - must be attached to VPC
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main-igw"
  }
}

# Route table for public subnet
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

# Associate route table with public subnet
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}
```

</details>

<details>
<summary>Hint 3: Subnet Configuration</summary>

```hcl
# Public subnet - instances get public IPs
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = var.availability_zone

  # This is what makes it "public"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet"
    Type = "public"
  }
}

# Private subnet - no public IPs
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block          = var.private_subnet_cidr
  availability_zone   = var.availability_zone

  tags = {
    Name = "private-subnet"
    Type = "private"
  }
}
```

</details>

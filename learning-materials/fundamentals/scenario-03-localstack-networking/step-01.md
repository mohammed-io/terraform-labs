# Step 1: VPC, Internet Gateway, and Subnets

## VPC Resource

A VPC (Virtual Private Cloud) is an isolated network environment:

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

**Key settings:**
- `cidr_block`: The IP range for your VPC (e.g., `10.0.0.0/16` = 65,536 IPs)
- `enable_dns_hostnames`: Instances get DNS names
- `enable_dns_support`: VPC has DNS resolution

## Internet Gateway

An Internet Gateway allows traffic between your VPC and the internet:

```hcl
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main-igw"
  }
}
```

**Important:** Only ONE internet gateway per VPC. It's the door to the internet.

## Subnets

Subnets segment your VPC into smaller networks:

### Public Subnet

```hcl
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
```

### Private Subnet

```hcl
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

**What makes a subnet public or private?**
- **Public**: Has `map_public_ip_on_launch = true` AND a route to an Internet Gateway
- **Private**: No route to Internet Gateway (or routes through NAT Gateway only)

## CIDR Notation Refresher

| CIDR | Usable IPs | Use Case |
|------|------------|----------|
| `10.0.0.0/16` | ~65,000 | Entire VPC |
| `10.0.1.0/24` | ~250 | Subnet |
| `10.0.2.0/24` | ~250 | Subnet |
| `10.0.0.0/28` | ~14 | Small subnet |

## Your Task

1. Create a VPC with `10.0.0.0/16` CIDR and DNS enabled
2. Create an Internet Gateway attached to the VPC
3. Create a public subnet (`10.0.1.0/24`) with auto-assign public IP
4. Create a private subnet (`10.0.2.0/24`) without public IP

## Quick Check

Test your understanding:

1. What's the difference between `enable_dns_hostnames` and `enable_dns_support`? (enable_dns_support enables DNS resolution in the VPC; enable_dns_hostnames gives instances public DNS hostnames)

2. Why can you only have one Internet Gateway per VPC? (The Internet Gateway is a single point of egress/ingress for the entire VPC - having more than one would create routing ambiguity)

3. What does `map_public_ip_on_launch = true` do? (Automatically assigns a public IP address to any instance launched in this subnet)

4. What makes a subnet "private" if both public and private subnets are in the same VPC? (A private subnet has no route to the Internet Gateway in its route table - or routes through a NAT Gateway)

5. How many usable IPs are in a /24 subnet? (256 total IPs - 5 reserved = 251 usable IPs for AWS subnets)

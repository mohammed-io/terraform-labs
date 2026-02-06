---
name: "LocalStack - AWS Networking"
category: "fundamentals"
difficulty: "intermediate"
time: "45 minutes"
services: ["vpc", "ec2"]
concepts: ["vpc", "subnets", "route-tables", "security-groups", "internet-gateway"]
---

# LocalStack - AWS Networking

## Scenario

You're building the networking foundation for a multi-tier web application. You need to create a VPC with public and private subnets, proper routing, and security groups that follow security best practices.

## Architecture

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

## Requirements

Build a secure multi-tier network:

1. **VPC**: `10.0.0.0/16` with DNS enabled
2. **Internet Gateway**: Attached to VPC
3. **Public Subnet**: `10.0.1.0/24` in us-east-1a, auto-assign public IP
4. **Private Subnet**: `10.0.2.0/24` in us-east-1a, no public IP
5. **Route Table**: Public subnet routes to internet gateway
6. **Route Table Association**: Connect public subnet to route table
7. **Security Group (Web)**: Allows HTTP/HTTPS from anywhere
8. **Security Group (App)**: Allows traffic only from web SG

## Constraints

- VPC must have DNS support and DNS hostnames enabled
- Public subnet must have `map_public_ip_on_launch = true`
- Private subnet should NOT have direct internet access
- Web security group allows HTTP (80) and HTTPS (443) from 0.0.0.0/0
- App security group only allows inbound from web security group

## Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `vpc_cidr` | "10.0.0.0/16" | VPC CIDR block |
| `public_subnet_cidr` | "10.0.1.0/24" | Public subnet CIDR |
| `private_subnet_cidr` | "10.0.2.0/24" | Private subnet CIDR |
| `availability_zone` | "us-east-1a" | Availability zone |

## Prerequisites

- Complete scenario-01-docker and scenario-02-localstack-basics
- Docker Desktop running
- Terraform 1.x installed
- Understanding of basic networking (IP addresses, subnets)

## What You'll Learn

| Concept | Why It Matters |
|---------|----------------|
| **VPC** | Network isolation = security boundary |
| **Subnets** | Segment network = public vs private resources |
| **Route Tables** | Control traffic flow between subnets/internet |
| **Security Groups** | Stateful firewall = instance-level security |
| **CIDR Notation** | IP address ranges = fundamental networking |

## Getting Started

1. Make sure LocalStack is running:
   ```bash
   docker run --rm -it -p 4566:4566 -p 4510-4559:4510-4559 \
     -e SERVICES=ec2,iam \
     -e DEBUG=1 \
     localstack/localstack:latest
   ```

2. Navigate to the lab directory and start building!

3. Check `step-01.md` for hints on VPC, Internet Gateway, and Subnets.

4. Check `step-02.md` for hints on Route Tables and Security Groups.

## Verification

Run the lab's `verify.sh` script to check your work:

```bash
cd lab
bash verify.sh
```

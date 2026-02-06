# Custom VPC Module

A reusable Terraform module for creating a complete AWS VPC with public, private, and database subnets.

## Features

- **VPC** with configurable CIDR block
- **Internet Gateway** for public internet access
- **Public Subnets** for internet-facing resources (ALB, bastion)
- **Private Subnets** for application servers
- **Database Subnets** for isolated data tier
- **NAT Gateway** (optional) for private subnet outbound internet
- **Route Tables** with proper routing
- **VPC Flow Logs** (optional) for network monitoring

## Usage

```hcl
module "vpc" {
  source = "../../modules/custom/vpc"

  name = "production-vpc"
  cidr = "10.0.0.0/16"

  availability_zones = ["us-east-1a", "us-east-1b"]

  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24"]
  database_subnet_cidrs = ["10.0.20.0/24", "10.0.21.0/24"]

  enable_nat_gateway = true
  enable_dns_hostnames = true
  enable_dns_support = true

  tags = {
    Environment = "production"
    Project     = "my-app"
  }
}
```

## Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `name` | VPC name | string | required |
| `cidr` | VPC CIDR block | string | "10.0.0.0/16" |
| `availability_zones` | AZ list | list(string) | [] |
| `public_subnet_cidrs` | Public subnet CIDRs | list(string) | ["10.0.1.0/24", "10.0.2.0/24"] |
| `private_subnet_cidrs` | Private subnet CIDRs | list(string) | ["10.0.10.0/24", "10.0.11.0/24"] |
| `database_subnet_cidrs` | Database subnet CIDRs | list(string) | ["10.0.20.0/24", "10.0.21.0/24"] |
| `enable_nat_gateway` | Enable NAT Gateway | bool | false |
| `enable_dns_hostnames` | Enable DNS hostnames | bool | true |
| `enable_dns_support` | Enable DNS support | bool | true |
| `tags` | Common tags | map(string) | {} |

## Outputs

| Name | Description |
|------|-------------|
| `vpc_id` | VPC ID |
| `vpc_cidr` | VPC CIDR block |
| `internet_gateway_id` | Internet Gateway ID |
| `public_subnet_ids` | List of public subnet IDs |
| `private_subnet_ids` | List of private subnet IDs |
| `database_subnet_ids` | List of database subnet IDs |
| `nat_gateway_id` | NAT Gateway ID (if enabled) |

## Architecture

```
                    Internet
                       │
                       │
              ┌────────┴────────┐
              │  Internet       │
              │  Gateway        │
              └────────┬────────┘
                       │
         ┌─────────────┴─────────────┐
         │                           │
    ┌────▼─────┐              ┌─────▼────┐
    │  Public  │              │   NAT    │
    │ Subnet   │              │ Gateway  │
    │ (10.0.1) │              └─────┬────┘
    └──────────┘                    │
                                    │
                           ┌────────┴────────┐
                    ┌──────▼──────┐  ┌──────▼──────┐
                    │   Private   │  │  Database   │
                    │   Subnet    │  │   Subnet    │
                    │  (10.0.10)  │  │  (10.0.20)  │
                    └─────────────┘  └─────────────┘
```

## Security Considerations

1. **Public Subnets**: Have routes to Internet Gateway, instances get public IPs
2. **Private Subnets**: No direct internet access, use NAT Gateway for outbound
3. **Database Subnets**: Isolated, no internet access even with NAT
4. **Security Groups**: Apply separately to control instance-level traffic

## Cost Warnings

- **NAT Gateway**: ~$0.045/hour + data processing charges (~$32/month minimum)
- **Flow Logs**: CloudWatch Logs charges apply
- **Internet Gateway**: Free, but data transfer charges apply

## Examples

See `examples/` directory for complete usage examples.

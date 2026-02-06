# Terraform Registry Modules

This directory contains examples and documentation for using modules from the [Terraform Registry](https://registry.terraform.io/).

## What is the Terraform Registry?

The Terraform Registry is a public repository of Terraform modules maintained by:
- HashiCorp (official)
- Community contributors
- Cloud providers (AWS, Azure, GCP, etc.)

## Why Use Registry Modules?

| Benefit | Description |
|---------|-------------|
| **Tested** | Peer-reviewed and battle-tested |
| **Updated** | Regular updates for new features |
| **Documented** | Comprehensive documentation |
| **Best Practices** | Follow cloud provider recommendations |
| **Time Saving** | Don't reinvent the wheel |

## Popular AWS Registry Modules

### VPC Module
```hcl
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.2"

  name = "my-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = true
  enable_vpn_gateway = false

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}
```

### EC2 Instance Module
```hcl
module "ec2_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "5.2.1"

  name           = "my-instance"
  instance_count = 1

  ami                    = "ami-0c55b159cbfafe1f0"
  instance_type          = "t3.micro"
  key_name               = "my-key"
  monitoring            = true
  vpc_security_group_ids = ["sg-12345678"]
  subnet_id             = "subnet-12345678"

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}
```

### RDS Module
```hcl
module "db" {
  source  = "terraform-aws-modules/rds/aws"
  version = "6.2.0"

  identifier = "demodb"

  engine            = "postgres"
  engine_version    = "15.3"
  instance_class    = "db.t3.micro"
  allocated_storage = 20

  db_name  = "mydb"
  username = "admin"
  port     = 5432

  multi_az               = true
  db_subnet_group_name   = "my-db-subnet-group"
  vpc_security_group_ids = ["sg-12345678"]

  backup_retention_period = 7
  skip_final_snapshot    = true

  tags = {
    Owner       = "user"
    Environment = "dev"
  }
}
```

### EKS Module
```hcl
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.17.2"

  cluster_name    = "my-cluster"
  cluster_version = "1.27"

  vpc_id     = "vpc-12345678"
  subnet_ids = ["subnet-12345", "subnet-67890"]

  eks_managed_node_groups = {
    general = {
      desired_size = 2
      min_size     = 1
      max_size     = 3

      instance_types = ["t3.small"]
      capacity_type  = "ON_DEMAND"
    }
  }

  tags = {
    Environment = "dev"
  }
}
```

### S3 Bucket Module
```hcl
module "s3_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "3.3.0"

  bucket = "my-s3-bucket"

  acl    = "private"
  versioning = true

  tags = {
    Environment = "dev"
  }
}
```

### Security Group Module
```hcl
module "security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.1.0"

  name        = "my-security-group"
  description = "Security group for my application"
  vpc_id      = "vpc-12345678"

  ingress_with_cidr_blocks = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      description = "HTTP"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      description = "HTTPS"
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = "0.0.0.0/0"
    }
  ]
}
```

## Finding Modules

1. Visit https://registry.terraform.io/
2. Browse by provider (AWS, Azure, GCP, etc.)
3. Check module stats:
   - Downloads (popularity)
   - Latest version (active maintenance)
   - Provider (official vs community)

## Version Pinning

```hcl
# Exact version (most restrictive)
version = "5.1.2"

# Minimum version (allows upgrades)
version = ">= 5.1.0"

# Allow minor/patch updates (recommended)
version = "~> 5.1"   # Allows 5.1.x, not 5.2.0+

# Allow any minor version (rarely used)
version = "~> 5"     # Allows 5.x.x, not 6.0.0+
```

## Module Sources

```hcl
# Terraform Registry
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.2"
}

# GitHub
module "vpc" {
  source = "github.com/terraform-aws-modules/terraform-aws-vpc"
}

# Git (HTTPS)
module "vpc" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-vpc.git?ref=v5.1.2"
}

# Git (SSH)
module "vpc" {
  source = "git@github.com:terraform-aws-modules/terraform-aws-vpc.git?ref=v5.1.2"
}

# Local path
module "vpc" {
  source = "../../modules/custom/vpc"
}
```

## Best Practices

1. **Always pin versions** - Prevents unexpected breaking changes
2. **Check documentation** - Read inputs/outputs before using
3. **Review examples** - Most modules have example folders
4. **Test in dev first** - Verify behavior before production
5. **Update regularly** - Stay current with security fixes

## Updating Modules

```bash
# Check for newer versions
terraform init -upgrade

# Update specific module
terraform apply -upgrade

# Lock to specific version
version = "= 5.1.2"  # Exact match only
```

## Reference Architecture

The Terraform AWS Modules team maintains a complete reference architecture:

```hcl
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.2"
  # ...
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.17.2"
  # ...
  vpc_id = module.vpc.vpc_id
  # ...
}

module "rds" {
  source  = "terraform-aws-modules/rds/aws"
  version = "6.2.0"
  # ...
}
```

## Useful Links

- [Terraform Registry](https://registry.terraform.io/)
- [Terraform AWS Modules](https://github.com/terraform-aws-modules)
- [Module Development Guide](https://developer.hashicorp.com/terraform/language/modules/develop)
- [Registry Publishing](https://developer.hashicorp.com/terraform/registry/modules/publish)

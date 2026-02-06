# Solution: The Stack Pattern

## Stack 1: Networking (01-networking/)

### main.tf

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

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  default = ["10.0.10.0/24", "10.0.11.0/24"]
}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "stack-vpc"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "stack-igw"
  }
}

resource "aws_subnet" "public" {
  count             = length(var.public_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_subnet_cidrs[count.index]
  availability_zone = "us-east-1a"

  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-${count.index}"
  }
}

resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = "us-east-1a"

  tags = {
    Name = "private-subnet-${count.index}"
  }
}

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

resource "aws_route_table_association" "public" {
  count          = length(var.public_subnet_cidrs)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "web" {
  name        = "web-sg"
  description = "Web tier security group"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "web-sg"
  }
}

resource "aws_security_group" "app" {
  name        = "app-sg"
  description = "App tier security group"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "app-sg"
  }
}
```

### outputs.tf

```hcl
output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}

output "web_security_group_id" {
  value = aws_security_group.web.id
}

output "app_security_group_id" {
  value = aws_security_group.app.id
}
```

---

## Stack 2: Database (02-database/)

### main.tf

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
    dynamodb = "http://localhost:4566"
  }

  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id   = true
}

data "terraform_remote_state" "networking" {
  backend = "local"

  config = {
    path = "${path.module}/../01-networking/terraform.tfstate"
  }
}

resource "aws_dynamodb_table" "users" {
  name           = "users-table"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "user_id"

  attribute {
    name = "user_id"
    type = "S"
  }

  tags = {
    Environment = "dev"
    VPC_ID      = data.terraform_remote_state.networking.outputs.vpc_id
  }
}
```

### outputs.tf

```hcl
output "table_name" {
  value = aws_dynamodb_table.users.name
}

output "table_arn" {
  value = aws_dynamodb_table.users.arn
}
```

---

## Stack 3: Application (03-application/)

### main.tf

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
    ec2      = "http://localhost:4566"
    elb      = "http://localhost:4566"
    dynamodb = "http://localhost:4566"
  }

  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id   = true
}

data "terraform_remote_state" "networking" {
  backend = "local"

  config = {
    path = "${path.module}/../01-networking/terraform.tfstate"
  }
}

data "terraform_remote_state" "database" {
  backend = "local"

  config = {
    path = "${path.module}/../02-database/terraform.tfstate"
  }
}

resource "aws_lb" "app" {
  name               = "app-lb"
  internal           = false
  load_balancer_type = "application"

  subnets = data.terraform_remote_state.networking.outputs.public_subnet_ids

  security_groups = [
    data.terraform_remote_state.networking.outputs.web_security_group_id
  ]

  tags = {
    Environment = "dev"
  }
}
```

### outputs.tf

```hcl
output "load_balancer_arn" {
  value = aws_lb.app.arn
}

output "load_balancer_dns_name" {
  value = try(aws_lb.app.dns_name, "N/A in LocalStack")
}

output "application_url" {
  value = try("http://${aws_lb.app.dns_name}", "http://localhost:8080")
}
```

---

## Deployment

```bash
# Deploy in order
cd 01-networking
terraform init
terraform apply -auto-approve

cd ../02-database
terraform init
terraform apply -auto-approve

cd ../03-application
terraform init
terraform apply -auto-approve

# Destroy in reverse order
terraform destroy -auto-approve
cd ../02-database
terraform destroy -auto-approve
cd ../01-networking
terraform destroy -auto-approve
```

---

## Key Concepts Demonstrated

| Concept | How It's Shown |
|---------|----------------|
| Stack Pattern | Multiple directories with separate state |
| terraform_remote_state | Reading outputs from other stacks |
| Cross-Stack Dependencies | Stack 2 reads from Stack 1 |
| Deployment Order | Must deploy dependencies first |
| Outputs | Passing data between stacks |

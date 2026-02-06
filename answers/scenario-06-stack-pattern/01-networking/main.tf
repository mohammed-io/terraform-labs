# -----------------------------------------------------------------------------
# Stack 1: Networking
# -----------------------------------------------------------------------------
# This stack creates the foundational network infrastructure:
# - VPC
# - Public subnets (for load balancers)
# - Private subnets (for application servers)
# - Database subnets (isolated)
# - Internet Gateway
# - Security Groups (web, app, database)

# -----------------------------------------------------------------------------
# VPC
# -----------------------------------------------------------------------------
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.environment}-vpc"
    Environment = var.environment
    Stack       = "01-networking"
  }
}

# -----------------------------------------------------------------------------
# Internet Gateway
# -----------------------------------------------------------------------------
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.environment}-igw"
    Environment = var.environment
    Stack       = "01-networking"
  }
}

# -----------------------------------------------------------------------------
# Public Subnets
# -----------------------------------------------------------------------------
# These subnets have direct internet access via the Internet Gateway.
# Used for: Load balancers, bastion hosts.

resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidrs)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.environment}-public-${count.index + 1}"
    Type        = "public"
    Environment = var.environment
    Stack       = "01-networking"
  }
}

# -----------------------------------------------------------------------------
# Private Subnets
# -----------------------------------------------------------------------------
# These subnets have no direct internet access.
# Used for: Application servers (ECS, Lambda).

resource "aws_subnet" "private" {
  count = length(var.private_subnet_cidrs)

  vpc_id            = aws_vpc.main.id
  cidr_block          = var.private_subnet_cidrs[count.index]
  availability_zone   = var.availability_zones[count.index]

  tags = {
    Name        = "${var.environment}-private-${count.index + 1}"
    Type        = "private"
    Environment = var.environment
    Stack       = "01-networking"
  }
}

# -----------------------------------------------------------------------------
# Database Subnets
# -----------------------------------------------------------------------------
# These subnets are isolated for databases.
# No internet access, even with NAT Gateway.

resource "aws_subnet" "database" {
  count = length(var.database_subnet_cidrs)

  vpc_id            = aws_vpc.main.id
  cidr_block          = var.database_subnet_cidrs[count.index]
  availability_zone   = var.availability_zones[count.index]

  tags = {
    Name        = "${var.environment}-database-${count.index + 1}"
    Type        = "database"
    Environment = var.environment
    Stack       = "01-networking"
  }
}

# -----------------------------------------------------------------------------
# Elastic IP for NAT Gateway (if enabled)
# -----------------------------------------------------------------------------
resource "aws_eip" "nat" {
  count = var.enable_nat_gateway ? 1 : 0

  domain = "vpc"

  tags = {
    Name        = "${var.environment}-nat-eip"
    Environment = var.environment
    Stack       = "01-networking"
  }

  depends_on = [aws_internet_gateway.main]
}

# -----------------------------------------------------------------------------
# NAT Gateway (if enabled)
# -----------------------------------------------------------------------------
# NOTE: Requires LocalStack Pro. Disabled by default for free tier.
resource "aws_nat_gateway" "main" {
  count = var.enable_nat_gateway ? 1 : 0

  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name        = "${var.environment}-nat"
    Environment = var.environment
    Stack       = "01-networking"
  }

  depends_on = [aws_internet_gateway.main]
}

# -----------------------------------------------------------------------------
# Route Tables
# -----------------------------------------------------------------------------

# Public route table - routes to Internet Gateway
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name        = "${var.environment}-public-rt"
    Environment = var.environment
    Stack       = "01-networking"
  }
}

# Private route table - routes to NAT Gateway (if enabled)
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  dynamic "route" {
    for_each = var.enable_nat_gateway ? [1] : []
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.main[0].id
    }
  }

  tags = {
    Name        = "${var.environment}-private-rt"
    Environment = var.environment
    Stack       = "01-networking"
  }
}

# Database route table - no internet route
resource "aws_route_table" "database" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.environment}-database-rt"
    Environment = var.environment
    Stack       = "01-networking"
  }
}

# -----------------------------------------------------------------------------
# Route Table Associations
# -----------------------------------------------------------------------------

resource "aws_route_table_association" "public" {
  count = length(var.public_subnet_cidrs)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count = length(var.private_subnet_cidrs)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "database" {
  count = length(var.database_subnet_cidrs)

  subnet_id      = aws_subnet.database[count.index].id
  route_table_id = aws_route_table.database.id
}

# -----------------------------------------------------------------------------
# Security Groups
# -----------------------------------------------------------------------------

# Web security group - for load balancers
resource "aws_security_group" "web" {
  name        = "${var.environment}-web-sg"
  description = "Security group for web tier (load balancers)"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name        = "${var.environment}-web-sg"
    Tier        = "web"
    Environment = var.environment
    Stack       = "01-networking"
  }
}

# Allow HTTP from anywhere
resource "aws_vpc_security_group_ingress_rule" "web_http" {
  security_group_id = aws_security_group.web.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

# Allow HTTPS from anywhere
resource "aws_vpc_security_group_ingress_rule" "web_https" {
  security_group_id = aws_security_group.web.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

# Allow all outbound
resource "aws_vpc_security_group_egress_rule" "web_all" {
  security_group_id = aws_security_group.web.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# App security group - for application servers
resource "aws_security_group" "app" {
  name        = "${var.environment}-app-sg"
  description = "Security group for application tier"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name        = "${var.environment}-app-sg"
    Tier        = "app"
    Environment = var.environment
    Stack       = "01-networking"
  }
}

# Allow traffic from web tier
resource "aws_vpc_security_group_ingress_rule" "app_from_web" {
  security_group_id              = aws_security_group.app.id
  referenced_security_group_id   = aws_security_group.web.id
  from_port                     = 8080
  ip_protocol                   = "tcp"
  to_port                       = 8080
}

# Allow all outbound
resource "aws_vpc_security_group_egress_rule" "app_all" {
  security_group_id = aws_security_group.app.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# Database security group - for databases
resource "aws_security_group" "database" {
  name        = "${var.environment}-database-sg"
  description = "Security group for database tier"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name        = "${var.environment}-database-sg"
    Tier        = "database"
    Environment = var.environment
    Stack       = "01-networking"
  }
}

# Allow traffic from app tier only
resource "aws_vpc_security_group_ingress_rule" "database_from_app" {
  security_group_id              = aws_security_group.database.id
  referenced_security_group_id   = aws_security_group.app.id
  from_port                     = 5432
  ip_protocol                   = "tcp"
  to_port                       = 5432
}

# Allow all outbound (for backups, etc.)
resource "aws_vpc_security_group_egress_rule" "database_all" {
  security_group_id = aws_security_group.database.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

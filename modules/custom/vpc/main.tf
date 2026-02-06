# -----------------------------------------------------------------------------
# Custom VPC Module
# -----------------------------------------------------------------------------
# This module creates a complete VPC with public, private, and database subnets.
# It's designed for learning and can be used in any AWS project.

# -----------------------------------------------------------------------------
# VPC Resource
# -----------------------------------------------------------------------------
# The Virtual Private Cloud - your isolated network in AWS.

resource "aws_vpc" "this" {
  cidr_block           = var.cidr
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support

  tags = merge(
    {
      Name = var.name
    },
    var.tags
  )
}

# -----------------------------------------------------------------------------
# Internet Gateway
# -----------------------------------------------------------------------------
# Enables internet communication for resources in public subnets.

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(
    {
      Name = "${var.name}-igw"
    },
    var.tags
  )
}

# -----------------------------------------------------------------------------
# Public Subnets
# -----------------------------------------------------------------------------
# Subnets that can reach the internet via the Internet Gateway.
# Resources here get public IP addresses.

resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidrs)

  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = length(var.availability_zones) > 0 ? var.availability_zones[count.index] : null

  map_public_ip_on_launch = true

  tags = merge(
    {
      Name = "${var.name}-public-${count.index + 1}"
      Type = "public"
    },
    var.tags
  )
}

# -----------------------------------------------------------------------------
# Private Subnets
# -----------------------------------------------------------------------------
# Subnets with no direct internet access.
# Used for application servers, backend services.

resource "aws_subnet" "private" {
  count = length(var.private_subnet_cidrs)

  vpc_id            = aws_vpc.this.id
  cidr_block          = var.private_subnet_cidrs[count.index]
  availability_zone   = length(var.availability_zones) > 0 ? var.availability_zones[count.index] : null

  tags = merge(
    {
      Name = "${var.name}-private-${count.index + 1}"
      Type = "private"
    },
    var.tags
  )
}

# -----------------------------------------------------------------------------
# Database Subnets
# -----------------------------------------------------------------------------
# Isolated subnets for databases.
# No internet access, additional security layer.

resource "aws_subnet" "database" {
  count = length(var.database_subnet_cidrs)

  vpc_id            = aws_vpc.this.id
  cidr_block          = var.database_subnet_cidrs[count.index]
  availability_zone   = length(var.availability_zones) > 0 ? var.availability_zones[count.index] : null

  tags = merge(
    {
      Name = "${var.name}-database-${count.index + 1}"
      Type = "database"
    },
    var.tags
  )
}

# -----------------------------------------------------------------------------
# NAT Gateway (Optional)
# -----------------------------------------------------------------------------
# Allows private subnets to initiate outbound internet connections.
# Note: Requires Elastic IP, adds cost.

resource "aws_eip" "nat" {
  count = var.enable_nat_gateway && length(var.public_subnet_cidrs) > 0 ? 1 : 0

  domain = "vpc"

  tags = merge(
    {
      Name = "${var.name}-nat-eip"
    },
    var.tags
  )

  depends_on = [aws_internet_gateway.this]
}

resource "aws_nat_gateway" "this" {
  count = var.enable_nat_gateway && length(var.public_subnet_cidrs) > 0 ? 1 : 0

  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public[0].id

  tags = merge(
    {
      Name = "${var.name}-nat"
    },
    var.tags
  )

  depends_on = [aws_internet_gateway.this]
}

# -----------------------------------------------------------------------------
# Route Tables
# -----------------------------------------------------------------------------
# Define how network traffic flows between subnets and external networks.

# Public route table - routes to Internet Gateway
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = merge(
    {
      Name = "${var.name}-public-rt"
    },
    var.tags
  )
}

# Private route table - routes to NAT Gateway (if enabled)
resource "aws_route_table" "private" {
  count = length(var.private_subnet_cidrs) > 0 ? 1 : 0

  vpc_id = aws_vpc.this.id

  dynamic "route" {
    for_each = var.enable_nat_gateway ? [1] : []
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.this[0].id
    }
  }

  tags = merge(
    {
      Name = "${var.name}-private-rt"
    },
    var.tags
  )
}

# Database route table - no internet route
resource "aws_route_table" "database" {
  count = length(var.database_subnet_cidrs) > 0 ? 1 : 0

  vpc_id = aws_vpc.this.id

  tags = merge(
    {
      Name = "${var.name}-database-rt"
    },
    var.tags
  )
}

# -----------------------------------------------------------------------------
# Route Table Associations
# -----------------------------------------------------------------------------
# Connect subnets to route tables.

resource "aws_route_table_association" "public" {
  count = length(var.public_subnet_cidrs)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count = length(var.private_subnet_cidrs)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[0].id
}

resource "aws_route_table_association" "database" {
  count = length(var.database_subnet_cidrs)

  subnet_id      = aws_subnet.database[count.index].id
  route_table_id = aws_route_table.database[0].id
}

# -----------------------------------------------------------------------------
# VPC Flow Logs (Optional)
# -----------------------------------------------------------------------------
# Capture information about IP traffic going to/from network interfaces.

resource "aws_flow_log" "this" {
  count = var.enable_flow_log ? 1 : 0

  log_destination_type = "cloud-watch-logs"
  log_destination      = var.flow_log_destination_arn
  traffic_type         = "ALL"
  vpc_id               = aws_vpc.this.id

  tags = var.tags
}

# -----------------------------------------------------------------------------
# Outputs - Custom VPC Module
# -----------------------------------------------------------------------------

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.this.id
}

output "vpc_cidr" {
  description = "VPC CIDR block"
  value       = aws_vpc.this.cidr_block
}

output "internet_gateway_id" {
  description = "Internet Gateway ID"
  value       = aws_internet_gateway.this.id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = aws_subnet.private[*].id
}

output "database_subnet_ids" {
  description = "List of database subnet IDs"
  value       = aws_subnet.database[*].id
}

output "public_route_table_id" {
  description = "Public route table ID"
  value       = aws_route_table.public.id
}

output "private_route_table_id" {
  description = "Private route table ID"
  value       = length(aws_route_table.private) > 0 ? aws_route_table.private[0].id : null
}

output "database_route_table_id" {
  description = "Database route table ID"
  value       = length(aws_route_table.database) > 0 ? aws_route_table.database[0].id : null
}

output "nat_gateway_id" {
  description = "NAT Gateway ID (if enabled)"
  value       = var.enable_nat_gateway ? aws_nat_gateway.this[0].id : null
}

output "nat_public_ip" {
  description = "NAT Gateway public IP (if enabled)"
  value       = var.enable_nat_gateway ? aws_eip.nat[0].public_ip : null
}

output "database_subnet_group" {
  description = "Database subnet group name (for RDS)"
  value       = "${var.name}-db-subnet-group"
}

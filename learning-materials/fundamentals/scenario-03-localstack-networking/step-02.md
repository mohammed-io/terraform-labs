# Step 2: Route Tables and Security Groups

## Route Tables

Route tables control where network traffic goes. Each subnet MUST be associated with a route table.

### Public Route Table

```hcl
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"  # All IPv4 traffic
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "public-rt"
  }
}
```

**The `0.0.0.0/0` route**: This is the "default route" - any traffic not matching more specific routes goes here (to the internet).

### Route Table Association

Connect a subnet to a route table:

```hcl
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}
```

**Note:** If you don't explicitly associate a subnet, it uses the VPC's "main" route table.

## Security Groups

Security groups are stateful firewalls that control INBOUND and OUTBOUND traffic at the instance level.

### Security Group Rules Format

```hcl
resource "aws_security_group" "web" {
  name        = "web-sg"
  description = "Allow HTTP/HTTPS inbound"
  vpc_id      = aws_vpc.main.id

  # Inbound rules
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

  # Outbound rules
  egress {
    description     = "Allow all outbound"
    from_port       = 0
    to_port         = 0
    protocol        = "-1"  # All protocols
    cidr_blocks     = ["0.0.0.0/0"]
  }

  tags = {
    Name = "web-sg"
  }
}
```

**Protocol values:**
- `"tcp"` - TCP protocol
- `"udp"` - UDP protocol
- `"-1"` or `"all"` - All protocols
- `"icmp"` - ICMP (ping)

### Security Group References

To allow traffic ONLY from another security group:

```hcl
resource "aws_security_group" "app" {
  name        = "app-sg"
  description = "Application tier - only from web SG"
  vpc_id      = aws_vpc.main.id

  # Only allow traffic from web security group
  ingress {
    description     = "Allow from web tier"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id]
  }

  # Outbound
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

**Why use `security_groups` instead of `cidr_blocks`?**
- `cidr_blocks = ["0.0.0.0/0"]`: Allow from ANYWHERE
- `security_groups = [web_sg.id]`: Allow ONLY from instances with that SG

## Stateful vs Stateless

**Security Groups are STATEFUL:**
- If you allow inbound port 80, outbound response is automatically allowed
- You don't need to explicitly allow return traffic

**NACLs are STATELESS:**
- You must explicitly allow both directions

## Your Task

1. Create a route table with a default route to the Internet Gateway
2. Associate the public subnet with this route table
3. Create a security group for the web tier (HTTP/HTTPS from anywhere)
4. Create a security group for the app tier (only from web SG)
5. Add outputs for VPC ID, subnet IDs, and security group IDs

## Quick Check

Test your understanding:

1. What does `cidr_block = "0.0.0.0/0"` mean in a route? (It's a catch-all route that matches any IPv4 address - essentially "send this traffic to the internet")

2. What's the difference between using `cidr_blocks` and `security_groups` in an ingress rule? (cidr_blocks allows traffic from an IP range; security_groups allows traffic only from instances that have that specific security group)

3. Why are security groups called "stateful"? (Return traffic is automatically allowed - if you allow inbound on port 80, the response on the same connection is allowed without an explicit rule)

4. What happens to a subnet that has no explicit route table association? (It uses the VPC's main route table, which is created automatically)

5. What does `protocol = "-1"` mean in a security group rule? (It means "all protocols" - TCP, UDP, ICMP, everything)

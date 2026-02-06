# -----------------------------------------------------------------------------
# Scenario 5: LocalStack - Full-Stack Architecture (Answer Key)
# -----------------------------------------------------------------------------

# This solution implements a complete 3-tier web application:
# - Uses custom VPC module
# - Uses registry RDS module
# - Data sources for dynamic values
# - Bastion host for SSH access
# - Application Load Balancer
# - Auto Scaling Group
# - S3 bucket for assets
# - Lambda function for background processing

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Note: In a real project, you'd use remote state:
  # backend "s3" {
  #   bucket         = "terraform-state"
  #   key            = "fullstack/terraform.tfstate"
  #   region         = "us-east-1"
  #   encrypt        = true
  #   dynamodb_table = "terraform-state-lock"
  # }
}

# -----------------------------------------------------------------------------
# Provider Configuration for LocalStack
# -----------------------------------------------------------------------------
provider "aws" {
  access_key = "test"
  secret_key = "test"
  region     = "us-east-1"

  endpoints {
    ec2             = "http://localhost:4566"
    elb             = "http://localhost:4566"
    rds             = "http://localhost:4566"
    s3              = "http://localhost:4566"
    lambda          = "http://localhost:4566"
    iam             = "http://localhost:4566"
    kms             = "http://localhost:4566"
    cloudwatch      = "http://localhost:4566"
    logs            = "http://localhost:4566"
    autoscaling     = "http://localhost:4566"
    ssm             = "http://localhost:4566"
  }

  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id   = true

  default_tags {
    tags = {
      Project     = "terraform-lab"
      ManagedBy   = "terraform"
    }
  }
}

# -----------------------------------------------------------------------------
# Variables
# -----------------------------------------------------------------------------
variable "environment" {
  description = "Environment name (dev/staging/prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "db_instance_class" {
  description = "Database instance size"
  type        = string
  default     = "t3.micro"
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "appdb"
}

variable "db_username" {
  description = "Database admin username"
  type        = string
  default     = "admin"
}

variable "app_min_size" {
  description = "Minimum app instances"
  type        = number
  default     = 2
}

variable "app_max_size" {
  description = "Maximum app instances"
  type        = number
  default     = 4
}

variable "app_desired_size" {
  description = "Desired app instances"
  type        = number
  default     = 2
}

variable "my_ip" {
  description = "Your IP address for SSH access (CIDR notation)"
  type        = string
  default     = "0.0.0.0/0"  # WARNING: In production, use your actual IP
}

variable "enable_bastion" {
  description = "Create bastion host for SSH access"
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# Locals
# -----------------------------------------------------------------------------
# Locals are like variables, but can include expressions.
# Good for: naming conventions, computed values, reducing repetition.

locals {
  name_prefix = "${var.environment}-fullstack"

  common_tags = {
    Environment = var.environment
    Project     = "terraform-lab"
  }
}

# -----------------------------------------------------------------------------
# Data Sources
# -----------------------------------------------------------------------------
# Data sources query existing resources or provider data.
# They're read-only: Terraform doesn't create/modify them.

# Get latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]  # Amazon's official AMIs

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Get available availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

# Get current caller identity
data "aws_caller_identity" "current" {}

# -----------------------------------------------------------------------------
# Custom VPC Module
# -----------------------------------------------------------------------------
# This would normally be in modules/custom/vpc/
# For this exercise, we'll define it inline but structured as a module.
# In production, create: modules/custom/vpc/main.tf

module "vpc" {
  source = "../../modules/custom/vpc"

  name               = "${local.name_prefix}-vpc"
  cidr               = var.vpc_cidr
  availability_zones = var.availability_zones

  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24"]
  database_subnet_cidrs = ["10.0.20.0/24", "10.0.21.0/24"]

  enable_nat_gateway = false  # Disable for LocalStack
  enable_dns_hostnames = true
  enable_dns_support = true

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# Security Groups
# -----------------------------------------------------------------------------
resource "aws_security_group" "bastion" {
  count = var.enable_bastion ? 1 : 0

  name        = "${local.name_prefix}-bastion"
  description = "Allow SSH from trusted IPs"
  vpc_id      = module.vpc.vpc_id

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-bastion" })
}

resource "aws_vpc_security_group_ingress_rule" "bastion_ssh" {
  count = var.enable_bastion ? 1 : 0

  security_group_id = aws_security_group.bastion[0].id
  cidr_ipv4         = var.my_ip
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_egress_rule" "bastion_all" {
  count = var.enable_bastion ? 1 : 0

  security_group_id = aws_security_group.bastion[0].id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# App tier security group
resource "aws_security_group" "app" {
  name        = "${local.name_prefix}-app"
  description = "Security group for application tier"
  vpc_id      = module.vpc.vpc_id

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-app" })
}

resource "aws_vpc_security_group_ingress_rule" "app_http" {
  security_group_id = aws_security_group.app.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "app_from_bastion" {
  count = var.enable_bastion ? 1 : 0

  security_group_id = aws_security_group.app.id
  referenced_security_group_id = aws_security_group.bastion[0].id
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_egress_rule" "app_all" {
  security_group_id = aws_security_group.app.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# Database security group
resource "aws_security_group" "database" {
  name        = "${local.name_prefix}-database"
  description = "Security group for database tier"
  vpc_id      = module.vpc.vpc_id

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-database" })
}

resource "aws_vpc_security_group_ingress_rule" "database_from_app" {
  security_group_id = aws_security_group.database.id
  referenced_security_group_id = aws_security_group.app.id
  from_port         = 5432
  ip_protocol       = "tcp"
  to_port           = 5432
}

# -----------------------------------------------------------------------------
# Bastion Host
# -----------------------------------------------------------------------------
# A bastion host provides secure SSH access to private resources.
# It sits in the public subnet but can reach private instances.

resource "aws_instance" "bastion" {
  count = var.enable_bastion ? 1 : 0

  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = "t3.micro"
  subnet_id              = module.vpc.public_subnet_ids[0]
  vpc_security_group_ids = [aws_security_group.bastion[0].id]

  # Enable SSM Session Manager (no need for SSH keys)
  # In real AWS, you'd use: aws ssm start-session --target <instance-id>

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-bastion"
  })
}

# -----------------------------------------------------------------------------
# Application Load Balancer
# -----------------------------------------------------------------------------
# ALB operates at Layer 7 (HTTP/HTTPS) and supports:
# - Path-based routing
# - Host-based routing
# - HTTP/HTTPS protocol
# - Health checks

resource "aws_lb" "app" {
  name               = "${local.name_prefix}-alb"
  internal           = false  # Internet-facing
  load_balancer_type = "application"
  security_groups    = [aws_security_group.app.id]
  subnets            = module.vpc.public_subnet_ids

  tags = local.common_tags
}

resource "aws_lb_target_group" "app" {
  name     = "${local.name_prefix}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = local.common_tags
}

resource "aws_lb_listener" "app_http" {
  load_balancer_arn = aws_lb.app.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

# -----------------------------------------------------------------------------
# Launch Template
# -----------------------------------------------------------------------------
# Launch templates define the configuration for EC2 instances.
# Used by: Auto Scaling Groups, Spot Fleet, EC2 Fleet.

resource "aws_launch_template" "app" {
  name_prefix   = "${local.name_prefix}-app-"
  image_id      = data.aws_ami.amazon_linux_2.id
  instance_type = "t3.micro"

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.app.id]
  }

  # User data script runs on instance boot
  user_data = base64encode(templatefile("${path.module}/user-data.sh", {
    db_host     = "db.example.com"  # Would use module output
    db_name     = var.db_name
    environment = var.environment
  }))

  tag_specifications {
    resource_type = "instance"

    tags = merge(local.common_tags, {
      Name = "${local.name_prefix}-app"
    })
  }
}

# -----------------------------------------------------------------------------
# Auto Scaling Group
# -----------------------------------------------------------------------------
# ASG automatically scales EC2 instances based on:
# - Schedule (time-based)
# - Demand (CPU, network, custom metrics)
# - Policies (target tracking, step scaling)

resource "aws_autoscaling_group" "app" {
  desired_capacity    = var.app_desired_size
  max_size           = var.app_max_size
  min_size           = var.app_min_size
  vpc_zone_identifier = module.vpc.private_subnet_ids

  target_group_arns = [aws_lb_target_group.app.arn]

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${local.name_prefix}-app"
    propagate_at_launch = true
  }

  # Prevent instances from being deleted during scale-in if they're unhealthy
  health_check_type = "EC2"
}

# CPU-based scaling policy
resource "aws_autoscaling_policy" "scale_cpu" {
  name                   = "${local.name_prefix}-scale-cpu"
  adjustment_type        = "ChangeInCapacity"
  autoscaling_group_name = aws_autoscaling_group.app.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value       = 70.0
    scale_in_cooldown  = 300
    scale_out_cooldown = 300
  }
}

# -----------------------------------------------------------------------------
# RDS PostgreSQL (simplified - in production, use registry module)
# -----------------------------------------------------------------------------
# Note: For LocalStack, RDS support may be limited.
# In real AWS, you'd use: terraform-aws-modules/rds/aws

resource "aws_db_instance" "main" {
  identifier        = "${local.name_prefix}-db"
  engine            = "postgres"
  engine_version    = "15.3"
  instance_class    = var.db_instance_class
  allocated_storage = 20

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.database.id]
  publicly_accessible    = false

  backup_retention_period = 7
  skip_final_snapshot    = true  # For testing
  multi_az               = false  # Disable for LocalStack

  tags = local.common_tags
}

resource "aws_db_subnet_group" "main" {
  name       = "${local.name_prefix}-db-subnet-group"
  subnet_ids = module.vpc.database_subnet_ids

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# S3 Buckets
# -----------------------------------------------------------------------------
resource "aws_s3_bucket" "assets" {
  bucket = "${local.name_prefix}-assets"

  tags = merge(local.common_tags, { Purpose = "static-assets" })
}

resource "aws_s3_bucket_versioning" "assets" {
  bucket = aws_s3_bucket.assets.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket" "logs" {
  bucket = "${local.name_prefix}-logs"

  tags = merge(local.common_tags, { Purpose = "application-logs" })
}

# Lifecycle rule for logs
resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    id     = "expire-old-logs"
    status = "Enabled"

    expiration {
      days = 90
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}

# -----------------------------------------------------------------------------
# Lambda Function
# -----------------------------------------------------------------------------
resource "aws_iam_role" "lambda" {
  name = "${local.name_prefix}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "processor" {
  function_name = "${local.name_prefix}-processor"
  role          = aws_iam_role.lambda.arn
  handler       = "index.handler"
  runtime       = "python3.11"

  filename = "${path.module}/lambda.zip"

  source_code_hash = filebase64sha256("${path.module}/lambda.zip")

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# CloudWatch Alarm
# -----------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "${local.name_prefix}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app.name
  }

  alarm_actions = []  # In real AWS, add SNS topic ARN
}

# -----------------------------------------------------------------------------
# Random Password (for demo - use proper secret management in prod)
# -----------------------------------------------------------------------------
resource "random_password" "db" {
  length  = 16
  special = true
}

resource "aws_secretsmanager_secret" "db" {
  name  = "${local.name_prefix}/db"
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id     = aws_secretsmanager_secret.db.id
  secret_string = jsonencode({
    username = var.db_username
    password = random_password.db.result
    host     = aws_db_instance.main.endpoint
    port     = 5432
    database = var.db_name
  })
}

# -----------------------------------------------------------------------------
# Outputs
# -----------------------------------------------------------------------------
output "environment" {
  description = "Environment"
  value       = var.environment
}

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "alb_dns_name" {
  description = "Load Balancer DNS name"
  value       = aws_lb.app.dns_name
}

output "alb_url" {
  description = "Load Balancer URL"
  value       = "http://${aws_lb.app.dns_name}"
}

output "db_endpoint" {
  description = "Database endpoint"
  value       = aws_db_instance.main.endpoint
  sensitive   = true
}

output "s3_assets_bucket" {
  description = "S3 assets bucket name"
  value       = aws_s3_bucket.assets.id
}

output "s3_logs_bucket" {
  description = "S3 logs bucket name"
  value       = aws_s3_bucket.logs.id
}

output "bastion_public_ip" {
  description = "Bastion host public IP"
  value       = var.enable_bastion ? aws_instance.bastion[0].public_ip : null
}

output "lambda_function_name" {
  description = "Lambda function name"
  value       = aws_lambda_function.processor.function_name
}

# -----------------------------------------------------------------------------
# Key Takeaways
# -----------------------------------------------------------------------------
# 1. **Modules**: Reuse infrastructure code across projects
# 2. **Data Sources**: Query dynamic values (AMIs, AZs, existing resources)
# 3. **Locals**: Computed values and naming conventions
# 4. **Workspaces**: terraform.workspace for environment separation
# 5. **Bastion Hosts**: Secure SSH access without exposing private resources
# 6. **ALB**: Layer 7 load balancing with health checks
# 7. **ASG**: Automatic scaling based on metrics
# 8. **Launch Templates**: Reusable instance configuration
# 9. **RDS**: Managed databases with automated backups
# 10. **Secrets Manager**: Never hardcode secrets in Terraform
# 11. **CloudWatch**: Monitoring and alerting
# 12. **S3 Lifecycle**: Cost optimization with automatic deletion

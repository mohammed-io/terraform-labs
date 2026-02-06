# -----------------------------------------------------------------------------
# Data Sources - Stack 3: Application
# -----------------------------------------------------------------------------
# This stack reads outputs from BOTH networking and database stacks.

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

# Get current region and account info
data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

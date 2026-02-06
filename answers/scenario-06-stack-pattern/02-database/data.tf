# -----------------------------------------------------------------------------
# Data Sources - Stack 2: Database
# -----------------------------------------------------------------------------
# This file reads outputs from the networking stack (Stack 1).
# This is how stacks communicate!

data "terraform_remote_state" "networking" {
  backend = "local"

  config = {
    path = "${path.module}/../01-networking/terraform.tfstate"
  }
}

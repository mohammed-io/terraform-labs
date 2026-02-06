# -----------------------------------------------------------------------------
# Backend Configuration
# -----------------------------------------------------------------------------
# In production, use S3 for remote state:
terraform {
  backend "local" {  # Change to "s3" in production
    path = "${path.module}/terraform.tfstate"
  }
}

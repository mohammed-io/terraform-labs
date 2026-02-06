# -----------------------------------------------------------------------------
# Variables - Stack 2: Database
# -----------------------------------------------------------------------------

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "database_name" {
  description = "Name of the database"
  type        = string
  default     = "appdb"
}

variable "database_username" {
  description = "Database admin username"
  type        = string
  default     = "admin"
}

variable "database_password" {
  description = "Database admin password (use variable in production, never hardcode)"
  type        = string
  sensitive   = true
  default     = "ChangeMe123!"
}

variable "enable_backup" {
  description = "Enable automated backups"
  type        = bool
  default     = true
}

variable "backup_retention_period" {
  description = "Number of days to retain backups"
  type        = number
  default     = 7
}

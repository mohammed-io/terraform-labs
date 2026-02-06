# -----------------------------------------------------------------------------
# Scenario 1: Docker Provider - Answer Key
# -----------------------------------------------------------------------------

# This solution implements a 3-tier web stack with:
# - Custom network for isolation
# - Load balancer (nginx) on port 8080
# - 3 app containers behind the LB
# - Persistent volume for data

terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

provider "docker" {}

# -----------------------------------------------------------------------------
# Variables
# -----------------------------------------------------------------------------
variable "app_count" {
  description = "Number of app containers to run"
  type        = number
  default     = 3

  validation {
    condition     = var.app_count > 0 && var.app_count <= 10
    error_message = "App count must be between 1 and 10."
  }
}

variable "app_port" {
  description = "Internal port for app containers"
  type        = number
  default     = 80
}

variable "lb_port" {
  description = "External port for load balancer"
  type        = number
  default     = 8080
}

# -----------------------------------------------------------------------------
# Images
# -----------------------------------------------------------------------------
# Pull images BEFORE creating containers that use them.
# This ensures the image is available when Terraform creates the container.

resource "docker_image" "nginx" {
  name = "nginx:alpine"
}

# -----------------------------------------------------------------------------
# Network
# -----------------------------------------------------------------------------
# A bridge network creates an isolated network segment.
# Containers on the same network can communicate by service name.
# Only containers with published ports can be accessed from the host.

resource "docker_network" "app_network" {
  name = "app_network"

  labels = {
    purpose = "web_application_stack"
  }

  # IPAM driver configuration (optional, shown for learning)
  ipam_config {
    subnet = "172.20.0.0/16"
  }
}

# -----------------------------------------------------------------------------
# Volume
# -----------------------------------------------------------------------------
# Volumes provide persistent storage that survives container restarts.
# This is useful for databases or any stateful application.

resource "docker_volume" "data" {
  name = "app_data"

  labels = {
    purpose = "persistent_storage"
  }
}

# -----------------------------------------------------------------------------
# App Containers
# -----------------------------------------------------------------------------
# Using for_each to create multiple similar resources.
# The each.key and each.value variables available in the block.

resource "docker_container" "app" {
  for_each = range(var.app_count)

  name  = "app-${each.value}"
  image = docker_image.nginx.image_id

  # Mount the volume into the container
  volumes {
    volume_name    = docker_volume.data.name
    container_path = "/data"
  }

  # Connect to our custom network
  networks_advanced {
    name = docker_network.app_network.name
  }

  # Restart policy: always restart unless stopped manually
  restart = "always"

  labels = {
    tier   = "app"
    app_id = "myapp"
  }
}

# -----------------------------------------------------------------------------
# Load Balancer
# -----------------------------------------------------------------------------
# The load balancer routes traffic to the app containers.
# We use nginx's round-robin for simplicity.

resource "docker_container" "load_balancer" {
  name  = "load_balancer"
  image = docker_image.nginx.image_id

  # Publish port to host - this is the only externally accessible service
  ports {
    internal = 80
    external = var.lb_port
  }

  # Custom nginx configuration for round-robin load balancing
  # In production, you'd use a proper config file or template
  command = [
    "/bin/sh",
    "-c",
    "echo 'events { worker_connections 4; } http { upstream backend ${join(" ", [for i in range(var.app_count) : "server app-${i}:80"]})} server { listen 80; location / { proxy_pass http://backend; } } }' > /etc/nginx/conf.d/default.conf && nginx -g 'daemon off;'"
  ]

  # Connect to app network
  networks_advanced {
    name = docker_network.app_network.name
  }

  # IMPORTANT: Load balancer depends on app containers being created first
  # Without this, LB might start before apps exist and fail
  depends_on = [
    docker_container.app
  ]

  restart = "always"

  labels = {
    tier = "lb"
  }
}

# -----------------------------------------------------------------------------
# Outputs
# -----------------------------------------------------------------------------
# Outputs provide useful information after `terraform apply`.

output "load_balancer_url" {
  description = "URL to access the load balancer"
  value       = "http://localhost:${var.lb_port}"
}

output "app_container_names" {
  description = "Names of the app containers"
  value       = [for c in docker_container.app : c.name]
}

output "app_container_ips" {
  description = "IP addresses of app containers (on internal network)"
  value       = [for c in docker_container.app : c.ip_address]
}

output "network_name" {
  description = "Docker network name"
  value       = docker_network.app_network.name
}

output "network_id" {
  description = "Docker network ID"
  value       = docker_network.app_network.id
}

# -----------------------------------------------------------------------------
# Terraform State
# -----------------------------------------------------------------------------
# After running `terraform apply`, Terraform creates:
#
# - .terraform/          # Provider plugins and lock file
# - terraform.tfstate   # State file (CRITICAL - backs up your infra)
# - terraform.tfstate.backup  # Backup of state (before last apply)
#
# NEVER edit .terraform/ or terraform.tfstate manually!
# The state file tracks what resources exist and their configuration.
#
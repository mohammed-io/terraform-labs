terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

provider "docker" {}

variable "app_count" {
  description = "Number of app containers"
  default     = 3
  type        = number
}

variable "app_port" {
  description = "Internal port for app containers"
  default     = 80
  type        = number
}

variable "lb_port" {
  description = "External port for load balancer"
  default     = 8080
  type        = number
}

# TODO: Create docker_image resource
# HINT: Use name = "nginx:alpine" and keep_locally = false

# TODO: Create docker_network resource
# HINT: Use name = "app_network"

# TODO: Create docker_volume resource
# HINT: Use name = "app_data"

# TODO: Create docker_container resource for apps
# HINT: Use for_each = range(var.app_count)
# HINT: Set ports with internal = var.app_port, external = null
# HINT: Attach to network using networks_advanced

# TODO: Create docker_container resource for load balancer
# HINT: Expose ports internal = 80, external = var.lb_port
# HINT: Use depends_on = [docker_container.app]

output "lb_url" {
  description = "URL of the load balancer"
  value       = "http://localhost:${var.lb_port}"
}

output "app_container_names" {
  description = "Names of all app containers"
  value       = [
    for container in docker_container.app :
    container.name
  ]
}

output "app_container_ips" {
  description = "IP addresses of app containers"
  value       = {
    for container in docker_container.app :
    container.name => container.ip_address
  }
}

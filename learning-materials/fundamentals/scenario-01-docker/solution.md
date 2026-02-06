# Solution: Docker Provider - Web Application Stack

---

## Complete main.tf

```hcl
terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

provider "docker" {}

# Variables
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

# Resources
resource "docker_image" "nginx" {
  name         = "nginx:alpine"
  keep_locally = false
}

resource "docker_network" "app_network" {
  name = "app_network"
}

resource "docker_volume" "data" {
  name = "app_data"
}

resource "docker_container" "app" {
  for_each = range(var.app_count)

  name  = "app-${each.value}"
  image = docker_image.nginx.image_id

  ports {
    internal = var.app_port
    external = null  # No external port - internal only
  }

  networks_advanced {
    name = docker_network.app_network.name
  }

  volumes {
    volume_name = docker_volume.data.name
    container_path = "/data"
  }
}

resource "docker_container" "lb" {
  name  = "load-balancer"
  image = docker_image.nginx.image_id

  ports {
    internal = 80
    external = var.lb_port
  }

  networks_advanced {
    name = docker_network.app_network.name
  }

  # Explicit dependency: wait for all app containers
  depends_on = [
    docker_container.app
  ]
}

# Outputs
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
```

---

## Explanation

### Provider Setup
- Declares Docker provider from kreuzwerker
- Uses version `~> 3.0` (any 3.x version)
- Empty provider block uses default Docker daemon connection

### Variables
- `app_count`: Controls number of app instances (default: 3)
- `app_port`: Internal container port (default: 80)
- `lb_port`: External LB port (default: 8080)

### Resources

1. **docker_image.nginx**: Pulls nginx:alpine image
2. **docker_network.app_network**: Creates internal network
3. **docker_volume.data**: Creates persistent volume
4. **docker_container.app**: Creates app containers using `for_each`
   - No external port exposure (internal only)
   - Attached to app_network
   - Mounts data volume
5. **docker_container.lb**: Creates load balancer
   - Exposes port 8080 to host
   - Depends on app containers explicitly

### Outputs
- `lb_url`: Full URL to access the load balancer
- `app_container_names`: List of app container names
- `app_container_ips`: Map of container names to IPs

---

## Testing

```bash
# Initialize
terraform init

# Plan (see what will be created)
terraform plan

# Apply
terraform apply -auto-approve

# Verify containers
docker ps
# Should see: load-balancer, app-0, app-1, app-2

# Test access
curl http://localhost:8080

# Check outputs
terraform output lb_url
terraform output app_container_names
terraform output app_container_ips

# Inspect network
docker network inspect app_network

# Cleanup
terraform destroy -auto-approve
```

---

## Key Concepts Demonstrated

| Concept | How It's Shown |
|---------|----------------|
| Provider configuration | terraform + provider blocks |
| Variables | variable blocks with defaults |
| Resource dependencies | depends_on + references |
| Multiple resources | for_each with range() |
| Outputs | Output blocks with expressions |
| Network isolation | docker_network + networks_advanced |
| Port mapping | ports block with internal/external |
| Volumes | docker_volume + volumes block |

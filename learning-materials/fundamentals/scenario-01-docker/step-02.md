# Step 2: Networks, Containers, and Dependencies

---

## Docker Networks

Docker networks allow containers to communicate with each other. In Terraform:

```hcl
resource "docker_network" "app_network" {
  name = "app_network"
}
```

This creates a bridge network that containers can attach to.

## Container Configuration

Containers need several key configurations:

```hcl
resource "docker_container" "app" {
  name  = "app-1"
  image = docker_image.nginx.image_id

  ports {
    internal = 80
    external = 8080
  }

  networks_advanced {
    name = docker_network.app_network.name
  }
}
```

**Key attributes:**
- `name`: Container name (must be unique)
- `image`: Which image to use (reference to docker_image resource)
- `ports`: Port mappings (internal = container port, external = host port)
- `networks_advanced`: Network attachments

## Multiple Containers with for_each

Instead of writing the same resource 3 times, use `for_each`:

```hcl
resource "docker_container" "app" {
  for_each = range(var.app_count)

  name  = "app-${each.value}"
  image = docker_image.nginx.image_id

  ports {
    internal = var.app_port
    external = null  # No external port for app containers
  }

  networks_advanced {
    name = docker_network.app_network.name
  }
}
```

**for_each syntax:**
- `for_each = range(var.app_count)`: Creates 0, 1, 2 (3 iterations)
- `each.value`: Current iteration value (0, 1, or 2)
- Result: Resources named `app["0"]`, `app["1"]`, `app["2"]`

## Dependencies

Terraform automatically infers dependencies from resource references. But sometimes you need explicit ordering:

```hcl
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
```

**When to use `depends_on`:**
- When Terraform can't infer dependency from references
- When you need a resource to complete before another starts
- With `for_each` resources (Terraform may not infer dependency)

## Your Task

Add to your `main.tf`:

1. Variables block with `app_count`, `app_port`, `lb_port`
2. Docker network resource
3. App containers using `for_each`
4. Load balancer container with `depends_on`
5. Outputs for LB URL and container IPs

## Variables Syntax

```hcl
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
```

## Outputs Syntax

```hcl
output "lb_url" {
  description = "URL of the load balancer"
  value       = "http://localhost:${var.lb_port}"
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

## Quick Check

Before moving on, make sure you understand:

1. What does `for_each = range(var.app_count)` produce? (Iterations 0, 1, 2 for app_count=3)
2. How do you reference a for_each resource's name? (`docker_container.app` creates app["0"], app["1"], etc.)
3. Why use `depends_on`? (When Terraform can't infer dependency from references alone)
4. What's `networks_advanced` vs `networks`? (Advanced form allows more configuration like aliases)
5. How do you output all container IPs from a for_each resource? (Use `for` expression to map over the resource)

---

**Continue to `solution.md`**

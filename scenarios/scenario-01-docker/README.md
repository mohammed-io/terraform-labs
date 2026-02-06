# Scenario 1: Docker Provider - Web Application Stack

## Prerequisites

**Skills needed before starting:**
- Basic understanding of Docker containers and images
- Command line familiarity (Linux/MacOS or WSL on Windows)
- Basic YAML syntax knowledge

**You will learn:**
- Terraform basic syntax (HCL - HashiCorp Configuration Language)
- How to define and configure providers
- Resource dependencies and implicit vs explicit ordering
- Variables, outputs, and provisioners

**Tools required:**
- Docker Desktop running locally
- Terraform 1.x installed
- Text editor (VS Code with Terraform extension recommended)

---

## Learning Objectives

- Understand Terraform basic syntax
- Learn about resources, providers, variables
- Create dependencies between resources
- Use outputs and provisioners

## Requirements

Build a 3-tier web application stack:

```
                    ┌─────────────┐
                    │   Nginx     │  (Port 8080)
                    │  (Reverse   │
                    │   Proxy)    │
                    └──────┬───────┘
                           │
              ┌────────────┼────────────┐
              │            │            │
        ┌─────▼─────┐ ┌───▼────┐ ┌───▼─────┐
        │  App 1    │ │ App 2  │ │  App 3  │
        │  (Nginx)  │ │ (Nginx) │ │ (Nginx)  │
        └───────────┘ └────────┘ └─────────┘
```

### Resources to Create

1. **Network**: `docker_network` - A private network for containers
2. **Load Balancer**: `docker_container` (nginx) - Exposed on port 8080
3. **App Instances**: 3 x `docker_container` (nginx) - Behind the LB
4. **Volume**: `docker_volume` - Persistent storage
5. **Image Resources**: `docker_image` - Pull images before using

### Variables to Use

| Variable | Default | Description |
|----------|---------|-------------|
| `app_count` | 3 | Number of app containers |
| `app_port` | 80 | Internal port for app containers |
| `lb_port` | 8080 | External port for load balancer |

## Your Task

Create `main.tf` in this directory with:

1. Provider configuration for Docker
2. Required variables (using `variable` blocks)
3. Docker network for internal communication
4. Docker images (nginx:alpine)
5. Docker volume for data persistence
6. Docker containers with proper networking
7. Outputs showing the load balancer URL and container IPs

## Constraints

- All app containers should be on the same network
- Only the load balancer should expose ports to host
- App containers should only be created AFTER the network exists
- Load balancer should only start AFTER app containers exist
- Use `depends_on` where `for_each` won't create implicit dependencies

## Testing Your Work

```bash
# Initialize
terraform init

# Check your plan
terraform plan

# Apply
terraform apply

# Verify containers are running
docker ps

# Test the load balancer
curl http://localhost:8080

# Check network
docker network inspect app_network

# Check outputs
terraform output

# Clean up
terraform destroy
```

## Expected Results

When you run `terraform apply`, you should see:
- 5 resources created (1 network, 1 volume, 3 images, 4 containers)
- Load balancer accessible at http://localhost:8080
- App containers accessible on internal network only
- No errors in `terraform plan`

## Hints (read only if stuck)

<details>
<summary>Hint 1: Provider Configuration</summary>

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
```

</details>

<details>
<summary>Hint 2: Using for_each for multiple containers</summary>

```hcl
resource "docker_container" "app" {
  for_each = range(var.app_count)

  name  = "app-${each.value}"
  image = docker_image.nginx.image_id

  # ... more config
}
```

</details>

<details>
<summary>Hint 3: Creating dependencies</summary>

Use `depends_on` when Terraform can't infer dependency from references:

```hcl
resource "docker_container" "lb" {
  # ...

  depends_on = [
    docker_container.app
  ]
}
```

Or use explicit references:

```hcl
networks_advanced = [
  {
    name = docker_network.app.name
  }
]
```

</details>

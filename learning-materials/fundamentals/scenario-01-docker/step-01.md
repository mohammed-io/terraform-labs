# Step 1: Provider Configuration and Resources

---

## Understanding Terraform Providers

Providers are plugins that Terraform uses to manage resources in a specific service. They define the set of resource types that can be managed.

## Provider Configuration

Every Terraform configuration starts with a provider block:

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

**What this does:**
- `required_providers`: Declares which providers the configuration uses
- `source`: Where to download the provider from (format: `namespace/name`)
- `version`: Version constraint (`~> 3.0` means >= 3.0, < 4.0)
- `provider` block: Configures the provider (empty `{}` uses defaults)

## Resource Basics

Resources are the most important element in the Terraform language. Each resource block describes one or more infrastructure objects:

```hcl
resource "docker_image" "nginx" {
  name         = "nginx:alpine"
  keep_locally = false
}
```

**Resource syntax:**
- `resource`: Keyword to declare a resource
- `"docker_image"`: Resource type (first part is provider prefix)
- `"nginx"`: Resource name (local to your module)
- `name`: Image name to pull
- `keep_locally`: Remove image after container creation

## Your Task

Create a new directory and add `main.tf` with:

1. Terraform block with Docker provider configuration
2. Provider block for Docker
3. A docker_image resource to pull nginx:alpine

## Initialize and Verify

```bash
# Create your project directory
mkdir terraform-docker-lab && cd terraform-docker-lab

# Create main.tf with the configuration above
# Then initialize:
terraform init
```

**Expected output:**
```
Initializing the backend...
Initializing provider plugins...
- Finding kreuzwerker/docker versions matching "~> 3.0"...
- Installing kreuzwerker/docker v3.0.2...
- Installed kreuzwerker/docker v3.0.2

Terraform has been successfully initialized!
```

## Verify Provider

```bash
# Check providers in your state
terraform providers

# Should show:
# Providers required by configuration:
# ├── docker
```

---

## Quick Check

Before moving on, make sure you understand:

1. What's a Terraform provider? (A plugin that connects to a specific service API like Docker, AWS, etc.)
2. What does `terraform init` do? (Downloads providers, initializes backend, sets up working directory)
3. What's the resource type format? (`"provider_resource"` like `"docker_image"` or `"aws_instance"`)
4. What does `~> 3.0` mean? (Version constraint: >= 3.0 but < 4.0)
5. Why separate `resource` type and name? (Type defines what kind of resource, name is your local reference)

---

**Continue to `step-02.md`**

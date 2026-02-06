# Lab: Docker Provider - Web Application Stack

## Setup

This lab uses your local Docker installation. No additional services needed.

## Prerequisites

1. Docker Desktop installed and running
2. Terraform 1.5+ installed

## Quick Start

```bash
# From this directory:
terraform init
terraform plan
terraform apply
```

## Verification

```bash
# Check containers are running
docker ps

# Test the load balancer
curl http://localhost:8080

# View outputs
terraform output
```

## Files

- `main.tf` - Starter code (complete solution provided)
- `verify.sh` - Automated verification script

## Cleanup

```bash
terraform destroy
```

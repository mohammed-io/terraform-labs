---
name: "Docker Provider - Web Application Stack"
category: "fundamentals"
difficulty: "beginner"
time: "30 minutes"
services: ["docker"]
concepts: ["provider", "resource", "depends_on", "for_each", "outputs"]
---

# Scenario 1: Docker Provider - Web Application Stack

## The Problem

You need to build a 3-tier web application stack using Terraform's Docker provider. This will teach you the fundamentals of Terraform syntax while working with familiar Docker containers.

## Architecture

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

## Requirements

Build a web application stack with:

1. **Network**: A private Docker network for internal container communication
2. **Load Balancer**: Nginx reverse proxy exposed on port 8080
3. **App Instances**: 3 x Nginx app containers behind the LB
4. **Volume**: Persistent storage for data
5. **Images**: Pre-pull nginx:alpine images
6. **Outputs**: Show LB URL and container IPs

## Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `app_count` | 3 | Number of app containers |
| `app_port` | 80 | Internal port for app containers |
| `lb_port` | 8080 | External port for load balancer |

## Constraints

- All app containers must be on the same network
- Only the load balancer should expose ports to the host
- App containers must be created AFTER the network exists
- Load balancer must start AFTER app containers exist
- Use `depends_on` where implicit dependencies don't work

## Prerequisites

- Docker Desktop running locally
- Terraform 1.x installed
- Text editor (VS Code with Terraform extension recommended)
- Basic Docker knowledge
- Command line familiarity

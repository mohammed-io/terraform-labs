#!/bin/bash
set -e

echo "=== Terraform Lab Verification ==="
echo ""

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker Desktop."
    exit 1
fi
echo "✅ Docker is running"

# Check if terraform is initialized
if [ ! -d ".terraform" ]; then
    echo "❌ Terraform not initialized. Run 'terraform init' first."
    exit 1
fi
echo "✅ Terraform initialized"

# Check if containers exist
CONTAINERS=$(docker ps --filter "name=load-balancer" --filter "name=app-" --format "{{.Names}}" | wc -l)
if [ "$CONTAINERS" -lt 4 ]; then
    echo "❌ Expected 4 containers (1 LB + 3 apps), found $CONTAINERS"
    echo "Run 'terraform apply' first."
    exit 1
fi
echo "✅ Found $CONTAINERS containers"

# Test load balancer
if curl -sf http://localhost:8080 > /dev/null; then
    echo "✅ Load balancer is responding"
else
    echo "❌ Load balancer not responding"
    exit 1
fi

# Check network
if docker network inspect app_network > /dev/null 2>&1; then
    echo "✅ Network 'app_network' exists"
else
    echo "❌ Network 'app_network' not found"
    exit 1
fi

# Check volume
if docker volume inspect app_data > /dev/null 2>&1; then
    echo "✅ Volume 'app_data' exists"
else
    echo "❌ Volume 'app_data' not found"
    exit 1
fi

echo ""
echo "=== All Checks Passed! ==="
echo ""
echo "Load Balancer URL: http://localhost:8080"
echo "Container Names:"
docker ps --filter "name=load-balancer" --filter "name=app-" --format "  - {{.Names}}"

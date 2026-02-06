#!/bin/bash
set -e

echo "=== Deploying All Stacks ==="
echo ""

# Check LocalStack is running
if ! curl -sf http://localhost:4566 > /dev/null 2>&1; then
    echo "❌ LocalStack is not running. Please start it first:"
    echo "   docker run --rm -it -p 4566:4566 -e SERVICES=ec2,dynamodb,iam,elb -e DEBUG=1 localstack/localstack:latest"
    exit 1
fi
echo "✅ LocalStack is running"

# Stack 1: Networking
echo ""
echo "=== Stack 1: Networking ==="
cd 01-networking
terraform init > /dev/null 2>&1
terraform apply -auto-approve
VPC_ID=$(terraform output -raw vpc_id)
echo "✅ Networking deployed (VPC: $VPC_ID)"
cd ..

# Stack 2: Database
echo ""
echo "=== Stack 2: Database ==="
cd 02-database
terraform init > /dev/null 2>&1
terraform apply -auto-approve
TABLE_NAME=$(terraform output -raw table_name)
echo "✅ Database deployed (Table: $TABLE_NAME)"
cd ..

# Stack 3: Application
echo ""
echo "=== Stack 3: Application ==="
cd 03-application
terraform init > /dev/null 2>&1
terraform apply -auto-approve
LB_ARN=$(terraform output -raw load_balancer_arn)
echo "✅ Application deployed (LB: $LB_ARN)"
cd ..

echo ""
echo "=== All Stacks Deployed! ==="
echo ""
echo "Outputs:"
echo "  VPC ID: $(terraform -chdir=01-networking output -raw vpc_id)"
echo "  Table: $(terraform -chdir=02-database output -raw table_name)"
echo "  LB ARN: $(terraform -chdir=03-application output -raw load_balancer_arn)"

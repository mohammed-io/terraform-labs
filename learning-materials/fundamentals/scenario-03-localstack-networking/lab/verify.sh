#!/bin/bash
set -e

echo "=== LocalStack Networking Verification ==="
echo ""

# Check if LocalStack is running
if ! curl -sf http://localhost:4566 > /dev/null 2>&1; then
    echo "❌ LocalStack is not running. Please start it first:"
    echo "   docker run --rm -it -p 4566:4566 -e SERVICES=ec2,iam -e DEBUG=1 localstack/localstack:latest"
    exit 1
fi
echo "✅ LocalStack is running"

# Check if terraform is initialized
if [ ! -d ".terraform" ]; then
    echo "❌ Terraform not initialized. Run 'terraform init' first."
    exit 1
fi
echo "✅ Terraform initialized"

# Get VPC ID
VPC_ID=$(terraform output -raw vpc_id 2>/dev/null || echo "")
if [ -z "$VPC_ID" ] || [ "$VPC_ID" = "not created" ]; then
    echo "❌ VPC not found. Run 'terraform apply' first."
    exit 1
fi
echo "✅ VPC created: $VPC_ID"

# Check VPC has DNS enabled
DNS_ENABLED=$(aws --endpoint-url=http://localhost:4566 ec2 describe-vpcs --vpc-ids "$VPC_ID" 2>/dev/null | jq -r '.Vpcs[0].EnableDnsHostnames')
if [ "$DNS_ENABLED" = "true" ]; then
    echo "✅ VPC has DNS enabled"
else
    echo "❌ VPC DNS not enabled"
    exit 1
fi

# Check for Internet Gateway
IGW_ID=$(terraform output -raw internet_gateway_id 2>/dev/null || echo "")
if [ -n "$IGW_ID" ] && [ "$IGW_ID" != "not created" ]; then
    echo "✅ Internet Gateway created: $IGW_ID"
else
    echo "❌ Internet Gateway not found"
    exit 1
fi

# Check subnets exist
PUBLIC_SUBNET_ID=$(terraform output -raw public_subnet_id 2>/dev/null || echo "")
PRIVATE_SUBNET_ID=$(terraform output -raw private_subnet_id 2>/dev/null || echo "")

if [ -n "$PUBLIC_SUBNET_ID" ] && [ "$PUBLIC_SUBNET_ID" != "not created" ]; then
    echo "✅ Public subnet created: $PUBLIC_SUBNET_ID"
else
    echo "❌ Public subnet not found"
    exit 1
fi

if [ -n "$PRIVATE_SUBNET_ID" ] && [ "$PRIVATE_SUBNET_ID" != "not created" ]; then
    echo "✅ Private subnet created: $PRIVATE_SUBNET_ID"
else
    echo "❌ Private subnet not found"
    exit 1
fi

# Check security groups
WEB_SG_ID=$(terraform output -raw web_security_group_id 2>/dev/null || echo "")
APP_SG_ID=$(terraform output -raw app_security_group_id 2>/dev/null || echo "")

if [ -n "$WEB_SG_ID" ] && [ "$WEB_SG_ID" != "not created" ]; then
    echo "✅ Web security group created: $WEB_SG_ID"
else
    echo "❌ Web security group not found"
    exit 1
fi

if [ -n "$APP_SG_ID" ] && [ "$APP_SG_ID" != "not created" ]; then
    echo "✅ App security group created: $APP_SG_ID"
else
    echo "❌ App security group not found"
    exit 1
fi

# Check security group rules (web should have port 80 and 443)
WEB_RULES=$(aws --endpoint-url=http://localhost:4566 ec2 describe-security-groups --group-ids "$WEB_SG_ID" 2>/dev/null | jq -r '.SecurityGroups[0].IpPermissions[])
if echo "$WEB_RULES" | grep -q "80" && echo "$WEB_RULES" | grep -q "443"; then
    echo "✅ Web security group has HTTP/HTTPS rules"
else
    echo "❌ Web security group missing HTTP/HTTPS rules"
    exit 1
fi

echo ""
echo "=== All Checks Passed! ==="
echo ""
echo "VPC ID: $VPC_ID"
echo "Public Subnet: $PUBLIC_SUBNET_ID"
echo "Private Subnet: $PRIVATE_SUBNET_ID"
echo "Web SG: $WEB_SG_ID"
echo "App SG: $APP_SG_ID"

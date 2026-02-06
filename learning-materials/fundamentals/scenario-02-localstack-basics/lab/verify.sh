#!/bin/bash
set -e

echo "=== LocalStack AWS Fundamentals Verification ==="
echo ""

# Check if LocalStack is running
if ! curl -sf http://localhost:4566 > /dev/null 2>&1; then
    echo "❌ LocalStack is not running. Please start it first:"
    echo "   docker run --rm -it -p 4566:4566 -e SERVICES=s3,dynamodb localstack/localstack:latest"
    exit 1
fi
echo "✅ LocalStack is running"

# Check if terraform is initialized
if [ ! -d ".terraform" ]; then
    echo "❌ Terraform not initialized. Run 'terraform init' first."
    exit 1
fi
echo "✅ Terraform initialized"

# Check if S3 bucket exists
if aws --endpoint-url=http://localhost:4566 s3 ls | grep -q "raw-uploads-bucket"; then
    echo "✅ S3 bucket 'raw-uploads-bucket' exists"
else
    echo "❌ S3 bucket 'raw-uploads-bucket' not found"
    echo "Run 'terraform apply' first."
    exit 1
fi

# Check if S3 object exists
if aws --endpoint-url=http://localhost:4566 s3api head-object --bucket raw-uploads-bucket --key sample-data.json > /dev/null 2>&1; then
    echo "✅ S3 object 'sample-data.json' exists"
else
    echo "❌ S3 object 'sample-data.json' not found"
    exit 1
fi

# Check if DynamoDB table exists
if aws --endpoint-url=http://localhost:4566 dynamodb describe-table --table-name users-table > /dev/null 2>&1; then
    echo "✅ DynamoDB table 'users-table' exists"
else
    echo "❌ DynamoDB table 'users-table' not found"
    exit 1
fi

# Check table has correct key schema
TABLE_SCHEMA=$(aws --endpoint-url=http://localhost:4566 dynamodb describe-table --table-name users-table | jq '.Table.KeySchema')
if echo "$TABLE_SCHEMA" | grep -q "user_id" && echo "$TABLE_SCHEMA" | grep -q "timestamp"; then
    echo "✅ DynamoDB table has correct key schema (user_id, timestamp)"
else
    echo "❌ DynamoDB table key schema is incorrect"
    exit 1
fi

# Check table has item
if aws --endpoint-url=http://localhost:4566 dynamodb get-item --table-name users-table --key '{"user_id": {"S": "user-123"}, "timestamp": {"S": "2024-01-01T00:00:00Z"}}' | grep -q "email"; then
    echo "✅ DynamoDB table has sample item"
else
    echo "❌ DynamoDB table item not found"
    exit 1
fi

echo ""
echo "=== All Checks Passed! ==="
echo ""
echo "S3 Endpoint: http://localhost:4566"
echo "DynamoDB Endpoint: http://localhost:4566"
echo ""
echo "S3 Bucket:"
aws --endpoint-url=http://localhost:4566 s3 ls
echo ""
echo "DynamoDB Tables:"
aws --endpoint-url=http://localhost:4566 dynamodb list-tables --output table

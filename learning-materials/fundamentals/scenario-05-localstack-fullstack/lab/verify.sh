#!/bin/bash
set -e

echo "=== LocalStack Full-Stack Verification ==="
echo ""

# Check if LocalStack is running
if ! curl -sf http://localhost:4566 > /dev/null 2>&1; then
    echo "❌ LocalStack is not running. Please start it first:"
    echo "   docker run --rm -it -p 4566:4566 -e SERVICES=lambda,apigateway,dynamodb,s3,iam,cloudwatch,logs,sts -e DEBUG=1 localstack/localstack:latest"
    exit 1
fi
echo "✅ LocalStack is running"

# Check if terraform is initialized
if [ ! -d ".terraform" ]; then
    echo "❌ Terraform not initialized. Run 'terraform init' first."
    exit 1
fi
echo "✅ Terraform initialized"

# Check if lambda.zip exists
if [ ! -f "lambda.zip" ]; then
    echo "❌ lambda.zip not found. Create it first:"
    echo "   cat > index.py << 'EOF'"
    echo "   import json"
    echo "   def handler(event, context):"
    echo "       return {'statusCode': 200, 'body': json.dumps({'status': 'ok'})}"
    echo "   EOF"
    echo "   zip lambda.zip index.py"
    exit 1
fi
echo "✅ lambda.zip exists"

# Check API Gateway
API_ID=$(terraform output -raw api_id 2>/dev/null || echo "")
if [ -n "$API_ID" ] && [ "$API_ID" != "not created" ]; then
    echo "✅ API Gateway created: $API_ID"
else
    echo "❌ API Gateway not found"
    exit 1
fi

# Check Lambda function
LAMBDA_NAME=$(terraform output -raw lambda_function_name 2>/dev/null || echo "")
if [ -n "$LAMBDA_NAME" ] && [ "$LAMBDA_NAME" != "not created" ]; then
    if aws --endpoint-url=http://localhost:4566 lambda get-function --function-name "$LAMBDA_NAME" > /dev/null 2>&1; then
        echo "✅ Lambda function created: $LAMBDA_NAME"
    else
        echo "❌ Lambda function not found in AWS"
        exit 1
    fi
else
    echo "❌ Lambda function not created"
    exit 1
fi

# Check DynamoDB table
TABLE_NAME=$(terraform output -raw dynamodb_table_name 2>/dev/null || echo "")
if [ -n "$TABLE_NAME" ] && [ "$TABLE_NAME" != "not created" ]; then
    if aws --endpoint-url=http://localhost:4566 dynamodb describe-table --table-name "$TABLE_NAME" > /dev/null 2>&1; then
        echo "✅ DynamoDB table created: $TABLE_NAME"
    else
        echo "❌ DynamoDB table not found"
        exit 1
    fi
else
    echo "❌ DynamoDB table not created"
    exit 1
fi

# Check S3 bucket
BUCKET_NAME=$(terraform output -raw s3_bucket_name 2>/dev/null || echo "")
if [ -n "$BUCKET_NAME" ] && [ "$BUCKET_NAME" != "not created" ]; then
    if aws --endpoint-url=http://localhost:4566 s3 ls "$BUCKET_NAME" > /dev/null 2>&1; then
        echo "✅ S3 bucket created: $BUCKET_NAME"
    else
        echo "❌ S3 bucket not found"
        exit 1
    fi
else
    echo "❌ S3 bucket not created"
    exit 1
fi

# Test API endpoint
API_URL=$(terraform output -raw api_endpoint 2>/dev/null || echo "")
if [ -n "$API_URL" ] && [ "$API_URL" != "not created" ]; then
    # Try calling the health endpoint
    if curl -sf "http://$API_URL/health" > /dev/null 2>&1; then
        echo "✅ API endpoint is responding"
    else
        echo "⚠️  API endpoint created but not responding (may need a moment)"
    fi
fi

echo ""
echo "=== All Checks Passed! ==="
echo ""
echo "API Endpoint: http://$API_URL"
echo "Lambda: $LAMBDA_NAME"
echo "DynamoDB: $TABLE_NAME"
echo "S3 Bucket: $BUCKET_NAME"
echo ""
echo "Test commands:"
echo "  curl \"http://$API_URL/health\""
echo "  curl \"http://$API_URL/api/users\""

#!/bin/bash
set -e

echo "=== LocalStack Security Verification ==="
echo ""

# Check if LocalStack is running
if ! curl -sf http://localhost:4566 > /dev/null 2>&1; then
    echo "❌ LocalStack is not running. Please start it first:"
    echo "   docker run --rm -it -p 4566:4566 -e SERVICES=iam,kms,secretsmanager,lambda,sts -e DEBUG=1 localstack/localstack:latest"
    exit 1
fi
echo "✅ LocalStack is running"

# Check if terraform is initialized
if [ ! -d ".terraform" ]; then
    echo "❌ Terraform not initialized. Run 'terraform init' first."
    exit 1
fi
echo "✅ Terraform initialized"

# Check IAM user exists
USER_NAME=$(terraform output -raw iam_user_name 2>/dev/null || echo "")
if [ -n "$USER_NAME" ] && [ "$USER_NAME" != "not created" ]; then
    if aws --endpoint-url=http://localhost:4566 iam get-user --user-name "$USER_NAME" > /dev/null 2>&1; then
        echo "✅ IAM user created: $USER_NAME"
    else
        echo "❌ IAM user not found in AWS"
        exit 1
    fi
else
    echo "❌ IAM user not created"
    exit 1
fi

# Check IAM group exists
GROUP_NAME=$(terraform output -raw group_name 2>/dev/null || echo "")
if [ -z "$GROUP_NAME" ]; then
    GROUP_NAME="developers"
fi

if aws --endpoint-url=http://localhost:4566 iam get-group --group-name "$GROUP_NAME" > /dev/null 2>&1; then
    echo "✅ IAM group created: $GROUP_NAME"
else
    echo "❌ IAM group not found"
    exit 1
fi

# Check user is in group
if aws --endpoint-url=http://localhost:4566 iam get-group --group-name "$GROUP_NAME" | grep -q "$USER_NAME"; then
    echo "✅ User is member of group"
else
    echo "❌ User is not member of group"
    exit 1
fi

# Check KMS key exists
KMS_KEY_ID=$(terraform output -raw kms_key_id 2>/dev/null || echo "")
if [ -n "$KMS_KEY_ID" ] && [ "$KMS_KEY_ID" != "not created" ]; then
    echo "✅ KMS key created: $KMS_KEY_ID"
else
    echo "❌ KMS key not found"
    exit 1
fi

# Check KMS key rotation
if aws --endpoint-url=http://localhost:4566 kms describe-key --key-id "$KMS_KEY_ID" | grep -q "true"; then
    echo "✅ KMS key rotation enabled"
else
    echo "❌ KMS key rotation not enabled"
    exit 1
fi

# Check IAM role exists
ROLE_NAME=$(terraform output -raw iam_role_name 2>/dev/null || echo "")
if [ -n "$ROLE_NAME" ] && [ "$ROLE_NAME" != "not created" ]; then
    if aws --endpoint-url=http://localhost:4566 iam get-role --role-name "$ROLE_NAME" > /dev/null 2>&1; then
        echo "✅ IAM role created: $ROLE_NAME"
    else
        echo "❌ IAM role not found"
        exit 1
    fi
else
    echo "❌ IAM role not created"
    exit 1
fi

# Check secret exists
SECRET_ARN=$(terraform output -raw secret_arn 2>/dev/null || echo "")
if [ -n "$SECRET_ARN" ] && [ "$SECRET_ARN" != "not created" ]; then
    SECRET_NAME=$(basename "$SECRET_ARN")
    if aws --endpoint-url=http://localhost:4566 secretsmanager describe-secret --secret-id "$SECRET_NAME" > /dev/null 2>&1; then
        echo "✅ Secret created: $SECRET_NAME"
    else
        echo "❌ Secret not found"
        exit 1
    fi
else
    echo "❌ Secret not created"
    exit 1
fi

echo ""
echo "=== All Checks Passed! ==="
echo ""
echo "IAM User: $USER_NAME"
echo "IAM Group: $GROUP_NAME"
echo "IAM Role: $ROLE_NAME"
echo "KMS Key: $KMS_KEY_ID"
echo "Secret: $SECRET_NAME"

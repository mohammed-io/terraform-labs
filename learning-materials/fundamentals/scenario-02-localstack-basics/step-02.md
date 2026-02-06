# Step 2: DynamoDB Tables and Items

## DynamoDB Table Resource

DynamoDB is a NoSQL key-value database. Tables require:

- **Hash key** (partition key) - required
- **Range key** (sort key) - optional
- **Billing mode** - PROVISIONED or PAY_PER_REQUEST
- **Attributes** - Define your key attributes

```hcl
resource "aws_dynamodb_table" "users" {
  name           = var.table_name
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "user_id"
  range_key      = "timestamp"

  attribute {
    name = "user_id"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "S"
  }

  tags = {
    Environment = var.environment
  }
}
```

**Attribute types:**
- `"S"` = String
- `"N"` = Number
- `"B"` = Binary

**Billing modes:**
- `PAY_PER_REQUEST`: On-demand, scales automatically (simpler)
- `PROVISIONED`: Fixed capacity (requires read/write capacity settings)

## DynamoDB Table Item Resource

To add data to your table during Terraform apply:

```hcl
resource "aws_dynamodb_table_item" "sample" {
  table_name = aws_dynamodb_table.users.name
  hash_key   = aws_dynamodb_table.users.hash_key
  range_key  = "${var.user_id}#2024-01-01T00:00:00Z"

  item = <<ITEM
{
  "user_id": {"S": "${var.user_id}"},
  "timestamp": {"S": "2024-01-01T00:00:00Z"},
  "email": {"S": "user@example.com"},
  "name": {"S": "Test User"}
}
ITEM
}
```

**The item format:**
- Each attribute is a key-value pair
- The value includes the type: `{"S": "string"}`, `{"N": "123"}`, etc.
- The `hash_key` and `range_key` values must match the item's key values

## Outputs

Add outputs to see your resources:

```hcl
output "bucket_name" {
  value = aws_s3_bucket.data.id
}

output "table_name" {
  value = aws_dynamodb_table.users.name
}

output "s3_endpoint" {
  value = "http://localhost:4566"
}

output "dynamodb_endpoint" {
  value = "http://localhost:4566"
}
```

## Your Task

1. Create a DynamoDB table with the schema from the problem description
2. Add a sample item to the table
3. Add outputs for bucket name, table name, and endpoints

## Quick Check

Test your understanding:

1. What's the difference between a hash key and a range key? (Hash key is the required partition key that distributes data across nodes; range key is an optional sort key that enables sorting and composite primary keys)

2. What does PAY_PER_REQUEST billing mode mean? (You pay only for what you use, no need to specify read/write capacity - it scales automatically)

3. Why does the DynamoDB item use type prefixes like {"S": "value"}? (DynamoDB is a typed database; the "S" indicates this is a String type, "N" for Number, "B" for Binary)

4. What happens if you try to create a table item with a hash_key that doesn't match the item's hash_key value? (Terraform will fail with a validation error - the keys must match exactly)

5. Why use `aws_dynamodb_table_item` instead of just inserting data with the AWS CLI? (aws_dynamodb_table_item ensures the data exists as part of your infrastructure, making it reproducible and version-controlled)

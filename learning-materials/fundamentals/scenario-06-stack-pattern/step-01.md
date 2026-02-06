# Step 1: Understanding terraform_remote_state

## The Magic Data Source

The `terraform_remote_state` data source lets one stack read outputs from another stack:

```hcl
data "terraform_remote_state" "networking" {
  backend = "local"

  config = {
    path = "${path.module}/../01-networking/terraform.tfstate"
  }
}
```

**How it works:**
1. Stack 1 writes outputs to its state file
2. Stack 2 uses `terraform_remote_state` to read those outputs
3. Stack 2 can reference Stack 1's values as `data.terraform_remote_state.networking.outputs.vpc_id`

## Reading Remote Outputs

Once you have the data source defined, reference outputs:

```hcl
resource "aws_dynamodb_table" "users" {
  # Use VPC ID from networking stack
  # (for VPC endpoint or similar)
  # ...

  tags = {
    VPC = data.terraform_remote_state.networking.outputs.vpc_id
  }
}
```

## Complete Pattern: Stack 2 Reading from Stack 1

### Stack 1 (01-networking/outputs.tf)
```hcl
output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}

output "web_security_group_id" {
  value = aws_security_group.web.id
}
```

### Stack 2 (02-database/data.tf)
```hcl
terraform {
  # Required for terraform_remote_state
}

data "terraform_remote_state" "networking" {
  backend = "local"

  config = {
    path = "${path.module}/../01-networking/terraform.tfstate"
  }
}
```

### Stack 2 (02-database/main.tf)
```hcl
resource "aws_dynamodb_table" "users" {
  name = "users-table"

  tags = {
    VPC_ID = data.terraform_remote_state.networking.outputs.vpc_id
  }
}
```

## Deployment Order

**IMPORTANT:** Deploy in dependency order!

```bash
# Step 1: Deploy networking (no dependencies)
cd 01-networking
terraform init
terraform apply
cd ..

# Step 2: Deploy database (depends on networking)
cd 02-database
terraform init
terraform apply
cd ..

# Step 3: Deploy application (depends on both)
cd 03-application
terraform init
terraform apply
cd ..
```

## Destroy Order

**Destroy in REVERSE order!**

```bash
cd 03-application && terraform destroy && cd ..
cd 02-database && terraform destroy && cd ..
cd 01-networking && terraform destroy && cd ..
```

## Multiple Remote States

A stack can read from multiple other stacks:

```hcl
data "terraform_remote_state" "networking" {
  backend = "local"
  config = {
    path = "${path.module}/../01-networking/terraform.tfstate"
  }
}

data "terraform_remote_state" "database" {
  backend = "local"
  config = {
    path = "${path.module}/../02-database/terraform.tfstate"
  }
}

resource "aws_ecs_task_definition" "app" {
  # Use outputs from both stacks
  container_definitions = jsonencode([
    {
      name = "app"
      environment = [
        {
          name  = "VPC_ID"
          value = data.terraform_remote_state.networking.outputs.vpc_id
        },
        {
          name  = "TABLE_NAME"
          value = data.terraform_remote_state.database.outputs.table_name
        }
      ]
    }
  ])
}
```

## Your Task

1. Complete Stack 1 (01-networking) with proper outputs
2. Create Stack 2 (02-database) that reads from Stack 1 using terraform_remote_state
3. Create Stack 3 (03-application) that reads from both Stack 1 and Stack 2
4. Deploy in order and verify outputs are passed correctly

## Quick Check

Test your understanding:

1. What does `terraform_remote_state` do? (Allows one Terraform configuration to read outputs from another Terraform state file)

2. Why is deployment order important with stacks? (A stack that depends on another stack's outputs can't be deployed until those outputs exist)

3. What happens if you deploy Stack 2 before Stack 1? (Terraform will fail because it can't find the networking state file or the outputs it needs)

4. How do you reference an output from a remote state? (data.terraform_remote_state.<name>.outputs.<output_name>)

5. Why use stacks instead of one big Terraform config? (Smaller blast radius, faster deployments, parallel work, team ownership, easier debugging)

#!/bin/bash
# -----------------------------------------------------------------------------
# Stack Pattern Deployment Script
# -----------------------------------------------------------------------------
# This script demonstrates the proper deployment order for stacks.
# Stacks MUST be deployed in dependency order.

set -e  # Exit on any error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Stack Pattern Deployment Script${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Function to deploy a stack
deploy_stack() {
    local stack_name=$1
    local stack_dir=$2

    echo -e "${YELLOW}Deploying Stack: ${stack_name}${NC}"
    echo -e "${BLUE}Directory: ${stack_dir}${NC}"
    echo ""

    cd "${SCRIPT_DIR}/${stack_dir}"

    # Initialize (if not already done)
    if [ ! -f ".terraform/terraform.tfstate" ]; then
        terraform init
    fi

    # Plan
    echo -e "${BLUE}Planning...${NC}"
    terraform plan -out=tfplan

    # Apply
    echo -e "${GREEN}Applying...${NC}"
    terraform apply -auto-approve tfplan

    # Clean up plan file
    rm -f tfplan

    echo -e "${GREEN}✓ Stack ${stack_name} deployed successfully!${NC}"
    echo ""
}

# Function to destroy a stack
destroy_stack() {
    local stack_name=$1
    local stack_dir=$2

    echo -e "${RED}Destroying Stack: ${stack_name}${NC}"
    echo -e "${BLUE}Directory: ${stack_dir}${NC}"
    echo ""

    cd "${SCRIPT_DIR}/${stack_dir}"

    terraform destroy -auto-approve

    echo -e "${GREEN}✓ Stack ${stack_name} destroyed!${NC}"
    echo ""
}

# -----------------------------------------------------------------------------
# Main Deployment
# -----------------------------------------------------------------------------

if [ "$1" == "destroy" ]; then
    echo -e "${RED}DESTROY MODE: Destroying stacks in REVERSE order${NC}"
    echo ""

    # Destroy in REVERSE dependency order
    destroy_stack "03-application" "03-application"
    destroy_stack "02-database" "02-database"
    destroy_stack "01-networking" "01-networking"

    echo -e "${GREEN}All stacks destroyed!${NC}"
    exit 0
fi

# Default: Deploy in dependency order
echo -e "${GREEN}DEPLOY MODE: Deploying stacks in dependency order${NC}"
echo ""

deploy_stack "01-networking" "01-networking"
deploy_stack "02-database" "02-database"
deploy_stack "03-application" "03-application"

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  All stacks deployed successfully!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Show outputs from the final stack
cd "${SCRIPT_DIR}/03-application"
echo -e "${BLUE}Application Outputs:${NC}"
terraform output -json | jq -r 'to_entries[] | "\(.key): \(.value)"'

echo ""
echo -e "${BLUE}Test your application:${NC}"
terraform output test_commands

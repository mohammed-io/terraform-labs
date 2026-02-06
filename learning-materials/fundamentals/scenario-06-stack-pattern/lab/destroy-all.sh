#!/bin/bash
set -e

echo "=== Destroying All Stacks (Reverse Order) ==="
echo ""

# Stack 3: Application
echo "=== Stack 3: Application ==="
cd 03-application
terraform destroy -auto-approve
echo "✅ Application destroyed"
cd ..

# Stack 2: Database
echo "=== Stack 2: Database ==="
cd 02-database
terraform destroy -auto-approve
echo "✅ Database destroyed"
cd ..

# Stack 1: Networking
echo "=== Stack 1: Networking ==="
cd 01-networking
terraform destroy -auto-approve
echo "✅ Networking destroyed"
cd ..

echo ""
echo "=== All Stacks Destroyed! ==="

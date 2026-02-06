#!/bin/bash
# -----------------------------------------------------------------------------
# User Data Script
# -----------------------------------------------------------------------------
# This script runs when the EC2 instance first boots.
# It's used to bootstrap the instance with configuration.

set -e  # Exit on any error

# Update system
yum update -y

# Install necessary packages
yum install -y docker git

# Enable and start Docker
systemctl enable docker
systemctl start docker

# Add ec2-user to docker group
usermod -aG docker ec2-user

# Create application directory
mkdir -p /opt/app
cd /opt/app

# Pull and run application (example)
docker run -d \
  --name myapp \
  -p 80:80 \
  --restart unless-stopped \
  nginx:alpine

# Configure environment variables
cat << EOF >> /etc/environment
DB_HOST=${db_host}
DB_NAME=${db_name}
ENVIRONMENT=${environment}
EOF

# Create startup log
echo "Instance bootstrapped at $(date)" > /var/log/bootstrap.log
echo "Database host: ${db_host}" >> /var/log/bootstrap.log
echo "Environment: ${environment}" >> /var/log/bootstrap.log

# Signal completion
echo "Bootstrap complete!"

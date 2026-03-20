#!/bin/bash
set -e

# Redirect stdout and stderr to a log file
exec > /var/log/user-data.log 2>&1

echo "===== Starting user-data script ====="
date

# Update system
echo "Updating system..."
dnf update -y
dnf install -y wget

# Bootstrap required external repository
REQUIRED_PACKAGE_REPO_NAME="docker-ce"
REQUIRED_PACKAGE_NAME="${required_package_name}"

echo "Bootstrapping external repository for ${required_package_name}..."
if ! wget -qO /etc/yum.repos.d/$${REQUIRED_PACKAGE_REPO_NAME}.repo "${required_package_repo_baseurl}"; then
    echo "ERROR: Could not bootstrap repository from ${required_package_repo_baseurl}"
    exit 1
fi

# Docker's CentOS repo file uses $releasever, which AL2023 expands to 2023.x and breaks metadata URL.
# Pin it to CentOS 9 so docker-ce packages can be resolved.
sed -i 's|\$releasever|9|g' /etc/yum.repos.d/$${REQUIRED_PACKAGE_REPO_NAME}.repo

dnf clean all

echo "Installing required dependency ${required_package_name}..."
if ! dnf install -y "$REQUIRED_PACKAGE_NAME"; then
    echo "ERROR: Required package $REQUIRED_PACKAGE_NAME could not be installed from ${required_package_repo_baseurl}"
    exit 1
fi

echo "Verifying required dependency ${required_package_name} is installed..."
if ! rpm -q "$REQUIRED_PACKAGE_NAME"; then
    echo "ERROR: Required package $REQUIRED_PACKAGE_NAME is missing; application startup aborted"
    exit 1
fi

# Install nginx directly (Amazon Linux 2023)
echo "Installing nginx..."
dnf install -y nginx

# Enable and start nginx
echo "Enabling and starting nginx service..."
systemctl enable nginx
systemctl start nginx

# Create simple index page for ALB health check
echo "Creating test HTML page..."
cat <<EOF > /usr/share/nginx/html/index.html
<h1>Running nginx on $(hostname)</h1>
<p>I want to be a part of your team :)</p>
EOF

# Test HTTPS connection to secureweb.com
BASE_URL="https://secureweb.com"
echo "Testing HTTPS connection to $BASE_URL..."
response=$(curl -s -o /dev/null -w "%%{http_code}" "$BASE_URL")
if [ "$response" -ne 200 ]; then
    echo "❌ Error connecting to $BASE_URL (HTTP $response)"
    exit 1
else
    echo "✅ Successfully connected to $BASE_URL (HTTP $response)"
fi

# Give some time for ALB health check to see the service
echo "Waiting 30s for ALB health checks..."
sleep 30

echo "===== User-data script completed successfully ====="
date

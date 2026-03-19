#!/bin/bash
set -e

# Redirect stdout and stderr to a log file
exec > /var/log/user-data.log 2>&1

echo "===== Starting user-data script ====="
date

# Update system
echo "Updating system..."
dnf update -y

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

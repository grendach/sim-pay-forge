#!/bin/bash
set -e

# Update system
dnf update -y

# Install nginx using dnf module
dnf module enable -y nginx:1.20
dnf install -y nginx

# Enable and start nginx
systemctl enable nginx
systemctl start nginx

# Create simple index page for testing ALB health check
echo "<h1>POC nginx on $(hostname)</h1>" > /usr/share/nginx/html/index.html

# Communicate with secureweb.com over HTTPS
BASE_URL="https://secureweb.com"
response=$(curl -s -o /dev/null -w "%%{http_code}" "$BASE_URL")
if [ "$response" -ne 200 ]; then
    echo "Error connecting to $BASE_URL (HTTP $response)"
    exit 1
fi

# Wait a bit to ensure ALB health check sees the server ready
sleep 30

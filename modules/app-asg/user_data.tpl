
# #!/bin/bash
# set -e

# echo "Installing required package..."

# # Example install (replace with real package)
# yum update -y
# yum install -y curl

# # Simulate dependency from example.com
# curl -f https://example.com/package.rpm -o /tmp/package.rpm

# if [ $? -ne 0 ]; then
#   echo "Package download failed. Exiting."
#   exit 1
# fi

# rpm -ivh /tmp/package.rpm

# echo "Starting application..."
# # systemctl start your-app

#!/bin/bash
# Install nginx if not present
if ! rpm -q nginx; then
  amazon-linux-extras enable nginx1
  yum install -y nginx
fi

# Start nginx
systemctl enable nginx
systemctl start nginx

# Simple HTML for testing
echo "<h1>POC nginx on $(hostname)</h1>" > /usr/share/nginx/html/index.html

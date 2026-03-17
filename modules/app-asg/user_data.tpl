#!/bin/bash
yum update -y
yum install -y httpd

cat <<EOF > /var/www/html/index.html
<!DOCTYPE html>
<html>
<head><title>SimPayForge</title></head>
<body>
<h1>🛒 Payment Provider Active</h1>
<p>Audit-ready infrastructure deployed!</p>
</body>
</html>
EOF

systemctl enable httpd
systemctl start httpd

# Health check endpoint
curl -f "http://localhost:${app_port}" || echo "Health check failed"

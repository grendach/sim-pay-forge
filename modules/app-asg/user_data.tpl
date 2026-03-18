#!/bin/bash
set -e

exec > /var/log/user-data.log 2>&1

echo "===== USER DATA START ====="

dnf update -y
dnf install -y curl nginx

BASE_URL="https://secureweb.com"

make_get_request() {
    local endpoint="$1"
    local url="$${BASE_URL}$${endpoint}"

    echo "Fetching: $${url}"

    response=$(curl -s -w "\n%%{http_code}" -L "$${url}")
    http_code=$(echo "$${response}" | tail -n1)

    if [ "$${http_code}" -eq 200 ]; then
        echo "Success (HTTP $${http_code})"
    else
        echo "Error (HTTP $${http_code})"
    fi
}

make_get_request "/"

systemctl enable nginx
systemctl start nginx

cat <<EOF > /usr/share/nginx/html/index.html
App is running on port ${app_port}
secureweb connectivity tested
EOF

echo "===== USER DATA END ====="

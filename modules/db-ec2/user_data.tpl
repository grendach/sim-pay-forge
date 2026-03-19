#!/bin/bash
set -e

exec > /var/log/user-data.log 2>&1

echo "===== MYSQL SETUP START ====="

# Update system
dnf update -y

# Install MySQL official repo
dnf install -y https://dev.mysql.com/get/mysql80-community-release-el9-1.noarch.rpm

# Install MySQL server
dnf install -y mysql-community-server

# Enable and start MySQL
systemctl enable mysqld
systemctl start mysqld

# Wait for MySQL to initialize
sleep 15

# Get temporary root password
TEMP_PASS=$(grep 'temporary password' /var/log/mysqld.log | awk '{print $NF}')

echo "Temporary MySQL password: $TEMP_PASS"

# Set new root password
NEW_PASS="RootPass123!"

mysql --connect-expired-password -u root -p"$TEMP_PASS" <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '${NEW_PASS}';
FLUSH PRIVILEGES;
EOF

echo "===== MYSQL SETUP DONE ====="

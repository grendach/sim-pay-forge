#!/bin/bash
set -e

# Log everything
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

echo "===== MYSQL SETUP START ====="

# Update system
dnf update -y

# Install required dependencies
dnf install -y wget

# Preflight: verify DNS and HTTPS connectivity to MySQL repos
echo "===== NETWORK PREFLIGHT START ====="
for host in dev.mysql.com repo.mysql.com; do
	echo "Checking DNS for $host"
	getent hosts "$host"
done

for url in \
	"https://dev.mysql.com/get/mysql80-community-release-el9-1.noarch.rpm" \
	"https://repo.mysql.com/"; do
	echo "Checking HTTPS reachability: $url"
	if ! wget --spider --server-response --timeout=15 --tries=2 "$url"; then
		echo "ERROR: Cannot reach $url over HTTPS (443). Check route table, NAT/IGW, NACL, proxy/firewall, and SG egress."
		exit 1
	fi
done
echo "===== NETWORK PREFLIGHT COMPLETE ====="

# Add MySQL 8 community repo
wget https://dev.mysql.com/get/mysql80-community-release-el9-1.noarch.rpm
dnf localinstall -y mysql80-community-release-el9-1.noarch.rpm

# Force HTTPS for MySQL repos (avoid port 80 timeouts)
sed -i 's|^baseurl=http://repo.mysql.com|baseurl=https://repo.mysql.com|g' /etc/yum.repos.d/mysql-community*.repo

# Import MySQL GPG keys (key rotation-safe)
wget -qO /etc/pki/rpm-gpg/RPM-GPG-KEY-mysql-2022 https://repo.mysql.com/RPM-GPG-KEY-mysql-2022
wget -qO /etc/pki/rpm-gpg/RPM-GPG-KEY-mysql-2023 https://repo.mysql.com/RPM-GPG-KEY-mysql-2023
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-mysql-2022
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-mysql-2023
sed -i 's|^gpgkey=.*|gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-mysql-2022 file:///etc/pki/rpm-gpg/RPM-GPG-KEY-mysql-2023|g' /etc/yum.repos.d/mysql-community*.repo
dnf clean all

# Install MySQL 8 server
dnf install -y --setopt=retries=10 --setopt=timeout=60 mysql-community-server

# Enable and start MySQL service
systemctl enable mysqld
systemctl start mysqld

# Set root password and secure installation
MYSQL_ROOT_PASSWORD="$${NEW_PASS}"   # Pass this from Terraform var

mysql --connect-expired-password -uroot <<MYSQL_SECURE
ALTER USER 'root'@'localhost' IDENTIFIED BY '$${NEW_PASS}';
DELETE FROM mysql.user WHERE User='';
DROP DATABASE IF EXISTS test;
FLUSH PRIVILEGES;
MYSQL_SECURE

echo "===== MYSQL SETUP COMPLETE ====="

# Optional: test MySQL
mysqladmin -uroot -p"$${NEW_PASS}" ping

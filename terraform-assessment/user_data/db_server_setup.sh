#!/bin/bash

yum update -y

# Create dbuser with password for bastion access
# Create user
useradd -m -s /bin/bash dev

# Set password
echo "dev:${db_user_password}" | chpasswd

# Ensure SSH allows password authentication
sed -i 's/^#PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config

# Restart SSH service
systemctl restart sshd

# Install PostgreSQL
amazon-linux-extras enable postgresql14
yum install postgresql-server postgresql-contrib -y

postgresql-setup initdb 

systemctl start postgresql
systemctl enable postgresql

# Sudo access
usermod -aG wheel dev
echo "dev ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/dev
chmod 0440 /etc/sudoers.d/dev
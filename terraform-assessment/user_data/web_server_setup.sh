#!/bin/bash
#  Update and install Apache
yum update -y
yum install -y httpd
systemctl start httpd
systemctl enable httpd

# Create dbuser with password for bastion access
# Create user
useradd -m -s /bin/bash web

# Set password
echo "web:${web_user_password}" | chpasswd

# Ensure SSH allows password authentication
sed -i 's/^#PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config

# Restart SSH service
systemctl restart sshd

# Get the Token for IMDSv2
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")

# Get the Instance ID using the Token
INSTANCE_ID=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id)


# 3. Create the HTML page
cat > /var/www/html/index.html <<EOF
<!DOCTYPE html>
<html>
<head>
  <title>TechCorp Web Server</title>
  <style>
    body {
      font-family: Arial, sans-serif;
      text-align: center;
      margin: 0;
      padding: 50px;
      background: linear-gradient(to right, #4facfe, #00f2fe);
      color: #333;
    }

    .card {
      background: #ffffff;
      padding: 30px;
      border-radius: 10px;
      max-width: 600px;
      margin: auto;
      box-shadow: 0 8px 20px rgba(0,0,0,0.2);
    }

    h1 {
      color: #0077b6;
      margin-bottom: 5px;
    }

    p {
      line-height: 1.5;
    }

    .info {
      color: #00b4d8;
      font-weight: bold;
    }

    ul {
      text-align: left;
      padding-left: 20px;
    }

    li {
      margin-bottom: 10px;
    }

    hr {
      margin: 20px 0;
      border: 0;
      height: 1px;
      background: #ddd;
    }
  </style>
</head>

<body>
  <div class="card">
    <h1>Akabeli Helen</h1>
    <p><strong>Cloud Engineering Student - AltSchool Africa</strong></p>

    <p>Welcome to my TechCorp Web Server for the Month 1 Terraform Assessment.</p>

    <p><strong>Instance ID:</strong> <span class="info">$INSTANCE_ID</span></p>

    <hr>

    <h3>Project Highlights</h3>
    <ul>
      <li>High availability across multiple zones</li>
      <li>Secure public and private subnets</li>
      <li>Load balancing for web traffic</li>
      <li>Bastion host for secure access</li>
      <li>Scalable cloud architecture</li>
    </ul>
  </div>
</body>
</html>
EOF

# 4. Ensure permissions are correct for Apache to read the file
chown apache:apache /var/www/html/index.html
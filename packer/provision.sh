#!/bin/bash
set -euxo pipefail

# 1. Install packages
sudo dnf update -y
sudo dnf install -y nginx

# 2. Copy app files
sudo mkdir -p /opt/myapp
sudo cp /tmp/app/index.template.html /opt/myapp/index.template.html

# 3. Script that writes the private IP into the web page at boot
sudo tee /usr/local/bin/set-ip.sh > /dev/null <<'EOF'
#!/bin/bash
TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 60")
IP=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/local-ipv4)
sed "s/__PRIVATE_IP__/$IP/g" /opt/myapp/index.template.html > /usr/share/nginx/html/index.html
EOF
sudo chmod +x /usr/local/bin/set-ip.sh

# 4. Run that script at every boot, before nginx starts
sudo tee /etc/systemd/system/set-ip.service > /dev/null <<'EOF'
[Unit]
Description=Write private IP to index.html
After=network-online.target
Wants=network-online.target
Before=nginx.service

[Service]
Type=oneshot
ExecStart=/usr/local/bin/set-ip.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

# 5. Enable on boot
sudo systemctl enable set-ip.service nginx
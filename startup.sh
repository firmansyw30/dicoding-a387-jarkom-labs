#! /bin/bash
# Log file for debugging
LOG_FILE="/tmp/user_data.log"
echo "Starting user_data script" > $LOG_FILE

# Update and install necessary packages
sudo apt-get update -y >> $LOG_FILE 2>&1
sudo apt-get install -y nginx python3-certbot-nginx git curl >> $LOG_FILE 2>&1

# Clone repository (ensure internet access and valid repo)
cd /home/ubuntu
git clone https://github.com/firmansyw30/dicoding-a387-jarkom-labs.git >> $LOG_FILE 2>&1
cd dicoding-a387-jarkom-labs || { echo "Directory not found" >> $LOG_FILE; exit 1; }

# Install Node.js (using NodeSource for simplicity)
curl -fsSL https://deb.nodesource.com/setup_14.x | sudo -E bash - >> $LOG_FILE 2>&1
sudo apt-get install -y nodejs >> $LOG_FILE 2>&1

# Install necessary library
sudo npm install >>$LOG_FILE 2>&1

# Install pm2 globally
sudo npm install -g pm2 >> $LOG_FILE 2>&1

# Start the Express app using pm2
pm2 start app.js --name "simple-express-app-firmansyw30" >> $LOG_FILE 2>&1

# Ensure pm2 restarts on server reboot
pm2 startup systemd >> $LOG_FILE 2>&1
sudo env PATH=$PATH:/usr/bin pm2 startup systemd -u ubuntu --hp /home/ubuntu >> $LOG_FILE 2>&1  # Modify the user if needed
pm2 save >> $LOG_FILE 2>&1

# Set up Nginx to reverse proxy to the app (optional, modify as needed)
# Add Nginx configuration in startup.sh
cat <<EOF | sudo tee /etc/nginx/sites-available/default
server {
    listen 80;
    server_name _;  # Wildcard to match any domain or IP address

    #server_name localhost;

    location / {
        proxy_pass http://localhost:8000;  # Proxy to the local Node.js app
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOF

# Restart Nginx to apply the new configuration
sudo systemctl restart nginx >> $LOG_FILE 2>&1

echo "user_data script completed" >> $LOG_FILE

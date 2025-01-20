#!/bin/bash
sudo apt install -y apache2 ssl-cert
sudo systemctl enable --now apache2
echo "My web Page" | sudo tee /var/www/html/index.html

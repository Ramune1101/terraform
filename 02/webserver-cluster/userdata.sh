#!/bin/bash
yum -y install httpd mod_ssl
echo "My Web" >> /var/www/html/index.html
systemctl enable --now httpd.service
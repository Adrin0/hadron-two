#!/bin/bash
# Run this script inside LXC 105 to install DVWA and Elastic Beats.
# Must be run as root.
# After running, configure Beats to point to your ELK LXC IP.
# See: security/docs/beats-config.md

set -e

echo "Updating system..."
apt update && apt upgrade -y

echo "Installing Apache, MySQL, PHP, and dependencies..."
apt install -y \
  apache2 \
  mysql-server \
  php \
  php-mysqli \
  php-gd \
  php-xml \
  libapache2-mod-php \
  git \
  curl \
  wget \
  apt-transport-https

echo "Enabling Apache rewrite module..."
a2enmod rewrite
systemctl enable --now apache2
systemctl enable --now mysql

echo "Setting up Elastic APT repository..."
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch \
  | gpg --dearmor -o /usr/share/keyrings/elasticsearch-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/elasticsearch-archive-keyring.gpg] \
  https://artifacts.elastic.co/packages/7.x/apt stable main" \
  | tee /etc/apt/sources.list.d/elastic-7.x.list

apt update

echo "Installing Elastic Beats..."
apt install -y filebeat metricbeat packetbeat

systemctl enable filebeat
systemctl enable metricbeat
systemctl enable packetbeat

echo "Cloning DVWA..."
cd /var/www/html
git clone https://github.com/digininja/DVWA.git
chmod -R 777 DVWA

echo "Configuring DVWA..."
cd DVWA/config
cp config.inc.php.dist config.inc.php

echo ""
echo "Installation complete."
echo ""
echo "Next steps:"
echo "  1. Set a MySQL root password and create a DVWA database user:"
echo "       mysql_secure_installation"
echo "       mysql -u root -p"
echo "       CREATE USER '<username>'@'localhost' IDENTIFIED BY '<password>';"
echo "       GRANT ALL PRIVILEGES ON dvwa.* TO '<username>'@'localhost';"
echo "       FLUSH PRIVILEGES;"
echo ""
echo "  2. Update /var/www/html/DVWA/config/config.inc.php with your MySQL credentials."
echo ""
echo "  3. Configure Beats to forward logs to your ELK container."
echo "     See: security/docs/beats-config.md"
echo ""
echo "  4. Complete DVWA setup at: http://$(hostname -I | awk '{print $1}')/DVWA/setup.php"

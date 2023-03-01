#!/usr/bin/env bash

# Setup script for running Blocks behind nginx reverse proxy on a bare-bones Debian 10/11.
# Script is assumed to run as root

# https://stackoverflow.com/questions/821396/aborting-a-shell-script-if-any-command-returns-a-non-zero-value
set -eu

# Show help in case required parameters are empty
if [ $# -lt 1 ]
then
   echo "Perform initial installation and server configuration";
   echo
   exit 1 # Exit script after printing help
fi

# Pick up FQDN or IP address of license server.
# DEPRECATED since this applied only when using remote physical dongle.
# Not needed when using cloud-based license.
# LICENSE_SERVER=$1


echo "••• Bumping max number of file descriptors to something more useful (for, e.g., websockets)"
FDS=5000
echo -e "\nDefaultLimitNOFILE=$FDS\n" >> /etc/systemd/user.conf
echo -e "\nDefaultLimitNOFILE=$FDS\n" >> /etc/systemd/system.conf
echo -e "*       soft    nofile  $FDS\n*       hard    nofile  $FDS\n" >> /etc/security/limits.conf

echo "••• Adding the blocks user account. You can set a password later using this command:  passwd blocks"
useradd -m blocks
BLOCKS_HOME=/home/blocks

# Set up locale to stop pearl from bitching about it
locale-gen en_US.UTF-8

echo "••• Installing Java"
apt-get update
apt-get install -y wget apt-transport-https
wget -O - https://packages.adoptium.net/artifactory/api/gpg/key/public | tee /usr/share/keyrings/adoptium.asc
echo "deb [signed-by=/usr/share/keyrings/adoptium.asc] https://packages.adoptium.net/artifactory/deb $(awk -F= '/^VERSION_CODENAME/{print$2}' /etc/os-release) main" | tee /etc/apt/sources.list.d/adoptium.list

# Update with package info from above repos
apt-get update

# Perform general system software upgrade
apt-get upgrade -y

# Install Java VM
apt-get install -y temurin-11-jdk

# to switch java VM, if you have many, run this later:
#	sudo update-alternatives --config java

echo "••• Installing Chromium (used headless as web renderer by Blocks)"
# Older non-snap Chromium, not being updated (Debian 10 only)
# apt-get install -y chromium
# So use snap-packaged Chromium instead (only option for Debian 11+)
apt install snapd
snap install core
snap install chromium

echo "••• Installing License Key Software"
# download and install codemeter support from our mirror
wget https://pixilab.se/outgoing/blocks/cloud-support/codemeter.deb
apt-get install  -y ./codemeter.deb
rm ./codemeter.deb

wget https://pixilab.se/outgoing/blocks/cloud-support/axprotector.deb
apt-get install  -y ./axprotector.deb
rm ./axprotector.deb


# Add external license server to search list (applies only when using remote physical dongle)
# cmu --clear-serversearchlist
# cmu --add-server $LICENSE_SERVER

# Disable codemeter's webadmin, which isn't needed on the server
systemctl disable codemeter-webadmin.service

echo "••• Installing some useful command line utilities"

# Some additional, useful monitoring and maintenance programs
apt-get install -y htop
# Efficient remote and local file synchronization
apt-get install -y rsync
# Network traffic status monitor
apt-get install -y vnstat
# Network performance
apt-get install -y iftop
# Disk performance
apt-get install -y iotop
# Zip and unzip functionality
apt-get install -y zip

# Install nginx to use as reverse proxy and for serving static files
apt-get install -y nginx

# Copy configuration file (e.g. Notes/nginx.txt) to /etc/nginx/sites-available
# symlink from /etc/nginx/sites-enabled

# Install our custom nginx error page
cp misc/error50x.html /usr/share/nginx/html/

# Reload nginx config by
#	nginx -s reload

echo "••• Configuring firewall"

# Install and configure firewall
# ALTERNATIVELY: Use infrastructure firewall, such as on digitalocean
apt-get install -y ufw
ufw allow OpenSSH
ufw allow "Nginx HTTP"
ufw allow "Nginx HTTPS"
ufw allow http
ufw allow https
ufw allow ssh
ufw --force enable

# Install intrusion detection with basic configuration
apt-get install -y fail2ban

echo "••• Installing LetsEncrypt certbot for SSL certificate (with automatic renewal)"

# Install Lets Encrypt cert support (https://www.digitalocean.com/community/tutorials/how-to-secure-nginx-with-let-s-encrypt-on-debian-10)
apt-get install -y python3-acme python3-certbot python3-mock python3-openssl python3-pkg-resources python3-pyparsing python3-zope.interface
apt-get install -y python3-certbot-nginx
# Then follow instructions here https://certbot.eff.org/lets-encrypt/debianbuster-nginx

# Tell nginx to reload its config when cert is updated
echo '' >> /etc/letsencrypt/cli.ini
echo '# Reload nginx config when cert is updated' >> /etc/letsencrypt/cli.ini
echo 'deploy-hook = systemctl reload nginx' >> /etc/letsencrypt/cli.ini

echo "••• Installing Blocks and associated files"

# Download and unpack Blocks and its "native" directory
cd $BLOCKS_HOME
wget https://pixilab.se/outgoing/blocks/PIXILAB_Blocks_Linux.tar.gz
tar -xzf PIXILAB_Blocks_Linux.tar.gz
rm PIXILAB_Blocks_Linux.tar.gz

# Configure blocks user to use same shell as root
usermod --shell /bin/bash blocks
cp /root/.profile /home/blocks

# Copy root's authorized_keys to the 'blocks' user, to provide access using same method
# This assumes ssh keys have been set up for root (done by default at digitalocean)
mkdir -p /home/blocks/.ssh/
cp /root/.ssh/authorized_keys /home/blocks/.ssh/authorized_keys

# See README for installing .config/systemd/user files and enabling user systemd over ssh
# Make user "blocks" systemd units start on boot
loginctl enable-linger blocks

# Make everything in $BLOCKS_HOME belong to the blocks user
chown -R blocks $BLOCKS_HOME
chgrp -R blocks $BLOCKS_HOME


# Set the desired local time zone for the server
timedatectl set-timezone Europe/Stockholm

echo "••• Checking license server access"
cmu  --list
echo "••• Examine output above, making sure you see your license number. If not shown, please"
echo "    contact PIXILAB for further instrutions on how to obtain and install your license."

# Verify the following setting is in your /etc/ssh/sshd_config
#   PasswordAuthentication no
# Some VPS providers (such as digitalocean) adds this by default, others may not

# See script add-domain.sh for how to add the actual domain


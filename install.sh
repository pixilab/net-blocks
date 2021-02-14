#!/usr/bin/env bash

# Setup script for running Blocks behind nginx reverse proxy on a bare-bones Debian 10.
# Script is assumed to run as root

# https://stackoverflow.com/questions/821396/aborting-a-shell-script-if-any-command-returns-a-non-zero-value
set -eu

# Show help in case required parameters are empty
if [ $# -lt 1 ]
then
   echo "Perform initial installation and server configuration";
   echo
   echo "Usage: $0 <license-server>"
   echo
   exit 1 # Exit script after printing help
fi

# Pick up FQDN or IP address of license server
LICENSE_SERVER=$1

# Location of the Blocks user's home dir
BLOCKS_HOME=/home/blocks

echo "••• Bumping max number of file descriptors to something more useful (for, e.g., websockets)"
FDS=5000
echo -e "DefaultLimitNOFILE=$FDS\n" >> /etc/systemd/user.conf
echo -e "DefaultLimitNOFILE=$FDS\n" >> /etc/systemd/system.conf
echo -e "*       soft    nofile  $FDS\n*       hard    nofile  $FDS\n" >> /etc/security/limits.conf

echo "••• Adding the blocks user account. You can set a password later using this command:  passwd blocks"
useradd -m blocks

# Set up locale to stop pearl from bitching about it
locale-gen en_US.UTF-8

echo "••• Installing Java"
# Add public keys to approve openjdk for apt
apt-get install -y gnupg2
wget -qO - https://adoptopenjdk.jfrog.io/adoptopenjdk/api/gpg/key/public | apt-key add -


# Add jfrog (OpenJDK) repositories
apt-get install -y software-properties-common
add-apt-repository --yes https://adoptopenjdk.jfrog.io/adoptopenjdk/deb/
echo "deb https://adoptopenjdk.jfrog.io/adoptopenjdk/deb buster main" | sudo tee /etc/apt/sources.list.d/adoptopenjdk.list

# Update with package info from above repos
apt-get update

# Perform general system software upgrade
apt-get upgrade -y

# install openj9
apt-get install -y adoptopenjdk-11-openj9
# or, for traditional hotspot VM
#	apt-get install  -y adoptopenjdk-11-hotspot
# to switch java VM
#	sudo update-alternatives --config java

echo "••• Installing License Key Software"
# download and install codemeter support from our mirror
wget -N http://files.pixilab.se/outgoing/blocks/cloud-support/codemeter.deb
apt-get install  -y ./codemeter.deb
rm ./codemeter.deb

wget -N http://files.pixilab.se/outgoing/blocks/cloud-support/axprotector.deb
apt-get install  -y ./axprotector.deb
rm ./axprotector.deb

echo "••• Installing Chromium (used headless as web renderer by Blocks)"
apt-get install -y chromium

# Add external license server to search list
cmu --clear-serversearchlist
cmu --add-server $LICENSE_SERVER

# Disable codemeter's webadmin, which isn't needed on the server
systemctl disable codemeter-webadmin.service

echo "••• Installing some useful command line utilities"

# Command line utility to show disk performance
apt-get install -y iotop

# Command line utility to show network performance
apt-get install -y iftop

#Install general purpose network traffic status monitor
apt-get install -y vnstat

# Some additional, useful monitoring programs
apt-get install -y htop

# Install nginx to use as reverse proxy and for serving static files
apt-get install -y nginx

# Copy configuration file (e.g. Notes/nginx.txt) to /etc/nginx/sites-available
# symlink from /etc/nginx/sites-enabled

# Reload nginx config by
#	nginx -s reload

echo "••• Configuring firewall"

# Install and configure firewall
apt-get install ufw
ufw allow OpenSSH
ufw allow "Nginx HTTP"
ufw allow "Nginx HTTPS"
ufw allow http
ufw allow https
ufw allow ssh
ufw --force enable

echo "••• Installing LetsEncrypt certbot for SSL certificate (with automatic renewal)"

# Install Lets Encrypt cert support (https://www.digitalocean.com/community/tutorials/how-to-secure-nginx-with-let-s-encrypt-on-debian-10)
apt-get install -y python3-acme python3-certbot python3-mock python3-openssl python3-pkg-resources python3-pyparsing python3-zope.interface
apt-get install -y python3-certbot-nginx
# Then follow instructions here https://certbot.eff.org/lets-encrypt/debianbuster-nginx

echo "••• Installing Blocks and associated files"

# Download and unpack Blocks and its "native" directory
cd $BLOCKS_HOME
wget http://files.pixilab.se/outgoing/blocks/PIXILAB_Blocks_Linux.tar.gz
tar -xzf PIXILAB_Blocks_Linux.tar.gz
rm PIXILAB_Blocks_Linux.tar.gz

# Configure blocks user to use same shell as root
usermod --shell /bin/bash blocks
cp /root/.profile /home/blocks

# See README for installing .config/systemd/user files and enabling user systemd over ssh
# Make user "blocks" systemd units start on boot
loginctl enable-linger blocks

chown -R blocks $BLOCKS_HOME
chgrp -R blocks $BLOCKS_HOME

echo "••• Checking license server access"
cmu  --list-network --all-servers
echo "••• Examine output above, make sure you see your license key's serial number"

# See installers/add-domain.sh for how to add the actual domain


#!/usr/bin/env bash

# Setup script for running Blocks behind nginx reverse proxy on a bare-bones Debian 10.
# Script is assumed to run as root

# https://stackoverflow.com/questions/821396/aborting-a-shell-script-if-any-command-returns-a-non-zero-value
set -eu

# Print help and exit
helpFunction() {
   echo "Missing required parameter(s)";
   echo
   echo "Usage: $0 <license-server> "
   echo
   exit 1 # Exit script after printing help
}

# Print helpFunction in case required parameters are empty
if [ -z "$1" ]
then
   helpFunction
fi

# Pick up FQDN or IP address of license server
LICENSE_SERVER=$1

# Location of the Blocks user's home dir
BLOCKS_HOME=/home/blocks

# Bump max number of file descriptors to something more useful (for, e.g., websockets)
FDS=5000
echo -e "DefaultLimitNOFILE=$FDS\n" >> /etc/systemd/user.conf
echo -e "DefaultLimitNOFILE=$FDS\n" >> /etc/systemd/system.conf
echo -e "*       soft    nofile  $FDS\n*       hard    nofile  $FDS\n" >> /etc/security/limits.conf

useradd -m blocks
# to set password, if desired, use
#	passwd blocks

# Add public keys to approve openjdk for apt
apt-get install gnupg2
wget -qO - https://adoptopenjdk.jfrog.io/adoptopenjdk/api/gpg/key/public | apt-key add -


# Add jfrog and certbot repositories
# apt-get install -y software-properties-common
apt-get install -y software-properties-common
add-apt-repository --yes https://adoptopenjdk.jfrog.io/adoptopenjdk/deb/
add-apt-repository --yes ppa:certbot/certbot

# Update with package info from above repos
apt-get update

# install openj9
apt-get install -y adoptopenjdk-11-openj9
# or, for traditional hotspot VM
#	apt-get install  -y adoptopenjdk-11-hotspot
# to switch java VM
#	sudo update-alternatives --config java

# download and install codemeter support from our mirror
wget -N http://ext.pixilab.se/outgoing/blocks/cloud-support/codemeter.deb
apt-get install  -y ./codemeter.deb
wget -N http://ext.pixilab.se/outgoing/blocks/cloud-support/axprotector.deb
apt-get install  -y ./axprotector.deb

# install chromium browser (used headless as web renderer by Blocks)
apt-get install  -y chromium
# remove unwanted codecs (yes, that's a confusing package that REMOVES codecs)
apt-get install  -y chromium-codecs-ffmpeg

# Add external license server to search list
cmu --clear-serversearchlist
cmu --add-server $LICENSE_SERVER

# Disable codemeter's webadmin, which isn't needed on the server
systemctl disable codemeter-webadmin.service

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

# Install Lets Encrypt cert support
apt-get install -y certbot python-certbot-nginx
# Then follow instructions here https://certbot.eff.org/lets-encrypt/debianbuster-nginx

# Install and configure firewall
apt-get install ufw
ufw allow OpenSSH
ufw allow Nginx
ufw allow "Nginx HTTP"
ufw allow "Nginx HTTPS"
ufw allow http
ufw allow https
ufw allow ssh
ufw enable

# Download and unpack Blocks and its "native" directory
cd $BLOCKS_HOME
wget https://pixilab.se/outgoing/blocks/PIXILAB_Blocks_Linux.tar.gz
tar -xzf PIXILAB_Blocks_Linux.tar.gz
rm PIXILAB_Blocks_Linux.tar.gz

# See Notes for installing .config/systemd/user files and enabling user systemd over ssh
# Make user "blocks" systemd units start on boot
loginctl enable-linger blocks

chown -R blocks *
chgrp -R blocks *

# Check you may want to perform at this point to ensure server license can be seen
cmu  --list-network --all-servers

# See installers/add-domain.sh for how to add the actual domain


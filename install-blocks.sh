#!/usr/bin/env bash

# Setup script for running Blocks behind nginx reverse proxy on a bare-bones Debian 10/11.
# Script is assumed to run as root

# https://stackoverflow.com/questions/821396/aborting-a-shell-script-if-any-command-returns-a-non-zero-value
set -eu

#Store the scripts base directory 
if [ -L $0 ] ; then
    BASEDIR=$(cd "$(dirname "$(readlink $0)")"; pwd -P) # for symbolic link
else
    BASEDIR=$(cd "$(dirname "$0")"; pwd -P) # for normal file
fi

echo "••• Bumping max number of file descriptors to something more useful (for, e.g., websockets)"
FDS=5000
echo -e "\nDefaultLimitNOFILE=$FDS\n" >> /etc/systemd/user.conf
echo -e "\nDefaultLimitNOFILE=$FDS\n" >> /etc/systemd/system.conf
echo -e "*       soft    nofile  $FDS\n*       hard    nofile  $FDS\n" >> /etc/security/limits.conf

echo "••• Adding the blocks user account. You can set a password later using this command:  passwd blocks"

# Check if user blocks already exists
if grep -q "blocks" /etc/passwd; then
  echo  "Blocks user already exists"
else
  echo "Adding blocks user"
  useradd -m blocks
fi

# Set up locale to stop pearl from bitching about it
if ! command -v locale-gen &> /dev/null
then
        echo "installing locale-gen"
        apt install -y locales
fi
locale-gen en_US.UTF-8

# specify the block user home dir
BLOCKS_HOME=/home/blocks

# Add Blocks user's systemd unit and config files
mkdir -p $BLOCKS_HOME/.config
cp -R $BASEDIR/config/* $BLOCKS_HOME/.config/

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

echo "••• Configuring firewall for http and ssh access"

# Install and configure firewall
# ALTERNATIVELY: Use infrastructure firewall, such as on digitalocean
apt-get install -y ufw
ufw allow OpenSSH
ufw allow http
ufw allow ssh
ufw allow 8080/tcp
ufw --force enable

# Optionally install intrusion detection with basic configuration
# apt-get install -y fail2ban

echo "••• Installing Blocks and associated files"

# Download and unpack Blocks and its "native" directory
cd $BLOCKS_HOME
wget https://pixilab.se/outgoing/blocks/PIXILAB_Blocks_Linux.tar.gz
tar -xzf PIXILAB_Blocks_Linux.tar.gz
rm PIXILAB_Blocks_Linux.tar.gz

# Configure blocks user to use same shell as root
usermod --shell /bin/bash blocks
cp /root/.profile $BLOCKS_HOME

# Copy root's authorized_keys to the 'blocks' user, to provide access using same method
# This assumes ssh keys have been set up for root (done by default at digitalocean)
mkdir -p $BLOCKS_HOME/.ssh/
cp /root/.ssh/authorized_keys $BLOCKS_HOME/.ssh/authorized_keys

# See README for installing .config/systemd/user files and enabling user systemd over ssh
# Make user "blocks" systemd units start on boot
loginctl enable-linger blocks


# Make everything in $BLOCKS_HOME belong to the blocks user
chown -R blocks $BLOCKS_HOME
chgrp -R blocks $BLOCKS_HOME


# Set the desired local time zone for the server
timedatectl set-timezone Europe/Stockholm

cmu  --list
echo "••• DONE!"
echo "••• Examine output above. If you don't see your license number, please contact"
echo "    PIXILAB for further instrutions on how to obtain and install your license."
echo "    Please set a secure password for blocks user using this command:"
echo "        passwd blocks"
echo "    A license file, once obtained, can be imported using this command:"
echo "        cmu --import --file <filename>"
echo "    Access blocks with http on the server ip-address port 8080. i.e http://10.2.0.10:8080/edit"

# Verify the following setting is in your /etc/ssh/sshd_config
#   PasswordAuthentication no
# Some VPS providers (such as digitalocean) adds this by default, others may not

# See script add-domain.sh for how to add the actual domain


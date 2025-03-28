#!/usr/bin/env bash

# Setup script for installing Blocks.
# Written to run on a bare-bones Debian 10/11, but has also been used on corresponding Ubuntu server edition.
# Script is assumed to run with root privileges

# https://stackoverflow.com/questions/821396/aborting-a-shell-script-if-any-command-returns-a-non-zero-value
set -eu

#Store the scripts base directory
if [ -L $0 ] ; then
    BASEDIR=$(cd "$(dirname "$(readlink $0)")"; pwd -P) # for symbolic link
else
    BASEDIR=$(cd "$(dirname "$0")"; pwd -P) # for normal file
fi

echo "••• Bumping max number of file descriptors to something more useful (for, e.g., websockets)"
FDS=10000
echo -e "\nDefaultLimitNOFILE=$FDS\n" >> /etc/systemd/user.conf
echo -e "\nDefaultLimitNOFILE=$FDS\n" >> /etc/systemd/system.conf
echo -e "*       soft    nofile  $FDS\n*       hard    nofile  $FDS\n" >> /etc/security/limits.conf

echo "••• Adding the blocks user account. You can set a password later using this command:  sudo passwd blocks"
# Check if user blocks already exists
if grep -q '^blocks:' /etc/passwd; then
  echo  "Blocks user already exists"
else
  echo "Adding blocks user"
  useradd -m blocks
fi

# Use apt which is better at installing things in the right order, a bit smarter, and show status bar
# set default options suitable for scripted install
echo -e "APT{Get{Assume-Yes true; Fix-Broken true;}}" > $BASEDIR/apt.conf
export APT_CONFIG=$BASEDIR/apt.conf

# Set the desired local time zone for the server
echo "••• Setting default timezone to Europe/Stockholm. "
timedatectl set-timezone Europe/Stockholm
echo "Reset timezone to you preferred timezone with:"
echo "timedatectl set-timezone Europe/Stockholm. "
echo "Search your nearest timezone with:"
echo "timedatectl list-timezones | grep 'Stockholm'"

# Set up locale to stop pearl from bitching about it
echo "••• Adding locales and generate localisation files. "
if ! command -v locale-gen &> /dev/null
then
        echo "••• locale-gen missing, installing locales."
        apt install locales
fi

# Uncomment the locales needed in /etc/locale.gen to enable them
sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
sed -i -e 's/# sv_SE.UTF-8 UTF-8/sv_SE.UTF-8 UTF-8/' /etc/locale.gen
# Unset LANG (allows ssh session to forward settings when connecting to the server instead)
update-locale LANG
# Generate locales
dpkg-reconfigure --frontend=noninteractive locales

# specify the block user home dir
BLOCKS_HOME=/home/blocks
BLOCKS_ROOT=$BLOCKS_HOME/PIXILAB-Blocks-root

# Java install add repo
echo "••• Adding Adoptium repo for the Java OpenJDK install"
apt update
apt install wget apt-transport-https
wget -O - https://packages.adoptium.net/artifactory/api/gpg/key/public | tee /usr/share/keyrings/adoptium.asc
echo "deb [signed-by=/usr/share/keyrings/adoptium.asc] https://packages.adoptium.net/artifactory/deb $(awk -F= '/^VERSION_CODENAME/{print$2}' /etc/os-release) main" | tee /etc/apt/sources.list.d/adoptium.list

# Update with package info from above repos
apt update

# Perform general system software upgrade
apt upgrade

# Install Java VM
echo "••• Installing Java OpenJDK platform"
apt install temurin-11-jdk

# to switch java VM, if you have many, run this later:
#	sudo update-alternatives --config java

echo "••• Installing Chromium (used headless as web renderer by Blocks)"
# Install snap-packaged Chromium and lock the current version
apt install snapd
snap install core
snap install chromium
snap refresh --hold=forever chromium


# Disable CUPS which isn't needed for anything anyway
snap stop cups
snap disable cups

echo "••• Installing License Key Software"
# download and install codemeter support from our mirror
wget https://pixilab.se/outgoing/blocks/cloud-support/codemeter.deb
apt install ./codemeter.deb
rm ./codemeter.deb

wget https://pixilab.se/outgoing/blocks/cloud-support/axprotector.deb
apt install ./axprotector.deb
rm ./axprotector.deb


# Add external license server to search list (applies only when using remote physical dongle)
# cmu --clear-serversearchlist
# cmu --add-server $LICENSE_SERVER

# Disable codemeter's webadmin, which isn't needed on the server
systemctl disable codemeter-webadmin.service

echo "••• Installing some useful command line utilities"

# Some additional, useful monitoring and maintenance programs
apt install htop
# Efficient remote and local file synchronization
apt install rsync
# Network traffic status monitor
apt install vnstat
# Network performance
apt install iftop
# Disk performance
apt install iotop
# Zip and unzip functionality
apt install zip
# Git, used to download scripts later
apt install git

echo "••• Configuring firewall for Blocks access on port 8080 and ssh access"

# Install and configure firewall
# ALTERNATIVELY: Use infrastructure firewall, such as on digitalocean
apt install ufw
ufw allow OpenSSH
ufw allow ssh
ufw allow 8080/tcp
ufw --force enable

# Optionally install intrusion detection with basic configuration
# apt install fail2ban

# Download latest net-blocks files from git
if [ -d "$BASEDIR/net-blocks" ]; then
  git -C $BASEDIR/net-blocks pull
else
  git clone https://github.com/pixilab/net-blocks.git $BASEDIR/net-blocks
fi

echo "••• Installing Blocks and associated files"
echo "••• Copying systemd units. "
# Add Blocks user's systemd unit and config files
mkdir -p $BLOCKS_HOME/.config
cp -R $BASEDIR/net-blocks/config/* $BLOCKS_HOME/.config/

echo "••• Adding a blocks root directory"
cp -R $BASEDIR/net-blocks/protos/root $BLOCKS_ROOT

# Adding a Blocks' config file
echo "••• Copying blocks configuration file 'PIXILAB-Blocks-config.yml' file to $BLOCKS_HOME"
cp $BASEDIR/net-blocks/protos/PIXILAB-Blocks-config.yml $BLOCKS_HOME/PIXILAB-Blocks-config.yml


# Install drivers, scripts and script support files from github
echo "••• Installing the latest script directory from https://github.com/pixilab/blocks-script"
echo "••• Clone blocks-script repo"
git clone https://github.com/pixilab/blocks-script.git $BASEDIR/blocks-script
echo "••• Check if $BLOCKS_ROOT/script/ exists if not create the directory"
if [ ! -d "$BLOCKS_ROOT/script/" ]; then
  mkdir $BLOCKS_ROOT/script/
fi
echo "••• Copying  files to $BLOCKS_ROOT/script/"
cp -r $BASEDIR/blocks-script/* $BLOCKS_ROOT/script/
echo "••• Cleaning up"
rm -r $BASEDIR/blocks-script

# Download and unpack Blocks and its "native" directory
echo "••• Downloading Blocks from pixilab.se. "
cd $BLOCKS_HOME
wget https://pixilab.se/outgoing/blocks/PIXILAB_Blocks_Linux.tar.gz
echo "••• Installing Blocks and cleaning up. "
tar -xzf PIXILAB_Blocks_Linux.tar.gz
rm PIXILAB_Blocks_Linux.tar.gz


# Configure blocks user to use same shell as root
echo "••• Setting the standard shell for the blocks user. "
usermod --shell /bin/bash blocks
cp /root/.profile $BLOCKS_HOME

# Copy root's authorized_keys to the 'blocks' user, to provide access using same method
# This assumes ssh keys have been set up for root (done by default at digitalocean)
echo "••• Syncing any ssh authorized keys making also the blocks user accessable. "
AUTH=/root/.ssh/authorized_keys
mkdir -p $BLOCKS_HOME/.ssh/
if [ -f $AUTH ]; then
  cp $AUTH $BLOCKS_HOME/.ssh/authorized_keys
fi

# Make user "blocks" systemd units start on boot
echo "••• Enable user lingering on the Blocks user. "
loginctl enable-linger blocks

# Make everything in $BLOCKS_HOME belong to the blocks user
echo "••• Make blocks user owner of all files in blocks home directory: $BLOCKS_HOME. "
chown -R blocks $BLOCKS_HOME
chgrp -R blocks $BLOCKS_HOME

# Make all directories and files under public readable/traversable by all users
find $BLOCKS_ROOT/public/ -type d -print0 | xargs -0 chmod o+x
chmod -R o+r $BLOCKS_ROOT/public/

echo "••• Listing any connected license keys"
cmu  --list
echo "••• DONE!"
echo "••• Examine output above. If you don't see your license number, please contact"
echo "    PIXILAB for further instrutions on how to obtain and install your license."
echo "    Please set a secure password for blocks user using this command:"
echo "        passwd blocks"
echo "    A license file, once obtained, can be imported using this command:"
echo "        cmu --import --file <filename>"
echo "    You can now access blocks with a browser using this servers ip-address port 8080. i.e http://10.2.0.10:8080/edit"

# Clean up
unset APT_CONFIG
rm $BASEDIR/apt.conf

# Verify the following setting is in your /etc/ssh/sshd_config
#   PasswordAuthentication no
# Some VPS providers (such as digitalocean) adds this by default, others may not




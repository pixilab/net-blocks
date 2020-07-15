#!/usr/bin/env bash
# Add the domain to nginx configuration and configure Blocks.

# exit if/when any command fails; https://intoli.com/blog/exit-on-errors-in-bash-scripts/
set -e

# Show help if missing parameter(s)
if [ $# -lt 1 ]
then
   echo "Missing required parameter(s)";
   echo
   echo "Usage: $0 <blocks-server-domain>"
   echo
   exit 1 # Exit script after printing help
fi

# Define variables from command line parameters, and some others
export DOMAIN=$1
HOME_DIR=/home/blocks
BLOCKS_ROOT=$HOME_DIR/PIXILAB-Blocks-root

echo "••• Configuring nginx reverse proxy"
# Configure nginx, after removing default site file
rm /etc/nginx/sites-enabled/default
cp -r etc-nginx/* /etc/nginx
sed -e "s,###DOMAIN###,$DOMAIN,g" <protos/blocks.conf >/etc/nginx/sites-enabled/blocks.conf

echo "••• Configuring up Blocks, with its initial admin user"
cp -r protos/root $BLOCKS_ROOT

# Add Blocks' config file
cp protos/PIXILAB-Blocks-config.yml $HOME_DIR/PIXILAB-Blocks-config.yml

# Add Blocks user's systemd unit and config files
cp -r config/* $HOME_DIR/.config/systemd/

# Copy root's authorized_keys to the 'blocks' user, to provide access using same method
mkdir -p /home/blocks/.ssh/
cp /root/.ssh/authorized_keys /home/blocks/.ssh/authorized_keys

echo "••• Testing and loading nginx configuration. Watch out for any error messages!"
nginx -t
nginx -s reload

# Make all that owned by blocks
chown blocks -R $HOME_DIR

# Enable certbot for the domain
echo
echo "••• Installing free LetsEncrypt SSL certificate for $DOMAIN. Answer questions as prompted"
certbot --nginx -d $DOMAIN

echo "••• Domain added. Now re-login as user 'blocks' and execute   systemctl --user enable --now blocks"

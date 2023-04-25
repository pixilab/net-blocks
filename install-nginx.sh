#!/usr/bin/env bash

# Setup script for running Blocks behind nginx reverse proxy on a bare-bones Debian 10/11.
# Script is assumed to run as root

# https://stackoverflow.com/questions/821396/aborting-a-shell-script-if-any-command-returns-a-non-zero-value
set -eu


# Define variables from command line parameters, and some others
export DOMAIN=$1
BLOCKS_HOME=/home/blocks
BLOCKS_ROOT=$BLOCKS_HOME/PIXILAB-Blocks-root

#Store the scripts base directory 
if [ -L $0 ] ; then
    BASEDIR=$(cd "$(dirname "$(readlink $0)")"; pwd -P) # for symbolic link
else
    BASEDIR=$(cd "$(dirname "$0")"; pwd -P) # for normal file
fi

# Allow for proxy running on another machine (later)
BLOCKS_HOST=localhost


echo "••• Install NGINX"
# Install nginx to use as reverse proxy and for serving static files
apt-get install -y nginx

# Copy configuration file (e.g. Notes/nginx.txt) to /etc/nginx/sites-available
# symlink from /etc/nginx/sites-enabled

# Install our custom nginx error page
cp $BASEDIR/misc/error50x.html /usr/share/nginx/html/

# Reload nginx config by
#	nginx -s reload

echo "••• Configuring firewall for http access"

# Install and configure firewall
# ALTERNATIVELY: Use infrastructure firewall, such as on digitalocean
ufw delete allow 8080/tcp #No need for external access to Blocks with NGINX as reverse proxy
ufw allow "Nginx HTTP"
ufw allow https
ufw --force enable

echo "••• Configuring nginx reverse proxy"


echo "••• Configure NGINX"
# Configure nginx, after removing default site file
rm /etc/nginx/sites-enabled/default
cp -r etc-nginx/* /etc/nginx
sed -e "s,###DOMAIN###,$DOMAIN,g" \
   -e "s,###BLOCKS_HOST###,$BLOCKS_HOST,g" \
<protos/blocks.conf >/etc/nginx/sites-enabled/blocks.conf

echo "••• Testing and loading nginx configuration. Watch out for any error messages!"
nginx -t
nginx -s reload

# Add Blocks' config file

echo "••• Install Blocks config file"
cp protos/PIXILAB-Blocks-config.yml $BLOCKS_HOME/PIXILAB-Blocks-config.yml

# Make all that owned by blocks
chown blocks -R $BLOCKS_HOME

echo "Finished. NGINX is now running as reverse proxy in front of blocks. Access blocks with http on the server ip-address."
echo "If you intend to use your a domain name to access Blocks run the add-domain.sh script after reading that section of the readme documentation "

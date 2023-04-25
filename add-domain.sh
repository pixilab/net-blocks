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
BLOCKS_HOME=/home/blocks
BLOCKS_ROOT=$BLOCKS_HOME/PIXILAB-Blocks-root

# Allow for proxy running on another machine (later)
BLOCKS_HOST=localhost



# Copy configuration file (e.g. Notes/nginx.txt) to /etc/nginx/sites-available
# symlink from /etc/nginx/sites-enabled


# Reload nginx config by
#	nginx -s reload

echo "••• Configuring firewall for https access"

# Install and configure firewall
# ALTERNATIVELY: Use infrastructure firewall, such as on digitalocean

ufw allow "Nginx HTTPS"
ufw allow https
ufw --force enable


echo "••• Installing LetsEncrypt certbot for SSL certificate (with automatic renewal)"

# Install Lets Encrypt cert support (https://www.digitalocean.com/community/tutorials/how-to-secure-nginx-with-let-s-encrypt-on-debian-10)
apt-get install -y python3-acme python3-certbot python3-mock python3-openssl python3-pkg-resources python3-pyparsing python3-zope.interface
apt-get install -y python3-certbot-nginx
# Then follow instructions here https://certbot.eff.org/lets-encrypt/debianbuster-nginx

# Tell nginx to reload its config when cert is updated
echo '' >> /etc/letsencrypt/cli.ini
echo '# Reload nginx config when cert is updated' >> /etc/letsencrypt/cli.ini
echo 'deploy-hook = systemctl reload nginx' >> /etc/letsencrypt/cli.ini


echo "••• Re-configure NGINX"
# Re-onfigure nginx, after removing default site file

if [ -d "/etc/nginx/sites-enabled/default" ]
then
       rm /etc/nginx/sites-enabled/default
fi

cp -r etc-nginx/* /etc/nginx
# Delete the http only config
rm /etc/nginx/pixilab_http.conf
sed -e "s,###DOMAIN###,$DOMAIN,g" \
   -e "s,###BLOCKS_HOST###,$BLOCKS_HOST,g" \
<protos/blocks.conf >/etc/nginx/sites-enabled/blocks.conf

echo "••• Testing and loading nginx configuration. Watch out for any error messages!"
nginx -t
nginx -s reload


# Make all that owned by blocks
chown blocks -R $BLOCKS_HOME

# Enable certbot for the domain
echo
echo "••• Installing free LetsEncrypt SSL certificate for $DOMAIN. Answer questions as prompted"
certbot --nginx -d $DOMAIN

echo "••• Domain added. Now re-login as user 'blocks' and execute   systemctl --user enable --now blocks"

#!/usr/bin/env bash
# Add the domain to nginx configuration.

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

# Allow for proxy running on another machine (later)
BLOCKS_HOST=localhost


# Install and configure firewall
# ALTERNATIVELY: Use infrastructure firewall, such as on digitalocean
echo "••• Reconfiguring firewall for https access"
ufw allow "Nginx HTTPS"
ufw allow https
ufw --force enable

# Install Lets Encrypt cert support (https://www.digitalocean.com/community/tutorials/how-to-secure-nginx-with-let-s-encrypt-on-debian-10)
echo "••• Installing LetsEncrypt certbot for SSL certificate (with automatic renewal)"
apt-get install -y python3-acme python3-certbot python3-mock python3-openssl python3-pkg-resources python3-pyparsing python3-zope.interface
apt-get install -y python3-certbot-nginx
# Instructions here https://certbot.eff.org/lets-encrypt/debianbuster-nginx


# Tell nginx to reload its config when cert is updated
echo '' >> /etc/letsencrypt/cli.ini
echo '# Reload nginx config when cert is updated' >> /etc/letsencrypt/cli.ini
echo 'deploy-hook = systemctl reload nginx' >> /etc/letsencrypt/cli.ini



# Re-onfigure nginx, after removing default site file
echo "••• Re-configuring NGINX for the domain name"
rm -f /etc/nginx/sites-enabled/default
echo "••• Copy configuration"
cp -r etc-nginx/* /etc/nginx
# Delete the http only config
echo "••• Configuring"
rm -f /etc/nginx/conf.d/pixilab_http.conf
sed -e "s,###DOMAIN###,$DOMAIN,g" \
   -e "s,###BLOCKS_HOST###,$BLOCKS_HOST,g" \
<protos/blocks.conf >/etc/nginx/sites-enabled/blocks.conf

echo "••• Testing and loading nginx configuration. Watch out for any error messages!"
nginx -t
nginx -s reload

# Enable certbot for the domain
echo
echo "••• Installing free LetsEncrypt SSL certificate for $DOMAIN. Answer questions as prompted"
certbot --nginx -d $DOMAIN
echo "••• DONE!"
echo "••• Domain added. Now re-login as user 'blocks' and execute   systemctl --user enable --now blocks"

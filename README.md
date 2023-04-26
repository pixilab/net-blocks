# IMPORTANT

This is an **unsupported example**. While we attempt to keep this up to date and working as described for the desired target audience and platform, this is NOT a PIXILAB product. If you need help setting up Blocks in the cloud, or on some other server, we may be able to assist you for a fee. Contact info@pixilab.se for more information.

## Scripts to build a Blocks server in the cloud

These scripts and files helps with installing PIXILAB Blocks on a VPS (Virtual Private Server) as well as some other "plain vanilla" server environments based on Debian 10 or similar operating systems (e.g. Ubuntu). It was initially devised for a Digital Ocean Debian 10 droplet, but has been used successfully with other hosting providers including Microsoft Azure, Linode and Vultr.

The scripts and instructions presented here assume familiarity with VPSes in general, the concept of private/public keys, domain names, DNS entries and the linux terminal. Items within angle brackets shown below are placeholders, to be substituted with your own values/names as appropriate. Items in `monospaced font` are to be entered, one line at a time, at the server's command prompt. The initial installation is assumed to be done by the root user. If that user account is not available, you need to prepend commands with *sudo*.

## Instructions

The installation is done in three separate steps. 
Step 1. Installs Blocks and dependencies. This step leaves us with a server listening on port 8080. (http://<ip-of-your-server>:8080/edit will open Blocks editor) If this is all you need no further action is required.
Step 2. Installs NGINX to act as a reverse proxy in front of Blocks. This step leaver us with a server listening on port 80.(http://<ip-of-your-server>/edit will open Blocks editor) If this is all you need no further action is required.
Step 3. Adds a domain name, certificates and makes NGINX listen to port 443. Enables https access on standard https port 443. (https://<server-domain-namer>/edit will open Blocks editor)

Create the droplet at digitalocean.com (or equivalent), using a private key for authentication. This can also be a virtual server running Debian-based Linux. This script is tested on Debian and Ubuntu 22.04LTS minimized server.

Inspect the install scripts for details. 

Log in to the server using ssh as the root (or sudoer) user.

`ssh <username>@<ip-of-your-server>`

Once logged in, run the following commands. (Remember to prepend with `sudo` if not doing this as the root user)

`apt update`

`apt -y upgrade`

`apt -y install git`

`git clone https://github.com/pixilab/net-blocks.git`

Enter your credentials if requested.

`cd net-blocks`

`chmod u+x *.sh`

`sudo ./install.sh`

Make sure the script makes it all the way to "••• DONE!". If not, examine the output for errors and correct script and files as necessary to complete the installation.

If the output shown at the end of the script run does not include your Blocks license number, you must obtain a cloud license from PIXILAB. The license is delivered as a file, which is then transferred to the server and with and imported to the license system.
To transfer a license file use scp like this:
scp <your-local-file> <user>@<ip-of-your-server>:/net-blocks

`cmu --import --file <filename>`

Verify that the license is imported OK using the command `cmu --list`, which should now show your license number.

Set a password for the `blocks` user using the command:
`passwd blocks`


### Optional set up domain name
Set up the domain name to be used, along with a SSL certificate (HTTPS) for your domain. This assumes that a DNS entry has been established, as mentioned above, pointing your domain name to your newly created server.


`sudo ./add-domain.sh _blocks-server-domain-name_`

Enter your email address and other preferences when prompted by the certbot. Select "2 - Redirect - Make all requests redirect to secure HTTPS access" when prompted.

Make sure the script makes it all the way to "••• Domain added."

Log out of the root account by

`exit`


### Start the server now and on boot

Log back in, now as the blocks user

`ssh blocks@<ip-of-your-droplet>`

Enable and start Blocks

`systemctl --user enable --now blocks`

Verify blocks was started OK

`systemctl --user status blocks`

Looking for its status being _Active: active (running)_

### Firewall
Depending on the setup the firewall may need further configuration.  I.e if we want to access Blocks from some existing load balancer or reverse proxy ww must allow access to Blocks on port 8080. 

Example command:

sudo ufw allow from <ip_of_reverse_proxy> proto tcp to any port 8080


Finally, log into your new Blocks server using its domain name. User name "admin", with the initial password to be provided by PIXILAB on request, and then change the admin user's password to your liking on the Manage page.

Some further details related to using nginx as a reverse proxy for Blocks can be found here:

https://pixilab.se/docs/blocks/server/nginx

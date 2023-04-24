# IMPORTANT

This is an **unsupported example**. While we attempt to keep this up to date and working as described for the desired target audience and platform, this is NOT a PIXILAB product. If you need help setting up Blocks in the cloud, or on some other server, we may be able to assist you for a fee. Contact info@pixilab.se for more information.

## Scripts to build a Blocks server in the cloud

These scripts and files helps with installing PIXILAB Blocks on a VPS (Virtual Private Server) as well as some other "plain vanilla" server environments based on Debian 10 or similar operating systems (e.g. Ubuntu). It was initially devised for a Digital Ocean Debian 10 droplet, but has been used successfully with other hosting providers including Microsoft Azure, Linode and Vultr.

The scripts and instructions presented here assume familiarity with VPSes in general, the concept of private/public keys, domain names, DNS entries and the linux terminal. Items within angle brackets shown below are placeholders, to be substituted with your own values/names as appropriate. Items in `monospaced font` are to be entered, one line at a time, at the server's command prompt. The initial installation is assumed to be done by the root user. If that user account is not available, you need to prepend  commands with *sudo*.

## Instructions
Create the droplet at digitalocean.com (or equivalent), using a private key for authentication.

Create a DNS entry in some suitable DNS you have control over, such as Cloudflare (they provide free DNS services). Specify your new server's domain name (possibly using a sub-domain) and make sure it points to the IP address of the droplet. Wait for this name to propagate (e.g., use *nslookup* or similar tool to check).

Log in to the VPS using ssh as the root user.

`ssh root@<ip-of-your-droplet>`

Once logged in, run the following commands.

`apt update`

`apt -y upgrade`

`apt -y install git`

`git clone https://github.com/pixilab/net-blocks.git`

Enter your credentials if requested.

`cd net-blocks`

`chmod u+x *.sh`

`sudo ./install.sh`

Make sure the script makes it all the way to "••• DONE!". If not, examine the output for errors and correct script and files as necessary to complete the installation.

If the output shown at the end of the script run does not include your Blocks license number, you need to obtain a license from PIXILAB. That license is delivered as a file, which is then (after being transferred to the server) imported like this:

`cmu --import --file <filename>`

Verify that the license is imported OK using the command `cmu --list`, which should now show your license number.

Set a password for the `blocks` user using the command:
`passwd blocks`


# Optional set up domain name
Set up the domain name to be used, along with a SSL certificate (HTTPS) for your domain. This assumes that a DNS entry has been established, as mentioned above, pointing your domain name to your newly created server.


`sudo ./add-domain.sh _blocks-server-domain-name_`

Enter your email address and other preferences when prompted by the certbot. Select "2 - Redirect - Make all requests redirect to secure HTTPS access" when prompted.

Make sure the script makes it all the way to "••• Domain added."

Log out of the root account by

`exit`


# Start the server now and on boot

Log back in, now as the blocks user

`ssh blocks@<ip-of-your-droplet>`

Enable and start Blocks

`systemctl --user enable --now blocks`

Verify blocks was started OK

`systemctl --user status blocks`

Looking for its status being _Active: active (running)_

Finally, log into your new Blocks server using its domain name. User name "admin", with the initial password to be provided by PIXILAB on request, and then change the admin user's password to your liking on the Manage page.

Some further details related to using nginx as a reverse proxy for Blocks can be found here:

https://pixilab.se/docs/blocks/server/nginx

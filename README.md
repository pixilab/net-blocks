# Scripts to build a Blocks server in the cloud

Developed and tested on digitalocean droplet based on Debian 10. In the instructions below, items within <angle brackets> are placeholders, to be substituted with your own values as appropriate. Items in `monospaced font` are to be entered, one line at a time, at the server's command prompt

## Instructions
Create the droplet at digitalocean.com, preferably using a public key for authentication.

Add a DNS entry giving the new server a domain name (possibly using a sub-domain), and make sure it points to the IP address of the droplet. Wait for this name to propagate (you may use nslookup or similar to verify this).

Log in to the droplet using ssh as the root user

`ssh root@<ip-of-your-droplet>`

Once logged in, run the following commands

`apt update`

`apt -y upgrade`

`apt -y install git`

`git clone https://github.com/TheWizz/net-blocks.git`

Enter your credentials if requested.

`cd net-blocks`

`chmod u+x *.sh`

`./install.sh <license-server-domain-or-ip>`

Make sure the script makes it all the way to "••• Examine output above, make sure you see your license key's serial number", and do so. If not, examint the output for errors and correct the script as necessary.

`./add-domain.sh _blocks-server-domain-name_`

Enter your email address and other preferences when prompted by the certbot. Select "2 - Redirect - Make all requests redirect to secure HTTPS access" when prompted.

Make sure the script makes it all the way to "••• Domain added."

Log out of the root account by

`exit`

Log back in, now as the blocks user

`ssh blocks@<ip-of-your-droplet>`

OPTIONALLY: For the latest and greatest, update Blocks to the latest beta version

`rm PIXILAN.jar`

`wget http://pixilab.se/outgoing/blocks/4.3b/PIXILAN.jar`

substituting the correct URL to the desired Blocks beta version, as approriate.

Enable and start Blocks

`systemctl --user enable --now blocks`

Verify blocks was started OK

`systemctl --user status blocks`

Looking for its status being _Active: active (running)_

Access your newfangled Blocks server using its domain name. Log in as "admin", with the initial password provided by PIXILAB, and change the admin user's password to your liking on the Manage page.

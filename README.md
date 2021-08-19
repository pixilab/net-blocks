# Scripts to build a Blocks server in the cloud

Developed and tested on digital ocean droplet based on Debian 10. In the instructions below, items within angle brackets are placeholders, to be substituted with your own values as appropriate. Items in `monospaced font` are to be entered, one line at a time, at the server's command prompt

## Instructions
Create the droplet at digitalocean.com, preferably using a public key for authentication.

Create a DNS entry (in some suitable DNS you have control over). Specify the name new server's domain name (possibly using a sub-domain) and make sure it points to the IP address of the droplet. Wait for this name to propagate (e.g., use nslookup or similar tool to check).

Log in to the droplet using ssh as the root user.

`ssh root@<ip-of-your-droplet>`

Once logged in, run the following commands.

`apt update`

`apt -y upgrade`

`apt -y install git`

`git clone https://github.com/TheWizz/net-blocks.git`

Enter your credentials if requested.

`cd net-blocks`

`chmod u+x *.sh`

`sudo ./install.sh <license-server-domain-or-ip>`

Make sure the script makes it all the way to "••• Examine output above, make sure you see your license key's serial number", and do so. If not, examint the output for errors and correct the script as necessary.

`sudo ./add-domain.sh _blocks-server-domain-name_`

Enter your email address and other preferences when prompted by the certbot. Select "2 - Redirect - Make all requests redirect to secure HTTPS access" when prompted.

Make sure the script makes it all the way to "••• Domain added."

Log out of the root account by

`exit`

Log back in, now as the blocks user

`ssh blocks@<ip-of-your-droplet>`

OPTIONALLY: For the latest and greatest, update Blocks to the latest beta version

`rm PIXILAN.jar`

`wget http://pixilab.se/outgoing/blocks/5.3b/PIXILAN.jar`

IMPORTANT: Substitute the correct URL to the desired Blocks beta version above.

Enable and start Blocks

`systemctl --user enable --now blocks`

Verify blocks was started OK

`systemctl --user status blocks`

Looking for its status being _Active: active (running)_

Access your newfangled Blocks server using its domain name. Log in as "admin", with the initial password provided by PIXILAB, and change the admin user's password to your liking on the Manage page.


## Setting up CodeMeter License server

A license server needs to be enabled on a computer that can be accessed under the name specified as a parameter to the install.sh command. Install the CodeMeter software on that computer as well (see inside the install.sh script for how you may do so on Linux). Make sure the port used for remote CodeMeter access (default is 22350) is open in any firewall.

Stop the CodeMeter service:

`sudo systemctl stop codemeter`

Edit its configuration file:

`sudo nano /etc/wibu/CodeMeter/Server.ini`

Enable the IsNetworkServer option by setting it to 1:

`IsNetworkServer=1` 

Save the file and exit the editor, then start and enable the CodeMeter service:

`sudo systemctl enable --now codemeter`

You can verify access to the CodeMeter service from the outside like this:

`telnet <name-or-ip-of-codemeter-server> 22350`

This should connect without error, indicating that the port can be reached and that CodeMeter is enabled to listen on it.


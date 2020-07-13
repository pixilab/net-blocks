# Install only security updates.
# From https://serverfault.com/questions/270260/how-do-you-use-apt-get-to-only-install-critical-security-updates-on-ubuntu/282518#282518

apt-get update
apt-get install -y --only-upgrade $( apt-get --just-print upgrade | awk 'tolower($4) ~ /.*security.*/ || tolower($5) ~ /.*security.*/ {print $2}' | sort | uniq )

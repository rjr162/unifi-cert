# unifi-cert

This script enables simple implementation of a Let's Encrypt certificate with the UniFi controller.
It uses the Let's Encrypt certbot and the built in web server for Domain Control Validation.

It will attempt to download 'certbot' from EFF if your system does not already have a copy, and places
the generated Let's Encrypt files into the default locations in /etc/letsencrypt.

The script also assumes the UniFi controller software is located in the default location and places the
generated Java Key Store (JKS) into the default location after backing up the original.

This script will also verify a certificate for the specified domain already exists. If it doesn't, it
will create a new one, but if it does exist it will tell certbot renew the existing one.

All logs are dumped to /var/log/unifi/ by default.

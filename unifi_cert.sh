#!/bin/bash

# Adjust these variables to what you require
DOMAIN="your.domain.name"
EMAIL="youremail@gmail.com"
# These shouldn't need to be changed
LEP="/etc/letsencrypt/live"
UEP="/usr/lib/unifi/data"
JKSP="aircontrolenterprise"

# Spit out messages to console
function bagthis {
  for e in "${@}"; do
    echo "${e}"
  done
}

# Create a new header line in the unifi-certbot.log log file

echo -e "\n------- `date` ------" >> /var/log/unifi-certbot.log

# Determine if a Let's Encrypt certificate already exists or not. If not, create. If so, renew

if [[ ! -d ${LEP}/${DOMAIN} ]]; then
  certbot certonly -m ${EMAIL} -d ${DOMAIN} --agree-tos --standalone >> /var/log/unifi-certbot.log 2>&1
else
  certbot renew >> /var/log/unifi-certbot.log 2>&1
fi

# If certbot process fails, print error alert to console

if [[ ${?} -gt 0 ]]; then
  bagthis "Error running certbot" "Please check /var/log/unifi-chatbot.log for details"
  exit 1
fi

# Now we mash the Let's Encrypt x509, key, and CA into a PKCS12

openssl pkcs12 -export -in ${LEP}/${DOMAIN}/cert.pem -inkey ${LEP}/${DOMAIN}/privkey.pem -out ${LEP}/${DOMAIN}/unifi.p12 \
  -name unifi -CAfile ${LEP}/${DOMAIN}/chain.pem -caname root -passout pass:${JKSP} >> /var/log/unifi-certbot.log 2>&1

# If the openssl process fails, print error alert to console

if [[ ${?} -gt 0 ]]; then
  bagthis "Error generating PKCS12" "Please check /var/log/unifi-chatbot.log for details"
  exit 1
fi

# Let's backup the existing Java Keystore just in case the new one is broken

if [[ -f ${UEP}/keystore ]]; then
  mv ${UEP}/keystore ${UEP}/keystore.`date +%m%d%y`
fi

# Time to create the new JKS!

#keytool -importkeystore -deststorepass ${JKSP} -destkeypass ${JKSP} -destkeystore ${UEP}/keystore -srckeystore ${LEP}/${DOMAIN}/unifi.p12 -srcstoretype PKCS12 -srcstorepass ${JKSP} -alias unifi >> /var/log/unifi-certbot.log 2&>1
keytool -importkeystore -deststorepass ${JKSP} -destkeypass ${JKSP} -destkeystore ${UEP}/keystore -srckeystore ${LEP}/${DOMAIN}/unifi.p12 -srcstoretype PKCS12 -srcstorepass ${JKSP} -alias unifi

# If the Keytool app process fails, print error alert to console

if [[ ${?} -gt 0 ]]; then
  bagthis "Error creating Java Key Store" "Please check /var/log/unifi-chatbot.log for details"
  exit 1
fi

# We got this far, so all of the above must have gone swell! Let's restart the unifi service to get the new cert in place

service unifi restart >> /var/log/unifi-certbot.log 2>&1

echo "Let's Encrypt certificate is in place and the UniFi service has been restarted"

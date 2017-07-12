#!/bin/bash

DOMAIN="your.domain.name"
EMAIL="youremail@gmail.com"
# These shouldn't need to be changed
LEP="/etc/letsencrypt/live"
UEP="/usr/lib/unifi/data"
JKSP="aircontrolenterprise"

function bagthis {
  for e in "${@}"; do
    echo "${e}"
  done
}

echo -e "\n------- `date` ------" >> /var/log/unifi-certbot.log

if [[ ! -d ${LEP}/${DOMAIN} ]]; then
  certbot certonly -m ${EMAIL} -d ${DOMAIN} --agree-tos --standalone >> /var/log/unifi-certbot.log 2>&1
else
  certbot renew >> /var/log/unifi-certbot.log 2>&1
fi

if [[ ${?} -gt 0 ]]; then
  bagthis "Error running certbot" "Please check /var/log/unifi-chatbot.log for details"
  exit 1
fi

openssl pkcs12 -export -in ${LEP}/${DOMAIN}/cert.pem -inkey ${LEP}/${DOMAIN}/privkey.pem -out ${LEP}/${DOMAIN}/unifi.p12 \
  -name unifi -CAfile ${LEP}/${DOMAIN}/chain.pem -caname root -passout pass:${JKSP} >> /var/log/unifi-certbot.log 2>&1

if [[ ${?} -gt 0 ]]; then
  bagthis "Error generating PKCS12" "Please check /var/log/unifi-chatbot.log for details"
  exit 1
fi

if [[ -f ${UEP}/keystore ]]; then
  mv ${UEP}/keystore ${UEP}/keystore.`date +%m%d%y`
fi

#keytool -importkeystore -deststorepass ${JKSP} -destkeypass ${JKSP} -destkeystore ${UEP}/keystore -srckeystore ${LEP}/${DOMAIN}/unifi.p12 -srcstoretype PKCS12 -srcstorepass ${JKSP} -alias unifi >> /var/log/unifi-certbot.log 2&>1
keytool -importkeystore -deststorepass ${JKSP} -destkeypass ${JKSP} -destkeystore ${UEP}/keystore -srckeystore ${LEP}/${DOMAIN}/unifi.p12 -srcstoretype PKCS12 -srcstorepass ${JKSP} -alias unifi

if [[ ${?} -gt 0 ]]; then
  bagthis "Error creating Java Key Store" "Please check /var/log/unifi-chatbot.log for details"
  exit 1
fi

service unifi restart >> /var/log/unifi-certbot.log 2>&1

echo "Let's Encrypt certificate is in place and the UniFi service has been restarted"

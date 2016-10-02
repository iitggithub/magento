#!/bin/sh
set -e

# Try to set servername
if [ -n ${SERVERNAME} ]
  then
  echo ${SERVERNAME} >/etc/httpd/conf.d/server_name.conf
fi

# Configure SSL certificates if they exist
test -f /etc/httpd/ssl/server.crt && sed -i "s/^SSLCertificateFile.*/SSLCertificateFile \/etc\/httpd\/ssl\/server.crt/g" /etc/httpd/conf.d/ssl.conf
test -f /etc/httpd/ssl/server.key && sed -i "s/^SSLCertificateKeyFile.*/SSLCertificateKeyFile \/etc\/httpd\/ssl\/server.key/g" /etc/httpd/conf.d/ssl.conf
test -f /etc/httpd/ssl/server-chain.crt && sed -i "s/^#SSLCertificateChainFile.*/SSLCertificateChainFile \/etc\/httpd\/ssl\/server-chain.crt/g" /etc/httpd/conf.d/ssl.conf
test -f /etc/httpd/ssl/ca-bundle.crt && sed -i "s/^#SSLCACertificateFile.*/SSLCACertificateFile \/etc\/httpd\/ssl\/ca-bundle.crt/g" /etc/httpd/conf.d/ssl.conf

# Apache gets grumpy about PID files pre-existing
rm -f /var/run/httpd/httpd.pid

exec httpd -DFOREGROUND

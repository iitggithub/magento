#!/bin/sh
set -e

# This file does lots of running around before launching httpd

# Try to set servername
if [ -n "${APACHE_SERVERNAME}" ]
  then
  echo "Setting ServerName to '${APACHE_SERVERNAME}' in /etc/httpd/conf.d/server_name.conf."
  echo "ServerName ${APACHE_SERVERNAME}" >/etc/httpd/conf.d/server_name.conf
fi

# Configure SSL certificates if they exist
test -f /etc/httpd/ssl/server.crt && echo "Found /etc/httpd/ssl/server.crt. Configuring /etc/httpd/conf.d/ssl.conf." && sed -i "s/^SSLCertificateFile.*/SSLCertificateFile \/etc\/httpd\/ssl\/server.crt/g" /etc/httpd/conf.d/ssl.conf
test -f /etc/httpd/ssl/server.key && echo "Found /etc/httpd/ssl/server.key. Configuring /etc/httpd/conf.d/ssl.conf." && sed -i "s/^SSLCertificateKeyFile.*/SSLCertificateKeyFile \/etc\/httpd\/ssl\/server.key/g" /etc/httpd/conf.d/ssl.conf
test -f /etc/httpd/ssl/server-chain.crt && echo "Found /etc/httpd/ssl/server-chain.crt. Configuring /etc/httpd/conf.d/ssl.conf." && sed -i "s/^#SSLCertificateChainFile.*/SSLCertificateChainFile \/etc\/httpd\/ssl\/server-chain.crt/g" /etc/httpd/conf.d/ssl.conf
test -f /etc/httpd/ssl/ca-bundle.crt && echo "Found /etc/httpd/ssl/ca-bundle.crt. Configuring /etc/httpd/conf.d/ssl.conf." && sed -i "s/^#SSLCACertificateFile.*/SSLCACertificateFile \/etc\/httpd\/ssl\/ca-bundle.crt/g" /etc/httpd/conf.d/ssl.conf

# Allows the user to turn mod_security off
if [ -n "${MOD_SECURITY_ENABLE}" ]
  then
  if [ ${MOD_SECURITY_ENABLE} -eq 0 ]
    then
    sed -i 's/SecRuleEngine On/SecRuleEngine DetectionOnly/g' /etc/httpd/conf.d/mod_security.conf
    else
    sed -i 's/SecRuleEngine DetectionOnly/SecRuleEngine On/g' /etc/httpd/conf.d/mod_security.conf
  fi
fi

# Skips the web interface setup wizard
# If all of the variables are set
if [ -n "${MAGENTO_LOCALE}" ] && \
   [ -n "${MAGENTO_TIMEZONE}" ] && \
   [ -n "${MAGENTO_DEFAULT_CURRENCY}" ] && \
   [ -n "${MYSQL_HOST}" ] && \
   [ -n "${MYSQL_DATABASE}" ] && \
   [ -n "${MYSQL_USER}" ] && \
   [ -n "${MYSQL_PASSWORD}" ] && \
   [ -n "${MAGENTO_URL}" ] && \
   [ -n "${MAGENTO_SKIP_URL_VALIDATION}" ] && \
   [ -n "${MAGENTO_USE_REWRITES}" ] && \
   [ -n "${MAGENTO_USE_SECURE}" ] && \
   [ -n "${MAGENTO_SECURE_BASE_URL}" ] && \
   [ -n "${MAGENTO_SECURE_ADMIN}" ] && \
   [ -n "${MAGENTO_ADMIN_FIRSTNAME}" ] && \
   [ -n "${MAGENTO_ADMIN_LASTNAME}" ] && \
   [ -n "${MAGENTO_ADMIN_EMAIL}" ] && \
   [ -n "${MAGENTO_ADMIN_USERNAME}" ] && \
   [ -n "${MAGENTO_ADMIN_PASSWORD}" ]
  then
  echo
  echo "----------------------------------------------------------------------"
  echo "Running install.php based on: "
  echo "----------------------------------------------------------------------"
  echo "MAGENTO_LOCALE: '${MAGENTO_LOCALE}'"
  echo "MAGENTO_TIMEZONE: '${MAGENTO_TIMEZONE}'"
  echo "MAGENTO_DEFAULT_CURRENCY: '${MAGENTO_DEFAULT_CURRENCY}'"
  echo "MYSQL_HOST: '${MYSQL_HOST}'"
  echo "MYSQL_DATABASE: '${MYSQL_DATABASE}'"
  echo "MYSQL_USER: '${MYSQL_USER}'"
  echo "MYSQL_PASSWORD: '${MYSQL_PASSWORD}'"
  echo "MAGENTO_URL: '${MAGENTO_URL}'"
  echo "MAGENTO_SKIP_URL_VALIDATION: '${MAGENTO_SKIP_URL_VALIDATION}'"
  echo "MAGENTO_USE_REWRITES: '${MAGENTO_USE_REWRITES}'"
  echo "MAGENTO_USE_SECURE: '${MAGENTO_USE_SECURE}'"
  echo "MAGENTO_SECURE_BASE_URL: '${MAGENTO_SECURE_BASE_URL}'"
  echo "MAGENTO_SECURE_ADMIN: '${MAGENTO_SECURE_ADMIN}'"
  echo "MAGENTO_ADMIN_FIRSTNAME: '${MAGENTO_ADMIN_FIRSTNAME}'"
  echo "MAGENTO_ADMIN_LASTNAME: '${MAGENTO_ADMIN_LASTNAME}'"
  echo "MAGENTO_ADMIN_EMAIL: '${MAGENTO_ADMIN_EMAIL}'"
  echo "MAGENTO_ADMIN_USERNAME: '${MAGENTO_ADMIN_USERNAME}'"
  echo "MAGENTO_ADMIN_PASSWORD: '${MAGENTO_ADMIN_PASSWORD}'"
  echo "----------------------------------------------------------------------"
  echo
  php -f /var/www/html/install.php -- --license_agreement_accepted "yes" --locale $MAGENTO_LOCALE --timezone $MAGENTO_TIMEZONE --default_currency $MAGENTO_DEFAULT_CURRENCY --db_host $MYSQL_HOST --db_name $MYSQL_DATABASE --db_user $MYSQL_USER --db_pass $MYSQL_PASSWORD --url $MAGENTO_URL --skip_url_validation "${MAGENTO_SKIP_URL_VALIDATION}" --use_rewrites "${MAGENTO_USE_REWRITES}" --use_secure "${MAGENTO_USE_SECURE}" --secure_base_url "${MAGENTO_SECURE_BASE_URL}" --use_secure_admin "${MAGENTO_SECURE_ADMIN}" --admin_firstname $MAGENTO_ADMIN_FIRSTNAME --admin_lastname $MAGENTO_ADMIN_LASTNAME --admin_email $MAGENTO_ADMIN_EMAIL --admin_username $MAGENTO_ADMIN_USERNAME --admin_password $MAGENTO_ADMIN_PASSWORD
  chown -vR apache:apache /var/www/html
fi

# Apache gets grumpy about PID files pre-existing
rm -vf /var/run/httpd/httpd.pid

if [ ! -f /var/lib/aide/aide.db.gz ]
  then
  echo "Generating a new AIDE database in /var/lib/aide/aide.db.gz..."
  /usr/sbin/aide --init && mv -vf /tmp/aide.db.new.gz /var/lib/aide/aide.db.gz
fi

echo "httpd starting as process 1 ..."
exec httpd -DFOREGROUND

#!/bin/sh
set -e

# Try to set servername
if [ -n "${MAGENTO_SERVERNAME}" ]
  then
  echo ${MAGENTO_SERVERNAME} >/etc/httpd/conf.d/server_name.conf
fi

# Configure SSL certificates if they exist
test -f /etc/httpd/ssl/server.crt && sed -i "s/^SSLCertificateFile.*/SSLCertificateFile \/etc\/httpd\/ssl\/server.crt/g" /etc/httpd/conf.d/ssl.conf
test -f /etc/httpd/ssl/server.key && sed -i "s/^SSLCertificateKeyFile.*/SSLCertificateKeyFile \/etc\/httpd\/ssl\/server.key/g" /etc/httpd/conf.d/ssl.conf
test -f /etc/httpd/ssl/server-chain.crt && sed -i "s/^#SSLCertificateChainFile.*/SSLCertificateChainFile \/etc\/httpd\/ssl\/server-chain.crt/g" /etc/httpd/conf.d/ssl.conf
test -f /etc/httpd/ssl/ca-bundle.crt && sed -i "s/^#SSLCACertificateFile.*/SSLCACertificateFile \/etc\/httpd\/ssl\/ca-bundle.crt/g" /etc/httpd/conf.d/ssl.conf

# Skips the web interface setup wizard
# If all of the variables are set
if [ -n "${MAGENTO_LOCALE}" ] && [ -n "${MAGENTO_LOCALE}" ] && [ -n "${MAGENTO_DEFAULT_CURRENCY}" ] && [ -n "${MAGENTO_DEFAULT_CURRENCY}" ] && [ -n "${MAGENTO_DEFAULT_CURRENCY}" ] && [ -n "${MAGENTO_ADMIN_LASTNAME}" ] && [ -n "${MAGENTO_ADMIN_EMAIL}" ] && [ -n "${MAGENTO_ADMIN_USERNAME}" ] && [ -n "${MAGENTO_ADMIN_PASSWORD}" ]
  then
  php -f /var/www/html/install.php -- --license_agreement_accepted "yes" --locale $MAGENTO_LOCALE --timezone $MAGENTO_TIMEZONE --default_currency $MAGENTO_DEFAULT_CURRENCY --db_host $MYSQL_HOST --db_name $MYSQL_DATABASE --db_user $MYSQL_USER --db_pass $MYSQL_PASSWORD --url $MAGENTO_URL --skip_url_validation "yes" --use_rewrites "no" --use_secure "no" --secure_base_url "" --use_secure_admin "no" --admin_firstname $MAGENTO_ADMIN_FIRSTNAME --admin_lastname $MAGENTO_ADMIN_LASTNAME --admin_email $MAGENTO_ADMIN_EMAIL --admin_username $MAGENTO_ADMIN_USERNAME --admin_password $MAGENTO_ADMIN_PASSWORD
fi

# Makes changes to the container if we're just testing
if [ ${MAGENTO_TESTING} -eq 1 ]
  then
  # Disables cookie stuff
fi

# Apache gets grumpy about PID files pre-existing
rm -f /var/run/httpd/httpd.pid

exec httpd -DFOREGROUND

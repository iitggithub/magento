FROM iitgdocker/apache:5.6

MAINTAINER "The Ignorant IT Guy" <iitg@gmail.com>

ENV MAGENTO_VERSION 1.9.3.0

RUN yum -y --nogpgcheck install \
                                wget \
                                which \
                                php-mysql \
                                php-mcrypt \
                                php-gd \
                                php-soap \
                                php-mbstring \
                                php-pecl-redis && \
                                yum clean all


# Change PHP settings as recommended by Magento
RUN sed -i -e 's/^max_execution_time = .*/max_execution_time = 18000/g' \
           -e 's/^zlib.output_compression = Off/; enable resulting html compression\nzlib.output_compression = on/g' /etc/php.ini
RUN echo -e "; disable automatic session start\n; before autoload was initialized\nflag session.auto_start = off\n\n; disable user agent verification to not break multiple image upload\nsuhosin.session.cryptua = Off" >>/etc/php.d/40-suhosin.ini

RUN curl -L --insecure -o /tmp/magento.tar.gz http://files.gtenterprises.net.au/magento-${MAGENTO_VERSION}.tar.gz
RUN tar zxvf /tmp/magento.tar.gz -C /tmp >/dev/null && mv /tmp/magento/* /tmp/magento/.htaccess /var/www/html

# TLSv1 is disabled, make sure we tell CURL not to use it and instead use TLS 1.2.
# Magento connect uses curl and will fail without this change.
RUN sed -i "s/\$this->curlOption(CURLOPT_SSL_CIPHER_LIST, 'TLSv1');/#\$this->curlOption(CURLOPT_SSL_CIPHER_LIST, 'TLSv1');\\n        \$this->curlOption(CURLOPT_SSLVERSION, CURL_SSLVERSION_TLSv1_2);/g" /var/www/html/downloader/lib/Mage/HTTP/Client/Curl.php

RUN chown -R apache:apache /var/www/html

# Make the cron files executable. 
RUN chmod 750 /var/www/html/cron.sh

EXPOSE 80
EXPOSE 443

# Secure Apache server as much as we can
COPY magento_admin.conf /etc/httpd/conf.d/magento_admin.conf

COPY run.sh /run.sh
RUN chmod +x /run.sh
CMD ["/run.sh"]

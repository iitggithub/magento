FROM centos:7.2.1511

MAINTAINER "The Ignorant IT Guy" <iitg@gmail.com>

ENV MAGENTO_VERSION 1.9.2.4

# Enables epel repo and remi repo w/ php 5.6 enabled.
COPY epel.repo /etc/yum.repos.d/epel.repo
COPY remi.repo /etc/yum.repos.d/remi.repo

RUN yum -y --nogpgcheck install \
                                httpd \
                                mod_ssl \
                                php \
                                php-devel \
                                php-suhosin \
                                php-mysql \
                                php-mcrypt \
                                php-gd \
                                php-soap \
                                php-mbstring \
                                php-pecl-redis && \
                                yum clean all


RUN sed -i 's/<Directory "\/var\/www\/html">/<Directory "\/var\/www\/html">\n<LimitExcept GET POST HEAD>\ndeny from all\n<\/LimitExcept>/1' /etc/httpd/conf/httpd.conf 

RUN sed -i 's/Options Indexes.*/Options -Indexes -Includes +FollowSymLinks/g' /etc/httpd/conf/httpd.conf

RUN sed -i -e 's/SSLProtocol.*/SSLProtocol all -SSLv3 -TLSv1 -TLSv1.1/g' \
           -e 's/^SSLCipherSuite.*/SSLCipherSuite ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256/g' \
           -e 's/#SSLHonorCipherOrder on/SSLHonorCipherOrder on\nHeader add Strict-Transport-Security "max-age=15768000"/g' \
           /etc/httpd/conf.d/ssl.conf

RUN sed -i -e 's/Listen 443 https/Listen 443 https\nSSLCompression off\nSSLUseStapling on\nSSLStaplingResponderTimeout 5\nSSLStaplingReturnResponderErrors off\nSSLStaplingCache shmcb:\/var\/run\/ocsp\(128000\)\n/g' \
           /etc/httpd/conf.d/ssl.conf

# Change PHP settings as recommended by Magento
RUN sed -i -e 's/^max_execution_time = .*/max_execution_time = 18000/g' \
           -e 's/^zlib.output_compression = Off/; enable resulting html compression\nzlib.output_compression = on/g' /etc/php.ini
RUN echo -e "; disable automatic session start\n; before autoload was initialized\nflag session.auto_start = off\n\n; disable user agent verification to not break multiple image upload\nsuhosin.session.cryptua = Off" >>/etc/php.d/40-suhosin.ini

# Disable unused modules
RUN sed -i 's/LoadModule info_module/#LoadModule info_module/g' /etc/httpd/conf.modules.d/00-base.conf

# Allow overrides. Surely, there's gotta be a better way to do this...
RUN awk '/    AllowOverride None/{count++;if(count==2){sub("    AllowOverride None","    AllowOverride All")}}1' /etc/httpd/conf/httpd.conf >/etc/httpd/conf/httpd.conf.new
RUN mv /etc/httpd/conf/httpd.conf.new /etc/httpd/conf/httpd.conf

COPY magento-1.9.2.4.tar.gz /tmp/magento-1.9.2.4.tar.gz
RUN tar zxvf /tmp/magento-1.9.2.4.tar.gz -C /tmp && mv /tmp/magento/* /tmp/magento/.htaccess /var/www/html

# Add the modified version of the Varien PHP file
#COPY Varien.php /Varien.php
#RUN chown apache:apache /Varien.php

RUN chown -R apache:apache /var/www/html

VOLUME ["/var/www/html/app/etc"]
VOLUME ["/etc/httpd/ssl"]

EXPOSE 80
EXPOSE 443

# Secure Apache server as much as we can
COPY magento_admin.conf /etc/httpd/conf.d/magento_admin.conf
COPY secure.conf /etc/httpd/conf.d/secure.conf
COPY run.sh /run.sh
RUN chmod +x /run.sh
CMD ["/run.sh"]

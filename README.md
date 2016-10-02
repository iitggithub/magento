# Docker Image for Magento 1.x

I was asked to install magento on a host and decided to run it via docker. The existing magento containers didn't suit my needs 100% so i made one. This image is a CentOS 7 based container which contains slightly more secure versions of Apache 2.4.6, openssl and PHP 5.6 w/ suhosin patch. Magento comes pre-installed but requires a seperate database in order to install correctly.

## Notes

The dockerfile is based on the actual installation guide/requirements on the magento website + some basic hardening guides for php, apache and openssl. It's also partially based on Alex Chengs' Magento 1.9.x image.

## Supported Magento versions

Version | Git branch | Tag name
--------| ---------- |---------
1.9.2.4 | master     | 1.9.2.4



## Docker Compose

The github repo contains a docker-compose.yml you can use as a base. The docker-compose.yml is compatible with docker-compose 1.5.2+.

```
apache:
  image: iitgdocker/magento:1.9.2.4
  ports:
    - "80:80"
    - "443:443"
  links:
    - percona-server
    - redis
  volumes:
    - /data/magento/etc:/var/www/html/app/etc
    - /data/magento/ssl:/etc/httpd/ssl
redis:
  image: redis:3.2.4
  ports:
    - "6379:6379"
percona-server:
  image: percona/percona-server:5.6.28
  ports:
    - "3306:3306"
  environment:
    - MYSQL_ROOT_PASSWORD=password
    - MYSQL_DATABASE=magento
    - MYSQL_USER=magento
    - MYSQL_PASSWORD=password
  volumes:
    - /data/percona/mysql:/var/lib/mysql
```

By running 'docker-compose up -d' from within the same directory as your docker-compose.yml, you'll be able to bring the container up.

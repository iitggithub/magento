# Docker Image for Magento 1.x

I was asked to install magento on a host and decided to run it via docker. The existing magento containers didn't suit my needs 100% so i made one. This image is a CentOS 7 based container which contains slightly more secure versions of Apache 2.4.6, openssl and PHP 5.6 w/ suhosin patch. Magento comes pre-installed but requires a seperate database in order to install correctly.

# Notes

The dockerfile is based on the actual installation guide/requirements on the magento website + some basic hardening guides for php, apache and openssl. It's also partially based on Alex Chengs' Magento 1.9.x image.

# Supported Magento versions

Version | Git branch | Tag name
--------| ---------- |---------
1.9.2.4 | master     | 1.9.2.4


# Getting Started

There's two ways to get up and running, the easy way and the hard way.

## The Hard Way (Standalone)

Start mysql (and redis if your using it) first

```
docker run -d --name percona-server -p 3306:3306 -v /data/percona/mysql:/var/lib/mysql -e MYSQL_ROOT_PASSWORD=password -e MYSQL_DATABASE=magento -e MYSQL_USER=magento -e MYSQL_PASSWORD=password percona/percona-server:5.6.28
docker run -d --name redis -p 6379:6379 redis:3.2.4
```

Fire up magento

```
docker run -d --name magento -p 80:80 -p 443:443 -v /data/magento/etc:/var/www/html/app/etc -v /data/magento/ssl:/etc/httpd/ssl iitgdocker/magento:1.9.2.4
```

## The Easy Way (Docker Compose)

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

# Volumes


## SSL Certificates

If you want to use your own SSL certificates you'll need to mount a volume onto /etc/httpd/ssl. Your certificates MUST be named as follows:

```
server.crt
server.key
server-chain.crt
ca-bundle.crt
```

The run.sh will check for each of those files before modifying /etc/httpd/conf.d/ssl.conf accordingly.

## Magento configuration

I've been tossing up whether to use environment variables a la Alex Cheng albeit with the run script making the changes or use a mounted volume. I still haven't decided so in the meantime, i've just been using a mounted volume.

# Environment variables

Other than the standard mysql container environment variables which can be better explained on their respective docker pages, there aren't any to note (yet).

Variable              | Default Value (docker-compose) | Description
--------------------- | ------------------------------ |------------
MYSQL_ROOT_PASSWORD   | password                       | MySQL root password (required)
MYSQL_DATABASE        | magento                        | The name of a MySQL database to create on startup
MYSQL_USER            | magento                        | The mysql user to create on startup
MYSQL_PASSWORD        | password                       | The password for the mysql user above

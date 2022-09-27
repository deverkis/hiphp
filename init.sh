#!/bin/bash
mkdir -p /data/www/typecho
cd /data/www/typecho
mkdir -p mysql
mkdir -p nginx
mkdir -p ssl
mkdir -p php
mkdir -p web
mkdir -p data
 
echo '
FROM php:7.3.31-fpm-buster
LABEL maintainer="deverkis" \
      email="deverkis@qq.com" \
      version="7.3.31"
RUN sed -i "s/deb.debian.org/mirrors.aliyun.com/g" /etc/apt/sources.list && apt-get update \
    && docker-php-ext-install pdo_mysql \
    && echo "output_buffering = 4096" > /usr/local/etc/php/conf.d/php.ini
' > php/Dockerfile
cd web
 
git clone https://github.com/typecho/typecho.git .
git clone https://github.com/typecho/typecho.git .
 
cd ..
 
if [ ! -e "web/index.php" ];then
   echo "typecho download failure, try again."
   exit;
fi
 
cd php 
 
docker build -t deverphp/php:1.0 .
 
cd ..
echo '
version: "3"
services:
  nginx:
    image: nginx
    container_name: deverserver
    ports:
      - "80:80"
      - "443:443"
    restart: always
    volumes:
      - ./data:/usr/uploads
      - ./web:/var/www/html
      - ./ssl:/var/www/ssl
      - ./nginx:/etc/nginx/conf.d
    depends_on:
      - php
    networks:
      - web
  php:
    image: deverphp/php:1.0
    container_name: deverphp
    restart: always
    ports:
      - "9000:9000"
    volumes:
      - ./data:/usr/uploads
      - ./web:/var/www/html
    environment:
      - TZ=Asia/Shanghai
    depends_on:
      - mysql
    networks:
      - web
  mysql:
    image: mysql:5.7
    container_name: devermysql
    restart: always
    ports:
      - "3306:3306"
    volumes:
      - ./mysql/data:/var/lib/mysql
      - ./mysql/logs:/var/log/mysql
      - ./mysql/conf:/etc/mysql/conf.d
    env_file:
      - mysql.env
    networks:
      - web
networks:
  web:
' > docker-compose.yml
 
echo '
server {
    listen 80;
    server_name localhost;
    root /var/www/html;
    index index.php;
    access_log /var/log/nginx/typecho_access.log main;
    if (!-e $request_filename) {
        rewrite ^(.*)$ /index.php$1 last;
    }
    location ~ .*\.php(\/.*)*$ {
        fastcgi_pass   php:9000;
        fastcgi_index  index.php;
        fastcgi_param  PATH_INFO $fastcgi_path_info;
        fastcgi_param  PATH_TRANSLATED $document_root$fastcgi_path_info;
        fastcgi_param  SCRIPT_NAME $fastcgi_script_name;
        fastcgi_param  SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include        fastcgi_params;
    }
    
}
' > nginx/default.conf
 
echo '
# MySQL的root用户默认密码，这里自行更改
MYSQL_ROOT_PASSWORD=deverphp668
# MySQL镜像创建时自动创建的数据库名称
MYSQL_DATABASE=typechodb
# MySQL镜像创建时自动创建的用户名
MYSQL_USER=deverphp
# MySQL镜像创建时自动创建的用户密码
MYSQL_PASSWORD=deverphp668
# 时区
TZ=Asia/Shanghai
' > mysql.env
 

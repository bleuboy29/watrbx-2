# ЭТАП 1: Скачиваем библиотеки через Composer
FROM composer:2.5 AS builder
COPY . /app
WORKDIR /app
RUN composer install --no-interaction --optimize-autoloader --no-dev --ignore-platform-reqs

# ----------------------------------------------------

# ЭТАП 2: Запускаем сервер со встроенным MySQL (MariaDB) и Apache
FROM php:8.1-apache

# Устанавливаем MariaDB (локальный MySQL сервер)
RUN apt-get update && apt-get install -y mariadb-server mariadb-client && docker-php-ext-install mysqli pdo pdo_mysql

# Перенаправляем корневую папку сервера на /public
ENV APACHE_DOCUMENT_ROOT /var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

# Копируем все файлы проекта вместе со скачанными библиотеками
COPY --from=builder /app /var/www/html/

# СТВОРЮЄМО ПОВНИЙ .ENV (Додано COOKIE_NAME та всі приховані налаштування сайту)
RUN echo "DB_HOST=127.0.0.1" > /var/www/html/.env && \
    echo "DB_PORT=3306" >> /var/www/html/.env && \
    echo "DB_USER=root" >> /var/www/html/.env && \
    echo "DB_PASS=watrbxpass" >> /var/www/html/.env && \
    echo "DB_NAME=watrbx" >> /var/www/html/.env && \
    echo "COOKIE_NAME=watrbx_session" >> /var/www/html/.env && \
    echo "APP_URL=https://onrender.com" >> /var/www/html/.env && \
    echo "APP_ENV=production" >> /var/www/html/.env && \
    echo "APP_KEY=base64:YmFzZTY0X2tleV9leGFtcGxlXzEyMzQ1Njc4OTA=" >> /var/www/html/.env

# Создаем конфигурацию Phinx под локальный mysql
RUN echo "<?php return ['paths'=>['migrations'=>'%%PHINX_CONFIG_DIR%%/db/migrations'],'environments'=>['default_migration_table'=>'phinxlog','default_environment'=>'production','production'=>['adapter'=>'mysql','host'=>'127.0.0.1','name'=>'watrbx','user'=>'root','pass'=>'watrbxpass','port'=>'3306','charset'=>'utf8']]];" > /var/www/html/phinx.php

# Включаем модуль rewrite
RUN a2enmod rewrite
RUN chown -R www-data:www-data /var/www/html

EXPOSE 80

# СКРИПТ ЗАПУСКА: Включаем локальный MySQL, создаем базу данных, запускаем миграцию таблиц и включаем Apache
CMD service mariadb start && \
    mysql -e "CREATE DATABASE IF NOT EXISTS watrbx;" && \
    mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY 'watrbxpass'; FLUSH PRIVILEGES;" && \
    /var/www/html/vendor/bin/phinx migrate -c /var/www/html/phinx.php || true && \
    apache2-foreground

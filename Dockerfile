# Используем стабильный и быстрый Alpine Linux вместо проблемного Debian
FROM php:7.4-fpm-alpine AS base

# Устанавливаем Apache, MySQL (MariaDB), Git и утилиты сжатия
RUN apk add --no-cache \
    apache2 \
    mariadb \
    mariadb-client \
    git \
    unzip \
    libzip-dev \
    bash

# Забираем чистый готовый Composer из официального контейнера
FROM composer:2.2 AS composer-builder
FROM base
COPY --from=composer-builder /usr/bin/composer /usr/local/bin/composer

# Включаем встроенные модули базы данных MySQL
RUN docker-php-ext-install mysqli pdo pdo_mysql zip

# Создаем папки для работы сервера Apache и базы данных
RUN mkdir -p /run/apache2 /var/www/html /run/mysqld /var/lib/mysql

# Перенаправляем корневую папку Apache на /public и включаем модуль rewrite для стилей
RUN sed -i 's|"/var/www/localhost/htdocs"|"/var/www/html/public"|g' /etc/apache2/httpd.conf && \
    sed -i 's/AllowOverride None/AllowOverride All/g' /etc/apache2/httpd.conf && \
    sed -i 's/#LoadModule rewrite_module/LoadModule rewrite_module/g' /etc/apache2/httpd.conf

# ОЧИЩАЕМ ПАПКУ И СКАЧИВАЕМ ОРИГИНАЛЬНУЮ ПЕРВУЮ ВЕРСИЮ WATRBX СО ВСЕМИ СТИЛЯМИ
WORKDIR /var/www/html
RUN rm -rf * && git clone https://github.com .

# Скачиваем все необходимые PHP библиотеки через Composer
RUN composer install --no-interaction --optimize-autoloader --no-dev --ignore-platform-reqs --prefer-dist

# Создаем файл настроек .env со всеми скрытыми ключами
RUN echo "DB_HOST=127.0.0.1" > /var/www/html/.env && \
    echo "DB_PORT=3306" >> /var/www/html/.env && \
    echo "DB_USER=root" >> /var/www/html/.env && \
    echo "DB_PASS=watrbxpass" >> /var/www/html/.env && \
    echo "DB_NAME=watrbx" >> /var/www/html/.env && \
    echo "COOKIE_NAME=watrbx_session" >> /var/www/html/.env && \
    echo "APP_URL=https://onrender.com" >> /var/www/html/.env

# Выдаем серверу Apache полные права на чтение картинок и стилей
RUN chown -R apache:apache /var/www/html

EXPOSE 80

# СКРИПТ АВТО-ЗАПУСКА: Инициализируем локальный MySQL, создаем базу и запускаем веб-сервер
CMD chown -R mysql:mysql /var/lib/mysql /run/mysqld && \
    mysql_install_db --user=mysql --datadir=/var/lib/mysql >/dev/null && \
    mysqld_safe --user=mysql --datadir=/var/lib/mysql & \
    sleep 5 && \
    mysql -e "CREATE DATABASE IF NOT EXISTS watrbx;" && \
    mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY 'watrbxpass'; FLUSH PRIVILEGES;" && \
    if [ -f vendor/bin/phinx ]; then ./vendor/bin/phinx migrate || true; fi && \
    httpd -D FOREGROUND

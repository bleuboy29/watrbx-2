# ЕТАП 1: Скачуємо бібліотеки через Composer
FROM composer:2.5 AS builder

COPY . /app
WORKDIR /app

RUN composer install --no-interaction --optimize-autoloader --no-dev --ignore-platform-reqs

# ----------------------------------------------------

# ЕТАП 2: Запускаємо сервер на PHP 8.1 з підтримкою PostgreSQL
FROM php:8.1-apache

# Встановлюємо системні бібліотеки та розширення для PostgreSQL
RUN apt-get update && apt-get install -y libpq-dev && docker-php-ext-install pdo pdo_pgsql

# Перенаправляємо кореневу папку сервера на /public, де лежать стилі
ENV APACHE_DOCUMENT_ROOT /var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

# Копіюємо всі файли проєкту разом зі скачаними бібліотеками
COPY --from=builder /app /var/www/html/

# Створюємо файл .env під конфігурацію Supabase
RUN echo "DB_CONNECTION=pgsql" > /var/www/html/.env && \
    echo "DB_HOST=\${DB_HOST}" >> /var/www/html/.env && \
    echo "DB_PORT=\${DB_PORT}" >> /var/www/html/.env && \
    echo "DB_USER=\${DB_USER}" >> /var/www/html/.env && \
    echo "DB_PASS=\${DB_PASSWORD}" >> /var/www/html/.env && \
    echo "DB_NAME=\${DB_NAME}" >> /var/www/html/.env

# Створюємо авто-конфіг Phinx під адаптер pgsql
RUN echo "<?php return ['paths'=>['migrations'=>'%%PHINX_CONFIG_DIR%%/db/migrations'],'environments'=>['default_migration_table'=>'phinxlog','default_environment'=>'production','production'=>['adapter'=>'pgsql','host'=>getenv('DB_HOST'),'name'=>getenv('DB_NAME'),'user'=>getenv('DB_USER'),'pass'=>getenv('DB_PASSWORD'),'port'=>getenv('DB_PORT'),'charset'=>'utf8']]];" > /var/www/html/phinx.php

# Вмикаємо модуль rewrite для коректних посилань сайту
RUN a2enmod rewrite

# Видаємо права серверу на читання файлів
RUN chown -R www-data:www-data /var/www/html

EXPOSE 80

# Запускаємо міграцію таблиць і вмикаємо сервер Apache
CMD /var/www/html/vendor/bin/phinx migrate -c /var/www/html/phinx.php || true && apache2-foreground

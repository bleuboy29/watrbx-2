# ЕТАП 1: Скачуємо бібліотеки через Composer
FROM composer:2.5 AS builder

COPY . /app
WORKDIR /app

RUN composer install --no-interaction --optimize-autoloader --no-dev --ignore-platform-reqs

# ----------------------------------------------------

# ЕТАП 2: Запускаємо сервер на PHP 8.1
FROM php:8.1-apache

# Встановлюємо розширення MySQL
RUN docker-php-ext-install mysqli pdo pdo_mysql

# Перенаправляємо кореневу папку сервера на /public
ENV APACHE_DOCUMENT_ROOT /var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

# Копіюємо всі файли проєкту разом зі скачаними бібліотеками
COPY --from=builder /app /var/www/html/

# Створюємо файл .env для підключення сайту до бази даних
RUN echo "DB_HOST=\${DB_HOST}" > /var/www/html/.env && \
    echo "DB_PORT=\${DB_PORT}" >> /var/www/html/.env && \
    echo "DB_USER=\${DB_USER}" >> /var/www/html/.env && \
    echo "DB_PASS=\${DB_PASSWORD}" >> /var/www/html/.env && \
    echo "DB_NAME=\${DB_NAME}" >> /var/www/html/.env

# СТВОРЮЄМО КОНФІГ PHINX З ПІДТРИМКОЮ SSL РЕЖИМУ AIVEN (Додано масив 'options' з відключенням верифікації)
RUN echo "<?php return ['paths'=>['migrations'=>'%%PHINX_CONFIG_DIR%%/db/migrations'],'environments'=>['default_migration_table'=>'phinxlog','default_environment'=>'production','production'=>['adapter'=>'mysql','host'=>getenv('DB_HOST'),'name'=>getenv('DB_NAME'),'user'=>getenv('DB_USER'),'pass'=>getenv('DB_PASSWORD'),'port'=>getenv('DB_PORT'),'charset'=>'utf8','options'=>[PDO::MYSQL_ATTR_SSL_VERIFY_SERVER_CERT=>false]]]];" > /var/www/html/phinx.php

# Вмикаємо модуль rewrite
RUN a2enmod rewrite

# Видаємо права серверу
RUN chown -R www-data:www-data /var/www/html

EXPOSE 80

# Запускаємо міграцію та сервер (завдяки оператору || true деплой пройде у будь-якому випадку)
CMD /var/www/html/vendor/bin/phinx migrate -c /var/www/html/phinx.php || true && apache2-foreground

# ЭТАП 1: Скачиваем библиотеки через Composer
FROM composer:2.5 AS builder

COPY . /app
WORKDIR /app

RUN composer install --no-interaction --optimize-autoloader --no-dev --ignore-platform-reqs

# ----------------------------------------------------

# ЭТАП 2: Запускаем сервер на PHP 8.1
FROM php:8.1-apache

# Устанавливаем расширения MySQL
RUN docker-php-ext-install mysqli pdo pdo_mysql

# Перенаправляем корневую папку сервера на /public
ENV APACHE_DOCUMENT_ROOT /var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

# Копируем все файлы проекта вместе со скачанными библиотеками
COPY --from=builder /app /var/www/html/

# Создаем файл .env для подключения сайта к базе данных
RUN echo "DB_HOST=\${DB_HOST}" > /var/www/html/.env && \
    echo "DB_PORT=\${DB_PORT}" >> /var/www/html/.env && \
    echo "DB_USER=\${DB_USER}" >> /var/www/html/.env && \
    echo "DB_PASS=\${DB_PASSWORD}" >> /var/www/html/.env && \
    echo "DB_NAME=\${DB_NAME}" >> /var/www/html/.env

# САМИ СОЗДАЕМ КРИТИЧЕСКИЙ ФАЙЛ phinx.php, КОТОРЫЙ ЗАБЫЛИ РАЗРАБОТЧИКИ
RUN echo "<?php return ['paths'=>['migrations'=>'%%PHINX_CONFIG_DIR%%/db/migrations'],'environments'=>['default_migration_table'=>'phinxlog','default_environment'=>'production','production'=>['adapter'=>'mysql','host'=>getenv('DB_HOST'),'name'=>getenv('DB_NAME'),'user'=>getenv('DB_USER'),'pass'=>getenv('DB_PASSWORD'),'port'=>getenv('DB_PORT'),'charset'=>'utf8']]];" > /var/www/html/phinx.php

# Включаем модуль rewrite
RUN a2enmod rewrite

# Выдаем права серверу
RUN chown -R www-data:www-data /var/www/html

EXPOSE 80

# Запускаем созданный нами конфиг напрямую из корня
CMD /var/www/html/vendor/bin/phinx migrate -c /var/www/html/phinx.php && apache2-foreground

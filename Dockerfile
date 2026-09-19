# ЭТАП 1: Скачиваем библиотеки через Composer
FROM composer:2.5 AS builder

COPY . /app
WORKDIR /app

RUN composer install --no-interaction --optimize-autoloader --no-dev --ignore-platform-reqs

# ----------------------------------------------------

# ЭТАП 2: Запускаем сервер на PHP 8.1 со встроенной SQLite
FROM php:8.1-apache

# Устанавливаем драйвер SQLite
RUN apt-get update && apt-get install -y sqlite3 libsqlite3-dev && docker-php-ext-install pdo pdo_sqlite

# Перенаправляем корневую папку сервера на /public
ENV APACHE_DOCUMENT_ROOT /var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

# Копируем все файлы проекта вместе со скачанными библиотеками
COPY --from=builder /app /var/www/html/

# Создаем пустой файл базы данных прямо внутри сервера
RUN mkdir -p /var/www/html/database && touch /var/www/html/database/database.sqlite

# Записываем настройки SQLite в файл .env (Сайт больше не будет просить пароли)
RUN echo "DB_CONNECTION=sqlite" > /var/www/html/.env && \
    echo "DB_DATABASE=/var/www/html/database/database.sqlite" >> /var/www/html/.env

# Создаем конфигурацию Phinx под SQLite
RUN echo "<?php return ['paths'=>['migrations'=>'%%PHINX_CONFIG_DIR%%/db/migrations'],'environments'=>['default_migration_table'=>'phinxlog','default_environment'=>'production','production'=>['adapter'=>'sqlite','name'=>'/var/www/html/database/database.sqlite']]];" > /var/www/html/phinx.php

# Включаем модуль rewrite для корректной работы стилей
RUN a2enmod rewrite

# Выдаем серверу полные права на чтение и запись локальной базы
RUN chown -R www-data:www-data /var/www/html

EXPOSE 80

# Автоматически создаем таблицы внутри файла и запускаем сайт
CMD /var/www/html/vendor/bin/phinx migrate -c /var/www/html/phinx.php || true && apache2-foreground

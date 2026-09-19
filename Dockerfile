# ЭТАП 1: Берем готовый образ, где ЕСТЬ и Git, и Composer. Он скачает всё без единой ошибки.
FROM composer:2.2 AS builder

# Копируем файлы проекта в папку сборщика
COPY . /app
WORKDIR /app

# Скачиваем библиотеки. Тут Git есть с завода, поэтому сборка пройдет идеально на 100%
RUN composer install --no-interaction --optimize-autoloader --no-dev --ignore-platform-reqs

# ----------------------------------------------------

# ЭТАП 2: Берем чистый сервер Apache, где PHP и стили уже настроены с завода
FROM php:7.4-apache

# Включаем встроенные модули MySQL
RUN docker-php-ext-install mysqli pdo pdo_mysql

# Перенаправляем корневую папку сервера на /public, где лежат все стили и index.php
ENV APACHE_DOCUMENT_ROOT /var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

# Копируем файлы проекта ИЗ ПЕРВОГО СБОРЩИКА (уже вместе со всеми скачанными библиотеками!)
COPY --from=builder /app /var/www/html/

# Включаем модуль rewrite для правильных ссылок и стилей
RUN a2enmod rewrite

# Выдаем права серверу на чтение файлов
RUN chown -R www-data:www-data /var/www/html

EXPOSE 80

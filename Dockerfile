# Забираем готовый Composer из официального контейнера
FROM composer:2.2 AS composer

FROM php:7.4-apache

# Копируем бинарник Composer
COPY --from=composer /usr/bin/composer /usr/local/bin/composer

# Включаем встроенные модули MySQL
RUN docker-php-ext-install mysqli pdo pdo_mysql

# Перенаправляем корневую папку Apache на /public
ENV APACHE_DOCUMENT_ROOT /var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

# Копируем все файлы проекта
COPY . /var/www/html/

# Отключаем Git в настройках Composer внутри контейнера и жестко ставим скачивание только ZIP-архивов
WORKDIR /var/www/html
RUN composer config ://github.com dist && \
    composer config preferred-install.* dist && \
    composer install --no-interaction --optimize-autoloader --no-dev --ignore-platform-reqs --prefer-dist --no-scripts

# Включаем модуль rewrite
RUN a2enmod rewrite

# Выдаем права серверу
RUN chown -R www-data:www-data /var/www/html

EXPOSE 80

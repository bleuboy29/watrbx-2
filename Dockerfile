# Используем официальный образ Composer, чтобы забрать готовый установщик без apt-get
FROM composer:2.2 AS composer

FROM php:7.4-apache

# Напрямую копируем готовый Composer из первого контейнера
COPY --from=composer /usr/bin/composer /usr/local/bin/composer

# Включаем встроенные модули MySQL (они уже есть в образе, apt-get не нужен)
RUN docker-php-ext-install mysqli pdo pdo_mysql

# Настраиваем корневую папку Apache на /public
ENV APACHE_DOCUMENT_ROOT /var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

# Копируем файлы сайта
COPY . /var/www/html/

# Запускаем Composer (используем флаг --ignore-platform-reqs, чтобы пропустить проверку системных утилит)
WORKDIR /var/www/html
RUN composer install --no-interaction --optimize-autoloader --no-dev --ignore-platform-reqs

# Включаем модуль rewrite
RUN a2enmod rewrite

# Выдаем права серверу
RUN chown -R www-data:www-data /var/www/html

EXPOSE 80

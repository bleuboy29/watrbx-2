# Використовуємо офіційний образ Composer, щоб забрати готовий установщик
FROM composer:2.2 AS composer

FROM php:7.4-apache

# Напряму копіюємо готовий Composer
COPY --from=composer /usr/bin/composer /usr/local/bin/composer

# Вмикаємо вбудовані модулі MySQL
RUN docker-php-ext-install mysqli pdo pdo_mysql

# Налаштовуємо кореневу папку Apache на /public
ENV APACHE_DOCUMENT_ROOT /var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

# Копіюємо файли сайту
COPY . /var/www/html/

# Запускаємо Composer з прапорцем --prefer-dist (щоб качати ZIP-архіви без git)
WORKDIR /var/www/html
RUN composer install --no-interaction --optimize-autoloader --no-dev --ignore-platform-reqs --prefer-dist

# Вмикаємо модуль rewrite
RUN a2enmod rewrite

# Видаємо права серверу
RUN chown -R www-data:www-data /var/www/html

EXPOSE 80

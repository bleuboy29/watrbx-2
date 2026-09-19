# Беремо готовий робочий Composer
FROM composer:2.2 AS composer-builder

# Повертаємося до класичного Apache образу, де PHP та стилі вже налаштовані виробником
FROM php:7.4-apache

# Напряму копіюємо готовий Composer в систему
COPY --from=composer-builder /usr/bin/composer /usr/local/bin/composer

# Вмикаємо вбудовані модулі MySQL (вони вже є в образі, apt-get update НЕ потрібен!)
RUN docker-php-ext-install mysqli pdo pdo_mysql

# Перенаправляємо кореневу папку сервера на /public, де лежать стилі та index.php
ENV APACHE_DOCUMENT_ROOT /var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

# Копіюємо всі файли вашого сайту
COPY . /var/www/html/

# Переходимо в папку сайту і ставимо бібліотеки (ігноруючи системні утиліти)
WORKDIR /var/www/html
RUN composer install --no-interaction --optimize-autoloader --no-dev --ignore-platform-reqs

# Вмикаємо модуль rewrite для правильних посилань
RUN a2enmod rewrite

# Надаємо права серверу на читання файлів
RUN chown -R www-data:www-data /var/www/html

EXPOSE 80

FROM php:7.4-apache

# Встановлюємо розширення для роботи з базою даних MySQL
RUN docker-php-ext-install mysqli pdo pdo_mysql

# Змінюємо кореневу папку Apache на папку public, де лежить index.php
ENV APACHE_DOCUMENT_ROOT /var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

# Копіюємо всі файли вашого сайту
COPY . /var/www/html/

# Вмикаємо модуль rewrite для гарних посилань
RUN a2enmod rewrite

# Надаємо серверу права на папки
RUN chown -R www-data:www-data /var/www/html

EXPOSE 80

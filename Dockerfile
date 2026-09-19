FROM php:7.4-apache

# Виправляємо застарілі репозиторії Debian Bullseye, перемикаючи їх на архів
RUN sed -i 's/deb.debian.org/archive.debian.org/g' /etc/apt/sources.list && \
    sed -i 's|security.debian.org/debian-security|archive.debian.org/debian-security|g' /etc/apt/sources.list && \
    sed -i '/stretch-updates/d' /etc/apt/sources.list

# Тепер оновлення та встановлення системних утиліт пройде без помилок 404
RUN apt-get update && apt-get install -y \
    git \
    unzip \
    libzip-dev \
    && docker-php-ext-install mysqli pdo pdo_mysql zip

# Встановлюємо Composer всередині контейнера
RUN curl -sS https://getcomposer.org | php -- --install-dir=/usr/local/bin --filename=composer

# Налаштовуємо кореневу папку Apache на /public
ENV APACHE_DOCUMENT_ROOT /var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

# Копіюємо всі файли проєкту
COPY . /var/www/html/

# Змінюємо робочу директорію та встановлюємо бібліотеки Composer
WORKDIR /var/www/html
RUN composer install --no-interaction --optimize-autoloader --no-dev

# Вмикаємо модуль rewrite
RUN a2enmod rewrite

# Видаємо права веб-серверу
RUN chown -R www-data:www-data /var/www/html

EXPOSE 80

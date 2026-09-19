# Використовуємо офіційний образ PHP 7.4 з Apache на базі Alpine
FROM php:7.4-apache-alpine

# Встановлюємо тільки необхідні утиліти для бази даних та Composer
RUN apk add --no-cache \
    git \
    unzip \
    libzip-dev \
    bash \
    && docker-php-ext-install mysqli pdo pdo_mysql zip

# Встановлюємо Composer
RUN curl -sS https://getcomposer.org | php -- --install-dir=/usr/local/bin --filename=composer

# Налаштовуємо кореневу папку сервера Apache на /public
ENV APACHE_DOCUMENT_ROOT /var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/httpd.conf /etc/apache2/conf-available/*.conf

# Копіюємо всі файли вашого сайту
COPY . /var/www/html/

# Переходимо в папку проєкту та запускаємо Composer
WORKDIR /var/www/html
RUN composer install --no-interaction --optimize-autoloader --no-dev --ignore-platform-reqs

# Вмикаємо модуль rewrite (на Alpine Apache налаштовується через httpd.conf)
RUN sed -i 's/#LoadModule rewrite_module/LoadModule rewrite_module/g' /etc/apache2/httpd.conf

# Надаємо серверу права на файли
RUN chown -R apache:apache /var/www/html

EXPOSE 80

# Беремо офіційний робочий образ Composer і називаємо його будівельником
FROM composer:2.2 AS composer-builder

# Основний образ нашого сервера
FROM php:7.4-fpm-alpine

# ПЕРЕНЕСЕННЯ ГОТОВОГО COMPOSER (Він гарантовано буде всередині системи)
COPY --from=composer-builder /usr/bin/composer /usr/local/bin/composer

# Встановлюємо Apache, Git, Unzip та модулі для бази даних MySQL
RUN apk add --no-cache \
    apache2 \
    git \
    unzip \
    libzip-dev \
    && docker-php-ext-install mysqli pdo pdo_mysql zip

# Створюємо необхідні папки для роботи Apache
RUN mkdir -p /run/apache2

# Налаштовуємо Apache для роботи з папкою /public
RUN sed -i 's|"/var/www/localhost/htdocs"|"/var/www/html/public"|g' /etc/apache2/httpd.conf && \
    sed -i 's/AllowOverride None/AllowOverride All/g' /etc/apache2/httpd.conf

# Копіюємо всі файли вашого сайту в контейнер
COPY . /var/www/html/

# Переходимо в папку проєкту
WORKDIR /var/www/html

# Запускаємо Composer (Тепер він точно запуститься)
RUN composer install --no-interaction --optimize-autoloader --no-dev --ignore-platform-reqs

# Надаємо серверу права на файли
RUN chown -R apache:apache /var/www/html

EXPOSE 80

# Запуск сервера Apache при старті контейнера
CMD ["httpd", "-D", "FOREGROUND"]

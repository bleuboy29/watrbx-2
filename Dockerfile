# Використовуємо офіційний образ PHP 7.4 на Alpine
FROM php:7.4-fpm-alpine

# Встановлюємо Apache, Git, Unzip, модулі MySQL та додаємо openssl + curl
RUN apk add --no-cache \
    apache2 \
    git \
    unzip \
    libzip-dev \
    curl \
    openssl \
    && docker-php-ext-install mysqli pdo pdo_mysql zip

# Завантажуємо Composer (тепер з openssl він точно скачається)
RUN curl -sS https://getcomposer.org | php -- --install-dir=/usr/local/bin --filename=composer

# Створюємо необхідні папки для роботи Apache
RUN mkdir -p /run/apache2

# Налаштовуємо Apache для роботи з папкою /public
RUN sed -i 's|"/var/www/localhost/htdocs"|"/var/www/html/public"|g' /etc/apache2/httpd.conf && \
    sed -i 's/AllowOverride None/AllowOverride All/g' /etc/apache2/httpd.conf

# Копіюємо всі файли вашого сайту в контейнер
COPY . /var/www/html/

# Переходимо в папку проєкту та запускаємо Composer
WORKDIR /var/www/html
RUN composer install --no-interaction --optimize-autoloader --no-dev --ignore-platform-reqs

# Надаємо серверу права на файли
RUN chown -R apache:apache /var/www/html

EXPOSE 80

# Запуск сервера Apache при старті контейнера
CMD ["httpd", "-D", "FOREGROUND"]

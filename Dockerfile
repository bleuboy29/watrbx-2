# Використовуємо офіційний образ PHP 7.4 на базі стабільного Alpine Linux
FROM php:7.4-fpm-alpine

# Миттєво встановлюємо GIT, ZIP та інструменти для збірки MySQL (на Alpine все працює!)
RUN apk add --no-cache \
    git \
    unzip \
    libzip-dev \
    shadow \
    bash \
    apache2 \
    php7-apache2 \
    && docker-php-ext-install mysqli pdo pdo_mysql zip

# Встановлюємо Composer
RUN curl -sS https://getcomposer.org | php -- --install-dir=/usr/local/bin --filename=composer

# Налаштовуємо Apache для роботи всередині Alpine
RUN mkdir -p /run/apache2 && \
    sed -i 's/#LoadModule rewrite_module/LoadModule rewrite_module/g' /etc/apache2/httpd.conf && \
    sed -i 's/AllowOverride None/AllowOverride All/g' /etc/apache2/httpd.conf

# Змінюємо папку сайту на /public
RUN sed -i 's|"/var/www/localhost/htdocs"|"/var/www/html/public"|g' /etc/apache2/httpd.conf

# Копіюємо всі файли вашого сайту
COPY . /var/www/html/

# Переходимо в папку проєкту та встановлюємо бібліотеки Composer (тепер з працюючим Git)
WORKDIR /var/www/html
RUN composer install --no-interaction --optimize-autoloader --no-dev --ignore-platform-reqs

# Видаємо права доступу серверу Apache
RUN chown -R apache:apache /var/www/html

EXPOSE 80

# Запускаємо веб-сервер у фоновому режимі
CMD ["httpd", "-D", "FOREGROUND"]

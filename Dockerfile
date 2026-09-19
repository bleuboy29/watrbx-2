# ЕТАП 1: Збираємо PHP бібліотеки та компілюємо CSS/JS стилі
FROM composer:2.5 AS composer-builder

# Копіюємо код проєкту
COPY . /app
WORKDIR /app

# Скачуємо всі PHP залежності
RUN composer install --no-interaction --optimize-autoloader --no-dev --ignore-platform-reqs

# Встановлюємо Node.js прямо в цей контейнер для збірки стилів
RUN apt-get update && apt-get install -y nodejs npm

# Компілюємо стилі сайту (якщо є package.json)
RUN if [ -f package.json ]; then \
        npm install --no-audit --no-fund && \
        (npm run prod || npm run dev || npm run build || true); \
    fi

# ----------------------------------------------------

# ЕТАП 2: Запускаємо основний сервер з базою даних та готовим дизайном
FROM php:8.1-apache

# Устанавливаем MariaDB (локальний MySQL сервер)
RUN apt-get update && apt-get install -y mariadb-server mariadb-client && docker-php-ext-install mysqli pdo pdo_mysql

# Перенаправляємо кореневу папку сервера на /public
ENV APACHE_DOCUMENT_ROOT /var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

# Копіюємо все файли проєкту разом зі ЗГЕНЕРОВАНИМИ СТИЛЯМИ з першого контейнера
COPY --from=composer-builder /app /var/www/html/

# Створюємо файл .env для налаштування
RUN echo "DB_HOST=127.0.0.1" > /var/www/html/.env && \
    echo "DB_PORT=3306" >> /var/www/html/.env && \
    echo "DB_USER=root" >> /var/www/html/.env && \
    echo "DB_PASS=watrbxpass" >> /var/www/html/.env && \
    echo "DB_NAME=watrbx" >> /var/www/html/.env && \
    echo "COOKIE_NAME=watrbx_session" >> /var/www/html/.env && \
    echo "APP_URL=https://onrender.com" >> /var/www/html/.env && \
    echo "APP_ENV=production" >> /var/www/html/.env && \
    echo "APP_KEY=base64:YmFzZTY0X2tleV9leGFtcGxlXzEyMzQ1Njc4OTA=" >> /var/www/html/.env

# Создаем конфигурацию Phinx под локальный mysql
RUN echo "<?php return ['paths'=>['migrations'=>'%%PHINX_CONFIG_DIR%%/db/migrations'],'environments'=>['default_migration_table'=>'phinxlog','default_environment'=>'production','production'=>['adapter'=>'mysql','host'=>'127.0.0.1','name'=>'watrbx','user'=>'root','pass'=>'watrbxpass','port'=>'3306','charset'=>'utf8']]];" > /var/www/html/phinx.php

# Замінюємо localhost на реальний домен у коді сайту
RUN find /var/www/html -type f -name "*.php" -exec sed -i 's|http://localhost|https://onrender.com|g' {} + && \
    find /var/www/html -type f -name "*.php" -exec sed -i 's|https://localhost|https://onrender.com|g' {} +

# Вмикаємо модуль rewrite
RUN a2enmod rewrite
RUN chown -R www-data:www-data /var/www/html

EXPOSE 80

# СКРИПТ ЗАПУСКА: Включаем локальный MySQL, создаем базу данных, запускаем миграцию таблиц и включаем Apache
CMD service mariadb start && \
    mysql -e "CREATE DATABASE IF NOT EXISTS watrbx;" && \
    mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY 'watrbxpass'; FLUSH PRIVILEGES;" && \
    /var/www/html/vendor/bin/phinx migrate -c /var/www/html/phinx.php || true && \
    apache2-foreground

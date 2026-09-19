FROM php:7.4-fpm-alpine

# Встановлюємо всі необхідні пакети для Apache, бази даних та Composer
RUN apk add --no-cache apache2 mariadb mariadb-client git unzip libzip-dev bash && docker-php-ext-install mysqli pdo pdo_mysql zip

# Завантажуємо чистий Composer напряму без зайвих етапів
RUN curl -sS https://getcomposer.org | php -- --install-dir=/usr/local/bin --filename=composer

# Створюємо потрібні системні папки для веб-сервера
RUN mkdir -p /run/apache2 /var/www/html /run/mysqld /var/lib/mysql

# Налаштовуємо Apache на папку public та вмикаємо rewrite модулі
RUN sed -i 's|"/var/www/localhost/htdocs"|"/var/www/html/public"|g' /etc/apache2/httpd.conf && sed -i 's/AllowOverride None/AllowOverride All/g' /etc/apache2/httpd.conf && sed -i 's/#LoadModule rewrite_module/LoadModule rewrite_module/g' /etc/apache2/httpd.conf

# Переходимо в робочу папку
WORKDIR /var/www/html

# СКАЧИВАЕМ ПЕРВУЮ ВЕРСИЮ WATRBX (Команда записана в один короткий рядок)
RUN rm -rf * && git clone https://github.com .

# Встановлюємо залежності проєкту через Composer
RUN composer install --no-interaction --optimize-autoloader --no-dev --ignore-platform-reqs --prefer-dist

# Створюємо конфігураційний файл .env
RUN echo "DB_HOST=127.0.0.1" > /var/www/html/.env && echo "DB_PORT=3306" >> /var/www/html/.env && echo "DB_USER=root" >> /var/www/html/.env && echo "DB_PASS=watrbxpass" >> /var/www/html/.env && echo "DB_NAME=watrbx" >> /var/www/html/.env && echo "COOKIE_NAME=watrbx_session" >> /var/www/html/.env && echo "APP_URL=https://onrender.com" >> /var/www/html/.env

# Надаємо веб-серверу права на читання стилів та картинок
RUN chown -R apache:apache /var/www/html

EXPOSE 80

# Запуск вбудованої бази даних, створення таблиць та старт сайту
CMD chown -R mysql:mysql /var/lib/mysql /run/mysqld && mysql_install_db --user=mysql --datadir=/var/lib/mysql >/dev/null && mysqld_safe --user=mysql --datadir=/var/lib/mysql & sleep 5 && mysql -e "CREATE DATABASE IF NOT EXISTS watrbx;" && mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY 'watrbxpass'; FLUSH PRIVILEGES;" && if [ -f vendor/bin/phinx ]; then ./vendor/bin/phinx migrate || true; fi && httpd -D FOREGROUND

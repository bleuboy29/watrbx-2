FROM php:7.4-fpm-alpine

# Устанавливаем все необходимые пакеты для Apache, базы данных и Composer
RUN apk add --no-cache apache2 mariadb mariadb-client git unzip libzip-dev bash && docker-php-ext-install mysqli pdo pdo_mysql zip

# Загружаем чистый Composer напрямую
RUN curl -sS https://getcomposer.org | php -- --install-dir=/usr/local/bin --filename=composer

# Создаем нужные системные папки для веб-сервера
RUN mkdir -p /run/apache2 /var/www/html /run/mysqld /var/lib/mysql

# Настраиваем Apache на папку public и включаем rewrite модули
RUN sed -i 's|"/var/www/localhost/htdocs"|"/var/www/html/public"|g' /etc/apache2/httpd.conf && sed -i 's/AllowOverride None/AllowOverride All/g' /etc/apache2/httpd.conf && sed -i 's/#LoadModule rewrite_module/LoadModule rewrite_module/g' /etc/apache2/httpd.conf

# Переходим в рабочую搬 папку
WORKDIR /var/www/html

# СКАЧИВАЕМ ПЕРВУЮ ВЕРСИЮ ЧЕРЕЗ АРХИВ (Одной прямой командой без подстановок)
RUN curl -L https://github.com -o web.zip && unzip web.zip && cp -rf watrbx-main/* . && rm -rf watrbx-main web.zip

# Устанавливаем зависимости проекта через Composer
RUN composer install --no-interaction --optimize-autoloader --no-dev --ignore-platform-reqs --prefer-dist

# Создаем конфигурационный файл .env
RUN echo "DB_HOST=127.0.0.1" > /var/www/html/.env && echo "DB_PORT=3306" >> /var/www/html/.env && echo "DB_USER=root" >> /var/www/html/.env && echo "DB_PASS=watrbxpass" >> /var/www/html/.env && echo "DB_NAME=watrbx" >> /var/www/html/.env && echo "COOKIE_NAME=watrbx_session" >> /var/www/html/.env && echo "APP_URL=https://onrender.com" >> /var/www/html/.env

# Предоставляем веб-серверу права на чтение стилей и картинок
RUN chown -R apache:apache /var/www/html

EXPOSE 80

# Запуск встроенной базы данных, создание таблиц и старт сайта
CMD chown -R mysql:mysql /var/lib/mysql /run/mysqld && mysql_install_db --user=mysql --datadir=/var/lib/mysql >/dev/null && mysqld_safe --user=mysql --datadir=/var/lib/mysql & sleep 5 && mysql -e "CREATE DATABASE IF NOT EXISTS watrbx;" && mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY 'watrbxpass'; FLUSH PRIVILEGES;" && if [ -f vendor/bin/phinx ]; then ./vendor/bin/phinx migrate || true; fi && httpd -D FOREGROUND

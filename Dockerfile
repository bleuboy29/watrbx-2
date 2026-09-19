# Берем готовый Composer
FROM composer:2.2 AS composer-builder

# Основной образ сервера
FROM php:7.4-fpm-alpine

# Переносим готовый Composer
COPY --from=composer-builder /usr/bin/composer /usr/local/bin/composer

# Устанавливаем Apache, Apache-PHP модуль, Git, Unzip и расширения MySQL
RUN apk add --no-cache \
    apache2 \
    apache2-utils \
    git \
    unzip \
    libzip-dev \
    && docker-php-ext-install mysqli pdo pdo_mysql zip

# Создаем папки для Apache
RUN mkdir -p /run/apache2

# ЖЕСТКО ВКЛЮЧАЕМ ОБРАБОТКУ PHP И СТИЛЕЙ В APACHE
RUN sed -i 's/#LoadModule rewrite_module/LoadModule rewrite_module/g' /etc/apache2/httpd.conf && \
    sed -i 's/#LoadModule mpm_prefork_module/LoadModule mpm_prefork_module/g' /etc/apache2/httpd.conf && \
    sed -i 's/LoadModule mpm_event_module/#LoadModule mpm_event_module/g' /etc/apache2/httpd.conf && \
    echo "LoadModule php7_module modules/mod_php7.so" >> /etc/apache2/httpd.conf && \
    echo "AddHandler php7-script .php" >> /etc/apache2/httpd.conf && \
    echo "DirectoryIndex index.php index.html" >> /etc/apache2/httpd.conf

# Настраиваем корневую папку на /public
RUN sed -i 's|"/var/www/localhost/htdocs"|"/var/www/html/public"|g' /etc/apache2/httpd.conf && \
    sed -i 's/AllowOverride None/AllowOverride All/g' /etc/apache2/httpd.conf

# Копируем все файлы проекта
COPY . /var/www/html/

# Переходим в папку проекта и ставим библиотеки
WORKDIR /var/www/html
RUN composer install --no-interaction --optimize-autoloader --no-dev --ignore-platform-reqs

# Выдаем права серверу
RUN chown -R apache:apache /var/www/html

EXPOSE 80

CMD ["httpd", "-D", "FOREGROUND"]

FROM php:7.4-apache

# Устанавливаем необходимые системные утилиты и библиотеки
RUN apt-get update && apt-get install -y \
    git \
    unzip \
    libzip-dev \
    && docker-php-ext-install mysqli pdo pdo_mysql zip

# Устанавливаем Composer внутри контейнера
RUN curl -sS https://getcomposer.org | php -- --install-dir=/usr/local/bin --filename=composer

# Настраиваем корневую папку Apache на /public
ENV APACHE_DOCUMENT_ROOT /var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

# Копируем все файлы проекта
COPY . /var/www/html/

# Меняем рабочую директорию и устанавливаем библиотеки Composer
WORKDIR /var/www/html
RUN composer install --no-interaction --optimize-autoloader --no-dev

# Включаем модуль rewrite
RUN a2enmod rewrite

# Выдаем права веб-серверу
RUN chown -R www-data:www-data /var/www/html

EXPOSE 80


# ИСПОЛЬЗУЕМ СТАБИЛЬНЫЙ ОБРАЗ PHP С АПАЧЕМ
FROM php:7.4-apache

# ПОЛНОСТЬЮ ПЕРЕПИСЫВАЕМ РЕПОЗИТОРИИ DEBIAN НА РАБОЧИЕ АРХИВЫ CLOUDFLARE И DEBIAN ARCHIVE
RUN echo "deb http://debian.org bullseye main contrib non-free" > /etc/apt/sources.list && \
    echo "deb-src http://debian.org bullseye main contrib non-free" >> /etc/apt/sources.list && \
    echo "deb http://debian.org bullseye-security main contrib non-free" >> /etc/apt/sources.list && \
    echo "deb-src http://debian.org bullseye-security main contrib non-free" >> /etc/apt/sources.list

# ОТКЛЮЧАЕМ ПРОВЕРКУ СРОКА ДЕЙСТВИЯ СЕРТИФИКАТОВ РЕПОЗИТОРИЕВ (ЧТОБЫ НЕ БЫЛО ОШИБОК ВРЕМЕНИ)
RUN echo 'Acquire::Check-Valid-Until "false";' > /etc/apt/apt.conf.d/99no-check-valid-until

# ОБНОВЛЯЕМ И ЖЕСТКО СТАВИМ GIT, UNZIP И ZIP ДЛЯ COMPOSER
RUN apt-get update -y && apt-get install -y \
    git \
    unzip \
    libzip-dev \
    && docker-php-ext-install mysqli pdo pdo_mysql zip

# СКАЧИВАЕМ СВЕЖИЙ COMPOSER НАПРЯМУЮ
RUN curl -sS https://getcomposer.org | php -- --install-dir=/usr/local/bin --filename=composer

# НАСТРАИВАЕМ КОРНЕВУЮ ПАПКУ ВЕБ-СЕРВЕРА НА ПАПКУ /PUBLIC
ENV APACHE_DOCUMENT_ROOT /var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

# КОПИРУЕМ ВСЕ ФАЙЛЫ ВАШЕГО РОБЛОКС-РЕВАЙВАЛА В КОНТЕЙНЕР
COPY . /var/www/html/

# ПЕРЕХОДИМ В ПАПКУ ПРОЕКТА
WORKDIR /var/www/html

# ЗАПУСКАЕМ COMPOSER (ТЕПЕРЬ У НЕГО ЕСТЬ GIT И ВСЕ БИБЛИОТЕКИ СКАЧАЮТСЯ ИДЕАЛЬНО)
RUN composer install --no-interaction --optimize-autoloader --no-dev --ignore-platform-reqs

# ВКЛЮЧАЕМ ПЕРЕЗАПИСЬ ССЫЛОК APACHE (ЧТОБЫ РАБОТАЛ ИНТЕРФЕЙС И СТРАНИЦЫ)
RUN a2enmod rewrite

# ДАЕМ ПОЛНЫЕ ПРАВА СЕРВЕРУ НА ИЗМЕНЕНИЕ И ЧТЕНИЕ ФАЙЛОВ
RUN chown -R www-data:www-data /var/www/html

# ОТКРЫВАЕМ ПОРТ ДЛЯ ИНТЕРНЕТА
EXPOSE 80

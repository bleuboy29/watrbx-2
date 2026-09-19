FROM php:7.4-apache

# Встановлюємо розширення для роботи з базою даних MySQL
RUN docker-php-ext-install mysqli pdo pdo_mysql

# Копіюємо всі файли вашого сайту в папку сервера Apache
COPY . /var/www/html/

# Вмикаємо модуль rewrite, щоб працювали посилання сайту
RUN a2enmod rewrite

# Надаємо серверу права на редагування файлів
RUN chown -R www-data:www-data /var/www/html

EXPOSE 80


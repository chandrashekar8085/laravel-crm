# 1) Build frontend
FROM node:18 AS node-builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# 2) Composer / PHP dependencies
FROM composer:2 AS vendor
WORKDIR /app
COPY composer.json composer.lock /app/
RUN composer install --no-dev --no-interaction --optimize-autoloader

# 3) Final runtime with Apache
FROM php:8.1-apache
ENV APACHE_DOCUMENT_ROOT /var/www/html/public

# Apache & PHP ext
RUN apt-get update && apt-get install -y \
    libpng-dev libonig-dev libxml2-dev libzip-dev zip unzip \
    && docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd zip \
    && a2enmod rewrite

# Copy app
COPY --from=vendor /app /var/www/html
COPY --from=node-builder /app/public/build /var/www/html/public/build

# copy remaining files
COPY . /var/www/html

# permissions
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html/storage /var/www/html/bootstrap/cache

EXPOSE 80
CMD ["apache2-foreground"]

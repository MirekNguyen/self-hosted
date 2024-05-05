FROM php:fpm

# Install the pdo_pgsql extension
RUN apt-get update && apt-get install -y \
    libpq-dev \
    && docker-php-ext-install \
    pdo_pgsql


FROM php:8.0.11-fpm

# Set working directory
WORKDIR /var/www

RUN rmdir html

# Install dependencies
RUN apt-get update
RUN apt-get -y upgrade
RUN apt-get -y dist-upgrade
RUN apt-get install -y git curl libpng-dev libonig-dev libxml2-dev zip unzip

# Cleanup
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Compile PHP Extensions
RUN docker-php-ext-install pdo_mysql exif pcntl bcmath gd

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Add user for laravel application
RUN groupadd -g 1000 www && useradd -u 1000 -ms /bin/bash -g www www

COPY artisan composer.lock composer.json /var/www/
COPY .env.example /var/www/.env
COPY bootstrap /var/www/bootstrap
COPY config /var/www/config
COPY database /var/www/database
COPY app /var/www/app
COPY public /var/www/public
COPY resources /var/www/resources
COPY routes /var/www/routes
COPY storage /var/www/storage

RUN mkdir vendor && \
    chown -R www:www \
        storage \
        bootstrap/cache \
            .env \
            vendor \
            composer.lock

# forward request and error logs to docker log collector
RUN ln -sf /dev/stderr /var/www/storage/logs/laravel.log

# Change current user to www
USER www

RUN composer update

# Expose port 9000 and start php-fpm server
EXPOSE 9000
CMD ["php-fpm"]

FROM php:8.0.11-fpm

# Set working directory
WORKDIR /var/www

RUN rmdir html

# Install dependencies
RUN update-ca-certificates && \
    apt-get update && \
    apt-get -y upgrade && \
    apt-get -y dist-upgrade && \
    apt-get install -y \
        build-essential \
        mariadb-client \
        libpng-dev \
        libjpeg62-turbo-dev \
        libfreetype6-dev \
        locales \
        zip \
        libzip-dev \
        jpegoptim optipng pngquant gifsicle \
        vim \
        unzip \
        git \
        curl && \
# Cleanup
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
# Compile PHP Extensions
    docker-php-ext-install pdo_mysql mbstring zip exif pcntl && \
    docker-php-ext-configure gd --with-gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ --with-png-dir=/usr/include/ && \
    docker-php-ext-install gd && \
# Install Composer
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer && \
# Add user for laravel application
    groupadd -g 1000 www && useradd -u 1000 -ms /bin/bash -g www www && \
# Change locales
    sed -i 's/^# de_DE.UTF-8 UTF-8$/de_DE.UTF-8 UTF-8/' /etc/locale.gen && \
    locale-gen && \
    update-locale LANG=de_DE.UTF-8

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

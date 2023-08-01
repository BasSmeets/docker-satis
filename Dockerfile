FROM php:8.1-fpm-alpine

ARG SATIS_VERSION=3.5.1
ENV USER_HOME=/root

# Install nginx and other dependencies
# TODO check to install specific version of nginx
# check what is required
RUN apk update && apk add --no-cache \
    supervisor \
    libzip-dev \
    icu-dev \
    nginx \
    libcurl \
    $PHPIZE_DEPS \
    curl-dev \
    libpng-dev \
    libjpeg-turbo-dev \
    freetype-dev \
    libxml2-dev \
    busybox \
    bash \
    openssh-client \
    git \ 
    sudo

# Install PHP extensions
RUN docker-php-ext-install curl
RUN docker-php-ext-install intl
RUN docker-php-ext-install zip
RUN docker-php-ext-install xml

# Install Composer TODO install specific version
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Copy the Nginx configuration file from the host into the container
RUN mkdir -p /etc/nginx/http.d
RUN rm -f /etc/nginx/http.d/default.conf
COPY ./nginx/nginx.conf /etc/nginx/http.d/satis.conf

# Install satisfy https://github.com/project-satisfy/satisfy/
RUN composer create-project playbloom/satisfy:${SATIS_VERSION} /satisfy

RUN cd /satisfy \
    && composer install --no-dev -n --optimize-autoloader \
    && chmod -R 777 /satisfy

# add cron
ADD scripts/cron /etc/cron.d/satis-cron

# add default configuration files
COPY ./config/parameters.yml.dist /satisfy/config/parameters.yml
COPY ./config/satis.json.dist /satisfy/satis.json

# copy scripts
COPY ./scripts /app/scripts

RUN chmod 0644 /etc/cron.d/satis-cron \
    && touch /var/log/satis-cron.log 

# Create .ssh directory for keys
RUN mkdir -p ${USER_HOME}/.ssh

# Copy the Supervisor configuration file from the host into the container
COPY ./supervisor/supervisord.conf /etc/supervisord.conf

# Expose ports
EXPOSE 80

WORKDIR /app

# Start Supervisor to manage Nginx and PHP-FPM processes
CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisord.conf"]